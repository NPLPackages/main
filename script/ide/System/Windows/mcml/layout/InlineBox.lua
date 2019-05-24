--[[
Title: 
Author(s): LiPeng
Date: 2018/3/12
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/InlineBox.lua");
local InlineBox = commonlib.gettable("System.Windows.mcml.layout.InlineBox");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObject.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntPoint.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/PaintPhase.lua");
local PaintPhase = commonlib.gettable("System.Windows.mcml.layout.PaintPhase");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local IntSize = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local IntRect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
local Point = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");

local InlineBox = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.InlineBox"));

local TextDirectionEnum = ComputedStyleConstants.TextDirectionEnum;

function InlineBox:ctor()
	self.next = nil; -- The next element on the same line as us.
    self.prev = nil; -- The previous element on the same line as us.

    self.parent = nil; -- The box that contains us.

    self.renderer = nil;

    self.topLeft = Point:new();
    self.logicalWidth = 0;
    
    -- Some of these bits are actually for subclasses and moved here to compact the structures.

    -- for this class

    self.firstLine = false;

    self.constructed = false;
    self.bidiEmbeddingLevel = 0;

    self.dirty = false;
    self.extracted = false;
    self.hasVirtualLogicalHeight = false;

    self.isHorizontal = true;

    -- for RootInlineBox
    self.endsWithBreak = false;  -- Whether the line ends with a <br>.
    -- shared between RootInlineBox and InlineTextBox
    self.hasSelectedChildrenOrCanHaveLeadingExpansion = false; -- Whether we have any children selected (this bit will also be set if the <br> that terminates our line is selected).
    self.knownToHaveNoOverflow = true;
    self.hasEllipsisBoxOrHyphen = false;

    -- for InlineTextBox

    self.dirOverride = false;
    self.isText = false; -- Whether or not this object represents text with a non-zero height. Includes non-image list markers, text boxes.

    self.determinedIfNextOnLineExists = false;
    self.nextOnLineExists = false;
    self.expansion = 0; -- for justified text

    self.hasBadParent = false;
end


function InlineBox:init(obj, topLeft, logicalWidth, firstLine, constructed, dirty, extracted, isHorizontal, next, prev, parent)
	self.renderer = obj;
	if(topLeft) then
		self.next = next;
		self.prev = prev;
		self.topLeft = topLeft;
		self.logicalWidth = logicalWidth;
		self.firstLine = firstLine;
		self.constructed = constructed;
		self.dirty = dirty;
		self.extracted = extracted;
		self.isHorizontal = isHorizontal;
	end

	return self;
end

function InlineBox:BoxName()
	return "InlineBox"; 
end

function InlineBox:Destroy(renderArena)
	if(not self:IsInlineFlowBox() and not self:IsInlineTextBox())then
--		if(self:Renderer():IsReplaced()) then
--			local control = self:Renderer():GetControl();
--			if(control) then
--				control:SetParent(nil)
--			end
--		end
		local control = self:Renderer():GetControl();
		if(control) then
			control:SetParent(nil)
		end
	end
end

function InlineBox:Renderer()
	return self.renderer;
end

function InlineBox:IsLineBreak()
	return false;
end

--virtual function
function InlineBox:AdjustPositionForChildren(dx, dy)

end

function InlineBox:AdjustPosition(dx, dy)
	self.topLeft:Move(dx, dy);

    if (self.renderer:IsReplaced()) then
        self.renderer:Move(dx, dy); 
	end
end

function InlineBox:AdjustLineDirectionPosition(delta)
    if (self:IsHorizontal()) then
        self:AdjustPosition(delta, 0);
    else
        self:AdjustPosition(0, delta);
	end
end

function InlineBox:AdjustBlockDirectionPositionForChildren(delta)
	if (self:IsHorizontal()) then
        self:AdjustPositionForChildren(0, delta);
    else
        self:AdjustPositionForChildren(delta, 0);
	end
end

function InlineBox:AdjustBlockDirectionPosition(delta)
    if (self:IsHorizontal()) then
        self:AdjustPosition(0, delta);
    else
        self:AdjustPosition(delta, 0);
	end
end

function InlineBox:Next()
	return self.next;
end

function InlineBox:IsText()
	return self.isText;
end

function InlineBox:SetIsText(b)
	self.isText = b;
end
 
function InlineBox:IsInlineFlowBox()
	return false;
end

function InlineBox:IsInlineTextBox()
	return false;
end

function InlineBox:IsRootInlineBox()
	return false;
end

function InlineBox:IsSVGInlineTextBox()
	return false;
end

function InlineBox:IsSVGInlineFlowBox()
	return false;
end

function InlineBox:IsSVGRootInlineBox()
	return false;
end

function InlineBox:HasVirtualLogicalHeight()
	return self.hasVirtualLogicalHeight;
end

function InlineBox:SetHasVirtualLogicalHeight()
	self.hasVirtualLogicalHeight = true;
end

function InlineBox:VirtualLogicalHeight()
    --ASSERT_NOT_REACHED();
    return 0;
end

function InlineBox:IsHorizontal()
	return self.isHorizontal;
end

function InlineBox:SetIsHorizontal(horizontal)
	self.isHorizontal = horizontal;
end

function InlineBox:CalculateBoundaries()
    --ASSERT_NOT_REACHED();
    return IntRect:new();
end

function InlineBox:IsConstructed()
	return self.constructed;
end

function InlineBox:SetConstructed()
	self.constructed = true;
end

function InlineBox:SetExtracted(b)
	b = if_else(b == nil, true, b);
	self.extracted = b;
end
    
function InlineBox:SetFirstLineStyleBit(f)
	self.firstLine = f;
end

function InlineBox:IsFirstLineStyle()
	return self.firstLine;
end

function InlineBox:Remove()
	if (self:Parent()) then
        self:Parent():RemoveChild(self);
	end
end

function InlineBox:ToInlineTextBox()
	if(self:IsInlineTextBox()) then
		return self;
	end
end

function InlineBox:ToInlineFlowBox()
	if(self:IsInlineFlowBox()) then
		return self;
	end
end

function InlineBox:NextOnLine()
	return self.next;
end

function InlineBox:PrevOnLine()
	return self.prev;
end

function InlineBox:SetNextOnLine(next)
    --ASSERT(m_parent || !next);
    self.next = next;
end

function InlineBox:SetPrevOnLine(prev)
    --ASSERT(m_parent || !prev);
    self.prev = prev;
end

function InlineBox:NextOnLineExists()
	if (not self.determinedIfNextOnLineExists) then
        self.determinedIfNextOnLineExists = true;

        if (not self:Parent()) then
            self.nextOnLineExists = false;
        elseif (self:NextOnLine()) then
            self.nextOnLineExists = true;
        else
            self.nextOnLineExists = self:Parent():NextOnLineExists();
		end
    end
    return self.nextOnLineExists;
end

function InlineBox:IsLeaf()
	return true;
end
    
function InlineBox:NextLeafChild()
	local leaf = nil;
	local box = self:NextOnLine();
	while(box and not leaf) do
		if(box:IsLeaf()) then
			leaf = box;
		else
			leaf = box:FirstLeafChild();
		end
		box = box:NextOnLine()
	end
    if (not leaf and self:Parent()) then
        leaf = self:Parent():NextLeafChild();
	end
    return leaf;
end

function InlineBox:PrevLeafChild()
	local leaf = nil;
	local box = self:PrevOnLine();
	while(box and not leaf) do
		if(box:IsLeaf()) then
			leaf = box;
		else
			leaf = box:LastLeafChild();
		end
		box = box:PrevOnLine()
	end
    if (not leaf and self:Parent()) then
        leaf = self:Parent():PrevLeafChild();
	end
    return leaf;
end
        
function InlineBox:Parent()
    --ASSERT(!m_hasBadParent);
    return self.parent;
end

function InlineBox:SetParent(parent)
	self.parent = parent;
end

function InlineBox:Root()
	if (self.parent) then
        return self.parent:Root(); 
	end
    --ASSERT(isRootInlineBox());
    return self;
end

-- x() is the left side of the box in the containing block's coordinate system.
function InlineBox:SetX(x)
	self.topLeft:SetX(x);
end

function InlineBox:X()
	return self.topLeft:X();
end

function InlineBox:Left()
	return self.topLeft:X();
end

-- y() is the top side of the box in the containing block's coordinate system.
function InlineBox:SetY(y)
	self.topLeft:SetY(y);
end

function InlineBox:Y()
	return self.topLeft:Y();
end

function InlineBox:Top()
	return self.topLeft:Y();
end

function InlineBox:TopLeft()
	return self.topLeft;
end

function InlineBox:Width()
	return if_else(self:IsHorizontal(), self:LogicalWidth(), self:LogicalHeight());
end

function InlineBox:Height()
	return if_else(self:IsHorizontal(), self:LogicalHeight(), self:LogicalWidth());
end

function InlineBox:Size()
	return IntSize:new(self:Width(), self:Height());
end

function InlineBox:Right()
	return self:Left() + self:Width();
end

function InlineBox:Bottom()
	return self:Top() + self:Height();
end

-- The logicalLeft position is the left edge of the line box in a horizontal line and the top edge in a vertical line.
function InlineBox:LogicalLeft()
	return if_else(self:IsHorizontal(), self.topLeft:X(), self.topLeft:Y());
end

function InlineBox:LogicalRight()
	return self:LogicalLeft() + self:LogicalWidth();
end

function InlineBox:SetLogicalLeft(left)
    if (self:IsHorizontal()) then
        self:SetX(left);
    else
        self:SetY(left);
	end
end

function InlineBox:PixelSnappedLogicalLeft()
	return self:LogicalLeft();
end

function InlineBox:PixelSnappedLogicalRight()
	return math.ceil(self:LogicalRight());
end

-- The logicalTop[ position is the top edge of the line box in a horizontal line and the left edge in a vertical line.
function InlineBox:LogicalTop()
	return if_else(self:IsHorizontal(), self.topLeft:Y(), self.topLeft:X());
end

function InlineBox:LogicalBottom()
	return self:LogicalTop() + self:LogicalHeight();
end

function InlineBox:SetLogicalTop(top)
    if (self:IsHorizontal()) then
        self:SetY(top);
    else
        self:SetX(top);
	end
end

-- The logical width is our extent in the line's overall inline direction, i.e., width for horizontal text and height for vertical text.
function InlineBox:SetLogicalWidth(w)
	self.logicalWidth = w;
end

function InlineBox:LogicalWidth()
	return self.logicalWidth;
end

function InlineBox:IsDirty()
	return self.dirty;
end

function InlineBox:MarkDirty(dirty)
	dirty = if_else(dirty == nil, true, dirty);
	self.dirty = dirty;
end

-- The logical height is our extent in the block flow direction, i.e., height for horizontal text and width for vertical text.
function InlineBox:LogicalHeight()
	if (self:HasVirtualLogicalHeight()) then
        return self:VirtualLogicalHeight();
	end
    
    if (self:Renderer():IsText()) then
        return if_else(self.isText, self:Renderer():Style(self.firstLine):FontMetrics():height(), 0);
	end
    if (self:Renderer():IsBox() and self:Parent()) then
		if(self:IsHorizontal()) then
			return self:Renderer():Height();
		end
        return self.renderer:Width();
	end

    --ASSERT(isInlineFlowBox());
    local flowObject = self:BoxModelObject();
	local result;
	if(self:IsRootInlineBox()) then
		result = self:Renderer():Style(self.firstLine):ComputedLineHeight();
	else
		local fontMetrics = self:Renderer():Style(self.firstLine):FontMetrics();
		result = fontMetrics:lineSpacing();
	end
    --local fontMetrics = self:Renderer():Style(self.firstLine):FontMetrics();
    --local result = fontMetrics:lineSpacing();
	--local result = self:Renderer():Style(self.firstLine):ComputedLineHeight();
    if (self:Parent()) then
        result = result + flowObject:BorderAndPaddingLogicalHeight();
	end
    return result;
end

-- Use with caution! The type is not checked!
function InlineBox:BoxModelObject()
    if (not self.renderer:IsText()) then
        return self.renderer;
	end
    return nil;
end

function InlineBox:Expansion()
	return self.expansion;
end

function InlineBox:DeleteLine(arena)
    if (not self.extracted and self.renderer:IsBox()) then
        self.renderer:SetInlineBoxWrapper();
	end
    self:Destroy(arena);
end

function InlineBox:KnownToHaveNoOverflow()
	return self.knownToHaveNoOverflow;
end

function InlineBox:ClearKnownToHaveNoOverflow()
	self.knownToHaveNoOverflow = false;
    if (self:Parent() and self:Parent():KnownToHaveNoOverflow()) then
        self:Parent():ClearKnownToHaveNoOverflow();
	end
end

function InlineBox:BaselinePosition(baselineType) 
	local direction = if_else(self:IsHorizontal(), "HorizontalLine", "VerticalLine");
	return self:BoxModelObject():BaselinePosition(baselineType, self.firstLine, direction, "PositionOnContainingLine");
end

function InlineBox:LineHeight()
	local direction = if_else(self:IsHorizontal(), "HorizontalLine", "VerticalLine");
	return self:BoxModelObject():LineHeight(self.firstLine, direction, "PositionOnContainingLine");
end

function InlineBox:VerticalAlign()
	return self:Renderer():Style(self.firstLine):VerticalAlign();
end

function InlineBox:BidiLevel()
	return self.bidiEmbeddingLevel;
end

function InlineBox:SetBidiLevel(level)
	self.bidiEmbeddingLevel = level;
end

function InlineBox:Direction()
	return if_else(self.bidiEmbeddingLevel % 2, TextDirectionEnum.RTL, TextDirectionEnum.LTR);
end

function InlineBox:IsLeftToRightDirection()
	return self:Direction() == TextDirectionEnum.LTR;
end

--void paint(PaintInfo&, const LayoutPoint&, LayoutUnit lineTop, LayoutUnit lineBottom)
function InlineBox:Paint(paintInfo, paintOffset, lineTop, lineBottom)
	--if (!paintInfo.shouldPaintWithinRoot(renderer()) || (paintInfo.phase != PaintPhaseForeground && paintInfo.phase != PaintPhaseSelection))
	if (not paintInfo:ShouldPaintWithinRoot(self:Renderer()) or (paintInfo.phase ~= PaintPhase.PaintPhaseForeground and paintInfo.phase ~= PaintPhase.PaintPhaseSelection)) then
        return;
	end

--    LayoutPoint childPoint = paintOffset;
--    if (parent()->renderer()->style()->isFlippedBlocksWritingMode()) // Faster than calling containingBlock().
--        childPoint = renderer()->containingBlock()->flipForWritingModeForChild(toRenderBox(renderer()), childPoint);
    
    -- Paint all phases of replaced elements atomically, as though the replaced element established its
    -- own stacking context.  (See Appendix E.2, section 6.4 on inline block/table elements in the CSS2.1
    -- specification.)
--    bool preservePhase = paintInfo.phase == PaintPhaseSelection || paintInfo.phase == PaintPhaseTextClip;
--    PaintInfo info(paintInfo);
--    info.phase = preservePhase ? paintInfo.phase : PaintPhaseBlockBackground;
--    renderer()->paint(info, childPoint);
--    if (!preservePhase) {
--        info.phase = PaintPhaseChildBlockBackgrounds;
--        renderer()->paint(info, childPoint);
--        info.phase = PaintPhaseFloat;
--        renderer()->paint(info, childPoint);
--        info.phase = PaintPhaseForeground;
--        renderer()->paint(info, childPoint);
--        info.phase = PaintPhaseOutline;
--        renderer()->paint(info, childPoint);
--    }
	local preservePhase = paintInfo.phase == PaintPhase.PaintPhaseSelection or paintInfo.phase == PaintPhase.PaintPhaseTextClip;
	local info = paintInfo:clone();
	info.phase = if_else(preservePhase, paintInfo.phase, PaintPhase.PaintPhaseBlockBackground);
	info:Rect():SetX(info:Rect():X() - self:Renderer():X())
	info:Rect():SetY(info:Rect():Y() - self:Renderer():Y())
	local childPoint = paintOffset;
	self:Renderer():Paint(info, childPoint);
	if (not preservePhase) then
		info.phase = PaintPhase.PaintPhaseChildBlockBackgrounds;
        self:Renderer():Paint(info, childPoint);
        info.phase = PaintPhase.PaintPhaseFloat;
        self:Renderer():Paint(info, childPoint);
        info.phase = PaintPhase.PaintPhaseForeground;
        self:Renderer():Paint(info, childPoint);
--        info.phase = PaintPhase.PaintPhaseOutline;
--        renderer()->paint(info, childPoint);
	end
end

function InlineBox:DirtyLineBoxes()
    self:MarkDirty();
	local curr = self:Parent();
	while(curr and not curr:IsDirty()) do
		curr:MarkDirty();
		curr = curr:Parent();
	end
end

--void flipForWritingMode(FloatRect&);
--FloatPoint flipForWritingMode(const FloatPoint&);
--void flipForWritingMode(IntRect&);
--IntPoint flipForWritingMode(const IntPoint&);
-- because these funtions are similar, we can use this one replace;
function InlineBox:FlipForWritingMode(point)
    if (not self:Renderer():Style():IsFlippedBlocksWritingMode()) then
        return point;
	end
    return self:Root():Block():FlipForWritingMode(point);
end

function InlineBox:ExtractLine()
	self.extracted = true;
    if (self.renderer:IsBox()) then
        self.renderer:ToRenderBox():SetInlineBoxWrapper(nil);
	end
end

function InlineBox:AttachLine()
    self.extracted = false;
    if (self.renderer:IsBox()) then
        self.renderer:ToRenderBox():SetInlineBoxWrapper(self);
	end
end

--FloatPoint InlineBox::locationIncludingFlipping()
function InlineBox:LocationIncludingFlipping()
    if (not self:Renderer():Style():IsFlippedBlocksWritingMode()) then
        return Point:new(self:X(), self:Y());
	end
	--RenderBlock* block = root()->block();
    local block = self:Root():Block();
    if (block:Style():IsHorizontalWritingMode()) then
        return Point:new(self:X(), block:Height() - self:Height() - self:Y());
    else
        return Point:new(block:Width() - self:Width() - self:X(), self:Y());
	end
end