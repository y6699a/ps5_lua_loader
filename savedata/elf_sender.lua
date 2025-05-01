--
-- elf_sender.lua
--
-- This script is designed to send ELF payloads to a local elf_loader server running on the PS5.
-- It looks for autoload config file (ps5_lua_loader/autoload.txt) in this priority order:
-- - USB drives,
-- - /data directory,
-- - lua game savedata directory.
--
-- The autoload config file should contain the names of ELF payloads that need to be sent.
-- (one ELF file name per line)
-- The script will ignore empty lines and comments (lines starting with #).
-- Lines starting with ! will be treated as sleep commands (e.g., !1000 will sleep for 1000ms).
--
-- The script will send each ELF file to a local server running on port 9021.
--

options = {
    elfs_dirname = "ps5_lua_loader", -- directory where the ELF files and autoload.txt are located
    elfs_autoload_config = "autoload.txt",
}


local function sceNetSend(sockfd, buf, len, flags, addr, addrlen)
    return syscall.sendto(sockfd, buf, len, flags, addr, addrlen):tonumber()
end
local function sceNetSocket(domain, type, protocol)
    return syscall.socket(domain, type, protocol):tonumber()
end
local function sceNetSocketClose(sockfd)
    return syscall.close(sockfd):tonumber()
end
local function htons(port)
    return bit32.bor(bit32.lshift(port, 8), bit32.rshift(port, 8)) % 0x10000
end


elf_sender = {}
elf_sender.__index = elf_sender

AF_INET = 2
SOCK_STREAM = 1

syscall.resolve(
    {
        sendto = 133
    }
)

function elf_sender:load_from_file(filepath)

    if file_exists(filepath) then
        print("Loading elf from:", filepath)
        send_ps_notification("Loading elf from: \n" .. filepath)
    else
        print("[-] File not found:", filepath)
        send_ps_notification("[-] File not found: \n" .. filepath)
    end

    local self = setmetatable({}, elf_sender)
    self.filepath = filepath
    self.elf_data = file_read(filepath)
    self.elf_size = #self.elf_data

    print("elf size:", self.elf_size)
    return self

end


function elf_sender:send_to_localhost(filepath, port)

    local sockfd = sceNetSocket(AF_INET, SOCK_STREAM, 0)
    print("Socket fd:", sockfd)
    assert(sockfd >= 0, "socket creation failed")
    local enable = memory.alloc(4)
    memory.write_dword(enable, 1)
    syscall.setsockopt(sockfd, 1, 2, enable, 4) -- SOL_SOCKET=1, SO_REUSEADDR=2

    local sockaddr = memory.alloc(16)

    memory.write_byte(sockaddr + 0, 16)
    memory.write_byte(sockaddr + 1, AF_INET)
    memory.write_word(sockaddr + 2, htons(port))

    memory.write_byte(sockaddr + 4, 0x7F) -- 127
    memory.write_byte(sockaddr + 5, 0x00) -- 0
    memory.write_byte(sockaddr + 6, 0x00) -- 0
    memory.write_byte(sockaddr + 7, 0x01) -- 1

    local buf = memory.alloc(#self.elf_data)
    memory.write_buffer(buf, self.elf_data)

    local total_sent = sceNetSend(sockfd, buf, #self.elf_data, 0, sockaddr, 16)
    sceNetSocketClose(sockfd)
    if total_sent < 0 then
        print("[-] error sending elf data to localhost")
        send_ps_notification("error sending elf data to localhost")
        return
    end
    print(string.format("Successfully sent %d bytes to loader", total_sent))
end


function main()

        -- Build possible paths, prioritizing USBs first, then /data, then savedata
        local possible_paths = {}
        for usb = 0, 7 do
            table.insert(possible_paths, string.format("/mnt/usb%d/%s/", usb, options.elfs_dirname))
        end
        table.insert(possible_paths, string.format("/data/%s/", options.elfs_dirname))
        table.insert(possible_paths, string.format("/mnt/sandbox/%s_000/savedata0/%s/", get_title_id(), options.elfs_dirname))

        local existing_path = nil
        for _, path in ipairs(possible_paths) do
            if file_exists(path .. options.elfs_autoload_config) then
                existing_path = path
                break
            end
        end

        if not existing_path then
            send_ps_notification("ELF autoload config not found")
            print("[-] ELF autoload config not found")
            return
        end

        print("Loading ELF autoload config from:", existing_path .. options.elfs_autoload_config)
        send_ps_notification("Loading ELF autoload config from: \n" .. existing_path .. options.elfs_autoload_config)
        local config = io.open(existing_path .. options.elfs_autoload_config, "r")

        for config_line in config:lines() do

            if config_line == "" or config_line:sub(1, 1) == "#" then
                -- skip empty lines and comments
            elseif config_line:sub(1, 1) == "!" then
                -- sleep line
                -- usage: !1000 to sleep for 1000ms
                local sleep_time = tonumber(config_line:sub(2))
                if type(sleep_time) ~= "number" then
                    print("[-] Invalid sleep time:", config_line:sub(2))
                    send_ps_notification("[-] Invalid sleep time: \n" .. config_line:sub(2))
                    return
                end
                print(string.format("Sleeping for: %s ms", sleep_time))
                sleep(sleep_time, "ms")
            else
                local full_path = existing_path .. config_line
                if file_exists(full_path) then
                    -- Load the ELF file and send it to localhost on port 9021
                    elf_sender:load_from_file(full_path):send_to_localhost(full_path, 9021)
                else
                    print("[ERROR] File not found:", full_path)
                    send_ps_notification("[ERROR] File not found: \n" .. full_path)
                end

            end

        end
        config:close()
end

main()