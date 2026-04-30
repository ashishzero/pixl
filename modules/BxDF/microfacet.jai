
//------------------------------------------------------------------------
// Microfacet Model
// Trowbridge–Reitz (GGX) model
// https://jcgt.org/published/0003/02/03/

#scope_export

MICROFACET_MIN_ROUGHNESS :: 1.0e-3;

microfacet_isotropic_alpha :: (roughness: float, $delta_supported: bool) -> float
{
    if (roughness < MICROFACET_MIN_ROUGHNESS && !delta_supported)
    {
        roughness = MICROFACET_MIN_ROUGHNESS;
    }
    alpha := roughness * roughness;
    return alpha;
}

microfacet_anisotropic_alpha :: (roughness: float, anisotrophy: float, $delta_supported: bool) -> Vector2
{
    alpha_iso   := microfacet_isotropic_alpha(roughness, delta_supported);
    anisotrophy *= 0.999999;

    alpha: Vector2;
    if (anisotrophy > 0.0)
    {
        inv_aniso := 1.0 - anisotrophy;
        alpha.x = alpha_iso * sqrt(2.0 / (1.0 + inv_aniso * inv_aniso));
        alpha.y = inv_aniso * alpha.x;
    }
    else
    {
        alpha.x = alpha_iso;
        alpha.y = alpha_iso;
    }

    if (!delta_supported)
    {
        alpha.x = max(alpha.x, alpha_iso);
        alpha.y = max(alpha.y, alpha_iso);
    }

    return alpha;
}

#scope_module

microfacet_ggx_distribution :: (wh: Vector3, alpha: Vector2) -> float
{
    whs      := wh / Vector3.{alpha.x, alpha.y, 1.0};
    lensq    := length_squared(whs);
    inv_dist := PI * alpha.x * alpha.y * lensq * lensq;
    dist     := 1.0 / max(inv_dist, 1.0e-6);
    return dist;
}

microfacet_ggx_lambda :: inline (w: Vector3, alpha: Vector2) -> float
{
    alpha_x      := alpha.x * w.x;
    alpha_y      := alpha.y * w.y;
    cos_theta_sq := max(w.z * w.z, 1.0e-6);
    tan_alpha_sq := (alpha_x * alpha_x + alpha_y * alpha_y) / cos_theta_sq;
    lambda       := 0.5 * (sqrt(1.0 + tan_alpha_sq) - 1.0);
    return lambda;
}

microfacet_ggx_mask :: (w: Vector3, alpha: Vector2) -> float
{
    lambda := microfacet_ggx_lambda(w, alpha);
    mask   := 1.0 / (1.0 + lambda);
    return mask;
}

microfacet_ggx_mask_shadow :: (wo: Vector3, wi: Vector3, alpha: Vector2) -> float
{
    lambda_wo   := microfacet_ggx_lambda(wo, alpha);
    lambda_wi   := microfacet_ggx_lambda(wi, alpha);
    mask_shadow := 1.0 / (1.0 + lambda_wo + lambda_wi);
    return mask_shadow;
}

// GGX VNDF importance sampling
// https://jcgt.org/published/0007/04/01/
microfacet_ggx_sample_vndf :: (wo: Vector3, alpha: Vector2, u1: float, u2: float) -> Vector3
{
    basis_n  := normalize(Vector3.{alpha.x * wo.x, alpha.y * wo.y, wo.z});
    lensq    := basis_n.x * basis_n.x + basis_n.y * basis_n.y;

    basis_x  := ifx (lensq > 0.0)
    {
        inv_len := 1.0 / sqrt(lensq);
        Vector3.{-basis_n.y * inv_len, basis_n.x * inv_len, 0.0};
    }
    else
    {
        Vector3.{1.0, 0.0, 0.0};
    };

    basis_y := cross(basis_n, basis_x);

    r   := sqrt(u1);
    phi := 2.0 * PI * u2;
    x   := r * cos(phi);
    y   := r * sin(phi);
    s   := 0.5 * (1.0 + basis_n.z);
    y    = (1.0 - s) * sqrt(1.0 - x * x) + s * y;

    wh   := x * basis_x + y * basis_y + sqrt(max(0.0, 1.0 - x * x - y * y)) * basis_n;
    wh.x *= alpha.x;
    wh.y *= alpha.y;
    wh.z  = max(0.0, wh.z);
    wh    = normalize(wh);
    return wh;
}

// TODO:
// Combine all GGX functions into 1
// Separate multi-scatter sampling into different functions

//------------------------------------------------------------------------
// Glossy/Specular BxDF

//#scope_module

//Glossy_Specular_Surface :: struct
//{
//    alpha            : Vector2;

//    // Metallic
//    metalness        : float;
//    reflectance      : Spectrum;
//    edge_tint        : Spectrum;
//    falloff          : Spectrum;

//    // Dielectric
//    eta_t_over_eta_i : float;
//}

//Microfacet_GGX_Surface :: struct
//{
//    alpha: Vector2;
//}

//Metallic_Surface :: struct
//{
//    using base  : Microfacet_GGX_Surface;
//    reflectance : Spectrum;
//    edge_tint   : Spectrum;
//    falloff     : Spectrum;
//}

//Opaque_Dielectric_Surface :: struct
//{
//    using base       : Microfacet_GGX_Surface;
//    eta_t_over_eta_i : float;
//}

//Transmissive_Dielectric_Surface :: struct
//{
//    using base       : Microfacet_GGX_Surface;
//    eta_t_over_eta_i : float;
//    transport        : Transport;
//}

//is_surface_delta :: (surface: $T/Microfacet_GGX_Surface) -> bool
//{
//    is_delta := max(surface.alpha.x, surface.alpha.y) < 1.0e-3;
//    #if type_of(surface) == Opaque_Dielectric_Surface || type_of(surface) == Transmissive_Dielectric_Surface
//    {
//        is_delta = is_delta || (surface.eta_t_over_eta_i == 1.0);
//    }
//    return is_delta;
//}

//fresnel_general :: (surface: $T/Microfacet_GGX_Surface, VoH: float) -> Spectrum
//{
//    #if type_of(surface) == Metallic_Surface
//    {
//        F := fresnel_metal(surface.reflectance, surface.edge_tint, surface.falloff, VoH);
//        return F;
//    }
//    else #if type_of(surface) == Opaque_Dielectric_Surface || type_of(surface) == Transmissive_Dielectric_Surface
//    {
//        F := fresnel_dielectric(surface.eta_t_over_eta_i, VoH);
//        return .{F, F, F};
//    }
//    return Spectrum_One;
//}

//sample_microfacet_ggx :: (surface: $T/Microfacet_GGX_Surface, V: Vector3, p: float, u: Vector2) -> Sampled_BSDF
//{
//    if !is_surface_delta(surface)
//    {
//        H := microfacet_ggx_sample_vndf(V, alpha, u.x, u.y);
//        F := fresnel_general(surface, dot(V, H));

//        #if type_of(surface) == Transmissive_Dielectric_Surface
//        {
//            P_r := max(F.x, F.y, F.z);
//            P_t := 1.0 - P_r;

//            if (p < P_t)
//            {
//                L, refracted := refract(-V, H, surface.eta_t_over_eta_i);
//                if (refracted)
//                {
//                    NoV     := V.z;
//                    NoL     := abs(L.z);
//                    VoH     := dot(V, H);
//                    LoH     := -dot(L, H);
//                    D       := microfacet_ggx_distribution(H, alpha);
//                    G       := microfacet_ggx_mask_shadow(V, L, alpha);
//                    G1      := microfacet_ggx_mask(V, alpha);
//                    dL_sqrt := LoH + VoH / surface.eta_t_over_eta_i;
//                    dL      := dL_sqrt * dL_sqrt;
//                    VoLoH   := VoH * LoH;
//                    f       := ((Spectrum_One - F) * D * G * VoLoH) / max(dL * NoL * NoV, 1.0e-6);
//                    f       /= (surface.eta_t_over_eta_i * surface.eta_t_over_eta_i);
//                    pdf     := (P_t * D * G1 * VoLoH) / max(dL * NoV, 1.0e-6);
//                    return sampled_bsdf(f, pdf, L, .TRANSMISSION);
//                }
//                else
//                {
//                    P_r = 1.0;
//                }
//            }
//        }
//        else
//        {
//            P_r := 1.0;
//        }

//        L := reflect(-V, H);
//        if (L.z > 0.0)
//        {
//            NoV := V.z;
//            NoL := L.z;
//            D   := microfacet_ggx_distribution(H, alpha);
//            G   := microfacet_ggx_mask_shadow(V, L, alpha);
//            G1  := microfacet_ggx_mask(V, alpha);
//            f   := (F * D * G) / max(4 * NoL * NoV, 1.0e-6);
//            pdf := (P_r * D * G1) / max(4 * NoV, 1.0e-6);

//            return sampled_bsdf(f, L, .REFLECTION);
//        }
//    }
//    else
//    {
//        H := Vector3.{0, 0, 1};
//        F := fresnel_general(surface, dot(V, H));

//        #if type_of(surface) == Transmissive_Dielectric_Surface
//        {
//            P_r := max(F.x, F.y, F.z);
//            P_t := 1.0 - P_r;

//            if (p < P_t)
//            {
//                L, refracted := refract(-V, H, surface.eta_t_over_eta_i);
//                if (refracted)
//                {
//                    f   := (Spectrum_One - F);
//                    f   /= (surface.eta_t_over_eta_i * surface.eta_t_over_eta_i);
//                    pdf := 1.0;
//                    return sampled_bsdf(f, pdf, L, .TRANSMISSION);
//                }
//                else
//                {
//                    P_r = 1.0;
//                }
//            }
//        }

//        L   := reflect(-V, H);
//        f   := F;
//        pdf := 1.0;
//        return sampled_bsdf(f, L, .REFLECTION);
//    }

//    return .{};
//}

//GGX_Sampled_BSDF :: struct
//{
//    using base: Sampled_BSDF;
//    H         : Vector3;
//}

//sampled_bsdf :: inline (bsdf: BSDF, L: Vector3, lobes: Lobe_Type, H: Vector3) -> GGX_Sampled_BSDF
//{
//    //return .{.{bsdf.f, bsdf.pdf, L, lobes}, H};
//    return .{};
//}

//evaluate_ggx_specular_reflect :: (V: Vector3, L: Vector3, H: Vector3, alpha: Vector2) -> BSDF
//{
//    NoV := V.z;
//    NoL := L.z;
//    D   := microfacet_ggx_distribution(H, alpha);
//    G   := microfacet_ggx_mask_shadow(V, L, alpha);
//    G1  := microfacet_ggx_mask(V, alpha);
//    f   := (D * G) / max(4 * NoL * NoV, 1.0e-6);
//    pdf := (D * G1) / max(4 * NoV, 1.0e-6);
//    return .{.{f, f, f}, pdf};
//}

//evaluate_ggx_specular_refract :: (V: Vector3, L: Vector3, H: Vector3, alpha: Vector2, ior: float) -> BSDF
//{
//    NoV     := V.z;
//    NoL     := abs(L.z);
//    VoH     := dot(V, H);
//    LoH     := -dot(L, H);
//    D       := microfacet_ggx_distribution(H, alpha);
//    G       := microfacet_ggx_mask_shadow(V, L, alpha);
//    G1      := microfacet_ggx_mask(V, alpha);
//    dL_sqrt := LoH + VoH / ior;
//    dL      := dL_sqrt * dL_sqrt;
//    VoLoH   := VoH * LoH;
//    f       := (D * G * VoLoH) / max(dL * NoL * NoV, 1.0e-6);
//    pdf     := (D * G1 * VoLoH) / max(dL * NoV, 1.0e-6);
//    return .{.{f, f, f}, pdf};
//}

//sample_ggx_specular_reflect :: (V: Vector3, alpha: Vector2, u: Vector2) -> GGX_Sampled_BSDF
//{
//    H := microfacet_ggx_sample_vndf(V, alpha, u.x, u.y);
//    L := reflect(-V, H);
//    brdf := evaluate_ggx_specular_reflect(V, L, H, alpha);
//    //return sampled_bsdf(brdf, L, ._REFLECTION, H);
//    return .{};
//}
