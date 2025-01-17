
--
-- syscall class
--
-- helper for managing & resolving syscalls
--

syscall = {}

function syscall.init()

    libkernel_base = resolve_base(
        memory.read_qword(libc_addrofs.gettimeofday_import),
        "libkernel.sprx", 5
    )

    print("[+] libkernel base @ " .. hex(libkernel_base))
    
    if PLATFORM == "ps4" then  -- ps4 requires valid syscall wrapper, which we can scrape from libkernel .text
        local libkernel_text = memory.read_buffer(libkernel_base, 0x40000)
        -- mov rax, <num>; mov r10, rcx; syscall
        local matches = find_pattern(libkernel_text, "48 c7 c0 ? ? ? ? 49 89 ca 0f 05")
        syscall.syscall_wrapper = {}
        for i,offset in ipairs(matches) do
            local num = uint64.unpack(libkernel_text:sub(offset+3, offset+6))
            syscall.syscall_wrapper[num:tonumber()] = libkernel_base + offset - 1
        end
    elseif PLATFORM == "ps5" then -- can be any syscall wrapper in libkernel
        local gettimeofday = memory.read_qword(libc_addrofs.gettimeofday_import)
        syscall.syscall_address = gettimeofday + 7  -- +7 is to skip "mov rax, <num>" instruction
    else
        errorf("invalid platform %s", PLATFORM)
    end

    syscall.do_sanity_check()
end

function syscall.resolve(list)
    for name, num in pairs(list) do
        if not syscall[name] then
            if PLATFORM == "ps4" then
                if syscall.syscall_wrapper[num] then
                    syscall[name] = fcall(syscall.syscall_wrapper[num], num)
                else
                    printf("warning: syscall %s (%d) not found", name, num)
                end
            elseif PLATFORM == "ps5" then
                syscall[name] = fcall(syscall.syscall_address, num)
            end
        end
    end
end

function syscall.do_sanity_check()

    syscall.resolve({
        getpid = 20,
    })

    local pid = syscall.getpid()
    if not (pid and pid.h == 0 and pid.l ~= 0) then
        error("syscall test failed")
    end
end
