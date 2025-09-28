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

PrimitiveSphere :: struct
{
    radius: float;
}

PrimitiveDisk :: struct
{
    radius: float;
}

PrimitiveBox :: struct
{
    vmin: Vector3;
    vmax: Vector3;
}

PrimitiveMesh :: struct
{
    indices: []u32;
    vertices: []Vertex3D;
    blas: AccelerationStructure;
}

PrimitiveShape :: union
{
    sphere : PrimitiveSphere;
    disk   : PrimitiveDisk;
    box    : PrimitiveBox;
    mesh   : PrimitiveMesh;
}

Primitive :: struct
{
    type        : PrimitiveType;
    xform       : Transform;
    material_id : MaterialID;
    shape       : PrimitiveShape;
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

    tlas       : AccelerationStructure;
    mapped     : [..]Primitive;

    rgbx_mem   : *void;
    rgbx       : []Vector4;
}

HitInfo :: struct
{
    p           : Vector3;
    t           : float;
    n           : Vector3;
    dpdu        : Vector3;
    dpdv        : Vector3;
    u           : float;
    v           : float;
    material_id : MaterialID;
}

#scope_file

intersect_primitive :: (primitive: Primitive, world_origin: Vector3, world_dir: Vector3, tmin: float, tmax: float) -> HitInfo
{
    origin := transform_point(primitive.xform.inverse, world_origin);
    dir    := transform_vector(primitive.xform.inverse, world_dir);

    intersect: IntersectInfo = ---;

    if #complete primitive.type ==
    {
        case .SPHERE;
            intersect = intersect_sphere(primitive.shape.sphere.radius, origin, dir, tmin, tmax);

        case .DISK;
            intersect = intersect_disk(primitive.shape.disk.radius, origin, dir, tmin, tmax);

        case .BOX;
            intersect = intersect_box(primitive.shape.box.vmin, primitive.shape.box.vmax, origin, dir, tmin, tmax);

        case .MESH;
            intersect = intersect_mesh(primitive.shape.mesh.indices, primitive.shape.mesh.vertices, primitive.shape.mesh.blas, origin, dir, tmin, tmax);
    }

    info := HitInfo.{ t = -1 };

    if (intersect.t >= 0.0)
    {
        // @todo: May be transform the minimum hit only??
        info.material_id  = primitive.material_id;
        info.p            = transform_point(primitive.xform.forward, intersect.p);
        info.n            = transform_vector(transpose(primitive.xform.inverse), intersect.n);
        info.n            = normalize(info.n);
        info.dpdu         = transform_vector(primitive.xform.forward, intersect.dpdu);
        info.dpdv         = transform_vector(primitive.xform.forward, intersect.dpdv);
        info.t            = intersect.t;
        info.u            = intersect.u;
        info.v            = intersect.v;
    }

    return info;
}

#scope_export

intersect_bvh :: (nodes: []BVHNode, primitives: []Primitive, origin: Vector3, dir: Vector3, tmin: float, tmax: float) -> HitInfo, int
{
    visited := 0;
    info := HitInfo.{ t = -1 };

    if nodes.count
    {
        nodes_stack : [64]u32 = ---;

        top : u32 = 1;
        nodes_stack[0] = 0;
        inv_dir := Vector3.{1.0 / dir.x, 1.0 / dir.y, 1.0 / dir.z};

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
                        current := intersect_primitive(primitive, origin, dir, tmin, tmax);
                        if (current.t >= 0.0)
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
    }

    return info, visited;
}

intersect :: (scene: Scene, origin: Vector3, dir: Vector3, tmin: float, tmax: float) -> HitInfo, int
{
    hit, num_visited := intersect_bvh(scene.tlas.nodes, scene.mapped, origin, dir, tmin, tmax);
    return hit, num_visited;
}

#import "Random";
