#scope_export

murmur_finalize32 :: inline (x: u32) -> u32
{
    x ^= x >> 16;
    x *= 0x85ebca6b;
    x ^= x >> 13;
    x *= 0xc2b2ae35;
    x ^= x >> 16;
    return x;
}

hash_combine :: inline (seed: u32, v: u32) -> u32
{
    return seed ^ (v + (seed << 6) + (seed >> 2));
}
