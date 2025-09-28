#load "primitives.jai";

MaterialID  :: #type,distinct u32;
PrimitiveID :: #type,distinct u32;

Box3 :: struct
{
    vmin: Vector3;
    vmax: Vector3;
}

Transform :: struct
{
    forward: Matrix4;
    inverse: Matrix4;
}

Primitive :: struct
{
    type        : PrimitiveType;
    xform       : Transform;
    id          : PrimitiveID;
    material_id : MaterialID;
}

MaterialType :: enum u32
{
    LAMBERTIAN    :: 0;
    METAL         :: 1;
    DIELECTRIC    :: 2;
    ISOTROPIC     :: 3;
    DIFFUSE_LIGHT :: 4;
}

Bitmap :: Simp.Bitmap;

SamplerType :: enum
{
    NONE;
    BITMAP;
    CHECKERBOARD;
}

Checker :: struct
{
    colors : [2]Vector3;
    scale  : Vector2;
}

Sampler :: struct
{
    type: SamplerType;

    union
    {
        bitmap  : Bitmap;
        checker : Checker;
    }
}

Material :: struct
{
    color           : Vector3;
    subsurface      : float;
    metallic        : float;
    specular        : float;
    specular_tint   : float;
    roughness       : float;
    anisotropic     : float;
    sheen           : float;
    sheen_tint      : float;
    clearcoat       : float;
    clearcoat_gloss : float;
    sampler         : Sampler;
}

MaterialOld :: struct
{
    type             : MaterialType;
    scale            : float;
    albedo           : Vector3;
    emission         : Vector3;
    fuzz             : float;
    refractive_index : float;
    sampler          : Sampler;
}

BVHNode :: struct
{
    bbox                     : Box3;
    first_child_or_primitive : u32;
    num_primitives           : u32;
}

Camera :: struct
{
    position           : Vector3;
    orientation        : Quaternion;
    fov                := 0.17;
    z_near             := 0.001;
    z_far              := 1000.0;
    lens_focal_length  := 10.0;
    lens_radius        := 0.0;

    xform              : CameraTransform;
}

CameraTransform :: struct
{
    view           : Matrix4;
    inv_view       : Matrix4;
    projection     : Matrix4;
    inv_projection : Matrix4;
}

PathTracerConfig :: struct
{
    width        : int = 1280;
    height       : int = 720;
    multisamples : u32 = 16;
    max_depth    : s32 = 5;
}

AccelerationStructure :: struct
{
    // @todo: Make these array view
    nodes      : [..]BVHNode;
    indices    : [..]u32;
    bboxes     : [..]Box3; // @todo: Not needed remove!!
}

Scene :: struct
{
    camera: Camera;
    config: PathTracerConfig;
    bitmap: Bitmap;

    materials_old : [..]MaterialOld;
    materials     : [..]Material;
    environment := Vector3.{0.7, 0.8, 1.0};

    primitives : [..]Primitive;
    spheres    : [..]SphereDesc;
    disks      : [..]DiskDesc;
    boxes      : [..]BoxDesc;
    meshes     : [..]MeshDesc;

    tlas       : AccelerationStructure;
    mapped     : [..]Primitive;

    rgbx_mem   : *void;
    rgbx       : []Vector4;
}

HitType :: enum u32
{
    MISSED;
    INTERSECT;
}

HitInfo :: struct
{
    type            : HitType;
    material_id     : MaterialID;
    using intersect : IntersectInfo;
}

#scope_file

intersect_primitive :: (scene: Scene, primitive: Primitive, origin: Vector3, direction: Vector3, tmin: float, tmax: float) -> HitInfo
{
    ray: Ray;
    ray.tmin      = tmin;
    ray.tmax      = tmax;
    ray.origin    = transform_point(primitive.xform.inverse, origin);
    ray.direction = transform_vector(primitive.xform.inverse, direction);

    info: HitInfo = .{};

    hit := false;
    if #complete primitive.type ==
    {
        case .SPHERE;
            hit, info.intersect = intersect_sphere(scene.spheres[primitive.id], ray);

        case .DISK;
            hit, info.intersect = intersect_disk(scene.disks[primitive.id], ray);

        case .BOX;
            hit, info.intersect = intersect_box(scene.boxes[primitive.id], ray);

        case .MESH;
            hit, info.intersect = intersect_mesh(scene.meshes[primitive.id], ray);
    }

    if (hit)
    {
        // @todo: May be transform the minimum hit only??
        info.type         = .INTERSECT;
        info.material_id  = primitive.material_id;
        info.p            = transform_point(primitive.xform.forward, info.p);
        info.n            = transform_vector(transpose(primitive.xform.inverse), info.n);
        info.n            = normalize(info.n);
        info.dpdu         = transform_vector(primitive.xform.forward, info.dpdu);
        info.dpdv         = transform_vector(primitive.xform.forward, info.dpdv);
    }

    return info;
}

#scope_export

// @todo: Remove scene from here
intersect_bvh :: (nodes: []BVHNode, primitives: []Primitive, ray: Ray, scene: Scene) -> HitInfo, int
{
    if nodes.count
    {
        nodes_stack : [64]u32 = ---;

        top : u32 = 1;
        nodes_stack[0] = 0;

        visited := 0;

        info := HitInfo.{ type = .MISSED };

        origin  := ray.origin;
        dir     := ray.direction;
        inv_dir := Vector3.{1.0 / dir.x, 1.0 / dir.y, 1.0 / dir.z};
        tmin    := ray.tmin;
        tmax    := ray.tmax;

        while top > 0
        {
            top -= 1;
            node := nodes[nodes_stack[top]];

            visited += 1;

            if (hits(origin, inv_dir, node.bbox, tmin, tmax))
            {
                if (node.num_primitives)
                {
                    for 0..node.num_primitives-1
                    {
                        primitive := primitives[node.first_child_or_primitive + it];
                        current := intersect_primitive(scene, primitive, origin, dir, tmin, tmax);
                        if (current.type == .INTERSECT)
                        {
                            tmax = current.t;
                            info = current;
                        }
                    }
                }
                else
                {
                    assert(top + 2 < nodes_stack.count);
                    nodes_stack[top + 0] = node.first_child_or_primitive + 1;
                    nodes_stack[top + 1] = node.first_child_or_primitive + 0;
                    top += 2;
                }
            }
        }

        return info, visited;
    }
    else
    {
        return .{}, 0;
    }
}

intersect :: (scene: Scene, ray: Ray) -> HitInfo, int
{
    hit, num_visited := intersect_bvh(scene.tlas.nodes, scene.mapped, ray, scene);
    return hit, num_visited;
}

#import "Random";
