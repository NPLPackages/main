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
NPL.load("(gl)script/ide/System/Windows/mcml/geometry/IntRect.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/geometry/IntSize.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/geometry/Length.lua");
local Length = commonlib.gettable("System.Windows.mcml.geometry.Length");
local Size = commonlib.gettable("System.Windows.mcml.geometry.IntSize");
local Rect = commonlib.gettable("System.Windows.mcml.geometry.IntRect");
local LayoutModel = commonlib.gettable("System.Windows.mcml.layout.LayoutModel");
local LayoutBox = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBoxModelObject"), commonlib.gettable("System.Windows.mcml.layout.LayoutBox"));

function LayoutBox:ctor()
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

	self:SetIsBox();
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
	if(write_mode ==  "TopToBottomWritingMode") then
		return self.marginTop;
	elseif(write_mode ==  "BottomToTopWritingMode") then
		return self.marginBottom;
	elseif(write_mode ==  "LeftToRightWritingMode") then
		return self.marginLeft;
	elseif(write_mode ==  "RightToLeftWritingMode") then
		return self.marginRight;
	end
	return self.marginTop;
end

function LayoutBox:MarginAfter()
	local write_mode = self:Style():WritingMode();
	if(write_mode ==  "TopToBottomWritingMode") then
		return self.marginBottom;
	elseif(write_mode ==  "BottomToTopWritingMode") then
		return self.marginTop;
	elseif(write_mode ==  "LeftToRightWritingMode") then
		return self.marginRight;
	elseif(write_mode ==  "RightToLeftWritingMode") then
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
	if(write_mode ==  "TopToBottomWritingMode") then
		self.marginTop = margin;
	elseif(write_mode ==  "BottomToTopWritingMode") then
		self.marginBottom = margin;
	elseif(write_mode ==  "LeftToRightWritingMode") then
		self.marginLeft = margin;
	elseif(write_mode ==  "RightToLeftWritingMode") then
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
    containingBlock:SetMarginBeforeForChild(self, self:Style():MarginBeforeUsing(containingBlockStyle));
    containingBlock:SetMarginAfterForChild(self, self:Style():MarginAfterUsing(containingBlockStyle));
end

function LayoutBox:SetMarginAfter(margin)
	local write_mode = self:Style():WritingMode();
	if(write_mode ==  "TopToBottomWritingMode") then
		self.marginBottom = margin;
	elseif(write_mode ==  "BottomToTopWritingMode") then
		self.marginTop = margin;
	elseif(write_mode ==  "LeftToRightWritingMode") then
		self.marginRight = margin;
	elseif(write_mode ==  "RightToLeftWritingMode") then
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

--function LayoutBox:ClientBoxRect()
--	return LayoutRect(clientLeft(), clientTop(), clientWidth(), clientHeight());
--end

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
	if (self:Style():BoxSizing() == "CONTENT_BOX") then
        return width + bordersPlusPadding;
	end
    return math.max(width, bordersPlusPadding);
end

function LayoutBox:ComputeBorderBoxLogicalHeight(height)
	local bordersPlusPadding = self:BorderAndPaddingLogicalHeight();
	if (self:Style():BoxSizing() == "CONTENT_BOX") then
        return height + bordersPlusPadding;
	end
    return math.max(height, bordersPlusPadding);
end

function LayoutBox:ComputeContentBoxLogicalWidth(width)
	if (self:Style():BoxSizing() == "CONTENT_BOX") then
        width = width - self:BorderAndPaddingLogicalWidth();
	end
    return math.max(0, width);
end

function LayoutBox:ComputeContentBoxLogicalHeight(height)
	if (self:Style():BoxSizing() == "CONTENT_BOX") then
        height = height - self:BorderAndPaddingLogicalHeight();
	end
    return math.max(0, height);
end

function LayoutBox:HasAutoVerticalScrollbar()
	return self:HasOverflowClip() and (self:Style():OverflowY() == "auto" or self:Style():OverflowY() == "overlay");
end

function LayoutBox:HasAutoHorizontalScrollbar()
	return self:HasOverflowClip() and (self:Style():OverflowX() == "auto" or self:Style():OverflowX() == "overlay");
end

function LayoutBox:ScrollsOverflow()
	return self:ScrollsOverflowX() or self:ScrollsOverflowY();
end

function LayoutBox:ScrollsOverflowX()
	return self:HasOverflowClip() and (self:Style():OverflowX() == "scroll" or self:HasAutoHorizontalScrollbar());
end

function LayoutBox:ScrollsOverflowY()
	return self:HasOverflowClip() and (self:Style():OverflowY() == "scroll" or self:HasAutoVerticalScrollbar());
end

function LayoutBox:OnAfterChildLayout(child)
	local control = child:GetControl();
	if(control) then
		control:ApplyCss(self:Style():GetStyle());
		control:setGeometry(child:X(), child:Y(), child:Width(), child:Height());
	end
end

-----------------------------------------------------------------------------------------------------
----------------	webkit/chromium	function

function LayoutBox:ComputePreferredLogicalWidths()
	self:SetPreferredLogicalWidthsDirty(false);
end

function LayoutBox:NeedsPreferredWidthsRecalculation()
    return Length.IsPercent(self:Style():PaddingStart()) or Length.IsPercent(self:Style():PaddingEnd());
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
	if (Length.IsIntrinsicOrAuto(logicalWidth)) then
        local marginStart = self:Style():MarginStart();
        local marginEnd = self:Style():MarginEnd();
        if (availableLogicalWidth) then
            logicalWidthResult = availableLogicalWidth - marginStart - marginEnd;
		end
        if (self:SizesToIntrinsicLogicalWidth(widthType)) then
            logicalWidthResult = math.max(logicalWidthResult, self:MinPreferredLogicalWidth());
            logicalWidthResult = math.min(logicalWidthResult, self:MaxPreferredLogicalWidth());
        end
    else -- FIXME: If the containing block flow is perpendicular to our direction we need to use the available logical height instead.
        logicalWidthResult = self:ComputeBorderBoxLogicalWidth(logicalWidth); 
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
        self:SetMarginStart(self:Style():MarginStart());
        self:SetMarginEnd(self:Style():MarginEnd());
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
        if (self:Style():LogicalMaxWidth() ~= nil) then
            local maxLogicalWidth = self:ComputeLogicalWidthUsing("MaxLogicalWidth", containerWidthInInlineDirection);
            if (self:LogicalWidth() > maxLogicalWidth) then
                self:SetLogicalWidth(maxLogicalWidth);
                logicalWidthLength = self:Style():LogicalMaxWidth();
            end
        end

        -- Calculate MinLogicalWidth
		if (self:Style():LogicalMinWidth() ~= nil) then
			local minLogicalWidth = self:ComputeLogicalWidthUsing("MinLogicalWidth", containerWidthInInlineDirection);
			if (self:LogicalWidth() < minLogicalWidth) then
				self:SetLogicalWidth(minLogicalWidth);
				logicalWidthLength = self:Style():LogicalMinWidth();
			end
		end
	end

	-- Fieldsets are currently the only objects that stretch to their minimum width.
    if (self:StretchesToMinIntrinsicLogicalWidth()) then
        self:SetLogicalWidth(math.max(self:LogicalWidth(), self:MinPreferredLogicalWidth()));
        --logicalWidthLength = Length(logicalWidth(), Fixed);
		logicalWidthLength = self:LogicalWidth();
    end

    -- Margin calculations.
    if (Length.IsAuto(logicalWidthLength) or hasPerpendicularContainingBlock) then
        self:SetMarginStart(self:Style():MarginStart());
        self:SetMarginEnd(self:Style():MarginEnd());
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
        containingBlock:SetMarginStartForChild(self, marginStartLength);
        containingBlock:SetMarginEndForChild(self, marginEndLength);
        return;
    end

    -- Case One: The object is being centered in the containing block's available logical width.
    if ((Length.IsAuto(marginStartLength) and Length.IsAuto(marginEndLength) and childWidth < containerWidth)
        or (not Length.IsAuto(marginStartLength) and not Length.IsAuto(marginEndLength) and containingBlock:Style():TextAlign() == "WEBKIT_CENTER")) then
        containingBlock:SetMarginStartForChild(self, math.max(0, (containerWidth - childWidth) / 2));
        containingBlock:SetMarginEndForChild(self, containerWidth - childWidth - containingBlock:MarginStartForChild(self));
        return;
    end
    
    -- Case Two: The object is being pushed to the start of the containing block's available logical width.
    if (Length.IsAuto(marginEndLength) and childWidth < containerWidth) then
        containingBlock:SetMarginStartForChild(self, marginStartLength);
        containingBlock:SetMarginEndForChild(self, containerWidth - childWidth - containingBlock:MarginStartForChild(self));
        return;
    end
    
    -- Case Three: The object is being pushed to the end of the containing block's available logical width.
    local pushToEndFromTextAlign = not Length.IsAuto(marginEndLength) and ((not containingBlockStyle:IsLeftToRightDirection() and containingBlockStyle:TextAlign() == "WEBKIT_LEFT")
        or (containingBlockStyle:IsLeftToRightDirection() and containingBlockStyle:TextAlign() == "WEBKIT_RIGHT"));
    if ((Length.IsAuto(marginStartLength) and childWidth < containerWidth) or pushToEndFromTextAlign) then
        containingBlock:SetMarginEndForChild(self, marginEndLength);
        containingBlock:SetMarginStartForChild(self, containerWidth - childWidth - containingBlock:MarginEndForChild(self));
        return;
    end
    
    -- Case Four: Either no auto margins, or our width is >= the container width (css2.1, 10.3.3).  In that case
    -- auto margins will just turn into 0.
    containingBlock:SetMarginStartForChild(self, marginStartLength);
    containingBlock:SetMarginEndForChild(self, marginEndLength);
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

function LayoutBox:ComputePositionedLogicalWidth(region, offsetFromLogicalTopOfFirstPage)
	--TODO: fixed this function
end

function LayoutBox:ShouldComputeSizeAsReplaced()
	return self:IsReplaced() and self:IsInlineBlockOrInlineTable();
end

function LayoutBox:HasOverrideHeight()
	return false;
	--return gOverrideHeightMap && gOverrideHeightMap->contains(this);
end

function LayoutBox:ComputePositionedLogicalHeight()
	--TODO: fixed this function
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
    if (self:Style():BoxSizing() == "CONTENT_BOX") then
        return height + bordersPlusPadding;
	end
    return math.max(height, bordersPlusPadding);
end

function LayoutBox:ComputeLogicalHeightUsing(h)
    local logicalHeight = -1;
    if (not Length.IsAuto(h)) then
        if (Length.IsFixed(h)) then
            logicalHeight = h;
        elseif (Length.IsPercent(h)) then
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
        local inHorizontalBox = self:Parent():IsDeprecatedFlexibleBox() and self:Parent():Style():BoxOrient() == "HORIZONTAL";
        local stretching = self:Parent():Style():BoxAlign() == "BSTRETCH";
        local treatAsReplaced = self:ShouldComputeSizeAsReplaced() and (not inHorizontalBox or not stretching);
        local checkMinMaxHeight = false;

        -- The parent box is flexing us, so it has increased or decreased our height.  We have to
        -- grab our cached flexible height.
        -- FIXME: Account for block-flow in flexible boxes.
        -- https://bugs.webkit.org/show_bug.cgi?id=46418
        if (self:HasOverrideHeight() and self:Parent():IsFlexibleBoxIncludingDeprecated()) then
            --h = Length(overrideHeight() - borderAndPaddingLogicalHeight(), Fixed);
        elseif (treatAsReplaced) then
            h = self:ComputeReplacedLogicalHeight();
        else
            h = self:Style():LogicalHeight();
            checkMinMaxHeight = true;
        end

        -- Block children of horizontal flexible boxes fill the height of the box.
        -- FIXME: Account for block-flow in flexible boxes.
        -- https://bugs.webkit.org/show_bug.cgi?id=46418
        if (Length.IsAuto(h) and self:Parent():IsDeprecatedFlexibleBox() and self:Parent():Style():BoxOrient() == "HORIZONTAL" and self:Parent():IsStretchingChildren()) then
--            h = Length(parentBox()->contentLogicalHeight() - marginBefore() - marginAfter() - borderAndPaddingLogicalHeight(), Fixed);
--            checkMinMaxHeight = false;
        end

        local heightResult;
        if (checkMinMaxHeight) then
            heightResult = self:ComputeLogicalHeightUsing(self:Style():LogicalHeight());
            -- FIXME: Use < 0 or roughlyEquals when we move to float, see https://bugs.webkit.org/show_bug.cgi?id=66148
            if (heightResult == -1) then
                heightResult = self:LogicalHeight();
			end
            local minH = self:ComputeLogicalHeightUsing(self:Style():LogicalMinHeight()); -- Leave as -1 if unset.
            local maxH = if_else(Length.IsUndefined(self:Style():LogicalMaxHeight()), heightResult, self:ComputeLogicalHeightUsing(self:Style():LogicalMaxHeight()));
            if (maxH == -1) then
                maxH = heightResult;
			end
            heightResult = math.min(maxH, heightResult);
            heightResult = math.max(minH, heightResult);
        else
            -- The only times we don't check min/max height are when a fixed length has
            -- been given as an override.  Just use that.  The value has already been adjusted
            -- for box-sizing.
            heightResult = h + self:BorderAndPaddingLogicalHeight();
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