
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
