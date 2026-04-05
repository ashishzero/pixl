#scope_module

effective_fresnel_dielectric :: inline (ior: float, cos_i: float) -> float
{
    cos_i   = saturate(cos_i);
    sin2_i := 1.0 - cos_i * cos_i;
    sin2_t := ior * ior * sin2_i;
    if (sin2_t >= 1.0)
    {
        return 1.0;
    }
    cos_t := sqrt(1 - saturate(sin2_t));
    Rs := (ior * cos_i - cos_t) / (ior * cos_i + cos_t);
    Rp := (ior * cos_t - cos_i) / (ior * cos_t + cos_i);
    R  := (Rs * Rs + Rp * Rp) * 0.5;
    return R;
}

eval_dielectric :: (V: Vector3, L: Vector3, surface: Surface) -> BxDF_Eval
{
    if (L.z > 0.0)
    {
        H    := normalize(V + L);
        R    := effective_fresnel_weight(surface, V, H);
        brdf := eval_ggx_specular_reflect(V, L, H, surface.microfacet_alpha);
        NoV  := abs(V.z);
        f    := R * surface.fresnel.F90 * brdf.f;
        pdf  := R * brdf.pdf;
        return .{f, pdf};
    }
    else if (L.z < 0.0)
    {
        H    := refracted_normal(V, L, surface.ior);
        R    := effective_fresnel_weight(surface, V, H);
        btdf := eval_ggx_specular_transmit(V, L, H, surface.ior, surface.microfacet_alpha);
        f    := (Spectrum_One - R * surface.fresnel.F90) * btdf.f;
        pdf  := (1.0 - R) * btdf.pdf;
        return .{f, pdf};
    }
    return .{};
}

sample_dielectric :: (V: Vector3, surface: Surface, u: Vector3) -> BxDF_Sample
{
    H := microfacet_ggx_sample_normal(V, surface.microfacet_alpha, u.x, u.y);
    R := effective_fresnel_weight(surface, V, H);

    if (u.z >= R)
    {
        L, refracted := refract(-V, H, surface.ior);
        if (refracted)
        {
            btdf := eval_ggx_specular_transmit(V, L, H, surface.ior, surface.microfacet_alpha);
            f    := (Spectrum_One - R * surface.fresnel.F90) * btdf.f;
            pdf  := (1.0 - R) * btdf.pdf;
            return .{.{f, pdf}, L};
        }
        else
        {
            R = 1.0;
        }
    }

    L := reflect(-V, H);
    if (L.z > 0.0)
    {
        brdf := eval_ggx_specular_reflect(V, L, H, surface.microfacet_alpha);
        f    := R * surface.fresnel.F90 * brdf.f;
        pdf  := R * brdf.pdf;
        return .{.{f, pdf}, L};
    }

    return .{};
}

#scope_file

refracted_normal :: inline (V: Vector3, L: Vector3, ior: float) -> Vector3
{
    H := normalize(V + ior * L);
    if (H.z < 0.0)
    {
        H = -H;
    }
    return H;
}

effective_fresnel_weight :: (surface: Surface, V: Vector3, H: Vector3) -> float
{
    fresnel := effective_fresnel_dielectric(surface.ior, dot(V, H));
    weight  := fresnel * surface.transmission + 1.0 - surface.transmission;
    return weight;
}
