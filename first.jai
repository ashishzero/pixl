
build_program :: (outpath: string, name: string, src: string)
{
    w := compiler_create_workspace(name);

    options := get_build_options();
    options.output_executable_name = name;
    options.output_path = outpath;

    set_build_options(options, w);
    
    compiler_begin_intercept(w);

    if options.backend == .X64
    {
        add_build_string("ENABLE_RAD_DEBUGGER :: true;", w);
    }
    else
    {
        add_build_string("ENABLE_RAD_DEBUGGER :: false;", w);
    }

    add_build_file(src, w);

    message_loop();

    compiler_end_intercept(w);
}

build :: ()
{
    output_path := "bin";
    make_directory_if_it_does_not_exist(output_path);

    build_program(output_path, "PixL", "source/main.jai");
    build_program(output_path, "PixL_meta", "source/meta.jai");

    set_build_options_dc(.{do_output=false});
}

message_loop :: ()
{
    while true
    {
        message := compiler_wait_for_message();
        if message.kind ==
        {
          case .COMPLETE;
              break;
        }
    }
}

#run build();

#import "Compiler";
#import "File";
