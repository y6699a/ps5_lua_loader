
--
-- thread class
--
-- use Thrd_create from libc to start a new thread
-- this thread is compatible with the libc functions that the game uses
--

thread = {}
thread.__index = thread

function thread.init()

    local setjmp = fcall(libc_addrofs.setjmp)
    
    -- get existing state
    local jmpbuf = memory.alloc(0x60)
    setjmp(jmpbuf)

    thread.fpu_ctrl_value = memory.read_dword(jmpbuf + 0x40)
    thread.mxcsr_value = memory.read_dword(jmpbuf + 0x44)
    thread.thr_handle_addr = memory.alloc(0x8)
    thread.initialized = true
end

function thread:new(chain)

    if not thread.initialized then
        thread.init()
    end

    if not chain.stack_base then
        error("`chain` argument must be a ropchain() object")
    end
    
    local self = setmetatable({}, thread)

    -- exit the thread after it has finished
    chain:push_fcall(libc_addrofs.Thrd_exit)

    self.jmpbuf = memory.alloc(0x60)

    memory.write_qword(self.jmpbuf, gadgets["ret"]) -- ret addr
    memory.write_qword(self.jmpbuf + 0x10, chain.stack_base) -- rsp - pivot to our ropchain
    memory.write_dword(self.jmpbuf + 0x40, thread.fpu_ctrl_value) -- fpu control word
    memory.write_dword(self.jmpbuf + 0x44, thread.mxcsr_value) -- mxcsr

    self.chain = chain
    return self
end

function thread:run()

    local Thrd_create = fcall(libc_addrofs.Thrd_create)
    
    -- spawn new thread with longjmp as entry, which then will jmp to our ropchain
    local ret = Thrd_create(thread.thr_handle_addr, libc_addrofs.longjmp, self.jmpbuf):tonumber()
    
    if ret ~= 0 then
        error("Thrd_create() error: " .. hex(ret))
    end

    self.thr_handle = memory.read_qword(thread.thr_handle_addr)
end

function thread:join()

    local Thrd_join = fcall(libc_addrofs.Thrd_join)

    -- will block until thread terminate
    local ret = Thrd_join(self.thr_handle, 0):tonumber()

    if ret ~= 0 then
        error("Thrd_join() error: " .. hex(ret))
    end
end

--
-- opt = {
--    args = additional data (table) to be passed to new thread
--    client_fd = output sink fd for new thread
--    close_socket_after_finished = if thread should close client_fd after it has finished running
-- }
function run_lua_code_in_new_thread(lua_code, opt)

    opt = opt or {}

    local LUA_REGISTRYINDEX = -10000
    local LUA_ENVIRONINDEX = -10001
    local LUA_GLOBALSINDEX = -10002
    local LUA_MULTRET = -1

    local luaL_newstate = fcall(eboot_addrofs.luaL_newstate)
    local luaL_openlibs = fcall(eboot_addrofs.luaL_openlibs)
    local lua_setfield = fcall(eboot_addrofs.lua_setfield)
    local luaL_loadstring = fcall(eboot_addrofs.luaL_loadstring)
    local lua_pushcclosure = fcall(eboot_addrofs.lua_pushcclosure)
    local lua_tolstring = fcall(eboot_addrofs.lua_tolstring)
    local lua_pushstring = fcall(eboot_addrofs.lua_pushstring)
    local lua_pushinteger = fcall(eboot_addrofs.lua_pushinteger)

    local lua_runner = [[

        package.path = package.path .. ";/savedata0/?.lua"
        
        require "misc"
        require "bit32"
        require "uint64"
        require "struct"
        require "lua"
        require "memory"
        require "ropchain"
        require "syscall"
        require "native"
        require "thread"

        function _payload_init()

            local data_from_loader = deserialize(_data_from_loader)

            local syscall_tbl = data_from_loader.syscall
            data_from_loader.syscall = nil  -- dont copy to global

            native.pivot_handler_rop = data_from_loader.native_pivot_handler_rop
            data_from_loader.native_pivot_handler_rop = nil  -- dont copy to global

            -- copy to global
            for k,v in pairs(data_from_loader) do
                _G[k] = v
            end

            -- copy (existing) resolved syscall from loader
            for k,v in pairs(syscall_tbl) do
                if v.fn_addr and v.syscall_no then
                    syscall[k] = fcall(v.fn_addr, v.syscall_no)
                end
            end

            syscall.syscall_wrapper = syscall_tbl.syscall_wrapper
            syscall.syscall_address = syscall_tbl.syscall_address

            -- enable addrof/fakeobj primitives
            lua.setup_victim_table()
        end

        _payload_init()

        old_print = print
        function print(...)
            local out = prepare_arguments(...) .. "\n"
            old_print(out)  -- print to stdout
            if client_fd then
                syscall.write(client_fd, out, #out)
            end
        end

        function _run_payload()

            local script, err = loadstring(_lua_code)
            if err then
                print(err)
                return
            end

            -- note: calling `debug.traceback` will crash the game. no stacktrace sucks :<
            -- local ok, err = xpcall(main, function(err)
            --     return debug.traceback(err, 2)
            -- end)

            local ok, err = pcall(script)
            if err then
                print(err)
            end
        end

        _run_payload()
    ]]

    local data_from_loader = {
        gadgets = gadgets,
        eboot_addrofs = eboot_addrofs,
        libc_addrofs = libc_addrofs,
        eboot_base = eboot_base,
        libc_base = libc_base,
        libkernel_base = libkernel_base,
        PLATFORM = PLATFORM,
        FW_VERSION = FW_VERSION,
        game_name = game_name,
        syscall = syscall,
        native_pivot_handler_rop = native.pivot_handler_rop,
        args = opt.args,
        client_fd = opt.client_fd,
        _lua_code = lua_code,
    }

    local pivot_handler = gadgets.stack_pivot[2]

    local L = luaL_newstate()
    luaL_openlibs(L)

    lua_pushinteger(L, native.create_cmd_handler());
    lua_setfield(L, LUA_GLOBALSINDEX, "native_cmd_handler");

    lua_pushcclosure(L, pivot_handler.gadget_addr, 1);
    lua_setfield(L, LUA_GLOBALSINDEX, "native_invoke");

    lua_pushstring(L, serialize(data_from_loader))
    lua_setfield(L, LUA_GLOBALSINDEX, "_data_from_loader");

    local ret = luaL_loadstring(L, lua_runner):tonumber()
    if ret ~= 0 then
        local err = memory.read_null_terminated_string(lua_tolstring(L, -1, 0))
        print(err)
        if opt.client_fd then
            syscall.write(opt.client_fd, err, #err)
            if opt.close_socket_after_finished then
                syscall.close(opt.client_fd)
            end
        end
        return
    end

    local chain = ropchain({
        fcall_stub_padding_size = 0x50000
    })

    -- run lua code
    chain:push_fcall_with_ret(eboot_addrofs.lua_pcall, L, 0, LUA_MULTRET, 0)

    if opt.client_fd then
        if opt.close_socket_after_finished then
            chain:push_syscall(syscall.close, opt.client_fd)
        end
    end

    local thr = thread:new(chain)

    -- spawn lua in new thread
    thr:run()

    return thr
end
