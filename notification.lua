sceKernelGetProcParam__Aibeya = 0x3A8

-- sceKernelGetProcParam is accessed from libc.
-- we can use this to traverse into libkernel and find notification.
sceKernelSendNotificationRequest__Address = nil

function read_jump(insaddr, dis)
    return memory.read_dword(insaddr + 6 + dis):tonumber()
end

function locate_notify()
    local match = libc_base + sceKernelGetProcParam__Aibeya -- Todo: set this in gadget_table
    local offset = memory.read_dword(match + 2)
    if PLATFORM == "ps4" then
        local distance = 0x3b0
        sceKernelSendNotificationRequest__Address = libkernel_base:tonumber() + read_jump(match, offset) - distance
        printf("sceKernelGetProcParam: offset -> %x", sceKernelSendNotificationRequest__Address - distance)
        printf("sceKernelSendNotificationRequest: offset -> %x\n", sceKernelSendNotificationRequest__Address)
    elseif PLATFORM == "ps5" then
        local distance = 0x360
        sceKernelSendNotificationRequest__Address = libkernel_base:tonumber() + read_jump(match, offset) - distance
        printf("sceKernelGetProcParam: offset -> %x", sceKernelSendNotificationRequest__Address - distance)
        printf("sceKernelSendNotificationRequest: offset -> %x\n", sceKernelSendNotificationRequest__Address)
    end
end

function sceKernelSendNotificationRequestFn(a1, a2, a3, a4)
    local sceKernelSendNotificationRequestAddr = function_rop(sceKernelSendNotificationRequest__Address)
    if sceKernelSendNotificationRequestAddr(a1, a2, a3, a4):tonumber() ~= 0 then
        error("sceKernelSendNotificationRequest() error! Address may be wrong.")
        return nil
    end
end

function sceKernelSendNotificationRequest(text)
    local size = 3120
    local notification = bump.alloc(3120)
    local icon_uri = "cxml://psnotification/tex_icon_system"

    memory.write_dword(notification, 0)
    memory.write_dword(notification + 40, 0)
    memory.write_dword(notification + 44, 1)
    memory.write_dword(notification + 16, -1)
    memory.write_buffer(notification + 1069, icon_uri)
    memory.write_buffer(notification + 45, text .. "\0")

    sceKernelSendNotificationRequestFn(0, notification, size, 0)
end

function main()
    locate_notify()
    sceKernelSendNotificationRequest("Hello from Remote Lua Loader")
end

main()