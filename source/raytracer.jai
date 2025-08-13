#load "primitives.jai";

MaterialID  :: #type,distinct u64;
PrimitiveID :: #type,distinct u64;

Box3 :: struct
{
    min: Vector3;
    max: Vector3;
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
    bbox        : Box3;
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

Material :: struct
{
    type             : MaterialType;
    scale            : float;
    albedo           : Vector3;
    emission         : Vector3;
    fuzz             : float;
    refractive_index : float;
    bitmap           : Bitmap;
}

BVHNode :: struct
{
    bbox                     : Box3;
    first_child_or_primitive : u32;
    num_primitives           : u32;
}

Camera :: struct
{
    position       : Vector3 = .{0, 0, 0};
    target         : Vector3 = .{0, 0, -1};
    fov            : float   = 0.17;
    focus_distance : float   = 10.0;
    defocus_angle  : float   = 0.0;
}

RenderConfig :: struct
{
    width        : u32 = 1280;
    height       : u32 = 720;
    multisamples : u32 = 16;
    max_depth    : s32 = 5;
}

ScreenParams :: struct
{
    center       : Vector3;
    du           : Vector3;
    dv           : Vector3;
    defocus_disk : [2]Vector3;
}

Scene :: struct
{
    camera: Camera;
    screen: ScreenParams;
    config: RenderConfig;
    bitmap: Bitmap;

    materials   : [..]Material;
    environment := Vector3.{0.7, 0.8, 1.0};

    primitives : [..]Primitive;
    spheres    : [..]SphereDesc;
    disks      : [..]DiskDesc;
    boxes      : [..]BoxDesc;
    meshes     : [..]MeshDesc;

    // render
    nodes      : [..]BVHNode;
    map        : [..]u32;
    mapped     : [..]Primitive;

    rgbn       : [..]Vector4;
};

HitType :: enum u32
{
    MISSED;
    INTERSECT;
};

HitInfo :: struct
{
    type            : HitType;
    material_id     : MaterialID;
    using intersect : IntersectInfo;
}

#scope_file

intersect_primitive :: (scene: Scene, primitive: Primitive, r: Ray) -> HitInfo
{
    ray: Ray;
    ray.tmin      = r.tmin;
    ray.tmax      = r.tmax;
    ray.origin    = transform_point(primitive.xform.inverse, r.origin);
    ray.direction = transform_vector(primitive.xform.inverse, r.direction);

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
        info.type        = .INTERSECT;
        info.material_id = primitive.material_id;
        info.p           = transform_point(primitive.xform.forward, info.p);
        info.n           = transform_vector(transpose(primitive.xform.inverse), info.n);
        info.n           = normalize(info.n);
    }

    return info;
}

#scope_export

intersect_bvh :: (scene: Scene, root: s64, ray: Ray) -> HitInfo
{
    node := scene.nodes[root];

    r    := ray;
    info := HitInfo.{ type = .MISSED };

    if (!hits(ray, node.bbox))
        return info;

    if (node.num_primitives == 0)
    {
        for 0..1
        {
            current := intersect_bvh(scene, node.first_child_or_primitive + it, r);
            if (current.type == .INTERSECT)
            {
                r.tmax = current.t;
                info   = current;
            }
        }
    }
    else
    {
        for 0..node.num_primitives-1
        {
            primitive := scene.mapped[node.first_child_or_primitive + it];
            if (hits(r, primitive.bbox))
            {
                current := intersect_primitive(scene, primitive, r);
                if (current.type == .INTERSECT)
                {
                    r.tmax = current.t;
                    info   = current;
                }
            }
        }
    }

    return info;
}

intersect :: (scene: Scene, ray: Ray) -> HitInfo
{
    hit := intersect_bvh(scene, 0, ray);
    return hit;
}

#import "Random";
