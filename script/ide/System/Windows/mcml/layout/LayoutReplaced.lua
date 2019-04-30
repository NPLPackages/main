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
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local IntSize = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local LayoutRepainter = commonlib.gettable("System.Windows.mcml.layout.LayoutRepainter");
local LayoutReplaced = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBox"), commonlib.gettable("System.Windows.mcml.layout.LayoutReplaced"));

local VisibilityEnum = ComputedStyleConstants.VisibilityEnum;

local cDefaultWidth = 300;
local cDefaultHeight = 150;

function LayoutReplaced:ctor()
	self.m_intrinsicSize = IntSize:new(cDefaultWidth, cDefaultHeight);
    self.m_hasIntrinsicSize = false;
end

function LayoutReplaced:init(node, intrinsicSize)
	LayoutReplaced._super.init(self, node);
	self:SetReplaced(true);
	if(intrinsicSize) then
		self.m_hasIntrinsicSize = true;
		self:SetIntrinsicSize(intrinsicSize)
	end
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
--	if(self:HasSelfPaintingLayer()) then
--		rect:Move(paintOffset:X(), paintOffset:Y());
--	end
	self:PaintBackground(paintInfo, rect);
end

--void RenderReplaced::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutReplaced:Paint(paintInfo, paintOffset)
	self:PaintBoxDecorations(paintInfo, paintOffset);
end

--IntSize RenderReplaced::intrinsicSize() const
function LayoutReplaced:IntrinsicSize()
    return self.m_intrinsicSize;
end

function LayoutReplaced:SetIntrinsicSize(size)
    --ASSERT(m_hasIntrinsicSize);
    self.m_intrinsicSize:Reset(size:Width(), size:Height());
end

function LayoutReplaced:SetHasIntrinsicSize()
	self.m_hasIntrinsicSize = true;
end

--bool RenderReplaced::shouldPaint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutReplaced:ShouldPaint(paintInfo, paintOffset)
--    if (paintInfo.phase != PaintPhaseForeground && paintInfo.phase != PaintPhaseOutline && paintInfo.phase != PaintPhaseSelfOutline 
--            && paintInfo.phase != PaintPhaseSelection && paintInfo.phase != PaintPhaseMask)
--        return false;

    if (not paintInfo:ShouldPaintWithinRoot(self)) then
        return false;
	end
        
    -- if we're invisible or haven't received a layout yet, then just bail.
    if (self:Style():Visibility() ~= VISIBLE) then
        return false;
	end

--    LayoutPoint adjustedPaintOffset = paintOffset + location();
--
--    // Early exit if the element touches the edges.
--    LayoutUnit top = adjustedPaintOffset.y() + minYVisualOverflow();
--    LayoutUnit bottom = adjustedPaintOffset.y() + maxYVisualOverflow();
--    if (isSelected() && m_inlineBoxWrapper) {
--        LayoutUnit selTop = paintOffset.y() + m_inlineBoxWrapper->root()->selectionTop();
--        LayoutUnit selBottom = paintOffset.y() + selTop + m_inlineBoxWrapper->root()->selectionHeight();
--        top = min(selTop, top);
--        bottom = max(selBottom, bottom);
--    }
--    
--    LayoutUnit os = 2 * maximalOutlineSize(paintInfo.phase);
--    if (adjustedPaintOffset.x() + minXVisualOverflow() >= paintInfo.rect.maxX() + os || adjustedPaintOffset.x() + maxXVisualOverflow() <= paintInfo.rect.x() - os)
--        return false;
--    if (top >= paintInfo.rect.maxY() + os || bottom <= paintInfo.rect.y() - os)
--        return false;
--
    return true;
end