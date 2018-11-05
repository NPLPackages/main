--[[
Title: 
Author(s): LiPeng
Date: 2018/3/12
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/RootInlineBox.lua");
local RootInlineBox = commonlib.gettable("System.Windows.mcml.layout.RootInlineBox");
local TrailingFloatsRootInlineBox = commonlib.gettable("System.Windows.mcml.layout.TrailingFloatsRootInlineBox");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/InlineFlowBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/text/BidiResolver.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local BidiStatus = commonlib.gettable("System.Windows.mcml.platform.text.BidiStatus");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");
local RootInlineBox = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.InlineFlowBox"), commonlib.gettable("System.Windows.mcml.layout.RootInlineBox"));

local LineBoxContainEnum = ComputedStyleConstants.LineBoxContainEnum;
local VerticalAlignEnum = ComputedStyleConstants.VerticalAlignEnum;

function RootInlineBox:ctor()
	-- This folds into the padding at the end of InlineFlowBox on 64-bit.
    self.lineBreakPos = 0;

    -- Where this line ended.  The exact object and the position within that object are stored so that
    -- we can create an InlineIterator beginning just after the end of this line.
    self.lineBreakObj = nil;
    --RefPtr<BidiContext> self.lineBreakContext;
	self.lineBreakContext = nil;

    self.lineTop = 0;
    self.lineBottom = 0;

    self.lineTopWithLeading = 0;
    self.lineBottomWithLeading = 0;

    self.paginationStrut = 0;
    self.paginatedLineWidth = 0;

    -- Floats hanging off the line are pushed into this vector during layout. It is only
    -- good for as long as the line has not been marked dirty.
    --OwnPtr<Vector<RenderBox*> > self.floats;
	--self.floats = commonlib.vector:new();
	self.floats = nil;
end

function RootInlineBox:BoxName()
    return "RootInlineBox";
end

function RootInlineBox:IsRootInlineBox()
	return true;
end

function RootInlineBox:NextRootBox()
	return self.nextLineBox;
end

function RootInlineBox:PrevRootBox()
	return self.prevLineBox;
end

function RootInlineBox:AdjustPosition(dx, dy)

end

function RootInlineBox:LineTop()
	return self.lineTop;
end

function RootInlineBox:LineBottom()
	return self.lineBottom;
end

function RootInlineBox:LineTopWithLeading()
	return self.lineTopWithLeading;
end

function RootInlineBox:LineBottomWithLeading()
	return self.lineBottomWithLeading;
end
    
function RootInlineBox:PaginationStrut()
	return self.paginationStrut;
end

function RootInlineBox:SetPaginationStrut(s)
	self.paginationStrut = s;
end

function RootInlineBox:PaginatedLineWidth()
	return self.paginatedLineWidth;
end

function RootInlineBox:SetPaginatedLineWidth(width)
	self.paginatedLineWidth = width;
end

function RootInlineBox:LineBreakObj()
	return self.lineBreakObj;
end

function RootInlineBox:LineBreakPos()
	return self.lineBreakPos;
end

function RootInlineBox:SetLineBreakPos(pos)
	self.lineBreakPos = pos;
end

function RootInlineBox:EndsWithBreak()
	return self.endsWithBreak;
end

function RootInlineBox:SetEndsWithBreak(b)
	self.endsWithBreak = b;
end

function RootInlineBox:RendererLineBoxes()
	return self:Block():LineBoxes();
end

function RootInlineBox:Block()
    return self:Renderer();
end

function RootInlineBox:SetLineTopBottomPositions(top, bottom, topWithLeading, bottomWithLeading)
    self.lineTop = top; 
    self.lineBottom = bottom;
    self.lineTopWithLeading = topWithLeading;
    self.lineBottomWithLeading = bottomWithLeading;
end

function RootInlineBox:HasEllipsisBox()
	return self.hasEllipsisBoxOrHyphen;
end

function RootInlineBox:SetHasEllipsisBox(hasEllipsisBox) 
	self.hasEllipsisBoxOrHyphen = hasEllipsisBox;
end


--@param arena:RenderArena object
function RootInlineBox:DetachEllipsisBox(arena)
    if (self:HasEllipsisBox()) then
--        EllipsisBox* box = gEllipsisBoxMap->take(this);
--        box->setParent(0);
--        box->destroy(arena);
--        setHasEllipsisBox(false);
    end
end
--@param arena:RenderArena object
function RootInlineBox:Destroy(arena)
	self:DetachEllipsisBox(arena);
	RootInlineBox._super.Destroy(self, renderArena)
end

function RootInlineBox:SetLineBreakInfo(obj, breakPos, status)
    self.lineBreakObj = obj;
    self.lineBreakPos = breakPos;
    self.lineBreakBidiStatusEor = status.eor;
    self.lineBreakBidiStatusLastStrong = status.lastStrong;
    self.lineBreakBidiStatusLast = status.last;
    self.lineBreakContext = status.context;
end

function RootInlineBox:FitsToGlyphs()
    -- FIXME: We can't fit to glyphs yet for vertical text, since the bounds returned are garbage.
    -- LineBoxContain lineBoxContain = renderer()->style()->lineBoxContain();
    -- return isHorizontal() && (lineBoxContain & LineBoxContainGlyphs);
	local lineBoxContain = self:Renderer():Style():LineBoxContain();
	return self:IsHorizontal() and mathlib.bit.band(lineBoxContain, LineBoxContainEnum.LineBoxContainGlyphs);
end

function RootInlineBox:BeforeAnnotationsAdjustment()
    local result = 0;

--    if (!renderer()->style()->isFlippedLinesWritingMode()) {
--        // Annotations under the previous line may push us down.
--        if (prevRootBox() && prevRootBox()->hasAnnotationsAfter())
--            result = prevRootBox()->computeUnderAnnotationAdjustment(lineTop());
--
--        if (!hasAnnotationsBefore())
--            return result;
--
--        // Annotations over this line may push us further down.
--        int highestAllowedPosition = prevRootBox() ? min(prevRootBox()->lineBottom(), lineTop()) + result : block()->borderBefore();
--        result = computeOverAnnotationAdjustment(highestAllowedPosition);
--    else
--        // Annotations under this line may push us up.
--        if (hasAnnotationsBefore())
--            result = computeUnderAnnotationAdjustment(prevRootBox() ? prevRootBox()->lineBottom() : block()->borderBefore());
--
--        if (!prevRootBox() || !prevRootBox()->hasAnnotationsAfter())
--            return result;
--
--        // We have to compute the expansion for annotations over the previous line to see how much we should move.
--        int lowestAllowedPosition = max(prevRootBox()->lineBottom(), lineTop()) - result;
--        result = prevRootBox()->computeOverAnnotationAdjustment(lowestAllowedPosition);
--    end

    return result;
end

function RootInlineBox:SimplyAlignBoxesInBlockDirection(heightOfBlock, textBoxDataMap, verticalPositionCache)
	if (self:IsSVGRootInlineBox()) then
        return 0;
	end
end

--LayoutUnit RootInlineBox::alignBoxesInBlockDirection(LayoutUnit heightOfBlock, GlyphOverflowAndFallbackFontsMap& textBoxDataMap, VerticalPositionCache& verticalPositionCache)
function RootInlineBox:AlignBoxesInBlockDirection(heightOfBlock, textBoxDataMap, verticalPositionCache)
	if (self:IsSVGRootInlineBox()) then
        return 0;
	end

	local maxPositionTop = 0;
    local maxPositionBottom = 0;
    local maxAscent = 0;
    local maxDescent = 0;
    local setMaxAscent = false;
    local setMaxDescent = false;

--	// Figure out if we're in no-quirks mode.
	local noQuirksMode = self:Renderer():Document():InNoQuirksMode();
	--local noQuirksMode = false;

	self.baselineType = if_else(self:RequiresIdeographicBaseline(textBoxDataMap), "IdeographicBaseline", "AlphabeticBaseline");

	maxPositionTop, maxPositionBottom, maxAscent, maxDescent, setMaxAscent, setMaxDescent = self:ComputeLogicalBoxHeights(self, maxPositionTop, maxPositionBottom, maxAscent, maxDescent, setMaxAscent, setMaxDescent, noQuirksMode,
                             textBoxDataMap, self:BaselineType(), verticalPositionCache);
	if (maxAscent + maxDescent < math.max(maxPositionTop, maxPositionBottom)) then
        maxAscent, maxDescent = self:AdjustMaxAscentAndDescent(maxAscent, maxDescent, maxPositionTop, maxPositionBottom);
	end
	local maxHeight = maxAscent + maxDescent;
    local lineTop = heightOfBlock;
    local lineBottom = heightOfBlock;
    local lineTopIncludingMargins = heightOfBlock;
    local lineBottomIncludingMargins = heightOfBlock;
    local setLineTop = false;
    local hasAnnotationsBefore = false;
    local hasAnnotationsAfter = false;

	lineTop, lineBottom, setLineTop, lineTopIncludingMargins, lineBottomIncludingMargins, hasAnnotationsBefore, hasAnnotationsAfter = self:PlaceBoxesInBlockDirection(heightOfBlock, maxHeight, maxAscent, noQuirksMode, lineTop, lineBottom, setLineTop,
                               lineTopIncludingMargins, lineBottomIncludingMargins, hasAnnotationsBefore, hasAnnotationsAfter, self:BaselineType());
	self.hasAnnotationsBefore = hasAnnotationsBefore;
    self.hasAnnotationsAfter = hasAnnotationsAfter;

	self:SetLineTopBottomPositions(lineTop, lineBottom, heightOfBlock, heightOfBlock + maxHeight);
    self:SetPaginatedLineWidth(self:Block():AvailableLogicalWidthForContent(heightOfBlock));

	local annotationsAdjustment = self:BeforeAnnotationsAdjustment();
    if (annotationsAdjustment ~= 0) then
        -- FIXME: Need to handle pagination here. We might have to move to the next page/column as a result of the ruby expansion.
        self:AdjustBlockDirectionPosition(annotationsAdjustment);
        heightOfBlock = heightOfBlock + annotationsAdjustment;
    end
    return heightOfBlock + maxHeight;
end

function RootInlineBox:BaselineType()
	return self.baselineType;
end

--static void setAscentAndDescent(LayoutUnit& ascent, LayoutUnit& descent, LayoutUnit newAscent, LayoutUnit newDescent, bool& ascentDescentSet)
local function setAscentAndDescent(ascent, descent, newAscent, newDescent, ascentDescentSet)
    if (not ascentDescentSet) then
        ascentDescentSet = true;
        ascent = newAscent;
        descent = newDescent;
    else
        ascent = math.max(ascent, newAscent);
        descent = math.max(descent, newDescent);
    end
	return ascent, descent, ascentDescentSet;
end

--void RootInlineBox::ascentAndDescentForBox(InlineBox* box, GlyphOverflowAndFallbackFontsMap& textBoxDataMap, LayoutUnit& ascent, LayoutUnit& descent,
--                                           bool& affectsAscent, bool& affectsDescent) const
function RootInlineBox:AscentAndDescentForBox(box, textBoxDataMap, ascent, descent, affectsAscent, affectsDescent)
	local ascentDescentSet = false;

--    -- Replaced boxes will return 0 for the line-height if line-box-contain says they are
--    -- not to be included.
    if (box:Renderer():IsReplaced()) then
		local lineBoxContain = self:Renderer():Style(self.firstLine):LineBoxContain();
        if (mathlib.bit.band(lineBoxContain, LineBoxContainEnum.LineBoxContainReplaced)) then
			
            ascent = box:BaselinePosition(self:BaselineType());
            descent = box:LineHeight() - ascent;
            
            -- Replaced elements always affect both the ascent and descent.
            affectsAscent = true;
            affectsDescent = true;
        end
        return ascent, descent, affectsAscent, affectsDescent;
    end

--    Vector<const SimpleFontData*>* usedFonts = 0;
--    GlyphOverflow* glyphOverflow = 0;
	local usedFonts = nil;
    local glyphOverflow = nil;
    if (box:IsText()) then
		usedFonts = textBoxDataMap[box];
        --GlyphOverflowAndFallbackFontsMap::iterator it = textBoxDataMap.find(toInlineTextBox(box));
        --usedFonts = it == textBoxDataMap.end() ? 0 : &it->second.first;
        --glyphOverflow = it == textBoxDataMap.end() ? 0 : &it->second.second;
    end

	local includeLeading = self:IncludeLeadingForBox(box);
    local includeFont = self:IncludeFontForBox(box);
    local setUsedFont = false;
    local setUsedFontWithLeading = false;
	if (usedFonts ~= nil and #usedFonts > 0 and (includeFont or (box:Renderer():Style(self.firstLine):LineHeight():IsNegative() and includeLeading))) then
        --usedFonts->append(box->renderer()->style(m_firstLine)->font().primaryFont());
		for i = 1, #usedFonts do
			local fontMetrics = usedFonts[i]:FontMetrics();
            local usedFontAscent = fontMetrics:ascent(self:BaselineType());
            local usedFontDescent = fontMetrics:descent(self:BaselineType());
            local halfLeading = math.floor((fontMetrics:lineSpacing() - fontMetrics:height())/2+0.5);
            local usedFontAscentAndLeading = usedFontAscent + halfLeading;
            local usedFontDescentAndLeading = fontMetrics:lineSpacing() - usedFontAscentAndLeading;
            if (includeFont) then
                ascent, descent, ascentDescentSet = setAscentAndDescent(ascent, descent, usedFontAscent, usedFontDescent, ascentDescentSet);
                setUsedFont = true;
            end
            if (includeLeading) then
                ascent, descent, ascentDescentSet = setAscentAndDescent(ascent, descent, usedFontAscentAndLeading, usedFontDescentAndLeading, ascentDescentSet);
                setUsedFontWithLeading = true;
            end
            if (not affectsAscent) then
                affectsAscent = usedFontAscent - box:LogicalTop() > 0;
			end
            if (not affectsDescent) then
                affectsDescent = usedFontDescent + box:LogicalTop() > 0;
			end
		end
    end

	-- If leading is included for the box, then we compute that box.
    if (includeLeading and not setUsedFontWithLeading) then
        local ascentWithLeading = box:BaselinePosition(self:BaselineType());
        local descentWithLeading = box:LineHeight() - ascentWithLeading;
        ascent, descent, ascentDescentSet = setAscentAndDescent(ascent, descent, ascentWithLeading, descentWithLeading, ascentDescentSet);
        
        -- Examine the font box for inline flows and text boxes to see if any part of it is above the baseline.
        -- If the top of our font box relative to the root box baseline is above the root box baseline, then
        -- we are contributing to the maxAscent value. Descent is similar. If any part of our font box is below
        -- the root box's baseline, then we contribute to the maxDescent value.
        affectsAscent = (ascentWithLeading - box:LogicalTop()) > 0;
        affectsDescent = (descentWithLeading + box:LogicalTop()) > 0; 
    end

	if (self:IncludeFontForBox(box) and not setUsedFont) then
        local fontAscent = box:Renderer():Style(self.firstLine):FontMetrics():ascent();
        local fontDescent = box:Renderer():Style(self.firstLine):FontMetrics():descent();
        ascent, descent, ascentDescentSet = setAscentAndDescent(ascent, descent, fontAscent, fontDescent, ascentDescentSet);
        affectsAscent = fontAscent - box:LogicalTop() > 0;
        affectsDescent = fontDescent + box:LogicalTop() > 0; 
    end

	if (self:IncludeMarginForBox(box)) then
        local ascentWithMargin = box:Renderer():Style(self.firstLine):FontMetrics():ascent();
        local descentWithMargin = box:Renderer():Style(self.firstLine):FontMetrics():descent();
        if (box:Parent() ~= nil and not box:Renderer():IsText()) then
            ascentWithMargin = ascentWithMargin + box:BoxModelObject():BorderBefore() + box:BoxModelObject():PaddingBefore() + box:BoxModelObject():MarginBefore();
            descentWithMargin = descentWithMargin + box:BoxModelObject():BorderAfter() + box:BoxModelObject():PaddingAfter() + box:BoxModelObject():MarginAfter();
        end
        ascent, descent, ascentDescentSet = setAscentAndDescent(ascent, descent, ascentWithMargin, descentWithMargin, ascentDescentSet);
        
        -- Treat like a replaced element, since we're using the margin box.
        affectsAscent = true;
        affectsDescent = true;
    end
	return ascent, descent, affectsAscent, affectsDescent;
end

--bool RootInlineBox::includeLeadingForBox(InlineBox* box) const
function RootInlineBox:IncludeLeadingForBox(box)
    if (box:Renderer():IsReplaced() or (box:Renderer():IsText() and not box:IsText())) then
        return false;
	end

    local lineBoxContain = self:Renderer():Style():LineBoxContain();
	local containInline = mathlib.bit.band(lineBoxContain, LineBoxContainEnum.LineBoxContainInline);
	local containBlock = mathlib.bit.band(lineBoxContain, LineBoxContainEnum.LineBoxContainBlock);
    return containInline ~= 0 or (box == self and containBlock ~= 0);
end

--bool RootInlineBox::includeFontForBox(InlineBox* box) const
function RootInlineBox:IncludeFontForBox(box)
    if (box:Renderer():IsReplaced() or (box:Renderer():IsText() and not box:IsText())) then
        return false;
	end
    
    if (not box:IsText() and box:IsInlineFlowBox() and not box:HasTextChildren()) then
        return false;
	end

    -- For now map "glyphs" to "font" in vertical text mode until the bounds returned by glyphs aren't garbage.
    local lineBoxContain = self:Renderer():Style():LineBoxContain();
	local containFont = mathlib.bit.band(lineBoxContain, LineBoxContainEnum.LineBoxContainFont);
	local containGlyphs = mathlib.bit.band(lineBoxContain, LineBoxContainEnum.LineBoxContainGlyphs);
    return containFont ~= 0 or (not self:IsHorizontal() and containGlyphs ~= 0);
end

function RootInlineBox:IncludeGlyphsForBox(box)
    if (box:Renderer():IsReplaced() or (box:Renderer():IsText() and not box:IsText())) then
        return false;
	end
    
    if (not box:IsText() and box:IsInlineFlowBox() and not box:HasTextChildren()) then
        return false;
	end

    -- FIXME: We can't fit to glyphs yet for vertical text, since the bounds returned are garbage.
    local lineBoxContain = self:Renderer():Style():LineBoxContain();
	local containGlyphs = mathlib.bit.band(lineBoxContain, LineBoxContainEnum.LineBoxContainGlyphs);
    return self:IsHorizontal() and containGlyphs ~= 0;
end

function RootInlineBox:IncludeMarginForBox(box)
	if (box:Renderer():IsReplaced() or (box:Renderer():IsText() and not box:IsText())) then
        return false;
	end

    local lineBoxContain = self:Renderer():Style():LineBoxContain();
	local containInlineBox = mathlib.bit.band(lineBoxContain, LineBoxContainEnum.LineBoxContainInlineBox);
    return containInlineBox ~= 0;
end

function RootInlineBox:BaselinePosition(baselineType)
	local direction = if_else(self:IsHorizontal(), "HorizontalLine", "VerticalLine");
	return self:BoxModelObject():BaselinePosition(baselineType, self.firstLine, direction, "PositionOfInteriorLineBoxes");
end

function RootInlineBox:LineHeight()
	local direction = if_else(self:IsHorizontal(), "HorizontalLine", "VerticalLine");
	return self:BoxModelObject():LineHeight(self.firstLine, direction, "PositionOfInteriorLineBoxes");
end

--LayoutUnit RootInlineBox::verticalPositionForBox(InlineBox* box, VerticalPositionCache& verticalPositionCache)
function RootInlineBox:VerticalPositionForBox(box, verticalPositionCache)
    if (box:Renderer():IsText()) then
        return box:Parent():LogicalTop();
	end
    
    local renderer = box:BoxModelObject();
    --ASSERT(renderer->isInline());
    if (not renderer:IsInline()) then
        return 0;
	end
    -- This method determines the vertical position for inline elements.
    local firstLine = self.firstLine;
    --if (firstLine && !renderer->document()->usesFirstLineRules())
	if (firstLine and not self.renderer:Document():UsesFirstLineRules()) then
        firstLine = false;
	end

    -- Check the cache.
    local isRenderInline = renderer:IsLayoutInline();
    if (isRenderInline and not firstLine) then
--        local verticalPosition = verticalPositionCache.get(renderer, baselineType());
--        if (verticalPosition != PositionUndefined)
--            return verticalPosition;
		--log("RootInlineBox:VerticalPositionForBox return value is error\r\n");
		--return;
    end

    local verticalPosition = 0;
    local verticalAlign = renderer:Style():VerticalAlign();
    if (verticalAlign == VerticalAlignEnum.TOP or verticalAlign == VerticalAlignEnum.BOTTOM) then
        return 0;
	end
   
    local parent = renderer:Parent();
    if (parent:IsLayoutInline() and parent:Style():VerticalAlign() ~= VerticalAlignEnum.TOP and parent:Style():VerticalAlign() ~= VerticalAlignEnum.BOTTOM) then
        verticalPosition = box:Parent():LogicalTop();
	end
    
    if (verticalAlign ~= VerticalAlignEnum.BASELINE) then
--        const Font& font = parent->style(firstLine)->font();
--        const FontMetrics& fontMetrics = font.fontMetrics();
--        int fontSize = font.pixelSize();
--
--        LineDirectionMode lineDirection = parent->isHorizontalWritingMode() ? HorizontalLine : VerticalLine;
--
--        if (verticalAlign == SUB)
--            verticalPosition += fontSize / 5 + 1;
--        else if (verticalAlign == SUPER)
--            verticalPosition -= fontSize / 3 + 1;
--        else if (verticalAlign == TEXT_TOP)
--            verticalPosition += renderer->baselinePosition(baselineType(), firstLine, lineDirection) - fontMetrics.ascent(baselineType());
--        else if (verticalAlign == MIDDLE)
--            verticalPosition += -static_cast<int>(fontMetrics.xHeight() / 2) - renderer->lineHeight(firstLine, lineDirection) / 2 + renderer->baselinePosition(baselineType(), firstLine, lineDirection);
--        else if (verticalAlign == TEXT_BOTTOM) {
--            verticalPosition += fontMetrics.descent(baselineType());
--            // lineHeight - baselinePosition is always 0 for replaced elements (except inline blocks), so don't bother wasting time in that case.
--            if (!renderer->isReplaced() || renderer->isInlineBlockOrInlineTable())
--                verticalPosition -= (renderer->lineHeight(firstLine, lineDirection) - renderer->baselinePosition(baselineType(), firstLine, lineDirection));
--        } else if (verticalAlign == BASELINE_MIDDLE)
--            verticalPosition += -renderer->lineHeight(firstLine, lineDirection) / 2 + renderer->baselinePosition(baselineType(), firstLine, lineDirection);
--        else if (verticalAlign == LENGTH)
--            verticalPosition -= renderer->style()->verticalAlignLength().calcValue(renderer->lineHeight(firstLine, lineDirection));
    end

    -- Store the cached value.
    if (isRenderInline and not firstLine) then
        --verticalPositionCache.set(renderer, baselineType(), verticalPosition);
	end

    return verticalPosition;
end

--void paint(PaintInfo&, const LayoutPoint&, LayoutUnit lineTop, LayoutUnit lineBottom)
function RootInlineBox:Paint(paintInfo, paintOffset, lineTop, lineBottom)
	RootInlineBox._super.Paint(self, paintInfo, paintOffset, lineTop, lineBottom)
end

function RootInlineBox:LogicalTopVisualOverflow()
    return RootInlineBox._super.LogicalTopVisualOverflow(self, self:LineTop());
end

function RootInlineBox:LogicalBottomVisualOverflow()
    return RootInlineBox._super.LogicalBottomVisualOverflow(self, self:LineBottom());
end

function RootInlineBox:LogicalTopLayoutOverflow()
    return RootInlineBox._super.LogicalTopLayoutOverflow(self, self:LineTop());
end

function RootInlineBox:LogicalBottomLayoutOverflow()
    return RootInlineBox._super.LogicalBottomLayoutOverflow(self, self:LineBottom());
end

function RootInlineBox:SelectionTop()
	local selectionTop = self.lineTop;
	return selectionTop;
end

function RootInlineBox:SelectionBottom()
	local selectionBottom = self.lineBottom;
	return selectionBottom;
end

function RootInlineBox:SelectionHeight()
	return math.max(0, self:SelectionBottom() - self:SelectionTop());
end

function RootInlineBox:LineBreakBidiStatus()
    --return BidiStatus(static_cast<WTF::Unicode::Direction>(m_lineBreakBidiStatusEor), static_cast<WTF::Unicode::Direction>(m_lineBreakBidiStatusLastStrong), static_cast<WTF::Unicode::Direction>(m_lineBreakBidiStatusLast), m_lineBreakContext);
	return BidiStatus:new():init(self.lineBreakBidiStatusEor, self.lineBreakBidiStatusLastStrong, self.lineBreakBidiStatusLast, self.lineBreakContext);
end

function RootInlineBox:IsHyphenated()
	local box = self:FirstLeafChild();
	while(box) do
		if (box:IsInlineTextBox()) then
            if (box:ToInlineTextBox():HasHyphen()) then
                return true;
			end
        end

		box = box:NextLeafChild();
	end

    return false;
end

function RootInlineBox:FloatsPtr() 
	return self.floats;
end

--void appendFloat(RenderBox* floatingBox)
function RootInlineBox:AppendFloat(floatingBox)
    --ASSERT(!isDirty());
    if (not self.floats) then
        self.floats = commonlib.vector:new();
	end
	self.floats:append(floatingBox);
end

function RootInlineBox:ExtractLineBoxFromRenderObject()
	self:Block():LineBoxes():ExtractLineBox(self);
end

function RootInlineBox:RemoveLineBoxFromRenderObject()
    self:Block():LineBoxes():RemoveLineBox(self);
end

function RootInlineBox:AttachLineBoxToRenderObject()
    self:Block():LineBoxes():AttachLineBox(self);
end

local TrailingFloatsRootInlineBox = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.RootInlineBox"), commonlib.gettable("System.Windows.mcml.layout.TrailingFloatsRootInlineBox"));

function TrailingFloatsRootInlineBox:init(obj)
	TrailingFloatsRootInlineBox._super.init(self, obj);
	self:SetHasVirtualLogicalHeight();
	return self;
end

function TrailingFloatsRootInlineBox:VirtualLogicalHeight()
	return 0;
end