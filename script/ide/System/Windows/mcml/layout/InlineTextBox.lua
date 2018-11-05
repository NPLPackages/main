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
NPL.load("(gl)script/ide/System/Windows/Controls/Label.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local Label = commonlib.gettable("System.Windows.Controls.Label");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
local InlineTextBox = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.InlineBox"), commonlib.gettable("System.Windows.mcml.layout.InlineTextBox"));

local USHRT_MAX = 0xffff;
local cNoTruncation = USHRT_MAX;
local cFullTruncation = USHRT_MAX - 1;

local VisibilityEnum = ComputedStyleConstants.VisibilityEnum;

function InlineTextBox:ctor()
	self.prevTextBox = nil; -- The previous box that also uses our RenderObject
    self.nextTextBox = nil; -- The next box that also uses our RenderObject

    self.start = 1;
    self.len = 0;

	self.control = nil;

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
	if(self.control) then
		self.control:Destroy();
		self.control = nil;
	end

	InlineTextBox._super.Destroy(self, arena);
end

function InlineTextBox:CanHaveLeadingExpansion()
	return self.hasSelectedChildrenOrCanHaveLeadingExpansion;
end

function InlineTextBox:SetCanHaveLeadingExpansion(canHaveLeadingExpansion)
	self.hasSelectedChildrenOrCanHaveLeadingExpansion = canHaveLeadingExpansion;
end

function InlineTextBox:GetParentControl()
	if(self:Parent()) then
		return self:Parent():GetControl();
	end
end

function InlineTextBox:CreateAndAppendLabel(left, top, width, height, text, parent)
	local _this = Label:new():init(parent);
	_this:SetText(text);

	local css = self:Renderer():Style();
	_this:SetFont(css:Font():ToTable());
	_this:SetColor(css:Color():ToDWORD());
	_this:SetScale(self.scale);
	_this:setGeometry(left, top, width, height);
	--self.labels:add(_this);

	return _this;
end

--void paint(PaintInfo&, const LayoutPoint&, LayoutUnit lineTop, LayoutUnit lineBottom)
function InlineTextBox:Paint(paintInfo, paintOffset, lineTop, lineBottom)
--	if (isLineBreak() || !paintInfo.shouldPaintWithinRoot(renderer()) || renderer()->style()->visibility() != VISIBLE ||
--        m_truncation == cFullTruncation || paintInfo.phase == PaintPhaseOutline || !m_len)
--        return;
	if(self:IsLineBreak() or not paintInfo:ShouldPaintWithinRoot(self:Renderer()) or self:Renderer():Style():Visibility() ~= VisibilityEnum.VISIBLE) then
		return;
	end
	local logicalLeftSide = self:LogicalLeftVisualOverflow();
    local logicalRightSide = self:LogicalRightVisualOverflow();
    local logicalStart = logicalLeftSide + if_else(self:IsHorizontal(), paintOffset:X(), paintOffset:Y());
    local logicalExtent = logicalRightSide - logicalLeftSide;

	local left, top, width ,height = self:LogicalLeftVisualOverflow(), self:LogicalTopVisualOverflow(), self.logicalWidth, self:LogicalHeight();

	if(self:Renderer() and self:Renderer():IsText()) then
		if(self.control) then
			self.control:setGeometry(left, top, width ,height);
		else
			local textRender = self:Renderer();
			local text = textRender:Characters():substr(self.start, self.start + self.len - 1);
			local control = self:GetParentControl();
			self.control = self:CreateAndAppendLabel(left, top, width ,height, text, control);
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

function InlineTextBox:BaselinePosition(baselineType)
    if (not self:IsText() or not self:Parent()) then
        return 0;
	end
    if (self:Parent():Renderer() == self:Renderer():Parent()) then
        return self:Parent():BaselinePosition(baselineType);
	end
	local direction = if_else(self:IsHorizontal(), "HorizontalLine", "VerticalLine");
	local renderer_parent = self:Renderer():Parent();
	local renderer_parent_boxModel = renderer_parent:ToRenderBoxModelObject();
	local baselinepos = renderer_parent_boxModel:BaselinePosition(baselineType, self.firstLine, direction, "PositionOnContainingLine")
    return self:Renderer():Parent():ToRenderBoxModelObject():BaselinePosition(baselineType, self.firstLine, direction, "PositionOnContainingLine");
end

function InlineTextBox:LineHeight()
    if (not self:IsText() or not self:Renderer():Parent()) then
        return 0;
	end
    if (self.renderer:IsBR()) then
        return self.renderer:ToRenderBR():LineHeight(self.firstLine);
	end
    if (self:Parent():Renderer() == self:Renderer():Parent()) then
        return self:Parent():LineHeight();
	end
	local direction = if_else(self:IsHorizontal(), "HorizontalLine", "VerticalLine");
    return self:Renderer():Parent():ToRenderBoxModelObject():LineHeight(self.firstLine, direction, "PositionOnContainingLine");
end

function InlineTextBox:HasHyphen() 
	return self.hasEllipsisBoxOrHyphen;
end

function InlineTextBox:SetHasHyphen(hasHyphen) 
	self.hasEllipsisBoxOrHyphen = hasHyphen;
end

function InlineTextBox:ExtractLine()
    if (self.extracted) then
        return;
	end
    self:Renderer():ToRenderText():ExtractTextBox(self);
end

function InlineTextBox:IsLineBreak()
    --return renderer()->isBR() || (renderer()->style()->preserveNewline() && len() == 1 && (*textRenderer()->text())[start()] == '\n');
	return self:Renderer():IsBR();
end