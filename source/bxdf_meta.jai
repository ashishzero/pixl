#load "async.jai";
#load "common.jai";
#load "noise.jai";
#load "microfacet.jai";

compute_metallic_k_ms_table :: ()
{
    wave: Thread_Wave;
    thread_wave_start(*wave, compute_metallic_k_ms_lut_thread, used_threads = 4);
    thread_wave_join(*wave);
}

compute_metallic_E_avg_table :: ()
{
    wave: Thread_Wave;
    thread_wave_start(*wave, compute_metallic_E_avg_lut_thread, used_threads = 4);
    thread_wave_join(*wave);
}

dump_computed_tables :: (path: string)
{
    write_entire_file(path, *shared_builder);
}

#scope_file

sample_brdf :: (V: Vector3, roughness: float, anisotropic: float, u: Vector2) -> float
{
    roughness  = max(roughness, 1.0e-4);
    alpha     := microfacet_alpha(roughness, anisotropic);
    H         := microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
    L         := reflect(V, H);
    NoV       := V.z;
    NoL       := L.z;
    G         := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
    G1        := microfacet_ggx_mask(NoV, alpha);
    fr        := G / max(G1, 1.0e-6);
    return fr;
}

METALLIC_K_MS_LUT_SIZE      :: 32;
METALLIC_E_AVG_LUT_SIZE     :: 32;
METALLIC_K_MS_SAMPLE_COUNT  :: 1 << 24;
METALLIC_E_AVG_SAMPLE_COUNT :: 1 << 26;

MAX_BUFFER_SIZE   :: #run -> int
{
    N := METALLIC_K_MS_LUT_SIZE * METALLIC_K_MS_LUT_SIZE;

    if (METALLIC_E_AVG_LUT_SIZE * METALLIC_E_AVG_LUT_SIZE > N)
    {
        N = METALLIC_E_AVG_LUT_SIZE * METALLIC_E_AVG_LUT_SIZE;
    }

    return N;
}

//------------------------------------------------------------------------
shared_index   : int;
shared_buffer  : [MAX_BUFFER_SIZE]float;
shared_builder : String_Builder;

compute_metallic_k_ms_lut_thread :: (thread: *Thread) -> s64
{
    sync_and_reset("\rComputing metallic k ms...");

    while (true)
    {
        captured_index := atomic_add(*shared_index, 1);
        if (captured_index >= METALLIC_K_MS_LUT_SIZE * METALLIC_K_MS_LUT_SIZE)
        {
            break;
        }

        print("\rComputing metallic k ms... %\%", captured_index * 100 / (METALLIC_K_MS_LUT_SIZE * METALLIC_K_MS_LUT_SIZE - 1));

        y  := captured_index / METALLIC_K_MS_LUT_SIZE;
        x  := captured_index % METALLIC_K_MS_LUT_SIZE;

        E_ss  : float64 = 0.0;
        seed  := hash_combine(murmur_finalize32(x.(u32)), murmur_finalize32(y.(u32)));
        index := y * METALLIC_K_MS_LUT_SIZE + x;

        for 0..METALLIC_K_MS_SAMPLE_COUNT-1
        {
            u1        := sample_scrambled_sobol(it.(u32), seed, 0);
            u2        := sample_scrambled_sobol(it.(u32), seed, 1);
            cosine    := x.(float) / (METALLIC_K_MS_LUT_SIZE - 1).(float);
            sine      := sqrt(1.0 - cosine * cosine);
            roughness := y.(float) / (METALLIC_K_MS_LUT_SIZE - 1).(float);
            V         := Vector3.{sine, 0.0, cosine};
            E_ss      += sample_brdf(V, roughness, 0.0, .{u1, u2});
        }
        E_ss  = saturate(E_ss / METALLIC_K_MS_SAMPLE_COUNT.(float64));
        k_ms := (1.0 - E_ss) / E_ss;
        shared_buffer[index] = k_ms.(float);
    }

    sync_and_reset();

    if (context.lane.index == 0)
    {
        print("\nDone\n");
        print_to_builder(*shared_builder, "METALLIC_K_MS_LUT_SIZE :: %;\n\n", METALLIC_K_MS_LUT_SIZE);
        print_to_builder(*shared_builder, "k_ms_metallic : [METALLIC_K_MS_LUT_SIZE * METALLIC_K_MS_LUT_SIZE]float : .[\n");

        for y:0..METALLIC_K_MS_LUT_SIZE-1
        {
            for x:0..METALLIC_K_MS_LUT_SIZE-1
            {
                value := *shared_buffer[y * METALLIC_K_MS_LUT_SIZE + x];
                print_to_builder(*shared_builder, "0h%,", FormatInt.{value=value.(*u32).*, base=16, minimum_digits=8});
                if ((x + 1) % 16 == 0)
                {
                    print_to_builder(*shared_builder, "\n");
                }
            }
        }
        print_to_builder(*shared_builder, "];\n\n");
    }

    return 0;
}

compute_metallic_E_avg_lut_thread :: (thread: *Thread) -> s64
{
    sync_and_reset("\rComputing metallic E avg...");

    while (true)
    {
        captured_index := atomic_add(*shared_index, 1);
        if (captured_index >= METALLIC_E_AVG_LUT_SIZE)
        {
            break;
        }

        print("\rComputing metallic E avg... %\%", captured_index * 100 / (METALLIC_E_AVG_LUT_SIZE - 1));

        x  := captured_index;

        E_avg : float64 = 0.0;
        seed  := murmur_finalize32(x.(u32));
        index := x;

        for 0..METALLIC_E_AVG_SAMPLE_COUNT-1
        {
            u1        := sample_scrambled_sobol(it.(u32), seed, 0);
            u2        := sample_scrambled_sobol(it.(u32), seed, 1);
            u3        := sample_scrambled_sobol(it.(u32), seed, 2);
            cosine    := u3;
            sine      := sqrt(1.0 - cosine * cosine);
            roughness := x.(float) / (METALLIC_E_AVG_LUT_SIZE - 1).(float);
            V         := Vector3.{sine, 0.0, cosine};
            E_avg     += 2.0 * sample_brdf(V, roughness, 0.0, .{u1, u2});
        }
        E_avg  = saturate(E_avg / METALLIC_E_AVG_SAMPLE_COUNT.(float64));
        shared_buffer[index] = E_avg.(float);
    }

    sync_and_reset();

    if (context.lane.index == 0)
    {
        print("\nDone\n");
        print_to_builder(*shared_builder, "METALLIC_E_AVG_LUT_SIZE :: %;\n\n", METALLIC_E_AVG_LUT_SIZE);
        print_to_builder(*shared_builder, "E_avg_metallic : [METALLIC_E_AVG_LUT_SIZE]float : .[\n");

        for x:0..METALLIC_E_AVG_LUT_SIZE-1
        {
            value := *shared_buffer[x];
            print_to_builder(*shared_builder, "0h%,", FormatInt.{value=value.(*u32).*, base=16, minimum_digits=8});
            if ((x + 1) % 16 == 0)
            {
                print_to_builder(*shared_builder, "\n");
            }
        }
        print_to_builder(*shared_builder, "];\n\n");
    }

    return 0;
}

sync_and_reset :: ($msg: string = "")
{
    lane_sync();
    if (context.lane.index == 0)
    {
        atomic_write(*shared_index, 0);
        if (msg.count)
        {
            print(msg);
        }
    }
    lane_sync();
}

#import "Atomics";
#import "Basic";
#import "File";
