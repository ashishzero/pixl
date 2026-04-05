
#scope_module

//------------------------------------------------------------------------
// Specular BRDF

eval_ggx_specular_reflect :: (V: Vector3, L: Vector3, H: Vector3, alpha: Vector2) -> BxDF_Eval
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

//------------------------------------------------------------------------
// Specular BTDF

eval_ggx_specular_transmit :: (V: Vector3, L: Vector3, H: Vector3, ior: float, alpha: Vector2) -> BxDF_Eval
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
