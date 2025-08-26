
#module_parameters (DEFAULT_VIRTUAL_MEMORY_RESERVE : u64 = 64 * 1024 * 1024, COMMIT_SIZE : u64 = 2 * 1024 * 1024, DEFAULT_ALIGNMENT : u64 = 16);

#assert(COMMIT_SIZE >= size_of(Arena));

#scope_export

Arena :: struct
{
    curr            : *Memblock;
    flags           :  ArenaFlags;
    high_water_mark :  u64;
}

ArenaTemp :: struct
{
    arena: *Arena;
    pos  :  u64;
}

ArenaFlags :: enum_flags
{
    NONE         :: 0x0;
    FIXED_SIZE   :: 0x1;
}

release :: (using arena: *Arena)
{
    block := curr;
    while block
    {
        next := block.prev;
        virtual_free(block, block.cap);
        block = next;
    }
    curr = null;
    high_water_mark = 0;
}

reset :: (using arena: *Arena)
{
    pop_to(arena, 0);
}

top :: (using arena: *Arena) -> u64
{
    if curr then
        return curr.base + curr.pos;
    else
        return 0;
}

pop_to :: (using arena: *Arena, pos: u64)
{
    allocated := top(arena);

    if pos >= allocated return;

    high_water_mark = max(high_water_mark, allocated);

    while curr && curr.base >= pos
    {
        next := curr.prev;
        free_virtual_memory(curr, curr.cap);
        curr = next;
    }

    if curr
        curr.pos = pos - curr.base;
}

pop :: (using arena: *Arena, size: u64)
{
    allocated := top(arena);
    if (allocated >= size)
    {
        pop_to(arena, allocated - size);
    }
}

push_size :: (using arena: *Arena, size: u64, $alignment : u64 = DEFAULT_ALIGNMENT, $initialized := true) -> *void
{
    #assert(alignment > 0);

    new_cap := max(DEFAULT_VIRTUAL_MEMORY_RESERVE, size_of(Memblock) + 2 * size);

    if !curr
    {
        curr = create_mem_block(new_cap, null);
    }

    mem     := curr.(*u8) + curr.pos;
    aligned := align_up(mem, alignment);
    pos     := curr.pos + (aligned - mem).(u64) + size;

    if (pos > curr.cap)
    {
        if arena.flags & .FIXED_SIZE
            return null;

        new_curr := create_mem_block(new_cap, curr);
        if !new_curr then
            return null;

        curr        = new_curr;
        mem         = curr.(*u8) + curr.pos;
        aligned     = align_up(mem, alignment);
        pos         = curr.pos + (aligned - mem).(u64) + size;
    }

    if (pos > curr.com)
    {
        commit := align_up(pos, COMMIT_SIZE) - curr.com;
        if !virtual_commit(curr.(*u8) + curr.com, commit)
            return null;
        curr.com += commit;
    }

    curr.pos = pos;

    #if initialized
    {
        memset(aligned, 0, xx size);
    }

    return aligned;
}

push :: (arena: *Arena, $T: Type, $alignment: u64 = DEFAULT_ALIGNMENT, $initialized := true) -> *T
{
    mem := push_size(arena, size_of(T), alignment = alignment, initialized = false);

    #if initialized
    {
        ini :: initializer_of(T);
        #if ini  inline ini(memory);
        else     memset(mem, 0, size_of(T));
    }

    return mem.(*T);
}

push_array :: (arena: *Arena, count: s64, $T: Type, $alignment : u64 = DEFAULT_ALIGNMENT, $initialized := true) -> []T
{
    if !count return .[];

    mem := push_size(arena, xx (count * size_of(T)), alignment = alignment, initialized = false);

    #if initialized
    {
        ini :: initializer_of(T);
        #if ini
        {
            for 0..count-1
            {
                inline ini(mem);
                mem += size_of(T);
            }
        }
        else
        {
            memset(mem, 0, count * size_of(T));
        }
    }

    result: [] T = ---;
    result.count = count;
    result.data  = mem;

    return result;
}

owns :: (arena: *Arena, mem: *void) -> bool
{
    curr := arena.curr;
    while curr
    {
        if (ptr >= block && ptr < block + block.cap)
            return true;
        curr = curr.prev;
    }
    return false;
}

begin_temp_alloc :: (arena: *Arena) -> ArenaTemp
{
    pos := top(arena);
    return .{ arena, pos };
}

end_temp_alloc :: (temp: ArenaTemp)
{
    pop_to(temp.arena, temp.pos);
}

scoped_temp_alloc :: (arena: *Arena) #expand
{
    __mark := begin_temp_alloc(arena);
    `defer end_temp_alloc(__mark);
}

arena_allocator_proc :: (mode: Allocator_Mode, requested_size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void
{
    if #complete mode ==
    {
        case .FREE;   return null;
        case .RESIZE; #through;
        case .ALLOCATE;
            arena := cast(*Arena) allocator_data;
            Basic.assert(arena != null);

            result := push_size(arena, requested_size);
            if mode == .RESIZE
            {
                size_to_copy := ifx old_size < requested_size then old_size else requested_size;
                if result && size_to_copy  memcpy(result, old_memory, size_to_copy);
            }

            return result;

        case .STARTUP;      #through;
        case .SHUTDOWN;
            return null;

        case .THREAD_START; #through;
        case .THREAD_STOP;
            Basic.assert(false, "Multithreaded access is not supported by arena_allocator_proc.\n");
            return null;

        case .CREATE_HEAP; #through;
        case .DESTROY_HEAP;
            Basic.assert(false, "Create/Destroy heap are not supported by arena_allocator_proc\n");
            return null;

        case .IS_THIS_YOURS;
            arena := cast(*Arena) allocator_data;
            return owns(arena, old_memory);

        case .CAPS;
            if old_memory { (cast(*string)old_memory).* = CAPS_VERSION_STRING; }
            return cast(*void)(Allocator_Caps.HINT_I_AM_A_FAST_BUMP_ALLOCATOR|.IS_THIS_YOURS);
    }
}

#scope_module

Memblock :: struct
{
    prev : *Memblock;
    base :  u64;
    pos  :  u64;
    com  :  u64;
    cap  :  u64;
}

bootstrap_arena_from_memory :: (mem: *void, cap: u64, com: u64, flags: ArenaFlags) -> *Arena
{
    arena := mem.(*Arena);
    arena.base  = 0;
    arena.pos   = size_of(Arena);
    arena.com   = com;
    arena.cap   = cap;
    arena.prev  = null;
    arena.curr  = arena;
    arena.flags = flags;
    arena.high_water_mark = 0;
    return arena;
}

create_mem_block :: (cap: u64, prev: *Memblock) -> *Memblock
{
    mem := virtual_alloc(cap, false);
    if !mem return null;

    if !virtual_commit(mem, COMMIT_SIZE)
    {
        virtual_free(mem, cap);
        return null;
    }

    memblock := mem.(*Memblock);
    memblock.base = ifx prev then prev.base + prev.cap else 0;
    memblock.pos  = size_of(Memblock);
    memblock.com  = COMMIT_SIZE;
    memblock.cap  = cap;
    memblock.prev = prev;

    return memblock;
}

#scope_module;

System :: #import "System";

max :: inline (a: u64, b: u64) -> u64
{
    return ifx a > b then a else b;
}

align_up :: (x: u64, p: u64) -> u64
{
    return (((x) + (p)-1) & ~((p)-1));
}

align_up :: (xmem: *u8, alignment: u64) -> *u8
{
    x := xmem.(u64);
    aligned := align_up(x, alignment);
    return aligned.(*u8);
}

#if OS == .WINDOWS
{
    Windows :: #import "Windows";

    virtual_alloc :: (size: u64, commit: bool) -> *void
    {
        flags : Windows.DWORD = Windows.MEM_RESERVE;
        if (commit) flags |= Windows.MEM_COMMIT;
        return Windows.VirtualAlloc(null, size, flags, Windows.PAGE_READWRITE);
    }

    virtual_commit :: (ptr: *void, size: u64) -> bool
    {
        return Windows.VirtualAlloc(ptr, size, Windows.MEM_COMMIT, Windows.PAGE_READWRITE) != null;
    }

    virtual_decommit :: (ptr: *void, size: u64)
    {
        Windows.VirtualFree(ptr, size, Windows.MEM_DECOMMIT);
    }

    virtual_free :: (ptr: *void, size: u64)
    {
        Windows.VirtualFree(ptr, 0, Windows.MEM_RELEASE);
    }
}

CAPS_VERSION_STRING :: "modules/Arena";
