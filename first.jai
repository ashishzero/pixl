
build :: () {
    output_path := "bin";

    make_directory_if_it_does_not_exist(output_path);
    
    w := compiler_create_workspace("PixL");

    options := get_build_options();
    options.output_executable_name = "pixl";
    options.output_path = output_path;

    set_build_options(options, w);
    
    compiler_begin_intercept(w);

    add_build_file("source/main.jai", w);

    message_loop();

    compiler_end_intercept(w);

    set_build_options_dc(.{do_output=false});
}

message_loop :: () {
    while true {
        message := compiler_wait_for_message();
        if message.kind == {
          case .COMPLETE;
              break;
        }
    }
}

#run build();

#import "Compiler";
#import "File";
