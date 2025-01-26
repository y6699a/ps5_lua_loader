
FD_SETSIZE = 1024
_NFDBITS = 64

function create_fd_set()
    return memory.alloc(8 * 16)
end

function FD_ZERO(p)
    for i=0,16-1 do
        memory.write_qword(p + i*8, 0)
    end
end

function FD_SET(n, p)
    local idx = math.floor(n / _NFDBITS)
    local cur = memory.read_qword(p + idx*8)
    cur = bit64.bor(cur, bit64.lshift(1, n % _NFDBITS))
    memory.write_qword(p + idx*8, cur)
end

function read_klog()

    local data_size = PAGE_SIZE
    local data_mem = memory.alloc(data_size)

    local flags = bit32.bor(O_RDONLY, O_NONBLOCK)

    local klog_fd = syscall.open("/dev/klog", flags):tonumber()
    if klog_fd == -1 then
        error("open() error: " .. get_error_string())
    end

    local readfds = create_fd_set()
    local timeval = memory.alloc(0x10)

    memory.write_dword(timeval, 0) -- tv_sec
    memory.write_dword(timeval + 8, 1000*10) -- tv_usec (10ms)

    FD_ZERO(readfds)
    FD_SET(klog_fd, readfds)

    local cur_read = 0

    while true do

        local select_ret = syscall.select(FD_SETSIZE, readfds, nil, nil, timeval):tonumber()

        if select_ret == -1 then -- error
            error("select() error: " .. get_error_string())
            break

        elseif select_ret == 0 then -- time	limit expires
            break

        else
            local read_size = syscall.read(klog_fd, data_mem + cur_read, data_size - cur_read):tonumber()
            cur_read = cur_read + read_size

            -- write klog data to client
            if cur_read >= data_size then
                syscall.write(client_fd, data_mem, cur_read)
                cur_read = 0
            end
        end
    end

    -- write any leftover data to client
    if cur_read > 0 then
        syscall.write(client_fd, data_mem, cur_read)
    end

    syscall.close(klog_fd)
end


function main()

    syscall.resolve({
        select = 0x5d
    })

    if not is_curproc_jailbroken() then
        error("current process is not jailbroken")
    end

    read_klog()
end

main()
