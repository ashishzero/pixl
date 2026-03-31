#load "scene.jai";

Render_Options :: struct
{
    width        := 1920;
    height       := 1080;
    num_threads  := 0;
    multisamples := 256;
    max_depth    := 15;
}

main :: ()
{
    success, options := parse_arguments(Render_Options);
    print("Render Options : %\n", FormatStruct.{value = options, use_long_form_if_more_than_this_many_members = -1});

    info := type_info(Test_Scene);

    for info.values
    {
        rendering_scene := it.(Test_Scene);
        print("Rendering % ... ", rendering_scene);

        scene: Scene; // todo: cleanup
        init_scene(*scene, xx options.width, xx options.height, multisamples=xx options.multisamples, max_depth=xx options.max_depth);
        load_test_scene(*scene, rendering_scene);
        prepare_for_rendering(*scene);

        raytrace_thread_proc :: (thread: *Thread) -> s64
        {
            render(thread.data.(*Scene), 1.0, 0);
            return 0;
        }

        t0 := current_time_monotonic();
        wave: Thread_Wave;
        thread_wave_start(*wave, raytrace_thread_proc, shared = *scene, num_threads = xx options.num_threads);
        thread_wave_join(*wave);
        t1 := current_time_monotonic();

        render_time := to_milliseconds(t1 - t0);
        print("%ms\n", render_time);

        make_directory_if_it_does_not_exist("test_renders");

        filepath := tprint("test_renders/%.png", rendering_scene);
        Simp.bitmap_save(*scene.bitmap, filepath);
    }
}
