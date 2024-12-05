sceKernelSendNotificationRequest__Address = nil
function locate_notify()
    if PLATFORM == "ps4" then
        local libkernel_text = memory.read_buffer(libkernel_base, 0x40000)
        local matches = find_pattern(libkernel_text, "55 48 89 E5 41 57 41 56 41 54 53 49 89 F4")
        if matches and matches[1] ~= nil then
            sceKernelSendNotificationRequest__Address = libkernel_base:tonumber() + matches[1] - 1
            printf("sceKernelSendNotificationRequest__Address: %x\n", sceKernelSendNotificationRequest__Address)
        end
    end
end

function sceKernelSendNotificationRequestFn(a1, buffer, size, a4)
    local sceKernelSendNotificationRequestAddr = function_rop(sceKernelSendNotificationRequest__Address)
    if sceKernelSendNotificationRequestAddr(a1, buffer, size, a4):tonumber() ~= 0 then
        error("sceKernelSendNotificationRequest() error! Address may be wrong.")
        return nil
    end
end

function sceKernelSendNotificationRequest(text)
    if PLATFORM == "ps4" then
        if sceKernelSendNotificationRequest__Address == nil then
            locate_notify()
        end
        if sceKernelSendNotificationRequest__Address ~= nil then
            local size = 3120
            local notification = bump.alloc(3121)
            local icon_uri = "cxml://psnotification/tex_icon_system"

            -- credits to OSM-Made for this one. @ https://github.com/OSM-Made/PS4-Notify
            memory.write_dword(notification + 0, 0)            -- type
            memory.write_dword(notification + 0x28, 0)         -- unk3
            memory.write_dword(notification + 0x2C, 1)         -- use_icon_image_uri
            memory.write_dword(notification + 0x10, -1)        -- target_id
            memory.write_buffer(notification + 0x2D, text .. "\0") -- message
            memory.write_buffer(notification + 0x42D, icon_uri) -- uri
            sceKernelSendNotificationRequestFn(0, notification, size, 0)
        end
    end
end

function main()
    sceKernelSendNotificationRequest("Hello world")
end

main()