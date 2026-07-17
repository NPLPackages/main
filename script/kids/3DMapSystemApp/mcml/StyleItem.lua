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
	["margin-left"] = true,
	["margin-top"] = true,
	["margin-right"] = true,
	["margin-bottom"] = true,
	["padding-left"] = true,
	["padding-top"] = true,
	["padding-right"] = true,
	["padding-bottom"] = true,
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

local values = {}
-- html5 style parsers
local styleItemParsers = {
	["margin"] = function(self, value)
		-- Parse margin values (1-4 values like CSS)
		-- Examples: "10px", "10px 20px", "10px 20px 30px", "10px 20px 30px 40px", "auto"

		local valueCount = 0;
		
		for val in string.gmatch(value, "([^%s]+)") do
			valueCount = valueCount + 1
			if val == "auto" then
				values[valueCount] = "auto"
			else
				local num = string.match(val, "([%+%-]?%d+)")
				if num then
					values[valueCount] = tonumber(num)
				else
					values[valueCount] = nil
				end
			end
		end

		if valueCount == 1 then
			-- margin: 10px (all sides) or margin: auto
			if(values[1] == "auto") then
				self["margin-left"] = "auto"
				self["margin-right"] = "auto"
			else
				self["margin"] = values[1]
			end
		elseif valueCount == 2 then
			-- margin: 10px 20px (top/bottom, left/right)
			self["margin-top"] = values[1]
			self["margin-bottom"] = values[1]
			self["margin-left"] = values[2]
			self["margin-right"] = values[2]
		elseif valueCount == 3 then
			-- margin: 10px 20px 30px (top, left/right, bottom)
			self["margin-top"] = values[1]
			self["margin-left"] = values[2]
			self["margin-right"] = values[2]
			self["margin-bottom"] = values[3]
		elseif valueCount == 4 then
			-- margin: 10px 20px 30px 40px (top, right, bottom, left)
			self["margin-top"] = values[1]
			self["margin-right"] = values[2]
			self["margin-bottom"] = values[3]
			self["margin-left"] = values[4]
		end
	end,
	["padding"] = function(self, value)
		-- Parse padding values (1-4 values like CSS)
		-- Examples: "10px", "10px 20px", "10px 20px 30px", "10px 20px 30px 40px"

		local valueCount = 0;
		
		for val in string.gmatch(value, "([^%s]+)") do
			local num = string.match(val, "([%+%-]?%d+)")
			if num then
				valueCount = valueCount + 1
				values[valueCount] = tonumber(num)
			end
		end

		if valueCount == 1 then
			-- padding: 10px (all sides)
			self["padding"] = values[1]
		elseif valueCount == 2 then
			-- padding: 10px 20px (top/bottom, left/right)
			self["padding-top"] = values[1]
			self["padding-bottom"] = values[1]
			self["padding-left"] = values[2]
			self["padding-right"] = values[2]
		elseif valueCount == 3 then
			-- padding: 10px 20px 30px (top, left/right, bottom)
			self["padding-top"] = values[1]
			self["padding-left"] = values[2]
			self["padding-right"] = values[2]
			self["padding-bottom"] = values[3]
		elseif valueCount == 4 then
			-- padding: 10px 20px 30px 40px (top, right, bottom, left)
			self["padding-top"] = values[1]
			self["padding-right"] = values[2]
			self["padding-bottom"] = values[3]
			self["padding-left"] = values[4]
		end
	end,
}
function StyleItem:AddItem(name,value)
	if(not name or not value) then
		return;
	end
	name = string_lower(name);
	value = string_gsub(value, "%s*$", "");
	if(styleItemParsers[name]) then
		styleItemParsers[name](self, value);
		return;
	elseif(number_fields[name]) then
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
