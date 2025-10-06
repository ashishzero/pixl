
EPSILON :: 1.192092896e-07;

Box3 :: struct
{
    vmin: Vector3;
    vmax: Vector3;
}

Box3_Empty :: Box3.{
    vmin = .{FLOAT32_INFINITY, FLOAT32_INFINITY, FLOAT32_INFINITY},
    vmax = .{-FLOAT32_INFINITY, -FLOAT32_INFINITY, -FLOAT32_INFINITY}
};

// @todo: add support for plane
Primitive_Type :: enum u32
{
    SPHERE :: 1;
    DISK   :: 2;
    BOX    :: 3;
    MESH   :: 4;
}

Vertex3D :: struct
{
    p  : Vector3;
    uv : Vector2;
    n  : Vector3;
    t  : Vector3;
    b  : Vector3;
}

Acceleration_Structure :: struct
{
    // @todo: Make these array view
    nodes      : [..]BVHNode;
    indices    : [..]u32;
    bboxes     : [..]Box3; // @todo: Not needed remove!!
}

Intersect_Info :: struct
{
    p    : Vector3;
    t    : float;
    n    : Vector3;
    dpdu : Vector3;
    dpdv : Vector3;
    u    : float;
    v    : float;
};

IntersectSphere :: (radius: float, origin: Vector3, dir: Vector3, tmin: float, tmax: float) -> Intersect_Info
{
    info := Intersect_Info.{ t = -1 };

    oc := -origin;
    a  := dot(dir, dir);
    b  := -2 * dot(dir, oc);
    c  := dot(oc, oc) - radius * radius;

    solved, t0, t1 := SolveQuadratic(a, b, c);

    if !solved then
        return info;

    root := t0;

    if (root < tmin || tmax < root)
    {
        root = t1;
        if root < tmin || tmax < root then
            return info;
    }

    hit_p := PointAt(origin, dir, root);

    info.t = root;
    info.p = hit_p;

    n := info.p / radius;

    // spherical encoding
    phi   := atan2(n.z, n.x);
    if (phi < 0)
    {
        phi += 2 * PI;
    }

    cos_theta := clamp(n.y, -1.0, 1.0);
    sin_theta := sqrt(1 - cos_theta * cos_theta);

    theta := acos(cos_theta);

    info.u = phi / (2 * PI);
    info.v = theta / PI;

    y_radius := sqrt(hit_p.x * hit_p.x + hit_p.z * hit_p.z);
    cos_phi := hit_p.x / y_radius;
    sin_phi := hit_p.z / y_radius;

    info.n    = n;
    info.dpdu = Vector3.{-2 * PI * hit_p.z, 0.0, 2 * PI * hit_p.x};
    info.dpdv = PI * Vector3.{hit_p.y * cos_phi, -radius * sin_theta, hit_p.y * sin_phi};

    return info;
}

IntersectBox :: (vmin: Vector3, vmax: Vector3, origin: Vector3, dir: Vector3, tmin: float, tmax: float) -> Intersect_Info
{
    info := Intersect_Info.{ t = -1 };

    t0 := tmin;
    t1 := tmax;

    t_axis := -1;
    t_sign := 1.0;

    for 0..2
    {
        inv_dir := 1 / dir.component[it];
        t_lo := (vmin.component[it] - origin.component[it]) * inv_dir;
        t_hi := (vmax.component[it] - origin.component[it]) * inv_dir;

        if t_lo > t_hi
        {
            Swap(*t_lo, *t_hi);
        }

        if t_lo > t0
        {
            t0 = t_lo;
            t_axis = it;
            t_sign = ifx inv_dir > 0.0 then -1.0 else 1.0;
        }

        if t_hi < t1
        {
            t1 = t_hi;
        }

        if t0 > t1 then
            return info;
    }

    if t_axis == -1
    {
        // inside the slab
        return info;
    }

    hit_p := PointAt(origin, dir, t0);

    info.t = t0;
    info.p = hit_p;

    info.n = Vector3.{0, 0, 0};
    info.n.component[t_axis] = t_sign;

    p    := hit_p - vmin;
    diag := vmax - vmin;

    if (t_axis == 0)
    {
        info.u = p.z / diag.z;
        info.v = p.y / diag.y;
        info.dpdu = Vector3.{0, 0, 1};
        info.dpdv = Vector3.{0, 1, 0};
    }
    else if (t_axis == 1)
    {
        info.u = p.x / diag.x;
        info.v = p.z / diag.z;
        info.dpdu = Vector3.{1, 0, 0};
        info.dpdv = Vector3.{0, 0, 1};
    }
    else
    {
        info.u = p.x / diag.x;
        info.v = p.y / diag.y;
        info.dpdu = Vector3.{1, 0, 0};
        info.dpdv = Vector3.{0, 1, 0};
    }

    Clamp(*info.u, 0.0, 1.0);
    Clamp(*info.v, 0.0, 1.0);

    return info;
}

IntersectDisk :: (radius: float, origin: Vector3, dir: Vector3, tmin: float, tmax: float) -> Intersect_Info
{
    info := Intersect_Info.{ t = -1 };

    radius2 := radius * radius;
    normal := Vector3.{0, 0, -1};

    denom := dir.z; // DotProduct(normal, ray.direction)

    if (abs(denom) == 0.0)
        return info;

    root := -origin.z / denom; // -DotProduct(normal, ray.origin)

    if root < tmin || tmax < root then
        return info;

    hit_p := PointAt(origin, dir, root);

    distsq := hit_p.x * hit_p.x + hit_p.y * hit_p.y;

    if (distsq > radius2)
        return info;

    info.t = root;
    info.p = hit_p;

    v := sqrt(distsq) / radius;

    theta   := atan2(normal.y, normal.x);
    if (theta < 0)
    {
        theta += 2 * PI;
    }

    info.u = theta / (2 * PI);
    info.v = v;

    hit_factor := radius / sqrt(hit_p.x * hit_p.x + hit_p.y * hit_p.y);

    info.n    = normal;
    info.dpdu = Vector3.{2 * PI * hit_p.y, 2 * PI * hit_p.x, 0.0};
    info.dpdv = Vector3.{hit_p.x * hit_factor, hit_p.y * hit_factor, 0.0};
    
    return info;
}

IntersectTriangle :: (v0: Vertex3D, v1: Vertex3D, v2: Vertex3D, origin: Vector3, dir: Vector3, tmin: float, tmax: float) -> Intersect_Info
{
    // https://www.graphics.cornell.edu/pubs/1997/MT97.pdf

    info := Intersect_Info.{ t = -1 };

    edge1 := v1.p - v0.p;
    edge2 := v2.p - v0.p;
    pvec  := cross(dir, edge2);

    det := dot(edge1, pvec);

    if (abs(det) < EPSILON)
        return info;
    inv_det := 1.0 / det;

    tvec := origin - v0.p;
    u := dot(tvec, pvec) * inv_det;
    if u < 0.0 || u > 1.0 then
        return info;

    qvec := cross(tvec, edge1);
    v    := dot(dir, qvec) * inv_det;
    if v < 0.0 || u + v > 1.0 then
        return info;

    t := dot(edge2, qvec) * inv_det;

    if (t <= tmin || tmax <= t)
        return info;

    w := 1.0 - u - v;

    hit_p := PointAt(origin, dir, t);

    info.t = t;
    info.p = hit_p;

    uv := w * v0.uv + u * v1.uv + v * v2.uv;
    info.u = uv.x;
    info.v = uv.y;

    info.n    = w * v0.n + u * v1.n + v * v2.n;
    info.dpdu = w * v0.t + u * v1.t + v * v2.t;
    info.dpdv = w * v0.b + u * v1.b + v * v2.b;

    return info;
}

// @todo: cleanup/copynpaste from intersect_bvh

IntersectBLAS :: (indices: []u32, vertices: []Vertex3D, blas: Acceleration_Structure, origin: Vector3, dir: Vector3, tmin: float, tmax: float) -> Intersect_Info
{
    info := Intersect_Info.{ t = -1 };

    nodes_stack : [64]u32 = ---;

    top : u32 = 1;
    nodes_stack[0] = 0;

    inv_dir := Vector3.{1.0 / dir.x, 1.0 / dir.y, 1.0 / dir.z};

    while top > 0
    {
        top -= 1;
        node := blas.nodes[nodes_stack[top]];

        if (Hits(origin, inv_dir, node.bbox, tmin, tmax))
        {
            if (node.num_primitives)
            {
                for 0..node.num_primitives-1
                {
                    // @cleanup @copynpaste Only change is here

                    face_index := blas.indices[node.first_child_or_primitive + it];

                    vtx_idx0   := indices[face_index * 3 + 0];
                    vtx_idx1   := indices[face_index * 3 + 1];
                    vtx_idx2   := indices[face_index * 3 + 2];

                    vtx0       := vertices[vtx_idx0];
                    vtx1       := vertices[vtx_idx1];
                    vtx2       := vertices[vtx_idx2];

                    current := IntersectTriangle(vtx0, vtx1, vtx2, origin, dir, tmin, tmax);

                    if current.t >= 0.0
                    {
                        tmax = current.t;
                        info = current;
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

    return info;
}

IntersectMesh :: (indices: []u32, vertices: []Vertex3D, blas: Acceleration_Structure, origin: Vector3, dir: Vector3, tmin: float, tmax: float) -> Intersect_Info
{
    info := IntersectBLAS(indices, vertices, blas, origin, dir, tmin, tmax);
    return info;
}

Hits :: (origin: Vector3, inv_dir: Vector3, box: Box3, t0: float, t1: float) -> bool
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

TransformPoint :: (m: Matrix4, v: Vector3) -> Vector3
{
    result: Vector3 = ---;
    result.x = m._11 * v.x + m._12 * v.y + m._13 * v.z + m._14;
    result.y = m._21 * v.x + m._22 * v.y + m._23 * v.z + m._24;
    result.z = m._31 * v.x + m._32 * v.y + m._33 * v.z + m._34;
    return result;
}

TransformVector :: (m: Matrix4, v: Vector3) -> Vector3
{
    result: Vector3 = ---;
    result.x = m._11 * v.x + m._12 * v.y + m._13 * v.z;
    result.y = m._21 * v.x + m._22 * v.y + m._23 * v.z;
    result.z = m._31 * v.x + m._32 * v.y + m._33 * v.z;
    return result;
}

TransformBox :: (t: Matrix4, box: Box3) -> Box3
{
    center := 0.5 * (box.vmin + box.vmax);
    extent := 0.5 * (box.vmax - box.vmin);

    rcenter := TransformPoint(t, center);
    half    := Vector3.{0, 0, 0};

    half.x       = abs(extent.x * t.floats[0 + 0]) + abs(extent.y * t.floats[0 + 1]) + abs(extent.z * t.floats[0 + 2]);
    half.y       = abs(extent.x * t.floats[4 + 0]) + abs(extent.y * t.floats[4 + 1]) + abs(extent.z * t.floats[4 + 2]);
    half.z       = abs(extent.x * t.floats[8 + 0]) + abs(extent.y * t.floats[8 + 1]) + abs(extent.z * t.floats[8 + 2]);

    return Box3.{rcenter - half, rcenter + half};
}

Union :: (b: Box3, p: Vector3) -> Box3
{
    ret: Box3;
    ret.vmin = min(b.vmin, p);
    ret.vmax = max(b.vmax, p);
    return ret;
}

Union :: (b1: Box3, b2: Box3) -> Box3
{
    ret: Box3;
    ret.vmin = min(b1.vmin, b2.vmin);
    ret.vmax = max(b1.vmax, b2.vmax);
    return ret;
}

#scope_file

PointAt :: inline (origin: Vector3, dir: Vector3, t: float) -> Vector3
{
    point := origin + dir * t;
    return point;
}

SolveQuadratic :: inline (a: float, b: float, c: float) -> (bool, float, float)
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
