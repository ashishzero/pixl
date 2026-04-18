//------------------------------------------------------------------------
// Diffuse EON BxDF

// EON: A practical energy-preserving rough diffuse BRDF
// https://arxiv.org/pdf/2410.18026

#scope_export

evaluate_diffuse :: (V: Vector3, L: Vector3, surface: Surface, label: BSDF_Label) -> BSDF
{
    if (L.z > 0.0 && (label & .REFLECTION))
    {
        r     := surface.diffuse_roughness;
        NoV   := V.z;
        f     := evaluate_diffuse_eon(V, L, surface);
        P_u   := pow(r, 0.1) * (0.162925 + NoV * (-0.372058 + (0.538233 - 0.290822 * NoV) * NoV));
        P_c   := 1.0 - P_u;
        pdf_c := pdf_cltc(V, L, r);
        pdf_u := pdf_uniform();
        pdf   := P_u * pdf_u + P_c * pdf_c;
        return .{f, pdf};
    }
    return .{};
}

sample_diffuse :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> Sampled_BSDF
{
    r         := surface.diffuse_roughness;
    NoV       := V.z;
    P_u       := pow(r, 0.1) * (0.162925 + NoV * (-0.372058 + (0.538233 - 0.290822 * NoV) * NoV));
    P_c       := 1.0 - P_u; // probability of CLTC sample

    L         : Vector3 = ---;
    pdf_c     : float   = ---;

    u1        := u.x;
    u2        := u.y;

    if (p < P_u)
    {
        L     = sample_uniform(u1, u2); // sample L from uniform lobe
        pdf_c = pdf_cltc(V, L, r); // evaluate CLTC PDF at L
    }
    else
    {
        L, pdf_c = sample_cltc(V, r, u1, u2); // sample L from CLTC lobe
    }

    f     := evaluate_diffuse_eon(V, L, surface);
    pdf_u := pdf_uniform();
    pdf   := P_u * pdf_u + P_c * pdf_c; // MIS PDF of L
    return .{.{f, pdf}, L, .DIFFUSE_REFLECTION};
}

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
        roughness := surface.diffuse_roughness;
        NoV       := V.z;
        NoL       := L.z;
        VoL       := dot(V, L);
        s         := VoL - NoL * NoV;
        s_over_t  := ifx (s > 0.0) then (s / max(max(NoL, NoV), 1.0e-4)) else s; // FON s/t
        AF        := 1.0 / (1.0 + FON1 * roughness);                             // FON A coeff
        f_ss      := (color / PI) * AF * (1.0 + roughness * s_over_t);           // single-scatter
        EFo       := e_fon_approx(NoV, roughness);                               // FON V albedo
        EFi       := e_fon_approx(NoL, roughness);                               // FON L albedo
        avgEF     := AF * (1.0 + FON2 * roughness);                              // average albedo
        rho_ms    := (color * color) * avgEF / (Vector3.{1, 1, 1} - color * (1.0 - avgEF));
        eps       := 1.0e-6;
        f_ms      := (rho_ms / PI) * max(eps, 1.0 - EFo) * max(eps, 1.0 - EFi) / max(eps, 1.0 - avgEF); // multi-scatterlobe
        f         := f_ss + f_ms;
        return f;
    }
    return Spectrum_Zero;
}

//------------------------------------------------------------------------
// Metal BRDF

#scope_export

evaluate_metal :: (V: Vector3, L: Vector3, surface: Surface, label: BSDF_Label) -> BSDF
{
    alpha := surface.microfacet_alpha;
    if !microfacet_is_delta(alpha) && L.z > 0.0 && (label & .REFLECTION)
    {
        rough  := sqrt(sqrt(alpha.x * alpha.y));
        E_avg  := average_energy_metal(rough);
        F_avg  := fresnel_average_metal(surface.reflectance, surface.edge_tint, surface.falloff);

        P_ss   := estimate_metal(E_avg, F_avg);
        P_ms   := 1.0 - P_ss;

        H      := normalize(V + L);
        VoH    := dot(V, H);
        spec   := evaluate_ggx_specular_reflect(V, L, H, alpha);
        F_ss   := fresnel_metal(surface.reflectance, surface.edge_tint, surface.falloff, VoH);
        f_ss   := F_ss * spec.f;
        f_ms   := multiscatter_compensation_metal(E_avg, F_avg, rough, V.z, L.z);
        pdf_ms := pdf_cosine(L);
        pdf_ss := spec.pdf;
        f      := f_ss + f_ms;
        pdf    := P_ss * pdf_ss + P_ms * pdf_ms;
        return .{f, pdf};
    }
    return .{};
}

sample_metal :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> Sampled_BSDF
{
    alpha := surface.microfacet_alpha;
    if !microfacet_is_delta(alpha)
    {
        rough := sqrt(sqrt(alpha.x * alpha.y));
        E_avg := average_energy_metal(rough);
        F_avg := fresnel_average_metal(surface.reflectance, surface.edge_tint, surface.falloff);

        P_ss  := estimate_metal(E_avg, F_avg);
        P_ms  := 1.0 - P_ss;

        if (p < P_ss)
        {
            sample := sample_ggx_specular_reflect(V, alpha, u);
            if (sample.L.z > 0.0)
            {
                VoH    := dot(V, sample.H);
                F_ss   := fresnel_metal(surface.reflectance, surface.edge_tint, surface.falloff, VoH);
                f_ss   := F_ss * sample.f;
                f_ms   := multiscatter_compensation_metal(E_avg, F_avg, rough, V.z, sample.L.z);
                pdf_ms := pdf_cosine(sample.L);
                pdf_ss := sample.pdf;
                f      := f_ss + f_ms;
                pdf    := P_ss * pdf_ss + P_ms * pdf_ms;
                return .{.{f, pdf}, sample.L, .SPECULAR_REFLECTION};
            }
        }
        else
        {
            L := sample_cosine(u.x, u.y);
            if (L.z > 0.0)
            {
                H      := normalize(V + L);
                VoH    := dot(V, H);
                F_ss   := fresnel_metal(surface.reflectance, surface.edge_tint, surface.falloff, VoH);
                spec   := evaluate_ggx_specular_reflect(V, L, H, alpha);
                f_ss   := F_ss * spec.f;
                f_ms   := multiscatter_compensation_metal(E_avg, F_avg, rough, V.z, L.z);
                pdf_ms := pdf_cosine(L);
                pdf_ss := spec.pdf;
                f      := f_ss + f_ms;
                pdf    := P_ss * pdf_ss + P_ms * pdf_ms;
                return .{.{f, pdf}, L, .SPECULAR_REFLECTION};
            }
        }
    }
    else
    {
        L   := Vector3.{-V.x, -V.y, V.z};
        pdf := 1.0;
        mu  := L.z;
        f   := fresnel_metal(surface.reflectance, surface.edge_tint, surface.falloff, mu) / max(mu, 1.0e-6);
        return .{.{f, pdf}, L, .SPECULAR_REFLECTION};
    }
    return .{};
}

#scope_file

average_energy_metal :: (rough: float) -> float
{
    E_avg := read_table_1D(metal_E_avg, METAL_E_SIZE, rough);
    return E_avg;
}

estimate_metal :: (E_avg: float, F_avg: Spectrum) -> float
{
    f := E_avg * F_avg;
    return luminance(f);
}

multiscatter_compensation_metal :: (E_avg: float, F_avg: Spectrum, rough: float, NoV: float, NoL: float) -> Spectrum
{
    #if PRESERVE_MS_ENERGY
    {
        // Based on: https://blog.selfshadow.com/publications/s2017-shading-course/imageworks/s2017_pbs_imageworks_slides_v2.pdf
        if (E_avg < 1.0)
        {
            E_l   := read_table_2D(metal_E, METAL_E_SIZE, METAL_E_SIZE, rough, NoL);
            E_v   := read_table_2D(metal_E, METAL_E_SIZE, METAL_E_SIZE, rough, NoV);
            f_ms  := (1.0 - E_l) * (1.0 - E_v) / (PI * (1.0 - E_avg));

            // Fresnel adjustment is done based on the following blog:
            // https://blog.selfshadow.com/2018/06/04/multi-faceted-part-2/
            F_ms  := F_avg * F_avg  * E_avg / (Spectrum_One - F_avg * (1.0 - E_avg));

            return F_ms * f_ms;
        }
    }
    return Spectrum_Zero;
}

//------------------------------------------------------------------------
// Glossy Diffuse

evaluate_glossy_diffuse :: (V: Vector3, L: Vector3, surface: Surface, label: BSDF_Label) -> BSDF
{
    if (L.z > 0.0 && (label & .REFLECTION))
    {
        alpha         := surface.microfacet_alpha;
        rough         := sqrt(sqrt(alpha.x * alpha.y));
        specular_ior  := surface.specular_ior;
        effective_ior := max(specular_ior, 1.0 / specular_ior);
        param_ior     := ior_inverse_parametrization(effective_ior);
        E_avg         := average_energy_glossy_diffuse_specular(specular_ior, rough, param_ior);
        P_s           := estimate_glossy_diffuse_specular(surface.specular_weight, E_avg);
        P_d           := 1.0 - P_s;
        
        H             := normalize(V + L);
        VoH           := dot(V, H);
        F             := fresnel_dielectric(specular_ior, VoH);
        specular      := evaluate_ggx_specular_reflect(V, L, H, alpha);
        diffuse       := evaluate_diffuse(V, L, surface, label);
        E_diffuse     := multiscatter_glossy_diffuse_compensation(specular_ior, E_avg, rough, V.z, L.z, param_ior);
        f             := F * specular.f * surface.specular_weight + E_diffuse * (1.0 - surface.specular_weight) * diffuse.f;
        pdf           := P_s * specular.pdf + P_d * diffuse.pdf;
        return .{f, pdf};
    }
    return .{};
}

sample_glossy_diffuse :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> Sampled_BSDF
{
    alpha         := surface.microfacet_alpha;
    rough         := sqrt(sqrt(alpha.x * alpha.y));
    specular_ior  := surface.specular_ior;
    effective_ior := max(specular_ior, 1.0 / specular_ior);
    param_ior     := ior_inverse_parametrization(effective_ior);
    E_avg         := average_energy_glossy_diffuse_specular(specular_ior, rough, param_ior);
    P_s           := estimate_glossy_diffuse_specular(surface.specular_weight, E_avg);
    P_d           := 1.0 - P_s;

    if (p < P_s)
    {
        specular := sample_ggx_specular_reflect(V, alpha, .{u.x, u.y});
        if (specular.L.z > 0.0)
        {
            L         := specular.L;
            H         := specular.H;
            VoH       := dot(V, H);
            F         := fresnel_dielectric(specular_ior, VoH);
            diffuse   := evaluate_diffuse(V, L, surface, specular.label);
            E_diffuse := multiscatter_glossy_diffuse_compensation(specular_ior, E_avg, rough, V.z, L.z, param_ior);
            f         := F * specular.f * surface.specular_weight + E_diffuse * (1.0 - surface.specular_weight) * diffuse.f;
            pdf       := P_s * specular.pdf + P_d * diffuse.pdf;
            return .{.{f, pdf}, L, .SPECULAR_REFLECTION};
        }
    }
    else
    {
        p        = (p - P_s) / P_d;
        diffuse := sample_diffuse(V, surface, p, u);
        if (diffuse.L.z > 0.0)
        {
            L         := diffuse.L;
            H         := normalize(V + L);
            VoH       := dot(V, H);
            F         := fresnel_dielectric(surface.specular_ior, VoH);
            specular  := evaluate_ggx_specular_reflect(V, L, H, alpha);
            E_diffuse := multiscatter_glossy_diffuse_compensation(specular_ior, E_avg, rough, V.z, L.z, param_ior);
            f         := F * specular.f * surface.specular_weight + E_diffuse * (1.0 - surface.specular_weight) * diffuse.f;
            pdf       := P_s * specular.pdf + P_d * diffuse.pdf;
            return .{.{f, pdf}, L, .DIFFUSE_REFLECTION};
        }
    }

    return .{};
}

#scope_file

average_energy_glossy_diffuse_specular :: (specular_ior: float, rough: float, param_ior: float) -> float
{
    E_avg_table := ifx specular_ior >= 1.0 then dielectric_E_avg else dielectric_inv_E_avg;
    E_avg       := read_table_2D(E_avg_table, DIELECTRIC_E_AVG_SIZE, DIELECTRIC_E_AVG_SIZE, rough, param_ior);
    return E_avg;
}

estimate_glossy_diffuse_specular :: (specular_weight: float, E_avg: float) -> float
{
    mapped_E := E_avg * 0.9 + 0.05;
    P_s      := specular_weight * mapped_E;
    return P_s;
}

multiscatter_glossy_diffuse_compensation :: (specular_ior: float, E_avg: float, rough: float, NoV: float, NoL: float, param_ior: float) -> float
{
    #if PRESERVE_MS_ENERGY
    {
        // Based on: https://blog.selfshadow.com/publications/s2017-shading-course/imageworks/s2017_pbs_imageworks_slides_v2.pdf
        if (E_avg < 1.0)
        {
            E_table   := ifx specular_ior >= 1.0 then dielectric_E else dielectric_inv_E;
            E_l       := read_table_3D(E_table, DIELECTRIC_E_SIZE, DIELECTRIC_E_SIZE, DIELECTRIC_E_SIZE, rough, NoL, param_ior);
            E_v       := read_table_3D(E_table, DIELECTRIC_E_SIZE, DIELECTRIC_E_SIZE, DIELECTRIC_E_SIZE, rough, NoV, param_ior);
            E_diffuse := (1.0 - E_l) * (1.0 - E_v) / (1.0 - E_avg);
            return E_diffuse;
        }
    }
    return 0.0;
}

//------------------------------------------------------------------------
// Dielectric Translucent

evaluate_dielectric :: (V: Vector3, L: Vector3, surface: Surface, label: BSDF_Label) -> BSDF
{
    if (L.z > 0.0)
    {
        H    := normalize(V + L);
        VoH  := dot(V, H);
        F    := fresnel_dielectric(surface.specular_ior, VoH);
        brdf := evaluate_ggx_specular_reflect(V, L, H, surface.microfacet_alpha);
        NoV  := abs(V.z);
        f    := F * surface.edge_tint * brdf.f;
        pdf  := F * brdf.pdf;
        return .{f, pdf};
    }
    else if (L.z < 0.0)
    {
        n_sq := surface.specular_ior * surface.specular_ior;
        H    := refracted_normal(V, L, surface.specular_ior);
        VoH  := dot(V, H);
        F    := fresnel_dielectric(surface.specular_ior, VoH);
        btdf := evaluate_ggx_specular_refract(V, L, H, surface.microfacet_alpha, surface.specular_ior);
        f    := (1.0 - F) * n_sq * btdf.f;
        pdf  := (1.0 - F) * btdf.pdf;
        return .{f, pdf};
    }
    return .{};
}

sample_dielectric :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> Sampled_BSDF
{
    H := microfacet_ggx_sample_normal(V, surface.microfacet_alpha, u.x, u.y);
    F := fresnel_dielectric(surface.specular_ior, dot(V, H));

    if (p >= F)
    {
        L, refracted := refract(-V, H, surface.specular_ior);
        if (refracted)
        {
            n_sq := surface.specular_ior * surface.specular_ior;
            btdf := evaluate_ggx_specular_refract(V, L, H, surface.microfacet_alpha, surface.specular_ior);
            f    := (1.0 - F) * n_sq * btdf.f;
            pdf  := (1.0 - F) * btdf.pdf;
            return .{.{f, pdf}, L, .SPECULAR_REFLECTION};
        }
        else
        {
            F = 1.0;
        }
    }

    L := reflect(-V, H);
    if (L.z > 0.0)
    {
        brdf := evaluate_ggx_specular_reflect(V, L, H, surface.microfacet_alpha);
        f    := F * brdf.f;
        pdf  := F * brdf.pdf;
        return .{.{f, pdf}, L, .SPECULAR_REFRACTION};
    }

    return .{};
}

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

//------------------------------------------------------------------------
// Geometry Transmission BTDF

evaluate_ambient :: (V: Vector3, L: Vector3, surface: Surface, label: BSDF_Label) -> BSDF
{
    return .{};
}

sample_ambient :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> Sampled_BSDF
{
    L   := -V;
    mu  := abs(L.z);
    f   := Spectrum_Zero;
    if (mu > 0.0)
    {
        f = Spectrum_One / mu;
    }
    pdf := 1.0;
    return .{.{f, pdf}, L, .TRANSMISSION};
}

//------------------------------------------------------------------------
// Principled BSDF

#scope_export

evaluate_principled_bsdf :: (V: Vector3, L: Vector3, surface: Surface) -> BSDF
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

sample_principled_bsdf :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> Sampled_BSDF
{
    weights := calculate_lobe_weights(surface);
    picked  := Lobe_Type.AMBIENT;

    cf: [MAX_LOBE_TYPES+1]float = ---;
    cf[0] = 0.0;
    cf[0] = 0.0;
    for 0..MAX_LOBE_TYPES-1
    {
        cf[it + 1] = cf[it] + weights[it];
    }

    for 0..MAX_LOBE_TYPES-1
    {
        if (p < cf[it + 1])
        {
            picked = it.(Lobe_Type);
            break;
        }
    }

    p_lobe  := (p - cf[picked]) / (cf[picked + 1] - cf[picked]);
    sample  := sample_lobe(V, surface, p_lobe, u, picked);

    if (sample.pdf > 0.0)
    {
        L := sample.L;

        mixed_bsdf: BSDF;
        for 0..MAX_LOBE_TYPES-1
        {
            type := it.(Lobe_Type);
            if (type != picked && weights[type] > 0.0)
            {
                bsdf := evaluate_lobe(V, L, surface, sample.label, type);
                if (bsdf.pdf > 0.0)
                {
                    mixed_bsdf.f   += weights[type] * bsdf.f;
                    mixed_bsdf.pdf += weights[type] * bsdf.pdf;
                }
            }
        }

        mixed_bsdf.f   += weights[picked] * sample.f;
        mixed_bsdf.pdf += weights[picked] * sample.pdf;

        return .{mixed_bsdf, L, sample.label};
    }

    return .{};
}

#scope_file

Lobe_Type :: enum u32
{
    AMBIENT;
    METALLIC;
    GLOSSY_DIFFUSE;
    DIELECTRIC;
}

MAX_LOBE_TYPES :: #run type_info(Lobe_Type).values.count;
Lobe_Weights   :: [MAX_LOBE_TYPES]float;

calculate_lobe_weights :: (surface: Surface) -> Lobe_Weights
{
    ambient        := 1.0 - surface.geometry_opacity;
    metallic       := surface.geometry_opacity * surface.metallic;
    non_metallic   := 1.0 - metallic;
    glossy_diffuse := non_metallic * (1.0 - surface.transmission_weight);
    dielectric     := non_metallic * surface.transmission_weight;

    weights: Lobe_Weights;
    weights[Lobe_Type.AMBIENT]        = ambient;
    weights[Lobe_Type.METALLIC]       = metallic;
    weights[Lobe_Type.GLOSSY_DIFFUSE] = glossy_diffuse;
    weights[Lobe_Type.DIELECTRIC]     = dielectric;

    return weights;
}

evaluate_lobe :: (V: Vector3, L: Vector3, surface: Surface, label: BSDF_Label, type: Lobe_Type) -> BSDF
{
    if #complete type ==
    {
        case .AMBIENT;
            return evaluate_ambient(V, L, surface, label);
        case .METALLIC;
            return evaluate_metal(V, L, surface, label);
        case .GLOSSY_DIFFUSE;
            return evaluate_glossy_diffuse(V, L, surface, label);
        case .DIELECTRIC;
            return evaluate_dielectric(V, L, surface, label);
    }
}

sample_lobe :: (V: Vector3, surface: Surface, p: float, u: Vector2, type: Lobe_Type) -> Sampled_BSDF
{
    if #complete type ==
    {
        case .AMBIENT;
            return sample_ambient(V, surface, p, u);
        case .METALLIC;
            return sample_metal(V, surface, p, u);
        case .GLOSSY_DIFFUSE;
            return sample_glossy_diffuse(V, surface, p, u);
        case .DIELECTRIC;
            return sample_dielectric(V, surface, p, u);
    }
}

//------------------------------------------------------------------------

#scope_file

sdiv :: inline (x: $T, y: T) -> T
{
    if (y != 0)
    {
        return x/y;
    }
    return 0;
}

#scope_file

#import "Math";
#import "Basic";

#if PRESERVE_MS_ENERGY
{
    #load "ms_tables.jai";

    sampler_1D :: inline (u: float, $dim: s32) -> s32, s32, float
    {
        up := u * (dim - 1);
        i0 := up.(s32);
        i1 := i0 + 1;
        u0 := clamp(i0, 0, dim - 1);
        u1 := clamp(i1, 0, dim - 1);
        uf := up - i0;
        return u0, u1, uf;
    }

    read_table_1D :: inline (table: []float, $dim_u: s32, u: float) -> float
    {
        u0, u1, uf := sampler_1D(u, dim_u);
        x  := lerp(table[u0], table[u1], uf);
        return x;
    }

    read_table_2D :: inline (table: []float, $dim_u: s32, $dim_v: s32, u: float, v: float) -> float
    {
        u0, u1, uf := sampler_1D(u, dim_u);
        v0, v1, vf := sampler_1D(v, dim_v);
        r0 := v0 * dim_u;
        r1 := v1 * dim_u;
        y0 := lerp(table[r0 + u0], table[r0 + u1], uf);
        y1 := lerp(table[r1 + u0], table[r1 + u1], uf);
        x  := lerp(y0, y1, vf);
        return x;
    }

    read_table_3D :: inline (table: []float, $dim_u: s32, $dim_v: s32, $dim_w: s32, u: float, v: float, w: float) -> float
    {
        u0, u1, uf := sampler_1D(u, dim_u);
        v0, v1, vf := sampler_1D(v, dim_v);
        w0, w1, wf := sampler_1D(w, dim_w);
        dim_uv := dim_u * dim_v;
        d0     := w0 * dim_uv;
        d1     := w1 * dim_uv;
        r0     := v0 * dim_u;
        r1     := v1 * dim_u;
        z0y0   := lerp(table[d0 + r0 + u0], table[d0 + r0 + u1], uf);
        z0y1   := lerp(table[d0 + r1 + u0], table[d0 + r1 + u1], uf);
        z1y0   := lerp(table[d1 + r0 + u0], table[d1 + r0 + u1], uf);
        z1y1   := lerp(table[d1 + r1 + u0], table[d1 + r1 + u1], uf);
        z0     := lerp(z0y0, z0y1, vf);
        z1     := lerp(z1y0, z1y1, vf);
        return lerp(z0, z1, wf);
    }

}
