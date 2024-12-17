
thread = {}
thread.__index = thread

function thread.init()
    
    local setjmp = fcall(libc_addrofs.setjmp)

    local jmpbuf_backup = memory.alloc(0x60)

    setjmp(jmpbuf_backup)
    
    local fpu_ctrl_value = memory.read_dword(jmpbuf_backup + 0x40)
    local mxcsr_value = memory.read_dword(jmpbuf_backup + 0x44)

    thread.tid_addr = memory.alloc(0x8)
    thread.jmpbuf = memory.alloc(0x60)

    memory.write_qword(thread.jmpbuf, gadgets["ret"]) -- ret addr
    memory.write_dword(thread.jmpbuf + 0x40, fpu_ctrl_value) -- fpu control word
    memory.write_dword(thread.jmpbuf + 0x44, mxcsr_value) -- mxcsr
end

--
-- thread.run can accept any of the following
--   1) ropchain object
--   2) syscall (eq syscall.write) with parameters
--   3) function addr with parameters
--
function thread.run(obj, ...)
    
    local Thrd_create = fcall(libc_addrofs.Thrd_create)
    
    local self = setmetatable({}, thread)

    local chain = nil
    if obj.stack_base then
        chain = obj
    else
        chain = ropchain({
            fcall_stub_padding_size = 0x50000  -- todo: create pool of fcall stub for thread
        })
        if obj.syscall_no then
            chain:push_syscall_with_ret(obj, ...)
        else
            chain:push_fcall_with_ret(obj, ...)
        end
    end

    -- exit the thread and return retval from last fn invocation
    chain:push_fcall_raw(libc_addrofs.Thrd_exit, function()
        local last_retval = chain.retval_addr[#chain.retval_addr]
        chain:push_set_reg_from_memory("rdi", last_retval)
    end)

    memory.write_qword(thread.jmpbuf+0x10, chain.stack_base) -- rsp - pivot to our ropchain

    local ret = Thrd_create(thread.tid_addr, libc_addrofs.longjmp, thread.jmpbuf):tonumber()
    if ret ~= 0 then
        error("Thrd_create() error: " .. hex(ret))
    end

    self.tid = memory.read_qword(thread.tid_addr)
    self.chain = chain
    return self
end

function thread:join()

    local Thrd_join = fcall(libc_addrofs.Thrd_join)
    local ret_value = memory.alloc(0x8)

    -- will block until thread finish
    local ret = Thrd_join(self.tid, ret_value):tonumber()
    if ret ~= 0 then
        error("Thrd_join() error: " .. hex(ret))
    end

    return memory.read_qword(ret_value)
end