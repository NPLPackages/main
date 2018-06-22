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
NPL.load("(gl)script/ide/System/Windows/mcml/layout/InLineFlowBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local Length = commonlib.gettable("System.Windows.mcml.platform.Length");
local InLineFlowBox = commonlib.gettable("System.Windows.mcml.layout.InLineFlowBox");
local LayoutLineBoxList = commonlib.gettable("System.Windows.mcml.layout.LayoutLineBoxList");
local LayoutObjectChildList = commonlib.gettable("System.Windows.mcml.layout.LayoutObjectChildList");
local LayoutInline = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBoxModelObject"), commonlib.gettable("System.Windows.mcml.layout.LayoutInline"));

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

function LayoutInline:IsLayoutInline()
	return true;
end

function LayoutInline:DirtyLinesFromChangedChild(child)
	--TODO: fixed this function
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
    --bool checkFonts = document()->inNoQuirksMode();
	local checkFonts = false;
    local alwaysCreateLineBoxes = (parentRenderInline ~= nil and parentRenderInline:AlwaysCreateLineBoxes())
        or (parentRenderInline ~= nil and parentStyle:VerticalAlign() ~= VerticalAlignEnum.BASELINE)
        or self:Style():VerticalAlign() ~= VerticalAlignEnum.BASELINE
        or self:Style():TextEmphasisMark() ~= TextEmphasisMarkEnum.TextEmphasisMarkNone
        -- or (checkFonts and (not parentStyle->font().fontMetrics().hasIdenticalAscentDescentAndLineGap(style()->font().fontMetrics())
		or (checkFonts and parentStyle:LineHeight() ~= self:Style():LineHeight());
	-- document()->usesFirstLineRules() default value is false;
--    if (!alwaysCreateLineBoxes && checkFonts && document()->usesFirstLineRules()) {
--        // Have to check the first line style as well.
--        parentStyle = parent()->style(true);
--        RenderStyle* childStyle = style(true);
--        alwaysCreateLineBoxes = !parentStyle->font().fontMetrics().hasIdenticalAscentDescentAndLineGap(childStyle->font().fontMetrics())
--        || childStyle->verticalAlign() != BASELINE
--        || parentStyle->lineHeight() != childStyle->lineHeight();
--    }

    if (alwaysCreateLineBoxes) then
        if (not fullLayout) then
            self:DirtyLineBoxes(false);
		end
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
--        for (RenderObject* curr = firstChild(); curr; curr = curr->nextSibling()) {
--            if (curr->isFloatingOrPositioned())
--                continue;
--            if (curr->isBox() && !curr->needsLayout()) {
--                RenderBox* currBox = toRenderBox(curr);
--                if (currBox->inlineBoxWrapper())
--                    currBox->inlineBoxWrapper()->root()->markDirty();
--            } else if (!curr->selfNeedsLayout()) {
--                if (curr->isRenderInline()) {
--                    RenderInline* currInline = toRenderInline(curr);
--                    for (InlineFlowBox* childLine = currInline->firstLineBox(); childLine; childLine = childLine->nextLineBox())
--                        childLine->root()->markDirty();
--                } else if (curr->isText()) {
--                    RenderText* currText = toRenderText(curr);
--                    for (InlineTextBox* childText = currText->firstTextBox(); childText; childText = childText->nextTextBox())
--                        childText->root()->markDirty();
--                }
--            }
--        }
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

function LayoutInline:StyleDidChange(diff, oldStyle)
	LayoutInline._super.StyleDidChange(self, diff, oldStyle);
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

function LayoutInline:Children()
	return self.children;
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