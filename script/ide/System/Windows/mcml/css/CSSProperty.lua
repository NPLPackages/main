--[[
Title: css property class
Author(s): LiXizhi
Date: 2018/6/8
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSProperty.lua");
local CSSProperty = commonlib.gettable("System.Windows.mcml.css.CSSProperty");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/Color.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local Color = commonlib.gettable("System.Windows.mcml.style.Color");
local Length = commonlib.gettable("System.Windows.mcml.platform.Length");

local string_gsub = string.gsub;

local CSSProperty = commonlib.gettable("System.Windows.mcml.css.CSSProperty");
CSSProperty.__index = CSSProperty;

function CSSProperty:new(name, value)
	local o = {};
	o.name = name;
	o.value = value;

	setmetatable(o, self);
	return o;
end

function CSSProperty:clone()
	return CSSProperty:new(self.name, self.value);
end

function CSSProperty.__eq(a, b)
	return a.name == b.name and a.value == b.value;
end

function CSSProperty:Name()
	return self.name;
end

function CSSProperty:Value()
	return self.value;
end

--local number_fields = {
--	["font-size"] = true,
--
--	["border-width"] = true,
--	["shadow-quality"] = true,
--	["text-shadow-offset-x"] = true,
--	["text-shadow-offset-y"] = true,
--};

local number_fields = {
	["border-width"] = true,
};

local length_fields = {
	["height"] = true,
	["width"] = true,

	["min-height"] = true,
	["max-height"] = true,
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

	["line-height"] = true,
};

local color_fields = {
	["color"] = true,
	["border-color"] = true,
	["background-color"] = true,
	--["shadow-color"] = true,
	["caret-color"] = true,
};

local image_fields = {
	["background"] = true,
	["background2"] = true,
	["background-image"] = true,
}

local border_style = {
	["none"] = "BNONE",
	["hidden"] = "BHIDDEN",
	["inset"] = "INSET",
	["groove"] = "GROOVE",
	["outset"] = "OUTSET",
	["ridge"] = "RIDGE",
	["dotted"] = "DOTTED",
	["dashed"] = "DASHED",
	["solid"] = "SOLID",
	["double"] = "DOUBLE",
};

local overflow = {
    ["visible"] = "OVISIBLE",
	["hidden"] = "OHIDDEN",
	["scroll"] = "OSCROLL",
	["auto"] = "OAUTO",
}

local enum_fields = {
	["display"] = {map = {
		["inline"] = "INLINE",
		["block"] = "BLOCK",
		["list-item"] = "LIST_ITEM",
		["run-in"] = "RUN_IN",
		["compact"] = "COMPACT",
		["inline-block"] = "INLINE_BLOCK",
		["table"] = "TABLE",
		["inline-table"] = "INLINE_TABLE",
		["table-row-group"] = "TABLE_ROW_GROUP",
		["table-header-group"] = "TABLE_HEADER_GROUP",
		["table-footer-group"] = "TABLE_FOOTER_GROUP",
		["table-row"] = "TABLE_ROW",
		["table-column-group"] = "TABLE_COLUMN_GROUP",
		["table-column"] = "TABLE_COLUMN",
		["table-cell"] = "TABLE_CELL",
		["table-caption"] = "TABLE_CAPTION",
		["box"] = "BOX",
		["inline-box"] = "INLINE_BOX",
		["flexbox"] = "FLEXBOX",
		["inline-flexbox"] = "INLINE_FLEXBOX",
		["none"] = "NONE",
	}, enum = ComputedStyleConstants.DisplayEnum},
	["border-style"] = {map = border_style, enum = ComputedStyleConstants.BorderStyleEnum},
	["border-left-style"] = {map = border_style, enum = ComputedStyleConstants.BorderStyleEnum},
	["border-top-style"] = {map = border_style, enum = ComputedStyleConstants.BorderStyleEnum},
	["border-right-style"] = {map = border_style, enum = ComputedStyleConstants.BorderStyleEnum},
	["border-bottom-style"] = {map = border_style, enum = ComputedStyleConstants.BorderStyleEnum},
	["position"] = {map = {
		["static"] = "StaticPosition",
		["relative"] = "RelativePosition",
		["absolute"] = "AbsolutePosition",
		["fixed"] = "FixedPosition",
	}, enum = ComputedStyleConstants.PositionEnum},
	["float"] = {map = {
		["none"] = "NoFloat",
		["left"] = "LeftFloat",
		["right"] = "RightFloat",
	}, enum = ComputedStyleConstants.FloatEnum},
	["overflow"] = {map = overflow, enum = ComputedStyleConstants.OverflowEnum},
	["overflow-x"] = {map = overflow, enum = ComputedStyleConstants.OverflowEnum},
	["overflow-y"] = {map = overflow, enum = ComputedStyleConstants.OverflowEnum},
	["text-align"] = {map = {
		["left"] = "LEFT",
		["right"] = "RIGHT",
		["center"] = "CENTER",
		["justify"] = "JUSTIFY",
	}, enum = ComputedStyleConstants.TextAlignEnum},
	["box-align"] = {map = {
		["start"] = "BSTART",
		["end"] = "BEND",
		["center"] = "BCENTER",
		["baseline"] = "BBASELINE",
		["stretch"] = "BSTRETCH",
	}, enum = ComputedStyleConstants.BoxAlignmentEnum},
	["visibility"] = {map = { 
		["visible"] = "VISIBLE",
		["hidden"] = "HIDDEN",
		["collapse"] = "COLLAPSE",
	}, enum = ComputedStyleConstants.VisibilityEnum},
	["appearance"] = {map = {
		["checkbox"] = "CheckboxPart",
		["radio"] = "RadioPart",
		["narrow"] = "NarrowPart",
		["button"] = "ButtonPart",
		["listbox"] = "ListboxPart",
		["progress-bar"] = "ProgressBarPart",
		["textfield"] = "TextFieldPart",
		["textarea"] = "TextAreaPart",
		["push-button"] = "PushButtonPart",
	},enum = ComputedStyleConstants.ControlPartEnum};
}

function CSSProperty:CreateValueFromCssString()
	local name, value = self.name, self.value;
	if(value == "inherit" or value == "initial") then
		return value;
	end
	if(length_fields[name]) then
		return Length.CreateFromCssLength(value);
	elseif(color_fields[name]) then
		return Color.CreateFromCssColor(value);
	elseif(image_fields[name]) then
		value = string_gsub(value, "url%((.*)%)", "%1");
		value = string_gsub(value, "#", ";");
		return value;
	elseif(number_fields[name]) then
		value = string.match(value, "([%+%-]?%d+[.]?%d*)");
		return value;
	elseif(enum_fields[name]) then
		local map = enum_fields[name].map;
		local enum = enum_fields[name].enum;
		value = enum[map[value]];
		return value;
	end

	if(name == "font-weight") then
		if(string.match(value, "bold")) then
			return true;
		end
		return false;
	end

	if(name == "font-size") then
		local value = string.match(value, "%d+");
		return tonumber(value);
	end

	return value;
end

