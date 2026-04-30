//------------------------------------------------------------------------
// Diffuse EON BxDF

// EON: A practical energy-preserving rough diffuse BRDF
// https://arxiv.org/pdf/2410.18026

#scope_export

evaluate_diffuse :: (using info: Diffuse_Shading_Info, wo: Vector3, wi: Vector3) -> Spectrum
{
    if wi.z > 0.0
    {
        wh        := normalize(wo + wi);
        wo_dot_wh := dot(wo, wh);
        fresnel   := fresnel_dielectric(eta_t_over_eta_i, wo.z);
        f         := diffuse_eon_spectrum(wo, wi, albedo, roughness);
        weight    := (Spectrum_One - fresnel) * f * wi.z; // TODO: Use better estimate
        return weight;
    }
    return Spectrum_Zero;
}

pdf_diffuse :: (using info: Diffuse_Shading_Info, wo: Vector3, wi: Vector3) -> float
{
    if wo.z > 0.0
    {
        wo_dot_n := wo.z;
        p_u      := pow(roughness, 0.1) * (0.162925 + wo_dot_n * (-0.372058 + (0.538233 - 0.290822 * wo_dot_n) * wo_dot_n));
        p_c      := 1.0 - p_u;
        pdf_c    := pdf_cltc(wo, wi, roughness);
        pdf_u    := pdf_uniform_hemisphere();
        pdf      := p_u * pdf_u + p_c * pdf_c;
        return pdf;
    }
    return 0.0;
}

sample_diffuse :: (using info: Diffuse_Shading_Info, wo: Vector3, u: Vector3) -> Sample
{
    wo_dot_n  := wo.z;
    p_u       := pow(roughness, 0.1) * (0.162925 + wo_dot_n * (-0.372058 + (0.538233 - 0.290822 * wo_dot_n) * wo_dot_n));
    p_c       := 1.0 - p_u; // probability of CLTC sample

    wi        : Vector3 = ---;
    pdf_c     : float   = ---;
    p         := u.z;

    if (p < p_u)
    {
        wi    = sample_uniform_hemisphere(u.x, u.y); // sample wi from uniform lobe
        pdf_c = pdf_cltc(wo, wi, roughness); // evaluate CLTC PDF at wi
    }
    else
    {
        wi, pdf_c = sample_cltc(wo, roughness, u.x, u.y); // sample wi from CLTC lobe
    }

    if wi.z > 0.0
    {
        wh        := normalize(wo + wi);
        wo_dot_wh := dot(wo, wh);
        fresnel   := fresnel_dielectric(eta_t_over_eta_i, wo_dot_wh);
        f         := diffuse_eon_spectrum(wo, wi, albedo, roughness);
        pdf_u     := pdf_uniform_hemisphere();
        pdf       := p_u * pdf_u + p_c * pdf_c; // MIS PDF of wi
        weight    := (Spectrum_One - fresnel) * f * wi.z / pdf;
        return make_sample(weight, pdf, wi, .REFLECTION | .DIFFUSE);
    }

    return make_zero_sample();
}

estimate_diffuse :: (using info: Diffuse_Shading_Info, wo: Vector3) -> float
{
    // TODO: Use better estimate
    fresnel  := fresnel_dielectric(eta_t_over_eta_i, wo.z);
    estimate := (1.0 - fresnel.x) * max_spectrum(albedo);
    return estimate;
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

sample_cltc :: (w: Vector3, roughness: float, u1: float, u2: float) -> Vector3, float
{
    a, b, c, d := ltc_coeffs(w.z, roughness);         // coeffs of LTC M
    radius     := sqrt(u1);                           // CLTC sampling
    phi        := 2.0 * PI * u2;                      // CLTC sampling
    x          := radius * cos(phi);                  // CLTC sampling factors
    y          := radius * sin(phi);                  // CLTC sampling factors
    vz         := 1.0 / sqrt(d * d + 1.0);            // CLTC sampling factors
    s          := 0.5 * (1.0 + vz);                   // CLTC sampling factors
    x           = -lerp(sqrt(1.0 - y * y), x, s);     // CLTC sampling
    wh         := Vector3.{x, y, sqrt(max(1.0 - (x * x + y * y), 0.0))}; // H sample via CLTC
    pdf_h      := wh.z / (PI * s);                    // PDF of H sample
    wi         := Vector3.{a * wh.x + b * wh.z, c * wh.y, d * wh.x + wh.z}; // M H (unnormalized)
    len        := length(wi);                         // ∥M H∥=1/∥inv(M) H∥
    det        := c * (a - b * d);                    // |M|
    pdf_wi     := pdf_h * len * len * len / det;      // wi sample PDF
    from_LTC   := ltc_orthonormal_basis(w);           // wi -> local space
    wi          = normalize(from_LTC * wi);           // wi -> local space
    return wi, pdf_wi;
}

pdf_cltc :: (wo_local: Vector3, wi_local: Vector3, roughness: float) -> float
{
    to_LTC     := transpose(ltc_orthonormal_basis(wo_local)); // wo -> LTC space
    L          := to_LTC * wi_local;                          // wi -> LTC space
    a, b, c, d := ltc_coeffs(abs(wo_local.z), roughness);     // coeffs of LTC M
    det        := c * (a - b * d);                            // |M|
    wh         := Vector3.{c * (L.x - b * L.z), (a - b * d) * L.y, -c * (d * L.x - a * L.z)}; // adj(M)L
    lensq      := dot(wh, wh);                                // |M|∥inv(M) H∥
    vz         := 1.0 / sqrt(d * d + 1.0);                    // CLTC sampling factors
    s          := 0.5 * (1.0 + vz);                           // CLTC sampling factors
    pdf        := sdiv(det * det * max(wh.z, 0.0), lensq * lensq * PI * s);
    return pdf;
}

diffuse_eon_spectrum :: (wo: Vector3, wi: Vector3, albedo: Spectrum, roughness: float) -> Spectrum
{
    assert(wi.z > 0.0);
    wo_dot_n  := wo.z;
    wi_dot_n  := wi.z;
    wo_dot_wi := dot(wo, wi);
    s         := wo_dot_wi - wi_dot_n * wo_dot_n;
    s_over_t  := ifx (s > 0.0) then (s / max(max(wi_dot_n, wo_dot_n), 1.0e-4)) else s; // FON s/t
    af        := 1.0 / (1.0 + FON1 * roughness);                             // FON A coeff
    f_ss      := (albedo / PI) * af * (1.0 + roughness * s_over_t);          // single-scatter
    efo       := e_fon_approx(wo_dot_n, roughness);                          // FON V albedo
    efi       := e_fon_approx(wi_dot_n, roughness);                          // FON L albedo
    avg_ef    := af * (1.0 + FON2 * roughness);                              // average albedo
    rho_ms    := (albedo * albedo) * avg_ef / (Vector3.{1, 1, 1} - albedo * (1.0 - avg_ef));
    eps       := 1.0e-6;
    f_ms      := (rho_ms / PI) * max(eps, 1.0 - efo) * max(eps, 1.0 - efi) / max(eps, 1.0 - avg_ef); // multi-scatterlobe
    f         := f_ss + f_ms;
    return f;
}

//------------------------------------------------------------------------
// Glossy Specular BSDF

#scope_export

evaluate_glossy_specular :: (using info: Glossy_Specular_Shading_Info, wo: Vector3, wi: Vector3) -> Spectrum
{
    if is_microfacet_alpha_delta(microfacet_alpha) return Spectrum_Zero;

    if wi.z > 0.0
    {
        wh           := normalize(wo + wi);
        wo_dot_n     := wo.z;
        wi_dot_n     := wi.z;
        dist         := microfacet_ggx_distribution(wh, microfacet_alpha);
        mask_shadow  := microfacet_ggx_mask_shadow(wo, wi, microfacet_alpha);
        radiance     := dist * mask_shadow / max(4 * wo_dot_n * wi_dot_n, 1.0e-6);
        wo_dot_wh    := dot(wo, wh);
        coefficients := calculate_glossy_specular_coefficients(info, wo_dot_wh);
        weight       := radiance * coefficients.reflect * wi.z;
        return weight;
    }
    else if wi.z < 0.0
    {
        wh               := refracted_normal(wo, wi, eta_t_over_eta_i_transparent);
        wo_dot_n         := wo.z;
        wi_dot_n         := -wi.z;
        wo_dot_wh        := dot(wo, wh);
        wi_dot_wh        := -dot(wi, wh);
        dist             := microfacet_ggx_distribution(wh, microfacet_alpha);
        mask_shadow      := microfacet_ggx_mask_shadow(wo, wi, microfacet_alpha);
        dwi_sqrt         := wi_dot_wh + wo_dot_wh / eta_t_over_eta_i_transparent;
        dwi              := dwi_sqrt * dwi_sqrt;
        wo_dot_wi_dot_wh := wo_dot_wh * wi_dot_wh;
        radiance         := (dist * mask_shadow * wo_dot_wi_dot_wh) / max(dwi * wi_dot_n * wo_dot_n, 1.0e-6);
        coefficients     := calculate_glossy_specular_coefficients(info, wo_dot_wh);
        weight           := radiance * coefficients.transmit * (-wi.z);
        return weight;
    }

    return Spectrum_Zero;
}

pdf_glossy_specular :: (using info: Glossy_Specular_Shading_Info, wo: Vector3, wi: Vector3) -> float
{
    if is_microfacet_alpha_delta(info.microfacet_alpha) return 0.0;

    if wi.z > 0.0
    {
        wh            := normalize(wo + wi);
        wo_dot_wh     := dot(wo, wh);
        probabilities := calculate_glossy_specular_probabilities(info, wo_dot_wh);
        wo_dot_n      := wo.z;
        dist          := microfacet_ggx_distribution(wh, microfacet_alpha);
        mask          := microfacet_ggx_mask(wo, microfacet_alpha);
        base_pdf      := dist * mask / max(4 * wo_dot_n, 1.0e-6);
        pdf           := probabilities.reflect * base_pdf;
        return pdf;
    }
    else if wi.z < 0.0
    {
        wh               := refracted_normal(wo, wi, eta_t_over_eta_i_transparent);
        wo_dot_wh        := dot(wo, wh);
        probabilities    := calculate_glossy_specular_probabilities(info, wo_dot_wh);
        dist             := microfacet_ggx_distribution(wh, microfacet_alpha);
        mask             := microfacet_ggx_mask(wo, microfacet_alpha);
        wo_dot_n         := wo.z;
        wi_dot_wh        := -dot(wi, wh);
        dwi_sqrt         := wi_dot_wh + wo_dot_wh / eta_t_over_eta_i_transparent;
        dwi              := dwi_sqrt * dwi_sqrt;
        wo_dot_wi_dot_wh := wo_dot_wh * wi_dot_wh;
        base_pdf         := (dist * mask * wo_dot_wi_dot_wh) / max(dwi * wo_dot_n, 1.0e-6);
        pdf              := probabilities.transmit * base_pdf;
        return pdf;
    }

    return 0.0;
}

sample_glossy_specular :: (using info: Glossy_Specular_Shading_Info, wo: Vector3, u: Vector3) -> Sample
{
    if !is_microfacet_alpha_delta(microfacet_alpha)
    {
        wh                          := microfacet_ggx_sample_vndf(wo, microfacet_alpha, u.x, u.y);
        wo_dot_wh                   := dot(wo, wh);
        coefficients, probabilities := calculate_glossy_specular_coefficients_and_probabilities(info, wo_dot_wh);

        if (probabilities.total <= FLOAT32_EPSILON)
            return make_zero_sample();

        if (u.z < probabilities.reflect)
        {
            wi := reflect(-wo, wh);
            if wi.z > 0.0
            {
                wo_dot_n     := wo.z;
                wi_dot_n     := wi.z;
                dist         := microfacet_ggx_distribution(wh, microfacet_alpha);
                mask_shadow  := microfacet_ggx_mask_shadow(wo, wi, microfacet_alpha);
                mask         := microfacet_ggx_mask(wo, microfacet_alpha);
                radiance     := mask_shadow / max(mask * wi_dot_n, 1.0e-6);
                base_pdf     := dist * mask / max(4 * wo_dot_n, 1.0e-6);

                weight       := coefficients.reflect * radiance * wi.z / probabilities.reflect;
                pdf          := probabilities.reflect * base_pdf;

                return make_sample(weight, pdf, wi, .REFLECTION | .GLOSSY);
            }
        }
        else
        {
            wi, refracted := refract(-wo, wh, eta_t_over_eta_i_transparent);
            if (refracted && wi.z < 0.0)
            {
                wo_dot_n         := wo.z;
                wi_dot_n         := -wi.z;
                wo_dot_wh        := dot(wo, wh);
                wi_dot_wh        := -dot(wi, wh);
                dist             := microfacet_ggx_distribution(wh, microfacet_alpha);
                mask_shadow      := microfacet_ggx_mask_shadow(wo, wi, microfacet_alpha);
                mask             := microfacet_ggx_mask(wo, microfacet_alpha);
                dwi_sqrt         := wi_dot_wh + wo_dot_wh / eta_t_over_eta_i_transparent;
                dwi              := dwi_sqrt * dwi_sqrt;
                wo_dot_wi_dot_wh := wo_dot_wh * wi_dot_wh;
                radiance         := mask_shadow / max(mask * wi_dot_n, 1.0e-6);
                base_pdf         := (dist * mask * wo_dot_wi_dot_wh) / max(dwi * wo_dot_n, 1.0e-6);

                weight           := coefficients.transmit * radiance * (-wi.z) / probabilities.transmit;
                pdf              := probabilities.transmit * base_pdf;

                return make_sample(weight, pdf, wi, .TRANSMISSION | .GLOSSY);
            }
        }
    }
    else
    {
        wh                          := Vector3.{0, 0, 1};
        wo_dot_wh                   := dot(wo, wh);
        coefficients, probabilities := calculate_glossy_specular_coefficients_and_probabilities(info, wo_dot_wh);

        if (probabilities.total <= FLOAT32_EPSILON)
            return make_zero_sample();

        if (u.z < probabilities.reflect)
        {
            wi     := reflect(-wo, wh);
            if wi.z > 0.0
            {
                weight := coefficients.reflect / probabilities.reflect;
                pdf    := probabilities.reflect;
                return make_sample(weight, pdf, wi, .REFLECTION | .SPECULAR);
            }
        }
        else
        {
            wi, refracted := refract(-wo, wh, eta_t_over_eta_i_transparent);
            if (refracted && wi.z < 0.0)
            {
                weight := coefficients.transmit / probabilities.transmit;
                pdf    := probabilities.transmit;
                return make_sample(weight, pdf, wi, .TRANSMISSION | .SPECULAR);
            }
        }
    }

    return make_zero_sample();
}

estimate_glossy_specular :: (using info: Glossy_Specular_Shading_Info, wo: Vector3) -> float
{
    // TODO: Use better estimate
    coefficients := calculate_glossy_specular_coefficients(info, wo.z);
    estimate     := max_spectrum(coefficients.reflect + coefficients.transmit);
    return estimate;
}

#scope_file

is_microfacet_alpha_delta :: (microfacet_alpha: Vector2) -> bool
{
    delta := max(microfacet_alpha.x, microfacet_alpha.y) < 1.0e-3;
    return delta;
}

Glossy_Specular_Coefficient :: struct
{
    reflect  : Spectrum;
    transmit : Spectrum;
}

Glossy_Specular_Probability :: struct
{
    reflect  : float;
    transmit : float;
    total    : float;
}

calculate_glossy_specular_coefficients :: (using info: Glossy_Specular_Shading_Info, wo_dot_wh: float) -> Glossy_Specular_Coefficient
{
    coefficients: Glossy_Specular_Coefficient;
    transparent_fresnel   := fresnel_dielectric(eta_t_over_eta_i_transparent, wo_dot_wh);
    coefficients.reflect  += transparent_dielectric_reflect_scale * transparent_fresnel;
    coefficients.transmit += transparent_dielectric_transmit_scale * (Spectrum_One - transparent_fresnel);
    coefficients.reflect  += opaque_dielectric_reflect_scale * fresnel_dielectric(eta_t_over_eta_i_opaque, wo_dot_wh);
    coefficients.reflect  += metal_scale * fresnel_metal(reflectance, edge_tint, falloff, wo_dot_wh);
    return coefficients;
}

calculate_glossy_specular_probabilities :: (coefficients: Glossy_Specular_Coefficient) -> Glossy_Specular_Probability
{
    probabilities: Glossy_Specular_Probability;
    probabilities.reflect   = max_spectrum(coefficients.reflect);
    probabilities.transmit  = max_spectrum(coefficients.transmit);
    total_probability      := probabilities.reflect + probabilities.transmit;
    if (total_probability > FLOAT32_EPSILON)
    {
        probabilities.reflect  /= total_probability;
        probabilities.transmit /= total_probability;
        probabilities.total     = 1.0;
    }
    else
    {
        probabilities.reflect  = 0.0;
        probabilities.transmit = 0.0;
        probabilities.total    = 0.0;
    }
    return probabilities;
}

calculate_glossy_specular_coefficients_and_probabilities :: (using info: Glossy_Specular_Shading_Info, wo_dot_wh: float) -> Glossy_Specular_Coefficient, Glossy_Specular_Probability
{
    coefficients  := calculate_glossy_specular_coefficients(info, wo_dot_wh);
    probabilities := calculate_glossy_specular_probabilities(coefficients);
    return coefficients, probabilities;
}

calculate_glossy_specular_probabilities :: (using info: Glossy_Specular_Shading_Info, wo_dot_wh: float) -> Glossy_Specular_Probability
{
    coefficients, probabilities := calculate_glossy_specular_coefficients_and_probabilities(info, wo_dot_wh);
    return probabilities;
}

//microfacet_is_delta :: (alpha: Vector2) -> bool// #deprecated
//{
//    return max(alpha.x, alpha.y) < 1.0e-4;
//}

//evaluate_metal :: (V: Vector3, L: Vector3, surface: Surface, transport: Transport) -> BSDF
//{
//    alpha := surface.microfacet_alpha;
//    if !microfacet_is_delta(alpha)
//    {
//        rough  := sqrt(sqrt(alpha.x * alpha.y));
//        E_avg  := average_energy_metal(rough);
//        F_avg  := fresnel_average_metal(surface.reflectance, surface.edge_tint, surface.falloff);

//        P_ss   := estimate_metal_single_scatter(E_avg, F_avg);
//        P_ms   := 1.0 - P_ss;

//        H      := normalize(V + L);
//        VoH    := dot(V, H);
//        spec   := evaluate_ggx_specular_reflect(V, L, H, alpha);
//        F_ss   := fresnel_metal(surface.reflectance, surface.edge_tint, surface.falloff, VoH);
//        f_ss   := F_ss * spec.f;
//        f_ms   := multi_scatter_compensation_metal(E_avg, F_avg, rough, V.z, L.z);
//        pdf_ms := pdf_cosine(L);
//        pdf_ss := spec.pdf;
//        f      := f_ss + f_ms;
//        pdf    := P_ss * pdf_ss + P_ms * pdf_ms;
//        return .{f, pdf};
//    }
//    return .{};
//}

//sample_metal :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> Sampled_BSDF
//{
//    alpha := surface.microfacet_alpha;
//    if !microfacet_is_delta(alpha)
//    {
//        rough := sqrt(sqrt(alpha.x * alpha.y));
//        E_avg := average_energy_metal(rough);
//        F_avg := fresnel_average_metal(surface.reflectance, surface.edge_tint, surface.falloff);

//        P_ss  := estimate_metal_single_scatter(E_avg, F_avg);
//        P_ms  := 1.0 - P_ss;

//        if (p < P_ss)
//        {
//            sample := sample_ggx_specular_reflect(V, alpha, u);
//            if (sample.wi.z > 0.0)
//            {
//                VoH    := dot(V, sample.H);
//                F_ss   := fresnel_metal(surface.reflectance, surface.edge_tint, surface.falloff, VoH);
//                f_ss   := F_ss * sample.weight.diffuse;
//                f_ms   := multi_scatter_compensation_metal(E_avg, F_avg, rough, V.z, sample.wi.z);
//                pdf_ms := pdf_cosine(sample.wi);
//                pdf_ss := sample.pdf;
//                f      := f_ss + f_ms;
//                pdf    := P_ss * pdf_ss + P_ms * pdf_ms;
//                //return sampled_bsdf(f, pdf, sample.wi, ._REFLECTION | ._GLOSSY);
//                return .{};
//            }
//        }
//        else
//        {
//            L      := sample_cosine(u.x, u.y);
//            H      := normalize(V + L);
//            VoH    := dot(V, H);
//            F_ss   := fresnel_metal(surface.reflectance, surface.edge_tint, surface.falloff, VoH);
//            spec   := evaluate_ggx_specular_reflect(V, L, H, alpha);
//            f_ss   := F_ss * spec.f;
//            f_ms   := multi_scatter_compensation_metal(E_avg, F_avg, rough, V.z, L.z);
//            pdf_ms := pdf_cosine(L);
//            pdf_ss := spec.pdf;
//            f      := f_ss + f_ms;
//            pdf    := P_ss * pdf_ss + P_ms * pdf_ms;
//            //return sampled_bsdf(f, pdf, L, ._REFLECTION | ._DIFFUSE);
//            return .{};
//        }
//    }
//    else
//    {
//        L   := Vector3.{-V.x, -V.y, V.z};
//        pdf := 1.0;
//        mu  := L.z;
//        f   := fresnel_metal(surface.reflectance, surface.edge_tint, surface.falloff, mu) / max(mu, 1.0e-6);
//        //return sampled_bsdf(f, pdf, L, ._REFLECTION | ._SPECULAR);
//        return .{};
//    }
//    return .{};
//}

//#scope_file

//average_energy_metal :: (rough: float) -> float
//{
//    E_avg := read_table_1D(metal_E_avg, METAL_E_SIZE, rough);
//    return E_avg;
//}

//estimate_metal_single_scatter :: (E_avg: float, F_avg: Spectrum) -> float
//{
//    f := E_avg * F_avg;
//    return max(f.x, f.y, f.z);
//}

//multi_scatter_compensation_metal :: (E_avg: float, F_avg: Spectrum, rough: float, NoV: float, NoL: float) -> Spectrum
//{
//    // Based on: https://blog.selfshadow.com/publications/s2017-shading-course/imageworks/s2017_pbs_imageworks_slides_v2.pdf
//    if (E_avg < 1.0)
//    {
//        E_l   := read_table_2D(metal_E, METAL_E_SIZE, METAL_E_SIZE, rough, NoL);
//        E_v   := read_table_2D(metal_E, METAL_E_SIZE, METAL_E_SIZE, rough, NoV);
//        f_ms  := (1.0 - E_l) * (1.0 - E_v) / (PI * (1.0 - E_avg));

//        // Fresnel adjustment is done based on the following blog:
//        // https://blog.selfshadow.com/2018/06/04/multi-faceted-part-2/
//        F_ms  := F_avg * F_avg  * E_avg / (Spectrum_One - F_avg * (1.0 - E_avg));

//        return F_ms * f_ms;
//    }
//    return Spectrum_Zero;
//}

////------------------------------------------------------------------------
//// Glossy Diffuse

//evaluate_glossy_diffuse :: (V: Vector3, L: Vector3, surface: Surface, transport: Transport) -> BSDF
//{
//    alpha    := surface.microfacet_alpha;
//    ior      := effective_specular_ior(surface.specular_weight, surface.specular_ior);

//    if ior == 1 || microfacet_is_delta(alpha)
//    {
//        P_s     := fresnel_average_dielectric(ior);
//        P_d     := 1.0 - P_s;
//        H       := normalize(V + L);
//        VoH     := dot(V, H);
//        F       := fresnel_dielectric(ior, VoH);
//        diffuse := evaluate_diffuse(V, L, .{surface.color, surface.diffuse_roughness});
//        f       := F * Spectrum_One + (1.0 - F) * diffuse;
//        //pdf     := P_s + P_d * diffuse.pdf;
//        pdf := 0.0;
//        return .{f, pdf};
//    }
//    else
//    {
//        rough         := sqrt(sqrt(alpha.x * alpha.y));
//        physical_ior  := max(ior, 1.0 / ior);
//        param_ior     := ior_inverse_parametrization(physical_ior);
//        E_avg         := average_energy_glossy_diffuse_specular(ior, rough, param_ior);
//        P_s           := lerp(0.5, 0.95, E_avg);
//        P_d           := 1.0 - P_s;
        
//        H             := normalize(V + L);
//        VoH           := dot(V, H);
//        F             := fresnel_dielectric(ior, VoH);
//        specular      := evaluate_ggx_specular_reflect(V, L, H, alpha);
//        diffuse       := evaluate_diffuse(V, L, .{surface.color, surface.diffuse_roughness});
//        E_diffuse     := multi_scatter_glossy_diffuse_compensation(ior, E_avg, rough, V.z, L.z, param_ior);
//        f             := F * specular.f + E_diffuse * diffuse;
//        //pdf           := P_s * specular.pdf + P_d * diffuse.pdf;
//        pdf := 0.0;
//        return .{f, pdf};
//    }
//    return .{};
//}

//sample_glossy_diffuse :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> Sampled_BSDF
//{
//    alpha    := surface.microfacet_alpha;
//    ior      := effective_specular_ior(surface.specular_weight, surface.specular_ior);

//    if ior == 1 || microfacet_is_delta(alpha)
//    {
//        P_s := fresnel_average_dielectric(ior);
//        P_d := 1.0 - P_s;

//        if (p < P_s)
//        {
//            H       := Vector3.{0, 0, 1};
//            L       := reflect(-V, H);
//            VoH     := dot(V, H);
//            F       := fresnel_dielectric(ior, VoH);
//            diffuse := evaluate_diffuse(V, L, .{surface.color, surface.diffuse_roughness});
//            f       := F * Spectrum_One / max(L.z, 1.0e-6) + (1.0 - F) * diffuse;
//            //pdf     := P_s + P_d * diffuse.pdf;
//            //return sampled_bsdf(f, pdf, L, ._REFLECTION | ._DIFFUSE);
//            return .{};
//        }
//        else
//        {
//            p        = (p - P_s) / P_d;
//            diffuse := sample_diffuse(V, .{surface.color, surface.diffuse_roughness}, p, u);
//            //L       := diffuse.L;
//            //H       := normalize(V + L);
//            //VoH     := dot(V, H);
//            //F       := fresnel_dielectric(ior, VoH);
//            //f       := (1.0 - F) * diffuse.f;
//            //pdf     := P_d * diffuse.pdf;
//            //return sampled_bsdf(f, pdf, L, ._REFLECTION | ._DIFFUSE);
//            return .{};
//        }
//    }
//    else
//    {
//        rough         := sqrt(sqrt(alpha.x * alpha.y));
//        physical_ior  := max(ior, 1.0 / ior);
//        param_ior     := ior_inverse_parametrization(physical_ior);
//        E_avg         := average_energy_glossy_diffuse_specular(ior, rough, param_ior);
//        P_s           := lerp(0.5, 0.95, E_avg);
//        P_d           := 1.0 - P_s;

//        if (p < P_s)
//        {
//            specular := sample_ggx_specular_reflect(V, alpha, u);
//            L         := specular.L;
//            if (L.z > 0.0)
//            {
//                H         := specular.H;
//                VoH       := dot(V, H);
//                F         := fresnel_dielectric(ior, VoH);
//                diffuse   := evaluate_diffuse(V, L, surface, .RADIANCE);
//                E_diffuse := multi_scatter_glossy_diffuse_compensation(ior, E_avg, rough, V.z, L.z, param_ior);
//                f         := F * specular.f + E_diffuse * diffuse.f;
//                pdf       := P_s * specular.pdf + P_d * diffuse.pdf;
//                return sampled_bsdf(f, pdf, L, ._REFLECTION | ._GLOSSY);
//            }
//        }
//        else
//        {
//            p          = (p - P_s) / P_d;
//            diffuse   := sample_diffuse(V, surface, p, u);
//            L         := diffuse.L;
//            H         := normalize(V + L);
//            VoH       := dot(V, H);
//            F         := fresnel_dielectric(ior, VoH);
//            specular  := evaluate_ggx_specular_reflect(V, L, H, alpha);
//            E_diffuse := multi_scatter_glossy_diffuse_compensation(ior, E_avg, rough, V.z, L.z, param_ior);
//            f         := F * specular.f + E_diffuse * diffuse.f;
//            pdf       := P_s * specular.pdf + P_d * diffuse.pdf;
//            return sampled_bsdf(f, pdf, L, ._REFLECTION | ._DIFFUSE);
//        }
//    }

//    return .{};
//}

//#scope_file

//effective_specular_ior :: (specular_weight: float, specular_ior: float) -> float
//{
//    sgn :: x => ((0.0 < x).(float) - (x < 0.0).(float));
//    F_sqrt    := (1.0 - specular_ior) / (1.0 + specular_ior);
//    e         := sgn(specular_ior - 1.0) * sqrt(specular_weight * F_sqrt * F_sqrt);
//    effective := (1.0 + e) / (1 - e);
//    return effective;
//}

//average_energy_glossy_diffuse_specular :: (specular_ior: float, rough: float, param_ior: float) -> float
//{
//    E_avg_table := ifx specular_ior >= 1.0 then dielectric_E_avg else dielectric_inv_E_avg;
//    E_avg       := read_table_2D(E_avg_table, DIELECTRIC_E_AVG_SIZE, DIELECTRIC_E_AVG_SIZE, rough, param_ior);
//    return E_avg;
//}

//multi_scatter_glossy_diffuse_compensation :: (specular_ior: float, E_avg: float, rough: float, NoV: float, NoL: float, param_ior: float) -> float
//{
//    // Based on: https://blog.selfshadow.com/publications/s2017-shading-course/imageworks/s2017_pbs_imageworks_slides_v2.pdf
//    if (E_avg < 1.0)
//    {
//        E_table   := ifx specular_ior >= 1.0 then dielectric_E else dielectric_inv_E;
//        E_l       := read_table_3D(E_table, DIELECTRIC_E_SIZE, DIELECTRIC_E_SIZE, DIELECTRIC_E_SIZE, rough, NoL, param_ior);
//        E_v       := read_table_3D(E_table, DIELECTRIC_E_SIZE, DIELECTRIC_E_SIZE, DIELECTRIC_E_SIZE, rough, NoV, param_ior);
//        E_diffuse := (1.0 - E_l) * (1.0 - E_v) / (1.0 - E_avg);
//        return E_diffuse;
//    }
//    return 0.0;
//}

////------------------------------------------------------------------------
//// Dielectric Translucent

//evaluate_dielectric :: (V: Vector3, L: Vector3, surface: Surface, transport: Transport) -> BSDF
//{
//    alpha := surface.microfacet_alpha;
//    ior   := surface.specular_ior;

//    if ior != 1.0 && !microfacet_is_delta(alpha)
//    {
//        if (L.z > 0.0)
//        {
//            H    := normalize(V + L);
//            VoH  := dot(V, H);
//            F    := fresnel_dielectric(ior, VoH);
//            brdf := evaluate_ggx_specular_reflect(V, L, H, alpha);
//            f    := F * surface.edge_tint * brdf.f;
//            pdf  := F * brdf.pdf;
//            return .{f, pdf};
//        }
//        else if (L.z < 0.0)
//        {
//            H    := refracted_normal(V, L, ior);
//            VoH  := dot(V, H);
//            F    := fresnel_dielectric(ior, VoH);
//            btdf := evaluate_ggx_specular_refract(V, L, H, alpha, ior);
//            f    := (1.0 - F) * btdf.f / (ior * ior);
//            pdf  := (1.0 - F) * btdf.pdf;
//            return .{f, pdf};
//        }
//    }
//    return .{};
//}

//sample_dielectric :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> Sampled_BSDF
//{
//    alpha := surface.microfacet_alpha;
//    ior   := surface.specular_ior;

//    if ior == 1 || microfacet_is_delta(alpha)
//    {
//        H := Vector3.{0, 0, 1};
//        F := fresnel_dielectric(ior, dot(V, H));

//        if (p >= F)
//        {
//            L, refracted := refract(-V, H, ior);
//            if (refracted)
//            {
//                f   := (1.0 - F) * Spectrum_One / max(ior * ior * abs(L.z), 1.0e-6);
//                pdf := 1.0 - F;
//                return sampled_bsdf(f, pdf, L, ._TRANSMISSION | ._GLOSSY);
//            }
//            else
//            {
//                F = 1.0;
//            }
//        }

//        L := reflect(-V, H);
//        if (L.z > 0.0)
//        {
//            f    := F * Spectrum_One / max(L.z, 1.0e-6);
//            pdf  := F;
//            return sampled_bsdf(f, pdf, L, ._REFLECTION | ._SPECULAR);
//        }
//    }
//    else
//    {
//        L, H : Vector3;

//        do_reflection := true;

//        rough := sqrt(sqrt(alpha.x * alpha.y));
//        P_ss  := estimate_dielectric_single_scatter(rough, ior);
//        P_ms  := 1.0 - P_ss;
//        F_ss  := 0.0;
//        F_ms  := fresnel_average_dielectric(ior);

//        if (p < P_ss)
//        {
//            //print("ggx!?\n");
//            p    = p / P_ss;
//            H    = microfacet_ggx_sample_vndf(V, alpha, u.x, u.y);
//            F_ss = fresnel_dielectric(ior, dot(V, H));

//            if (p >= F_ss)
//            {
//                refracted: bool;
//                L, refracted = refract(-V, H, ior);
//                if (refracted)
//                {
//                    do_reflection = false;
//                }
//                else
//                {
//                    F_ss = 1.0;
//                    L    = reflect(-V, H);
//                }
//            }
//            else
//            {
//                L = reflect(-V, H);
//            }
//        }
//        else
//        {
//            L = sample_cosine(u.x, u.y);
//            p = (p - P_ss) / P_ms;

//            if (p < F_ms)
//            {
//                H = normalize(V + L);
//            }
//            else
//            {
//                L.z       = -L.z;
//                H         = refracted_normal(V, L, ior);
//                do_reflection = false;
//            }

//            F_ss = fresnel_dielectric(ior, dot(V, H));
//        }

//        f_ms  := multi_scatter_dielectric_contribution(do_reflection, rough, V.z, abs(L.z), ior);

//        if (do_reflection && L.z > 0.0)
//        {
//            brdf   := evaluate_ggx_specular_reflect(V, L, H, alpha);
//            f_ss   := F_ss * brdf.f;
//            pdf_ss := F_ss * brdf.pdf;
//            pdf_ms := F_ms * pdf_cosine(L);
//            f      := f_ms + f_ss;
//            pdf    := P_ss * pdf_ss + P_ms * pdf_ms;
//            return sampled_bsdf(f, pdf, L, ._REFLECTION | ._GLOSSY);
//        }
//        else if (!do_reflection && L.z < 0.0)
//        {
//            //print("transmission!?\n");
//            btdf   := evaluate_ggx_specular_refract(V, L, H, alpha, ior);
//            f_ss   := (1.0 - F_ss) * btdf.f / (ior * ior);
//            pdf_ss := (1.0 - F_ss) * btdf.pdf;
//            pdf_ms := (1.0 - F_ms) * pdf_cosine(L);
//            f      := f_ms + f_ss;
//            pdf    := P_ss * pdf_ss + P_ms * pdf_ms;
//            return sampled_bsdf(f, pdf, L, ._TRANSMISSION | ._GLOSSY);
//        }
//    }
//    return .{};
//}

//#scope_file

refracted_normal :: inline (wo: Vector3, wi: Vector3, eta_t_over_eta_i: float) -> Vector3
{
    wh := normalize(wo + eta_t_over_eta_i * wi);
    if (wh.z < 0.0)
    {
        wh = -wh;
    }
    return wh;
}

//estimate_dielectric_single_scatter :: (rough: float, ior: float) -> float
//{
//    //return 0.0;
//    E_avg_table  := dielectric_full_E_avg;
//    physical_ior := ior;
//    if (ior < 1.0)
//    {
//        E_avg_table  = dielectric_full_inv_E_avg;
//        physical_ior = 1.0 / ior;
//    }
//    param_ior := ior_inverse_parametrization(physical_ior);
//    E_avg     := read_table_2D(E_avg_table, DIELECTRIC_FULL_E_AVG_SIZE, DIELECTRIC_FULL_E_AVG_SIZE, rough, param_ior);
//    return E_avg;
//}

//multi_scatter_dielectric_contribution :: (do_reflection: bool, rough: float, NoV: float, NoL: float, ior: float) -> Spectrum
//{
//    ior_1        := ior;
//    ior_2        := 1.0 / ior_1;
//    physical_ior := max(ior_1, ior_2);
//    param_ior    := ior_inverse_parametrization(physical_ior);

//    E_table_1, E_table_2: []float;
//    E_avg_1, E_avg_2: float;

//    if (ior >= 1.0)
//    {
//        E_table_1 = dielectric_full_E;
//        E_table_2 = dielectric_full_inv_E;
//        E_avg_1   = read_table_2D(dielectric_full_E_avg, DIELECTRIC_FULL_E_AVG_SIZE, DIELECTRIC_FULL_E_AVG_SIZE, rough, param_ior);
//        E_avg_2   = read_table_2D(dielectric_full_inv_E_avg, DIELECTRIC_FULL_E_AVG_SIZE, DIELECTRIC_FULL_E_AVG_SIZE, rough, param_ior);
//    }
//    else
//    {
//        E_table_1 = dielectric_full_inv_E;
//        E_table_2 = dielectric_full_E;
//        E_avg_1   = read_table_2D(dielectric_full_inv_E_avg, DIELECTRIC_FULL_E_AVG_SIZE, DIELECTRIC_FULL_E_AVG_SIZE, rough, param_ior);
//        E_avg_2   = read_table_2D(dielectric_full_E_avg, DIELECTRIC_FULL_E_AVG_SIZE, DIELECTRIC_FULL_E_AVG_SIZE, rough, param_ior);
//    }

//  //  print("%, %\n", E_avg_1, E_avg_2);

//  //  return .{E_avg_1, E_avg_1, E_avg_1};

//    F_1 := fresnel_average_dielectric(ior_1);
//    F_2 := fresnel_average_dielectric(ior_2);

//    num       := (1.0 - F_2) * (1.0 - E_avg_2) * ior_1 * ior_1;
//    den       := (1.0 - F_1) * (1.0 - E_avg_1) + num;
//    ratio     := num / den;

//    //ratio = 1.0;//nocheckin

//    E_table_v := E_table_1;
//    E_table_l := E_table_1;
//    E_avg_l   := E_avg_1;

//    if (!do_reflection)
//    {
//        ratio     = 1.0 - ratio;
//        E_table_l = E_table_2;
//        E_avg_l   = E_avg_2;
//    }

//    if (E_avg_l < 1.0)
//    {
//        //print("E_avg: %\n", E_avg_l);
//        E_v   := read_table_3D(E_table_v, DIELECTRIC_FULL_E_SIZE, DIELECTRIC_FULL_E_SIZE, DIELECTRIC_FULL_E_SIZE, rough, NoV, param_ior);
//        E_l   := read_table_3D(E_table_l, DIELECTRIC_FULL_E_SIZE, DIELECTRIC_FULL_E_SIZE, DIELECTRIC_FULL_E_SIZE, rough, NoL, param_ior);
//        f_ms  := ratio * (1.0 - E_v) * (1.0 - E_l) / (PI * (1.0 - E_avg_l));
//        //print("f_ms: %\n", f_ms);
//        return Spectrum.{f_ms, f_ms, f_ms};
//    }

//    return Spectrum_Zero;
//}

////------------------------------------------------------------------------
//// Geometry Transmission BTDF

//evaluate_ambient :: (V: Vector3, L: Vector3, surface: Surface, transport: Transport) -> BSDF
//{
//    return .{};
//}

//sample_ambient :: (V: Vector3, surface: Surface, p: float, u: Vector2) -> Sampled_BSDF
//{
//    L   := -V;
//    mu  := abs(L.z);
//    f   := Spectrum_Zero;
//    if (mu > 0.0)
//    {
//        f = Spectrum_One / mu;
//    }
//    pdf := 1.0;
//    return .{};
//    //return .{f.weight.diffuse, pdf, L, ._TRANSMISSION};
//}

////------------------------------------------------------------------------
//// Principled BSDF

#scope_export

//evaluate_principled_bsdf :: (V: Vector3, L: Vector3, surface: Surface) -> BSDF
//{
//    weights := calculate_lobe_weights(surface);
//    bsdf    : BSDF;
//    for 0..MAX_LOBE_TYPES-1
//    {
//        index    := it.(Lobe_Type);
//        bxdf     := evaluate_principled_lobe(V, L, surface, index);
//        bsdf.f   += weights[it] * bxdf.f;
//        bsdf.pdf += weights[it] * bxdf.pdf;
//    }
//    return bsdf;
//}

prepare_surface :: (surface: Surface, wo: Vector3) -> Shading_Context
{
    //------------------------------------------------------------------------
    // Lobe radiance contribution
    metallic                := surface.metallic;
    dielectric              := 1.0 - metallic;
    opaque                  := 1.0 - surface.transmission_weight;
    opaque_dielectric       := opaque * dielectric;
    transparent_dielectric  := surface.transmission_weight * dielectric;

    //------------------------------------------------------------------------
    // Surface info initialization

    eta_t_over_eta_i_transparent := surface.specular_ior;
    eta_t_over_eta_i_opaque      := calculate_specular_ior_for_dielectric_opaque(surface.specular_weight, surface.specular_ior);

    ctx: Shading_Context;
    ctx.diffuse.albedo           = surface.color * opaque_dielectric;
    ctx.diffuse.roughness        = surface.diffuse_roughness;
    ctx.diffuse.eta_t_over_eta_i = eta_t_over_eta_i_opaque;

    ctx.glossy_specular.microfacet_alpha                      = surface.microfacet_alpha;
    ctx.glossy_specular.transparent_dielectric_reflect_scale  = transparent_dielectric;
    ctx.glossy_specular.transparent_dielectric_transmit_scale = transparent_dielectric;
    ctx.glossy_specular.opaque_dielectric_reflect_scale       = opaque_dielectric;
    ctx.glossy_specular.eta_t_over_eta_i_transparent          = eta_t_over_eta_i_transparent;
    ctx.glossy_specular.eta_t_over_eta_i_opaque               = eta_t_over_eta_i_opaque;

    ctx.glossy_specular.metal_scale                           = metallic;
    ctx.glossy_specular.reflectance                           = surface.reflectance;
    ctx.glossy_specular.falloff                               = surface.falloff;

    // TODO: Only do this for Transport == .RADIANCE
    ctx.glossy_specular.transparent_dielectric_transmit_scale /= (eta_t_over_eta_i_transparent * eta_t_over_eta_i_transparent);

    ctx.microfacet_alpha    = surface.microfacet_alpha;
    ctx.dielectric_reflect  = dielectric;
    ctx.dielectric_transmit = transparent_dielectric;
    ctx.metallic            = surface.metallic;
    ctx.reflectance         = surface.reflectance;
    ctx.edge_tint           = surface.edge_tint;
    ctx.falloff             = surface.falloff;
    ctx.wo                  = wo;

    //------------------------------------------------------------------------
    // Lobe PDF Weights

    ctx.weights[Lobe_Index.DIFFUSE]         = estimate_diffuse(ctx.diffuse, wo);
    ctx.weights[Lobe_Index.GLOSSY_SPECULAR] = estimate_glossy_specular(ctx.glossy_specular, wo);

    ctx.total_weight = 0.0;
    for ctx.weights
    {
        ctx.total_weight += it;
    }

    return ctx;
}

sample_surface :: (using ctx: Shading_Context, u: Vector3) -> Sample
{
    if (ctx.total_weight <= FLOAT32_EPSILON)
        return make_zero_sample();

    lobe   := pick_lobe(ctx, clamp_random_number(u.z));
    sample := sample_lobe(info, wo, .{u.x, u.y, lobe.remapped_p}, lobe.index);

    if !sample.lobe_type return make_zero_sample();

    if !(sample.lobe_type & .SPECULAR)
    {
        radiance := sample.weight * sample.pdf;
        pdf      := sample.pdf * weights[lobe.index];
    
        for 0..LOBE_COUNT-1
        {
            index := it.(Lobe_Index);
            if (index != lobe.index)
            {
                lobe_pdf := pdf_lobe(info, wo, sample.wi, index);
                if lobe_pdf > 0.0
                {
                    radiance += evaluate_lobe(info, wo, sample.wi, index);
                    pdf += weights[index] * lobe_pdf;
                }
            }
        }

        sample.pdf    = pdf / ctx.total_weight;
        sample.weight = radiance / sample.pdf;
    }
    else
    {
        sample.weight *= ctx.total_weight / ctx.weights[lobe.index];
    }

    return sample;
}

#scope_file

calculate_specular_ior_for_dielectric_opaque :: (specular_weight: float, eta_t_over_eta_i: float) -> float
{
    sgn :: x => ((0.0 < x).(float) - (x < 0.0).(float));
    f_sqrt    := (1.0 - eta_t_over_eta_i) / (1.0 + eta_t_over_eta_i);
    e         := sgn(eta_t_over_eta_i - 1.0) * sqrt(specular_weight * f_sqrt * f_sqrt);
    effective := (1.0 + e) / (1 - e);
    return effective;
}

Lobe_Info :: struct
{
    index      : Lobe_Index;
    remapped_p : float;
}

pick_lobe :: (ctx: Shading_Context, p: float) -> Lobe_Info
{
    p *= ctx.total_weight;
    weights_so_far := 0.0;
    for 0..LOBE_COUNT-2
    {
        it_lobe_weight := ctx.weights[it];
        if (p < weights_so_far + it_lobe_weight)
        {
            remapped_p := clamp_random_number((p - weights_so_far) / it_lobe_weight);
            return .{it.(Lobe_Index), remapped_p};
        }
        weights_so_far += it_lobe_weight;
    }
    last        := LOBE_COUNT - 1;
    last_weight := ctx.weights[last];
    remapped_p  := clamp_random_number((p - weights_so_far) / last_weight);
    return .{last.(Lobe_Index), FLOAT32_ONE_MINUS_EPSILON};
}

evaluate_lobe :: (info: Shading_Info, wo: Vector3, wi: Vector3, index: Lobe_Index) -> Spectrum
{
    if #complete index ==
    {
        case .DIFFUSE;
            return evaluate_diffuse(info.diffuse, wo, wi);
        case .GLOSSY_SPECULAR;
            return evaluate_glossy_specular(info.glossy_specular, wo, wi);
    }
    return Spectrum_Zero;
}

pdf_lobe :: (info: Shading_Info, wo: Vector3, wi: Vector3, index: Lobe_Index) -> float
{
    if #complete index ==
    {
        case .DIFFUSE;
            return pdf_diffuse(info.diffuse, wo, wi);
        case .GLOSSY_SPECULAR;
            return pdf_glossy_specular(info.glossy_specular, wo, wi);
    }
    return 0.0;
}

sample_lobe :: (info: Shading_Info, wo: Vector3, u: Vector3, index: Lobe_Index) -> Sample
{
    if #complete index ==
    {
        case .DIFFUSE;
            return sample_diffuse(info.diffuse, wo, u);
        case .GLOSSY_SPECULAR;
            return sample_glossy_specular(info.glossy_specular, wo, u);
    }
    return .{};
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

#load "ms_tables.jai";


FLOAT32_EPSILON :: 0h34000000;
FLOAT32_ONE_MINUS_EPSILON :: 0h3F7FFFFF;

clamp_random_number :: (p: float) -> float
{
    return min(p, FLOAT32_ONE_MINUS_EPSILON);
}

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
