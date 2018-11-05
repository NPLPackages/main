--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleBoxData.lua");
local StyleBoxData = commonlib.gettable("System.Windows.mcml.style.StyleBoxData");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local Length = commonlib.gettable("System.Windows.mcml.platform.Length");

local StyleBoxData = commonlib.gettable("System.Windows.mcml.style.StyleBoxData");
StyleBoxData.__index = StyleBoxData;

function StyleBoxData:new(width, height, minWidth, maxWidth, minHeight, maxHeight, zIndex, hasAutoZIndex, boxSizing)
	local o = {};

	o.m_width = width or Length:new();
    o.m_height = height or Length:new();

    o.m_minWidth = minWidth or ComputedStyle.initialMinSize();
    o.m_maxWidth = maxWidth or ComputedStyle.initialMaxSize();

    o.m_minHeight = minHeight or ComputedStyle.initialMinSize();
    o.m_maxHeight = maxHeight or ComputedStyle.initialMaxSize();

    o.m_zIndex = zIndex or 0;
    o.m_hasAutoZIndex = hasAutoZIndex or true;
    o.m_boxSizing = boxSizing or ComputedStyleConstants.BoxSizingEnum.CONTENT_BOX; -- EBoxSizing

	o.m_verticalAlign = Length:new();

	setmetatable(o, self);
	return o;
end

function StyleBoxData:clone()
	return StyleBoxData:new(self.m_width:clone(), self.m_height:clone(), self.m_minWidth:clone(), self.m_maxWidth:clone(), 
								self.m_minHeight:clone(), self.m_maxHeight:clone(), self.m_zIndex, self.m_hasAutoZIndex, self.m_boxSizing);
end

function StyleBoxData.__eq(a, b)
	    return a.m_width == b.m_width
           and a.m_height == b.m_height
           and a.m_minWidth == b.m_minWidth
           and a.m_maxWidth == b.m_maxWidth
           and a.m_minHeight == b.m_minHeight
           and a.m_maxHeight == b.m_maxHeight
           and a.m_zIndex == b.m_zIndex
           and a.m_hasAutoZIndex == b.m_hasAutoZIndex
           and a.m_boxSizing == b.m_boxSizing;
end

function StyleBoxData:Width()
	return self.m_width;
end

function StyleBoxData:Height()
	return self.m_height;
end


function StyleBoxData:MinWidth()
	return self.m_minWidth;
end

function StyleBoxData:MinHeight()
	return self.m_minHeight;
end


function StyleBoxData:MaxWidth()
	return self.m_maxWidth;
end

function StyleBoxData:MaxHeight()
	return self.m_maxHeight;
end


function StyleBoxData:VerticalAlign()
	return self.m_verticalAlign;
end


function StyleBoxData:ZIndex()
	return self.m_zIndex;
end

function StyleBoxData:HasAutoZIndex()
	return self.m_hasAutoZIndex;
end


function StyleBoxData:BoxSizing()
	return self.m_boxSizing;
end