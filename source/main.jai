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

recusively_trace :: (scene: Scene, ray: Ray, depth: s32) -> Vector3
{
    if (depth <= 0)
        return Vector3.{0, 0, 0};

    hit := intersect(scene, ray);

    if hit.type == .INTERSECT
    {
        //return Vector3.{info.u, info.v, 0.0f};
        //return hit.n * 0.5 + Vector3.{0.5, 0.5, 0.5};

        emitted := emitted_color_at_hit(scene, hit);
        desc    := scatter(scene, ray, hit);

        if (!desc.scatter)
        {
            return emitted;
        }

        traced := recusively_trace(scene, desc.scattered, depth - 1);
        color  := traced * desc.attenuation + emitted;
        return color;
    }

    return scene.environment;
}

recursively_trace_pixel :: (scene: Scene, x: u32, y: u32) -> Vector3
{
    sqrt_samples := sqrt(scene.config.multisamples.(float32)).(u32);
    inv_sqrt_samples := 1.0 / sqrt_samples.(float32);

    color := Vector3.{0, 0, 0};

    for n_y:0..sqrt_samples-1
    {
        for n_x:0..sqrt_samples-1
        {
            offset := sample_stratified_square(n_x.(float), n_y.(float), inv_sqrt_samples);

            query: Vector2;
            query.x = x.(float) + offset.x;
            query.y = y.(float) + offset.y;

            ray := generate_ray(scene.camera, scene.screen, query);
            color += recusively_trace(scene, ray, scene.config.max_depth);
        }
    }

    return color;
}

write_color :: (bitmap: *Bitmap, x: int, y: int, linear: Vector3)
{
    index := y * bitmap.stride + x * 4;

    color := linear_to_srgb(linear);

    r := (color.x * 255).(u8);
    g := (color.y * 255).(u8);
    b := (color.z * 255).(u8);

    bitmap.data[index + 0] = r;
    bitmap.data[index + 1] = g;
    bitmap.data[index + 2] = b;
    bitmap.data[index + 3] = 0xFF;
}

render :: (scene: Scene)
{
    width  := scene.config.width;
    height := scene.config.height;

    for y:0..height-1
    {
        for x:0..width-1
        {
            color := recursively_trace_pixel(scene, x, y);
            index := y * width + x;

            scene.rgbn[index].xyz += color;
            scene.rgbn[index].w += 1;

            render := scene.rgbn[index].xyz;
            render /= scene.rgbn[index].w;

            // TODO: HDR mapping
            Clamp(*render.x, 0, 1);
            Clamp(*render.y, 0, 1);
            Clamp(*render.z, 0, 1);

            write_color(*scene.bitmap, x, y, render);
        }
    }
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
    bitmap := thread.data.(*Bitmap);

    scene: Scene;
    init_scene(*scene, bitmap.*);
    load_scene(*scene, .CORNELL_BOX);

    prepare_for_rendering(*scene);

    while (!should_quit)
    {
        render(scene);

  //      {
  //          for y:0..bitmap.height - 1 {
  //              for x:0..bitmap.width - 1 {
  //                  it : = y * bitmap.stride + x * 4;
  //                  bitmap.data[it + 0] = 0x00;
  //                  bitmap.data[it + 1] = 0xFF;
  //                  bitmap.data[it + 2] = 0x00;
  //                  bitmap.data[it + 3] = 0xFF;
  //              }
  //          }
  //      }

        if want_screenshot {
            save_screenshot(bitmap);
            want_screenshot = false;
        }
    }

    return 0;
}

load_scene :: (using scene: *Scene, type: SceneType)
{
    if #complete type ==
    {
        case .RANDOM_SPHERES;

        case .CAR_MESH;

        case .BASIC_LIGHT;

        case .CORNELL_BOX;
            camera.fov           = 40.0 / 360.0;
            camera.position      = .{278, 278, -800};
            camera.target        = .{278, 278, 0};
            camera.defocus_angle = 0;

            environment          = .{0, 0, 0};

            red   := add_lambertian_material(scene, .{0.65, 0.05, 0.05});
            white := add_lambertian_material(scene, .{0.73, 0.73, 0.73});
            green := add_lambertian_material(scene, .{0.12, 0.45, 0.15});
            light := add_diffuse_light(scene, .{15, 15, 15});

            add_box(scene, Matrix4_Identity, .{555, 0, 0}, .{555.01, 555, 555}, green);
            add_box(scene, Matrix4_Identity, .{0, 0, 0}, .{0.01, 555, 555}, red);
            add_box(scene, Matrix4_Identity, .{213, 554, 227}, .{343, 554.01, 332}, light);
            add_box(scene, Matrix4_Identity, .{0, 0, 0}, .{555, 0.01, 555}, white);
            add_box(scene, Matrix4_Identity, .{0, 555, 0}, .{555, 555.01, 555}, white);
            add_box(scene, Matrix4_Identity, .{0, 0, 555}, .{555, 555, 555.01}, white);

            rot1, rot2: Quaternion;

            set_from_axis_and_angle(*rot1, 0, 1, 0, -18.0 / 360.0 * 2 * PI);
            set_from_axis_and_angle(*rot2, 0, 1, 0, 15.0 / 360.0 * 2 * PI);

            xform1 := rotation_matrix(Matrix4, rot1);
            xform2 := rotation_matrix(Matrix4, rot2);

            add_translated_box(scene, xform1, .{130, 0, 65}, .{295, 165, 230}, white);
            add_translated_box(scene, xform2, .{265, 0, 295}, .{430, 330, 460}, white);

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
    primitive.bbox.min = center - Vector3.{radius, radius, radius};
    primitive.bbox.max = center + Vector3.{radius, radius, radius};
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
    primitive.bbox = pad_to_minimus(bbox, 0.0001);

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
    primitive.bbox = transform_box(xform, Box3.{min, max});
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

    add_box(scene, translate(xform, h), -d, d, material_id);
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

    primitive.bbox = bbox;
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

init_scene :: (scene: *Scene, bitmap: Bitmap, multisamples: u32 = 16, max_depth: s32 = 5)
{
    add_lambertian_material(scene, .{0, 0, 0});
    scene.bitmap = bitmap;

    scene.config.width        = bitmap.width.(u32);
    scene.config.height       = bitmap.height.(u32);
    scene.config.multisamples = multisamples;
    scene.config.max_depth    = max_depth;

    array_resize(*scene.rgbn, scene.config.width * scene.config.height);
}

prepare_for_rendering :: (scene: *Scene)
{
    calculate_screen_params(scene);
    build_bounding_volume_hierarchy(scene);
}

build_bounding_volume_hierarchy :: (scene: *Scene)
{
    array_resize(*scene.map, scene.primitives.count, initialize=false);
    array_resize(*scene.mapped, scene.primitives.count, initialize=false);
    array_resize(*scene.nodes, 2 * scene.primitives.count + 1);

    for *scene.map
    {
        it.* = it_index.(u32);
    }
    
    build_bounding_volume_hierarchy(scene.nodes, scene.map, scene.primitives);

    for scene.map
    {
        scene.mapped[it_index] = scene.primitives[it];
    }
}

partition :: (A: []$T, lo: int, hi: int, user: $U, $compare: (T, U) -> bool) -> int
{
    i := lo - 1;
    j := hi + 1;

    while 1
    {
        i += 1;

        while compare(A[i], user)
        {
            i += 1;
        }

        j -= 1;

        while !compare(A[j], user)
        {
            j -= 1;
        }

        if i >= j then
            return j;

        Swap(*A[j], *A[i]);
    }

    return -1; // compiler warning
}

build_bounding_volume_hierarchy :: (nodes: []BVHNode, indices: []u32, primitives: []Primitive)
{
    assert(nodes.count >= primitives.count * 2 + 1 && indices.count == primitives.count);

    BUCKET_COUNT :: 12;
    SPLIT_COUNT :: BUCKET_COUNT - 1;
    
    HierarchicalBVH :: struct
    {
        nodes     : []BVHNode;
        next_node : u32;
    }
    
    BVHSplitBucket :: struct
    {
        count: u32;
        bbox : Box3;
    }

    next_children_nodes :: (bvh: *HierarchicalBVH) -> u32
    {
        index := bvh.next_node;
        bvh.next_node += 2;
        return index;
    }

    build_bounding_volume_hierarchy_recurse :: (bvh: *HierarchicalBVH, root: u32, lo: s64, hi: s64, id_map: []u32, primitives: []Primitive)
    {
        num_primitives := hi - lo + 1;

        if (num_primitives <= 1)
        {
            node := *bvh.nodes[root];
            node.bbox                     = Box3_Empty;
            node.first_child_or_primitive = lo.(u32);
            node.num_primitives           = max(0, num_primitives).(u32);

            if (num_primitives >= 1)
            {
                node.bbox = primitives[id_map[lo]].bbox;
            }
        }
        else if (num_primitives == 2)
        {
            next := next_children_nodes(bvh);
            build_bounding_volume_hierarchy_recurse(bvh, next + 0, lo, lo, id_map, primitives);
            build_bounding_volume_hierarchy_recurse(bvh, next + 1, hi, hi, id_map, primitives);

            bvh.nodes[root].bbox = concat(bvh.nodes[next + 0].bbox, bvh.nodes[next + 1].bbox);
            bvh.nodes[root].first_child_or_primitive = next;
            bvh.nodes[root].num_primitives = 0;
        }
        else
        {
            node_box     := Box3_Empty;
            centroid_box := Box3_Empty;

            for primitive_id: lo..hi
            {
                bbox := primitives[id_map[primitive_id]].bbox;
                centroid := 0.5 * (bbox.min + bbox.max);
                centroid_box = concat(centroid_box, centroid);
                node_box     = concat(node_box, bbox);
            }

            axis  := max_axis(centroid_box);
            daxis := centroid_box.max.component[axis] - centroid_box.min.component[axis];

            if (daxis < EPSILON || half_area(node_box) <= EPSILON)
            {
                node := *bvh.nodes[root];
                node.first_child_or_primitive = lo.(u32);
                node.num_primitives           = num_primitives.(u32);
                node.bbox                     = node_box;
            }
            else
            {
                buckets: [BUCKET_COUNT]BVHSplitBucket;

                for *buckets
                {
                    it.count = 0;
                    it.bbox  = Box3_Empty;
                }
                
                idiv := 1.0 / daxis;

                for primitive_id: lo..hi
                {
                    bbox     := primitives[id_map[primitive_id]].bbox;
                    centriod := 0.5 * (bbox.min.component[axis] + bbox.max.component[axis]);
                    bucket   := (BUCKET_COUNT * (centriod - centroid_box.min.component[axis]) * idiv).(u32);

                    if bucket >= BUCKET_COUNT then
                        bucket = BUCKET_COUNT  - 1;

                    buckets[bucket].count += 1;
                    buckets[bucket].bbox = concat(buckets[bucket].bbox, bbox);
                }

                costs: [SPLIT_COUNT]float;

                prev_count := 0;
                prev_box   := Box3_Empty;

                for 0..SPLIT_COUNT-1
                {
                    prev_box = concat(prev_box, buckets[it].bbox);
                    prev_count += buckets[it].count;
                    costs[it] += prev_count * half_area(prev_box);
                }

                prev_count = 0;
                prev_box   = Box3_Empty;

                for #v2 < SPLIT_COUNT..1
                {
                    prev_box = concat(prev_box, buckets[it].bbox);
                    prev_count += buckets[it].count;
                    costs[it - 1] += prev_count * half_area(prev_box);
                }

                min_cost := costs[0];
                min_cost_index := 0;

                for 1..SPLIT_COUNT-1
                {
                    if (costs[it] < min_cost)
                    {
                        min_cost = costs[it];
                        min_cost_index = it;
                    }
                }

                leaf_cost := num_primitives.(float);
                min_cost   = 0.5 + min_cost / half_area(node_box);

                if (min_cost < leaf_cost)
                {
                    SAHPartition :: struct
                    {
                        primitives     : []Primitive;
                        centroid_box   : Box3;
                        axis           : s32;
                        idiv           : float;
                        min_cost_index : s64;
                    }

                    part_compare :: (primitive_id: u32, using p: SAHPartition) -> bool
                    {
                        bbox := primitives[primitive_id].bbox;
                        centriod := 0.5 * (bbox.min.component[axis] + bbox.max.component[axis]);
                        bucket   := (BUCKET_COUNT * (centriod - centroid_box.min.component[axis]) * idiv).(s32);
                        if bucket >= BUCKET_COUNT then
                            bucket = BUCKET_COUNT - 1;
                        return bucket <= min_cost_index;
                    }

                    sah := SAHPartition.{ primitives, centroid_box, axis, idiv, min_cost_index };
                    mid := partition(id_map, lo, hi, sah, part_compare);

                    assert(mid >= lo && mid < hi);

                    next := next_children_nodes(bvh);

                    build_bounding_volume_hierarchy_recurse(bvh, next + 0, lo, mid, id_map, primitives);
                    build_bounding_volume_hierarchy_recurse(bvh, next + 1, mid + 1, hi, id_map, primitives);

                    bvh.nodes[root].bbox = concat(bvh.nodes[next + 0].bbox, bvh.nodes[next + 1].bbox);
                    bvh.nodes[root].first_child_or_primitive = next;
                    bvh.nodes[root].num_primitives = 0;
                }
                else
                {
                    node := *bvh.nodes[root];
                    node.bbox                     = node_box;
                    node.first_child_or_primitive = lo.(u32);
                    node.num_primitives           = num_primitives.(u32);
                }
            }
        }
    }

    bvh:= HierarchicalBVH.{ nodes, 1 };
    build_bounding_volume_hierarchy_recurse(*bvh, 0, 0, indices.count - 1, indices, primitives);
}

max_axis :: (b: Box3) -> s32
{
    d := b.max - b.min;
    if (d.x > d.y && d.x > d.z)
        return 0;
    else if (d.y > d.z)
        return 1;
    else
        return 2;
}

half_area :: (b: Box3) -> float
{
    d := b.min - b.min;
    return (d.x * d.y + d.x * d.z + d.y * d.z);
}

calculate_screen_params :: (using scene: *Scene)
{
    width  := scene.config.width.(float);
    height := scene.config.height.(float);

    aspect_ratio := width / height;

    h := tan(camera.fov * PI);

    vp_h := 2 * h * camera.focus_distance;
    vp_w := vp_h * aspect_ratio;

    world_up := Vector3.{0, 1, 0};

    w := normalize(camera.position - camera.target);
    u := normalize(cross(world_up, w));
    v := cross(w, u);

    vp_u := vp_w * u;
    vp_v := -vp_h * v;

    du := vp_u / width;
    dv := vp_v / height;

    vp_tl := camera.position - w * camera.focus_distance - 0.5 * (vp_u + vp_v);
    pixel_00 := vp_tl + 0.5 * (du + dv);

    defocus_radius := camera.focus_distance * tan(camera.defocus_angle * PI);

    defocus_disk_u := defocus_radius * u;
    defocus_disk_v := defocus_radius * v;

    params := *scene.screen;

    params.center = pixel_00;
    params.du = du;
    params.dv = dv;
    params.defocus_disk[0] = defocus_disk_u;
    params.defocus_disk[1] = defocus_disk_v;
}

generate_ray :: (camera: Camera, params: ScreenParams, query: Vector2) -> Ray
{
    pixel := params.center + (query.y * params.dv) + (query.x * params.du);
    origin := camera.position;

    if (camera.defocus_angle > 0)
    {
        u := random_get_zero_to_one();
        v := random_get_zero_to_one();
        p := uniform_disk(u, v);
        origin += p.x * params.defocus_disk[0];
        origin += p.y * params.defocus_disk[1];
    }

    dir := normalize(pixel - origin);
    ray := Ray.{ origin = origin, direction = dir, tmin = 0.0, tmax = FLOAT32_INFINITY };
    return ray;
}

sample_stratified_square :: (x: float, y: float, inv_size: float) -> Vector2
{
    px := x + random_get_zero_to_one();
    py := y + random_get_zero_to_one();

    px *= inv_size;
    py *= inv_size;

    px -= 0.5;
    py -= 0.5;

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
    if (r.max.x - r.min.x < padding)
    {
        r.min.x -= padding;
        r.max.x += padding;
    }
    if (r.max.y - r.min.y < padding)
    {
        r.min.y -= padding;
        r.max.y += padding;
    }
    if (r.max.z - r.min.z < padding)
    {
        r.min.z -= padding;
        r.max.z += padding;
    }
    return r;
}

main :: () {
    init();

    MSAA :: 8;

    wnd := create_window(1920, 1080, "PixL", wanted_msaa = MSAA);

    raytrace_bitmap  :Bitmap;

    bitmap_alloc(*raytrace_bitmap, RAYTRACE_BITMAP_WIDTH, RAYTRACE_BITMAP_HEIGHT, .RGBA8);

    thread: Thread;
    thread.data = *raytrace_bitmap;

    thread_init(*thread, raytrace_thread);
    thread_start(*thread);

    prepare_window(wnd, wanted_msaa = MSAA);

    set_render_target(wnd, .LEFT_HANDED);

    raytrace_map : Texture;

    while !should_quit {
        update_window_events();

        for get_window_resizes() {
            update_window(it.window);
        }

        for events_this_frame {
            if it.type == .QUIT then should_quit = true;

            if it.type == {
              case .KEYBOARD;
                if it.key_pressed && it.key_code == .ESCAPE {
                    should_quit = true;
                }

                if it.key_pressed && it.key_code == #char " " {
                    want_screenshot = true;
                }
            }
        }

        texture_load_from_bitmap(*raytrace_map, *raytrace_bitmap);

        draw_one_frame(wnd, *raytrace_map);

        sleep_milliseconds(10);

        reset_temporary_storage();
    }

    thread_deinit(*thread);
}

save_screenshot :: (bitmap: Bitmap)
{
    screenshot_index += 1;            
    filepath := tprint("captures/screenshot_%.png", screenshot_index);
    print("Saving screenshot: %\n", filepath);
    bitmap_save(*bitmap, filepath);
}

draw_one_frame :: (wnd: Window_Type, map : *Texture)
{
    window_width, window_height := get_render_dimensions(wnd);

    clear_render_target(.15, .08, .08, 1);

    set_shader_for_images(map);

    time := seconds_since_init();

    {
        map_ratio := 0.8;

        aspect_ratio := window_width.(float) / window_height.(float);

        rect_height := window_height.(float) * map_ratio;
        rect_width := aspect_ratio * rect_height;

        center: Vector2;
        center.x = window_width.(float) / 2;
        center.y = window_height.(float) / 2;

        w := Vector2.{rect_width / 2, 0};
        h := Vector2.{0, rect_height / 2};

        p0 := center - w - h;
        p1 := center + w - h;
        p2 := center + w + h;
        p3 := center - w + h;

        white : = Vector4.{ 1, 1, 1, 1 };
        
        immediate_quad(p0, p1, p2, p3, white, white, white, white);
    }

    swap_buffers(wnd);
}

should_quit := false;
screenshot_index : s64;

find_next_screenshot_index :: (info: *File_Visit_Info, user_data: *void) {
    prefix := "screenshot_";

    if (starts_with(info.short_name, prefix)) {
        postfix := slice(info.short_name, prefix.count, info.short_name.count - prefix.count);

        postfix_number, success, _ := to_integer(postfix);
        if success && postfix_number > screenshot_index then
            screenshot_index = postfix_number;
    }
}

init :: () {
    #if OS == .WINDOWS {
        Windows :: #import "Windows";
        Windows.SetProcessDPIAware();
        Windows.timeBeginPeriod(1);
    }

    make_directory_if_it_does_not_exist("captures");

    visit_files("captures", false, null, find_next_screenshot_index);
}

#import "Basic";
#import "File";
#import "File_Utilities";
#import "Simp";
#import "Window_Creation";
#import "Input";
#import "Math";
#import "String";
#import "Thread";
#import "Srgb";
