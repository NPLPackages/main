--[[
Title: 
Author(s): LiPeng
Date: 2018/11/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutTextControlSingleLine.lua");
local LayoutTextControlSingleLine = commonlib.gettable("System.Windows.mcml.layout.LayoutTextControlSingleLine");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutTextControl.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutText.lua");
local LayoutText = commonlib.gettable("System.Windows.mcml.layout.LayoutText");
local Length = commonlib.gettable("System.Windows.mcml.platform.Length");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");
local LayoutTextControlSingleLine = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutTextControl"), commonlib.gettable("System.Windows.mcml.layout.LayoutTextControlSingleLine"));

local LengthTypeEnum = Length.LengthTypeEnum;

function LayoutTextControlSingleLine:ctor()
	
end

function LayoutTextControlSingleLine:IsTextField()
	return true;
end

-- virtual function
function LayoutTextControlSingleLine:AdjustControlHeightBasedOnLineHeight(lineHeight)
	self:SetHeight(self:Height() + lineHeight);
end

function LayoutTextControlSingleLine:PreferredContentWidth(charWidth)
	local factor = 20;
	return charWidth * factor;
end

function LayoutTextControlSingleLine:CreateInnerTextStyle(startStyle)
	local textBlockStyle = ComputedStyle:new();   
    textBlockStyle:InheritFrom(startStyle);
    self:AdjustInnerTextStyle(startStyle, textBlockStyle);

    textBlockStyle:SetWhiteSpace(ComputedStyleConstants.WhiteSpaceEnum.PRE);
    textBlockStyle:SetWordWrap(ComputedStyleConstants.WordWrapEnum.NormalWordWrap);
    textBlockStyle:SetOverflowX(ComputedStyleConstants.OverflowEnum.OHIDDEN);
    textBlockStyle:SetOverflowY(ComputedStyleConstants.OverflowEnum.OHIDDEN);

--    if (m_desiredInnerTextHeight >= 0)
--        textBlockStyle->setHeight(Length(m_desiredInnerTextHeight, Fixed));
    -- Do not allow line-height to be smaller than our default.
    if (textBlockStyle:FontMetrics():lineSpacing() > self:LineHeight(true, "HorizontalLine", "PositionOfInteriorLineBoxes")) then
        textBlockStyle:SetLineHeight(Length:new(-100.0, LengthTypeEnum.Percent));
	end

    textBlockStyle:SetDisplay(ComputedStyleConstants.DisplayEnum.BLOCK);

    -- We're adding one extra pixel of padding to match WinIE.
    textBlockStyle:SetPaddingLeft(Length:new(1, LengthTypeEnum.Fixed));
    textBlockStyle:SetPaddingRight(Length:new(1, LengthTypeEnum.Fixed));

    return textBlockStyle;
end

function LayoutTextControlSingleLine:Layout()
    -- FIXME: We should remove the height-related hacks in layout() and
    -- styleDidChange(). We need them because
    -- - Center the inner elements vertically if the input height is taller than
    --   the intrinsic height of the inner elements.
    -- - Shrink the inner elment heights if the input height is samller than the
    --   intrinsic heights of the inner elements.

    -- We don't honor paddings and borders for textfields without decorations
    -- and type=search if the text height is taller than the contentHeight()
    -- because of compability.

    local oldHeight = self:Height();
    self:ComputeLogicalHeight();

    local oldWidth = self:Width();
    self:ComputeLogicalWidth();

    local relayoutChildren = oldHeight ~= self:Height() or oldWidth ~= self:Width();

    LayoutTextControlSingleLine._super.LayoutBlock(self, relayoutChildren);
end

--void RenderTextControlSingleLine::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutTextControlSingleLine:Paint(paintInfo, paintOffset)
    LayoutTextControlSingleLine._super.Paint(self, paintInfo, paintOffset);
	local control = self:GetControl();
	if(control) then
		control:SetTextMargin(self:PaddingLeft(), self:PaddingTop(), self:PaddingRight(), self:PaddingBottom());
	end
--    if (paintInfo.phase == PaintPhaseBlockBackground && m_shouldDrawCapsLockIndicator) {
--        LayoutRect contentsRect = contentBoxRect();
--
--        // Center vertically like the text.
--        contentsRect.setY((height() - contentsRect.height()) / 2);
--
--        // Convert the rect into the coords used for painting the content
--        contentsRect.moveBy(paintOffset + location());
--        theme()->paintCapsLockIndicator(this, paintInfo, contentsRect);
--    }
end

function LayoutTextControlSingleLine:PaintContents(paintInfo, paintOffset)

end

function LayoutTextControlSingleLine:UpdateFromElement()
	-- If we're an input element, we may need to change our button text.
    --if (node()->hasTagName(inputTag)) {
	if(self:Node() and self:Node():HasTagName("input")) then
        --HTMLInputElement* input = static_cast<HTMLInputElement*>(node());
		local input = self:Node();
       -- String value = input->valueWithDefault();
        self:SetText(input:ValueWithDefault());
    end
end

function LayoutTextControlSingleLine:SetText(str)
	local innerText = LayoutText:new():init(nil, str or "");
    innerText:SetStyle(self:CreateInnerTextStyle(self:Style()));
    self:AddChild(innerText);
end
