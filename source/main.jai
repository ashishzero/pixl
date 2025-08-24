#load "raytracer.jai";

RAYTRACE_BITMAP_WIDTH  :: 1280;
RAYTRACE_BITMAP_HEIGHT :: 720;

want_screenshot := false;

reflect :: inline (d: Vector3, n: Vector3) -> Vector3
{
    return d - 2 * dot(d, n) * n;
}

refract :: inline (uv: Vector3, n: Vector3, factor: float) -> Vector3
{
    cos_theta    := min(dot(-uv, n), 1.0);
    out_perp     := factor * (uv + cos_theta * n);
    out_parallel := -sqrt(abs(1.0 - length_squared(out_perp))) * n;
    return out_perp + out_parallel;
}

reflectance :: inline (cosine: float, refraction_index: float) -> float
{
    // Use Schlick's approximation for reflectance.
    r0 := (1 - refraction_index) / (1 + refraction_index);
    r0 = r0 * r0;
    return r0 + (1 - r0) * pow((1 - cosine), 5);
}

sample :: inline (bitmap: Bitmap, u: float, v: float) -> Vector3
{
    if !bitmap.width || !bitmap.height || !bitmap.data.data then
        return .{1, 1, 1};

    Clamp(*u, 0, 1);
    Clamp(*v, 0, 1);

    // TODO: bilinear interpolate
    x := (u * (bitmap.width - 1)).(s32);
    y := (v * (bitmap.height - 1)).(s32);

    index := y * bitmap.stride + x * 4;

    r := bitmap.data[index + 0].(float);
    g := bitmap.data[index + 1].(float);
    b := bitmap.data[index + 2].(float);

    r /= 255;
    g /= 255;
    b /= 255;

    return .{r, g, b};
}

emitted_color_at_hit :: (scene: Scene, hit: HitInfo) -> Vector3
{
    material := scene.materials[hit.material_id];
    color    := material.emission;
    if (material.type == .DIFFUSE_LIGHT)
    {
        color *= sample(material.bitmap, hit.u, hit.v);
    }
    return color;
}

uniform_disk :: (u: float, v: float) -> Vector2
{
    r := sqrt(u);
    theta := 2 * PI * v;
    x := r * cos(theta);
    y := r * sin(theta);
    return .{x, y};
}

uniform_sphere :: (u: float, v: float) -> Vector3
{
    z := 1 - 2 * u;
    r := sqrt(max(0.0, 1.0 - z * z));
    phi := 2 * PI * v;
    return .{r * cos(phi), r * sin(phi), z};
}

uniform_normal :: () -> Vector3
{
    u := random_get_zero_to_one();
    v := random_get_zero_to_one();
    n := uniform_sphere(u, v);
    return n;
}

ScatterInfo :: struct
{
    attenuation : Vector3;
    scattered   : Ray;
    scatter     : bool;
}

scatter :: (scene: Scene, ray: Ray, hit: HitInfo) -> ScatterInfo
{
    info: ScatterInfo;

    material := scene.materials[hit.material_id];

    if #complete material.type ==
    {
        case .LAMBERTIAN;
            n   := hit.n;
            dir := n + uniform_normal();

            if (abs(dir.x) <= EPSILON && abs(dir.y) <= EPSILON)
                dir = n;

            info.scattered.direction = normalize(dir);
            info.scattered.origin = hit.p;
            info.scattered.tmin = 0.001;
            info.scattered.tmax = FLOAT32_MAX;
            info.attenuation = sample(material.bitmap, hit.u, hit.v) * material.albedo;
            info.scatter = true;

        case .METAL;
            reflected := reflect(ray.direction, hit.n);
            dir := reflected;

            info.scatter = true;
        
            if (material.fuzz != 0.0)
            {
                fuzz_vector := uniform_normal();
                dir = normalize(dir) + (material.fuzz * fuzz_vector);

                if (dot(dir, hit.n) <= 0)
                {
                    info.scatter = false;
                }
            }

            if (info.scatter)
            {
                info.scattered.direction = normalize(dir);
                info.scattered.origin = hit.p;
                info.scattered.tmin = 0.001;
                info.scattered.tmax = FLOAT32_MAX;
            }

            info.attenuation = sample(material.bitmap, hit.u, hit.v) * material.albedo;

        case .DIELECTRIC;
            ri := ifx hit.flags & .FRONT_FACE then
                     (1.0 / material.refractive_index)
                else material.refractive_index;

            cos_theta := min(dot(-ray.direction, hit.n), 1.0);
            sin_theta := sqrt(1.0 - cos_theta * cos_theta);

            dir: Vector3;

            should_reflect := ri * sin_theta > 1.0;

            if should_reflect || reflectance(cos_theta, ri) > random_get_zero_to_one()
            {
                dir = reflect(ray.direction, hit.n);
            }
            else
            {
                dir = refract(ray.direction, hit.n, ri);
            }

            info.scattered.direction = normalize(dir);
            info.scattered.origin = hit.p;
            info.scattered.tmin = 0.001;
            info.scattered.tmax = FLOAT32_MAX;
            info.attenuation = sample(material.bitmap, hit.u, hit.v) * material.albedo;

            info.scatter = true;

        case .ISOTROPIC;
            info.scattered.direction = uniform_normal();
            info.scattered.origin = hit.p;
            info.scattered.tmin = 0.001;
            info.scattered.tmax = FLOAT32_MAX;
            info.attenuation = sample(material.bitmap, hit.u, hit.v) * material.albedo;

            info.scatter = true;

        case .DIFFUSE_LIGHT;
            // nothing here
    }

    return info;
}

trace_ray :: (scene: Scene, first_ray: Ray, depth: s32) -> Vector3
{
    color := Vector3.{0, 0, 0};
    throughput := Vector3.{1, 1, 1};

    ray := first_ray;

    for 0..depth-1
    {
        hit, num_visited := intersect(scene, ray);

        if hit.type == .INTERSECT
        {
            emitted := emitted_color_at_hit(scene, hit);
            desc    := scatter(scene, ray, hit);

            color += throughput * emitted;

            if (!desc.scatter)
            {
                break;
            }

            throughput *= desc.attenuation;
            ray = desc.scattered;
        }
        else
        {
            color += throughput * scene.environment;
            break;
        }
    }

    return color;
}

trace_pixel :: (scene: Scene, x: s32, y: s32, num_samples: s32) -> Vector3
{
    inv_sqrt_samples := 1.0 / num_samples.(float);
    sampled := Vector3.{0, 0, 0};

    width  := scene.config.width;
    height := scene.config.height;

    scale  := Vector2.{ 2.0 / (width - 1).(float), 2.0 / (height - 1).(float) };
    shift  := Vector2.{ -1.0, -1.0 };

    for n_y:0..num_samples-1
    {
        for n_x:0..num_samples-1
        {
            offset := sample_stratified_square(n_x.(float), n_y.(float), inv_sqrt_samples);
            sample := Vector2.{ x.(float), y.(float) } + offset;
            query  := sample * scale + shift;
            ray    := generate_ray(query, scene.camera.xform, scene.camera.lens_focal_length, scene.camera.lens_radius);
            color  := trace_ray(scene, ray, scene.config.max_depth);
            sampled += color;
        }
    }

    return sampled;
}

TracePixelWork :: struct
{
    x           : s32;
    y           : s32;
    num_samples : s32;
    color       : Vector3;
}

recursive_trace_pixel_work :: (group: *Thread_Group, thread: *Thread, user_data: *void) -> Thread_Continue_Status
{
    scene := thread.data.(*Scene);
    work := user_data.(*TracePixelWork);
    work.color = trace_pixel(scene, work.x, work.y, work.num_samples);
    return .CONTINUE;
}

render :: (group: *Thread_Group, scene: *Scene, arena: *Arena, frame_index: u64)
{
    width  := scene.config.width;
    height := scene.config.height;

    num_samples := sqrt(scene.config.multisamples.(float32)).(s32);

    for y:0..height-1
    {
        for x:0..width-1
        {
            work := push(arena, TracePixelWork);
            work.x = x.(s32);
            work.y = y.(s32);
            work.num_samples = num_samples;
            add_work(group, work); // FIXME: Calling this in loop explodes memory
        }
    }

    work_remaining := width * height;

    while work_remaining > 0
    {
        sleep_milliseconds(10);

        results := get_completed_work(group);

        for results
        {
            using work := it.(*TracePixelWork);
            index := y * width + x;

            prev_color := scene.rgb[index];
            curr_color := color / (num_samples * num_samples).(float);

            weight := 1.0 / (frame_index.(float) + 1);

            render := lerp(prev_color, curr_color, weight);

            scene.rgb[index] = render;

            //render := scene.rgbn[index].xyz;
            //render /= scene.rgbn[index].w;

            // TODO: HDR mapping
            Clamp(*render.x, 0, 1);
            Clamp(*render.y, 0, 1);
            Clamp(*render.z, 0, 1);

            write_color(*scene.bitmap, x, y, render);
        }

        work_remaining -= results.count;

        reset_temporary_storage();
    }
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
    RANDOM_SPHERES;
    CAR_MESH;
    BASIC_LIGHT;
    CORNELL_BOX;
    CORNELL_CAR;
    RANDOM_SHAPES;
}

raytrace_thread :: (thread: *Thread) -> s64
{
    scene := thread.data.(*Scene);
    
    group: Thread_Group;
    init_thread_group(*group, scene);
    start(*group);

    frame_index : u64 = 0;
    screenshot_index := get_first_screenshot_index("captures");

    while (!should_quit)
    {
        scoped_temp_alloc(scene.scratch);
        render(*group, scene, scene.scratch, frame_index);

        if want_screenshot
        {
            save_screenshot(scene.bitmap, *screenshot_index);
            want_screenshot = false;
        }

        frame_index += 1;
    }

    shutdown(*group);
    return 0;
}

init_thread_group :: (group: *Thread_Group, scene: *Scene)
{
    num_cpus := get_number_of_processors();

    assert(num_cpus >= 1);
    if num_cpus > 200  num_cpus = 200;

    #if (OS == .WINDOWS) || (OS == .LINUX)
    {
        num_cpus /= 2;
    }

    num_threads := max(num_cpus - 1, 2);

    init(group, num_threads, recursive_trace_pixel_work);

    group.logging = false;
    
    for * group.worker_info
    {
        it.thread.data = scene;
        seed: Some_Big_Time_Value;
        apollo := current_time_consensus();
        seed.high = apollo.high;
        seed.low  = apollo.low;
        seed.low += it.thread.index.(u64);
        random_seed(*it.thread.starting_context.random_state, seed);
    }
}

load_scene :: (using scene: *Scene, type: SceneType)
{
    if #complete type ==
    {
        case .RANDOM_SPHERES;

        case .CAR_MESH;

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

            red   := add_lambertian_material(scene, .{0.65, 0.05, 0.05});

            //add_translated_box(scene, xform1, .{-10, -5, -10}, .{5, 5, 25}, red);

            add_sphere(scene, Vector3.{15, 15, 75}, 5, red);

        case .CORNELL_BOX;
            camera.fov           = 40.0 / 360.0;
            camera.position      = .{278, 278, -800};

            camera.lens_focal_length = 1200;
            camera.lens_radius = 10.0;

            environment          = .{0, 0, 0};

            red   := add_lambertian_material(scene, .{0.65, 0.05, 0.05});
            white := add_lambertian_material(scene, .{0.73, 0.73, 0.73});
            green := add_lambertian_material(scene, .{0.12, 0.45, 0.15});
            light := add_diffuse_light(scene, .{15, 15, 15});

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

        case .CORNELL_CAR;

        case .RANDOM_SHAPES;
    }
}

add_primitive :: (scene: *Scene, type: PrimitiveType) -> *Primitive
{
    primitive := array_add(*scene.primitives);
    primitive.type = type;
    return primitive;
}

add_sphere :: (scene: *Scene, xform: Matrix4, radius: float, material_id: MaterialID)
{
    center := transform_point(xform, Vector3.{0, 0, 0});
    _, inv := inverse(xform);

    primitive := add_primitive(scene, .SPHERE);
    array_add(*scene.spheres, .{ radius });
    primitive.xform.forward = xform;
    primitive.xform.inverse = inv;
    primitive.id = (scene.spheres.count - 1).(PrimitiveID);
    bbox: Box3 = ---;
    bbox.vmin = center - Vector3.{radius, radius, radius};
    bbox.vmax = center + Vector3.{radius, radius, radius};
    array_add(*scene.bboxes, bbox);
    primitive.material_id = material_id;
}

add_sphere :: (scene: *Scene, center: Vector3, radius: float, material_id: MaterialID)
{
    xform := make_translation_matrix4(center);
    add_sphere(scene, xform, radius, material_id);
}

add_disk :: (scene: *Scene, p: Vector3, radius: float, material_id: MaterialID)
{
    primitive := add_primitive(scene, .DISK);
    array_add(*scene.disks, DiskDesc.{ radius });
    primitive.xform.forward = make_translation_matrix4(p);
    primitive.xform.inverse = make_translation_matrix4(-p);
    primitive.id = (scene.disks.count - 1).(PrimitiveID);

    bbox := bounding_box_from_points(p - Vector3.{radius, radius, 0}, p + Vector3.{radius, radius, 0});
    //primitive.bbox = pad_to_minimus(bbox, 0.0001);

    primitive.material_id = material_id;
}

add_box :: (scene: *Scene, xform: Matrix4, min: Vector3, max: Vector3, material_id: MaterialID)
{
    _, inv := inverse(xform);

    primitive := add_primitive(scene, .BOX);
    array_add(*scene.boxes, BoxDesc.{ min, max });
    primitive.xform.forward = xform;
    primitive.xform.inverse = inv;
    primitive.id = (scene.boxes.count - 1).(PrimitiveID);
    bbox := transform_box(xform, Box3.{min, max});
    array_add(*scene.bboxes, bbox);
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

add_mesh :: (scene: *Scene, desc: MeshDesc, xform: Matrix4, material_id: MaterialID)
{
    primitive := add_primitive(scene, .MESH);
    array_add(*scene.meshes, desc);

    _, inv := inverse(xform);

    primitive.xform.forward = xform;
    primitive.xform.inverse = inv;
    primitive.id = (scene.meshes.count - 1).(PrimitiveID);

    bbox := Box3_Empty;

    for v: desc.vertices
    {
        p := transform_point(xform, v.p);
        bbox = concat(bbox, p);
    }

    array_add(*scene.bboxes, bbox);
    primitive.material_id = material_id;
}

add_material :: (scene: *Scene, type: MaterialType) -> MaterialID, *Material
{
    id := scene.materials.count.(MaterialID);
    material := array_add(*scene.materials);
    material.type = type;
    return id, material;
}

add_lambertian_material :: (scene: *Scene, albedo: Vector3, bitmap: Bitmap = .{}) -> MaterialID
{
    id, material := add_material(scene, .LAMBERTIAN);
    material.scale = 0.0;
    material.albedo = albedo;
    material.fuzz = 0.0;
    material.refractive_index = 0;
    material.bitmap = bitmap;
    return id;
}

add_metal_material :: (scene: *Scene, albedo: Vector3 = .{1, 1, 1}, fuzz: float = 1.1, bitmap: Bitmap = .{}) -> MaterialID
{
    id, material := add_material(scene, .METAL);
    material.scale = 0.0;
    material.albedo = albedo;
    material.fuzz = fuzz;
    material.refractive_index = 0;
    material.bitmap = bitmap;
    return id;
}

add_dielectric_material :: (scene: *Scene, albedo: Vector3 = .{1, 1, 1}, refractive_index: float = 1.1, bitmap: Bitmap = .{}) -> MaterialID
{
    id, material := add_material(scene, .DIELECTRIC);
    material.scale = 0.0;
    material.albedo = albedo;
    material.fuzz = 0.0;
    material.refractive_index = refractive_index;
    material.bitmap = bitmap;
    return id;
}

add_isotropic_material :: (scene: *Scene, color: Vector3) -> MaterialID
{
    id, material := add_material(scene, .ISOTROPIC);
    material.scale = 0.0;
    material.albedo = color;
    material.fuzz = 0.0;
    material.refractive_index = 0.0;
    material.bitmap = .{};
    return id;
}

add_diffuse_light :: (scene: *Scene, color: Vector3, bitmap : Bitmap = .{}) -> MaterialID
{
    id, material := add_material(scene, .DIFFUSE_LIGHT);
    material.scale = 0.0;
    material.albedo = .{0, 0, 0};
    material.fuzz = 0.0;
    material.refractive_index = 0.0;
    material.emission = color;
    material.bitmap = bitmap;
    return id;
}

init_scene :: (scene: *Scene, width: s32, height: s32, multisamples: u32 = 16, max_depth: s32 = 5)
{
    add_lambertian_material(scene, .{0, 0, 0});
    bitmap_alloc(*scene.bitmap, width, height, .RGBA8);

    scene.config.width        = width.(u32);
    scene.config.height       = height.(u32);
    scene.config.multisamples = multisamples;
    scene.config.max_depth    = max_depth;
    scene.scratch             = make_arena();
    array_resize(*scene.rgb, scene.config.width * scene.config.height);
}

prepare_for_rendering :: (scene: *Scene)
{
    aspect_ratio := scene.config.width.(float) / scene.config.height.(float);
    calculate_camera_transform(*scene.camera, aspect_ratio);
    //calculate_screen_params(scene);
    build_bvh(scene);
}

build_bvh :: (scene: *Scene)
{
    array_resize(*scene.map, scene.primitives.count, initialize=false);
    array_resize(*scene.mapped, scene.primitives.count, initialize=false);
    array_resize(*scene.nodes, 2 * scene.primitives.count - 1);

    for *scene.map
    {
        it.* = it_index.(u32);
    }

    build_bvh_binned_sah(scene.nodes, scene.map, scene.bboxes, scene.scratch);

    for scene.map
    {
        scene.mapped[it_index] = scene.primitives[it];
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

inverse_matrix4 :: (mat: Matrix4) -> Matrix4
{
    result : Matrix4 = ---;

    result.floats[0] = mat.floats[5] * mat.floats[10] * mat.floats[15] - mat.floats[5] * mat.floats[11] * mat.floats[14] -
        mat.floats[9] * mat.floats[6] * mat.floats[15] + mat.floats[9] * mat.floats[7] * mat.floats[14] + mat.floats[13] * mat.floats[6] * mat.floats[11] -
        mat.floats[13] * mat.floats[7] * mat.floats[10];

    result.floats[4] = -mat.floats[4] * mat.floats[10] * mat.floats[15] + mat.floats[4] * mat.floats[11] * mat.floats[14] +
        mat.floats[8] * mat.floats[6] * mat.floats[15] - mat.floats[8] * mat.floats[7] * mat.floats[14] - mat.floats[12] * mat.floats[6] * mat.floats[11] +
        mat.floats[12] * mat.floats[7] * mat.floats[10];

    result.floats[8] = mat.floats[4] * mat.floats[9] * mat.floats[15] - mat.floats[4] * mat.floats[11] * mat.floats[13] - mat.floats[8] * mat.floats[5] * mat.floats[15] +
        mat.floats[8] * mat.floats[7] * mat.floats[13] + mat.floats[12] * mat.floats[5] * mat.floats[11] - mat.floats[12] * mat.floats[7] * mat.floats[9];

    result.floats[12] = -mat.floats[4] * mat.floats[9] * mat.floats[14] + mat.floats[4] * mat.floats[10] * mat.floats[13] +
        mat.floats[8] * mat.floats[5] * mat.floats[14] - mat.floats[8] * mat.floats[6] * mat.floats[13] -
        mat.floats[12] * mat.floats[5] * mat.floats[10] + mat.floats[12] * mat.floats[6] * mat.floats[9];

    result.floats[1] = -mat.floats[1] * mat.floats[10] * mat.floats[15] + mat.floats[1] * mat.floats[11] * mat.floats[14] +
        mat.floats[9] * mat.floats[2] * mat.floats[15] - mat.floats[9] * mat.floats[3] * mat.floats[14] - mat.floats[13] * mat.floats[2] * mat.floats[11] +
        mat.floats[13] * mat.floats[3] * mat.floats[10];

    result.floats[5] = mat.floats[0] * mat.floats[10] * mat.floats[15] - mat.floats[0] * mat.floats[11] * mat.floats[14] -
        mat.floats[8] * mat.floats[2] * mat.floats[15] + mat.floats[8] * mat.floats[3] * mat.floats[14] + mat.floats[12] * mat.floats[2] * mat.floats[11] -
        mat.floats[12] * mat.floats[3] * mat.floats[10];

    result.floats[9] = -mat.floats[0] * mat.floats[9] * mat.floats[15] + mat.floats[0] * mat.floats[11] * mat.floats[13] +
        mat.floats[8] * mat.floats[1] * mat.floats[15] - mat.floats[8] * mat.floats[3] * mat.floats[13] - mat.floats[12] * mat.floats[1] * mat.floats[11] +
        mat.floats[12] * mat.floats[3] * mat.floats[9];

    result.floats[13] = mat.floats[0] * mat.floats[9] * mat.floats[14] - mat.floats[0] * mat.floats[10] * mat.floats[13] -
        mat.floats[8] * mat.floats[1] * mat.floats[14] + mat.floats[8] * mat.floats[2] * mat.floats[13] +
        mat.floats[12] * mat.floats[1] * mat.floats[10] - mat.floats[12] * mat.floats[2] * mat.floats[9];

    result.floats[2] = mat.floats[1] * mat.floats[6] * mat.floats[15] - mat.floats[1] * mat.floats[7] * mat.floats[14] - mat.floats[5] * mat.floats[2] * mat.floats[15] +
        mat.floats[5] * mat.floats[3] * mat.floats[14] + mat.floats[13] * mat.floats[2] * mat.floats[7] - mat.floats[13] * mat.floats[3] * mat.floats[6];

    result.floats[6] = -mat.floats[0] * mat.floats[6] * mat.floats[15] + mat.floats[0] * mat.floats[7] * mat.floats[14] + mat.floats[4] * mat.floats[2] * mat.floats[15] -
        mat.floats[4] * mat.floats[3] * mat.floats[14] - mat.floats[12] * mat.floats[2] * mat.floats[7] + mat.floats[12] * mat.floats[3] * mat.floats[6];

    result.floats[10] = mat.floats[0] * mat.floats[5] * mat.floats[15] - mat.floats[0] * mat.floats[7] * mat.floats[13] - mat.floats[4] * mat.floats[1] * mat.floats[15] +
        mat.floats[4] * mat.floats[3] * mat.floats[13] + mat.floats[12] * mat.floats[1] * mat.floats[7] - mat.floats[12] * mat.floats[3] * mat.floats[5];

    result.floats[14] = -mat.floats[0] * mat.floats[5] * mat.floats[14] + mat.floats[0] * mat.floats[6] * mat.floats[13] +
        mat.floats[4] * mat.floats[1] * mat.floats[14] - mat.floats[4] * mat.floats[2] * mat.floats[13] - mat.floats[12] * mat.floats[1] * mat.floats[6] +
        mat.floats[12] * mat.floats[2] * mat.floats[5];

    result.floats[3] = -mat.floats[1] * mat.floats[6] * mat.floats[11] + mat.floats[1] * mat.floats[7] * mat.floats[10] + mat.floats[5] * mat.floats[2] * mat.floats[11] -
        mat.floats[5] * mat.floats[3] * mat.floats[10] - mat.floats[9] * mat.floats[2] * mat.floats[7] + mat.floats[9] * mat.floats[3] * mat.floats[6];

    result.floats[7] = mat.floats[0] * mat.floats[6] * mat.floats[11] - mat.floats[0] * mat.floats[7] * mat.floats[10] - mat.floats[4] * mat.floats[2] * mat.floats[11] +
        mat.floats[4] * mat.floats[3] * mat.floats[10] + mat.floats[8] * mat.floats[2] * mat.floats[7] - mat.floats[8] * mat.floats[3] * mat.floats[6];

    result.floats[11] = -mat.floats[0] * mat.floats[5] * mat.floats[11] + mat.floats[0] * mat.floats[7] * mat.floats[9] + mat.floats[4] * mat.floats[1] * mat.floats[11] -
        mat.floats[4] * mat.floats[3] * mat.floats[9] - mat.floats[8] * mat.floats[1] * mat.floats[7] + mat.floats[8] * mat.floats[3] * mat.floats[5];

    result.floats[15] = mat.floats[0] * mat.floats[5] * mat.floats[10] - mat.floats[0] * mat.floats[6] * mat.floats[9] - mat.floats[4] * mat.floats[1] * mat.floats[10] +
        mat.floats[4] * mat.floats[2] * mat.floats[9] + mat.floats[8] * mat.floats[1] * mat.floats[6] - mat.floats[8] * mat.floats[2] * mat.floats[5];

    det := mat.floats[0] * result.floats[0] + mat.floats[1] * result.floats[4] + mat.floats[2] * result.floats[8] + mat.floats[3] * result.floats[12];
    det     = 1.0 / det;
    for 0..15
    {
        result.floats[it] = result.floats[it] * det;
    }
    return result;
}

calculate_camera_transform :: (using camera: *Camera, aspect_ratio: float)
{
    rotation := Matrix4_Identity;
    set_rotation(*rotation, orientation);

    xform.inv_view       = make_translation_matrix4(camera.position) * rotation;
    xform.view           = inverse_matrix4(camera.xform.inv_view);
    xform.projection     = perspective_projection(camera.fov, aspect_ratio, 0.01, 1000.0);
    xform.inv_projection = inverse_matrix4(camera.xform.projection);
}

generate_ray :: (query: Vector2, camera: CameraTransform, lens_focal_length: float, lens_radius: float) -> Ray
{
    origin := Vector3.{0, 0, 0};
    target := transform_point(camera.inv_projection, Vector3.{ query.x, query.y, 1.0 });

    if lens_radius > 0.0
    {
        u := random_get_zero_to_one();
        v := random_get_zero_to_one();

        origin.xy = lens_radius * uniform_disk(u, v);

        dir   := normalize(target);
        ft    := lens_focal_length / dir.z;
        focus := ft * dir;

        target = focus - origin;
    }

    origin = transform_point(camera.inv_view, origin);
    dir    := transform_vector(camera.inv_view, target);

    ray: Ray = ---;

    ray.origin    = origin;
    ray.direction = normalize(dir);
    ray.tmin      = 0.0;
    ray.tmax      = FLOAT32_INFINITY;

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

// TODO: Multithread
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
    bbox = concat(bbox, p);
    bbox = concat(bbox, q);
    bbox = concat(bbox, r);
    return bbox;
}

// https://fgiesen.wordpress.com/2009/12/13/decoding-morton-codes/

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
        node_bbox     = concat(node_bbox, bboxes[indices[it]]);
        centriod_bbox = concat(centriod_bbox, centriods[indices[it]]);
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
        bins[bin_index].bbox = concat(bins[bin_index].bbox, bboxes[indices[it]]);
    }

    split_costs: [SPLIT_COUNT]float;

    prev_count := 0;
    prev_box   := Box3_Empty;

    for 0..SPLIT_COUNT-1
    {
        prev_box = concat(prev_box, bins[it].bbox);
        prev_count += bins[it].count;
        split_costs[it] += prev_count * half_area(prev_box);
    }

    prev_count = 0;
    prev_box   = Box3_Empty;

    for #v2 < 1..SPLIT_COUNT
    {
        prev_box = concat(prev_box, bins[it].bbox);
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

    node.bbox                     = concat(builder.nodes[next + 0].bbox, builder.nodes[next + 1].bbox);
    node.first_child_or_primitive = next;
    node.num_primitives           = 0;
}

build_bvh_binned_sah :: (nodes: []BVHNode, indices: []u32, bboxes: []Box3, scratch: *Arena)
{
    assert(nodes.count == bboxes.count * 2 - 1 && indices.count == bboxes.count);

    scoped_temp_alloc(scratch);

    centriods := push_array(scratch, bboxes.count, Vector3, initialized=false);

    for bboxes
    {
        centriods[it_index] = 0.5 * (it.vmin + it.vmax);
    }

    builder := SAHBuilder.{nodes, 1};
    build_bvh_sah_binned_recursive(*builder, 0, 0, indices.count - 1, indices, bboxes, centriods);
}

debug_nodes:   [..]BVHNode;
debug_boxes:   [..]Box3;
debug_indices: [..]u32;

add_bbox :: (x: float, y: float, w: float, h: float)
{
    vmin := Vector3.{x, y, 0};
    vmax := Vector3.{x + w, y + h, 0};
    array_add(*debug_boxes, Box3.{vmin, vmax});
}

build :: ()
{
    if debug_boxes.count == 0 return;

    array_resize(*debug_nodes, debug_boxes.count * 2 - 1);
    array_resize(*debug_indices, debug_boxes.count);

    for *debug_indices
        it.* = it_index.(u32);

    arena := make_arena();

    build_bvh_binned_sah(debug_nodes, debug_indices, debug_boxes, arena);

    free_arena(arena);
}

main :: ()
{
    add_bbox(1550, 440, 50, 50);
    add_bbox(50, 40, 150, 50);
    add_bbox(170, 50, 150, 250);
    add_bbox(860, 440, 200, 200);

    build();

    init();

    MSAA :: 8;

    wnd := create_window(1920, 1080, "PixL", wanted_msaa = MSAA);

    scene: Scene;
    init_scene(*scene, RAYTRACE_BITMAP_WIDTH, RAYTRACE_BITMAP_HEIGHT, multisamples = 50, max_depth=5);
    load_scene(*scene, .CORNELL_BOX);
    prepare_for_rendering(*scene);

    thread: Thread;
    thread.data = *scene;

    thread_init(*thread, raytrace_thread);
    thread_start(*thread);

    prepare_window(wnd, wanted_msaa = MSAA);

    set_render_target(wnd, .LEFT_HANDED);

    raytrace_map : Texture;

    while !should_quit
    {
        memory_visualizer_per_frame_update();

        update_window_events();

        for get_window_resizes()
        {
            update_window(it.window);
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
                    if debug_bvh_depth > scene.nodes.count then debug_bvh_depth = scene.nodes.count;
                    print("debug_bvh_depth : %\n", debug_bvh_depth);
                }

                if it.key_pressed && it.key_code == #char ","
                {
                    debug_bvh_depth -= 1;
                    if debug_bvh_depth < -1 then debug_bvh_depth = -1;
                    print("debug_bvh_depth : %\n", debug_bvh_depth);
                }
            }
        }

        texture_load_from_bitmap(*raytrace_map, *scene.bitmap);
        draw_one_frame(wnd, *raytrace_map, scene);

        sleep_milliseconds(10);

        reset_temporary_storage();
    }

    thread_is_done(*thread);
    thread_deinit(*thread);
}

save_screenshot :: (bitmap: Bitmap, screenshot_index: *int)
{
    filepath := tprint("captures/screenshot_%.png", screenshot_index.*);
    print("Saving screenshot: %\n", filepath);
    if (bitmap_save(*bitmap, filepath))
        screenshot_index.* += 1;
}

draw_rect :: (center: Vector2, w: Vector2, h: Vector2, color: Vector4)
{
    p0 := center - w - h;
    p1 := center + w - h;
    p2 := center + w + h;
    p3 := center - w + h;
    immediate_quad(p0, p1, p2, p3, color, color, color, color);
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

    p0.y = 1 - p0.y;
    p1.y = 1 - p1.y;

    p0.x *= (render_width - 1);
    p0.y *= (render_height - 1);
    p1.x *= (render_width - 1);
    p1.y *= (render_height - 1);

    corners := emboss_line(p0.xy, p1.xy, 1);

    immediate_quad(corners[0], corners[1], corners[2], corners[3], color, color, color, color);
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

draw_one_frame :: (wnd: Window_Type, map: *Texture, scene: Scene)
{
    render_width, render_height = get_render_dimensions(wnd);

    clear_render_target(.15, .08, .08, 1);

    set_shader_for_images(map);

    {
        aspect_ratio := render_width.(float) / render_height.(float);

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
        
        immediate_quad(p0, p1, p2, p3, white, white, white, white);
    }

    set_shader_for_color();

    if show_debug_bvh
    {
        projection_view := scene.camera.xform.projection * scene.camera.xform.view;
        draw_bvh(0, scene.nodes, scene.bboxes, scene.map, projection_view, 0);
    }

    swap_buffers(wnd);
}

MAP_RATIO :: 0.9;

debug_bvh_depth := -1;
show_debug_bvh := true;
should_quit := false;
render_width := 0;
render_height := 0;

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

#import "Basic"()(MEMORY_DEBUGGER=true);
#import "File";
#import "File_Utilities";
#import "Simp";
#import "Window_Creation";
#import "Input";
#import "Math";
#import "String";
#import "Thread";
#import "System";
#import "Srgb";

#import "Arena";
#import "Raddbg";
