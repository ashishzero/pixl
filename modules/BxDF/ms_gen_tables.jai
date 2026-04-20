
main :: ()
{
    push_work(compute_metal_E, 1 << 23, 32, 32, 1, "metal_E");
    push_work(compute_metal_E_avg, 1 << 26, 32, 1, 1, "metal_E_avg");

    push_work(compute_dielectric_E, 1 << 23, 16, 16, 16, "dielectric_E");
    push_work(compute_dielectric_E_avg, 1 << 26, 16, 1, 16, "dielectric_E_avg");

    push_work(compute_dielectric_inv_E, 1 << 23, 16, 16, 16, "dielectric_inv_E");
    push_work(compute_dielectric_inv_E_avg, 1 << 26, 16, 1, 16, "dielectric_inv_E_avg");

    push_work(compute_dielectric_full_E, 1 << 23, 16, 16, 16, "dielectric_full_E");
    push_work(compute_dielectric_full_E_avg, 1 << 26, 16, 1, 16, "dielectric_full_E_avg");

    push_work(compute_dielectric_full_inv_E, 1 << 23, 16, 16, 16, "dielectric_full_inv_E");
    push_work(compute_dielectric_full_inv_E_avg, 1 << 26, 16, 1, 16, "dielectric_full_inv_E_avg");

    args    := get_command_line_arguments();
    program := args[0];
    args     = array_view(args, 1, args.count - 1);

    if args.count
    {
        for arg: args
        {
            name := trim(arg);
            if compare_nocase(name, "-help") == 0
            {
                print("USAGE ::\n    % all OR computes...\n", program);
                print("Computes:\n");
                for compute_queue
                {
                    print("    %\n", it.name);
                }
                print("\n\n");
                return;
            }

            for * compute_queue
            {
                if compare_nocase(name, it.name) == 0
                {
                    it.compute = true;
                }
            }
        }
    }
    else
    {
        for * compute_queue
        {
            it.compute = true;
        }
    }

    execute();
}

//------------------------------------------------------------------------
// Compute Functions

compute_metal_E :: (roughness: float, cosine: float, ior: float, p: float, u: Vector2) -> float
{
    alpha  := microfacet_alpha(roughness, 0.0);
    if microfacet_is_delta(alpha) return 1.0;
    sine   := sqrt(1.0 - cosine * cosine);
    V      := Vector3.{sine, 0.0, cosine};
    sample := sample_ggx_specular_reflect(V, alpha, u);
    if (sample.pdf > 0.0)
    {
        E := sample.f.x * abs(sample.L.z) / sample.pdf;
        return E;
    }
    return 0.0;
}

compute_metal_E_avg :: (roughness: float, cosine: float, ior: float, p: float, u: Vector2) -> float
{
    E := compute_metal_E(roughness, cosine, ior, p, u);
    return 2.0 * cosine * E;
}

compute_dielectric_E :: (roughness: float, cosine: float, ior: float, p: float, u: Vector2) -> float
{
    alpha  := microfacet_alpha(roughness, 0.0);
    if microfacet_is_delta(alpha) return 1.0;
    sine   := sqrt(1.0 - cosine * cosine);
    V      := Vector3.{sine, 0.0, cosine};
    sample := sample_ggx_specular_reflect(V, alpha, u);
    if (sample.pdf > 0.0)
    {
        H    := sample.H;
        F    := fresnel_dielectric(ior, dot(V, H));
        E    := F * sample.f.x * abs(sample.L.z) / sample.pdf;
        return E;
    }
    return 0.0;
}

compute_dielectric_E_avg :: (roughness: float, cosine: float, ior: float, p: float, u: Vector2) -> float
{
    E := compute_dielectric_E(roughness, cosine, ior, p, u);
    return 2.0 * cosine * E;
}

compute_dielectric_inv_E :: (roughness: float, cosine: float, ior: float, p: float, u: Vector2) -> float
{
    inv_ior := 1.0 / ior;
    return compute_dielectric_E(roughness, cosine, inv_ior, p, u);
}

compute_dielectric_inv_E_avg :: (roughness: float, cosine: float, ior: float, p: float, u: Vector2) -> float
{
    E := compute_dielectric_inv_E(roughness, cosine, ior, p, u);
    return 2.0 * cosine * E;
}

compute_dielectric_full_E :: (roughness: float, cosine: float, ior: float, p: float, u: Vector2) -> float
{
    alpha  := microfacet_alpha(roughness, 0.0);
    if microfacet_is_delta(alpha) return 1.0;
    sine   := sqrt(1.0 - cosine * cosine);
    V      := Vector3.{sine, 0.0, cosine};
    H      := microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
    F      := fresnel_dielectric(ior, dot(V, H));

    if (p >= F)
    {
        L, refracted := refract(-V, H, ior);
        if (refracted)
        {
            btdf := evaluate_ggx_specular_refract(V, L, H, alpha, ior);
            f    := btdf.f / (ior * ior);
            pdf  := btdf.pdf;
            E    := f.x * abs(L.z) / pdf;
            return E;
        }
        else
        {
            F = 1.0;
        }
    }

    L := reflect(-V, H);
    if (L.z > 0.0)
    {
        brdf := evaluate_ggx_specular_reflect(V, L, H, alpha);
        f    := brdf.f;
        pdf  := brdf.pdf;
        E    := f.x * abs(L.z) / pdf;
        return E;
    }

    return 0.0;
}

compute_dielectric_full_E_avg :: (roughness: float, cosine: float, ior: float, p: float, u: Vector2) -> float
{
    E := compute_dielectric_full_E(roughness, cosine, ior, p, u);
    return 2.0 * cosine * E;
}

compute_dielectric_full_inv_E :: (roughness: float, cosine: float, ior: float, p: float, u: Vector2) -> float
{
    inv_ior := 1.0 / ior;
    return compute_dielectric_full_E(roughness, cosine, inv_ior, p, u);
}

compute_dielectric_full_inv_E_avg :: (roughness: float, cosine: float, ior: float, p: float, u: Vector2) -> float
{
    E := compute_dielectric_full_inv_E(roughness, cosine, ior, p, u);
    return 2.0 * cosine * E;
}

//------------------------------------------------------------------------
// Compute

Compute_Proc :: #type (x: float, y: float, z: float, p: float, u: Vector2) -> float;

Compute_Work :: struct
{
    dim_z     : int;
    dim_y     : int;
    dim_x     : int;
    n_samples : int;
    sample_it : int;
    data      : []float;
    proc      : Compute_Proc;
    name      : string;
    compute   : bool;
}

compute_queue : [..]Compute_Work;

push_work :: (proc: Compute_Proc, n: int, x: int, y: int, z: int, name: string)
{
    work: Compute_Work;
    work.dim_z     = z;
    work.dim_y     = y;
    work.dim_x     = x;
    work.n_samples = n;
    work.sample_it = 0;
    work.proc      = proc;
    work.name      = name;
    work.compute   = false;
    array_resize(*work.data, x * y * z);
    array_add(*compute_queue, work);
}

hash :: (x: int, y: int) -> u32
{
    xh := murmur_finalize32(x.(u32));
    yh := murmur_finalize32(y.(u32));
    return hash_combine(xh, yh);
}

execute :: ()
{
    threads: []Thread;
    array_resize(*threads, max(1, get_number_of_processors() - 1));

    for * threads
    {
        thread_init(it, compute_thread);
        it.data = it_index.(*void);
        thread_start(it);
    }

    for * threads
    {
        thread_is_done(it, -1);
        thread_deinit(it);
    }

    now   := current_time_consensus();
    local := to_calendar(now, .LOCAL);
    date  := calendar_to_string(local);

    for compute_queue
    {
        if !it.compute continue;

        uname := to_upper_copy(it.name);

        print("// Generated at % by ms_gen_table.exe\n", date);

        n_dim := 1;

        if (it.dim_z != 1 && it.dim_z != it.dim_x)
        {
            print("%_SIZE_Z : s32 : %;\n", uname, it.dim_z);
            n_dim += 1;
        }

        if (it.dim_y != 1 && it.dim_y != it.dim_x)
        {
            print("%_SIZE_Y : s32 : %;\n", uname, it.dim_y);
            n_dim += 1;
        }

        if (n_dim == 1)
        {
            print("%_SIZE : s32 : %;\n", uname, it.dim_x);
        }
        else
        {
            print("%_SIZE_X : s32 : %;\n", uname, it.dim_x);
        }

        print("% : [%]float : .[\n", it.name, it.data.count);

        for value,index: it.data
        {
            print("%,", FormatFloat.{value=value, width=8, zero_removal=.NO});
            if ((index + 1) % it.dim_x == 0)
            {
                print("\n");
            }
        }
        print("];\n\n");
    }

    array_reset(*compute_queue);
}

compute_thread :: (thread: *Thread) -> s64
{
    thread_index := thread.data.(int);

    for * compute_queue
    {
        if !it.compute continue;

        if (thread_index == 0)
        {
            print("// Computing % ... ", it.name);
        }

        while (true)
        {
            index := atomic_add(*it.sample_it, 1);
            if (index >= it.data.count)
                break;

            z    := index / (it.dim_x * it.dim_y);
            a    := index % (it.dim_x * it.dim_y);
            y    := a / it.dim_x;
            x    := a % it.dim_x;

            seed := hash(x, y);
            acc  : float64 = 0.0;

            for sample:0..it.n_samples-1
            {
                random    := sample_random_4D(sample.(u32), seed);

                roughness := ifx it.dim_x > 1 then x.(float) / (it.dim_x - 1).(float) else 0.0;
                cosine    := ifx it.dim_y > 1 then y.(float) / (it.dim_y - 1).(float) else random.z;
                t         := ifx it.dim_z > 1 then z.(float) / (it.dim_z - 1).(float) else 0.0;

                roughness  = clamp(roughness, 1.0e-4, 1.0);
                cosine     = clamp(cosine, 1.0e-4, 1.0);
                t          = clamp(t, 1.0e-4, 0.999999);
                ior       := ior_parametrization(t);
                p         := random.w;

                E := it.proc(roughness, cosine, ior, p, random.xy);
                acc += E.(float64);
            }

            it.data[index] = saturate(acc / it.n_samples.(float64)).(float);
        }

        if (thread_index == 0)
        {
            print("Done.\n", it.name);
        }
    }

    return 0;
}

#load "microfacet.jai";
#load "fresnel.jai";
#load "surface.jai";

#import "PathNoise";
#import "Hashing";

#import "Atomics";
#import "Basic";
#import "File";
#import "String";
#import "System";
#import "Thread";
#import "Math";

