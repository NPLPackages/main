--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleFlexibleBoxData.lua");
local StyleFlexibleBoxData = commonlib.gettable("System.Windows.mcml.style.StyleFlexibleBoxData");
------------------------------------------------------------
]]


NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");

local StyleFlexibleBoxData = commonlib.gettable("System.Windows.mcml.style.StyleFlexibleBoxData");
StyleFlexibleBoxData.__index = StyleFlexibleBoxData;

local memberAndInitialValues = 
{
	["flexGrow"] = ComputedStyle.initialFlexGrow(),
	["flexShrink"] = ComputedStyle.initialFlexShrink(),
	["flexBasis"] = ComputedStyle.initialFlexBasis(),
	["flexDirection"] = ComputedStyle.initialFlexDirection(),
	["flexWrap"] = ComputedStyle.initialFlexWrap(),
};

local class_members = {
	
};

function StyleFlexibleBoxData:new(other)
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

function StyleFlexibleBoxData:clone()
	return StyleFlexibleBoxData:new(self);
end

function StyleFlexibleBoxData.__eq(a, b)
	for k in pairs(memberAndInitialValues) do
		if(a[k] ~= b[k]) then
			return false;
		end
	end
	return true;
end