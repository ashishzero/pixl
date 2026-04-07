
main :: ()
{
    push_work(compute_conductor_E, 1 << 23, 32, 32, 1, "conductor_E");
    push_work(compute_conductor_E_avg, 1 << 26, 32, 1, 1, "conductor_E_avg");

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
                print("Computes:\n    ");
                print(compute_queue[0].name);
                for 1..compute_queue.count-1
                {
                    print(", %", compute_queue[it].name);
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

average :: inline (s: Spectrum) -> float
{
    return (s.x + s.y + s.z) / 3.0;
}

compute_conductor_E :: (roughness: float, cosine: float, ior: float, u: Vector3) -> float
{
    alpha := microfacet_alpha(roughness, 0.0);
    surface := Surface.{
        color            = .{1, 1, 1},
        roughness        = 0.0,
        ior              = ior,
        specular         = 0.0,
        metallic         = 1.0,
        fresnel          = .{.{1, 1, 1}, .{1, 1, 1}},
        microfacet_alpha = alpha,
        transmission     = 0.0,
        opacity          = 1.0,
        absorption       = .{0, 0, 0},
        emission         = .{0, 0, 0}
    };

    sine := sqrt(1.0 - cosine * cosine);
    V    := Vector3.{sine, 0.0, cosine};

    sample := sample_conductor(V, surface, u);
    if (sample.pdf > 0.0)
    {
        E := average(sample.f) * abs(sample.L.z) / sample.pdf;
        return E;
    }

    return 0.0;
}

compute_conductor_E_avg :: (roughness: float, cosine: float, ior: float, u: Vector3) -> float
{
    E := compute_conductor_E(roughness, cosine, ior, u);
    return 2.0 * cosine * E;
}

//------------------------------------------------------------------------
// Compute

Compute_Proc :: #type (x: float, y: float, z: float, u: Vector3) -> float;

Compute_Work :: struct
{
    z       : int;
    y       : int;
    x       : int;
    n       : int;
    si      : int;
    data    : []float;
    proc    : Compute_Proc;
    name    : string;
    compute : bool;
}

compute_queue : [..]Compute_Work;

push_work :: (proc: Compute_Proc, n: int, x: int, y: int, z: int, name: string)
{
    work: Compute_Work;
    work.z       = z;
    work.y       = y;
    work.x       = x;
    work.n       = n;
    work.si      = 0;
    work.proc    = proc;
    work.name    = name;
    work.compute = false;
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

        if (it.z == 1)
        {
            if (it.x == it.y || it.y == 1)
            {
                print("%_SIZE : u32 : %;\n", uname, it.x);
            }
            else
            {
                print("%_SIZE_X : u32 : %;\n", uname, it.x);
                print("%_SIZE_Y : u32 : %;\n", uname, it.y);
            }
        }
        else
        {
            print("%_SIZE_X : u32 : %;\n", uname, it.x);
            print("%_SIZE_Y : u32 : %;\n", uname, it.y);
            print("%_SIZE_Z : u32 : %;\n", uname, it.z);
        }

        print("% : [%]float : .[\n", it.name, it.data.count);

        for value,index: it.data
        {
            print("%,", FormatFloat.{value=value, width=8, zero_removal=.NO});
            if ((index + 1) % it.x == 0)
            {
                print("\n");
            }
            if ((index + 1) % it.y == 0 && it.z > 1)
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
            index := atomic_add(*it.si, 1);
            if (index >= it.data.count)
                break;

            z    := index / (it.x * it.y);
            a    := index % (it.x * it.y);
            y    := a / it.x;
            x    := a % it.x;

            seed := hash(x, y);
            acc  : float64 = 0.0;

            for sample:0..it.n-1
            {
                random    := sample_random_4D(sample.(u32), seed);

                roughness := ifx it.x > 1 then x.(float) / (it.x - 1).(float) else 0.0;
                cosine    := ifx it.y > 1 then y.(float) / (it.y - 1).(float) else random.w;
                ior       := ifx it.z > 1 then z.(float) / (it.z - 1).(float) else 0.0;

                roughness = clamp(roughness, 1.0e-4, 1.0);
                cosine    = clamp(cosine, 1.0e-4, 1.0);
                ior       = clamp(ior, 0.0, 1.0);

                E := it.proc(roughness, cosine, ior, random.xyz);
                acc += E.(float64);
            }

            it.data[index] = saturate(acc / it.n.(float64)).(float);
        }

        if (thread_index == 0)
        {
            print("Done.\n", it.name);
        }
    }

    return 0;
}

#import "BxDF"()(PRESERVE_MS_ENERGY=false);
#import "PathNoise";
#import "Hashing";

#import "Atomics";
#import "Basic";
#import "File";
#import "String";
#import "System";
#import "Thread";
#import "Math";

