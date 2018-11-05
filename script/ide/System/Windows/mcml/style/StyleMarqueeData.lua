--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleMarqueeData.lua");
local StyleMarqueeData = commonlib.gettable("System.Windows.mcml.style.StyleMarqueeData");
------------------------------------------------------------
]]


NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");

local StyleMarqueeData = commonlib.gettable("System.Windows.mcml.style.StyleMarqueeData");
StyleMarqueeData.__index = StyleMarqueeData;

local memberAndInitialValues = 
{
	["increment"] = ComputedStyle.initialMarqueeIncrement(),
	["speed"] = ComputedStyle.initialMarqueeSpeed(),
	["m_gap"] = ComputedStyle.initialMarqueeIncrement(),
	["loops"] = ComputedStyle.initialMarqueeLoopCount(),
	["behavior"] = ComputedStyle.initialMarqueeBehavior(),
	["direction"] = ComputedStyle.initialMarqueeDirection(),
}

local class_members = {
	["increment"] = true,
}

function StyleMarqueeData:new(other)
	local o = {};
	for k, v in pairs(memberAndInitialValues) do
		if(other) then
			v = other[k];
		end
		if(class_members[k]) then
			v = v:clone();
		end
		o[k] = v;
	end
	setmetatable(o, self);
	return o;
end

function StyleMarqueeData:clone()
	return StyleMarqueeData:new(self);
end

function StyleMarqueeData.__eq(a, b)
	for k in pairs(memberAndInitialValues) do
		if(a[k] ~= b[k]) then
			return false;
		end
	end
	return true;
end