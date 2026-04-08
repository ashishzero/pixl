
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
    pdf_integration;
    energy_integration;
    reciprocity;
}

BSDF_Test :: struct
{
    name       : string;
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

    test("diffuse", create_diffuse_surface(Spectrum_One, 0.7), .DIFFUSE);

    N_ROUGHNESS :: 8;

    for 0..N_ROUGHNESS-1
    {
        roughness := it.(float) / (N_ROUGHNESS-1).(float);
        test(tprint("conductor_%", it+1), create_conductor_surface(Spectrum_One, roughness, 0.0), .CONDUCTOR);
    }

    run_tests(config);
}

#scope_file

//------------------------------------------------------------------------
// Helper functions

create_diffuse_surface :: (color: Spectrum, roughness: float, opacity := 1.0) -> Surface
{
    surface := Surface.{
        color     = color,
        roughness = roughness,
        ior       = 1.5,
        fresnel   = .{.{1, 1, 1}, .{1, 1, 1}},
        opacity   = opacity,
    };
    return surface;
}

create_conductor_surface :: (color: Spectrum, roughness: float, anisotropic: float, tint := Spectrum_One) -> Surface
{
    alpha   := microfacet_alpha(roughness, anisotropic);
    surface := Surface.{
        color            = color,
        roughness        = roughness,
        ior              = 1.5,
        fresnel          = .{color, tint},
        opacity          = 1.0,
        metallic         = 1.0,
        microfacet_alpha = alpha
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
    buff     : []float;
}

bsdf_tests            : [..]BSDF_Test;
bsdf_test_index       : int;
#add_context bsdf_test: BSDF_Test_Context;

test :: (name: string, surface: Surface, type: Lobe_Type)
{
    array_add(*bsdf_tests, .{name=name, surface=surface, lobe_type=type, principled=false});
}

test :: (name: string, surface: Surface)
{
    array_add(*bsdf_tests, .{name=name, surface=surface, lobe_type=.DIFFUSE, principled=true});
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

        run_pdf_integration := (config.type == .complete || config.type == .pdf_integration);
        run_e_integration   := (config.type == .complete || config.type == .energy_integration);
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

            if run_pdf_integration
            {
                context.bsdf_test.n_passed = 0;
                context.bsdf_test.n_failed = 0;

                info("> Running % (pdf integration test)...", test.name);
                if test.principled
                {
                    pdf_integration_test(test.surface, test.lobe_type, true);
                }
                else
                {
                    pdf_integration_test(test.surface, test.lobe_type, false);
                }

                info("  PASSED : %", context.bsdf_test.n_passed);
                info("  FAILED : %", context.bsdf_test.n_failed);
                info("==================================\n");
                flush();

                n_failed += context.bsdf_test.n_failed;
            }

            if run_e_integration
            {
                context.bsdf_test.n_passed = 0;
                context.bsdf_test.n_failed = 0;

                info("> Running % (energy integration test)...", test.name);
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
    MAX_NAME :: 50;

    print("\n");
    print("*******************************");
    print(" summary ");
    print("*******************************");
    print("\n");

    for bsdf_tests
    {
        if (it.state == .SKIPPED) continue;
        len := min(it.name.count, MAX_NAME);
        print(" % ", slice(it.name, 0, len));
        for len..MAX_NAME
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

scratch_buffer :: inline () -> []float
{
    if !context.bsdf_test.buff
    {
        array_resize(*context.bsdf_test.buff, N_SAMPLES);
    }
    return context.bsdf_test.buff;
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

assert_bsdf :: (bsdf: BSDF)
{
    F_THRESHOLD   :: 1.0e4;
    PDF_THRESHOLD :: 1.0e6;

    if (isnan(bsdf.f.x) || isnan(bsdf.f.y) || isnan(bsdf.f.z) || isnan(bsdf.pdf) ||
        isinf(bsdf.f.x) || isinf(bsdf.f.y) || isinf(bsdf.f.z) || isinf(bsdf.pdf))
    {
        assert_true(false, "NaN/Inf detected: f=% pdf=%", bsdf.f, bsdf.pdf);
    }

    if (bsdf.f.x < 0.0 || bsdf.f.y < 0.0 || bsdf.f.z < 0.0 || bsdf.pdf < 0.0)
    {
        assert_true(false, "Negative BSDF: f=% pdf=%", bsdf.f, bsdf.pdf);
    }

    if (bsdf.f.x > F_THRESHOLD || bsdf.f.y > F_THRESHOLD || bsdf.f.z > F_THRESHOLD)
    {
        assert_true(false, "BSDF too large: f=%", bsdf.f);
    }

    if (bsdf.pdf > PDF_THRESHOLD)
    {
        assert_true(false, "PDF too large: pdf=%", bsdf.pdf);
    }

    if (bsdf.pdf == 0.0)
    {
        if (bsdf.f.x > 0.0 || bsdf.f.y > 0.0 || bsdf.f.z > 0.0)
        {
            assert_true(false, "Non-zero f with zero pdf: f=% pdf=%", bsdf.f, bsdf.pdf);
        }
    }
}

assert_samples :: (samples: []float, V: Vector3, name: string) -> float64
{
    ABS_TOLERANCE : float64 : 1.0e-6;

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

    // 95% Confidence Interval (Z = 1.96)
    tolerance := max(1.96 * std_err, ABS_TOLERANCE);
    diff      := abs(mean - 1.0);

    assert_true(diff <= tolerance, "%: mean % is outside 95\% tolerance % for V=%", name, mean, tolerance, V);

    return mean;
}

//------------------------------------------------------------------------
// Test Procedures

pdf_integration_test :: (surface: Surface, type: Lobe_Type, $principled: bool)
{
    seed1 := random_get();
    seed2 := random_get();
    buff  := scratch_buffer();

    for 0..N_VIEWS-1
    {
        p     := sample_random_2D(it.(u32), seed1.(u32, no_check));
        V     := sample_uniform_lobe(p.x, p.y);

        for 0..N_SAMPLES-1
        {
            u    := sample_random_3D(it.(u32), seed2.(u32, no_check));
            L    := sample_uniform_lobe(u.x, u.y);
            #if principled
                bsdf := evaluate_principled(V, L, surface);
            else
                bsdf := evaluate_principled_lobe(V, L, surface, type);
            assert_bsdf(bsdf);
            buff[it] = bsdf.pdf * (2.0 * PI);
        }

        assert_samples(buff, V, "PDF integration failed");
    }
}

energy_conservation_test :: (surface: Surface, type: Lobe_Type, $principled: bool)
{
    seed1 := random_get();
    seed2 := random_get();
    e_max := FLOAT32_MIN;
    e_min := FLOAT32_MAX;
    e_avg : float64 = 0.0;
    buff  := scratch_buffer();

    for 0..N_VIEWS-1
    {
        p     := sample_random_2D(it.(u32), seed1.(u32, no_check));
        V     := sample_uniform_lobe(p.x, p.y);

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
            assert_bsdf(sample.bsdf);
            if (sample.pdf > 0.0)
            {
                cosine   := abs(sample.L.z);
                f        := sample.f * cosine / sample.pdf;
                e        := (f.x + f.y + f.z) / 3.0;
                buff[it]  = e;
                e_min     = min(e_min, e);
                e_max     = max(e_max, e);
            }
        }

        mean := assert_samples(buff, V, "Energy integration failed");
        e_avg += mean;
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
            
        V := sample_uniform_lobe(v.x, v.y);
        L := sample_uniform_lobe(u.x, u.y);

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

        assert_bsdf(bsdf1);
        assert_bsdf(bsdf2);

        f1        := bsdf1.f;
        f2        := bsdf2.f;
        diff      := abs(f1 - f2) / max(abs(f1), abs(f2));
        tolerance := 1.0e-6;

        assert_true(diff.x < tolerance && diff.y < tolerance && diff.z < tolerance,
                    "Reciprocity failed: V = %, L = %, f(V, L) = %, f(L, V) = %, diff = %",
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
#import "BxDF"()(PRESERVE_MS_ENERGY=false);

#load "sampling.jai";
