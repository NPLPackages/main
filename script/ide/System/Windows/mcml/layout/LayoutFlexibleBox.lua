--[[
Title: 
Author(s): LiPeng
Date: 2018/7/24
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutFlexibleBox.lua");
local LayoutFlexibleBox = commonlib.gettable("System.Windows.mcml.layout.LayoutFlexibleBox");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlock.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntPoint.lua");
local Point = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local Size = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");

local IntSize = Size;
local IntPoint = Point;

local FlexFlowEnum = ComputedStyleConstants.FlexFlowEnum;
local WritingModeEnum = ComputedStyleConstants.WritingModeEnum;
local FlexPackEnum = ComputedStyleConstants.FlexPackEnum;
local FlexAlignEnum = ComputedStyleConstants.FlexAlignEnum;


local TreeOrderIterator = commonlib.inherit(nil, {});

function TreeOrderIterator:ctor()
	self.m_flexibleBox = nil;
	self.m_currentChild = nil;
	self.m_flexOrderValues = {}; -- it is a set container.
end

function TreeOrderIterator:init(flexibleBox)
	self.m_flexibleBox = flexibleBox;
	return self;
end

function TreeOrderIterator:Reset()
	self.m_currentChild = nil;
end

function TreeOrderIterator:First()
	self:Reset();
	return self:Next();
end

function TreeOrderIterator:Next()
	local child;
	if(self.m_currentChild) then
		child = self.m_currentChild:NextSibling();
	else
		child = self.m_flexibleBox:FirstChild();
	end
    -- FIXME: Inline nodes (like <img> or <input>) should also be treated as boxes.
    while (child and not child:IsBox()) do
        child = child:NextSibling();
	end
    if (child) then
        self.m_flexOrderValues[child:Style():FlexOrder()] = true;
	end

    self.m_currentChild = child:ToRenderBox();
    return self.m_currentChild;
end

function TreeOrderIterator:FlexOrderValues()
    return self.m_flexOrderValues;
end


local FlexOrderIterator = commonlib.inherit(nil, {});

function FlexOrderIterator:ctor()
	self.m_flexibleBox = nil;
	self.m_currentChild = nil;
	self.m_orderValues = {};	-- it's a vector container.
	self.m_orderValuesIterator = 0;
end

local function copyToVector(set, vector)
	for key, _ in pairs(set) do
		vector[#vector + 1] = key;
	end
end

--FlexOrderIterator(RenderFlexibleBox* flexibleBox, const FlexOrderHashSet& flexOrderValues)
function FlexOrderIterator:init(flexibleBox, flexOrderValues)
	self.m_flexibleBox = flexibleBox;
	copyToVector(flexOrderValues, self.m_orderValues);
	table.sort(self.m_orderValues);

	return self;
end

function FlexOrderIterator:First()
    self:Reset();
    return self:Next();
end

function FlexOrderIterator:Next()
    local child = self.m_currentChild;
	if (not child) then
        if (self.m_orderValuesIterator == #(self.m_orderValues) + 1) then
            return;
		end
        if (self.m_orderValuesIterator > 0) then
            self.m_orderValuesIterator = self.m_orderValuesIterator + 1;
            if (self.m_orderValuesIterator == #(self.m_orderValues) + 1) then
                return;
			end
        else
            self.m_orderValuesIterator = 1;
		end

        child = self.m_flexibleBox:FirstChild();
    else
        child = child:NextSibling();
	end


	while (not child or not child:IsBox() or child:Style():FlexOrder() ~= self.m_orderValues[self.m_orderValuesIterator]) do
		if (not child) then
			if (self.m_orderValuesIterator == #(self.m_orderValues) + 1) then
				return;
			end
			if (self.m_orderValuesIterator > 0) then
				self.m_orderValuesIterator = self.m_orderValuesIterator + 1;
				if (self.m_orderValuesIterator == #(self.m_orderValues) + 1) then
					return;
				end
			else
				self.m_orderValuesIterator = 1;
			end

			child = self.m_flexibleBox:FirstChild();
		else
			child = child:NextSibling();
		end
	end
    self.m_currentChild = child:ToRenderBox();
    return self.m_currentChild;
end

function FlexOrderIterator:Reset()
    self.m_currentChild = nil;
    self.m_orderValuesIterator = 0;
end


local LayoutFlexibleBox = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBlock"), commonlib.gettable("System.Windows.mcml.layout.LayoutFlexibleBox"));

function LayoutFlexibleBox:ctor()

end

function LayoutFlexibleBox:GetName()
	return "LayoutFlexibleBox";
end

function LayoutFlexibleBox:IsFlexibleBox() 
	return true;
end

--virtual void layoutBlock(bool relayoutChildren, int pageLogicalHeight = 0, BlockLayoutPass = NormalLayoutPass);
function LayoutFlexibleBox:LayoutBlock(relayoutChildren, pageLogicalHeight, layoutPass)
	pageLogicalHeight = pageLogicalHeight or 0;
	layoutPass = layoutPass or "NormalLayoutPass";


	--ASSERT(needsLayout());

    if (not relayoutChildren and self:SimplifiedLayout()) then
        return;
	end

    --LayoutRepainter repainter(*this, checkForRepaintDuringLayout());
    --LayoutStateMaintainer statePusher(view(), this, IntSize(x(), y()), hasTransform() || hasReflection() || style()->isFlippedBlocksWritingMode());

    local previousSize = Size:new();

    -- FIXME: In theory we should only have to call one of these.
    -- computeLogicalWidth for flex-flow:row and computeLogicalHeight for flex-flow:column.
    self:ComputeLogicalWidth();
    self:ComputeLogicalHeight();

    --m_overflow.clear();

    self:LayoutInlineDirection(relayoutChildren);

    if (self:IsColumnFlow()) then
        self:ComputeLogicalWidth();
    else
        self:ComputeLogicalHeight();
	end

    if (self:Size() ~= previousSize) then
        relayoutChildren = true;
	end

    self:LayoutPositionedObjects(relayoutChildren or self:IsRoot());

    --statePusher.pop();

    self:UpdateLayerTransform();

    --repainter.repaintAfterLayout();

    self:SetNeedsLayout(false);
end

function LayoutFlexibleBox:IsColumnFlow()
    local flow = self:Style():FlexFlow();
    return flow == FlexFlowEnum.FlowColumn or flow == FlexFlowEnum.FlowColumnReverse;
end

function LayoutFlexibleBox:HasOrthogonalFlow(child)
    -- FIXME: If the child is a flexbox, then we need to check isHorizontalFlow.
    return self:IsHorizontalFlow() ~= child:IsHorizontalWritingMode();
end

function LayoutFlexibleBox:IsHorizontalFlow()
    if (self:IsHorizontalWritingMode()) then
        return not self:IsColumnFlow();
	end
    return self:IsColumnFlow();
end

function LayoutFlexibleBox:IsLeftToRightFlow()
    if (self:IsColumnFlow()) then
        return self:Style():WritingMode() == WritingModeEnum.TopToBottomWritingMode or self:Style():WritingMode() == WritingModeEnum.LeftToRightWritingMode;
	end
    return self:Style():IsLeftToRightDirection();
end

function LayoutFlexibleBox:IsFlowAwareLogicalHeightAuto()
    local height = if_else(self:IsHorizontalFlow() , self:Style():Height() , self:Style():Width());
    return height:IsAuto();
end

function LayoutFlexibleBox:SetFlowAwareLogicalHeight(size)
    if (self:IsHorizontalFlow()) then
        self:SetHeight(size);
    else
        self:SetWidth(size);
	end
end

function LayoutFlexibleBox:FlowAwareLogicalHeightForChild(child)
    return if_else(self:IsHorizontalFlow() , child:Height() , child:Width());
end

function LayoutFlexibleBox:FlowAwareLogicalWidthForChild(child)
    return if_else(self:IsHorizontalFlow() , child:Width() , child:Height());
end

function LayoutFlexibleBox:FlowAwareLogicalHeight()
    return if_else(self:IsHorizontalFlow() , self:Height() , self:Width());
end

function LayoutFlexibleBox:FlowAwareLogicalWidth()
    return if_else(self:IsHorizontalFlow() , self:Width() , self:Height());
end

function LayoutFlexibleBox:FlowAwareContentLogicalHeight()
    return if_else(self:IsHorizontalFlow() , self:ContentHeight() , self:ContentWidth());
end

function LayoutFlexibleBox:FlowAwareContentLogicalWidth()
    return if_else(self:IsHorizontalFlow() , self:ContentWidth() , self:ContentHeight());
end

function LayoutFlexibleBox:TransformedWritingMode()
    local mode = self:Style():WritingMode();
    if (not self:IsColumnFlow()) then
        return mode;
	end

    
    if(mode == WritingModeEnum.TopToBottomWritingMode or mode == WritingModeEnum.BottomToTopWritingMode) then
        return if_else(self:Style():IsLeftToRightDirection() , WritingModeEnum.LeftToRightWritingMode , WritingModeEnum.RightToLeftWritingMode);
    elseif(mode == WritingModeEnum.LeftToRightWritingMode or mode == WritingModeEnum.RightToLeftWritingMode) then
        return if_else(self:Style():IsLeftToRightDirection() , WritingModeEnum.TopToBottomWritingMode , WritingModeEnum.BottomToTopWritingMode);
    end
    -- ASSERT_NOT_REACHED();
    return WritingModeEnum.TopToBottomWritingMode;
end

function LayoutFlexibleBox:FlowAwareBorderStart()
    if (self:IsHorizontalFlow()) then
        return if_else(self:IsLeftToRightFlow() , self:BorderLeft() , self:BorderRight());
	end
    return if_else(self:IsLeftToRightFlow() , self:BorderTop() , self:BorderBottom());
end

function LayoutFlexibleBox:FlowAwareBorderBefore()
    local mode = self:TransformedWritingMode();
	if(mode == WritingModeEnum.TopToBottomWritingMode) then
        return self:BorderTop();
	elseif(mode == WritingModeEnum.BottomToTopWritingMode) then
        return self:BorderBottom();
	elseif(mode == WritingModeEnum.LeftToRightWritingMode) then
        return self:BorderLeft();
	elseif(mode == WritingModeEnum.RightToLeftWritingMode) then
        return self:BorderRight();
    end
    -- ASSERT_NOT_REACHED();
    return self:BorderTop();
end

function LayoutFlexibleBox:FlowAwareBorderAfter()
    local mode = self:TransformedWritingMode();
	if(mode == WritingModeEnum.TopToBottomWritingMode) then
        return self:BorderBottom();
	elseif(mode == WritingModeEnum.BottomToTopWritingMode) then
        return self:BorderTop();
	elseif(mode == WritingModeEnum.LeftToRightWritingMode) then
        return self:BorderRight();
	elseif(mode == WritingModeEnum.RightToLeftWritingMode) then
        return self:BorderLeft();
    end
    -- ASSERT_NOT_REACHED();
    return self:BorderBottom();
end

function LayoutFlexibleBox:FlowAwareBorderAndPaddingLogicalHeight()
    return if_else(self:IsHorizontalFlow() , borderAndPaddingHeight() , borderAndPaddingWidth());
end

function LayoutFlexibleBox:FlowAwarePaddingStart()
    if (self:IsHorizontalFlow()) then
        return if_else(self:IsLeftToRightFlow() , self:PaddingLeft() , self:PaddingRight());
	end
    return if_else(self:IsLeftToRightFlow() , self:PaddingTop() , self:PaddingBottom());
end

function LayoutFlexibleBox:FlowAwarePaddingBefore()
    local mode = self:TransformedWritingMode();
	if(mode == WritingModeEnum.TopToBottomWritingMode) then
        return self:PaddingTop();
	elseif(mode == WritingModeEnum.BottomToTopWritingMode) then
        return self:PaddingBottom();
	elseif(mode == WritingModeEnum.LeftToRightWritingMode) then
        return self:PaddingLeft();
	elseif(mode == WritingModeEnum.RightToLeftWritingMode) then
        return self:PaddingRight();
    end
    -- ASSERT_NOT_REACHED();
    return self:PaddingTop();
end

function LayoutFlexibleBox:FlowAwarePaddingAfter()
    local mode = self:TransformedWritingMode();
	if(mode == WritingModeEnum.TopToBottomWritingMode) then
        return self:PaddingBottom();
	elseif(mode == WritingModeEnum.BottomToTopWritingMode) then
        return self:PaddingTop();
	elseif(mode == WritingModeEnum.LeftToRightWritingMode) then
        return self:PaddingRight();
	elseif(mode == WritingModeEnum.RightToLeftWritingMode) then
        return self:PaddingLeft();
    end
    -- ASSERT_NOT_REACHED();
    return self:PaddingBottom();
end

function LayoutFlexibleBox:FlowAwareMarginStartForChild(child)
    if (self:IsHorizontalFlow()) then
        return if_else(self:IsLeftToRightFlow() , child:MarginLeft() , child:MarginRight());
	end
    return if_else(self:IsLeftToRightFlow() , child:MarginTop() , child:MarginBottom());
end

function LayoutFlexibleBox:FlowAwareMarginEndForChild(child)
    if (self:IsHorizontalFlow()) then
        return if_else(self:IsLeftToRightFlow() , child:MarginRight() , child:MarginLeft());
	end
    return if_else(self:IsLeftToRightFlow() , child:MarginBottom() , child:MarginTop());
end

function LayoutFlexibleBox:FlowAwareMarginBeforeForChild(child)
    local mode = self:TransformedWritingMode();
	if(mode == WritingModeEnum.TopToBottomWritingMode) then
        return child:MarginTop();
	elseif(mode == WritingModeEnum.BottomToTopWritingMode) then
        return child:MarginBottom();
	elseif(mode == WritingModeEnum.LeftToRightWritingMode) then
        return child:MarginLeft();
	elseif(mode == WritingModeEnum.RightToLeftWritingMode) then
        return child:MarginRight();
    end
    -- ASSERT_NOT_REACHED();
    return self:MarginTop();
end

function LayoutFlexibleBox:FlowAwareMarginAfterForChild(child)
    local mode = self:TransformedWritingMode();
	if(mode == WritingModeEnum.TopToBottomWritingMode) then
        return child:MarginBottom();
	elseif(mode == WritingModeEnum.BottomToTopWritingMode) then
        return child:MarginTop();
	elseif(mode == WritingModeEnum.LeftToRightWritingMode) then
        return child:MarginRight();
	elseif(mode == WritingModeEnum.RightToLeftWritingMode) then
        return child:MarginLeft();
    end
    -- ASSERT_NOT_REACHED();
    return self:MarginBottom();
end

function LayoutFlexibleBox:FlowAwareMarginLogicalHeightForChild(child)
    return if_else(self:IsHorizontalFlow() , child:MarginTop() + child:MarginBottom() , child:MarginLeft() + child:MarginRight());
end

function LayoutFlexibleBox:FlowAwareLogicalLocationForChild(child)
    return if_else(self:IsHorizontalFlow() , child:Location() , child:Location():TransposedPoint());
end

function LayoutFlexibleBox:SetFlowAwareMarginStartForChild(child, margin)
    if (self:IsHorizontalFlow()) then
        if (self:IsLeftToRightFlow()) then
            child:SetMarginLeft(margin);
        else
            child:SetMarginRight(margin);
		end
    else
        if (self:IsLeftToRightFlow()) then
            child:SetMarginTop(margin);
        else
            child:SetMarginBottom(margin);
		end
    end
end

function LayoutFlexibleBox:SetFlowAwareMarginEndForChild(child, margin)
    if (self:IsHorizontalFlow()) then
        if (self:IsLeftToRightFlow()) then
            child:SetMarginRight(margin);
        else
            child:SetMarginLeft(margin);
		end
    else
        if (self:IsLeftToRightFlow()) then
            child:SetMarginBottom(margin);
        else
            child:SetMarginTop(margin);
		end
    end
end

function LayoutFlexibleBox:SetFlowAwareLogicalLocationForChild(child, location)
    if (self:IsHorizontalFlow()) then
        child:SetLocation(location);
    else
        child:SetLocation(location:TransposedPoint());
	end
end

function LayoutFlexibleBox:LogicalBorderAndPaddingWidthForChild(child)
    return if_else(self:IsHorizontalFlow() , child:BorderAndPaddingWidth() , child:BorderAndPaddingHeight());
end

function LayoutFlexibleBox:LogicalScrollbarHeightForChild(child)
    return if_else(self:IsHorizontalFlow() , child:VerticalScrollbarWidth() , child:HorizontalScrollbarHeight());
end

function LayoutFlexibleBox:MarginStartStyleForChild(child)
    if (self:IsHorizontalFlow()) then
        return if_else(self:IsLeftToRightFlow() , child:Style():MarginLeft() , child:Style():MarginRight());
	end
    return if_else(self:IsLeftToRightFlow() , child:Style():MarginTop() , child:Style():MarginBottom());
end

function LayoutFlexibleBox:MarginEndStyleForChild(child)
    if (self:IsHorizontalFlow()) then
        return if_else(self:IsLeftToRightFlow() , child:Style():MarginRight() , child:Style():MarginLeft());
	end
    return if_else(self:IsLeftToRightFlow() , child:Style():MarginBottom() , child:Style():MarginTop());
end

function LayoutFlexibleBox:PreferredLogicalContentWidthForFlexItem(child)
    local width = if_else(self:IsHorizontalFlow() , child:Style():Width() , child:Style():Height());
    if (width:IsAuto()) then
		local logicalWidth;
		if(self:HasOrthogonalFlow(child)) then
			logicalWidth = child:LogicalHeight();
		else
			logicalWidth = child:MaxPreferredLogicalWidth();
		end
        return logicalWidth - self:LogicalBorderAndPaddingWidthForChild(child) - self:LogicalScrollbarHeightForChild(child);
    end
    return if_else(self:IsHorizontalFlow() , child:ContentWidth() , child:ContentHeight());
end

function LayoutFlexibleBox:LayoutInlineDirection(relayoutChildren)
    local preferredLogicalWidth;
    local totalPositiveFlexibility;
    local totalNegativeFlexibility;
    local treeIterator = TreeOrderIterator:new():init(self);

    preferredLogicalWidth, totalPositiveFlexibility, totalNegativeFlexibility = self:ComputePreferredLogicalWidth(relayoutChildren, treeIterator, preferredLogicalWidth, totalPositiveFlexibility, totalNegativeFlexibility);
    local availableFreeSpace = self:FlowAwareContentLogicalWidth() - preferredLogicalWidth;

    local flexIterator = FlexOrderIterator:new():init(self, treeIterator:FlexOrderValues());
	-- typedef WTF::HashMap<const RenderBox*, LayoutUnit> InflexibleFlexItemSize;
	-- InflexibleFlexItemSize inflexibleItems;
    local inflexibleItems = {}; -- it's a map.
    --WTF::Vector<LayoutUnit> childSizes;
	local childSizes = commonlib.Array:new();
	while(true) do
		local value, availableFreeSpace, totalPositiveFlexibility, totalNegativeFlexibility = self:RunFreeSpaceAllocationAlgorithmInlineDirection(flexIterator, availableFreeSpace, totalPositiveFlexibility, totalNegativeFlexibility, inflexibleItems, childSizes);
		if(value) then
			break;
		end
	end
--    while (not self:RunFreeSpaceAllocationAlgorithmInlineDirection(flexIterator, availableFreeSpace, totalPositiveFlexibility, totalNegativeFlexibility, inflexibleItems, childSizes)) do
--        -- ASSERT(totalPositiveFlexibility >= 0 && totalNegativeFlexibility >= 0);
--        -- ASSERT(inflexibleItems.size() > 0);
--    end

    self:LayoutAndPlaceChildrenInlineDirection(flexIterator, childSizes, availableFreeSpace, totalPositiveFlexibility);
end

function LayoutFlexibleBox:LogicalPositiveFlexForChild(child)
    return if_else(self:IsHorizontalFlow() , child:Style():FlexboxWidthPositiveFlex() , child:Style():FlexboxHeightPositiveFlex());
end

function LayoutFlexibleBox:LogicalNegativeFlexForChild(child)
    return if_else(self:IsHorizontalFlow() , child:Style():FlexboxWidthNegativeFlex() , child:Style():FlexboxHeightNegativeFlex());
end

function LayoutFlexibleBox:AvailableLogicalHeightForChild(child)
    local contentLogicalHeight = self:FlowAwareContentLogicalHeight();
    local currentChildHeight = self:FlowAwareMarginLogicalHeightForChild(child) + self:FlowAwareLogicalHeightForChild(child);
    return contentLogicalHeight - currentChildHeight;
end

function LayoutFlexibleBox:MarginBoxAscent(child)
    local ascent = child:FirstLineBoxBaseline();
    if (ascent == -1) then
        ascent = self:FlowAwareLogicalHeightForChild(child) + self:FlowAwareMarginAfterForChild(child);
	end
    return ascent + self:FlowAwareMarginBeforeForChild(child);
end

--void RenderFlexibleBox::computePreferredLogicalWidth(bool relayoutChildren, TreeOrderIterator& iterator, LayoutUnit& preferredLogicalWidth, float& totalPositiveFlexibility, float& totalNegativeFlexibility)
function LayoutFlexibleBox:ComputePreferredLogicalWidth(relayoutChildren, iterator, preferredLogicalWidth, totalPositiveFlexibility, totalNegativeFlexibility)
    preferredLogicalWidth = 0;
    totalPositiveFlexibility = 0;
	totalNegativeFlexibility = 0;

    local flexboxAvailableLogicalWidth = self:FlowAwareContentLogicalWidth();
	local child = iterator:First();
	while(child) do
		-- We always have to lay out flexible objects again, since the flex distribution
        -- may have changed, and we need to reallocate space.
        child:ClearOverrideSize();
        if (not relayoutChildren) then
            child:SetChildNeedsLayout(true);
		end
        child:LayoutIfNeeded();

        -- We can't just use marginStartForChild, et. al. because "auto" needs to be treated as 0.
        if (self:IsHorizontalFlow()) then
            preferredLogicalWidth = preferredLogicalWidth + child:Style():MarginLeft():CalcMinValue(flexboxAvailableLogicalWidth);
            preferredLogicalWidth = preferredLogicalWidth + child:Style():MarginRight():CalcMinValue(flexboxAvailableLogicalWidth);
        else
            preferredLogicalWidth = preferredLogicalWidth + child:Style():MarginTop():CalcMinValue(flexboxAvailableLogicalWidth);
            preferredLogicalWidth = preferredLogicalWidth + child:Style():MarginBottom():CalcMinValue(flexboxAvailableLogicalWidth);
        end

        preferredLogicalWidth = preferredLogicalWidth + self:LogicalBorderAndPaddingWidthForChild(child);
        preferredLogicalWidth = preferredLogicalWidth + self:PreferredLogicalContentWidthForFlexItem(child);

        totalPositiveFlexibility = totalPositiveFlexibility + self:LogicalPositiveFlexForChild(child);
        totalNegativeFlexibility = totalNegativeFlexibility + self:LogicalNegativeFlexForChild(child);
	
		child = iterator:Next();
	end

	return preferredLogicalWidth, totalPositiveFlexibility, totalNegativeFlexibility;
end

-- Returns true if we successfully ran the algorithm and sized the flex items.
--bool RenderFlexibleBox::runFreeSpaceAllocationAlgorithmInlineDirection(FlexOrderIterator& iterator, LayoutUnit& availableFreeSpace, float& totalPositiveFlexibility, float& totalNegativeFlexibility, InflexibleFlexItemSize& --inflexibleItems, WTF::Vector<LayoutUnit>& childSizes)
function LayoutFlexibleBox:RunFreeSpaceAllocationAlgorithmInlineDirection(iterator, availableFreeSpace, totalPositiveFlexibility, totalNegativeFlexibility, inflexibleItems, childSizes)
    childSizes:clear();

    local flexboxAvailableLogicalWidth = self:FlowAwareContentLogicalWidth();
	local child = iterator:First();
	while(child) do
		local childPreferredSize;
        if (inflexibleItems[child]) then
            childPreferredSize = inflexibleItems[child];
        else
            childPreferredSize = self:PreferredLogicalContentWidthForFlexItem(child);
            if (availableFreeSpace > 0 and totalPositiveFlexibility > 0) then
                childPreferredSize = childPreferredSize + math.floor(availableFreeSpace * self:LogicalPositiveFlexForChild(child) / totalPositiveFlexibility + 0.5);

                local childLogicalMaxWidth = if_else(self:IsHorizontalFlow(), child:Style():MaxWidth(), child:Style():MaxHeight());
                if (not childLogicalMaxWidth:IsUndefined() and childLogicalMaxWidth:IsSpecified() and childPreferredSize > childLogicalMaxWidth:CalcValue(flexboxAvailableLogicalWidth)) then
                    childPreferredSize = childLogicalMaxWidth:CalcValue(flexboxAvailableLogicalWidth);
                    availableFreeSpace = availableFreeSpace - (childPreferredSize - self:PreferredLogicalContentWidthForFlexItem(child));
                    totalPositiveFlexibility = totalPositiveFlexibility - self:LogicalPositiveFlexForChild(child);

                    inflexibleItems[child] = childPreferredSize;
                    return false , availableFreeSpace, totalPositiveFlexibility, totalNegativeFlexibility;
                end
            elseif (availableFreeSpace < 0 and totalNegativeFlexibility > 0) then
                childPreferredSize = childPreferredSize + math.floor(availableFreeSpace * self:LogicalNegativeFlexForChild(child) / totalNegativeFlexibility + 0.5);

                local childLogicalMinWidth = if_else(self:IsHorizontalFlow(), child:Style():MinWidth(), child:Style():MinHeight());
                if (not childLogicalMinWidth:IsUndefined() and childLogicalMinWidth:IsSpecified() and childPreferredSize < childLogicalMinWidth:CalcValue(flexboxAvailableLogicalWidth)) then
                    childPreferredSize = childLogicalMinWidth:CalcValue(flexboxAvailableLogicalWidth);
                    availableFreeSpace = availableFreeSpace + self:PreferredLogicalContentWidthForFlexItem(child) - childPreferredSize;
                    totalNegativeFlexibility = totalNegativeFlexibility - self:LogicalNegativeFlexForChild(child);

                    inflexibleItems[child] = childPreferredSize;
                    return false, availableFreeSpace, totalPositiveFlexibility, totalNegativeFlexibility;
                end
            end
        end
        childSizes:append(childPreferredSize);

		child = iterator:Next();
	end

    return true, availableFreeSpace, totalPositiveFlexibility, totalNegativeFlexibility;
end

local function hasPackingSpace(availableFreeSpace, totalPositiveFlexibility)
    return availableFreeSpace > 0 and totalPositiveFlexibility == 0;
end

--void RenderFlexibleBox::setLogicalOverrideSize(RenderBox* child, LayoutUnit childPreferredSize)
function LayoutFlexibleBox:SetLogicalOverrideSize(child, childPreferredSize)
    -- FIXME: Rename setOverrideWidth/setOverrideHeight to setOverrideLogicalWidth/setOverrideLogicalHeight.
    if (self:HasOrthogonalFlow(child)) then
        child:SetOverrideHeight(childPreferredSize);
    else
        child:SetOverrideWidth(childPreferredSize);
	end
end

--void RenderFlexibleBox::layoutAndPlaceChildrenInlineDirection(FlexOrderIterator& iterator, const WTF::Vector<LayoutUnit>& childSizes, LayoutUnit availableFreeSpace, float totalPositiveFlexibility)
function LayoutFlexibleBox:LayoutAndPlaceChildrenInlineDirection(iterator, childSizes, availableFreeSpace, totalPositiveFlexibility)
    local startEdge = self:FlowAwareBorderStart() + self:FlowAwarePaddingStart();

    if (hasPackingSpace(availableFreeSpace, totalPositiveFlexibility)) then
        if (self:Style():FlexPack() == FlexPackEnum.PackEnd) then
            startEdge = startEdge + availableFreeSpace;
        elseif (self:Style():FlexPack() == FlexPackEnum.PackCenter) then
            startEdge = startEdge + availableFreeSpace / 2;
		end
    end

    local logicalTop = self:FlowAwareBorderBefore() + self:FlowAwarePaddingBefore();
    local totalLogicalWidth = self:FlowAwareLogicalWidth();
    if (self:IsFlowAwareLogicalHeightAuto()) then
        self:SetFlowAwareLogicalHeight(0);
	end
    local maxAscent, maxDescent = 0, 0; -- Used when flex-align: baseline.
    local i = 0;
	local child = iterator:First();
	while(child) do
		local childPreferredSize = childSizes[i] + self:LogicalBorderAndPaddingWidthForChild(child);
        self:SetLogicalOverrideSize(child, childPreferredSize);
        child:SetChildNeedsLayout(true);
        child:LayoutIfNeeded();

        if (child:Style():FlexAlign() == FlexAlignEnum.AlignBaseline) then
            local ascent = self:MarginBoxAscent(child);
            local descent = (self:FlowAwareMarginLogicalHeightForChild(child) + self:FlowAwareLogicalHeightForChild(child)) - ascent;

            maxAscent = math.max(maxAscent, ascent);
            maxDescent = math.max(maxDescent, descent);

            -- FIXME: add flowAwareScrollbarLogicalHeight.
            if (self:IsFlowAwareLogicalHeightAuto()) then
				local height = self:FlowAwareBorderAndPaddingLogicalHeight() + self:FlowAwareMarginLogicalHeightForChild(child) + maxAscent + maxDescent + self:ScrollbarLogicalHeight();
                self:SetFlowAwareLogicalHeight(math.max(self:FlowAwareLogicalHeight(), height));
			end
        elseif (self:IsFlowAwareLogicalHeightAuto()) then
			local height = self:FlowAwareBorderAndPaddingLogicalHeight() + self:FlowAwareMarginLogicalHeightForChild(child) + self:FlowAwareLogicalHeightForChild(child) + self:ScrollbarLogicalHeight();
            self:SetFlowAwareLogicalHeight(math.max(self:FlowAwareLogicalHeight(), height));
		end

        if (self:MarginStartStyleForChild(child):IsAuto()) then
            self:SetFlowAwareMarginStartForChild(child, 0);
		end
        if (self:MarginEndStyleForChild(child):IsAuto()) then
            self:SetFlowAwareMarginEndForChild(child, 0);
		end

        startEdge = startEdge + self:FlowAwareMarginStartForChild(child);

        local childLogicalWidth = self:FlowAwareLogicalWidthForChild(child);
        local shouldFlipInlineDirection = if_else(self:IsColumnFlow(), true, self:IsLeftToRightFlow());
        local logicalLeft = if_else(shouldFlipInlineDirection, startEdge, totalLogicalWidth - startEdge - childLogicalWidth);

        -- FIXME: Supporting layout deltas.
        self:SetFlowAwareLogicalLocationForChild(child, IntPoint:new_from_pool(logicalLeft, logicalTop + self:FlowAwareMarginBeforeForChild(child)));
        startEdge = startEdge + childLogicalWidth + self:FlowAwareMarginEndForChild(child);

        if (hasPackingSpace(availableFreeSpace, totalPositiveFlexibility) and self:Style():FlexPack() == FlexPackEnum.PackJustify and childSizes:size() > 1) then
            startEdge = startEdge + availableFreeSpace / (childSizes:size() - 1);
		end

		child = iterator:Next()
		i = i + 1;
	end


    self:AlignChildrenBlockDirection(iterator, maxAscent);
end

--void RenderFlexibleBox::self:AdjustLocationLogicalTopForChild(RenderBox* child, LayoutUnit delta)
function LayoutFlexibleBox:AdjustLocationLogicalTopForChild(child, delta)
    local oldRect = child:FrameRect();

    self:SetFlowAwareLogicalLocationForChild(child, self:FlowAwareLogicalLocationForChild(child) + LayoutSize(0, delta));

    -- If the child moved, we have to repaint it as well as any floating/positioned
    -- descendants. An exception is if we need a layout. In this case, we know we're going to
    -- repaint ourselves (and the child) anyway.
    if (not self:SelfNeedsLayout() and child:CheckForRepaintDuringLayout()) then
        child:RepaintDuringLayoutIfMoved(oldRect);
	end
end

--void RenderFlexibleBox::alignChildrenBlockDirection(FlexOrderIterator& iterator, LayoutUnit maxAscent)
function LayoutFlexibleBox:AlignChildrenBlockDirection(iterator, maxAscent)
    local logicalHeight = self:FlowAwareLogicalHeight();

	local child = iterator:First();
	while(child) do
		-- direction:rtl + flex-flow:column means the cross-axis direction is flipped.
        if (not self:Style():IsLeftToRightDirection() and self:IsColumnFlow()) then
            local location = self:FlowAwareLogicalLocationForChild(child);
            location:SetY(logicalHeight - self:FlowAwareLogicalHeightForChild(child) - location:Y());
            self:SetFlowAwareLogicalLocationForChild(child, location);
        end

        -- FIXME: Make sure this does the right thing with column flows.
		local child_flex_align = child:Style():FlexAlign();
		if(child_flex_align == FlexAlignEnum.AlignStretch) then
			local height = if_else(self:IsHorizontalFlow(), child:Style():Height(), child:Style():Width());
            if (height:IsAuto()) then
                -- FIXME: Clamp to max-height once it's spec'ed (should we align towards the start or center?).
                local stretchedHeight = self:LogicalHeightForChild(child) + self:AvailableLogicalHeightForChild(child);
                if (self:IsHorizontalFlow()) then
                    child:SetHeight(stretchedHeight);
                else
                    child:SetWidth(stretchedHeight);
				end
            end
--		elseif(child_flex_align == FlexAlignEnum.AlignStart) then
			
		elseif(child_flex_align == FlexAlignEnum.AlignEnd) then
			self:AdjustLocationLogicalTopForChild(child, self:AvailableLogicalHeightForChild(child));
		elseif(child_flex_align == FlexAlignEnum.AlignCenter) then
			self:AdjustLocationLogicalTopForChild(child, self:AvailableLogicalHeightForChild(child) / 2);
		elseif(child_flex_align == FlexAlignEnum.AlignBaseline) then
			local ascent = self:MarginBoxAscent(child);
            self:AdjustLocationLogicalTopForChild(child, maxAscent - ascent);
		end

		child = iterator:Next();
	end
end