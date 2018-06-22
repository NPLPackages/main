--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/ShadowData.lua");
local ShadowData = commonlib.gettable("System.Windows.mcml.style.ShadowData");
------------------------------------------------------------
]]


NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/LengthBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/Color.lua");
local Color = commonlib.gettable("System.Windows.mcml.style.Color");
local LengthBox = commonlib.gettable("System.Windows.mcml.platform.LengthBox");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");

local ShadowData = commonlib.gettable("System.Windows.mcml.style.ShadowData");
ShadowData.__index = ShadowData;

function ShadowData:new(x, y, blur, color)
	local o = {};

	o.x = x or 0;
	o.y = y or 0;
	o.blur = blur or 0;
	o.color = color or Color:new();
	o.next = nil;

	setmetatable(o, self);
	return o;
end

function ShadowData:clone()
	return ShadowData:new(self.x, self.y, self.blur, self.color:clone());
end

function ShadowData._eq(a, b)
	return a.x == b.x and a.y == b.y and a.blur == b.blur and a.color == b.color;
end

function ShadowData:X()
	return self.x;
end

function ShadowData:Y()
	return self.y;
end

function ShadowData:Blur()
	return self.blur;
end

function ShadowData:Color()
	return self.color;
end