--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleVisualData.lua");
local StyleVisualData = commonlib.gettable("System.Windows.mcml.style.StyleVisualData");
------------------------------------------------------------
]]


NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/LengthBox.lua");
local LengthBox = commonlib.gettable("System.Windows.mcml.platform.LengthBox");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");

local StyleVisualData = commonlib.gettable("System.Windows.mcml.style.StyleVisualData");
StyleVisualData.__index = StyleVisualData;

function StyleVisualData:new(clip, hasClip, textDecoration, zoom)
	local o = {};

	o.clip = clip or LengthBox:new();
    o.hasClip = hasClip or false;
    o.textDecoration = textDecoration or ComputedStyle.initialTextDecoration(); -- Text decorations defined *only* by this element.
    
    o.m_zoom = zoom or ComputedStyle.initialZoom();

	setmetatable(o, self);
	return o;
end

function StyleVisualData:clone()
	return StyleVisualData:new(self.clip:clone(), self.hasClip, self.textDecoration, self.m_zoom);
end

function StyleVisualData.__eq(a, b)
	    return a.clip == b.clip 
			and a.hasClip == b.hasClip
			and a.textDecoration == b.textDecoration
			and a.m_zoom == b.m_zoom;
end

function StyleVisualData.Create()
	return StyleVisualData:new();
end

function StyleVisualData:copy()
	return self:clone();
end