--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutScrollCorner.lua");
local LayoutScrollCorner = commonlib.gettable("System.Windows.mcml.layout.LayoutScrollCorner");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlock.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Canvas.lua");
local Canvas = commonlib.gettable("System.Windows.Controls.Canvas");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
local LayoutScrollCorner = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBlock"), commonlib.gettable("System.Windows.mcml.layout.LayoutScrollCorner"));

local IntRect = Rect;

function LayoutScrollCorner:ctor()
	-- LayoutLayer
	self.scrollArea = nil
	-- LayoutBox
	self.owner = nil;

	self.control = nil;
end

function LayoutScrollCorner:init(scrollArea, orientation, renderer)
	LayoutScrollCorner._super.init(self)
	self.scrollArea = scrollArea;
	self.owner = renderer;

--	local thickness = self.theme:scrollbarThickness();
--    self:SetFrameRect(IntRect:new(0, 0, thickness, thickness));

	return self;
end

function LayoutScrollCorner:GetName()
	return "LayoutScrollCorner";
end

function LayoutScrollCorner:Destroy()
	if(self.control) then
--		local scrollArea_control = self.scrollArea:Renderer():GetControl();
--		scrollArea_control:DestroyScrollCorner(); 
		self.control:Destroy();
		self.control = nil;
	end
end

--ScrollableArea* scrollableArea() const { return m_scrollableArea; }
function LayoutScrollCorner:ScrollableArea()
	return self.scrollableArea;
end

function LayoutScrollCorner:StyleChanged()
    --updateScrollbarParts();
end

function LayoutScrollCorner:GetControl()	
	return self.control;
end

function LayoutScrollCorner:GetOrCreateControl()	
	if(not self.control) then
		local scrollArea_control = self.scrollArea:Renderer():GetControl();
		local corner = Canvas:new():init(scrollArea_control);
		corner:SetBackgroundColor("#ffffffff")
		self.control = corner;
	end	
	return self.control
end

--void RenderReplaced::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutScrollCorner:Paint(paintInfo, paintOffset)
	echo("LayoutScrollCorner:Paint")
	echo(paintOffset)
	echo(self.frame_rect)

	self:PaintBoxDecorations(paintInfo, paintOffset);
end
