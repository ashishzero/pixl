//------------------------------------------------------------------------
// From integration.cu

Integrate_Method :: enum s32
{
    DIRECTIONAL_ALBEDO;
    HEMISPHERICAL_ALBEDO;
}

Glossy_Specular_Type :: enum s32
{
    METAL;
    DIELECTRIC_OPAQUE;
    DIELECTRIC_TRANSPARENT;
}

Integration_Result :: struct
{
    n_x       : s32;
    n_y       : s32;
    n_z       : s32;
    n_samples : s64;
    type      : Glossy_Specular_Type;
    method    : Integrate_Method;
    devptr    : CUdeviceptr;
    count     : int;
    stream    : CUstream;
}

execute_integrate :: (func: CUfunction, xn: s32, yn: s32, zn: s32, n_samples: s64, type: Glossy_Specular_Type, method: Integrate_Method) -> Integration_Result
{
    BLOCK_SIZE :: 8;

    if (xn > 1 && xn % BLOCK_SIZE != 0)
    {
        print("WARNING: xn=% is not divisible by %\n", xn, BLOCK_SIZE);
    }

    if (yn > 1 && yn % BLOCK_SIZE != 0)
    {
        print("WARNING: yn=% is not divisible by %\n", yn, BLOCK_SIZE);
    }
    
    if (zn > 1 && zn % BLOCK_SIZE != 0)
    {
        print("WARNING: zn=% is not divisible by %\n", zn, BLOCK_SIZE);
    }

    result: Integration_Result;
    result.n_x       = xn;
    result.n_y       = yn;
    result.n_z       = zn;
    result.n_samples = n_samples;
    result.type      = type;
    result.method    = method;
    result.count     = xn * yn * zn;

    status := cuMemAlloc(*result.devptr, result.count.(u64) * size_of(float));
    cu_handle_error(status, "Failed to allocate memory");

    status = cuStreamCreate(*result.stream, xx CUstream_flags_enum.CU_STREAM_DEFAULT);
    cu_handle_error(status, "Failed to create stream");

    config: CUlaunchConfig;

    config.blockDimX = xx ifx xn == 1 then 1 else BLOCK_SIZE;
    config.blockDimY = xx ifx yn == 1 then 1 else BLOCK_SIZE;
    config.blockDimZ = xx ifx zn == 1 then 1 else BLOCK_SIZE;
    config.gridDimX  = xx xn / config.blockDimX;
    config.gridDimY  = xx yn / config.blockDimY;
    config.gridDimZ  = xx zn / config.blockDimZ;
    config.hStream   = result.stream;

    args  := *void.[*result.method, *result.type, *result.n_x, *result.n_y, *result.n_z, *result.n_samples, *result.devptr];
    status = cuLaunchKernelEx(*config, func, args.data, null);
    cu_handle_error(status, "Failed to launch kernel");

    return result;
}

Output_Options :: struct
{
    quantize   := false;
    complement := false;
}

main :: ()
{
    success, options := parse_arguments(Output_Options);
    if !success return;

    status : CUresult;

    status = cuInit(0);
    cu_handle_error(status, "Failed to initialize");

    dev : CUdevice;
    ctx : CUcontext;
    mod : CUmodule;

    status = cuDeviceGet(*dev, 0);
    cu_handle_error(status, "Failed to get device");

    status = cuCtxCreate(*ctx, null, 0, dev);
    cu_handle_error(status, "Failed to create context");

    status = cuModuleLoadFatBinary(*mod, INTEGRATION_FATCUBIN.data.(*void));
    cu_handle_error(status, "Failed to load fat binary");

    func : CUfunction;
    status = cuModuleGetFunction(*func, mod, "integrate_glossy_specular\0".data);
    cu_handle_error(status, "Failed to get function");

    results: [6]Integration_Result;

    results[0] = execute_integrate(func, 32,  1, 1, 16 * 1024 * 1024, .METAL, .HEMISPHERICAL_ALBEDO);
    results[1] = execute_integrate(func, 32, 32, 1,  8 * 1024 * 1024, .METAL, .DIRECTIONAL_ALBEDO);
  
    results[2] = execute_integrate(func, 32,  1, 32, 16 * 1024 * 1024, .DIELECTRIC_OPAQUE, .HEMISPHERICAL_ALBEDO);
    results[3] = execute_integrate(func, 32, 32, 32,  8 * 1024 * 1024, .DIELECTRIC_OPAQUE, .DIRECTIONAL_ALBEDO);

    results[4] = execute_integrate(func, 32,  1, 32, 16 * 1024 * 1024, .DIELECTRIC_TRANSPARENT, .HEMISPHERICAL_ALBEDO);
    results[5] = execute_integrate(func, 32, 32, 32,  8 * 1024 * 1024, .DIELECTRIC_TRANSPARENT, .DIRECTIONAL_ALBEDO);

    builder: String_Builder;

    now   := current_time_consensus();
    local := to_calendar(now, .LOCAL);
    date  := calendar_to_string(local);

    print(*builder, "//\n");
    print(*builder, "// Generated at % by bsdf_energy_compensation_lut_generation using the following command:\n", date);
    {
        print(*builder, "//\n// bsdf_energy_compensation_lut_generation ");
        args := get_command_line_arguments();
        for 1..args.count-1
        {
            print(*builder, "% ", args[it]);
        }
        print(*builder, "\n//\n");
    }

    max_count := 0;
    for results
    {
        max_count = max(max_count, it.count);
    }

    values := NewArray(max_count, float, initialized=false);

    for results
    {
        status = cuStreamSynchronize(it.stream);
        cu_handle_error(status, "Failed to synchronize stream");

        status = cuMemcpyDtoH_v2(values.data, it.devptr, it.count.(u64) * size_of(float));
        cu_handle_error(status, "Failed to synchronize stream");

        name := tprint("%_%%",
                       it.type,
                       ifx it.method == .DIRECTIONAL_ALBEDO then "ENERGY" else "AVG_ENERGY",
                       ifx options.complement "_COMPLEMENT" else "");
        type := ifx options.quantize then "u16" else "float";

        print(*builder, "%_LUT_SIZE : s32 : %;\n", name, it.n_x);
        print(*builder, "%_LUT  : [%]% : .[\n", name, it.n_x * it.n_y * it.n_z, type);
        
        for z:0..it.n_z-1
        {
            for y:0..it.n_y-1
            {
                for x:0..it.n_x-1
                {
                    index := z * it.n_y * it.n_x + y * it.n_x + x;
                    value := values[index];

                    if options.complement
                    {
                        value = 1.0 - value;
                    }

                    if options.quantize
                    {
                        quantized  := clamp(value * U16_MAX.(float), 0.0, U16_MAX.(float)).(u16);
                        print(*builder, "0x%,", FormatInt.{value=quantized, base=16, minimum_digits=4});
                    }
                    else
                    {
                        print(*builder, "%,", FormatFloat.{value=value, width=8, zero_removal=.NO});
                    }
                }
                if it.n_y > 1
                    print(*builder, "\n");
            }
            if it.n_z > 1
                print(*builder, "\n");
        }

        print(*builder, "];\n\n");
    }

    output := "bsdf_energy_compensation_lut.jai";
    if options.quantize
    {
        output = "bsdf_energy_compensation_quantized_lut.jai";
    }
    write_entire_file(output, *builder);
}

cu_handle_error :: (status: CUresult, msg: string)
{
    if (status != .CUDA_SUCCESS)
    {
        cerr: *u8;
        cuGetErrorString(status, *cerr);
        print("ERROR: %. Reason: %\n", msg, to_string(cerr));
        exit(1);
    }
}

INTEGRATION_FATCUBIN :: #run -> []u8
{
    print("Building cuda kernels...\n");

    fatbin := path_join(#filepath, "integration.fatbin");

    pr := run_command(
        "nvcc", "--fatbin",
        "--output-file", fatbin,
        "-O3", "--std", "c++17",
        "--machine", "64",
        "-gencode", "arch=compute_89,code=sm_89",
        "-gencode", "arch=compute_89,code=compute_89",
        path_join(#filepath, "integration.cu")
    );

    if pr.exit_code != 0
    {
        exit(pr.exit_code);
    }

    data := read_entire_file(fatbin);
    return data.([]u8);
}

#import "Compiler";
#import "Cuda";
#import "File";
#import "Basic";
#import "Process";
#import "String";
#import "Math";
#import "Command_Line";
