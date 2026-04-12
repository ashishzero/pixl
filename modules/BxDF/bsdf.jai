#scope_export

Spectrum :: #type,isa Vector3;

Spectrum_One  :: Spectrum.{1, 1, 1};
Spectrum_Zero :: Spectrum.{0, 0, 0};

Fresnel :: struct
{
    reflectivity : Spectrum;
    edge_tint    : Spectrum;
}

Surface_Flags :: enum u32
{
    PRESERVE_MULTI_SCATTER_ENERGY :: 0x1;
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
    opacity          : float;
    absorption       : Spectrum;
    emission         : Spectrum;
    flags            : Surface_Flags;
}

BSDF_Flags :: enum_flags
{
    DIFFUSE                  :: 0x1;
    CONDUCTOR                :: 0x2; // TODO: Combine CONDUCTOR AND DIELECTRIC to SPECULAR
    DIELECTRIC_REFLECTION    :: 0x4;
    DIELECTRIC_REFRACTION    :: 0x8;
    TRANSMISSION             :: 0x10;
}

BSDF :: struct
{
    f     : Spectrum;
    pdf   : float;
    flags : BSDF_Flags; // TODO: Handle this properly in principled BSDF
}

Sampled_BSDF :: struct
{
    using bsdf : BSDF;
    L          : Vector3;
}

//------------------------------------------------------------------------
// Sampling

#scope_export

sample_uniform :: (u1: float, u2: float) -> Vector3
{
    sintheta := sqrt(1.0 - u1 * u1);
    phi      := 2.0 * PI * u2;
    L : Vector3 = ---;
    L.x = sintheta * cos(phi);
    L.y = sintheta * sin(phi);
    L.z = u1;
    return L;
}

pdf_uniform :: () -> float
{
    return 1.0 / (2.0 * PI);
}

sample_cosine :: (u1: float, u2: float) -> Vector3
{
    ct  := sqrt(u1);
    st  := sqrt(1.0 - u1);
    phi := 2.0 * PI * u2;
    x   := st * cos(phi);
    y   := st * sin(phi);
    z   := ct;
    return .{x, y, z};
}

pdf_cosine :: (L: Vector3) -> float
{
    return L.z * INV_PI;
}

//------------------------------------------------------------------------
// Diffuse EON BxDF

// EON: A practical energy-preserving rough diffuse BRDF
// https://arxiv.org/pdf/2410.18026

#scope_export

evaluate_diffuse :: (V: Vector3, L: Vector3, surface: Surface) -> BSDF
{
    if (L.z > 0.0)
    {
        NoV   := V.z;
        f     := evaluate_diffuse_eon(V, L, surface);
        P_u   := pow(surface.roughness, 0.1) * (0.162925 + NoV * (-0.372058 + (0.538233 - 0.290822 * NoV) * NoV));
        P_c   := 1.0 - P_u;
        pdf_c := pdf_cltc(V, L, surface.roughness);
        pdf_u := pdf_uniform();
        pdf   := P_u * pdf_u + P_c * pdf_c;
        return .{f, pdf, .DIFFUSE};
    }
    return .{};
}

sample_diffuse :: (V: Vector3, surface: Surface, u: Vector3) -> Sampled_BSDF
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
        L     = sample_uniform(u1, u2); // sample L from uniform lobe
        pdf_c = pdf_cltc(V, L, surface.roughness); // evaluate CLTC PDF at L
    }
    else
    {
        L, pdf_c = sample_cltc(V, surface.roughness, u1, u2); // sample L from CLTC lobe
    }

    f     := evaluate_diffuse_eon(V, L, surface);
    pdf_u := pdf_uniform();
    pdf   := P_u * pdf_u + P_c * pdf_c; // MIS PDF of L
    return .{.{f, pdf, .DIFFUSE}, L};
}

#scope_module

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
    x           = -lerp(sqrt(1.0 - y * y), x, s);     // CLTC sampling
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

evaluate_diffuse_eon :: (V: Vector3, L: Vector3, surface: Surface) -> Spectrum
{
    if (L.z > 0.0)
    {
        color     := surface.color;
        roughness := surface.roughness;
        NoV       := V.z;
        NoL       := L.z;
        VoL       := dot(V, L);
        s         := VoL - NoL * NoV;
        s_over_t  := ifx (s > 0.0) then (s / max(max(NoL, NoV), 1.0e-4)) else s; // FON s/t
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

//------------------------------------------------------------------------
// Conductor BRDF

#scope_export

evaluate_conductor :: (V: Vector3, L: Vector3, surface: Surface) -> BSDF
{
    alpha := surface.microfacet_alpha;
    if (microfacet_is_rough(alpha) && L.z > 0.0)
    {
        H      := normalize(V + L);
        NoV    := V.z;
        NoL    := L.z;
        VoH    := dot(V, H);
        brdf   := evaluate_ggx_specular_reflect(V, L, H, alpha);
        F_ss   := fresnel_conductor(surface.fresnel.reflectivity, surface.fresnel.edge_tint, VoH);
        f_ss   := brdf.f * F_ss;
        f_ms   := evaluate_conductor_multi_scatter(surface, NoV, NoL);
        pdf_ss := brdf.pdf;
        pdf_ms := pdf_cosine(L);
        f      := f_ss + f_ms;
        pdf    := 0.5 * (pdf_ss + pdf_ms);
        return .{f, pdf, .CONDUCTOR};
    }
    return .{};
}

sample_conductor :: (V: Vector3, surface: Surface, u: Vector3) -> Sampled_BSDF
{
    alpha := surface.microfacet_alpha;
    if (microfacet_is_rough(alpha))
    {
        L, H: Vector3;

        if (u.z < 0.5)
        {
            H = microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
            L = reflect(-V, H);
        }
        else
        {
            L = sample_cosine(u.x, u.y);
            H = normalize(V + L);
        }

        if (L.z > 0.0)
        {
            NoV      := V.z;
            NoL      := L.z;
            VoH      := dot(V, H);
            ggx_brdf := evaluate_ggx_specular_reflect(V, L, H, alpha);
            F_ss     := fresnel_conductor(surface.fresnel.reflectivity, surface.fresnel.edge_tint, VoH);
            f_ms     := evaluate_conductor_multi_scatter(surface, NoV, NoL);
            pdf_ms   := pdf_cosine(L);
            f_ss     := ggx_brdf.f * F_ss;
            pdf_ss   := ggx_brdf.pdf;
            f        := f_ss + f_ms;
            pdf      := 0.5 * (pdf_ss + pdf_ms);
            return .{.{f, pdf, .CONDUCTOR}, L};
        }
        return .{};
    }
    else
    {
        L   := Vector3.{-V.x, -V.y, V.z};
        pdf := 1.0;
        mu  := L.z;
        f   := fresnel_conductor(surface.fresnel.reflectivity, surface.fresnel.edge_tint, mu) / max(mu, 1.0e-6);
        return .{.{f, pdf, .CONDUCTOR}, L};
    }
}

#scope_export

// Conductor Fresnel is based on Gulbrandsen, 2014
// https://jcgt.org/published/0003/04/03/paper.pdf

fresnel_conductor :: (reflectivity: Spectrum, edge_tint: Spectrum, VoH: float) -> Spectrum
{
    r      := reflectivity;
    r.x     = clamp(r.x, 0.0, 0.99);
    r.y     = clamp(r.y, 0.0, 0.99);
    r.z     = clamp(r.z, 0.0, 0.99);

    g      := edge_tint;
    r_sqrt := Spectrum.{sqrt(r.x), sqrt(r.y), sqrt(r.z)};

    n_min  := (Spectrum_One - r) / (Spectrum_One + r);
    n_max  := (Spectrum_One + r_sqrt) / (Spectrum_One - r_sqrt);

    n      := n_min * g + (Spectrum_One - g) * n_max;
    n1     := n + Spectrum_One;
    n2     := n - Spectrum_One;

    nr     := n1 * n1 * r - n2 * n2;
    k2     := nr / (Spectrum_One - r);

    c      := VoH;
    c_sq   := c * c;
    nn     := n * n;
    cc     := Spectrum.{c_sq, c_sq, c_sq};
    nc     := n * c;

    nnk2   := nn + k2;
    t1     := nnk2 + cc;
    t2     := 2 * nc;
    t3     := nnk2 * cc + Spectrum_One;
    t4     := 2 * nc;

    rs_num := t1 - t2;
    rs_den := t1 + t2;
    rs     := rs_num / rs_den;

    rp_num := t3 - t4;
    rp_den := t3 + t4;
    rp     := rp_num / rp_den;

    F      := 0.5 * (rs + rp);

    return F;
}

fresnel_average_conductor :: (reflectivity: Spectrum, edge_tint: Spectrum) -> Spectrum
{
    r     := reflectivity;
    r.x    = clamp(r.x, 0.0, 0.99);
    r.y    = clamp(r.y, 0.0, 0.99);
    r.z    = clamp(r.z, 0.0, 0.99);
    g     := edge_tint;
    g2    := g * g;
    g3    := g2 * g;
    r2    := r * r;
    r3    := r2 * r;
    F_avg := Spectrum.{0.087237, 0.087237, 0.087237} + 0.0230685 * g - 0.0864902 * g2 + 0.0774594 * g3
            + 0.782654 * r - 0.136432 * r2 + 0.278708 * r3 + 0.19744 * g * r
            + 0.0360605 * g2 * r - 0.2586 * g * r2;
    return F_avg;
}

evaluate_conductor_multi_scatter :: inline (surface: Surface, NoV: float, NoL: float) -> Spectrum
{
    #if PRESERVE_MS_ENERGY
    {
        if (surface.flags & .PRESERVE_MULTI_SCATTER_ENERGY)
        {
            // Based on: https://blog.selfshadow.com/publications/s2017-shading-course/imageworks/s2017_pbs_imageworks_slides_v2.pdf

            alpha := surface.microfacet_alpha;
            r     := sqrt(sqrt(alpha.x * alpha.y));
            E_avg := read_table_1D(conductor_E_avg, CONDUCTOR_E_SIZE, r);

            if (E_avg < 1.0)
            {
                E_l   := read_table_2D(conductor_E, CONDUCTOR_E_SIZE, CONDUCTOR_E_SIZE, r, NoL);
                E_v   := read_table_2D(conductor_E, CONDUCTOR_E_SIZE, CONDUCTOR_E_SIZE, r, NoV);
                f_ms  := (1.0 - E_l) * (1.0 - E_v) / (PI * (1.0 - E_avg));

                // Fresnel adjustment is done based on the following blog:
                // https://blog.selfshadow.com/2018/06/04/multi-faceted-part-2/

                F_avg := fresnel_average_conductor(surface.fresnel.reflectivity, surface.fresnel.edge_tint);
                F_ms  := F_avg * F_avg  * E_avg / (Spectrum_One - F_avg * (1.0 - E_avg));

                return F_ms * f_ms;
            }
        }
    }
    return Spectrum_Zero;
}

//------------------------------------------------------------------------
// Dielectric BSDF

evaluate_dielectric :: (V: Vector3, L: Vector3, surface: Surface) -> BSDF
{
    if (L.z > 0.0)
    {
        H    := normalize(V + L);
        R    := effective_fresnel_weight(surface, V, H);
        brdf := evaluate_ggx_specular_reflect(V, L, H, surface.microfacet_alpha);
        NoV  := abs(V.z);
        f    := R * surface.fresnel.edge_tint * brdf.f;
        pdf  := R * brdf.pdf;
        return .{f, pdf, .DIELECTRIC_REFLECTION};
    }
    else if (L.z < 0.0)
    {
        H    := refracted_normal(V, L, surface.ior);
        R    := effective_fresnel_weight(surface, V, H);
        btdf := evaluate_ggx_specular_transmit(V, L, H, surface.microfacet_alpha, surface.ior);
        f    := (Spectrum_One - R * surface.fresnel.edge_tint) * btdf.f;
        pdf  := (1.0 - R) * btdf.pdf;
        return .{f, pdf, .DIELECTRIC_REFRACTION};
    }
    return .{};
}

sample_dielectric :: (V: Vector3, surface: Surface, u: Vector3) -> Sampled_BSDF
{
    H := microfacet_ggx_sample_normal(V, surface.microfacet_alpha, u.x, u.y);
    R := effective_fresnel_weight(surface, V, H);

    if (u.z >= R)
    {
        L, refracted := refract(-V, H, surface.ior);
        if (refracted)
        {
            btdf := evaluate_ggx_specular_transmit(V, L, H, surface.microfacet_alpha, surface.ior);
            f    := (Spectrum_One - R * surface.fresnel.edge_tint) * btdf.f;
            pdf  := (1.0 - R) * btdf.pdf;
            return .{.{f, pdf, .DIELECTRIC_REFRACTION}, L};
        }
        else
        {
            R = 1.0;
        }
    }

    L := reflect(-V, H);
    if (L.z > 0.0)
    {
        brdf := evaluate_ggx_specular_reflect(V, L, H, surface.microfacet_alpha);
        f    := R * surface.fresnel.edge_tint * brdf.f;
        pdf  := R * brdf.pdf;
        return .{.{f, pdf, .DIELECTRIC_REFLECTION}, L};
    }

    return .{};
}

#scope_module

effective_fresnel_dielectric :: inline (ior: float, cos_i: float) -> float
{
    cos_i   = saturate(cos_i);
    sin2_i := 1.0 - cos_i * cos_i;
    sin2_t := ior * ior * sin2_i;
    if (sin2_t >= 1.0)
    {
        return 1.0;
    }
    cos_t := sqrt(1 - saturate(sin2_t));
    Rs := (ior * cos_i - cos_t) / (ior * cos_i + cos_t);
    Rp := (ior * cos_t - cos_i) / (ior * cos_t + cos_i);
    R  := (Rs * Rs + Rp * Rp) * 0.5;
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

effective_fresnel_weight :: (surface: Surface, V: Vector3, H: Vector3) -> float
{
    fresnel := effective_fresnel_dielectric(surface.ior, dot(V, H));
    weight  := fresnel * surface.transmission + 1.0 - surface.transmission;
    return weight;
}

//------------------------------------------------------------------------
// Opacity BTDF

evaluate_opacity :: (V: Vector3, L: Vector3, surface: Surface) -> BSDF
{
    return .{};
}

sample_opacity :: (V: Vector3, surface: Surface, u: Vector3) -> Sampled_BSDF
{
    L   := -V;
    mu  := abs(L.z);
    f   := Spectrum_Zero;
    if (mu > 0.0)
    {
        f = Spectrum_One / mu;
    }
    pdf := 1.0;
    return .{.{f, pdf, .TRANSMISSION}, L};
}

//------------------------------------------------------------------------
// Microfacet Model
// Trowbridge–Reitz (GGX) model
// https://jcgt.org/published/0003/02/03/

#scope_module

microfacet_ggx_distribution :: (H: Vector3, alpha: Vector2) -> float
{
    Hs           := H / Vector3.{alpha.x, alpha.y, 1.0};
    lensq        := length_squared(Hs);
    inv_D        := PI * alpha.x * alpha.y * lensq * lensq;
    D            := 1.0 / inv_D;
    return D;
}

microfacet_ggx_lambda :: inline (N: Vector3, alpha: Vector2) -> float
{
    alpha_x      := alpha.x * N.x;
    alpha_y      := alpha.y * N.y;
    cos_theta_sq := max(N.z * N.z, 1.0e-6);
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

MICROFACET_ALPHA_THRESHOLD :: 1.0e-4;

#scope_export

microfacet_is_rough :: (alpha: Vector2) -> bool
{
    return alpha.x >= MICROFACET_ALPHA_THRESHOLD || alpha.y >= MICROFACET_ALPHA_THRESHOLD;
}

microfacet_is_smooth :: alpha => !microfacet_is_rough(alpha);

microfacet_alpha :: (roughness: float, anisotropic: float) -> Vector2
{
    r2      := roughness * roughness;
    aspect  := 0.9 * anisotropic;
    alpha_x := r2 * (1.0 + aspect);
    alpha_y := r2 * (1.0 - aspect);
    alpha   := Vector2.{alpha_x, alpha_y};
    if microfacet_is_rough(alpha)
    {
        alpha.x = max(alpha.x, MICROFACET_ALPHA_THRESHOLD);
        alpha.y = max(alpha.y, MICROFACET_ALPHA_THRESHOLD);
    }
    return alpha;
}

//------------------------------------------------------------------------
// Specular BxDF

#scope_export

evaluate_ggx_specular_reflect :: (V: Vector3, L: Vector3, H: Vector3, alpha: Vector2) -> BSDF
{
    NoV := V.z;
    NoL := L.z;
    D   := microfacet_ggx_distribution(H, alpha);
    G   := microfacet_ggx_mask_shadow(V, L, alpha);
    G1  := microfacet_ggx_mask(V, alpha);
    f   := (D * G) / max(4 * NoL * NoV, 1.0e-6);
    pdf := (D * G1) / max(4 * NoV, 1.0e-6);
    return .{.{f, f, f}, pdf, 0};
}

sample_ggx_specular_reflect :: (V: Vector3, alpha: Vector2, u: Vector2) -> Sampled_BSDF
{
    H    := microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
    L    := reflect(-V, H);
    if (L.z > 0.0)
    {
        brdf := evaluate_ggx_specular_reflect(V, L, H, alpha);
        return .{brdf, L};
    }
    return .{};
}

evaluate_ggx_specular_transmit :: (V: Vector3, L: Vector3, H: Vector3, alpha: Vector2, ior: float) -> BSDF
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
    return .{.{f, f, f}, pdf, 0};
}

sample_ggx_specular_transmit :: (V: Vector3, alpha: Vector2, ior: float, u: Vector2) -> Sampled_BSDF
{
    H := microfacet_ggx_sample_normal(V, alpha, u.x, u.y);
    L, refracted := refract(-V, H, surface.ior);
    if (refracted)
    {
        btdf := evaluate_ggx_specular_transmit(V, L, H, ior, alpha);
        return .{btdf, L};
    }
    return .{};
}

//------------------------------------------------------------------------
// Principled BSDF

#scope_export

Lobe_Type :: enum u32
{
    DIFFUSE;
    CONDUCTOR;
    DIELECTRIC;
    OPACITY;
}

MAX_LOBE_TYPES :: #run type_info(Lobe_Type).values.count;

Lobe_Weights :: [MAX_LOBE_TYPES]float;

evaluate_principled_lobe :: (V: Vector3, L: Vector3, surface: Surface, type: Lobe_Type) -> BSDF
{
    if #complete type ==
    {
        case .DIFFUSE;
            return evaluate_diffuse(V, L, surface);
        case .CONDUCTOR;
            return evaluate_conductor(V, L, surface);
        case .DIELECTRIC;
            return evaluate_dielectric(V, L, surface);
        case .OPACITY;
            return evaluate_opacity(V, L, surface);
    }
}

sample_principled_lobe :: (V: Vector3, surface: Surface, u: Vector3, type: Lobe_Type) -> Sampled_BSDF
{
    if #complete type ==
    {
        case .DIFFUSE;
            return sample_diffuse(V, surface, u);
        case .CONDUCTOR;
            return sample_conductor(V, surface, u);
        case .DIELECTRIC;
            return sample_dielectric(V, surface, u);
        case .OPACITY;
            return sample_opacity(V, surface, u);
    }
}

evaluate_principled :: (V: Vector3, L: Vector3, surface: Surface) -> BSDF
{
    weights := calculate_lobe_weights(surface);
    bsdf    : BSDF;
    for 0..MAX_LOBE_TYPES-1
    {
        index    := it.(Lobe_Type);
        bxdf     := evaluate_principled_lobe(V, L, surface, index);
        bsdf.f   += weights[it] * bxdf.f;
        bsdf.pdf += weights[it] * bxdf.pdf;
    }
    return bsdf;
}

sample_principled :: (V: Vector3, surface: Surface, p: float, u: Vector3) -> Sampled_BSDF
{
    weights := calculate_lobe_weights(surface);
    picked  := pick_lobe(p, weights);
    sample  := sample_principled_lobe(V, surface, u, picked);

    if (sample.pdf > 0.0)
    {
        L := sample.L;

        mixed_bsdf: BSDF;
        for 0..MAX_LOBE_TYPES-1
        {
            type := it.(Lobe_Type);

            if type == .DIELECTRIC continue; // TODO: fix dielectric

            if (type != picked)
            {
                bsdf           := evaluate_principled_lobe(V, L, surface, type);
                mixed_bsdf.f   += weights[type] * bsdf.f;
                mixed_bsdf.pdf += weights[type] * bsdf.pdf;
            }
        }

        mixed_bsdf.f   += weights[picked] * sample.f;
        mixed_bsdf.pdf += weights[picked] * sample.pdf;
        mixed_bsdf.flags |= sample.flags;

        return .{mixed_bsdf, L};
    }

    return .{};
}

#scope_module

pick_lobe :: (p: float, weights: Lobe_Weights) -> Lobe_Type
{
    sum_p := 0.0;
    for 0..MAX_LOBE_TYPES-1
    {
        sum_p += weights[it];
        if (p < sum_p)
        {
            return it.(Lobe_Type);
        }
    }
    return .DIFFUSE;
}

calculate_lobe_weights :: (using surface: Surface) -> Lobe_Weights
{
    o   := clamp(opacity, 0.0, 1.0);
    m   := clamp(metallic, 0.0, 1.0);
    s   := clamp(specular, 0.0, 1.0);
    t   := clamp(transmission, 0.0, 1.0);
    nm  := o * (1.0 - m);
    weights: Lobe_Weights;
    weights[Lobe_Type.OPACITY]     = (1.0 - o);
    weights[Lobe_Type.CONDUCTOR]   = o * m;
    weights[Lobe_Type.DIFFUSE]     = nm * (1.0 - s);
    weights[Lobe_Type.DIELECTRIC]  = nm * s;
    return weights;
}

//------------------------------------------------------------------------

#scope_module

INV_PI :: 1.0 / PI;

power6 :: inline (x: float) -> float
{
    x2 := x * x;
    x3 := x2 * x;
    x6 := x3 * x3;
    return x6;
}

sdiv :: inline (x: $T, y: T) -> T
{
    if (y != 0)
    {
        return x/y;
    }
    return 0;
}

reflect :: inline (I: Vector3, N: Vector3) -> Vector3
{
    return I - 2.0 * dot(N, I) * N;
}

refract :: inline (I: Vector3, N: Vector3, ior: float) -> Vector3, bool
{
    cos_i := -dot(N, I);
    sin_t := ior * ior * (1.0 - cos_i * cos_i);
    if (sin_t <= 1.0)
    {
        k := 1.0 - sin_t;
        R := ior * I + (ior * cos_i - sqrt(k)) * N;
        return R, true;
    }
    return .{}, false;
}

read_table_1D :: inline (table: []float, $w: int, u: float) -> float
{
    up := u * w - 0.5;
    i0 := floor(up).(int);
    i1 := i0 + 1;
    u0 := clamp(i0, 0, w - 1);
    u1 := clamp(i1, 0, w - 1);
    uf := up - i0;
    x  := lerp(table[u0], table[u1], uf);
    return x;
}

read_table_2D :: inline (table: []float, $w: int, $h: int, u: float, v: float) -> float
{
    up  := u * w - 0.5;
    vp  := v * h - 0.5;
    iu0 := floor(up).(int);
    iv0 := floor(vp).(int);
    iu1 := iu0 + 1;
    iv1 := iv0 + 1;
    u0 := clamp(iu0, 0, w - 1);
    u1 := clamp(iu1, 0, w - 1);
    v0 := clamp(iv0, 0, h - 1);
    v1 := clamp(iv1, 0, h - 1);
    uf := up - iu0;
    vf := vp - iv0;
    y0 := lerp(table[v0 * w + u0], table[v0 * w + u1], uf);
    y1 := lerp(table[v1 * w + u0], table[v1 * w + u1], uf);
    x  := lerp(y0, y1, vf);
    return x;
}

#scope_file

#import "Math";
#import "Basic";
