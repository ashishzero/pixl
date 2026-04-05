#scope_export

// TODO: cleanup, move these to separate files?

sdiv :: inline (x: $T, y: T) -> T
{
    if (y != 0)
    {
        return x/y;
    }
    return 0;
}

max :: inline (x: $T, y: T) -> T
{
    return ifx x > y then x else y;
}

min :: inline (x: $T, y: T) -> T
{
    return ifx x < y then x else y;
}

clamp :: inline (x: $T, a: T, b: T) -> T
{
    if x < a  x = a;
    if x > b  x = b;
    return x;
}

hash_combine :: inline (seed: u32, v: u32) -> u32
{
    return seed ^ (v + (seed << 6) + (seed >> 2));
}
