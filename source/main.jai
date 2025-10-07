#load "raytracer.jai";
#load "bxdf.jai";

RAYTRACE_BITMAP_WIDTH  :: 1920;
RAYTRACE_BITMAP_HEIGHT :: 1080;

//RAYTRACE_BITMAP_WIDTH  :: 800;
//RAYTRACE_BITMAP_HEIGHT :: 600;

want_screenshot := false;

reflect :: inline (d: Vector3, n: Vector3) -> Vector3
{
    return -d + 2 * dot(d, n) * n;
}

refract :: inline (uv: Vector3, n: Vector3, factor: float) -> Vector3
{
    cos_theta    := min(dot(-uv, n), 1.0);
    out_perp     := factor * (uv + cos_theta * n);
    out_parallel := -sqrt(abs(1.0 - length_squared(out_perp))) * n;
    return out_perp + out_parallel;
}

fract :: inline (x: float) -> float { return x - floor(x); }

smoothstep :: inline (a: float, b: float, v: float) -> float
{
    dist := b - a;
    if (dist)
    {
        x := clamp((v - a) / dist, 0.0, 1.0);
        return x * x * (3 - 2 * x);
    }
    return 1;
}

sample_texture :: (texture: Texture2D, u: float, v: float) -> texture.ValueType
{
    // @todo: remove flags and always sample!!
    value := texture.values[0];

    if (texture.flags & .CHECKERBOARD)
    {
        u_scaled := u * texture.scale.x;
        v_scaled := v * texture.scale.y;

        // @todo: antialiasing
        // this can be done after we have differentials for du and dv
        // https://pbr-book.org/3ed-2018/Texture/Solid_and_Procedural_Texturing

        if ((u_scaled.(int) + v_scaled.(int)) & 1) == 1
        {
            value = texture.values[0];
        }
        else
        {
            value = texture.values[1];
        }
    }

    if (texture.bitmap.width && texture.bitmap.height && texture.bitmap.data)
    {
        u = clamp(u, 0.0, (1.0 - 0.000001).(float));
        v = clamp(v, 0.0, (1.0 - 0.000001).(float));

        // @todo: bilinear interpolate
        x := (u * (texture.bitmap.width - 1)).(s32);
        y := (v * (texture.bitmap.height - 1)).(s32);

        index := y * texture.bitmap.stride + x * 4;

        #if texture.ValueType == Vector3
        {
            r := texture.bitmap.data[index + 0].(float);
            g := texture.bitmap.data[index + 1].(float);
            b := texture.bitmap.data[index + 2].(float);

            r /= 255;
            g /= 255;
            b /= 255;

            value.x *= r;
            value.y *= g;
            value.z *= b;
        }
        else
        {
            r := texture.bitmap.data[index].(float);
            r /= 255;
            value *= r;
        }
    }

    return value;
}

sample_uniform_disk_polar :: (u: Vector2) -> Vector2
{
    r := sqrt(u.x);
    theta := 2 * PI * u.y;
    sample: Vector2 = ---;
    sample.x = r * cos(theta);
    sample.y = r * sin(theta);
    return sample;
}

ForwardTransform :: (xform: Matrix3, p: Vector3) -> Vector3
{
    r: Vector3 = ---;
    r.x = xform._11 * p.x + xform._12 * p.y + xform._13 * p.z;
    r.y = xform._21 * p.x + xform._22 * p.y + xform._23 * p.z;
    r.z = xform._31 * p.x + xform._32 * p.y + xform._33 * p.z;
    return r;
}

InverseTransform :: (xform: Matrix3, p: Vector3) -> Vector3
{
    r: Vector3 = ---;
    r.x = xform._11 * p.x + xform._21 * p.y + xform._31 * p.z;
    r.y = xform._12 * p.x + xform._22 * p.y + xform._32 * p.z;
    r.z = xform._13 * p.x + xform._23 * p.y + xform._33 * p.z;
    return r;
}

SampleMaterialSurfaceProperties :: (material: Material, hit: HitInfo) -> SurfaceProperties
{
    surface: SurfaceProperties   = ---;
    surface.color                = sample_texture(material.color, hit.u, hit.v);
    surface.metalness            = sample_texture(material.metalness, hit.u, hit.v);
    surface.diffuse_roughness    = sample_texture(material.diffuse_roughness, hit.u, hit.v);
    surface.specular_weight      = sample_texture(material.specular_weight, hit.u, hit.v);
    surface.specular_color       = sample_texture(material.specular_color, hit.u, hit.v);
    surface.specular_roughness   = sample_texture(material.specular_roughness, hit.u, hit.v);
    surface.specular_anisotropic = sample_texture(material.specular_anisotropic, hit.u, hit.v);
    surface.emission             = sample_texture(material.emission, hit.u, hit.v);
    surface.emission_strength    = sample_texture(material.emission_strength, hit.u, hit.v);
    return surface;
}

mix :: (x: $T, y: T, t: float) -> T
{
    return x * (1.0 - t) + y * t;
}

BSDFSample :: (V: Vector3, surface: SurfaceProperties, p: float, u: Vector2) -> BSDF_Sample
{
    P_m := surface.metalness;
    P_d := 1.0 - P_m;

    if (p < P_d)
    {
        sample := DiffuseSample(V, surface.color, surface.diffuse_roughness, u.x, u.y);
        pdf_m  := MetalPDF(V, sample.L, surface.specular_roughness, surface.specular_anisotropic);
        pdf    := P_m * pdf_m + P_d * sample.pdf;
        return .{sample.Fr, sample.L, pdf};
    }
    else
    {
        sample := MetalSample(V, surface.color, surface.specular_color, surface.specular_roughness, surface.specular_anisotropic, u.x, u.y);
        pdf_d  := DiffusePDF(V, sample.L, surface.diffuse_roughness);
        pdf    := P_m * sample.pdf + P_d * pdf_d;
        return .{sample.Fr, sample.L, pdf};
    }

    return .{};
}

Ray :: struct
{
    origin : Vector3;
    tmin   : float;
    dir    : Vector3;
    tmax   : float;
}

IntegratePath :: (scene: Scene, primary: Ray, depth: s32) -> Vector3
{
    Lo   := Vector3.{0, 0, 0};
    Fr   := Vector3.{1, 1, 1};
    ray  := primary;

    for 0..depth
    {
        hit, num_visited := IntersectScene(scene, ray.origin, ray.dir, ray.tmin, ray.tmax);

        if hit.t >= 0.0
        {
            //------------------------------------------------------------------------
            // TBN
            N := hit.n;
            T := normalize(hit.dpdu - hit.n * dot(hit.dpdu, hit.n));
            B := cross(N, T);
            handedness := ifx (dot(B, hit.dpdv) < 0.0) then -1.0 else 1.0;
            B *= handedness;

            inv_TBN : Matrix3 = ---;
            inv_TBN.v[0] = T;
            inv_TBN.v[1] = B;
            inv_TBN.v[2] = N;

            //------------------------------------------------------------------------
            // Sample
            material := scene.materials[hit.material_id];
            surface  := SampleMaterialSurfaceProperties(material, hit);

            u   : Vector2;
            p   := random_get_zero_to_one_open();
            u.x  = random_get_zero_to_one_open();
            u.y  = random_get_zero_to_one_open();

            V      := ForwardTransform(inv_TBN, -ray.dir);
            sample := BSDFSample(V, surface, p, u);

            Le     := surface.emission_strength * surface.emission;
            Lo += Fr * Le;

            if (sample.pdf < 1.e-6)
            {
                break;
            }

            cosine := saturate(sample.L.z);
            Fr *= cosine * sample.Fr / sample.pdf;

            //print("Fr = %\n", cosine * sample.Fr / sample.pdf);

            //------------------------------------------------------------------------
            // Next ray
            ray.origin = hit.p;
            ray.dir    = InverseTransform(inv_TBN, sample.L);
            ray.tmin   = 1.0e-3;
            ray.tmax   = FLOAT32_MAX;
        }
        else
        {
            if (it == 0)
            {
                Lo += Fr * scene.environment;
            }
            else
            {
                Lo += Fr * Vector3.{1, 1, 1};
            }
            break;
        }
    }

    return Lo;
}

trace_pixel :: (scene: Scene, x: s32, y: s32, num_samples: s32) -> Vector3
{
    inv_sqrt_samples := 1.0 / num_samples.(float);
    sampled := Vector3.{0, 0, 0};

    width  := scene.config.width;
    height := scene.config.height;

    assert(width > 1 && height > 1);

    scale  := Vector2.{ 2.0 / (width - 1).(float), 2.0 / (height - 1).(float) };
    shift  := Vector2.{ -1.0, -1.0 };

    for n_y:0..num_samples-1
    {
        for n_x:0..num_samples-1
        {
            offset := sample_stratified_square(n_x.(float), n_y.(float), inv_sqrt_samples);
            sample := Vector2.{ x.(float), y.(float) } + offset;
            query  := sample * scale + shift;
            ray    := GenerateRay(query, scene.camera.xform, scene.camera.lens_focal_length, scene.camera.lens_radius);
            color  := IntegratePath(scene, ray, scene.config.max_depth);
            sampled += color;
        }
    }

    return sampled;
}

LaneDescription :: struct
{
    index    :  int;
    count    :  int;
    wavefront: *Wavefront;
}

Wavefront :: struct
{
    shared  : RenderShared;
    barrier : SyncBarrier;
    threads : [..]Thread;
}

#add_context lane: LaneDescription;

RAY_TRACE_TILE_SIZE : s32 : 4;

RenderShared :: struct
{
    tile_id: int;
}

ApplyToneMapping :: (func: Tone_Map_Type, v: Vector3) -> Vector3
{
    if #complete func ==
    {
        case .LINEAR;
            return Vector3.{saturate(v.x), saturate(v.y), saturate(v.z)};
        case .REINHARD;
            return v / (Vector3.{1, 1, 1} + v);
    }
}

render :: (scene: *Scene, weight: float, num_samples: s32, shared: *RenderShared)
{
    width  := scene.config.width;
    height := scene.config.height;

    assert(width % RAY_TRACE_TILE_SIZE == 0);
    assert(height % RAY_TRACE_TILE_SIZE == 0);

    num_tile_w := width / RAY_TRACE_TILE_SIZE;
    num_tile_h := height / RAY_TRACE_TILE_SIZE;

    num_tiles := num_tile_w * num_tile_h;

    if context.lane.index == 0
    {
        atomic_write(*shared.tile_id, 0);
    }

    inv_samples := 1.0 / (num_samples * num_samples).(float);

    lane_sync();

    while !should_quit
    {
        captured_tile_id := atomic_add(*shared.tile_id, 1);

        if captured_tile_id >= num_tiles then break;

        tile_y := captured_tile_id / num_tile_w;
        tile_x := captured_tile_id % num_tile_w;

        y0 := tile_y * RAY_TRACE_TILE_SIZE;
        y1 := y0 + RAY_TRACE_TILE_SIZE - 1;

        x0 := tile_x * RAY_TRACE_TILE_SIZE;
        x1 := x0 + RAY_TRACE_TILE_SIZE - 1;

        if x1 >= width  then x1 = width - 1;
        if y1 >= height then y1 = height - 1;

        //offset := captured_tile_id * RAY_TRACE_TILE_SIZE * RAY_TRACE_TILE_SIZE;

        for y:y0..y1
        {
            for x:x0..x1
            {
                color := trace_pixel(scene, x.(s32), y.(s32), num_samples);

                index := y * width + x;
                //index := offset;
                //offset += 1;

                color *= inv_samples;
                prev_color := scene.rgbx[index].xyz;

                render := lerp(prev_color, color, weight);

                scene.rgbx[index].xyz = render;

                // @todo: proper Tone Mapping + Gamma correction
                // https://64.github.io/tonemapping/
                render = ApplyToneMapping(scene.tonemap, render);

                if (white_furnace_test_enabled)
                {
                    render.x = pow(abs(render.x - 1), 0.5);
                    render.y = pow(abs(render.y - 1), 0.5);
                    render.z = pow(abs(render.z - 1), 0.5);
                }

                write_color(*scene.bitmap, x, y, render);
            }
        }
    }

    lane_sync();
}

write_color :: (bitmap: *Bitmap, x: int, y: int, linear: Vector3)
{
    index := (bitmap.height - y - 1) * bitmap.stride + x * 4;

    color := linear_to_srgb(linear);

    r := (color.x * 255).(u8);
    g := (color.y * 255).(u8);
    b := (color.z * 255).(u8);

    bitmap.data[index + 0] = r;
    bitmap.data[index + 1] = g;
    bitmap.data[index + 2] = b;
    bitmap.data[index + 3] = 0xFF;
}

SceneType :: enum
{
    BASIC_LIGHT;
    CORNELL_BOX;
    CORNELL_DRAGON;
    CORNELL_MONKEY;
    WHITE_FURNACE_TEST;
    SHADERBALL_TEST;
    MATERIAL_TEST;
}

white_furnace_test_enabled   := false;
white_furnace_test_error     := 0.0;
white_furnace_test_bias      := 0.0;
white_furnace_test_max_error := 0.0;

wavefront_raytrace_entry :: (thread: *Thread) -> s64
{
    scene := thread.data.(*Scene);

    width  := scene.config.width;
    height := scene.config.height;

    num_samples := sqrt(scene.config.multisamples.(float32)).(s32);

    screenshot_index := 0;

    if context.lane.index == 0
    {
        screenshot_index = get_first_screenshot_index("captures");
    }

    while (!should_quit)
    {
        weight := 1.0 / (frame_index.(float) + 1);

        t0 := current_time_monotonic();

        render(scene, weight, num_samples, *context.lane.wavefront.shared);

        t1 := current_time_monotonic();

        if context.lane.index == 0
        {
            last_frame_render_time_ms = to_milliseconds(t1 - t0);
            frame_index += 1;

            if want_screenshot || (frame_index % 12) == 0
            {
                save_screenshot(scene.bitmap, *screenshot_index);
                want_screenshot = false;
            }

            if white_furnace_test_enabled
            {
                error     := 0.0;
                max_error := 0.0;
                bias      := 0.0;
                for scene.rgbx
                {
                    err_r := it.x - 1.0;
                    err_g := it.y - 1.0;
                    err_b := it.z - 1.0;
                    error += abs(err_r) + abs(err_g) + abs(err_b);
                    bias  += (err_r + err_g + err_b);
                    max_error = max(max_error, max(abs(err_r), max(abs(err_g), abs(err_b))));
                }
                white_furnace_test_error     = error / (scene.rgbx.count);
                white_furnace_test_bias      = bias / (scene.rgbx.count);
                white_furnace_test_max_error = max_error;
                print("White Furnace Test dE = %\%, bias = %\%, max error = %\n", white_furnace_test_error * 100, white_furnace_test_bias * 100, white_furnace_test_max_error);
            }
        }

        lane_sync();
    }

    return 0;
}

init :: (wavefront: *Wavefront, scene: *Scene, max_threads: s32 = 0)
{
    num_cpus := get_number_of_processors();

    assert(num_cpus >= 1);
    if num_cpus > 200  num_cpus = 200;

    num_cpus = max(num_cpus - 4, 2);

    if max_threads > 0 && num_cpus > max_threads
    {
        num_cpus = max_threads;
    }

    init_sync_barrier(*wavefront.barrier, num_cpus);

    array_resize(*wavefront.threads, num_cpus);

    for * wavefront.threads
    {
        thread_init(it, wavefront_raytrace_entry);
        it.data = scene;

        it.starting_context.lane.index = it_index;
        it.starting_context.lane.count = num_cpus;
        it.starting_context.lane.wavefront = wavefront;

        seed: Some_Big_Time_Value;
        apollo := current_time_consensus();
        seed.high = apollo.high;
        seed.low  = apollo.low;
        seed.low += it.(u64);
        random_seed(*it.starting_context.random_state, seed);
    }
}

start :: (using wavefront: Wavefront)
{
    for * threads
    {
        thread_start(it);
    }
}

join :: (using wavefront: *Wavefront)
{
    for * threads
    {
        thread_is_done(it, -1);
        thread_deinit(it);
    }
    deinit_sync_barrier(*wavefront.barrier);
    array_free(threads);
}

load_bunny :: () -> PrimitiveMesh, Matrix4
{
    theta := 20.0 / 360.0 * 2 * PI;

    rot: Quaternion;

    set_from_axis_and_angle(*rot, 0, 1, 0, theta);

    scale := 300.0;

    bunny := load_obj_model("data/bunny/bunny.obj");
    xform := make_translation_matrix4(.{270, 90, 270}) * rotation_matrix(Matrix4, rot) * make_scale_matrix4(.{scale, scale, scale});

    return bunny, xform;
}

load_monkey :: () -> PrimitiveMesh, Matrix4
{
    theta := 30.0 / 360.0 * 2 * PI;

    rot: Quaternion;

    set_from_axis_and_angle(*rot, 0, 1, 0, theta);

    scale := 200.0;

    monkey := load_obj_model("data/spot/spot_triangulated.obj");
    xform  := make_translation_matrix4(.{270, 140, 270}) * rotation_matrix(Matrix4, rot) * make_scale_matrix4(.{scale, scale, scale});

    return monkey, xform;
}

load_dragon :: () -> PrimitiveMesh, Matrix4
{
    theta := 90.0 / 360.0 * 2 * PI;

    rot: Quaternion;

    set_from_axis_and_angle(*rot, 0, 1, 0, theta);

    scale := 500.0;

    dragon := load_obj_model("data/dragon/dragon.obj");
    xform  := make_translation_matrix4(.{270, 140, 270}) * rotation_matrix(Matrix4, rot) * make_scale_matrix4(.{scale, scale, scale});

    return dragon, xform;
}

load_backdrop :: () -> PrimitiveMesh, Matrix4
{
    scale := 2.0;
    position := Vector3.{0, 0, -10.1};
    backdrop := load_obj_model("data/backdrop/Backdrop.obj");
    xform    := make_translation_matrix4(position) * make_scale_matrix4(.{scale, scale, scale});
    return backdrop, xform;
}

load_shaderball :: () -> PrimitiveMesh, PrimitiveMesh, Matrix4
{
    scale := 2.0;
    position := Vector3.{0, 0, 0};
    internals := load_obj_model("data/shaderball/shader_ball_internals.obj");
    externals := load_obj_model("data/shaderball/shader_ball_externals.obj");

    theta := 30.0 / 360.0 * 2 * PI;

    orientation: Quaternion;
    set_from_axis_and_angle(*orientation, 0, 1, 0, theta);

    xform    := make_translation_matrix4(position) * rotation_matrix(Matrix4, orientation) * make_scale_matrix4(.{scale, scale, scale});
    return internals, externals, xform;
}

quaternion_between_vectors :: (from: Vector3, to: Vector3) -> Quaternion
{
    q: Quaternion;
    w := 1.0 + dot(from, to);
    if (w)
    {
        v  := cross(from, to);
        q.x = v.x;
        q.y = v.y;
        q.z = v.z;
        q.w = w;
    }
    else
    {
        xyz := ifx abs(from.x) > abs(from.z)
                Vector3.{-from.y, from.x, 0.0}
               else
                Vector3.{0.0, -from.z, from.y};
        q = .{xyz.x, xyz.y, xyz.z, w};
    }
    return normalize(q);
}

lookat :: (from: Vector3, to: Vector3, world_forward: Vector3) -> Quaternion
{
    dir := to - from;
    return quaternion_between_vectors(world_forward, dir);
}

turns_to_radians :: (turns: float) -> float
{
    return turns * 2.0 * PI;
}

load_scene :: (using scene: *Scene, type: SceneType)
{
    if #complete type ==
    {
        case .BASIC_LIGHT;
            camera.fov           = 40.0 / 360.0;
            camera.position      = .{0, 0, -30};

            theta1 := -18.0 / 360.0 * 2 * PI;
            theta2 := 15.0 / 360.0 * 2 * PI;

            rot1, rot2: Quaternion;

            set_from_axis_and_angle(*rot1, 0, 1, 0, theta1);
            set_from_axis_and_angle(*rot2, 0, 1, 0, theta2);

            xform1 := rotation_matrix(Matrix4, rot1);
            xform2 := rotation_matrix(Matrix4, rot2);

            red   := create_lambertian_material(scene, texture_vector3(.{0.65, 0.05, 0.05}));

            //add_translated_box(scene, xform1, .{-10, -5, -10}, .{5, 5, 25}, red);

            add_sphere(scene, Vector3.{15, 15, 75}, 5, red);

        case .CORNELL_BOX;
            camera.fov           = 40.0 / 360.0;
            camera.position      = .{278, 278, -800};

            //camera.lens_focal_length = 1200;
            //camera.lens_radius = 10.0;

            environment          = .{0.0, 0.0, 0.0};

            red   := create_lambertian_material(scene, texture_vector3(.{0.65, 0.05, 0.05}));
            white := create_lambertian_material(scene, texture_vector3(.{0.73, 0.73, 0.73}));
            green := create_lambertian_material(scene, texture_vector3(.{0.12, 0.45, 0.15}));
            light := create_emission_material(scene, texture_vector3(.{15, 15, 15}));

            add_box(scene, Matrix4_Identity, .{213, 554, 227}, .{343, 554.01, 332}, light); // top
            add_box(scene, Matrix4_Identity, .{0, 0, 0}, .{0.01, 555, 555}, green); // left
            add_box(scene, Matrix4_Identity, .{555, 0, 0}, .{555.01, 555, 555}, red); // right
            add_box(scene, Matrix4_Identity, .{0, 0, 0}, .{555, 0.01, 555}, white); // bottom
            add_box(scene, Matrix4_Identity, .{0, 0, 555}, .{555, 555, 555.01}, white); // back
            add_box(scene, Matrix4_Identity, .{0, 555, 0}, .{555, 555.01, 555}, white); // top

            theta1 := 18.0 / 360.0 * 2 * PI;
            theta2 := -15.0 / 360.0 * 2 * PI;

            rot1, rot2: Quaternion;

            set_from_axis_and_angle(*rot1, 0, 1, 0, theta1);
            set_from_axis_and_angle(*rot2, 0, 1, 0, theta2);

            xform1 := rotation_matrix(Matrix4, rot1);
            xform2 := rotation_matrix(Matrix4, rot2);

            add_translated_box(scene, xform1, .{260, 0,  65}, .{425, 165, 225}, white);
            add_translated_box(scene, xform2, .{130, 0, 295}, .{290, 330, 455}, white);

        case .CORNELL_DRAGON;
            camera.fov           = 40.0 / 360.0;
            camera.position      = .{278, 278, -800};

            environment          = .{0, 0, 0};
            //environment          = .{0.3, 0.2, 0.7};

            red   := create_lambertian_material(scene, texture_vector3(.{0.65, 0.05, 0.05}));
            white := create_lambertian_material(scene, texture_vector3(.{0.73, 0.73, 0.73}));
            green := create_lambertian_material(scene, texture_vector3(.{0.12, 0.45, 0.15}));
            light := create_emission_material(scene, texture_vector3(.{15, 15, 15}));

            add_box(scene, Matrix4_Identity, .{213, 554, 227}, .{343, 554.01, 332}, light);
            add_box(scene, Matrix4_Identity, .{0, 0, 0}, .{0.01, 555, 555}, green); // left
            add_box(scene, Matrix4_Identity, .{555, 0, 0}, .{555.01, 555, 555}, red); // right
            add_box(scene, Matrix4_Identity, .{0, 0, 0}, .{555, 0.01, 555}, white); // bottom
            add_box(scene, Matrix4_Identity, .{0, 0, 555}, .{555, 555, 555.01}, white); // back
            add_box(scene, Matrix4_Identity, .{0, 555, 0}, .{555, 555.01, 555}, white); // top

            dragon_material := create_lambertian_material(scene, texture_vector3(.{1, 1, 1}));
            dragon, xform   := load_dragon();

            add_mesh(scene, xform, dragon, dragon_material);

        case .CORNELL_MONKEY;
            camera.fov           = 40.0 / 360.0;
            camera.position      = .{278, 278, -800};

            environment          = .{0, 0, 0};
            //environment          = .{0.3, 0.2, 0.7};

            red   := create_lambertian_material(scene, texture_vector3(.{0.65, 0.05, 0.05}));
            white := create_lambertian_material(scene, texture_vector3(.{0.73, 0.73, 0.73}));
            green := create_lambertian_material(scene, texture_vector3(.{0.12, 0.45, 0.15}));
            light := create_emission_material(scene, texture_vector3(.{15, 15, 15}));

            add_box(scene, Matrix4_Identity, .{213, 554, 227}, .{343, 554.01, 332}, light); // top
            add_box(scene, Matrix4_Identity, .{0, 27, 227}, .{0.1, 127, 327}, light); // left

            add_box(scene, Matrix4_Identity, .{0, 0, 0}, .{0.01, 555, 555}, green); // left
            add_box(scene, Matrix4_Identity, .{555, 0, 0}, .{555.01, 555, 555}, red); // right
            add_box(scene, Matrix4_Identity, .{0, 0, 0}, .{555, 0.01, 555}, white); // bottom
            add_box(scene, Matrix4_Identity, .{0, 0, 555}, .{555, 555, 555.01}, white); // back
            add_box(scene, Matrix4_Identity, .{0, 555, 0}, .{555, 555.01, 555}, white); // top

            monkey, xform := load_monkey();

            add_mesh(scene, xform, monkey, white);

        case .WHITE_FURNACE_TEST;
            white_furnace_test_enabled = true;

            tonemap            = .LINEAR;
            camera.fov         = 45.0 / 360.0;
            camera.position    = .{0, 0, -5};
            camera.orientation = .{};
            environment        = .{1, 1, 1};

            center  := Vector3.{0.0, 0.0, 0.0};
            radius  := 1.0;

            id, material        := create_material(scene);
            material.color       = texture_vector3(.{1, 1, 1});
            material.metalness   = texture_value(1.0);
            material.diffuse_roughness    = texture_value(1.0);
            material.specular_weight      = texture_value(1.0);
            material.specular_color       = texture_vector3(.{1, 1, 1});
            material.specular_roughness   = texture_value(0.2);
            material.specular_anisotropic = texture_value(0.0);

            add_sphere(scene, center, radius, id);

        case .SHADERBALL_TEST;
            camera.fov           = 40.0 / 360.0;
            camera.position      = .{0, 10, -10};
            set_from_axis_and_angle(*camera.orientation, Vector3.{1, 0, 0}, turns_to_radians(0.1));

            light := create_emission_material(scene, texture_vector3(.{40, 40, 40}));

            environment          = .{1.0, 1.0, 1.0};

            id, material        := create_material(scene);
            //material.color       = texture_vector3(.{0.827, 0.686, 0.216});
            //material.color       = texture_vector3(.{1, 1, 1});
            material.color       = texture_vector3(.{1.000, 0.735, 0.353}); // Gold
            material.metalness   = texture_value(1.0);
            material.specular_weight      = texture_value(1.0);
            //material.specular_color       = texture_vector3(.{1, 1, 1});
            material.specular_color       = texture_vector3(.{0.993, 1.000, 1.000}); // Gold
            material.specular_roughness   = texture_value(0.25);
            material.specular_anisotropic = texture_value(0.0);

            red        := create_lambertian_material(scene, texture_vector3(.{0.65, 0.05, 0.05}));
            black      := create_lambertian_material(scene, texture_vector3(.{0.01, 0.01, 0.01}));
            checker    := create_lambertian_material(scene, texture_checkerboard(Vector3.{0.9, 0.9, 0.9}, .{0.1, 0.1, 0.1}, .{40, 40}));

            backdrop, backdrop_xform     := load_backdrop();
            internals, externals, shaderball_xform := load_shaderball();

            add_box(scene, Matrix4_Identity, .{ -5, 10, -15 }, .{ -1, 10.01, -11 }, light);
            add_box(scene, Matrix4_Identity, .{  1, 10, -15 }, .{  5, 10.01, -11 }, light);

            //add_sphere(scene, Vector3.{0, 2, 0}, 2, red);

            add_mesh(scene, backdrop_xform, backdrop, checker);
            //add_sphere(scene, Vector3.{0, 2, 0}, 2, id);
            add_mesh(scene, shaderball_xform, internals, black);
            add_mesh(scene, shaderball_xform, externals, id);

        case .MATERIAL_TEST;
            camera.fov         = 45.0 / 360.0;
            camera.position    = .{0, 0, -5};
            camera.orientation = .{};
            environment        = .{0.16, 0.16, 0.16};

            NUM_TEST_SPHERES :: 11;

            // Diffuse
            {
                color   := Vector3.{0.02, 0.53, 0.42};
                center  := Vector3.{-3.0, 0.0, 0.0};
                radius  := 0.2;
                spacing := 2 * radius + 0.1;

                for 0..NUM_TEST_SPHERES-1
                {
                    roughness := it.(float) / (NUM_TEST_SPHERES - 1).(float);
                    //material  := create_lambertian_material(scene, texture_value(color), roughness);

                    id, material                 := create_material(scene);
                    material.color                = texture_vector3(.{1.000, 0.735, 0.353}); // Gold
                    material.metalness            = texture_value(1.0);
                    material.specular_weight      = texture_value(1.0);
                    material.specular_color       = texture_vector3(.{0.993, 1.000, 1.000}); // Gold
                    material.specular_roughness   = texture_value(roughness);
                    material.specular_anisotropic = texture_value(0.0);

                    add_sphere(scene, center, radius, id);
                    center.x += spacing;
                }
            }
    }
}

add_primitive :: (scene: *Scene, type: Primitive_Type) -> *Primitive
{
    primitive := array_add(*scene.primitives);
    primitive.type = type;
    return primitive;
}

add_sphere :: (scene: *Scene, xform: Matrix4, radius: float, material_id: MaterialID)
{
    if radius <= 0.0 then
        radius = 1;

    center := transform_point(xform, Vector3.{0, 0, 0});
    _, inv := inverse(xform);

    primitive := add_primitive(scene, .SPHERE);
    primitive.shape.sphere.radius = radius;
    primitive.xform.forward = xform;
    primitive.xform.inverse = inv;
    bbox: Box3 = ---;
    bbox.vmin = center - Vector3.{radius, radius, radius};
    bbox.vmax = center + Vector3.{radius, radius, radius};
    array_add(*scene.tlas.bboxes, bbox);
    primitive.material_id = material_id;
}

add_sphere :: (scene: *Scene, center: Vector3, radius: float, material_id: MaterialID)
{
    xform := make_translation_matrix4(center);
    add_sphere(scene, xform, radius, material_id);
}

add_disk :: (scene: *Scene, p: Vector3, radius: float, material_id: MaterialID)
{
    if radius <= 0.0 then
        radius = 1;

    primitive := add_primitive(scene, .DISK);
    primitive.shape.disk.radius = radius;
    primitive.xform.forward = make_translation_matrix4(p);
    primitive.xform.inverse = make_translation_matrix4(-p);

    bbox := bounding_box_from_points(p - Vector3.{radius, radius, 0}, p + Vector3.{radius, radius, 0});
    //primitive.bbox = pad_to_minimus(bbox, 0.0001);
    array_add(*scene.tlas.bboxes, bbox);
    primitive.material_id = material_id;
}

add_box :: (scene: *Scene, xform: Matrix4, min: Vector3, max: Vector3, material_id: MaterialID)
{
    _, inv := inverse(xform);

    primitive := add_primitive(scene, .BOX);
    primitive.shape.box.vmin = min;
    primitive.shape.box.vmax = max;
    primitive.xform.forward = xform;
    primitive.xform.inverse = inv;
    bbox := TransformBox(xform, Box3.{min, max});
    array_add(*scene.tlas.bboxes, bbox);
    primitive.material_id = material_id;
}

add_box :: (scene: *Scene, xform: Matrix4, material_id: MaterialID)
{
    add_box(scene, xform, Vector3.{-0.5, -0.5, -0.5}, Vector3.{0.5, 0.5, 0.5}, material_id);
}

add_translated_box :: (scene: *Scene, xform: Matrix4, p: Vector3, q: Vector3, material_id: MaterialID)
{
    pmin := min(p, q);
    pmax := max(p, q);

    dx := Vector3.{pmax.x - pmin.x, 0, 0};
    dy := Vector3.{0, pmax.y - pmin.y, 0};
    dz := Vector3.{0, 0, pmax.z - pmin.z};

    h := 0.5 * (pmin + pmax);
    d := 0.5 * (pmax - pmin);

    add_box(scene, make_translation_matrix4(h) * xform, -d, d, material_id);
}

add_mesh :: (scene: *Scene, xform: Matrix4, mesh: PrimitiveMesh, material_id: MaterialID)
{
    primitive := add_primitive(scene, .MESH);

    primitive.shape.mesh = mesh;

    _, inv := inverse(xform);

    primitive.xform.forward = xform;
    primitive.xform.inverse = inv;

    bbox := Box3_Empty;

    for v: mesh.vertices
    {
        p := TransformPoint(xform, v.p);
        bbox = Union(bbox, p);
    }

    array_add(*scene.tlas.bboxes, bbox);
    primitive.material_id = material_id;
}

create_material :: (scene: *Scene) -> MaterialID, *Material
{
    id       := scene.materials.count.(MaterialID);
    material := array_add(*scene.materials);
    return id, material;
}

create_lambertian_material :: (scene: *Scene, color: Texture2D(Vector3), roughness := 0.0) -> MaterialID
{
    id, material := create_material(scene);
    material.color = color;
    material.diffuse_roughness = texture_value(roughness);
    return id;
}

create_metal_material :: (scene: *Scene, roughness := 0.0) -> MaterialID
{
    id, material := create_material(scene);
    material.metalness = texture_value(1.0);
    material.specular_roughness = texture_value(roughness);
    return id;
}

create_emission_material :: (scene: *Scene, color: Texture2D(Vector3), strength := 1.0) -> MaterialID
{
    id, material := create_material(scene);
    material.emission = color;
    material.emission_strength = texture_value(strength);
    return id;
}

texture_value :: (value: $T) -> Texture2D(T)
{
    texture: Texture2D(T);
    texture.values = .[value, value];
    return texture;
}

texture_vector3 :: (value: Vector3) -> Texture2D(Vector3)
{
    return texture_value(value);
}

texture_checkerboard :: (v0: $T, v1: T, scale: Vector2) -> Texture2D(T)
{
    texture: Texture2D(T);
    texture.values = .[v0, v1];
    texture.scale  = scale;
    texture.flags |= .CHECKERBOARD;
    return texture;
}

init_scene :: (scene: *Scene, width: s32, height: s32, multisamples: u32 = 16, max_depth: s32 = 5)
{
    create_lambertian_material(scene, texture_vector3(.{0, 0, 0}));
    Simp.bitmap_alloc(*scene.bitmap, width, height, .RGBA8);
    scene.bitmap.flags |= .IS_SRGB;

    scene.config.width        = width.(u32);
    scene.config.height       = height.(u32);
    scene.config.multisamples = multisamples;
    scene.config.max_depth    = max_depth;

    CACHE_LINE_SIZE :: 64; // mac?

    scene.rgbx, scene.rgbx_mem = NewArray(scene.config.width * scene.config.height, Vector4, alignment=CACHE_LINE_SIZE);
}

prepare_for_rendering :: (scene: *Scene)
{
    aspect_ratio := scene.config.width.(float) / scene.config.height.(float);
    calculate_camera_transform(*scene.camera, aspect_ratio);
    build_bvh(scene);
}

build_bvh :: (scene: *Scene)
{
    if scene.primitives.count
    {
        array_resize(*scene.tlas.indices, scene.primitives.count, initialize=false);
        array_resize(*scene.tlas.nodes, 2 * scene.primitives.count - 1);

        array_resize(*scene.mapped, scene.primitives.count, initialize=false);

        for *scene.tlas.indices
        {
            it.* = it_index.(u32);
        }

        build_bvh_binned_sah(scene.tlas.nodes, scene.tlas.indices, scene.tlas.bboxes);

        for scene.tlas.indices
        {
            scene.mapped[it_index] = scene.primitives[it];
        }
    }
}

half_area :: (b: Box3) -> float
{
    d := b.vmax - b.vmin;
    res := (d.x * d.y + d.x * d.z + d.y * d.z);
    return res;
}

perspective_projection :: (fov: float, aspect_ratio: float, z_near: float, z_far: float) -> Matrix4
{
    assert(z_near != z_far && fov > 0.0);

    result := Matrix4_Identity;

    tan_theta := tan(fov * PI);
    cot_theta := 1 / tan_theta;

    range := 1 / (z_far - z_near);

    result._11 = cot_theta / aspect_ratio;
    result._22 = cot_theta;
    result._33 = z_far * range;
    result._43 = 1;
    result._34 = -z_far * z_near * range;
    result._44 = 0;

    return result;
}

calculate_camera_transform :: (using camera: *Camera, aspect_ratio: float)
{
    rotation := Matrix4_Identity;
    set_rotation(*rotation, orientation);

    xform.inv_view       = make_translation_matrix4(camera.position) * rotation;
    xform.projection     = perspective_projection(camera.fov, aspect_ratio, 0.01, 1000.0);

    inversed : bool;

    inversed, xform.view = inverse(camera.xform.inv_view);
    inversed, xform.inv_projection = inverse(camera.xform.projection);
}

GenerateRay :: (query: Vector2, camera: CameraTransform, lens_focal_length: float, lens_radius: float) -> Ray
{
    origin := Vector3.{0, 0, 0};
    target := transform_point(camera.inv_projection, Vector3.{ query.x, query.y, 1.0 });

    if lens_radius > 0.0
    {
        u := random_get_zero_to_one_open();
        v := random_get_zero_to_one_open();

        origin.xy = lens_radius * sample_uniform_disk_polar(Vector2.{u, v});

        dir   := normalize(target);
        ft    := lens_focal_length / dir.z;
        focus := ft * dir;
        target = focus;
    }

    origin = transform_point(camera.inv_view, origin);
    target = transform_point(camera.inv_view, target);

    ray: Ray = ---;

    ray.origin = origin;
    ray.dir    = normalize(target - origin);
    ray.tmin   = 0.0;
    ray.tmax   = FLOAT32_INFINITY;

    return ray;
}

sample_stratified_square :: (x: float, y: float, inv_size: float) -> Vector2
{
    px := x + random_get_zero_to_one_open();
    py := y + random_get_zero_to_one_open();

    px *= inv_size;
    py *= inv_size;

    return .{px, py};
}

bounding_box_from_points :: (a : Vector3, b: Vector3) -> Box3
{
    minp := min(a, b);
    maxp := max(a, b);
    return Box3.{minp, maxp};
}

pad_to_minimus :: (b: Box3, padding: float) -> Box3
{
    r := b;
    if (r.vmax.x - r.vmin.x < padding)
    {
        r.vmin.x -= padding;
        r.vmax.x += padding;
    }
    if (r.vmax.y - r.vmin.y < padding)
    {
        r.vmin.y -= padding;
        r.vmax.y += padding;
    }
    if (r.vmax.z - r.vmin.z < padding)
    {
        r.vmin.z -= padding;
        r.vmax.z += padding;
    }
    return r;
}

// @todo: Multithread
radix_sort :: (K: []u32, K_temp: []u32, V: []$T, V_temp: []T, n: s64)
{
    prefix: [256]u32;

    for 0..3
    {
        memset(prefix.data, 0, size_of(type_of(prefix)));

        shift := it * 8;
        for 0..n-1
        {
            bin_index := ((K[it] >> shift) & 0xFF);
            assert(bin_index < prefix.count);
            prefix[bin_index] += 1;
        }

        prev_sum : u32 = 0;

        for 0..prefix.count-1
        {
            sum := prefix[it] + prev_sum;
            prefix[it] = prev_sum;
            prev_sum = sum;
        }

        for 0..n-1
        {
            bin_index := ((K[it] >> shift) & 0xFF);
            offset := prefix[bin_index];
            K_temp[offset] = K[it];
            V_temp[offset] = V[it];
            prefix[bin_index] += 1;
        }

        Swap(*K, *K_temp);
        Swap(*V, *V_temp);
    }
}

triangle_bbox :: (p: Vector3, q: Vector3, r: Vector3) -> Box3
{
    bbox := Box3_Empty;
    bbox = Union(bbox, p);
    bbox = Union(bbox, q);
    bbox = Union(bbox, r);
    return bbox;
}

// https://fgiesen.wordpress.com/2009/12/13/decoding-morton-codes/

split2 :: (x: u32) -> u32
{
    x &= 0X0000FFFF;
    x = (x ^ (x <<  8)) & 0X00FF00FF;
    x = (x ^ (x <<  4)) & 0X0F0F0F0F;
    x = (x ^ (x <<  2)) & 0X33333333;
    x = (x ^ (x <<  1)) & 0X55555555;
    return x;
}

encode_morton2 :: (x: u32, y: u32) -> u32
{
    x_split := split2(x);
    y_split := split2(y);
    code    := (y_split << 1) | x_split;
    return code;
}

split3 :: (x: u32) -> u32
{
    x &= 0x000003ff;
    x = (x ^ (x << 16)) & 0xFF0000FF;
    x = (x ^ (x <<  8)) & 0x0300F00F;
    x = (x ^ (x <<  4)) & 0x030C30C3;
    x = (x ^ (x <<  2)) & 0x09249249;
    return x;
}

encode_morton3 :: (x: u32, y: u32, z: u32) -> u32
{
    x_split := split3(x);
    y_split := split3(y);
    z_split := split3(z);
    code    := (z_split << 2) | (y_split << 1) | x_split;
    return code;
}

SAHBuilder :: struct
{
    nodes     : []BVHNode;
    next_node : u32;
}

build_bvh_sah_binned_recursive :: (builder: *SAHBuilder, root: u32, lo: s64, hi: s64, indices: []u32, bboxes: []Box3, centriods: []Vector3)
{
    assert(hi >= lo);

    node := *builder.nodes[root];

    if (hi == lo)
    {
        node.bbox                     = bboxes[indices[lo]];
        node.first_child_or_primitive = lo.(u32);
        node.num_primitives           = 1;
        return;
    }

    node_bbox     := Box3_Empty;
    centriod_bbox := Box3_Empty;

    for lo..hi
    {
        node_bbox     = Union(node_bbox, bboxes[indices[it]]);
        centriod_bbox = Union(centriod_bbox, centriods[indices[it]]);
    }

    split_axis := 0;
    max_delta  := centriod_bbox.vmax.component[0] - centriod_bbox.vmin.component[0];

    for 1..2
    {
        delta := centriod_bbox.vmax.component[it] - centriod_bbox.vmin.component[it];
        if delta > max_delta
        {
            max_delta = delta;
            split_axis = it;
        }
    }

    if max_delta <= EPSILON || half_area(node_bbox) <= EPSILON
    {
        node.bbox                     = node_bbox;
        node.first_child_or_primitive = lo.(u32);
        node.num_primitives           = (hi - lo + 1).(u32);
        return;
    }

    BIN_COUNT   :: 16;
    SPLIT_COUNT :: BIN_COUNT - 1;

    Bin :: struct
    {
        count: s64;
        bbox : Box3;
    }

    bins: [BIN_COUNT]Bin;

    for *bins
    {
        it.count = 0;
        it.bbox = Box3_Empty;
    }

    idelta := 1.0 / max_delta;
    offset := centriod_bbox.vmin.component[split_axis];

    find_bin_index :: (centriod: Vector3) -> int #expand
    {
        bin_index := (BIN_COUNT * (centriod.component[split_axis] - offset) * idelta).(s64);
        if bin_index >= BIN_COUNT then
            bin_index = BIN_COUNT - 1;
        return bin_index;
    }

    for lo..hi
    {
        bin_index := find_bin_index(centriods[indices[it]]);
        bins[bin_index].count += 1;
        bins[bin_index].bbox = Union(bins[bin_index].bbox, bboxes[indices[it]]);
    }

    split_costs: [SPLIT_COUNT]float;

    prev_count := 0;
    prev_box   := Box3_Empty;

    for 0..SPLIT_COUNT-1
    {
        prev_box = Union(prev_box, bins[it].bbox);
        prev_count += bins[it].count;
        split_costs[it] += prev_count * half_area(prev_box);
    }

    prev_count = 0;
    prev_box   = Box3_Empty;

    for #v2 < 1..SPLIT_COUNT
    {
        prev_box = Union(prev_box, bins[it].bbox);
        prev_count += bins[it].count;
        split_costs[it - 1] += prev_count * half_area(prev_box);
    }

    min_split_cost := split_costs[0];
    min_split_cost_index := 0;

    for 1..SPLIT_COUNT-1
    {
        if (split_costs[it] < min_split_cost)
        {
            min_split_cost = split_costs[it];
            min_split_cost_index = it;
        }
    }

    split_cost  := 0.5 + min_split_cost / half_area(node_bbox);
    leaves_cost := (hi - lo + 1).(float);

    if (split_cost > leaves_cost)
    {
        node.bbox                     = node_bbox;
        node.first_child_or_primitive = lo.(u32);
        node.num_primitives           = (hi - lo + 1).(u32);
        return;
    }

    // partition
    mid := -1;

    {
        i := lo - 1;
        j := hi + 1;

        while 1
        {
            i += 1;

            while i <= hi
            {
                bin_index := find_bin_index(centriods[indices[i]]);
                if bin_index > min_split_cost_index
                    break;
                i += 1;
            }

            j -= 1;

            while j >= lo
            {
                bin_index := find_bin_index(centriods[indices[j]]);
                if bin_index <= min_split_cost_index
                    break;
                j -= 1;
            }

            if i >= j
            {
                mid = j;
                break;
            }

            Swap(*indices[j], *indices[i]);
        }
    }

    assert(mid >= lo && mid < hi);

    next := builder.next_node;
    builder.next_node += 2;

    build_bvh_sah_binned_recursive(builder, next + 0, lo, mid, indices, bboxes, centriods);
    build_bvh_sah_binned_recursive(builder, next + 1, mid + 1, hi, indices, bboxes, centriods);

    node.bbox                     = Union(builder.nodes[next + 0].bbox, builder.nodes[next + 1].bbox);
    node.first_child_or_primitive = next;
    node.num_primitives           = 0;
}

build_bvh_binned_sah :: (nodes: []BVHNode, indices: []u32, bboxes: []Box3)
{
    assert(nodes.count == bboxes.count * 2 - 1 && indices.count == bboxes.count);

    auto_release_temp();

    centriods := NewArray(bboxes.count, Vector3, initialized=false,, temp);

    for bboxes
    {
        centriods[it_index] = 0.5 * (it.vmin + it.vmax);
    }

    builder := SAHBuilder.{nodes, 1};
    build_bvh_sah_binned_recursive(*builder, 0, 0, indices.count - 1, indices, bboxes, centriods);
}

build_blas :: (using mesh: *PrimitiveMesh)
{    
    num_triangles := indices.count / 3;

    array_resize(*blas.bboxes, num_triangles, initialize=false);
    array_resize(*blas.indices, num_triangles, initialize=false);
    array_resize(*blas.nodes, 2 * num_triangles - 1, initialize=false);

    for 0..num_triangles-1
    {
        i0 := indices[it * 3 + 0];
        i1 := indices[it * 3 + 1];
        i2 := indices[it * 3 + 2];

        v0 := vertices[i0].p;
        v1 := vertices[i1].p;
        v2 := vertices[i2].p;

        blas.bboxes[it]  = triangle_bbox(v0, v1, v2);
        blas.indices[it] = it.(u32);
    }

    // @todo: map indices or may be not worth it??
    build_bvh_binned_sah(blas.nodes, blas.indices, blas.bboxes);
}

sign_of :: (v: float) -> float
{
    return ((0 < v).(float) - (v < 0).(float));
}

orthonormal_basis :: (x_axis: Vector3) -> (y_axis: Vector3, z_axis: Vector3)
{
    cross := Vector3.{1, 1, 1};
    if x_axis.x > x_axis.y
    {
        if x_axis.x > x_axis.z
        {
            cross.x = 0;
        }
        else
        {
            cross.z = 0;
        }
    }
    else
    {
        if x_axis.y > x_axis.z
        {
            cross.y = 0;
        }
        else
        {
            cross.z = 0;
        }
    }

    y_axis := cross_product(cross, x_axis);
    normalize(*y_axis, fallback=.{z=1});

    z_axis := cross_product(x_axis, y_axis);
    normalize(*z_axis, fallback=.{z=1});

    return y_axis, z_axis;
}

load_obj_model :: (path: string) -> PrimitiveMesh
{
    auto_release_temp();

    content := read_entire_file(path,,temp);

    vertices  : [..]Vector3;
    normals   : [..]Vector3;
    texcoords : [..]Vector2;

    vertex_indices   : [..]u32;
    normal_indices   : [..]u32;
    texcoord_indices : [..]u32;

    // @todo @cleanup
    // Use Xar or temporary memory/arena
    defer
    {
        array_free(vertices);
        array_free(normals);
        array_free(texcoords);
        array_free(vertex_indices);
        array_free(normal_indices);
        array_free(texcoord_indices);
    }

    while content
    {
        found:, line:, content = split_from_left(content, #char "\n");
        if !found break;

        if starts_with(line, "v ")
        {
            v: Vector3;
            scan2(line, "v % % %", *v.x, *v.y, *v.z);
            array_add(*vertices, v);
        }
        else if starts_with(line, "vt ")
        {
            uv: Vector2;
            scan2(line, "vt % %", *uv.x, *uv.y);
            array_add(*texcoords, uv);
        }
        else if starts_with(line, "vn ")
        {
            n: Vector3;
            scan2(line, "vn % % %", *n.x, *n.y, *n.z);
            array_add(*normals, n);
        }
        else if starts_with(line, "f ")
        {
            parse_face :: (line: string) #expand
            {
                number, success, face := string_to_int(line, T=s32);
                index := ifx number > 0 then (number - 1).(u32) else (vertices.count + number).(u32);
                array_add(*vertex_indices, index);

                if !face return;
                face = slice(face, 1, face.count - 1);

                number, success, face = string_to_int(face, T=s32);
                if success
                {
                    index = ifx number > 0 then (number - 1).(u32) else (texcoords.count + number).(u32);
                    array_add(*texcoord_indices, index);
                }

                if !face return;
                face = slice(face, 1, face.count - 1);

                number, success, face = string_to_int(face, T=s32);
                if success
                {
                    index = ifx number > 0 then (number - 1).(u32) else (normals.count + number).(u32);
                    array_add(*normal_indices, index);
                }
            }

            face1, face2, face3 : string;
            found, line, face3 = split_from_right(line, #char " ");
            found, line, face2 = split_from_right(line, #char " ");
            found, line, face1 = split_from_right(line, #char " ");

            parse_face(face1);
            parse_face(face2);
            parse_face(face3);
        }
    }

    AttrIndex :: struct
    {
        vertex_index   : u32;
        normal_index   : u32;
        texcoord_index : u32;
    }

    hash_attr_index :: (a: AttrIndex) -> u32
    {
        return sdbm_hash((*a).(*void), size_of(AttrIndex));
    }

    compare_attr_index :: (a: AttrIndex, b: AttrIndex) -> bool
    {
        return a.vertex_index == b.vertex_index && a.normal_index == b.normal_index && a.texcoord_index == b.texcoord_index;
    }

    map   : Table(AttrIndex, u32, given_hash_function=hash_attr_index, given_compare_function=compare_attr_index, REFILL_REMOVED=false);
    attrs := NewArray(vertex_indices.count, Vertex3D ,,temp);

    defer deinit(*map); // @todo: Use temporary memory

    indices := NewArray(vertex_indices.count, u32);

    num_attrs := 0;

    for 0..vertex_indices.count-1
    {
        index: AttrIndex;
        index.vertex_index   = vertex_indices[it];
        index.texcoord_index = ifx texcoord_indices texcoord_indices[it] else 0;
        index.normal_index   = ifx normal_indices normal_indices[it] else 0;

        entry, added := find_or_add(*map, index);

        if added
        {
            entry.* = num_attrs.(u32);
            attrs[num_attrs].p  = vertices[index.vertex_index];
            if texcoords
                attrs[num_attrs].uv = texcoords[index.texcoord_index];
            if normals
                attrs[num_attrs].n  = normals[index.normal_index];
            attrs[num_attrs].t = Vector3.{0, 0, 0};
            attrs[num_attrs].b = Vector3.{0, 0, 0};
            num_attrs += 1;
        }

        indices[it] = entry.*;
    }

    mesh: PrimitiveMesh;

    mesh.vertices = array_copy(array_view(attrs, 0, num_attrs));
    mesh.indices  = indices;

    num_triangles := indices.count / 3;

    if !normals
    {
        for 0..num_triangles-1
        {
            v0 := *mesh.vertices[indices[it * 3 + 0]];
            v1 := *mesh.vertices[indices[it * 3 + 1]];
            v2 := *mesh.vertices[indices[it * 3 + 2]];

            e1 := v1.p - v0.p;
            e2 := v2.p - v0.p;

            n  := cross_product(e1, e2);
            n   = normalize(n);

            v0.n = n;
            v1.n = n;
            v2.n = n;
        }
    }

    num_triangles_included := NewArray(num_attrs, u32,,temp);

    for 0..num_triangles-1
    {
        i0 := indices[it * 3 + 0];
        i1 := indices[it * 3 + 1];
        i2 := indices[it * 3 + 2];

        v0 := *mesh.vertices[i0];
        v1 := *mesh.vertices[i1];
        v2 := *mesh.vertices[i2];

        delta_uv1 := v1.uv - v0.uv;
        delta_uv2 := v2.uv - v0.uv;
        det       := delta_uv1.x * delta_uv2.y - delta_uv1.y * delta_uv2.x;
        degen     := abs(det) == 0.0;

        tangent, bitangent : Vector3;

        if (!degen)
        {
            inv_det  := 1.0 / det;
            delta_p1 := v1.p - v0.p;
            delta_p2 := v2.p - v0.p;
            tangent = (delta_p1 * delta_uv2.y - delta_p2 * delta_uv1.y) * inv_det;
            bitangent = (delta_p2 * delta_uv1.x - delta_p1 * delta_uv2.x) * inv_det;
        }

        if (degen || length_squared(cross(tangent, bitangent)) == 0.0)
        {
            normal := normalize((v0.n + v1.n + v2.n) / 3);
            tangent, bitangent = orthonormal_basis(normal);
        }

        v0.t += tangent;
        v1.t += tangent;
        v2.t += tangent;

        v0.b += bitangent;
        v1.b += bitangent;
        v2.b += bitangent;

        num_triangles_included[i0] += 1;
        num_triangles_included[i1] += 1;
        num_triangles_included[i2] += 1;
    }

    for 0..mesh.vertices.count-1
    {
        v := *mesh.vertices[it];

        v.t /= num_triangles_included[it].(float);
        v.b /= num_triangles_included[it].(float);

        v.t = normalize(v.t - v.n * dot(v.t, v.n));
        handedness := ifx (dot(cross(v.n, v.t), v.b) < 0.0) then -1.0 else 1.0;
        v.b = cross(v.n, v.t) * handedness;
    }

    build_blas(*mesh);

    return mesh;
}

CommandLineArgs :: struct
{
    width       := 1920;
    height      := 1080;
    scene       := "";
    num_threads := 0;
}

main :: ()
{
    init();

    success, args := parse_arguments(CommandLineArgs);

    print("args = %\n", args);

    // test code
  //  N :: 200000;
  //  errors : [..]float;
  //  roughness := 0.7;

  //  V := Vector3.{0, 0, 1};

  //  for 0..N
  //  {
    //      u1 := random_get_zero_to_one_open();
    //      u2 := random_get_zero_to_one_open();
  //      sample := cltc_sample(V, roughness, u1, u2);
  //      pdf_a  := cltc_pdf(V, sample.L, roughness);
  //      array_add(*errors, (sample.pdf - pdf_a) / max(pdf_a, 1.0e-9));
  //  }

  //  mean := 0.0;
  //  for errors
  //  {
  //      mean += it * it;
  //  }
  //  mean /= errors.count.(float);
  //  print("RMS : %\n", sqrt(mean));

    MSAA :: 8;

    render_width  = args.width;
    render_height = args.height;

    wnd := create_window(render_width, render_height, "PixL", wanted_msaa = MSAA);

    init_fonts();

    scene: Scene;
    init_scene(*scene, RAYTRACE_BITMAP_WIDTH, RAYTRACE_BITMAP_HEIGHT, multisamples=200, max_depth=5);

    name       := to_upper_copy(args.scene);
    scene_type := SceneType.MATERIAL_TEST;

    info := type_info(SceneType);

    for info.names
    {
        if (name == it)
        {
            scene_type = info.values[it_index].(SceneType);
            break;
        }
    }

    load_scene(*scene, scene_type);
    prepare_for_rendering(*scene);

    wavefront: Wavefront;

    init(*wavefront, *scene, max_threads = args.num_threads.(s32));
    start(*wavefront);

    Simp.prepare_window(wnd, wanted_msaa = MSAA);

    Simp.set_render_target(wnd, .RIGHT_HANDED);

    raytrace_map : Simp.Texture;

    while !should_quit
    {
        memory_visualizer_per_frame_update();

        update_window_events();

        for get_window_resizes()
        {
            Simp.update_window(it.window);

            if it.window == wnd
            {
                should_reinit := (it.width != render_width) || (it.height != render_height);

                render_width  = it.width;
                render_height = it.height;

                if should_reinit then
                    init_fonts();
            }
        }

        for events_this_frame
        {
            if it.type == .QUIT then should_quit = true;

            if it.type ==
            {
              case .KEYBOARD;
                if it.key_pressed && it.key_code == .ESCAPE
                {
                    should_quit = true;
                }

                if it.key_pressed && it.key_code == #char "H"
                {
                    show_debug_bvh = !show_debug_bvh;
                }

                if it.key_pressed && it.key_code == #char " "
                {
                    want_screenshot = true;
                }

                if it.key_pressed && it.key_code == #char "."
                {
                    debug_bvh_depth += 1;
                    if debug_bvh_depth > 255 debug_bvh_depth = 255;
                    print("debug_bvh_depth : %\n", debug_bvh_depth);
                }

                if it.key_pressed && it.key_code == #char ","
                {
                    debug_bvh_depth -= 1;
                    if debug_bvh_depth < 0 debug_bvh_depth = 0;
                    print("debug_bvh_depth : %\n", debug_bvh_depth);
                }
            }
        }

        Simp.texture_load_from_bitmap(*raytrace_map, *scene.bitmap);
        draw_one_frame(wnd, *raytrace_map, scene, wavefront.threads.count);

        sleep_milliseconds(10);

        reset_temporary_storage();
    }

    join(*wavefront);
}

save_screenshot :: (bitmap: Bitmap, screenshot_index: *int)
{
    filepath := tprint("captures/screenshot_%.png", screenshot_index.*);
    print("Saving screenshot: %\n", filepath);
    if (Simp.bitmap_save(*bitmap, filepath))
        screenshot_index.* += 1;
}

draw_rect :: (center: Vector2, w: Vector2, h: Vector2, color: Vector4)
{
    p0 := center - w - h;
    p1 := center + w - h;
    p2 := center + w + h;
    p3 := center - w + h;
    Simp.immediate_quad(p0, p1, p2, p3, color, color, color, color);
}

emboss_line :: (p0: Vector2, p1: Vector2, stroke: float) -> [4]Vector2
{
    corners: [4]Vector2 = ---;
    dx := p1.x - p0.x;
    dy := p1.y - p0.y;
    normal := normalize(Vector2.{-dy, dx});
    corners[0] = p0 - stroke * normal;
    corners[1] = p0 + stroke * normal;
    corners[2] = p1 + stroke * normal;
    corners[3] = p1 - stroke * normal;
    return corners;
}

draw_line :: (a: Vector3, b: Vector3, color: Vector4, projection: Matrix4)
{
    p0 := projection * Vector4.{ a.x, a.y, a.z, 1 };
    p1 := projection * Vector4.{ b.x, b.y, b.z, 1 };

    p0 /= p0.w;
    p1 /= p1.w;

    p0.x *= MAP_RATIO;
    p0.y *= MAP_RATIO;

    p1.x *= MAP_RATIO;
    p1.y *= MAP_RATIO;

    p0 *= 0.5;
    p1 *= 0.5;

    p0 += Vector4.{ 0.5, 0.5, 0.5, 0.5 };
    p1 += Vector4.{ 0.5, 0.5, 0.5, 0.5 };

    p0.x *= (render_width - 1);
    p0.y *= (render_height - 1);
    p1.x *= (render_width - 1);
    p1.y *= (render_height - 1);

    corners := emboss_line(p0.xy, p1.xy, 1);

    Simp.immediate_quad(corners[0], corners[1], corners[2], corners[3], color, color, color, color);
}

draw_triangle :: (v0: Vertex3D, v1: Vertex3D, v2: Vertex3D, color: Vector4, pv: Matrix4, inv_transpose: Matrix4)
{
    light_dir := Vector3.{0, -1, 1};

    light_dir = normalize(light_dir);

    strength1 := max(dot(v0.n, -light_dir), 0.0);
    strength2 := max(dot(v1.n, -light_dir), 0.0);
    strength3 := max(dot(v2.n, -light_dir), 0.0);

    color1 := strength1 * color;
    color2 := strength2 * color;
    color3 := strength3 * color;

    p0 := pv * Vector4.{ v0.p.x, v0.p.y, v0.p.z, 1 };
    p1 := pv * Vector4.{ v1.p.x, v1.p.y, v1.p.z, 1 };
    p2 := pv * Vector4.{ v2.p.x, v2.p.y, v2.p.z, 1 };

    p0 /= p0.w;
    p1 /= p1.w;
    p2 /= p2.w;

    p0.x *= MAP_RATIO;
    p0.y *= MAP_RATIO;

    p1.x *= MAP_RATIO;
    p1.y *= MAP_RATIO;

    p2.x *= MAP_RATIO;
    p2.y *= MAP_RATIO;

    p0 *= 0.5;
    p1 *= 0.5;
    p2 *= 0.5;

    p0 += Vector4.{ 0.5, 0.5, 0.5, 0.0 };
    p1 += Vector4.{ 0.5, 0.5, 0.5, 0.0 };
    p2 += Vector4.{ 0.5, 0.5, 0.5, 0.0 };

    face := cross(p1.xyz - p0.xyz, p2.xyz - p0.xyz);

    if face.z >= 0 then
        return;

    p0.x *= (render_width - 1);
    p0.y *= (render_height - 1);
    p1.x *= (render_width - 1);
    p1.y *= (render_height - 1);
    p2.x *= (render_width - 1);
    p2.y *= (render_height - 1);

    Simp.immediate_triangle(p0.xyz, p1.xyz, p2.xyz, color1, color2, color3);

    //draw_line(v0.p, v1.p, color, projection);
    //draw_line(v1.p, v2.p, color, projection);
    //draw_line(v2.p, v0.p, color, projection);
}

draw_mesh :: (mesh: PrimitiveMesh, color: Vector4, pv: Matrix4, inv_transpose: Matrix4)
{
    num_triangles := mesh.indices.count / 3;

    for 0..num_triangles-1
    {
        i0 := mesh.indices[it * 3 + 0];
        i1 := mesh.indices[it * 3 + 1];
        i2 := mesh.indices[it * 3 + 2];
        draw_triangle(mesh.vertices[i0], mesh.vertices[i1], mesh.vertices[i2], color, pv, inv_transpose);
    }
}

draw_box :: (box: Box3, color: Vector4, projection: Matrix4)
{
    diag := box.vmax - box.vmin;

    dx := Vector3.{diag.x, 0, 0};
    dy := Vector3.{0, diag.y, 0};
    dz := Vector3.{0, 0, diag.z};

    draw_line(box.vmin, box.vmin + dx, color, projection);
    draw_line(box.vmin, box.vmin + dy, color, projection);
    draw_line(box.vmin, box.vmin + dz, color, projection);
    draw_line(box.vmin + dz, box.vmin + dz + dx, color, projection);
    draw_line(box.vmin + dz, box.vmin + dz + dy, color, projection);
    draw_line(box.vmin + dx, box.vmin + dx + dz, color, projection);
    draw_line(box.vmin + dx, box.vmin + dx + dy, color, projection);
    draw_line(box.vmin + dy, box.vmin + dy + dx, color, projection);
    draw_line(box.vmin + dy, box.vmin + dy + dz, color, projection);
    draw_line(box.vmin + dx + dz, box.vmin + dx + dz + dy, color, projection);
    draw_line(box.vmin + dx + dy, box.vmin + dx + dy + dz, color, projection);
    draw_line(box.vmin + dy + dz, box.vmin + dy + dz + dx, color, projection);
}

draw_bvh :: (root: int, nodes: []BVHNode, boxes: []Box3, indices: []u32, projection: Matrix4, depth: int)
{
    using node := nodes[root];

    if num_primitives
    {
        if depth == debug_bvh_depth || debug_bvh_depth == -1
        {
            for 0..num_primitives-1
            {
                index := indices[it + first_child_or_primitive];
                draw_box(boxes[index], Vector4.{1, 1, 1, 1}, projection);
            }
        }
    }
    else
    {
        if depth == debug_bvh_depth || debug_bvh_depth == -1
            draw_box(bbox, Vector4.{1, 1, 1, 1}, projection);

        draw_bvh(first_child_or_primitive + 0, nodes, boxes, indices, projection, depth + 1);
        draw_bvh(first_child_or_primitive + 1, nodes, boxes, indices, projection, depth + 1);
    }
}

draw_one_frame :: (wnd: Window_Type, map: *Simp.Texture, scene: Scene, num_threads: int)
{
    time := seconds_since_init();

    Simp.clear_render_target(.15, .08, .08, 1);

    Simp.set_shader_for_images(map);

    {
        aspect_ratio := RAYTRACE_BITMAP_WIDTH.(float) / RAYTRACE_BITMAP_HEIGHT.(float);

        rect_height := render_height.(float) * MAP_RATIO;
        rect_width := aspect_ratio * rect_height;

        center: Vector2;
        center.x = render_width.(float) / 2;
        center.y = render_height.(float) / 2;

        w := Vector2.{rect_width / 2, 0};
        h := Vector2.{0, rect_height / 2};

        p0 := center - w - h;
        p1 := center + w - h;
        p2 := center + w + h;
        p3 := center - w + h;

        white : = Vector4.{ 1, 1, 1, 1 };
        
        Simp.immediate_quad(p0, p1, p2, p3, white, white, white, white);
    }

    Simp.set_shader_for_color();

    if show_debug_bvh
    {
        //projection_view := scene.camera.xform.projection * scene.camera.xform.view * debug_mesh_xform;
        //draw_bvh(0, scene.tlas.nodes, scene.tlas.bboxes, scene.tlas.indices, projection_view, 0);
        //draw_bvh(0, debug_mesh.blas.nodes, debug_mesh.blas.bboxes, debug_mesh.blas.indices, projection_view, 0);

        //_, inv := inverse(scene.camera.xform.view * debug_mesh_xform);
        //inv_transpose := transpose(inv);

        //draw_mesh(debug_mesh, .{1, 1, 1, 1}, projection_view, inv_transpose);
    }

    secs  := time.(int);
    mins  := secs / 60;
    secs   = secs % 60;
    hours := mins / 60;
    mins   = mins % 60;

    total_runtime := tprint("%:%:%",
                            formatInt(hours, minimum_digits=2),
                            formatInt(mins, minimum_digits=2),
                            formatInt(secs, minimum_digits=2));

    if (white_furnace_test_enabled)
    {
        text := tprint("Frame: %; Last frame render time: %ms; Threads: %; Runtime: %; White Furnace Test dE = %\%, bias = %\%, max error = %",
                       frame_index, last_frame_render_time_ms, num_threads, total_runtime,
                       white_furnace_test_error * 100, white_furnace_test_bias * 100, white_furnace_test_max_error);
        Simp.draw_text(debug_font, 10, 10, text);
    }
    else
    {
        text := tprint("Frame: %; Last frame render time: %ms; Threads: %; Runtime: %",
                       frame_index, last_frame_render_time_ms, num_threads, total_runtime);
        Simp.draw_text(debug_font, 10, 10, text);
    }

    Simp.swap_buffers(wnd);
}

MAP_RATIO :: 0.9;

debug_bvh_depth := -1;
show_debug_bvh := false;
should_quit := false;
render_width := 0;
render_height := 0;

frame_index := 0;
last_frame_render_time_ms := 0;

debug_font: *Simp.Dynamic_Font;

init_fonts :: ()
{
    if render_height <= 0 then return;

    pixel_height := render_height / 54;

    debug_font = Simp.get_font_at_size("data/fonts/KodeMono", "KodeMono-Medium.ttf", pixel_height);
    assert(debug_font != null);
}

find_next_screenshot_index :: (info: *File_Visit_Info, user_data: *void)
{
    screenshot_index := user_data.(*int);
    prefix := "screenshot_";

    if (starts_with(info.short_name, prefix))
    {
        postfix := slice(info.short_name, prefix.count, info.short_name.count - prefix.count);

        postfix_number, success, _ := to_integer(postfix);
        if success && postfix_number > screenshot_index.* then
            screenshot_index.* = postfix_number;
    }
}

get_first_screenshot_index :: (path: string) -> int
{
    screenshot_index := 0;
    make_directory_if_it_does_not_exist(path);
    visit_files(path, false, (*screenshot_index).(*void), find_next_screenshot_index);
    return screenshot_index + 1;
}

init :: ()
{
    #if OS == .WINDOWS
    {
        Windows :: #import "Windows";
        Windows.SetProcessDPIAware();
        Windows.timeBeginPeriod(1);
    }
}

lane_divide :: (count: int) -> int, int
{
    beg := (context.lane.index * count) / context.lane.count;
    end := ((context.lane.index + 1) * count) / context.lane.count;
    return beg, end;
}

lane_sync :: ()
{
    wait_sync_barrier(*context.lane.wavefront.barrier);
}

#import "Basic"()(MEMORY_DEBUGGER=true);
#import "File";
#import "File_Utilities";
#import "Window_Creation";
#import "Input";
#import "Math";
#import "String";
#import "Thread";
#import "System";
#import "Srgb";
#import "Atomics";
#import "Hash_Table";
#import "Hash";
#import "Command_Line";

Simp :: #import "Simp";

#import "Arena";
#import "Raddbg"()(ENABLED=ENABLE_RAD_DEBUGGER);

Windows :: #import "Windows";

ULONG_PTR :: u64; // x64 only
LONG :: s32;

SYNCHRONIZATION_BARRIER  :: struct
{
    Reserved1: Windows.DWORD;
    Reserved2: Windows.DWORD;
    Reserved3: [2]ULONG_PTR;
    Reserved4: Windows.DWORD;
    Reserved5: Windows.DWORD;
}

SyncBarrier :: struct
{
    platform_specific: SYNCHRONIZATION_BARRIER;
}

kernel32 :: #library,system "kernel32";

InitializeSynchronizationBarrier :: (lpBarrier: *SYNCHRONIZATION_BARRIER, lTotalThreads: LONG, lSpinCount: LONG) -> Windows.BOOL #foreign kernel32;
DeleteSynchronizationBarrier :: (lpBarrier: *SYNCHRONIZATION_BARRIER) -> Windows.BOOL #foreign kernel32;
EnterSynchronizationBarrier :: (lpBarrier: *SYNCHRONIZATION_BARRIER, dwFlags: Windows.DWORD) -> Windows.BOOL #foreign kernel32;

init_sync_barrier :: (barrier: *SyncBarrier, num_threads: int)
{
    InitializeSynchronizationBarrier(*barrier.platform_specific, xx num_threads, -1);
}

deinit_sync_barrier :: (barrier: *SyncBarrier)
{
    DeleteSynchronizationBarrier(*barrier.platform_specific);
}

wait_sync_barrier :: (barrier: *SyncBarrier)
{
    EnterSynchronizationBarrier(*barrier.platform_specific, 0);
}
