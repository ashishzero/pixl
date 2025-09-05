
EPSILON :: 1.192092896e-07;

Box3_Empty :: Box3.{ vmin = .{FLOAT32_INFINITY, FLOAT32_INFINITY, FLOAT32_INFINITY},
                     vmax = .{-FLOAT32_INFINITY, -FLOAT32_INFINITY, -FLOAT32_INFINITY}
                    };

Ray :: struct
{
    origin    : Vector3;
    tmin      : float;
    direction : Vector3;
    tmax      : float;
}

// @todo: add support for plane
PrimitiveType :: enum u32
{
    SPHERE :: 1;
    DISK   :: 2;
    BOX    :: 3;
    MESH   :: 4;
}

SphereDesc :: struct
{
    radius : float;
}

DiskDesc :: struct
{
    radius : float;
}

BoxDesc :: struct
{
    min : Vector3;
    max : Vector3;
}

Vertex3D :: struct
{
    p  : Vector3;
    uv : Vector2;
    n  : Vector3;
}

MeshDesc :: struct
{
    indices : []u32;
    vertices: []Vertex3D;
    blas    : AccelerationStructure; // @todo: Remove this, and add this to Primitive instead
}

IntersectFlags :: enum_flags u32
{
    FRONT_FACE :: 0x1;
}

IntersectInfo :: struct
{
    p : Vector3;
    t : float;
    n : Vector3;
    u : float;
    v : float;
    flags : IntersectFlags;
};

point_at :: inline (ray: Ray, t: float) -> Vector3
{
    point := ray.origin + ray.direction * t;
    return point;
}

point_at :: inline (origin: Vector3, direction: Vector3, t: float) -> Vector3
{
    point := origin + direction * t;
    return point;
}

intersect_sphere :: (sphere: SphereDesc, ray: Ray) -> bool, IntersectInfo
{
    oc := -ray.origin;
    a  := dot(ray.direction, ray.direction);
    b  := -2 * dot(ray.direction, oc);
    c  := dot(oc, oc) - sphere.radius * sphere.radius;

    solved, t0, t1 := solve_quadratic(a, b, c);

    if !solved then
        return false, .{};

    root := t0;

    if (root < ray.tmin || ray.tmax < root)
    {
        root = t1;
        if root < ray.tmin || ray.tmax < root then
            return false, .{};
    }

    hit_p := point_at(ray, root);

    info : IntersectInfo;
    info.t = root;
    info.p = hit_p;

    n := info.p / sphere.radius;

    uv := encode_spherical_uv(n);
    info.u = uv.x;
    info.v = uv.y;

    set_face_normal(ray.direction, n, *info);

    return true, info;
}

intersect_box :: (box: BoxDesc, ray: Ray) -> bool, IntersectInfo
{
    t0 := ray.tmin;
    t1 := ray.tmax;

    t_axis := -1;
    t_sign := 1.0;

    for 0..2
    {
        inv_dir := 1 / ray.direction.component[it];
        tmin := (box.min.component[it] - ray.origin.component[it]) * inv_dir;
        tmax := (box.max.component[it] - ray.origin.component[it]) * inv_dir;

        if tmin > tmax
        {
            Swap(*tmin, *tmax);
        }

        if tmin > t0
        {
            t0 = tmin;
            t_axis = it;
            t_sign = ifx inv_dir > 0.0 then -1.0 else 1.0;
        }

        if tmax < t1
        {
            t1 = tmax;
        }

        if t0 > t1 then
            return false, .{};
    }

    if t_axis == -1
    {
        // inside the slab
        return false, .{};
    }

    hit_p := point_at(ray, t0);

    info: IntersectInfo;
    info.t = t0;
    info.p = hit_p;

    n   := Vector3.{0, 0, 0};
    n.component[t_axis] = t_sign;

    p    := hit_p - box.min;
    diag := box.max - box.min;

    if (t_axis == 0)
    {
        info.u = p.z / diag.z;
        info.v = p.y / diag.y;
    }
    else if (t_axis == 1)
    {
        info.u = p.x / diag.x;
        info.v = p.z / diag.z;
    }
    else
    {
        info.u = p.x / diag.x;
        info.v = p.y / diag.y;
    }

    Clamp(*info.u, 0.0, 1.0);
    Clamp(*info.v, 0.0, 1.0);

    set_face_normal(ray.direction, n, *info);

    return true, info;
}

intersect_disk :: (disk: DiskDesc, ray: Ray) -> bool, IntersectInfo
{
    radius2 := disk.radius * disk.radius;
    normal := Vector3.{0, 0, -1};

    denom := ray.direction.z; // DotProduct(normal, ray.direction)

    if (abs(denom) == 0.0)
        return false, .{};

    root := -ray.origin.z / denom; // -DotProduct(normal, ray.origin)

    if root < ray.tmin || ray.tmax < root then
        return false, .{};

    hit_p := point_at(ray, root);

    distsq := hit_p.x * hit_p.x + hit_p.y * hit_p.y;

    if (distsq > radius2)
        return false, .{};

    info: IntersectInfo;
    info.t = root;
    info.p = hit_p;

    v := sqrt(distsq) / disk.radius;

    theta := atan2(hit_p.y, hit_p.x) / (2 * PI);
    if theta < 0.0 then
        theta += 1.0;

    info.u = theta;
    info.v = v;

    set_face_normal(ray.direction, normal, *info);

    return true, info;
}

intersect_triangle :: (v0: Vertex3D, v1: Vertex3D, v2: Vertex3D, origin: Vector3, direction: Vector3, tmin: float, tmax: float) -> bool, IntersectInfo
{
    // https://www.graphics.cornell.edu/pubs/1997/MT97.pdf

    edge1 := v1.p - v0.p;
    edge2 := v2.p - v0.p;
    pvec  := cross(direction, edge2);

    det := dot(edge1, pvec);

    // @todo: remove culling

    if (det <= 0.0) // culling
        return false, .{};

    tvec := origin - v0.p;
    u := dot(tvec, pvec);
    if u < 0.0 || u > det then
        return false, .{};

    qvec := cross(tvec, edge1);
    v    := dot(direction, qvec);
    if v < 0.0 || u + v > det then
        return false, .{};

    t := dot(edge2, qvec);
    inv_det := 1.0 / det;

    t *= inv_det;

    if (t <= tmin || tmax <= t)
        return false, .{};

    u *= inv_det;
    v *= inv_det;

    info: IntersectInfo;

    w := 1.0 - u - v;

    hit_p := point_at(origin, direction, t);

    info.t = t;
    info.p = hit_p;

    uv := w * v0.uv + u * v1.uv + v * v2.uv;
    info.u = uv.x;
    info.v = uv.y;

    normal := w * v0.n + u * v1.n + v * v2.n;
    normal = normalize(normal);

    // back faces are culled
    info.flags |= .FRONT_FACE;
    info.n = normal;

    return true, info;
}

// @todo: cleanup/copynpaste from intersect_bvh

intersect_blas :: (mesh: MeshDesc, ray: Ray) -> bool, IntersectInfo
{
    using blas := mesh.blas;

    nodes_stack : [64]u32 = ---;

    top : u32 = 1;
    nodes_stack[0] = 0;

    hit  := false;
    info : IntersectInfo;

    origin  := ray.origin;
    dir     := ray.direction;
    inv_dir := Vector3.{1.0 / dir.x, 1.0 / dir.y, 1.0 / dir.z};
    tmin    := ray.tmin;
    tmax    := ray.tmax;

    while top > 0
    {
        top -= 1;
        node := nodes[nodes_stack[top]];

        if (hits(origin, inv_dir, node.bbox, tmin, tmax))
        {
            if (node.num_primitives)
            {
                for 0..node.num_primitives-1
                {
                    // @cleanup @copynpaste Only change is here

                    face_index := indices[node.first_child_or_primitive + it];

                    vtx_idx0   := mesh.indices[face_index * 3 + 0];
                    vtx_idx1   := mesh.indices[face_index * 3 + 1];
                    vtx_idx2   := mesh.indices[face_index * 3 + 2];

                    vtx0       := mesh.vertices[vtx_idx0];
                    vtx1       := mesh.vertices[vtx_idx1];
                    vtx2       := mesh.vertices[vtx_idx2];

                    intersect, current := intersect_triangle(vtx0, vtx1, vtx2, origin, dir, tmin, tmax);

                    if intersect
                    {
                        tmax = current.t;
                        info = current;
                        hit  = true;
                    }
                }
            }
            else
            {
                assert(top + 2 < nodes_stack.count);
                // @todo @speed push the node that is likely to be hit at the top; refer pbrt
                nodes_stack[top + 0] = node.first_child_or_primitive + 1;
                nodes_stack[top + 1] = node.first_child_or_primitive + 0;
                top += 2;
            }
        }
    }

    return hit, info;
}

intersect_mesh :: (mesh: MeshDesc, ray: Ray) -> bool, IntersectInfo
{
    hit, info := intersect_blas(mesh, ray);
    return hit, info;
}

intersect_mesh_slow :: (mesh: MeshDesc, ray: Ray) -> bool, IntersectInfo
{
    tmin := ray.tmin;
    tmax := ray.tmax;
    hit  := false;

    hit_i0, hit_i1, hit_i2 : u32;
    hit_t, hit_u, hit_v : float;

    // https://www.graphics.cornell.edu/pubs/1997/MT97.pdf

    index := 0;

    while index < mesh.indices.count
    {
        defer index += 3;

        i0 := mesh.indices[index + 0];
        i1 := mesh.indices[index + 1];
        i2 := mesh.indices[index + 2];

        v0 := mesh.vertices[i0].p;
        v1 := mesh.vertices[i1].p;
        v2 := mesh.vertices[i2].p;

        edge1 := v1 - v0;
        edge2 := v2 - v0;
        pvec  := cross(ray.direction, edge2);

        det := dot(edge1, pvec);

        if (det < EPSILON)
            continue;

        tvec := ray.origin - v0;
        u := dot(tvec, pvec);
        if u < 0.0 || u > det then
            continue;

        qvec := cross(tvec, edge1);
        v    := dot(ray.direction, qvec);
        if v < 0.0 || u + v > det then
            continue;

        t := dot(edge2, qvec);
        inv_det := 1.0 / det;

        t *= inv_det;

        if (t <= tmin || tmax <= t)
            continue;

        tmax = t;

        u *= inv_det;
        v *= inv_det;

        hit_t = t;
        hit_u = u;
        hit_v = v;

        hit_i0 = i0;
        hit_i1 = i1;
        hit_i2 = i2;

        hit = true;
    }

    info: IntersectInfo;

    if hit
    {
        hit_w := 1.0 - hit_u - hit_v;

        hit_p := point_at(ray, hit_t);

        info.t = hit_t;
        info.p = hit_p;

        uv := hit_w * mesh.vertices[hit_i0].uv + hit_u * mesh.vertices[hit_i1].uv + hit_v * mesh.vertices[hit_i2].uv;
        info.u = uv.x;
        info.v = uv.y;

        normal := hit_w * mesh.vertices[hit_i0].n + hit_u * mesh.vertices[hit_i1].n + hit_v * mesh.vertices[hit_i2].n;
        normal = normalize(normal);

        set_face_normal(ray.direction, normal, *info);
    }

    return hit, info;
}

hits :: (origin: Vector3, inv_dir: Vector3, box: Box3, t0: float, t1: float) -> bool
{
    for 0..2
    {
        if box.vmin.component[it] > box.vmax.component[it]
        {
            return false;
        }

        tmin := (box.vmin.component[it] - origin.component[it]) * inv_dir.component[it];
        tmax := (box.vmax.component[it] - origin.component[it]) * inv_dir.component[it];

        if tmin > tmax
            Swap(*tmin, *tmax);

        if tmin > t0
        {
            t0 = tmin;
        }

        if tmax < t1
        {
            t1 = tmax;
        }

        if t0 > t1 then
            return false;
    }

    return true;
}

transform_box :: (t: Matrix4, box: Box3) -> Box3
{
    center := 0.5 * (box.vmin + box.vmax);
    extent := 0.5 * (box.vmax - box.vmin);

    rcenter := transform_point(t, center);
    half    := Vector3.{0, 0, 0};

    half.x       = abs(extent.x * t.floats[0 + 0]) + abs(extent.y * t.floats[0 + 1]) + abs(extent.z * t.floats[0 + 2]);
    half.y       = abs(extent.x * t.floats[4 + 0]) + abs(extent.y * t.floats[4 + 1]) + abs(extent.z * t.floats[4 + 2]);
    half.z       = abs(extent.x * t.floats[8 + 0]) + abs(extent.y * t.floats[8 + 1]) + abs(extent.z * t.floats[8 + 2]);

    return Box3.{rcenter - half, rcenter + half};
}

concat :: (b: Box3, p: Vector3) -> Box3
{
    ret: Box3;
    ret.vmin = min(b.vmin, p);
    ret.vmax = max(b.vmax, p);
    return ret;
}

concat :: (b1: Box3, b2: Box3) -> Box3
{
    ret: Box3;
    ret.vmin = min(b1.vmin, b2.vmin);
    ret.vmax = max(b1.vmax, b2.vmax);
    return ret;
}

#scope_file

encode_spherical_uv :: inline (n: Vector3) -> Vector2
{
    phi   := atan2(-n.z, n.x) / (2 * PI) + 0.5;
    theta := acos(clamp(n.y, -1.0, 1.0));
    u     := phi;
    v     := theta * PI;
    return Vector2.{u, 1.0 - v};
}

set_face_normal :: inline (direction: Vector3, outward_normal : Vector3, info: *IntersectInfo)
{
    if (dot(direction, outward_normal) < 0)
    {
        info.flags |= .FRONT_FACE;
        info.n = outward_normal;
    }
    else
    {
        info.n = -outward_normal;
    }
}

solve_quadratic :: (a: float, b: float, c: float) -> (bool, float, float)
{
    if (a == 0.0)
    {
        if b == 0.0 then
            return false, 0.0, 0.0;
        t := -c / b;
        return true, t, t;
    }

    discrim := b.(float64) * b.(float64) - 4 * a.(float64) * c.(float64);
    if (discrim < 0)
        return false, 0, 0;

    root_discrim := sqrt(discrim);

    q: float64;
    if (b < 0)
        q = -0.5 * (b - root_discrim);
    else
        q = -0.5 * (b + root_discrim);

    t0 := (q / a.(float64)).(float);
    t1 := (c.(float64) / q).(float);

    if (t0 > t1)
        Swap(*t0, *t1);

    return true, t0, t1;
}
