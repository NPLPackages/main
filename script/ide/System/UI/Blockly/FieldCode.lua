local FieldCode = NPL.export();


function FieldCode.RGBToRGB565(color)
    color = string.sub(color, 2);
    local R = tonumber("0x" .. string.sub(color, 1, 2), 16)
    local G = tonumber("0x" .. string.sub(color, 3, 4), 16)
    local B = tonumber("0x" .. string.sub(color, 5, 6), 16)
    color = mathlib.bit.bor(mathlib.bit.lshift(R, 16), mathlib.bit.lshift(G, 8), B)
    local RGB565_red = mathlib.bit.rshift(mathlib.bit.band(color, 0xf80000), 19)
    local RGB565_green = mathlib.bit.rshift(mathlib.bit.band(color, 0xfc00), 10)
    local RGB565_green1 = mathlib.bit.rshift(mathlib.bit.band(RGB565_green, 0x38), 3)
    local RGB565_green2 = mathlib.bit.band(RGB565_green, 0x07)
    local RGB565_blue = mathlib.bit.rshift(mathlib.bit.band(color, 0xf8), 3)

    local n565Color = mathlib.bit.bor(mathlib.bit.lshift(RGB565_blue, 8),mathlib.bit.lshift(RGB565_green2, 13), mathlib.bit.lshift(RGB565_red, 3), mathlib.bit.lshift(RGB565_green1, 0))

    return n565Color
end

function FieldCode.ToValidParamName(value)
    return commonlib.Encoding.toValidParamName(value);
end