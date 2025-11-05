
main :: ()
{
    compute_metallic_k_ms_table();
    compute_metallic_E_avg_table();

    dump_computed_tables("source/bxdf_lut.jai");
}

#load "bxdf_meta.jai";
