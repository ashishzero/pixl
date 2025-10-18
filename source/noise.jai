
NOISE_PCG :: false;

Path_Random_State :: struct
{
    index  : u32;
    bounce : u32;
    seed   : u32;
}

Path_Dimension :: enum u32
{
    FILTER :: 0;
    LENS   :: 1;

    LOBE   :: 2;
    BxDF   :: 3;
}

MAX_BOUNCE :: 16;

// Based on: https://psychopath.io/post/2022_07_24_owen_scrambling_based_dithered_blue_noise_sampling
CreatePathRandomState :: (x: u32, y: u32, sample: u32, spp: u32, seed: u32) -> Path_Random_State
{
    morton_index := Morton2(x, y);
    sample_index := FastOwenScramble4(morton_index, seed) * spp.(u64);
    index        := (sample_index + sample).(u32, no_check);
    rng          := Path_Random_State.{index=index.(u32), bounce=0, seed=seed};
    return rng;
}

#if NOISE_PCG
{
    GetRandom1D :: (rng: Path_Random_State, dim: Path_Dimension) -> float
    {
        x := random_get_zero_to_one_open();
        return x;
    }

    GetRandom2D :: (rng: Path_Random_State, dim: Path_Dimension) -> Vector2
    {
        x := random_get_zero_to_one_open();
        y := random_get_zero_to_one_open();
        return .{x, y};
    }

    GetRandom3D :: (rng: Path_Random_State, dim: Path_Dimension) -> Vector3
    {
        x := random_get_zero_to_one_open();
        y := random_get_zero_to_one_open();
        z := random_get_zero_to_one_open();
        return .{x, y, z};
    }

    GetRandom4D :: (rng: Path_Random_State, dim: Path_Dimension) -> Vector4
    {
        x := random_get_zero_to_one_open();
        y := random_get_zero_to_one_open();
        z := random_get_zero_to_one_open();
        w := random_get_zero_to_one_open();
        return .{x, y, z, w};
    }
}
else
{
    GetRandom1D :: (rng: Path_Random_State, dim: Path_Dimension) -> float
    {
        seed := HashDimension(rng, dim);
        x    := SampleScrambledSobol(rng.index, seed, 0);
        return x;
    }

    GetRandom2D :: (rng: Path_Random_State, dim: Path_Dimension) -> Vector2
    {
        seed := HashDimension(rng, dim);
        x    := SampleScrambledSobol(rng.index, seed, 0);
        y    := SampleScrambledSobol(rng.index, seed, 1);
        return .{x, y};
    }

    GetRandom3D :: (rng: Path_Random_State, dim: Path_Dimension) -> Vector3
    {
        seed := HashDimension(rng, dim);
        x    := SampleScrambledSobol(rng.index, seed, 0);
        y    := SampleScrambledSobol(rng.index, seed, 1);
        z    := SampleScrambledSobol(rng.index, seed, 2);
        return .{x, y, z};
    }

    GetRandom4D :: (rng: Path_Random_State, dim: Path_Dimension) -> Vector4
    {
        seed := HashDimension(rng, dim);
        x    := SampleScrambledSobol(rng.index, seed, 0);
        y    := SampleScrambledSobol(rng.index, seed, 1);
        z    := SampleScrambledSobol(rng.index, seed, 2);
        w    := SampleScrambledSobol(rng.index, seed, 3);
        return .{x, y, z, w};
    }
}

NextBounce :: (rng: *Path_Random_State)
{
    rng.bounce += MAX_BOUNCE;
}

//------------------------------------------------------------------------
// Sobol Sampler
// The following code is based on the paper:
//      https://jcgt.org/published/0009/04/01/

SOBOL_MATRIX_DIMENSION :: 4;

SampleScrambledSobol :: (index: u32, seed: u32, dim: u32) -> float
{
    v := ScrambledSobol(index, seed, dim);
    return min(v.(float) * SOBOL_INV_RESOLUTION, 1.0 - FLOAT_EPS);
}

SampleSobol :: (index: u32, dim: u32) -> float
{
    v := Sobol(index, dim);
    return min(v.(float) * SOBOL_INV_RESOLUTION, 1.0 - FLOAT_EPS);
}

#scope_file

ScrambledSobol :: inline (index: u32, seed: u32, dim: u32) -> u32
{
    index  = FastOwenScramble2(index, seed ^ 0x79c68e4a);
    v     := Sobol(index, dim);
    v      = FastOwenScramble2(v, HashCombine(seed, dim));
    return v;
}

Sobol :: inline (index: u32, dim: u32) -> u32
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
FastOwenScramble4 :: (n: u32, seed: u32) -> u32
{
    n = ReverseBits(n);
    n ^= n * 0x3d20adea;
    n ^= (n >> 1) & (n << 1) & 0x55555555;
    n += seed;
    n *= (seed >> 16) | 1;
    n ^= (n >> 1) & (n << 1) & 0x55555555;
    n ^= n * 0x05526c56;
    n ^= n * 0x53a22864;
    n = ReverseBits(n);
    return n;
}

// Based on: https://psychopath.io/post/2021_01_30_building_a_better_lk_hash
FastOwenScramble2 :: inline (v: u32, seed: u32) -> u32
{
    v = ReverseBits(v);
    v ^= v * 0x3d20adea;
    v += seed;
    v *= (seed >> 16) | 1;
    v ^= v * 0x05526c56;
    v ^= v * 0x53a22864;
    return ReverseBits(v);
}

HashCombine :: inline (seed: u32, v: u32) -> u32
{
    return seed ^ (v + (seed << 6) + (seed >> 2));
}

ReverseBits :: inline (x: u32) -> u32
{
    x = (((x & 0xaaaaaaaa) >> 1) | ((x & 0x55555555) << 1));
    x = (((x & 0xcccccccc) >> 2) | ((x & 0x33333333) << 2));
    x = (((x & 0xf0f0f0f0) >> 4) | ((x & 0x0f0f0f0f) << 4));
    x = (((x & 0xff00ff00) >> 8) | ((x & 0x00ff00ff) << 8));
    return ((x >> 16) | (x << 16));
}

HashDimension :: (rng: Path_Random_State, set: Path_Dimension) -> u32
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
