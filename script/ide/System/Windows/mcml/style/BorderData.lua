--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/BorderData.lua");
local BorderData = commonlib.gettable("System.Windows.mcml.style.BorderData");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/BorderValue.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/LengthSize.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
local Length = commonlib.gettable("System.Windows.mcml.platform.Length");
local LengthSize = commonlib.gettable("System.Windows.mcml.platform.LengthSize");
local BorderValue = commonlib.gettable("System.Windows.mcml.style.BorderValue");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");

local LengthTypeEnum = Length.LengthTypeEnum;
local BorderStyleEnum = ComputedStyleConstants.BorderStyleEnum;

local BorderData = commonlib.gettable("System.Windows.mcml.style.BorderData");
BorderData.__index = BorderData;

function BorderData:new(left, right, top, bottom, topLeft, topRight, bottomLeft, bottomRight)
	local o = {};

	o.m_left = left or BorderValue:new();
    o.m_right = right or BorderValue:new();
    o.m_top = top or BorderValue:new();
    o.m_bottom = bottom or BorderValue:new();

    o.m_topLeft = topLeft or LengthSize:new(Length:new(0, LengthTypeEnum.Fixed), Length:new(0, LengthTypeEnum.Fixed));
    o.m_topRight = topRight or LengthSize:new(Length:new(0, LengthTypeEnum.Fixed), Length:new(0, LengthTypeEnum.Fixed));
	o.m_bottomLeft = bottomLeft or LengthSize:new(Length:new(0, LengthTypeEnum.Fixed), Length:new(0, LengthTypeEnum.Fixed));
    o.m_bottomRight = bottomRight or LengthSize:new(Length:new(0, LengthTypeEnum.Fixed), Length:new(0, LengthTypeEnum.Fixed));

	setmetatable(o, self);
	return o;
end

function BorderData:clone()
	return BorderData:new(self.m_left:clone(), self.m_right:clone(), self.m_top:clone(), self.m_bottom:clone(), 
							self.m_topLeft:clone(), self.m_topRight:clone(), self.m_bottomLeft:clone(), self.m_bottomRight:clone());
end

function BorderData._eq(a, b)
	return a.m_left == b.m_left
        and a.m_right == b.m_right
        and a.m_top == b.m_top
        and a.m_bottom == b.m_bottom
        and a.m_topLeft == b.m_topLeft
        and a.m_topRight == b.m_topRight
        and a.m_bottomLeft == b.m_bottomLeft
        and a.m_bottomRight == b.m_bottomRight;
end

function BorderData:Left()
	return self.m_left;
end

function BorderData:Right()
	return self.m_right;
end

function BorderData:Top()
	return self.m_top;
end

function BorderData:Bottom()
	return self.m_bottom;
end

function BorderData:TopLeft()
	return self.m_topLeft;
end

function BorderData:TopRight()
	return self.m_topRight;
end

function BorderData:BottomLeft()
	return self.m_bottomLeft;
end

function BorderData:BottomRight()
	return self.m_bottomRight;
end

function BorderData:HasBorder()
	local haveImage = false;
	return self.m_left:NonZero(not haveImage) or self.m_right:NonZero(not haveImage) or self.m_top:NonZero(not haveImage) or self.m_bottom:NonZero(not haveImage);
end

function BorderData:HasBorderRadius()
	if (not self.m_topLeft:Width():IsZero()) then
		return true;
	end
	if (not self.m_topRight:Width():IsZero()) then
		return true;
	end
	if (not self.m_bottomLeft:Width():IsZero()) then
		return true;
	end
	if (not self.m_bottomRight:Width():IsZero()) then
		return true;
	end
	return false;
end

function BorderData:BorderLeftWidth()
	if ((self.m_left:Style() == BorderStyleEnum.BNONE or self.m_left:Style() == BorderStyleEnum.BHIDDEN)) then
		return 0; 
	end
	return self.m_left:Width();
end

function BorderData:BorderRightWidth()
	if ((self.m_right:Style() == BorderStyleEnum.BNONE or self.m_right:Style() == BorderStyleEnum.BHIDDEN)) then
		return 0;
	end
	return self.m_right:Width();
end

function BorderData:BorderTopWidth()
	if ((self.m_top:Style() == BorderStyleEnum.BNONE or self.m_top:Style() == BorderStyleEnum.BHIDDEN)) then
		return 0;
	end
	return self.m_top:Width();
end

function BorderData:BorderBottomWidth()
	if ((self.m_bottom:Style() == BorderStyleEnum.BNONE or self.m_bottom:Style() == BorderStyleEnum.BHIDDEN)) then
		return 0;
	end
	return self.m_bottom:Width();
end