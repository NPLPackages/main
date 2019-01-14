--[[
Title: 
Author(s): LiPeng
Date: 2018/11/27
Desc: 

LayoutOverflow is a class for tracking content that spills out of a box.  This class is used by LayoutBox and
InlineFlowBox.

There are two types of overflow: layout overflow (which is expected to be reachable via scrolling mechanisms) and
visual overflow (which is not expected to be reachable via scrolling mechanisms).

Layout overflow examples include other boxes that spill out of our box,  For example, in the inline case a tall image
could spill out of a line box. 
 
Examples of visual overflow are shadows, text stroke (and eventually outline and border-image).

This object is allocated only when some of these fields have non-default values in the owning box.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutOverflow.lua");
local LayoutOverflow = commonlib.gettable("System.Windows.mcml.layout.LayoutOverflow");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
local LayoutRect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
local LayoutOverflow = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.LayoutOverflow"));

local math_min = math.min;
local math_max = math.max;

function LayoutOverflow:ctor()
	self.m_minYLayoutOverflow = nil;
	self.m_maxYLayoutOverflow = nil;
	self.m_minXLayoutOverflow = nil;
	self.m_maxXLayoutOverflow = nil;
	self.m_minYVisualOverflow = nil;
	self.m_maxYVisualOverflow = nil;
	self.m_minXVisualOverflow = nil;
	self.m_maxXVisualOverflow = nil;
end

--RenderOverflow(const LayoutRect& layoutRect, const LayoutRect& visualRect) 
function LayoutOverflow:init(layoutRect, visualRect)
	echo("LayoutOverflow:init")
	echo("LayoutOverflow:LayoutOverflowChanged")
	echo(layoutRect)
	self.m_minYLayoutOverflow = layoutRect:Y();
	self.m_maxYLayoutOverflow = layoutRect:MaxY();
	self.m_minXLayoutOverflow = layoutRect:X();
	self.m_maxXLayoutOverflow = layoutRect:MaxX();
	self.m_minYVisualOverflow = visualRect:Y();
	self.m_maxYVisualOverflow = visualRect:MaxY();
	self.m_minXVisualOverflow = visualRect:X();
	self.m_maxXVisualOverflow = visualRect:MaxX();

	return self;
end
   
function LayoutOverflow:MinYLayoutOverflow()
	return self.m_minYLayoutOverflow;
end

function LayoutOverflow:MaxYLayoutOverflow()
	return self.m_maxYLayoutOverflow;
end

function LayoutOverflow:MinXLayoutOverflow()
	return self.m_minXLayoutOverflow;
end

function LayoutOverflow:MaxXLayoutOverflow()
	return self.m_maxXLayoutOverflow;
end


function LayoutOverflow:MinYVisualOverflow()
	return self.m_minYVisualOverflow;
end

function LayoutOverflow:MaxYVisualOverflow()
	return self.m_maxYVisualOverflow;
end

function LayoutOverflow:MinXVisualOverflow()
	return self.m_minXVisualOverflow;
end

function LayoutOverflow:MaxXVisualOverflow()
	return self.m_maxXVisualOverflow;
end


function LayoutOverflow:SetMinYLayoutOverflow(overflow)
	self.m_minYLayoutOverflow = overflow;
end

function LayoutOverflow:SetMaxYLayoutOverflow(overflow)
	self.m_maxYLayoutOverflow = overflow;
end

function LayoutOverflow:SetMinXLayoutOverflow(overflow)
	self.m_minXLayoutOverflow = overflow;
end

function LayoutOverflow:SetMaxXLayoutOverflow(overflow)
	self.m_maxXLayoutOverflow = overflow;
end

    
function LayoutOverflow:SetMinYVisualOverflow(overflow)
	self.m_minYVisualOverflow = overflow;
end

function LayoutOverflow:SetMaxYVisualOverflow(overflow)
	self.m_maxYVisualOverflow = overflow;
end

function LayoutOverflow:SetMinXVisualOverflow(overflow)
	self.m_minXVisualOverflow = overflow;
end

function LayoutOverflow:SetMaxXVisualOverflow(overflow)
	self.m_maxXVisualOverflow = overflow;
end


function LayoutOverflow:LayoutOverflowRect()
    return LayoutRect:new(self.m_minXLayoutOverflow, self.m_minYLayoutOverflow, self.m_maxXLayoutOverflow - self.m_minXLayoutOverflow, self.m_maxYLayoutOverflow - self.m_minYLayoutOverflow);
end

function LayoutOverflow:VisualOverflowRect()
    return LayoutRect:new(self.m_minXVisualOverflow, self.m_minYVisualOverflow, self.m_maxXVisualOverflow - self.m_minXVisualOverflow, self.m_maxYVisualOverflow - self.m_minYVisualOverflow);
end

function LayoutOverflow:Move(dx, dy)
    self.m_minYLayoutOverflow = self.m_minYLayoutOverflow + dy;
    self.m_maxYLayoutOverflow = self.m_maxYLayoutOverflow + dy;
    self.m_minXLayoutOverflow = self.m_minXLayoutOverflow + dx;
    self.m_maxXLayoutOverflow = self.m_maxXLayoutOverflow + dx;
    
    self.m_minYVisualOverflow = self.m_minYVisualOverflow + dy;
    self.m_maxYVisualOverflow = self.m_maxYVisualOverflow + dy;
    self.m_minXVisualOverflow = self.m_minXVisualOverflow + dx;
    self.m_maxXVisualOverflow = self.m_maxXVisualOverflow + dx;
end

function LayoutOverflow:AddLayoutOverflow(rect)
	echo("LayoutOverflow:AddLayoutOverflow")
	echo("LayoutOverflow:LayoutOverflowChanged")
	echo(rect)
    self.m_minYLayoutOverflow = math_min(rect:Y(), self.m_minYLayoutOverflow);
    self.m_maxYLayoutOverflow = math_max(rect:MaxY(), self.m_maxYLayoutOverflow);
    self.m_minXLayoutOverflow = math_min(rect:X(), self.m_minXLayoutOverflow);
    self.m_maxXLayoutOverflow = math_max(rect:MaxX(), self.m_maxXLayoutOverflow);
end

function LayoutOverflow:AddVisualOverflow(rect)
    self.m_minYVisualOverflow = math_min(rect:Y(), self.m_minYVisualOverflow);
    self.m_maxYVisualOverflow = math_max(rect:MaxY(), self.m_maxYVisualOverflow);
    self.m_minXVisualOverflow = math_min(rect:X(), self.m_minXVisualOverflow);
    self.m_maxXVisualOverflow = math_max(rect:MaxX(), self.m_maxXVisualOverflow);
end

function LayoutOverflow:SetLayoutOverflow(rect)
	echo("LayoutOverflow:SetLayoutOverflow")
	echo("LayoutOverflow:LayoutOverflowChanged")
	echo(rect)
    self.m_minYLayoutOverflow = rect:Y();
    self.m_maxYLayoutOverflow = rect:MaxY();
    self.m_minXLayoutOverflow = rect:X();
    self.m_maxXLayoutOverflow = rect:MaxX();
end

function LayoutOverflow:SetVisualOverflow(rect)
    self.m_minYVisualOverflow = rect:Y();
    self.m_maxYVisualOverflow = rect:MaxY();
    self.m_minXVisualOverflow = rect:X();
    self.m_maxXVisualOverflow = rect:MaxX();
end

function LayoutOverflow:ResetLayoutOverflow(rect)
	echo("LayoutOverflow:ResetLayoutOverflow")
	echo("LayoutOverflow:LayoutOverflowChanged")
	echo(rect)
    self.m_minYLayoutOverflow = rect:Y();
    self.m_maxYLayoutOverflow = rect:MaxY();
    self.m_minXLayoutOverflow = rect:X();
    self.m_maxXLayoutOverflow = rect:MaxX();
end

