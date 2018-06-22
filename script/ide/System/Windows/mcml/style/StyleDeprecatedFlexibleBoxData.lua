--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleDeprecatedFlexibleBoxData.lua");
local StyleDeprecatedFlexibleBoxData = commonlib.gettable("System.Windows.mcml.style.StyleDeprecatedFlexibleBoxData");
------------------------------------------------------------
]]


NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");

local StyleDeprecatedFlexibleBoxData = commonlib.gettable("System.Windows.mcml.style.StyleDeprecatedFlexibleBoxData");
StyleDeprecatedFlexibleBoxData.__index = StyleDeprecatedFlexibleBoxData;

local memberAndInitialValues = 
{
	["flex"] = ComputedStyle.initialBoxFlex(),
	["flex_group"] = ComputedStyle.initialBoxFlexGroup(),
	["ordinal_group"] = ComputedStyle.initialBoxOrdinalGroup(),
	["align"] = ComputedStyle.initialBoxAlign(), -- EBoxAlignment
	["pack"] = ComputedStyle.initialBoxPack(), -- EBoxAlignment
	["orient"] = ComputedStyle.initialBoxOrient(), -- EBoxOrient
	["lines"] = ComputedStyle.initialBoxLines(), -- EBoxLines
};

local class_members = {
	
};

function StyleDeprecatedFlexibleBoxData:new(other)
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

function StyleDeprecatedFlexibleBoxData:clone()
	return StyleDeprecatedFlexibleBoxData:new(self);
end

function StyleDeprecatedFlexibleBoxData._eq(a, b)
	for k in pairs(memberAndInitialValues) do
		if(a[k] ~= b[k]) then
			return false;
		end
	end
	return true;
end