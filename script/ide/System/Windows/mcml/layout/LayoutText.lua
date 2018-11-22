--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutText.lua");
local LayoutText = commonlib.gettable("System.Windows.mcml.layout.LayoutText");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObject.lua");
NPL.load("(gl)script/ide/System/Core/UniString.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/InlineTextBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/text/TextBreakIterator.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/BreakLines.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
local BreakLines = commonlib.gettable("System.Windows.mcml.layout.BreakLines");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local LazyLineBreakIterator = commonlib.gettable("System.Windows.mcml.platform.text.LazyLineBreakIterator");
local InlineTextBox = commonlib.gettable("System.Windows.mcml.layout.InlineTextBox");
local UniString = commonlib.gettable("System.Core.UniString");

local LayoutText = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutObject"), commonlib.gettable("System.Windows.mcml.layout.LayoutText"));

local IntRect = Rect;

local INT_MAX = 0xffffffff;
local INT_MIN = -0xffffffff;

local WordBreakEnum = ComputedStyleConstants.WordBreakEnum;
local WordWrapEnum = ComputedStyleConstants.WordWrapEnum;
local NBSPModeEnum = ComputedStyleConstants.NBSPModeEnum
local WhiteSpaceEnum = ComputedStyleConstants.WhiteSpaceEnum;

function LayoutText:ctor()
	self.name = "LayoutText";

	self.minWidth = -1; -- here to minimize padding in 64-bit.

    self.text = UniString:new();

    self.firstTextBox = nil;
    self.lastTextBox = nil;

    self.maxWidth = -1;
    self.beginMinWidth = 0;
    self.endMinWidth = 0;

    self.hasBreakableChar = false; -- Whether or not we can be broken into multiple lines.
    self.hasBreak = false; -- Whether or not we have a hard break (e.g., <pre> with '\n').
    self.hasTab = false; -- Whether or not we have a variable width tab character (e.g., <pre> with '\t').
    self.hasBeginWS = false; -- Whether or not we begin with WS (only true if we aren't pre)
    self.hasEndWS = false; -- Whether or not we end with WS (only true if we aren't pre)
    self.linesDirty = false; -- This bit indicates that the text run has already dirtied specific
                           -- line boxes, and this hint will enable layoutInlineChildren to avoid
                           -- just dirtying everything when character data is modified (e.g., appended/inserted
                           -- or removed).
    self.containsReversedText = false;
    self.isAllASCII = false;
    self.knownToHaveNoOverflowAndNoFallbackFonts = false;
    self.needsTranscoding = false;
end

function LayoutText:init(node, str)
	self.text:SetText(str);
	LayoutText._super.init(self, node);
	self:SetIsText();

	return self;
end

function LayoutText:GetName()
	return "LayoutText";
end

function LayoutText:FirstTextBox()
	return self.firstTextBox;
end

function LayoutText:LastTextBox()
	return self.lastTextBox;
end

function LayoutText:DeleteTextBoxes()
	if (self:FirstTextBox()) then
        local arena = self:RenderArena();
		local curr = self:FirstTextBox()
        local next;
		while(curr) do
			next = curr:NextTextBox();
			curr:Destroy(arena);
			curr = next;
		end
        self.firstTextBox = nil;
		self.lastTextBox = nil;
    end
end

function LayoutText:DirtyLineBoxes(fullLayout)
	if (fullLayout) then
        self:DeleteTextBoxes();
    elseif (not self.linesDirty) then
		local box = self:FirstTextBox();
		while(box) do
			box:DirtyLineBoxes();
			box = box:NextTextBox()
		end
    end
    self.linesDirty = false;
end


function LayoutText:StyleDidChange(diff, oldStyle)
	LayoutText._super.StyleDidChange(self, diff, oldStyle);
end

function LayoutText:TextLength()
	return self.text:length(); -- non virtual implementation of length()
end 

-- Make length() private so that callers that have a RenderText*
-- will use the more efficient textLength() instead, while
-- callers with a RenderObject* can continue to use length().
function LayoutText:Length()
	return self:TextLength();
end

function LayoutText:IsWordBreak()
    return false;
end

function LayoutText:Characters()
	return self.text;
end

function LayoutText:Text()
	return self.text;
end

--void RenderText::setTextInternal(PassRefPtr<StringImpl> text)
function LayoutText:SetTextInternal(text)
	self.text:SetText(text);
end

--void RenderText::setText(PassRefPtr<StringImpl> text, bool force)
function LayoutText:SetText(text, force)
    --ASSERT(text);
	force = if_else(force == nil, false, force);
    if (not force and self.text:GetText() == text) then
        return;
	end

    self:SetTextInternal(text);
    self:SetNeedsLayoutAndPrefWidthsRecalc();
    self.knownToHaveNoOverflowAndNoFallbackFonts = false;
    
--    AXObjectCache* axObjectCache = document()->axObjectCache();
--    if (axObjectCache->accessibilityEnabled())
--        axObjectCache->contentChanged(this);
end

function LayoutText:CreateTextBox()
    return InlineTextBox:new():init(self);
end

function LayoutText:CreateInlineTextBox()
    local textBox = self:CreateTextBox();
    if (not self.firstTextBox) then
        self.firstTextBox = textBox;
		self.lastTextBox = textBox;
    else
        self.lastTextBox:SetNextTextBox(textBox);
        textBox:SetPreviousTextBox(self.lastTextBox);
        self.lastTextBox = textBox;
    end
    textBox:SetIsText(true);
    return textBox;
end

--function LayoutText:Width(unsigned from, unsigned len, const Font& f, float xPos, HashSet<const SimpleFontData*>* fallbackFonts, GlyphOverflow* glyphOverflow) const
function LayoutText:Width(from, len, font, xPos, fallbackFonts, glyphOverflow)
	if(type(font) == "number" and type(xPos) == "boolean") then
		if(from > self:TextLength()) then
			return 0;
		end

		if(from + len > self:TextLength()) then
			len = self:TextLength() - from + 1;
		end

		local firstLine = xPos;
		xPos = font;
		font = self:Style(firstLine):Font():ToString();
	end
	if (self:Characters():empty()) then
        return 0;
	end

    local w = self.text:GetWidth(font, from, len);

--	if (&f == &style()->font()) {
--        if (!style()->preserveNewline() && !from && len == textLength() && (!glyphOverflow || !glyphOverflow->computeBounds)) {
--            if (fallbackFonts) {
--                ASSERT(glyphOverflow);
--                if (preferredLogicalWidthsDirty() || !m_knownToHaveNoOverflowAndNoFallbackFonts) {
--                    const_cast<RenderText*>(this)->computePreferredLogicalWidths(0, *fallbackFonts, *glyphOverflow);
--                    if (fallbackFonts->isEmpty() && !glyphOverflow->left && !glyphOverflow->right && !glyphOverflow->top && !glyphOverflow->bottom)
--                        m_knownToHaveNoOverflowAndNoFallbackFonts = true;
--                }
--                w = m_maxWidth;
--            } else
--                w = maxLogicalWidth();
--        } else
--            w = widthFromCache(f, from, len, xPos, fallbackFonts, glyphOverflow);
--    } else {
--        TextRun run = RenderBlock::constructTextRun(const_cast<RenderText*>(this), f, text()->characters() + from, len, style());
--        run.setCharactersLength(textLength() - from);
--        ASSERT(run.charactersLength() >= run.length());
--
--        run.setAllowTabs(allowTabs());
--        run.setXPos(xPos);
--        w = f.width(run, fallbackFonts, glyphOverflow);
--    }

    return w;
end

--void RenderText::positionLineBox(InlineBox* box)
function LayoutText:PositionLineBox(box)
    --InlineTextBox* s = toInlineTextBox(box);
	local s = box;

    -- FIXME: should not be needed!!!
    if (s:Len() == 0) then
        -- We want the box to be destroyed.
        s:Remove();
        if (self.firstTextBox == s) then
            self.firstTextBox = s:NextTextBox();
        else
            s:PrevTextBox():SetNextTextBox(s:NextTextBox());
		end
        if (self.lastTextBox == s) then
            self.lastTextBox = s:PrevTextBox();
        else
            s:NextTextBox():SetPreviousTextBox(s:PrevTextBox());
		end
        s:Destroy(self:RenderArena());
        return;
    end

    --m_containsReversedText |= !s->isLeftToRightDirection();
	self.containsReversedText = self.containsReversedText or not s:IsLeftToRightDirection();
end

function LayoutText:RemoveAndDestroyTextBoxes()
    if (not self:DocumentBeingDestroyed()) then
        if (self:FirstTextBox()) then
            if (self:IsBR()) then
                local next = self:FirstTextBox():Root():NextRootBox();
                if (next) then
                    next:MarkDirty();
				end
            end
			local box = self:FirstTextBox();
			while(box) do
				box:Remove();
				box = box:NextTextBox();
			end
        elseif (self:Parent()) then
            self:Parent():DirtyLinesFromChangedChild(self);
		end
    end
    self:DeleteTextBoxes();
end

function LayoutText:WillBeDestroyed()
    self:RemoveAndDestroyTextBoxes();
    LayoutText._super.WillBeDestroyed(self);
end

--void RenderText::trimmedPrefWidths(float leadWidth,
--                                   float& beginMinW, bool& beginWS,
--                                   float& endMinW, bool& endWS,
--                                   bool& hasBreakableChar, bool& hasBreak,
--                                   float& beginMaxW, float& endMaxW,
--                                   float& minW, float& maxW, bool& stripFrontSpaces)
function LayoutText:TrimmedPrefWidths(leadWidth, beginMinW, beginWS, endMinW, endWS, hasBreakableChar, 
											hasBreak, beginMaxW, endMaxW, minW, maxW, stripFrontSpaces)
	local collapseWhiteSpace = self:Style():CollapseWhiteSpace();
    if (not collapseWhiteSpace) then
        stripFrontSpaces = false;
	end

    if (self.hasTab or self:PreferredLogicalWidthsDirty()) then
        self:ComputePreferredLogicalWidths(leadWidth);
	end
    beginWS = not stripFrontSpaces and self.hasBeginWS;
    endWS = self.hasEndWS;

    local len = self:TextLength();

    if (len == 0 or (stripFrontSpaces and self:Text():ContainsOnlyWhitespace())) then
        beginMinW = 0;
        endMinW = 0;
        beginMaxW = 0;
        endMaxW = 0;
        minW = 0;
        maxW = 0;
        hasBreak = false;
        return beginMinW, beginWS, endMinW, endWS, hasBreakableChar, hasBreak, beginMaxW, endMaxW, minW, maxW, stripFrontSpaces;
    end

    minW = self.minWidth;
    maxW = self.maxWidth;

    beginMinW = self.beginMinWidth;
    endMinW = self.endMinWidth;

    hasBreakableChar = self.hasBreakableChar;
    hasBreak = self.hasBreak;

    --ASSERT(m_text);
    --StringImpl& text = *m_text.impl();
	local text = self.text;
	local firstChar = text[0];
    if (firstChar == " " or (firstChar == "\n" and not self:Style():PreserveNewline()) or firstChar == "\t") then
        local font = self:Style():Font(); -- FIXME: This ignores first-line.
        if (stripFrontSpaces) then
            --const UChar space = ' ';
            --local spaceWidth = font.width(RenderBlock::constructTextRun(this, font, &space, 1, style()));
			local spaceWidth = UniString.GetSpaceWidth(font:ToString());
            maxW = maxW - spaceWidth;
        else
            maxW = maxW + font:WordSpacing();
		end
    end

    stripFrontSpaces = collapseWhiteSpace and self.hasEndWS;

    if (not self:Style():AutoWrap() or minW > maxW) then
        minW = maxW;
	end
    -- Compute our max widths by scanning the string for newlines.
    if (hasBreak) then
        local font = self:Style():Font(); -- FIXME: This ignores first-line.
        local firstLine = true;
        beginMaxW = maxW;
        endMaxW = maxW;
		local i = 1;
		while(i <= len) do
        --for (int i = 0; i < len; i++) then
            local linelen = 0;
            while (i + linelen < len and text[i + linelen] ~= "\n") do
                linelen = linelen + 1;
			end

            if (linelen ~= 0) then
                endMaxW = self:WidthFromCache(font:ToString(), i, linelen - 1, leadWidth + endMaxW, nil, nil);
                if (firstLine) then
                    firstLine = false;
                    leadWidth = 0;
                    beginMaxW = endMaxW;
                end
                i = i + linelen;
            elseif (firstLine) then
                beginMaxW = 0;
                firstLine = false;
                leadWidth = 0;
            end

            if (i == len - 1) then
                -- A <pre> run that ends with a newline, as in, e.g.,
                -- <pre>Some text\n\n<span>More text</pre>
                endMaxW = 0;
			end
			i = i + 1;
        end
    end
	return beginMinW, beginWS, endMinW, endWS, hasBreakableChar, hasBreak, beginMaxW, endMaxW, minW, maxW, stripFrontSpaces;
end

local noBreakSpace = UniString.SpecialCharacter.Nbsp;
local softHyphen = UniString.SpecialCharacter.SoftHyphen;

--static inline bool isSpaceAccordingToStyle(UChar c, RenderStyle* style)
local function isSpaceAccordingToStyle(c, style)
    return c == " " or (string.byte(c,1) == noBreakSpace and style:NbspMode() == NBSPModeEnum.SPACE);
end

--bool RenderText::containsOnlyWhitespace(unsigned from, unsigned len) const
function LayoutText:ContainsOnlyWhitespace(from, len)
    --ASSERT(m_text);
    local text = self.text;
    local currPos = from;
	local currChar;
	while(currPos < from + len) do
		currChar = text[currPos];
		if(currChar == "\n" or currChar == " " or currChar == "\t") then
			currPos = currPos + 1;
		else
			break;
		end
	end

--    for (currPos = from;
--         currPos < from + len && (text[currPos] == '\n' || text[currPos] == ' ' || text[currPos] == '\t');
--         currPos++) { }
    return currPos >= (from + len);
end

--void RenderText::computePreferredLogicalWidths(float leadWidth, HashSet<const SimpleFontData*>& fallbackFonts, GlyphOverflow& glyphOverflow)
function LayoutText:ComputePreferredLogicalWidths(leadWidth, fallbackFonts, glyphOverflow)
	self.minWidth = 0;
    self.beginMinWidth = 0;
    self.endMinWidth = 0;
    self.maxWidth = 0;

    if (self:IsBR()) then
        return;
	end

    local currMinWidth = 0;
    local currMaxWidth = 0;
    self.hasBreakableChar = false;
    self.hasBreak = false;
    self.hasTab = false;
    self.hasBeginWS = false;
    self.hasEndWS = false;

    --const Font& f = style()->font(); // FIXME: This ignores first-line.
	local f = self:Style():Font();
	local font_str = f:ToString();
    local wordSpacing = self:Style():WordSpacing();
    local len = self:TextLength();

    --const UChar* txt = characters();
	local txt = self:Characters();
    local breakIterator = LazyLineBreakIterator:new():init(txt, len);
    local needsWordSpacing = false;
    local ignoringSpaces = false;
    local isSpace = false;
    local firstWord = true;
    local firstLine = true;
    local nextBreakable = -1;
    local lastWordBoundary = 1;

    -- Non-zero only when kerning is enabled, in which case we measure words with their trailing
    -- space, then subtract its width.
    --float wordTrailingSpaceWidth = f.typesettingFeatures() & Kerning ? f.width(RenderBlock::constructTextRun(this, f, &space, 1, style())) : 0;
	local wordTrailingSpaceWidth = 0;

    --int firstGlyphLeftOverflow = -1;

    local breakNBSP = self:Style():AutoWrap() and self:Style():NbspMode() == NBSPModeEnum.SPACE;
    local breakAll = (self:Style():WordBreak() == WordBreakEnum.BreakAllWordBreak or self:Style():WordBreak() == WordBreakEnum.BreakWordBreak) and self:Style():AutoWrap();

	--for (int i = 0; i < len; i++) {
	local i = 1;
	while(i <= len) do
--	for i = 1, len do
        local c = txt[i];
        local previousCharacterIsSpace = isSpace;

        local isNewline = false;
        if (c == "\n") then
            if (self:Style():PreserveNewline()) then
                m_hasBreak = true;
                isNewline = true;
                isSpace = false;
            else
                isSpace = true;
			end
        elseif (c == "\t") then
            if (not self:Style():CollapseWhiteSpace()) then
                m_hasTab = true;
                isSpace = false;
            else
                isSpace = true;
			end
        else
            isSpace = c == " ";
		end
        if ((isSpace or isNewline) and i == 1) then
            self.hasBeginWS = true;
		end
        if ((isSpace or isNewline) and i == len) then
            self.hasEndWS = true;
		end

        if (not ignoringSpaces and self:Style():CollapseWhiteSpace() and previousCharacterIsSpace and isSpace) then
            ignoringSpaces = true;
		end

        if (ignoringSpaces and not isSpace) then
            ignoringSpaces = false;
		end
        -- Ignore spaces and soft hyphens
        if (ignoringSpaces) then
            -- ASSERT(lastWordBoundary == i);
            lastWordBoundary = lastWordBoundary + 1;
            --continue; 
        elseif (string.byte(c,1) == softHyphen) then
            currMaxWidth = currMaxWidth + self:WidthFromCache(font_str, lastWordBoundary, i - lastWordBoundary, leadWidth + currMaxWidth, fallbackFonts, glyphOverflow);
--            if (firstGlyphLeftOverflow < 0)
--                firstGlyphLeftOverflow = glyphOverflow.left;
            lastWordBoundary = i + 1;
            --continue;
        else

			local hasBreak = breakAll or BreakLines.IsBreakable(breakIterator, i, nextBreakable, breakNBSP);
			local betweenWords = true;
			local j = i;
			while (c ~= "\n" and not isSpaceAccordingToStyle(c, self:Style()) and c ~= "\t" and string.byte(c,1) ~= softHyphen) do
				j = j + 1;
				if (j == len + 1) then
					break;
				end
				c = txt[j];
				if (BreakLines.IsBreakable(breakIterator, j, nextBreakable, breakNBSP)) then
					break;
				end
				if (breakAll) then
					betweenWords = false;
					break;
				end
			end

			local wordLen = j - i;
			if (wordLen ~= 0) then
				local isSpace = (j < len) and isSpaceAccordingToStyle(c, self:Style());
				local w;
				if (wordTrailingSpaceWidth ~= 0 and isSpace) then
					w = self:WidthFromCache(font_str, i, wordLen + 1 - 1, leadWidth + currMaxWidth, fallbackFonts, glyphOverflow) - wordTrailingSpaceWidth;
				else
					w = self:WidthFromCache(font_str, i, wordLen - 1, leadWidth + currMaxWidth, fallbackFonts, glyphOverflow);
				end

--				if (firstGlyphLeftOverflow < 0)
--					firstGlyphLeftOverflow = glyphOverflow.left;
				currMinWidth = currMinWidth + w;
				if (betweenWords) then
					if (lastWordBoundary == i) then
						currMaxWidth = currMaxWidth + w;
					else
						currMaxWidth = currMaxWidth + self:WidthFromCache(f, lastWordBoundary, j - lastWordBoundary, leadWidth + currMaxWidth, fallbackFonts, glyphOverflow);
					end
					lastWordBoundary = j;
				end

				local isCollapsibleWhiteSpace = (j < len) and self:Style():IsCollapsibleWhiteSpace(c);
				if (j < len and self:Style():AutoWrap()) then
					m_hasBreakableChar = true;
				end

				-- Add in wordSpacing to our currMaxWidth, but not if this is the last word on a line or the
				-- last word in the run.
				if (wordSpacing ~= 0 and (isSpace or isCollapsibleWhiteSpace) and not self:ContainsOnlyWhitespace(j, len-j)) then
					currMaxWidth = currMaxWidth + wordSpacing;
				end
				if (firstWord) then
					firstWord = false;
					-- If the first character in the run is breakable, then we consider ourselves to have a beginning
					-- minimum width of 0, since a break could occur right before our run starts, preventing us from ever
					-- being appended to a previous text run when considering the total minimum width of the containing block.
					if (hasBreak) then
						self.hasBreakableChar = true;
					end
					self.beginMinWidth = if_else(hasBreak, 0, w);
				end
				self.endMinWidth = w;

				if (currMinWidth > self.minWidth) then
					self.minWidth = currMinWidth;
				end
				currMinWidth = 0;

				i = i + wordLen;
			else
				-- Nowrap can never be broken, so don't bother setting the
				-- breakable character boolean. Pre can only be broken if we encounter a newline.
				if (self:Style():AutoWrap() or isNewline) then
					self.hasBreakableChar = true;
				end
				if (currMinWidth > self.minWidth) then
					self.minWidth = currMinWidth;
				end
				currMinWidth = 0;

				if (isNewline) then -- Only set if preserveNewline was true and we saw a newline.
					if (firstLine) then
						firstLine = false;
						leadWidth = 0;
						if (not self:Style():AutoWrap()) then
							self.beginMinWidth = currMaxWidth;
						end
					end

					if (currMaxWidth > self.maxWidth) then
						self.maxWidth = currMaxWidth;
					end
					currMaxWidth = 0;
				else
--					TextRun run = RenderBlock::constructTextRun(this, f, txt + i, 1, style());
--					run.setCharactersLength(len - i);
--					ASSERT(run.charactersLength() >= run.length());
--
--					run.setAllowTabs(allowTabs());
--					run.setXPos(leadWidth + currMaxWidth);

					--currMaxWidth += f.width(run);
					currMaxWidth = currMaxWidth + self.text:GetWidth(font_str, i, 1);
					--glyphOverflow.right = 0;
					needsWordSpacing = isSpace and not previousCharacterIsSpace and i == len - 1;
				end
				--ASSERT(lastWordBoundary == i);
				lastWordBoundary = lastWordBoundary + 1;
			end
		end
    end

--	if (firstGlyphLeftOverflow > 0)
--        glyphOverflow.left = firstGlyphLeftOverflow;

    if ((needsWordSpacing and len > 1) or (ignoringSpaces and not firstWord)) then
        currMaxWidth = currMaxWidth + wordSpacing;
	end

    self.minWidth = math.max(currMinWidth, self.minWidth);
    self.maxWidth = math.max(currMaxWidth, self.maxWidth);

    if (not self:Style():AutoWrap()) then
        self.minWidth = self.maxWidth;
	end

    if (self:Style():WhiteSpace() == WhiteSpaceEnum.PRE) then
        if (firstLine) then
            self.beginMinWidth = self.maxWidth;
		end
        self.endMinWidth = currMaxWidth;
    end

    self:SetPreferredLogicalWidthsDirty(false);
end

--ALWAYS_INLINE float RenderText::widthFromCache(const Font& f, int start, int len, float xPos, HashSet<const SimpleFontData*>* fallbackFonts, GlyphOverflow* glyphOverflow) const
function LayoutText:WidthFromCache(f, start, len, xPos, fallbackFonts, glyphOverflow)
	local w = self.text:GetWidth(f, start, len);
	return w;
end

--IntRect RenderText::clippedOverflowRectForRepaint(RenderBoxModelObject* repaintContainer) const
function LayoutText:ClippedOverflowRectForRepaint(repaintContainer)
    local rendererToRepaint = self:ContainingBlock();

    -- Do not cross self-painting layer boundaries.
    local enclosingLayerRenderer = self:EnclosingLayer():Renderer();
    if (enclosingLayerRenderer ~= rendererToRepaint and not rendererToRepaint:IsDescendantOf(enclosingLayerRenderer)) then
        rendererToRepaint = enclosingLayerRenderer;
	end

    -- The renderer we chose to repaint may be an ancestor of repaintContainer, but we need to do a repaintContainer-relative repaint.
    if (repaintContainer and repaintContainer ~= rendererToRepaint and not rendererToRepaint:IsDescendantOf(repaintContainer)) then
        return repaintContainer:ClippedOverflowRectForRepaint(repaintContainer);
	end

    return rendererToRepaint:ClippedOverflowRectForRepaint(repaintContainer);
end

--IntRect RenderText::linesVisualOverflowBoundingBox() const
function LayoutText:LinesVisualOverflowBoundingBox()
    if (self:FirstTextBox() == nil) then
        return IntRect:new();
	end

    -- Return the width of the minimal left side and the maximal right side.
    local logicalLeftSide = INT_MAX;
    local logicalRightSide = INT_MIN;
	local curr = self:FirstTextBox();
	while(curr) do
		logicalLeftSide = math.min(logicalLeftSide, curr:LogicalLeftVisualOverflow());
        logicalRightSide = math.max(logicalRightSide, curr:LogicalRightVisualOverflow());

		curr = curr:NextTextBox();
	end
    
    local logicalTop = self:FirstTextBox():LogicalTopVisualOverflow();
    local logicalWidth = logicalRightSide - logicalLeftSide;
    local logicalHeight = self:LastTextBox():LogicalBottomVisualOverflow() - logicalTop;
    
    local rect = IntRect:new(logicalLeftSide, logicalTop, logicalWidth, logicalHeight);
    if (not self:Style():IsHorizontalWritingMode()) then
        rect = rect:TransposedRect();
	end
    return rect;
end

function LayoutText:CheckConsistency()

end

--void RenderText::extractTextBox(InlineTextBox* box)
function LayoutText:ExtractTextBox(box)
    self:CheckConsistency();

    self.lastTextBox = box:PrevTextBox();
    if (box == self.firstTextBox) then
        self.firstTextBox = nil;
	end
    if (box:PrevTextBox()) then
        box:PrevTextBox():SetNextTextBox(nil);
	end
    box:SetPreviousTextBox(nil);
	local curr = box;
	while(curr) do
		curr:SetExtracted();
		curr = curr:NextTextBox();
	end

    self:CheckConsistency();
end
	
--void RenderText::attachTextBox(InlineTextBox* box)
function LayoutText:AttachTextBox(box)
    self:CheckConsistency();

    if (self.lastTextBox) then
        self.lastTextBox:SetNextTextBox(box);
        box:SetPreviousTextBox(self.lastTextBox);
    else
        self.firstTextBox = box;
	end
    --InlineTextBox* last = box;
	local last = box;
	local curr = box;
	while(curr) do
		curr:SetExtracted(false);
        last = curr;
		
		curr = curr:NextTextBox();
	end
    
    self.lastTextBox = last;

    self:CheckConsistency();
end

--void RenderText::removeTextBox(InlineTextBox* box)
function LayoutText:RemoveTextBox(box)
    self:CheckConsistency();

    if (box == self.firstTextBox) then
        self.firstTextBox = box:NextTextBox();
	end
    if (box == self.lastTextBox) then
        self.lastTextBox = box:PrevTextBox();
	end
    if (box:NextTextBox()) then
        box:NextTextBox():SetPreviousTextBox(box:PrevTextBox());
	end
    if (box:PrevTextBox()) then
        box:PrevTextBox():SetNextTextBox(box:NextTextBox());
	end

    self:CheckConsistency();
end