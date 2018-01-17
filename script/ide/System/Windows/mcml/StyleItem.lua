--[[
Title: StyleItem object
Author(s): LiXizhi
Date: 2015/4/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/StyleItem.lua");
local StyleItem = commonlib.gettable("System.Windows.mcml.StyleItem");
local style = StyleItem:new();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/LocalCache.lua");
local LocalCache = commonlib.gettable("System.Windows.mcml.LocalCache");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");

local type = type;
local tonumber = tonumber;
local string_gsub = string.gsub;
local string_lower = string.lower
local string_match = string.match;
local string_find = string.find;

local StyleItem = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.StyleItem"));

local remoteTextrue = {};

function StyleItem:ctor()
	self.style = nil;
	self.pageElement = nil;
	self.remoteResource = {};
end

function StyleItem:init(style,pageElement)
	self.style = style;
	self.pageElement = pageElement;
	return self;
end

function StyleItem:GetPageCachePolicy()
	local cache_policy;
--	if(self.style and self.style.page) then
--		cache_policy =  self.style.page.cache_policy;
--	end
	return cache_policy or System.localserver.CachePolicy:new("access plus 1 hour");
end

-- merge style with current style. 
function StyleItem:Merge(style)
	if(style) then
		if(type(style) == "table") then
			for key, value in pairs(style) do
				self[key] = value;
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
	["shadow-color"] = true,
	["text-shadow-offset-x"] = true,
	["text-shadow-offset-y"] = true,
};

-- only merge inheritable style like font, color, etc. 
function StyleItem:MergeInheritable(style)
	if(style) then
		for field,_ in pairs(inheritable_fields) do
			self[field] = self[field] or style[field];
		end
--		self.color = self.color or style.color;
--		self["font-family"] = self["font-family"] or style["font-family"];
--		self["font-size"] = self["font-size"] or style["font-size"];
--		self["font-weight"] = self["font-weight"] or style["font-weight"];
--		self["text-shadow"] = self["text-shadow"] or style["text-shadow"];
	end
end

local reset_fields = 
{
	["height"] = true,
	["min-height"] = true,
	["max-height"] = true,
	["width"] = true,
	["min-width"] = true,
	["max-width"] = true,
	["left"] = true,
	["top"] = true,

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
	["font-size"] = true,
	["spacing"] = true,
	["base-font-size"] = true,
	["border-width"] = true,
	["shadow-quality"] = true,
	["text-shadow-offset-x"] = true,
	["text-shadow-offset-y"] = true,
};

local boolean_fields = {
	["text-shadow"] = true,
}

local color_fields = {
	["color"] = true,
	["border-color"] = true,
	["background-color"] = true,
	["shadow-color"] = true,
};

local image_fields = 
{
	["background"] = true,
	["background2"] = true,
	["background-image"] = true,
}
-- these fields are made up of the other simple fields.
local complex_fields = {
	["border"] = "border-width border-style border-color",
};

function StyleItem.AddRemoteTextureLocalPath(url, path)
	remoteTextrue[url] = path;
end

function StyleItem.isResetField(name)
	return reset_fields[name];
end

-- @param style_code: mcml style attribute string like "background:url();margin:10px;"
function StyleItem:AddString(style_code)
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

function StyleItem:AddComplexField(names_code,values_code)
	local names = commonlib.split(names_code, "%s");
	local values = commonlib.split(values_code, "%s");
	for i = 1, #names do
		self:AddItem(names[i], values[i]);
	end
end

function StyleItem:AddItem(name,value)
	if(not name or not value) then
		return;
	end
	name = string_lower(name);
	value = string_gsub(value, "%s*$", "");
	if(number_fields[name] or string_find(name,"^margin") or string_find(name,"^padding")) then
		local _, _, selfvalue = string_find(value, "([%+%-]?%d+)");
		if(selfvalue~=nil) then
			value = tonumber(selfvalue);
		else
			value = nil;
		end
	elseif(boolean_fields[name]) then
		if(value=="true") then
			value = true;
		elseif(value=="false") then
			value = false;
		end
	elseif(color_fields[name]) then
		value = StyleColor.ConvertTo16(value);
	elseif(string_match(name, "^background[2]?$") or name == "background-image") then
		value = string_gsub(value, "url%((.*)%)", "%1");
		value = string_gsub(value, "#", ";");
	end
	if(image_fields[name] and string.match(value,"^http[s]?")) then
		if(self.pageElement) then
			-- mcml v2 http texture process
			LocalCache:GetRemoteTexture(value, self:GetPageCachePolicy(), function (entry)
				if(entry and entry.entry and entry.entry.url and entry.payload and entry.payload.cached_filepath) then
					self[name] = entry.payload.cached_filepath;
					self.pageElement:UpdateCssStyle();
				end
			end);
			return;
		end
	end
	self[name] = value;
end

function StyleItem:padding_left()
	return (self["padding-left"] or self["padding"] or 0);
end

function StyleItem:padding_right()
	return (self["padding-right"] or self["padding"] or 0);
end

function StyleItem:padding_top()
	return (self["padding-top"] or self["padding"] or 0);
end

function StyleItem:padding_bottom()
	return (self["padding-bottom"] or self["padding"] or 0);
end

-- return left, top, right, bottom
function StyleItem:paddings()
	return self:padding_left(), self:padding_top(), self:padding_right(), self:padding_bottom();
end

function StyleItem:margin_left()
	return (self["margin-left"] or self["margin"] or 0);
end

function StyleItem:margin_right()
	return (self["margin-right"] or self["margin"] or 0);
end

function StyleItem:margin_top()
	return (self["margin-top"] or self["margin"] or 0);
end

function StyleItem:margin_bottom()
	return (self["margin-bottom"] or self["margin"] or 0);
end

-- return left, top, right, bottom
function StyleItem:margins()
	return self:margin_left(), self:margin_top(), self:margin_right(), self:margin_bottom();
end

-- the user may special many font size, however, some font size is simulated with a base font and scaling. 
-- @return font, base_font_size, font_scaling: font may be nil if not specified. font_size is the base font size.
function StyleItem:GetFontSettings()
	local font;
	local scale;
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

function StyleItem:TextShadow()
	return self["text-shadow"] or false;
end

function StyleItem:TextShadowOffsetX()
	return self["text-shadow-offset-x"] or 3;
end

function StyleItem:TextShadowOffsetY()
	return self["text-shadow-offset-y"] or 3;
end

function StyleItem:TextShadowColor()
	return self["shadow-color"] or "#00000088";
end

function StyleItem:GetTextShadow()
	return self:TextShadow(), self:TextShadowOffsetX(), self:TextShadowOffsetY(), self:TextShadowColor();
end

function StyleItem:GetTextAlignment()
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