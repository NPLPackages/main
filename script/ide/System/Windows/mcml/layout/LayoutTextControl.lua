--[[
Title: 
Author(s): LiPeng
Date: 2018/11/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutTextControl.lua");
local LayoutTextControl = commonlib.gettable("System.Windows.mcml.layout.LayoutTextControl");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlock.lua");
NPL.load("(gl)script/ide/System/Core/UniString.lua");
local UniString = commonlib.gettable("System.Core.UniString");
local LayoutTextControl = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBlock"), commonlib.gettable("System.Windows.mcml.layout.LayoutTextControl"));

function LayoutTextControl:ctor()
	self.innerTextStyle = nil;
end

function LayoutTextControl:CanHaveChildren() 
	return false;
end

function LayoutTextControl:AvoidsFloats()
	return true;
end

function LayoutTextControl:GetName()
	return "LayoutTextControl";
end

function LayoutTextControl:IsTextControl()
	return true;
end

--virtual PassRefPtr<RenderStyle> createInnerTextStyle(const RenderStyle* startStyle) const = 0;
function LayoutTextControl:CreateInnerTextStyle(startStyle)
	
end

--void RenderTextControl::adjustInnerTextStyle(const RenderStyle* startStyle, RenderStyle* textBlockStyle) const
function LayoutTextControl:AdjustInnerTextStyle(startStyle, textBlockStyle)
--    // The inner block, if present, always has its direction set to LTR,
--    // so we need to inherit the direction and unicode-bidi style from the element.
--    textBlockStyle->setDirection(style()->direction());
--    textBlockStyle->setUnicodeBidi(style()->unicodeBidi());
--
--    bool disabled = updateUserModifyProperty(node(), textBlockStyle);
--    if (disabled)
--        textBlockStyle->setColor(disabledTextColor(textBlockStyle->visitedDependentColor(CSSPropertyColor), startStyle->visitedDependentColor(CSSPropertyBackgroundColor)));
end

function LayoutTextControl:StyleDidChange(diff, oldStyle)
    LayoutTextControl._super.StyleDidChange(self, diff, oldStyle);

	self.innerTextStyle = self:CreateInnerTextStyle(self:Style());

--    Element* innerText = innerTextElement();
--    if (!innerText)
--        return;
--    RenderBlock* innerTextRenderer = toRenderBlock(innerText->renderer());
--    if (innerTextRenderer) {
--        // We may have set the width and the height in the old style in layout().
--        // Reset them now to avoid getting a spurious layout hint.
--        innerTextRenderer->style()->setHeight(Length());
--        innerTextRenderer->style()->setWidth(Length());
--        innerTextRenderer->setStyle(createInnerTextStyle(style()));
--        innerText->setNeedsStyleRecalc();
--    }
--    textFormControlElement()->updatePlaceholderVisibility(false);
end

-- virtual function
function LayoutTextControl:AdjustControlHeightBasedOnLineHeight(lineHeight)

end
-- virtual function
function LayoutTextControl:InnerTextRenderBox()

end

function LayoutTextControl:ComputeLogicalHeight()

	local innerTextRenderBox = self:InnerTextRenderBox();
	self:SetHeight(0);
--	setHeight(innerTextRenderBox:BorderTop() + innerTextRenderBox:BorderBottom() +
--              innerTextRenderBox:PaddingTop() + innerTextRenderBox:PaddingBottom() +
--              innerTextRenderBox:MarginTop() + innerTextRenderBox:MarginBottom());
    self:AdjustControlHeightBasedOnLineHeight(innerTextRenderBox:Style():ComputedLineHeight());
    self:SetHeight(self:Height() + self:BorderAndPaddingHeight());

    -- We are able to have a horizontal scrollbar if the overflow style is scroll, or if its auto and there's no word wrap.
--    if (self:Style():OverflowX() == OSCROLL or  (self:Style():OverflowX() == OAUTO and self:Style():WordWrap() == NormalWordWrap)) then
--        self:SetHeight(self:Height() + scrollbarThickness());
--	end

    LayoutTextControl._super.ComputeLogicalHeight(self);
end

-- virtual function
function LayoutTextControl:PreferredContentWidth(charWidth)

end

function LayoutTextControl:ComputePreferredLogicalWidths()
    --ASSERT(preferredLogicalWidthsDirty());

    self.minPreferredLogicalWidth = 0;
    self.maxPreferredLogicalWidth = 0;

    if (self:Style():Width():IsFixed() and self:Style():Width():Value() > 0) then
        self.minPreferredLogicalWidth = self:ComputeContentBoxLogicalWidth(self:Style():Width():Value());
		self.maxPreferredLogicalWidth = self.minPreferredLogicalWidth;
    else
        -- Use average character width. Matches IE.
--        AtomicString family = style()->font().family().family();
--        RenderBox* innerTextRenderBox = innerTextElement()->renderBox();
--        self.maxPreferredLogicalWidth = preferredContentWidth(getAvgCharWidth(family)) + innerTextRenderBox->paddingLeft() + innerTextRenderBox->paddingRight();
		self.maxPreferredLogicalWidth = self:PreferredContentWidth(UniString.GetSpaceWidth(self:Style():Font():ToString()));
    end

    if (self:Style():MinWidth():IsFixed() and self:Style():MinWidth():Value() > 0) then
        self.maxPreferredLogicalWidth = math.max(self.maxPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():MinWidth():Value()));
        self.minPreferredLogicalWidth = math.max(self.minPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():MinWidth():Value()));
    elseif (self:Style():Width():IsPercent() or (self:Style():Width():IsAuto() and self:Style():Height():IsPercent())) then
        self.minPreferredLogicalWidth = 0;
    else
        self.minPreferredLogicalWidth = self.maxPreferredLogicalWidth;
	end

    if (self:Style():MaxWidth():IsFixed()) then
        self.maxPreferredLogicalWidth = math.min(self.maxPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():MaxWidth():Value()));
        self.minPreferredLogicalWidth = math.min(self.minPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():MaxWidth():Value()));
    end

    local toAdd = self:BorderAndPaddingWidth();

    self.minPreferredLogicalWidth = self.minPreferredLogicalWidth + toAdd;
    self.maxPreferredLogicalWidth = self.maxPreferredLogicalWidth + toAdd;

    self:SetPreferredLogicalWidthsDirty(false);
end

