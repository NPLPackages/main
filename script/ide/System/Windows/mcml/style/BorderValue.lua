--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/BorderValue.lua");
local BorderValue = commonlib.gettable("System.Windows.mcml.style.BorderValue");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/Color.lua");
local Color = commonlib.gettable("System.Windows.mcml.style.Color");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");

local BorderValue = commonlib.gettable("System.Windows.mcml.style.BorderValue");
BorderValue.__index = BorderValue;

function BorderValue:new(width, style, color)
	local o = {};

	o.m_width = width or 3;
    o.m_style = style or ComputedStyleConstants.BorderStyleEnum.BNONE;
	o.m_color = color or Color:new();
	o.m_isAuto = ComputedStyleConstants.OutlineIsAutoEnum.AUTO_OFF;
	setmetatable(o, self);
	return o;
end

function BorderValue:clone()
	local o = BorderValue:new(self.m_width, self.m_style, self.m_color:clone());
	return o;
end

function BorderValue._eq(a, b)
	return a.m_color == b.m_color and a.m_width == b.m_width and a.m_style == b.m_style;
end

function BorderValue:Width()
	return self.m_width;
end

function BorderValue:Color()
	return self.m_color;
end


function BorderValue:Style()
	return self.m_style;
end

function BorderValue:NonZero(checkStyle)
	checkStyle = if_else(checkStyle == nil, true, checkStyle);
    return self:Width() ~= 0 and (not checkStyle or self.m_style ~= ComputedStyleConstants.BorderStyleEnum.BNONE);
end

function BorderValue:IsTransparent()
    return self.m_color:IsValid() and self.m_color:Alpha() == 0;
end

function BorderValue:IsVisible(checkStyle)
	checkStyle = if_else(checkStyle == nil, true, checkStyle);
    return self:NonZero(checkStyle) and not self:IsTransparent() and (not checkStyle or self.m_style ~= ComputedStyleConstants.BorderStyleEnum.BHIDDEN);
end