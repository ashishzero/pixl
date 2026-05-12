generate_bindings :: ()
{
    set_build_options_dc(.{do_output=false});

    cuda_path := to_string(getenv("CUDA_PATH"));

    output_filename := "cuda.jai";
    opts: Generate_Bindings_Options;

    {
        using opts;

        cuda_lib_path     := path_join(cuda_path, "lib", "x64");
        cuda_include_path := path_join(cuda_path, "include");

        array_add(*library_search_paths, cuda_lib_path);
        array_add(*libraries, .{filename="cuda"});
        array_add(*source_files, path_join(cuda_include_path, "cuda.h"));

        try_to_preserve_comments              = false;
        add_overloaded_const_and_ref_comments = false;
        generate_compile_time_struct_checks   = false;
        generate_library_declarations         = false;
        generate_library_declarations         = false;
    }

    success := generate_bindings(opts, output_filename);
    if !success
    {
        compiler_set_workspace_status(.FAILED);
        return;
    }
}

#run generate_bindings();

#if OS == .WINDOWS
{
    Windows :: #import "Windows";
    getenv :: Windows.getenv;
}
else
{
    Posix :: #import "Posix";
    getenv :: Posix.getenv;
}

#import "Basic";
#import "Bindings_Generator";
#import "Compiler";
#import "String";

