--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleInheritedData.lua");
local StyleInheritedData = commonlib.gettable("System.Windows.mcml.style.StyleInheritedData");
------------------------------------------------------------
]]


NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/LengthBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/Font.lua");
local Font = commonlib.gettable("System.Windows.mcml.style.Font");
local LengthBox = commonlib.gettable("System.Windows.mcml.platform.LengthBox");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");


local StyleInheritedData = commonlib.gettable("System.Windows.mcml.style.StyleInheritedData");
StyleInheritedData.__index = StyleInheritedData;

function StyleInheritedData:new(horizontal_border_spacing, vertical_border_spacing, line_height, font, color, visitedLinkColor)
	local o = {};

	o.horizontal_border_spacing = horizontal_border_spacing or ComputedStyle.initialHorizontalBorderSpacing();
	o.vertical_border_spacing = vertical_border_spacing or ComputedStyle.initialVerticalBorderSpacing();
	o.line_height = line_height or ComputedStyle.initialLineHeight();
	o.font = font or Font:new();
	o.color = color or ComputedStyle.initialColor();
	o.visitedLinkColor = visitedLinkColor or ComputedStyle.initialColor();

	setmetatable(o, self);
	return o;
end

function StyleInheritedData:clone()
	return StyleInheritedData:new(self.horizontal_border_spacing, self.vertical_border_spacing, 
									self.line_height:clone(), self.font:clone(), self.color:clone(), self.visitedLinkColor:clone());
end

function StyleInheritedData._eq(a, b)
	    return a.horizontal_border_spacing == b.horizontal_border_spacing 
			and a.vertical_border_spacing == b.vertical_border_spacing
			and a.line_height == b.line_height
			and a.font == b.font
			and a.color == b.color
			and a.visitedLinkColor == b.visitedLinkColor;
end

function StyleInheritedData.Create()
	return StyleInheritedData:new();
end

function StyleInheritedData:copy()
	return self:clone();
end