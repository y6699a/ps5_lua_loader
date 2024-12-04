-- parts taken from al-azif ftp server. to credits to him. thank you very much.
-- Note! This may crash on the PS5, for some reason.

function sceNetRecv(sockfd, buf, len, flags)
    return syscall.recvfrom(sockfd, buf, len, flags, 0, 0):tonumber()
end

-- __int64 __fastcall send(__int64 a1, __int64 a2, __int64 a3, __int64 a4)
function sceNetSend(sockfd, buf, len, flags)
    return syscall.sendto(sockfd, buf, len, flags, 0, 0):tonumber()
end

function sceNetListen(sockfd, backlog)
    return syscall.listen(sockfd, backlog):tonumber()
end

function sceNetBind(sockfd, addr, addrlen)
    return syscall.bind(sockfd, addr, addrlen):tonumber()
end

function sceNetSocket(domain, type, protocol)
    return syscall.socket(domain, type, protocol):tonumber()
end

function sceNetSocketClose(sockfd)
    return syscall.close(sockfd):tonumber()
end

function sceNetSetsockopt(sockfd, level, optname, optval, optlen)
    return syscall.setsockopt(sockfd, level, optname, optval, optlen):tonumber()
end

function sceNetHtonl(hostlong)
    return bit32.bor(
        bit32.lshift(bit32.band(hostlong, 0xFF), 24),
        bit32.lshift(bit32.band(hostlong, 0xFF00), 8),
        bit32.rshift(bit32.band(hostlong, 0xFF0000), 8),
        bit32.rshift(bit32.band(hostlong, 0xFF000000), 24)
    )
end

function sceNetHtons(hostshort)
    return bit32.bor(
        bit32.lshift(bit32.band(hostshort, 0xFF), 8),
        bit32.rshift(bit32.band(hostshort, 0xFF00), 8)
    )
end

function sceNetAccept(sockfd, addr, addrlen)
    return syscall.accept(sockfd, addr, addrlen):tonumber()
end

function sceListenFTP(ftp_port)
    local server_sock = sceNetSocket(AF_INET, SOCK_STREAM, 0)
    if server_sock < 0 then
        error("sceNetSocket() error: " .. get_error_string())
    end

    local s_enable = bump.alloc(4)
    local s_sockaddr_in = bump.alloc(16) -- sizeof(sockaddr_in)
    local s_sockaddr_len = 16

    memory.write(s_enable, 1)
    if sceNetSetsockopt(server_sock, 0xffff, 4, s_enable, 4) < 0 then
        error("sceNetSetsockopt() error: " .. get_error_string())
    end

    memory.write_byte(s_sockaddr_in + 1, AF_INET)
    memory.write_word(s_sockaddr_in + 2, sceNetHtons(ftp_port))
    memory.write_dword(s_sockaddr_in, sceNetHtonl(INADDR_ANY))

    if sceNetBind(server_sock, s_sockaddr_in, s_sockaddr_len) < 0 then -- 16 being size of sockaddr_in
        error("sceNetBind() error: " .. get_error_string())
    end

    -- if we've come this far, then good.
    if sceNetListen(server_sock, 128) < 0 then
        error("sceNetListen() error: " .. get_error_string())
    end

    -- Todo!
    -- Spawn a thread to accept incoming clients.
    -- Add commands, such as LIST, PWD, USER, PASV, PORT etc...
    -- sceKernelSendNotificationRequest("FTP Server running on port " .. ftp_port)
end

function main()
    syscall.resolve({
        recvfrom = 29,
        getsockname = 32,
        access = 33,
        sendto = 133, -- this is send.
        stat = 188,
        getdents = 272,
        sendfile = 393,
    })

    sceListenFTP(3232)
end

main()