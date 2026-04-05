#scope_module

// F82-tint

eval_conductor_f82 :: (V: Vector3, L: Vector3, surface: Surface) -> BxDF_Eval
{
    alpha := surface.microfacet_alpha;
    if (is_rough(alpha) && V.z * L.z > 0.0)
    {
        H         := normalize(V + L);
        NoV       := V.z;
        VoH       := dot(V, H);
        brdf      := eval_ggx_specular_reflect(V, L, H, alpha);
        F_ss      := f82_tint(VoH, surface.fresnel.F0, surface.fresnel.F90);
        darkening := microfacet_ggx_metallic_multiscatter_energy_preservation_factor(F_ss, NoV, alpha);
        brdf.f    *= darkening * F_ss;
        return brdf;
    }
    return .{};
}

sample_conductor_f82 :: (V: Vector3, surface: Surface, u: Vector3) -> BxDF_Sample
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
            brdf      := eval_ggx_specular_reflect(V, L, H, alpha);
            F_ss      := f82_tint(VoH, surface.fresnel.F0, surface.fresnel.F90);
            darkening := microfacet_ggx_metallic_multiscatter_energy_preservation_factor(F_ss, NoV, alpha);
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

#scope_file

power6 :: inline (x: float) -> float
{
    x2 := x * x;
    x3 := x2 * x;
    x6 := x3 * x3;
    return x6;
}

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

microfacet_ggx_metallic_multiscatter_energy_preservation_factor :: inline (F_ss: Spectrum, NoV: float, alpha: Vector2) -> Spectrum
{
    #if MULTISCATTER_ENERGY_PRESERVATION
    {
        r     := sqrt(sqrt(alpha.x * alpha.y));
        E_avg := read_table_1D(conductor_E_avg, CONDUCTOR_E_SIZE, r);
        E_ms  := read_table_2D(conductor_E, CONDUCTOR_E_SIZE, CONDUCTOR_E_SIZE, r, NoV);

        // Fresnel term is based on the following blog:
        // https://blog.selfshadow.com/2018/06/04/multi-faceted-part-2/
        F_ms  := F_ss * E_avg / (Spectrum_One - F_ss * (1.0 - E_avg));

        // Energy preservation is based on the "Practical multiple scattering compensation for microfacet models" by Emmanuel Turquin
        // Reference: https://blog.selfshadow.com/publications/turquin/ms_comp_final.pdf
        k_ms := ifx (E_ms >= 1.0e-3) then (1.0 - E_ms) / E_ms else 0.0;
        darkening := Spectrum_One + F_ms * k_ms;
        return darkening;
    }
    else
    {
        return Spectrum_One;
    }
}
