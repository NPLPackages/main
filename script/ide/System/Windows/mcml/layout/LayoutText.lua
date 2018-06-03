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
local InlineTextBox = commonlib.gettable("System.Windows.mcml.layout.InlineTextBox");
local UniString = commonlib.gettable("System.Core.UniString");

local LayoutText = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutObject"), commonlib.gettable("System.Windows.mcml.layout.LayoutText"));

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
		if(from >= self:TextLength()) then
			return 0;
		end

		if(from + len > self:TextLength()) then
			len = self:TextLength() - from + 1;
		end

		local firstLine = xPos;
		xPos = font;
		font = self:Style(firstLine):Font();
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