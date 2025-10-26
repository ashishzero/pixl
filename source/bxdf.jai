
Surface :: struct
{
    color                : Spectrum;
    metalness            : float;
    diffuse_roughness    : float;
    specular_weight      : float;
    specular_color       : Spectrum;
    specular_roughness   : float;
    specular_anisotropic : float;

    emission_strength    : float;
    emission             : Spectrum;

    //specular        : float;
    //subsurface      : float;
    //sheen           : float;
    //sheen_tint      : float;
    //clearcoat       : float;
    //clearcoat_gloss : float;
}

BxDF_Sample :: struct
{
    fr  : Spectrum;
    L   : Vector3;
    pdf : float;
}

#scope_file

//------------------------------------------------------------------------
// Diffuse Model
// EON: A practical energy-preserving rough diffuse BRDF
// https://arxiv.org/pdf/2410.18026

#scope_file

FON1 :: 0.5 - 2.0 / (3.0 * PI);
FON2 :: 2.0 / 3.0 - 28.0 / (15.0 * PI);

e_fon_approx :: (mu: float, roughness: float) -> float
{
    G1      :: 0.057108529;
    G2      :: 0.49188187;
    G3      :: -0.33218144;
    G4      :: 0.07144299;
    mucomp  := 1.0 - mu;
    goverpi := mucomp * (G1 + mucomp * (G2 + mucomp * (G3 + mucomp * G4)));
    return (1.0 + roughness * goverpi) / (1.0 + FON1 * roughness);
}

ltc_coeffs :: (mu: float, roughness: float) -> float, float, float, float
{
    r := roughness;
    a := 1.0 + r * (0.303392 + (-0.518982 + 0.111709 * mu) * mu + (-0.276266 + 0.335918 * mu) * r);
    b := r * (-1.16407 + 1.15859 * mu + (0.150815 - 0.150105 * mu) * r) / (mu * mu * mu - 1.43545);
    c := 1.0 + (0.20013 + (-0.506373 + 0.261777 * mu) * mu) * r;
    d := ((0.540852 + (-1.01625 + 0.475392 * mu) * mu) * r) / (-1.0743 + mu * (0.0725628 + mu));
    return a, b, c, d;
}

ltc_orthonormal_basis :: (w: Vector3) -> Matrix3
{
    lensq := dot(w.xy, w.xy);
    X     := ifx (lensq > 0.0) then (Vector3.{w.x, w.y, 0.0} / sqrt(lensq)) else Vector3.{1, 0, 0};
    Y     := Vector3.{-X.y, X.x, 0.0}; // cross(Z, X)
    Z     := Vector3.{0, 0, 1};

    LTC : Matrix3 = ---;
    LTC.v[0] = Vector3.{X.x, Y.x, Z.x};
    LTC.v[1] = Vector3.{X.y, Y.y, Z.y};
    LTC.v[2] = Vector3.{X.z, Y.z, Z.z};
    return LTC;
}

sample_cltc :: (V: Vector3, roughness: float, u1: float, u2: float) -> Vector3, float
{
    a, b, c, d := ltc_coeffs(V.z, roughness);         // coeffs of LTC M
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
    detM       := c * (a - b * d);                    // |M|
    pdf_L      := pdf_H * len * len * len / detM;     // L sample PDF
    from_LTC   := ltc_orthonormal_basis(V);            // L -> local space
    L           = normalize(from_LTC * L);            // L -> local space
    return L, pdf_L;
}

pdf_cltc :: (V_local: Vector3, L_local: Vector3, roughness: float) -> float
{
    to_LTC     := transpose(ltc_orthonormal_basis(V_local));  // V -> LTC space
    L          := to_LTC * L_local;                          // V -> LTC space
    a, b, c, d := ltc_coeffs(abs(V_local.z), roughness);     // coeffs of LTC M
    detM       := c * (a - b * d);                           // |M|
    H          := Vector3.{c * (L.x - b * L.z), (a - b * d) * L.y, -c * (d * L.x - a * L.z)}; // adj(M)L
    lensq      := dot(H, H);                                 // |M|∥inv(M) H∥
    vz         := 1.0 / sqrt(d * d + 1.0);                   // CLTC sampling factors
    s          := 0.5 * (1.0 + vz);                          // CLTC sampling factors
    pdf        := detM * detM / (lensq * lensq) * max(H.z, 0.0) / (PI * s);
    return pdf;
}

sample_uniform_lobe :: (u1: float, u2: float) -> Vector3
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

f_diffuse :: (V: Vector3, L: Vector3, surface: Surface) -> Spectrum
{
    color     := surface.color;
    roughness := surface.diffuse_roughness;
    NoV       := saturate(V.z);
    NoL       := saturate(L.z);
    VoL       := saturate(dot(V, L));
    s         := VoL - NoL * NoV;
    s_over_t  := ifx (s > 0.0) then (s / max(max(NoL, NoV), 1.0e-6)) else s; // FON s/t
    AF        := 1.0 / (1.0 + FON1 * roughness);                             // FON A coeff
    f_ss      := (color * INV_PI) * AF * (1.0 + roughness * s_over_t);       // single-scatter
    EFo       := e_fon_approx(NoV, roughness);                               // FON V albedo
    EFi       := e_fon_approx(NoL, roughness);                               // FON L albedo
    avgEF     := AF * (1.0 + FON2 * roughness);                              // average albedo
    rho_ms    := (color * color) * avgEF / (Vector3.{1, 1, 1} - color * (1.0 - avgEF));
    eps       := 1.0e-6;
    f_ms      := (rho_ms * INV_PI) * max(eps, 1.0 - EFo) * max(eps, 1.0 - EFi) / max(eps, 1.0 - avgEF); // multi-scatterlobe
    return f_ss + f_ms;
}

pdf_diffuse :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    roughness := surface.diffuse_roughness;
    NoV       := saturate(V.z);
    P_u       := pow(roughness, 0.1) * (0.162925 + NoV * (-0.372058 + (0.538233 - 0.290822 * NoV) * NoV));
    P_c       := 1.0 - P_u;
    pdf_c     := pdf_cltc(V, L, roughness);
    pdf_u     := 1.0 / (2.0 * PI);
    return P_u * pdf_u + P_c * pdf_c;
}

sample_diffuse :: (V: Vector3, surface: Surface, u: Vector2) -> BxDF_Sample
{
    roughness := surface.diffuse_roughness;

    NoV       := V.z;
    P_u       := pow(roughness, 0.1) * (0.162925 + NoV * (-0.372058 + (0.538233 - 0.290822 * NoV) * NoV));
    P_c       := 1.0 - P_u; // probability of CLTC sample

    L         : Vector3 = ---;
    pdf_c     : float   = ---;

    u1        := u.x;
    u2        := u.y;

    if (u1 < P_u)
    {
        u1    = u1 / P_u;
        L     = sample_uniform_lobe(u1, u2); // sample L from uniform lobe
        pdf_c = pdf_cltc(V, L, roughness); // evaluate CLTC PDF at L
    }
    else
    {
        u1       = (u1 - P_u) / P_c;
        L, pdf_c = sample_cltc(V, roughness, u1, u2); // sample L from CLTC lobe
    }

    fr    := f_diffuse(V, L, surface);
    pdf_u := 1.0 / (2.0 * PI);
    pdf   := P_u * pdf_u + P_c * pdf_c; // MIS PDF of L
    return .{fr, L, pdf};
}

//------------------------------------------------------------------------
// Metal Model
// F82-tint

#scope_file

f_schlick :: (Fo: Spectrum, mu: float) -> Spectrum
{
    w1 := 1.0 - mu;
    w2 := w1 * w1;
    w5 := w2 * w2 * w1; // pow(1 - mu, 5)
    F := Fo + (Spectrum_One - Fo) * w5;
    return F;
}

power6 :: inline (x: float) -> float
{
    x2 := x * x;
    x3 := x2 * x;
    x6 := x3 * x3;
    return x6;
}

f82_tint :: (mu: float, Fo: Spectrum, specular_color: Spectrum) -> Spectrum
{
    mu82   := 1.0 / 7.0;
    f_mu   := f_schlick(Fo, mu);
    f_82   := f_schlick(Fo, mu82);
    r_mu   := mu * power6(1.0 - mu);
    r_82   := mu82 * power6(1.0 - mu82);
    f_spec := r_mu * f_82 * (Spectrum_One - specular_color) / r_82;
    tinted := max(f_mu - f_spec, Vector3.{0, 0, 0});
    return tinted;
}

// Multiscatter energy preservation: https://blog.selfshadow.com/2019/03/30/multi-faceted-part-4/
// which is an approximation of https://eheitzresearch.wordpress.com/240-2/

E_avg_metallic :: (roughness: float) -> float
{
    x := roughness;
    a := 0.935594 + x * (-0.214381 - 0.0739448 * x);
    b := 0.935594 + x * (-0.213352 + x * (-0.144444 + x));
    return saturate(a / b);
}

f_ms_avg_metallic :: (Fo: Spectrum, E_avg: float) -> Spectrum
{
    W1 :: 20.0 / 21.0;
    W2 :: 1.0 / 21.0;
    Favg  := W1 * Fo + Spectrum.{W2, W2, W2};
    f_avg := Favg * Favg * E_avg / (Spectrum_One - Favg * (1.0 - E_avg));
    return f_avg;
}

f_ms_metallic :: (Fo: Spectrum, NoL: float, NoV: float, roughness: float, alpha: Vector2) -> Spectrum
{
    ErL       := read_lookup_table3D(Er_metallic, BxDF_LOOKUP_TABLE_SIZE, BxDF_LOOKUP_TABLE_SIZE, BxDF_LOOKUP_TABLE_SIZE, NoL, alpha.x, alpha.y);
    ErV       := read_lookup_table3D(Er_metallic, BxDF_LOOKUP_TABLE_SIZE, BxDF_LOOKUP_TABLE_SIZE, BxDF_LOOKUP_TABLE_SIZE, NoV, alpha.x, alpha.y);
    E_avg     := E_avg_metallic(roughness);
    f_avg     := f_ms_avg_metallic(Fo, E_avg);
    f_ms      := f_avg * ErL * ErV * INV_PI / (1.0 - E_avg);
    return f_ms;
}

#scope_export

f_metallic :: (V: Vector3, L: Vector3, surface: Surface) -> Vector3
{
    Fo             := surface.color;
    specular_color := surface.specular_color;
    roughness      := surface.specular_roughness;
    anisotropic    := surface.specular_anisotropic;

    if (roughness < 1.0e-4)
    {
        return .{0, 0, 0};
    }
    else
    {
        alpha  := microfacet_alpha(roughness, anisotropic);
        H      := normalize(V + L);
        NoV    := saturate(V.z);
        NoL    := saturate(L.z);
        NoH    := saturate(H.z);
        VoH    := saturate(dot(V, H));
        D      := microfacet_distribution(NoH, alpha);
        G      := microfacet_mask_shadow(NoV, NoL, alpha);
        Fss    := f82_tint(VoH, Fo, specular_color);
        fr     := D * G * Fss / max(4 * NoL * NoV, 1.0e-6);
        fr     += f_ms_metallic(Fo, NoL, NoV, roughness, alpha);
        return fr;
    }
}

pdf_metallic :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    roughness   := surface.specular_roughness;
    anisotropic := surface.specular_anisotropic;

    if (roughness < 1.0e-4)
    {
        return 0.0;
    }
    else
    {
        H     := normalize(V + L);
        VoH   := saturate(dot(V, H));
        NoH   := saturate(H.z);
        NoV   := saturate(V.z);
        alpha := microfacet_alpha(roughness, anisotropic);
        D     := microfacet_distribution(NoH, alpha);
        G1    := microfacet_mask(NoV, alpha);
        pdf   := (D * G1) / max(4 * NoV, 1.0e-6);
        return pdf;
    }
}

sample_metallic :: (V: Vector3, surface: Surface, u: Vector2) -> BxDF_Sample
{
    Fo             := surface.color;
    specular_color := surface.specular_color;
    roughness      := surface.specular_roughness;
    anisotropic    := surface.specular_anisotropic;

    if (roughness < 1.0e-4)
    {
        L   := Vector3.{-V.x, -V.y, V.z};
        pdf := 1.0;
        mu  := L.z;
        fr  := f82_tint(mu, Fo, specular_color) / max(mu, 1.0e-6);
        return .{fr, L, pdf};
    }
    else
    {
        alpha  := microfacet_alpha(roughness, anisotropic);
        H      := microfacet_sample(V, alpha, u.x, u.y);
        L      := reflect(V, H);
        NoV    := V.z;
        NoL    := L.z;
        NoH    := H.z;
        VoH    := dot(V, H);
        D      := microfacet_distribution(NoH, alpha);
        G      := microfacet_mask_shadow(NoV, NoL, alpha);
        G1     := microfacet_mask(NoV, alpha);
        Fss    := f82_tint(VoH, Fo, specular_color);
        fr     := (D * G * Fss) / max(4 * NoL * NoV, 1.0e-6);
        fr     += f_ms_metallic(Fo, NoL, NoV, roughness, alpha);
        pdf    := (D * G1) / max(4 * NoV, 1.0e-6);
        return .{fr, L, pdf};
    }
}

#load "microfacet.jai";
#load "bxdf_lookup.jai";
