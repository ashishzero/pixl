
Lobe_Index :: enum
{
    DIFFUSE;
    CONDUCTOR;
    DIELECTRIC;
    TRANSPARENT;
}

MAX_LOBE_INDEX :: #run type_info(Lobe_Index).values.count;

Fresnel :: struct
{
    F0   : Spectrum;
    F90  : Spectrum;
}

Surface :: struct
{
    color            : Spectrum;
    roughness        : float;
    ior              : float;
    specular         : float;
    metallic         : float;
    fresnel          : Fresnel;
    microfacet_alpha : Vector2;
    transmission     : float;
    alpha            : float;
    absorption       : Spectrum;
    emission         : Spectrum;
}

Lobe_Weights :: [MAX_LOBE_INDEX]float;

Surface_Interaction :: struct
{
    using bxdf : BxDF;
    L          : Vector3;
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
    r         := sqrt(sqrt(alpha.x * alpha.y));
    E_avg     := E_avg_metallic(r);
    E_ms      := E_metallic(r, NoV);
    darkening := microfacet_ggx_metallic_preserve_energy_factor(F_ss, E_avg, E_ms);
    return darkening;
}

#scope_export

f_f82_conductor_brdf :: (V: Vector3, L: Vector3, surface: Surface) -> BxDF
{
    alpha := surface.microfacet_alpha;
    if (is_rough(alpha) && V.z * L.z > 0.0)
    {
        H         := normalize(V + L);
        NoV       := V.z;
        VoH       := dot(V, H);
        brdf      := f_specular_brdf(V, L, H, alpha);
        F_ss      := f82_tint(VoH, surface.fresnel.F0, surface.fresnel.F90);
        darkening := microfacet_ggx_metallic_preserve_energy(F_ss, NoV, alpha);
        brdf.f    *= darkening * F_ss;
        return brdf;
    }
    return .{};
}

pdf_f82_conductor_brdf :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    alpha := surface.microfacet_alpha;
    if (is_rough(alpha) && V.z * L.z > 0.0)
    {
        H   := normalize(V + L);
        pdf := pdf_specular_brdf(V, L, H, alpha);
        return pdf;
    }
    return 0.0;
}

sample_f82_conductor_brdf :: (V: Vector3, surface: Surface, u: Vector3) -> Surface_Interaction
{
    alpha := surface.microfacet_alpha;
    if (is_rough(alpha))
    {
        H := microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
        L := reflect(-V, H);
        if (L.z > 0.0)
        {
            NoV       := V.z;
            VoH       := dot(V, H);
            brdf      := f_specular_brdf(V, L, H, alpha);
            F_ss      := f82_tint(VoH, surface.fresnel.F0, surface.fresnel.F90);
            darkening := microfacet_ggx_metallic_preserve_energy(F_ss, NoV, alpha);
            brdf.f    *= darkening * F_ss;
            return .{brdf, L};
        }
        return .{};
    }
    else
    {
        L := Vector3.{-V.x, -V.y, V.z};
        pdf := 1.0;
        mu  := L.z;
        f   := f82_tint(mu, surface.fresnel.F0, surface.fresnel.F90) / max(mu, 1.0e-6);
        return .{.{f, pdf}, L};
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
    from_LTC   := ltc_orthonormal_basis(V);           // L -> local space
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

f_diffuse_eon_eval_brdf :: (V: Vector3, L: Vector3, surface: Surface) -> Spectrum
{
    if (L.z > 0.0)
    {
        color     := surface.color;
        roughness := surface.roughness;
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
        f         := f_ss + f_ms;
        return f;
    }
    return Spectrum_Zero;
}

#scope_export

f_diffuse_eon_brdf :: (V: Vector3, L: Vector3, surface: Surface) -> BxDF
{
    if (L.z > 0.0)
    {
        NoV   := V.z;
        f     := f_diffuse_eon_eval_brdf(V, L, surface);
        P_u   := pow(surface.roughness, 0.1) * (0.162925 + NoV * (-0.372058 + (0.538233 - 0.290822 * NoV) * NoV));
        P_c   := 1.0 - P_u;
        pdf_c := pdf_cltc(V, L, surface.roughness);
        pdf_u := 1.0 / (2.0 * PI);
        pdf   := P_u * pdf_u + P_c * pdf_c;
        return .{f, pdf};
    }
    return .{};
}

pdf_diffuse_eon_brdf :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    if (L.z > 0.0)
    {
        roughness := surface.roughness;
        NoV       := V.z;
        P_u       := pow(roughness, 0.1) * (0.162925 + NoV * (-0.372058 + (0.538233 - 0.290822 * NoV) * NoV));
        P_c       := 1.0 - P_u;
        pdf_c     := pdf_cltc(V, L, roughness);
        pdf_u     := 1.0 / (2.0 * PI);
        return P_u * pdf_u + P_c * pdf_c;
    }
    return 0.0;
}

sample_diffuse_eon_brdf :: (V: Vector3, surface: Surface, u: Vector3) -> Surface_Interaction
{
    NoV       := V.z;
    P_u       := pow(surface.roughness, 0.1) * (0.162925 + NoV * (-0.372058 + (0.538233 - 0.290822 * NoV) * NoV));
    P_c       := 1.0 - P_u; // probability of CLTC sample

    L         : Vector3 = ---;
    pdf_c     : float   = ---;

    u1        := u.x;
    u2        := u.y;

    if (u.z < P_u)
    {
        L     = sample_uniform_lobe(u1, u2); // sample L from uniform lobe
        pdf_c = pdf_cltc(V, L, surface.roughness); // evaluate CLTC PDF at L
    }
    else
    {
        L, pdf_c = sample_cltc(V, surface.roughness, u1, u2); // sample L from CLTC lobe
    }

    f     := f_diffuse_eon_eval_brdf(V, L, surface);
    pdf_u := 1.0 / (2.0 * PI);
    pdf   := P_u * pdf_u + P_c * pdf_c; // MIS PDF of L
    return .{.{f, pdf}, L};
}

//------------------------------------------------------------------------
// Dielectric

#scope_file

refracted_normal :: inline (V: Vector3, L: Vector3, ior: float) -> Vector3
{
    H := normalize(V + ior * L);
    if (H.z < 0.0)
    {
        H = -H;
    }
    return H;
}

effective_fresnel_weight :: (surface: Surface, V: Vector3, H: Vector3) -> float
{
    fresnel := effective_fresnel_dielectric(surface.ior, dot(V, H));
    weight  := fresnel * surface.transmission + 1.0 - surface.transmission;
    return weight;
}

#scope_export

f_dielectric_bsdf :: (V: Vector3, L: Vector3, surface: Surface) -> BxDF
{
    if (L.z > 0.0)
    {
        H    := normalize(V + L);
        R    := effective_fresnel_weight(surface, V, H);
        brdf := f_specular_brdf(V, L, H, surface.microfacet_alpha);
        NoV  := abs(V.z);
        f    := R * surface.fresnel.F90 * brdf.f;
        pdf  := R * brdf.pdf;
        return .{f, pdf};
    }
    else if (L.z < 0.0)
    {
        H    := refracted_normal(V, L, surface.ior);
        R    := effective_fresnel_weight(surface, V, H);
        btdf := f_specular_btdf(V, L, H, surface.ior, surface.microfacet_alpha);
        f    := (Spectrum_One - R * surface.fresnel.F90) * btdf.f;
        pdf  := (1.0 - R) * btdf.pdf;
        return .{f, pdf};
    }
    return .{};
}

pdf_dielectric_bsdf :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    if (L.z < 0.0)
    {
        H   := refracted_normal(V, L, surface.ior);
        R   := effective_fresnel_weight(surface, V, H);
        pdf := pdf_specular_btdf(V, L, H, surface.ior, surface.microfacet_alpha);
        return (1.0 - R) * pdf;
    }
    else if (L.z > 0.0)
    {
        H   := normalize(V + L);
        R   := effective_fresnel_weight(surface, V, H);
        pdf := pdf_specular_brdf(V, L, H, surface.microfacet_alpha);
        return R * pdf;
    }
    return 0.0;
}

sample_dielectric_bsdf :: (V: Vector3, surface: Surface, u: Vector3) -> Surface_Interaction
{
    H := microfacet_ggx_sample_normal(V, surface.microfacet_alpha, u.x, u.y);
    R := effective_fresnel_weight(surface, V, H);

    if (u.z >= R)
    {
        L, refracted := refract(-V, H, surface.ior);
        if (refracted)
        {
            btdf := f_specular_btdf(V, L, H, surface.ior, surface.microfacet_alpha);
            f    := (Spectrum_One - R * surface.fresnel.F90) * btdf.f;
            pdf  := (1.0 - R) * btdf.pdf;
            return .{.{f, pdf}, L};
        }
        else
        {
            R = 1.0;
        }
    }

    L := reflect(-V, H);
    if (L.z > 0.0)
    {
        brdf := f_specular_brdf(V, L, H, surface.microfacet_alpha);
        f    := R * surface.fresnel.F90 * brdf.f;
        pdf  := R * brdf.pdf;
        return .{.{f, pdf}, L};
    }

    return .{};
}

//------------------------------------------------------------------------
// Transparent

#scope_export

f_transparent_btdf :: (V: Vector3, L: Vector3, surface: Surface) -> BxDF
{
    return .{};
}

pdf_transparent_btdf :: (V: Vector3, L: Vector3, surface: Surface) -> float
{
    return 0.0;
}

sample_transparent_btdf :: (V: Vector3, surface: Surface, u: Vector3) -> Surface_Interaction
{
    L   := -V;
    mu  := abs(L.z);
    f   := Spectrum_One / max(mu, 1.0e-6);
    pdf := 1.0;
    return .{.{f, pdf}, L};
}

//------------------------------------------------------------------------
// BSDF

#scope_file

pick_lobe :: (p: float, weights: Lobe_Weights) -> Lobe_Index
{
    sum_p := 0.0;
    for 0..MAX_LOBE_INDEX-1
    {
        sum_p += weights[it];
        if (p < sum_p)
        {
            return it.(Lobe_Index);
        }
    }
    return .DIFFUSE;
}

calculate_lobe_weights :: (using surface: Surface) -> Lobe_Weights
{
    a   := clamp(alpha, 0.0, 1.0);
    m   := clamp(metallic, 0.0, 1.0);
    s   := clamp(specular, 0.0, 1.0);
    t   := clamp(transmission, 0.0, 1.0);
    nm  := a * (1.0 - m);

    weights: Lobe_Weights;
    weights[Lobe_Index.TRANSPARENT] = (1.0 - a);
    weights[Lobe_Index.CONDUCTOR]   = a * m;
    weights[Lobe_Index.DIFFUSE]     = nm * (1.0 - s);
    weights[Lobe_Index.DIELECTRIC]  = nm * s;

    return weights;
}

#scope_export

f_surface_bxdf_lobe :: (V: Vector3, L: Vector3, surface: Surface, index: Lobe_Index) -> BxDF
{
    if #complete index ==
    {
        case .DIFFUSE;
            return f_diffuse_eon_brdf(V, L, surface);
        case .CONDUCTOR;
            return f_f82_conductor_brdf(V, L, surface);
        case .DIELECTRIC;
            return f_dielectric_bsdf(V, L, surface);
        case .TRANSPARENT;
            return f_transparent_btdf(V, L, surface);
    }
}

pdf_surface_bxdf_lobe :: (V: Vector3, L: Vector3, surface: Surface, index: Lobe_Index) -> float
{
    if #complete index ==
    {
        case .DIFFUSE;
            return pdf_diffuse_eon_brdf(V, L, surface);
        case .CONDUCTOR;
            return pdf_f82_conductor_brdf(V, L, surface);
        case .DIELECTRIC;
            return pdf_dielectric_bsdf(V, L, surface);
        case .TRANSPARENT;
            return pdf_transparent_btdf(V, L, surface);
    }
}

sample_surface_bxdf_lobe :: (V: Vector3, surface: Surface, u: Vector3, index: Lobe_Index) -> Surface_Interaction
{
    if #complete index ==
    {
        case .DIFFUSE;
            return sample_diffuse_eon_brdf(V, surface, u);
        case .CONDUCTOR;
            return sample_f82_conductor_brdf(V, surface, u);
        case .DIELECTRIC;
            return sample_dielectric_bsdf(V, surface, u);
        case .TRANSPARENT;
            return sample_transparent_btdf(V, surface, u);
    }
}

f_surface_bsdf :: (V: Vector3, L: Vector3, surface: Surface) -> BxDF
{
    weights := calculate_lobe_weights(surface);
    bsdf    : BxDF;
    for 0..MAX_LOBE_INDEX-1
    {
        index    := it.(Lobe_Index);
        bxdf     := f_surface_bxdf_lobe(V, L, surface, index);
        bsdf.f   += weights[it] * bxdf.f;
        bsdf.pdf += weights[it] * bxdf.pdf;
    }
    return bsdf;
}

pdf_surface_bsdf :: (V: Vector3, L: Vector3, surface: Surface, weights: Lobe_Weights) -> float
{
    pdf: float;
    for 0..MAX_LOBE_INDEX-1
    {
        index    := it.(Lobe_Index);
        lobe_pdf := pdf_surface_bxdf_lobe(V, L, surface, index);
        pdf      += weights[it] * lobe_pdf;
    }
    return pdf;
}

sample_surface_bsdf :: (V: Vector3, surface: Surface, p: float, u: Vector3) -> Surface_Interaction
{
    weights := calculate_lobe_weights(surface);
    picked  := pick_lobe(p, weights);
    si      := sample_surface_bxdf_lobe(V, surface, u, picked);

    if (si.bxdf.pdf == 0.0)
    {
        return .{};
    }

    L := si.L;

    bsdf : BxDF;
    for 0..MAX_LOBE_INDEX-1
    {
        index := it.(Lobe_Index);
        if (index != picked)
        {
            bxdf     := f_surface_bxdf_lobe(V, L, surface, index);
            bsdf.f   += weights[index] * bxdf.f;
            bsdf.pdf += weights[index] * bxdf.pdf;
        }
    }

    bsdf.f   += weights[picked] * si.bxdf.f;
    bsdf.pdf += weights[picked] * si.bxdf.pdf;

    return .{bsdf, L};
}

//------------------------------------------------------------------------
// Utils

#scope_file

E_avg_metallic :: (roughness: float) -> float
{
    E_avg := read_lookup_table_1D(metallic_E_avg, METALLIC_E_AVG_X_DIM, roughness);
    return E_avg;
}

E_metallic :: (roughness: float, NoV: float) -> float
{
    E := read_lookup_table_2D(metallic_E, METALLIC_E_X_DIM, METALLIC_E_Y_DIM, roughness, NoV);
    return E;
}

microfacet_ggx_metallic_preserve_energy_factor :: (F_ss: Spectrum, E_avg: float, E_ms: float) -> Spectrum
{
    // Fresnel term is based on the following blog:
    // https://blog.selfshadow.com/2018/06/04/multi-faceted-part-2/
    F_ms  := F_ss * E_avg / (Spectrum_One - F_ss * (1.0 - E_avg));

    // Energy preservation is based on the "Practical multiple scattering compensation for microfacet models" by Emmanuel Turquin
    // Reference: https://blog.selfshadow.com/publications/turquin/ms_comp_final.pdf
    k_ms := (1.0 - E_ms) / max(E_ms, 1.0e-6);
    darkening := Spectrum_One + F_ms * k_ms;
    return darkening;
}

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
#load "bxdf_shared.jai";
#load "bxdf_gen_tables.jai";
