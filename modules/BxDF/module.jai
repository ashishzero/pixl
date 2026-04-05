
#module_parameters()(MULTISCATTER_ENERGY_PRESERVATION:=true);

#scope_export

Spectrum :: #type,isa Vector3;

Spectrum_One  :: Spectrum.{1, 1, 1};
Spectrum_Zero :: Spectrum.{0, 0, 0};

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

BxDF_Eval :: struct
{
    f    : Spectrum;
    pdf  : float;
}

BxDF_Sample :: struct
{
    using eval : BxDF_Eval;
    L          : Vector3;
}

Lobe_Index :: enum
{
    DIFFUSE;
    CONDUCTOR;
    DIELECTRIC;
    TRANSPARENT;
}

MAX_LOBE_INDEX :: #run type_info(Lobe_Index).values.count;

Lobe_Weights :: [MAX_LOBE_INDEX]float;

#scope_module

//------------------------------------------------------------------------
// Shared

#import "Math";
#import "Common";

INV_PI :: 1.0 / PI;

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

#load "microfacet.jai";
#load "specular.jai";
#load "diffuse.jai";
#load "dielectric.jai";
#load "conductor.jai";
#load "transparent.jai";
#load "bsdf.jai";

#if MULTISCATTER_ENERGY_PRESERVATION
{
    #load "ms_tables.jai";
}
