--[[
Title: Color class
Author(s): LiXizhi, 
Date: 2015/6/5
Desc: static functions for color based computations.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");
echo(Color.convert32_16(Color.ToValue("0xffffff")));
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/bit.lua");
local rshift = mathlib.bit.rshift;
local lshift = mathlib.bit.lshift;
local band = mathlib.bit.band;
local bor = mathlib.bit.bor;

local math_floor = math.floor;
local alphaMask = (256*256*256);
local Color = commonlib.gettable("System.Core.Color");

function Color.ConvertColorToRGBAString(color)
	if(color and string.find(color, "#")~=nil) then
		color = string.gsub(string.gsub(color, "#", ""), "(%x%x)", function (h)
			return tonumber(h, 16).." "
		end);
	end
	return color;
end


-- helper function for hsl2rgb
local function funcRGBHelper(v1, v2, h)
	if h < 0 then
		h = h + 1
	elseif h > 1 then
		h = h - 1
	end
	if h < 1/6 then
		return v1 + (v2 - v1) * 6 * h
	elseif h < 1/2 then
		return v2
	elseif h < 2/3 then
		return v1 + (v2 - v1) * (2/3 - h) * 6
	else
		return v1
	end
end

-- convert HSL to RGB
-- hsl is [0, 1]
function Color.hsl2rgb(h, s, l)
	--if s == 0 then
		--return 255, 255, 255
	--end

	local v2
	if l < 0.5 then
		v2 = l * (1+s)
	else
		v2 = (l + s) - (s * l)
	end
	local v1 = 2*l - v2

	local r = funcRGBHelper(v1, v2, h + 1/3)
	local g = funcRGBHelper(v1, v2, h)
	local b = funcRGBHelper(v1, v2, h - 1/3)
	return math_floor(r*255), math_floor(g*255), math_floor(b*255)
end

-- convert RGB to HSL
-- inputs are [0, 255]
function Color.rgb2hsl(r, g, b)
	r = r/255;
	g = g/255;
	b = b/255;
	local min = math.min(r, g, b)
	local max = math.max(r, g, b)
	local delta = max - min

	local l = (max + min)/2

	if delta == 0 then
		return 0, 0, l
	end

	local s
	if l < 0.5 then
		s = delta / (max + min)
	else
		s = delta / (2 - max - min)
	end

	local deltaR = (max - r)/(6*delta) + 1/2
	local deltaG = (max - g)/(6*delta) + 1/2
	local deltaB = (max - b)/(6*delta) + 1/2

	local h
	if r == max then
		h = deltaB - deltaG
	elseif g == max then
		h = 1/3 + deltaR - deltaB
	elseif b == max then
		h = 2/3 + deltaG - deltaR
	end
	if h < 0 then
		h = h + 1
	elseif h > 1 then
		h = h - 1
	end

	return h, s, l
end

-- @param r, g, b, a: each in [0,255]
function Color.RGBA_TO_DWORD(r, g, b, a)
	local c=0;
	if(a~=nil) then
	 	c=c+a*alphaMask
	 else
		c=c+255*alphaMask
	end
	
	if(r~=nil) then
	 	c=c+r*(256*256)
	end
	if(g~=nil) then
	 	c=c+g*(256)
	end
	if(b~=nil) then
	 	c=c+b;
	end
	return c;
end

-- convert from color string to dwColor
-- if alpha is not provided. the returned wColor will also not contain alpha. 
-- @param color: can be "#FFFFFF" or "#FFFFFF00" with alpha
function Color.ColorStr_TO_DWORD(color)
	if(string.find(color, "#")~=nil) then
		local dwColor = 0;
		color = string.gsub(string.gsub(color, "#", ""), "(%x%x)", function (h)
			dwColor = dwColor*256 + tonumber(h, 16);
		end);
		return dwColor;
	else
		color = tonumber(color);
	end
	return 0;
end

-- @return r,g,b,a in [0,1] range
function Color.ColorStr_TO_RGBAfloat(color)
	if(string.find(color, "#")~=nil) then
		local dwColor = 0;
		local r,g,b,a;
		color = string.gsub(string.gsub(color, "#", ""), "(%x%x)", function (h)
			h = tonumber(h, 16) / 255;
			if(not r) then
				r = h
			elseif(not g) then
				g = h
			elseif(not b) then
				b = h
			elseif(not a) then
				r,g,b,a = g, b, h, r
			end
		end);
		return r, g, b, a;
	end
	return 0,0,0;
end

-- @param r,g,b,a in [0,1] range
-- @return #ffffff or #ffffff00
function Color.RGBAfloat_TO_ColorStr(r,g,b,a)
	if(not a) then
		return string.format("#%02x%02x%02x", math.floor(r*255+0.5), math.floor(g*255+0.5), math.floor(b*255+0.5));
	else
		return string.format("#%02x%02x%02x%02x", math.floor(r*255+0.5), math.floor(g*255+0.5), math.floor(b*255+0.5), math.floor(a*255+0.5));
	end
end

-- @param r, g, b, a: each in [0,255]
-- @return r, g, b, a: each in [0,255]
function Color.DWORD_TO_RGBA(w)
	local r, g, b, a;
	
	local b = w - math_floor( w / 256 ) * 256;
	w = (w - b) / 256;
	
	local g = w - math_floor( w / 256 ) * 256;
	w = (w - g) / 256;
	
	local r = w - math_floor( w / 256 ) * 256;
	w = (w - r) / 256;
	
	local a = w - math_floor( w / 256 ) * 256;
	w = (w - a) / 256;
	
	return r, g, b, a;
end

-- from DWORD color to h,s,l in [0,1] range
function Color.ColorToHSL(color)
	local r,g,b = Color.DWORD_TO_RGBA(color);
	return Color.rgb2hsl(r, g, b);
end

-- from h,s,l in [0,1] range to DWORD color (alpha is 1)
-- @param alpha:[0,1] default to 1.
function Color.HSLToColor(h, s, l, a)
	local r,g,b = Color.hsl2rgb(h,s,l);
	if(a) then
		a = math.floor(a * 256);
	end
	return Color.RGBA_TO_DWORD(r, g, b, a);
end

-- convert 32bits color to 16bits
function Color.convert32_16(rgb)
    local a = rshift(band(rgb, 0xF0000000), 16);
    local r = rshift(band(rgb, 0x00F00000), 12);
    local g = rshift(band(rgb, 0x0000F000),  8);
    local b = rshift(band(rgb, 0x000000F0),  4);
    return a+r+g+b;
end

-- convert 16bits color to 32bits(default)
function Color.convert16_32(rgb)
    local a = lshift(band(rgb, 0xF000), 16);
	a = a + rshift(a, 4);
    local r = lshift(band(rgb, 0x0F00), 12);
	r = r + rshift(r, 4);
    local g = lshift(band(rgb, 0x00F0),  8);
	g = g + rshift(g, 4);
    local b = lshift(band(rgb, 0x000F),  4);
	b = b + rshift(b, 4);
    return a+r+g+b;
end

-- convert 32bits color to 8bits
function Color.convert32_8(rgb)
    local a = rshift(band(rgb, 0xC0000000), 24);
    local r = rshift(band(rgb, 0x00C00000), 18);
    local g = rshift(band(rgb, 0x0000C000), 12);
    local b = rshift(band(rgb, 0x000000C0),  6);
    return a+r+g+b;
end

-- convert 8bits color to 32bits(default)
function Color.convert8_32(rgb)
	local a = lshift(band(rgb, 0xC0), 24);
	a = a + rshift(a, 2)+rshift(a, 4) + rshift(a, 6);
    local r = lshift(band(rgb, 0x30), 18);
	r = r + rshift(r, 2)+rshift(r, 4) + rshift(r, 6);
    local g = lshift(band(rgb, 0xC ), 12);
	g = g + rshift(g, 2)+rshift(g, 4) + rshift(g, 6);
    local b = lshift(band(rgb, 0x3 ),  6);
	b = b + rshift(b, 2)+rshift(b, 4) + rshift(b, 6);
    return a+r+g+b;
end

-- convert 8bits color to 32bits(without alpha)
function Color.convert8_24(rgb)
	local r = lshift(band(rgb, 0x30), 18);
	r = r + rshift(r, 2)+rshift(r, 4) + rshift(r, 6);
    local g = lshift(band(rgb, 0xC ), 12);
	g = g + rshift(g, 2)+rshift(g, 4) + rshift(g, 6);
    local b = lshift(band(rgb, 0x3 ),  6);
	b = b + rshift(b, 2)+rshift(b, 4) + rshift(b, 6);
    return r+g+b;
end


-- @param color: either 0xffffff, or string like "#ff0000"
function Color.ToValue(color)
	if(type(color) == "string") then
		color = color:gsub("^#", "0x");
		color = tonumber(color);
	end
	return color;
end

-- @param color: DWORD
-- @return string like "#ffffff", if alpha is not 0, we will output like "#000000ff"
function Color.FromValueToStr(color)
	if(type(color) == "number") then
		local a = rshift(band(color, 0xFF000000), 24);
		local r = rshift(band(color, 0x00FF0000), 16);
		local g = rshift(band(color, 0x0000FF00), 8);
		local b = band(color, 0x000000FF);
		if(a == 0) then
			color = string.format("#%02x%02x%02x", r, g, b);
		else
			color = string.format("#%02x%02x%02x%02x", r, g, b, 1);
		end
	end
	return color;
end

-- change the opacity of the input color to given value and return the result color as DWORD. 
-- @param color: either 0xffffff, or string like "#ff0000"
-- @param opacity: [0-255], if nil, default to 255. 
-- @return the color DWORD with the changed opacity
function Color.ChangeOpacity(color, opacity)
	if(type(color) == "string") then
		color = Color.ToValue(color);
	end
	return (opacity or 255)*alphaMask + band(color, 0xffffff)
end

local color1_num = {};
local color2_num = {};

-- @param color1 and color2: string like "#ff0000"
function Color.Multiply(color1, color2)
	color1_num[4] = nil;
	color2_num[4] = nil;
	local color_index = 1;
	for s in string.gfind(color1,"%x%x") do
		color1_num[color_index] = tonumber(s, 16);
		color_index = color_index + 1;
	end
	color_index = 1;
	for s in string.gfind(color2,"%x%x") do
		color2_num[color_index] = tonumber(s, 16);
		color_index = color_index + 1;
	end

	local color_num = {};
	for i = 1,3 do
		color_num[i] = color1_num[i] * color2_num[i] / 255;
	end

	local color = "#";
	for i = 1, 3 do
		color = color..string.format("%02x", color_num[i]);
	end

	if (#color1_num > 3 and #color2_num > 3) then
		color = color..string.format("%02x", color1_num[4] * color2_num[4] / 255);
	elseif (#color1_num > 3) then
		color = color..string.format("%02x", color1_num[4]);
	elseif (#color2_num > 3) then
		color = color..string.format("%02x", color2_num[4]);
	end

	return color;
end