
//------------------------------------------------------------------------
// Microfacet Model
// Trowbridge–Reitz (GGX) model
// https://jcgt.org/published/0003/02/03/

#scope_export

microfacet_is_delta :: (alpha: Vector2) -> bool
{
    return max(alpha.x, alpha.y) <= MICROFACET_ALPHA_THRESHOLD;
}

microfacet_alpha :: (roughness: float, anisotropic: float) -> Vector2
{
    r2      := roughness * roughness;
    aspect  := 0.9 * anisotropic;
    alpha_x := r2 * (1.0 + aspect);
    alpha_y := r2 * (1.0 - aspect);
    alpha   := Vector2.{alpha_x, alpha_y};
    return alpha;
}

#scope_module

MICROFACET_ALPHA_THRESHOLD :: 1.0e-4;

microfacet_ggx_distribution :: (H: Vector3, alpha: Vector2) -> float
{
    alpha_x      := max(alpha.x, MICROFACET_ALPHA_THRESHOLD);
    alpha_y      := max(alpha.y, MICROFACET_ALPHA_THRESHOLD);
    Hs           := H / Vector3.{alpha_x, alpha_y, 1.0};
    lensq        := length_squared(Hs);
    inv_D        := PI * alpha_x * alpha_y * lensq * lensq;
    D            := 1.0 / max(inv_D, 1.0e-6);
    return D;
}

microfacet_ggx_lambda :: inline (V: Vector3, alpha: Vector2) -> float
{
    alpha_x      := alpha.x * V.x;
    alpha_y      := alpha.y * V.y;
    cos_theta_sq := max(V.z * V.z, 1.0e-6);
    tan_alpha_sq := (alpha_x * alpha_x + alpha_y * alpha_y) / cos_theta_sq;
    lambda       := 0.5 * (sqrt(1.0 + tan_alpha_sq) - 1.0);
    return lambda;
}

microfacet_ggx_mask :: (N: Vector3, alpha: Vector2) -> float
{
    lambda := microfacet_ggx_lambda(N, alpha);
    G1     := 1.0 / (1.0 + lambda);
    return G1;
}

microfacet_ggx_mask_shadow :: (V: Vector3, L: Vector3, alpha: Vector2) -> float
{
    lambda_V := microfacet_ggx_lambda(V, alpha);
    lambda_L := microfacet_ggx_lambda(L, alpha);
    G        := 1.0 / (1.0 + lambda_V + lambda_L);
    return G;
}

// GGX VNDF importance sampling
// https://jcgt.org/published/0007/04/01/
microfacet_ggx_sample_normal :: (V: Vector3, alpha: Vector2, u1: float, u2: float) -> Vector3
{
    N := normalize(Vector3.{alpha.x * V.x, alpha.y * V.y, V.z});

    lensq := N.x * N.x + N.y * N.y;

    X := ifx (lensq > 0.0)
    {
        inv_len := 1.0 / sqrt(lensq);
        Vector3.{-N.y * inv_len, N.x * inv_len, 0.0};
    }
    else
    {
        Vector3.{1.0, 0.0, 0.0};
    };

    Y   := cross(N, X);

    r   := sqrt(u1);
    phi := 2.0 * PI * u2;
    x   := r * cos(phi);
    y   := r * sin(phi);
    s   := 0.5 * (1.0 + N.z);
    y    = (1.0 - s) * sqrt(1.0 - x * x) + s * y;

    H   := x * X + y * Y + sqrt(max(0.0, 1.0 - x * x - y * y)) * N;
    H.x *= alpha.x;
    H.y *= alpha.y;
    H.z  = max(0.0, H.z);
    H    = normalize(H);
    return H;
}

//------------------------------------------------------------------------
// Specular BxDF

#scope_module

GGX_Sampled_BSDF :: struct
{
    using base: Sampled_BSDF;
    H         : Vector3;
}

sampled_bsdf :: inline (bsdf: BSDF, L: Vector3, transport: Transport, H: Vector3) -> GGX_Sampled_BSDF
{
    return .{.{bsdf, L, transport}, H};
}

evaluate_ggx_specular_reflect :: (V: Vector3, L: Vector3, H: Vector3, alpha: Vector2) -> BSDF
{
    NoV := V.z;
    NoL := L.z;
    D   := microfacet_ggx_distribution(H, alpha);
    G   := microfacet_ggx_mask_shadow(V, L, alpha);
    G1  := microfacet_ggx_mask(V, alpha);
    f   := (D * G) / max(4 * NoL * NoV, 1.0e-6);
    pdf := (D * G1) / max(4 * NoV, 1.0e-6);
    return .{.{f, f, f}, pdf};
}

evaluate_ggx_specular_refract :: (V: Vector3, L: Vector3, H: Vector3, alpha: Vector2, ior: float) -> BSDF
{
    NoV     := V.z;
    NoL     := abs(L.z);
    VoH     := dot(V, H);
    LoH     := -dot(L, H);
    D       := microfacet_ggx_distribution(H, alpha);
    G       := microfacet_ggx_mask_shadow(V, L, alpha);
    G1      := microfacet_ggx_mask(V, alpha);
    dL_sqrt := LoH + VoH / ior;
    dL      := dL_sqrt * dL_sqrt;
    VoLoH   := VoH * LoH;
    f       := (D * G * VoLoH) / max(dL * NoL * NoV, 1.0e-6);
    pdf     := (D * G1 * VoLoH) / max(dL * NoV, 1.0e-6);
    return .{.{f, f, f}, pdf};
}

sample_ggx_specular_reflect :: (V: Vector3, alpha: Vector2, u: Vector2) -> GGX_Sampled_BSDF
{
    H := microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
    L := reflect(-V, H);
    brdf := evaluate_ggx_specular_reflect(V, L, H, alpha);
    return sampled_bsdf(brdf, L, .REFLECTION, H);
}
