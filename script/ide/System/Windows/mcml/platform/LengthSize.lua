--[[
Title: 
Author(s): LiPeng
Date: 2018/2/2
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/LengthSize.lua");
local LengthSize = commonlib.gettable("System.Windows.mcml.platform.LengthSize");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
local Length = commonlib.gettable("System.Windows.mcml.platform.Length");

local LengthSize = commonlib.gettable("System.Windows.mcml.platform.LengthSize");
LengthSize.__index = LengthSize;

function LengthSize:new(width, height)
	local o = {};

	o.width = width or Length:new();
    o.height = height or Length:new();

	setmetatable(o, self);
	return o;
end

function LengthSize:clone()
	return LengthSize:new(self.width:clone(), self.height:clone());
end

function LengthSize._eq(a, b)
	return a.width == b.width and a.height == b.height;
end

function LengthSize:SetWidth(width)
	self.width = width;
end

function LengthSize:Width()
	return self.width;
end

function LengthSize:SetHeight(height)
	self.height = height; 
end

function LengthSize:Height()
	return self.height;
end