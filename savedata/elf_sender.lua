--
-- work-in-progress
--
-- This script sends an ELF file to a local server running on port 9021.
-- 


function sceNetSend(sockfd, buf, len, flags, addr, addrlen)
    return syscall.sendto(sockfd, buf, len, flags, addr, addrlen):tonumber()
end
function sceNetConnect(sockfd, addr, addrlen)
    return syscall.connect(sockfd, addr, addrlen):tonumber()
end
function sceNetSocket(domain, type, protocol)
    return syscall.socket(domain, type, protocol):tonumber()
end
function sceNetSocketClose(sockfd)
    return syscall.close(sockfd):tonumber()
end

function ip_to_dword(ip)
    local a, b, c, d = ip:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")
    return bit32.lshift(tonumber(a), 24) + bit32.lshift(tonumber(b), 16) + bit32.lshift(tonumber(c), 8) + tonumber(d)
end
function htons(port)
    return bit32.bor(bit32.lshift(port, 8), bit32.rshift(port, 8)) % 0x10000
end

elf_sender = {}
elf_sender.__index = elf_sender

function elf_sender:load_from_file(filepath)
    if not file_exists(filepath) then
        errorf("file does not exist: %s", filepath)
    end

    local self = setmetatable({}, elf_sender)
    self.filepath = filepath
    self.elf_data = file_read(filepath)
    self.elf_size = #self.elf_data

    print("elf size:", self.elf_size)
    return self
end

syscall.resolve(
    {
        sendto = 133
    }
)

function send_elf_to_localhost(filepath)
    local elf = elf_sender:load_from_file(filepath)
    local elf_data = elf.elf_data

    local sockfd = sceNetSocket(2, 1, 0)
    print("Socket fd:", sockfd)
    assert(sockfd >= 0, "socket creation failed")

    local sock_fd = syscall.socket(AF_INET, SOCK_STREAM, 0):tonumber()

    if sock_fd < 0 then
        error("socket() error: " .. get_error_string())
    end
    local enable = memory.alloc(4)
    memory.write_dword(enable, 1)
    syscall.setsockopt(sockfd, 1, 2, enable, 4) -- SOL_SOCKET=1, SO_REUSEADDR=2

    local sockaddr = memory.alloc(16)

    memory.write_byte(sockaddr + 0, 16)
    memory.write_byte(sockaddr + 1, 2) -- AF_INET
    memory.write_word(sockaddr + 2, htons(9021)) -- Port

    memory.write_byte(sockaddr + 4, 0x7F) -- 127
    memory.write_byte(sockaddr + 5, 0x00) -- 0
    memory.write_byte(sockaddr + 6, 0x00) -- 0
    memory.write_byte(sockaddr + 7, 0x01) -- 1

    local buf = memory.alloc(#elf_data)
    memory.write_buffer(buf, elf_data)

    local total_sent = sceNetSend(sockfd, buf, #elf_data, 0, sockaddr, 16)
    print("Sendto result:", total_sent)
    sceNetSocketClose(sockfd)
    print(string.format("Successfully sent %d bytes to loader", total_sent))
end

local filetoload = "/mnt/usb0/test.elf"
if file_exists(filetoload) then
    send_elf_to_localhost(filetoload)
else
    print("[-] File not found: " .. filetoload)
end

