
N_VIEWS   :: 32;
N_SAMPLES :: 16384;

BSDF_Test_State :: enum u32
{
    WAIT;
    SKIPPED;
    PASSED;
    FAILED;
}

BSDF_Test_Type :: enum u32
{
    complete;
    pdf_consistency;
    energy_conservation;
    reciprocity;
}

BSDF_Test :: struct
{
    name       : string;
    desc       : string;
    surface    : Surface;
    lobe_type  : Lobe_Type;
    principled : bool;
    state      : BSDF_Test_State;
}

BSDF_Test_Config :: struct
{
    prefix      : string;
    type        : BSDF_Test_Type;
    num_threads : int;
    list        : bool;
}

main :: ()
{
    success, config := parse_arguments(BSDF_Test_Config);
    if !success return;

    test("diffuse", "", create_diffuse_surface(Spectrum_One, 0.7), .DIFFUSE);

    N_ROUGHNESS :: 8;

    {
        // K-C energy compensation can overshoot at high roughness
        // See: https://blog.selfshadow.com/2018/06/04/multi-faceted-part-2/
        // So test is only performed for roughness: [0, 0.5]

        for 0..N_ROUGHNESS-1
        {
            roughness := 0.5 * it.(float) / (N_ROUGHNESS-1).(float);
            name      := sprint("conductor_gold_%", it+1);
            desc      := sprint("roughness: %", FormatFloat.{value=roughness, zero_removal=.NO, width=3, trailing_width=1});
            test(name, desc, create_conductor_surface(.{1.0, 0.86, 0.57}, roughness, 0.0, tint=.{1.0, 1.0, 0.9}), .CONDUCTOR);
        }

        for 0..N_ROUGHNESS-1
        {
            roughness := 0.5 * it.(float) / (N_ROUGHNESS-1).(float);
            name      := sprint("conductor_silver_%", it+1);
            desc      := sprint("roughness: %", FormatFloat.{value=roughness, zero_removal=.NO, width=3, trailing_width=1});
            test(name, desc, create_conductor_surface(.{0.98, 0.97, 0.95}, roughness, 0.0, tint=.{1.0, 1.0, 1.0}), .CONDUCTOR);
        }

        for 0..N_ROUGHNESS-1
        {
            roughness := 0.5 * it.(float) / (N_ROUGHNESS-1).(float);
            name      := sprint("conductor_perfect_reflector_%", it+1);
            desc      := sprint("roughness: %", FormatFloat.{value=roughness, zero_removal=.NO, width=3, trailing_width=1});
            test(name, desc, create_conductor_surface(Spectrum_One, roughness, 0.0), .CONDUCTOR);
        }
    }

    run_tests(config);
}

#scope_file

//------------------------------------------------------------------------
// Helper functions

create_diffuse_surface :: (color: Spectrum, roughness: float, opacity := 1.0) -> Surface
{
    surface := Surface.{
        color             = color,
        diffuse_roughness = roughness,
        specular_ior      = 1.5,
        opacity           = opacity,
    };
    return surface;
}

create_conductor_surface :: (color: Spectrum, roughness: float, anisotropic: float, tint := Spectrum_One) -> Surface
{
    alpha   := microfacet_alpha(roughness, anisotropic);
    surface := Surface.{
        color             = color,
        diffuse_roughness = roughness,
        specular_ior      = 1.5,
        reflectance       = color,
        edge_tint         = tint,
        falloff           = Spectrum_Zero,
        opacity           = 1.0,
        metallic          = 1.0,
        microfacet_alpha  = alpha,
    };
    return surface;
}

//------------------------------------------------------------------------
// Test Utility

BSDF_Test_Context :: struct
{
    n_passed : int;
    n_failed : int;
    dump     : *String_Builder;
}

bsdf_tests            : [..]BSDF_Test;
bsdf_test_index       : int;
#add_context bsdf_test: BSDF_Test_Context;

test :: (name: string, desc: string, surface: Surface, type: Lobe_Type)
{
    array_add(*bsdf_tests, .{name=name, desc=desc, surface=surface, lobe_type=type, principled=false});
}

test :: (name: string, desc: string, surface: Surface)
{
    array_add(*bsdf_tests, .{name=name, desc=desc, surface=surface, lobe_type=.DIFFUSE, principled=true});
}

run_tests :: (config: BSDF_Test_Config)
{
    quick_sort(bsdf_tests, (a, b) => compare(a.name, b.name));

    if config.list
    {
        print("Test Lists:\n");
        for * bsdf_tests
        {
            print("   [%] %\n", it_index + 1, it.name);
        }
        print("\n");
        return;
    }

    n_threads := config.num_threads;

    if !n_threads
    {
        n_threads = max(1, min(bsdf_tests.count, get_number_of_processors() - 1));
    }

    print("Starting % threads...\n", n_threads);

    test_thread :: (thread: *Thread) -> s64
    {
        config := thread.data.(*BSDF_Test_Config).*;
        prefix := trim(config.prefix);

        run_pdf_consistency := (config.type == .complete || config.type == .pdf_consistency);
        run_e_conversation  := (config.type == .complete || config.type == .energy_conservation);
        run_reciprocity     := (config.type == .complete || config.type == .reciprocity);

        while (true)
        {
            it := atomic_add(*bsdf_test_index, 1);
            if (it >= bsdf_tests.count)
                break;

            test := *bsdf_tests[it];

            if prefix
            {
                if !starts_with(test.name, prefix)
                {
                    test.state = .SKIPPED;
                    continue;
                }
            }

            fmt_surface := FormatStruct.{
                value=test.surface,
                draw_type_name=true,
                use_long_form_if_more_than_this_many_members=-1,
                use_newlines_if_long_form=true
            };
            info("=== Test %\n%\n", test.name, fmt_surface);

            n_failed := 0;

            if run_pdf_consistency
            {
                context.bsdf_test.n_passed = 0;
                context.bsdf_test.n_failed = 0;

                info("> Running % (pdf consistency test)...", test.name);
                if test.principled
                {
                    pdf_consistency_test(test.surface, test.lobe_type, true);
                }
                else
                {
                    pdf_consistency_test(test.surface, test.lobe_type, false);
                }

                info("  PASSED : %", context.bsdf_test.n_passed);
                info("  FAILED : %", context.bsdf_test.n_failed);
                info("==================================\n");
                flush();

                n_failed += context.bsdf_test.n_failed;
            }

            if run_e_conversation
            {
                context.bsdf_test.n_passed = 0;
                context.bsdf_test.n_failed = 0;

                info("> Running % (energy conservation test)...", test.name);
                if test.principled
                {
                    energy_conservation_test(test.surface, test.lobe_type, true);
                }
                else
                {
                    energy_conservation_test(test.surface, test.lobe_type, false);
                }

                info("  PASSED : %", context.bsdf_test.n_passed);
                info("  FAILED : %", context.bsdf_test.n_failed);
                info("==================================\n");
                flush();

                n_failed += context.bsdf_test.n_failed;
            }

            if run_reciprocity
            {
                context.bsdf_test.n_passed = 0;
                context.bsdf_test.n_failed = 0;

                info("> Running % (reciprocity test)...", test.name);
                if test.principled
                {
                    reciprocity_test(test.surface, test.lobe_type, true);
                }
                else
                {
                    reciprocity_test(test.surface, test.lobe_type, false);
                }

                info("  PASSED : %", context.bsdf_test.n_passed);
                info("  FAILED : %", context.bsdf_test.n_failed);
                info("==================================\n");
                flush();

                n_failed += context.bsdf_test.n_failed;
            }

            test.state = ifx n_failed == 0 then .PASSED else .FAILED;
        }

        return 0;
    }

    threads: []Thread;
    array_resize(*threads, n_threads);
    defer array_free(threads);

    for * threads
    {
        thread_init(it, test_thread);
        it.data = *config;
        thread_start(it);
    }

    for * threads
    {
        thread_is_done(it, -1);
        thread_deinit(it);
    }

    print_test_summary();
}

print_test_summary :: ()
{
    MAX_TITLE :: 50;

    print("\n");
    print("*******************************");
    print(" summary ");
    print("*******************************");
    print("\n");

    for bsdf_tests
    {
        if (it.state == .SKIPPED) continue;
        title := ifx it.desc.count then tprint("% (%)", it.name, it.desc) else it.name;
        len   := min(title.count, MAX_TITLE);
        print(" % ", slice(title, 0, len));
        for len..MAX_TITLE
        {
            print(".");
        }
        print("...... %\n", ifx it.state == .PASSED then "\e[32mPASSED\e[0m" else "\e[31mFAILED\e[0m");
    }

    print("*******************************");
    print("*********");
    print("*******************************");
    print("\n\n");
}

init_dump :: inline ()
{
    if !context.bsdf_test.dump
    {
        context.bsdf_test.dump = New(String_Builder);
    }
}

info :: ($format_string: string, args: ..Any)
{
    init_dump();
    print_to_builder(context.bsdf_test.dump, format_string, ..args);
    print_to_builder(context.bsdf_test.dump, "\n");
}

error :: ($format_string: string, args: ..Any)
{
    init_dump();
    print_to_builder(context.bsdf_test.dump, "\e[31m");
    print_to_builder(context.bsdf_test.dump, "ERROR: ");
    print_to_builder(context.bsdf_test.dump, format_string, ..args);
    print_to_builder(context.bsdf_test.dump, "\e[0m");
    print_to_builder(context.bsdf_test.dump, "\n");
}

flush :: ()
{
    if (context.bsdf_test.dump)
    {
        str := builder_to_string(context.bsdf_test.dump);
        print("%", str);
        free(str);
    }
}

assert_true :: (expr: bool, $fmt: string, args: ..Any)
{
    if (expr)
    {
        context.bsdf_test.n_passed += 1;
    }
    else
    {
        context.bsdf_test.n_failed += 1;
        error(fmt, ..args);
    }
}

assert_bsdf :: (bsdf: BSDF, V: Vector3, L: Vector3)
{
    if (isnan(bsdf.f.x) || isnan(bsdf.f.y) || isnan(bsdf.f.z) || isnan(bsdf.pdf) ||
        isinf(bsdf.f.x) || isinf(bsdf.f.y) || isinf(bsdf.f.z) || isinf(bsdf.pdf))
    {
        assert_true(false, "NaN/Inf detected: f=% pdf=% for V=%, L=%", bsdf.f, bsdf.pdf, V, L);
    }

    if (bsdf.f.x < 0.0 || bsdf.f.y < 0.0 || bsdf.f.z < 0.0 || bsdf.pdf < 0.0)
    {
        assert_true(false, "Negative BSDF: f=% pdf=% for V=%, L=%", bsdf.f, bsdf.pdf, V, L);
    }

    if (bsdf.pdf == 0.0)
    {
        if (bsdf.f.x > 0.0 || bsdf.f.y > 0.0 || bsdf.f.z > 0.0)
        {
            assert_true(false, "Non-zero f with zero pdf: f=% pdf=% for V=%, L=%", bsdf.f, bsdf.pdf, V, L);
        }
    }
}

assert_sample :: (sample: Sampled_BSDF, V: Vector3)
{
    assert_bsdf(sample.bsdf, sample.L, V);

    L := sample.L;

    if (isnan(L.x) || isnan(L.y) || isnan(L.z) ||
        isinf(L.x) || isinf(L.y) || isinf(L.z))
    {
        assert_true(false, "NaN/Inf detected: L=%", L);
    }

    if (abs(L.x) < 1.0e-6 && abs(L.y) < 1.0e-6 && abs(L.z) < 1.0e-6)
    {
        assert_true(false, "L is close to zero: L=%", L);
    }
}

//------------------------------------------------------------------------
// Test Procedures

pdf_consistency_test :: (surface: Surface, type: Lobe_Type, $principled: bool)
{
    // Skip perfectly smooth conductors as PDF returned is zero
    if !principled && type == .CONDUCTOR && microfacet_is_delta(surface.microfacet_alpha)
    {
        return;
    }

    seed1 := random_get();
    seed2 := random_get();

    for 0..N_SAMPLES-1
    {
        p     := sample_random_2D(it.(u32), seed1.(u32, no_check));
        u     := sample_random_4D(it.(u32), seed2.(u32, no_check));
        V     := sample_uniform(p.x, p.y);

        #if principled
        {
            sample := sample_principled(V, surface, u.w, .{u.x, u.y, u.z});
        }
        else
        {
            sample := sample_principled_lobe(V, surface, .{u.x, u.y, u.z}, type);
        }

        // Skip grazing angles
        if (V.z < 1.0e-4 || sample.L.z < 1.0e-4)
            continue;

        if (sample.pdf > 0.0)
        {
            #if principled
                bsdf := evaluate_principled(V, sample.L, surface);
            else
                bsdf := evaluate_principled_lobe(V, sample.L, surface, type);

            assert_sample(sample, V);
            assert_bsdf(bsdf, V, sample.L);

            if ((sample.pdf == 0.0) != (bsdf.pdf == 0.0))
            {
                assert_true(false,
                            "PDF zero mismatch: V=%, L=% (sampled=%, evaluated=%)",
                            V, sample.L, sample.pdf, bsdf.pdf);
            }

            diff      := abs(bsdf.pdf - sample.pdf) / max(abs(bsdf.pdf), abs(sample.pdf), 1.0e-6);
            tolerance := 0.003;

            assert_true(diff <= tolerance,
                        "PDF Consistency failed: V: %, L: %, sampled: %, evaluated: %, diff: %",
                        V, sample.L, sample.pdf, bsdf.pdf, diff);
        }
    }
}

assert_energy_samples :: (samples: []float, V: Vector3, surface: Surface) -> float64
{
    n   := samples.count.(float64);
    sum : float64 = 0.0;

    for samples
    {
        sum += it;
    }

    mean := sum / n;
    sq_diff_sum : float64 = 0.0;

    for samples
    {
        diff := it - mean;
        sq_diff_sum += diff * diff;
    }

    variance := sq_diff_sum / (n - 1);
    std_dev  := sqrt(variance);
    std_err  := std_dev / sqrt(n);

    ABS_TOLERANCE :: 0.02;

    overshoot_tolerance := 0.0;

    angle_scale         := 1.0 / max(V.z, 0.1);
    tolerance           := max(3 * std_err, ABS_TOLERANCE * angle_scale);
    overshoot           := mean - 1.0;

    assert_true(overshoot <= tolerance,
                "Energy exceeded: mean % is above 1 + tolerance % for V: % (overshoot: %, std_err: %)",
                mean, tolerance, V, overshoot, std_err);

    UNDERFLOW :: 0.3;

    assert_true(mean >= 1.0 - UNDERFLOW,
                "Too much energy loss: mean % is below % for V: %",
                mean, 1.0 - UNDERFLOW, V);

    return mean;
}

energy_conservation_test :: (surface: Surface, type: Lobe_Type, $principled: bool)
{
    seed1 := random_get();
    seed2 := random_get();
    e_max := FLOAT32_MIN;
    e_min := FLOAT32_MAX;
    e_avg : float64 = 0.0;

    samples: []float;
    array_resize(*samples, N_SAMPLES);
    defer array_free(samples);

    for 0..N_VIEWS-1
    {
        p := sample_random_2D(it.(u32), seed1.(u32, no_check));
        V := sample_uniform(p.x, p.y);

        // Skip grazing angles
        if (V.z < 1.0e-1) continue;

        n_samples := 0;

        for 0..N_SAMPLES-1
        {
            u  := sample_random_4D(it.(u32), seed2.(u32, no_check));
            #if principled
            {
                sample := sample_principled(V, surface, u.w, .{u.x, u.y, u.z});
            }
            else
            {
                sample := sample_principled_lobe(V, surface, .{u.x, u.y, u.z}, type);
            }

            if (sample.L.z < 1.0e-4 || sample.pdf < 1.0e-4)
                continue;

            assert_sample(sample, V);

            cosine := abs(sample.L.z);
            f      := sample.f * cosine / sample.pdf;
            e      := (f.x + f.y + f.z) / 3.0;
            e_min   = min(e_min, e);
            e_max   = max(e_max, e);
            samples[n_samples] = e;
            n_samples += 1;
        }

        if (n_samples < 2) continue;
        e_avg += assert_energy_samples(array_view(samples, 0, n_samples), V, surface);
    }

    e_avg /= N_VIEWS.(float64);
    info("  Mean f: %, Max f: %, Min f: %", e_avg, e_max, e_min);
}

reciprocity_test :: (surface: Surface, type: Lobe_Type, $principled: bool)
{
    seed1 := random_get();
    seed2 := random_get();

    for 0..N_VIEWS-1
    {
        u := sample_random_2D(it.(u32), seed1.(u32, no_check));
        v := sample_random_2D(it.(u32), seed2.(u32, no_check));
            
        V := sample_uniform(v.x, v.y);
        L := sample_uniform(u.x, u.y);

        #if principled
        {
            bsdf1 := evaluate_principled(V, L, surface);
            bsdf2 := evaluate_principled(L, V, surface);
        }
        else
        {
            bsdf1 := evaluate_principled_lobe(V, L, surface, type);
            bsdf2 := evaluate_principled_lobe(L, V, surface, type);
        }

        assert_bsdf(bsdf1, V, L);
        assert_bsdf(bsdf2, V, L);

        f1        := bsdf1.f;
        f2        := bsdf2.f;
        diff      := abs(f1 - f2) / max(abs(f1), abs(f2));
        tolerance := 1.0e-6;

        assert_true(diff.x <= tolerance && diff.y <= tolerance && diff.z <= tolerance,
                    "Reciprocity failed: V: %, L: %, f(V, L): %, f(L, V): %, diff: %",
                    V, L, f1, f2, diff);
    }
}

//------------------------------------------------------------------------

#import "Atomics";
#import "Basic";
#import "File";
#import "Random";
#import "Math";
#import "Thread";
#import "String";
#import "System";
#import "Sort";
#import "Command_Line";

#import "PathNoise";
#import "BxDF"()(PRESERVE_MS_ENERGY=true);
