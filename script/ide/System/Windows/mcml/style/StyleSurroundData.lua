--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleSurroundData.lua");
local StyleSurroundData = commonlib.gettable("System.Windows.mcml.style.StyleSurroundData");
------------------------------------------------------------
]]


NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/LengthBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/BorderData.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
local Length = commonlib.gettable("System.Windows.mcml.platform.Length");
local BorderData = commonlib.gettable("System.Windows.mcml.style.BorderData");
local LengthBox = commonlib.gettable("System.Windows.mcml.platform.LengthBox");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");

local LengthTypeEnum = Length.LengthTypeEnum;

local StyleSurroundData = commonlib.gettable("System.Windows.mcml.style.StyleSurroundData");
StyleSurroundData.__index = StyleSurroundData;

function StyleSurroundData:new(offset, margin, padding, border)
	local o = {};

	-- LengthBox 
	o.offset = offset or LengthBox:new();
    o.margin = margin  or LengthBox:new("type", LengthTypeEnum.Fixed);
    o.padding = padding or LengthBox:new("type", LengthTypeEnum.Fixed);
	-- BorderData 
    o.border = border or BorderData:new();

	setmetatable(o, self);
	return o;
end

function StyleSurroundData:clone()
	return StyleSurroundData:new(self.offset:clone(), self.margin:clone(), self.padding:clone(), self.border:clone());
end

function StyleSurroundData.__eq(a, b)
	    return a.offset == b.offset 
			and a.margin == b.margin
			and a.padding == b.padding
			and a.border == b.border;
end

function StyleSurroundData.Create()
	return StyleSurroundData:new();
end

function StyleSurroundData:copy()
	return self:clone();
end