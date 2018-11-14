--[[
Title: 
Author(s): LiPeng
Date: 2018/11/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutReplaced.lua");
local LayoutReplaced = commonlib.gettable("System.Windows.mcml.layout.LayoutReplaced");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutRepainter.lua");
local LayoutRepainter = commonlib.gettable("System.Windows.mcml.layout.LayoutRepainter");
local LayoutReplaced = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBox"), commonlib.gettable("System.Windows.mcml.layout.LayoutReplaced"));

function LayoutReplaced:ctor()

end

function LayoutReplaced:init(node)
	LayoutReplaced._super.init(self, node);
	self:SetReplaced(true);

	return self;
end

function LayoutReplaced:GetName()
	return "LayoutReplaced";
end

function LayoutReplaced:CanHaveChildren()
	return false;
end

function LayoutReplaced:Layout()
    --ASSERT(needsLayout());
    
    --LayoutRepainter repainter(*this, checkForRepaintDuringLayout());
	local repainter = LayoutRepainter:new():init(self, self:CheckForRepaintDuringLayout());
    
    --setHeight(minimumReplacedHeight());

    self:ComputeLogicalWidth();
    self:ComputeLogicalHeight();

    --m_overflow.clear();
    --addBoxShadowAndBorderOverflow();
    self:UpdateLayerTransform();
    
    repainter:RepaintAfterLayout();
    self:SetNeedsLayout(false);
end

--void RenderBox::paintBoxDecorations(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutReplaced:PaintBoxDecorations(paintInfo, paintOffset)
	local rect = self.frame_rect:clone_from_pool();
	if(self:HasSelfPaintingLayer()) then
		rect:Move(paintOffset:X(), paintOffset:Y());
	end
	self:PaintBackground(paintInfo, rect);
end

--void RenderReplaced::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutReplaced:Paint(paintInfo, paintOffset)
	self:PaintBoxDecorations(paintInfo, paintOffset);
end