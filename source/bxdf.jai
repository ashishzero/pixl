
Surface :: struct
{
    base_color           : Spectrum;
    metallic             : float;
    diffuse_roughness    : float;
    specular             : float;
    specular_ior         : float; // @todo: map ior and specular into 1 parameter
    specular_tint        : Spectrum;
    specular_roughness   : float;
    specular_anisotropic : float;
    transmission         : float;
    absorption_strength  : float;
    absorption           : Spectrum;
    emission_strength    : float;
    emission_color       : Spectrum;

    //specular        : float;
    //subsurface      : float;
    //sheen           : float;
    //sheen_tint      : float;
    //clearcoat       : float;
    //clearcoat_gloss : float;
}

BSDF_Sample :: struct
{
    L   : Vector3;
    f   : Spectrum;
    pdf : float;
}

Frensel_Spectrum :: struct
{
    f      : Spectrum;
    weight : float;
}

Frensel_BSDF_Sample :: struct
{
    L   : Vector3;
    f   : Frensel_Spectrum;
    pdf : float;
}

ROUGHNESS_THRESHOLD :: 1.0e-4;

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

f82_tint :: (mu: float, Fo: Spectrum, specular_tint: Spectrum) -> Spectrum
{
    mu82   := 1.0 / 7.0;
    f_mu   := f_schlick_metallic(Fo, mu);
    f_82   := f_schlick_metallic(Fo, mu82);
    r_mu   := mu * power6(1.0 - mu);
    r_82   := mu82 * power6(1.0 - mu82);
    f_spec := r_mu * f_82 * (Spectrum_One - specular_tint) / r_82;
    tinted := max(f_mu - f_spec, Vector3.{0, 0, 0});
    return tinted;
}

microfacet_ggx_metallic_preserve_energy :: (F_ss: Spectrum, NoV: float, alpha: Vector2) -> Spectrum
{
    roughness := sqrt(sqrt(alpha.x * alpha.y));

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

f_metallic_brdf :: (V: Vector3, L: Vector3, surface: Surface) -> Spectrum
{
    Fo             := surface.base_color;
    specular_tint  := surface.specular_tint;
    roughness      := surface.specular_roughness;
    anisotropic    := surface.specular_anisotropic;
    if (roughness >= ROUGHNESS_THRESHOLD && V.z * L.z > 0.0)
    {
        alpha     := microfacet_alpha(roughness, anisotropic);
        H         := normalize(V + L);
        NoV       := V.z;
        NoL       := L.z;
        NoH       := H.z;
        VoH       := dot(V, H);
        D         := microfacet_ggx_distribution(NoH, alpha);
        G         := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
        scale     := D * G / max(4 * NoL * NoV, 1.0e-6);
        F_ss      := f82_tint(VoH, Fo, specular_tint);
        darkening := microfacet_ggx_metallic_preserve_energy(F_ss, NoV, alpha);
        f_ss      := scale * F_ss;
        f         := darkening * f_ss;
        return f;
    }
    return Spectrum_Zero;
}

pdf_metallic_brdf :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    roughness   := surface.specular_roughness;
    anisotropic := surface.specular_anisotropic;
    if (roughness >= ROUGHNESS_THRESHOLD && V.z * L.z > 0.0)
    {
        H      := normalize(V + L);
        VoH    := dot(V, H);
        NoH    := H.z;
        NoV    := V.z;
        alpha  := microfacet_alpha(roughness, anisotropic);
        D      := microfacet_ggx_distribution(NoH, alpha);
        G1     := microfacet_ggx_mask(NoV, alpha); 
        pdf    := (D * G1) / max(4 * NoV, 1.0e-6);
        return pdf;
    }
    return 0.0;
}

sample_metallic_brdf :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> BSDF_Sample
{
    Fo             := surface.base_color;
    specular_tint  := surface.specular_tint;
    roughness      := surface.specular_roughness;
    anisotropic    := surface.specular_anisotropic;

    if (roughness >= ROUGHNESS_THRESHOLD)
    {
        alpha     := microfacet_alpha(roughness, anisotropic);
        H         := microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
        L         := reflect(-V, H);

        if (L.z > 0.0)
        {
            NoV       := V.z;
            NoL       := L.z;
            NoH       := H.z;
            VoH       := dot(V, H);
            D         := microfacet_ggx_distribution(NoH, alpha);
            G         := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
            G1        := microfacet_ggx_mask(NoV, alpha);
            scale     := (D * G) / max(4 * NoL * NoV, 1.0e-6);
            F_ss      := f82_tint(VoH, Fo, specular_tint);
            darkening := microfacet_ggx_metallic_preserve_energy(F_ss, NoV, alpha);
            f_ss      := scale * F_ss;
            f         := darkening * f_ss;
            pdf       := (D * G1) / max(4 * NoV, 1.0e-6);
            return .{L, f, pdf};
        }

        return .{};
    }
    else
    {
        L   := Vector3.{-V.x, -V.y, V.z};
        pdf := 1.0;
        mu  := L.z;
        f   := f82_tint(mu, Fo, specular_tint) / max(mu, 1.0e-6);
        return .{L, f, pdf};
    }
}

//------------------------------------------------------------------------

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

f_diffuse_brdf :: (V: Vector3, L: Vector3, surface: Surface) -> Spectrum
{
    if (L.z > 0.0)
    {
        color     := surface.base_color;
        roughness := surface.diffuse_roughness;
        NoV       := V.z;
        NoL       := L.z;
        VoL       := dot(V, L);
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
    return Spectrum_Zero;
}

pdf_diffuse_brdf :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    if (L.z > 0.0)
    {
        roughness := surface.diffuse_roughness;
        NoV       := V.z;
        P_u       := pow(roughness, 0.1) * (0.162925 + NoV * (-0.372058 + (0.538233 - 0.290822 * NoV) * NoV));
        P_c       := 1.0 - P_u;
        pdf_c     := pdf_cltc(V, L, roughness);
        pdf_u     := 1.0 / (2.0 * PI);
        return P_u * pdf_u + P_c * pdf_c;
    }
    return 0.0;
}

sample_diffuse_brdf :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> BSDF_Sample
{
    roughness := surface.diffuse_roughness;

    NoV       := V.z;
    P_u       := pow(roughness, 0.1) * (0.162925 + NoV * (-0.372058 + (0.538233 - 0.290822 * NoV) * NoV));
    P_c       := 1.0 - P_u; // probability of CLTC sample

    L         : Vector3 = ---;
    pdf_c     : float   = ---;

    u1        := u.x;
    u2        := u.y;

    if (p < P_u)
    {
        L     = sample_uniform_lobe(u1, u2); // sample L from uniform lobe
        pdf_c = pdf_cltc(V, L, roughness); // evaluate CLTC PDF at L
    }
    else
    {
        L, pdf_c = sample_cltc(V, roughness, u1, u2); // sample L from CLTC lobe
    }

    f     := f_diffuse_brdf(V, L, surface);
    pdf_u := 1.0 / (2.0 * PI);
    pdf   := P_u * pdf_u + P_c * pdf_c; // MIS PDF of L
    return .{L, f, pdf};
}

//------------------------------------------------------------------------
// Dielectric

#scope_file

effective_frensel_dielectric :: inline (ior: float, cos_i: float) -> float
{
    assert(cos_i >= 0.0);

    sin2_i := 1.0 - cos_i * cos_i;
    sin2_t := ior * ior * sin2_i;
    if (sin2_t > 1.0)
    {
        return 1.0;
    }
    cos_t := sqrt(1 - saturate(sin2_t));

    Rs := (ior * cos_i - cos_t) / (ior * cos_i + cos_t);
    Rp := (ior * cos_t - cos_i) / (ior * cos_t + cos_i);
    R  := (Rs * Rs + Rp * Rp) * 0.5;
    return R;
}

schlick_frensel_dielectric :: inline (ior: float, cos_i: float) -> float
{
    R0 := (ior - 1.0) / (ior + 1.0);
    R0 *= R0;

    sin_t := ior * ior * (1.0 - cos_i * cos_i);
    if (sin_t > 1.0)
    {
        return 1.0;
    }
    cos_t := sqrt(1.0 - sin_t);

    x := 1.0 - cos_t;
    R := R0 + (1.0 - R0) * power5(x);
    return R;
}

refracted_normal :: inline (V: Vector3, L: Vector3, ior: float) -> Vector3
{
    H := normalize(V + ior * L);
    if (H.z < 0.0)
    {
        H = -H;
    }
    return H;
}

//------------------------------------------------------------------------
// Translucent BSDF

#scope_export

f_translucent_bsdf :: (V: Vector3, L: Vector3, surface: Surface) -> Spectrum
{
    specular_tint := surface.specular_tint;
    ior           := surface.specular_ior;
    roughness     := surface.specular_roughness;
    anisotropic   := surface.specular_anisotropic;

    if (ior == 1.0 || roughness < ROUGHNESS_THRESHOLD)
    {
        return Spectrum_Zero;
    }
    else
    {
        NoV     := V.z;
        NoL     := L.z;
        alpha   := microfacet_alpha(roughness, anisotropic);

        if (NoV == 0.0 && NoL == 0.0)
        {
            return Spectrum_Zero;
        }

        if (NoL > 0.0)
        {
            H     := normalize(V + L);
            R     := effective_frensel_dielectric(ior, V.z);
            NoH   := H.z;
            D     := microfacet_ggx_distribution(NoH, alpha);
            G     := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
            scale := (R * D * G) / max(4 * NoL * NoV, 1.0e-6);
            f_ss  := scale * specular_tint; // @todo: multiscatter!!!
            f     := f_ss;
            return f;
        }
        else
        {
            H                 := refracted_normal(V, L, ior);
            R                 := effective_frensel_dielectric(ior, V.z);
            transmission_tint := Spectrum_One - R * specular_tint;
            NoH               := H.z;
            VoH               := dot(V, H);
            LoH               := -dot(L, H);
            D                 := microfacet_ggx_distribution(NoH, alpha);
            G                 := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
            dL_sqrt           := LoH + VoH / ior;
            dL                := dL_sqrt * dL_sqrt;
            VoLoH             := VoH * LoH;
            scale             := (D * G * VoLoH) / max(dL * NoL * NoV, 1.0e-6);
            f_ss              := scale * transmission_tint;
            f                 := f_ss;
            return f;
        }
    }
}

pdf_translucent_bsdf :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    specular_tint := surface.specular_tint;
    ior           := surface.specular_ior;
    roughness     := surface.specular_roughness;
    anisotropic   := surface.specular_anisotropic;

    if (ior == 1.0 || roughness < ROUGHNESS_THRESHOLD)
    {
        return 0.0;
    }
    else
    {
        NoV     := V.z;
        NoL     := L.z;
        alpha   := microfacet_alpha(roughness, anisotropic);

        if (NoV == 0.0 && NoL == 0.0)
        {
            return 0.0;
        }

        if (NoL > 0.0)
        {
            H   := normalize(V + L);
            R   := effective_frensel_dielectric(ior, V.z);
            P_r := R;
            NoH := H.z;
            D   := microfacet_ggx_distribution(NoH, alpha);
            G1  := microfacet_ggx_mask(NoV, alpha);
            pdf := (P_r * D * G1) / max(4 * NoV, 1.0e-6);
            return pdf;
        }
        else
        {
            H       := refracted_normal(V, L, ior);
            R       := effective_frensel_dielectric(ior, V.z);
            P_t     := 1.0 - R;
            NoH     := H.z;
            VoH     := dot(V, H);
            LoH     := -dot(L, H);
            D       := microfacet_ggx_distribution(NoH, alpha);
            G1      := microfacet_ggx_mask(NoV, alpha);
            VoLoH   := VoH * LoH;
            dL_sqrt := LoH + VoH / ior;
            dL      := dL_sqrt * dL_sqrt;
            pdf     := (P_t * D * G1 * VoLoH) / max(dL * NoV, 1.0e-6);
            return pdf;
        }
    }
}

sample_translucent_bsdf :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> BSDF_Sample
{
    specular_tint := surface.specular_tint;
    ior           := surface.specular_ior;
    roughness     := surface.specular_roughness;
    anisotropic   := surface.specular_anisotropic;

    if (ior == 1.0)
    {
        f := Spectrum_One / max(V.z, 1.0e-6);
        return .{-V, f, 1.0};
    }

    if (roughness < ROUGHNESS_THRESHOLD)
    {
        R   := effective_frensel_dielectric(ior, V.z);
        P_r := R;
        P_t := 1.0 - R;

        if (p < P_r)
        {
            L   := Vector3.{-V.x, -V.y, V.z};
            pdf := P_r;
            f   := (R / max(L.z, 1.0e-6)) * specular_tint;
            return .{L, f, pdf};
        }
        else
        {
            transmission_tint := Spectrum_One - R * specular_tint;

            L, refracted := refract(-V, .{0, 0, 1}, ior);
            if (refracted)
            {
                f   := (transmission_tint / max(-L.z, 1.0e-6));
                pdf := P_t;
                return .{L, f, pdf};
            }
            return .{};
        }
    }
    else
    {
        alpha       := microfacet_alpha(roughness, anisotropic);
        H           := microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
        R           := effective_frensel_dielectric(ior, dot(V, H));
        P_r         := R;
        P_t         := 1.0 - R;

        if (p < P_r)
        {
            L := reflect(-V, H);
            if (L.z > 0.0)
            {
                NoV            := V.z;
                NoL            := L.z;
                NoH            := H.z;
                D              := microfacet_ggx_distribution(NoH, alpha);
                G              := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
                G1             := microfacet_ggx_mask(NoV, alpha);
                scale          := (R * D * G) / max(4 * NoL * NoV, 1.0e-6);
                f_ss           := scale * specular_tint; // @todo: multiscatter!!!
                f              := f_ss;
                pdf            := (P_r * D * G1) / max(4 * NoV, 1.0e-6);
                return .{L, f, pdf};
            }
        }
        else
        {
            transmission_tint := Spectrum_One - R * specular_tint;

            L, refracted := refract(-V, H, surface.specular_ior);
            if (refracted)
            {
                NoV        := V.z;
                NoL        := abs(L.z);
                NoH        := H.z;
                VoH        := dot(V, H);
                LoH        := -dot(L, H);
                D          := microfacet_ggx_distribution(NoH, alpha);
                G          := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
                G1         := microfacet_ggx_mask(NoV, alpha);
                dL_sqrt    := LoH + VoH / ior;
                dL         := dL_sqrt * dL_sqrt;
                // @todo: multiscatter!!!
                VoLoH      := VoH * LoH;
                scale      := (D * G * VoLoH) / max(dL * NoL * NoV, 1.0e-6);
                f_ss       := scale * transmission_tint;
                f          := f_ss;
                pdf        := (P_t * D * G1 * VoLoH) / max(dL * NoV, 1.0e-6);
                return .{L, f, pdf};
            }
        }
        return .{};
    }
}

//------------------------------------------------------------------------
// Opaque

#scope_file

f_specular_brdf :: inline (V: Vector3, L: Vector3, H: Vector3, alpha: Vector2, specular_tint: Spectrum) -> Spectrum
{
    if (V.z * L.z > 0.0)
    {
        NoV           := V.z;
        NoL           := L.z;
        NoH           := H.z;
        D             := microfacet_ggx_distribution(NoH, alpha);
        G             := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
        scale         := (D * G) / max(4 * NoL * NoV, 1.0e-6);
        f_ss          := scale * specular_tint;
        f             := f_ss; // @todo: multiscatter!!!
        return f;
    }
    return Spectrum_Zero;
}

pdf_specular_brdf :: inline (V: Vector3, L: Vector3, H: Vector3, alpha: Vector2) -> float
{
    if (V.z * L.z > 0.0)
    {
        NoH            := H.z;
        NoV            := V.z;
        D              := microfacet_ggx_distribution(NoH, alpha);
        G1             := microfacet_ggx_mask(NoV, alpha);
        pdf            := (D * G1) / max(4 * NoV, 1.0e-6);
        return pdf;
    }
    return 0.0;
}

f_pdf_specular_brdf :: (V: Vector3, L: Vector3, H: Vector3, alpha: Vector2, specular_tint: Spectrum) -> Spectrum, float
{
    assert(V.z * L.z > 0.0);
    NoV   := V.z;
    NoL   := L.z;
    NoH   := H.z;
    D     := microfacet_ggx_distribution(NoH, alpha);
    G     := microfacet_ggx_mask_shadow(NoV, NoL, alpha);
    G1    := microfacet_ggx_mask(NoV, alpha);
    scale := (D * G) / max(4 * NoL * NoV, 1.0e-6);
    f_ss  := scale * specular_tint;
    f     := f_ss; // @todo: multiscatter!!!
    pdf   := (D * G1) / max(4 * NoV, 1.0e-6);
    return f, pdf;
}

#scope_export

f_glossy_brdf :: (V: Vector3, L: Vector3, surface: Surface) -> Spectrum
{
    if (V.z * L.z > 0.0)
    {
        H             := refracted_normal(V, L, surface.specular_ior);
        F             := schlick_frensel_dielectric(surface.specular_ior, dot(V, H));
        P_s           := F * surface.specular;

        specular_tint := surface.specular_tint;
        roughness     := max(ROUGHNESS_THRESHOLD, surface.specular_roughness);
        anisotropic   := surface.specular_anisotropic;
        alpha         := microfacet_alpha(roughness, anisotropic);
        f_s           := f_specular_brdf(V, L, H, alpha, specular_tint);
        f_d           := f_diffuse_brdf(V, L, surface);
        r             := P_s * specular_tint;
        f             := P_s * f_s + (Spectrum_One - r) * f_d;
        return f;
    }
    return Spectrum_Zero;
}

pdf_glossy_brdf :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    if (V.z * L.z > 0.0)
    {
        H             := refracted_normal(V, L, surface.specular_ior);
        F             := schlick_frensel_dielectric(surface.specular_ior, dot(V, H));
        P_s           := F * surface.specular;
        P_d           := 1.0 - P_s;

        specular_tint := surface.specular_tint;
        roughness     := max(ROUGHNESS_THRESHOLD, surface.specular_roughness);
        anisotropic   := surface.specular_anisotropic;
        alpha         := microfacet_alpha(roughness, anisotropic);
        pdf_s         := pdf_specular_brdf(V, L, H, alpha);
        pdf_d         := pdf_diffuse_brdf(V, L, surface);
        pdf           := P_s * pdf_s + P_d * pdf_d;
        return pdf;
    }
    return 0.0;
}

sample_glossy_brdf :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> BSDF_Sample
{
    specular_tint := surface.specular_tint;
    roughness     := max(ROUGHNESS_THRESHOLD, surface.specular_roughness);
    anisotropic   := surface.specular_anisotropic;
    alpha         := microfacet_alpha(roughness, anisotropic);
    H             := microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
    F             := schlick_frensel_dielectric(surface.specular_ior, dot(V, H));

    P_s           := F * surface.specular;
    P_d           := 1.0 - P_s;

    L   : Vector3 = ---;
    f_s, f_d : Spectrum = Spectrum_Zero;
    pdf_s, pdf_d: float;

    if (p < P_s)
    {
        L = reflect(-V, H);
        if (V.z * L.z > 0.0)
        {
            f_s, pdf_s = f_pdf_specular_brdf(V, L, H, alpha, specular_tint);
            f_d        = f_diffuse_brdf(V, L, surface);
            pdf_d      = pdf_diffuse_brdf(V, L, surface);
        }
    }
    else
    {
        p       = (p - P_s) / P_d;
        sample := sample_diffuse_brdf(V, surface, p, u);
        L       = sample.L;
        H      := refracted_normal(V, L, surface.specular_ior);
        f_s     = f_specular_brdf(V, L, H, alpha, specular_tint);
        f_d     = sample.f;
        pdf_s   = pdf_specular_brdf(V, L, H, alpha);
        pdf_d   = sample.pdf;
    }

    r   := P_s * specular_tint;
    f   := P_s * f_s + (Spectrum_One - r) * f_d;
    pdf := P_s * pdf_s + P_d * pdf_d;
    return .{L, f, pdf};
}

//------------------------------------------------------------------------
// Opaque Base

f_opaque_base_brdf      :: f_glossy_brdf;
pdf_opaque_base_brdf    :: pdf_glossy_brdf;
sample_opaque_base_brdf :: sample_glossy_brdf;

//------------------------------------------------------------------------
// Dielectric Base

f_dielectric_base_bsdf :: (V: Vector3, L: Vector3, surface: Surface) -> Spectrum
{
    P_t := surface.transmission;
    P_o := 1.0 - P_t;
    f_t := f_translucent_bsdf(V, L, surface);
    f_o := f_opaque_base_brdf(V, L, surface);
    f   := P_t * f_t + P_o * f_o;
    return f;
}

pdf_dielectric_base_bsdf :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    P_t   := surface.transmission;
    P_o   := 1.0 - P_t;
    pdf_t := pdf_translucent_bsdf(V, L, surface);
    pdf_o := pdf_opaque_base_brdf(V, L, surface);
    pdf   := P_t * pdf_t + P_o * pdf_o;
    return pdf;
}

sample_dielectric_base_bsdf :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> BSDF_Sample
{
    P_t := surface.transmission;
    P_o := 1.0 - P_t;

    L : Vector3 = ---;
    f_t, f_o: Spectrum = ---;
    pdf_t, pdf_o: float = ---;

    if (p < P_o)
    {
        p       = p / P_o;
        sample := sample_opaque_base_brdf(V, surface, p, u);
        L       = sample.L;
        f_t     = f_translucent_bsdf(V, L, surface);
        f_o     = sample.f;
        pdf_t   = pdf_translucent_bsdf(V, L, surface);
        pdf_o   = sample.pdf;
    }
    else
    {
        p       = (p - P_o) / P_t;
        sample := sample_translucent_bsdf(V, surface, p, u);
        L       = sample.L;
        f_t     = sample.f;
        f_o     = f_opaque_base_brdf(V, L, surface);
        pdf_t   = sample.pdf;
        pdf_o   = pdf_opaque_base_brdf(V, L, surface);
    }

    f   := P_t * f_t + P_o * f_o;
    pdf := P_t * pdf_t + P_o * pdf_o;
    return .{L, f, pdf};
}

//------------------------------------------------------------------------
// Principled BSDF

f_principled_bsdf :: (V: Vector3, L: Vector3, surface: Surface) -> Spectrum
{
    P_m := surface.metallic;
    P_d := 1.0 - P_m;
    f_m := f_metallic_brdf(V, L, surface);
    f_d := f_dielectric_base_bsdf(V, L, surface);
    f   := P_m * f_m + P_d * f_d;
    return f;
}

pdf_principled_bsdf :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    P_m   := surface.metallic;
    P_d   := 1.0 - P_m;
    pdf_m := pdf_metallic_brdf(V, L, surface);
    pdf_d := pdf_dielectric_base_bsdf(V, L, surface);
    pdf   := P_m * pdf_m + P_d * pdf_d;
    return pdf;
}

sample_principled_bsdf :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> BSDF_Sample
{
    P_m := surface.metallic;
    P_d := 1.0 - P_m;

    L : Vector3 = ---;
    f_m, f_d: Spectrum = ---;
    pdf_m, pdf_d: float = ---;

    if (p < P_d)
    {
        // non-metals
        p       = p / P_d;
        sample := sample_dielectric_base_bsdf(V, surface, p, u);
        L       = sample.L;
        f_m     = f_metallic_brdf(V, L, surface);
        f_d     = sample.f;
        pdf_m   = pdf_metallic_brdf(V, L, surface);
        pdf_d   = sample.pdf;
    }
    else
    {
        // metallic
        p       = (p - P_d) / P_m;
        sample := sample_metallic_brdf(V, surface, p, u);
        L       = sample.L;
        f_m     = sample.f;
        f_d     = f_dielectric_base_bsdf(V, L, surface);
        pdf_m   = sample.pdf;
        pdf_d   = pdf_dielectric_base_bsdf(V, L, surface);
    }

    f   := P_m * f_m + P_d * f_d;
    pdf := P_m * pdf_m + P_d * pdf_d;
    return .{L, f, pdf};
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
