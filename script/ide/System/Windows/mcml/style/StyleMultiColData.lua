--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleMultiColData.lua");
local StyleMultiColData = commonlib.gettable("System.Windows.mcml.style.StyleMultiColData");
------------------------------------------------------------
]]


NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/BorderValue.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/Color.lua");
local Color = commonlib.gettable("System.Windows.mcml.style.Color");
local BorderValue = commonlib.gettable("System.Windows.mcml.style.BorderValue");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");

local StyleMultiColData = commonlib.gettable("System.Windows.mcml.style.StyleMultiColData");
StyleMultiColData.__index = StyleMultiColData;

local memberAndInitialValues = 
{
	["m_width"] = 0,
	["m_count"] = ComputedStyle.initialColumnCount(),
	["m_gap"] = 0,
	["m_rule"] = BorderValue:new(),
	["m_visitedLinkColumnRuleColor"] = Color:new(),
	["m_autoWidth"] = true,
	["m_autoCount"] = true,
	["m_normalGap"] = true,
	["m_columnSpan"] = false,
	["m_breakBefore"] = ComputedStyle.initialPageBreak(),
	["m_breakAfter"] = ComputedStyle.initialPageBreak(),
	["m_breakInside"] = ComputedStyle.initialPageBreak(),
};

local class_members = {
	["m_rule"] = true,
	["m_visitedLinkColumnRuleColor"] = true,
};

function StyleMultiColData:new(other)
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

function StyleMultiColData:clone()
	return StyleMultiColData:new(self);
end

function StyleMultiColData._eq(a, b)
	for k in pairs(memberAndInitialValues) do
		if(a[k] ~= b[k]) then
			return false;
		end
	end
	return true;
end