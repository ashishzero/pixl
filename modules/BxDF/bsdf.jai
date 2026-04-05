
#scope_export

eval_surface_lobe :: (V: Vector3, L: Vector3, surface: Surface, index: Lobe_Index) -> BxDF_Eval
{
    if #complete index ==
    {
        case .DIFFUSE;
            return eval_diffuse_eon(V, L, surface);
        case .CONDUCTOR;
            return eval_conductor_f82(V, L, surface);
        case .DIELECTRIC;
            return eval_dielectric(V, L, surface);
        case .TRANSPARENT;
            return eval_transparent(V, L, surface);
    }
}

sample_surface_lobe :: (V: Vector3, surface: Surface, u: Vector3, index: Lobe_Index) -> BxDF_Sample
{
    if #complete index ==
    {
        case .DIFFUSE;
            return sample_diffuse_eon(V, surface, u);
        case .CONDUCTOR;
            return sample_conductor_f82(V, surface, u);
        case .DIELECTRIC;
            return sample_dielectric(V, surface, u);
        case .TRANSPARENT;
            return sample_transparent(V, surface, u);
    }
}

eval_surface :: (V: Vector3, L: Vector3, surface: Surface) -> BxDF_Eval
{
    weights := calculate_lobe_weights(surface);
    bsdf    : BxDF;
    for 0..MAX_LOBE_INDEX-1
    {
        index    := it.(Lobe_Index);
        bxdf     := f_surface_bxdf_lobe(V, L, surface, index);
        bsdf.f   += weights[it] * bxdf.f;
        bsdf.pdf += weights[it] * bxdf.pdf;
    }
    return bsdf;
}

sample_surface :: (V: Vector3, surface: Surface, p: float, u: Vector3) -> BxDF_Sample
{
    weights := calculate_lobe_weights(surface);
    picked  := pick_lobe(p, weights);
    sample  := sample_surface_lobe(V, surface, u, picked);

    if (sample.pdf == 0.0)
    {
        return .{};
    }

    L := sample.L;

    weighted: BxDF_Eval;
    for 0..MAX_LOBE_INDEX-1
    {
        index := it.(Lobe_Index);
        if (index != picked)
        {
            eval         := eval_surface_lobe(V, L, surface, index);
            weighted.f   += weights[index] * eval.f;
            weighted.pdf += weights[index] * eval.pdf;
        }
    }

    weighted.f   += weights[picked] * sample.f;
    weighted.pdf += weights[picked] * sample.pdf;

    return .{weighted, L};
}

#scope_file

pick_lobe :: (p: float, weights: Lobe_Weights) -> Lobe_Index
{
    sum_p := 0.0;
    for 0..MAX_LOBE_INDEX-1
    {
        sum_p += weights[it];
        if (p < sum_p)
        {
            return it.(Lobe_Index);
        }
    }
    return .DIFFUSE;
}

calculate_lobe_weights :: (using surface: Surface) -> Lobe_Weights
{
    a   := clamp(alpha, 0.0, 1.0);
    m   := clamp(metallic, 0.0, 1.0);
    s   := clamp(specular, 0.0, 1.0);
    t   := clamp(transmission, 0.0, 1.0);
    nm  := a * (1.0 - m);

    weights: Lobe_Weights;
    weights[Lobe_Index.TRANSPARENT] = (1.0 - a);
    weights[Lobe_Index.CONDUCTOR]   = a * m;
    weights[Lobe_Index.DIFFUSE]     = nm * (1.0 - s);
    weights[Lobe_Index.DIELECTRIC]  = nm * s;

    return weights;
}
