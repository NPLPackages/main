--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutInline.lua");
local LayoutInline = commonlib.gettable("System.Windows.mcml.layout.LayoutInline");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBoxModelObject.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObjectChildList.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutLineBoxList.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/InlineFlowBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local Length = commonlib.gettable("System.Windows.mcml.platform.Length");
local InlineFlowBox = commonlib.gettable("System.Windows.mcml.layout.InlineFlowBox");
local LayoutLineBoxList = commonlib.gettable("System.Windows.mcml.layout.LayoutLineBoxList");
local LayoutObjectChildList = commonlib.gettable("System.Windows.mcml.layout.LayoutObjectChildList");
local LayoutInline = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBoxModelObject"), commonlib.gettable("System.Windows.mcml.layout.LayoutInline"));

local LayoutRect = Rect;

local VerticalAlignEnum = ComputedStyleConstants.VerticalAlignEnum;
local TextEmphasisMarkEnum = ComputedStyleConstants.TextEmphasisMarkEnum;

function LayoutInline:ctor()
	self.name = "LayoutInline";
	self.children = LayoutObjectChildList:new();
    self.lineBoxes = LayoutLineBoxList:new();   -- All of the line boxes created for this inline flow.  For example, <i>Hello<br>world.</i> will have two <i> line boxes.

    self.lineHeight = -1;
    self.alwaysCreateLineBoxes = false;
end

function LayoutInline:init(node)
	LayoutInline._super.init(self, node);

	return self;
end

function LayoutInline:GetName()
	return "LayoutInline";
end

function LayoutInline:IsLayoutInline()
	return true;
end

function LayoutInline:DirtyLinesFromChangedChild(child)
	self.lineBoxes:DirtyLinesFromChangedChild(self, child);
end

function LayoutInline:UpdateAlwaysCreateLineBoxes(fullLayout)
	--TODO: fixed this function

	-- Once we have been tainted once, just assume it will happen again. This way effects like hover highlighting that change the
    -- background color will only cause a layout on the first rollover.
    if (self.alwaysCreateLineBoxes) then
        return;
	end

    local parentStyle = self:Parent():Style();
    local parentRenderInline = if_else(self:Parent():IsLayoutInline(), self:Parent(), nil);
    local checkFonts = self:Document():InNoQuirksMode();
	--local checkFonts = false;
    local alwaysCreateLineBoxes = (parentRenderInline ~= nil and parentRenderInline:AlwaysCreateLineBoxes())
        or (parentRenderInline ~= nil and parentStyle:VerticalAlign() ~= VerticalAlignEnum.BASELINE)
        or self:Style():VerticalAlign() ~= VerticalAlignEnum.BASELINE
        or self:Style():TextEmphasisMark() ~= TextEmphasisMarkEnum.TextEmphasisMarkNone
        or (checkFonts and (not parentStyle:Font():FontMetrics():hasIdenticalAscentDescentAndLineGap(self:Style():Font():FontMetrics())))
		or (checkFonts and parentStyle:LineHeight() ~= self:Style():LineHeight());
	-- document()->usesFirstLineRules() default value is false;
    if (not alwaysCreateLineBoxes and checkFonts and self:Document():UsesFirstLineRules()) then
        -- Have to check the first line style as well.
        parentStyle = self:Parent():Style(true);
        local childStyle = self:Style(true);
        alwaysCreateLineBoxes = not parentStyle:Font():FontMetrics():hasIdenticalAscentDescentAndLineGap(childStyle:Font():FontMetrics())
        or childStyle:VerticalAlign() ~= VerticalAlignEnum.BASELINE
        or parentStyle:LineHeight() ~= childStyle:LineHeight();
    end

    if (alwaysCreateLineBoxes) then
        if (not fullLayout) then
            self:DirtyLineBoxes(false);
		end
			echo("self.alwaysCreateLineBoxes = true;");
        self.alwaysCreateLineBoxes = true;
    end
end

function LayoutInline:DirtyLineBoxes(fullLayout)
	if (fullLayout) then
        self.lineBoxes:DeleteLineBoxes(self:RenderArena());
        return;
    end

    if (not self:AlwaysCreateLineBoxes()) then
        -- We have to grovel into our children in order to dirty the appropriate lines.
		local curr = self:FirstChild();
		while(curr) do
			if (curr:IsFloatingOrPositioned()) then
                --continue;
			else
				if (curr:IsBox() and not curr:NeedsLayout()) then
					local currBox = curr:ToRenderBox();
					if (currBox:InlineBoxWrapper()) then
						currBox:InlineBoxWrapper():Root():MarkDirty();
					end
				elseif (not curr:SelfNeedsLayout()) then
					if (curr:IsLayoutInline()) then
						local currInline = curr:ToRenderInline();
						local childLine = currInline:FirstLineBox();
						while(childLine) do
							childLine:Root():MarkDirty();
							childLine = childLine:NextLineBox();
						end
					elseif (curr:IsText()) then
						local currText = curr:ToRenderText();
						local childText = currText:FirstTextBox();
						while(childText) do
							childText:Root():MarkDirty();
							childText = childText:NextTextBox();
						end
					end
				end
			end
			curr = curr:NextSibling();
		end
    else
		self.lineBoxes:DirtyLineBoxes();
	end
end

function LayoutInline:LineBoxes()
	return self.lineBoxes;
end

function LayoutInline:FirstLineBox()
	return self.lineBoxes:FirstLineBox();
end

function LayoutInline:LastLineBox()
	return self.lineBoxes:LastLineBox();
end

function LayoutInline:WillBeDestroyed()
--#ifndef NDEBUG
    -- Make sure we do not retain "this" in the continuation outline table map of our containing blocks.
    if (self:Parent() and self:Style():Visibility() == VISIBLE and self:HasOutline()) then
--        bool containingBlockPaintsContinuationOutline = continuation() || isInlineElementContinuation();
--        if (containingBlockPaintsContinuationOutline) {
--            if (RenderBlock* cb = containingBlock()) {
--                if (RenderBlock* cbCb = cb->containingBlock())
--                    ASSERT(!cbCb->paintsContinuationOutline(this));
--            }
--        }
    end
--#endif

    -- Make sure to destroy anonymous children first while they are still connected to the rest of the tree, so that they will
    -- properly dirty line boxes that they are removed from.  Effects that do :before/:after only on hover could crash otherwise.
    self:Children():DestroyLeftoverChildren();

    -- Destroy our continuation before anything other than anonymous children.
    -- The reason we don't destroy it before anonymous children is that they may
    -- have continuations of their own that are anonymous children of our continuation.
--    RenderBoxModelObject* continuation = this->continuation();
--    if (continuation) {
--        continuation->destroy();
--        setContinuation(0);
--    }
    
    if (not self:DocumentBeingDestroyed()) then
        if (self:FirstLineBox()) then
            -- We can't wait for RenderBoxModelObject::destroy to clear the selection,
            -- because by then we will have nuked the line boxes.
            -- FIXME: The FrameSelection should be responsible for this when it
            -- is notified of DOM mutations.
--            if (isSelectionBorder())
--                view()->clearSelection();

            -- If line boxes are contained inside a root, that means we're an inline.
            -- In that case, we need to remove all the line boxes so that the parent
            -- lines aren't pointing to deleted children. If the first line box does
            -- not have a parent that means they are either already disconnected or
            -- root lines that can just be destroyed without disconnecting.
            if (self:FirstLineBox():Parent()) then
				local box = self:FirstLineBox();
				while(box) do
					box:Remove();
					box = box:NextLineBox();
				end
            end
        elseif (self:Parent()) then
            self:Parent():DirtyLinesFromChangedChild(self);
		end
    end

    self.lineBoxes:DeleteLineBoxes(self:RenderArena());

    LayoutInline._super.WillBeDestroyed(self);
end

function LayoutInline:StyleDidChange(diff, oldStyle)
	LayoutInline._super.StyleDidChange(self, diff, oldStyle);

	self.lineHeight = -1;

	if (not self.alwaysCreateLineBoxes) then
		--local alwaysCreateLineBoxes = self:HasSelfPaintingLayer() or self:HasBoxDecorations() or self:Style():HasPadding() or self:Style():HasMargin() or self:Style():HasOutline();
        local alwaysCreateLineBoxes = self:HasSelfPaintingLayer() or self:HasBoxDecorations() or self:Style():HasPadding() or self:Style():HasMargin();
        if (oldStyle and alwaysCreateLineBoxes) then
            self:DirtyLineBoxes(false);
            self:SetNeedsLayout(true);
        end
        self.alwaysCreateLineBoxes = alwaysCreateLineBoxes;
    end
end

--LayoutUnit RenderInline::lineHeight(bool firstLine, LineDirectionMode /*direction*/, LinePositionMode /*linePositionMode*/) const
function LayoutInline:LineHeight(firstLine, LineDirectionMode, LinePositionMode)
	if (firstLine and self:Document():UsesFirstLineRules()) then
        local s = self:Style(firstLine);
        if (s ~= self:Style()) then
            return s:ComputedLineHeight();
		end
    end
    
    if (self.lineHeight == -1) then
        self.lineHeight = self:Style():ComputedLineHeight();
	end
    return self.lineHeight;
end

--LayoutUnit RenderInline::baselinePosition(FontBaseline baselineType, bool firstLine, LineDirectionMode direction, LinePositionMode linePositionMode) const
function LayoutInline:BaselinePosition(baselineType, firstLine, direction, linePositionMode)
	local fontMetrics = self:Style(firstLine):FontMetrics();
	return fontMetrics:ascent(baselineType) + math.floor((self:LineHeight(firstLine, direction, linePositionMode) - fontMetrics:height()) / 2 + 0.5);
	-- 
end

function LayoutInline:UpdateBoxModelInfoFromStyle()
	LayoutInline._super.UpdateBoxModelInfoFromStyle(self);

    self:SetInline(true); -- Needed for run-ins, since run-in is considered a block display type.

    -- FIXME: Support transforms and reflections on inline flows someday.
    self:SetHasTransform(false);
    self:SetHasReflection(false);  
end

function LayoutInline:AlwaysCreateLineBoxes()
	return self.alwaysCreateLineBoxes;
end

function LayoutInline:SetAlwaysCreateLineBoxes()
	self.alwaysCreateLineBoxes = true;
end

function LayoutInline:CreateInlineFlowBox() 
    return InlineFlowBox:new():init(self);
end

function LayoutInline:CreateAndAppendInlineFlowBox()
	echo("LayoutInline:CreateAndAppendInlineFlowBox()");
    self:SetAlwaysCreateLineBoxes();
    local flowBox = self:CreateInlineFlowBox();
    self.lineBoxes:AppendLineBox(flowBox);
    return flowBox;
end

function LayoutInline:RequiresLayer()
	return self:IsRelPositioned() or self:IsTransparent() or self:HasMask();
end

--static LayoutUnit computeMargin(const RenderInline* renderer, const Length& margin)
local function computeMargin(renderer, margin)
    if (margin:IsAuto()) then
        return 0;
	end
    if (margin:IsFixed()) then
        return margin:Value();
	end
    if (margin:IsPercent()) then
        return margin:CalcMinValue(math.max(0, renderer:ContainingBlock():AvailableLogicalWidth():Value()));
	end
    return 0;
end

function LayoutInline:MarginLeft()
	return computeMargin(self, self:Style():MarginLeft());
end

function LayoutInline:MarginRight()
	return computeMargin(self, self:Style():MarginRight());
end

function LayoutInline:MarginTop()
	return computeMargin(self, self:Style():MarginTop());
end

function LayoutInline:MarginBottom()
	return computeMargin(self, self:Style():MarginBottom());
end

function LayoutInline:MarginBefore()
	return computeMargin(self, self:Style():MarginBefore());
end

function LayoutInline:MarginAfter()
	return computeMargin(self, self:Style():MarginAfter());
end

function LayoutInline:MarginStart()
	return computeMargin(self, self:Style():MarginStart());
end

function LayoutInline:MarginEnd()
	return computeMargin(self, self:Style():MarginEnd());
end

--void RenderInline::addChild(RenderObject* newChild, RenderObject* beforeChild)
function LayoutInline:AddChild(newChild, beforeChild)
    if (self:Continuation()) then
        return self:AddChildToContinuation(newChild, beforeChild);
	end
    return self:AddChildIgnoringContinuation(newChild, beforeChild);
end

local function nextContinuation(renderer)
    if (renderer:IsInline() and not renderer:IsReplaced()) then
        return renderer:Continuation();
	end
    return renderer:InlineElementContinuation();
end

--RenderBoxModelObject* RenderInline::continuationBefore(RenderObject* beforeChild)
function LayoutInline:ContinuationBefore(beforeChild)
    if (beforeChild and beforeChild:Parent() == self) then
        return self;
	end

    local curr = nextContinuation(self);
    local nextToLast = self;
    local last = self;
    while (curr) do
        if (beforeChild and beforeChild:Parent() == curr) then
            if (curr:FirstChild() == beforeChild) then
                return last;
			end
            return curr;
        end

        nextToLast = last;
        last = curr;
        curr = nextContinuation(curr);
    end

    if (beforeChild == nil and last:FirstChild() == nil) then
        return nextToLast;
	end
    return last;
end

--void RenderInline::addChildToContinuation(RenderObject* newChild, RenderObject* beforeChild)
function LayoutInline:AddChildToContinuation(newChild, beforeChild)
    local flow = self:ContinuationBefore(beforeChild);
    --ASSERT(!beforeChild || beforeChild->parent()->isRenderBlock() || beforeChild->parent()->isRenderInline());
    local beforeChildParent;
    if (beforeChild) then
        beforeChildParent = beforeChild:Parent();
    else
        local cont = nextContinuation(flow);
        if (cont) then
            beforeChildParent = cont;
        else
            beforeChildParent = flow;
		end
    end

    if (newChild:IsFloatingOrPositioned()) then
        return beforeChildParent:AddChildIgnoringContinuation(newChild, beforeChild);
	end

    -- A continuation always consists of two potential candidates: an inline or an anonymous
    -- block box holding block children.
    local childInline = newChild:IsInline();
    local bcpInline = beforeChildParent:IsInline();
    local flowInline = flow:IsInline();

    if (flow == beforeChildParent) then
        return flow:AddChildIgnoringContinuation(newChild, beforeChild);
    else
        -- The goal here is to match up if we can, so that we can coalesce and create the
        -- minimal # of continuations needed for the inline.
        if (childInline == bcpInline) then
            return beforeChildParent:AddChildIgnoringContinuation(newChild, beforeChild);
        elseif (flowInline == childInline) then
            return flow:AddChildIgnoringContinuation(newChild, 0); -- Just treat like an append.
        else
            return beforeChildParent:AddChildIgnoringContinuation(newChild, beforeChild);
		end
    end
end

--void RenderInline::addChildIgnoringContinuation(RenderObject* newChild, RenderObject* beforeChild)
function LayoutInline:AddChildIgnoringContinuation(newChild, beforeChild)
    -- Make sure we don't append things after :after-generated content if we have it.
    if (beforeChild == nil and self:IsAfterContent(self:LastChild(), false)) then
        beforeChild = self:LastChild();
	end

    if (not newChild:IsInline() and not newChild:IsFloatingOrPositioned()) then
        -- We are placing a block inside an inline. We have to perform a split of this
        -- inline into continuations.  This involves creating an anonymous block box to hold
        -- |newChild|.  We then make that block box a continuation of this inline.  We take all of
        -- the children after |beforeChild| and put them in a clone of this object.
--        RefPtr<RenderStyle> newStyle = RenderStyle::createAnonymousStyle(style());
--        newStyle->setDisplay(BLOCK);
--
--        RenderBlock* newBox = new (renderArena()) RenderBlock(document() /* anonymous box */);
--        newBox->setStyle(newStyle.release());
--        RenderBoxModelObject* oldContinuation = continuation();
--        setContinuation(newBox);
--
--        // Someone may have put a <p> inside a <q>, causing a split.  When this happens, the :after content
--        // has to move into the inline continuation.  Call updateBeforeAfterContent to ensure that our :after
--        // content gets properly destroyed.
--        bool isLastChild = (beforeChild == lastChild());
--        if (document()->usesBeforeAfterRules())
--            children()->updateBeforeAfterContent(this, AFTER);
--        if (isLastChild && beforeChild != lastChild())
--            beforeChild = 0; // We destroyed the last child, so now we need to update our insertion
--                             // point to be 0.  It's just a straight append now.
--
--        splitFlow(beforeChild, newBox, newChild, oldContinuation);
--        return;
    end

    LayoutInline._super.AddChild(self, newChild, beforeChild);

    newChild:SetNeedsLayoutAndPrefWidthsRecalc();
end

function LayoutInline:VirtualChildren()
	return self:Children();
end

function LayoutInline:Paint(paintInfo, paintOffset)
	self.lineBoxes:Paint(self, paintInfo, paintOffset);
end

function LayoutInline:Children()
	return self.children;
end

function LayoutInline:VirtualContinuation()
	return self:Continuation();
end

--LayoutRect RenderInline::linesBoundingBox() const
function LayoutInline:LinesBoundingBox()
--    if (not self:AlwaysCreateLineBoxes()) then
--        --ASSERT(!firstLineBox());
--        return self:EnclosingLayoutRect(culledInlineBoundingBox(this));
--    end
--
--    LayoutRect result;
--    
--    // See <rdar://problem/5289721>, for an unknown reason the linked list here is sometimes inconsistent, first is non-zero and last is zero.  We have been
--    // unable to reproduce this at all (and consequently unable to figure ot why this is happening).  The assert will hopefully catch the problem in debug
--    // builds and help us someday figure out why.  We also put in a redundant check of lastLineBox() to avoid the crash for now.
--    ASSERT(!firstLineBox() == !lastLineBox());  // Either both are null or both exist.
--    if (firstLineBox() && lastLineBox()) {
--        // Return the width of the minimal left side and the maximal right side.
--        float logicalLeftSide = 0;
--        float logicalRightSide = 0;
--        for (InlineFlowBox* curr = firstLineBox(); curr; curr = curr->nextLineBox()) {
--            if (curr == firstLineBox() || curr->logicalLeft() < logicalLeftSide)
--                logicalLeftSide = curr->logicalLeft();
--            if (curr == firstLineBox() || curr->logicalRight() > logicalRightSide)
--                logicalRightSide = curr->logicalRight();
--        }
--        
--        bool isHorizontal = style()->isHorizontalWritingMode();
--        
--        float x = isHorizontal ? logicalLeftSide : firstLineBox()->x();
--        float y = isHorizontal ? firstLineBox()->y() : logicalLeftSide;
--        float width = isHorizontal ? logicalRightSide - logicalLeftSide : lastLineBox()->logicalBottom() - x;
--        float height = isHorizontal ? lastLineBox()->logicalBottom() - y : logicalRightSide - logicalLeftSide;
--        result = enclosingLayoutRect(FloatRect(x, y, width, height));
--    }
--
--    return result;
end

function LayoutInline:CulledInlineFirstLineBox()
	local curr = self:FirstChild();
	while(curr) do
		if (curr:IsFloatingOrPositioned()) then
            --continue;
		else
			-- We want to get the margin box in the inline direction, and then use our font ascent/descent in the block
			-- direction (aligned to the root box's baseline).
			if (curr:IsBox()) then
				return curr:ToRenderBox():InlineBoxWrapper();
			end
			if (curr:IsLayoutInline()) then
				local currInline = curr:ToRenderInline();
				local result = currInline:FirstLineBoxIncludingCulling();
				if (result) then
					return result;
				end
			elseif (curr:IsText()) then
				local currText = curr:ToRenderText();
				if (currText:FirstTextBox()) then
					return currText:FirstTextBox();
				end
			end
		end
	
		curr = curr:NextSibling();
	end
    return;
end

function LayoutInline:CulledInlineLastLineBox()
	local curr = self:LastChild();
	while(curr) do
		if (curr:IsFloatingOrPositioned()) then
            --continue;
        else
			-- We want to get the margin box in the inline direction, and then use our font ascent/descent in the block
			-- direction (aligned to the root box's baseline).
			if (curr:IsBox()) then
				return curr:ToRenderBox():InlineBoxWrapper();
			end
			if (curr:IsLayoutInline()) then
				local currInline = curr:ToRenderInline();
				local result = currInline:LastLineBoxIncludingCulling();
				if (result) then
					return result;
				end
			elseif (curr:IsText()) then
				local currText = curr:ToRenderText();
				if (currText:LastTextBox()) then
					return currText:LastTextBox();
				end
			end
		end
	
		curr = curr:PreviousSibling();
	end
    return;
end

function LayoutInline:FirstLineBoxIncludingCulling()
	if(self:AlwaysCreateLineBoxes()) then
		return self:FirstLineBox();
	end
	return self:CulledInlineFirstLineBox();
end

function LayoutInline:LastLineBoxIncludingCulling()
	if(self:AlwaysCreateLineBoxes()) then
		return self:LastLineBox();
	end
	return self:CulledInlineLastLineBox();
end

--LayoutRect RenderInline::clippedOverflowRectForRepaint(RenderBoxModelObject* repaintContainer) const
function LayoutInline:ClippedOverflowRectForRepaint(repaintContainer)
    -- Only run-ins are allowed in here during layout.
    -- ASSERT(!view() or not view()->layoutStateEnabled() or isRunIn());

    if (not self:FirstLineBoxIncludingCulling() and not self:Continuation()) then
        return LayoutRect:new();
	end

--    -- Find our leftmost position.
--    local boundingBox = self:LinesVisualOverflowBoundingBox():clone();
--    local left = boundingBox:X();
--    local top = boundingBox:Y();
--
--    -- Now invalidate a rectangle.
--	local ow = 0;
--	if(self:Style()) then
--		ow = self:Style():OutlineSize();
--	end
--    
--    -- We need to add in the relative position offsets of any inlines (including us) up to our
--    -- containing block.
--    local cb = self:ContainingBlock();
--	local inlineFlow = self;
--	while(inlineFlow and inlineFlow:IsLayoutInline() and inlineFlow ~= cb) do
--		if (inlineFlow:Style():Position() == RelativePosition and inlineFlow:HasLayer()) then
--            inlineFlow:ToRenderInline():Layer():RelativePositionOffset(left, top);
--		end
--		
--		inlineFlow = inlineFlow:Parent();
--	end
--	
--	local r = LayoutRect:new(-ow + left, -ow + top, boundingBox.width() + ow * 2, boundingBox.height() + ow * 2);
--
--    if (cb:HasColumns()) then
--        --cb->adjustRectForColumns(r);
--	end
--
--    if (cb:HasOverflowClip()) then
--        -- cb->height() is inaccurate if we're in the middle of a layout of |cb|, so use the
--        -- layer's size instead.  Even if the layer's size is wrong, the layer itself will repaint
--        -- anyway if its size does change.
--        local repaintRect = r:clone();
--        repaintRect:Move(-cb:Layer():ScrolledContentOffset()); -- For overflow:auto/scroll/hidden.
--
--        local boxRect = LayoutRect:new(LayoutPoint:new(), cb:Layer():Size());
--        r = LayoutRect.Intersection(repaintRect, boxRect);
--    end
--    
--    -- FIXME: need to ensure that we compute the correct repaint rect when the repaint container
--    -- is an inline.
--    if (repaintContainer ~= self) then
--        cb:ComputeRectForRepaint(repaintContainer, r);
--	end
--
--    if (ow) then
--		local curr = self:FirstChild();
--		while(curr) do
--			if (not curr:IsText()) then
--                local childRect = curr:RectWithOutlineForRepaint(repaintContainer, ow):clone();
--                r:Unite(childRect);
--            end
--		
--			curr = curr:NextSibling();
--		end
--
--        if (self:Continuation() and not self:Continuation():IsInline()) then
--            --LayoutRect contRect = continuation()->rectWithOutlineForRepaint(repaintContainer, ow);
--            r:Unite(contRect);
--        end
--    end
--
--    return r;
end

--LayoutRect RenderInline::linesVisualOverflowBoundingBox() const
function LayoutInline:LinesVisualOverflowBoundingBox()
--    if (not self:AlwaysCreateLineBoxes()) then
--        return culledInlineVisualOverflowBoundingBox();
--	end
--
--    if (!firstLineBox() || !lastLineBox())
--        return LayoutRect();
--
--    // Return the width of the minimal left side and the maximal right side.
--    LayoutUnit logicalLeftSide = numeric_limits<LayoutUnit>::max();
--    LayoutUnit logicalRightSide = numeric_limits<LayoutUnit>::min();
--    for (InlineFlowBox* curr = firstLineBox(); curr; curr = curr->nextLineBox()) {
--        logicalLeftSide = min(logicalLeftSide, curr->logicalLeftVisualOverflow());
--        logicalRightSide = max(logicalRightSide, curr->logicalRightVisualOverflow());
--    }
--
--    RootInlineBox* firstRootBox = firstLineBox()->root();
--    RootInlineBox* lastRootBox = lastLineBox()->root();
--    
--    LayoutUnit logicalTop = firstLineBox()->logicalTopVisualOverflow(firstRootBox->lineTop());
--    LayoutUnit logicalWidth = logicalRightSide - logicalLeftSide;
--    LayoutUnit logicalHeight = lastLineBox()->logicalBottomVisualOverflow(lastRootBox->lineBottom()) - logicalTop;
--    
--    LayoutRect rect(logicalLeftSide, logicalTop, logicalWidth, logicalHeight);
--    if (!style()->isHorizontalWritingMode())
--        rect = rect.transposedRect();
--    return rect;
end

--virtual LayoutRect borderBoundingBox() const
function LayoutInline:BorderBoundingBox()
    local boundingBox = self:LinesBoundingBox();
    return LayoutRect:new(0, 0, boundingBox:Width(), boundingBox:Height());
end

--LayoutSize RenderInline::relativePositionedInlineOffset(const RenderBox* child) const
function LayoutInline:RelativePositionedInlineOffset(child)
    -- FIXME: This function isn't right with mixed writing modes.

    -- ASSERT(isRelPositioned());
    if (not self:IsRelPositioned()) then
        return LayoutSize:new();
	end

    -- When we have an enclosing relpositioned inline, we need to add in the offset of the first line
    -- box from the rest of the content, but only in the cases where we know we're positioned
    -- relative to the inline itself.

    local logicalOffset = LayoutSize:new();
    local inlinePosition, blockPosition;
    if (self:FirstLineBox()) then
        inlinePosition = math.floor(self:FirstLineBox():LogicalLeft() + 0.5);
        blockPosition = self:FirstLineBox():LogicalTop();
    else
        inlinePosition = self:Layer():StaticInlinePosition();
        blockPosition = self:Layer():StaticBlockPosition();
    end

    if (not child:Style():HasStaticInlinePosition(self:Style():IsHorizontalWritingMode())) then
        logicalOffset:SetWidth(inlinePosition);

    -- This is not terribly intuitive, but we have to match other browsers.  Despite being a block display type inside
    -- an inline, we still keep our x locked to the left of the relative positioned inline.  Arguably the correct
    -- behavior would be to go flush left to the block that contains the inline, but that isn't what other browsers
    -- do.
    elseif (not child:Style():IsOriginalDisplayInlineType()) then
        -- Avoid adding in the left border/padding of the containing block twice.  Subtract it out.
        logicalOffset:SetWidth(inlinePosition - child:ContainingBlock():BorderAndPaddingLogicalLeft());
	end
    if (not child:Style():HasStaticBlockPosition(self:Style():IsHorizontalWritingMode())) then
        logicalOffset:SetHeight(blockPosition);
	end
	if(self:Style():IsHorizontalWritingMode()) then
		return logicalOffset;
	end
    return logicalOffset:TransposedSize();
end