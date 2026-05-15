#scope_export

LOBE_COUNT :: #run type_info(Lobe_Index).values.count;

prepare_surface :: (surface: Surface, wo: Vector3) -> Shading_Context
{
    if (wo.z <= 0.0)
    {
        return .{};
    }

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
    isotropic_alpha              := microfacet_isotropic_alpha(surface.specular_roughness, true);

    ctx: Shading_Context;
    ctx.diffuse.albedo                              = surface.color * opaque_dielectric;
    ctx.diffuse.roughness                           = surface.diffuse_roughness;
    ctx.diffuse.specular_eta_t_over_eta_i           = eta_t_over_eta_i_opaque;
    ctx.diffuse.specular_microfacet_alpha           = isotropic_alpha;
    ctx.diffuse.specular_energy_complement_wo_dot_n = read_dielectric_opaque_energy_complement(isotropic_alpha, wo.z, eta_t_over_eta_i_opaque);
    ctx.diffuse.specular_avg_energy_complement      = read_dielectric_opaque_average_energy_complement(isotropic_alpha, eta_t_over_eta_i_opaque);

    ctx.glossy_specular.microfacet_alpha                      = microfacet_anisotropic_alpha(surface.specular_roughness, surface.specular_anisotropic, true);
    ctx.glossy_specular.transparent_dielectric_reflect_scale  = transparent_dielectric;
    ctx.glossy_specular.transparent_dielectric_transmit_scale = transparent_dielectric;
    ctx.glossy_specular.opaque_dielectric_reflect_scale       = opaque_dielectric;
    ctx.glossy_specular.eta_t_over_eta_i_transparent          = eta_t_over_eta_i_transparent;
    ctx.glossy_specular.eta_t_over_eta_i_opaque               = eta_t_over_eta_i_opaque;

    ctx.glossy_specular.metal_scale                           = metallic;
    ctx.glossy_specular.reflectance                           = surface.reflectance;
    ctx.glossy_specular.falloff                               = surface.falloff;

    ctx.multi_scatter_metal.microfacet_alpha           = isotropic_alpha;
    ctx.multi_scatter_metal.average_energy_complement  = 0.0;
    ctx.multi_scatter_metal.energy_complement_wo_dot_n = 0.0;
    ctx.multi_scatter_metal.scale                      = Spectrum_Zero;

    if has_visible_energy_loss(ctx.multi_scatter_metal.microfacet_alpha)
    {
        ctx.multi_scatter_metal.average_energy_complement  = read_metal_average_energy_complement(ctx.multi_scatter_metal.microfacet_alpha);
        ctx.multi_scatter_metal.energy_complement_wo_dot_n = read_metal_energy_complement(ctx.multi_scatter_metal.microfacet_alpha, wo.z);

        // Fresnel adjustment is done based on the following blog:
        // https://blog.selfshadow.com/2018/06/04/multi-faceted-part-2/
        avg_energy                    := 1.0 - ctx.multi_scatter_metal.average_energy_complement;
        avg_fresnel                   := fresnel_average_metal(surface.reflectance, surface.edge_tint, surface.falloff);
        scale_num                     := metallic * avg_fresnel * avg_fresnel * avg_energy;
        scale_den                     := Spectrum_One - avg_fresnel * ctx.multi_scatter_metal.average_energy_complement;
        ctx.multi_scatter_metal.scale  = scale_num / max(scale_den, make_spectrum(1.0e-6));
    }

    ctx.wo = wo;

    //------------------------------------------------------------------------
    // Lobe PDF Weights

    for 0..LOBE_COUNT-1
    {
        ctx.weights[it] = estimate_lobe(ctx.info, wo, it.(Lobe_Index));
    }

    ctx.total_weight = 0.0;
    for ctx.weights
    {
        ctx.total_weight += it;
    }

    return ctx;
}

sample_surface :: (using ctx: Shading_Context, u_sample: Vector3) -> Sample
{
    if (ctx.total_weight <= FLOAT32_EPSILON)
        return make_zero_sample();

    u      := clamp_random_sample(u_sample);
    lobe   := pick_lobe(ctx, u.z);
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

        sample.pdf = pdf / ctx.total_weight;
        sample.weight = radiance / sample.pdf;
    }
    else
    {
        sample.weight *= ctx.total_weight / ctx.weights[lobe.index];
    }

    return sample;
}

#scope_file

Lobe_Index :: enum u32
{
    DIFFUSE             :: 0;
    GLOSSY_SPECULAR     :: 1;
    MULTI_SCATTER_METAL :: 2;
}

Lobe_Info :: struct
{
    index      : Lobe_Index;
    remapped_p : float;
}

calculate_specular_ior_for_dielectric_opaque :: (specular_weight: float, eta_t_over_eta_i: float) -> float
{
    sgn :: x => ((0.0 < x).(float) - (x < 0.0).(float));
    f_sqrt    := (1.0 - eta_t_over_eta_i) / (1.0 + eta_t_over_eta_i);
    e         := sgn(eta_t_over_eta_i - 1.0) * sqrt(specular_weight * f_sqrt * f_sqrt);
    effective := (1.0 + e) / (1 - e);
    return effective;
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
        case .MULTI_SCATTER_METAL;
            return evaluate_multi_scatter_metal(info.multi_scatter_metal, wo, wi);
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
        case .MULTI_SCATTER_METAL;
            return pdf_multi_scatter_metal(info.multi_scatter_metal, wo, wi);
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
        case .MULTI_SCATTER_METAL;
            return sample_multi_scatter_metal(info.multi_scatter_metal, wo, u);
    }
    return .{};
}

estimate_lobe :: (info: Shading_Info, wo: Vector3, index: Lobe_Index) -> float
{
    if #complete index ==
    {
        case .DIFFUSE;
            return estimate_diffuse(info.diffuse, wo);
        case .GLOSSY_SPECULAR;
            return estimate_glossy_specular(info.glossy_specular, wo);
        case .MULTI_SCATTER_METAL;
            return estimate_multi_scatter_metal(info.multi_scatter_metal, wo);
    }
    return 0.0;
}

//------------------------------------------------------------------------
// Diffuse EON BxDF

// EON: A practical energy-preserving rough diffuse BRDF
// https://arxiv.org/pdf/2410.18026

#scope_module

evaluate_diffuse :: (using info: Diffuse_Shading_Info, wo: Vector3, wi: Vector3) -> Spectrum
{
    if wi.z > 0.0
    {
        wh        := normalize(wo + wi);
        scale     := calculate_diffuse_contribution_scale(info, wi);
        f         := diffuse_eon_spectrum(wo, wi, albedo, roughness);
        weight    := scale * f * wi.z;
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
        wh     := normalize(wo + wi);
        scale  := calculate_diffuse_contribution_scale(info, wi);
        f      := diffuse_eon_spectrum(wo, wi, albedo, roughness);
        pdf_u  := pdf_uniform_hemisphere();
        pdf    := p_u * pdf_u + p_c * pdf_c; // MIS PDF of wi
        weight := scale * f * wi.z / pdf;
        return make_sample(weight, pdf, wi, .REFLECTION | .DIFFUSE);
    }

    return make_zero_sample();
}

estimate_diffuse :: (using info: Diffuse_Shading_Info, wo: Vector3) -> float
{
    estimate := specular_energy_complement_wo_dot_n / specular_avg_energy_complement * max_spectrum(albedo);
    return estimate;
}

#scope_file

calculate_diffuse_contribution_scale :: (using info: Diffuse_Shading_Info, wi: Vector3) -> float
{
    if (specular_avg_energy_complement > 0.0)
    {
        specular_energy_complement_wi_dot_n := read_dielectric_opaque_energy_complement(specular_microfacet_alpha, wi.z, specular_eta_t_over_eta_i);
        scale                               := specular_energy_complement_wo_dot_n * specular_energy_complement_wi_dot_n / specular_avg_energy_complement;
        return scale;
    }
    return 0.0;
}

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

#scope_module

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
        // TODO: Only do this for Transport == .RADIANCE
        weight /= (eta_t_over_eta_i_transparent * eta_t_over_eta_i_transparent);
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
                return make_sample(weight, 1.0, wi, .REFLECTION | .SPECULAR);
            }
        }
        else
        {
            wi, refracted := refract(-wo, wh, eta_t_over_eta_i_transparent);
            if (refracted && wi.z < 0.0)
            {
                weight := coefficients.transmit / probabilities.transmit;
                // TODO: Only do this for Transport == .RADIANCE
                weight /= (eta_t_over_eta_i_transparent * eta_t_over_eta_i_transparent);
                return make_sample(weight, 1.0, wi, .TRANSMISSION | .SPECULAR);
            }
        }
    }

    return make_zero_sample();
}

estimate_glossy_specular :: (using info: Glossy_Specular_Shading_Info, wo: Vector3) -> float
{
    if !is_microfacet_alpha_delta(microfacet_alpha)
    {
        mask         := microfacet_ggx_mask(wo, microfacet_alpha);
        coefficients := calculate_glossy_specular_coefficients(info, wo.z);
        estimate     := max_spectrum(coefficients.reflect + coefficients.transmit) * mask;
        return estimate;
    }
    else
    {
        coefficients := calculate_glossy_specular_coefficients(info, wo.z);
        estimate     := max_spectrum(coefficients.reflect + coefficients.transmit);
        return estimate;
    }
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

//------------------------------------------------------------------------
// Multi Scatter Metal BRDF

#scope_module

evaluate_multi_scatter_metal :: (using info: Multi_Scatter_Metal_Shading_Info, wo: Vector3, wi: Vector3) -> Spectrum
{
    if (has_visible_energy_loss(microfacet_alpha) && wi.z > 0.0)
    {
        clamped_weight := calculate_multi_scatter_metal_energy(info, wi);
        weight         := scale * clamped_weight * wi.z;
        return weight;
    }
    return Spectrum_Zero;
}

pdf_multi_scatter_metal :: (using info: Multi_Scatter_Metal_Shading_Info, wo: Vector3, wi: Vector3) -> float
{
    if (has_visible_energy_loss(microfacet_alpha))
    {
        pdf := pdf_cosine(wi);
        return pdf;
    }
    return 0.0;
}

sample_multi_scatter_metal :: (using info: Multi_Scatter_Metal_Shading_Info, wo: Vector3, u: Vector3) -> Sample
{
    if (has_visible_energy_loss(microfacet_alpha))
    {
        wi := sample_cosine(u.x, u.y);
        if (wi.z > 0.0)
        {
            wi_energy_complement := read_metal_energy_complement(microfacet_alpha, wi.z);
            pdf                  := pdf_cosine(wi);
            clamped_weight       := calculate_multi_scatter_metal_energy(info, wi);
            weight               := scale * clamped_weight * wi.z / pdf;
            return make_sample(weight, pdf, wi, .REFLECTION | .DIFFUSE);
        }
    }
    return make_zero_sample();
}

estimate_multi_scatter_metal :: (using info: Multi_Scatter_Metal_Shading_Info, wo: Vector3) -> float
{
    if (has_visible_energy_loss(microfacet_alpha))
    {
        estimate := max_spectrum(scale) * energy_complement_wo_dot_n;
        return estimate;
    }
    return 0.0;
}

#scope_file

calculate_multi_scatter_metal_energy :: (using info: Multi_Scatter_Metal_Shading_Info, wi: Vector3) -> float
{
    // Based on: https://blog.selfshadow.com/publications/s2017-shading-course/imageworks/s2017_pbs_imageworks_slides_v2.pdf
    // (1 - E(wi)) * (1 - E(wo)) / (PI * (1 - E_avg))
    energy_complement_wi_dot_n := read_metal_energy_complement(microfacet_alpha, wi.z);
    unscaled_weight            := energy_complement_wi_dot_n * energy_complement_wo_dot_n / max(PI * average_energy_complement, 1.0e-6);
    // Prevent weights from getting out of control near grazing angles at low roughnesses
    clamped_weight             := min(unscaled_weight, sdiv(1.0, wi.z));
    return clamped_weight;
}

////------------------------------------------------------------------------
//// Glossy Diffuse

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

#scope_file

has_visible_energy_loss :: inline (alpha: float) -> bool
{
    MIN_ROUGHNESS_WITH_VISIBLE_ENERGY_LOSS :: 0.04;
    MIN_ALPHA_WITH_VISIBLE_ENERGY_LOSS     :: MIN_ROUGHNESS_WITH_VISIBLE_ENERGY_LOSS * MIN_ROUGHNESS_WITH_VISIBLE_ENERGY_LOSS;
    return alpha >= MIN_ALPHA_WITH_VISIBLE_ENERGY_LOSS;
}

sdiv :: inline (x: $T, y: T) -> T
{
    if (y != 0)
    {
        return x/y;
    }
    return 0;
}

refracted_normal :: inline (wo: Vector3, wi: Vector3, eta_t_over_eta_i: float) -> Vector3
{
    wh := normalize(wo + eta_t_over_eta_i * wi);
    if (wh.z < 0.0)
    {
        wh = -wh;
    }
    return wh;
}

FLOAT32_EPSILON :: 0h34000000;
FLOAT32_ONE_MINUS_EPSILON :: 0h3F7FFFFF;

clamp_random_number :: inline (p: float) -> float
{
    return min(p, FLOAT32_ONE_MINUS_EPSILON);
}

clamp_random_sample :: inline (u: Vector3) -> Vector3
{
    clamped_u: Vector3 = ---;
    clamped_u.x = clamp_random_number(u.x);
    clamped_u.y = clamp_random_number(u.y);
    clamped_u.z = clamp_random_number(u.z);
    return clamped_u;
}

#import "Math";
#import "Basic";
