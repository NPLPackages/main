--[[
Title: StyleItem object
Author(s): LiXizhi
Date: 2015/4/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/StyleItem.lua");
local StyleItem = commonlib.gettable("Map3DSystem.mcml_controls.StyleItem");
local style = StyleItem:new();
------------------------------------------------------------
]]
local type = type;
local tonumber = tonumber;
local string_gsub = string.gsub;
local string_lower = string.lower
local string_match = string.match;
local string_find = string.find;

local StyleItem = commonlib.inherit(nil, commonlib.gettable("Map3DSystem.mcml_controls.StyleItem"));

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
};

-- only merge inheritable style like font, color, etc. 
function StyleItem:MergeInheritable(style)
	if(style) then
		self.color = self.color or style.color;
		self["font-family"] = self["font-family"] or style["font-family"];
		self["font-size"] = self["font-size"] or style["font-size"];
		self["font-weight"] = self["font-weight"] or style["font-weight"];
		self["text-shadow"] = self["text-shadow"] or style["text-shadow"];
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
};

local color_fields = {
	["color"] = true,
	["border-color"] = true,
	["background-color"] = true,
};


-- @param style_code: mcml style attribute string like "background:url();margin:10px;"
function StyleItem:AddString(style_code)
	local name, value;
	for name, value in string.gfind(style_code, "([%w%-]+)%s*:%s*([^;]*)[;]?") do
		name = string_lower(name);
		value = string_gsub(value, "%s*$", "");
		self:AddItem(name,value);
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
	elseif(color_fields[name]) then
		-- value = StyleColor.ConvertTo16(value);
	elseif(string_match(name, "^background[2]?$") or name == "background-image") then
		value = string_gsub(value, "url%((.*)%)", "%1");
		value = string_gsub(value, "#", ";");
	end
	self[name] = value;
end
