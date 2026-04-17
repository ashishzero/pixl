#scope_export

// Artist Friendly - Schlick inspired
// Based on: https://blog.selfshadow.com/publications/s2017-shading-course/imageworks/s2017_pbs_imageworks_slides_v2.pdf

MAX_REASONABLE_IOR :: 400.0;
MIN_REASONABLE_IOR :: 1.0 / MAX_REASONABLE_IOR;

fresnel_metal :: (reflectance: Spectrum, edge_tint: Spectrum, falloff: Spectrum, VoH: float) -> Spectrum
{
    t   := 1.0 - VoH;
    x   := pow(t, 1.0 / max(falloff.x, 1.0e-6));
    y   := pow(t, 1.0 / max(falloff.y, 1.0e-6));
    z   := pow(t, 1.0 / max(falloff.z, 1.0e-6));
    F   := reflectance + (edge_tint - reflectance) * Spectrum.{x, y, z};
    return F;
}

fresnel_average_metal :: (reflectance: Spectrum, edge_tint: Spectrum, falloff: Spectrum) -> Spectrum
{
    psq2  := 2 * falloff * falloff;
    p3    := 3 * falloff;
    num   := edge_tint * psq2 + reflectance + p3 * reflectance;
    den   := Spectrum_One + p3 + psq2;
    F_avg := num / den;
    return F_avg;
}

fresnel_dielectric :: (ior: float, mu: float) -> float
{
    u  := abs(clamp(mu, -1.0, 1.0));
    g2 := ior * ior + u * u - 1.0;
    if g2 <= 0.0 return 1.0;
    g  := sqrt(g2);
    n1 := g - u;
    d1 := g + u;
    t1 := n1 / d1;
    n2 := u * d1 - 1.0;
    d2 := u * n1 + 1.0;
    if d2 <= 0.0 return 1.0;
    t2 := n2 / d2;
    F  := 0.5 * t1 * t1 * (1.0 + t2 * t2);
    return F;
}

fresnel_average_dielectric :: (ior: float) -> float
{
    n := clamp(ior, MIN_REASONABLE_IOR, MAX_REASONABLE_IOR);
    if (n >= 1.0)
    {
        num   := n - 1.0;
        den   := 4.08567 + 1.00071 * n;
        F_avg := num / den;
        return F_avg;
    }
    else
    {
        n2    := n * n;
        n3    := n2 * n;
        F_avg := 0.997118 + 0.1014 * n - 0.965241 * n2 - 0.1306073 * n3;
        return F_avg;
    }
}

ior_inverse_parametrization :: (ior: float) -> float
{
    assert(ior >= 1.0);
    t := sqrt((ior - 1.0) / (ior + 1.0));
    return t;
}

ior_parametrization :: (t: float) -> float
{
    p   := clamp(t, 0.0, 0.999999);
    p2  := p * p;
    ior := (1.0 + p2) / (1.0 - p2);
    return ior;
}
