#scope_module

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
