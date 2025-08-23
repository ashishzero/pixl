
#module_parameters (DEFAULT_VIRTUAL_MEMORY_RESERVE : u64 = 256 * 1024 * 1024, MIN_VIRTUAL_MEMORY_RESERVE : u64 = 32 * 1024 * 1024, COMMIT_SIZE : u64 = 2 * 1024 * 1024, DEFAULT_ALIGNMENT : u64 = 16);

#assert(COMMIT_SIZE >= size_of(Arena));

#scope_export

Arena :: struct
{
    curr: *Arena;
    prev: *Arena;

    base:  u64;
    pos:   u64;
    com:   u64;
    cap:   u64;
    flags: ArenaFlags;

    high_water_mark: u64;
}

ArenaTemp :: struct
{
    arena: *Arena;
    pos: u64;
}

ArenaFlags :: enum_flags
{
    NONE                :: 0x0;
    DO_NOT_GROW         :: 0x1;
    DOES_NOT_OWN_MEMORY :: 0x2;
}

get_null_arena :: () -> *Arena
{
    return *falback_arena;
}

create_arena_from_preallocated_memory :: (mem: *void, cap: u64) -> *Arena
{
    if (cap < size_of(Arena))
        return *fallback_arena;
    arena := bootstrap_arena_from_memory(mem, cap, cap, .NONE, 0);
    return arena;
}

make_arena :: (cap: u64 = DEFAULT_VIRTUAL_MEMORY_RESERVE, fixed: bool = false) -> *Arena
{
    arena := bootstrap_arena(null, cap, fixed);
    return ifx arena then arena else *fallback_arena;
}

free_arena :: (arena: *Arena)
{
    prev : *Arena = null;
    curr := arena.curr;

    while curr
    {
        prev = curr.prev;
        if (curr != *fallback_arena && !(curr.flags & .DOES_NOT_OWN_MEMORY))
            free_virtual_memory(curr, curr.cap);
        curr = prev;
    }
}

reset :: (arena: *Arena)
{
    pop_to(arena, 0);
}

top :: (arena: *Arena) -> u64
{
    curr := arena.curr;
    pos := curr.base + curr.pos;
    return pos;
}

get_high_water_mark :: (arena: *Arena) -> u64
{
    return arena.high_water_mark;
}

pop_to :: (arena: *Arena, pos: u64)
{
    arena.high_water_mark = max(arena.high_water_mark, arena.curr.base + arena.curr.pos);
    pos                   = max(pos, size_of(Arena));

    current := arena.curr;
    prev: *Arena = null;

    while current.base >= pos
    {
        prev = current.prev;
        free_virtual_memory(current, current.cap);
        current = prev;
    }

    current.pos = pos - current.base;
    arena.curr = current;
}

pop :: (arena: *Arena, size: u64)
{
    pos := top(arena);
    if (pos >= size)
    {
        pop_to(arena, pos - size);
    }
}

push_size :: (arena: *Arena, size: u64, $alignment : u64 = DEFAULT_ALIGNMENT, $initialized := true) -> *void
{
    #assert(alignment > 0);

    current := arena.curr;
    mem     := current.(*u8) + current.pos;
    aligned := align_up(mem, alignment);
    pos     := current.pos + (aligned - mem).(u64) + size;

    if (pos > current.cap)
    {
        if arena.flags & .DO_NOT_GROW
            return null;

        current = bootstrap_arena(arena.curr, max(size + size_of(Arena), arena.cap * 2), false);
        if !current
            return null;

        arena.curr  = current;

        mem         = current.(*u8) + current.pos;
        aligned     = align_up(mem, alignment);
        pos         = current.pos + (aligned - mem).(u64) + size;
    }

    if (pos > current.com)
    {
        commit := align_up(pos, COMMIT_SIZE) - current.com;
        if !commit_virtual_memory(current.(*u8) + current.com, commit)
            return null;
        current.com += commit;
    }

    current.pos = pos;

    #if initialized
    {
        memset(aligned, 0, size);
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

#scope_module

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

bootstrap_arena :: (prev: *Arena, cap: u64, is_fixed: bool) -> *Arena
{
    cap = max(MIN_VIRTUAL_MEMORY_RESERVE, cap);

    mem := alloc_virtual_memory(cap, false);
    if (!mem) return null;

    if (!commit_virtual_memory(mem, COMMIT_SIZE))
    {
        free_virtual_memory(mem, cap);
        return null;
    }

    flags := ArenaFlags.NONE;

    if (is_fixed)
        flags |= .DO_NOT_GROW;

    arena := bootstrap_arena_from_memory(mem, cap, COMMIT_SIZE, flags);

    if (prev)
    {
        arena.prev = prev;
        arena.base = prev.base + prev.cap;
    }

    return arena;
}

fallback_arena : Arena;

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

#scope_module;

Basic  :: #import "Basic";
System :: #import "System";

max :: inline (a: $T, b: T) -> T
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
    PAGE_SIZE :: 4096;

    alloc_virtual_memory :: (size: u64, commit: bool) -> *void
    {
        flags : Windows.DWORD = Windows.MEM_RESERVE;
        if (commit) flags |= Windows.MEM_COMMIT;
        return Windows.VirtualAlloc(null, size, flags, Windows.PAGE_READWRITE);
    }

    commit_virtual_memory :: (ptr: *void, size: u64) -> bool
    {
        return Windows.VirtualAlloc(ptr, size, Windows.MEM_COMMIT, Windows.PAGE_READWRITE) != null;
    }

    decommit_virtual_memory :: (ptr: *void, size: u64)
    {
        Windows.VirtualFree(ptr, size, Windows.MEM_DECOMMIT);
    }

    free_virtual_memory :: (ptr: *void, size: u64)
    {
        Windows.VirtualFree(ptr, 0, Windows.MEM_RELEASE);
    }
}

CAPS_VERSION_STRING :: "modules/Arena";
