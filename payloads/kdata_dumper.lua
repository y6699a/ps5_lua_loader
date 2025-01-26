
--[[
    run netcat on the other end to receives the kernel .data dump
    $ nc -nlvp 5656 > kernel_data_dump.bin
]]

IP = "192.168.1.2"
PORT = 5656

function htons(port)
    return bit32.bor(bit32.lshift(port, 8), bit32.rshift(port, 8)) % 0x10000
end

function aton(ip)
    local a, b, c, d = ip:match("(%d+).(%d+).(%d+).(%d+)")
    return bit32.bor(bit32.lshift(d, 24), bit32.lshift(c, 16), bit32.lshift(b, 8), a)
end

function dump_kdata_over_network(IP, PORT)

    local sock_fd = syscall.socket(AF_INET, SOCK_STREAM, 0):tonumber()
    if sock_fd == -1 then
        error("socket() error: " .. get_error_string())
    end

    local sockaddr_in = memory.alloc(16)

    memory.write_byte(sockaddr_in + 1, AF_INET) -- sin_family
    memory.write_word(sockaddr_in + 2, htons(PORT)) -- sin_port
    memory.write_dword(sockaddr_in + 4, aton(IP)) -- sin_addr

    printf("trying to connect to %s:%d. fd = %d", IP, PORT, sock_fd)

    if syscall.connect(sock_fd, sockaddr_in, 16):tonumber() == -1 then
        error("connect() error: " .. get_error_string())
    end

    print("connected sucessfully")

    local start_index = 0
    local end_index = kernel_offset.DATA_SIZE
    
    local read_size = PAGE_SIZE
    local mem = memory.alloc(read_size)

    for index = start_index, end_index-1, read_size do

        local total_read = index - start_index

        if total_read % (5 * 0x100000) == 0 then
            printf("dumping kernel .data: %d / %.2f mb", total_read / 0x100000, end_index / 0x100000)
        end

        kernel.copyout(kernel.addr.data_base + index, mem, read_size)

        if syscall.write(sock_fd, mem, read_size):tonumber() == -1 then
            error("write() error: " .. get_error_string())
            break
        end
    end

    printf("dumped %.2f mb of kernel data", end_index / 0x100000)

end


function main()

    if not is_kernel_rw_available() then
        error("kernel r/w is not available")
    end

    dump_kdata_over_network(IP, PORT)

end

main()

