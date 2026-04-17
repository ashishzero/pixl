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

BSDF_Label :: enum_flags u32
{
    DIFFUSE_REFLECTION    :: 0x1;
    SPECULAR_REFLECTION   :: 0x2;
    REFLECTION            :: DIFFUSE_REFLECTION | SPECULAR_REFLECTION;
    SPECULAR_REFRACTION   :: 0x4;
    GEOMETRY_TRANSMISSION :: 0x8;
    TRANSMISSION          :: SPECULAR_REFRACTION | GEOMETRY_TRANSMISSION;
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
    label      : BSDF_Label;
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
    sin_t := ior * ior * (1.0 - cos_i * cos_i);
    if (sin_t <= 1.0)
    {
        k := 1.0 - sin_t;
        R := ior * I + (ior * cos_i - sqrt(k)) * N;
        return R, true;
    }
    return .{}, false;
}
