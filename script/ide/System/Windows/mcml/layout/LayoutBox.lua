--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBox.lua");
local LayoutBox = commonlib.gettable("System.Windows.mcml.layout.LayoutBox");
LayoutBox:new():init();
------------------------------------------------------------

// ***** THE BOX MODEL *****
// The CSS box model is based on a series of nested boxes:
// http://www.w3.org/TR/CSS21/box.html
//
//       |----------------------------------------------------|
//       |                                                    |
//       |                   margin-top                       |
//       |                                                    |
//       |     |-----------------------------------------|    |
//       |     |                                         |    |
//       |     |             border-top                  |    |
//       |     |                                         |    |
//       |     |    |--------------------------|----|    |    |
//       |     |    |                          |    |    |    |
//       |     |    |       padding-top        |####|    |    |
//       |     |    |                          |####|    |    |
//       |     |    |    |----------------|    |####|    |    |
//       |     |    |    |                |    |    |    |    |
//       | ML  | BL | PL |  content box   | PR | SW | BR | MR |
//       |     |    |    |                |    |    |    |    |
//       |     |    |    |----------------|    |    |    |    |
//       |     |    |                          |    |    |    |
//       |     |    |      padding-bottom      |    |    |    |
//       |     |    |--------------------------|----|    |    |
//       |     |    |                      ####|    |    |    |
//       |     |    |     scrollbar height ####| SC |    |    |
//       |     |    |                      ####|    |    |    |
//       |     |    |-------------------------------|    |    |
//       |     |                                         |    |
//       |     |           border-bottom                 |    |
//       |     |                                         |    |
//       |     |-----------------------------------------|    |
//       |                                                    |
//       |                 margin-bottom                      |
//       |                                                    |
//       |----------------------------------------------------|
//
// BL = border-left
// BR = border-right
// ML = margin-left
// MR = margin-right
// PL = padding-left
// PR = padding-right
// SC = scroll corner (contains UI for resizing (see the 'resize' property)
// SW = scrollbar width


]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBoxModelObject.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutModel.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/InlineBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntPoint.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local Point = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");
local InlineBox = commonlib.gettable("System.Windows.mcml.layout.InlineBox");
local Length = commonlib.gettable("System.Windows.mcml.platform.Length");
local Size = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
local LayoutModel = commonlib.gettable("System.Windows.mcml.layout.LayoutModel");
local LayoutBox = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBoxModelObject"), commonlib.gettable("System.Windows.mcml.layout.LayoutBox"));

local LayoutRect = Rect;
local LayoutSize, IntSize = Size, Size;
local LayoutPoint, IntPoint = Point, Point;

local FloatEnum = ComputedStyleConstants.FloatEnum;
local WritingModeEnum = ComputedStyleConstants.WritingModeEnum;
local VisibilityEnum = ComputedStyleConstants.VisibilityEnum;
local PositionEnum = ComputedStyleConstants.PositionEnum;
local OverflowEnum = ComputedStyleConstants.OverflowEnum;
local BoxSizingEnum = ComputedStyleConstants.BoxSizingEnum;
local BoxOrientEnum = ComputedStyleConstants.BoxOrientEnum;
local BoxAlignmentEnum = ComputedStyleConstants.BoxAlignmentEnum;
local TextAlignEnum = ComputedStyleConstants.TextAlignEnum;
local LengthTypeEnum = Length.LengthTypeEnum;
local TextDirectionEnum = ComputedStyleConstants.TextDirectionEnum;

function LayoutBox:ctor()
	self.name = "LayoutBox";

	-- Our overflow information.
	self.overflow = nil;

	self.marginLeft = 0;
	self.marginRight = 0;
	self.marginTop = 0;
	self.marginBottom = 0;

	-- The width/height of the contents + borders + padding.  The x/y location is relative to our container (which is not always our parent).
    self.frame_rect = Rect:new();

	self.minPreferredLogicalWidth = -1;
	self.maxPreferredLogicalWidth = -1;

	self.inlineBoxWrapper = nil;

	
end

function LayoutBox:init(node)
	LayoutBox._super.init(self, node);
	self:SetIsBox();

	return self;
end

function LayoutBox:X()
	return self.frame_rect:X();
end

function LayoutBox:Y()
	return self.frame_rect:Y();
end

function LayoutBox:SetX(x)
	return self.frame_rect:SetX(x);
end

function LayoutBox:SetY(y)
	return self.frame_rect:SetY(y);
end

function LayoutBox:Width()
	return self.frame_rect:Width();
end

function LayoutBox:Height()
	return self.frame_rect:Height();
end

function LayoutBox:SetWidth(width)
	return self.frame_rect:SetWidth(width);
end

function LayoutBox:SetHeight(height)
	return self.frame_rect:SetHeight(height);
end

function LayoutBox:Location()
	return self.frame_rect:Location();
end

function LayoutBox:LocationOffset()
	return Size:new(self:X(), self:Y());
end

function LayoutBox:SetLocation(location)
	self.frame_rect:SetLocation(location);
end

function LayoutBox:Size()
	return self.frame_rect:Size();
end

function LayoutBox:SetSize(size)
	return self.frame_rect:SetSize(size);
end

function LayoutBox:Move(x,y)
	self.frame_rect:Move(x,y);
--	self:SetPos(x,y);
--	if(beMovedControl and self.pageElement) then
--		local control = self.pageElement:GetControl();
--		if(control) then
--			control:move(x,y);
--		end
--	end
end

function LayoutBox:FrameRect()
	return self.frame_rect;
end

function LayoutBox:SetFrameRect(rect)
	self.frame_rect = rect;
end

function LayoutBox:Offset(offset_x, offset_y, beMovedControl)
	local x = self.frame_rect.x + offset_x;
	local y = self.frame_rect.y + offset_y;
	self:Move(x,y,beMovedControl);
end

-- frame_rect x or y changed
function LayoutBox:LocationChanged()

end
-- frame_rect width or heihgt changed
function LayoutBox:SizeChanged()

end

function LayoutBox:MarginTop()
	return self.marginTop;
end

function LayoutBox:MarginBottom()
	return self.marginBottom;
end

function LayoutBox:MarginLeft()
	return self.marginLeft;
end

function LayoutBox:MarginRight()
	return self.marginRight;
end

function LayoutBox:SetMarginTop(margin)
	self.marginTop = margin;
end

function LayoutBox:SetMarginBottom(margin)
	self.marginBottom = margin;
end

function LayoutBox:SetMarginLeft(margin)
	self.marginLeft = margin;
end

function LayoutBox:SetMarginRight(margin)
	self.marginRight = margin;
end

function LayoutBox:MarginBefore()
	local write_mode = self:Style():WritingMode();
	if(write_mode ==  WritingModeEnum.TopToBottomWritingMode) then
		return self.marginTop;
	elseif(write_mode ==  WritingModeEnum.BottomToTopWritingMode) then
		return self.marginBottom;
	elseif(write_mode ==  WritingModeEnum.LeftToRightWritingMode) then
		return self.marginLeft;
	elseif(write_mode ==  WritingModeEnum.RightToLeftWritingMode) then
		return self.marginRight;
	end
	return self.marginTop;
end

function LayoutBox:MarginAfter()
	local write_mode = self:Style():WritingMode();
	if(write_mode ==  WritingModeEnum.TopToBottomWritingMode) then
		return self.marginBottom;
	elseif(write_mode ==  WritingModeEnum.BottomToTopWritingMode) then
		return self.marginTop;
	elseif(write_mode ==  WritingModeEnum.LeftToRightWritingMode) then
		return self.marginRight;
	elseif(write_mode ==  WritingModeEnum.RightToLeftWritingMode) then
		return self.marginLeft;
	end
	return self.marginBottom;
end

function LayoutBox:MarginStart()
	local start_;
	if(self:IsHorizontalWritingMode()) then
		start_ = if_else(self:Style():IsLeftToRightDirection(), self.marginLeft, self.marginRight);
	else
		start_ = if_else(self:Style():IsLeftToRightDirection(), self.marginTop, self.marginBottom);
	end
	return start_;
end

function LayoutBox:MarginEnd()
	local end_;
	if(self:IsHorizontalWritingMode()) then
		end_ = if_else(self:Style():IsLeftToRightDirection(), self.marginRight, self.marginLeft);
	else
		end_ = if_else(self:Style():IsLeftToRightDirection(), self.marginBottom, self.marginTop);
	end
	return end_;
end

function LayoutBox:SetMarginStart(margin)
    if (self:IsHorizontalWritingMode()) then
        if (self:Style():IsLeftToRightDirection()) then
            self.marginLeft = margin;
        else
            self.marginRight = margin;
		end
    else
        if (self:Style():IsLeftToRightDirection()) then
            self.marginTop = margin;
        else
            self.marginBottom = margin;
		end
    end
end

function LayoutBox:SetMarginEnd(margin)
    if (self:IsHorizontalWritingMode()) then
        if (self:Style():IsLeftToRightDirection()) then
            self.marginRight = margin;
        else
            self.marginLeft = margin;
		end
    else
        if (self:Style():IsLeftToRightDirection()) then
            self.marginBottom = margin;
        else
            self.marginTop = margin;
		end
    end
end

function LayoutBox:SetMarginBefore(margin)
	local write_mode = self:Style():WritingMode();
	if(write_mode ==  WritingModeEnum.TopToBottomWritingMode) then
		self.marginTop = margin;
	elseif(write_mode ==  WritingModeEnum.BottomToTopWritingMode) then
		self.marginBottom = margin;
	elseif(write_mode ==  WritingModeEnum.LeftToRightWritingMode) then
		self.marginLeft = margin;
	elseif(write_mode ==  WritingModeEnum.RightToLeftWritingMode) then
		self.marginRight = margin;
	end
end

function LayoutBox:ComputeBlockDirectionMargins(containingBlock)
	if (self:IsTableCell()) then
        -- FIXME: Not right if we allow cells to have different directionality than the table.  If we do allow this, though,
        -- we may just do it with an extra anonymous block inside the cell.
        self:SetMarginBefore(0);
        self:SetMarginAfter(0);
        return;
    end

    -- Margins are calculated with respect to the logical width of
    -- the containing block (8.3)
    local cw = self:ContainingBlockLogicalWidthForContent();

    local containingBlockStyle = containingBlock:Style();
    containingBlock:SetMarginBeforeForChild(self, self:Style():MarginBeforeUsing(containingBlockStyle):CalcMinValue(cw));
    containingBlock:SetMarginAfterForChild(self, self:Style():MarginAfterUsing(containingBlockStyle):CalcMinValue(cw));
end

function LayoutBox:SetMarginAfter(margin)
	local write_mode = self:Style():WritingMode();
	if(write_mode ==  WritingModeEnum.TopToBottomWritingMode) then
		self.marginBottom = margin;
	elseif(write_mode ==  WritingModeEnum.BottomToTopWritingMode) then
		self.marginTop = margin;
	elseif(write_mode ==  WritingModeEnum.LeftToRightWritingMode) then
		self.marginRight = margin;
	elseif(write_mode ==  WritingModeEnum.RightToLeftWritingMode) then
		self.marginLeft = margin;
	end
end

function LayoutBox:BorderBoxRect()
	return Rect:new_from_pool(0, 0, self:Width(), self:Height());
end

function LayoutBox:BorderBoundingBox()
	return self:BorderBoxRect();
end

function LayoutBox:PaddingBoxRect()
	return self:ClientLeft(), self:ClientTop(), self:ClientWidth(), self:ClientHeight();
end

function LayoutBox:VerticalScrollbarWidth()
	return 0;
end

function LayoutBox:HorizontalScrollbarHeight()
	return 0;
end

function LayoutBox:ScrollbarLogicalHeight()
	return if_else(self:Style():IsHorizontalWritingMode(), self:HorizontalScrollbarHeight(), self:VerticalScrollbarWidth());
end

function LayoutBox:ClientLeft()
	return self:BorderLeft();
end

function LayoutBox:ClientTop()
	return self:BorderTop();
end

function LayoutBox:ClientWidth()
	return self:Width() - self:BorderLeft() - self:BorderRight() - self:VerticalScrollbarWidth();
end

function LayoutBox:ClientHeight()
	return self:Height() - self:BorderTop() - self:BorderBottom() - self:HorizontalScrollbarHeight();
end

function LayoutBox:ClientLogicalWidth()
	return if_else(self:Style():IsHorizontalWritingMode(), self:ClientWidth(), self:ClientHeight());
end

function LayoutBox:ClientLogicalHeight()
	return if_else(self:Style():IsHorizontalWritingMode(), self:ClientHeight(), self:ClientWidth());
end

function LayoutBox:ClientLogicalBottom()
	return self:BorderBefore() + self:ClientLogicalHeight();
end

function LayoutBox:ClientBoxRect()
	return LayoutRect:new(self:ClientLeft(), self:ClientTop(), self:ClientWidth(), self:ClientHeight());
end

function LayoutBox:ClientSize()
	return self:ClientWidth(), self:ClientHeight();
end

function LayoutBox:OffsetWidth()
	return self.frame_rect.w;
end

function LayoutBox:OffsetHeight()
	return self.frame_rect.h;
end

function LayoutBox:ContentWidth()
	return self:ClientWidth() - self:PaddingLeft() - self:PaddingRight();
end

function LayoutBox:ContentHeight()
	return self:ClientHeight() - self:PaddingTop() - self:PaddingBottom();
end

function LayoutBox:ContentLogicalWidth()
	local width = self:ContentWidth();
	if(not self:Style():IsHorizontalWritingMode()) then
		width = self:ContentHeight();
	end
	return width;
end

function LayoutBox:ContentLogicalHeight()
	local height = self:ContentHeight();
	if(not self:Style():IsHorizontalWritingMode()) then
		height = self:ContentWidth();
	end
	return height;
end

function LayoutBox:ContentSize()
	return self:ContentWidth(), self:ContentHeight();
end

-- return the left,top,width,height
function LayoutBox:ContentBoxRect()
	return self:BorderLeft() + self:PaddingLeft(), self:BorderTop() + self:PaddingTop(), self:ContentWidth(), self:ContentHeight();
end

function LayoutBox:ContentBoxOffset()
	return self:BorderLeft() + self:PaddingLeft(), self:BorderTop() + self:PaddingTop();
end

function LayoutBox:LogicalLeft()
	return if_else(self:Style():IsHorizontalWritingMode(), self:X(), self:Y());
end

function LayoutBox:LogicalRight()
	return self:LogicalLeft() + self:LogicalWidth();
end

function LayoutBox:LogicalTop()
	return if_else(self:Style():IsHorizontalWritingMode(), self:Y(), self:X());
end

function LayoutBox:LogicalBottom()
	return self:LogicalTop() + self:LogicalHeight();
end

function LayoutBox:LogicalWidth()
	local width = self:Width();
	if(not self:Style():IsHorizontalWritingMode()) then
		width = self:Height();
	end
	return width;
	--return if_else(self:Style():IsHorizontalWritingMode(), self:Width(), self:Height());
end

function LayoutBox:LogicalHeight()
	return if_else(self:Style():IsHorizontalWritingMode(), self:Height(), self:Width());
end

function LayoutBox:SetLogicalLeft(left)
	if(self:Style():IsHorizontalWritingMode()) then
		self:SetX(left);
	else
		self:SetY(left);
	end
end

function LayoutBox:SetLogicalTop(top)
	if(self:Style():IsHorizontalWritingMode()) then
		self:SetY(top);
	else
		self:SetX(top);
	end
end

function LayoutBox:SetLogicalLocation(location)
	if(not self:Style():IsHorizontalWritingMode()) then
		location = location:TransposedPoint();
	end
	self:SetLocation(location);
end

function LayoutBox:SetLogicalWidth(width)
	if(self:Style():IsHorizontalWritingMode()) then
		self:SetWidth(width);
	else
		self:SetHeight(width);
	end
end

function LayoutBox:SetLogicalHeight(height)
	if(self:Style():IsHorizontalWritingMode()) then
		self:SetHeight(height);
	else
		self:SetWidth(height);
	end
end

function LayoutBox:SetLogicalSize(size)
	if(not self:Style():IsHorizontalWritingMode()) then
		size = size:TransposedSize();
	end
	self:SetSize(size);
end

function LayoutBox:ComputeBorderBoxLogicalWidth(width)
	local bordersPlusPadding = self:BorderAndPaddingLogicalWidth();
	if (self:Style():BoxSizing() == BoxSizingEnum.CONTENT_BOX) then
        return width + bordersPlusPadding;
	end
    return math.max(width, bordersPlusPadding);
end

function LayoutBox:ComputeBorderBoxLogicalHeight(height)
	local bordersPlusPadding = self:BorderAndPaddingLogicalHeight();
	if (self:Style():BoxSizing() == BoxSizingEnum.CONTENT_BOX) then
        return height + bordersPlusPadding;
	end
    return math.max(height, bordersPlusPadding);
end

function LayoutBox:ComputeContentBoxLogicalWidth(width)
	if (self:Style():BoxSizing() == BoxSizingEnum.CONTENT_BOX) then
        width = width - self:BorderAndPaddingLogicalWidth();
	end
    return math.max(0, width);
end

function LayoutBox:ComputeContentBoxLogicalHeight(height)
	if (self:Style():BoxSizing() == BoxSizingEnum.CONTENT_BOX) then
        height = height - self:BorderAndPaddingLogicalHeight();
	end
    return math.max(0, height);
end

function LayoutBox:HasAutoVerticalScrollbar()
	return self:HasOverflowClip() and (self:Style():OverflowY() == OverflowEnum.OAUTO or self:Style():OverflowY() == OverflowEnum.OOVERLAY);
end

function LayoutBox:HasAutoHorizontalScrollbar()
	return self:HasOverflowClip() and (self:Style():OverflowX() == OverflowEnum.OAUTO or self:Style():OverflowX() == OverflowEnum.OOVERLAY);
end

function LayoutBox:ScrollsOverflow()
	return self:ScrollsOverflowX() or self:ScrollsOverflowY();
end

function LayoutBox:ScrollsOverflowX()
	return self:HasOverflowClip() and (self:Style():OverflowX() == OverflowEnum.OSCROLL or self:HasAutoHorizontalScrollbar());
end

function LayoutBox:ScrollsOverflowY()
	return self:HasOverflowClip() and (self:Style():OverflowY() == OverflowEnum.OSCROLL or self:HasAutoVerticalScrollbar());
end

-----------------------------------------------------------------------------------------------------
----------------	webkit/chromium	function

function LayoutBox:ComputePreferredLogicalWidths()
	self:SetPreferredLogicalWidthsDirty(false);
end

function LayoutBox:NeedsPreferredWidthsRecalculation()
    return self:Style():PaddingStart():IsPercent() or self:Style():PaddingEnd():IsPercent();
end

function LayoutBox:MinPreferredLogicalWidth()
	if (self:PreferredLogicalWidthsDirty()) then
        self:ComputePreferredLogicalWidths();
	end
    return self.minPreferredLogicalWidth;
end

function LayoutBox:MaxPreferredLogicalWidth()
	if (self:PreferredLogicalWidthsDirty()) then
        self:ComputePreferredLogicalWidths();
	end
    return self.maxPreferredLogicalWidth;
end

function LayoutBox:ClearLayoutOverflow()
	if(not self.overflow) then
		return;
	end
end

function LayoutBox:HasControlClip()
	return false;
end

function LayoutBox:Layout()
	if(not self:NeedsLayout()) then
		return;
	end

	local child = self:FirstChild();
	if(not child) then
		self:SetNeedsLayout(false);
		return;
	end

	while (child) do
		child:LayoutIfNeeded();
		child = child:NextSibling();
	end

	self:SetNeedsLayout(false);
end

function LayoutBox:ComputeLogicalWidth()
	--TODO: fixed this function
	self:ComputeLogicalWidthInRegion();
end

--function LayoutBox:LengthIsIntrinsicOrAuto(length)
--	if (logicalWidth == nil or type(logicalWidth) == "number") then
--		return true;
--	end
--	return false;
--end

-- @param widthType: can be "LogicalWidth","MinLogicalWidth","MaxLogicalWidth";
function LayoutBox:ComputeLogicalWidthUsing(widthType, availableLogicalWidth)
    local logicalWidthResult = self:LogicalWidth();
    local logicalWidth;
    if (widthType == "LogicalWidth") then
        logicalWidth = self:Style():LogicalWidth();
    elseif (widthType == "MinLogicalWidth") then
        logicalWidth = self:Style():LogicalMinWidth();
    else
        logicalWidth = self:Style():LogicalMaxWidth();
	end
    --if (logicalWidth.isIntrinsicOrAuto()) then
	if (logicalWidth:IsIntrinsicOrAuto()) then
        local marginStart = self:Style():MarginStart():CalcMinValue(availableLogicalWidth);
        local marginEnd = self:Style():MarginEnd():CalcMinValue(availableLogicalWidth);
        if (availableLogicalWidth) then
            logicalWidthResult = availableLogicalWidth - marginStart - marginEnd;
		end
        if (self:SizesToIntrinsicLogicalWidth(widthType)) then
            logicalWidthResult = math.max(logicalWidthResult, self:MinPreferredLogicalWidth());
            logicalWidthResult = math.min(logicalWidthResult, self:MaxPreferredLogicalWidth());
        end
    else -- FIXME: If the containing block flow is perpendicular to our direction we need to use the available logical height instead.
        logicalWidthResult = self:ComputeBorderBoxLogicalWidth(logicalWidth:CalcValue(availableLogicalWidth)); 
	end
    return logicalWidthResult;
end

-- Whether or not the element shrinks to its intrinsic width (rather than filling the width
-- of a containing block).  HTML4 buttons, <select>s, <input>s, legends, and floating/compact elements do this.
function LayoutBox:SizesToIntrinsicLogicalWidth(value)
	return false;
end

function LayoutBox:ComputeLogicalWidthInRegion(region, offsetFromLogicalTopOfFirstPage)
	if(self:IsPositioned()) then
		self:ComputePositionedLogicalWidth(region, offsetFromLogicalTopOfFirstPage);
	end
	-- If layout is limited to a subtree, the subtree root's logical width does not change.
    -- if (node() and view():frameView() and view():frameView():layoutRoot(true) == this)
	if(self:IsLayoutView()) then
		return;
	end

	local treatAsReplaced = false;

	local logicalWidthLength = self:Style():LogicalWidth();

	local cb = self:ContainingBlock();
	local containerLogicalWidth = math.max(0, self:ContainingBlockLogicalWidthForContentInRegion(region, offsetFromLogicalTopOfFirstPage));
	local hasPerpendicularContainingBlock = cb:IsHorizontalWritingMode() ~= self:IsHorizontalWritingMode();
    local containerWidthInInlineDirection = containerLogicalWidth;
    if (hasPerpendicularContainingBlock) then
        containerWidthInInlineDirection = PerpendicularContainingBlockLogicalHeight();
	end

	if (self:IsInline() and not self:IsInlineBlockOrInlineTable()) then
        -- just calculate margins
        self:SetMarginStart(self:Style():MarginStart():CalcMinValue(containerLogicalWidth));
        self:SetMarginEnd(self:Style():MarginEnd():CalcMinValue(containerLogicalWidth));
        if (treatAsReplaced) then
            --self:SetLogicalWidth(math.max(self:LogicalWidthLength.calcFloatValue(0) + borderAndPaddingLogicalWidth(), minPreferredLogicalWidth()));
		end
        return;
    end
	if(treatAsReplaced) then
		-- FIXME: add the code latter
	else

		self:SetLogicalWidth(self:ComputeLogicalWidthUsing("LogicalWidth", containerWidthInInlineDirection));

        -- Calculate MaxLogicalWidth
        if (not self:Style():LogicalMaxWidth():IsUndefined()) then
            local maxLogicalWidth = self:ComputeLogicalWidthUsing("MaxLogicalWidth", containerWidthInInlineDirection);
            if (self:LogicalWidth() > maxLogicalWidth) then
                self:SetLogicalWidth(maxLogicalWidth);
                logicalWidthLength = self:Style():LogicalMaxWidth();
            end
        end

        -- Calculate MinLogicalWidth
		local minLogicalWidth = self:ComputeLogicalWidthUsing("MinLogicalWidth", containerWidthInInlineDirection);
		if (self:LogicalWidth() < minLogicalWidth) then
			self:SetLogicalWidth(minLogicalWidth);
			logicalWidthLength = self:Style():LogicalMinWidth();
		end
	end

	-- Fieldsets are currently the only objects that stretch to their minimum width.
    if (self:StretchesToMinIntrinsicLogicalWidth()) then
        self:SetLogicalWidth(math.max(self:LogicalWidth(), self:MinPreferredLogicalWidth()));
        --logicalWidthLength = Length(logicalWidth(), Fixed);
		logicalWidthLength = Length:new(self:LogicalWidth(), LengthTypeEnum.Fixed);
    end

    -- Margin calculations.
    if (logicalWidthLength:IsAuto() or hasPerpendicularContainingBlock) then
        self:SetMarginStart(self:Style():MarginStart():CalcMinValue(containerLogicalWidth));
        self:SetMarginEnd(self:Style():MarginEnd():CalcMinValue(containerLogicalWidth));
    else
        self:ComputeInlineDirectionMargins(cb, containerLogicalWidth, self:LogicalWidth());
	end
    if (not hasPerpendicularContainingBlock and containerLogicalWidth and containerLogicalWidth ~= (self:LogicalWidth() + self:MarginStart() + self:MarginEnd())
            and not self:IsFloating() and self:IsInline() and not cb:IsFlexibleBoxIncludingDeprecated()) then
        cb:SetMarginEndForChild(self, containerLogicalWidth - self:LogicalWidth() - cb:MarginStartForChild(self));
	end
end

function LayoutBox:IsFlexibleBoxIncludingDeprecated()
	--TODO: fixed this function
	return false;
end

function LayoutBox:ComputeInlineDirectionMargins(containingBlock, containerWidth, childWidth)
	local containingBlockStyle = containingBlock:Style();
    local marginStartLength = self:Style():MarginStartUsing(containingBlockStyle);
    local marginEndLength = self:Style():MarginEndUsing(containingBlockStyle);

    if (self:IsFloating() or self:IsInline()) then
        -- Inline blocks/tables and floats don't have their margins increased.
        containingBlock:SetMarginStartForChild(self, marginStartLength:CalcMinValue(containerWidth));
        containingBlock:SetMarginEndForChild(self, marginEndLength:CalcMinValue(containerWidth));
        return;
    end

    -- Case One: The object is being centered in the containing block's available logical width.
    if ((marginStartLength:IsAuto() and marginEndLength:IsAuto() and childWidth < containerWidth)
        or (not marginStartLength:IsAuto() and not marginEndLength:IsAuto() and containingBlock:Style():TextAlign() == TextAlignEnum.WEBKIT_CENTER)) then
        containingBlock:SetMarginStartForChild(self, math.max(0, (containerWidth - childWidth) / 2));
        containingBlock:SetMarginEndForChild(self, containerWidth - childWidth - containingBlock:MarginStartForChild(self));
        return;
    end
    
    -- Case Two: The object is being pushed to the start of the containing block's available logical width.
    if (marginEndLength:IsAuto() and childWidth < containerWidth) then
        containingBlock:SetMarginStartForChild(self, marginStartLength:CalcValue(containerWidth));
        containingBlock:SetMarginEndForChild(self, containerWidth - childWidth - containingBlock:MarginStartForChild(self));
        return;
    end
    
    -- Case Three: The object is being pushed to the end of the containing block's available logical width.
    local pushToEndFromTextAlign = not marginEndLength:IsAuto() and ((not containingBlockStyle:IsLeftToRightDirection() and containingBlockStyle:TextAlign() == TextAlignEnum.WEBKIT_LEFT)
        or (containingBlockStyle:IsLeftToRightDirection() and containingBlockStyle:TextAlign() == TextAlignEnum.WEBKIT_RIGHT));
    if ((marginStartLength:IsAuto() and childWidth < containerWidth) or pushToEndFromTextAlign) then
        containingBlock:SetMarginEndForChild(self, marginEndLength:CalcValue(containerWidth));
        containingBlock:SetMarginStartForChild(self, containerWidth - childWidth - containingBlock:MarginEndForChild(self));
        return;
    end
    
    -- Case Four: Either no auto margins, or our width is >= the container width (css2.1, 10.3.3).  In that case
    -- auto margins will just turn into 0.
    containingBlock:SetMarginStartForChild(self, marginStartLength:CalcMinValue(containerWidth));
    containingBlock:SetMarginEndForChild(self, marginEndLength:CalcMinValue(containerWidth));
end

function LayoutBox:StretchesToMinIntrinsicLogicalWidth()
	return false; 
end

function LayoutBox:PerpendicularContainingBlockLogicalHeight()
	--TODO: fixed this function
	return 0;
end

function LayoutBox:IsWritingModeRoot()
	return not self:Parent() or self:Parent():Style():WritingMode() ~= self:Style():WritingMode();
end

function LayoutBox:IsDeprecatedFlexItem()
	return false;
end

function LayoutBox:AvoidsFloats()
    return self:IsReplaced() or self:HasOverflowClip() or self:IsHR() or self:IsLegend() or self:IsWritingModeRoot() or self:IsDeprecatedFlexItem();
end

function LayoutBox:ShrinkToAvoidFloats()
	-- Floating objects don't shrink.  Objects that don't avoid floats don't shrink.  Marquees don't shrink.
    --if ((self:IsInline() and not self:IsHTMLMarquee()) or self:AvoidsFloats() or self:IsFloating()) then
	if ((self:IsInline() and not self:IsHTMLMarquee()) or not self:AvoidsFloats() or self:IsFloating()) then
        return false;
	end
    -- All auto-width objects that avoid floats should always use lineWidth.
	return self:Style():Width() == nil;
    --return self:Style():Width().isAuto(); 
end

function LayoutBox:ContainingBlockLogicalWidthForContent()
	local cb = self:ContainingBlock();
	if(self:ShrinkToAvoidFloats() and not self:InRenderFlowThread()) then
		return cb:AvailableLogicalWidthForLine(self:LogicalTop(), false);
	end
	return cb:AvailableLogicalWidth();
end

function LayoutBox:ContainingBlockLogicalWidthForContentInRegion(region, offsetFromLogicalTopOfFirstPage)
	if(not region) then
		return self:ContainingBlockLogicalWidthForContent();
	end
	-- FIXME: add the region condition;
	return 0;
end

function LayoutBox:ComputePositionedLogicalWidthReplaced()
	--TODO: fixed this function latter.
end

--static void computeInlineStaticDistance(Length& logicalLeft, Length& logicalRight, const RenderBox* child, const RenderBoxModelObject* containerBlock, LayoutUnit containerLogicalWidth, RenderRegion* region)
local function computeInlineStaticDistance(logicalLeft, logicalRight, child, containerBlock, containerLogicalWidth, region)
    if (not logicalLeft:IsAuto() or not logicalRight:IsAuto()) then
        return;
	end
	--TODO: fixed latter.
end

function LayoutBox:SetMarginLogicalLeftRight(left, right)
	local isHorizontal = self:IsHorizontalWritingMode();
	if(isHorizontal) then
		self.marginLeft, self.marginRight = left, right;
		return;
	end
	self.marginTop, self.marginBottom = left, right;
end

function LayoutBox:GetMarginLogicalLeftRight()
	local isHorizontal = self:IsHorizontalWritingMode();
	if(isHorizontal) then
		return self.marginLeft, self.marginRight;
	end
	return self.marginTop, self.marginBottom;
end

function LayoutBox:ComputePositionedLogicalWidth(region, offsetFromLogicalTopOfFirstPage)
	if (self:IsReplaced()) then
        self:ComputePositionedLogicalWidthReplaced(); -- FIXME: Patch for regions when we add replaced element support.
        return;
    end

	local containerBlock = self:Container();

	local containerLogicalWidth = self:ContainingBlockLogicalWidthForPositioned(containerBlock, region, offsetFromLogicalTopOfFirstPage);

	-- Use the container block's direction except when calculating the static distance
    -- This conforms with the reference results for abspos-replaced-width-margin-000.htm
    -- of the CSS 2.1 test suite
    local containerDirection = containerBlock:Style():Direction();

    local isHorizontal = self:IsHorizontalWritingMode();
    local bordersPlusPadding = self:BorderAndPaddingLogicalWidth();
    local marginLogicalLeft = if_else(isHorizontal, self:Style():MarginLeft(), self:Style():MarginTop());
    local marginLogicalRight = if_else(isHorizontal, self:Style():MarginRight(), self:Style():MarginBottom());
	local marginLogicalLeftAlias, marginLogicalRightAlias = self:GetMarginLogicalLeftRight();
--    LayoutUnit& marginLogicalLeftAlias = isHorizontal ? m_marginLeft : m_marginTop;
--    LayoutUnit& marginLogicalRightAlias = isHorizontal ? m_marginRight : m_marginBottom;

    local logicalLeftLength = self:Style():LogicalLeft();
    local logicalRightLength = self:Style():LogicalRight();

	--[[
	/*---------------------------------------------------------------------------*\
     * For the purposes of this section and the next, the term "static position"
     * (of an element) refers, roughly, to the position an element would have had
     * in the normal flow. More precisely:
     *
     * * The static position for 'left' is the distance from the left edge of the
     *   containing block to the left margin edge of a hypothetical box that would
     *   have been the first box of the element if its 'position' property had
     *   been 'static' and 'float' had been 'none'. The value is negative if the
     *   hypothetical box is to the left of the containing block.
     * * The static position for 'right' is the distance from the right edge of the
     *   containing block to the right margin edge of the same hypothetical box as
     *   above. The value is positive if the hypothetical box is to the left of the
     *   containing block's edge.
     *
     * But rather than actually calculating the dimensions of that hypothetical box,
     * user agents are free to make a guess at its probable position.
     *
     * For the purposes of calculating the static position, the containing block of
     * fixed positioned elements is the initial containing block instead of the
     * viewport, and all scrollable boxes should be assumed to be scrolled to their
     * origin.
    \*---------------------------------------------------------------------------*/
	]]

	-- see FIXME 1
    -- Calculate the static distance if needed.
    computeInlineStaticDistance(logicalLeftLength, logicalRightLength, self, containerBlock, containerLogicalWidth, region);

	-- Calculate constraint equation values for 'width' case.
    local logicalWidthResult, logicalLeftResult;

	logicalWidthResult, marginLogicalLeftAlias, marginLogicalRightAlias, logicalLeftResult = 
		self:ComputePositionedLogicalWidthUsing(self:Style():LogicalWidth(), containerBlock, containerDirection,
			containerLogicalWidth, bordersPlusPadding,
			logicalLeftLength, logicalRightLength, marginLogicalLeft, marginLogicalRight,
			logicalWidthResult, marginLogicalLeftAlias, marginLogicalRightAlias, logicalLeftResult);

	self:SetMarginLogicalLeftRight(marginLogicalLeftAlias, marginLogicalRightAlias);

	self:SetLogicalWidth(logicalWidthResult);
    self:SetLogicalLeft(logicalLeftResult);


	-- Calculate constraint equation values for 'max-width' case.
    if (not self:Style():LogicalMaxWidth():IsUndefined()) then
        local maxLogicalWidth, maxMarginLogicalLeft, maxMarginLogicalRight, maxLogicalLeftPos;

        maxLogicalWidth, maxMarginLogicalLeft, maxMarginLogicalRight, maxLogicalLeftPos = 
			self:ComputePositionedLogicalWidthUsing(self:Style():LogicalMaxWidth(), containerBlock, containerDirection,
                containerLogicalWidth, bordersPlusPadding,
                logicalLeftLength, logicalRightLength, marginLogicalLeft, marginLogicalRight,
                maxLogicalWidth, maxMarginLogicalLeft, maxMarginLogicalRight, maxLogicalLeftPos);
		
		

        if (self:LogicalWidth() > maxLogicalWidth) then
            self:SetLogicalWidth(maxLogicalWidth);
            marginLogicalLeftAlias = maxMarginLogicalLeft;
            marginLogicalRightAlias = maxMarginLogicalRight;
			self:SetMarginLogicalLeftRight(marginLogicalLeftAlias, marginLogicalRightAlias);
            self:SetLogicalLeft(maxLogicalLeftPos);
        end
    end

	-- Calculate constraint equation values for 'min-width' case.
    if (not self:Style():LogicalMinWidth():IsZero()) then
        local minLogicalWidth, minMarginLogicalLeft, minMarginLogicalRight, minLogicalLeftPos;

        minLogicalWidth, minMarginLogicalLeft, minMarginLogicalRight, minLogicalLeftPos = 
			self:ComputePositionedLogicalWidthUsing(self:Style():LogicalMinWidth(), containerBlock, containerDirection,
                    containerLogicalWidth, bordersPlusPadding,
                    logicalLeftLength, logicalRightLength, marginLogicalLeft, marginLogicalRight,
                    minLogicalWidth, minMarginLogicalLeft, minMarginLogicalRight, minLogicalLeftPos);

        if (self:LogicalWidth() < minLogicalWidth) then
            self:SetLogicalWidth(minLogicalWidth);
            marginLogicalLeftAlias = minMarginLogicalLeft;
            marginLogicalRightAlias = minMarginLogicalRight;
			self:SetMarginLogicalLeftRight(marginLogicalLeftAlias, marginLogicalRightAlias);
            self:SetLogicalLeft(minLogicalLeftPos);
        end
    end


	if (self:StretchesToMinIntrinsicLogicalWidth() and self:LogicalWidth() < self:MinPreferredLogicalWidth() - bordersPlusPadding) then
        logicalWidthResult, marginLogicalLeftAlias, marginLogicalRightAlias, logicalLeftResult = 
			self:ComputePositionedLogicalWidthUsing(Length:new(self:MinPreferredLogicalWidth() - bordersPlusPadding, LengthTypeEnum.Fixed), containerBlock, containerDirection,
                    containerLogicalWidth, bordersPlusPadding,
                    logicalLeftLength, logicalRightLength, marginLogicalLeft, marginLogicalRight,
                    logicalWidthResult, marginLogicalLeftAlias, marginLogicalRightAlias, logicalLeftResult);

		self:SetMarginLogicalLeftRight(marginLogicalLeftAlias, marginLogicalRightAlias);
        self:SetLogicalWidth(logicalWidthResult);
        self:SetLogicalLeft(logicalLeftResult);
    end

	-- Put logicalWidth() into correct form.
    self:SetLogicalWidth(self:LogicalWidth() + bordersPlusPadding);

--	// Adjust logicalLeft if we need to for the flipped version of our writing mode in regions.
--    if (inRenderFlowThread() && !region && isWritingModeRoot() && isHorizontalWritingMode() == containerBlock->isHorizontalWritingMode()) {
--        LayoutUnit logicalLeftPos = logicalLeft();
--        const RenderBlock* cb = toRenderBlock(containerBlock);
--        LayoutUnit cbPageOffset = offsetFromLogicalTopOfFirstPage - logicalTop();
--        RenderRegion* cbRegion = cb->regionAtBlockOffset(cbPageOffset);
--        cbRegion = cb->clampToStartAndEndRegions(cbRegion);
--        RenderBoxRegionInfo* boxInfo = cb->renderBoxRegionInfo(cbRegion, cbPageOffset);
--        if (boxInfo) {
--            logicalLeftPos += boxInfo->logicalLeft();
--            setLogicalLeft(logicalLeftPos);
--        }
--    }
end

function LayoutBox:ShouldComputeSizeAsReplaced()
	return self:IsReplaced() and self:IsInlineBlockOrInlineTable();
end

function LayoutBox:HasOverrideHeight()
	return false;
	--return gOverrideHeightMap && gOverrideHeightMap->contains(this);
end

function LayoutBox:ComputePositionedLogicalHeightReplaced()
	--TODO: fixed this function latter.
end

function LayoutBox:SetMarginBeforeAfter(before, after)
	local isHorizontal = self:IsHorizontalWritingMode();
	local isFlipped = self:Style():IsFlippedBlocksWritingMode();
	if(isHorizontal) then
		if(isFlipped) then
			self.marginBottom, self.marginTop = before, after;
			return;
		end
		self.marginTop, self.marginBottom = before, after;
		return;
	end

	if(isFlipped) then
		self.marginRight, self.marginLeft = before, after;
		return;
	end
	self.marginLeft, self.marginRight = before, after;
end

function LayoutBox:GetMarginBeforeAfter()
	local isHorizontal = self:IsHorizontalWritingMode();
	local isFlipped = self:Style():IsFlippedBlocksWritingMode();
	if(isHorizontal) then
		if(isFlipped) then
			return self.marginBottom, self.marginTop;
		end
		return self.marginTop, self.marginBottom;
	end

	if(isFlipped) then
		return self.marginRight, self.marginLeft;
	end
	return self.marginLeft, self.marginRight;
end

-- static void computeBlockStaticDistance(Length& logicalTop, Length& logicalBottom, const RenderBox* child, const RenderBoxModelObject* containerBlock)
local function computeBlockStaticDistance(logicalTop, logicalBottom, child, containerBlock)
    if (not logicalTop:IsAuto() or not logicalBottom:IsAuto()) then
        return;
	end
    
    -- FIXME: The static distance computation has not been patched for mixed writing modes.
    local staticLogicalTop = child:Layer():StaticBlockPosition() - containerBlock:BorderBefore();

	local curr = child:Parent();
	while(curr and curr ~= containerBlock) do
		if (curr:IsBox() and not curr:IsTableRow()) then
            staticLogicalTop = staticLogicalTop + curr:LogicalTop();
		end
		curr = curr:Container();
	end
    logicalTop:SetValue(LengthTypeEnum.Fixed, staticLogicalTop);
end

function LayoutBox:ComputePositionedLogicalHeight()
	if (self:IsReplaced()) then
        self:ComputePositionedLogicalHeightReplaced();
        return;
    end

	-- The following is based off of the W3C Working Draft from April 11, 2006 of
    -- CSS 2.1: Section 10.6.4 "Absolutely positioned, non-replaced elements"
    -- <http://www.w3.org/TR/2005/WD-CSS21-20050613/visudet.html#abs-non-replaced-height>
    -- (block-style-comments in this function and in computePositionedLogicalHeightUsing()
    -- correspond to text from the spec)


    -- We don't use containingBlock(), since we may be positioned by an enclosing relpositioned inline.
    local containerBlock = self:Container();

    local containerLogicalHeight = self:ContainingBlockLogicalHeightForPositioned(containerBlock);

    local bordersPlusPadding = self:BorderAndPaddingLogicalHeight();
    local marginBefore = self:Style():MarginBefore();
    local marginAfter = self:Style():MarginAfter();
	local marginBeforeAlias, marginAfterAlias = self:GetMarginBeforeAfter();
    -- LayoutUnit& marginBeforeAlias = isHorizontal ? (isFlipped ? m_marginBottom : m_marginTop) : (isFlipped ? m_marginRight: m_marginLeft);
    -- LayoutUnit& marginAfterAlias = isHorizontal ? (isFlipped ? m_marginTop : m_marginBottom) : (isFlipped ? m_marginLeft: m_marginRight);

    local logicalTopLength = self:Style():LogicalTop();
    local logicalBottomLength = self:Style():LogicalBottom();
        
	--[[
    /*---------------------------------------------------------------------------*\
     * For the purposes of this section and the next, the term "static position"
     * (of an element) refers, roughly, to the position an element would have had
     * in the normal flow. More precisely, the static position for 'top' is the
     * distance from the top edge of the containing block to the top margin edge
     * of a hypothetical box that would have been the first box of the element if
     * its 'position' property had been 'static' and 'float' had been 'none'. The
     * value is negative if the hypothetical box is above the containing block.
     *
     * But rather than actually calculating the dimensions of that hypothetical
     * box, user agents are free to make a guess at its probable position.
     *
     * For the purposes of calculating the static position, the containing block
     * of fixed positioned elements is the initial containing block instead of
     * the viewport.
    \*---------------------------------------------------------------------------*/
	]]
	
    -- see FIXME 1
    -- Calculate the static distance if needed.
    computeBlockStaticDistance(logicalTopLength, logicalBottomLength, this, containerBlock);

    local logicalHeightResult; -- Needed to compute overflow.
    local logicalTopPos;

    -- Calculate constraint equation values for 'height' case.
    logicalHeightResult, marginBeforeAlias, marginAfterAlias, logicalTopPos = 
		self:ComputePositionedLogicalHeightUsing(self:Style():LogicalHeight(), containerBlock, containerLogicalHeight, bordersPlusPadding,
			logicalTopLength, logicalBottomLength, marginBefore, marginAfter,
			logicalHeightResult, marginBeforeAlias, marginAfterAlias, logicalTopPos);
	self:SetMarginBeforeAfter(marginBeforeAlias, marginAfterAlias);
    self:SetLogicalTop(logicalTopPos);

    -- Avoid doing any work in the common case (where the values of min-height and max-height are their defaults).
    -- see FIXME 2

    -- Calculate constraint equation values for 'max-height' case.
    if (not self:Style():LogicalMaxHeight():IsUndefined()) then
        local maxLogicalHeight, maxMarginBefore, maxMarginAfter, maxLogicalTopPos;

        maxLogicalHeight, maxMarginBefore, maxMarginAfter, maxLogicalTopPos = 
			self:ComputePositionedLogicalHeightUsing(self:Style():LogicalMaxHeight(), containerBlock, containerLogicalHeight, bordersPlusPadding,
                logicalTopLength, logicalBottomLength, marginBefore, marginAfter,
                maxLogicalHeight, maxMarginBefore, maxMarginAfter, maxLogicalTopPos);

        if (logicalHeightResult > maxLogicalHeight) then
            logicalHeightResult = maxLogicalHeight;
            marginBeforeAlias = maxMarginBefore;
            marginAfterAlias = maxMarginAfter;
			self:SetMarginBeforeAfter(marginBeforeAlias, marginAfterAlias);
            self:SetLogicalTop(maxLogicalTopPos);
        end
    end

    -- Calculate constraint equation values for 'min-height' case.
    if (not self:Style():LogicalMinHeight():IsZero()) then
        local minLogicalHeight, minMarginBefore, minMarginAfter, minLogicalTopPos;

        minLogicalHeight, minMarginBefore, minMarginAfter, minLogicalTopPos = 
			self:ComputePositionedLogicalHeightUsing(self:Style():LogicalMinHeight(), containerBlock, containerLogicalHeight, bordersPlusPadding,
                logicalTopLength, logicalBottomLength, marginBefore, marginAfter,
                minLogicalHeight, minMarginBefore, minMarginAfter, minLogicalTopPos);

        if (logicalHeightResult < minLogicalHeight) then
            logicalHeightResult = minLogicalHeight;
            marginBeforeAlias = minMarginBefore;
            marginAfterAlias = minMarginAfter;
			self:SetMarginBeforeAfter(marginBeforeAlias, marginAfterAlias);
            self:SetLogicalTop(minLogicalTopPos);
        end
    end

    -- Set final height value.
    self:SetLogicalHeight(logicalHeightResult + bordersPlusPadding);
    
--    -- Adjust logicalTop if we need to for perpendicular writing modes in regions.
--    if (inRenderFlowThread() && self:IsHorizontalWritingMode() ~= containerBlock:IsHorizontalWritingMode()) then
--        LayoutUnit logicalTopPos = logicalTop();
--        const RenderBlock* cb = toRenderBlock(containerBlock);
--        LayoutUnit cbPageOffset = cb->offsetFromLogicalTopOfFirstPage() - logicalLeft();
--        RenderRegion* cbRegion = cb->regionAtBlockOffset(cbPageOffset);
--        cbRegion = cb->clampToStartAndEndRegions(cbRegion);
--        RenderBoxRegionInfo* boxInfo = cb->renderBoxRegionInfo(cbRegion, cbPageOffset);
--        if (boxInfo) then
--            logicalTopPos += boxInfo:LogicalLeft();
--            self:SetLogicalTop(logicalTopPos);
--        end
--    end
end

function LayoutBox:ComputeReplacedLogicalHeight()
	--TODO: fixed this function
end

function LayoutBox:ComputePercentageLogicalHeight(h)
	local result = -1;
    
    -- In quirks mode, blocks with auto height are skipped, and we keep looking for an enclosing
    -- block that may have a specified height and then use it. In strict mode, this violates the
    -- specification, which states that percentage heights just revert to auto if the containing
    -- block has an auto height. We still skip anonymous containing blocks in both modes, though, and look
    -- only at explicit containers.
    local skippedAutoHeightContainingBlock = false;
    local cb = self:ContainingBlock();
--    while (!cb->isRenderView() && !cb->isBody() && !cb->isTableCell() && !cb->isPositioned() && cb->style()->logicalHeight().isAuto()) {
--        if (!document()->inQuirksMode() && !cb->isAnonymousBlock())
--            break;
--        skippedAutoHeightContainingBlock = true;
--        cb = cb->containingBlock();
--        cb->addPercentHeightDescendant(this);
--    }
--
--    // A positioned element that specified both top/bottom or that specifies height should be treated as though it has a height
--    // explicitly specified that can be used for any percentage computations.
--    // FIXME: We can't just check top/bottom here.
--    // https://bugs.webkit.org/show_bug.cgi?id=46500
--    bool isPositionedWithSpecifiedHeight = cb->isPositioned() && (!cb->style()->logicalHeight().isAuto() || (!cb->style()->top().isAuto() && !cb->style()->bottom().isAuto()));
--
--    bool includeBorderPadding = isTable();
--
--    // Table cells violate what the CSS spec says to do with heights.  Basically we
--    // don't care if the cell specified a height or not.  We just always make ourselves
--    // be a percentage of the cell's current content height.
--    if (cb->isTableCell()) {
--        if (!skippedAutoHeightContainingBlock) {
--            if (!cb->hasOverrideHeight()) {
--                // Normally we would let the cell size intrinsically, but scrolling overflow has to be
--                // treated differently, since WinIE lets scrolled overflow regions shrink as needed.
--                // While we can't get all cases right, we can at least detect when the cell has a specified
--                // height or when the table has a specified height.  In these cases we want to initially have
--                // no size and allow the flexing of the table or the cell to its specified height to cause us
--                // to grow to fill the space.  This could end up being wrong in some cases, but it is
--                // preferable to the alternative (sizing intrinsically and making the row end up too big).
--                RenderTableCell* cell = toRenderTableCell(cb);
--                if (scrollsOverflowY() && (!cell->style()->logicalHeight().isAuto() || !cell->table()->style()->logicalHeight().isAuto()))
--                    return 0;
--                return -1;
--            }
--            result = cb->overrideHeight();
--            includeBorderPadding = true;
--        }
--    }
--    // Otherwise we only use our percentage height if our containing block had a specified
--    // height.
--    else if (cb->style()->logicalHeight().isFixed())
--        result = cb->computeContentBoxLogicalHeight(cb->style()->logicalHeight().value());
--    else if (cb->style()->logicalHeight().isPercent() && !isPositionedWithSpecifiedHeight) {
--        // We need to recur and compute the percentage height for our containing block.
--        result = cb->computePercentageLogicalHeight(cb->style()->logicalHeight());
--        // FIXME: Use < 0 or roughlyEquals when we move to float, see https://bugs.webkit.org/show_bug.cgi?id=66148
--        if (result != -1)
--            result = cb->computeContentBoxLogicalHeight(result);
--    } else if (cb->isRenderView() || (cb->isBody() && document()->inQuirksMode()) || isPositionedWithSpecifiedHeight) {
--        // Don't allow this to affect the block' height() member variable, since this
--        // can get called while the block is still laying out its kids.
--        LayoutUnit oldHeight = cb->logicalHeight();
--        cb->computeLogicalHeight();
--        result = cb->contentLogicalHeight();
--        cb->setLogicalHeight(oldHeight);
--    } else if (cb->isRoot() && isPositioned())
--        // Match the positioned objects behavior, which is that positioned objects will fill their viewport
--        // always.  Note we could only hit this case by recurring into computePercentageLogicalHeight on a positioned containing block.
--        result = cb->computeContentBoxLogicalHeight(cb->availableLogicalHeight());
--
--    // FIXME: Use < 0 or roughlyEquals when we move to float, see https://bugs.webkit.org/show_bug.cgi?id=66148
--    if (result != -1) {
--        result = height.calcValue(result);
--        if (includeBorderPadding) {
--            // It is necessary to use the border-box to match WinIE's broken
--            // box model.  This is essential for sizing inside
--            // table cells using percentage heights.
--            result -= borderAndPaddingLogicalHeight();
--            result = max<LayoutUnit>(0, result);
--        }
--    }
    return result;
end

function LayoutBox:ComputeBorderBoxLogicalHeight(height)
	local bordersPlusPadding = self:BorderAndPaddingLogicalHeight();
    if (self:Style():BoxSizing() == BoxSizingEnum.CONTENT_BOX) then
        return height + bordersPlusPadding;
	end
    return math.max(height, bordersPlusPadding);
end

function LayoutBox:ComputeLogicalHeightUsing(h)
    local logicalHeight = -1;
    if (not h:IsAuto()) then
        if (h:IsFixed()) then
            logicalHeight = h:Value();
        elseif (h:IsPercent()) then
            logicalHeight = self:ComputePercentageLogicalHeight(h);
		end
        -- FIXME: Use < 0 or roughlyEquals when we move to float, see https://bugs.webkit.org/show_bug.cgi?id=66148
        if (logicalHeight ~= -1) then
            logicalHeight = self:ComputeBorderBoxLogicalHeight(logicalHeight);
            return logicalHeight;
        end
    end
    return logicalHeight;
end

function LayoutBox:ComputeLogicalHeight()
	if (self:IsTableCell() or (self:IsInline() or self:IsReplaced())) then
        return;
	end
	local h;
    if (self:IsPositioned()) then
        self:ComputePositionedLogicalHeight();
    else
        local cb = self:ContainingBlock();
        local hasPerpendicularContainingBlock = cb:IsHorizontalWritingMode() ~= self:IsHorizontalWritingMode();
    
        if (not hasPerpendicularContainingBlock) then
            self:ComputeBlockDirectionMargins(cb);
		end
        -- For tables, calculate margins only.
        if (self:IsTable()) then
            if (hasPerpendicularContainingBlock) then
                self:ComputeInlineDirectionMargins(cb, self:ContainingBlockLogicalWidthForContent(), self:LogicalHeight());
			end
            return;
        end

        -- FIXME: Account for block-flow in flexible boxes.
        -- https://bugs.webkit.org/show_bug.cgi?id=46418
        local inHorizontalBox = self:Parent():IsDeprecatedFlexibleBox() and self:Parent():Style():BoxOrient() == BoxOrientEnum.HORIZONTAL;
        local stretching = self:Parent():Style():BoxAlign() == BoxAlignmentEnum.BSTRETCH;
        local treatAsReplaced = self:ShouldComputeSizeAsReplaced() and (not inHorizontalBox or not stretching);
        local checkMinMaxHeight = false;

        -- The parent box is flexing us, so it has increased or decreased our height.  We have to
        -- grab our cached flexible height.
        -- FIXME: Account for block-flow in flexible boxes.
        -- https://bugs.webkit.org/show_bug.cgi?id=46418
        if (self:HasOverrideHeight() and self:Parent():IsFlexibleBoxIncludingDeprecated()) then
            --h = Length(overrideHeight() - borderAndPaddingLogicalHeight(), Fixed);
        elseif (treatAsReplaced) then
            h = Length:new(self:ComputeReplacedLogicalHeight(), Length.LengthTypeEnum.Fixed);
        else
            h = self:Style():LogicalHeight();
            checkMinMaxHeight = true;
        end

        -- Block children of horizontal flexible boxes fill the height of the box.
        -- FIXME: Account for block-flow in flexible boxes.
        -- https://bugs.webkit.org/show_bug.cgi?id=46418
        if (h:IsAuto() and self:Parent():IsDeprecatedFlexibleBox() and self:Parent():Style():BoxOrient() == BoxOrientEnum.HORIZONTAL and self:Parent():IsStretchingChildren()) then
            h = Length:new(self:ParentBox():ContentLogicalHeight() - self:MarginBefore() - self:MarginAfter() - self:BorderAndPaddingLogicalHeight(), Length.LengthTypeEnum.Fixed);
            checkMinMaxHeight = false;
        end

        local heightResult;
        if (checkMinMaxHeight) then
            heightResult = self:ComputeLogicalHeightUsing(self:Style():LogicalHeight());
            -- FIXME: Use < 0 or roughlyEquals when we move to float, see https://bugs.webkit.org/show_bug.cgi?id=66148
            if (heightResult == -1) then
                heightResult = self:LogicalHeight();
			end
            local minH = self:ComputeLogicalHeightUsing(self:Style():LogicalMinHeight()); -- Leave as -1 if unset.
            local maxH = if_else(self:Style():LogicalMaxHeight():IsUndefined(), heightResult, self:ComputeLogicalHeightUsing(self:Style():LogicalMaxHeight()));
            if (maxH == -1) then
                maxH = heightResult;
			end
            heightResult = math.min(maxH, heightResult);
            heightResult = math.max(minH, heightResult);
        else
            -- The only times we don't check min/max height are when a fixed length has
            -- been given as an override.  Just use that.  The value has already been adjusted
            -- for box-sizing.
            heightResult = h:Value() + self:BorderAndPaddingLogicalHeight();
        end

        self:SetLogicalHeight(heightResult);
        
        if (hasPerpendicularContainingBlock) then
            self:ComputeInlineDirectionMargins(cb, self:ContainingBlockLogicalWidthForContent(), heightResult);
		end
    end
end

-- Called when a positioned object moves but doesn't necessarily change size.  A simplified layout is attempted
-- that just updates the object's position. If the size does change, the object remains dirty.
function LayoutBox:TryLayoutDoingPositionedMovementOnly()
	local oldWidth = self:Width();
	self:ComputeLogicalWidth();
	-- If we shrink to fit our width may have changed, so we still need full layout.
	if(oldWidth ~= self:Width()) then
		return false;
	end
	self:ComputeLogicalHeight();
	return true;
end

function LayoutBox:UpdateLayerTransform()
	--TODO: fixed this function
end

function LayoutBox:AvailableLogicalWidth()
	return self:ContentLogicalWidth();
end

function LayoutBox:PreviousSiblingBox()
	return LayoutBox._super.PreviousSibling(self);
end

function LayoutBox:NextSiblingBox()
	return LayoutBox._super.NextSibling(self);
end

function LayoutBox:FirstChildBox()
	return LayoutBox._super.FirstChild(self);
end

function LayoutBox:LastChildBox()
	return LayoutBox._super.LastChild(self);
end

function LayoutBox:CollapsedMarginBefore()
	return self:MarginBefore();
end

function LayoutBox:CollapsedMarginAfter()
	return self:MarginAfter();
end

function LayoutBox:IsSelfCollapsingBlock()
	return false;
end

function LayoutBox:DirtyLineBoxes(fullLayout)
	--TODO: fixed this function
end

function LayoutBox:StyleDidChange(diff, oldStyle)
	LayoutBox._super.StyleDidChange(self, diff, oldStyle);
end

function LayoutBox:UpdateBoxModelInfoFromStyle()
	--TODO: fixed this function
	LayoutBox._super.UpdateBoxModelInfoFromStyle(self);

	local isRootObject = self:IsRoot();
    local isViewObject = self:IsLayoutView();

--	// The root and the RenderView always paint their backgrounds/borders.
--    if (isRootObject || isViewObject)
--        setHasBoxDecorations(true);
	self:SetPositioned(self:Style():Position() == PositionEnum.AbsolutePosition or self:Style():Position() == PositionEnum.FixedPosition);
    self:SetFloating(self:Style():IsFloating() and (not self:IsPositioned() or self:Style():Floating() == FloatEnum.PositionedFloat));



	--self:SetHasTransform(self:Style():HasTransformRelatedProperty());
    --self:SetHasReflection(self:Style():BoxReflect());
end

function LayoutBox:SetInlineBoxWrapper(boxWrapper)
	self.inlineBoxWrapper = boxWrapper;
end

function LayoutBox:CreateInlineBox()
    return InlineBox:new():init(self);
end

function LayoutBox:LineHeight(firstLine, direction, linePositionMode)
	linePositionMode = linePositionMode or "PositionOnContainingLine";
	if (self:IsReplaced()) then
		return if_else(direction == "HorizontalLine", self.marginTop + self:Height() + self.marginBottom, self.marginRight + self:Width() + self.marginLeft);
	end
    return 0;
end

--virtual LayoutUnit baselinePosition(FontBaseline, bool firstLine, LineDirectionMode, LinePositionMode = PositionOnContainingLine) const = 0;
function LayoutBox:BaselinePosition(baselineType, firstLine, direction, linePositionMode)
	linePositionMode = linePositionMode or "PositionOnContainingLine";
	if (self:IsReplaced()) then
        local result = if_else(direction == "HorizontalLine", self.marginTop + self:Height() + self.marginBottom, self.marginRight + self:Width() + self.marginLeft);
        if (baselineType == "AlphabeticBaseline") then
            return result;
		end
        return result - result / 2;
    end
    return 0;
end

--void RenderBox::positionLineBox(InlineBox* box)
function LayoutBox:PositionLineBox(box)
    if (self:IsPositioned()) then
        -- Cache the x position only if we were an INLINE type originally.
--        bool wasInline = style()->isOriginalDisplayInlineType();
--        if (wasInline) {
--            // The value is cached in the xPos of the box.  We only need this value if
--            // our object was inline originally, since otherwise it would have ended up underneath
--            // the inlines.
--            RootInlineBox* root = box->root();
--            root->block()->setStaticInlinePositionForChild(this, root->lineTopWithLeading(), lroundf(box->logicalLeft()));
--            if (style()->hasStaticInlinePosition(box->isHorizontal()))
--                setChildNeedsLayout(true, false); // Just go ahead and mark the positioned object as needing layout, so it will update its position properly.
--        } else {
--            // Our object was a block originally, so we make our normal flow position be
--            // just below the line box (as though all the inlines that came before us got
--            // wrapped in an anonymous block, which is what would have happened had we been
--            // in flow).  This value was cached in the y() of the box.
--            layer()->setStaticBlockPosition(box->logicalTop());
--            if (style()->hasStaticBlockPosition(box->isHorizontal()))
--                setChildNeedsLayout(true, false); // Just go ahead and mark the positioned object as needing layout, so it will update its position properly.
--        }
--
--        // Nuke the box.
--        box->remove();
--        box->destroy(renderArena());
    elseif (self:IsReplaced()) then
--        setLocation(roundedLayoutPoint(FloatPoint(box->x(), box->y())));
--        if (m_inlineBoxWrapper)
--            deleteLineBoxWrapper();
--        m_inlineBoxWrapper = box;
    end
end

-- Visual and layout overflow are in the coordinate space of the box.  This means that they aren't purely physical directions.
-- For horizontal-tb and vertical-lr they will match physical directions, but for horizontal-bt and vertical-rl, the top/bottom and left/right
-- respectively are flipped when compared to their physical counterparts.  For example minX is on the left in vertical-lr,
-- but it is on the right in vertical-rl.
function LayoutBox:LayoutOverflowRect()
	--return m_overflow ? m_overflow->layoutOverflowRect() : clientBoxRect();
	return self:ClientBoxRect();
end

function LayoutBox:MinYLayoutOverflow()
	--return m_overflow? m_overflow->minYLayoutOverflow() : borderTop();
	return self:BorderTop();
end

function LayoutBox:MaxYLayoutOverflow()
	--return m_overflow ? m_overflow->maxYLayoutOverflow() : borderTop() + clientHeight();
	return self:BorderTop() + self:ClientHeight();
end

function LayoutBox:MinXLayoutOverflow()
	--return m_overflow ? m_overflow->minXLayoutOverflow() : borderLeft();
	return self:BorderLeft();
end

function LayoutBox:MaxXLayoutOverflow()
	--return m_overflow ? m_overflow->maxXLayoutOverflow() : borderLeft() + clientWidth();
	return self:BorderLeft() + self:ClientWidth();
end

function LayoutBox:MaxLayoutOverflow()
	return LayoutSize:new(self:MaxXLayoutOverflow(), self:MaxYLayoutOverflow());
end

function LayoutBox:LogicalLeftLayoutOverflow()
	return if_else(self:Style():IsHorizontalWritingMode(), self:MinXLayoutOverflow(), self:MinYLayoutOverflow());
end

function LayoutBox:LogicalRightLayoutOverflow()
	return if_else(self:Style():IsHorizontalWritingMode(), self:MaxXLayoutOverflow(), self:MaxYLayoutOverflow());
end

function LayoutBox:VisualOverflowRect()
--	if(self.overflow) then
--		-- TODO: add latter
--		--overflow:VisualOverflowRect();
--	end
	return self:BorderBoxRect();
end

function LayoutBox:MinYVisualOverflow()
	--return m_overflow? m_overflow->minYVisualOverflow() : 0;
	return 0;
end

function LayoutBox:MaxYVisualOverflow()
	--return m_overflow ? m_overflow->maxYVisualOverflow() : height();
	return self:Height();
end

function LayoutBox:MinXVisualOverflow()
	--return m_overflow ? m_overflow->minXVisualOverflow() : 0;
	return 0;
end

function LayoutBox:MaxXVisualOverflow()
	--return m_overflow ? m_overflow->maxXVisualOverflow() : width();
	return self:Width();
end

function LayoutBox:LogicalLeftVisualOverflow()
	return if_else(self:Style():IsHorizontalWritingMode(), self:MinXVisualOverflow(), self:MinYVisualOverflow());
end

function LayoutBox:LogicalRightVisualOverflow()
	return if_else(self:Style():IsHorizontalWritingMode(), self:MaxXVisualOverflow(), self:MaxYVisualOverflow());
end

function LayoutBox:ClippedOverflowRectForRepaint(repaintContainer)
    if (self:Style():Visibility() ~= VisibilityEnum.VISIBLE and not self:EnclosingLayer():HasVisibleContent()) then
        return LayoutRect:new();
	end

    local rect = self:VisualOverflowRect();

    local view = self:View();
    if (view) then
        -- FIXME: layoutDelta needs to be applied in parts before/after transforms and
        -- repaint containers. https://bugs.webkit.org/show_bug.cgi?id=23308
        rect:Move(view:LayoutDelta());
    end
    
    if (self:Style()) then
        if (self:Style():HasAppearance()) then
            -- The theme may wish to inflate the rect used when repainting.
            --theme()->adjustRepaintRect(this, r);
		end
        -- We have to use maximalOutlineSize() because a child might have an outline
        -- that projects outside of our overflowRect.
        if (view) then
            --ASSERT(style()->outlineSize() <= v->maximalOutlineSize());
            rect:Inflate(view:MaximalOutlineSize());
        end
    end
    
    self:ComputeRectForRepaint(repaintContainer, rect);
    return rect;
end

--void RenderBox::computeRectForRepaint(RenderBoxModelObject* repaintContainer, LayoutRect& rect, bool fixed) const
function LayoutBox:ComputeRectForRepaint(repaintContainer, rect, fixed)
	-- parameter default value;
	fixed = if_else(fixed == nil, false, fixed);

	-- TODO: fixed latter;

	if (repaintContainer == self) then
		return;
	end

    local object, containerSkipped = self:Container(repaintContainer);
	if(not object) then
		return;
	end

	local topLeft = rect:Location();
    topLeft:Move(self:X(), self:Y());

	local position = self:Style():Position();

	fixed = position == PositionEnum.FixedPosition;

	-- TODO: layer transform latter add


	object:ComputeRectForRepaint(repaintContainer, rect, fixed);
end

function LayoutBox:HasControlClip()
	return false;
end

--void RenderBox::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutBox:Paint(paintInfo, paintOffset)
    local adjustedPaintOffset = paintOffset + self:Location();
    -- default implementation. Just pass paint through to the children
--    PaintInfo childInfo(paintInfo);
--    childInfo.updatePaintingRootForChildren(this);
	local childInfo = paintInfo;
	local child = self:FirstChild();
	while(child) do
		child:Paint(childInfo, adjustedPaintOffset);
		child = child:NextSibling();
	end
end

--int flipForWritingMode(int position) const; // The offset is in the block direction (y for horizontal writing modes, x for vertical writing modes).
--IntPoint flipForWritingMode(const IntPoint&) const;
--IntSize flipForWritingMode(const IntSize&) const;
--void flipForWritingMode(IntRect&) const;
--FloatPoint flipForWritingMode(const FloatPoint&) const;
--void flipForWritingMode(FloatRect&) const;
function LayoutBox:FlipForWritingMode(position)
	if (not self:Style():IsFlippedBlocksWritingMode()) then
		return position;
	end
	
	if(position:IsRect()) then
		local rect = position;
		if (self:IsHorizontalWritingMode()) then
			rect:SetY(self:Height() - rect:MaxY());
		else
			rect:SetX(self:Width() - rect:MaxX());
		end
	elseif(position:IsSize()) then
		local offset = position;
		if (self:IsHorizontalWritingMode()) then
			return IntSize:new(offset:Width(), self:Height() - offset:Height());
		end
		return IntSize:new(self:Width() - offset:Width(), offset:Height());
	elseif(position:IsPoint()) then
		if (self:IsHorizontalWritingMode()) then
			return IntPoint:new(position:X(), self:Height() - position:Y());
		end
		return IntPoint:new(self:Width() - position:X(), position:Y());
	end
	return self:LogicalHeight() - position;
end

--void RenderBox::repaintDuringLayoutIfMoved(const LayoutRect& rect)
function LayoutBox:RepaintDuringLayoutIfMoved(rect)
	-- TODO: add latter;
end

--LayoutSize RenderBox::topLeftLocationOffset() const
function LayoutBox:TopLeftLocationOffset()
    local containerBlock = self:ContainingBlock();
    if (not containerBlock or containerBlock == self) then
        return self:LocationOffset();
	end
    
    local rect = self:FrameRect():clone_from_pool();
    containerBlock:FlipForWritingMode(rect); -- FIXME: This is wrong if we are an absolutely positioned object enclosed by a relative-positioned inline.
    return LayoutSize:new(rect:X(), rect:Y());
end

--int RenderBox::containingBlockLogicalHeightForPositioned(const RenderBoxModelObject* containingBlock, bool checkForPerpendicularWritingMode) const
function LayoutBox:ContainingBlockLogicalHeightForPositioned(containingBlock, checkForPerpendicularWritingMode)
	checkForPerpendicularWritingMode = if_else(checkForPerpendicularWritingMode == nil, true, checkForPerpendicularWritingMode);
    if (checkForPerpendicularWritingMode and containingBlock:IsHorizontalWritingMode() ~= self:IsHorizontalWritingMode()) then
        return self:ContainingBlockLogicalWidthForPositioned(containingBlock, 0, 0, false);
	end
	
	if (containingBlock:IsBox()) then
        local cb = containingBlock;
        local result = cb:ClientLogicalHeight();
--        if (inRenderFlowThread() && containingBlock->isRenderFlowThread() && enclosingRenderFlowThread()->isHorizontalWritingMode() == containingBlock->isHorizontalWritingMode())
--            return toRenderFlowThread(containingBlock)->contentLogicalHeightOfFirstRegion();
        return result;
    end
        
    --ASSERT(containingBlock->isRenderInline() && containingBlock->isRelPositioned());

    local flow = containingBlock;
    local first = flow:FirstLineBox();
    local last = flow:LastLineBox();

    -- If the containing block is empty, return a height of 0.
    if (not first or not last) then
        return 0;
	end
    local heightResult;
    local boundingBox = flow:LinesBoundingBox();
    if (containingBlock:IsHorizontalWritingMode()) then
        heightResult = boundingBox:Height();
    else
        heightResult = boundingBox:Width();
	end
    heightResult = heightResult - (containingBlock:BorderBefore() + containingBlock:BorderAfter());
    return heightResult;
end

--int RenderBox::containingBlockLogicalWidthForPositioned(const RenderBoxModelObject* containingBlock, RenderRegion* region,
--    LayoutUnit offsetFromLogicalTopOfFirstPage, bool checkForPerpendicularWritingMode) const
function LayoutBox:ContainingBlockLogicalWidthForPositioned(containingBlock, region, offsetFromLogicalTopOfFirstPage, checkForPerpendicularWritingMode)
	offsetFromLogicalTopOfFirstPage = if_else(offsetFromLogicalTopOfFirstPage == nil, 0, offsetFromLogicalTopOfFirstPage);
	checkForPerpendicularWritingMode = if_else(checkForPerpendicularWritingMode == nil, true, checkForPerpendicularWritingMode);
    if (checkForPerpendicularWritingMode and containingBlock:IsHorizontalWritingMode() ~= self:IsHorizontalWritingMode()) then
        return self:ContainingBlockLogicalHeightForPositioned(containingBlock, false);
	end

    if (containingBlock:IsBox()) then
        local cb = containingBlock;
        local result = cb:ClientLogicalWidth();
        if (self:InRenderFlowThread()) then
--            RenderBoxRegionInfo* boxInfo = 0;
--            if (!region) {
--                if (containingBlock->isRenderFlowThread() && !checkForPerpendicularWritingMode)
--                    return toRenderFlowThread(containingBlock)->contentLogicalWidthOfFirstRegion();
--                if (isWritingModeRoot()) {
--                    LayoutUnit cbPageOffset = offsetFromLogicalTopOfFirstPage - logicalTop();
--                    RenderRegion* cbRegion = cb->regionAtBlockOffset(cbPageOffset);
--                    cbRegion = cb->clampToStartAndEndRegions(cbRegion);
--                    boxInfo = cb->renderBoxRegionInfo(cbRegion, cbPageOffset);
--                }
--            } else if (region && enclosingRenderFlowThread()->isHorizontalWritingMode() == containingBlock->isHorizontalWritingMode()) {
--                RenderRegion* containingBlockRegion = cb->clampToStartAndEndRegions(region);
--                boxInfo = cb->renderBoxRegionInfo(containingBlockRegion, offsetFromLogicalTopOfFirstPage - logicalTop());
--            }
--            if (boxInfo)
--                return max(0, result - (cb->logicalWidth() - boxInfo->logicalWidth()));
        end
        return result;
    end

    --ASSERT(containingBlock->isRenderInline() && containingBlock->isRelPositioned());

--    const RenderInline* flow = toRenderInline(containingBlock);
--    InlineFlowBox* first = flow->firstLineBox();
--    InlineFlowBox* last = flow->lastLineBox();
--
--    // If the containing block is empty, return a width of 0.
--    if (!first || !last)
--        return 0;
--
--    LayoutUnit fromLeft;
--    LayoutUnit fromRight;
--    if (containingBlock->style()->isLeftToRightDirection()) {
--        fromLeft = first->logicalLeft() + first->borderLogicalLeft();
--        fromRight = last->logicalLeft() + last->logicalWidth() - last->borderLogicalRight();
--    } else {
--        fromRight = first->logicalLeft() + first->logicalWidth() - first->borderLogicalRight();
--        fromLeft = last->logicalLeft() + last->borderLogicalLeft();
--    }
--
--    return max<LayoutUnit>(0, fromRight - fromLeft);
	return 0;
end

--static void computeLogicalLeftPositionedOffset(LayoutUnit& logicalLeftPos, const RenderBox* child, LayoutUnit logicalWidthValue, const RenderBoxModelObject* containerBlock, LayoutUnit containerLogicalWidth)
local function computeLogicalLeftPositionedOffset(logicalLeftPos, child, logicalWidthValue, containerBlock, containerLogicalWidth)
    -- Deal with differing writing modes here.  Our offset needs to be in the containing block's coordinate space. If the containing block is flipped
    -- along this axis, then we need to flip the coordinate.  This can only happen if the containing block is both a flipped mode and perpendicular to us.
    if (containerBlock:IsHorizontalWritingMode() ~= child:IsHorizontalWritingMode() and containerBlock:Style():IsFlippedBlocksWritingMode()) then
        logicalLeftPos = containerLogicalWidth - logicalWidthValue - logicalLeftPos;
        logicalLeftPos = logicalLeftPos + if_else(child:IsHorizontalWritingMode(), containerBlock:BorderRight(), containerBlock:BorderBottom());
    else
        logicalLeftPos = logicalLeftPos + if_else(child:IsHorizontalWritingMode(), containerBlock:BorderLeft(), containerBlock:BorderTop());
	end
	return logicalLeftPos;
end

--void RenderBox::computePositionedLogicalWidthUsing(Length logicalWidth, const RenderBoxModelObject* containerBlock, TextDirection containerDirection,
--                                                   LayoutUnit containerLogicalWidth, LayoutUnit bordersPlusPadding,
--                                                   Length logicalLeft, Length logicalRight, Length marginLogicalLeft, Length marginLogicalRight,
--                                                   LayoutUnit& logicalWidthValue, LayoutUnit& marginLogicalLeftValue, LayoutUnit& marginLogicalRightValue, LayoutUnit& logicalLeftPos)
function LayoutBox:ComputePositionedLogicalWidthUsing(logicalWidth, containerBlock, containerDirection, containerLogicalWidth, bordersPlusPadding,
                                                   logicalLeft, logicalRight, marginLogicalLeft, marginLogicalRight,
                                                   logicalWidthValue, marginLogicalLeftValue, marginLogicalRightValue, logicalLeftPos)
	-- 'left' and 'right' cannot both be 'auto' because one would of been
    -- converted to the static position already
    -- ASSERT(!(logicalLeft.isAuto() && logicalRight.isAuto()));

    local logicalLeftValue = 0;

    local logicalWidthIsAuto = logicalWidth:IsIntrinsicOrAuto();
    local logicalLeftIsAuto = logicalLeft:IsAuto();
    local logicalRightIsAuto = logicalRight:IsAuto();

	if (not logicalLeftIsAuto and not logicalWidthIsAuto and not logicalRightIsAuto) then
		--[[
		/*-----------------------------------------------------------------------*\
         * If none of the three is 'auto': If both 'margin-left' and 'margin-
         * right' are 'auto', solve the equation under the extra constraint that
         * the two margins get equal values, unless this would make them negative,
         * in which case when direction of the containing block is 'ltr' ('rtl'),
         * set 'margin-left' ('margin-right') to zero and solve for 'margin-right'
         * ('margin-left'). If one of 'margin-left' or 'margin-right' is 'auto',
         * solve the equation for that value. If the values are over-constrained,
         * ignore the value for 'left' (in case the 'direction' property of the
         * containing block is 'rtl') or 'right' (in case 'direction' is 'ltr')
         * and solve for that value.
        \*-----------------------------------------------------------------------*/
		]]
        -- NOTE:  It is not necessary to solve for 'right' in the over constrained
        -- case because the value is not used for any further calculations.

        logicalLeftValue = logicalLeft:CalcValue(containerLogicalWidth);
        logicalWidthValue = self:ComputeContentBoxLogicalWidth(logicalWidth:CalcValue(containerLogicalWidth));

        local availableSpace = containerLogicalWidth - (logicalLeftValue + logicalWidthValue + logicalRight:CalcValue(containerLogicalWidth) + bordersPlusPadding);

        -- Margins are now the only unknown
        if (marginLogicalLeft:IsAuto() and marginLogicalRight:IsAuto()) then
            -- Both margins auto, solve for equality
            if (availableSpace >= 0) then
                marginLogicalLeftValue = availableSpace / 2; -- split the difference
                marginLogicalRightValue = availableSpace - marginLogicalLeftValue; -- account for odd valued differences
            else
                -- Use the containing block's direction rather than the parent block's
                -- per CSS 2.1 reference test abspos-non-replaced-width-margin-000.
                if (containerDirection == TextDirectionEnum.LTR) then
                    marginLogicalLeftValue = 0;
                    marginLogicalRightValue = availableSpace; -- will be negative
                else
                    marginLogicalLeftValue = availableSpace; -- will be negative
                    marginLogicalRightValue = 0;
                end
            end
        elseif (marginLogicalLeft:IsAuto()) then
            -- Solve for left margin
            marginLogicalRightValue = marginLogicalRight:CalcValue(containerLogicalWidth);
            marginLogicalLeftValue = availableSpace - marginLogicalRightValue;
        elseif (marginLogicalRight:IsAuto()) then
            -- Solve for right margin
            marginLogicalLeftValue = marginLogicalLeft:CalcValue(containerLogicalWidth);
            marginLogicalRightValue = availableSpace - marginLogicalLeftValue;
        else
            -- Over-constrained, solve for left if direction is RTL
            marginLogicalLeftValue = marginLogicalLeft:CalcValue(containerLogicalWidth);
            marginLogicalRightValue = marginLogicalRight:CalcValue(containerLogicalWidth);

            -- Use the containing block's direction rather than the parent block's
            -- per CSS 2.1 reference test abspos-non-replaced-width-margin-000.
            if (containerDirection == TextDirectionEnum.RTL) then
                logicalLeftValue = (availableSpace + logicalLeftValue) - marginLogicalLeftValue - marginLogicalRightValue;
			end
        end
	else
		--[[
		/*--------------------------------------------------------------------*\
         * Otherwise, set 'auto' values for 'margin-left' and 'margin-right'
         * to 0, and pick the one of the following six rules that applies.
         *
         * 1. 'left' and 'width' are 'auto' and 'right' is not 'auto', then the
         *    width is shrink-to-fit. Then solve for 'left'
         *
         *              OMIT RULE 2 AS IT SHOULD NEVER BE HIT
         * ------------------------------------------------------------------
         * 2. 'left' and 'right' are 'auto' and 'width' is not 'auto', then if
         *    the 'direction' property of the containing block is 'ltr' set
         *    'left' to the static position, otherwise set 'right' to the
         *    static position. Then solve for 'left' (if 'direction is 'rtl')
         *    or 'right' (if 'direction' is 'ltr').
         * ------------------------------------------------------------------
         *
         * 3. 'width' and 'right' are 'auto' and 'left' is not 'auto', then the
         *    width is shrink-to-fit . Then solve for 'right'
         * 4. 'left' is 'auto', 'width' and 'right' are not 'auto', then solve
         *    for 'left'
         * 5. 'width' is 'auto', 'left' and 'right' are not 'auto', then solve
         *    for 'width'
         * 6. 'right' is 'auto', 'left' and 'width' are not 'auto', then solve
         *    for 'right'
         *
         * Calculation of the shrink-to-fit width is similar to calculating the
         * width of a table cell using the automatic table layout algorithm.
         * Roughly: calculate the preferred width by formatting the content
         * without breaking lines other than where explicit line breaks occur,
         * and also calculate the preferred minimum width, e.g., by trying all
         * possible line breaks. CSS 2.1 does not define the exact algorithm.
         * Thirdly, calculate the available width: this is found by solving
         * for 'width' after setting 'left' (in case 1) or 'right' (in case 3)
         * to 0.
         *
         * Then the shrink-to-fit width is:
         * min(max(preferred minimum width, available width), preferred width).
        \*--------------------------------------------------------------------*/
		]]
        -- NOTE: For rules 3 and 6 it is not necessary to solve for 'right'
        -- because the value is not used for any further calculations.

        -- Calculate margins, 'auto' margins are ignored.
        marginLogicalLeftValue = marginLogicalLeft:CalcMinValue(containerLogicalWidth);
        marginLogicalRightValue = marginLogicalRight:CalcMinValue(containerLogicalWidth);

		local availableSpace = containerLogicalWidth - (marginLogicalLeftValue + marginLogicalRightValue + bordersPlusPadding);

		-- FIXME: Is there a faster way to find the correct case?
        -- Use rule/case that applies.
        if (logicalLeftIsAuto and logicalWidthIsAuto and not logicalRightIsAuto) then
			-- RULE 1: (use shrink-to-fit for width, and solve of left)
            local logicalRightValue = logicalRight:CalcValue(containerLogicalWidth);

            -- FIXME: would it be better to have shrink-to-fit in one step?
            local preferredWidth = self:MaxPreferredLogicalWidth() - bordersPlusPadding;
            local preferredMinWidth = self:MinPreferredLogicalWidth() - bordersPlusPadding;
            local availableWidth = availableSpace - logicalRightValue;
            logicalWidthValue = math.min(math.max(preferredMinWidth, availableWidth), preferredWidth);
            logicalLeftValue = availableSpace - (logicalWidthValue + logicalRightValue);
		elseif (not logicalLeftIsAuto and logicalWidthIsAuto and logicalRightIsAuto) then
			-- RULE 3: (use shrink-to-fit for width, and no need solve of right)
            logicalLeftValue = logicalLeft:CalcValue(containerLogicalWidth);

            -- FIXME: would it be better to have shrink-to-fit in one step?
            local preferredWidth = self:MaxPreferredLogicalWidth() - bordersPlusPadding;
            local preferredMinWidth = self:MinPreferredLogicalWidth() - bordersPlusPadding;
            local availableWidth = availableSpace - logicalLeftValue;
            logicalWidthValue = math.min(math.max(preferredMinWidth, availableWidth), preferredWidth);
		elseif (logicalLeftIsAuto and not logicalWidthIsAuto and not logicalRightIsAuto) then
			-- RULE 4: (solve for left)
            logicalWidthValue = self:ComputeContentBoxLogicalWidth(logicalWidth:CalcValue(containerLogicalWidth));
            logicalLeftValue = availableSpace - (logicalWidthValue + logicalRight:CalcValue(containerLogicalWidth));
		elseif (not logicalLeftIsAuto and logicalWidthIsAuto and not logicalRightIsAuto) then
			-- RULE 5: (solve for width)
            logicalLeftValue = logicalLeft:CalcValue(containerLogicalWidth);
            logicalWidthValue = availableSpace - (logicalLeftValue + logicalRight:CalcValue(containerLogicalWidth));
		elseif (not logicalLeftIsAuto and not logicalWidthIsAuto and logicalRightIsAuto) then
			-- RULE 6: (no need solve for right)
            logicalLeftValue = logicalLeft:CalcValue(containerLogicalWidth);
            logicalWidthValue = self:ComputeContentBoxLogicalWidth(logicalWidth:CalcValue(containerLogicalWidth));
		end
	end


	-- Use computed values to calculate the horizontal position.

	-- FIXME: This hack is needed to calculate the  logical left position for a 'rtl' relatively
	-- positioned, inline because right now, it is using the logical left position
	-- of the first line box when really it should use the last line box.  When
	-- this is fixed elsewhere, this block should be removed.
	if (containerBlock:IsLayoutInline() and not containerBlock:Style():IsLeftToRightDirection()) then
		local flow = containerBlock;
		local firstLine = flow:FirstLineBox();
		local lastLine = flow:LastLineBox();
		if (firstLine and lastLine and firstLine ~= lastLine) then
			logicalLeftPos = logicalLeftValue + marginLogicalLeftValue + lastLine:BorderLogicalLeft() + (lastLine:LogicalLeft() - firstLine:LogicalLeft());
			return logicalWidthValue, marginLogicalLeftValue, marginLogicalRightValue, logicalLeftPos;
		end
	end

	logicalLeftPos = logicalLeftValue + marginLogicalLeftValue;
	logicalLeftPos = computeLogicalLeftPositionedOffset(logicalLeftPos, self, logicalWidthValue, containerBlock, containerLogicalWidth);

	return logicalWidthValue, marginLogicalLeftValue, marginLogicalRightValue, logicalLeftPos;
end

function LayoutBox:ParentBox()
	return self:Parent();
end

--static void computeLogicalTopPositionedOffset(LayoutUnit& logicalTopPos, const RenderBox* child, LayoutUnit logicalHeightValue, const RenderBoxModelObject* containerBlock, LayoutUnit containerLogicalHeight)
local function computeLogicalTopPositionedOffset(logicalTopPos, child, logicalHeightValue, containerBlock, containerLogicalHeight)
    -- Deal with differing writing modes here.  Our offset needs to be in the containing block's coordinate space. If the containing block is flipped
    -- along this axis, then we need to flip the coordinate.  This can only happen if the containing block is both a flipped mode and perpendicular to us.
    if ((child:Style():IsFlippedBlocksWritingMode() and child:IsHorizontalWritingMode() ~= containerBlock:IsHorizontalWritingMode())
        or (child:Style():IsFlippedBlocksWritingMode() ~= containerBlock:Style():IsFlippedBlocksWritingMode() and child:IsHorizontalWritingMode() == containerBlock:IsHorizontalWritingMode())) then
        logicalTopPos = containerLogicalHeight - logicalHeightValue - logicalTopPos;
	end

    -- Our offset is from the logical bottom edge in a flipped environment, e.g., right for vertical-rl and bottom for horizontal-bt.
    if (containerBlock:Style():IsFlippedBlocksWritingMode() and child:IsHorizontalWritingMode() == containerBlock:IsHorizontalWritingMode()) then
        if (child:IsHorizontalWritingMode()) then
            logicalTopPos = logicalTopPos + containerBlock:BorderBottom();
        else
            logicalTopPos = logicalTopPos + containerBlock:BorderRight();
		end
    else
        if (child:IsHorizontalWritingMode()) then
            logicalTopPos = logicalTopPos + containerBlock:BorderTop();
        else
            logicalTopPos = logicalTopPos + containerBlock:BorderLeft();
		end
    end
	return logicalTopPos;
end

--void RenderBox::computePositionedLogicalHeightUsing(Length logicalHeightLength, const RenderBoxModelObject* containerBlock,
--                                                    LayoutUnit containerLogicalHeight, LayoutUnit bordersPlusPadding,
--                                                    Length logicalTop, Length logicalBottom, Length marginBefore, Length marginAfter,
--                                                    LayoutUnit& logicalHeightValue, LayoutUnit& marginBeforeValue, LayoutUnit& marginAfterValue, LayoutUnit& logicalTopPos)
function LayoutBox:ComputePositionedLogicalHeightUsing(logicalHeightLength, containerBlock,
													containerLogicalHeight, bordersPlusPadding,
                                                    logicalTop, logicalBottom, marginBefore, marginAfter,
                                                    logicalHeightValue, marginBeforeValue, marginAfterValue, logicalTopPos)
    -- 'top' and 'bottom' cannot both be 'auto' because 'top would of been
    -- converted to the static position in computePositionedLogicalHeight()
    -- ASSERT(!(logicalTop.isAuto() && logicalBottom.isAuto()));

    local contentLogicalHeight = self:LogicalHeight() - bordersPlusPadding;

    local logicalTopValue = 0;

    local logicalHeightIsAuto = logicalHeightLength:IsAuto();
    local logicalTopIsAuto = logicalTop:IsAuto();
    local logicalBottomIsAuto = logicalBottom:IsAuto();

    -- Height is never unsolved for tables.
    if (self:IsTable()) then
        logicalHeightLength:SetValue(LengthTypeEnum.Fixed, contentLogicalHeight);
        logicalHeightIsAuto = false;
    end

    if (not logicalTopIsAuto and not logicalHeightIsAuto and not logicalBottomIsAuto) then
		--[[
        /*-----------------------------------------------------------------------*\
         * If none of the three are 'auto': If both 'margin-top' and 'margin-
         * bottom' are 'auto', solve the equation under the extra constraint that
         * the two margins get equal values. If one of 'margin-top' or 'margin-
         * bottom' is 'auto', solve the equation for that value. If the values
         * are over-constrained, ignore the value for 'bottom' and solve for that
         * value.
        \*-----------------------------------------------------------------------*/
		]]
        -- NOTE:  It is not necessary to solve for 'bottom' in the over constrained
        -- case because the value is not used for any further calculations.

        logicalHeightValue = self:ComputeContentBoxLogicalHeight(logicalHeightLength:CalcValue(containerLogicalHeight));
        logicalTopValue = logicalTop:CalcValue(containerLogicalHeight);

        local availableSpace = containerLogicalHeight - (logicalTopValue + logicalHeightValue + logicalBottom:CalcValue(containerLogicalHeight) + bordersPlusPadding);

        -- Margins are now the only unknown
        if (marginBefore:IsAuto() and marginAfter:IsAuto()) then
            -- Both margins auto, solve for equality
            -- NOTE: This may result in negative values.
            marginBeforeValue = availableSpace / 2; -- split the difference
            marginAfterValue = availableSpace - marginBeforeValue; -- account for odd valued differences
        elseif (marginBefore:IsAuto()) then
            -- Solve for top margin
            marginAfterValue = marginAfter:CalcValue(containerLogicalHeight);
            marginBeforeValue = availableSpace - marginAfterValue;
        elseif (marginAfter:IsAuto()) then
            -- Solve for bottom margin
            marginBeforeValue = marginBefore:CalcValue(containerLogicalHeight);
            marginAfterValue = availableSpace - marginBeforeValue;
        else
            -- Over-constrained, (no need solve for bottom)
            marginBeforeValue = marginBefore:CalcValue(containerLogicalHeight);
            marginAfterValue = marginAfter:CalcValue(containerLogicalHeight);
        end
    else
		--[[
        /*--------------------------------------------------------------------*\
         * Otherwise, set 'auto' values for 'margin-top' and 'margin-bottom'
         * to 0, and pick the one of the following six rules that applies.
         *
         * 1. 'top' and 'height' are 'auto' and 'bottom' is not 'auto', then
         *    the height is based on the content, and solve for 'top'.
         *
         *              OMIT RULE 2 AS IT SHOULD NEVER BE HIT
         * ------------------------------------------------------------------
         * 2. 'top' and 'bottom' are 'auto' and 'height' is not 'auto', then
         *    set 'top' to the static position, and solve for 'bottom'.
         * ------------------------------------------------------------------
         *
         * 3. 'height' and 'bottom' are 'auto' and 'top' is not 'auto', then
         *    the height is based on the content, and solve for 'bottom'.
         * 4. 'top' is 'auto', 'height' and 'bottom' are not 'auto', and
         *    solve for 'top'.
         * 5. 'height' is 'auto', 'top' and 'bottom' are not 'auto', and
         *    solve for 'height'.
         * 6. 'bottom' is 'auto', 'top' and 'height' are not 'auto', and
         *    solve for 'bottom'.
        \*--------------------------------------------------------------------*/
		]]
        -- NOTE: For rules 3 and 6 it is not necessary to solve for 'bottom'
        -- because the value is not used for any further calculations.

        -- Calculate margins, 'auto' margins are ignored.
        marginBeforeValue = marginBefore:CalcMinValue(containerLogicalHeight);
        marginAfterValue = marginAfter:CalcMinValue(containerLogicalHeight);

        local availableSpace = containerLogicalHeight - (marginBeforeValue + marginAfterValue + bordersPlusPadding);

        -- Use rule/case that applies.
        if (logicalTopIsAuto and logicalHeightIsAuto and not logicalBottomIsAuto) then
            -- RULE 1: (height is content based, solve of top)
            logicalHeightValue = contentLogicalHeight;
            logicalTopValue = availableSpace - (logicalHeightValue + logicalBottom:CalcValue(containerLogicalHeight));
        elseif (not logicalTopIsAuto and logicalHeightIsAuto and logicalBottomIsAuto) then
            -- RULE 3: (height is content based, no need solve of bottom)
            logicalTopValue = logicalTop:CalcValue(containerLogicalHeight);
            logicalHeightValue = contentLogicalHeight;
        elseif (logicalTopIsAuto and not logicalHeightIsAuto and not logicalBottomIsAuto) then
            -- RULE 4: (solve of top)
            logicalHeightValue = self:ComputeContentBoxLogicalHeight(logicalHeightLength:CalcValue(containerLogicalHeight));
            logicalTopValue = availableSpace - (logicalHeightValue + logicalBottom:CalcValue(containerLogicalHeight));
        elseif (not logicalTopIsAuto and logicalHeightIsAuto and not logicalBottomIsAuto) then
            -- RULE 5: (solve of height)
            logicalTopValue = logicalTop:CalcValue(containerLogicalHeight);
            logicalHeightValue = math.max(0, availableSpace - (logicalTopValue + logicalBottom:CalcValue(containerLogicalHeight)));
        elseif (not logicalTopIsAuto and not logicalHeightIsAuto and logicalBottomIsAuto) then
            -- RULE 6: (no need solve of bottom)
            logicalHeightValue = self:ComputeContentBoxLogicalHeight(logicalHeightLength:CalcValue(containerLogicalHeight));
            logicalTopValue = logicalTop:CalcValue(containerLogicalHeight);
        end
    end

    -- Use computed values to calculate the vertical position.
    logicalTopPos = logicalTopValue + marginBeforeValue;
    logicalTopPos = computeLogicalTopPositionedOffset(logicalTopPos, self, logicalHeightValue, containerBlock, containerLogicalHeight);
	return logicalHeightValue, marginBeforeValue, marginAfterValue, logicalTopPos;
end

function LayoutBox:StretchesToViewport()
    --return document()->inQuirksMode() && style()->logicalHeight().isAuto() && !isFloatingOrPositioned() && (isRoot() || isBody());
	return self:Style():LogicalHeight():IsAuto() and not self:IsFloatingOrPositioned() and (self:IsRoot() or self:IsBody());
end

-- There are a few cases where we need to refer specifically to the available physical width and available physical height.
-- Relative positioning is one of those cases, since left/top offsets are physical.
function LayoutBox:AvailableWidth() 
	if(self:Style():IsHorizontalWritingMode()) then
		return self:AvailableLogicalWidth()
	end
	return  self:AvailableLogicalHeight();
end

function LayoutBox:AvailableHeight() 
	if(self:Style():IsHorizontalWritingMode()) then
		return self:AvailableLogicalHeight()
	end
	return  self:AvailableLogicalWidth();
end

--LayoutPoint RenderBox::flipForWritingModeForChild(const RenderBox* child, const LayoutPoint& point) const
function LayoutBox:FlipForWritingModeForChild(child, point)
    if (not self:Style():IsFlippedBlocksWritingMode()) then
        return point;
	end
    
    -- The child is going to add in its x() and y(), so we have to make sure it ends up in
    -- the right place.
    if (self:IsHorizontalWritingMode()) then
        return LayoutPoint:new(point:X(), point:Y() + self:Height() - child:Height() - (2 * child:Y()));
	end
    return LayoutPoint:new(point:X() + self:Width() - child:Width() - (2 * child:X()), point:Y());
end