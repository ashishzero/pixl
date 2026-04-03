#load "bxdf.jai";
#load "common.jai";
#load "noise.jai";

#import "Basic";
#import "String";
#import "Command_Line";

NUM_VIEWS   :: 512;
NUM_SAMPLES :: 8192;

register_tests :: ()
{
    register_test("Diffuse Energy Conservation Uniform Sampling",
                  test_diffuse_energy_conservation_test_uniform_sampling,
                  .DIFFUSE, .ENERGY, .UNIFORM);
    register_test("Diffuse Energy Conservation BSDF Sampling",
                  test_diffuse_energy_conservation_test_bsdf_sampling,
                  .DIFFUSE, .ENERGY, .BSDF);
    register_test("Diffuse PDF Integration",
                  test_diffuse_pdf,
                  .DIFFUSE, .PDF);
    register_test("Diffuse Reciprocity", test_diffuse_reciprocity,
                  .DIFFUSE, .RECIPROCITY);
    register_test("Diffuse White Furnace Test", test_diffuse_white_furnace,
                  .DIFFUSE, .WHITE_FURNACE);
}

Test_Tag :: enum
{
    DIFFUSE;
    CONDUCTOR;
    SPECULAR_REFLECTION;
    SPECULAR_TRANSMISSION;
    DIELECTRIC;
    ALPHA;
    UNIFORM;
    BSDF;
    ENERGY;
    RECIPROCITY;
    PDF;
    WHITE_FURNACE;
}

main :: ()
{
    register_tests();

    args    := get_command_line_arguments();
    program := args[0];
    args     = array_view(args, 1, args.count - 1);

    tags: [..]Test_Tag;

    info := type_info(Test_Tag);

    for arg: args
    {
        name := trim(arg);

        if compare_nocase(name, "-help") == 0
        {
            print("USAGE ::\n    % tags...\n", program);
            print("Tags:\n    ");
            print(to_lower_copy(info.names[0]));
            for 1..info.names.count-1
            {
                print(", ");
                print(to_lower_copy(info.names[it]));
            }
            print("\n\n");
            return;
        }

        found := false;

        for 0..info.values.count-1
        {
            if compare_nocase(name, info.names[it]) == 0
            {
                tag := info.values[it].(Test_Tag);
                if !array_find(tags, tag)
                {
                    found = true;
                    array_add(*tags, tag);
                    break;
                }
            }
        }

        if !found
        {
            print("Invalid tag: %\n", name);
        }
    }

    run_tagged_tests(tags);
    print_test_summary();
}

//------------------------------------------------------------------------
// Energy tests

Sampling_Method :: enum
{
    UNIFORM;
    BSDF;
}

energy_conservation_test :: (surface: Surface, $sm: Sampling_Method, $index: Lobe_Index)
{
    rngv := path_random_state(0, 0, 0, NUM_VIEWS, 0);

    for 0..NUM_VIEWS-1
    {
        v   := random_sample_2D(rngv, .BxDF);
        V   := sample_uniform_lobe(v.x, v.y);
        f   := Spectrum.{0, 0, 0};

        next_bounce(*rngv);

        rngu := path_random_state(0, 0, 0, NUM_SAMPLES, 0);

        for 0..NUM_SAMPLES-1
        {
            #if (sm == .UNIFORM)
            {
                u      := random_sample_2D(rngu, .BxDF);
                L      := sample_uniform_lobe(u.x, u.y);
                u_pdf  := Uniform_PDF;
                bxdf   := f_surface_bxdf_lobe(V, L, surface, index);
                assert_bxdf(bxdf, "Invalid BxDF value: ", bxdf);
                cosine := abs(L.z);
                f      += bxdf.f * cosine / u_pdf;
            }
            else
            {
                u      := random_sample_3D(rngu, .BxDF);
                si     := sample_surface_bxdf_lobe(V, surface, u, index);
                assert_bxdf(si.bxdf, "Invalid BxDF value: ", si.bxdf);
                cosine := abs(si.L.z);
                if (si.bxdf.pdf != 0.0)
                {
                    f   += si.bxdf.f * cosine / si.bxdf.pdf;
                }
            }

            next_bounce(*rngu);
        }

        E   := average(f) / NUM_SAMPLES.(float);
        tol := 1.0 / sqrt(NUM_SAMPLES.(float));
        assert_true(abs(E - 1.0) < tol, "Energy divergence. E = %, tol = %, V = %", E, tol, V);
    }
}

test_diffuse_energy_conservation_test_uniform_sampling :: ()
{
    surface := Surface.{
        color = .{1, 1, 1},
        roughness = 0.8,
        ior = 1.5,
        specular = 0.0,
        metallic = 0.0,
        fresnel = .{.{1, 1, 1}, .{1, 1, 1}},
        microfacet_alpha = .{0.0, 0.0},
        transmission = 0.0,
        alpha = 1.0,
        absorption = .{0, 0, 0},
        emission = .{0, 0, 0}
    };
    energy_conservation_test(surface, .UNIFORM, .DIFFUSE);
}

test_diffuse_energy_conservation_test_bsdf_sampling :: ()
{
    surface := Surface.{
        color = .{1, 1, 1},
        roughness = 0.8,
        ior = 1.5,
        specular = 0.0,
        metallic = 0.0,
        fresnel = .{.{1, 1, 1}, .{1, 1, 1}},
        microfacet_alpha = .{0.0, 0.0},
        transmission = 0.0,
        alpha = 1.0,
        absorption = .{0, 0, 0},
        emission = .{0, 0, 0}
    };
    energy_conservation_test(surface, .BSDF, .DIFFUSE);
}

//------------------------------------------------------------------------
// PDF validation

pdf_test :: (surface: Surface, $index: Lobe_Index)
{
    rngv := path_random_state(0, 0, 0, NUM_VIEWS, 0);
    for 0..NUM_VIEWS-1
    {
        v  := random_sample_2D(rngv, .BxDF);
        V  := sample_uniform_lobe(v.x, v.y);
        p  := 0.0;
        next_bounce(*rngv);

        rngu := path_random_state(0, 0, 0, NUM_SAMPLES, 0);

        for 0..NUM_SAMPLES-1
        {
            u     := random_sample_2D(rngu, .BxDF);
            L     := sample_uniform_lobe(u.x, u.y);
            bxdf  := f_surface_bxdf_lobe(V, L, surface, index);
            p     += bxdf.pdf / Uniform_PDF;
            next_bounce(*rngu);
        }

        P   := p / NUM_SAMPLES.(float);
        tol := 1.0 / sqrt(NUM_SAMPLES.(float));
        assert_true(abs(P - 1.0) < tol, "PDF integration failed. P = %, tol = %, V = %", P, tol, V);
    }
}

test_diffuse_pdf :: ()
{
    surface := Surface.{
        color = .{1, 1, 1},
        roughness = 0.8,
        ior = 1.5,
        specular = 0.0,
        metallic = 0.0,
        fresnel = .{.{1, 1, 1}, .{1, 1, 1}},
        microfacet_alpha = .{0.0, 0.0},
        transmission = 0.0,
        alpha = 1.0,
        absorption = .{0, 0, 0},
        emission = .{0, 0, 0}
    };
    pdf_test(surface, .DIFFUSE);
}

//------------------------------------------------------------------------
// Reciprocity test

reciprocity_test :: (surface: Surface, $index: Lobe_Index)
{
    rngu := path_random_state(0, 0, 0, NUM_VIEWS, 0xcdcdcdcd);
    rngv := path_random_state(0, 0, 0, NUM_VIEWS, 0xefefefef);

    for 0..NUM_VIEWS-1
    {
        u := random_sample_2D(rngu, .BxDF);
        v := random_sample_2D(rngv, .BxDF);
            
        V := sample_uniform_lobe(v.x, v.y);
        L := sample_uniform_lobe(u.x, u.y);

        next_bounce(*rngu);
        next_bounce(*rngv);

        bxdf1 := f_surface_bxdf_lobe(V, L, surface, index);
        bxdf2 := f_surface_bxdf_lobe(L, V, surface, index);

        assert_bxdf(bxdf1, "Invalid BxDF(V, L) value: ", bxdf1);
        assert_bxdf(bxdf2, "Invalid BxDF(L, V) value: ", bxdf2);

        mag   := max(length(bxdf1.f),  length(bxdf2.f), 1.0e-8);
        diff  := bxdf1.f - bxdf2.f;
        rdiff := diff / mag;
        tol   := 1.0e-4;

        assert_true(abs(rdiff.x) < tol && abs(rdiff.y) < tol && abs(rdiff.z) < tol,
                    "Reciprocity test failed. V = %, L = %, f(V, L) = %, f(L, V) = %",
                    V, L, bxdf1, bxdf2);
    }
}

test_diffuse_reciprocity :: ()
{
    surface := Surface.{
        color = .{1, 1, 1},
        roughness = 0.8,
        ior = 1.5,
        specular = 0.0,
        metallic = 0.0,
        fresnel = .{.{1, 1, 1}, .{1, 1, 1}},
        microfacet_alpha = .{0.0, 0.0},
        transmission = 0.0,
        alpha = 1.0,
        absorption = .{0, 0, 0},
        emission = .{0, 0, 0}
    };
    reciprocity_test(surface, .DIFFUSE);
}

//------------------------------------------------------------------------
// White Furnace Test

white_conservation_test :: (surface: Surface)
{
    rngv := path_random_state(0, 0, 0, NUM_VIEWS, 0);

    for 0..NUM_VIEWS-1
    {
        v   := random_sample_2D(rngv, .BxDF);
        V   := sample_uniform_lobe(v.x, v.y);
        f   := Spectrum.{0, 0, 0};

        next_bounce(*rngv);

        rngu := path_random_state(0, 0, 0, NUM_SAMPLES, 0);

        for 0..NUM_SAMPLES-1
        {
            p      := random_sample_1D(rngu, .LOBE);
            u      := random_sample_3D(rngu, .BxDF);
            si     := sample_surface_bsdf(V, surface, p, u);
            assert_bxdf(si.bxdf, "Invalid BxDF value: ", si.bxdf);
            cosine := abs(si.L.z);
            if (si.bxdf.pdf != 0.0)
            {
                f   += si.bxdf.f * cosine / si.bxdf.pdf;
            }
            next_bounce(*rngu);
        }

        E   := average(f) / NUM_SAMPLES.(float);
        tol := 1.0 / sqrt(NUM_SAMPLES.(float));
        assert_true(abs(E - 1.0) < tol, "Energy divergence. E = %, tol = %, V = %", E, tol, V);
    }
}

test_diffuse_white_furnace :: ()
{
    surface := Surface.{
        color = .{1, 1, 1},
        roughness = 0.8,
        ior = 1.5,
        specular = 0.0,
        metallic = 0.0,
        fresnel = .{.{1, 1, 1}, .{1, 1, 1}},
        microfacet_alpha = .{0.0, 0.0},
        transmission = 0.0,
        alpha = 1.0,
        absorption = .{0, 0, 0},
        emission = .{0, 0, 0}
    };
    white_conservation_test(surface);
}

//------------------------------------------------------------------------
// Test Utils

print_test_summary :: ()
{
    MAX_NAME :: 50;

    print("\n");
    print("*******************************");
    print(" summary ");
    print("*******************************");
    print("\n");

    for registered_tests
    {
        if it.state == .WAIT then continue;
        len := min(it.name.count, MAX_NAME);
        print(" % ", slice(it.name, 0, len));
        for len..MAX_NAME
        {
            print(".");
        }
        print("...... %\n", ifx it.state == .PASSED then "PASSED" else "FAILED");
    }

    print("*******************************");
    print("*********");
    print("*******************************");
    print("\n");
}

run_tagged_tests :: (tags: []Test_Tag)
{
    run_test :: (test: *Test_Desc)
    {
        num_passed = 0;
        num_failed = 0;

        print("=== Running %...\n", test.name);
        test.proc();
        print("  PASSED : %\n", num_passed);
        print("  FAILED : %\n", num_failed);

        test.state = ifx (num_failed == 0) then .PASSED else .FAILED;
        test.n_passed = num_passed;
        test.n_failed = num_failed;
    }

    filter_test :: (test: Test_Desc) -> bool #expand 
    {
        for tag: tags
        {
            if !array_find(test.tags, tag) then
                return true;
        }
        return false;
    }

    for * registered_tests
    {
        if filter_test(it) continue;
        run_test(it);
    }
}

registered_tests: [..]Test_Desc;
num_passed: int;
num_failed: int;

Test_Proc :: #type ();

Test_State :: enum
{
    WAIT;
    PASSED;
    FAILED;
}

Test_Desc :: struct
{
    tags     : [..]Test_Tag;
    name     : string;
    proc     : Test_Proc;
    state    := Test_State.WAIT;
    n_passed := 0;
    n_failed := 0;
}

register_test :: ($name: string, $proc: Test_Proc, $tags: ..Test_Tag)
{
    desc := array_add(*registered_tests);
    desc.name = name;
    desc.proc = proc;
    array_add(*desc.tags, ..tags);
}

assert_bxdf :: (bxdf: BxDF, format_string: string, args: .. Any)
{
    if (bxdf.f.x < 0.0 || bxdf.f.y < 0.0 || bxdf.f.z < 0.0 || bxdf.pdf < 0.0)
    {
        assert_true(false, format_string, args);
    }
}

assert_true :: (expr: bool, format_string: string, args: .. Any)
{
    if (!expr)
    {
        print("    FAILED: ");
        print(format_string, ..args);
        print("\n");
        num_failed += 1;
    }
    else
    {
        num_passed += 1;
    }
}
