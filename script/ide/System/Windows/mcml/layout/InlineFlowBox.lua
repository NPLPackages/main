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
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/Shapes/Rectangle.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutOverflow.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");
local LayoutOverflow = commonlib.gettable("System.Windows.mcml.layout.LayoutOverflow");
local Rectangle = commonlib.gettable("System.Windows.Shapes.Rectangle");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local UniString = commonlib.gettable("System.Core.UniString");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");

local InlineFlowBox = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.InlineBox"), commonlib.gettable("System.Windows.mcml.layout.InlineFlowBox"));

local DisplayEnum = ComputedStyleConstants.DisplayEnum;
local VerticalAlignEnum = ComputedStyleConstants.VerticalAlignEnum;
local TextEmphasisMarkEnum = ComputedStyleConstants.TextEmphasisMarkEnum;
local VisibilityEnum = ComputedStyleConstants.VisibilityEnum;
local LineBoxContainEnum = ComputedStyleConstants.LineBoxContainEnum;

local IntRect = Rect;
local LayoutRect = Rect;

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

	self.control = nil;
end

function InlineFlowBox:init(obj)
	InlineFlowBox._super.init(self, obj);
	self.hasTextChildren = obj:Style():Display() == DisplayEnum.LIST_ITEM;
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
	--InlineBox* leaf = 0;
	local leaf = nil;
	local child = self:FirstChild();
	while(child and not leaf) do
		if(child:IsLeaf()) then
			leaf = child;
		else
			leaf = child:ToInlineFlowBox():FirstLeafChild();
		end
		
		child = child:NextOnLine();
	end
    return leaf;
end

function InlineFlowBox:LastLeafChild()
	local leaf = nil;
	local child = self:LastChild();
	while(child and not leaf) do
		if(child:IsLeaf()) then
			leaf = child;
		else
			leaf = child:ToInlineFlowBox():LastLeafChild();
		end
		
		child = child:PrevOnLine();
	end
    return leaf;
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
				if(not parentStyle:Font():FontMetrics():hasIdenticalAscentDescentAndLineGap(childStyle:Font():FontMetrics())
					or parentStyle:LineHeight() ~= childStyle:LineHeight()
					or (parentStyle:VerticalAlign() ~= VerticalAlignEnum.BASELINE and not self:IsRootInlineBox()) or childStyle:VerticalAlign() ~= VerticalAlignEnum.BASELINE) then
					shouldClearDescendantsHaveSameLineHeightAndBaseline = true;
				end
            end
            if (childStyle:HasTextCombine() or childStyle:TextEmphasisMark() ~= TextEmphasisMarkEnum.TextEmphasisMarkNone) then
                shouldClearDescendantsHaveSameLineHeightAndBaseline = true;
			end
        else
            if (child:Renderer():IsBR()) then
                -- FIXME: This is dumb. We only turn off because current layout test results expect the <br> to be 0-height on the baseline.
                -- Other than making a zillion tests have to regenerate results, there's no reason to ditch the optimization here.
                shouldClearDescendantsHaveSameLineHeightAndBaseline = true;
            else
                --ASSERT(isInlineFlowBox());
                local childFlowBox = child;
                -- Check the child's bit, and then also check for differences in font, line-height, vertical-align
				if (not childFlowBox:DescendantsHaveSameLineHeightAndBaseline()
					or not parentStyle:Font():FontMetrics():hasIdenticalAscentDescentAndLineGap(childStyle:Font():FontMetrics())
                    or parentStyle:LineHeight() ~= childStyle:LineHeight()
                    or (parentStyle:VerticalAlign() ~= VerticalAlignEnum.BASELINE and not self:IsRootInlineBox()) or childStyle:VerticalAlign() ~= VerticalAlignEnum.BASELINE
                    or childStyle:HasBorder() or childStyle:HasPadding() or childStyle:HasTextCombine()) then
                    shouldClearDescendantsHaveSameLineHeightAndBaseline = true;
				end
            end
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
            local box = child:Renderer();
            if (box:HasRenderOverflow() or box:HasSelfPaintingLayer()) then
                child:ClearKnownToHaveNoOverflow();
			end
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

function InlineFlowBox:Destroy(arena)
--    if (!m_knownToHaveNoOverflow && gTextBoxesWithOverflow) then
--        gTextBoxesWithOverflow->remove(this);
--	end
	if(self.control) then
		self.control:Destroy();
		self.control = nil;
	end

	InlineFlowBox._super.Destroy(self, arena);
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
	echo("InlineFlowBox:PlaceBoxesInInlineDirection")
	self:Renderer():PrintNodeInfo();
	echo(logicalLeft)
	echo(needsWordSpacing)
	local originalLogicalLeft = logicalLeft;
	-- Set our x position.
    self:SetLogicalLeft(logicalLeft);
	if(self:IsRootInlineBox()) then
		logicalLeft = 0
	end
  
    local startLogicalLeft = logicalLeft;
    logicalLeft = logicalLeft + self:BorderLogicalLeft() + self:PaddingLogicalLeft();
    local minLogicalLeft = startLogicalLeft;
    local maxLogicalRight = logicalLeft;

	local curr = self:FirstChild();
	local isFirstChild = true;
	while(curr) do
		echo("while(curr) do")
		echo(logicalLeft)
		if (curr:Renderer():IsText()) then
            local text = curr;
            local rt = text:Renderer();
            if (rt:TextLength()) then
                if (needsWordSpacing and UniString.IsSpaceOrNewline(rt:Characters()[text:Start()])) then
                    logicalLeft = logicalLeft + rt:Style(self.firstLine):WordSpacing();
				end
                needsWordSpacing = not UniString.IsSpaceOrNewline(rt:Characters()[text:End()]);
            end
			if(self:IsRootInlineBox()) then
				text:SetLogicalLeft(logicalLeft);
			else
				text:SetLogicalLeft(logicalLeft - originalLogicalLeft);
			end
			--text:SetLogicalLeft(logicalLeft);
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
				if (curr:Renderer():IsLayoutInline()) then
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
				--elseif (not curr:Renderer():IsListMarker() or toRenderListMarker(curr->renderer())->isInside()) {
				elseif (not curr:Renderer():IsListMarker()) then
					-- The box can have a different writing-mode than the overall line, so this is a bit complicated.
					-- Just get all the physical margin and overflow values by hand based off |isVertical|.
					local logicalLeftMargin, logicalRightMargin;
					if(self:IsHorizontal()) then
						logicalLeftMargin = curr:BoxModelObject():MarginLeft();
						logicalRightMargin = curr:BoxModelObject():MarginTop();
					else
						logicalLeftMargin = curr:BoxModelObject():MarginRight();
						logicalRightMargin = curr:BoxModelObject():MarginBottom();
					end

                
					logicalLeft = logicalLeft + logicalLeftMargin;
					curr:SetLogicalLeft(logicalLeft);
					if (self:KnownToHaveNoOverflow()) then
						minLogicalLeft = math.min(logicalLeft, minLogicalLeft);
					end
					logicalLeft = logicalLeft + curr:LogicalWidth();
					if (self:KnownToHaveNoOverflow()) then
						maxLogicalRight = math.max(logicalLeft, maxLogicalRight);
					end
					logicalLeft = logicalLeft + logicalRightMargin;
				end
			end
		end
		isFirstChild = false;
		curr = curr:NextOnLine();
	end

	logicalLeft = logicalLeft + self:BorderLogicalRight() + self:PaddingLogicalRight();
	local logicalWidth = logicalLeft - startLogicalLeft;
	if(self:IsRootInlineBox()) then
		logicalWidth = logicalWidth + originalLogicalLeft;
	end
	echo("InlineFlowBox:PlaceBoxesInInlineDirection end")
	echo(logicalLeft - startLogicalLeft)
    self:SetLogicalWidth(logicalWidth);
    if (self:KnownToHaveNoOverflow() and (minLogicalLeft < startLogicalLeft or maxLogicalRight > logicalLeft)) then
        self:ClearKnownToHaveNoOverflow();
	end
    return logicalLeft, needsWordSpacing;
end

function InlineFlowBox:DescendantsHaveSameLineHeightAndBaseline()
	return self.descendantsHaveSameLineHeightAndBaseline;
end

function InlineFlowBox:ClearDescendantsHaveSameLineHeightAndBaseline()
	echo("InlineFlowBox:ClearDescendantsHaveSameLineHeightAndBaseline");
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
			echo("rootBox:AscentAndDescentForBox");
			curr:Renderer():PrintNodeInfo();
			echo({ascent, descent, affectsAscent, affectsDescent})
			local boxHeight = ascent + descent;
			if (curr:VerticalAlign() == VerticalAlignEnum.TOP) then
				if (maxPositionTop < boxHeight) then
					maxPositionTop = boxHeight;
				end
			elseif (curr:VerticalAlign() == VerticalAlignEnum.BOTTOM) then
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
	local curr = self:FirstChild();
	while(curr) do
		-- The computed lineheight needs to be extended for the
        -- positioned elements
        if (curr:Renderer():IsPositioned()) then
            -- continue; 
			-- Positioned placeholders don't affect calculations.
		else
			if (curr:VerticalAlign() == VerticalAlignEnum.TOP or curr:VerticalAlign() == VerticalAlignEnum.BOTTOM) then
				local lineHeight = curr:LineHeight();
				if (curr:VerticalAlign() == VerticalAlignEnum.TOP) then
					if (maxAscent + maxDescent < lineHeight) then
						maxDescent = lineHeight - maxAscent;
					end
				else
					if (maxAscent + maxDescent < lineHeight) then
						maxAscent = lineHeight - maxDescent;
					end
				end

				if (maxAscent + maxDescent >= math.max(maxPositionTop, maxPositionBottom)) then
					break;
				end
			end

			if (curr:IsInlineFlowBox()) then
				maxAscent, maxDescent = curr:AdjustMaxAscentAndDescent(maxAscent, maxDescent, maxPositionTop, maxPositionBottom);
			end
		end

		curr = curr:NextOnLine()
	end
	return maxAscent, maxDescent;
end

function InlineFlowBox:AdjustBlockDirectionPositionForChild(child, adjustmentForChildrenWithSameLineHeightAndBaseline)
	if(child:IsInlineTextBox()) then
		child:AdjustBlockDirectionPosition(adjustmentForChildrenWithSameLineHeightAndBaseline);
	elseif(child:IsInlineFlowBox()) then
		local curr = child:FirstChild();
		while(curr) do
			child:AdjustBlockDirectionPositionForChild(curr, adjustmentForChildrenWithSameLineHeightAndBaseline);
			curr = curr:NextOnLine();
		end
	end
end

function InlineFlowBox:AscentAndDescentForBox(box, baselineType)
	local ascent, descent = 0, 0;
	if (box:Renderer():IsReplaced()) then
		local lineBoxContain = self:Renderer():Style(self.firstLine):LineBoxContain();
        if (mathlib.bit.band(lineBoxContain, LineBoxContainEnum.LineBoxContainReplaced)) then		
            ascent = box:BaselinePosition(baselineType);
			local fontMetrics = box:Renderer():Style(self.firstLine):FontMetrics();
			local height = box:Height() + box:Renderer():MarginTop() + box:Renderer():MarginBottom()
--			if(fontMetrics:lineSpacing() > height) then
--				height = fontMetrics:lineSpacing()
--			end
            descent = height - ascent;
        end
    end

	if (box:IsText()) then
		local fontMetrics = box:Renderer():Style(self.firstLine):FontMetrics();
		ascent, descent = fontMetrics:ascent(baselineType), fontMetrics:descent(baselineType);
	end

	if(box:IsInlineFlowBox()) then
		local fontMetrics = box:Renderer():Style(self.firstLine):FontMetrics();
		ascent = math.floor(fontMetrics:ascent(baselineType) + (fontMetrics:lineSpacing()  - fontMetrics.height()) / 2 + 0.5);
		descent = fontMetrics:lineSpacing() - ascent;
	end
	return ascent, descent;
end

function InlineFlowBox:PlaceBoxesInBlockDirection(textBoxDataMap, baselineType)
	echo("InlineFlowBox:PlaceBoxesInBlockDirection begin")
	self:Renderer():PrintNodeInfo()
	local maxAscent, maxDescent = 0, 0;
	local ascentMap = {}
	local curr = self:FirstChild();
	while(curr) do
		echo("while(curr) do")
		curr:Renderer():PrintNodeInfo()
		if (curr:Renderer():IsPositioned()) then
            -- Positioned placeholders don't affect calculations.
		else
			local ascent, descent = 0, 0;
			local inlineFlowBox = if_else(curr:IsInlineFlowBox(), curr, nil);
			if (inlineFlowBox) then
				ascent, descent = inlineFlowBox:PlaceBoxesInBlockDirection()
			else
				ascent, descent = self:AscentAndDescentForBox(curr, baselineType)
			end
			echo({ascent,descent})
			ascentMap[curr] = ascent
			if(ascent > maxAscent) then
				maxAscent = ascent
			end
			if(descent > maxDescent) then
				maxDescent = descent
			end
		end
		curr = curr:NextOnLine();
	end
	echo("maxAscent, maxDescent")
	echo({maxAscent, maxDescent})
	local maxHeight = maxAscent + maxDescent;
	local lineHeight;
	if (self:IsRootInlineBox()) then
		lineHeight = self:LineHeight();
	elseif(self:IsInlineFlowBox()) then
		local fontMetrics = self:Renderer():Style(self.firstLine):FontMetrics();
		lineHeight = fontMetrics:lineSpacing();
	end
	if(lineHeight > maxHeight) then
		maxAscent = maxAscent + (lineHeight - maxHeight) / 2;
		maxDescent = lineHeight - maxAscent;
	end
	echo("InlineFlowBox:PlaceBoxesInBlockDirection Place")
	self:Renderer():PrintNodeInfo()
	echo({maxAscent, maxDescent})
	echo({lineHeight,maxHeight})
	local curr = self:FirstChild();
	while(curr) do
		if (curr:Renderer():IsPositioned()) then
            -- Positioned placeholders don't affect calculations.
		else
			
			local ascent = ascentMap[curr];
			
			echo("while(curr) do")
			curr:Renderer():PrintNodeInfo()
			echo(ascent)
			curr:SetLogicalTop(maxAscent - ascent)

			local newLogicalTop = curr:LogicalTop();
			if (curr:IsText() or curr:IsInlineFlowBox()) then
				if(curr:IsInlineFlowBox()) then
					local boxObject = curr:Renderer():ToRenderBoxModelObject();
					newLogicalTop = newLogicalTop - if_else(boxObject:Style(self.firstLine):IsHorizontalWritingMode(), boxObject:BorderTop() + boxObject:PaddingTop(), 
									 boxObject:BorderRight() + boxObject:PaddingRight());
				end
			elseif (not curr:Renderer():IsBR()) then
				local box = curr:Renderer();
				local overSideMargin = if_else(curr:IsHorizontal(), box:MarginTop(), box:MarginRight());
				newLogicalTop = newLogicalTop + overSideMargin
			end

			if(self:IsInlineFlowBox() and not self:IsRootInlineBox()) then
				local boxObject = self:Renderer():ToRenderBoxModelObject();
				newLogicalTop = newLogicalTop + if_else(boxObject:Style(self.firstLine):IsHorizontalWritingMode(), boxObject:BorderTop() + boxObject:PaddingTop(), 
									 boxObject:BorderRight() + boxObject:PaddingRight());
			end

			curr:SetLogicalTop(newLogicalTop)
		end
		curr = curr:NextOnLine();
	end
	echo("InlineFlowBox:PlaceBoxesInBlockDirection end")
	return maxAscent, maxDescent;
end

--function InlineFlowBox:PlaceBoxesInBlockDirection(top, maxHeight, maxAscent, strictMode, lineTop, lineBottom, setLineTop,
--													lineTopIncludingMargins, lineBottomIncludingMargins, hasAnnotationsBefore, hasAnnotationsAfter, baselineType)
--	local isRootBox = self:IsRootInlineBox();
--    if (isRootBox) then
--		self:SetLogicalTop(top)
--    end
--	local curr = self:FirstChild();
--	while(curr) do
--		if (curr:Renderer():IsPositioned()) then
--            -- Positioned placeholders don't affect calculations.
--		else
--			local inlineFlowBox = if_else(curr:IsInlineFlowBox(), curr, nil);
--			local childAffectsTopBottomPos = true;
--			if (curr:VerticalAlign() == VerticalAlignEnum.TOP) then
--				curr:SetLogicalTop(top);
--			elseif (curr:VerticalAlign() == VerticalAlignEnum.BOTTOM) then
--				curr:SetLogicalTop(top + maxHeight - curr:LineHeight());
--			else
--				local posAdjust = maxAscent - curr:BaselinePosition(baselineType);
--				curr:SetLogicalTop(curr:LogicalTop() + posAdjust);
--			end
--
--
--			local newLogicalTop = curr:LogicalTop();
--			local newLogicalTopIncludingMargins = newLogicalTop;
--			local boxHeight = curr:LogicalHeight();
--			local boxHeightIncludingMargins = boxHeight;
--			if (curr:IsText() or curr:IsInlineFlowBox()) then
--				local fontMetrics = curr:Renderer():Style(self.firstLine):FontMetrics();
--				newLogicalTop = newLogicalTop + curr:BaselinePosition(baselineType) - fontMetrics:ascent(baselineType);
--				if (curr:IsInlineFlowBox()) then
--					local boxObject = curr:Renderer():ToRenderBoxModelObject();
--					newLogicalTop = newLogicalTop - if_else(boxObject:Style(self.firstLine):IsHorizontalWritingMode(), boxObject:BorderTop() + boxObject:PaddingTop(), 
--									 boxObject:BorderRight() + boxObject:PaddingRight());
--				end
--				newLogicalTopIncludingMargins = newLogicalTop;
--			elseif (not curr:Renderer():IsBR()) then
--				local box = curr:Renderer();
--				newLogicalTopIncludingMargins = newLogicalTop;
--				local overSideMargin = if_else(curr:IsHorizontal(), box:MarginTop(), box:MarginRight());
--				local underSideMargin = if_else(curr:IsHorizontal(), box:MarginBottom(), box:MarginLeft());
--				newLogicalTop = newLogicalTop + overSideMargin;
--				boxHeightIncludingMargins = boxHeightIncludingMargins + overSideMargin + underSideMargin;
--			end
--
--			curr:SetLogicalTop(newLogicalTop);
--
--			if (childAffectsTopBottomPos) then
--				if (not setLineTop) then
--					setLineTop = true;
--					lineTop = newLogicalTop;
--					lineTopIncludingMargins = math.min(lineTop, newLogicalTopIncludingMargins);
--				else
--					lineTop = math.min(lineTop, newLogicalTop);
--					lineTopIncludingMargins = math.min(lineTop, math.min(lineTopIncludingMargins, newLogicalTopIncludingMargins));
--				end
--				lineBottom = math.max(lineBottom, newLogicalTop + boxHeight);
--				lineBottomIncludingMargins = math.max(lineBottom, math.max(lineBottomIncludingMargins, newLogicalTopIncludingMargins + boxHeightIncludingMargins));
--			end
--
--			-- Adjust boxes to use their real box y/height and not the logical height (as dictated by
--			-- line-height).
--			if (inlineFlowBox) then
--				lineTop, lineBottom, setLineTop, lineTopIncludingMargins, lineBottomIncludingMargins, hasAnnotationsBefore, hasAnnotationsAfter = inlineFlowBox:PlaceBoxesInBlockDirection(top, maxHeight, maxAscent, strictMode, 
--				lineTop, lineBottom, setLineTop, lineTopIncludingMargins, lineBottomIncludingMargins, hasAnnotationsBefore, hasAnnotationsAfter, baselineType);
--			end
--		end
--		curr = curr:NextOnLine();
--	end
--
--	if (isRootBox) then
--        if (strictMode or self:HasTextChildren() or (self:DescendantsHaveSameLineHeightAndBaseline() and self:HasTextDescendants())) then
--            if (not setLineTop) then
--                setLineTop = true;
--                lineTop = self:LogicalTop();
--                lineTopIncludingMargins = lineTop;
--            else
--                lineTop = math.min(lineTop, self:LogicalTop());
--                lineTopIncludingMargins = math.min(lineTop, lineTopIncludingMargins);
--            end
--            lineBottom = math.max(lineBottom, self:LogicalTop() + self:LogicalHeight());
--            lineBottomIncludingMargins = math.max(lineBottom, lineBottomIncludingMargins);
--        end
--        
--        if (self:Renderer():Style():IsFlippedLinesWritingMode()) then
--            self:FlipLinesInBlockDirection(lineTopIncludingMargins, lineBottomIncludingMargins);
--		end
--    end
--
--	return lineTop, lineBottom, setLineTop, lineTopIncludingMargins, lineBottomIncludingMargins, hasAnnotationsBefore, hasAnnotationsAfter;
--end

--[[
--void InlineFlowBox::placeBoxesInBlockDirection(LayoutUnit top, LayoutUnit maxHeight, LayoutUnit maxAscent, bool strictMode, LayoutUnit& lineTop, LayoutUnit& lineBottom, bool& setLineTop,
--                                               LayoutUnit& lineTopIncludingMargins, LayoutUnit& lineBottomIncludingMargins, bool& hasAnnotationsBefore, bool& hasAnnotationsAfter, FontBaseline baselineType)
function InlineFlowBox:PlaceBoxesInBlockDirection(top, maxHeight, maxAscent, strictMode, lineTop, lineBottom, setLineTop,
													lineTopIncludingMargins, lineBottomIncludingMargins, hasAnnotationsBefore, hasAnnotationsAfter, baselineType)
	local isRootBox = self:IsRootInlineBox();
	echo("InlineFlowBox:PlaceBoxesInBlockDirection");
	echo(self:BoxName())
	echo({self:LogicalLeft(), self:LogicalTop(), self:LogicalWidth(), self:LogicalHeight()});
	echo({top, maxHeight, maxAscent, strictMode, lineTop, lineBottom, setLineTop,
													lineTopIncludingMargins, lineBottomIncludingMargins, hasAnnotationsBefore, hasAnnotationsAfter, baselineType})
    if (isRootBox) then
        --const FontMetrics& fontMetrics = renderer()->style(m_firstLine)->fontMetrics();
		local fontMetrics = self:Renderer():Style(self.firstLine):FontMetrics();
		--local fontAscent = self:Renderer():Style():FontAscent(baselineType);
		echo("fontMetrics:ascent(baselineType)");
		echo(fontMetrics:ascent(baselineType))
        --self:SetLogicalTop(top + maxAscent - fontMetrics:ascent(baselineType));
		self:SetLogicalTop(top)
    end
	local adjustmentForChildrenWithSameLineHeightAndBaseline = 0;
    if (self:DescendantsHaveSameLineHeightAndBaseline()) then
		adjustmentForChildrenWithSameLineHeightAndBaseline = self:LogicalTop();
--		if (isRootBox) then
--			adjustmentForChildrenWithSameLineHeightAndBaseline = self:LogicalTop();
--		else
--			local fontMetrics = self:Renderer():Style(self.firstLine):FontMetrics();
--			adjustmentForChildrenWithSameLineHeightAndBaseline = maxAscent - fontMetrics:ascent(baselineType)
--		end
        if (self:Parent()) then
            adjustmentForChildrenWithSameLineHeightAndBaseline = adjustmentForChildrenWithSameLineHeightAndBaseline + (self:BoxModelObject():BorderBefore() + self:BoxModelObject():PaddingBefore());
		end
    end

	local curr = self:FirstChild();
	while(curr) do
		echo("while(curr) do")
		echo(curr:BoxName())
		echo(curr:BaselinePosition(baselineType))
		echo({curr:LogicalLeft(), curr:LogicalTop(), curr:LogicalWidth(), curr:LogicalHeight()});
		if (curr:Renderer():IsPositioned()) then
            -- Positioned placeholders don't affect calculations.
		elseif (self:DescendantsHaveSameLineHeightAndBaseline()) then
			echo("22222222222222222222222222222222");
			echo(curr:IsLeaf());
			--curr:SetLogicalTop(curr:LogicalTop() + top);
--			if(curr:IsText() and self:Parent() ~= nil and self:Parent():IsInlineFlowBox()) then
--				curr:AdjustBlockDirectionPosition(adjustmentForChildrenWithSameLineHeightAndBaseline - self:LogicalTop());
--			--elseif(not curr:Renderer():IsInline()) then
--			else
--				curr:AdjustBlockDirectionPosition(adjustmentForChildrenWithSameLineHeightAndBaseline);
--			end

--			if(curr:IsInlineTextBox()) then
--				curr:AdjustBlockDirectionPosition(adjustmentForChildrenWithSameLineHeightAndBaseline);
--			else
--				curr:AdjustBlockDirectionPosition(adjustmentForChildrenWithSameLineHeightAndBaseline - self:LogicalTop());
--			end
--			if(curr:IsInlineFlowBox()) then
--				curr._super.AdjustBlockDirectionPosition(curr, top);
--				adjustmentForChildrenWithSameLineHeightAndBaseline = adjustmentForChildrenWithSameLineHeightAndBaseline - top;
--			end
			if(curr:IsInlineFlowBox()) then
				curr:AdjustBlockDirectionPosition(maxAscent - curr:BaselinePosition(baselineType));
			elseif(curr:IsInlineTextBox()) then
				local fontMetrics = self:Renderer():Style(self.firstLine):FontMetrics();
				curr:AdjustBlockDirectionPosition(maxAscent - fontMetrics:ascent(baselineType));
			else
				--curr:AdjustBlockDirectionPosition(maxAscent - curr:BaselinePosition(baselineType));
			end
			curr:AdjustBlockDirectionPosition(adjustmentForChildrenWithSameLineHeightAndBaseline);
			--self:AdjustBlockDirectionPositionForChild(curr,adjustmentForChildrenWithSameLineHeightAndBaseline);
--			if(curr:IsLeaf()) then
--				curr:AdjustBlockDirectionPosition(adjustmentForChildrenWithSameLineHeightAndBaseline);
--			else
--				curr:AdjustBlockDirectionPosition(top);
--			end
			--curr:AdjustBlockDirectionPositionForChildren(adjustmentForChildrenWithSameLineHeightAndBaseline - curr:LogicalTop());
            
            --continue;
        else
			echo("3333333333333333333333333333333333333333");
			local inlineFlowBox = if_else(curr:IsInlineFlowBox(), curr, nil);
			local childAffectsTopBottomPos = true;
			if (curr:VerticalAlign() == VerticalAlignEnum.TOP) then
				curr:SetLogicalTop(top);
			elseif (curr:VerticalAlign() == VerticalAlignEnum.BOTTOM) then
				curr:SetLogicalTop(top + maxHeight - curr:LineHeight());
			else
				if (not strictMode and inlineFlowBox ~= nil and not inlineFlowBox:HasTextChildren() and not curr:BoxModelObject():HasInlineDirectionBordersOrPadding()
					and not (inlineFlowBox:DescendantsHaveSameLineHeightAndBaseline() and inlineFlowBox:HasTextDescendants())) then
					childAffectsTopBottomPos = false;
				end
				
				
				local posAdjust = maxAscent - curr:BaselinePosition(baselineType);
--				if (curr:IsText()) then
--					local fontMetrics = curr:Renderer():Style(self.firstLine):FontMetrics();
--					posAdjust = maxAscent - fontMetrics:ascent(baselineType);
--					echo(fontMetrics:ascent(baselineType));
--				end

--				if (curr:IsInlineFlowBox()) then
--					echo(curr:Renderer():Style():ComputedLineHeight())
--					posAdjust = maxAscent - curr:Renderer():Style():ComputedLineHeight() / 2;
--				end
--				if(curr:IsText() and self:Parent() and self:Parent():IsInlineFlowBox()) then
--					curr:SetLogicalTop(curr:LogicalTop() + posAdjust);
--				else
--					curr:SetLogicalTop(curr:LogicalTop() + top + posAdjust);
--				end
				echo("55555555555555555");
				curr:SetLogicalTop(curr:LogicalTop() + top + posAdjust);
			end
        
			local newLogicalTop = curr:LogicalTop();
			local newLogicalTopIncludingMargins = newLogicalTop;
			local boxHeight = curr:LogicalHeight();
			local boxHeightIncludingMargins = boxHeight;
			if (curr:IsText() or curr:IsInlineFlowBox()) then
				--local fontAscent = curr:Renderer():Style():FontAscent(baselineType);
				--const FontMetrics& fontMetrics = curr->renderer()->style(m_firstLine)->fontMetrics();
				--newLogicalTop += curr->baselinePosition(baselineType) - fontMetrics.ascent(baselineType);
				local fontMetrics = curr:Renderer():Style(self.firstLine):FontMetrics();
				newLogicalTop = newLogicalTop + curr:BaselinePosition(baselineType) - fontMetrics:ascent(baselineType);
--				if(curr:IsText() and not self:IsRootInlineBox()) then
--					newLogicalTop = newLogicalTop - top;
--				end

--				if(curr:IsText()) then
--					if(self:IsRootInlineBox()) then
--						newLogicalTop = newLogicalTop + curr:BaselinePosition(baselineType) - fontMetrics:ascent(baselineType);
--					else
--						newLogicalTop = curr:BaselinePosition(baselineType) - fontMetrics:ascent(baselineType);
--					end
--					
--				end
				--newLogicalTop = newLogicalTop + curr:BaselinePosition(baselineType) - fontMetrics:ascent(baselineType);
				if (curr:IsInlineFlowBox()) then
					local boxObject = curr:Renderer():ToRenderBoxModelObject();
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
            self:FlipLinesInBlockDirection(lineTopIncludingMargins, lineBottomIncludingMargins);
		end
    end

	return lineTop, lineBottom, setLineTop, lineTopIncludingMargins, lineBottomIncludingMargins, hasAnnotationsBefore, hasAnnotationsAfter;
end
--]]

--void InlineFlowBox::flipLinesInBlockDirection(LayoutUnit lineTop, LayoutUnit lineBottom)
function InlineFlowBox:FlipLinesInBlockDirection(lineTop, lineBottom)
	echo("InlineFlowBox:FlipLinesInBlockDirection");
    -- Flip the box on the line such that the top is now relative to the lineBottom instead of the lineTop.
    self:SetLogicalTop(lineBottom - (self:LogicalTop() - lineTop) - self:LogicalHeight());
    
	local curr = self:FirstChild();
	while(curr) do
		if (curr:Renderer():IsPositioned()) then
            --continue; // Positioned placeholders aren't affected here.
        else
			if (curr:IsInlineFlowBox()) then
				curr:FlipLinesInBlockDirection(lineTop, lineBottom);
			else
				curr:SetLogicalTop(lineBottom - (curr:LogicalTop() - lineTop) - curr:LogicalHeight());
			end
		end

		curr = curr:NextOnLine();
	end
end

--void InlineFlowBox::computeOverflow(LayoutUnit lineTop, LayoutUnit lineBottom, GlyphOverflowAndFallbackFontsMap& textBoxDataMap)
function InlineFlowBox:ComputeOverflow(lineTop, lineBottom, textBoxDataMap)
    -- If we know we have no overflow, we can just bail.
    if (self:KnownToHaveNoOverflow()) then
        return;
	end
    -- Visual overflow just includes overflow for stuff we need to repaint ourselves.  Self-painting layers are ignored.
    -- Layout overflow is used to determine scrolling extent, so it still includes child layers and also factors in
    -- transforms, relative positioning, etc.
    local logicalLayoutOverflow = self:LogicalFrameRectIncludingLineHeight(lineTop, lineBottom);
    local logicalVisualOverflow = logicalLayoutOverflow:clone();
  
    --addBoxShadowVisualOverflow(logicalVisualOverflow);
    --addBorderOutsetVisualOverflow(logicalVisualOverflow);

	local curr = self:FirstChild();
	while(curr) do
		if (curr:Renderer():IsPositioned()) then
            -- continue; // Positioned placeholders don't affect calculations.
		else
			if (curr:Renderer():IsText()) then
				local text = curr:ToInlineTextBox();
				local rt = text:Renderer():ToRenderText();
				if (rt:IsBR()) then
					--continue;
				else
					local textBoxOverflow = text:LogicalFrameRect();
					self:AddTextBoxVisualOverflow(text, textBoxDataMap, textBoxOverflow);
					logicalVisualOverflow:Unite(textBoxOverflow);
				end
			elseif (curr:Renderer():IsLayoutInline()) then
				local flow = curr:ToInlineFlowBox();
				flow:ComputeOverflow(lineTop, lineBottom, textBoxDataMap);
				if (not flow:BoxModelObject():HasSelfPaintingLayer()) then
					logicalVisualOverflow:Unite(flow:LogicalVisualOverflowRect(lineTop, lineBottom));
				end
				local childLayoutOverflow = flow:LogicalLayoutOverflowRect(lineTop, lineBottom);
				childLayoutOverflow:Move(flow:BoxModelObject():RelativePositionLogicalOffset());
				logicalLayoutOverflow:Unite(childLayoutOverflow);
			else
				self:AddReplacedChildOverflow(curr, logicalLayoutOverflow, logicalVisualOverflow);	
			end
		end
		curr = curr:NextOnLine();
	end
    
    self:SetOverflowFromLogicalRects(logicalLayoutOverflow, logicalVisualOverflow, lineTop, lineBottom);
end

function InlineFlowBox:RoundedFrameRect()
    -- Begin by snapping the x and y coordinates to the nearest pixel.
    local snappedX = math.floor(self:X() + 0.5);
    local snappedY = math.floor(self:Y() + 0.5);
    
    local snappedMaxX = math.floor(self:X() + self:Width() + 0.5);
    local snappedMaxY = math.floor(self:Y() + self:Height() + 0.5);
    
    return IntRect:new(snappedX, snappedY, snappedMaxX - snappedX, snappedMaxY - snappedY);
end

--void InlineFlowBox::constrainToLineTopAndBottomIfNeeded(LayoutRect& rect)
function InlineFlowBox:ConstrainToLineTopAndBottomIfNeeded(rect)
	local noQuirksMode = self:Renderer():Document():InNoQuirksMode();
    if (not noQuirksMode and not self:HasTextChildren() and not (self:DescendantsHaveSameLineHeightAndBaseline() and self:HasTextDescendants())) then
        local rootBox = self:Root();
        local logicalTop = if_else(self:IsHorizontal(), rect:Y(), rect:X());
        local logicalHeight = if_else(self:IsHorizontal(), rect:Height(), rect:Width());
        local bottom = math.min(rootBox:LineBottom(), logicalTop + logicalHeight);
        logicalTop = math.max(rootBox:LineTop(), logicalTop);
        logicalHeight = bottom - logicalTop;
        if (self:IsHorizontal()) then
            rect:SetY(logicalTop);
            rect:SetHeight(logicalHeight);
        else
            rect:SetX(logicalTop);
            rect:SetWidth(logicalHeight);
        end
    end
end


function InlineFlowBox:PaintBoxDecorations(paintInfo, paintOffset)
	if (not paintInfo:ShouldPaintWithinRoot(self:Renderer()) or self:Renderer():Style():Visibility() ~= VisibilityEnum.VISIBLE) then
        return;
	end

	-- Pixel snap background/border painting.
    local frameRect = self:RoundedFrameRect();
	echo("frameRect")
	echo(frameRect)
	self:ConstrainToLineTopAndBottomIfNeeded(frameRect);

	-- Move x/y to our coordinates.
    local localRect = frameRect:clone();
	echo("localRect");
	echo(localRect)
    localRect = self:FlipForWritingMode(localRect);
    --local adjustedPaintoffset = paintOffset + localRect:Location();
	echo(localRect)
	local adjustedPaintoffset = localRect:Location();
	if(self:IsRootInlineBox() and not self:Renderer():IsAnonymous()) then
		adjustedPaintoffset = adjustedPaintoffset + paintOffset;
	end

	local styleToUse = self:Renderer():Style(self.firstLine);

    --if ((not self:Parent() and self.firstLine and styleToUse ~= self:Renderer():Style()) or (self:Parent() and self:Renderer():HasBoxDecorations())) then
	--  or self:Renderer():IsAnonymous()
	--if ((not self:Parent() and self.firstLine and styleToUse ~= self:Renderer():Style()) or self:Parent()) then
	if(true) then
		local paintRect = LayoutRect:new(adjustedPaintoffset, frameRect:Size());
        
        self:PaintFillLayers(paintInfo, paintRect);
	end
end

function InlineFlowBox:PaintFillLayers(paintInfo, rect)
	self:PaintFillLayer(paintInfo, rect);
end

function InlineFlowBox:GetControl()
	echo("InlineFlowBox:GetControl()")
	if(self.control) then
		return self.control;
	end
	return self:Renderer():GetControl();
end

function InlineFlowBox:GetParentControl()
echo("InlineFlowBox:GetParentControl()")
	if(self:Parent()) then
		return self:Parent():GetControl()
	end
	return self:Renderer():GetControl();
end

function InlineFlowBox:PaintFillLayer(paintInfo, rect)
	echo("InlineFlowBox:PaintFillLayer")
	self:Renderer():PrintNodeInfo();
	local control;
	local control = self:GetParentControl();
	if(control:PageElement()) then
		control:PageElement():PrintNodeInfo();
	end
	if(control) then
		local x, y, w, h = rect:X(), rect:Y(), rect:Width(), rect:Height();
		echo({x, y, w, h});
		if(self.control) then
			self.control:setGeometry(x, y, w, h);
		else
			local _this = Rectangle:new():init(control);
			_this:setGeometry(x, y, w, h);
			local style = if_else(self:IsRootInlineBox(), ComputedStyle.CreateDefaultStyle(), self:Renderer():Style())
			_this:ApplyCss(style);
			self.control = _this;
		end
	end
	--self:BoxModelObject():PaintFillLayerExtended(paintInfo, rect);
end

--void paint(PaintInfo&, const LayoutPoint&, LayoutUnit lineTop, LayoutUnit lineBottom)
function InlineFlowBox:Paint(paintInfo, paintOffset, lineTop, lineBottom)
	local overflowRect = self:VisualOverflowRect(lineTop, lineBottom);
	echo("InlineFlowBox:Paint");
	echo(self:BoxName());
	echo(overflowRect);
	echo(self:RoundedFrameRect())
	echo(paintOffset)
    --overflowRect.inflate(renderer()->maximalOutlineSize(paintInfo.phase));
    --flipForWritingMode(overflowRect);
    --overflowRect.moveBy(paintOffset);
    
--    if (!paintInfo.rect.intersects(overflowRect))
--        return;


	self:PaintBoxDecorations(paintInfo, paintOffset);

	--PaintInfo childInfo(paintInfo);
	local childInfo = paintInfo;

	-- Paint our children.
	local curr = self:FirstChild();
	while(curr) do
		if (curr:Renderer():IsText() or not curr:BoxModelObject():HasSelfPaintingLayer()) then
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

--FloatRect logicalFrameRectIncludingLineHeight(LayoutUnit lineTop, LayoutUnit lineBottom) const
function InlineFlowBox:LogicalFrameRectIncludingLineHeight(lineTop, lineBottom)
    return Rect:new(self:LogicalLeft(), lineTop, self:LogicalWidth(), lineBottom - lineTop);
end

-- Line visual and layout overflow are in the coordinate space of the block.  This means that they aren't purely physical directions.
-- For horizontal-tb and vertical-lr they will match physical directions, but for horizontal-bt and vertical-rl, the top/bottom and left/right
-- respectively are flipped when compared to their physical counterparts.  For example minX is on the left in vertical-lr, but it is on the right in vertical-rl.
--LayoutRect layoutOverflowRect(LayoutUnit lineTop, LayoutUnit lineBottom) const
function InlineFlowBox:LayoutOverflowRect(lineTop, lineBottom)
	
	if (self.overflow) then
		echo("InlineFlowBox:LayoutOverflowRect")
        return self.overflow:LayoutOverflowRect();
	end
	return self:FrameRectIncludingLineHeight(lineTop, lineBottom)
end

function InlineFlowBox:LogicalLeftLayoutOverflow()
	if (self.overflow) then
        return if_else(self:IsHorizontal(), self.overflow:MinXLayoutOverflow(), self.overflow:MinYLayoutOverflow());
	end
	return self:LogicalLeft();
end

function InlineFlowBox:LogicalRightLayoutOverflow()
	if (self.overflow) then
        return if_else(self:IsHorizontal(), self.overflow:MaxXLayoutOverflow(), self.overflow:MaxYLayoutOverflow());
	end
	return self:LogicalRight();
end

function InlineFlowBox:LogicalTopLayoutOverflow(lineTop)
	if (self.overflow) then
        return if_else(self:IsHorizontal(), self.overflow:MinYLayoutOverflow(), self.overflow:MinXLayoutOverflow());
	end
    return lineTop;
end

function InlineFlowBox:LogicalBottomLayoutOverflow(lineBottom)
	if (self.overflow) then
        return if_else(self:IsHorizontal(), self.overflow:MaxYLayoutOverflow(), self.overflow:MaxXLayoutOverflow());
	end
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
	if (self.overflow) then
        return self.overflow:VisualOverflowRect();
	end
	return self:FrameRectIncludingLineHeight(lineTop, lineBottom);
end

function InlineFlowBox:LogicalLeftVisualOverflow()
	if (self.overflow) then
        return if_else(self:IsHorizontal(), self.overflow:MinXVisualOverflow(), self.overflow:MinYVisualOverflow());
	end
	return self:LogicalLeft();
end

function InlineFlowBox:LogicalRightVisualOverflow()
	if (self.overflow) then
        return if_else(self:IsHorizontal(), self.overflow:MaxXVisualOverflow(), self.overflow:MaxYVisualOverflow());
	end
	return self:LogicalRight();
end

function InlineFlowBox:LogicalTopVisualOverflow(lineTop)
	if (self.overflow) then
        return if_else(self:IsHorizontal(), self.overflow:MinYVisualOverflow(), self.overflow:MinXVisualOverflow());
	end
    return lineTop;
end

function InlineFlowBox:LogicalBottomVisualOverflow(lineBottom)
    if (self.overflow) then
        return if_else(self:IsHorizontal(), self.overflow:MaxYVisualOverflow(), self.overflow:MaxXVisualOverflow());
	end
    return lineBottom;
end

function InlineFlowBox:LogicalVisualOverflowRect(lineTop, lineBottom)
    local result = self:VisualOverflowRect(lineTop, lineBottom);
    if (not self:Renderer():IsHorizontalWritingMode()) then
        result = result:TransposedRect();
	end
    return result;
end

function InlineFlowBox:HasTextChildren() 
	return self.hasTextChildren;
end

function InlineFlowBox:HasTextDescendants()
	return self.hasTextDescendants;
end

function InlineFlowBox:ExtractLine()
    if (not self.extracted) then
        self:ExtractLineBoxFromRenderObject();
	end
	local child = self:FirstChild();
	while(child) do
		child:ExtractLine();

		child = child:NextOnLine();
	end
end

function InlineFlowBox:AttachLine()
    if (self.extracted) then
        self:AttachLineBoxToRenderObject();
	end
	local child = self:FirstChild();
	while(child) do
		child:AttachLine();

		child = child:NextOnLine();
	end
end

function InlineFlowBox:AttachLineBoxToRenderObject()
	if(self:Renderer()) then
		self:Renderer():ToRenderInline():LineBoxes():AttachLineBox(self);
	end
end

function InlineFlowBox:ExtractLineBoxFromRenderObject()
	if(self:Renderer()) then
		self:Renderer():ToRenderInline():LineBoxes():ExtractLineBox(self);
	end
end

function InlineFlowBox:AttachLine()
    if (self.extracted) then
        self:AttachLineBoxToRenderObject();
	end

	local child = self:FirstChild();
	while(child) do
		child:AttachLine();

		child = child:NextOnLine();
	end
end

--void InlineFlowBox::setOverflowFromLogicalRects(const LayoutRect& logicalLayoutOverflow, const LayoutRect& logicalVisualOverflow, LayoutUnit lineTop, LayoutUnit lineBottom)
function InlineFlowBox:SetOverflowFromLogicalRects(logicalLayoutOverflow, logicalVisualOverflow, lineTop, lineBottom)
    local layoutOverflow = if_else(self:IsHorizontal(), logicalLayoutOverflow, logicalLayoutOverflow:TransposedRect());
    self:SetLayoutOverflow(layoutOverflow, lineTop, lineBottom);
    
    local visualOverflow = if_else(self:IsHorizontal(), logicalVisualOverflow, logicalVisualOverflow:TransposedRect());
    self:SetVisualOverflow(visualOverflow, lineTop, lineBottom);
end

--void InlineFlowBox::setLayoutOverflow(const LayoutRect& rect, LayoutUnit lineTop, LayoutUnit lineBottom)
function InlineFlowBox:SetLayoutOverflow(rect, lineTop, lineBottom)
    local frameBox = self:FrameRectIncludingLineHeight(lineTop, lineBottom);
    if (frameBox:Contains(rect) or rect:IsEmpty()) then
        return;
	end

    if (not self.overflow) then
        self.overflow = LayoutOverflow:new():init(frameBox, frameBox);
	end
    
    self.overflow:SetLayoutOverflow(rect);
end

--void InlineFlowBox::setVisualOverflow(const LayoutRect& rect, LayoutUnit lineTop, LayoutUnit lineBottom)
function InlineFlowBox:SetVisualOverflow(rect, lineTop, lineBottom)
    local frameBox = self:FrameRectIncludingLineHeight(lineTop, lineBottom);
    if (frameBox:Contains(rect) or rect:IsEmpty()) then
        return;
	end
        
    if (not self.overflow) then
        self.overflow = LayoutOverflow:new():init(frameBox, frameBox);
	end
    
    self.overflow:SetVisualOverflow(rect);
end

function InlineFlowBox:AdjustPositionForChildren(dx, dy)
	local child = self:FirstChild();
	while(child) do
		child:AdjustPosition(dx, dy);
		child = child:NextOnLine();
	end
end

--void InlineFlowBox::adjustPosition(float dx, float dy)
function InlineFlowBox:AdjustPosition(dx, dy)
    InlineFlowBox._super.AdjustPosition(self, dx, dy);
	local child = self:FirstChild();
	while(child) do
		child:AdjustPosition(dx, dy);
		child = child:NextOnLine();
	end

    if (self.overflow) then
        self.overflow:Move(dx, dy); -- FIXME: Rounding error here since overflow was pixel snapped, but nobody other than list markers passes non-integral values here.
	end
end

--inline void InlineFlowBox::addTextBoxVisualOverflow(InlineTextBox* textBox, GlyphOverflowAndFallbackFontsMap& textBoxDataMap, LayoutRect& logicalVisualOverflow)
function InlineFlowBox:AddTextBoxVisualOverflow(textBox, textBoxDataMap, logicalVisualOverflow)
    if (textBox:KnownToHaveNoOverflow()) then
        return;
	end

--    RenderStyle* style = textBox->renderer()->style(m_firstLine);
--    
--    GlyphOverflowAndFallbackFontsMap::iterator it = textBoxDataMap.find(textBox);
--    GlyphOverflow* glyphOverflow = it == textBoxDataMap.end() ? 0 : &it->second.second;
--    bool isFlippedLine = style->isFlippedLinesWritingMode();
--
--    int topGlyphEdge = glyphOverflow ? (isFlippedLine ? glyphOverflow->bottom : glyphOverflow->top) : 0;
--    int bottomGlyphEdge = glyphOverflow ? (isFlippedLine ? glyphOverflow->top : glyphOverflow->bottom) : 0;
--    int leftGlyphEdge = glyphOverflow ? glyphOverflow->left : 0;
--    int rightGlyphEdge = glyphOverflow ? glyphOverflow->right : 0;
--
--    int strokeOverflow = static_cast<int>(ceilf(style->textStrokeWidth() / 2.0f));
--    int topGlyphOverflow = -strokeOverflow - topGlyphEdge;
--    int bottomGlyphOverflow = strokeOverflow + bottomGlyphEdge;
--    int leftGlyphOverflow = -strokeOverflow - leftGlyphEdge;
--    int rightGlyphOverflow = strokeOverflow + rightGlyphEdge;
--
--    TextEmphasisPosition emphasisMarkPosition;
--    if (style->textEmphasisMark() != TextEmphasisMarkNone && textBox->getEmphasisMarkPosition(style, emphasisMarkPosition)) {
--        int emphasisMarkHeight = style->font().emphasisMarkHeight(style->textEmphasisMarkString());
--        if ((emphasisMarkPosition == TextEmphasisPositionOver) == (!style->isFlippedLinesWritingMode()))
--            topGlyphOverflow = min(topGlyphOverflow, -emphasisMarkHeight);
--        else
--            bottomGlyphOverflow = max(bottomGlyphOverflow, emphasisMarkHeight);
--    }
--
--    // If letter-spacing is negative, we should factor that into right layout overflow. (Even in RTL, letter-spacing is
--    // applied to the right, so this is not an issue with left overflow.
--    rightGlyphOverflow -= min(0, (int)style->font().letterSpacing());
--
--    LayoutUnit textShadowLogicalTop;
--    LayoutUnit textShadowLogicalBottom;
--    style->getTextShadowBlockDirectionExtent(textShadowLogicalTop, textShadowLogicalBottom);
--    
--    LayoutUnit childOverflowLogicalTop = min<LayoutUnit>(textShadowLogicalTop + topGlyphOverflow, topGlyphOverflow);
--    LayoutUnit childOverflowLogicalBottom = max<LayoutUnit>(textShadowLogicalBottom + bottomGlyphOverflow, bottomGlyphOverflow);
--   
--    LayoutUnit textShadowLogicalLeft;
--    LayoutUnit textShadowLogicalRight;
--    style->getTextShadowInlineDirectionExtent(textShadowLogicalLeft, textShadowLogicalRight);
--   
--    LayoutUnit childOverflowLogicalLeft = min<LayoutUnit>(textShadowLogicalLeft + leftGlyphOverflow, leftGlyphOverflow);
--    LayoutUnit childOverflowLogicalRight = max<LayoutUnit>(textShadowLogicalRight + rightGlyphOverflow, rightGlyphOverflow);

	local childOverflowLogicalTop, childOverflowLogicalBottom, childOverflowLogicalLeft, childOverflowLogicalRight = 0, 0, 0, 0;

    local logicalTopVisualOverflow = math.min(textBox:LogicalTop() + childOverflowLogicalTop, logicalVisualOverflow:Y());
    local logicalBottomVisualOverflow = math.max(textBox:LogicalBottom() + childOverflowLogicalBottom, logicalVisualOverflow:MaxY());
    local logicalLeftVisualOverflow = math.min(textBox:PixelSnappedLogicalLeft() + childOverflowLogicalLeft, logicalVisualOverflow:X());
    local logicalRightVisualOverflow = math.max(textBox:PixelSnappedLogicalRight() + childOverflowLogicalRight, logicalVisualOverflow:MaxX());
    
    logicalVisualOverflow:Reset(logicalLeftVisualOverflow, logicalTopVisualOverflow,
                                       logicalRightVisualOverflow - logicalLeftVisualOverflow, logicalBottomVisualOverflow - logicalTopVisualOverflow);
                                    
    textBox:SetLogicalOverflowRect(logicalVisualOverflow);
end

--inline void InlineFlowBox::addReplacedChildOverflow(const InlineBox* inlineBox, LayoutRect& logicalLayoutOverflow, LayoutRect& logicalVisualOverflow)
function InlineFlowBox:AddReplacedChildOverflow(inlineBox, logicalLayoutOverflow, logicalVisualOverflow)
    local box = inlineBox:Renderer():ToRenderBox();
    
    -- Visual overflow only propagates if the box doesn't have a self-painting layer.  This rectangle does not include
    -- transforms or relative positioning (since those objects always have self-painting layers), but it does need to be adjusted
    -- for writing-mode differences.
    if (not box:HasSelfPaintingLayer()) then
        local childLogicalVisualOverflow = box:LogicalVisualOverflowRectForPropagation(self:Renderer():Style());
        childLogicalVisualOverflow:Move(inlineBox:LogicalLeft(), inlineBox:LogicalTop());
        logicalVisualOverflow:Unite(childLogicalVisualOverflow);
    end

    -- Layout overflow internal to the child box only propagates if the child box doesn't have overflow clip set.
    -- Otherwise the child border box propagates as layout overflow.  This rectangle must include transforms and relative positioning
    -- and be adjusted for writing-mode differences.
    local childLogicalLayoutOverflow = box:LogicalLayoutOverflowRectForPropagation(self:Renderer():Style());
    childLogicalLayoutOverflow:Move(inlineBox:LogicalLeft(), inlineBox:LogicalTop());
    logicalLayoutOverflow:Unite(childLogicalLayoutOverflow);
end