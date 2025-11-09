
Surface :: struct
{
    color                : Spectrum;
    metalness            : float;
    diffuse_roughness    : float;
    specular_weight      : float;
    specular_color       : Spectrum;
    specular_roughness   : float;
    specular_anisotropic : float;
    specular_ior         : float;
    transmission         : float;

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
    b := sdiv(r * (-1.16407 + 1.15859 * mu + (0.150815 - 0.150105 * mu) * r), (mu * mu * mu - 1.43545));
    c := 1.0 + (0.20013 + (-0.506373 + 0.261777 * mu) * mu) * r;
    d := sdiv(((0.540852 + (-1.01625 + 0.475392 * mu) * mu) * r), (-1.0743 + mu * (0.0725628 + mu)));
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
    pdf        := sdiv(detM * detM * max(H.z, 0.0), lensq * lensq * PI * s);
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

f_schlick_metallic :: (Fo: Spectrum, mu: float) -> Spectrum
{
    w1 := 1.0 - mu;
    w2 := w1 * w1;
    w5 := w2 * w2 * w1; // pow(1 - mu, 5)
    F := Fo + (Spectrum_One - Fo) * w5;
    return F;
}

f82_tint :: (mu: float, Fo: Spectrum, specular_color: Spectrum) -> Spectrum
{
    mu82   := 1.0 / 7.0;
    f_mu   := f_schlick_metallic(Fo, mu);
    f_82   := f_schlick_metallic(Fo, mu82);
    r_mu   := mu * power6(1.0 - mu);
    r_82   := mu82 * power6(1.0 - mu82);
    f_spec := r_mu * f_82 * (Spectrum_One - specular_color) / r_82;
    tinted := max(f_mu - f_spec, Vector3.{0, 0, 0});
    return tinted;
}

microfacet_ggx_metallic_preserve_energy :: (F_ss: Spectrum, NoV: float, roughness: float) -> Spectrum
{
    // Fresnel term is based on the following blog:
    // https://blog.selfshadow.com/2018/06/04/multi-faceted-part-2/
    E_avg := read_lookup_table_1D(E_avg_metallic, METALLIC_E_AVG_LUT_SIZE, roughness);
    F_ms  := F_ss * E_avg / (Spectrum_One - F_ss * (1.0 - E_avg));

    // Energy preservation is based on the "Practical multiple scattering compensation for microfacet models" by Emmanuel Turquin
    // Reference: https://blog.selfshadow.com/publications/turquin/ms_comp_final.pdf
    k_ms := read_lookup_table_2D(k_ms_metallic, METALLIC_K_MS_LUT_SIZE, METALLIC_K_MS_LUT_SIZE, NoV, roughness);

    darkening := Spectrum_One + F_ms * k_ms;
    return darkening;
}

#scope_export

f_metallic :: (V: Vector3, L: Vector3, surface: Surface) -> Spectrum
{
    Fo             := surface.color;
    specular_color := surface.specular_color;
    roughness      := surface.specular_roughness;
    anisotropic    := surface.specular_anisotropic;

    if (roughness < 1.0e-4 || V.z * L.z <= 0.0)
    {
        return Spectrum_Zero;
    }
    else
    {
        alpha     := microfacet_alpha(roughness, anisotropic);
        H         := normalize(V + L);
        NoV       := saturate(V.z);
        NoL       := saturate(L.z);
        NoH       := saturate(H.z);
        VoH       := saturate(dot(V, H));
        D         := microfacet_ggx_distribution(NoH, alpha);
        G         := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
        F_ss      := f82_tint(VoH, Fo, specular_color);
        darkening := microfacet_ggx_metallic_preserve_energy(F_ss, NoV, roughness);
        f_ss      := D * G * F_ss / max(4 * NoL * NoV, 1.0e-6);
        fr        := darkening * f_ss;
        return fr;
    }
}

pdf_metallic :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    roughness   := surface.specular_roughness;
    anisotropic := surface.specular_anisotropic;

    if (roughness < 1.0e-4 || V.z * L.z <= 0.0)
    {
        return 0.0;
    }
    else
    {
        H      := normalize(V + L);
        VoH    := saturate(dot(V, H));
        NoH    := saturate(H.z);
        NoV    := saturate(V.z);
        alpha  := microfacet_alpha(roughness, anisotropic);
        D      := microfacet_ggx_distribution(NoH, alpha);
        G1     := microfacet_ggx_mask(NoV, alpha);
        pdf    := (D * G1) / max(4 * NoV, 1.0e-6);
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
        alpha     := microfacet_alpha(roughness, anisotropic);
        H         := microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
        L         := reflect(-V, H);

        if (L.z > 0.0)
        {
            NoV       := V.z;
            NoL       := saturate(L.z);
            NoH       := H.z;
            VoH       := dot(V, H);
            D         := microfacet_ggx_distribution(NoH, alpha);
            G         := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
            G1        := microfacet_ggx_mask(NoV, alpha);
            F_ss      := f82_tint(VoH, Fo, specular_color);
            darkening := microfacet_ggx_metallic_preserve_energy(F_ss, NoV, roughness);
            f_ss      := D * G * F_ss / max(4 * NoL * NoV, 1.0e-6);
            fr        := darkening * f_ss;
            pdf       := (D * G1) / max(4 * NoV, 1.0e-6);
            return .{fr, L, pdf};
        }

        return .{};
    }
}

//------------------------------------------------------------------------
// Specular Model

#scope_file

//microfacet_ggx_metallic_preserve_energy :: (F_ss: Spectrum, NoV: float, roughness: float) -> Spectrum
//{
//    // Fresnel term is based on the following blog:
//    // https://blog.selfshadow.com/2018/06/04/multi-faceted-part-2/
//    E_avg := read_lookup_table_1D(E_avg_metallic, METALLIC_E_AVG_LUT_SIZE, roughness);
//    F_ms  := F_ss * E_avg / (Spectrum_One - F_ss * (1.0 - E_avg));

//    // Energy preservation is based on the "Practical multiple scattering compensation for microfacet models" by Emmanuel Turquin
//    // Reference: https://blog.selfshadow.com/publications/turquin/ms_comp_final.pdf
//    k_ms := read_lookup_table_2D(k_ms_metallic, METALLIC_K_MS_LUT_SIZE, METALLIC_K_MS_LUT_SIZE, NoV, roughness);

//    darkening := Spectrum_One + F_ms * k_ms;
//    return darkening;
//}

#scope_export

f_specular_reflect :: (V: Vector3, L: Vector3, surface: Surface) -> Spectrum
{
    if (V.z * L.z > 0.0)
    {
        specular_color := surface.specular_color;
        roughness      := max(surface.specular_roughness, 1.0e-4);
        anisotropic    := surface.specular_anisotropic;
        alpha          := microfacet_alpha(roughness, anisotropic);
        H              := normalize(V + L);
        NoV            := saturate(V.z);
        NoL            := saturate(L.z);
        NoH            := saturate(H.z);
        D              := microfacet_ggx_distribution(NoH, alpha);
        G              := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
        fr             := (surface.specular_color * D * G) / max(4 * NoL * NoV, 1.0e-6);
        return fr;
    }
    return Spectrum_Zero;
}

pdf_specular_reflect :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    if (V.z * L.z > 0.0)
    {
        specular_color := surface.specular_color;
        roughness      := max(surface.specular_roughness, 1.0e-4);
        anisotropic    := surface.specular_anisotropic;
        H              := normalize(V + L);
        VoH            := saturate(dot(V, H));
        NoH            := saturate(H.z);
        NoV            := saturate(V.z);
        alpha          := microfacet_alpha(roughness, anisotropic);
        D              := microfacet_ggx_distribution(NoH, alpha);
        G1             := microfacet_ggx_mask(NoV, alpha);
        pdf            := (D * G1) / max(4 * NoV, 1.0e-6);
        return pdf;
    }
    return 0.0;
}

sample_specular_reflect :: (V: Vector3, surface: Surface, u: Vector2, r: float) -> BxDF_Sample
{
    specular_color := surface.specular_color;
    roughness      := max(surface.specular_roughness, 1.0e-4);
    anisotropic    := surface.specular_anisotropic;
    alpha          := microfacet_alpha(roughness, anisotropic);
    H              := microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
    L              := reflect(-V, H);

    if (L.z > 0.0)
    {
        NoV            := V.z;
        NoL            := L.z;
        NoH            := H.z;
        D              := microfacet_ggx_distribution(NoH, alpha);
        G              := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
        G1             := microfacet_ggx_mask(NoV, alpha);
        // @todo: multiscatter!!!
        fr             := (specular_color * D * G) / max(4 * NoL * NoV, 1.0e-6);
        pdf            := (D * G1) / max(4 * NoV, 1.0e-6);
        return .{fr, L, pdf};
    }

    return .{};
}

sample_specular_transmit :: (V: Vector3, surface: Surface, u: Vector2, r: float) -> BxDF_Sample
{
    roughness      := max(surface.specular_roughness, 1.0e-4);
    anisotropic    := surface.specular_anisotropic;
    alpha          := microfacet_alpha(roughness, anisotropic);
    H              := microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
    L              := refract(-V, H, surface.specular_ior);

    if (L.z < 0.0)
    {
        // @todo: multiscatter!!!
        NoV        := V.z;
        NoL        := abs(L.z);
        NoH        := H.z;
        VoH        := dot(V, H);
        LoH        := -dot(L, H);
        D          := microfacet_ggx_distribution(NoH, alpha);
        G          := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
        G1         := microfacet_ggx_mask(NoV, alpha);
        dL_sqrt    := LoH + VoH / surface.specular_ior;
        dL         := dL_sqrt * dL_sqrt;
        ft         := (Spectrum_One * D * G * VoH * LoH) / max(dL * NoL * NoV, 1.0e-4);
        pdf        := D * G1 * LoH * VoH / max(dL * NoV, 1.0e-6);
        return .{ft, L, pdf};
    }

    return .{};
}

//------------------------------------------------------------------------
// Glossy

#scope_file

f_schlick_dielectric :: (mu: float, ior: float) -> float
{
    r  := (1 - ior) / (1 + ior);
    r2 := r * r;
    f  := r2 + (1.0 - r2) * power5(1.0 - mu);
    return f;
}

#scope_export

f_glossy :: (V: Vector3, L: Vector3, surface: Surface) -> Spectrum
{
    // @todo: make this equivalent to sample_glossy
    r   := f_schlick_dielectric(V.z, surface.specular_ior);
    t   := surface.transmission;
    sw  := surface.specular_weight;
    P_r := sw * r;
    P_t := t * (1.0 - P_r);
    P_d := 1.0 - P_r - P_t;

    f_r   := f_specular_reflect(V, L, surface);
    f_d   := f_diffuse(V, L, surface);
    f     := P_r * f_r + P_d * f_d;
    return f;
}

pdf_glossy :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    // @todo: make this equivalent to sample_glossy
    r   := f_schlick_dielectric(V.z, surface.specular_ior);
    t   := surface.transmission;
    sw  := surface.specular_weight;
    P_r := sw * r;
    P_t := t * (1.0 - P_r);
    P_d := 1.0 - P_r - P_t;

    pdf_r := pdf_specular_reflect(V, L, surface);
    pdf_d := pdf_diffuse(V, L, surface);
    pdf   := P_r * pdf_r + P_d * pdf_d;
    return pdf;
}

sample_glossy :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> BxDF_Sample
{
    r   := f_schlick_dielectric(V.z, surface.specular_ior);
    t   := surface.transmission;
    sw  := surface.specular_weight;
    P_r := sw * r;
    P_t := t * (1.0 - P_r);
    P_d := 1.0 - P_r - P_t;

    if (p < P_d)
    {
        sample := sample_diffuse(V, surface, u);
        fs     := f_specular_reflect(V, sample.L, surface);
        fd     := sample.fr;
        f      := P_r * fs + P_d * fd;
        pdf_s  := pdf_specular_reflect(V, sample.L, surface);
        pdf    := P_r * pdf_s + P_d * sample.pdf;
        return .{f, sample.L, pdf};
    }
    else if (p < P_d + P_r)
    {
        // @todo: energy conservation
        sample := sample_specular_reflect(V, surface, u, r);
        fd     := f_diffuse(V, sample.L, surface);
        fs     := sample.fr;
        f      := P_r * fs + P_d * fd;
        pdf_d  := pdf_diffuse(V, sample.L, surface);
        pdf    := P_r * sample.pdf + P_d * pdf_d;
        return .{f, sample.L, pdf};
    }
    else
    {
        sample := sample_specular_transmit(V, surface, u, r);
        f      := P_t * sample.fr;
        pdf    := P_t * sample.pdf;
        return .{f, sample.L, pdf};
    }
}

//------------------------------------------------------------------------
// Principled BSDF

f_principled_bsdf :: (V: Vector3, L: Vector3, surface: Surface) -> Spectrum
{
    P_m := surface.metalness;
    P_g := 1.0 - P_m;
    f_m := f_metallic(V, L, surface);
    f_g := f_glossy(V, L, surface);
    f   := P_m * f_m + P_g * f_g;
    return f;
}

pdf_principled_bsdf :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    P_m   := surface.metalness;
    P_g   := 1.0 - P_m;
    pdf_m := pdf_metallic(V, L, surface);
    pdf_g := pdf_glossy(V, L, surface);
    pdf   := P_m * pdf_m + P_g * pdf_g;
    return pdf;
}

sample_principled_bsdf :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> BxDF_Sample
{
    P_m := surface.metalness;
    P_g := 1.0 - P_m;

    if (p < P_g)
    {
        p = p / P_g;
        sample := sample_glossy(V, surface, p, u);
        fm     := f_metallic(V, sample.L, surface);
        f      := P_m * fm + P_g * sample.fr;
        pdf_m  := pdf_metallic(V, sample.L, surface);
        pdf    := P_m * pdf_m + P_g * sample.pdf;
        return .{f, sample.L, pdf};
    }
    else
    {
        sample := sample_metallic(V, surface, u);
        fg     := f_metallic(V, sample.L, surface);
        f      := P_m * sample.fr + P_g * fg;
        pdf_g  := pdf_glossy(V, sample.L, surface);
        pdf    := P_m * sample.pdf + P_g * pdf_g;
        return .{f, sample.L, pdf};
    }
}

//------------------------------------------------------------------------
// Utils

power5 :: inline (x: float) -> float
{
    x2 := x * x;
    y  := x2 * x2 * x;
    return y;
}

power6 :: inline (x: float) -> float
{
    x2 := x * x;
    x3 := x2 * x;
    x6 := x3 * x3;
    return x6;
}

#load "microfacet.jai";
#load "bxdf_lut.jai";
