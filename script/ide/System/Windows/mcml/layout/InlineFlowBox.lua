--[[
Title: 
Author(s): LiPeng
Date: 2018/3/12
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/InlineFlowBox.lua");
local InlineFlowBox = commonlib.gettable("System.Windows.mcml.layout.InlineFlowBox");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/InlineBox.lua");
NPL.load("(gl)script/ide/System/Core/UniString.lua");
local UniString = commonlib.gettable("System.Core.UniString");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");

local InlineFlowBox = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.InlineBox"), commonlib.gettable("System.Windows.mcml.layout.InlineFlowBox"));

function InlineFlowBox:ctor()
	self.overflow = nil;
    self.firstChild = nil;
    self.lastChild = nil;
    
    self.prevLineBox = nil; -- The previous box that also uses our RenderObject
    self.nextLineBox = nil; -- The next box that also uses our RenderObject

    self.includeLogicalLeftEdge = false;
    self.includeLogicalRightEdge = false;
    self.hasTextChildren = nil;
    self.hasTextDescendants = nil;
    self.descendantsHaveSameLineHeightAndBaseline = true;

    -- The following members are only used by RootInlineBox but moved here to keep the bits packed.

    -- Whether or not this line uses alphabetic or ideographic baselines by default.
    self.baselineType = "AlphabeticBaseline"; -- FontBaseline

    -- If the line contains any ruby runs, then this will be true.
    self.hasAnnotationsBefore = false;
    self.hasAnnotationsAfter = false;

    self.lineBreakBidiStatusEor = nil; -- WTF::Unicode::Direction
    self.lineBreakBidiStatusLastStrong = nil; -- WTF::Unicode::Direction
    self.lineBreakBidiStatusLast = nil; -- WTF::Unicode::Direction

    -- End of RootInlineBox-specific members.

    self.hasBadChildList = false;
end

function InlineFlowBox:init(obj)
	InlineFlowBox._super.init(self, obj);
	self.hasTextChildren = obj:Style():Display() == "LIST_ITEM";
    self.hasTextDescendants = self.hasTextChildren;

	return self;
end

function InlineFlowBox:BoxName()
	return "InlineFlowBox"; 
end

function InlineFlowBox:IsInlineFlowBox()
	return true;
end

function InlineFlowBox:PrevLineBox()
	return self.prevLineBox;
end

function InlineFlowBox:NextLineBox()
	return self.nextLineBox;
end

function InlineFlowBox:SetNextLineBox(next)
	self.nextLineBox = next;
end

function InlineFlowBox:SetPreviousLineBox(prev)
	self.prevLineBox = prev;
end

function InlineFlowBox:FirstChild()
	self:CheckConsistency(); 
	return self.firstChild;
end

function InlineFlowBox:LastChild()
	self:CheckConsistency(); 
	return self.lastChild;
end

function InlineFlowBox:IsLeaf()
	return false;
end

    
function InlineFlowBox:FirstLeafChild()

end

function InlineFlowBox:LastLeafChild()

end

function InlineFlowBox:CheckConsistency()
	
end

function InlineFlowBox:RemoveChild(child)
	--TODO: fixed this function
end

function InlineFlowBox:AddToLine(child) 
	--TODO: fixed this function
--	ASSERT(!child->parent());
--    ASSERT(!child->nextOnLine());
--    ASSERT(!child->prevOnLine());
    self:CheckConsistency();

	child:SetParent(self);
    if (self.firstChild == nil) then
        self.firstChild = child;
        self.lastChild = child;
    else
        self.lastChild:SetNextOnLine(child);
        child:SetPrevOnLine(self.lastChild);
        self.lastChild = child;
    end
    child:SetFirstLineStyleBit(self.firstLine);
    child:SetIsHorizontal(self:IsHorizontal());

	if (child:IsText()) then
        if (child:Renderer():Parent() == self:Renderer()) then
            self.hasTextChildren = true;
		end
        self.hasTextDescendants = true;
    elseif (child:IsInlineFlowBox()) then
        if (child:HasTextDescendants()) then
            self.hasTextDescendants = true;
		end
    end

	if (self:DescendantsHaveSameLineHeightAndBaseline() and not child:Renderer():IsPositioned()) then
        local parentStyle = self:Renderer():Style(self.firstLine);
        local childStyle = child:Renderer():Style(self.firstLine);
        local shouldClearDescendantsHaveSameLineHeightAndBaseline = false;
        if (child:Renderer():IsReplaced()) then
            shouldClearDescendantsHaveSameLineHeightAndBaseline = true;
        elseif (child:IsText()) then
            if (child:Renderer():IsBR() or child:Renderer():Parent() ~= self:Renderer()) then
--                if (!parentStyle->font().fontMetrics().hasIdenticalAscentDescentAndLineGap(childStyle->font().fontMetrics())
--                    || parentStyle->lineHeight() != childStyle->lineHeight()
--                    || (parentStyle->verticalAlign() != BASELINE && !isRootInlineBox()) || childStyle->verticalAlign() != BASELINE)
--                    shouldClearDescendantsHaveSameLineHeightAndBaseline = true;
            end
            if (childStyle:HasTextCombine() or childStyle:TextEmphasisMark() ~= "TextEmphasisMarkNone") then
                shouldClearDescendantsHaveSameLineHeightAndBaseline = true;
			end
        else
--            if (child->renderer()->isBR()) {
--                // FIXME: This is dumb. We only turn off because current layout test results expect the <br> to be 0-height on the baseline.
--                // Other than making a zillion tests have to regenerate results, there's no reason to ditch the optimization here.
--                shouldClearDescendantsHaveSameLineHeightAndBaseline = true;
--            } else {
--                ASSERT(isInlineFlowBox());
--                InlineFlowBox* childFlowBox = toInlineFlowBox(child);
--                // Check the child's bit, and then also check for differences in font, line-height, vertical-align
--                if (!childFlowBox->descendantsHaveSameLineHeightAndBaseline()
--                    || !parentStyle->font().fontMetrics().hasIdenticalAscentDescentAndLineGap(childStyle->font().fontMetrics())
--                    || parentStyle->lineHeight() != childStyle->lineHeight()
--                    || (parentStyle->verticalAlign() != BASELINE && !isRootInlineBox()) || childStyle->verticalAlign() != BASELINE
--                    || childStyle->hasBorder() || childStyle->hasPadding() || childStyle->hasTextCombine())
--                    shouldClearDescendantsHaveSameLineHeightAndBaseline = true;
--            }
        end

        if (shouldClearDescendantsHaveSameLineHeightAndBaseline) then
            self:ClearDescendantsHaveSameLineHeightAndBaseline();
		end
    end

	if (not child:Renderer():IsPositioned()) then
        if (child:IsText()) then
            local childStyle = child:Renderer():Style(self.firstLine);
--            if (childStyle->letterSpacing() < 0 || childStyle->textShadow() || childStyle->textEmphasisMark() != TextEmphasisMarkNone || childStyle->textStrokeWidth())
--                child->clearKnownToHaveNoOverflow();
        elseif (child:Renderer():IsReplaced()) then
--            RenderBox* box = toRenderBox(child->renderer());
--            if (box->hasRenderOverflow() || box->hasSelfPaintingLayer())
--                child->clearKnownToHaveNoOverflow();
--        elseif (!child->renderer()->isBR() && (child->renderer()->style(m_firstLine)->boxShadow() || child->boxModelObject()->hasSelfPaintingLayer()
--                   || (child->renderer()->isListMarker() && !toRenderListMarker(child->renderer())->isInside())
--                   || child->renderer()->style(m_firstLine)->hasBorderImageOutsets()))
--            child->clearKnownToHaveNoOverflow();
		end
        
        if (self:KnownToHaveNoOverflow() and child:IsInlineFlowBox() and not child:KnownToHaveNoOverflow()) then
            self:ClearKnownToHaveNoOverflow();
		end
    end

    self:CheckConsistency();
end

function InlineFlowBox:RemoveLineBoxFromRenderObject()
    --toRenderInline(renderer())->lineBoxes()->removeLineBox(this);
	self:Renderer():LineBoxes():RemoveLineBox(self);
end

function InlineFlowBox:DeleteLine(arena)
    local child = self:FirstChild();
    local next = nil;
    while (child) do
        --ASSERT(this == child->parent());
        next = child:NextOnLine();
        child:SetParent(0);
        child:DeleteLine(arena);
        child = next;
    end
    self.firstChild = nil;
    self.lastChild = nil;

    self:RemoveLineBoxFromRenderObject();
    self:Destroy(arena);
end

function InlineFlowBox:RendererLineBoxes()
    --return toRenderInline(renderer())->lineBoxes();
	return self:Renderer():LineBoxes();
end

local function isAnsectorAndWithinBlock(ancestor, child)
	object = child;
    while (object and (not object:IsLayoutBlock() or object:IsInline())) do
        if (object == ancestor) then
            return true;
		end
        object = object:Parent();
    end
    return false;
end

local function isLastChildForRenderer(ancestor, child)
    if (not child) then
        return false;
	end
    
    if (child == ancestor) then
        return true;
	end

    local curr = child;
    local parent = curr:Parent();
    while (parent and (not parent:IsLayoutBlock() or parent:IsInline())) do
        if (parent:LastChild() ~= curr) then
            return false;
		end
        if (parent == ancestor) then
            return true;
        end
        curr = parent;
        parent = curr:Parent();
    end

    return true;
end

--void InlineFlowBox::determineSpacingForFlowBoxes(bool lastLine, bool isLogicallyLastRunWrapped, RenderObject* logicallyLastRunRenderer)
function InlineFlowBox:DetermineSpacingForFlowBoxes(lastLine, isLogicallyLastRunWrapped, logicallyLastRunRenderer)
	-- TODO: add function later;
	-- All boxes start off open.  They will not apply any margins/border/padding on any side.
    local includeLeftEdge = false;
    local includeRightEdge = false;

	-- The root inline box never has borders/margins/padding.
    if (self:Parent()) then
        local ltr = self:Renderer():Style():IsLeftToRightDirection();

        -- Check to see if all initial lines are unconstructed.  If so, then
        -- we know the inline began on this line (unless we are a continuation).
        local lineBoxList = self:RendererLineBoxes();
        if (not lineBoxList:FirstLineBox():IsConstructed() and not self:Renderer():IsInlineElementContinuation()) then
            if (ltr and lineBoxList:FirstLineBox() == self) then
                includeLeftEdge = true;
            elseif (not ltr and lineBoxList:LastLineBox() == self) then
                includeRightEdge = true;
			end
        end

        if (not lineBoxList:LastLineBox():IsConstructed()) then
            --local inlineFlow = toRenderInline(renderer());
			local inlineFlow = self:Renderer();
            local isLastObjectOnLine = not isAnsectorAndWithinBlock(self:Renderer(), logicallyLastRunRenderer) or (isLastChildForRenderer(self:Renderer(), logicallyLastRunRenderer) and not isLogicallyLastRunWrapped);

            -- We include the border under these conditions:
            -- (1) The next line was not created, or it is constructed. We check the previous line for rtl.
            -- (2) The logicallyLastRun is not a descendant of this renderer.
            -- (3) The logicallyLastRun is a descendant of this renderer, but it is the last child of this renderer and it does not wrap to the next line.
            
            if (ltr) then
                if (self:NextLineBox() == nil and ((lastLine ~= nil or isLastObjectOnLine) and inlineFlow:Continuation() == nil)) then
                    includeRightEdge = true;
				end
            else
                if ((self:PrevLineBox() == nil or self:PrevLineBox():IsConstructed()) and ((lastLine ~= nil or isLastObjectOnLine) and inlineFlow:Continuation() == nil)) then
                    includeLeftEdge = true;
				end
            end
        end
    end

	self:SetEdges(includeLeftEdge, includeRightEdge);

	-- Recur into our children.
	local currChild = self:FirstChild();
	while(currChild) do
		if (currChild:IsInlineFlowBox()) then
            local currFlow = currChild;
            currFlow:DetermineSpacingForFlowBoxes(lastLine, isLogicallyLastRunWrapped, logicallyLastRunRenderer);
        end
		currChild = currChild:NextOnLine();
	end
end

-- logicalLeft = left in a horizontal line and top in a vertical line.
function InlineFlowBox:MarginBorderPaddingLogicalLeft()
	return self:MarginLogicalLeft() + self:BorderLogicalLeft() + self:PaddingLogicalLeft();
end

function InlineFlowBox:MarginBorderPaddingLogicalRight()
	return self:MarginLogicalRight() + self:BorderLogicalRight() + self:PaddingLogicalRight();
end

function InlineFlowBox:MarginLogicalLeft()
	if (not self:IncludeLogicalLeftEdge()) then
		return 0;
	end
	return if_else(self:IsHorizontal(), self:BoxModelObject():MarginLeft(), self:BoxModelObject():MarginTop());
end

function InlineFlowBox:MarginLogicalRight()
	if (not self:IncludeLogicalRightEdge()) then
		return 0;
	end
	return if_else(self:IsHorizontal(), self:BoxModelObject():MarginRight(), self:BoxModelObject():MarginBottom());
end

function InlineFlowBox:BorderLogicalLeft()
	if (not self:IncludeLogicalLeftEdge()) then
		return 0;
	end
	return if_else(self:IsHorizontal(), self:Renderer():Style():BorderLeftWidth(), self:Renderer():Style():BorderTopWidth());
end

function InlineFlowBox:BorderLogicalRight()
	if (not self:IncludeLogicalRightEdge()) then
		return 0;
	end
	return if_else(self:IsHorizontal(), self:Renderer():Style():BorderRightWidth(), self:Renderer():Style():BorderBottomWidth());
end

function InlineFlowBox:PaddingLogicalLeft()
	if (not self:IncludeLogicalLeftEdge()) then
		return 0;
	end
	return if_else(self:IsHorizontal(), self:BoxModelObject():PaddingLeft(), self:BoxModelObject():PaddingTop());
end

function InlineFlowBox:PaddingLogicalRight()
	if (not self:IncludeLogicalRightEdge()) then
		return 0;
	end
	return if_else(self:IsHorizontal(), self:BoxModelObject():PaddingRight(), self:BoxModelObject():PaddingBottom());
end


function InlineFlowBox:GetFlowSpacingLogicalWidth()
    local totWidth = self:MarginBorderPaddingLogicalLeft() + self:MarginBorderPaddingLogicalRight();
	local curr = self:FirstChild();
	while(curr) do
		if (curr:IsInlineFlowBox()) then
            totWidth = totWidth + curr:GetFlowSpacingLogicalWidth();
		end
		curr = curr:NextOnLine();
	end

    return totWidth;
end

function InlineFlowBox:IncludeLogicalLeftEdge()
	return self.includeLogicalLeftEdge;
end

function InlineFlowBox:IncludeLogicalRightEdge()
	return self.includeLogicalRightEdge;
end
-- @param includeLeft: bool
-- @param includeRight: bool
function InlineFlowBox:SetEdges(includeLeft, includeRight)
    self.includeLogicalLeftEdge = includeLeft;
    self.includeLogicalRightEdge = includeRight;
end

--float InlineFlowBox::placeBoxesInInlineDirection(float logicalLeft, bool& needsWordSpacing, GlyphOverflowAndFallbackFontsMap& textBoxDataMap)
function InlineFlowBox:PlaceBoxesInInlineDirection(logicalLeft, needsWordSpacing, textBoxDataMap)
	-- Set our x position.
    self:SetLogicalLeft(logicalLeft);
  
    local startLogicalLeft = logicalLeft;
    logicalLeft = logicalLeft + self:BorderLogicalLeft() + self:PaddingLogicalLeft();

    local minLogicalLeft = startLogicalLeft;
    local maxLogicalRight = logicalLeft;

	local curr = self:FirstChild();
	while(curr) do
		if (curr:Renderer():IsText()) then
            local text = curr;
            local rt = text:Renderer();
            if (rt:TextLength()) then
                if (needsWordSpacing and UniString.IsSpaceOrNewline(rt:Characters()[text:Start()])) then
                    logicalLeft = logicalLeft + rt:Style(self.firstLine):WordSpacing();
				end
                needsWordSpacing = not UniString.IsSpaceOrNewline(rt:Characters()[text:End()]);
            end
            text:SetLogicalLeft(logicalLeft);
            if (self:KnownToHaveNoOverflow()) then
                minLogicalLeft = math.min(logicalLeft, minLogicalLeft);
			end
            logicalLeft = logicalLeft + text:LogicalWidth();
            if (self:KnownToHaveNoOverflow()) then
                maxLogicalRight = math.max(logicalLeft, maxLogicalRight);
			end
        else
			local continue = false;
			if (curr:Renderer():IsPositioned()) then
                if (curr:Renderer():Parent():Style():IsLeftToRightDirection()) then
                    curr:SetLogicalLeft(logicalLeft);
                else
                    -- Our offset that we cache needs to be from the edge of the right border box and
                    -- not the left border box.  We have to subtract |x| from the width of the block
                    -- (which can be obtained from the root line box).
                    curr:SetLogicalLeft(self:Root():Block():LogicalWidth() - logicalLeft);
				end
                continue = true; -- The positioned object has no effect on the width.
            end
			if(not continue) then
				if (curr:Renderer():IsRenderInline()) then
					local flow = curr;
					logicalLeft = logicalLeft + flow:MarginLogicalLeft();
					if (self:KnownToHaveNoOverflow()) then
						minLogicalLeft = math.min(logicalLeft, minLogicalLeft);
					end
					logicalLeft, needsWordSpacing = flow:PlaceBoxesInInlineDirection(logicalLeft, needsWordSpacing, textBoxDataMap);
					if (self:KnownToHaveNoOverflow()) then
						maxLogicalRight = math.max(logicalLeft, maxLogicalRight);
					end
					logicalLeft = logicalLeft + flow:MarginLogicalRight();
--				elseif (not curr:Renderer():IsListMarker() or toRenderListMarker(curr->renderer())->isInside()) {
--					// The box can have a different writing-mode than the overall line, so this is a bit complicated.
--					// Just get all the physical margin and overflow values by hand based off |isVertical|.
--					int logicalLeftMargin = isHorizontal() ? curr->boxModelObject()->marginLeft() : curr->boxModelObject()->marginTop();
--					int logicalRightMargin = isHorizontal() ? curr->boxModelObject()->marginRight() : curr->boxModelObject()->marginBottom();
--                
--					logicalLeft += logicalLeftMargin;
--					curr->setLogicalLeft(logicalLeft);
--					if (knownToHaveNoOverflow())
--						minLogicalLeft = min(logicalLeft, minLogicalLeft);
--					logicalLeft += curr->logicalWidth();
--					if (knownToHaveNoOverflow())
--						maxLogicalRight = max(logicalLeft, maxLogicalRight);
--					logicalLeft += logicalRightMargin;
				end
			end
		end

		curr = curr:NextOnLine();
	end

	logicalLeft = logicalLeft + self:BorderLogicalRight() + self:PaddingLogicalRight();
    self:SetLogicalWidth(logicalLeft - startLogicalLeft);
    if (self:KnownToHaveNoOverflow() and (minLogicalLeft < startLogicalLeft or maxLogicalRight > logicalLeft)) then
        self:ClearKnownToHaveNoOverflow();
	end
    return logicalLeft, needsWordSpacing;
end

function InlineFlowBox:DescendantsHaveSameLineHeightAndBaseline()
	return self.descendantsHaveSameLineHeightAndBaseline;
end

function InlineFlowBox:ClearDescendantsHaveSameLineHeightAndBaseline()
    self.descendantsHaveSameLineHeightAndBaseline = false;
    if (self:Parent() and self:Parent():DescendantsHaveSameLineHeightAndBaseline()) then
        self:Parent():ClearDescendantsHaveSameLineHeightAndBaseline();
	end
end

--bool InlineFlowBox::requiresIdeographicBaseline(const GlyphOverflowAndFallbackFontsMap& textBoxDataMap) const
function InlineFlowBox:RequiresIdeographicBaseline(textBoxDataMap)
	if (self:IsHorizontal()) then
        return false;
	end
	-- TODO: add later;

--	if (renderer()->style(m_firstLine)->fontDescription().textOrientation() == TextOrientationUpright
--        || renderer()->style(m_firstLine)->font().primaryFont()->hasVerticalGlyphs())
--        return true;
--
--    for (InlineBox* curr = firstChild(); curr; curr = curr->nextOnLine()) {
--        if (curr->renderer()->isPositioned())
--            continue; // Positioned placeholders don't affect calculations.
--        
--        if (curr->isInlineFlowBox()) {
--            if (toInlineFlowBox(curr)->requiresIdeographicBaseline(textBoxDataMap))
--                return true;
--        } else {
--            if (curr->renderer()->style(m_firstLine)->font().primaryFont()->hasVerticalGlyphs())
--                return true;
--            
--            const Vector<const SimpleFontData*>* usedFonts = 0;
--            if (curr->isInlineTextBox()) {
--                GlyphOverflowAndFallbackFontsMap::const_iterator it = textBoxDataMap.find(toInlineTextBox(curr));
--                usedFonts = it == textBoxDataMap.end() ? 0 : &it->second.first;
--            }
--
--            if (usedFonts) {
--                for (size_t i = 0; i < usedFonts->size(); ++i) {
--                    if (usedFonts->at(i)->hasVerticalGlyphs())
--                        return true;
--                }
--            }
--        }
--    }
	return false;
end

function InlineFlowBox:HasTextChildren()
	return self.hasTextChildren;
end

function InlineFlowBox:HasTextDescendants()
	return self.hasTextDescendants;
end

--void InlineFlowBox::computeLogicalBoxHeights(RootInlineBox* rootBox, LayoutUnit& maxPositionTop, LayoutUnit& maxPositionBottom,
--                                             LayoutUnit& maxAscent, LayoutUnit& maxDescent, bool& setMaxAscent, bool& setMaxDescent,
--                                             bool strictMode, GlyphOverflowAndFallbackFontsMap& textBoxDataMap,
--                                             FontBaseline baselineType, VerticalPositionCache& verticalPositionCache)
function InlineFlowBox:ComputeLogicalBoxHeights(rootBox, maxPositionTop, maxPositionBottom, maxAscent, maxDescent, setMaxAscent, setMaxDescent, 
													strictMode, textBoxDataMap, baselineType, verticalPositionCache)
	-- The primary purpose of this function is to compute the maximal ascent and descent values for
    -- a line. These values are computed based off the block's line-box-contain property, which indicates
    -- what parts of descendant boxes have to fit within the line.
    --
    -- The maxAscent value represents the distance of the highest point of any box (typically including line-height) from
    -- the root box's baseline. The maxDescent value represents the distance of the lowest point of any box
    -- (also typically including line-height) from the root box baseline. These values can be negative.
    --
    -- A secondary purpose of this function is to store the offset of every box's baseline from the root box's
    -- baseline. This information is cached in the logicalTop() of every box. We're effectively just using
    -- the logicalTop() as scratch space.
    --
    -- Because a box can be positioned such that it ends up fully above or fully below the
    -- root line box, we only consider it to affect the maxAscent and maxDescent values if some
    -- part of the box (EXCLUDING leading) is above (for ascent) or below (for descent) the root box's baseline.
    local affectsAscent = false;
    local affectsDescent = false;
    local checkChildren = not self:DescendantsHaveSameLineHeightAndBaseline();

	if (self:IsRootInlineBox()) then
        -- Examine our root box.
        local ascent = 0;
        local descent = 0;
        ascent, descent, affectsAscent, affectsDescent = rootBox:AscentAndDescentForBox(rootBox, textBoxDataMap, ascent, descent, affectsAscent, affectsDescent);
        if (strictMode or self:HasTextChildren() or (not checkChildren and self:HasTextDescendants())) then
            if (maxAscent < ascent or not setMaxAscent) then
                maxAscent = ascent;
                setMaxAscent = true;
            end
            if (maxDescent < descent or not setMaxDescent) then
                maxDescent = descent;
                setMaxDescent = true;
            end
        end
    end

	if (not checkChildren) then
        return maxPositionTop, maxPositionBottom, maxAscent, maxDescent, setMaxAscent, setMaxDescent;
	end

	local curr = self:FirstChild();
	while(curr) do
		if (curr:Renderer():IsPositioned()) then
			-- Positioned placeholders don't affect calculations.
		else
			local inlineFlowBox = if_else(curr:IsInlineFlowBox(),curr, nil);
        
			local affectsAscent = false;
			local affectsDescent = false;
        
			-- The verticalPositionForBox function returns the distance between the child box's baseline
			-- and the root box's baseline.  The value is negative if the child box's baseline is above the
			-- root box's baseline, and it is positive if the child box's baseline is below the root box's baseline.
			curr:SetLogicalTop(rootBox:VerticalPositionForBox(curr, verticalPositionCache));

			local ascent = 0;
			local descent = 0;
			ascent, descent, affectsAscent, affectsDescent = rootBox:AscentAndDescentForBox(curr, textBoxDataMap, ascent, descent, affectsAscent, affectsDescent);

			local boxHeight = ascent + descent;
			if (curr:VerticalAlign() == "TOP") then
				if (maxPositionTop < boxHeight) then
					maxPositionTop = boxHeight;
				end
			elseif (curr:VerticalAlign() == "BOTTOM") then
				if (maxPositionBottom < boxHeight) then
					maxPositionBottom = boxHeight;
				end
			elseif (inlineFlowBox == nil or strictMode or inlineFlowBox:HasTextChildren() or (inlineFlowBox:DescendantsHaveSameLineHeightAndBaseline() and inlineFlowBox:HasTextDescendants())
					   or inlineFlowBox:BoxModelObject():HasInlineDirectionBordersOrPadding()) then
				-- Note that these values can be negative.  Even though we only affect the maxAscent and maxDescent values
				-- if our box (excluding line-height) was above (for ascent) or below (for descent) the root baseline, once you factor in line-height
				-- the final box can end up being fully above or fully below the root box's baseline!  This is ok, but what it
				-- means is that ascent and descent (including leading), can end up being negative.  The setMaxAscent and
				-- setMaxDescent booleans are used to ensure that we're willing to initially set maxAscent/Descent to negative
				-- values.
				ascent = ascent - curr:LogicalTop();
				descent = descent + curr:LogicalTop();
				if (affectsAscent and (maxAscent < ascent or not setMaxAscent)) then
					maxAscent = ascent;
					setMaxAscent = true;
				end

				if (affectsDescent and (maxDescent < descent or not setMaxDescent)) then
					maxDescent = descent;
					setMaxDescent = true;
				end
			end

			if (inlineFlowBox) then
				maxPositionTop, maxPositionBottom, maxAscent, maxDescent, setMaxAscent, setMaxDescent = inlineFlowBox:ComputeLogicalBoxHeights(rootBox, 
				maxPositionTop, maxPositionBottom, maxAscent, maxDescent, setMaxAscent, setMaxDescent, strictMode, textBoxDataMap, baselineType, verticalPositionCache);
			end
		end


		curr = curr:NextOnLine();
	end

	return maxPositionTop, maxPositionBottom, maxAscent, maxDescent, setMaxAscent, setMaxDescent;
end

--void InlineFlowBox::adjustMaxAscentAndDescent(LayoutUnit& maxAscent, LayoutUnit& maxDescent, LayoutUnit maxPositionTop, LayoutUnit maxPositionBottom)
function InlineFlowBox:AdjustMaxAscentAndDescent(maxAscent, maxDescent, maxPositionTop, maxPositionBottom)
--    for (InlineBox* curr = firstChild(); curr; curr = curr->nextOnLine()) {
--        // The computed lineheight needs to be extended for the
--        // positioned elements
--        if (curr->renderer()->isPositioned())
--            continue; // Positioned placeholders don't affect calculations.
--        if (curr->verticalAlign() == TOP || curr->verticalAlign() == BOTTOM) {
--            LayoutUnit lineHeight = curr->lineHeight();
--            if (curr->verticalAlign() == TOP) {
--                if (maxAscent + maxDescent < lineHeight)
--                    maxDescent = lineHeight - maxAscent;
--            }
--            else {
--                if (maxAscent + maxDescent < lineHeight)
--                    maxAscent = lineHeight - maxDescent;
--            }
--
--            if (maxAscent + maxDescent >= max(maxPositionTop, maxPositionBottom))
--                break;
--        }
--
--        if (curr->isInlineFlowBox())
--            toInlineFlowBox(curr)->adjustMaxAscentAndDescent(maxAscent, maxDescent, maxPositionTop, maxPositionBottom);
--    }
end

--void InlineFlowBox::placeBoxesInBlockDirection(LayoutUnit top, LayoutUnit maxHeight, LayoutUnit maxAscent, bool strictMode, LayoutUnit& lineTop, LayoutUnit& lineBottom, bool& setLineTop,
--                                               LayoutUnit& lineTopIncludingMargins, LayoutUnit& lineBottomIncludingMargins, bool& hasAnnotationsBefore, bool& hasAnnotationsAfter, FontBaseline baselineType)
function InlineFlowBox:PlaceBoxesInBlockDirection(top, maxHeight, maxAscent, strictMode, lineTop, lineBottom, setLineTop,
													lineTopIncludingMargins, lineBottomIncludingMargins, hasAnnotationsBefore, hasAnnotationsAfter, baselineType)
	local isRootBox = self:IsRootInlineBox();
    if (isRootBox) then
        --const FontMetrics& fontMetrics = renderer()->style(m_firstLine)->fontMetrics();
		local fontAscent = self:Renderer():Style():FontAscent(baselineType);
        self:SetLogicalTop(top + maxAscent - fontAscent);
    end

	local adjustmentForChildrenWithSameLineHeightAndBaseline = 0;
    if (self:DescendantsHaveSameLineHeightAndBaseline()) then
        adjustmentForChildrenWithSameLineHeightAndBaseline = self:LogicalTop();
        if (self:Parent()) then
            adjustmentForChildrenWithSameLineHeightAndBaseline = adjustmentForChildrenWithSameLineHeightAndBaseline + (self:BoxModelObject():BorderBefore() + self:BoxModelObject():PaddingBefore());
		end
    end

	local curr = self:FirstChild();
	while(curr) do
		if (curr:Renderer():IsPositioned()) then
            -- Positioned placeholders don't affect calculations.
		elseif (self:DescendantsHaveSameLineHeightAndBaseline()) then
            curr:AdjustBlockDirectionPosition(adjustmentForChildrenWithSameLineHeightAndBaseline);
            --continue;
        else
			local inlineFlowBox = if_else(curr:IsInlineFlowBox(), curr, nil);
			local childAffectsTopBottomPos = true;
			if (curr:VerticalAlign() == "TOP") then
				curr:SetLogicalTop(top);
			elseif (curr:VerticalAlign() == "BOTTOM") then
				curr:SetLogicalTop(top + maxHeight - curr:LineHeight());
			else
				if (not strictMode and inlineFlowBox ~= nil and not inlineFlowBox:HasTextChildren() and not curr:BoxModelObject():HasInlineDirectionBordersOrPadding()
					and not (inlineFlowBox:DescendantsHaveSameLineHeightAndBaseline() and inlineFlowBox:HasTextDescendants())) then
					childAffectsTopBottomPos = false;
				end
				local posAdjust = maxAscent - curr:BaselinePosition(baselineType);
				curr:SetLogicalTop(curr:LogicalTop() + top + posAdjust);
			end
        
			local newLogicalTop = curr:LogicalTop();
			local newLogicalTopIncludingMargins = newLogicalTop;
			local boxHeight = curr:LogicalHeight();
			local boxHeightIncludingMargins = boxHeight;
            
			if (curr:IsText() or curr:IsInlineFlowBox()) then
				local fontAscent = self:Style():FontAscent(baselineType);
				--const FontMetrics& fontMetrics = curr->renderer()->style(m_firstLine)->fontMetrics();
				--newLogicalTop += curr->baselinePosition(baselineType) - fontMetrics.ascent(baselineType);
				newLogicalTop = newLogicalTop + curr:BaselinePosition(baselineType) - fontAscent;
				if (curr:IsInlineFlowBox()) then
					local boxObject = curr:Renderer();
					newLogicalTop = newLogicalTop - if_else(boxObject:Style(self.firstLine):IsHorizontalWritingMode(), boxObject:BorderTop() + boxObject:PaddingTop(), 
									 boxObject:BorderRight() + boxObject:PaddingRight());
				end
				newLogicalTopIncludingMargins = newLogicalTop;
			elseif (not curr:Renderer():IsBR()) then
				local box = curr:Renderer();
				newLogicalTopIncludingMargins = newLogicalTop;
				local overSideMargin = if_else(curr:IsHorizontal(), box:MarginTop(), box:MarginRight());
				local underSideMargin = if_else(curr:IsHorizontal(), box:MarginBottom(), box:MarginLeft());
				newLogicalTop = newLogicalTop + overSideMargin;
				boxHeightIncludingMargins = boxHeightIncludingMargins + overSideMargin + underSideMargin;
			end

			curr:SetLogicalTop(newLogicalTop);

			if (childAffectsTopBottomPos) then
				if (curr:Renderer():IsRubyRun()) then
--					// Treat the leading on the first and last lines of ruby runs as not being part of the overall lineTop/lineBottom.
--					// Really this is a workaround hack for the fact that ruby should have been done as line layout and not done using
--					// inline-block.
--					if (!renderer()->style()->isFlippedLinesWritingMode())
--						hasAnnotationsBefore = true;
--					else
--						hasAnnotationsAfter = true;
--
--					RenderRubyRun* rubyRun = toRenderRubyRun(curr->renderer());
--					if (RenderRubyBase* rubyBase = rubyRun->rubyBase()) {
--						LayoutUnit bottomRubyBaseLeading = (curr->logicalHeight() - rubyBase->logicalBottom()) + rubyBase->logicalHeight() - (rubyBase->lastRootBox() ? rubyBase->lastRootBox()->lineBottom() : 0);
--						LayoutUnit topRubyBaseLeading = rubyBase->logicalTop() + (rubyBase->firstRootBox() ? rubyBase->firstRootBox()->lineTop() : 0);
--						newLogicalTop += !renderer()->style()->isFlippedLinesWritingMode() ? topRubyBaseLeading : bottomRubyBaseLeading;
--						boxHeight -= (topRubyBaseLeading + bottomRubyBaseLeading);
--					}
				end
				if (curr:IsInlineTextBox()) then
--					TextEmphasisPosition emphasisMarkPosition;
--					if (toInlineTextBox(curr)->getEmphasisMarkPosition(curr->renderer()->style(m_firstLine), emphasisMarkPosition)) {
--						bool emphasisMarkIsOver = emphasisMarkPosition == TextEmphasisPositionOver;
--						if (emphasisMarkIsOver != curr->renderer()->style(m_firstLine)->isFlippedLinesWritingMode())
--							hasAnnotationsBefore = true;
--						else
--							hasAnnotationsAfter = true;
--					}
				end

				if (not setLineTop) then
					setLineTop = true;
					lineTop = newLogicalTop;
					lineTopIncludingMargins = math.min(lineTop, newLogicalTopIncludingMargins);
				else
					lineTop = math.min(lineTop, newLogicalTop);
					lineTopIncludingMargins = math.min(lineTop, math.min(lineTopIncludingMargins, newLogicalTopIncludingMargins));
				end
				lineBottom = math.max(lineBottom, newLogicalTop + boxHeight);
				lineBottomIncludingMargins = math.max(lineBottom, math.max(lineBottomIncludingMargins, newLogicalTopIncludingMargins + boxHeightIncludingMargins));
			end

			-- Adjust boxes to use their real box y/height and not the logical height (as dictated by
			-- line-height).
			if (inlineFlowBox) then
				lineTop, lineBottom, setLineTop, lineTopIncludingMargins, lineBottomIncludingMargins, hasAnnotationsBefore, hasAnnotationsAfter = inlineFlowBox:PlaceBoxesInBlockDirection(top, maxHeight, maxAscent, strictMode, 
				lineTop, lineBottom, setLineTop, lineTopIncludingMargins, lineBottomIncludingMargins, hasAnnotationsBefore, hasAnnotationsAfter, baselineType);
			end
		end

		curr = curr:NextOnLine();
	end

	if (isRootBox) then
        if (strictMode or self:HasTextChildren() or (self:DescendantsHaveSameLineHeightAndBaseline() and self:HasTextDescendants())) then
            if (not setLineTop) then
                setLineTop = true;
                lineTop = self:LogicalTop();
                lineTopIncludingMargins = lineTop;
            else
                lineTop = math.min(lineTop, self:LogicalTop());
                lineTopIncludingMargins = math.min(lineTop, lineTopIncludingMargins);
            end
            lineBottom = math.max(lineBottom, self:LogicalTop() + self:LogicalHeight());
            lineBottomIncludingMargins = math.max(lineBottom, lineBottomIncludingMargins);
        end
        
        if (self:Renderer():Style():IsFlippedLinesWritingMode()) then
            --flipLinesInBlockDirection(lineTopIncludingMargins, lineBottomIncludingMargins);
		end
    end

	return lineTop, lineBottom, setLineTop, lineTopIncludingMargins, lineBottomIncludingMargins, hasAnnotationsBefore, hasAnnotationsAfter;
end

--void InlineFlowBox::computeOverflow(LayoutUnit lineTop, LayoutUnit lineBottom, GlyphOverflowAndFallbackFontsMap& textBoxDataMap)
function InlineFlowBox:ComputeOverflow(lineTop, lineBottom, textBoxDataMap)
    -- If we know we have no overflow, we can just bail.
    if (self:KnownToHaveNoOverflow()) then
        return;
	end
--    // Visual overflow just includes overflow for stuff we need to repaint ourselves.  Self-painting layers are ignored.
--    // Layout overflow is used to determine scrolling extent, so it still includes child layers and also factors in
--    // transforms, relative positioning, etc.
--    LayoutRect logicalLayoutOverflow(enclosingLayoutRect(logicalFrameRectIncludingLineHeight(lineTop, lineBottom)));
--    LayoutRect logicalVisualOverflow(logicalLayoutOverflow);
--  
--    addBoxShadowVisualOverflow(logicalVisualOverflow);
--    addBorderOutsetVisualOverflow(logicalVisualOverflow);
--
--    for (InlineBox* curr = firstChild(); curr; curr = curr->nextOnLine()) {
--        if (curr->renderer()->isPositioned())
--            continue; // Positioned placeholders don't affect calculations.
--        
--        if (curr->renderer()->isText()) {
--            InlineTextBox* text = toInlineTextBox(curr);
--            RenderText* rt = toRenderText(text->renderer());
--            if (rt->isBR())
--                continue;
--            LayoutRect textBoxOverflow(enclosingLayoutRect(text->logicalFrameRect()));
--            addTextBoxVisualOverflow(text, textBoxDataMap, textBoxOverflow);
--            logicalVisualOverflow.unite(textBoxOverflow);
--        } else  if (curr->renderer()->isRenderInline()) {
--            InlineFlowBox* flow = toInlineFlowBox(curr);
--            flow->computeOverflow(lineTop, lineBottom, textBoxDataMap);
--            if (!flow->boxModelObject()->hasSelfPaintingLayer())
--                logicalVisualOverflow.unite(flow->logicalVisualOverflowRect(lineTop, lineBottom));
--            LayoutRect childLayoutOverflow = flow->logicalLayoutOverflowRect(lineTop, lineBottom);
--            childLayoutOverflow.move(flow->boxModelObject()->relativePositionLogicalOffset());
--            logicalLayoutOverflow.unite(childLayoutOverflow);
--        } else
--            addReplacedChildOverflow(curr, logicalLayoutOverflow, logicalVisualOverflow);
--    }
--    
--    setOverflowFromLogicalRects(logicalLayoutOverflow, logicalVisualOverflow, lineTop, lineBottom);
end

--void paint(PaintInfo&, const LayoutPoint&, LayoutUnit lineTop, LayoutUnit lineBottom)
function InlineFlowBox:Paint(paintInfo, paintOffset, lineTop, lineBottom)
	
	--PaintInfo childInfo(paintInfo);
	local childInfo = paintInfo;

	-- Paint our children.
	local curr = self:FirstChild();
	while(curr) do
		--if (curr:Renderer():IsText() or not curr:BoxModelObject():HasSelfPaintingLayer()) then
		if (curr:Renderer():IsText()) then
            curr:Paint(childInfo, paintOffset, lineTop, lineBottom);
		end

		curr = curr:NextOnLine();
	end
end

--FloatRect frameRectIncludingLineHeight(LayoutUnit lineTop, LayoutUnit lineBottom) const
function InlineFlowBox:FrameRectIncludingLineHeight(lineTop, lineBottom)
    if (self:IsHorizontal()) then
        return Rect:new(self.topLeft:X(), lineTop, self:Width(), lineBottom - lineTop);
	end
    return Rect:new(lineTop, self.topLeft:Y(), lineBottom - lineTop, self:Height());
end

-- Line visual and layout overflow are in the coordinate space of the block.  This means that they aren't purely physical directions.
-- For horizontal-tb and vertical-lr they will match physical directions, but for horizontal-bt and vertical-rl, the top/bottom and left/right
-- respectively are flipped when compared to their physical counterparts.  For example minX is on the left in vertical-lr, but it is on the right in vertical-rl.
--LayoutRect layoutOverflowRect(LayoutUnit lineTop, LayoutUnit lineBottom) const
function InlineFlowBox:LayoutOverflowRect(lineTop, lineBottom)
    --return m_overflow ? m_overflow->layoutOverflowRect() : enclosingLayoutRect(frameRectIncludingLineHeight(lineTop, lineBottom));
	return self:FrameRectIncludingLineHeight(lineTop, lineBottom)
end

function InlineFlowBox:LogicalLeftLayoutOverflow()
	--return m_overflow ? (isHorizontal() ? m_overflow->minXLayoutOverflow() : m_overflow->minYLayoutOverflow()) : logicalLeft();
	return self:LogicalLeft();
end

function InlineFlowBox:LogicalRightLayoutOverflow()
	--return m_overflow ? (isHorizontal() ? m_overflow->maxXLayoutOverflow() : m_overflow->maxYLayoutOverflow()) : ceilf(logicalRight());
	return self:LogicalRight();
end

function InlineFlowBox:LogicalTopLayoutOverflow(lineTop)
--    if (m_overflow)
--        return isHorizontal() ? m_overflow->minYLayoutOverflow() : m_overflow->minXLayoutOverflow();
    return lineTop;
end

function InlineFlowBox:LogicalBottomLayoutOverflow(lineBottom)
--    if (m_overflow)
--        return isHorizontal() ? m_overflow->maxYLayoutOverflow() : m_overflow->maxXLayoutOverflow();
    return lineBottom;
end

function InlineFlowBox:LogicalLayoutOverflowRect(lineTop, lineBottom)
    local result = self:LayoutOverflowRect(lineTop, lineBottom);
    if (not self:Renderer():IsHorizontalWritingMode()) then
        result = result:TransposedRect();
	end
    return result;
end

function InlineFlowBox:VisualOverflowRect(lineTop, lineBottom)
    --return m_overflow ? m_overflow->visualOverflowRect() : enclosingLayoutRect(frameRectIncludingLineHeight(lineTop, lineBottom));
	return self:FrameRectIncludingLineHeight(lineTop, lineBottom);
end

function InlineFlowBox:LogicalLeftVisualOverflow()
	--return m_overflow ? (isHorizontal() ? m_overflow->minXVisualOverflow() : m_overflow->minYVisualOverflow()) : logicalLeft();
	return self:LogicalLeft();
end

function InlineFlowBox:LogicalRightVisualOverflow()
	--return m_overflow ? (isHorizontal() ? m_overflow->maxXVisualOverflow() : m_overflow->maxYVisualOverflow()) : ceilf(logicalRight());
	return self:LogicalRight();
end

function InlineFlowBox:LogicalTopVisualOverflow(lineTop)
--    if (m_overflow)
--        return isHorizontal() ? m_overflow->minYVisualOverflow() : m_overflow->minXVisualOverflow();
    return lineTop;
end

function InlineFlowBox:LogicalBottomVisualOverflow(lineBottom)
--    if (m_overflow)
--        return isHorizontal() ? m_overflow->maxYVisualOverflow() : m_overflow->maxXVisualOverflow();
    return lineBottom;
end

function InlineFlowBox:LogicalVisualOverflowRect(lineTop, lineBottom)
    local result = self:VisualOverflowRect(lineTop, lineBottom);
    if (not self:Renderer():IsHorizontalWritingMode()) then
        result = result:TransposedRect();
	end
    return result;
end