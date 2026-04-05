
#scope_module

eval_transparent :: (V: Vector3, L: Vector3, surface: Surface) -> BxDF_Eval
{
    return .{};
}

sample_transparent :: (V: Vector3, surface: Surface, u: Vector3) -> BxDF_Sample
{
    L   := -V;
    mu  := abs(L.z);
    f   := Spectrum_One / max(mu, 1.0e-6);
    pdf := 1.0;
    return .{.{f, pdf}, L};
}
