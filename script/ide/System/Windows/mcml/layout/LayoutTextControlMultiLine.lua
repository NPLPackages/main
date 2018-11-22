--[[
Title: 
Author(s): LiPeng
Date: 2018/11/22
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutTextControlMultiLine.lua");
local LayoutTextControlMultiLine = commonlib.gettable("System.Windows.mcml.layout.LayoutTextControlMultiLine");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutTextControl.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutText.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBox.lua");
local LayoutBox = commonlib.gettable("System.Windows.mcml.layout.LayoutBox");
local LayoutText = commonlib.gettable("System.Windows.mcml.layout.LayoutText");
local Length = commonlib.gettable("System.Windows.mcml.platform.Length");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");
local LayoutTextControlMultiLine = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutTextControl"), commonlib.gettable("System.Windows.mcml.layout.LayoutTextControlMultiLine"));

local LengthTypeEnum = Length.LengthTypeEnum;

function LayoutTextControlMultiLine:ctor()
	--self.m_innerText = nil;
end

function LayoutTextControlMultiLine:IsTextArea()
	return true;
end

-- virtual function
function LayoutTextControlMultiLine:AdjustControlHeightBasedOnLineHeight(lineHeight)
	self:SetHeight(self:Height() + lineHeight * self:Node():Rows());
end

function LayoutTextControlMultiLine:PreferredContentWidth(charWidth)
	--int factor = static_cast<HTMLTextAreaElement*>(node())->cols();
	local factor = self:Node():Cols();
	return charWidth * factor + self:ScrollbarThickness();
end

--LayoutUnit RenderTextControlMultiLine::baselinePosition(FontBaseline baselineType, bool firstLine, LineDirectionMode direction, LinePositionMode linePositionMode) const
function LayoutTextControlMultiLine:BaselinePosition(baselineType, firstLine, direction, linePositionMode)
    return LayoutBox.BaselinePosition(self, baselineType, firstLine, direction, linePositionMode);
end


function LayoutTextControlMultiLine:CreateInnerTextStyle(startStyle)
	local textBlockStyle = ComputedStyle:new();   
    textBlockStyle:InheritFrom(startStyle);
    self:AdjustInnerTextStyle(startStyle, textBlockStyle);

    textBlockStyle:SetDisplay(ComputedStyleConstants.DisplayEnum.BLOCK);

    return textBlockStyle;
end

--function LayoutTextControlMultiLine:Layout()
--    -- FIXME: We should remove the height-related hacks in layout() and
--    -- styleDidChange(). We need them because
--    -- - Center the inner elements vertically if the input height is taller than
--    --   the intrinsic height of the inner elements.
--    -- - Shrink the inner elment heights if the input height is samller than the
--    --   intrinsic heights of the inner elements.
--
--    -- We don't honor paddings and borders for textfields without decorations
--    -- and type=search if the text height is taller than the contentHeight()
--    -- because of compability.
--
--    local oldHeight = self:Height();
--    self:ComputeLogicalHeight();
--
--    local oldWidth = self:Width();
--    self:ComputeLogicalWidth();
--
--    local relayoutChildren = oldHeight ~= self:Height() or oldWidth ~= self:Width();
--
--    LayoutTextControlMultiLine._super.LayoutBlock(self, relayoutChildren);
--end

--void RenderTextControlSingleLine::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutTextControlMultiLine:Paint(paintInfo, paintOffset)
    LayoutTextControlMultiLine._super.Paint(self, paintInfo, paintOffset);
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
--
--function LayoutTextControlMultiLine:PaintContents(paintInfo, paintOffset)
--
--end
