#scope_export

Spectrum :: #type,isa Vector3;

Spectrum_One  :: Spectrum.{1, 1, 1};
Spectrum_Zero :: Spectrum.{0, 0, 0};

Surface :: struct
{
    // Dielectrics
    color               : Spectrum;
    diffuse_roughness   : float;
    specular_ior        : float;
    specular_weight     : float;
    transmission_weight : float;

    // Metals
    metallic            : float;
    reflectance         : Spectrum;
    edge_tint           : Spectrum;
    falloff             : Spectrum;

    // Microfacet GGX
    microfacet_alpha    : Vector2;

    // Ambient Medium
    geometry_opacity    : float;

    // TODO: Include these into the BRDF
    absorption       : Spectrum;
    emission         : Spectrum;
}

Transport :: enum u32
{
    NONE;
    REFLECTION;
    TRANSMISSION;
}

BSDF :: struct
{
    f     : Spectrum;
    pdf   : float;
}

Sampled_BSDF :: struct
{
    using bsdf : BSDF;
    L          : Vector3;
    transport  : Transport;
}

sampled_bsdf :: inline (bsdf: BSDF, L: Vector3, transport: Transport) -> Sampled_BSDF
{
    return .{bsdf, L, transport};
}

sampled_bsdf :: inline (f: Spectrum, pdf: float, L: Vector3, transport: Transport) -> Sampled_BSDF
{
    return sampled_bsdf(.{f, pdf}, L, transport);
}

//------------------------------------------------------------------------
// Sampling

#scope_export

sample_uniform_hemisphere :: (u1: float, u2: float) -> Vector3
{
    r   := sqrt(1.0 - u1 * u1);
    phi := 2.0 * PI * u2;
    L   : Vector3 = ---;
    L.x  = r * cos(phi);
    L.y  = r * sin(phi);
    L.z  = u1;
    return L;
}

pdf_uniform_hemisphere :: () -> float
{
    return 1.0 / (2.0 * PI);
}

sample_uniform_sphere :: (u1: float, u2: float) -> Vector3
{
    z   := 1.0 - 2.0 * u1;
    r   := sqrt(1.0 - z * z);
    phi := 2 * PI * u2;
    L   : Vector3 = ---;
    L.x  = r * cos(phi);
    L.y  = r * sin(phi);
    L.z  = z;
    return L;
}

pdf_uniform_sphere :: () -> float
{
    return 1.0 / (4.0 * PI);
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
    return L.z / PI;
}

//------------------------------------------------------------------------
// Utils

reflect :: inline (I: Vector3, N: Vector3) -> Vector3
{
    return I - 2.0 * dot(N, I) * N;
}

refract :: inline (I: Vector3, N: Vector3, ior: float) -> Vector3, bool
{
    cos_i := -dot(N, I);
    sin_t := max(0.0, 1.0 - cos_i * cos_i) / (ior * ior);
    if (sin_t <= 1.0)
    {
        k := 1.0 - sin_t;
        R := I / ior + (cos_i / ior - sqrt(k)) * N;
        return R, true;
    }
    return .{}, false;
}

luminance :: (s: Spectrum) -> float
{
    R :: 0.2126;
    G :: 0.7152;
    B :: 0.0722;
    l := R * s.x + G * s.y + B * s.z;
    return l;
}
