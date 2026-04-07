#module_parameters()(PRESERVE_MS_ENERGY:=true);

#load "bsdf.jai";
#load "sampling.jai";

#scope_module

#if PRESERVE_MS_ENERGY
{
    #load "ms_tables.jai";
}
