
--
-- uint64 class
--
-- constructor accepts:
-- 1) uint64 instance
-- 2) hex value in string ("0xaabb")
-- 3) lua number
--
-- note: from llm and refined over time. might have some bugs
--

uint64 = {}
uint64.__index = uint64

setmetatable(uint64, {
    __call = function(_, v) -- make class callable
        return uint64:new(v)
    end
})

function is_uint64(v)
    return type(v) == "table" and v.h and v.l and true or false
end

function ub8(n) 
    return uint64(n):pack() 
end

function hex(v)
    if is_uint64(v) then
        return tostring(v)
    elseif type(v) == "number" then
        return string.format("0x%x", v)
    else
        errorf("hex: unknown type (%s) for value %s", type(v), tostring(v))
    end
end

function uint64:new(v)

    local self = setmetatable({}, uint64)

    if is_uint64(v) then
        self.h, self.l = v.h, v.l
    elseif type(v) == "number" then
        self.h, self.l = math.floor(v / 2^32), v % 2^32
    elseif type(v) == "string" then
        if v:sub(1, 2):lower() == "0x" then  -- init from hexstring
            v = v:sub(3):gsub("^0+", ""):upper()
            if #v > 16 then
                errorf("uint64:new: hex string too long for uint64 (%s)", v)
            end
            v = string.rep("0", 16 - #v) .. v  -- pad with leading zeros
            self.h = tonumber(v:sub(1, 8), 16) or 0
            self.l = tonumber(v:sub(9, 16), 16) or 0
        else
            local num = tonumber(v)  -- assume its normal number
            if not num then
                errorf("uint64:new: invalid decimal string for uint64 (%s)", v)
            end
            self.h, self.l = math.floor(num / 2^32), num % 2^32
        end
    else
        errorf("uint64:new: invalid type passed to constructor (%s)", type(v))
    end

    return self
end

function uint64:__tostring()
    local hex = string.format("%x%08x", self.h, self.l):gsub("^0+", "")
    return "0x" .. (hex == "" and "0" or hex)
end

function uint64:tonumber()
    if self.h >= 0x80000000 then -- for negative number
        return -(bit32.bnot(self.h) * 2^32 + bit32.bnot(self.l) + 1)
    else
        return self.h * 2^32 + self.l
    end
end

function uint64:pack()
    return struct.pack("<I", self.l) .. struct.pack("<I", self.h)
end

function uint64.unpack(str)
    if type(str) ~= "string" or #str > 8 then
        error("uint64.unpack: input string must be 8 bytes length or lower")
    end
    if #str < 8 then
        str = str .. string.rep('\0', 8 - #str)
    end
    return uint64({
        h = struct.unpack("<I", str:sub(5,8)),
        l = struct.unpack("<I", str:sub(1,4))
    })
end

-- note: comparison ops only work if both are same type

function uint64:__eq(v)
    v = uint64(v)
    return self.h == v.h and self.l == v.l
end

function uint64:__lt(v)
    v = uint64(v)
    return self.h < v.h or (self.h == v.h and self.l < v.l)
end

function uint64:__le(v)
    v = uint64(v)
    return self.h < v.h or (self.h == v.h and self.l <= v.l)
end

function uint64:__add(v)
    v = uint64(v)
    local l = self.l + v.l
    local h = self.h + v.h + (l >= 2^32 and 1 or 0)
    return uint64({h = h % 2^32, l = l % 2^32})
end

function uint64:__sub(v)
    v = uint64(v)
    local l = self.l - v.l
    local h = self.h - v.h - (l < 0 and 1 or 0)
    return uint64({h = (h + 2^32) % 2^32, l = (l + 2^32) % 2^32})
end

function uint64:__mul(v)
    v = uint64(v)
    local ah, al, bh, bl = self.h, self.l, v.h, v.l
    local h = ah * bl + al * bh
    local l = al * bl
    return uint64({h = (h + bit32.rshift(l, 32)) % 2^32, l = l % 2^32})
end

function uint64:divmod(v)
    v = uint64(v)
    if v.h == 0 and v.l == 0 then
        error("division by zero")
    end
    local q, r = uint64(0), uint64(0)
    for i = 63, 0, -1 do
        r = bit64.lshift(r, 1)
        if bit32.rshift(self.h, i % 32) % 2 == 1 or (i < 32 and bit32.rshift(self.l, i) % 2 == 1) then
            r = r + 1
        end
        if r >= v then
            r = r - v
            q = q + bit64.lshift(1, i)
        end
    end
    return q, r
end

function uint64:__div(v) return select(1, self:divmod(v)) end
function uint64:__mod(v) return select(2, self:divmod(v)) end


--
-- bitwise operations for uint64 class
--

bit64 = {}

function bit64.lshift(x, s_amount)
    
    x = uint64(x)

    if s_amount >= 64 then
        return uint64(0)
    elseif s_amount >= 32 then
        return uint64({h = bit32.lshift(x.l, s_amount - 32), l = 0})
    else
        local h = bit32.bor(bit32.lshift(x.h, s_amount), bit32.rshift(x.l, 32 - s_amount))
        local l = bit32.lshift(x.l, s_amount)
        return uint64({h = h, l = l})
    end
end

function bit64.rshift(x, s_amount)

    x = uint64(x)

    if s_amount >= 64 then
        return uint64(0)
    elseif s_amount >= 32 then
        return uint64({h = 0, l = bit32.rshift(x.h, s_amount - 32)})
    else
        local h = bit32.rshift(x.h, s_amount)
        local l = bit32.bor(bit32.rshift(x.l, s_amount), bit32.lshift(x.h % (2^s_amount), 32 - s_amount))
        return uint64({h = h, l = l})
    end
end

function bit64.bxor(...)

    local args = {...}
    local result = uint64(args[1]) or 0

    for i = 2, #args do
        local x = uint64(args[i])
        result = uint64({
            h = bit32.bxor(result.h, x.h),
            l = bit32.bxor(result.l, x.l)
        })
    end

    return result
end

function bit64.band(...)

    local args = {...}
    local result = uint64(args[1]) or 0

    for i = 2, #args do
        local x = uint64(args[i])
        result = uint64({
            h = bit32.band(result.h, x.h),
            l = bit32.band(result.l, x.l)
        })
    end

    return result
end

function bit64.bor(...)

    local args = {...}
    local result = uint64(args[1]) or 0

    for i = 2, #args do
        local x = uint64(args[i])
        result = uint64({
            h = bit32.bor(result.h, x.h),
            l = bit32.bor(result.l, x.l)
        })
    end

    return result
end

function bit64.bnot(x)
    
    x = uint64(x)

    return uint64({
        h = bit32.bnot(x.h),
        l = bit32.bnot(x.l)
    })
end
