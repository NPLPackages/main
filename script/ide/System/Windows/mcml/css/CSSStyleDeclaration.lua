--[[
Title: CSSStyleDeclaration object
Author(s): LiPeng
Date: 2018/1/12
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleDeclaration.lua");
local CSSStyleDeclaration = commonlib.gettable("System.Windows.mcml.css.CSSStyleDeclaration");
local style = CSSStyleDeclaration:new();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");

local type = type;
local tonumber = tonumber;
local string_gsub = string.gsub;
local string_lower = string.lower
local string_match = string.match;
local string_find = string.find;

local CSSStyleDeclaration = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.css.CSSStyleDeclaration"));

function CSSStyleDeclaration:ctor()
	self.pageElement = nil;
end

function CSSStyleDeclaration:init(pageElement)
	self.pageElement = pageElement;
	return self;
end

local property_fields = 
{
	--TODO: add all css properties later
	-- TODO: add css3 animation next step

	-- background
	["background"] = true,
	["background2"] = true,
	["background_checked"] = true,
	["background-color"] = true,
	["background_over"] = true,
	["background_down"] = true,

	-- border ["border"] = "border-width border-style border-color"
	["border-width"] = true,
	["border-style"] = true,
	["border-color"] = true,

	-- box 
	["overflow"] = true,
	["overflow-x"] = true,
	["overflow-y"] = true,

	-- dimension
	["width"] = true,
	["min-width"] = true,
	["max-width"] = true,
	["height"] = true,
	["min-height"] = true,
	["max-height"] = true,

	-- font
	["font"] = true,
	["font-family"] = true,
	["font-size"] = true,
	["font-weight"] = true,

	-- margin
	["margin"] = true,
	["margin-left"] = true,
	["margin-top"] = true,
	["margin-right"] = true,
	["margin-bottom"] = true,

	-- padding
	["padding"] = true,
	["padding-left"] = true,
	["padding-top"] = true,
	["padding-right"] = true,
	["padding-bottom"] = true,

	-- positioning
	["left"] = true,
	["top"] = true,
	["right"] = true,
	["bottom"] = true,
	["align"] = true,
	["valign"] = true,
	["display"] = true,
	["float"] = true,
	["position"] = true,
	["visibility"] = true,
	["z-index"] = true,

	-- text
	["color"] = true,
	["direction"] = true,
	["line-height"] = true,
	["text-align"] = true,
	["text-shadow"] = true,
}

-- merge style with current style. 
function CSSStyleDeclaration:Merge(style)
	if(style) then
		if(type(style) == "table") then
			for key, _ in pairs(property_fields) do
				self[key] = style[key] or self[key];
			end
		elseif(type(style) == "string") then
			self:AddString(style);
		end
	end
end

local inheritable_fields = {
	["color"] = true,
	["font-family"] = true,
	["font-size"] = true,
	["font-weight"] = true,
	["text-shadow"] = true,
};

-- only merge inheritable style like font, color, etc. 
function CSSStyleDeclaration:MergeInheritable(style)
	if(style) then
		for key, _ in pairs(inheritable_fields) do
--			echo(key.." "..(style[key] or "nil"));
			self[key] = style[key];
		end
	end
end

local layout_fields = 
{
	["height"] = true,
	["min-height"] = true,
	["max-height"] = true,
	["width"] = true,
	["min-width"] = true,
	["max-width"] = true,
	["left"] = true,
	["top"] = true,
	["right"] = true,
	["bottom"] = true,

	["margin"] = true,
	["margin-left"] = true,
	["margin-top"] = true,
	["margin-right"] = true,
	["margin-bottom"] = true,

	["padding"] = true,
	["padding-left"] = true,
	["padding-top"] = true,
	["padding-right"] = true,
	["padding-bottom"] = true,

	["border-width"] = true,
}

local number_fields = {
	["height"] = true,
	["min-height"] = true,
	["max-height"] = true,
	["width"] = true,
	["min-width"] = true,
	["max-width"] = true,
	["left"] = true,
	["top"] = true,
	["right"] = true,
	["bottom"] = true,
	["font-size"] = true,
	["spacing"] = true,
	["base-font-size"] = true,
	["border-width"] = true,
};

local color_fields = {
	["color"] = true,
	["border-color"] = true,
	["background-color"] = true,
};


local complex_fields = {
	["border"] = "border-width border-style border-color",
};

function CSSStyleDeclaration.isResetField(name)
	return layout_fields[name];
end

function CSSStyleDeclaration:Diff(changes)
	local style_change_type = "no_change";
	if(next(changes)) then
		for key,_ in pairs(changes) do
			if(layout_fields[key]) then
				return "change_layout";
			end
		end
	end
	return "change_update";
end

-- @param style_code: mcml style attribute string like "background:url();margin:10px;"
function CSSStyleDeclaration:AddString(style_code)
	local name, value;
	for name, value in string.gfind(style_code, "([%w%-]+)%s*:%s*([^;]*)[;]?") do
		name = string_lower(name);
		value = string_gsub(value, "%s*$", "");
		local complex_name = complex_fields[name];
		if(complex_name) then
			self:AddComplexField(complex_name,value);
		else
			self:AddItem(name,value);
		end
	end
end

function CSSStyleDeclaration:AddComplexField(names_code,values_code)
	local names = commonlib.split(names_code, "%s");
	local values = commonlib.split(values_code, "%s");
	for i = 1, #names do
		self:AddItem(names[i], values[i]);
	end
end

function CSSStyleDeclaration:AddItem(name,value)
	if(not name or not value) then
		return;
	end
	name = string_lower(name);
	value = string_gsub(value, "%s*$", "");
	if(number_fields[name] or string_find(name,"^margin") or string_find(name,"^padding")) then
		local _, _, selfvalue = string_find(value, "([%+%-]?%d+[%%]?)");
		if(selfvalue~=nil) then
			value = tonumber(selfvalue);
		else
			value = nil;
		end
	elseif(color_fields[name]) then
		value = StyleColor.ConvertTo16(value);
	elseif(string_match(name, "^background[2]?$") or name == "background-image") then
		value = string_gsub(value, "url%((.*)%)", "%1");
		value = string_gsub(value, "#", ";");
	end
	self[name] = value;
end

function CSSStyleDeclaration:padding_left()
	return (self["padding-left"] or self["padding"] or 0);
end

function CSSStyleDeclaration:padding_right()
	return (self["padding-right"] or self["padding"] or 0);
end

function CSSStyleDeclaration:padding_top()
	return (self["padding-top"] or self["padding"] or 0);
end

function CSSStyleDeclaration:padding_bottom()
	return (self["padding-bottom"] or self["padding"] or 0);
end

-- return left, top, right, bottom
function CSSStyleDeclaration:paddings()
	return self:padding_left(), self:padding_top(), self:padding_right(), self:padding_bottom();
end

function CSSStyleDeclaration:margin_left()
	return (self["margin-left"] or self["margin"] or 0);
end

function CSSStyleDeclaration:margin_right()
	return (self["margin-right"] or self["margin"] or 0);
end

function CSSStyleDeclaration:margin_top()
	return (self["margin-top"] or self["margin"] or 0);
end

function CSSStyleDeclaration:margin_bottom()
	return (self["margin-bottom"] or self["margin"] or 0);
end

-- return left, top, right, bottom
function CSSStyleDeclaration:margins()
	return self:margin_left(), self:margin_top(), self:margin_right(), self:margin_bottom();
end

function CSSStyleDeclaration:border_left_width()
	return (self["border-left-width"] or self["border-left"] or self["border"] or 0);
end

function CSSStyleDeclaration:border_right_width()
	return (self["border-right-width"] or self["border-right"] or self["border"] or 0);
end

function CSSStyleDeclaration:border_top_width()
	return (self["border-top-width"] or self["border-top"] or self["border"] or 0);
end

function CSSStyleDeclaration:border_bottom_width()
	return (self["border-bottom-width"] or self["border-bottom"] or self["border"] or 0);
end

function CSSStyleDeclaration:border_left_color()
	return (self["border-left-color"] or self["border-left"] or self["border"] or "");
end

function CSSStyleDeclaration:border_right_color()
	return (self["border-right-color"] or self["border-right"] or self["border"] or "");
end

function CSSStyleDeclaration:border_top_color()
	return (self["border-top-color"] or self["border-top"] or self["border"] or "");
end

function CSSStyleDeclaration:border_bottom_color()
	return (self["border-bottom-color"] or self["border-bottom"] or self["border"] or "");
end

function CSSStyleDeclaration:border_left_style()
	return (self["border-left-style"] or self["border-left"] or self["border"] or "");
end

function CSSStyleDeclaration:border_right_style()
	return (self["border-right-style"] or self["border-right"] or self["border"] or "");
end

function CSSStyleDeclaration:border_top_style()
	return (self["border-top-style"] or self["border-top"] or self["border"] or "");
end

function CSSStyleDeclaration:border_bottom_style()
	return (self["border-bottom-style"] or self["border-bottom"] or self["border"] or "");
end

-- return left, top, right, bottom
function CSSStyleDeclaration:borders()
	return self:border_left(), self:border_top(), self:border_right(), self:border_bottom();
end
-- text show direction, value can be "LTR", "RTL";
function CSSStyleDeclaration:TextDirection()
	return self["direction"] or "LTR";
end

function CSSStyleDeclaration:Width()
	return self["width"];
end

function CSSStyleDeclaration:MinWidth()
	return self["min-width"];
end

function CSSStyleDeclaration:MaxWidth()
	return self["max-width"];
end

function CSSStyleDeclaration:Height()
	return self["height"];
end

function CSSStyleDeclaration:MinHeight()
	return self["min-height"];
end

function CSSStyleDeclaration:MaxHeight()
	return self["max-height"];
end

function CSSStyleDeclaration:Left()
	return self["left"] or 0;
end

function CSSStyleDeclaration:Top()
	return self["top"] or 0;
end

function CSSStyleDeclaration:Right()
	return self["right"] or 0;
end

function CSSStyleDeclaration:Bottom()
	return self["bottom"] or 0;
end

function CSSStyleDeclaration:Position()
	return self["position"] or "static";
end

function CSSStyleDeclaration:Floating()
	return self["float"] or "none";
end

function CSSStyleDeclaration:Display()
	return self["display"];
end

function CSSStyleDeclaration:Align()
	return self["align"];
end

function CSSStyleDeclaration:Valign()
	return self["valign"];
end

function CSSStyleDeclaration:OverflowX()
	return self["overflow-x"];
end

function CSSStyleDeclaration:OverflowY()
	return self["overflow-y"];
end

function CSSStyleDeclaration:Visibility()
	return self["visibility"];
end

function CSSStyleDeclaration:FontSize()
	return self["font-size"] or 12;
end

function CSSStyleDeclaration:Color()
	return self["color"] or "#000000";
end

-- the user may special many font size, however, some font size is simulated with a base font and scaling. 
-- @return font, base_font_size, font_scaling: font may be nil if not specified. font_size is the base font size.
function CSSStyleDeclaration:GetFontSettings()
	local font;
	local scale = 1;
	local font_size = 12;
	if(self["font-family"] or self["font-size"] or self["font-weight"])then
		local font_family = self["font-family"] or "System";
		-- this is tricky. we convert font size to integer, and we will use scale if font size is either too big or too small. 
		font_size = math.floor(tonumber(self["font-size"] or 12));
--		local max_font_size = tonumber(self["base-font-size"]) or 14;
--		local min_font_size = tonumber(self["base-font-size"]) or 11;
--		if(font_size>max_font_size) then
--			scale = font_size / max_font_size;
--			font_size = max_font_size;
--		end
--		if(font_size<min_font_size) then
--			scale = font_size / min_font_size;
--			font_size = min_font_size;
--		end
		local font_weight = self["font-weight"] or "norm";
		font = string.format("%s;%d;%s", font_family, font_size, font_weight);
	else
		font = string.format("%s;%d;%s", "System", font_size, "norm");
	end
	return font, font_size, scale;
end

function CSSStyleDeclaration:GetTextAlignment()
	local alignment = 1;	-- center align
	if(self["text-align"]) then
		if(self["text-align"] == "right") then
			alignment = 2;
		elseif(self["text-align"] == "left") then
			alignment = 0;
		end
	end
	if(self["text-singleline"] ~= "false") then
		alignment = alignment + 32;
	else
		if(self["text-wordbreak"] == "true") then
			alignment = alignment + 16;
		end
	end
	if(self["text-noclip"] ~= "false") then
		alignment = alignment + 256;
	end
	if(self["text-valign"] ~= "top") then
		alignment = alignment + 4;
	end
	return alignment;
end

-- 创建唯一索引
local index = {}

-- 创建元表
local mt = {
     __index = function (t, k)
          --print("access to element " .. tostring(k))		  
          return t[index][k]
     end,

     __newindex = function (t, k, v)
		t[index]["pageElement"]:ChangeCSSValue(k,v);
        --print("update of element " .. tostring(k))
        t[index][k] = v
     end
}

function CSSStyleDeclaration:CreateProxy(pageElement)
	local style_decl = CSSStyleDeclaration:new():init(pageElement);
	local proxy = {}
	proxy[index] = style_decl;
	setmetatable(proxy, mt);
	return proxy;
end