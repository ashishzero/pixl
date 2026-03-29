#load "async.jai";
#load "common.jai";
#load "noise.jai";
#load "microfacet.jai";
#load "bxdf_shared.jai";

main :: ()
{
    prepare_batch(compute_metallic_E, 1 << 24, 32, 32, 1, "metallic_E");
    prepare_batch(compute_metallic_E_avg, 1 << 26, 32, 1, 1, "metallic_E_avg");
    execute_batches("bxdf_gen_tables.jai");
}

//------------------------------------------------------------------------
// Compute Functions

compute_metallic_E :: (x: int, y: int, z: int, n_x: int, n_y: int, n_z: int, n_samples: int, seed: u32) -> float
{
    if (x == 0)
    {
        return 1.0;
    }

    cosine    := y.(float) / (n_y - 1).(float);
    sine      := sqrt(1.0 - cosine * cosine);
    V         := Vector3.{sine, 0.0, cosine};
    roughness := x.(float) / (n_x - 1).(float);
    alpha     := microfacet_alpha(roughness, 0.0);

    E_ss : float64 = 0.0;
    for 0..n_samples-1
    {
        u     := random_v4(it, seed);
        H     := microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
        L     := reflect(-V, H);
        if (L.z > 0.0)
        {
            brdf := f_specular_brdf(V, L, H, alpha);
            if (brdf.pdf >= FLOAT_EPS)
            {
                E_ss += brdf.f.x * abs(L.z) / brdf.pdf;
            }
        }
    }
    E_ss = saturate(E_ss / n_samples.(float64));
    return E_ss.(float);
}

compute_metallic_E_avg :: (x: int, y: int, z: int, n_x: int, n_y: int, n_z: int, n_samples: int, seed: u32) -> float
{
    if (x == 0)
    {
        return 1.0;
    }

    roughness := x.(float) / (n_x - 1).(float);
    alpha     := microfacet_alpha(roughness, 0.0);

    E_avg : float64 = 0.0;
    for 0..n_samples-1
    {
        u         := random_v4(it, seed);
        cosine    := u.z;
        sine      := sqrt(1.0 - cosine * cosine);
        V         := Vector3.{sine, 0.0, cosine};
        H         := microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
        L         := reflect(-V, H);
        if (L.z > 0.0)
        {
            brdf := f_specular_brdf(V, L, H, alpha);
            if (brdf.pdf >= FLOAT_EPS)
            {
                f := brdf.f.x * abs(L.z) / brdf.pdf;
                E_avg += 2.0 * cosine * f;
            }
        }
    }
    E_avg = saturate(E_avg / n_samples.(float64));
    return E_avg.(float);
}

//------------------------------------------------------------------------

random_v4 :: (index: int, seed: u32) -> Vector4
{
    u1 := sample_scrambled_sobol(index.(u32), seed, 0);
    u2 := sample_scrambled_sobol(index.(u32), seed, 1);
    u3 := sample_scrambled_sobol(index.(u32), seed, 2);
    u4 := sample_scrambled_sobol(index.(u32), seed, 3);
    u  := Vector4.{u1, u2, u3, u4};
    return u;
}

//------------------------------------------------------------------------
// Batch

batches: [..]Batch;

prepare_batch :: (proc: Batch_Proc, n_samples: int, n_x: int, n_y: int, n_z: int, name: string)
{
    batch: Batch;
    batch.n_z          = n_z;
    batch.n_y          = n_y;
    batch.n_x          = n_x;
    batch.n_samples    = n_samples;
    batch.shared_index = 0;
    batch.proc         = proc;
    batch.name         = name;
    array_resize(*batch.buffer, n_x * n_y * n_z);
    array_add(*batches, batch);
}

execute_batches :: (path: string)
{
    for * batches
    {
        wave: Thread_Wave;
        thread_wave_start(*wave, batch_execute_thread, shared = it, used_threads = 4);
        thread_wave_join(*wave);
    }

    builder: String_Builder;

    for batches
    {
        uname := to_upper_copy(it.name);
        n     := it.n_x * it.n_y * it.n_z;

        print_to_builder(*builder, "%_X_DIM :: %;\n", uname, it.n_x);
        print_to_builder(*builder, "%_Y_DIM :: %;\n", uname, it.n_y);
        print_to_builder(*builder, "%_Z_DIM :: %;\n\n", uname, it.n_z);

        print_to_builder(*builder, "% : [%]float : .[\n", it.name, n);
        for value,index: it.buffer
        {
            print_to_builder(*builder, "%,", FormatFloat.{value=value, width=8, zero_removal=.NO});
            if ((index + 1) % it.n_x == 0)
            {
                print_to_builder(*builder, "\n");
            }
        }
        print_to_builder(*builder, "];\n\n");

        free(uname);
        array_free(it.buffer);
    }

    array_reset(*batches);
    write_entire_file(path, *builder);
}

Batch_Proc :: #type (x: int, y: int, z: int, n_x: int, n_y: int, n_z: int, n_samples: int, seed: u32) -> float;

Batch :: struct
{
    n_z          : int;
    n_y          : int;
    n_x          : int;
    n_samples    : int;
    shared_index : int;
    buffer       : []float;
    proc         : Batch_Proc;
    name         : string;
}

batch_execute_thread :: (thread: *Thread) -> s64
{
    batch := thread.data.(*Batch);
    n_z   := batch.n_z;
    n_y   := batch.n_y;
    n_x   := batch.n_x;

    n := n_x * n_y * n_z;

    while (true)
    {
        index := atomic_add(*batch.shared_index, 1);
        if (index >= n)
        {
            break;
        }

        percent := (index * 100) / n;
        print("\rComputing % ... %\%", batch.name, percent);

        z := index / (n_x * n_y);
        a := index % (n_x * n_y);
        y := a / n_x;
        x := a % n_x;

        seed := hash_combine(
                hash_combine(murmur_finalize32(x.(u32)),
                             murmur_finalize32(y.(u32))),
                murmur_finalize32(z.(u32)));
        batch.buffer[index] = batch.proc(x, y, z, n_x, n_y, n_z, batch.n_samples, seed);
    }

    if (context.lane.index == 0)
    {
        print("\rComputing % ... 100\%\n", batch.name);
    }

    return 0;
}

#import "Atomics";
#import "Basic";
#import "File";
#import "String";
