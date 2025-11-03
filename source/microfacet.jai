
//------------------------------------------------------------------------
// Microfacet Model
// Trowbridge–Reitz (GGX) model

microfacet_ggx_distribution :: (NoH: float, alpha: Vector2) -> float
{
    alpha_x  := max(alpha.x, 1.0e-3);
    alpha_y  := max(alpha.y, 1.0e-3);
    alpha_x2 := alpha_x * alpha_x;
    alpha_y2 := alpha_y * alpha_y;
    cos2     := max(NoH * NoH, 1.0e-6);
    sin2     := 1 - cos2;
    tan2     := sin2 / cos2;
    cos4     := cos2 * cos2;
    f        := 1.0 + tan2 * (cos2 / alpha_x2 + sin2 / alpha_y2);
    inv_D    := PI * alpha_x * alpha_y * cos4 * f * f;
    D        := 1.0 / max(1.0e-6, inv_D);
    return D;
}

microfacet_ggx_mask :: (mu: float, alpha: Vector2) -> float
{
    cos_mu    := saturate(mu);
    cos2      := max(cos_mu * cos_mu, 1.0e-6);
    sin2      := 1.0 - cos2;
    sin_mu    := sqrt(sin2);
    alpha2    := square(alpha.x * cos_mu) + square(alpha.y * sin_mu);
    lambda    := 0.5 * (sqrt(1.0 + alpha2 * sin2 / cos2) - 1.0);
    G         := 1.0 / (1.0 + lambda);
    return G;
}

microfacet_ggx_mask_shadow :: (NoV: float, NoL: float, alpha: Vector2) -> float
{
    cosV      := saturate(NoV);
    cosL      := saturate(NoL);
    cosV2     := max(cosV * cosV, 1.0e-6);
    cosL2     := max(cosL * cosL, 1.0e-6);
    sinV2     := 1.0 - cosV2;
    sinL2     := 1.0 - cosL2;
    sinV      := sqrt(sinV2);
    sinL      := sqrt(sinL2);
    alphaV2   := square(alpha.x * cosV) + square(alpha.y * sinV);
    alphaL2   := square(alpha.x * cosL) + square(alpha.y * sinL);
    GV        := 0.5 * (sqrt(1.0 + alphaV2 * sinV2 / cosV2) - 1.0);
    GL        := 0.5 * (sqrt(1.0 + alphaL2 * sinL2 / cosL2) - 1.0);
    G         := 1.0 / (1.0 + GL + GV);
    return G;
}

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
    y    = (1.0 - s) * sqrt(max(0.0, 1.0 - x * x)) + s * y;
    
    H   := x * X + y * Y + sqrt(max(0.0, 1.0 - x * x - y * y)) * N;
    H.x *= alpha.x;
    H.y *= alpha.y;
    H.z  = max(1.0e-6, H.z);
    H    = normalize(H);
    return H;
}

microfacet_ggx_brdf_cosine :: (V: Vector3, alpha: Vector2, u: Vector2) -> float
{
    H      := microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
    L      := reflect(V, H);
    NoV    := V.z;
    NoL    := L.z;
    G      := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
    G1     := microfacet_ggx_mask(NoV, alpha);
    f      := G / G1; // includes cosine term
    return f;
}

microfacet_alpha :: (roughness: float, anisotropic: float) -> Vector2
{
    r       := clamp(roughness, 1.0e-3, 1.0);
    r2      := r * r;
    aspect  := 0.9 * anisotropic;
    alpha_x := r2 * (1.0 + aspect);
    alpha_y := r2 * (1.0 - aspect);
    alpha   := Vector2.{alpha_x, alpha_y};
    return alpha;
}
