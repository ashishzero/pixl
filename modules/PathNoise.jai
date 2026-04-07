#scope_export

Path_State :: struct
{
    index  : u32;
    bounce : u32;
    seed   : u32;
}

Path_Dimension :: enum u32
{
    FILTER :: 0;
    LENS   :: 1;

    LOBE   :: 0;
    BxDF   :: 1;
}

MAX_BOUNCE :: 16;

// Based on: https://psychopath.io/post/2022_07_24_owen_scrambling_based_dithered_blue_noise_sampling
path_state :: (x: u32, y: u32, sample: u32, spp: u32, seed: u32) -> Path_State
{
    morton_index := morton2(x, y);
    sample_index := fast_owen_scramble4(morton_index, seed) * spp.(u64);
    index        := (sample_index + sample).(u32, no_check);
    rng          := Path_State.{index=index.(u32), bounce=0, seed=seed};
    return rng;
}

sample_1D :: (rng: Path_State, dim: Path_Dimension) -> float
{
    seed := hash_dimension(rng, dim);
    x    := sample_scrambled_sobol(rng.index, seed, 0);
    return x;
}

sample_2D :: (rng: Path_State, dim: Path_Dimension) -> Vector2
{
    seed := hash_dimension(rng, dim);
    x    := sample_scrambled_sobol(rng.index, seed, 0);
    y    := sample_scrambled_sobol(rng.index, seed, 1);
    return .{x, y};
}

sample_3D :: (rng: Path_State, dim: Path_Dimension) -> Vector3
{
    seed := hash_dimension(rng, dim);
    x    := sample_scrambled_sobol(rng.index, seed, 0);
    y    := sample_scrambled_sobol(rng.index, seed, 1);
    z    := sample_scrambled_sobol(rng.index, seed, 2);
    return .{x, y, z};
}

sample_4D :: (rng: Path_State, dim: Path_Dimension) -> Vector4
{
    seed := hash_dimension(rng, dim);
    x    := sample_scrambled_sobol(rng.index, seed, 0);
    y    := sample_scrambled_sobol(rng.index, seed, 1);
    z    := sample_scrambled_sobol(rng.index, seed, 2);
    w    := sample_scrambled_sobol(rng.index, seed, 3);
    return .{x, y, z, w};
}

sample_random_1D :: (index: u32, seed: u32) -> float
{
    u := sample_scrambled_sobol(index, seed, 0);
    return u;
}

sample_random_2D :: (index: u32, seed: u32) -> Vector2
{
    u1 := sample_scrambled_sobol(index, seed, 0);
    u2 := sample_scrambled_sobol(index, seed, 1);
    u  := Vector2.{u1, u2};
    return u;
}

sample_random_3D :: (index: u32, seed: u32) -> Vector3
{
    u1 := sample_scrambled_sobol(index, seed, 0);
    u2 := sample_scrambled_sobol(index, seed, 1);
    u3 := sample_scrambled_sobol(index, seed, 2);
    u  := Vector3.{u1, u2, u3};
    return u;
}

sample_random_4D :: (index: u32, seed: u32) -> Vector4
{
    u1 := sample_scrambled_sobol(index, seed, 0);
    u2 := sample_scrambled_sobol(index, seed, 1);
    u3 := sample_scrambled_sobol(index, seed, 2);
    u4 := sample_scrambled_sobol(index, seed, 3);
    u  := Vector4.{u1, u2, u3, u4};
    return u;
}

next_bounce :: (rng: *Path_State)
{
    rng.bounce += MAX_BOUNCE;
}

//------------------------------------------------------------------------
// Sobol Sampler
// The following code is based on the paper:
//      https://jcgt.org/published/0009/04/01/

SOBOL_MATRIX_DIMENSION :: 4;

sample_scrambled_sobol :: inline (index: u32, seed: u32, dim: u32) -> float
{
    v := scrambled_sobol(index, seed, dim);
    r := v.(float) * SOBOL_INV_RESOLUTION;
    if (r < 1.0) return r;
    return 1.0 - FLOAT32_EPSILON;
}

sample_sobol :: inline (index: u32, dim: u32) -> float
{
    v := sobol(index, dim);
    r := v.(float) * SOBOL_INV_RESOLUTION;
    if (r < 1.0) return r;
    return 1.0 - FLOAT32_EPSILON;
}

#scope_file

scrambled_sobol :: inline (index: u32, seed: u32, dim: u32) -> u32
{
    index  = fast_owen_scramble2(index, seed ^ 0x79c68e4a);
    v     := sobol(index, dim);
    v      = fast_owen_scramble2(v, hash_combine(seed, dim));
    return v;
}

sobol :: inline (index: u32, dim: u32) -> u32
{
    v : u32 = 0;
    i := dim * SOBOL_MATRIX_SIZE;
    while (index != 0)
    {
        if (index & 1)
        {
            v ^= SobolDirectionLUT[i];
        }
        i += 1;
        index >>= 1;
    }
    return v;
}

// Based on: https://psychopath.io/post/2022_08_14_a_fast_hash_for_base_4_owen_scrambling
fast_owen_scramble4 :: (n: u32, seed: u32) -> u32
{
    n = reverse_bits(n);
    n ^= n * 0x3d20adea;
    n ^= (n >> 1) & (n << 1) & 0x55555555;
    n += seed;
    n *= (seed >> 16) | 1;
    n ^= (n >> 1) & (n << 1) & 0x55555555;
    n ^= n * 0x05526c56;
    n ^= n * 0x53a22864;
    n = reverse_bits(n);
    return n;
}

// Based on: https://psychopath.io/post/2021_01_30_building_a_better_lk_hash
fast_owen_scramble2 :: inline (v: u32, seed: u32) -> u32
{
    v = reverse_bits(v);
    v ^= v * 0x3d20adea;
    v += seed;
    v *= (seed >> 16) | 1;
    v ^= v * 0x05526c56;
    v ^= v * 0x53a22864;
    return reverse_bits(v);
}

reverse_bits :: inline (x: u32) -> u32
{
    x = (((x & 0xaaaaaaaa) >> 1) | ((x & 0x55555555) << 1));
    x = (((x & 0xcccccccc) >> 2) | ((x & 0x33333333) << 2));
    x = (((x & 0xf0f0f0f0) >> 4) | ((x & 0x0f0f0f0f) << 4));
    x = (((x & 0xff00ff00) >> 8) | ((x & 0x00ff00ff) << 8));
    return ((x >> 16) | (x << 16));
}

hash_dimension :: (rng: Path_State, set: Path_Dimension) -> u32
{
    Hash :: (n: u32) -> u32
    {
        // From: https://github.com/skeeto/hash-prospector
        n ^= 0xe6fe3beb; // So zero doesn't map to zero
        n ^= n >> 16;
        n *= 0x7feb352d;
        n ^= n >> 15;
        n *= 0x846ca68b;
        n ^= n >> 16;
        return n;
    }

    dim   := rng.bounce + set.(u32);
    seed  := rng.seed ^ Hash(dim);
    return seed;
}

split2 :: (x: u32) -> u32
{
    // Based on: https://fgiesen.wordpress.com/2009/12/13/decoding-morton-codes/
    x &= 0X0000FFFF;
    x = (x ^ (x <<  8)) & 0X00FF00FF;
    x = (x ^ (x <<  4)) & 0X0F0F0F0F;
    x = (x ^ (x <<  2)) & 0X33333333;
    x = (x ^ (x <<  1)) & 0X55555555;
    return x;
}

morton2 :: (x: u32, y: u32) -> u32
{
    x_split := split2(x);
    y_split := split2(y);
    code    := (x_split << 1) | y_split;
    return code;
}

FLOAT32_EPSILON        :: 0h34000000;

//------------------------------------------------------------------------
// Sobol Table

SOBOL_MATRIX_SIZE      :: 32;
SOBOL_INV_RESOLUTION   :: 0h2f800000;

SobolDirectionLUT : [SOBOL_MATRIX_DIMENSION * SOBOL_MATRIX_SIZE]u32 : .[
    0x80000000, 0x40000000, 0x20000000, 0x10000000,
    0x08000000, 0x04000000, 0x02000000, 0x01000000,
    0x00800000, 0x00400000, 0x00200000, 0x00100000,
    0x00080000, 0x00040000, 0x00020000, 0x00010000,
    0x00008000, 0x00004000, 0x00002000, 0x00001000,
    0x00000800, 0x00000400, 0x00000200, 0x00000100,
    0x00000080, 0x00000040, 0x00000020, 0x00000010,
    0x00000008, 0x00000004, 0x00000002, 0x00000001,

    0x80000000, 0xc0000000, 0xa0000000, 0xf0000000,
    0x88000000, 0xcc000000, 0xaa000000, 0xff000000,
    0x80800000, 0xc0c00000, 0xa0a00000, 0xf0f00000,
    0x88880000, 0xcccc0000, 0xaaaa0000, 0xffff0000,
    0x80008000, 0xc000c000, 0xa000a000, 0xf000f000,
    0x88008800, 0xcc00cc00, 0xaa00aa00, 0xff00ff00,
    0x80808080, 0xc0c0c0c0, 0xa0a0a0a0, 0xf0f0f0f0,
    0x88888888, 0xcccccccc, 0xaaaaaaaa, 0xffffffff,

    0x80000000, 0xc0000000, 0x60000000, 0x90000000,
    0xe8000000, 0x5c000000, 0x8e000000, 0xc5000000,
    0x68800000, 0x9cc00000, 0xee600000, 0x55900000,
    0x80680000, 0xc09c0000, 0x60ee0000, 0x90550000,
    0xe8808000, 0x5cc0c000, 0x8e606000, 0xc5909000,
    0x6868e800, 0x9c9c5c00, 0xeeee8e00, 0x5555c500,
    0x8000e880, 0xc0005cc0, 0x60008e60, 0x9000c590,
    0xe8006868, 0x5c009c9c, 0x8e00eeee, 0xc5005555,

    0x80000000, 0xc0000000, 0x20000000, 0x50000000,
    0xf8000000, 0x74000000, 0xa2000000, 0x93000000,
    0xd8800000, 0x25400000, 0x59e00000, 0xe6d00000,
    0x78080000, 0xb40c0000, 0x82020000, 0xc3050000,
    0x208f8000, 0x51474000, 0xfbea2000, 0x75d93000,
    0xa0858800, 0x914e5400, 0xdbe79e00, 0x25db6d00,
    0x58800080, 0xe54000c0, 0x79e00020, 0xb6d00050,
    0x800800f8, 0xc00c0074, 0x200200a2, 0x50050093,
];

#import "Math";
#import "Hashing";
