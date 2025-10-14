
Path_Random_State :: struct
{
    index : u32;
    seed  : u32;
}

Path_Dimension :: enum u32
{
    FILTER :: 0;
    LENS   :: 1;

    LOBE   :: 2;
    BxDF   :: 4;
}

// Based on: https://psychopath.io/post/2022_07_24_owen_scrambling_based_dithered_blue_noise_sampling
CreatePathRandomState :: (x: u32, y: u32, sample: u32, spp: u32, seed: u32) -> Path_Random_State
{
    morton_index := Morton2(x, y);
    sample_index := FastOwenScramble4(morton_index, seed) * spp.(u64);
    index        := (sample_index + sample) & 0xffffffff;
    return .{index.(u32), seed};
}

GetRandom1D :: (rng: Path_Random_State, dim: Path_Dimension) -> float
{
    seed := rng.seed ^ HashDimension(dim);
    x := SampleScrambledSobol(rng.index, seed ^ 0xed5ad4bb, dim.(u32));
    return x;
}

GetRandom2D :: (rng: Path_Random_State, dim: Path_Dimension) -> Vector2
{
    seed := rng.seed ^ HashDimension(dim);
    x := SampleScrambledSobol(rng.index, seed ^ 0xac4c1b51, dim.(u32) + 0);
    y := SampleScrambledSobol(rng.index, seed ^ 0x31848bab, dim.(u32) + 1);
    return .{x, y};
}

GetRandom3D :: (rng: Path_Random_State, dim: Path_Dimension) -> Vector3
{
    seed := rng.seed ^ HashDimension(dim);
    x := SampleScrambledSobol(rng.index, seed ^ 0x846ca68b, dim.(u32) + 0);
    y := SampleScrambledSobol(rng.index, seed ^ 0x1d69e2a5, dim.(u32) + 1);
    z := SampleScrambledSobol(rng.index, seed ^ 0x43021123, dim.(u32) + 2);
    return .{x, y, z};
}

GetRandom4D :: (rng: Path_Random_State, dim: Path_Dimension) -> Vector4
{
    seed := rng.seed ^ HashDimension(dim);
    x := SampleScrambledSobol(rng.index, seed ^ 0x297a2d39, dim.(u32) + 0);
    y := SampleScrambledSobol(rng.index, seed ^ 0x2c1b3c6d, dim.(u32) + 1);
    z := SampleScrambledSobol(rng.index, seed ^ 0x1eca7d79, dim.(u32) + 2);
    w := SampleScrambledSobol(rng.index, seed ^ 0x10afe4e7, dim.(u32) + 2);
    return .{x, y, z, w};
}

#scope_file

//------------------------------------------------------------------------
// Sobol Sampler
// The following code is based on the paper:
//      https://jcgt.org/published/0009/04/01/
// The direction tables are generated using generate.jai file
// If higher dimension are needed, modifiy the file to generate more dimensions:
//      jai.exe source/generate.jai

#load "sobol_lut.jai";

SOBOL_MATRIX_SIZE    :: 32;
SOBOL_INV_RESOLUTION :: 0h2f800000;

SampleScrambledSobol :: (index: u32, seed: u32, dim: u32) -> float
{
    v := ScrambledSobol(index, seed, dim);
    return min(v.(float) * SOBOL_INV_RESOLUTION, 1.0 - FLOAT_EPS);
}

ScrambledSobol :: inline (index: u32, seed: u32, dim: u32) -> u32
{
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

HashDimension :: (dim: Path_Dimension) -> u32
{
    x := dim.(u32);
    // Finalizer from murmurhash3
    x ^= x >> 16;
    x *= 0x85ebca6b;
    x ^= x >> 13;
    x *= 0xc2b2ae35;
    x ^= x >> 16;
    return x;
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

