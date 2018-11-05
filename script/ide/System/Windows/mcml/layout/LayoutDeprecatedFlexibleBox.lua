--[[
Title: 
Author(s): LiPeng
Date: 2018/7/27
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutDeprecatedFlexibleBox.lua");
local LayoutDeprecatedFlexibleBox = commonlib.gettable("System.Windows.mcml.layout.LayoutDeprecatedFlexibleBox");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlock.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntPoint.lua");
local Point = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");

local IntPoint = Point;
local LayoutPoint = Point;

local BoxOrientEnum = ComputedStyleConstants.BoxOrientEnum;
local BoxDirectionEnum = ComputedStyleConstants.BoxDirectionEnum;
local BoxLinesEnum = ComputedStyleConstants.BoxLinesEnum;
local OverflowEnum = ComputedStyleConstants.OverflowEnum;
local BoxAlignmentEnum = ComputedStyleConstants.BoxAlignmentEnum;

local MAX_INT = tonumber("ffffffff", 16);
local horizontalEllipsis = 0x2026;

local FlexBoxIterator = commonlib.inherit(nil, {});

function FlexBoxIterator:ctor()
	--RenderDeprecatedFlexibleBox* m_box;
	self.m_box = nil;
    --RenderBox* m_currentChild;
	self.m_currentChild = nil;
    --bool m_forward;
	self.m_forward = false;
    --unsigned int m_currentOrdinal;
	self.m_currentOrdinal = 0;
    --unsigned int m_largestOrdinal;
	self.m_largestOrdinal = 0;
    --HashSet<unsigned int> m_ordinalValues;
	self.m_ordinalValues = commonlib.UnorderedArraySet:new();
    --Vector<unsigned int> m_sortedOrdinalValues;
	self.m_sortedOrdinalValues = {};
    --int m_ordinalIteration;
	self.m_ordinalIteration = -1;
end

function FlexBoxIterator:init(parent)
	self.m_box = parent;
	self.m_largestOrdinal = 1;

	if (self.m_box:Style():BoxOrient() == BoxOrientEnum.HORIZONTAL and not self.m_box:Style():IsLeftToRightDirection()) then
		self.m_forward = self.m_box:Style():BoxDirection() ~= BoxDirectionEnum.BNORMAL;
	else
		self.m_forward = self.m_box:Style():BoxDirection() == BoxDirectionEnum.BNORMAL;
	end
	if (not self.m_forward) then
		-- No choice, since we're going backwards, we have to find out the highest ordinal up front.
		local child = self.m_box:FirstChildBox();
		while (child) do
			if (child:Style():BoxOrdinalGroup() > self.m_largestOrdinal) then
				self.m_largestOrdinal = child:Style():BoxOrdinalGroup();
			end
			child = child:NextSiblingBox();
		end
	end

	self:Reset();


	return self;
end

function FlexBoxIterator:Reset()
	self.m_currentChild = nil;
    self.m_ordinalIteration = -1;
end

function FlexBoxIterator:First()
    self:Reset();
    return self:Next();
end

function FlexBoxIterator:Next()
	repeat
		if (not self.m_currentChild) then
			self.m_ordinalIteration = self.m_ordinalIteration + 1;

			if (self.m_ordinalIteration == 0) then
				self.m_currentOrdinal = if_else(self.m_forward, 1, self.m_largestOrdinal);
			else
				if (self.m_ordinalIteration >= self.m_ordinalValues:size() + 1) then
					return nil;
				end
				-- Only copy+sort the values once per layout even if the iterator is reset.
				if (self.m_ordinalValues:size() ~= self.m_sortedOrdinalValues.size()) then
					copyToVector(self.m_ordinalValues, self.m_sortedOrdinalValues);
					table.sort(self.m_sortedOrdinalValues);
					--sort(self.m_sortedOrdinalValues.begin(), self.m_sortedOrdinalValues.end());
				end
				self.m_currentOrdinal = if_else(self.m_forward, self.m_sortedOrdinalValues[self.m_ordinalIteration - 1], self.m_sortedOrdinalValues[self.m_sortedOrdinalValues:size() - self.m_ordinalIteration]);
			end

			self.m_currentChild = if_else(self.m_forward, self.m_box:FirstChildBox(), self.m_box:LastChildBox());
		else
			self.m_currentChild = if_else(self.m_forward, self.m_currentChild:NextSiblingBox(), self.m_currentChild:PreviousSiblingBox());
		end

		if (self.m_currentChild and self:NotFirstOrdinalValue()) then
			self.m_ordinalValues:add(self.m_currentChild:Style():BoxOrdinalGroup());
		end
	until (self.m_currentChild and (self.m_currentChild:IsAnonymous() or self.m_currentChild:Style():BoxOrdinalGroup() == self.m_currentOrdinal))

	return self.m_currentChild;
end

local function copyToVector(set, vector)
	for key, _ in pairs(set) do
		vector[#vector + 1] = key;
	end
end

function FlexBoxIterator:NotFirstOrdinalValue()
    local firstOrdinalValue = if_else(self.m_forward, 1, self.m_largestOrdinal);
    return self.m_currentOrdinal == firstOrdinalValue and self.m_currentChild:Style():BoxOrdinalGroup() ~= firstOrdinalValue;
end


local LayoutDeprecatedFlexibleBox = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBlock"), commonlib.gettable("System.Windows.mcml.layout.LayoutDeprecatedFlexibleBox"));

function LayoutDeprecatedFlexibleBox:ctor()
	self.m_flexingChildren = false;
	self.m_stretchingChildren = false;
end

function LayoutDeprecatedFlexibleBox:init(node)
	LayoutDeprecatedFlexibleBox._super.init(self, node)

	self:SetChildrenInline(false);
	return self;
end

function LayoutDeprecatedFlexibleBox:GetName()
    if (self:IsFloating()) then
        return "LayoutDeprecatedFlexibleBox (floating)";
	end
    if (self:IsPositioned()) then
        return "LayoutDeprecatedFlexibleBox (positioned)";
	end
    if (self:IsAnonymous()) then
        return "LayoutDeprecatedFlexibleBox (generated)";
	end
    if (self:IsRelPositioned()) then
        return "LayoutDeprecatedFlexibleBox (relative positioned)";
	end
    return "LayoutDeprecatedFlexibleBox";
end

function LayoutDeprecatedFlexibleBox:AvoidsFloats()  return true; end
function LayoutDeprecatedFlexibleBox:IsDeprecatedFlexibleBox()  return true; end
function LayoutDeprecatedFlexibleBox:IsFlexingChildren()  return self.m_flexingChildren; end
function LayoutDeprecatedFlexibleBox:IsStretchingChildren()  return self.m_stretchingChildren; end
function LayoutDeprecatedFlexibleBox:HasMultipleLines()  return self:Style():BoxLines() == BoxLinesEnum.MULTIPLE; end
function LayoutDeprecatedFlexibleBox:IsVertical()  return self:Style():BoxOrient() == BoxOrientEnum.VERTICAL; end
function LayoutDeprecatedFlexibleBox:IsHorizontal()  return self:Style():BoxOrient() == BoxOrientEnum.HORIZONTAL; end

-- static int marginWidthForChild(RenderBox* child)
local function marginWidthForChild(child)
    -- A margin basically has three types: fixed, percentage, and auto (variable).
    -- Auto and percentage margins simply become 0 when computing min/max width.
    -- Fixed margins can be added in as is.
    local marginLeft = child:Style():MarginLeft();
    local marginRight = child:Style():MarginRight();
    local margin = 0;
    if (marginLeft:IsFixed()) then
        margin = margin + marginLeft:Value();
	end
    if (marginRight:IsFixed()) then
        margin = margin + marginRight:Value();
	end
    return margin;
end

--static bool childDoesNotAffectWidthOrFlexing(RenderObject* child)
local function childDoesNotAffectWidthOrFlexing(child)
    -- Positioned children and collapsed children don't affect the min/max width.
    return child:IsPositioned() or child:Style():Visibility() == COLLAPSE;
end

function LayoutDeprecatedFlexibleBox:CalcHorizontalPrefWidths()
	local child = self:FirstChildBox();
	while(child) do
		if (childDoesNotAffectWidthOrFlexing(child)) then
            --continue;
		else
			local margin = marginWidthForChild(child);
			self.minPreferredLogicalWidth = self.minPreferredLogicalWidth + child:MinPreferredLogicalWidth() + margin;
			self.maxPreferredLogicalWidth = self.maxPreferredLogicalWidth + child:MaxPreferredLogicalWidth() + margin;
		end
		
		child = child:NextSiblingBox();
	end
end

function LayoutDeprecatedFlexibleBox:CalcVerticalPrefWidths()
	local child = self:FirstChildBox();
    while(child) do
        if (childDoesNotAffectWidthOrFlexing(child)) then
            --continue;
		else
			local margin = marginWidthForChild(child);
			local width = child:MinPreferredLogicalWidth() + margin;
			self.minPreferredLogicalWidth = math.max(width, self.minPreferredLogicalWidth);

			width = child:MaxPreferredLogicalWidth() + margin;
			self.maxPreferredLogicalWidth = math.max(width, self.maxPreferredLogicalWidth);
		end
		
		child = child:NextSiblingBox();
    end
end

function LayoutDeprecatedFlexibleBox:ComputePreferredLogicalWidths()
    -- ASSERT(preferredLogicalWidthsDirty());

    if (self:Style():Width():IsFixed() and self:Style():Width():Value() > 0) then
        self.minPreferredLogicalWidth = self:ComputeContentBoxLogicalWidth(self:Style():Width():Value());
		self.maxPreferredLogicalWidth = self.minPreferredLogicalWidth;
    else
        self.minPreferredLogicalWidth, self.maxPreferredLogicalWidth = 0, 0;

        if (self:HasMultipleLines() or self:IsVertical()) then
            self:CalcVerticalPrefWidths();
        else
            self:CalcHorizontalPrefWidths();
		end
        self.maxPreferredLogicalWidth = math.max(self.minPreferredLogicalWidth, self.maxPreferredLogicalWidth);
    end

    if (self:HasOverflowClip() and self:Style():OverflowY() == OverflowEnum.OSCROLL) then
        self:Layer():SetHasVerticalScrollbar(true);
        local scrollbarWidth = self:VerticalScrollbarWidth();
        self.maxPreferredLogicalWidth = self.maxPreferredLogicalWidth + scrollbarWidth;
        self.minPreferredLogicalWidth = self.minPreferredLogicalWidth + scrollbarWidth;
    end

    if (self:Style():MinWidth():IsFixed() and self:Style():MinWidth():Value() > 0) then
        self.maxPreferredLogicalWidth = math.max(self.maxPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():MinWidth():Value()));
        self.minPreferredLogicalWidth = math.max(self.minPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():MinWidth():Value()));
    end

    if (self:Style():MaxWidth():IsFixed()) then
        self.maxPreferredLogicalWidth = min(self.maxPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():MaxWidth():Value()));
        self.minPreferredLogicalWidth = min(self.minPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():MaxWidth():Value()));
    end

    local borderAndPadding = self:BorderAndPaddingLogicalWidth();
    self.minPreferredLogicalWidth = self.minPreferredLogicalWidth + borderAndPadding;
    self.maxPreferredLogicalWidth = self.maxPreferredLogicalWidth + borderAndPadding;

    self:SetPreferredLogicalWidthsDirty(false);
end

function LayoutDeprecatedFlexibleBox:LayoutBlock(relayoutChildren, pageLogicalHeight, layoutPass)
	pageHeight = pageHeight or 0;
	layoutPass = layoutPass or "NormalLayoutPass";
    --ASSERT(needsLayout());

    if (not relayoutChildren and self:SimplifiedLayout()) then
        return;
	end

    -- LayoutRepainter repainter(*this, checkForRepaintDuringLayout());
    -- LayoutStateMaintainer statePusher(view(), this, IntSize(x(), y()), hasTransform() or hasReflection() or self:Style():IsFlippedBlocksWritingMode());

    local previousSize = self:Size();

    self:ComputeLogicalWidth();
    self:ComputeLogicalHeight();

    -- self.m_overflow:Clear();
    if (previousSize ~= self:Size()
        or (self:Parent():IsDeprecatedFlexibleBox() and self:Parent():Style():BoxOrient() == BoxOrientEnum.HORIZONTAL
        and self:Parent():Style():BoxAlign() == BoxAlignmentEnum.BSTRETCH)) then
        relayoutChildren = true;
	end

    self:SetHeight(0);

    self.m_flexingChildren, self.m_stretchingChildren = false, false;

    self:InitMaxMarginValues();

    -- For overflow:scroll blocks, ensure we have both scrollbars in place always.
    if (self:ScrollsOverflow()) then
        if (self:Style():OverflowX() == OverflowEnum.OSCROLL) then
            self:Layer():SetHasHorizontalScrollbar(true);
		end
        if (self:Style():OverflowY() == OverflowEnum.OSCROLL) then
            self:Layer():SetHasVerticalScrollbar(true);
		end
    end

    if (self:IsHorizontal()) then
        self:LayoutHorizontalBox(relayoutChildren);
    else
        self:LayoutVerticalBox(relayoutChildren);
	end

    local oldClientAfterEdge = self:ClientLogicalBottom();
    self:ComputeLogicalHeight();

    if (previousSize:Height() ~= self:Height()) then
        relayoutChildren = true;
	end

    local needAnotherLayoutPass = self:LayoutPositionedObjects(relayoutChildren or self:IsRoot());

    if (not self:IsFloatingOrPositioned() and self:Height() == 0) then
        -- We are a block with no border and padding and a computed height
        -- of 0.  The CSS spec states that zero-height blocks collapse their margins
        -- together.
        -- When blocks are self-collapsing, we just use the top margin values and set the
        -- bottom margin max values to 0.  This way we don't factor in the values
        -- twice when we collapse with our previous vertically adjacent and
        -- following vertically adjacent blocks.
        local pos = self:MaxPositiveMarginBefore();
        local neg = self:MaxNegativeMarginBefore();
        if (self:MaxPositiveMarginAfter() > pos) then
            pos = self:MaxPositiveMarginAfter();
		end
        if (self:MaxNegativeMarginAfter() > neg) then
            neg = self:MaxNegativeMarginAfter();
		end
        self:SetMaxMarginBeforeValues(pos, neg);
        self:SetMaxMarginAfterValues(0, 0);
    end

    self:ComputeOverflow(oldClientAfterEdge);

    --statePusher:Pop();

    self:UpdateLayerTransform();

    if (self:View():LayoutState():PageLogicalHeight()) then
        self:SetPageLogicalOffset(self:View():LayoutState():PageLogicalOffset(self:LogicalTop()));
	end

    -- Update our scrollbars if we're overflow:auto/scroll/hidden now that we know if
    -- we overflow or not.
    if (self:HasOverflowClip()) then
        self:Layer():UpdateScrollInfoAfterLayout();
	end

    -- Repaint with our new bounds if they are different from our old bounds.
    -- repainter:RepaintAfterLayout();

    if (needAnotherLayoutPass and layoutPass == "NormalLayoutPass") then
        self:SetChildNeedsLayout(true, false);
        self:LayoutBlock(false, pageLogicalHeight);
    else
        self:SetNeedsLayout(false);
	end
end

-- The first walk over our kids is to find out if we have any flexible children.
-- static void gatherFlexChildrenInfo(FlexBoxIterator& iterator, bool relayoutChildren, unsigned int& highestFlexGroup, unsigned int& lowestFlexGroup, bool& haveFlex)
local function gatherFlexChildrenInfo(iterator, relayoutChildren, highestFlexGroup, lowestFlexGroup, haveFlex)
	local child = iterator:First();
    while(child) do
        -- Check to see if this child flexes.
        if (not childDoesNotAffectWidthOrFlexing(child) and child:Style():BoxFlex() > 0) then
            -- We always have to lay out flexible objects again, since the flex distribution
            -- may have changed, and we need to reallocate space.
            child:ClearOverrideSize();
            if (not relayoutChildren) then
                child:SetChildNeedsLayout(true, false);
			end
            haveFlex = true;
            local flexGroup = child:Style():BoxFlexGroup();
            if (lowestFlexGroup == 0) then
                lowestFlexGroup = flexGroup;
			end
            if (flexGroup < lowestFlexGroup) then
                lowestFlexGroup = flexGroup;
			end
            if (flexGroup > highestFlexGroup) then
                highestFlexGroup = flexGroup;
			end
        end
		
		child = iterator:Next();
    end
	return highestFlexGroup, lowestFlexGroup, haveFlex;
end

function LayoutDeprecatedFlexibleBox:LayoutHorizontalBox(relayoutChildren)
    local toAdd = self:BorderBottom() + self:PaddingBottom() + self:HorizontalScrollbarHeight();
    local yPos = self:BorderTop() + self:PaddingTop();
    local xPos = self:BorderLeft() + self:PaddingLeft();
    local heightSpecified = false;
    local oldHeight = 0;

    local remainingSpace = 0;


    local iterator = FlexBoxIterator:new():init(self);
    local highestFlexGroup = 0;
    local lowestFlexGroup = 0;
    local haveFlex = false;
    highestFlexGroup, lowestFlexGroup, haveFlex = gatherFlexChildrenInfo(iterator, relayoutChildren, highestFlexGroup, lowestFlexGroup, haveFlex);

    -- RenderBlock::startDelayUpdateScrollInfo();

    -- We do 2 passes.  The first pass is simply to lay everyone out at
    -- their preferred widths.  The second pass handles flexing the children.
    repeat
        -- Reset our height.
        self:SetHeight(yPos);

        xPos = self:BorderLeft() + self:PaddingLeft();

        -- Our first pass is done without flexing.  We simply lay the children
        -- out within the box.  We have to do a layout first in order to determine
        -- our box's intrinsic height.
        local maxAscent, maxDescent = 0, 0;
		local child = iterator:First(); 
        while (child) do
            -- make sure we relayout children if we need it.
            if (relayoutChildren or (child:IsReplaced() and (child:Style():Width():IsPercent() or child:Style():Height():IsPercent()))) then
                child:SetChildNeedsLayout(true, false);
			end

            if (child:IsPositioned()) then
                -- continue;
			else
				-- Compute the child's vertical margins.
				child:ComputeBlockDirectionMargins(self);

				if (not child:NeedsLayout()) then
					child:MarkForPaginationRelayoutIfNeeded();
				end

				-- Now do the layout.
				child:LayoutIfNeeded();

				-- Update our height and overflow height.
				if (self:Style():BoxAlign() == BoxAlignmentEnum.BBASELINE) then
					local ascent = child:FirstLineBoxBaseline();
					if (ascent == -1) then
						ascent = child:Height() + child:MarginBottom();
					end
					ascent = ascent + child:MarginTop();
					local descent = (child:MarginTop() + child:Height() + child:MarginBottom()) - ascent;

					-- Update our maximum ascent.
					maxAscent = math.max(maxAscent, ascent);

					-- Update our maximum descent.
					maxDescent = math.max(maxDescent, descent);

					-- Now update our height.
					self:SetHeight(math.max(yPos + maxAscent + maxDescent, self:Height()));
				else
					self:SetHeight(math.max(self:Height(), yPos + child:MarginTop() + child:Height() + child:MarginBottom()));
				end
			end
			
			child = iterator:Next();
        end

        if (not iterator:First() and self:HasLineIfEmpty()) then
            self:SetHeight(self:Height() + self:LineHeight(true, if_else(self:Style():IsHorizontalWritingMode(), "HorizontalLine", "VerticalLine"), "PositionOfInteriorLineBoxes"));
		end

        self:SetHeight(self:Height() + toAdd);

        oldHeight = self:Height();
        self:ComputeLogicalHeight();

        relayoutChildren = false;
        if (oldHeight ~= self:Height()) then
            heightSpecified = true;
		end

        -- Now that our height is actually known, we can place our boxes.
        self.m_stretchingChildren = (self:Style():BoxAlign() == BoxAlignmentEnum.BSTRETCH);
		local child = iterator:First();
        while(child) do
            if (child:IsPositioned()) then
                child:ContainingBlock():InsertPositionedObject(child);
                local childLayer = child:Layer();
                childLayer:SetStaticInlinePosition(xPos); -- FIXME: Not right for regions.
                if (childLayer:StaticBlockPosition() ~= yPos) then
                    childLayer:SetStaticBlockPosition(yPos);
                    if (child:Style():HasStaticBlockPosition(self:Style():IsHorizontalWritingMode())) then
                        child:SetChildNeedsLayout(true, false);
					end
                end
                --continue;
            elseif (child:Style():Visibility() == COLLAPSE) then
                -- visibility: collapsed children do not participate in our positioning.
                -- But we need to lay them down.
                child:LayoutIfNeeded();
                -- continue;
			else
				-- We need to see if this child's height has changed, since we make block elements
				-- fill the height of a containing box by default.
				-- Now do a layout.
				local oldChildHeight = child:Height();
				child:ComputeLogicalHeight();
				if (oldChildHeight ~= child:Height()) then
					child:SetChildNeedsLayout(true, false);
				end

				if (not child:NeedsLayout()) then
					child:MarkForPaginationRelayoutIfNeeded();
				end

				child:LayoutIfNeeded();

				-- We can place the child now, using our value of box-align.
				xPos = xPos + child:MarginLeft();
				local childY = yPos;
				local boxAlign = self:Style():BoxAlign();
				if(boxAlign == BoxAlignmentEnum.BCENTER) then
					childY = childY + child:MarginTop() + math.max(0, (self:ContentHeight() - (child:Height() + child:MarginTop() + child:MarginBottom())) / 2);
				elseif(boxAlign == BoxAlignmentEnum.BBASELINE) then
					local ascent = child:FirstLineBoxBaseline();
					if (ascent == -1) then
						ascent = child:Height() + child:MarginBottom();
					end
					ascent = ascent + child:MarginTop();
					childY = childY + child:MarginTop() + (maxAscent - ascent);
				elseif(boxAlign == BoxAlignmentEnum.BEND) then
					childY = childY + self:ContentHeight() - child:MarginBottom() - child:Height();
				else -- BSTART
					childY = childY + child:MarginTop();
				end

				self:PlaceChild(child, IntPoint:new(xPos, childY));

				xPos = xPos + child:Width() + child:MarginRight();
            end
			
			child = iterator:Next();
        end

        remainingSpace = self:BorderLeft() + self:PaddingLeft() + self:ContentWidth() - xPos;

        self.m_stretchingChildren = false;
        if (self.m_flexingChildren) then
            haveFlex = false; -- We're done.
        elseif (haveFlex) then
            -- We have some flexible objects.  See if we need to grow/shrink them at all.
            if (remainingSpace == 0) then
                break;
			end
            -- Allocate the remaining space among the flexible objects.  If we are trying to
            -- grow, then we go from the lowest flex group to the highest flex group.  For shrinking,
            -- we go from the highest flex group to the lowest group.
            local expanding = remainingSpace > 0;
            local start = if_else(expanding, lowestFlexGroup, highestFlexGroup);
            local _end = if_else(expanding, highestFlexGroup , lowestFlexGroup);
			
            for i = start, _end do
				if(remainingSpace == 0) then
					break;
				end
                -- Always start off by assuming the group can get all the remaining space.
                local groupRemainingSpace = remainingSpace;
                repeat
                    -- Flexing consists of multiple passes, since we have to change ratios every time an object hits its max/min-width
                    -- For a given pass, we always start off by computing the totalFlex of all objects that can grow/shrink at all, and
                    -- computing the allowed growth before an object hits its min/max width (and thus
                    -- forces a totalFlex recomputation).
                    local groupRemainingSpaceAtBeginning = groupRemainingSpace;
                    local totalFlex = 0;
					local child = iterator:First();
                    while(child) do
                        if (self:AllowedChildFlex(child, expanding, i)) then
                            totalFlex = totalFlex + child:Style():BoxFlex();
						end
						
						child = iterator:Next()
                    end
                    local spaceAvailableThisPass = groupRemainingSpace;
					local child = iterator:First();
                    while(child) do
                        local allowedFlex = self:AllowedChildFlex(child, expanding, i);
                        if (allowedFlex) then
							local projectedFlex = allowedFlex;
							if(allowedFlex ~= MAX_INT) then
								projectedFlex = math.floor(allowedFlex * (totalFlex / child:Style():BoxFlex()));
							end
							if(expanding) then
								spaceAvailableThisPass = math.min(spaceAvailableThisPass, projectedFlex);
							else
								spaceAvailableThisPass = math.max(spaceAvailableThisPass, projectedFlex);
							end
                        end
						child = iterator:Next();
                    end

                    -- The flex groups may not have any flexible objects this time around.
                    if (not spaceAvailableThisPass or totalFlex == 0) then
                        -- If we just couldn't grow/shrink any more, then it's time to transition to the next flex group.
                        groupRemainingSpace = 0;
                        -- continue;
					else
						-- Now distribute the space to objects.
						local child = iterator:First(); 
						while(child and spaceAvailableThisPass and totalFlex) do
							if (child:Style():Visibility() ~= COLLAPSE) then
								if (self:AllowedChildFlex(child, expanding, i)) then
									local spaceAdd = math.floor(spaceAvailableThisPass * (child:Style():BoxFlex() / totalFlex));
									if (spaceAdd) then
										child:SetOverrideWidth(child:OverrideWidth() + spaceAdd);
										self.m_flexingChildren = true;
										relayoutChildren = true;
									end

									spaceAvailableThisPass = spaceAvailableThisPass - spaceAdd;
									remainingSpace = remainingSpace - spaceAdd;
									groupRemainingSpace = groupRemainingSpace - spaceAdd;

									totalFlex = totalFlex - child:Style():BoxFlex();
								end
							end
							
							child = iterator:Next();
						end
						if (groupRemainingSpace == groupRemainingSpaceAtBeginning) then
							-- This is not advancing, avoid getting stuck by distributing the remaining pixels.
							local spaceAdd = if_else(groupRemainingSpace > 0, 1, -1);
							local child = iterator:First(); 
							while(child and groupRemainingSpace ~= 0) do
								if (self:AllowedChildFlex(child, expanding, i)) then
									child:SetOverrideWidth(child:OverrideWidth() + spaceAdd);
									self.m_flexingChildren = true;
									relayoutChildren = true;
									remainingSpace = remainingSpace - spaceAdd;
									groupRemainingSpace = groupRemainingSpace - spaceAdd;
								end
								
								child = iterator:Next();
							end
						end
                    end
                    
                until (groupRemainingSpace == 0)
            end

            -- We didn't find any children that could grow.
            if (haveFlex and not self.m_flexingChildren) then
                haveFlex = false;
			end
        end
    until (not haveFlex)

    self.m_flexingChildren = false;

    -- RenderBlock::finishDelayUpdateScrollInfo();

    if (remainingSpace > 0 and ((self:Style():IsLeftToRightDirection() and self:Style():BoxPack() ~= BoxAlignmentEnum.BSTART)
        or (not self:Style():IsLeftToRightDirection() and self:Style():BoxPack() ~= BoxAlignmentEnum.BEND))) then
        -- Children must be repositioned.
        local offset = 0;
        if (self:Style():BoxPack() == BoxAlignmentEnum.BJUSTIFY) then
            -- Determine the total number of children.
            local totalChildren = 0;
			local child = iterator:First(); 
            while(child) do
                if (not childDoesNotAffectWidthOrFlexing(child)) then
					totalChildren = totalChildren + 1;
				end
				
				child = iterator:Next();
            end

            -- Iterate over the children and space them out according to the
            -- justification level.
            if (totalChildren > 1) then
                --totalChildren;
                local firstChild = true;
				local child = iterator:First();
                while(child) do
                    if (childDoesNotAffectWidthOrFlexing(child)) then
                        -- continue;
					else
						if (firstChild) then
							firstChild = false;
							--continue;
						else
							offset = offset + remainingSpace/totalChildren;
							remainingSpace = remainingSpace - (remainingSpace/totalChildren);
							--totalChildren;

							self:PlaceChild(child, child:Location() + LayoutSize:new(offset, 0));
						end
					end

					child = iterator:Next();
                end
            end
        else
            if (self:Style():BoxPack() == BoxAlignmentEnum.BCENTER) then
                offset = offset + remainingSpace / 2;
            else -- END for LTR, START for RTL
                offset = offset + remainingSpace;
			end
			local child = iterator:First();
            while(child) do
                if (childDoesNotAffectWidthOrFlexing(child)) then
                    -- continue;
				else
					self:PlaceChild(child, child:Location() + LayoutSize:new(offset, 0));
				end

				child = iterator:Next()
            end
        end
    end

    -- So that the computeLogicalHeight in layoutBlock() knows to relayout positioned objects because of
    -- a height change, we revert our height back to the intrinsic height before returning.
    if (heightSpecified) then
        self:SetHeight(oldHeight);
	end
end

function LayoutDeprecatedFlexibleBox:LayoutVerticalBox(relayoutChildren)
    local yPos = self:BorderTop() + self:PaddingTop();
    local toAdd = self:BorderBottom() + self:PaddingBottom() + self:HorizontalScrollbarHeight();
    local heightSpecified = false;
    local oldHeight = 0;

    local remainingSpace = 0;

    local iterator = FlexBoxIterator:new():init(self);
    local highestFlexGroup = 0;
    local lowestFlexGroup = 0;
    local haveFlex = false;
    highestFlexGroup, lowestFlexGroup, haveFlex = gatherFlexChildrenInfo(iterator, relayoutChildren, highestFlexGroup, lowestFlexGroup, haveFlex);

    -- We confine the line clamp ugliness to vertical flexible boxes (thus keeping it out of
    -- mainstream block layout); this is not really part of the XUL box model.
    local haveLineClamp = not self:Style():LineClamp():IsNone();
    if (haveLineClamp) then
        self:ApplyLineClamp(iterator, relayoutChildren);
	end

    --RenderBlock::startDelayUpdateScrollInfo();

    -- We do 2 passes.  The first pass is simply to lay everyone out at
    -- their preferred widths.  The second pass handles flexing the children.
    -- Our first pass is done without flexing.  We simply lay the children
    -- out within the box.
    repeat
        self:SetHeight(self:BorderTop() + self:PaddingTop());
        local minHeight = self:Height() + toAdd;

		local child = iterator:First();
        while(child) do
            -- Make sure we relayout children if we need it.
            if (not haveLineClamp and (relayoutChildren or (child:IsReplaced() and (child:Style():Width():IsPercent() or child:Style():Height():IsPercent())))) then
                child:SetChildNeedsLayout(true, false);
			end

            if (child:IsPositioned()) then
                child:ContainingBlock():InsertPositionedObject(child);
                local childLayer = child:Layer();
                childLayer:SetStaticInlinePosition(self:BorderStart() + self:PaddingStart()); -- FIXME: Not right for regions.
                if (childLayer:StaticBlockPosition() ~= self:Height()) then
                    childLayer:SetStaticBlockPosition(self:Height());
                    if (child:Style():HasStaticBlockPosition(self:Style():IsHorizontalWritingMode())) then
                        child:SetChildNeedsLayout(true, false);
					end
                end
                --continue;
            elseif (child:Style():Visibility() == COLLAPSE) then
                -- visibility: collapsed children do not participate in our positioning.
                -- But we need to lay them down.
                child:LayoutIfNeeded();
                --continue;
			else
				-- Compute the child's vertical margins.
				child:ComputeBlockDirectionMargins(self);

				-- Add in the child's marginTop to our height.
				self:SetHeight(self:Height() + child:MarginTop());

				if (not child:NeedsLayout()) then
					child:MarkForPaginationRelayoutIfNeeded();
				end

				-- Now do a layout.
				child:LayoutIfNeeded();

				-- We can place the child now, using our value of box-align.
				local childX = self:BorderLeft() + self:PaddingLeft();
				local boxAlign = self:Style():BoxAlign();
				
				if(boxAlign == BoxAlignmentEnum.BCENTER or boxAlign == BoxAlignmentEnum.BBASELINE) then
					childX = childX + child:MarginLeft() + math.max(0, (self:ContentWidth() - (child:Width() + child:MarginLeft() + child:MarginRight())) / 2);
				elseif(boxAlign == BoxAlignmentEnum.BEND) then
					if (not self:Style():IsLeftToRightDirection()) then
						childX = childX + child:MarginLeft();
					else
						childX = childX + self:ContentWidth() - child:MarginRight() - child:Width();
					end
				else	-- BSTART/BSTRETCH
					if (self:Style():IsLeftToRightDirection()) then
						childX = childX + child:MarginLeft();
					else
						childX = childX + self:ContentWidth() - child:MarginRight() - child:Width();
					end
				end

				-- Place the child.
				self:PlaceChild(child, LayoutPoint:new(childX, self:Height()));
				self:SetHeight(self:Height() + child:Height() + child:MarginBottom());
            end

			child = iterator:Next();
        end

        yPos = self:Height();

        if (not iterator:First() and self:HasLineIfEmpty()) then
            self:SetHeight(self:Height() + self:LineHeight(true, if_else(self:Style():IsHorizontalWritingMode(), "HorizontalLine", "VerticalLine"), "PositionOfInteriorLineBoxes"));
		end

        self:SetHeight(self:Height() + toAdd);

        -- Negative margins can cause our height to shrink below our minimal height (border/padding).
        -- If this happens, ensure that the computed height is increased to the minimal height.
        if (self:Height() < minHeight) then
            self:SetHeight(minHeight);
		end

        -- Now we have to calc our height, so we know how much space we have remaining.
        oldHeight = self:Height();
        self:ComputeLogicalHeight();
        if (oldHeight ~= self:Height()) then
            heightSpecified = true;
		end

        remainingSpace = self:BorderTop() + self:PaddingTop() + self:ContentHeight() - yPos;

        if (self.m_flexingChildren) then
            haveFlex = false; -- We're done.
        elseif (haveFlex) then
            -- We have some flexible objects.  See if we need to grow/shrink them at all.
            if (remainingSpace == 0) then
                break;
			end

            -- Allocate the remaining space among the flexible objects.  If we are trying to
            -- grow, then we go from the lowest flex group to the highest flex group.  For shrinking,
            -- we go from the highest flex group to the lowest group.
            local expanding = remainingSpace > 0;
            local start = if_else(expanding, lowestFlexGroup , highestFlexGroup);
            local _end = if_else(expanding, highestFlexGroup , lowestFlexGroup);
            for i = start, _end do
				if(remainingSpace == 0) then
					break;
				end
                -- Always start off by assuming the group can get all the remaining space.
                local groupRemainingSpace = remainingSpace;
                repeat
                    -- Flexing consists of multiple passes, since we have to change ratios every time an object hits its max/min-width
                    -- For a given pass, we always start off by computing the totalFlex of all objects that can grow/shrink at all, and
                    -- computing the allowed growth before an object hits its min/max width (and thus
                    -- forces a totalFlex recomputation).
                    local groupRemainingSpaceAtBeginning = groupRemainingSpace;
                    local totalFlex = 0;
					local child = iterator:First();
                    while(child) do
                        if (self:AllowedChildFlex(child, expanding, i)) then
                            totalFlex = totalFlex + child:Style():BoxFlex();
						end
						
						child = iterator:Next()
                    end
                    local spaceAvailableThisPass = groupRemainingSpace;
                    local child = iterator:First();
                    while(child) do
                        local allowedFlex = self:AllowedChildFlex(child, expanding, i);
                        if (allowedFlex) then
                            local projectedFlex = allowedFlex;
							if(allowedFlex ~= MAX_INT) then
								projectedFlex = math.floor(allowedFlex * (totalFlex / child:Style():BoxFlex()));
							end
							if(expanding) then
								spaceAvailableThisPass = math.min(spaceAvailableThisPass, projectedFlex);
							else
								spaceAvailableThisPass = math.max(spaceAvailableThisPass, projectedFlex);
							end
                        end
						
						child = iterator:Next()
                    end

                    -- The flex groups may not have any flexible objects this time around.
                    if (not spaceAvailableThisPass or totalFlex == 0) then
                        -- If we just couldn't grow/shrink any more, then it's time to transition to the next flex group.
                        groupRemainingSpace = 0;
                        --continue;
					else
						-- Now distribute the space to objects.
						local child = iterator:First();
						while(child and spaceAvailableThisPass and totalFlex) do
							if (self:AllowedChildFlex(child, expanding, i)) then
								local spaceAdd = math.floor(spaceAvailableThisPass * (child:Style():BoxFlex() / totalFlex));
								if (spaceAdd) then
									child:SetOverrideHeight(child:OverrideHeight() + spaceAdd);
									self.m_flexingChildren = true;
									relayoutChildren = true;
								end

								spaceAvailableThisPass = spaceAvailableThisPass - spaceAdd;
								remainingSpace = remainingSpace - spaceAdd;
								groupRemainingSpace = groupRemainingSpace - spaceAdd;

								totalFlex = totalFlex - child:Style():BoxFlex();
							end
							child = iterator:Next();
						end
						if (groupRemainingSpace == groupRemainingSpaceAtBeginning) then
							-- This is not advancing, avoid getting stuck by distributing the remaining pixels.
							local spaceAdd = if_else(groupRemainingSpace > 0, 1, -1);
							local child = iterator:First();
							while(child and groupRemainingSpace ~= 0) do
								if (self:AllowedChildFlex(child, expanding, i)) then
									child:SetOverrideHeight(child:OverrideHeight() + spaceAdd);
									self.m_flexingChildren = true;
									relayoutChildren = true;
									remainingSpace = remainingSpace - spaceAdd;
									groupRemainingSpace = groupRemainingSpace - spaceAdd;
								end
								
								child = iterator:Next();
							end
						end
                    end

                    
                until (groupRemainingSpace == 0)
            end

            -- We didn't find any children that could grow.
            if (haveFlex and not self.m_flexingChildren) then
                haveFlex = false;
			end
        end
    until (not haveFlex)

    --RenderBlock::finishDelayUpdateScrollInfo();

    if (self:Style():BoxPack() ~= BoxAlignmentEnum.BSTART and remainingSpace > 0) then
        -- Children must be repositioned.
        local offset = 0;
        if (self:Style():BoxPack() == BoxAlignmentEnum.BJUSTIFY) then
            -- Determine the total number of children.
            local totalChildren = 0;
			local child = iterator:First();
			while(child) do
                if (childDoesNotAffectWidthOrFlexing(child)) then
                    --continue;
				else
					totalChildren = totalChildren + 1;
				end
				
				child = iterator:Next();
            end

            -- Iterate over the children and space them out according to the
            -- justification level.
            if (totalChildren > 1) then
                --totalChildren;
                local firstChild = true;
				local child = iterator:First();
				while(child) do
                    if (childDoesNotAffectWidthOrFlexing(child)) then
                        -- continue;
                    elseif (firstChild) then
                        firstChild = false;
                        -- continue;
					else
						offset = offset + remainingSpace/totalChildren;
						remainingSpace = remainingSpace - (remainingSpace/totalChildren);
						--totalChildren;
						self:PlaceChild(child, child:Location() + LayoutSize:new(0, offset));
                    end

					child = iterator:Next();
                end
            end
        else
            if (self:Style():BoxPack() == BoxAlignmentEnum.BCENTER) then
                offset = offset + remainingSpace / 2;
            else -- END
                offset = offset + remainingSpace;
			end
			local child = iterator:First();
			while(child) do
                if (childDoesNotAffectWidthOrFlexing(child)) then
                    -- continue;
				else
					self:PlaceChild(child, child:Location() + LayoutSize:new(0, offset));
				end
				child = iterator:Next()
            end
        end
    end

    -- So that the computeLogicalHeight in layoutBlock() knows to relayout positioned objects because of
    -- a height change, we revert our height back to the intrinsic height before returning.
    if (heightSpecified) then
        self:SetHeight(oldHeight);
	end
end

function LayoutDeprecatedFlexibleBox:ApplyLineClamp(iterator, relayoutChildren)
    local maxLineCount = 0;
	local child = iterator:First();
	while(child) do
        if (childDoesNotAffectWidthOrFlexing(child)) then
            --continue;
		else
			if (relayoutChildren or (child:IsReplaced() and (child:Style():Width():IsPercent() or child:Style():Height():IsPercent()))
				or (child:Style():Height():IsAuto() and child:IsBlockFlow())) then
				child:SetChildNeedsLayout(true, false);

				-- Dirty all the positioned objects.
				if (child:IsRenderBlock()) then
					child:ToRenderBlock():MarkPositionedObjectsForLayout();
					child:ToRenderBlock():ClearTruncation();
				end
			end
			child:LayoutIfNeeded();
			if (child:Style():Height():IsAuto() and child:IsBlockFlow()) then
				maxLineCount = math.max(maxLineCount, child:ToRenderBlock():LineCount());
			end
		end
		child = iterator:Next();
    end

    -- Get the number of lines and then alter all block flow children with auto height to use the
    -- specified height. We always try to leave room for at least one line.
    local lineClamp = self:Style():LineClamp();
    local numVisibleLines = if_else(lineClamp:IsPercentage(), math.max(1, (maxLineCount + 1) * lineClamp:Value() / 100), lineClamp:Value());
    if (numVisibleLines >= maxLineCount) then
        return;
	end

	local child = iterator:First();
	while(child) do
        if (childDoesNotAffectWidthOrFlexing(child) or not child:Style():Height():IsAuto() or not child:IsBlockFlow()) then
            -- continue;
		else
			local blockChild = child:ToRenderBlock();
			local lineCount = blockChild:LineCount();
			if (lineCount <= numVisibleLines) then
				--continue;
			else
				local newHeight = blockChild:HeightForLineCount(numVisibleLines);
				if (newHeight == child:Height()) then
					--continue;
				else
					child:SetChildNeedsLayout(true, false);
					child:SetOverrideHeight(newHeight);
					self.m_flexingChildren = true;
					child:LayoutIfNeeded();
					self.m_flexingChildren = false;
					child:ClearOverrideSize();

					-- FIXME: For now don't support RTL.
					if (self:Style():Direction() ~= LTR) then
						--continue;
					else
						-- Get the last line
						local lastLine = blockChild:LineAtIndex(lineCount - 1);
						if (not lastLine) then
							--continue;
						else
							local lastVisibleLine = blockChild:LineAtIndex(numVisibleLines - 1);
							if (not lastVisibleLine) then
								--continue;
							else
--								const UChar ellipsisAndSpace[2] = { horizontalEllipsis, ' ' };
--								DEFINE_STATIC_LOCAL(AtomicString, ellipsisAndSpaceStr, (ellipsisAndSpace, 2));
--								DEFINE_STATIC_LOCAL(AtomicString, ellipsisStr, (&horizontalEllipsis, 1));
--								const Font& font = style(numVisibleLines == 1):Font();
--
--								-- Get ellipsis width, and if the last child is an anchor, it will go after the ellipsis, so add in a space and the anchor width too
--								local totalWidth;
--								InlineBox* anchorBox = lastLine:LastChild();
--								if (anchorBox and anchorBox:Renderer():Style():IsLink())
--									totalWidth = anchorBox:LogicalWidth() + font:Width(constructTextRun(self, font, ellipsisAndSpace, 2, self:Style()));
--								else
--									anchorBox = 0;
--									totalWidth = font:Width(constructTextRun(self, font, &horizontalEllipsis, 1, self:Style()));
--								end
--
--								-- See if this width can be accommodated on the last visible line
--								RenderBlock* destBlock = toRenderBlock(lastVisibleLine:Renderer());
--								RenderBlock* srcBlock = toRenderBlock(lastLine:Renderer());
--
--								-- FIXME: Directions of src/destBlock could be different from our direction and from one another.
--								if (not srcBlock:Style():IsLeftToRightDirection())
--									continue;
--
--								local leftToRight = destBlock:Style():IsLeftToRightDirection();
--								if (not leftToRight)
--									continue;
--
--								local blockRightEdge = destBlock:LogicalRightOffsetForLine(lastVisibleLine->y(), false);
--								local blockLeftEdge = destBlock:LogicalLeftOffsetForLine(lastVisibleLine->y(), false);
--
--								local blockEdge = if_else(leftToRight, blockRightEdge , blockLeftEdge);
--								if (not lastVisibleLine:LineCanAccommodateEllipsis(leftToRight, blockEdge, lastVisibleLine->x() + lastVisibleLine:LogicalWidth(), totalWidth))
--									continue;
--
--								-- Let the truncation code kick in.
--								lastVisibleLine:PlaceEllipsis(anchorBox ? ellipsisAndSpaceStr : ellipsisStr, leftToRight, blockLeftEdge, blockRightEdge, totalWidth, anchorBox);
--								destBlock:SetHasMarkupTruncation(true);
							end
						end
					end
				end
			end
		end
		
		child = iterator:Next();
    end
end

function LayoutDeprecatedFlexibleBox:PlaceChild(child, location)
    local oldRect = child:FrameRect();

    -- Place the child.
    child:SetLocation(location);

    -- If the child moved, we have to repaint it as well as any floating/positioned
    -- descendants.  An exception is if we need a layout.  In this case, we know we're going to
    -- repaint ourselves (and the child) anyway.
    if (not self:SelfNeedsLayout() and child:CheckForRepaintDuringLayout()) then
        child:RepaintDuringLayoutIfMoved(oldRect);
	end
end

function LayoutDeprecatedFlexibleBox:AllowedChildFlex(child, expanding, group)
    if (childDoesNotAffectWidthOrFlexing(child) or child:Style():BoxFlex() == 0 or child:Style():BoxFlexGroup() ~= group) then
        return 0;
	end

    if (expanding) then
        if (self:IsHorizontal()) then
            -- FIXME: For now just handle fixed values.
            local maxWidth = MAX_INT;
            local width = child:OverrideWidth() - child:BorderAndPaddingWidth();
            if (not child:Style():MaxWidth():IsUndefined() and child:Style():MaxWidth():IsFixed()) then
                maxWidth = child:Style():MaxWidth():Value();
            elseif (child:Style():MaxWidth():Type() == Intrinsic) then
                maxWidth = child:MaxPreferredLogicalWidth();
            elseif (child:Style():MaxWidth():Type() == MinIntrinsic) then
                maxWidth = child:MinPreferredLogicalWidth();
			end
            if (maxWidth == MAX_INT) then
                return maxWidth;
			end
            return math.max(0, maxWidth - width);
        else
            -- FIXME: For now just handle fixed values.
            local maxHeight = MAX_INT;
            local height = child:OverrideHeight() - child:BorderAndPaddingHeight();
            if (not child:Style():MaxHeight():IsUndefined() and child:Style():MaxHeight():IsFixed()) then
                maxHeight = child:Style():MaxHeight():Value();
			end
            if (maxHeight == MAX_INT) then
                return maxHeight;
			end
            return math.max(0, maxHeight - height);
        end
    end

    -- FIXME: For now just handle fixed values.
    if (self:IsHorizontal()) then
        local minWidth = child:MinPreferredLogicalWidth();
        local width = child:OverrideWidth() - child:BorderAndPaddingWidth();
        if (child:Style():MinWidth():IsFixed()) then
            minWidth = child:Style():MinWidth():Value();
        elseif (child:Style():MinWidth():Type() == Intrinsic) then
            minWidth = child:MaxPreferredLogicalWidth();
        elseif (child:Style():MinWidth():Type() == MinIntrinsic) then
            minWidth = child:MinPreferredLogicalWidth();
		end
        local allowedShrinkage = math.min(0, math.floor(minWidth - width));
        return allowedShrinkage;
    else
        if (child:Style():MinHeight():IsFixed()) then
            local minHeight = child:Style():MinHeight():Value();
            local height = child:OverrideHeight() - child:BorderAndPaddingHeight();
            local allowedShrinkage = math.min(0, math.floor(minHeight - height));
            return allowedShrinkage;
        end
    end

    return 0;
end
