
MAX_THREADS :: 256;

Thread_Lane :: struct
{
    index   :  u32;
    count   :  u32;
    barrier : *Thread_Barrier;
}

#add_context lane: Thread_Lane;

Thread_Wave :: struct
{
    barrier   : Thread_Barrier;
    threads   : [..]Thread;
}

thread_wave_start :: (wave: *Thread_Wave, proc: Thread_Proc, shared: *void = null, num_threads : s32 = 0, used_threads : s32 = 0)
{
    if (num_threads <= 0)
    {
        num_cpus := get_number_of_processors();

        assert(num_cpus >= 1);
        if num_cpus > MAX_THREADS num_cpus = MAX_THREADS;

        num_threads = max(num_cpus - used_threads, 1);
    }

    array_resize(*wave.threads, num_threads);
    thread_barrier_init(*wave.barrier, num_threads);

    for * wave.threads
    {
        thread_init(it, proc);
        it.data = shared;
        it.starting_context.lane.index   = it_index.(u32);
        it.starting_context.lane.count   = num_threads.(u32);
        it.starting_context.lane.barrier = *wave.barrier;
    }

    for * wave.threads
    {
        thread_start(it);
    }
}

thread_wave_join :: (wave: *Thread_Wave)
{
    for * wave.threads
    {
        thread_is_done(it, -1);
        thread_deinit(it);
    }
    thread_barrier_deinit(*wave.barrier);
    array_free(wave.threads);
    wave.* = .{};
}

lane_sync :: ()
{
    thread_barrier_sync(context.lane.barrier);
}

Thread_Barrier :: struct
{
    platform_specific: Thread_Barrier_Platform_Specific;
}

#scope_file

#if OS == .WINDOWS
{
    Thread_Barrier_Platform_Specific :: SYNCHRONIZATION_BARRIER;

    Windows   :: #import "Windows";

    ULONG_PTR :: u64; // x64 only
    LONG      :: s32;

    SYNCHRONIZATION_BARRIER  :: struct
    {
        Reserved1: Windows.DWORD;
        Reserved2: Windows.DWORD;
        Reserved3: [2]ULONG_PTR;
        Reserved4: Windows.DWORD;
        Reserved5: Windows.DWORD;
    }

    kernel32 :: #library,system "kernel32";

    InitializeSynchronizationBarrier :: (lpBarrier: *SYNCHRONIZATION_BARRIER, lTotalThreads: LONG, lSpinCount: LONG) -> Windows.BOOL #foreign kernel32;
    DeleteSynchronizationBarrier :: (lpBarrier: *SYNCHRONIZATION_BARRIER) -> Windows.BOOL #foreign kernel32;
    EnterSynchronizationBarrier :: (lpBarrier: *SYNCHRONIZATION_BARRIER, dwFlags: Windows.DWORD) -> Windows.BOOL #foreign kernel32;

    thread_barrier_init :: (barrier: *Thread_Barrier, num_threads: int)
    {
        InitializeSynchronizationBarrier(*barrier.platform_specific, xx num_threads, -1);
    }

    thread_barrier_deinit :: (barrier: *Thread_Barrier)
    {
        DeleteSynchronizationBarrier(*barrier.platform_specific);
    }

    thread_barrier_sync :: (barrier: *Thread_Barrier)
    {
        EnterSynchronizationBarrier(*barrier.platform_specific, 0);
    }
}

#import "Thread";
#import "System";
