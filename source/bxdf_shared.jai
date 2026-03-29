
BxDF :: struct
{
    f    : Spectrum;
    pdf  : float;
};

//------------------------------------------------------------------------
// IOR Mapping: IOR = 1 + 2 * sqr(specular)

ior_relative_to_physical :: (specular: float) -> float
{
    ior := 1.0 + 2 * specular * specular;
    return ior;
}

ior_physical_to_relative :: (ior: float) -> float
{
    specular := sqrt((ior - 1.0) * 0.5);
    return specular;
}

//------------------------------------------------------------------------
// Specular BRDF

f_specular_brdf :: (V: Vector3, L: Vector3, H: Vector3, alpha: Vector2) -> BxDF
{
    NoV   := V.z;
    NoL   := L.z;
    NoH   := abs(H.z);
    D     := microfacet_ggx_distribution(NoH, alpha);
    G     := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
    G1    := microfacet_ggx_mask(NoV, alpha);
    f     := (D * G) / max(4 * NoL * NoV, 1.0e-6);
    pdf   := (D * G1) / max(4 * NoV, 1.0e-6);
    return .{.{f, f, f}, pdf};
}

pdf_specular_brdf :: (V: Vector3, L: Vector3, H: Vector3, alpha: Vector2) -> float
{
    NoV := V.z;
    NoH := H.z;
    D   := microfacet_ggx_distribution(NoH, alpha);
    G1  := microfacet_ggx_mask(NoV, alpha);
    pdf := (D * G1) / max(4 * NoV, 1.0e-6);
    return pdf;
}

//------------------------------------------------------------------------
// Specular BTDF

f_specular_btdf :: (V: Vector3, L: Vector3, H: Vector3, ior: float, alpha: Vector2) -> BxDF
{
    NoV     := V.z;
    NoL     := abs(L.z);
    NoH     := H.z;
    VoH     := dot(V, H);
    LoH     := -dot(L, H);
    D       := microfacet_ggx_distribution(NoH, alpha);
    G       := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
    G1      := microfacet_ggx_mask(NoV, alpha);
    dL_sqrt := LoH + VoH / ior;
    dL      := dL_sqrt * dL_sqrt;
    VoLoH   := VoH * LoH;
    f       := (D * G * VoLoH) / max(dL * NoL * NoV, 1.0e-6);
    pdf     := (D * G1 * VoLoH) / max(dL * NoV, 1.0e-6);
    return .{.{f, f, f}, pdf};
}

pdf_specular_btdf :: (V: Vector3, L: Vector3, H: Vector3, ior: float, alpha: Vector2) -> float
{
    NoV     := V.z;
    NoH     := H.z;
    VoH     := dot(V, H);
    LoH     := -dot(L, H);
    D       := microfacet_ggx_distribution(NoH, alpha);
    G1      := microfacet_ggx_mask(NoV, alpha);
    VoLoH   := VoH * LoH;
    dL_sqrt := LoH + VoH / ior;
    dL      := dL_sqrt * dL_sqrt;
    pdf     := (D * G1 * VoLoH) / max(dL * NoV, 1.0e-6);
    return pdf;
}

//------------------------------------------------------------------------
// Dielectric

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
