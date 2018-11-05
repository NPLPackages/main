--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/OutlineValue.lua");
local OutlineValue = commonlib.gettable("System.Windows.mcml.style.OutlineValue");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/style/BorderValue.lua");
local BorderValue = commonlib.gettable("System.Windows.mcml.style.BorderValue");

local OutlineValue = commonlib.gettable("System.Windows.mcml.style.OutlineValue");
OutlineValue.__index = OutlineValue;

function OutlineValue:new(width, style, color, offset)
	local o = BorderValue:new(width, style, color);
	o.m_offset = offset or 0;
	setmetatable(o, self);
	return o;
end

function OutlineValue:clone()
	local o = OutlineValue:new(self.m_width, self.m_style, self.m_color:clone(), self.m_offset);
	return o;
end

function OutlineValue.__eq(a, b)
	return a.m_color == b.m_color and a.m_width == b.m_width and a.m_style == b.m_style and a.m_offset == b.m_offset and a.m_isAuto == b.m_isAuto;
end

function OutlineValue:Offset()
	return self.m_offset;
end

function OutlineValue:isAuto()
	return self.m_isAuto;
end

function OutlineValue:Style()
	return self.m_style;
end