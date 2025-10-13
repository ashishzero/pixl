
//------------------------------------------------------------------------
// @todo
// https://psychopath.io/post/2021_01_30_building_a_better_lk_hash
// https://psychopath.io/post/2022_07_24_owen_scrambling_based_dithered_blue_noise_sampling

Sampler :: struct
{
    index           : u32;
    seed            : u32;
    bounce          : u32;
    scatter         : u32;
    dims_per_bounce : u32;
}

MAX_SCATTER           : u32 : 1;
DIMENSION_PER_SCATTER : u32 : 3;

SamplePixel :: (sampler: Sampler) -> Vector2
{
    x := SampleShuffledScrambledSobol(sampler.index, sampler.seed, 0);
    y := SampleShuffledScrambledSobol(sampler.index, sampler.seed, 1);
    return .{x, y};
}

SampleLens :: (sampler: Sampler) -> Vector2
{
    x := SampleShuffledScrambledSobol(sampler.index, sampler.seed, 2);
    y := SampleShuffledScrambledSobol(sampler.index, sampler.seed, 3);
    return .{x, y};
}

NextBounce :: (sampler: *Sampler)
{
    sampler.bounce += 1;
    sampler.scatter = 0;
}

NextScatter :: (sampler: *Sampler)
{
    sampler.scatter += 1;
}

SampleLobe :: (sampler: Sampler) -> float
{
    dim := BOUNCE_D + sampler.bounce * sampler.dims_per_bounce + sampler.scatter * 3;
    x := SampleShuffledScrambledSobol(sampler.index, sampler.seed, dim);
    return x;
}

SampleL :: (sampler: Sampler) -> Vector2
{
    dim := BOUNCE_D + sampler.bounce * sampler.dims_per_bounce + sampler.scatter * 3;
    x := SampleShuffledScrambledSobol(sampler.index, sampler.seed, dim + 1);
    y := SampleShuffledScrambledSobol(sampler.index, sampler.seed, dim + 2);
    return .{x, y};
}

CreateSampler :: (index: u32, seed: u32) -> Sampler
{
    sampler: Sampler;
    sampler.index           = index;
    sampler.seed            = seed;
    sampler.bounce          = 0;
    sampler.scatter         = 0;
    sampler.dims_per_bounce = max(MAX_SCATTER, 1) * DIMENSION_PER_SCATTER;
    return sampler;
}

#scope_file

BOUNCE_D    : u32 : 4;

//------------------------------------------------------------------------
// Sobol Sampler
// https://jcgt.org/published/0009/04/01/

//------------------------------------------------------------------------
// Generated table

#scope_export

Sobol :: (index: u32, dim: u32) -> u32
{
    assert(dim < 1024);
    X : u32 = 0;
    for bit:0..31
    {
        mask := (index >> bit) & 1;
        X ^= mask * Sobol_D[dim * 32 + bit];
    }
    return X;
}

ShuffledScrambledSobol :: (index: u32, seed: u32, dim: u32) -> u32
{
    index  = NestedUniformScrambleBase2(index, seed);
    X     := Sobol(index, dim);
    X      = NestedUniformScrambleBase2(X, HashCombine(seed, dim));
    return X;
}

SampleSobol :: (index: u32, dim: u32) -> float
{
    X := Sobol(index, dim);
    return min(X.(float) * INV_MAX_SOBOL, 1.0 - EPS);
}

SampleShuffledScrambledSobol :: (index: u32, seed: u32, dim: u32) -> float
{
    EPS :: 0h34000000;
    X := ShuffledScrambledSobol(index, seed, dim);
    return min(X.(float) * INV_MAX_SOBOL, 1.0 - EPS);
}

#scope_file

#load "sobol_D.jai";

EPS           :: 0h34000000;
INV_MAX_SOBOL :: 0h2f800000;

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

LaineKarrasPermutation :: inline (x: u32, seed: u32) -> u32
{
    x += seed;
    x ^= x * 0x6c50b47c;
    x ^= x * 0xb82f1e52;
    x ^= x * 0xc7afe638;
    x ^= x * 0x8d22f6e6;
    return x;
}

NestedUniformScrambleBase2 :: inline (x: u32, seed: u32) -> u32
{
    x = ReverseBits(x);
    x = LaineKarrasPermutation(x, seed);
    x = ReverseBits(x);
    return x;
}

//------------------------------------------------------------------------
// Direction Matrix Generator
// https://web.maths.unsw.edu.au/~fkuo/sobol/

#scope_export

GenerateSobolDirectionMatrix :: (D: int)
{
    FILE  :: "source/data/sobol/new-joe-kuo-6.21201";
    File  :: #import "File";
    Basic :: #import "Basic";
    L     :: 32; // number of bits

    V : [L + 1]u32;
    m : [L + 1]u32;

    WriteV :: (last_line := false) #expand
    {
        for 1..L
        {
            Basic.print("0x%, ", Basic.FormatInt.{value=V[it], base=16, minimum_digits=8});
            if it % 4 == 0 then Basic.print("\n");
        }
        if !last_line then Basic.print("\n");
    }

    Basic.print("Sobol_D : [% * %]u32 : .[\n", D, L);

    // First dimension
    for i:1..L
    {
        V[i] = (1 << (32 - i)).(u32);
    }
    WriteV();

    content := File.read_entire_file(FILE);
    assert(content.count != 0, Basic.tprint("Sobol file: '%' could not be read", FILE));

    // Skip first line
    ok:, line:, content = split_from_left(content, #char "\n");
    assert(ok);

    // Remaining dimensions
    for j:1..D-1
    {
        ok, line, content = split_from_left(content, #char "\n");
        assert(ok);

        d:, ok = parse_int(*line, u32);
        assert(ok);

        s:, ok = parse_int(*line, u32);
        assert(ok);

        a:, ok = parse_int(*line, u32);
        assert(ok);

        for i:1..s
        {
            m[i], ok = parse_int(*line, u32);
            assert(ok);
        }

        assert(j + 1 == d);

        if (L <= s)
        {
            for i:1..L
            {
                V[i] = (m[i] << (32 - i)).(u32);
            }
        }
        else
        {
            for i:1..s
            {
                V[i] = (m[i] << (32 - i)).(u32);
            }
            for i:s+1..L
            {
                V[i] = V[i - s] ^ (V[i - s] >> s); 
                for k:1..s-1
                {
                    V[i] ^= (((a >> (s - 1 - k)) & 1) * V[i - k]); 
                }
            }
        }

        WriteV(j == D - 1);
    }

    Basic.print("];\n");
}
