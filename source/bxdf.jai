
BSDF_Sample :: struct
{
    Fr  : Vector3;
    L   : Vector3;
    pdf : float;
}

#scope_file

INV_PI    :: 1.0 / PI;
PI_OVER_4 :: PI / 4;
PI_OVER_2 :: PI / 2;

//------------------------------------------------------------------------
// Diffuse Model
// EON: Apractical energy-preserving rough diffuse BRDF
// https://arxiv.org/pdf/2410.18026

#scope_file

FON1 :: 0.5- 2.0 / (3.0 * PI);
FON2 :: 2.0/ 3.0 - 28.0 / (15.0 * PI);

EFonApprox :: (mu: float, roughness: float) -> float
{
    G_COEFFS :: Vector2.[ .{0.05710852, -0.3321814}, .{0.4918818, 0.07144299} ];
    mucomp   := 1.0 - mu;
    mucomp2  := mucomp * mucomp;
    vcomp    := Vector2.{mucomp, mucomp2};
    gx       := dot(G_COEFFS[0], vcomp);
    gy       := dot(G_COEFFS[1], vcomp);
    goverpi  := gx + gy * mucomp2;
    return(1.0 + roughness * goverpi) / (1.0 + FON1 * roughness);
}

LTC_Coeffs :: (mu: float, roughness: float) -> float, float, float, float
{
    r := roughness;
    a := 1.0 + r * (0.303392 + (-0.518982 + 0.111709 * mu) * mu + (-0.276266 + 0.335918 * mu) * r);
    b := r * (-1.16407 + 1.15859 * mu + (0.150815 - 0.150105 * mu) * r) / (mu * mu * mu - 1.43545);
    c := 1.0 + (0.20013 + (-0.506373 + 0.261777 * mu) * mu) * r;
    d := ((0.540852 + (-1.01625 + 0.475392 * mu) * mu) * r) / (-1.0743 + mu * (0.0725628 + mu));
    return a, b, c, d;
}

LTC_OrthonormalBasis :: (w: Vector3) -> Matrix3
{
    lensq := dot(w.xy, w.xy);
    X     := ifx (lensq > 0.0) then (Vector3.{w.x, w.y, 0.0} / sqrt(lensq)) else Vector3.{1, 0, 0};
    Y     := Vector3.{-X.y, X.x, 0.0}; // cross(Z, X)
    Z     := Vector3.{0, 0, 1};

    LTC : Matrix3 = ---;
    LTC.v[0] = X;
    LTC.v[1] = Y;
    LTC.v[2] = Z;
    return LTC;
}

CLTC_Sample :: (V: Vector3, roughness: float, u1: float, u2: float) -> Vector3, float
{
    a, b, c, d := LTC_Coeffs(abs(V.z), roughness);    // coeffs of LTC M
    radius     := sqrt(u1);                           // CLTC sampling
    phi        := 2.0 * PI * u2;                      // CLTC sampling
    x          := radius * cos(phi);                  // CLTC sampling factors
    y          := radius * sin(phi);                  // CLTC sampling factors
    vz         := 1.0 / sqrt(d * d + 1.0);            // CLTC sampling factors
    s          := 0.5 * (1.0 + vz);                   // CLTC sampling factors
    x           = -mix(sqrt(1.0 - y * y), x, s);      // CLTC sampling
    wh         := Vector3.{x, y, sqrt(max(1.0 - (x * x + y * y), 0.0))}; // H sample via CLTC
    pdf_H      := wh.z / (PI * s);                    // PDF of H sample
    L          := Vector3.{a * wh.x + b * wh.z, c * wh.y, d * wh.x + wh.z}; // M H (unnormalized)
    len        := length(L);                          // ∥M H∥=1/∥inv(M) H∥
    detM       := c * (a- b * d);                     // |M|
    pdf_L      := pdf_H * len * len * len / detM;     // L sample PDF
    from_LTC   := LTC_OrthonormalBasis(V);            // L -> local space
    L           = normalize(from_LTC * L);            // L -> local space
    return L, pdf_L;
}

CLTC_PDF :: (V_local: Vector3, L_local: Vector3, roughness: float) -> float
{
    to_LTC     := transpose(LTC_OrthonormalBasis(V_local)); // V -> LTC space
    L          := to_LTC * L_local;                          // V -> LTC space
    a, b, c, d := LTC_Coeffs(abs(V_local.z), roughness);     // coeffs of LTC M
    detM       := c * (a - b * d);                           // |M|
    H          := Vector3.{c * (L.x - b * L.z), (a - b * d) * L.y, -c * (d * L.x - a * L.z)}; // adj(M)L
    lensq      := dot(H, H);                                 // |M|∥inv(M) H∥
    vz         := 1.0 / sqrt(d * d + 1.0);                   // CLTC sampling factors
    s          := 0.5 * (1.0 + vz);                          // CLTC sampling factors
    pdf        := detM * detM/(lensq * lensq) * max(H.z, 0.0) / (PI * s);
    return pdf;
}

SampleUniformLobe :: (u1: float, u2: float) -> Vector3
{
    sintheta := sqrt(1.0 - u1 * u1);
    phi      := 2.0 * PI * u2;
    L : Vector3 = ---;
    L.x = sintheta * cos(phi);
    L.y = sintheta * sin(phi);
    L.z = u1;
    return L;
}

#scope_export

DiffuseFr :: (V: Vector3, L: Vector3, color: Vector3, roughness: float) -> Vector3
{
    NoV      := saturate(V.z);
    NoL      := saturate(L.z);
    VoL      := saturate(dot(V, L));
    s        := VoL - NoL * NoV;
    s_over_t := ifx (s > 0.0) then (s / max(max(NoL, NoV), 1.0e-6)) else s; // FON s/t
    AF       := 1.0 / (1.0 + FON1 * roughness);                             // FON A coeff
    f_ss     := (color * INV_PI) * AF * (1.0 + roughness * s_over_t);       // single-scatter
    EFo      := EFonApprox(NoV, roughness);                                 // FON V albedo(approx)
    EFi      := EFonApprox(NoL, roughness);                                 // FON L albedo(approx)
    avgEF    := AF * (1.0 + FON2 * roughness);                              // average albedo
    rho_ms   := (color * color) * avgEF / (Vector3.{1, 1, 1} - color * (1.0 - avgEF));
    eps      := 1.0e-6;
    f_ms     := (rho_ms * INV_PI) * max(eps, 1.0 - EFo) * max(eps, 1.0 - EFi) / max(eps, 1.0 - avgEF); // multi-scatterlobe
    return f_ss + f_ms;
}

DiffusePDF :: (V: Vector3, L: Vector3, roughness: float) -> float
{
    NoV   := saturate(V.z);
    P_u   := pow(roughness, 0.1) * (0.162925 + NoV * (-0.372058 + (0.538233 - 0.290822 * NoV) * NoV));
    P_c   := 1.0 - P_u;
    pdf_c := CLTC_PDF(V, L, roughness);
    pdf_u := 1.0 / (2.0 * PI);
    return P_u * pdf_u + P_c * pdf_c;
}

DiffuseSample :: (V: Vector3, color: Vector3, roughness: float, u1: float, u2: float) -> BSDF_Sample
{
    NoV   := V.z;
    P_u   := pow(roughness, 0.1) * (0.162925 + NoV * (-0.372058 + (0.538233 - 0.290822 * NoV) * NoV));
    P_c   := 1.0 - P_u; // probability of CLTC sample

    L     : Vector3 = ---;
    pdf_c : float   = ---;

    if (u1 < P_u)
    {
        u1    = u1 / P_u;
        L     = SampleUniformLobe(u1, u2); // sample L from uniform lobe
        pdf_c = CLTC_PDF(V, L, roughness); // evaluate CLTC PDF at L
    }
    else
    {
        u1       = (u1 - P_u) / P_c;
        L, pdf_c = CLTC_Sample(V, roughness, u1, u2); // sample L from CLTC lobe
    }

    Fr    := DiffuseFr(V, L, color, roughness);
    pdf_u := 1.0 / (2.0 * PI);
    pdf   := P_u * pdf_u + P_c * pdf_c; // MIS PDF of L
    return .{Fr, L, pdf};
}

//------------------------------------------------------------------------
// Microfacet Model
// Trowbridge–Reitz (GGX) model
// https://www.pbrt.org/

#scope_export

MicrofacetAnisotropicDistribution :: (NoH: float, alpha: Vector2) -> float
{
    alpha_x  := max(alpha.x, 1.0e-3);
    alpha_y  := max(alpha.y, 1.0e-3);
    alpha_x2 := alpha_x * alpha_x;
    alpha_y2 := alpha_y * alpha_y;
    cos2     := NoH * NoH;
    sin2     := 1 - cos2;
    f        := sin2 * (cos2 / alpha_x2 + sin2 / alpha_y2) + cos2;
    inv_D    := PI * alpha_x * alpha_y * f * f;
    D        := 1.0 / max(1.0e-6, inv_D);
    return D;
}

MicrofacetMask :: (mu: float, alpha: Vector2) -> float
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

MicrofacetMaskShadow :: (NoV: float, NoL: float, alpha: Vector2) -> float
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

MicrofacetSample :: (V: Vector3, alpha: Vector2, u1: float, u2: float) -> Vector3
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

MicrofacetAnisotropicAlpha :: (roughness: float, anisotropic: float) -> Vector2
{
    r       := clamp(roughness, 1.0e-3, 1.0);
    r2      := r * r;
    aspect  := sqrt(1.0 - 0.9 * anisotropic);
    alpha_x := r2 / aspect;
    alpha_y := r2 * aspect;
    alpha   := Vector2.{alpha_x, alpha_y};
    return alpha;
}

//------------------------------------------------------------------------
// Metal Model
// F82-tint

#scope_file

Reflect :: inline (d: Vector3, n: Vector3) -> Vector3
{
    return -d + 2 * dot(d, n) * n;
}

F_Schlick :: (Fo: Vector3, mu: float) -> Vector3
{
    w1 := 1.0 - mu;
    w2 := w1 * w1;
    w5 := w2 * w2 * w1; // pow(1 - mu, 5)
    F := Fo + (Vector3.{1, 1, 1} - Fo) * w5;
    return F;
}

Power6 :: inline (x: float) -> float
{
    x2 := x * x;
    x3 := x2 * x;
    x6 := x3 * x3;
    return x6;
}

F82Tint :: (mu: float, Fo: Vector3, specular_weight: float, specular_color: Vector3) -> Vector3
{
    mu82   := 1.0 / 7.0;
    f_mu   := F_Schlick(Fo, mu);
    f_82   := F_Schlick(Fo, mu82);
    r_mu   := mu * Power6(1.0 - mu);
    r_82   := mu82 * Power6(1.0 - mu82);
    f_spec := r_mu * f_82 * (Vector3.{1, 1, 1} - specular_color) / r_82;
    tinted := max(f_mu - f_spec, Vector3.{0, 0, 0});
    return specular_weight * tinted;
}

#scope_export

MetalFr :: (V: Vector3, L: Vector3, Fo: Vector3, specular_weight: float, specular_color: Vector3, roughness: float, anisotropic: float) -> Vector3
{
    if (roughness < 1.0e-3)
    {
        return .{0, 0, 0};
    }
    else
    {
        alpha  := MicrofacetAnisotropicAlpha(roughness, anisotropic);
        H      := normalize(V + L);
        NoV    := saturate(V.z);
        NoL    := saturate(L.z);
        NoH    := saturate(H.z);
        VoH    := saturate(dot(V, H));
        D      := MicrofacetAnisotropicDistribution(NoH, alpha);
        G      := MicrofacetMaskShadow(NoV, NoL, alpha);
        Fm     := F82Tint(VoH, Fo, specular_weight, specular_color);
        Fr     := D * G * Fm / max(4 * NoL * NoV, 1.0e-6);
        return Fr;
    }
}

MetalPDF :: (V: Vector3, L: Vector3, roughness: float, anisotropic: float) -> float
{
    if (roughness < 1.0e-3)
    {
        return 0.0;
    }
    else
    {
        H     := normalize(V + L);
        VoH   := saturate(dot(V, H));
        NoH   := saturate(H.z);
        NoV   := saturate(V.z);
        alpha := MicrofacetAnisotropicAlpha(roughness, anisotropic);
        D     := MicrofacetAnisotropicDistribution(NoH, alpha);
        G1    := MicrofacetMask(NoV, alpha);
        pdf   := (D * G1) / max(4 * NoV, 1.0e-6);
        return pdf;
    }
}

MetalSample :: (V: Vector3, Fo: Vector3, specular_weight: float, specular_color: Vector3, roughness: float, anisotropic: float, u1: float, u2: float) -> BSDF_Sample
{
    if (roughness < 1.0e-3)
    {
        L   := Vector3.{-V.x, -V.y, V.z};
        pdf := 1.0;
        mu  := L.z;
        Fr  := F82Tint(mu, Fo, specular_weight, specular_color) / max(mu, 1.0e-6);
        return .{Fr, L, pdf};
    }
    else
    {
        alpha  := MicrofacetAnisotropicAlpha(roughness, anisotropic);
        H      := MicrofacetSample(V, alpha, u1, u2);
        L      := Reflect(V, H);
        NoV    := V.z;
        NoL    := L.z;
        NoH    := H.z;
        VoH    := dot(V, H);
        D      := MicrofacetAnisotropicDistribution(NoH, alpha);
        G      := MicrofacetMaskShadow(NoV, NoL, alpha);
        G1     := MicrofacetMask(NoV, alpha);
        Fm     := F82Tint(VoH, Fo, specular_weight, specular_color);
        Fr     := (D * G * Fm) / max(4 * NoL * NoV, 1.0e-6);
        pdf    := (D * G1) / max(4 * NoV, 1.0e-6);
        //print("D = %, G = %, Fm = %, pdf = %, Fr = %, Fr/pdf = %, denom = %\n", D, G, Fm, pdf, Fr, Fr/pdf, max(4 * NoL * NoV, 1.0e-6));
        return .{Fr, L, pdf};
    }
}

//------------------------------------------------------------------------
