--[[
Title: 
Author(s): LiPeng
Date: 2018/2/2
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/LengthBox.lua");
local LengthBox = commonlib.gettable("System.Windows.mcml.platform.LengthBox");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
local Length = commonlib.gettable("System.Windows.mcml.platform.Length");
local LengthTypeEnum = Length.LengthTypeEnum;

local LengthBox = commonlib.gettable("System.Windows.mcml.platform.LengthBox");
LengthBox.__index = LengthBox;

function LengthBox:new(type, left, right, top, bottom)
	local o = {};

	if(type == "value") then
		left, right, top, bottom = left, right or left, top or left, bottom or left;
		o.m_left = Length:new(left, LengthTypeEnum.Fixed);
		o.m_right = Length:new(right, LengthTypeEnum.Fixed);
		o.m_top = Length:new(top, LengthTypeEnum.Fixed);
		o.m_bottom = Length:new(bottom, LengthTypeEnum.Fixed);
	elseif(type == "type") then
		local lengthType = left;
		o.m_left = Length:new(lengthType);
		o.m_right = Length:new(lengthType);
		o.m_top = Length:new(lengthType);
		o.m_bottom = Length:new(lengthType);
	elseif(type == "object") then
		o.m_left = left;
		o.m_right = right;
		o.m_top = top;
		o.m_bottom = bottom;
	else
		o.m_left = Length:new();
		o.m_right = Length:new();
		o.m_top = Length:new();
		o.m_bottom = Length:new();
	end

	setmetatable(o, self);
	return o;
end

function LengthBox:clone()
	local o = LengthBox:new("object", self.m_left:clone(), self.m_right:clone(), self.m_top:clone(), self.m_bottom:clone());
	return o;
end

function LengthBox.__eq(a, b)
	return a.m_left == b.m_left and a.m_right == b.m_right and a.m_top == b.m_top and a.m_bottom == b.m_bottom;
end

function LengthBox:Left()
	return self.m_left;
end

function LengthBox:Right()
	return self.m_right;
end

function LengthBox:Top()
	return self.m_top;
end

function LengthBox:Bottom()
	return self.m_bottom;
end

function LengthBox:NonZero()
    return not (self.m_left:IsZero() and self.m_right:IsZero() and self.m_top:IsZero() and self.m_bottom:IsZero());
end
