// EON: A practical energy-preserving rough diffuse BRDF
// https://arxiv.org/pdf/2410.18026

#scope_module

eval_diffuse_eon :: (V: Vector3, L: Vector3, surface: Surface) -> BxDF_Eval
{
    if (L.z > 0.0)
    {
        NoV   := V.z;
        f     := eval_diffuse_eon_spectrum(V, L, surface);
        P_u   := pow(surface.roughness, 0.1) * (0.162925 + NoV * (-0.372058 + (0.538233 - 0.290822 * NoV) * NoV));
        P_c   := 1.0 - P_u;
        pdf_c := pdf_cltc(V, L, surface.roughness);
        pdf_u := 1.0 / (2.0 * PI);
        pdf   := P_u * pdf_u + P_c * pdf_c;
        return .{f, pdf};
    }
    return .{};
}

sample_diffuse_eon :: (V: Vector3, surface: Surface, u: Vector3) -> BxDF_Sample
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

    f     := eval_diffuse_eon_spectrum(V, L, surface);
    pdf_u := 1.0 / (2.0 * PI);
    pdf   := P_u * pdf_u + P_c * pdf_c; // MIS PDF of L
    return .{.{f, pdf}, L};
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

sample_uniform_lobe :: (u1: float, u2: float) -> Vector3
{
    sintheta := sqrt(1.0 - u1 * u1);
    phi      := 2.0 * PI * u2;
    L : Vector3 = ---;
    L.x = sintheta * cos(phi);
    L.y = sintheta * sin(phi);
    L.z = u1;
    return L;
}

eval_diffuse_eon_spectrum :: (V: Vector3, L: Vector3, surface: Surface) -> Spectrum
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

