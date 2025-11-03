#load "async.jai";
#load "common.jai";
#load "noise.jai";
#load "microfacet.jai";

compute_metallic_brdf_lookup_tables :: ()
{
    wave: Thread_Wave;
    thread_wave_start(*wave, compute_metallic_brdf_lookup_tables_thread, used_threads = 4);
    thread_wave_join(*wave);
}

#scope_file

N :: 32;
NUM_SAMPLES :: 1 << 20;

Compute_BxDF_Lookup_Table_Shared :: struct
{
    index          : int;
    Er_metallic    : [N * N * N]float;
}

shared: Compute_BxDF_Lookup_Table_Shared;

sync_and_reset :: ($msg: string = "")
{
    lane_sync();
    if (context.lane.index == 0)
    {
        atomic_write(*shared.index, 0);
        if (msg.count)
        {
            print(msg);
        }
    }
    lane_sync();
}

compute_metallic_brdf_lookup_tables_thread :: (thread: *Thread) -> s64
{
    //------------------------------------------------------------------------
    // Metallic

    sync_and_reset("\rComputing metallic E table...");

    while (true)
    {
        BIAS :: 1.0e-6;

        captured_index := atomic_add(*shared.index, 1);
        if (captured_index >= N * N * N) then break;

        print("\rComputing metallic E table... %\%", captured_index * 100 / (N * N * N - 1));

        z  := captured_index / (N * N);
        zr := captured_index % (N * N);
        y  := zr / N;
        x  := zr % N;

        E_sum : float64 = 0.0;
        seed  := hash_combine(hash_combine(murmur_finalize32(x.(u32)), murmur_finalize32(y.(u32))), murmur_finalize32(z.(u32)));
        index := z * N * N + y * N + x;

        for 0..NUM_SAMPLES-1
        {
            u1        := sample_scrambled_sobol(it.(u32), seed, 0);
            u2        := sample_scrambled_sobol(it.(u32), seed, 1);
            u3        := sample_scrambled_sobol(it.(u32), seed, 2);

            cosine    := max(BIAS, x.(float) / (N - 1).(float));
            sine      := sqrt(1.0 - cosine * cosine);
            alpha_x   := max(BIAS, y.(float) / (N - 1).(float));
            alpha_y   := z.(float) / (N - 1).(float);
            V         := Vector3.{sine, 0.0, cosine};
            E_sum     += microfacet_ggx_brdf_cosine(normalize(V), .{alpha_x, alpha_y}, .{u1, u2});
        }
        E := saturate((E_sum / NUM_SAMPLES.(float64)).(float));
        shared.Er_metallic[index] = 1.0 - E;
    }

    sync_and_reset();

    if (context.lane.index == 0)
    {
        print("\nDone\n");

        builder: String_Builder;

        print_to_builder(*builder, "BxDF_LOOKUP_TABLE_SIZE :: %;\n\n", N);

        print_to_builder(*builder, "Er_metallic : [BxDF_LOOKUP_TABLE_SIZE * BxDF_LOOKUP_TABLE_SIZE * BxDF_LOOKUP_TABLE_SIZE]float : .[\n");
        for z:0..N-1
        {
            for y:0..N-1
            {
                for x:0..N-1
                {
                    value := *shared.Er_metallic[z * N * N + y * N + x];
                    print_to_builder(*builder, "0h%,", FormatInt.{value=value.(*u32).*, base=16, minimum_digits=8});
                    if ((x + 1) % 16 == 0)
                    {
                        print_to_builder(*builder, "\n");
                    }
                }
            }
        }
        print_to_builder(*builder, "];\n\n");
        write_entire_file("source/bxdf_metallic_lookup.jai", *builder);
    }

    return 0;
}

#import "Atomics";
#import "Basic";
#import "File";
