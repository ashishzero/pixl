
//------------------------------------------------------------------------

INV_PI    :: 1.0 / PI;
PI_OVER_4 :: PI / 4;
PI_OVER_2 :: PI / 2;

FLOAT_EPS :: 0h34000000;

//------------------------------------------------------------------------

Box3 :: struct
{
    vmin: Vector3;
    vmax: Vector3;
}

Box3_Empty :: Box3.{
    vmin = .{FLOAT32_INFINITY, FLOAT32_INFINITY, FLOAT32_INFINITY},
    vmax = .{-FLOAT32_INFINITY, -FLOAT32_INFINITY, -FLOAT32_INFINITY}
};

Vertex3 :: struct
{
    p  : Vector3;
    uv : Vector2;
    n  : Vector3;
    t  : Vector3;
    b  : Vector3;
}

Ray :: struct
{
    origin : Vector3;
    tmin   : float;
    dir    : Vector3;
    tmax   : float;
}

BVH_Node :: struct
{
    bbox                     : Box3;
    first_child_or_primitive : u32;
    num_primitives           : u32;
}

Acceleration_Structure :: struct
{
    // @todo: Make these array view
    nodes      : [..]BVH_Node;
    indices    : [..]u32;
    bboxes     : [..]Box3; // @todo: Not needed remove!!
}

// @todo: cleanup: use Matrix4x3
Transform :: struct
{
    forward: Matrix4;
    inverse: Matrix4;
}

MaterialID  :: #type,distinct u32;
PrimitiveID :: #type,distinct u32;

// @todo: move to camera.jai??

FILTER_SIZE :: 1023;

Filter_Type :: enum
{
    BOX;
    BLACKMAN_HARRIS;
}

Filter :: struct
{
    type  := Filter_Type.BLACKMAN_HARRIS;
    width := 1.5;
}

Camera :: struct
{
    position           : Vector3;
    orientation        : Quaternion;
    fov                := 0.17;
    aspect_ratio       := 1.0;
    lens_focal_length  := 15.0;
    lens_radius        := 0.0;
    filter             : Filter;

    // constructed from above parameters
    // @todo: cleanup; generate them before rendering!!
    xform              : Matrix4;
    dxdu               : Vector3;
    dydv               : Vector3;
    filter_lut         : [FILTER_SIZE]float;
}

//------------------------------------------------------------------------
// Morton codes
// Based on: https://fgiesen.wordpress.com/2009/12/13/decoding-morton-codes/

Split2 :: (x: u32) -> u32
{
    x &= 0X0000FFFF;
    x = (x ^ (x <<  8)) & 0X00FF00FF;
    x = (x ^ (x <<  4)) & 0X0F0F0F0F;
    x = (x ^ (x <<  2)) & 0X33333333;
    x = (x ^ (x <<  1)) & 0X55555555;
    return x;
}

Morton2 :: (x: u32, y: u32) -> u32
{
    x_split := Split2(x);
    y_split := Split2(y);
    code    := (x_split << 1) | y_split;
    return code;
}

#import "Math";
