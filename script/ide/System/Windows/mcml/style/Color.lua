--[[
Title: 
Author(s): LiPeng
Date: 2018/2/8
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/Color.lua");
local Color = commonlib.gettable("System.Windows.mcml.style.Color");
local color = Color.CreateFromCssColor("#0000ff00");
echo(color);
color = Color.CreateFromCssColor("rgba(255,0,0,0.5)");
echo(color);
color = Color.CreateFromCssColor("hsla(120,65%,75%,0.3)");
echo(color);
color = Color.CreateFromCssColor("wheat");
echo(color);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Color.lua");
local ColorHelper = commonlib.gettable("System.Core.Color");

local Color = commonlib.gettable("System.Windows.mcml.style.Color");
Color.__index = Color;

-- {family="System", size=10, bold=true}
-- "System;14;bold"
function Color:new(r, g, b, a)
	local o = {};

	o.r = r or 0;
	o.g = g or 0;
	o.b = b or 0;
	o.a = a or 255;

	o.valid = if_else(r, true, false);

	setmetatable(o, self);
	return o;
end

function Color:ToDWORD()
	return ColorHelper.RGBA_TO_DWORD(self.r, self.g, self.b, self.a);
end

function Color:clone()
	return Color:new(self.r, self.g, self.b, self.a);
end

function Color:IsValid()
	return self.valid;
end

function Color:Alpha()
	return self.a;
end

function Color._eq(a, b)
	return a.r == b.r and a.g == b.g and a.b == b.b and a.a == b.a and a.valid == b.valid;
end

local presetColors = {
	["aliceblue"]="#f0f8ff",
	["antiquewhite"]="#faebd7",
	["aqua"]="#00ffff",
	["aquamarine"]="#7fffd4",
	["azure"]="#f0ffff",
	["beige"]="#f5f5dc",
	["bisque"]="#ffe4c4",
	["black"]="#000000",
	["blanchedalmond"]="#ffebcd",
	["blue"]="#0000ff",
	["blueviolet"]="#8a2be2",
	["brown"]="#a52a2a",
	["burlywood"]="#deb887",
	["cadetblue"]="#5f9ea0",
	["chartreuse"]="#7fff00",
	["chocolate"]="#d2691e",
	["coral"]="#ff7f50",
	["cornflowerblue"]="#6495ed",
	["cornsilk"]="#fff8dc",
	["crimson"]="#dc143c",
	["cyan"]="#00ffff",
	["darkblue"]="#00008b",
	["darkcyan"]="#008b8b",
	["darkgoldenrod"]="#b8860b",
	["darkgray"]="#a9a9a9",
	["darkgreen"]="#006400",
	["darkkhaki"]="#bdb76b",
	["darkmagenta"]="#8b008b",
	["darkolivegreen"]="#556b2f",
	["darkorange"]="#ff8c00",
	["darkorchid"]="#9932cc",
	["darkred"]="#8b0000",
	["darksalmon"]="#e9967a",
	["darkseagreen"]="#8fbc8f",
	["darkslateblue"]="#483d8b",
	["darkslategray"]="#2f4f4f",
	["darkturquoise"]="#00ced1",
	["darkviolet"]="#9400d3",
	["deeppink"]="#ff1493",
	["deepskyblue"]="#00bfff",
	["dimgray"]="#696969",
	["dodgerblue"]="#1e90ff",
	["feldspar"]="#d19275",
	["firebrick"]="#b22222",
	["floralwhite"]="#fffaf0",
	["forestgreen"]="#228b22",
	["fuchsia"]="#ff00ff",
	["gainsboro"]="#dcdcdc",
	["ghostwhite"]="#f8f8ff",
	["gold"]="#ffd700",
	["goldenrod"]="#daa520",
	["gray"]="#808080",
	["green"]="#008000",
	["greenyellow"]="#adff2f",
	["honeydew"]="#f0fff0",
	["hotpink"]="#ff69b4",
	["indianred"]="#cd5c5c",
	["indigo"]="#4b0082",
	["ivory"]="#fffff0",
	["khaki"]="#f0e68c",
	["lavender"]="#e6e6fa",
	["lavenderblush"]="#fff0f5",
	["lawngreen"]="#7cfc00",
	["lemonchiffon"]="#fffacd",
	["lightblue"]="#add8e6",
	["lightcoral"]="#f08080",
	["lightcyan"]="#e0ffff",
	["lightgoldenrodyellow"]="#fafad2",
	["lightgrey"]="#d3d3d3",
	["lightgreen"]="#90ee90",
	["lightpink"]="#ffb6c1",
	["lightsalmon"]="#ffa07a",
	["lightseagreen"]="#20b2aa",
	["lightskyblue"]="#87cefa",
	["lightslateblue"]="#8470ff",
	["lightslategray"]="#778899",
	["lightsteelblue"]="#b0c4de",
	["lightyellow"]="#ffffe0",
	["lime"]="#00ff00",
	["limegreen"]="#32cd32",
	["linen"]="#faf0e6",
	["magenta"]="#ff00ff",
	["maroon"]="#800000",
	["mediumaquamarine"]="#66cdaa",
	["mediumblue"]="#0000cd",
	["mediumorchid"]="#ba55d3",
	["mediumpurple"]="#9370d8",
	["mediumseagreen"]="#3cb371",
	["mediumslateblue"]="#7b68ee",
	["mediumspringgreen"]="#00fa9a",
	["mediumturquoise"]="#48d1cc",
	["mediumvioletred"]="#c71585",
	["midnightblue"]="#191970",
	["mintcream"]="#f5fffa",
	["mistyrose"]="#ffe4e1",
	["moccasin"]="#ffe4b5",
	["navajowhite"]="#ffdead",
	["navy"]="#000080",
	["oldlace"]="#fdf5e6",
	["olive"]="#808000",
	["olivedrab"]="#6b8e23",
	["orange"]="#ffa500",
	["orangered"]="#ff4500",
	["orchid"]="#da70d6",
	["palegoldenrod"]="#eee8aa",
	["palegreen"]="#98fb98",
	["paleturquoise"]="#afeeee",
	["palevioletred"]="#d87093",
	["papayawhip"]="#ffefd5",
	["peachpuff"]="#ffdab9",
	["peru"]="#cd853f",
	["pink"]="#ffc0cb",
	["plum"]="#dda0dd",
	["powderblue"]="#b0e0e6",
	["purple"]="#800080",
	["red"]="#ff0000",
	["rosybrown"]="#bc8f8f",
	["royalblue"]="#4169e1",
	["saddlebrown"]="#8b4513",
	["salmon"]="#fa8072",
	["sandybrown"]="#f4a460",
	["seagreen"]="#2e8b57",
	["seashell"]="#fff5ee",
	["sienna"]="#a0522d",
	["silver"]="#c0c0c0",
	["skyblue"]="#87ceeb",
	["slateblue"]="#6a5acd",
	["slategray"]="#708090",
	["snow"]="#fffafa",
	["springgreen"]="#00ff7f",
	["steelblue"]="#4682b4",
	["tan"]="#d2b48c",
	["teal"]="#008080",
	["thistle"]="#d8bfd8",
	["tomato"]="#ff6347",
	["turquoise"]="#40e0d0",
	["violet"]="#ee82ee",
	["violetred"]="#d02090",
	["wheat"]="#f5deb3",
	["white"]="#ffffff",
	["whitesmoke"]="#f5f5f5",
	["yellow"]="#ffff00",
	["yellowgreen"]="#9acd32"
}

local function createFromHex(color_str)
	if(not string.match(color_str,"^#%x+")) then
		return nil;
	end
	if(string.match(color_str,"^#%x%x%x$")) then
		color_str = string.gsub(color_str,"%x","%1%1");
	end

	local r, g, b, a = string.match(color_str, "^#(%x%x)(%x%x)(%x%x)(%x*)");
	if(r and g and b) then
		r, g, b = tonumber("0x"..r), tonumber("0x"..g), tonumber("0x"..b);
		if(a) then
			a = tonumber("0x"..a);
		end
		return Color:new(r, g, b, a);
	end

	return nil;
end

local function createFromRGBA(color_str)
	if(not string.match(color_str,"^rgb.+")) then
		return nil;
	end
	local r, g, b, a = string.match(color_str,"(%d+),(%d+),(%d+),?(%d*[.]?%d*)");
	if(r and g and b) then
		r, g, b = tonumber(r), tonumber(g), tonumber(b);
		if(a) then
			a = a * 256 - 1;
		end
		return Color:new(r, g, b, a);
	end
	return nil;
end

local function createFromHSLA(color_str)
	if(not string.match(color_str,"^hsl.+")) then
		return nil;
	end

	local h,s,l,a = string.match(color_str,"(%d+),(%d+)%%,(%d+)%%,?(%d*[.]?%d*)");

	if(h and s and l) then
		h, s, l = h%360, s/100, l/100;
		local r,g,b = ColorHelper.hsl2rgb(h, s, l);
		if(a) then
			a = math.floor(a * 255 + 0.5);
		end
		return Color:new(r, g, b, a);
	end
	return nil;
end

local function createFromPreset(color_str)
	local color_str = presetColors[color_str];
	if(color_str) then
		return createFromHex(color_str);
	end
	return nil;
end

function Color.CreateFromCssColor(color_str)
	color_str = string.lower(color_str);
	
	local color = createFromHex(color_str);
	if(color) then
		return color;
	end

	color = createFromPreset(color_str);
	if(color) then
		return color;
	end

	color = createFromRGBA(color_str);
	if(color) then
		return color;
	end

	color = createFromHSLA(color_str);
	if(color) then
		return color;
	end

	LOG.std(nil, "warn", "Color.CreateFromCssColor", "\"%s\" is invalid css color format!", color_str);

	return Color:new();
end

Color.black = createFromHex("#000000FF");
Color.white = createFromHex("#FFFFFFFF");
Color.darkGray = createFromHex("#808080FF");
Color.gray = createFromHex("#A0A0A0FF");
Color.lightGray = createFromHex("#C0C0C0FF");
Color.transparent = createFromHex("#00000000");