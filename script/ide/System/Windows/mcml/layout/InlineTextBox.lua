--[[
Title: 
Author(s): LiPeng
Date: 2018/3/12
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/InlineTextBox.lua");
local InlineTextBox = commonlib.gettable("System.Windows.mcml.layout.InlineTextBox");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/InlineBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
local InlineTextBox = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.InlineBox"), commonlib.gettable("System.Windows.mcml.layout.InlineTextBox"));

local USHRT_MAX = 0xffff;
local cNoTruncation = USHRT_MAX;
local cFullTruncation = USHRT_MAX - 1;

function InlineTextBox:ctor()
	self.prevTextBox = nil; -- The previous box that also uses our RenderObject
    self.nextTextBox = nil; -- The next box that also uses our RenderObject

    self.start = 1;
    self.len = 0;

    self.truncation = cNoTruncation;	-- Where to truncate when text overflow is applied.  We use special constants to
										-- denote no truncation (the whole run paints) and full truncation (nothing paints at all).
end

function InlineTextBox:BoxName()
    return "InlineTextBox";
end

function InlineTextBox:IsInlineTextBox()
	return true;
end

function InlineTextBox:PrevTextBox()
	return self.prevTextBox;
end

function InlineTextBox:NextTextBox()
	return self.nextTextBox;
end

function InlineTextBox:SetNextTextBox(next)
	self.nextTextBox = next;
end

function InlineTextBox:SetPreviousTextBox(prev)
	self.prevTextBox = prev;
end

function InlineTextBox:Start()
	return self.start;
end

function InlineTextBox:End()
	local _end = self.start;
	if(self.len ~= 0) then
		_end = self.start + self.len - 1;
	end
	return _end;
end

function InlineTextBox:Len()
	return self.len;
end

function InlineTextBox:SetStart(start)
	self.start = start;
end

function InlineTextBox:SetLen(len)
	self.len = len;
end

function InlineTextBox:OffsetRun(d)
	self.start = self.start + d;
end

function InlineTextBox:Truncation()
	return self.truncation;
end

function InlineTextBox:Destroy(arena)
--    if (!m_knownToHaveNoOverflow && gTextBoxesWithOverflow) then
--        gTextBoxesWithOverflow->remove(this);
--	end
	InlineTextBox._super.Destroy(self, arena);
end

function InlineTextBox:CanHaveLeadingExpansion()
	return self.hasSelectedChildrenOrCanHaveLeadingExpansion;
end

function InlineTextBox:SetCanHaveLeadingExpansion(canHaveLeadingExpansion)
	self.hasSelectedChildrenOrCanHaveLeadingExpansion = canHaveLeadingExpansion;
end

--void paint(PaintInfo&, const LayoutPoint&, LayoutUnit lineTop, LayoutUnit lineBottom)
function InlineTextBox:Paint(paintInfo, paintOffset, lineTop, lineBottom)
	local logicalLeftSide = self:LogicalLeftVisualOverflow();
    local logicalRightSide = self:LogicalRightVisualOverflow();
    local logicalStart = logicalLeftSide + if_else(self:IsHorizontal(), paintOffset:X(), paintOffset:Y());
    local logicalExtent = logicalRightSide - logicalLeftSide;

	local left, top, width ,height = self:LogicalLeftVisualOverflow(), self:LogicalTopVisualOverflow(), self.logicalWidth, self:LogicalHeight();

	if(self:Renderer() and self:Renderer():IsText()) then
		local textRender = self:Renderer();
		local textNode = textRender:Node();
		if(textNode) then
			local text = string.sub(tostring(textRender.text), self.start, self.start + self.len - 1);
			textNode:CreateAndAppendLabel(left, top, width ,height, text);
		end
	end
end

function InlineTextBox:LogicalFrameRect()
	if(self:IsHorizontal()) then
		return Rect:new(self.topLeft:X(), self.topLeft:Y(), self.logicalWidth, self:LogicalHeight());
	end
	return Rect:new(self.topLeft:Y(), self.topLeft:X(), self.logicalWidth, self:LogicalHeight());
end

local gTextBoxesWithOverflow = {};

--    LayoutRect logicalOverflowRect() const;
function InlineTextBox:LogicalOverflowRect()
--    if (m_knownToHaveNoOverflow || !gTextBoxesWithOverflow)
--        return enclosingIntRect(logicalFrameRect());
--    return gTextBoxesWithOverflow->get(this);
	return self:LogicalFrameRect();
end

function InlineTextBox:SetLogicalOverflowRect(rect)

end

function InlineTextBox:LogicalTopVisualOverflow()
	return self:LogicalOverflowRect():Y();
end

function InlineTextBox:LogicalBottomVisualOverflow()
	return self:LogicalOverflowRect():MaxY();
end

function InlineTextBox:LogicalLeftVisualOverflow()
	return self:LogicalOverflowRect():X();
end

function InlineTextBox:LogicalRightVisualOverflow()
	return self:LogicalOverflowRect():MaxX();
end

function InlineTextBox:TextRenderer()
	return self:Renderer();
end

function InlineTextBox:SelectionTop()
    return self:Root():SelectionTop();
end

function InlineTextBox:SelectionBottom()
    return self:Root():SelectionBottom();
end

function InlineTextBox:SelectionHeight()
    return self:Root():SelectionHeight();
end