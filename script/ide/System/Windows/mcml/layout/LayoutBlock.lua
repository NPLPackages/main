--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlock.lua");
local LayoutBlock = commonlib.gettable("System.Windows.mcml.layout.LayoutBlock");
LayoutBlock:new():init();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlockLineLayout.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObjectChildList.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutLineBoxList.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/RootInlineBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntPoint.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Core/UniString.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/wtf/ListHashSet.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/PODInterval.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/PODIntervalTree.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutRepainter.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutTheme.lua");
local LayoutTheme = commonlib.gettable("System.Windows.mcml.layout.LayoutTheme");
local LayoutRepainter = commonlib.gettable("System.Windows.mcml.layout.LayoutRepainter");
local PODIntervalTree = commonlib.gettable("System.Windows.mcml.platform.PODIntervalTree");
local PODInterval = commonlib.gettable("System.Windows.mcml.platform.PODInterval");
local ListHashSet = commonlib.gettable("System.Windows.mcml.platform.wtf.ListHashSet");
local UniString = commonlib.gettable("System.Core.UniString");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local Point = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");
local RootInlineBox = commonlib.gettable("System.Windows.mcml.layout.RootInlineBox");
local LayoutLineBoxList = commonlib.gettable("System.Windows.mcml.layout.LayoutLineBoxList");
local LayoutObjectChildList = commonlib.gettable("System.Windows.mcml.layout.LayoutObjectChildList");
local Size = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
local Length = commonlib.gettable("System.Windows.mcml.platform.Length");
local LayoutModel = commonlib.gettable("System.Windows.mcml.layout.LayoutModel");
local LayoutBlock = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBox"), commonlib.gettable("System.Windows.mcml.layout.LayoutBlock"));

local LayoutRect = Rect;
local IntRect = Rect;
local LayoutPoint = Point;

local LayoutSize, IntSize = Size, Size;
local FloatingObjectInterval = PODInterval;
local FloatingObjectTree = PODIntervalTree;

local INT_MAX = 0xffffffff;
local INT_MIN = -0xffffffff;

local MarginCollapseEnum = ComputedStyleConstants.MarginCollapseEnum;
local FloatEnum = ComputedStyleConstants.FloatEnum;
local WhiteSpaceEnum = ComputedStyleConstants.WhiteSpaceEnum;
local ClearEnum = ComputedStyleConstants.ClearEnum;
local WritingModeEnum = ComputedStyleConstants.WritingModeEnum;
local VisibilityEnum = ComputedStyleConstants.VisibilityEnum;
local OverflowEnum = ComputedStyleConstants.OverflowEnum;
local DisplayEnum = ComputedStyleConstants.DisplayEnum;
local LengthTypeEnum = Length.LengthTypeEnum;
local PositionEnum = ComputedStyleConstants.PositionEnum;
local StyleDifferenceEnum = ComputedStyleConstants.StyleDifferenceEnum;


local MarginInfo = commonlib.inherit(nil,{});

function MarginInfo:ctor()
	self.atBeforeSideOfBlock = true;
    self.atAfterSideOfBlock = false;
    self.marginBeforeQuirk = false;
    self.marginAfterQuirk = false;
    self.determinedMarginBeforeQuirk = false;

	self.canCollapseWithChildren = nil;
	self.canCollapseMarginBeforeWithChildren = nil;
	self.canCollapseMarginAfterWithChildren = nil;
	self.quirkContainer = nil;
	self.positiveMargin = nil;
	self.negativeMargin = nil;
end
-- @param block: LayoutBlock object
-- @param beforeBorderPadding: length number
-- @param afterBorderPadding: length number
function MarginInfo:init(block, beforeBorderPadding, afterBorderPadding)
	-- Whether or not we can collapse our own margins with our children.  We don't do this
    -- if we had any border/padding (obviously), if we're the root or HTML elements, or if
    -- we're positioned, floating, a table cell.
    self.canCollapseWithChildren = not block:IsLayoutView() and not block:IsRoot() and not block:IsPositioned()
        and not block:IsFloating() and not block:IsTableCell() and not block:HasOverflowClip() and not block:IsInlineBlockOrInlineTable()
        and not block:IsWritingModeRoot() and block:Style():HasAutoColumnCount() and block:Style():HasAutoColumnWidth()
        and not block:Style():ColumnSpan();

    self.canCollapseMarginBeforeWithChildren = self.canCollapseWithChildren and (beforeBorderPadding == 0) and block:Style():MarginBeforeCollapse() ~= MarginCollapseEnum.MSEPARATE;

    -- If any height other than auto is specified in CSS, then we don't collapse our bottom
    -- margins with our children's margins.  To do otherwise would be to risk odd visual
    -- effects when the children overflow out of the parent block and yet still collapse
    -- with it.  We also don't collapse if we have any bottom border/padding.
    self.canCollapseMarginAfterWithChildren = self.canCollapseWithChildren and (afterBorderPadding == 0) and
        (block:Style():LogicalHeight():IsAuto() and block:Style():LogicalHeight():Value() == 0) and block:Style():MarginAfterCollapse() ~= MarginCollapseEnum.MSEPARATE;
    
    self.quirkContainer = block:IsTableCell() or block:IsBody() or block:Style():MarginBeforeCollapse() == MarginCollapseEnum.MDISCARD or block:Style():MarginAfterCollapse() == MarginCollapseEnum.MDISCARD;

    self.positiveMargin = if_else(self.canCollapseMarginBeforeWithChildren, block:MaxPositiveMarginBefore(), 0);
    self.negativeMargin = if_else(self.canCollapseMarginBeforeWithChildren, block:MaxNegativeMarginBefore(), 0);
	return self;
end

function MarginInfo:SetAtBeforeSideOfBlock(b)
	self.atBeforeSideOfBlock = b;
end

function MarginInfo:SetAtAfterSideOfBlock(b)
	self.atAfterSideOfBlock = b;
end

function MarginInfo:ClearMargin()
	self.positiveMargin = 0;
	self.negativeMargin = 0;
end

function MarginInfo:SetMarginBeforeQuirk(b)
	self.marginBeforeQuirk = b;
end

function MarginInfo:SetMarginAfterQuirk(b)
	self.marginAfterQuirk = b;
end

function MarginInfo:SetDeterminedMarginBeforeQuirk(b)
	self.determinedMarginBeforeQuirk = b;
end

function MarginInfo:SetPositiveMargin(p)
	self.positiveMargin = p;
end

function MarginInfo:SetNegativeMargin(n)
	self.negativeMargin = n;
end

function MarginInfo:SetPositiveMarginIfLarger(p)
	if (p > self.positiveMargin) then 
		self.positiveMargin = p;
	end
end

function MarginInfo:SetNegativeMarginIfLarger(n)
	if (n > self.negativeMargin) then
		self.negativeMargin = n;
	end
end

function MarginInfo:SetMargin(positive, negative)
	self.positiveMargin = positive; 
	self.negativeMargin = negative;
end

function MarginInfo:AtBeforeSideOfBlock()
	return self.atBeforeSideOfBlock;
end

function MarginInfo:CanCollapseWithMarginBefore()
	return self.atBeforeSideOfBlock and self.canCollapseMarginBeforeWithChildren;
end

function MarginInfo:CanCollapseWithMarginAfter()
	return self.atAfterSideOfBlock and self.canCollapseMarginAfterWithChildren;
end

function MarginInfo:CanCollapseMarginBeforeWithChildren()
	return self.canCollapseMarginBeforeWithChildren;
end

function MarginInfo:CanCollapseMarginAfterWithChildren()
	return self.canCollapseMarginAfterWithChildren;
end

function MarginInfo:QuirkContainer()
	return self.quirkContainer;
end

function MarginInfo:DeterminedMarginBeforeQuirk()
	return self.determinedMarginBeforeQuirk;
end

function MarginInfo:MarginBeforeQuirk()
	return self.marginBeforeQuirk;
end

function MarginInfo:MarginAfterQuirk()
	return self.marginAfterQuirk;
end

function MarginInfo:PositiveMargin()
	return self.positiveMargin;
end

function MarginInfo:NegativeMargin()
	return self.negativeMargin;
end

function MarginInfo:Margin()
	return self.positiveMargin - self.negativeMargin;
end

local MarginValues = commonlib.inherit(nil,{});

function MarginValues:ctor()
	self.positiveMarginBefore = nil;
	self.negativeMarginBefore = nil;
	self.positiveMarginAfter = nil;
	self.negativeMarginAfter = nil;
end

function MarginValues:init(beforePos, beforeNeg, afterPos, afterNeg)
	self.positiveMarginBefore = beforePos;
	self.negativeMarginBefore = beforeNeg;
	self.positiveMarginAfter = afterPos;
	self.negativeMarginAfter = afterNeg;

	return self;
end

function MarginValues:PositiveMarginBefore()
	return self.positiveMarginBefore;
end

function MarginValues:NegativeMarginBefore()
	return self.negativeMarginBefore;
end

function MarginValues:PositiveMarginAfter()
	return self.positiveMarginAfter;
end

function MarginValues:NegativeMarginAfter()
	return self.negativeMarginAfter;
end

function MarginValues:SetPositiveMarginBefore(pos)
	self.positiveMarginBefore = pos;
end

function MarginValues:SetNegativeMarginBefore(neg)
	self.negativeMarginBefore = neg;
end

function MarginValues:SetPositiveMarginAfter(pos)
	self.positiveMarginAfter = pos;
end

function MarginValues:SetNegativeMarginAfter(neg)
	self.negativeMarginAfter = neg;
end


local RenderBlockRareData = commonlib.inherit(nil,{});

function RenderBlockRareData:ctor()
	self.m_margins = nil;
    self.m_paginationStrut = 0;
    self.m_pageLogicalOffset = 0;
end

function RenderBlockRareData:init(block)
	local beforePos, beforeNeg, afterPos, afterNeg = RenderBlockRareData.PositiveMarginBeforeDefault(block), RenderBlockRareData.NegativeMarginBeforeDefault(block), 
													RenderBlockRareData.PositiveMarginAfterDefault(block), RenderBlockRareData.NegativeMarginAfterDefault(block);
	self.m_margins = MarginValues:new():init(beforePos, beforeNeg, afterPos, afterNeg);

	return self;
end

function RenderBlockRareData.PositiveMarginBeforeDefault(block)
	return math.max(block:MarginBefore(), 0);
end

function RenderBlockRareData.NegativeMarginBeforeDefault(block)
	return math.max(-block:MarginBefore(), 0);
end

function RenderBlockRareData.PositiveMarginAfterDefault(block)
	return math.max(block:MarginAfter(), 0);
end

function RenderBlockRareData.NegativeMarginAfterDefault(block)
	return math.max(-block:MarginAfter(), 0);
end


local FloatWithRect = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.LayoutBlock.FloatWithRect"));

function FloatWithRect:ctor()
	self.object = nil;
    self.rect = IntRect:new();
    self.everHadLayout = false;
end
-- @param f: LayoutBox
function FloatWithRect:init(f)
	self.object = f;
	self.rect:Reset(f:X() - f:MarginLeft(), f:Y() - f:MarginTop(), f:Width() + f:MarginLeft() + f:MarginRight(), f:Height() + f:MarginTop() + f:MarginBottom());
	self.everHadLayout = f.everHadLayout;

	return self;
end

function FloatWithRect:Rect()
	return self.rect;
end

function FloatWithRect:EverHadLayout()
	return self.everHadLayout;
end

function FloatWithRect:Object()
	return self.object;
end

local FloatingObject = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.LayoutBlock.FloatingObject"));

-- enum Type { FloatLeft = 1, FloatRight = 2, FloatLeftRight = 3, FloatPositioned = 4, FloatAll = 7 };
local FloatType = 
{
	["FloatLeft"] = 1, 
	["FloatRight"] = 2, 
	["FloatLeftRight"] = 3, 
	["FloatPositioned"] = 4, 
	["FloatAll"] = 7
};

FloatingObject.FloatType = FloatType;

function FloatingObject:ctor()
	self.renderer = nil;
	self.originatingLine = nil;
	self.frameRect = nil;
	self.paginationStrut = 0;
	self.type = nil; -- Type (left/right aligned or positioned)
	self.shouldPaint = false;
    self.isDescendant = false;
    self.isPlaced = nil;
	self.isInPlacedTree = false;

--	    RenderBox* m_renderer;
--        RootInlineBox* m_originatingLine;
--        LayoutRect m_frameRect;
--        int m_paginationStrut;
--        unsigned m_type : 3; // Type (left/right aligned or positioned)
--        bool m_shouldPaint : 1;
--        bool m_isDescendant : 1;
--        bool m_isPlaced : 1;
--#ifndef NDEBUG
--        bool m_isInPlacedTree : 1;
--#endif
end

function FloatingObject:init(type, frameRect)
	if(not frameRect) then
		-- enum EFloat { NoFloat, LeftFloat, RightFloat, PositionedFloat };
		-- type is EFloat
		if (type == FloatEnum.LeftFloat) then
            self.type = FloatType["FloatLeft"];
        elseif (type == FloatEnum.RightFloat) then
            self.type = FloatType["FloatRight"];
        elseif (type == FloatEnum.PositionedFloat) then
            self.type = FloatType["FloatPositioned"];
		end
		self.isPlaced = false;
	else
		self.type = type;
		self.shouldPaint = (type ~= FloatType["FloatPositioned"]);
		self.isPlaced = true;
	end
	self.frameRect = Rect:new(frameRect);

	return self;
end

function FloatingObject:Type()
	return self.type;
end

function FloatingObject:Renderer()
	return self.renderer;
end

function FloatingObject:IsPlaced()
	return self.isPlaced;
end

function FloatingObject:ShouldPaint()
	return self.shouldPaint;
end

function FloatingObject:SetIsPlaced(placed)
	placed = if_else(placed == nil, true, placed);
	self.isPlaced = placed;
end

function FloatingObject:X()
	return self.frameRect:X();
end

function FloatingObject:MaxX()
	return self.frameRect:MaxX();
end

function FloatingObject:Y()
	return self.frameRect:Y();
end

function FloatingObject:MaxY()
	return self.frameRect:MaxY();
end

function FloatingObject:Width()
	return self.frameRect:Width();
end

function FloatingObject:Height()
	return self.frameRect:Height();
end

function FloatingObject:SetX(x)
	self.frameRect:SetX(x);
end

function FloatingObject:SetY(y)
	self.frameRect:SetY(y);
end

function FloatingObject:SetWidth(width)
	self.frameRect:SetWidth(width);
end

function FloatingObject:SetHeight(height)
	self.frameRect:SetHeight(height);
end

function FloatingObject:FrameRect()
	return self.frameRect;
end

function FloatingObject:SetFrameRect(frameRect)
	self.frameRect:init(frameRect);
end

function FloatingObject:IsInPlacedTree()
	return self.isInPlacedTree;
end

function FloatingObject:IsDescendant()
	return self.isDescendant;
end

function FloatingObject:SetIsInPlacedTree(value)
	self.isInPlacedTree = value;
end


local FloatIntervalSearchAdapter = commonlib.inherit(nil, {});

function FloatIntervalSearchAdapter:ctor()
	self.renderer = nil;
    self.value = 0;
    self.offset = 0;
    self.heightRemaining = nil;
	-- FloatingObject.FloatType
	self.floatTypeValue = nil;
end

function FloatIntervalSearchAdapter:init(renderer, value, offset, heightRemaining, floatTypeValue)
	self.renderer = renderer;
    self.value = value;
    self.offset = offset;
    self.heightRemaining = heightRemaining;
	-- FloatingObject.FloatType
	self.floatTypeValue = floatTypeValue;

	return self;
end

function FloatIntervalSearchAdapter:lowValue()
	return self.value;
end

function FloatIntervalSearchAdapter:highValue()
	return self.value;
end


--inline void RenderBlock::FloatIntervalSearchAdapter<FloatTypeValue>::collectIfNeeded(const IntervalType& interval) const
function FloatIntervalSearchAdapter:collectIfNeeded(interval)
    --const FloatingObject* r = interval.data();
	local r = interval:data();
    if (r:Type() == self.floatTypeValue and interval:low() <= self.value and self.value < interval:high()) then
        -- All the objects returned from the tree should be already placed.
        -- ASSERT(r->isPlaced() && m_renderer->logicalTopForFloat(r) <= m_value && m_renderer->logicalBottomForFloat(r) > m_value);

        if (self.floatTypeValue == FloatType.FloatLeft and self.renderer:LogicalRightForFloat(r) > self.offset) then
            self.offset = self.renderer:LogicalRightForFloat(r);
            if (self.heightRemaining) then
				self.heightRemaining = self.renderer:LogicalBottomForFloat(r) - self.value;
			end
        end

        if (self.floatTypeValue == FloatType.FloatRight and self.renderer:LogicalLeftForFloat(r) < self.offset) then
            self.offset = self.renderer:LogicalLeftForFloat(r);
            if (self.heightRemaining) then
				self.heightRemaining = self.renderer:LogicalBottomForFloat(r) - self.value;
			end
        end
    end
end


local FloatingObjects = commonlib.inherit(nil, {});

local FloatingObjectSetFindFunction = function(floatingObject, layoutBox)
	if(floatingObject:Renderer() == layoutBox) then
		return true;
	end
	return false;
end

function FloatingObjects:ctor()
	--FloatingObjectSet m_set;
	self.set = ListHashSet:new();
    --FloatingObjectTree m_placedFloatsTree;
	self.placedFloatsTree = FloatingObjectTree:new();
    self.leftObjectsCount = 0;
    self.rightObjectsCount = 0;
    self.positionedObjectsCount = 0;
    self.horizontalWritingMode = true;
end
-- @param horizontalWritingMode: bool
function FloatingObjects:init(horizontalWritingMode)
	self.horizontalWritingMode = horizontalWritingMode;
	return self;
end

function FloatingObjects:Clear()
	self.set:clear();
	self.placedFloatsTree:clear();
	self.leftObjectsCount = 0;
    self.rightObjectsCount = 0;
    self.positionedObjectsCount = 0;
end

--inline void RenderBlock::FloatingObjects::increaseObjectsCount(FloatingObject::Type type)
function FloatingObjects:IncreaseObjectsCount(type)
    if (type == FloatType.FloatLeft) then
        self.leftObjectsCount = self.leftObjectsCount + 1;
    elseif (type == FloatType.FloatRight) then
		self.rightObjectsCount = self.rightObjectsCount + 1;
    else
		self.positionedObjectsCount = self.positionedObjectsCount + 1;
	end
end

--inline void RenderBlock::FloatingObjects::decreaseObjectsCount(FloatingObject::Type type)
function FloatingObjects:DecreaseObjectsCount(type)
    if (type == FloatType.FloatLeft) then
        self.leftObjectsCount = self.leftObjectsCount - 1;
    elseif (type == FloatType.FloatRight) then
		self.rightObjectsCount = self.rightObjectsCount - 1;
    else
		self.positionedObjectsCount = self.positionedObjectsCount - 1;
	end
end

--inline void RenderBlock::FloatingObjects::add(FloatingObject* floatingObject)
function FloatingObjects:Add(floatingObject)
    self:IncreaseObjectsCount(floatingObject:Type());
    self.set:add(floatingObject);
    if (floatingObject:IsPlaced()) then
        self:AddPlacedObject(floatingObject);
	end
end

--void RenderBlock::FloatingObjects::addPlacedObject(FloatingObject* floatingObject)
function FloatingObjects:AddPlacedObject(floatingObject)
    --ASSERT(!floatingObject->isInPlacedTree());

    floatingObject:SetIsPlaced(true);
    if (self.placedFloatsTree:isInitialized()) then
		self.placedFloatsTree:add(self:IntervalForFloatingObject(floatingObject));
	end

--#ifndef NDEBUG
    floatingObject:SetIsInPlacedTree(true);      
--#endif
end

--inline void RenderBlock::FloatingObjects::remove(FloatingObject* floatingObject)
function FloatingObjects:Remove(floatingObject)
    self:DecreaseObjectsCount(floatingObject:Type());
    self.set:remove(floatingObject);
    --ASSERT(floatingObject->isPlaced() || !floatingObject->isInPlacedTree());
    if (floatingObject:IsPlaced()) then
        self:RemovePlacedObject(floatingObject);
	end
end

--void RenderBlock::FloatingObjects::removePlacedObject(FloatingObject* floatingObject)
function FloatingObjects:RemovePlacedObject(floatingObject)
    --ASSERT(floatingObject->isPlaced() && floatingObject->isInPlacedTree());

    if (self.placedFloatsTree:isInitialized()) then
		self.placedFloatsTree:remove(self:IntervalForFloatingObject(floatingObject));
	end
    
    floatingObject:SetIsPlaced(false);
--#ifndef NDEBUG
    floatingObject:SetIsInPlacedTree(false);
--#endif
end

function FloatingObjects:SetHorizontalWritingMode(b)
	b = if_else(b == nil, true, b);
	self.horizontalWritingMode = b;
end

function FloatingObjects:HasLeftObjects()
	return self.leftObjectsCount > 0;
end

function FloatingObjects:HasRightObjects()
	return self.rightObjectsCount > 0;
end

function FloatingObjects:HasPositionedObjects()
	return self.positionedObjectsCount > 0;
end

function FloatingObjects:Set()
	return self.set;
end

function FloatingObjects:PlacedFloatsTree()
    self:ComputePlacedFloatsTreeIfNeeded();
    return self.placedFloatsTree; 
end

function FloatingObjects:ComputePlacedFloatsTree()
	--ASSERT(!m_placedFloatsTree.isInitialized());
    if (self.set:isEmpty()) then
        return;
	end
    self.placedFloatsTree:initIfNeeded();

	local it = self.set:Begin();
	while(it) do
		local floatingObject = it();
		if (floatingObject:IsPlaced()) then
			
            self.placedFloatsTree:add(self:IntervalForFloatingObject(floatingObject));
		end
	
		it = self.set:next(it);
	end
end

function FloatingObjects:ComputePlacedFloatsTreeIfNeeded()
	if (not self.placedFloatsTree:isInitialized()) then
        self:ComputePlacedFloatsTree();
	end
end

--inline RenderBlock::FloatingObjectInterval RenderBlock::FloatingObjects::intervalForFloatingObject(FloatingObject* floatingObject)
function FloatingObjects:IntervalForFloatingObject(floatingObject)
	-- TODO: add latter;
	if (self.horizontalWritingMode) then
		return FloatingObjectInterval:new():init(floatingObject:Y(), floatingObject:MaxY(), floatingObject);
        --return RenderBlock::FloatingObjectInterval(floatingObject->y(), floatingObject->maxY(), floatingObject);
	end
	return FloatingObjectInterval:new():init(floatingObject:X(), floatingObject:MaxX(), floatingObject);
    --return RenderBlock::FloatingObjectInterval(floatingObject->x(), floatingObject->maxX(), floatingObject);
end

--[[
 InlineMinMaxIterator is a class that will iterate over all render objects that contribute to
   inline min/max width calculations.  Note the following about the way it walks:
   (1) Positioned content is skipped (since it does not contribute to min/max width of a block)
   (2) We do not drill into the children of floats or replaced elements, since you can't break
       in the middle of such an element.
   (3) Inline flows (e.g., <a>, <span>, <i>) are walked twice, since each side can have
       distinct borders/margin/padding that contribute to the min/max width.
]]
local InlineMinMaxIterator = commonlib.inherit(nil,{});

function InlineMinMaxIterator:ctor()
--	RenderObject* parent;
	self.parent = nil;
--    RenderObject* current;
	self.current = nil;
--    bool endOfInline;
	self.endOfInline = nil;
end

--InlineMinMaxIterator(RenderObject* p, bool end = false)
function InlineMinMaxIterator:init(p, endOfInline)
	endOfInline = if_else(endOfInline == nil, false, endOfInline);
	self.parent = p;
	self.current = p;
	self.endOfInline = endOfInline;
	return self;
end

function InlineMinMaxIterator:Next()
    local result;
    local oldEndOfInline = self.endOfInline;
    self.endOfInline = false;
    while (self.current or self.current == self.parent) do
        if (not oldEndOfInline and
            (self.current == self.parent or
             (not self.current:IsFloating() and not self.current:IsReplaced() and not self.current:IsPositioned()))) then
            result = self.current:FirstChild();
		end
        if (not result) then
            -- We hit the end of our inline. (It was empty, e.g., <span></span>.)
            if (not oldEndOfInline and self.current:IsLayoutInline()) then
                result = self.current;
                self.endOfInline = true;
                break;
            end

            while (self.current and self.current ~= self.parent) do
                result = self.current:NextSibling();
                if (result) then
					break;
				end
                self.current = self.current:Parent();
                if (self.current and self.current ~= self.parent and self.current:IsLayoutInline()) then
                    result = self.current;
                    self.endOfInline = true;
                    break;
                end
            end
        end

        if (not result) then
            break;
		end

        if (not result:IsPositioned() and (result:IsText() or result:IsFloating() or result:IsReplaced() or result:IsLayoutInline())) then
             break;
        end
        self.current = result;
        result = nil;
    end
    -- Update our position.
    self.current = result;
    return self.current;
end

--static int getBPMWidth(int childValue, Length cssUnit)
local function getBPMWidth(childValue, cssUnit)
    if (cssUnit:Type() ~= LengthTypeEnum.Auto) then
        return if_else(cssUnit:IsFixed(), cssUnit:Value(), childValue);
	end
    return 0;
end

--static int getBorderPaddingMargin(const RenderBoxModelObject* child, bool endOfInline)
local function getBorderPaddingMargin(child, endOfInline)
    local cstyle = child:Style();
	if (endOfInline) then
        return getBPMWidth(child:MarginEnd(), cstyle:MarginEnd()) + 
               getBPMWidth(child:PaddingEnd(), cstyle:PaddingEnd()) +
               child:BorderEnd();
	end
    return getBPMWidth(child:MarginStart(), cstyle:MarginStart()) + 
               getBPMWidth(child:PaddingStart(), cstyle:PaddingStart()) +
               child:BorderStart();
end

--static inline void stripTrailingSpace(float& inlineMax, float& inlineMin, RenderObject* trailingSpaceChild)
local function stripTrailingSpace(inlineMax, inlineMin, trailingSpaceChild)
    if (trailingSpaceChild and trailingSpaceChild:IsText()) then
        -- Collapse away the trailing space at the end of a block.
        local t = trailingSpaceChild:ToRenderText();
        local UChar space = ' ';
        local font = t:Style():Font(); -- FIXME: This ignores first-line.
        local spaceWidth = UniString.GetSpaceWidth(font:ToString());
        inlineMax = inlineMax- spaceWidth - font:WordSpacing();
        if (inlineMin > inlineMax) then
            inlineMin = inlineMax;
		end
    end
	return inlineMax, inlineMin;
end

--static inline void updatePreferredWidth(LayoutUnit& preferredWidth, float& result)
local function updatePreferredWidth(preferredWidth, result)
    local snappedResult = math.floor(result+0.5);
    preferredWidth = math.max(snappedResult, preferredWidth);
	return preferredWidth;
end

-- Used to store state between styleWillChange and styleDidChange
local s_canPropagateFloatIntoSibling = false;

function LayoutBlock:ctor()
	self.name = "LayoutBlock";

	-- LayoutObjectChildList object;
	self.children = LayoutObjectChildList:new();

	self.lineBoxes = LayoutLineBoxList:new();   -- All of the line boxes created for this inline flow.  For example, <i>Hello<br>world.</i> will have two <i> line boxes.

	self.lineHeight = -1;
	self.beingDestroyed = false;
    self.hasPositionedFloats = false;

	self.floatingObjects = nil
	self.positionedObjects = nil;

	self.m_rareData = nil;
end

function LayoutBlock:init(node)
	LayoutBlock._super.init(self, node);
	self:SetChildrenInline(true);

	return self;
end

function LayoutBlock:HasPositionedFloats() 
	return self.hasPositionedFloats;
end

function LayoutBlock:Children()
	return self.children;
end

function LayoutBlock:BeingDestroyed()
	return self.beingDestroyed;
end

-------------------------------------------------------------------------------------------------------------------------
---			html layout function
--
--
--
--
--

---------------------------------------------------------------------------------------------------
----------------	webkit/chromium	function

function LayoutBlock:IsLayoutBlock()
	return true;
end

function LayoutBlock:IsBlockFlow()
	return (not self:IsInline() or self:IsReplaced()) and not self:IsTable();
end

function LayoutBlock:BeingDestroyed() 
	return self.beingDestroyed;
end

function LayoutBlock:ComputeInlinePreferredLogicalWidths()
	local inlineMax = 0;
    local inlineMin = 0;

    local containingBlock = self:ContainingBlock();
    local cw = 0;
	if(containingBlock) then
		cw = containingBlock:ContentLogicalWidth()
	end

    -- If we are at the start of a line, we want to ignore all white-space.
    -- Also strip spaces if we previously had text that ended in a trailing space.
    local stripFrontSpaces = true;
    local trailingSpaceChild;

    -- Firefox and Opera will allow a table cell to grow to fit an image inside it under
    -- very specific cirucumstances (in order to match common WinIE renderings). 
    -- Not supporting the quirk has caused us to mis-render some real sites. (See Bugzilla 10517.) 
    local allowImagesToBreak = not self:Document():InQuirksMode() or not self:IsTableCell() or not self:Style():LogicalWidth():IsIntrinsicOrAuto();

    local autoWrap, oldAutoWrap;
    oldAutoWrap = self:Style():AutoWrap();
	autoWrap = oldAutoWrap;

    --InlineMinMaxIterator childIterator(this);
	local childIterator = InlineMinMaxIterator:new():init(self);
    local addedTextIndent = false; -- Only gets added in once.
    local prevFloat;
	local child = childIterator:Next();
	local isContinue;
    while (child) do
		isContinue = false;
		if(child:IsReplaced()) then
			autoWrap = child:Parent():Style():AutoWrap();
		else
			autoWrap = child:Style():AutoWrap();
		end

        if (not child:IsBR()) then
            -- Step One: determine whether or not we need to go ahead and
            -- terminate our current line.  Each discrete chunk can become
            -- the new min-width, if it is the widest chunk seen so far, and
            -- it can also become the max-width.

            -- Children fall into three categories:
            -- (1) An inline flow object.  These objects always have a min/max of 0,
            -- and are included in the iteration solely so that their margins can
            -- be added in.
            --
            -- (2) An inline non-text non-flow object, e.g., an inline replaced element.
            -- These objects can always be on a line by themselves, so in this situation
            -- we need to go ahead and break the current line, and then add in our own
            -- margins and min/max width on its own line, and then terminate the line.
            --
            -- (3) A text object.  Text runs can have breakable characters at the start,
            -- the middle or the end.  They may also lose whitespace off the front if
            -- we're already ignoring whitespace.  In order to compute accurate min-width
            -- information, we need three pieces of information.
            -- (a) the min-width of the first non-breakable run.  Should be 0 if the text string
            -- starts with whitespace.
            -- (b) the min-width of the last non-breakable run. Should be 0 if the text string
            -- ends with whitespace.
            -- (c) the min/max width of the string (trimmed for whitespace).
            --
            -- If the text string starts with whitespace, then we need to go ahead and
            -- terminate our current line (unless we're already in a whitespace stripping
            -- mode.
            --
            -- If the text string has a breakable character in the middle, but didn't start
            -- with whitespace, then we add the width of the first non-breakable run and
            -- then end the current line.  We then need to use the intermediate min/max width
            -- values (if any of them are larger than our current min/max).  We then look at
            -- the width of the last non-breakable run and use that to start a new line
            -- (unless we end in whitespace).
            local cstyle = child:Style();
            local childMin = 0;
            local childMax = 0;

            if (not child:IsText()) then
                -- Case (1) and (2).  Inline replaced and inline flow elements.
                if (child:IsLayoutInline()) then
                    -- Add in padding/border/margin from the appropriate side of
                    -- the element.
                    local bpm = getBorderPaddingMargin(child:ToRenderInline(), childIterator.endOfInline);
                    childMin = childMin + bpm;
                    childMax = childMax + bpm;

                    inlineMin = inlineMin + childMin;
                    inlineMax = inlineMax + childMax;
                    
                    child:SetPreferredLogicalWidthsDirty(false);
                else
                    -- Inline replaced elts add in their margins to their min/max values.
                    local margins = 0;
                    local startMargin = cstyle:MarginStart();
                    local endMargin = cstyle:MarginEnd();
                    if (startMargin:IsFixed()) then
                        margins = margins + startMargin:Value();
					end
                    if (endMargin:IsFixed()) then
                        margins = margins + endMargin:Value();
					end
                    childMin = childMin + margins;
                    childMax = childMax + margins;
                end
            end

            if (not child:IsLayoutInline() and not child:IsText()) then
                -- Case (2). Inline replaced elements and floats.
                -- Go ahead and terminate the current line as far as
                -- minwidth is concerned.
                childMin = childMin + child:MinPreferredLogicalWidth();
                childMax = childMax + child:MaxPreferredLogicalWidth();

                local clearPreviousFloat;
                if (child:IsFloating()) then
					local clear = child:Style():Clear();
                    clearPreviousFloat = (prevFloat
                        and ((prevFloat:Style():Floating() == FloatEnum.LeftFloat and (clear == ClearEnum.CLEFT and clear == ClearEnum.CBOTH))
                            or (prevFloat:Style():Floating() == FloatEnum.RightFloat and (clear == ClearEnum.CRIGHT and clear == ClearEnum.CBOTH))));
                    prevFloat = child;
                else
                    clearPreviousFloat = false;
				end

                local canBreakReplacedElement = not child:IsImage() or allowImagesToBreak;
                if ((canBreakReplacedElement and (autoWrap or oldAutoWrap)) or clearPreviousFloat) then
                    self.minPreferredLogicalWidth = updatePreferredWidth(self.minPreferredLogicalWidth, inlineMin);
                    inlineMin = 0;
                end

                -- If we're supposed to clear the previous float, then terminate maxwidth as well.
                if (clearPreviousFloat) then
                    self.maxPreferredLogicalWidth = updatePreferredWidth(self.maxPreferredLogicalWidth, inlineMax);
                    inlineMax = 0;
                end

                -- Add in text-indent.  This is added in only once.
                local ti = 0;
                if (not addedTextIndent) then
                    addedTextIndent = true;
                    ti = self:Style():TextIndent():CalcMinValue(cw);
                    childMin = childMin + ti;
                    childMax = childMax + ti;
                end

                -- Add our width to the max.
                inlineMax = inlineMax + childMax;

                if (not autoWrap or not canBreakReplacedElement) then
                    if (child:IsFloating()) then
                        self.minPreferredLogicalWidth = updatePreferredWidth(self.minPreferredLogicalWidth, childMin);
                    else
                        inlineMin = inlineMin + childMin;
					end
                else
                    -- Now check our line.
                    self.minPreferredLogicalWidth = updatePreferredWidth(self.minPreferredLogicalWidth, childMin);

                    -- Now start a new line.
                    inlineMin = 0;
                end

                -- We are no longer stripping whitespace at the start of
                -- a line.
                if (not child:IsFloating()) then
                    stripFrontSpaces = false;
                    trailingSpaceChild = nil;
                end
            elseif (child:IsText()) then
                -- Case (3). Text.
                local t = child:ToRenderText();

                if (t:IsWordBreak()) then
                    self.minPreferredLogicalWidth = updatePreferredWidth(self.minPreferredLogicalWidth, inlineMin);
                    inlineMin = 0;
                    isContinue = true; -- continue;
				else
					if (t:Style():HasTextCombine() and t:IsCombineText()) then
						--toRenderCombineText(t)->combineText();
					end

					-- Determine if we have a breakable character.  Pass in
					-- whether or not we should ignore any spaces at the front
					-- of the string.  If those are going to be stripped out,
					-- then they shouldn't be considered in the breakable char
					-- check.
					local hasBreakableChar, hasBreak;
					local beginMin, endMin;
					local beginWS, endWS;
					local beginMax, endMax = 0, 0;
					beginMin, beginWS, endMin, endWS, hasBreakableChar, hasBreak, beginMax, endMax, childMin, childMax, stripFrontSpaces = 
						t:TrimmedPrefWidths(inlineMax, beginMin, beginWS, endMin, endWS, hasBreakableChar, hasBreak, beginMax, endMax, childMin, childMax, stripFrontSpaces);

					-- This text object will not be rendered, but it may still provide a breaking opportunity.
					if (not hasBreak and childMax == 0) then
						if (autoWrap and (beginWS or endWS)) then
							self.minPreferredLogicalWidth = updatePreferredWidth(self.minPreferredLogicalWidth, inlineMin);
							inlineMin = 0;
						end
						isContinue = true; -- continue;
					else
						if (stripFrontSpaces) then
							trailingSpaceChild = child;
						else
							trailingSpaceChild = nil;
						end

						-- Add in text-indent.  This is added in only once.
						local ti = 0;
						if (not addedTextIndent) then
							addedTextIndent = true;
							ti = self:Style():TextIndent():CalcMinValue(cw);
							childMin = childMin + ti; 
							beginMin = beginMin + ti;
							childMax = childMax + ti; 
							beginMax = beginMax + ti;
						end
						
						-- If we have no breakable characters at all,
						-- then this is the easy case. We add ourselves to the current
						-- min and max and continue.
						if (not hasBreakableChar) then
							inlineMin = inlineMin + childMin;
						else
							-- We have a breakable character.  Now we need to know if
							-- we start and end with whitespace.
							if (beginWS) then
								-- Go ahead and end the current line.
								self.minPreferredLogicalWidth = updatePreferredWidth(self.minPreferredLogicalWidth, inlineMin);
							else
								inlineMin = inlineMin + beginMin;
								self.minPreferredLogicalWidth = updatePreferredWidth(self.minPreferredLogicalWidth, inlineMin);
								childMin = childMin - ti;
							end

							inlineMin = childMin;

							if (endWS) then
								-- We end in whitespace, which means we can go ahead
								-- and end our current line.
								self.minPreferredLogicalWidth = updatePreferredWidth(self.minPreferredLogicalWidth, inlineMin);
								inlineMin = 0;
							else
								self.minPreferredLogicalWidth = updatePreferredWidth(self.minPreferredLogicalWidth, inlineMin);
								inlineMin = endMin;
							end
						end

						if (hasBreak) then
							inlineMax = inlineMax + beginMax;
							self.maxPreferredLogicalWidth = updatePreferredWidth(self.maxPreferredLogicalWidth, inlineMax);
							self.maxPreferredLogicalWidth = updatePreferredWidth(self.maxPreferredLogicalWidth, childMax);
							inlineMax = endMax;
						else
							inlineMax = inlineMax + childMax;
						end
					end
                end
            end

			if(not isContinue) then
				-- Ignore spaces after a list marker.
				if (child:IsListMarker()) then
					stripFrontSpaces = true;
				end
			end
        else
            self.minPreferredLogicalWidth = updatePreferredWidth(self.minPreferredLogicalWidth, inlineMin);
            self.maxPreferredLogicalWidth = updatePreferredWidth(self.maxPreferredLogicalWidth, inlineMax);
            inlineMin, inlineMax = 0, 0;
            stripFrontSpaces = true;
            trailingSpaceChild = nil;
        end

		if(not isContinue) then
			oldAutoWrap = autoWrap;
		end
		
		child = childIterator:Next();
    end

    if (self:Style():CollapseWhiteSpace()) then
        inlineMax, inlineMin = stripTrailingSpace(inlineMax, inlineMin, trailingSpaceChild);
	end
    self.minPreferredLogicalWidth = updatePreferredWidth(self.minPreferredLogicalWidth, inlineMin);
    self.maxPreferredLogicalWidth = updatePreferredWidth(self.maxPreferredLogicalWidth, inlineMax);
end

local BLOCK_MAX_WIDTH = 15000;

function LayoutBlock:ComputeBlockPreferredLogicalWidths()
	local nowrap = self:Style():WhiteSpace() == WhiteSpaceEnum.NOWRAP;

    local child = self:FirstChild();
    local containingBlock = self:ContainingBlock();
    local floatLeftWidth, floatRightWidth = 0, 0;
    while (child) do
        -- Positioned children don't affect the min/max width
        if (child:IsPositioned()) then
            child = child:NextSibling();
        else

			if (child:IsFloating() or (child:IsBox() and child:AvoidsFloats())) then
				local floatTotalWidth = floatLeftWidth + floatRightWidth;
				local clear = child:Style():Clear();
				if (clear == ClearEnum.CLEFT or clear == ClearEnum.CBOTH) then
					self.maxPreferredLogicalWidth = math.max(floatTotalWidth, self.maxPreferredLogicalWidth);
					floatLeftWidth = 0;
				end
				if (clear == ClearEnum.CRIGHT or clear == ClearEnum.CBOTH) then
					self.maxPreferredLogicalWidth = math.max(floatTotalWidth, self.maxPreferredLogicalWidth);
					floatRightWidth = 0;
				end
			end

			-- A margin basically has three types: fixed, percentage, and auto (variable).
			-- Auto and percentage margins simply become 0 when computing min/max width.
			-- Fixed margins can be added in as is.
			local startMarginLength = child:Style():MarginStartUsing(self:Style());
			local endMarginLength = child:Style():MarginEndUsing(self:Style());
			local margin = 0;
			local marginStart = 0;
			local marginEnd = 0;
			if (startMarginLength:IsFixed()) then
				marginStart = marginStart + startMarginLength:Value();
			end
			if (endMarginLength:IsFixed()) then
				marginEnd = marginEnd + endMarginLength:Value();
			end
			margin = marginStart + marginEnd;

			local childMinPreferredLogicalWidth, childMaxPreferredLogicalWidth;
			if (child:IsBox() and child:IsHorizontalWritingMode() ~= self:IsHorizontalWritingMode()) then
				local childBox = child;
				local oldHeight = childBox:LogicalHeight();
				self:SetLogicalHeight(childBox:BorderAndPaddingLogicalHeight());
				childBox:ComputeLogicalHeight();
				childMinPreferredLogicalWidth = childBox:LogicalHeight();
				childMaxPreferredLogicalWidth = childMinPreferredLogicalWidth;
				childBox:SetLogicalHeight(oldHeight);
			else
				childMinPreferredLogicalWidth = child:MinPreferredLogicalWidth();
				childMaxPreferredLogicalWidth = child:MaxPreferredLogicalWidth();
			end

			local w = childMinPreferredLogicalWidth + margin;
			self.minPreferredLogicalWidth = math.max(w, self.minPreferredLogicalWidth);
        
			-- IE ignores tables for calculation of nowrap. Makes some sense.
			if (nowrap and not child:IsTable()) then
				self.maxPreferredLogicalWidth = math.max(w, self.maxPreferredLogicalWidth);
			end

			w = childMaxPreferredLogicalWidth + margin;

			if (not child:IsFloating()) then
				if (child:IsBox() and child:AvoidsFloats()) then
					-- Determine a left and right max value based off whether or not the floats can fit in the
					-- margins of the object.  For negative margins, we will attempt to overlap the float if the negative margin
					-- is smaller than the float width.
					local ltr;
					if(containingBlock) then
						ltr = containingBlock:Style():IsLeftToRightDirection();
					else
						ltr = self:Style():IsLeftToRightDirection();
					end
					local marginLogicalLeft = if_else(ltr, marginStart, marginEnd);
					local marginLogicalRight = if_else(ltr, marginEnd, marginStart);
					local maxLeft = if_else(marginLogicalLeft > 0, math.max(floatLeftWidth, marginLogicalLeft), floatLeftWidth + marginLogicalLeft);
					local maxRight = if_else(marginLogicalRight > 0, math.max(floatRightWidth, marginLogicalRight), floatRightWidth + marginLogicalRight);
					w = childMaxPreferredLogicalWidth + maxLeft + maxRight;
					w = math.max(w, floatLeftWidth + floatRightWidth);
				else
					self.maxPreferredLogicalWidth = math.max(floatLeftWidth + floatRightWidth, self.maxPreferredLogicalWidth);
				end
				floatLeftWidth, floatRightWidth = 0, 0;
			end
        
			if (child:IsFloating()) then
				if (self:Style():Floating() == FloatEnum.LeftFloat) then
					floatLeftWidth = floatLeftWidth + w;
				else
					floatRightWidth = floatRightWidth + w;
				end
			else
				self.maxPreferredLogicalWidth = math.max(w, self.maxPreferredLogicalWidth);
			end

			-- A very specific WinIE quirk.
			-- Example:
			--[[
			   <div style="position:absolute; width:100px; top:50px;">
				  <div style="position:absolute;left:0px;top:50px;height:50px;background-color:green">
					<table style="width:100%"><tr><td></table>
				  </div>
			   </div>
			]]
			-- In the above example, the inner absolute positioned block should have a computed width
			-- of 100px because of the table.
			-- We can achieve this effect by making the maxwidth of blocks that contain tables
			-- with percentage widths be infinite (as long as they are not inside a table cell).
			-- FIXME: There is probably a bug here with orthogonal writing modes since we check logicalWidth only using the child's writing mode.
			if (containingBlock and self:Document():InQuirksMode() and child:Style():LogicalWidth():IsPercent()
				and not self:IsTableCell() and child:IsTable() and self.maxPreferredLogicalWidth < BLOCK_MAX_WIDTH) then
				local cb = containingBlock;
				while (not cb:IsLayoutView() and not cb:IsTableCell()) do
					cb = cb:ContainingBlock();
				end
				if (not cb:IsTableCell()) then
					self.maxPreferredLogicalWidth = BLOCK_MAX_WIDTH;
				end
			end
        
			child = child:NextSibling();
		end
    end

    -- Always make sure these values are non-negative.
    self.minPreferredLogicalWidth = math.max(0, self.minPreferredLogicalWidth);
    self.maxPreferredLogicalWidth = math.max(0, self.maxPreferredLogicalWidth);

    self.maxPreferredLogicalWidth = math.max(floatLeftWidth + floatRightWidth, self.maxPreferredLogicalWidth);
end

function LayoutBlock:ComputePreferredLogicalWidths()
	self:UpdateFirstLetter();

	if (not self:IsTableCell() and self:Style():LogicalWidth():IsFixed() and self:Style():LogicalWidth():Value() > 0) then
        self.minPreferredLogicalWidth = self:ComputeContentBoxLogicalWidth(self:Style():LogicalWidth():Value());
		self.maxPreferredLogicalWidth = self.minPreferredLogicalWidth;
	else
        self.minPreferredLogicalWidth = 0;
        self.maxPreferredLogicalWidth = 0;

        if (self:ChildrenInline()) then
            self:ComputeInlinePreferredLogicalWidths();
        else
            self:ComputeBlockPreferredLogicalWidths();
		end
        self.maxPreferredLogicalWidth = math.max(self.minPreferredLogicalWidth, self.maxPreferredLogicalWidth);

        if (not self:Style():AutoWrap() and self:ChildrenInline()) then
            self.minPreferredLogicalWidth = self.maxPreferredLogicalWidth;
            
            -- A horizontal marquee with inline children has no minimum width.
--            if (layer() && layer()->marquee() && layer()->marquee()->isHorizontal())
--                m_minPreferredLogicalWidth = 0;
        end

        local scrollbarWidth = 0;
        if (self:HasOverflowClip() and self:Style():OverflowY() == OverflowEnum.OSCROLL) then
            --layer()->setHasVerticalScrollbar(true);
            scrollbarWidth = self:VerticalScrollbarWidth();
            self.maxPreferredLogicalWidth = self.maxPreferredLogicalWidth + scrollbarWidth;
        end

--        if (self:IsTableCell()) then
--            local w = self:StyleOrColLogicalWidth();
--            if (w.isFixed() && w.value() > 0) {
--                m_maxPreferredLogicalWidth = max(m_minPreferredLogicalWidth, computeContentBoxLogicalWidth(w.value()));
--                scrollbarWidth = 0;
--            end
--        end
        
        self.minPreferredLogicalWidth = self.minPreferredLogicalWidth + scrollbarWidth;
    end
    
    if (self:Style():LogicalMinWidth():IsFixed() and self:Style():LogicalMinWidth():Value() > 0) then
        self.maxPreferredLogicalWidth = math.max(self.maxPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():LogicalMinWidth():Value()));
        self.minPreferredLogicalWidth = math.max(self.minPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():LogicalMinWidth():Value()));
    end
    
    if (self:Style():LogicalMaxWidth():IsFixed()) then
        self.maxPreferredLogicalWidth = math.min(self.maxPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():LogicalMaxWidth()));
        self.minPreferredLogicalWidth = math.min(self.minPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():LogicalMaxWidth()));
    end

    local borderAndPadding = self:BorderAndPaddingLogicalWidth();
    self.minPreferredLogicalWidth = self.minPreferredLogicalWidth + borderAndPadding;
    self.maxPreferredLogicalWidth = self.maxPreferredLogicalWidth + borderAndPadding;
    self:SetPreferredLogicalWidthsDirty(false);
end

function LayoutBlock:LogicalWidthForChild(child)
	return if_else(self:IsHorizontalWritingMode(), child:Width(), child:Height());
end
function LayoutBlock:LogicalHeightForChild(child)
	return if_else(self:IsHorizontalWritingMode(), child:Height(), child:Width());
end
function LayoutBlock:LogicalTopForChild(child)
	return if_else(self:IsHorizontalWritingMode(), child:Y(), child:X());
end

function LayoutBlock:LogicalLeftForChild(child)
	return if_else(self:IsHorizontalWritingMode(), child:X(), child:Y());
end

-- Accessors for logical width/height and margins in the containing block's block-flow direction.
-- ApplyLayoutDeltaMode is enum, can be "ApplyLayoutDelta", "DoNotApplyLayoutDelta"
--void RenderBlock::setLogicalTopForChild(RenderBox* child, LayoutUnit logicalTop, ApplyLayoutDeltaMode applyDelta)
function LayoutBlock:SetLogicalLeftForChild(child, logicalLeft, applyDelta)
	applyDelta = if_else(applyDelta == nil, "DoNotApplyLayoutDelta", applyDelta);
	if (self:IsHorizontalWritingMode()) then
--        if (applyDelta == ApplyLayoutDelta)
--            view()->addLayoutDelta(LayoutSize(child->x() - logicalLeft, 0));
        child:SetX(logicalLeft);
    else
--        if (applyDelta == ApplyLayoutDelta)
--            view()->addLayoutDelta(LayoutSize(0, child->y() - logicalLeft));
        child:SetY(logicalLeft);
    end
end

function LayoutBlock:SetLogicalTopForChild(child, logicalTop, applyDelta)
	applyDelta = if_else(applyDelta == nil, "DoNotApplyLayoutDelta", applyDelta);
	if (self:IsHorizontalWritingMode()) then
--        if (applyDelta == ApplyLayoutDelta)
--            view()->addLayoutDelta(LayoutSize(0, child->y() - logicalTop));
        child:SetY(logicalTop);
    else
--        if (applyDelta == ApplyLayoutDelta)
--            view()->addLayoutDelta(LayoutSize(child->x() - logicalTop, 0));
        child:SetX(logicalTop);
    end
end

function LayoutBlock:MarginBeforeForChild(child)
	local write_mode = self:Style():WritingMode();
	if(write_mode ==  WritingModeEnum.TopToBottomWritingMode) then
		return child:MarginTop();
	elseif(write_mode ==  WritingModeEnum.BottomToTopWritingMode) then
		return child:MarginBottom();
	elseif(write_mode ==  WritingModeEnum.LeftToRightWritingMode) then
		return child:MarginLeft();
	elseif(write_mode ==  WritingModeEnum.RightToLeftWritingMode) then
		return child:MarginRight();
	end
	return child:MarginTop();
end

function LayoutBlock:MarginAfterForChild(child)
	local write_mode = self:Style():WritingMode();
	if(write_mode ==  WritingModeEnum.TopToBottomWritingMode) then
		return child:MarginBottom();
	elseif(write_mode ==  WritingModeEnum.BottomToTopWritingMode) then
		return child:MarginTop();
	elseif(write_mode ==  WritingModeEnum.LeftToRightWritingMode) then
		return child:MarginRight();
	elseif(write_mode ==  WritingModeEnum.RightToLeftWritingMode) then
		return child:MarginLeft();
	end
	return child:MarginBottom();
end
function LayoutBlock:MarginStartForChild(child)
	local start_;
	if(self:IsHorizontalWritingMode()) then
		start_ = if_else(self:Style():IsLeftToRightDirection(), child:MarginLeft(), child:MarginRight());
	else
		start_ = if_else(self:Style():IsLeftToRightDirection(), child:MarginTop(), child:MarginBottom());
	end
	return start_;
end

function LayoutBlock:MarginEndForChild(child)
	local end_;
	if(self:IsHorizontalWritingMode()) then
		end_ = if_else(self:Style():IsLeftToRightDirection(), child:MarginRight(), child:MarginLeft());
	else
		end_ = if_else(self:Style():IsLeftToRightDirection(), child:MarginBottom(), child:MarginTop());
	end
	return end_;
end

function LayoutBlock:MarginLogicalLeftForChild(child)
	if (self:IsHorizontalWritingMode()) then
        return child:MarginLeft();
	end
    return child:MarginTop();
end

function LayoutBlock:MarginLogicalRightForChild(child)
	if (self:IsHorizontalWritingMode()) then
        return child:MarginRight();
	end
    return child:MarginBottom();
end
function LayoutBlock:SetMarginStartForChild(child, margin)
	if (self:IsHorizontalWritingMode()) then
        if (self:Style():IsLeftToRightDirection()) then
            child:SetMarginLeft(margin);
        else
            child:SetMarginRight(margin);
		end
    else
        if (self:Style():IsLeftToRightDirection()) then
            child:SetMarginTop(margin);
        else
            child:SetMarginBottom(margin);
		end
    end
end

function LayoutBlock:SetMarginEndForChild(child, margin)
	if (self:IsHorizontalWritingMode()) then
        if (self:Style():IsLeftToRightDirection()) then
            child:SetMarginRight(margin);
        else
            child:SetMarginLeft(margin);
		end
    else
        if (self:Style():IsLeftToRightDirection()) then
            child:SetMarginBottom(margin);
        else
            child:SetMarginTop(margin);
		end
    end
end

function LayoutBlock:SetMarginBeforeForChild(child, margin)
	local write_mode = self:Style():WritingMode();
	if(write_mode ==  WritingModeEnum.TopToBottomWritingMode) then
		child:SetMarginTop(margin);
	elseif(write_mode ==  WritingModeEnum.BottomToTopWritingMode) then
		child:SetMarginBottom(margin);
	elseif(write_mode ==  WritingModeEnum.LeftToRightWritingMode) then
		child:SetMarginLeft(margin);
	elseif(write_mode ==  WritingModeEnum.RightToLeftWritingMode) then
		child:SetMarginRight(margin);
	end
end

function LayoutBlock:SetMarginAfterForChild(child, margin)
	local write_mode = self:Style():WritingMode();
	if(write_mode ==  WritingModeEnum.TopToBottomWritingMode) then
		child:SetMarginBottom(margin);
	elseif(write_mode ==  WritingModeEnum.BottomToTopWritingMode) then
		child:SetMarginTop(margin);
	elseif(write_mode ==  WritingModeEnum.LeftToRightWritingMode) then
		child:SetMarginRight(margin);
	elseif(write_mode ==  WritingModeEnum.RightToLeftWritingMode) then
		child:SetMarginLeft(margin);
	end
end
function LayoutBlock:CollapsedMarginBeforeForChild(child)
	--TODO: fixed this function
end
function LayoutBlock:CollapsedMarginAfterForChild(child)
	--TODO: fixed this function
end

function LayoutBlock:DesiredColumnWidth()
	--TODO: fixed this function
	return 0;
end

--LayoutUnit availableLogicalWidthForLine(LayoutUnit position, bool firstLine, RenderRegion* region, LayoutUnit offsetFromLogicalTopOfFirstPage) const
--LayoutUnit availableLogicalWidthForLine(LayoutUnit position, bool firstLine) const
function LayoutBlock:AvailableLogicalWidthForLine(position, firstLine, region, offsetFromLogicalTopOfFirstPage)
	if(region == nil and offsetFromLogicalTopOfFirstPage == nil) then
		return self:AvailableLogicalWidthForLine(position, firstLine, self:RegionAtBlockOffset(position), self:OffsetFromLogicalTopOfFirstPage());
	end
	--TODO: fixed this function
	local right = self:LogicalRightOffsetForLine(position, firstLine, region, offsetFromLogicalTopOfFirstPage);
	local left = self:LogicalLeftOffsetForLine(position, firstLine, region, offsetFromLogicalTopOfFirstPage);
	return math.max(0, right - left);
end

function LayoutBlock:AvailableLogicalWidth()
	if (self:HasColumns()) then
        return self:DesiredColumnWidth();
	end
    return LayoutBlock._super.AvailableLogicalWidth(self);
end

function LayoutBlock:IsInlineBlockOrInlineTable()
	return self:IsInline() and self:IsReplaced();
end

function LayoutBlock:UpdateFirstLetter()
	--TODO: fixed this function
end

function LayoutBlock:Layout()
	-- Update our first letter info now.
	self:UpdateFirstLetter();

	-- Table cells call layoutBlock directly, so don't add any logic here.  Put code into
    -- layoutBlock().
	self:LayoutBlock(false);

	if(self:HasControlClip() and self.overflow) then
		self:ClearLayoutOverflow();
	end
end

function LayoutBlock:ClearFloats(layoutPass)
	if (self.floatingObjects) then
		self.floatingObjects:SetHorizontalWritingMode(self:IsHorizontalWritingMode());
	end

	-- Clear our positioned floats boolean.
	self.hasPositionedFloats = false;

	-- Inline blocks are covered by the isReplaced() check in the avoidFloats method.
	if (self:AvoidsFloats() or self:IsRoot() or self:IsLayoutView() or self:IsFloatingOrPositioned() or self:IsTableCell()) then
		if (self.floatingObjects) then
			--deleteAllValues(self.floatingObjects->set());
			self.floatingObjects:Clear();
		end
		if (layoutPass == "PositionedFloatLayoutPass") then
			self:AddPositionedFloats();
		end
		return;
	end

	--typedef HashMap<RenderObject*, FloatingObject*> RendererToFloatInfoMap;
	--RendererToFloatInfoMap floatMap;
	local floatMap = {};

	if (self.floatingObjects) then
		local floatingObjectSet = self.floatingObjects:Set();
		if (self:ChildrenInline()) then
			local it = floatingObjectSet:Begin();
			while(it) do
				local f = it();
				floatMap[f:Renderer()] = f;
			
				it = floatingObjectSet:next(it);
			end
		else
			--deleteAllValues(floatingObjectSet);
		end
		self.floatingObjects:Clear();
	end

	if (layoutPass == "PositionedFloatLayoutPass") then
		self:AddPositionedFloats();
	end

	-- We should not process floats if the parent node is not a RenderBlock. Otherwise, we will add 
	-- floats in an invalid context. This will cause a crash arising from a bad cast on the parent.
	-- See <rdar:--problem/8049753>, where float property is applied on a text node in a SVG.
	if (not self:Parent() or not self:Parent():IsLayoutBlock()) then
		return;
	end

	-- Attempt to locate a previous sibling with overhanging floats.  We skip any elements that are
	-- out of flow (like floating/positioned elements), and we also skip over any objects that may have shifted
	-- to avoid floats.
	local parentBlock = self:Parent():ToRenderBlock();
	local parentHasFloats = parentBlock:HasPositionedFloats();
	local prev = self:PreviousSibling();
	while (prev and (prev:IsFloatingOrPositioned() or not prev:IsBox() or not prev:IsLayoutBlock() or prev:ToRenderBlock():AvoidsFloats())) do
		if (prev:IsFloating()) then
			parentHasFloats = true;
		end
		prev = prev:PreviousSibling();
	end

	-- First add in floats from the parent.
	local logicalTopOffset = self:LogicalTop();
	if (parentHasFloats) then
		self:AddIntrudingFloats(parentBlock, parentBlock:LogicalLeftOffsetForContent(), logicalTopOffset);
	end
	local logicalLeftOffset = 0;
	if (prev) then
		logicalTopOffset = logicalTopOffset - prev:ToRenderBox():LogicalTop();
	elseif (not parentHasFloats) then
		prev = parentBlock;
		logicalLeftOffset = logicalLeftOffset + parentBlock:LogicalLeftOffsetForContent();
	end

	-- Add overhanging floats from the previous RenderBlock, but only if it has a float that intrudes into our space.    
	local block = nil;
	if(prev) then
		block = prev:ToRenderBlock();
	end
	if (block and block.floatingObjects and block:LowestFloatLogicalBottomIncludingPositionedFloats() > logicalTopOffset) then
		self:AddIntrudingFloats(block, logicalLeftOffset, logicalTopOffset);
	end

	if (self:ChildrenInline()) then
		--LayoutUnit changeLogicalTop = numeric_limits<LayoutUnit>::max();
		--LayoutUnit changeLogicalBottom = numeric_limits<LayoutUnit>::min();
		local changeLogicalTop = INT_MAX;
		local changeLogicalBottom = INT_MIN;
		if (self.floatingObjects) then
			local floatingObjectSet = self.floatingObjects:Set();
			local it = floatingObjectSet:Begin();
			while(it) do
				--FloatingObject* f = *it;
				local f = it();
			
				local oldFloatingObject = floatMap[f:Renderer()];
				local logicalBottom = self:LogicalBottomForFloat(f);
				if (oldFloatingObject) then
					local oldLogicalBottom = self:LogicalBottomForFloat(oldFloatingObject);
					if (self:LogicalWidthForFloat(f) ~= self:LogicalWidthForFloat(oldFloatingObject) or self:LogicalLeftForFloat(f) ~= self:LogicalLeftForFloat(oldFloatingObject)) then
						changeLogicalTop = 0;
						changeLogicalBottom = math.max(changeLogicalBottom, math.max(logicalBottom, oldLogicalBottom));
					elseif (logicalBottom ~= oldLogicalBottom) then
						changeLogicalTop = math.min(changeLogicalTop, math.min(logicalBottom, oldLogicalBottom));
						changeLogicalBottom = math.max(changeLogicalBottom, math.max(logicalBottom, oldLogicalBottom));
					end

					floatMap[f:Renderer()] = nil;
					if (oldFloatingObject.originatingLine and not self:SelfNeedsLayout()) then
						--ASSERT(oldFloatingObject->m_originatingLine->renderer() == this);
						oldFloatingObject.originatingLine:MarkDirty();
					end
					--delete oldFloatingObject;
				else
					changeLogicalTop = 0;
					changeLogicalBottom = math.max(changeLogicalBottom, logicalBottom);
				end
			
				it = floatingObjectSet:next(it);
			end
		end
	
		for render,floatingObject in pairs(floatMap) do
			if (not floatingObject.isDescendant) then
				changeLogicalTop = 0;
				changeLogicalBottom = math.max(changeLogicalBottom, self:LogicalBottomForFloat(floatingObject));
			end
		end

	
		--deleteAllValues(floatMap);

		self:MarkLinesDirtyInBlockRange(changeLogicalTop, changeLogicalBottom);
	end
end

function LayoutBlock:PositionedFloatsNeedRelayout()
	--TODO: fixed this function
	return false;
end

function LayoutBlock:IsBlockFlow()
	return (not self:IsInline() or self:IsReplaced()) and not self:IsTable();
end

function LayoutBlock:LayoutBlock(relayoutChildren, pageLogicalHeight, layoutPass)
	pageLogicalHeight = pageLogicalHeight or 0;
	layoutPass = layoutPass or "NormalLayoutPass";
	if(not self:NeedsLayout()) then
		return;
	end
	if(self:IsInline() and not self:IsInlineBlockOrInlineTable()) then
		return;
	end
	if (not relayoutChildren and self:SimplifiedLayout()) then
        return;
	end

	local repainter = LayoutRepainter:new():init(self, self.everHadLayout and self:CheckForRepaintDuringLayout());

	local oldWidth = self:LogicalWidth();

	self:ComputeLogicalWidth();

	if(oldWidth ~= self:LogicalWidth()) then
		relayoutChildren = true;
	end


	local floatsLayoutPass = layoutPass;
    if (floatsLayoutPass == "NormalLayoutPass" and not relayoutChildren and not self:PositionedFloatsNeedRelayout()) then
        floatsLayoutPass = "PositionedFloatLayoutPass";
	end
	self:ClearFloats(floatsLayoutPass);

	local previousHeight = self:LogicalHeight();
    self:SetLogicalHeight(0);
    local hasSpecifiedPageLogicalHeight = false;
    local pageLogicalHeightChanged = false;
--    ColumnInfo* colInfo = columnInfo();
--    if (hasColumns()) {
--        if (!pageLogicalHeight) {
--            // We need to go ahead and set our explicit page height if one exists, so that we can
--            // avoid doing two layout passes.
--            computeLogicalHeight();
--            LayoutUnit columnHeight = contentLogicalHeight();
--            if (columnHeight > 0) {
--                pageLogicalHeight = columnHeight;
--                hasSpecifiedPageLogicalHeight = true;
--            }
--            setLogicalHeight(0);
--        }
--        if (colInfo->columnHeight() != pageLogicalHeight && m_everHadLayout) {
--            colInfo->setColumnHeight(pageLogicalHeight);
--            pageLogicalHeightChanged = true;
--        }
--        
--        if (!hasSpecifiedPageLogicalHeight && !pageLogicalHeight)
--            colInfo->clearForcedBreaks();
--    }

	-- We use four values, maxTopPos, maxTopNeg, maxBottomPos, and maxBottomNeg, to track
    -- our current maximal positive and negative margins.  These values are used when we
    -- are collapsed with adjacent blocks, so for example, if you have block A and B
    -- collapsing together, then you'd take the maximal positive margin from both A and B
    -- and subtract it from the maximal negative margin from both A and B to get the
    -- true collapsed margin.  This algorithm is recursive, so when we finish layout()
    -- our block knows its current maximal positive/negative values.
    --
    -- Start out by setting our margin values to our current margins.  Table cells have
    -- no margins, so we don't fill in the values for table cells.
    local isCell = self:IsTableCell();
    if (not isCell) then
        self:InitMaxMarginValues();
        
        self:SetMarginBeforeQuirk(self:Style():MarginBefore():Quirk());
        self:SetMarginAfterQuirk(self:Style():MarginAfter():Quirk());

        local n = self:Node();
--        if (n && n->hasTagName(formTag) && static_cast<HTMLFormElement*>(n)->isMalformed()) {
--            // See if this form is malformed (i.e., unclosed). If so, don't give the form
--            // a bottom margin.
--            setMaxMarginAfterValues(0, 0);
--        }
        
        self:SetPaginationStrut(0);
    end


	-- For overflow:scroll blocks, ensure we have both scrollbars in place always.
--    if (self:ScrollsOverflow()) then
--        if (self:Style()->overflowX() == OSCROLL) then
--            layer()->setHasHorizontalScrollbar(true);
--		end
--        if (self:Style()->overflowY() == OSCROLL) then
--            layer()->setHasVerticalScrollbar(true);
--		end
--    end

	local repaintLogicalTop = 0;
    local repaintLogicalBottom = 0;
    local maxFloatLogicalBottom = 0;
    if (not self:FirstChild() and not self:IsAnonymousBlock()) then
        self:SetChildrenInline(true);
	end

    if (self:ChildrenInline()) then
        repaintLogicalTop, repaintLogicalBottom = self:LayoutInlineChildren(relayoutChildren, repaintLogicalTop, repaintLogicalBottom);
    else
        self:LayoutBlockChildren(relayoutChildren, maxFloatLogicalBottom);
	end

	-- Expand our intrinsic height to encompass floats.
    local toAdd = self:BorderAfter() + self:PaddingAfter() + self:ScrollbarLogicalHeight();
--    if (lowestFloatLogicalBottom() > (logicalHeight() - toAdd) && expandsToEncloseOverhangingFloats())
--        setLogicalHeight(lowestFloatLogicalBottom() + toAdd);
--    
--    if (layoutColumns(hasSpecifiedPageLogicalHeight, pageLogicalHeight, statePusher))
--        return;

	-- Calculate our new height.
    local oldHeight = self:LogicalHeight();
    local oldClientAfterEdge = self:ClientLogicalBottom();
    self:ComputeLogicalHeight();
    local newHeight = self:LogicalHeight();
    if (oldHeight ~= newHeight) then
        if (oldHeight > newHeight and maxFloatLogicalBottom > newHeight and self:ChildrenInline()) then
            -- One of our children's floats may have become an overhanging float for us. We need to look for it.
			local child = self:FirstChild();
			while(child) do
				if (child:IsLayoutFlow() and not child:IsFloatingOrPositioned()) then
                    local block = child:ToRenderBlock();
                    if (block:LowestFloatLogicalBottomIncludingPositionedFloats() + block:LogicalTop() > newHeight) then
                        self:AddOverhangingFloats(block, false);
					end
                end

				child = child:NextSibling();
			end
        end
    end


	if (previousHeight ~= newHeight) then
        relayoutChildren = true;
	end

    local needAnotherLayoutPass = self:LayoutPositionedObjects(relayoutChildren or self:IsRoot());

    if (self:InRenderFlowThread()) then
        --enclosingRenderFlowThread()->setRegionRangeForBox(this, offsetFromLogicalTopOfFirstPage());
	end

    -- Add overflow from children (unless we're multi-column, since in that case all our child overflow is clipped anyway).
    self:ComputeOverflow(oldClientAfterEdge);

	--statePusher.pop();

--    if (renderView->layoutState()->m_pageLogicalHeight)
--        setPageLogicalOffset(renderView->layoutState()->pageLogicalOffset(logicalTop()));

    self:UpdateLayerTransform();

    -- Update our scroll information if we're overflow:auto/scroll/hidden now that we know if
    -- we overflow or not.
    self:UpdateScrollInfoAfterLayout();

	-- FIXME: This repaint logic should be moved into a separate helper function!
    -- Repaint with our new bounds if they are different from our old bounds.
    local didFullRepaint = repainter:RepaintAfterLayout();
    --if (!didFullRepaint && repaintLogicalTop != repaintLogicalBottom && (style()->visibility() == VISIBLE || enclosingLayer()->hasVisibleContent())) {

	if(not didFullRepaint and repaintLogicalTop ~= repaintLogicalBottom and self:Style():Visibility() == VisibilityEnum.VISIBLE) then
        -- FIXME: We could tighten up the left and right invalidation points if we let layoutInlineChildren fill them in based off the particular lines
        -- it had to lay out.  We wouldn't need the hasOverflowClip() hack in that case either.
        local repaintLogicalLeft = self:LogicalLeftVisualOverflow();
        local repaintLogicalRight = self:LogicalRightVisualOverflow();
--        if (hasOverflowClip()) {
--            // If we have clipped overflow, we should use layout overflow as well, since visual overflow from lines didn't propagate to our block's overflow.
--            // Note the old code did this as well but even for overflow:visible.  The addition of hasOverflowClip() at least tightens up the hack a bit.
--            // layoutInlineChildren should be patched to compute the entire repaint rect.
--            repaintLogicalLeft = min(repaintLogicalLeft, logicalLeftLayoutOverflow());
--            repaintLogicalRight = max(repaintLogicalRight, logicalRightLayoutOverflow());
--        }
        
        local repaintRect = nil;
        if (self:IsHorizontalWritingMode()) then
            repaintRect = LayoutRect:new(repaintLogicalLeft, repaintLogicalTop, repaintLogicalRight - repaintLogicalLeft, repaintLogicalBottom - repaintLogicalTop);
        else
            repaintRect = LayoutRect:new(repaintLogicalTop, repaintLogicalLeft, repaintLogicalBottom - repaintLogicalTop, repaintLogicalRight - repaintLogicalLeft);
		end

        -- The repaint rect may be split across columns, in which case adjustRectForColumns() will return the union.
        -- adjustRectForColumns(repaintRect);

        -- repaintRect.inflate(maximalOutlineSize(PaintPhaseOutline));
        
--        if (hasOverflowClip()) {
--            // Adjust repaint rect for scroll offset
--            repaintRect.move(-layer()->scrolledContentOffset());
--
--            // Don't allow this rect to spill out of our overflow box.
--            repaintRect.intersect(LayoutRect(LayoutPoint(), size()));
--        }

        -- Make sure the rect is still non-empty after intersecting for overflow above
        if (not repaintRect:IsEmpty()) then
            -- FIXME: Might need rounding once we switch to float, see https://bugs.webkit.org/show_bug.cgi?id=64021
            self:RepaintRectangle(repaintRect); -- We need to do a partial repaint of our content.
--            if (hasReflection())
--                repaintRectangle(reflectedRect(repaintRect));
        end
    end

	if (needAnotherLayoutPass and layoutPass == "NormalLayoutPass") then
        self:SetChildNeedsLayout(true, false);
        self:LayoutBlock(false, pageLogicalHeight, "PositionedFloatLayoutPass");
    else
        self:SetNeedsLayout(false);
	end

end

function LayoutBlock:UpdateLayerTransform()
	--TODO: fixed this function
end

function LayoutBlock:HasLineIfEmpty()
	--TODO: fixed this function
	return false;
end

function LayoutBlock:CheckLinesForTextOverflow()
	--TODO: fixed this function
end

function LayoutBlock:LayoutBlockChildren(relayoutChildren, maxFloatLogicalBottom)
	--TODO: fixed this function
--	if (gPercentHeightDescendantsMap) {
--        if (HashSet<RenderBox*>* descendants = gPercentHeightDescendantsMap->get(this)) {
--            HashSet<RenderBox*>::iterator end = descendants->end();
--            for (HashSet<RenderBox*>::iterator it = descendants->begin(); it != end; ++it) {
--                RenderBox* box = *it;
--                while (box != this) {
--                    if (box->normalChildNeedsLayout())
--                        break;
--                    box->setChildNeedsLayout(true, false);
--                    box = box->containingBlock();
--                    ASSERT(box);
--                    if (!box)
--                        break;
--                }
--            }
--        }
--    }

    local beforeEdge = self:BorderBefore() + self:PaddingBefore();
    local afterEdge = self:BorderAfter() + self:PaddingAfter() + self:ScrollbarLogicalHeight();

    self:SetLogicalHeight(beforeEdge);

    -- The margin struct caches all our current margin collapsing state.  The compact struct caches state when we encounter compacts,
    local marginInfo = MarginInfo:new():init(self, beforeEdge, afterEdge);

    -- Fieldsets need to find their legend and position it inside the border of the object.
    -- The legend then gets skipped during normal layout.  The same is true for ruby text.
    -- It doesn't get included in the normal layout process but is instead skipped.
    --RenderObject* childToExclude = layoutSpecialExcludedChild(relayoutChildren);

    local previousFloatLogicalBottom = 0;
    maxFloatLogicalBottom = 0;

    local next = self:FirstChildBox();

    while (next) do
        local child = next;
        next = child:NextSiblingBox();

--        if (childToExclude == child)
--            continue; // Skip this child, since it will be positioned by the specialized subclass (fieldsets and ruby runs).

        -- Make sure we layout children if they need it.
        -- FIXME: Technically percentage height objects only need a relayout if their percentage isn't going to be turned into
        -- an auto value.  Add a method to determine this, so that we can avoid the relayout.
        if (relayoutChildren or ((child:Style():LogicalHeight():IsPercent() or child:Style():LogicalMinHeight():IsPercent() or child:Style():LogicalMaxHeight():IsPercent()) and not self:IsLayoutView())) then
            child:SetChildNeedsLayout(true, false);
		end
        -- If relayoutChildren is set and the child has percentage padding or an embedded content box, we also need to invalidate the childs pref widths.
        if (relayoutChildren and child:NeedsPreferredWidthsRecalculation()) then
            child:SetPreferredLogicalWidthsDirty(true, false);
		end

        -- Handle the four types of special elements first.  These include positioned content, floating content, compacts and
        -- run-ins.  When we encounter these four types of objects, we don't actually lay them out as normal flow blocks.
        if (not self:HandleSpecialChild(child, marginInfo)) then
			-- Lay out the child.
			self:LayoutBlockChild(child, marginInfo, previousFloatLogicalBottom, maxFloatLogicalBottom);	
		end
    end
    
    -- Now do the handling of the bottom of the block, adding in our bottom border/padding and
    -- determining the correct collapsed bottom margin information.
    self:HandleAfterSideOfBlock(beforeEdge, afterEdge, marginInfo);
end

function LayoutBlock:HandleSpecialChild(child, marginInfo)
	-- Handle in the given order
    return self:HandlePositionedChild(child, marginInfo)
        or self:HandleFloatingChild(child, marginInfo)
        or self:HandleRunInChild(child);
	--return false;
end

--bool RenderBlock::handlePositionedChild(RenderBox* child, const MarginInfo& marginInfo)
function LayoutBlock:HandlePositionedChild(child, marginInfo)
    if (child:IsPositioned()) then
        child:ContainingBlock():InsertPositionedObject(child);
        self:AdjustPositionedBlock(child, marginInfo);
        return true;
    end
    return false;
end

--bool RenderBlock::handleFloatingChild(RenderBox* child, const MarginInfo& marginInfo)
function LayoutBlock:HandleFloatingChild(child, marginInfo)
    if (child:IsFloating()) then
        self:InsertFloatingObject(child);
        self:AdjustFloatingBlock(marginInfo);
        return true;
    end
    return false;
end

--bool RenderBlock::handleRunInChild(RenderBox* child)
function LayoutBlock:HandleRunInChild(child)
    -- See if we have a run-in element with inline children.  If the
    -- children aren't inline, then just treat the run-in as a normal
    -- block.
    if (not child:IsRunIn() or not child:ChildrenInline()) then
        return false;
	end
    -- FIXME: We don't handle non-block elements with run-in for now.
    if (not child:IsLayoutBlock()) then
        return false;
	end

	-- TODO: add latter;
	return true;
end

--void RenderBlock::adjustFloatingBlock(const MarginInfo& marginInfo)
function LayoutBlock:AdjustFloatingBlock(marginInfo)
    -- The float should be positioned taking into account the bottom margin
    -- of the previous flow.  We add that margin into the height, get the
    -- float positioned properly, and then subtract the margin out of the
    -- height again.  In the case of self-collapsing blocks, we always just
    -- use the top margins, since the self-collapsing block collapsed its
    -- own bottom margin into its top margin.
    --
    -- Note also that the previous flow may collapse its margin into the top of
    -- our block.  If this is the case, then we do not add the margin in to our
    -- height when computing the position of the float.   This condition can be tested
    -- for by simply calling canCollapseWithMarginBefore.  See
    -- http://www.hixie.ch/tests/adhoc/css/box/block/margin-collapse/046.html for
    -- an example of this scenario.
    local marginOffset = if_else(marginInfo:CanCollapseWithMarginBefore(), 0, marginInfo:Margin());
    self:SetLogicalHeight(self:LogicalHeight() + marginOffset);
    self:PositionNewFloats();
    self:SetLogicalHeight(self:LogicalHeight() - marginOffset);
end

--void RenderBlock::adjustPositionedBlock(RenderBox* child, const MarginInfo& marginInfo)
function LayoutBlock:AdjustPositionedBlock(child, marginInfo)
    local isHorizontal = self:IsHorizontalWritingMode();
    local hasStaticBlockPosition = child:Style():HasStaticBlockPosition(isHorizontal);
    
    local logicalTop = self:LogicalHeight();
    self:SetStaticInlinePositionForChild(child, logicalTop, self:StartOffsetForContent(logicalTop));

    if (not marginInfo:CanCollapseWithMarginBefore()) then
        child:ComputeBlockDirectionMargins(self);
        local marginBefore = self:MarginBeforeForChild(child);
        local collapsedBeforePos = marginInfo:PositiveMargin();
        local collapsedBeforeNeg = marginInfo:NegativeMargin();
        if (marginBefore > 0) then
            if (marginBefore > collapsedBeforePos) then
                collapsedBeforePos = marginBefore;
			end
        else
            if (-marginBefore > collapsedBeforeNeg) then
                collapsedBeforeNeg = -marginBefore;
			end
        end
        logicalTop = logicalTop + (collapsedBeforePos - collapsedBeforeNeg) - marginBefore;
    end
    
    local childLayer = child:Layer();
    if (childLayer:StaticBlockPosition() ~= logicalTop) then
        childLayer:SetStaticBlockPosition(logicalTop);
        if (hasStaticBlockPosition) then
            child:SetChildNeedsLayout(true, false);
		end
    end
end

function LayoutBlock:MaxPositiveMarginBefore()
	if(self.m_rareData) then
		return self.m_rareData.m_margins:PositiveMarginBefore();
	end
	return RenderBlockRareData.PositiveMarginBeforeDefault(self);
end

function LayoutBlock:MaxNegativeMarginBefore()
	if(self.m_rareData) then
		return self.m_rareData.m_margins:NegativeMarginBefore();
	end
	return RenderBlockRareData.NegativeMarginBeforeDefault(self);
end

function LayoutBlock:MaxPositiveMarginAfter()
	if(self.m_rareData) then
		return self.m_rareData.m_margins:PositiveMarginAfter();
	end
	return RenderBlockRareData.PositiveMarginAfterDefault(self);
end

function LayoutBlock:MaxNegativeMarginAfter()
	if(self.m_rareData) then
		return self.m_rareData.m_margins:NegativeMarginAfter();
	end
	return RenderBlockRareData.NegativeMarginAfterDefault(self);
end

function LayoutBlock:CollapsedMarginBefore()
	return self:MaxPositiveMarginBefore() - self:MaxNegativeMarginBefore();
end

function LayoutBlock:CollapsedMarginAfter()
	return self:MaxPositiveMarginAfter() - self:MaxNegativeMarginAfter();
end

function LayoutBlock:CollapsedMarginBeforeForChild(child)
    -- If the child has the same directionality as we do, then we can just return its collapsed margin.
    if (not child:IsWritingModeRoot()) then
        return child:CollapsedMarginBefore();
    end
    -- The child has a different directionality.  If the child is parallel, then it's just
    -- flipped relative to us.  We can use the collapsed margin for the opposite edge.
    if (child:IsHorizontalWritingMode() == self:IsHorizontalWritingMode()) then
        return child:CollapsedMarginAfter();
    end
    -- The child is perpendicular to us, which means its margins don't collapse but are on the
    -- "logical left/right" sides of the child box.  We can just return the raw margin in this case.  
    return self:MarginBeforeForChild(child);
end

function LayoutBlock:ContainsFloats()
	return self.floatingObjects and not self.floatingObjects:Set():isEmpty();
end

function LayoutBlock:ContainsFloat(renderer)
	-- return m_floatingObjects && m_floatingObjects->set().contains<RenderBox*, FloatingObjectHashTranslator>(renderer);
    return self.floatingObjects ~= nil and self.floatingObjects:Set():contains(renderer);
end

function LayoutBlock:GetClearDelta(child, logicalTop)
	-- There is no need to compute clearance if we have no floats.
    if (not self:ContainsFloats()) then
        return 0;
    end
	-- At least one float is present.  We need to perform the clearance computation.
	local child_clear = child:Style():Clear();
    local clearSet = child_clear ~= ClearEnum.CNONE;
    local logicalBottom = 0;
	
	if(child_clear == ClearEnum.CLEFT) then
		logicalBottom = self:LowestFloatLogicalBottom(FloatType.FloatLeft);
	elseif(child_clear == ClearEnum.CRIGHT) then
		logicalBottom = self:LowestFloatLogicalBottom(FloatType.FloatRight);
	elseif(child_clear == ClearEnum.CBOTH) then
		logicalBottom = self:LowestFloatLogicalBottom();
	end
	

    -- We also clear floats if we are too big to sit on the same line as a float (and wish to avoid floats by default).
    local result = if_else(clearSet, math.max(0, logicalBottom - logicalTop), 0);
    if (not result and child:AvoidsFloats()) then
        local newLogicalTop = logicalTop;
        while (true) do
            local availableLogicalWidthAtNewLogicalTopOffset = self:AvailableLogicalWidthForLine(newLogicalTop, false);
            -- FIXME: Change to use roughlyEquals when we move to float.
            -- See https:--bugs.webkit.org/show_bug.cgi?id=66148
            if (availableLogicalWidthAtNewLogicalTopOffset == self:AvailableLogicalWidthForContent(newLogicalTop)) then
                return newLogicalTop - logicalTop;
			end

            -- FIXME: None of this is right for perpendicular writing-mode children.
            local childOldLogicalWidth = child:LogicalWidth();
            local childOldMarginLeft = child:MarginLeft();
            local childOldMarginRight = child:MarginRight();
            local childOldLogicalTop = child:LogicalTop();

            child:SetLogicalTop(newLogicalTop);
            child:ComputeLogicalWidth();
            local region = self:RegionAtBlockOffset(self:LogicalTopForChild(child));
            local borderBox = child:BorderBoxRectInRegion(region, self:OffsetFromLogicalTopOfFirstPage() + self:LogicalTopForChild(child), DoNotCacheRenderBoxRegionInfo);
            local childLogicalWidthAtNewLogicalTopOffset = if_else(self:IsHorizontalWritingMode(), borderBox:Width(), borderBox:Height());

            child:SetLogicalTop(childOldLogicalTop);
            child:SetLogicalWidth(childOldLogicalWidth);
            child:SetMarginLeft(childOldMarginLeft);
            child:SetMarginRight(childOldMarginRight);
            
            -- FIXME: Change to use roughlyEquals when we move to float.
            -- See https:--bugs.webkit.org/show_bug.cgi?id=66148
            if (childLogicalWidthAtNewLogicalTopOffset <= availableLogicalWidthAtNewLogicalTopOffset) then
                return newLogicalTop - logicalTop;
			end

            newLogicalTop = self:NextFloatLogicalBottomBelow(newLogicalTop);
            --ASSERT(newLogicalTop >= logicalTop);
            if (newLogicalTop < logicalTop) then
                break;
			end
        end
        --ASSERT_NOT_REACHED();
    end
    return result;
end

function LayoutBlock:EstimateLogicalTopPosition(child, marginInfo, estimateWithoutPagination)
	-- FIXME: We need to eliminate the estimation of vertical position, because when it's wrong we sometimes trigger a pathological
    -- relayout if there are intruding floats.
    local logicalTopEstimate = self:LogicalHeight();
    if (not marginInfo:CanCollapseWithMarginBefore()) then
        local childMarginBefore = if_else(child:SelfNeedsLayout(), self:MarginBeforeForChild(child), self:CollapsedMarginBeforeForChild(child));
        logicalTopEstimate = logicalTopEstimate + math.max(marginInfo:Margin(), childMarginBefore);
    end

    -- Adjust logicalTopEstimate down to the next page if the margins are so large that we don't fit on the current page.
--    LayoutState* layoutState = view()->layoutState();
--    if (layoutState->isPaginated() && layoutState->pageLogicalHeight() && logicalTopEstimate > logicalHeight()
--        && hasNextPage(logicalHeight()))
--        logicalTopEstimate = min(logicalTopEstimate, nextPageLogicalTop(logicalHeight()));

    logicalTopEstimate = logicalTopEstimate+ self:GetClearDelta(child, logicalTopEstimate);
    
    --estimateWithoutPagination = logicalTopEstimate;

--    if (layoutState->isPaginated()) {
--        // If the object has a page or column break value of "before", then we should shift to the top of the next page.
--        logicalTopEstimate = applyBeforeBreak(child, logicalTopEstimate);
--    
--        // For replaced elements and scrolled elements, we want to shift them to the next page if they don't fit on the current one.
--        logicalTopEstimate = adjustForUnsplittableChild(child, logicalTopEstimate);
--        
--        if (!child->selfNeedsLayout() && child->isRenderBlock())
--            logicalTopEstimate += toRenderBlock(child)->paginationStrut();
--    }

    return logicalTopEstimate;
end

function LayoutBlock:MarkAllDescendantsWithFloatsForLayout(floatToRemove, inLayout)
	inLayout = if_else(inLayout == nil, true, inLayout);
	if (not self.everHadLayout) then
        return;
	end

    self:SetChildNeedsLayout(true, not inLayout);
 
    if (floatToRemove) then
        self:RemoveFloatingObject(floatToRemove);
	end

    -- Iterate over our children and mark them as needed.
    if (not self:ChildrenInline()) then
		local child = self:FirstChild();
		while(child) do
			if ((not floatToRemove and child:IsFloatingOrPositioned()) or not child:IsLayoutBlock()) then
                --continue;
			else
				local childBlock = child:ToRenderBlock();
				if(floatToRemove) then
					if(childBlock:ContainsFloat(floatToRemove)) then
						childBlock:MarkAllDescendantsWithFloatsForLayout(floatToRemove, inLayout);
					end
				elseif(childBlock:ContainsFloats() or childBlock:ShrinkToAvoidFloats()) then
					childBlock:MarkAllDescendantsWithFloatsForLayout(floatToRemove, inLayout);
				end
				
			end

			child = child:NextSibling();
		end
    end
end

function LayoutBlock:MarkForPaginationRelayoutIfNeeded()
	
end

function LayoutBlock:ClearFloatsIfNeeded(child, marginInfo, oldTopPosMargin, oldTopNegMargin, yPos)
	local heightIncrease = self:GetClearDelta(child, yPos);
    if (heightIncrease == 0) then
        return yPos;
	end
	--TODO: fixed this function
end

--LayoutUnit RenderBlock::addOverhangingFloats(RenderBlock* child, bool makeChildPaintOtherFloats)
function LayoutBlock:AddOverhangingFloats(child, makeChildPaintOtherFloats)
	-- Prevent floats from being added to the canvas by the root element, e.g., <html>.
	if (child:HasOverflowClip() or not child:ContainsFloats() or child:IsRoot() or child:HasColumns() or child:IsWritingModeRoot()) then
		return 0;
	end

--	local childLogicalTop = child:LogicalTop();
--	local childLogicalLeft = child:LogicalLeft();
	local childLogicalTop = 0;
	local childLogicalLeft = 0;
	local lowestFloatLogicalBottom = 0;

	-- Floats that will remain the child's responsibility to paint should factor into its
	-- overflow.
	local childFloatingObjectSet = child.floatingObjects:Set();
	local childIt = childFloatingObjectSet:Begin();
	while(childIt) do
		--FloatingObject* r = *childIt;
		local r = childIt();
	
		local logicalBottomForFloat = math.min(self:LogicalBottomForFloat(r), INT_MAX - childLogicalTop);
		local logicalBottom = childLogicalTop + logicalBottomForFloat;
		lowestFloatLogicalBottom = math.max(lowestFloatLogicalBottom, logicalBottom);
		if (logicalBottom > self:LogicalHeight()) then
			-- If the object is not in the list, we add it now.
			if (not self:ContainsFloat(r:Renderer())) then
				local leftOffset = if_else(self:IsHorizontalWritingMode(), -childLogicalLeft, -childLogicalTop);
				local topOffset = if_else(self:IsHorizontalWritingMode(), -childLogicalTop, -childLogicalLeft);
				local floatingObj = FloatingObject:new():init(r:Type(), LayoutRect:new(r:X() - leftOffset, r:Y() - topOffset, r:Width(), r:Height()));
				floatingObj.renderer = r.renderer;

				-- The nearest enclosing layer always paints the float (so that zindex and stacking
				-- behaves properly).  We always want to propagate the desire to paint the float as
				-- far out as we can, to the outermost block that overlaps the float, stopping only
				-- if we hit a self-painting layer boundary.
				if (r:Renderer():EnclosingFloatPaintingLayer() == self:EnclosingFloatPaintingLayer()) then
					r.shouldPaint = false;
				else
					floatingObj.shouldPaint = false;
				end
			
				floatingObj.isDescendant = true;

				-- We create the floating object list lazily.
				if (not self.floatingObjects) then
					self.floatingObjects = FloatingObjects:new():init(self:IsHorizontalWritingMode());
				end

				self.floatingObjects:Add(floatingObj);
			end
		else
			if (makeChildPaintOtherFloats and not r:ShouldPaint() and not r:Renderer():HasSelfPaintingLayer() and
				r:Renderer():IsDescendantOf(child) and r:Renderer():EnclosingFloatPaintingLayer() == child:EnclosingFloatPaintingLayer()) then
				-- The float is not overhanging from this block, so if it is a descendant of the child, the child should
				-- paint it (the other case is that it is intruding into the child), unless it has its own layer or enclosing
				-- layer.
				-- If makeChildPaintOtherFloats is false, it means that the child must already know about all the floats
				-- it should paint.
				r.shouldPaint = true;
			end
		
			-- Since the float doesn't overhang, it didn't get put into our list.  We need to go ahead and add its overflow in to the
			-- child now.
			if (r:IsDescendant()) then
				child:AddOverflowFromChild(r:Renderer(), LayoutSize:new(self:XPositionForFloatIncludingMargin(r), self:YPositionForFloatIncludingMargin(r)));
			end
		end
	
		childIt = childFloatingObjectSet:next(childIt);
	end

	return lowestFloatLogicalBottom;
end

function LayoutBlock:LayoutBlockChild(child, marginInfo, previousFloatLogicalBottom, maxFloatLogicalBottom)
	local oldPosMarginBefore = self:MaxPositiveMarginBefore();
    local oldNegMarginBefore = self:MaxNegativeMarginBefore();

    -- The child is a normal flow object.  Compute the margins we will use for collapsing now.
    child:ComputeBlockDirectionMargins(self);

	-- Do not allow a collapse if the margin-before-collapse style is set to SEPARATE.
    if (child:Style():MarginBeforeCollapse() == MarginCollapseEnum.MSEPARATE) then
        marginInfo:SetAtBeforeSideOfBlock(false);
        marginInfo:ClearMargin();
    end

	-- Try to guess our correct logical top position.  In most cases this guess will
    -- be correct.  Only if we're wrong (when we compute the real logical top position)
    -- will we have to potentially relayout.
    local estimateWithoutPagination;
    local logicalTopEstimate = self:EstimateLogicalTopPosition(child, marginInfo, estimateWithoutPagination);
    -- Cache our old rect so that we can dirty the proper repaint rects if the child moves.
    local oldRect = Rect:new(child:X(), child:Y() , child:Width(), child:Height());
    local oldLogicalTop = self:LogicalTopForChild(child);

--#ifndef NDEBUG
--    LayoutSize oldLayoutDelta = view()->layoutDelta();
--#endif
    -- Go ahead and position the child as though it didn't collapse with the top.
    self:SetLogicalTopForChild(child, logicalTopEstimate, "ApplyLayoutDelta");

	local childRenderBlock = if_else(child:IsLayoutBlock(), child, nil);
    local markDescendantsWithFloats = false;
    if (logicalTopEstimate ~= oldLogicalTop and not child:AvoidsFloats() and childRenderBlock and childRenderBlock:ContainsFloats()) then
        markDescendantsWithFloats = true;
    elseif (not child:AvoidsFloats() or child:ShrinkToAvoidFloats()) then
        -- If an element might be affected by the presence of floats, then always mark it for layout.
        local fb = math.max(previousFloatLogicalBottom, self:LowestFloatLogicalBottomIncludingPositionedFloats());
        if (fb > logicalTopEstimate) then
            markDescendantsWithFloats = true;
		end
    end

	if (childRenderBlock) then
        if (markDescendantsWithFloats) then
            childRenderBlock:MarkAllDescendantsWithFloatsForLayout();
		end
        if (not child:IsWritingModeRoot()) then
            previousFloatLogicalBottom = math.max(previousFloatLogicalBottom, oldLogicalTop + childRenderBlock:LowestFloatLogicalBottomIncludingPositionedFloats());
		end
    end

	if (not child:NeedsLayout()) then
        child:MarkForPaginationRelayoutIfNeeded();
	end

	local childHadLayout = child.everHadLayout;
	local childNeededLayout = child:NeedsLayout();
    if (childNeededLayout) then
        child:Layout();
	end

	-- Cache if we are at the top of the block right now.
    local atBeforeSideOfBlock = marginInfo:AtBeforeSideOfBlock();

    -- Now determine the correct ypos based off examination of collapsing margin values.
    local logicalTopBeforeClear = self:CollapseMargins(child, marginInfo);

    -- Now check for clear.
    local logicalTopAfterClear = self:ClearFloatsIfNeeded(child, marginInfo, oldPosMarginBefore, oldNegMarginBefore, logicalTopBeforeClear);
    
--    bool paginated = view()->layoutState()->isPaginated();
--    if (paginated)
--        logicalTopAfterClear = adjustBlockChildForPagination(logicalTopAfterClear, estimateWithoutPagination, child,
--            atBeforeSideOfBlock && logicalTopBeforeClear == logicalTopAfterClear);
--
    self:SetLogicalTopForChild(child, logicalTopAfterClear, "ApplyLayoutDelta");


	-- Now we have a final top position.  See if it really does end up being different from our estimate.
    if (logicalTopAfterClear ~= logicalTopEstimate) then
        if (child:ShrinkToAvoidFloats()) then
            -- The child's width depends on the line width.
            -- When the child shifts to clear an item, its width can
            -- change (because it has more available line width).
            -- So go ahead and mark the item as dirty.
            child:SetChildNeedsLayout(true, false);
        end
        
        if (childRenderBlock) then
            if (not child:AvoidsFloats() and childRenderBlock:ContainsFloats()) then
                childRenderBlock:MarkAllDescendantsWithFloatsForLayout();
			end
            if (not child:NeedsLayout()) then
                child:MarkForPaginationRelayoutIfNeeded();
			end
        end

        -- Our guess was wrong. Make the child lay itself out again.
        child:LayoutIfNeeded();
    end

	-- We are no longer at the top of the block if we encounter a non-empty child.  
    -- This has to be done after checking for clear, so that margins can be reset if a clear occurred.
    if (marginInfo:AtBeforeSideOfBlock() and not child:IsSelfCollapsingBlock()) then
        marginInfo:SetAtBeforeSideOfBlock(false);
	end

    -- Now place the child in the correct left position
    self:DetermineLogicalLeftPositionForChild(child);

    -- Update our height now that the child has been placed in the correct position.
    self:SetLogicalHeight(self:LogicalHeight() + self:LogicalHeightForChild(child));
    if (child:Style():MarginAfterCollapse() == MarginCollapseEnum.MSEPARATE) then
        self:SetLogicalHeight(self:LogicalHeight() + self:MarginAfterForChild(child));
        marginInfo:ClearMargin();
    end
    -- If the child has overhanging floats that intrude into following siblings (or possibly out
    -- of this block), then the parent gets notified of the floats now.
    if (childRenderBlock and childRenderBlock:ContainsFloats()) then
        maxFloatLogicalBottom = math.max(maxFloatLogicalBottom, self:AddOverhangingFloats(child, not childNeededLayout));
	end

    local childOffset = Size:new(child:X() - oldRect:X(), child:Y() - oldRect:Y());
    if (childOffset:Width() ~= 0 or childOffset:Height() ~= 0) then
        self:View():AddLayoutDelta(childOffset);

        -- If the child moved, we have to repaint it as well as any floating/positioned
        -- descendants.  An exception is if we need a layout.  In this case, we know we're going to
        -- repaint ourselves (and the child) anyway.
        if (childHadLayout and not self:SelfNeedsLayout() and child:CheckForRepaintDuringLayout()) then
            child:RepaintDuringLayoutIfMoved(oldRect);
		end
    end

    --if (not childHadLayout and child:CheckForRepaintDuringLayout()) {
	if (not childHadLayout and child:CheckForRepaintDuringLayout()) then
        child:Repaint();
        --child->repaintOverhangingFloats(true);
    end

--    if (paginated) {
--        // Check for an after page/column break.
--        LayoutUnit newHeight = applyAfterBreak(child, logicalHeight(), marginInfo);
--        if (newHeight != height())
--            setLogicalHeight(newHeight);
--    }

--    // FIXME: Change to use roughlyEquals when we move to float.
--    // See https://bugs.webkit.org/show_bug.cgi?id=66148
--    ASSERT(oldLayoutDelta == view()->layoutDelta());
end

function LayoutBlock:MarginValuesForChild(child)
	local childBeforePositive = 0;
    local childBeforeNegative = 0;
    local childAfterPositive = 0;
    local childAfterNegative = 0;

    local beforeMargin = 0;
    local afterMargin = 0;

    local childRenderBlock = if_else(child:IsLayoutBlock(), child , nil);
    
    -- If the child has the same directionality as we do, then we can just return its margins in the same direction.
    if (not child:IsWritingModeRoot()) then
        if (childRenderBlock) then
            childBeforePositive = childRenderBlock:MaxPositiveMarginBefore();
            childBeforeNegative = childRenderBlock:MaxNegativeMarginBefore();
            childAfterPositive = childRenderBlock:MaxPositiveMarginAfter();
            childAfterNegative = childRenderBlock:MaxNegativeMarginAfter();
        else
            beforeMargin = child:MarginBefore();
            afterMargin = child:MarginAfter();
        end
    elseif (child:IsHorizontalWritingMode() == self:IsHorizontalWritingMode()) then
        -- The child has a different directionality.  If the child is parallel, then it's just
        -- flipped relative to us.  We can use the margins for the opposite edges.
        if (childRenderBlock) then
            childBeforePositive = childRenderBlock:MaxPositiveMarginAfter();
            childBeforeNegative = childRenderBlock:MaxNegativeMarginAfter();
            childAfterPositive = childRenderBlock:MaxPositiveMarginBefore();
            childAfterNegative = childRenderBlock:MaxNegativeMarginBefore();
        else
            beforeMargin = child:MarginAfter();
            afterMargin = child:MarginBefore();
        end
    else
        -- The child is perpendicular to us, which means its margins don't collapse but are on the
        -- "logical left/right" sides of the child box.  We can just return the raw margin in this case.
        beforeMargin = self:MarginBeforeForChild(child);
        afterMargin = self:MarginAfterForChild(child);
    end

    -- Resolve uncollapsing margins into their positive/negative buckets.
    if (beforeMargin) then
        if (beforeMargin > 0) then
            childBeforePositive = beforeMargin;
        else
            childBeforeNegative = -beforeMargin;
		end
    end
    if (afterMargin) then
        if (afterMargin > 0) then
            childAfterPositive = afterMargin;
        else
            childAfterNegative = -afterMargin;
		end
    end

    return MarginValues:new():init(childBeforePositive, childBeforeNegative, childAfterPositive, childAfterNegative);
end

function LayoutBlock:IsSelfCollapsingBlock()
	-- We are not self-collapsing if we
    -- (a) have a non-zero height according to layout (an optimization to avoid wasting time)
    -- (b) are a table,
    -- (c) have border/padding,
    -- (d) have a min-height
    -- (e) have specified that one of our margins can't collapse using a CSS extension
    if (self:LogicalHeight() > 0
        or self:IsTable() or self:BorderAndPaddingLogicalHeight() ~= 0
        or self:Style():LogicalMinHeight():IsPositive()
        or self:Style():MarginBeforeCollapse() == MarginCollapseEnum.MSEPARATE or self:Style():MarginAfterCollapse() == MarginCollapseEnum.MSEPARATE) then
			return false;
	end

    local logicalHeightLength = self:Style():LogicalHeight();
    local hasAutoHeight = logicalHeightLength:IsAuto();
	--if (logicalHeightLength.isPercent() && !document()->inQuirksMode()) {
    if (logicalHeightLength:IsPercent()) then
        hasAutoHeight = true;
		local cb = self:ContainingBlock();
		while(not cb:IsLayoutView()) do
			if (cb:Style():LogicalHeight():IsFixed() or cb:IsTableCell()) then
                hasAutoHeight = false;
			end
			cb = cb:ContainingBlock();
		end
    end

    -- If the height is 0 or auto, then whether or not we are a self-collapsing block depends
    -- on whether we have content that is all self-collapsing or not.
    if (hasAutoHeight or ((logicalHeightLength:IsFixed() or logicalHeightLength:IsPercent()) and logicalHeightLength:IsZero())) then
        -- If the block has inline children, see if we generated any line boxes.  If we have any
        -- line boxes, then we can't be self-collapsing, since we have content.
        if (self:ChildrenInline()) then
            return not self:FirstLineBox();
		end
        
        -- Whether or not we collapse is dependent on whether all our normal flow children
        -- are also self-collapsing.
		local child = self:FirstChildBox();
		while(child) do
			if (not child:IsFloatingOrPositioned()) then
				if (not child:IsSelfCollapsingBlock()) then
					return false;
				end
			end
			child = child:NextSiblingBox();
		end
        return true;
    end
    return false;
end

--void RenderBlock::setMaxMarginBeforeValues(LayoutUnit pos, LayoutUnit neg)
function LayoutBlock:SetMaxMarginBeforeValues(pos, neg)
	if (not self.m_rareData) then
        if (pos == RenderBlockRareData.PositiveMarginBeforeDefault(self) and neg == RenderBlockRareData.NegativeMarginBeforeDefault(self)) then
            return;
		end
        self.m_rareData = RenderBlockRareData:new():init(self);
    end
    self.m_rareData.m_margins:SetPositiveMarginBefore(pos);
    self.m_rareData.m_margins:SetNegativeMarginBefore(neg);
end

function LayoutBlock:SetMaxMarginAfterValues(pos, neg)
    if (not self.m_rareData) then
        if (pos == RenderBlockRareData.PositiveMarginAfterDefault(self) and neg == RenderBlockRareData.NegativeMarginAfterDefault(self)) then
            return;
		end
        self.m_rareData = RenderBlockRareData:new():init(self);
    end
    self.m_rareData.m_margins:SetPositiveMarginAfter(pos);
    self.m_rareData.m_margins:SetNegativeMarginAfter(neg);
end

function LayoutBlock:CollapseMargins(child, marginInfo)
	-- Get the four margin values for the child and cache them.
    local childMargins = self:MarginValuesForChild(child);

    -- Get our max pos and neg top margins.
    local posTop = childMargins:PositiveMarginBefore();
    local negTop = childMargins:NegativeMarginBefore();

    -- For self-collapsing blocks, collapse our bottom margins into our top to get new posTop and negTop values.
    if (child:IsSelfCollapsingBlock()) then
        posTop = math.max(posTop, childMargins:PositiveMarginAfter());
        negTop = math.max(negTop, childMargins:NegativeMarginAfter());
    end
    
    -- See if the top margin is quirky. We only care if this child has
    -- margins that will collapse with us.
    local topQuirk = child:IsMarginBeforeQuirk() or self:Style():MarginBeforeCollapse() == MarginCollapseEnum.MDISCARD;

	if (marginInfo:CanCollapseWithMarginBefore()) then
        -- This child is collapsing with the top of the block.  If it has larger margin values, then we need to update
        -- our own maximal values.
        if (not marginInfo:QuirkContainer() or not topQuirk) then
            self:SetMaxMarginBeforeValues(math.max(posTop, self:MaxPositiveMarginBefore()), math.max(negTop, self:MaxNegativeMarginBefore()));
		end

        -- The minute any of the margins involved isn't a quirk, don't
        -- collapse it away, even if the margin is smaller (www.webreference.com
        -- has an example of this, a <dt> with 0.8em author-specified inside
        -- a <dl> inside a <td>.
        if (not marginInfo:DeterminedMarginBeforeQuirk() and not topQuirk and (posTop - negTop) ~= 0 ) then
            self:SetMarginBeforeQuirk(false);
            marginInfo:SetDeterminedMarginBeforeQuirk(true);
        end

        if (not marginInfo:DeterminedMarginBeforeQuirk() and topQuirk and not self:MarginBefore()) then
            -- We have no top margin and our top child has a quirky margin.
            -- We will pick up this quirky margin and pass it through.
            -- This deals with the <td><div><p> case.
            -- Don't do this for a block that split two inlines though.  You do
            -- still apply margins in this case.
            self:SetMarginBeforeQuirk(true);
		end
    end

	if (marginInfo:QuirkContainer() and marginInfo:AtBeforeSideOfBlock() and (posTop - negTop) ~= 0) then
        marginInfo:SetMarginBeforeQuirk(topQuirk);
	end

    local beforeCollapseLogicalTop = self:LogicalHeight();
    local logicalTop = beforeCollapseLogicalTop;

	if (child:IsSelfCollapsingBlock()) then
        -- This child has no height.  We need to compute our
        -- position before we collapse the child's margins together,
        -- so that we can get an accurate position for the zero-height block.
        local collapsedBeforePos = math.max(marginInfo:PositiveMargin(), childMargins:PositiveMarginBefore());
        local collapsedBeforeNeg = math.max(marginInfo:NegativeMargin(), childMargins:NegativeMarginBefore());
        marginInfo:SetMargin(collapsedBeforePos, collapsedBeforeNeg);
        
        -- Now collapse the child's margins together, which means examining our
        -- bottom margin values as well. 
        marginInfo:SetPositiveMarginIfLarger(childMargins:PositiveMarginAfter());
        marginInfo:SetNegativeMarginIfLarger(childMargins:NegativeMarginAfter());

        if (not marginInfo:CanCollapseWithMarginBefore()) then
            -- We need to make sure that the position of the self-collapsing block
            -- is correct, since it could have overflowing content
            -- that needs to be positioned correctly (e.g., a block that
            -- had a specified height of 0 but that actually had subcontent).
            logicalTop = self:LogicalHeight() + collapsedBeforePos - collapsedBeforeNeg;
		end
    else
        if (child:Style():MarginBeforeCollapse() == MarginCollapseEnum.MSEPARATE) then
            self:SetLogicalHeight(self:LogicalHeight() + marginInfo:Margin() + self:MarginBeforeForChild(child));
            logicalTop = self:LogicalHeight();
        elseif (not marginInfo:AtBeforeSideOfBlock() or
            (not marginInfo:CanCollapseMarginBeforeWithChildren()
             and (not marginInfo:QuirkContainer() or not marginInfo:MarginBeforeQuirk()))) then
            -- We're collapsing with a previous sibling's margins and not
            -- with the top of the block.
            self:SetLogicalHeight(self:LogicalHeight() + math.max(marginInfo:PositiveMargin(), posTop) - math.max(marginInfo:NegativeMargin(), negTop));
            logicalTop = self:LogicalHeight();
        end

        marginInfo:SetPositiveMargin(childMargins:PositiveMarginAfter());
        marginInfo:SetNegativeMargin(childMargins:NegativeMarginAfter());

        if (marginInfo:Margin()) then
            marginInfo:SetMarginAfterQuirk(child:IsMarginAfterQuirk() or self:Style():MarginAfterCollapse() == MarginCollapseEnum.MDISCARD);
		end
    end

	-- If margins would pull us past the top of the next page, then we need to pull back and pretend like the margins
    -- collapsed into the page edge.
--    LayoutState* layoutState = view()->layoutState();
--    if (layoutState->isPaginated() && layoutState->pageLogicalHeight() && logicalTop > beforeCollapseLogicalTop
--        && hasNextPage(beforeCollapseLogicalTop)) {
--        LayoutUnit oldLogicalTop = logicalTop;
--        logicalTop = min(logicalTop, nextPageLogicalTop(beforeCollapseLogicalTop));
--        setLogicalHeight(logicalHeight() + (logicalTop - oldLogicalTop));
--    }
    return logicalTop;
end

function LayoutBlock:DetermineLogicalLeftPositionForChild(child)
    local startPosition = self:BorderStart() + self:PaddingStart();
    local totalAvailableLogicalWidth = self:BorderAndPaddingLogicalWidth() + self:AvailableLogicalWidth();

    -- Add in our start margin.
    local childMarginStart = self:MarginStartForChild(child);
    local newPosition = startPosition + childMarginStart;
        
    -- Some objects (e.g., tables, horizontal rules, overflow:auto blocks) avoid floats.  They need
    -- to shift over as necessary to dodge any floats that might get in the way.
--    if (child:AvoidsFloats() and self:ContainsFloats() and not self:InRenderFlowThread()) then
--        newPosition += computeStartPositionDeltaForChildAvoidingFloats(child, marginStartForChild(child), logicalWidthForChild(child));
--	end
    self:SetLogicalLeftForChild(child, if_else(self:Style():IsLeftToRightDirection(), newPosition, totalAvailableLogicalWidth - newPosition - self:LogicalWidthForChild(child), "ApplyLayoutDelta"));
end

--void RenderBlock::handleAfterSideOfBlock(LayoutUnit beforeSide, LayoutUnit afterSide, MarginInfo& marginInfo)
function LayoutBlock:HandleAfterSideOfBlock(beforeSide, afterSide, marginInfo)
	marginInfo:SetAtAfterSideOfBlock(true);

    -- If we can't collapse with children then go ahead and add in the bottom margin.
    if (not marginInfo:CanCollapseWithMarginAfter() and not marginInfo:CanCollapseWithMarginBefore()
        and (not marginInfo:QuirkContainer() or not marginInfo:MarginAfterQuirk())) then
        self:SetLogicalHeight(self:LogicalHeight() + marginInfo:Margin());
	end
        
    -- Now add in our bottom border/padding.
    self:SetLogicalHeight(self:LogicalHeight() + afterSide);

    -- Negative margins can cause our height to shrink below our minimal height (border/padding).
    -- If this happens, ensure that the computed height is increased to the minimal height.
    self:SetLogicalHeight(math.max(self:LogicalHeight(), beforeSide + afterSide));

    -- Update our bottom collapsed margin info.
    self:SetCollapsedBottomMargin(marginInfo);

end

--void RenderBlock::setCollapsedBottomMargin(const MarginInfo& marginInfo)
function LayoutBlock:SetCollapsedBottomMargin(marginInfo)
    if (marginInfo:CanCollapseWithMarginAfter() and not marginInfo:CanCollapseWithMarginBefore()) then
        -- Update our max pos/neg bottom margins, since we collapsed our bottom margins
        -- with our children.
        self:SetMaxMarginAfterValues(math.max(self:MaxPositiveMarginAfter(), marginInfo:PositiveMargin()), math.max(self:MaxNegativeMarginAfter(), marginInfo:NegativeMargin()));

        if (not marginInfo:MarginAfterQuirk()) then
            self:SetMarginAfterQuirk(false);
		end

        if (marginInfo:MarginAfterQuirk() and self:MarginAfter() == 0) then
            -- We have no bottom margin and our last child has a quirky margin.
            -- We will pick up this quirky margin and pass it through.
            -- This deals with the <td><div><p> case.
            self:SetMarginAfterQuirk(true);
		end
    end
end

function LayoutBlock:ComputeOverflow(oldClientAfterEdge, recomputeFloats)
	--TODO: fixed this function
end

function LayoutBlock:UpdateScrollInfoAfterLayout()
	--TODO: fixed this function
end

function LayoutBlock:SimplifiedLayout()
	if ((not self:PosChildNeedsLayout() and not self:NeedsSimplifiedNormalFlowLayout()) or self:NormalChildNeedsLayout() or self:SelfNeedsLayout()) then
        return false;
	end
	if (self:NeedsPositionedMovementLayout() and not self:TryLayoutDoingPositionedMovementOnly()) then
        return false;
	end

	if(self:PosChildNeedsLayout() and self:LayoutPositionedObjects(false)) then
		return false;
	end

	--self.overflow:Clear();
	self:ComputeOverflow(self:ClientLogicalBottom(), true);

	self:UpdateLayerTransform();

	self:UpdateScrollInfoAfterLayout();

	self:SetNeedsLayout(false);

	return true;
end

--function LayoutBlock:AddChildBeforeDescendant(new_child, before_descendant)
--	if(before_descendant:Parent() ~= self) then
--		return;
--	end
--	--DCHECK_NE(before_descendant->Parent(), this);
--	local before_descendant_container = before_descendant:Parent();
--	while (before_descendant_container:Parent() ~= self) do
--		before_descendant_container = before_descendant_container:Parent();
--	end
--
--	--DCHECK(before_descendant_container);
--
--	-- We really can't go on if what we have found isn't anonymous. We're not
--	-- supposed to use some random non-anonymous object and put the child there.
--	-- That's a recipe for security issues.
--	if(before_descendant_container:IsAnonymous()) then
--		return;
--	end
--	--CHECK(before_descendant_container->IsAnonymous());
--
--	-- If the requested insertion point is not one of our children, then this is
--	-- because there is an anonymous container within this object that contains
--	-- the beforeDescendant.
--	if (before_descendant_container:IsAnonymousBlock() or before_descendant_container:IsLayoutFullScreen() or before_descendant_container:IsLayoutFullScreenPlaceholder()) then
--		-- Full screen layoutObjects and full screen placeholders act as anonymous
--		-- blocks, not tables:
--		-- Insert the child into the anonymous block box instead of here.
--	if (new_child:IsInline() or (new_child:IsFloatingOrOutOfFlowPositioned() and not self:IsFlexibleBox() and not self:IsLayoutGrid()) or before_descendant:Parent():SlowFirstChild() ~= before_descendant) then
--			before_descendant_container:AddChild(new_child, before_descendant);
--		else
--			self:AddChild(new_child, before_descendant:Parent());
--		end
--		return;
--	end
--
--	--DCHECK(before_descendant_container->IsTable());
--	if(before_descendant_container:IsTable()) then
--		return;
--	end
--	if (new_child:IsTablePart()) then
--		-- Insert into the anonymous table.
--		before_descendant_container:AddChild(new_child, before_descendant);
--		return;
--	end
--
--	LayoutObject* before_child =
--		SplitAnonymousBoxesAroundChild(before_descendant);
--
--	DCHECK_EQ(before_child->Parent(), this);
--	if (before_child->Parent() != this) {
--	// We should never reach here. If we do, we need to use the
--	// safe fallback to use the topmost beforeChild container.
--	before_child = before_descendant_container;
--	}
--
--	AddChild(new_child, before_child);
--end
--
--function LayoutBlock:AddChild(new_child, before_child)
--	if (before_child and before_child:Parent() ~= self) then
--		self:AddChildBeforeDescendant(new_child, before_child);
--		return;
--	end
--
--  -- Only LayoutBlockFlow should have inline children, and then we shouldn't be
--  -- here.
--	if(not self:ChildrenInline()) then
--	return;
--	end
--	--DCHECK(!ChildrenInline());
--
--	if (new_child:IsInline() or (new_child:IsFloatingOrOutOfFlowPositioned() and not self:IsFlexibleBox() and not self:IsLayoutGrid())) then
--		-- If we're inserting an inline child but all of our children are blocks,
--		-- then we have to make sure it is put into an anomyous block box. We try to
--		-- use an existing anonymous box if possible, otherwise a new one is created
--		-- and inserted into our list of children in the appropriate position.
--		local after_child = if_else(before_child, before_child:PreviousSibling(), self:LastChild());
--
--		if (after_child and after_child:IsAnonymousBlock()) then
--			after_child:AddChild(new_child);
--			return;
--		end
--
--		if (new_child:IsInline()) then
--			-- No suitable existing anonymous box - create a new one.
--			local new_box = CreateAnonymousBlock();
--			LayoutBlock._super.AddChild(self, new_box, before_child);
--			new_box:AddChild(new_child);
--			return;
--		end
--	end
--
--	LayoutBlock._super.AddChild(new_child, before_child);
--end

-- virtual function
function LayoutBlock:DirtyLinesFromChangedChild(child)
	self.lineBoxes:DirtyLinesFromChangedChild(self, child);
end

function LayoutBlock:AddChild(newChild, beforeChild)
	if (self:Continuation() and not self:IsAnonymousBlock()) then
        return self:AddChildToContinuation(newChild, beforeChild);
	end
    return self:AddChildIgnoringContinuation(newChild, beforeChild);
end

function LayoutBlock:AddChildToContinuation(newChild, beforeChild)

end

function LayoutBlock:AddChildIgnoringContinuation(newChild, beforeChild)
	if (not self:IsAnonymousBlock() and self:FirstChild() and (self:FirstChild():IsAnonymousColumnsBlock() and self:FirstChild():IsAnonymousColumnSpanBlock())) then
        return self:AddChildToAnonymousColumnBlocks(newChild, beforeChild);
	end
    return self:AddChildIgnoringAnonymousColumnBlocks(newChild, beforeChild);
end

function LayoutBlock:AddChildToAnonymousColumnBlocks(newChild, beforeChild)
	--TODO: fixed this function
end

function LayoutBlock:VirtualChildren()
	return self:Children();
end

function LayoutBlock:ColumnsBlockForSpanningElement(newChild)
	local columnsBlockAncestor = nil;
--    if (not newChild:IsText() and newChild->style()->columnSpan() && !newChild->isFloatingOrPositioned()
--        && !newChild->isInline() && !isAnonymousColumnSpanBlock()) {
--        if (style()->specifiesColumns())
--            columnsBlockAncestor = this;
--        else if (!isInline() && parent() && parent()->isRenderBlock()) {
--            columnsBlockAncestor = toRenderBlock(parent())->containingColumnsBlock(false);
--            
--            if (columnsBlockAncestor) {
--                // Make sure that none of the parent ancestors have a continuation.
--                // If yes, we do not want split the block into continuations.
--                RenderObject* curr = this;
--                while (curr && curr != columnsBlockAncestor) {
--                    if (curr->isRenderBlock() && toRenderBlock(curr)->continuation()) {
--                        columnsBlockAncestor = 0;
--                        break;
--                    }
--                    curr = curr->parent();
--                }
--            }
--        }
--    }
    return columnsBlockAncestor;
end

--static void getInlineRun(RenderObject* start, RenderObject* boundary,
--                         RenderObject*& inlineRunStart,
--                         RenderObject*& inlineRunEnd)
local function getInlineRun(start, boundary, inlineRunStart, inlineRunEnd)
    -- Beginning at |start| we find the largest contiguous run of inlines that
    -- we can.  We denote the run with start and end points, |inlineRunStart|
    -- and |inlineRunEnd|.  Note that these two values may be the same if
    -- we encounter only one inline.
    --
    -- We skip any non-inlines we encounter as long as we haven't found any
    -- inlines yet.
    --
    -- |boundary| indicates a non-inclusive boundary point.  Regardless of whether |boundary|
    -- is inline or not, we will not include it in a run with inlines before it.  It's as though we encountered
    -- a non-inline.
    
    -- Start by skipping as many non-inlines as we can.
    local curr = start;
    local sawInline;
    repeat
        while (curr and not (curr:IsInline() or curr:IsFloatingOrPositioned())) do
            curr = curr:NextSibling();
		end
        inlineRunStart = curr;
		inlineRunEnd = curr;
        
        if (not curr) then
            return inlineRunStart, inlineRunEnd; -- No more inline children to be found.
		end
        
        sawInline = curr:IsInline();
        
        curr = curr:NextSibling();
        while (curr and (curr:IsInline() or curr:IsFloatingOrPositioned()) and (curr ~= boundary)) do
            inlineRunEnd = curr;
            if (curr:IsInline()) then
                sawInline = true;
			end
            curr = curr:NextSibling();
        end
    until (sawInline);
	return inlineRunStart, inlineRunEnd;
end

--void moveAllChildrenTo(RenderBlock* to, RenderObject* beforeChild, bool fullRemoveInsert = false)
function LayoutBlock:MoveAllChildrenTo(to, beforeChild, fullRemoveInsert)
	if(fullRemoveInsert == nil) then
		return self:MoveAllChildrenTo(to, nil, beforeChild);
	end
    return self:MoveChildrenTo(to, self:FirstChild(), nil, beforeChild, fullRemoveInsert);
end

--void RenderBlock::moveChildrenTo(RenderBlock* to, RenderObject* startChild, RenderObject* endChild, RenderObject* beforeChild, bool fullRemoveInsert)
function LayoutBlock:MoveChildrenTo(to, startChild, endChild, beforeChild, fullRemoveInsert)
	
	if(fullRemoveInsert == nil) then
		return self:MoveChildrenTo(to, startChild, endChild, nil, beforeChild);
	end
    --ASSERT(!beforeChild || to == beforeChild->parent());
    local nextChild = startChild;
    while (nextChild and nextChild ~= endChild) do
        local child = nextChild;
        nextChild = child:NextSibling();
		local remove_child = self:Children():RemoveChildNode(self, child, fullRemoveInsert);
        to:Children():InsertChildNode(to, remove_child, beforeChild, fullRemoveInsert);
        if (child == endChild) then
            return;
		end
    end
end

--void RenderBlock::moveChildTo(RenderBlock* to, RenderObject* child, RenderObject* beforeChild, bool fullRemoveInsert)
function LayoutBlock:MoveChildTo(to, child, beforeChild, fullRemoveInsert)
	if(fullRemoveInsert == nil) then
		return self:MoveChildTo(to, child, nil, beforeChild);
	end
--    ASSERT(this == child->parent());
--    ASSERT(!beforeChild || to == beforeChild->parent());
    to:Children():InsertChildNode(to, self:Children():RemoveChildNode(self, child, fullRemoveInsert), beforeChild, fullRemoveInsert);
end

function LayoutBlock:MakeChildrenNonInline(insertionPoint)
	-- makeChildrenNonInline takes a block whose children are *all* inline and it
    -- makes sure that inline children are coalesced under anonymous
    -- blocks.  If |insertionPoint| is defined, then it represents the insertion point for
    -- the new block child that is causing us to have to wrap all the inlines.  This
    -- means that we cannot coalesce inlines before |insertionPoint| with inlines following
    -- |insertionPoint|, because the new child is going to be inserted in between the inlines,
    -- splitting them.
--    if(self:IsInlineBlockOrInlineTable() or not self:IsInline()) then
--		return;
--	end
--  if(not insertionPoint or insertionPoint:Parent() == self) then
--		return;
--	end
    self:SetChildrenInline(false);

    local child = self:FirstChild();
    if (not child) then
        return;
	end
    
	self:DeleteLineBoxTree();

    while (child) do
        local inlineRunStart, inlineRunEnd = getInlineRun(child, insertionPoint);

        if (not inlineRunStart) then
            break;
		end

        child = inlineRunEnd:NextSibling();

        local block = self:CreateAnonymousBlock();
        self:Children():InsertChildNode(self, block, inlineRunStart);
        self:MoveChildrenTo(block, inlineRunStart, child, false);
    end

--#ifndef NDEBUG
--    for (RenderObject *c = firstChild(); c; c = c->nextSibling())
--        ASSERT(!c->isInline());
--#endif

    self:Repaint();
end


function LayoutBlock:AddChildIgnoringAnonymousColumnBlocks(newChild, beforeChild)
	-- Make sure we don't append things after :after-generated content if we have it.
    if (not beforeChild) then
        beforeChild = self:FindAfterContentRenderer();
	end

    -- If the requested beforeChild is not one of our children, then this is because
    -- there is an anonymous container within this object that contains the beforeChild.
    if (beforeChild and beforeChild:Parent() ~= self) then
--        RenderObject* beforeChildAnonymousContainer = anonymousContainer(beforeChild);
--        ASSERT(beforeChildAnonymousContainer);
--        ASSERT(beforeChildAnonymousContainer->isAnonymous());
--
--        if (beforeChildAnonymousContainer->isAnonymousBlock()) {
--            // Insert the child into the anonymous block box instead of here.
--            if (newChild->isInline() || beforeChild->parent()->firstChild() != beforeChild)
--                beforeChild->parent()->addChild(newChild, beforeChild);
--            else
--                addChild(newChild, beforeChild->parent());
--            return;
--        }
--
--        ASSERT(beforeChildAnonymousContainer->isTable());
--        if ((newChild->isTableCol() && newChild->style()->display() == TABLE_COLUMN_GROUP)
--                || (newChild->isRenderBlock() && newChild->style()->display() == TABLE_CAPTION)
--                || newChild->isTableSection()
--                || newChild->isTableRow()
--                || newChild->isTableCell()) {
--            // Insert into the anonymous table.
--            beforeChildAnonymousContainer->addChild(newChild, beforeChild);
--            return;
--        }
--
--        // Go on to insert before the anonymous table.
--        beforeChild = beforeChildAnonymousContainer;
    end

    -- Check for a spanning element in columns.
    local columnsBlockAncestor = self:ColumnsBlockForSpanningElement(newChild);
    if (columnsBlockAncestor) then
--        // We are placing a column-span element inside a block. 
--        RenderBlock* newBox = createAnonymousColumnSpanBlock();
--        
--        if (columnsBlockAncestor != this) {
--            // We are nested inside a multi-column element and are being split by the span.  We have to break up
--            // our block into continuations.
--            RenderBoxModelObject* oldContinuation = continuation();
--            setContinuation(newBox);
--
--            // Someone may have put a <p> inside a <q>, causing a split.  When this happens, the :after content
--            // has to move into the inline continuation.  Call updateBeforeAfterContent to ensure that our :after
--            // content gets properly destroyed.
--            bool isLastChild = (beforeChild == lastChild());
--            if (document()->usesBeforeAfterRules())
--                children()->updateBeforeAfterContent(this, AFTER);
--            if (isLastChild && beforeChild != lastChild())
--                beforeChild = 0; // We destroyed the last child, so now we need to update our insertion
--                                 // point to be 0.  It's just a straight append now.
--
--            splitFlow(beforeChild, newBox, newChild, oldContinuation);
--            return;
--        }
--
--        // We have to perform a split of this block's children.  This involves creating an anonymous block box to hold
--        // the column-spanning |newChild|.  We take all of the children from before |newChild| and put them into
--        // one anonymous columns block, and all of the children after |newChild| go into another anonymous block.
--        makeChildrenAnonymousColumnBlocks(beforeChild, newBox, newChild);
--        return;
    end

    local madeBoxesNonInline = false;

    -- A block has to either have all of its children inline, or all of its children as blocks.
    -- So, if our children are currently inline and a block child has to be inserted, we move all our
    -- inline children into anonymous block boxes.
    if (self:ChildrenInline() and not newChild:IsInline() and not newChild:IsFloatingOrPositioned()) then
        -- This is a block with inline content. Wrap the inline content in anonymous blocks.
        self:MakeChildrenNonInline(beforeChild);
        madeBoxesNonInline = true;

        if (beforeChild and beforeChild:Parent() ~= self) then
            beforeChild = beforeChild:Parent();
            if(beforeChild:IsAnonymousBlock()) then
				return;
			end
            if(beforeChild:Parent() == self) then
				return;
			end
        end
    elseif(not self:ChildrenInline() and (newChild:IsFloatingOrPositioned() or newChild:IsInline())) then
        -- If we're inserting an inline child but all of our children are blocks, then we have to make sure
        -- it is put into an anomyous block box. We try to use an existing anonymous box if possible, otherwise
        -- a new one is created and inserted into our list of children in the appropriate position.
        local afterChild;
		if(beforeChild) then
			afterChild = beforeChild:PreviousSibling();
		else
			afterChild = self:LastChild()
		end

        if (afterChild and afterChild:IsAnonymousBlock()) then
            afterChild:AddChild(newChild);
            return;
        end

        if (newChild:IsInline()) then
            -- No suitable existing anonymous box - create a new one.
            local newBox = self:CreateAnonymousBlock();
            --RenderBox::addChild(newBox, beforeChild);
			LayoutBlock._super.AddChild(self, newBox, beforeChild);
            newBox:AddChild(newChild);
            return;
        end
    end

    LayoutBlock._super.AddChild(self, newChild, beforeChild);

    if (madeBoxesNonInline and self:Parent() and self:IsAnonymousBlock() and self:Parent():IsLayoutBlock()) then
       self:Parent():RemoveLeftoverAnonymousBlock(self);
	end
    -- this object may be dead here
end

function LayoutBlock:RemoveLeftoverAnonymousBlock(child)
	--TODO: fixed this function
end

function LayoutBlock:FirstRootBox()
	return self:FirstLineBox();
end

function LayoutBlock:LastRootBox()
	return self:LastLineBox();
end

function LayoutBlock:FirstLineBox()
	return self.lineBoxes:FirstLineBox();
end

function LayoutBlock:LastLineBox()
	return self.lineBoxes:LastLineBox();
end

function LayoutBlock:LineBoxes()
	return self.lineBoxes;
end

function LayoutBlock:VirtualContinuation()
	return self:Continuation();
end

function LayoutBlock:WillBeDestroyed()
    -- Mark as being destroyed to avoid trouble with merges in removeChild().
    self.beingDestroyed = true;

    -- Make sure to destroy anonymous children first while they are still connected to the rest of the tree, so that they will
    -- properly dirty line boxes that they are removed from. Effects that do :before/:after only on hover could crash otherwise.
    self:Children():DestroyLeftoverChildren();

    -- Destroy our continuation before anything other than anonymous children.
    -- The reason we don't destroy it before anonymous children is that they may
    -- have continuations of their own that are anonymous children of our continuation.
--    RenderBoxModelObject* continuation = this->continuation();
--    if (continuation) {
--        continuation->destroy();
--        setContinuation(0);
--    }
    
    if (not self:DocumentBeingDestroyed()) then
        if (self:FirstLineBox()) then
            -- We can't wait for RenderBox::destroy to clear the selection,
            -- because by then we will have nuked the line boxes.
            -- FIXME: The FrameSelection should be responsible for this when it
            -- is notified of DOM mutations.
--            if (isSelectionBorder())
--                view()->clearSelection();

            -- If we are an anonymous block, then our line boxes might have children
            -- that will outlast this block. In the non-anonymous block case those
            -- children will be destroyed by the time we return from this function.
            if (self:IsAnonymousBlock()) then
				local box = self:FirstLineBox();
				while(box) do
					local childBox = box:FirstChild();
					while (childBox) do
                        childBox:Remove();
						childBox = box:FirstChild();
					end

					box = box:NextLineBox();
				end

            end
        elseif (self:Parent()) then
            self:Parent():DirtyLinesFromChangedChild(self);
		end
    end

    self.lineBoxes:DeleteLineBoxes(self:RenderArena());

--    if (UNLIKELY(gDelayedUpdateScrollInfoSet != 0))
--        gDelayedUpdateScrollInfoSet->remove(this);

	if(self:IsAnonymous()) then
		self.anonymousControl:Destroy();
		self.anonymousControl = nil;
	end

    LayoutBlock._super.WillBeDestroyed(self);
end

function LayoutBlock:StyleDidChange(diff, oldStyle)
	LayoutBlock._super.StyleDidChange(self, diff, oldStyle);

	self:PropagateStyleToAnonymousChildren();

	self.lineHeight = -1;
end

function LayoutBlock:StyleWillChange(diff, newStyle)
	if(self:Style()) then
		s_canPropagateFloatIntoSibling = not self:IsFloatingOrPositioned() and not self:AvoidsFloats();
	else
		s_canPropagateFloatIntoSibling = false;
	end

	self:SetReplaced(newStyle:IsDisplayInlineType());

	if (self:Style() and self:Parent() and diff == StyleDifferenceEnum.StyleDifferenceLayout and self:Style():Position() ~= newStyle:Position()) then
        if (newStyle:Position() == PositionEnum.StaticPosition) then
            -- Clear our positioned objects list. Our absolutely positioned descendants will be
            -- inserted into our containing block's positioned objects list during layout.
            self:RemovePositionedObjects();
        elseif (self:Style():Position() == PositionEnum.StaticPosition) then
            -- Remove our absolutely positioned descendants from their current containing block.
            -- They will be inserted into our positioned objects list during layout.
            local cb = self:Parent();
            while (cb and (cb:Style():Position() == PositionEnum.StaticPosition or (cb:IsInline() and not cb:IsReplaced())) and not cb:IsLayoutView()) do
                if (cb:Style():Position() == PositionEnum.RelativePosition and cb:IsInline() and not cb:IsReplaced()) then
                    cb = cb:ContainingBlock();
                    break;
                end
                cb = cb:Parent();
            end
            
            if (cb:IsLayoutBlock()) then
                cb:ToRenderBlock():RemovePositionedObjects(self);
			end
        end

        if (self:ContainsFloats() and not self:IsFloating() and not self:IsPositioned() and (newStyle:Position() == PositionEnum.AbsolutePosition or newStyle:Position() == PositionEnum.FixedPosition)) then
            self:MarkAllDescendantsWithFloatsForLayout();
		end
    end

	LayoutBlock._super.StyleWillChange(self, diff, newStyle);
end

function LayoutBlock:OffsetFromLogicalTopOfFirstPage()
	--return 0;
	-- FIXME: This function needs to work without layout state. It's fine to use the layout state as a cache
    -- for speed, but we need a slow implementation that will walk up the containing block chain and figure
    -- out our offset from the top of the page.
    local layoutState = self:View():LayoutState();
    if (layoutState == nil or not layoutState:IsPaginated()) then
        return 0;
	end

    -- FIXME: Sanity check that the renderer in the layout state is ours, since otherwise the computation will be off.
    -- Right now this assert gets hit inside computeLogicalHeight for percentage margins, since they're computed using
    -- widths which can vary in each region. Until we patch that, we can't have this assert.
    -- ASSERT(layoutState->m_renderer == this);

    local offsetDelta = layoutState.layoutOffset - layoutState.pageOffset;
    return if_else(self:IsHorizontalWritingMode(), offsetDelta:Height(), offsetDelta:Width());
end

--RenderRegion* RenderBlock::regionAtBlockOffset(LayoutUnit blockOffset) const
function LayoutBlock:RegionAtBlockOffset(blockOffset)
	if (self:InRenderFlowThread()) then
        return nil;
	end
	--TODO: fixed this function later;
	return nil;
end

function LayoutBlock:LogicalLeftOffsetForContent(region, offsetFromLogicalTopOfFirstPage)
	if(region == nil and offsetFromLogicalTopOfFirstPage == nil) then
		local offset = self:BorderLeft() + self:PaddingLeft();
		if(not self:IsHorizontalWritingMode()) then
			offset = self:BorderTop() + self:PaddingTop();
		end
		return offset;
	end

	if(offsetFromLogicalTopOfFirstPage == nil) then
		local blockOffset = region;
		region = self:RegionAtBlockOffset(blockOffset);
		offsetFromLogicalTopOfFirstPage = self:OffsetFromLogicalTopOfFirstPage();
	end

	local logicalLeftOffset;
	if(self:IsHorizontalWritingMode()) then
		logicalLeftOffset = self:BorderLeft() + self:PaddingLeft();
	else
		logicalLeftOffset = self:BorderTop() + self:PaddingTop();
	end

	if(not self:InRenderFlowThread()) then
		return logicalLeftOffset;
	end
	--TODO: fixed this later
--	LayoutRect boxRect = borderBoxRectInRegion(region, offsetFromLogicalTopOfFirstPage);
--  return logicalLeftOffset + (isHorizontalWritingMode() ? boxRect.x() : boxRect.y());
	return logicalLeftOffset;
end

function LayoutBlock:LogicalRightOffsetForContent(region, offsetFromLogicalTopOfFirstPage)
	if(region == nil and offsetFromLogicalTopOfFirstPage == nil) then
		return self:LogicalLeftOffsetForContent() + self:AvailableLogicalWidth();
	end
	if(offsetFromLogicalTopOfFirstPage == nil) then
		local blockOffset = region;
		region = self:RegionAtBlockOffset(blockOffset);
		offsetFromLogicalTopOfFirstPage = self:OffsetFromLogicalTopOfFirstPage();
	end

	local logicalRightOffset;
	if(self:Style():IsHorizontalWritingMode()) then
		logicalRightOffset = self:BorderLeft() + self:PaddingLeft()
	else
		logicalRightOffset = self:BorderTop() + self:PaddingTop()
	end
    logicalRightOffset = logicalRightOffset + self:AvailableLogicalWidth();
    if (not self:InRenderFlowThread()) then
        return logicalRightOffset;
	end
	--TODO: fixed this later
--    LayoutRect boxRect = borderBoxRectInRegion(region, offsetFromLogicalTopOfFirstPage);
--    return logicalRightOffset - (logicalWidth() - (isHorizontalWritingMode() ? boxRect.maxX() : boxRect.maxY()));
	return logicalRightOffset;
end

--LayoutUnit RenderBlock::logicalRightOffsetForLine(LayoutUnit logicalTop, LayoutUnit fixedOffset, bool applyTextIndent, LayoutUnit* heightRemaining) const
function LayoutBlock:LogicalRightOffsetForLine(logicalTop, fixedOffset, applyTextIndent, heightRemaining)
	if(applyTextIndent == nil and heightRemaining == nil) then
		return self:LogicalRightOffsetForLine(logicalTop, self:LogicalRightOffsetForContent(logicalTop), fixedOffset);
	elseif(type(fixedOffset) == "boolean") then
		return self:LogicalRightOffsetForLine(logicalTop, self:LogicalRightOffsetForContent(applyTextIndent, heightRemaining), fixedOffset);
	end
	local right = fixedOffset;
	--TODO: fixed this when process floating;
	if (self.floatingObjects and self.floatingObjects:HasRightObjects()) then
        if (heightRemaining ~= nil) then
            heightRemaining = 1;
		end

        local rightFloatOffset = fixedOffset;
        --FloatIntervalSearchAdapter<FloatingObject::FloatRight> adapter(this, logicalTop, rightFloatOffset, heightRemaining);
		adapter = FloatIntervalSearchAdapter:new():init(self, logicalTop, rightFloatOffset, heightRemaining, FloatType.FloatRight);
        self.floatingObjects:PlacedFloatsTree():allOverlapsWithAdapter(adapter);
		rightFloatOffset, heightRemaining = adapter.offset, adapter.heightRemaining;
        right = math.min(right, rightFloatOffset);
    end
    
    if (applyTextIndent and not self:Style():IsLeftToRightDirection()) then
        right = right - self:TextIndentOffset();
	end
    
    --return right, heightRemaining;
	return right;
end

function LayoutBlock:TextIndentOffset()
	local cw = 0;
    if (self:Style():TextIndent():IsPercent()) then
        cw = self:ContainingBlock():AvailableLogicalWidth();
	end
    return self:Style():TextIndent():CalcMinValue(cw);
end
--LayoutUnit RenderBlock::logicalLeftOffsetForLine(LayoutUnit logicalTop, LayoutUnit fixedOffset, bool applyTextIndent, LayoutUnit* heightRemaining) const
function LayoutBlock:LogicalLeftOffsetForLine(logicalTop, fixedOffset, applyTextIndent, heightRemaining)
	if(applyTextIndent == nil and heightRemaining == nil) then
		return self:LogicalLeftOffsetForLine(logicalTop, self:LogicalLeftOffsetForContent(logicalTop), fixedOffset);
	elseif(type(fixedOffset) == "boolean") then
		return self:LogicalLeftOffsetForLine(logicalTop, self:LogicalLeftOffsetForContent(applyTextIndent, heightRemaining), fixedOffset);
	end
	local left = fixedOffset;
    if (self.floatingObjects and self.floatingObjects:HasLeftObjects()) then
        if (heightRemaining) then
            heightRemaining = 1;
		end

        --FloatIntervalSearchAdapter<FloatingObject::FloatLeft> adapter(this, logicalTop, left, heightRemaining);
		local adapter = FloatIntervalSearchAdapter:new():init(self, logicalTop, left, heightRemaining, FloatType.FloatLeft)
        self.floatingObjects:PlacedFloatsTree():allOverlapsWithAdapter(adapter);
		left, heightRemaining = adapter.offset, adapter.heightRemaining;
    end

    if (applyTextIndent and self:Style():IsLeftToRightDirection()) then
        left = left + self:TextIndentOffset();
	end
    --return left, heightRemaining;
	return left;
end

function LayoutBlock:CreateRootInlineBox() 
    return RootInlineBox:new():init(self);
end

function LayoutBlock:CreateAndAppendRootInlineBox()
    local rootBox = self:CreateRootInlineBox();
    self.lineBoxes:AppendLineBox(rootBox);
    return rootBox;
end

function LayoutBlock:LineHeight(firstLine, direction, linePositionMode)
	linePositionMode = linePositionMode or "PositionOnContainingLine";
    -- Inline blocks are replaced elements. Otherwise, just pass off to
    -- the base class.  If we're being queried as though we're the root line
    -- box, then the fact that we're an inline-block is irrelevant, and we behave
    -- just like a block.
    if (self:IsReplaced() and linePositionMode == "PositionOnContainingLine") then
        return LayoutBlock._super.LineHeight(self, firstLine, direction, linePositionMode);
	end
    if (firstLine and self:Document():UsesFirstLineRules()) then
        local s = self:Style(firstLine);
        if (s ~= self:Style()) then
            return s:ComputedLineHeight();
		end
    end
    
    if (self.lineHeight == -1) then
        self.lineHeight = self:Style():ComputedLineHeight();
	end
    return self.lineHeight;
end

function LayoutBlock:LastLineBoxBaseline()
	if (not self:IsBlockFlow() or (self:IsWritingModeRoot() and not self:IsRubyRun())) then
        return -1;
	end

    local lineDirection = if_else(self:IsHorizontalWritingMode(), "HorizontalLine", "VerticalLine");

    if (self:ChildrenInline()) then
        if (not self:FirstLineBox() and self:HasLineIfEmpty()) then
            local fontMetrics = self:FirstLineStyle():FontMetrics();
            return fontMetrics:ascent()
                 + (self:LineHeight(true, lineDirection, PositionOfInteriorLineBoxes) - fontMetrics:height()) / 2
                 + if_else(lineDirection == "HorizontalLine", self:BorderTop() + self:PaddingTop(), self:BorderRight() + self:PaddingRight());
        end
        if (self:LastLineBox()) then
			return self:LastLineBox():LogicalTop() + self:Style(self:LastLineBox() == self:FirstLineBox()):FontMetrics():ascent(self:LastRootBox():BaselineType());
            --return self:LastLineBox():LogicalTop() + self:Style(self:LastLineBox() == self:FirstLineBox()):FontAscent(self:LastRootBox():BaselineType());
		end
        return -1;
    else
        local haveNormalFlowChild = false;
        --for (RenderBox* curr = lastChildBox(); curr; curr = curr->previousSiblingBox()) then
		local curr = self:LastChildBox();
		while(curr) do
            if (not curr:IsFloatingOrPositioned()) then
                haveNormalFlowChild = true;
                local result = curr:LastLineBoxBaseline();
                if (result ~= -1) then
                    return curr:LogicalTop() + result; -- Translate to our coordinate space.
				end
            end

			curr = curr:PreviousSiblingBox()
        end
        if (not haveNormalFlowChild and self:HasLineIfEmpty()) then
            local fontMetrics = self:FirstLineStyle():FontMetrics();
            return fontMetrics:ascent()
                 + (self:LineHeight(true, lineDirection, PositionOfInteriorLineBoxes) - fontMetrics:height()) / 2
                 + if_else(lineDirection == "HorizontalLine", self:BorderTop() + self:PaddingTop(), self:BorderRight() + self:PaddingRight());
        end
    end

    return -1;
end

function LayoutBlock:BaselinePosition(baselineType, firstLine, direction, linePositionMode)
	linePositionMode = linePositionMode or "PositionOnContainingLine";
    -- Inline blocks are replaced elements. Otherwise, just pass off to
    -- the base class.  If we're being queried as though we're the root line
    -- box, then the fact that we're an inline-block is irrelevant, and we behave
    -- just like a block.
    if (self:IsReplaced() and linePositionMode == "PositionOnContainingLine") then
--        -- For "leaf" theme objects, let the theme decide what the baseline position is.
--        -- FIXME: Might be better to have a custom CSS property instead, so that if the theme
--        -- is turned off, checkboxes/radios will still have decent baselines.
--        -- FIXME: Need to patch form controls to deal with vertical lines.
        if (self:Style():HasAppearance() and not LayoutTheme:DefaultTheme():IsControlContainer(self:Style():Appearance())) then
            return LayoutTheme:DefaultTheme():BaselinePosition(self);
		end
            
        -- CSS2.1 states that the baseline of an inline block is the baseline of the last line box in
        -- the normal flow.  We make an exception for marquees, since their baselines are meaningless
        -- (the content inside them moves).  This matches WinIE as well, which just bottom-aligns them.
        -- We also give up on finding a baseline if we have a vertical scrollbar, or if we are scrolled
        -- vertically (e.g., an overflow:hidden block that has had scrollTop moved) or if the baseline is outside
        -- of our content box.
        local ignoreBaseline = (self:Layer() and (self:Layer():Marquee()
			or if_else(direction == "HorizontalLine", 
				(self:Layer():VerticalScrollbar() or self:Layer():ScrollYOffset() ~= 0), 
				(self:Layer():HorizontalScrollbar() or self:Layer():ScrollXOffset() ~= 0))))
			or (self:IsWritingModeRoot() and not self:IsRubyRun());
        
        local baselinePos = if_else(ignoreBaseline, -1, self:LastLineBoxBaseline());
        
        local bottomOfContent = if_else(direction == "HorizontalLine", self:BorderTop() + self:PaddingTop() + self:ContentHeight(), self:BorderRight() + self:PaddingRight() + self:ContentWidth());
        if (baselinePos ~= -1 and baselinePos <= bottomOfContent) then
            return if_else(direction == "HorizontalLine", self:MarginTop() + baselinePos, self:MarginRight() + baselinePos);
		end
            
        return LayoutBlock._super.BaselinePosition(self, baselineType, firstLine, direction, linePositionMode);
    end

--    const FontMetrics& fontMetrics = style(firstLine)->fontMetrics();
--    return fontMetrics.ascent(baselineType) + (lineHeight(firstLine, direction, linePositionMode) - fontMetrics.height()) / 2;
	local fontMetrics = self:Style(firstLine):FontMetrics();
    return fontMetrics:ascent(baselineType) + math.floor((self:LineHeight(firstLine, direction, linePositionMode) - fontMetrics:height())/2+0.5);
--	local fontHeight = self:Style():FontSize();
--	local fontAscent = self:Style():FontAscent(baselineType);
--	return fontAscent + (self:LineHeight(firstLine, direction, linePositionMode) - fontHeight) / 2;
end

function LayoutBlock:AvailableLogicalWidthForContent(region, offsetFromLogicalTopOfFirstPage)
	if(offsetFromLogicalTopOfFirstPage ~= nil) then
		local blockOffset = region;
		offsetFromLogicalTopOfFirstPage = self:OffsetFromLogicalTopOfFirstPage();
		region = self:RegionAtBlockOffset(blockOffset);
	end

	local rightOffset = self:LogicalRightOffsetForContent(region, offsetFromLogicalTopOfFirstPage);
	local leftOffset = self:LogicalLeftOffsetForContent(region, offsetFromLogicalTopOfFirstPage);
	local width = rightOffset - leftOffset;

	return math.max(0, width);
end

function LayoutBlock:NewLine(clear)
    self:PositionNewFloats();
    -- set y position
    local newY = 0;
	if(clear == ClearEnum.CLEFT) then
		newY = self:LowestFloatLogicalBottom(FloatType.FloatLeft);
	elseif(clear == ClearEnum.CRIGHT) then
		newY = self:LowestFloatLogicalBottom(FloatType.FloatRight);
	elseif(clear == ClearEnum.CBOTH) then
		newY = self:LowestFloatLogicalBottom();
	end
    if (self:Height() < newY) then
        self:SetLogicalHeight(newY);
	end
end

--void RenderBlock::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutBlock:Paint(paintInfo, paintOffset)
    local adjustedPaintOffset = paintOffset + self:Location();
    -- default implementation. Just pass paint through to the children
--    PaintInfo childInfo(paintInfo);
--    childInfo.updatePaintingRootForChildren(this);
	self:PaintObject(paintInfo, adjustedPaintOffset)
end

--void RenderBlock::paintObject(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutBlock:PaintObject(paintInfo, paintOffset)
	-- 1. paint background, borders etc
	self:PaintBoxDecorations(paintInfo, paintOffset);
	-- 2. paint contents
	self:PaintContents(paintInfo, paintOffset);
	-- 4. paint floats.
	self:PaintFloats(paintInfo, paintOffset)
end

--void RenderBox::paintBoxDecorations(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutBlock:PaintBoxDecorations(paintInfo, paintOffset)
	local rect = self.frame_rect:clone_from_pool();
	if(self:HasSelfPaintingLayer()) then
		rect:Move(paintOffset:X(), paintOffset:Y());
	end
	self:PaintBackground(paintInfo, rect);

--	local control = self:GetControl();
--	if(control) then
--		local x, y, w, h = self:X(), self:Y(), self:Width(), self:Height();
--		echo({x, y, w, h});
--		if(self:HasSelfPaintingLayer()) then
--			x, y = x + paintOffset:X(), y + paintOffset:Y();
--		end
--		echo({x, y, w, h});
--		control:ApplyCss(self:Style());
--		control:setGeometry(x, y, w, h);
--	end
end

--void RenderBlock::paintContents(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutBlock:PaintContents(paintInfo, paintOffset)
    -- Avoid painting descendants of the root element when stylesheets haven't loaded.  This eliminates FOUC.
    -- It's ok not to draw, because later on, when all the stylesheets do load, updateStyleSelector on the Document
    -- will do a full repaint().
--    if (document()->didLayoutWithPendingStylesheets() && !isRenderView())
--        return;

--    if (childrenInline())
--        m_lineBoxes.paint(this, paintInfo, paintOffset);
--    else
--        paintChildren(paintInfo, paintOffset);
	if (self:ChildrenInline()) then
        self.lineBoxes:Paint(self, paintInfo, paintOffset);
    else
--        local control = self:GetControl();
--		if(control) then
--			control:ApplyCss(self:Style():GetStyle());
--			control:setGeometry(self:X(), self:Y(), self:Width(), self:Height());
--		end
		self:PaintChildren(paintInfo, paintOffset);
	end
end

--void RenderBlock::paintChildren(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutBlock:PaintChildren(paintInfo, paintOffset)
	local info = paintInfo;
	local child = self:FirstChild();
	while(child) do
--		if(not child:IsFloating()) then
--			child:Paint(info, paintOffset);
--		end

		local childPoint = self:FlipForWritingModeForChild(child, paintOffset);
        if (not child:HasSelfPaintingLayer() and not child:IsFloating()) then
            child:Paint(info, childPoint);
		end

		child = child:NextSibling();
	end
end

--LayoutUnit xPositionForFloatIncludingMargin(const FloatingObject* child) const
function LayoutBlock:XPositionForFloatIncludingMargin(child)
    if (self:IsHorizontalWritingMode()) then
        return child:X() + child:Renderer():MarginLeft();
    else
        return child:X() + self:MarginBeforeForChild(child:Renderer());
	end
end
        
--LayoutUnit yPositionForFloatIncludingMargin(const FloatingObject* child) const
function LayoutBlock:YPositionForFloatIncludingMargin(child)
    if (self:IsHorizontalWritingMode()) then
        return child:Y() + self:MarginBeforeForChild(child:Renderer());
    else
        return child:Y() + child:Renderer():MarginTop();
	end
end

--LayoutPoint RenderBlock::flipFloatForWritingModeForChild(const FloatingObject* child, const LayoutPoint& point) const
function LayoutBlock:FlipFloatForWritingModeForChild(child, point)
    if (not self:Style():IsFlippedBlocksWritingMode()) then
        return point;
	end
    
    -- This is similar to RenderBox::flipForWritingModeForChild. We have to subtract out our left/top offsets twice, since
    -- it's going to get added back in. We hide this complication here so that the calling code looks normal for the unflipped
    -- case.
    if (self:IsHorizontalWritingMode()) then
        return LayoutPoint:new(point:X(), point:Y() + self:Height() - child:Renderer():Height() - 2 * self:YPositionForFloatIncludingMargin(child));
	end
    return LayoutPoint:new(point:X() + self:Width() - child:Width() - 2 * self:XPositionForFloatIncludingMargin(child), point:Y());
end

--void RenderBlock::paintFloats(PaintInfo& paintInfo, const LayoutPoint& paintOffset, bool preservePhase)
function LayoutBlock:PaintFloats(paintInfo, paintOffset, preservePhase)
	preservePhase = if_else(preservePhase == nil, false, preservePhase);
	if(not self.floatingObjects) then
		return;
	end


	local floatingObjectSet = self.floatingObjects:Set();
	local it = floatingObjectSet:Begin();
	while(it) do
		local floatingObject = it();
		if(floatingObject.shouldPaint and (not floatingObject.renderer:HasSelfPaintingLayer())) then
			local point_x = paintOffset:X() + self:XPositionForFloatIncludingMargin(floatingObject) - floatingObject:Renderer():X();
			local point_y = paintOffset:Y() + self:YPositionForFloatIncludingMargin(floatingObject) - floatingObject:Renderer():Y();
			local childPoint = self:FlipFloatForWritingModeForChild(floatingObject, LayoutPoint:new(point_x, point_y));

			floatingObject.renderer:SetX(floatingObject:FrameRect():X());
			floatingObject.renderer:SetY(floatingObject:FrameRect():Y());
			floatingObject.renderer:Paint(paintInfo, childPoint);
		end
		it = floatingObjectSet:next(it);
	end
--    FloatingObjectSetIterator end = floatingObjectSet.end();
--    for (FloatingObjectSetIterator it = floatingObjectSet.begin(); it != end; ++it) {
--        FloatingObject* r = *it;
--        // Only paint the object if our m_shouldPaint flag is set.
--        if (r->m_shouldPaint && !r->m_renderer->hasSelfPaintingLayer()) {
--            PaintInfo currentPaintInfo(paintInfo);
--            currentPaintInfo.phase = preservePhase ? paintInfo.phase : PaintPhaseBlockBackground;
--            LayoutPoint childPoint = flipFloatForWritingModeForChild(r, LayoutPoint(paintOffset.x() + xPositionForFloatIncludingMargin(r) - r->m_renderer->x(), paintOffset.y() + yPositionForFloatIncludingMargin(r) - r->m_renderer->y()));
--            r->m_renderer->paint(currentPaintInfo, childPoint);
--            if (!preservePhase) {
--                currentPaintInfo.phase = PaintPhaseChildBlockBackgrounds;
--                r->m_renderer->paint(currentPaintInfo, childPoint);
--                currentPaintInfo.phase = PaintPhaseFloat;
--                r->m_renderer->paint(currentPaintInfo, childPoint);
--                currentPaintInfo.phase = PaintPhaseForeground;
--                r->m_renderer->paint(currentPaintInfo, childPoint);
--                currentPaintInfo.phase = PaintPhaseOutline;
--                r->m_renderer->paint(currentPaintInfo, childPoint);
--            }
--        }
--    }
end

--RenderInline* RenderBlock::inlineElementContinuation() const
function LayoutBlock:InlineElementContinuation()
    local continuation = self:Continuation();
    return if_else(continuation ~= nil and continuation:IsInline(), continuation, nil);
end

--RenderBlock* RenderBlock::createAnonymousBlock(bool isFlexibleBox) const
function LayoutBlock:CreateAnonymousBlock(isFlexibleBox)
	isFlexibleBox = if_else(isFlexibleBox == nil, false, isFlexibleBox);
	local newStyle = ComputedStyle.CreateAnonymousStyle(self:Style());

    local newBox = nil;
    if (isFlexibleBox) then
--        newStyle:SetDisplay(DisplayEnum.BOX);
--        newBox = new (renderArena()) RenderDeprecatedFlexibleBox(document() /* anonymous box */);
    else
        newStyle:SetDisplay(DisplayEnum.BLOCK);
        newBox = LayoutBlock:new():init();
    end
	newBox:SetIsAnonymous(true);
	newBox:SetAnonymousControl(self:CreateAnonymousControl());
    newBox:SetStyle(newStyle);
    return newBox;
end

function LayoutBlock:GetName()
	return "LayoutBlock";
end

--bool RenderBlock::layoutColumns(bool hasSpecifiedPageLogicalHeight, int pageLogicalHeight, LayoutStateMaintainer& statePusher)
function LayoutBlock:LayoutColumns(hasSpecifiedPageLogicalHeight, pageLogicalHeight, statePusher)
    if (not self:HasColumns()) then
        return false;
	end

	-- TODO: add latter;

	return false;
end

--LayoutUnit logicalTopForFloat(const FloatingObject* child) const
function LayoutBlock:LogicalTopForFloat(child)
	return if_else(self:IsHorizontalWritingMode(), child:Y(), child:X());
end

--LayoutUnit logicalBottomForFloat(const FloatingObject* child) const
function LayoutBlock:LogicalBottomForFloat(child)
	return if_else(self:IsHorizontalWritingMode(), child:MaxY(), child:MaxX());
end

--LayoutUnit logicalLeftForFloat(const FloatingObject* child) const
function LayoutBlock:LogicalLeftForFloat(child)
	return if_else(self:IsHorizontalWritingMode(), child:X(), child:Y());
end

--LayoutUnit logicalRightForFloat(const FloatingObject* child) const
function LayoutBlock:LogicalRightForFloat(child)
	return if_else(self:IsHorizontalWritingMode(), child:MaxX(), child:MaxY());
end

--LayoutUnit logicalWidthForFloat(const FloatingObject* child) const
function LayoutBlock:LogicalWidthForFloat(child)
	return if_else(self:IsHorizontalWritingMode(), child:Width(), child:Height());
end

--void setLogicalTopForFloat(FloatingObject* child, LayoutUnit logicalTop)
function LayoutBlock:SetLogicalTopForFloat(child, logicalTop)
    if (self:IsHorizontalWritingMode()) then
        child:SetY(logicalTop);
    else
        child:SetX(logicalTop);
	end
end

--void setLogicalLeftForFloat(FloatingObject* child, LayoutUnit logicalLeft)
function LayoutBlock:SetLogicalLeftForFloat(child, logicalLeft)
    if (self:IsHorizontalWritingMode()) then
        child:SetX(logicalLeft);
    else
        child:SetY(logicalLeft);
	end
end

--void setLogicalHeightForFloat(FloatingObject* child, LayoutUnit logicalHeight)
function LayoutBlock:SetLogicalHeightForFloat(child, logicalHeight)
    if (self:IsHorizontalWritingMode()) then
        child:SetHeight(logicalHeight);
    else
        child:SetWidth(logicalHeight);
	end
end

--void setLogicalWidthForFloat(FloatingObject* child, LayoutUnit logicalWidth)
function LayoutBlock:SetLogicalWidthForFloat(child, logicalWidth)
    if (self:IsHorizontalWritingMode()) then
        child:SetWidth(logicalWidth);
    else
        child:SetHeight(logicalWidth);
	end
end

--LayoutUnit xPositionForFloatIncludingMargin(const FloatingObject* child) const
function LayoutBlock:XPositionForFloatIncludingMargin(child)
    if (self:IsHorizontalWritingMode()) then
        return child:X() + child:Renderer():MarginLeft();
    else
        return child:X() + self:MarginBeforeForChild(child:Renderer());
	end
end

--LayoutUnit yPositionForFloatIncludingMargin(const FloatingObject* child) const        
function LayoutBlock:YPositionForFloatIncludingMargin(child)
    if (self:IsHorizontalWritingMode()) then
        return child:Y() + self:MarginBeforeForChild(child:Renderer());
    else
        return child:Y() + child:Renderer():MarginTop();
	end
end

--RenderBlock::FloatingObject* RenderBlock::insertFloatingObject(RenderBox* o)
function LayoutBlock:InsertFloatingObject(o)
    --ASSERT(o->isFloating());

    -- Create the list of special objects if we don't aleady have one
    if (not self.floatingObjects) then
        self.floatingObjects = FloatingObjects:new():init(self:IsHorizontalWritingMode());
    else
        -- Don't insert the object again if it's already in the list
        local floatingObjectSet = self.floatingObjects:Set();

		local it = floatingObjectSet:find(FloatingObjectSetFindFunction, o);
		if(it) then
			return it();
		end
    end

    -- Create the special object entry & append it to the list

    local newObj = FloatingObject:new():init(o:Style():Floating());
    
    -- Our location is irrelevant if we're unsplittable or no pagination is in effect.
    -- Just go ahead and lay out the float.
    if (not o:IsPositioned()) then
        local isChildRenderBlock = o:IsLayoutBlock();
        if (isChildRenderBlock and not o:NeedsLayout() and self:View():LayoutState():PageLogicalHeightChanged()) then
            o:SetChildNeedsLayout(true, false);
		end
            
        local affectedByPagination = isChildRenderBlock and self:View():LayoutState().pageLogicalHeight ~= 0;
        if (not affectedByPagination or self:IsWritingModeRoot()) then -- We are unsplittable if we're a block flow root.
            o:LayoutIfNeeded();
        else
            o:ComputeLogicalWidth();
            o:ComputeBlockDirectionMargins(self);
        end
    end
    self:SetLogicalWidthForFloat(newObj, self:LogicalWidthForChild(o) + self:MarginStartForChild(o) + self:MarginEndForChild(o));

    --newObj.shouldPaint = not o:HasSelfPaintingLayer(); -- If a layer exists, the float will paint itself.  Otherwise someone else will.
	newObj.shouldPaint = not o:HasSelfPaintingLayer();
    newObj.isDescendant = true;
    newObj.renderer = o;

    self.floatingObjects:Add(newObj);
    return newObj;
end

--LayoutUnit RenderBlock::adjustForUnsplittableChild(RenderBox* child, LayoutUnit logicalOffset, bool includeMargins)
function LayoutBlock:AdjustForUnsplittableChild(child, logicalOffset, includeMargins)
	includeMargins = if_else(includeMargins == nil, false, includeMargins);

end

--bool RenderBlock::positionNewFloats()
function LayoutBlock:PositionNewFloats()
    if (not self.floatingObjects) then
        return false;
	end

	local floatingObjectSet = self.floatingObjects:Set();
    if (floatingObjectSet:isEmpty()) then
        return false;
	end

    -- If all floats have already been positioned, then we have no work to do.
    if (floatingObjectSet:last():IsPlaced()) then
        return false;
	end

    -- Move backwards through our floating object list until we find a float that has
    -- already been positioned.  Then we'll be able to move forward, positioning all of
    -- the new floats that need it.

	local it = floatingObjectSet:End();
	local begin = floatingObjectSet:Begin();
	local lastPlacedFloatingObject = nil;
	while(it ~= begin) do
		it = floatingObjectSet:prev(it);
		if(it():IsPlaced()) then
			lastPlacedFloatingObject = it();
            it = floatingObjectSet:next(it);
            break;
		end
	end

    local logicalTop = self:LogicalHeight();
    
    -- The float cannot start above the top position of the last positioned float.
    if (lastPlacedFloatingObject) then
        logicalTop = math.max(self:LogicalTopForFloat(lastPlacedFloatingObject), logicalTop);
	end

	-- Now walk through the set of unpositioned floats and place them.
	while(it) do
		local floatingObject = it();
		-- The containing block is responsible for positioning floats, so if we have floats in our
        -- list that come from somewhere else, do not attempt to position them. Also don't attempt to handle
        -- positioned floats, since the positioning layout code handles those.
        if (floatingObject:Renderer():ContainingBlock() ~= self or floatingObject:Renderer():IsPositioned()) then
            -- continue;
		else
			local childBox = floatingObject:Renderer();
			local childLogicalLeftMargin = if_else(self:Style():IsLeftToRightDirection(), self:MarginStartForChild(childBox), self:MarginEndForChild(childBox));

			local oldRect = LayoutRect:new(childBox:X(), childBox:Y() , childBox:Width(), childBox:Height());

			local clear = childBox:Style():Clear();

			--if (childBox:Style()->clear() & CLEFT)
			if (clear == ClearEnum.CLEFT or clear == ClearEnum.CBOTH) then
				logicalTop = math.max(self:LowestFloatLogicalBottom(FloatType.FloatLeft), logicalTop);
			end
			if (clear == ClearEnum.CRIGHT or clear == ClearEnum.CBOTH) then
				logicalTop = math.max(self:LowestFloatLogicalBottom(FloatType.FloatRight), logicalTop);
			end

			local floatLogicalLocation = self:ComputeLogicalLocationForFloat(floatingObject, logicalTop);

			self:SetLogicalLeftForFloat(floatingObject, floatLogicalLocation:X());
			self:SetLogicalLeftForChild(childBox, floatLogicalLocation:X() + childLogicalLeftMargin);
			self:SetLogicalTopForChild(childBox, floatLogicalLocation:Y() + self:MarginBeforeForChild(childBox));

			if (self:View():LayoutState():IsPaginated()) then
				local childBlock = if_else(childBox:IsLayoutBlock(), childBox, nil);

				if (not childBox:NeedsLayout()) then
					childBox:MarkForPaginationRelayoutIfNeeded();
				end
				childBox:LayoutIfNeeded();

				-- If we are unsplittable and don't fit, then we need to move down.
				-- We include our margins as part of the unsplittable area.
				local newLogicalTop = self:AdjustForUnsplittableChild(childBox, floatLogicalLocation:Y(), true);
            
				-- See if we have a pagination strut that is making us move down further.
				-- Note that an unsplittable child can't also have a pagination strut, so this is
				-- exclusive with the case above.
				if (childBlock and childBlock:PaginationStrut()) then
					newLogicalTop = newLogicalTop + childBlock:PaginationStrut();
					childBlock:SetPaginationStrut(0);
				end
            
				if (newLogicalTop ~= floatLogicalLocation:Y()) then
					floatingObject.paginationStrut = newLogicalTop - floatLogicalLocation:Y();

					floatLogicalLocation = self:ComputeLogicalLocationForFloat(floatingObject, newLogicalTop);
					self:SetLogicalLeftForFloat(floatingObject, floatLogicalLocation:X());
					self:SetLogicalLeftForChild(childBox, floatLogicalLocation:X() + childLogicalLeftMargin);
					self:SetLogicalTopForChild(childBox, floatLogicalLocation:Y() + self:MarginBeforeForChild(childBox));
        
					if (childBlock) then
						childBlock:SetChildNeedsLayout(true, false);
					end
					childBox:LayoutIfNeeded();
				end
			end

			self:SetLogicalTopForFloat(floatingObject, floatLogicalLocation:Y());
			self:SetLogicalHeightForFloat(floatingObject, self:LogicalHeightForChild(childBox) + self:MarginBeforeForChild(childBox) + self:MarginAfterForChild(childBox));

			self.floatingObjects:AddPlacedObject(floatingObject);

			-- If the child moved, we have to repaint it.
			if (childBox:CheckForRepaintDuringLayout()) then
				childBox:RepaintDuringLayoutIfMoved(oldRect);
			end
		end

		it = floatingObjectSet:next(it);
	end

    
    return true;
end

function LayoutBlock:HasOverhangingFloats() 
	return self:Parent() and not self:HasColumns() and self:ContainsFloats() and self:LowestFloatLogicalBottomIncludingPositionedFloats() > self:LogicalHeight();
end

function LayoutBlock:HasOverhangingFloat(renderer)
	if (not self.floatingObjects or self:HasColumns() or not self:Parent()) then
        return false;
	end

    local floatingObjectSet = self.floatingObjects:Set();
    --FloatingObjectSetIterator it = floatingObjectSet.find<RenderBox*, FloatingObjectHashTranslator>(renderer);
	local it = floatingObjectSet:find(FloatingObjectSetFindFunction, renderer);
    if (not it) then
        return false;
	end

    return self:LogicalBottomForFloat(it()) > logicalHeight();
end

function LayoutBlock:LowestFloatLogicalBottomIncludingPositionedFloats() 
	return self:LowestFloatLogicalBottom(FloatType.FloatAll);
end

--LayoutUnit lowestFloatLogicalBottom(FloatingObject::Type )
function LayoutBlock:LowestFloatLogicalBottom(floatType)
	floatType = if_else(floatType == nil, FloatType.FloatLeftRight, floatType);

	if (not self.floatingObjects) then
        return 0;
	end
    local lowestFloatBottom = 0;
    local floatingObjectSet = self.floatingObjects:Set();
	local it = floatingObjectSet:Begin();
	while(it) do
		local floatingObject = it();
        if (floatingObject:IsPlaced() and mathlib.bit.band(floatingObject:Type(), floatType)) then
            lowestFloatBottom = math.max(lowestFloatBottom, self:LogicalBottomForFloat(floatingObject));
		end
		it = floatingObjectSet:next(it);
	end

    return lowestFloatBottom;
end

--LayoutPoint RenderBlock::computeLogicalLocationForFloat(const FloatingObject* floatingObject, LayoutUnit logicalTopOffset) const
function LayoutBlock:ComputeLogicalLocationForFloat(floatingObject, logicalTopOffset)
	local childBox = floatingObject:Renderer();
    local logicalRightOffset = self:LogicalRightOffsetForContent(logicalTopOffset); -- Constant part of right offset.
    local logicalLeftOffset = self:LogicalLeftOffsetForContent(logicalTopOffset); -- Constant part of left offset.
    local floatLogicalWidth = math.min(self:LogicalWidthForFloat(floatingObject), logicalRightOffset - logicalLeftOffset); -- The width we look for.
    local floatLogicalLeft;

    if (childBox:Style():Floating() == FloatEnum.LeftFloat) then
        local heightRemainingLeft = 1;
        local heightRemainingRight = 1;
        floatLogicalLeft = self:LogicalLeftOffsetForLine(logicalTopOffset, logicalLeftOffset, false, heightRemainingLeft);
        while (self:LogicalRightOffsetForLine(logicalTopOffset, logicalRightOffset, false, heightRemainingRight) - floatLogicalLeft < floatLogicalWidth) do
            logicalTopOffset = logicalTopOffset + math.min(heightRemainingLeft, heightRemainingRight);
            floatLogicalLeft = self:LogicalLeftOffsetForLine(logicalTopOffset, logicalLeftOffset, false, heightRemainingLeft);
--            if (inRenderFlowThread()) {
--                // Have to re-evaluate all of our offsets, since they may have changed.
--                logicalRightOffset = logicalRightOffsetForContent(logicalTopOffset); // Constant part of right offset.
--                logicalLeftOffset = logicalLeftOffsetForContent(logicalTopOffset); // Constant part of left offset.
--                floatLogicalWidth = min(logicalWidthForFloat(floatingObject), logicalRightOffset - logicalLeftOffset);
--            }
        end
        floatLogicalLeft = math.max(logicalLeftOffset - self:BorderAndPaddingLogicalLeft(), floatLogicalLeft);
    else
        local heightRemainingLeft = 1;
        local heightRemainingRight = 1;
        floatLogicalLeft = self:LogicalRightOffsetForLine(logicalTopOffset, logicalRightOffset, false, heightRemainingRight);
        while (floatLogicalLeft - self:LogicalLeftOffsetForLine(logicalTopOffset, logicalLeftOffset, false, heightRemainingLeft) < floatLogicalWidth) do
            logicalTopOffset = logicalTopOffset + math.min(heightRemainingLeft, heightRemainingRight);
            floatLogicalLeft = self:LogicalRightOffsetForLine(logicalTopOffset, logicalRightOffset, false, heightRemainingRight);
--            if (inRenderFlowThread()) {
--                // Have to re-evaluate all of our offsets, since they may have changed.
--                logicalRightOffset = logicalRightOffsetForContent(logicalTopOffset); // Constant part of right offset.
--                logicalLeftOffset = logicalLeftOffsetForContent(logicalTopOffset); // Constant part of left offset.
--                floatLogicalWidth = min(logicalWidthForFloat(floatingObject), logicalRightOffset - logicalLeftOffset);
--            }
        end
        floatLogicalLeft = floatLogicalLeft - self:LogicalWidthForFloat(floatingObject); 
		-- Use the original width of the float here, since the local variable |floatLogicalWidth| was capped to the available line width. See fast/block/float/clamped-right-float.html.
    end
    
    return LayoutPoint:new(floatLogicalLeft, logicalTopOffset);
end

--void RenderBlock::insertPositionedObject(RenderBox* o)
function LayoutBlock:InsertPositionedObject(o)
    if (o:IsLayoutFlowThread()) then
        return;
	end
    
    -- Create the list of special objects if we don't aleady have one
    if (not self.positionedObjects) then
        self.positionedObjects = ListHashSet:new();
	end

    self.positionedObjects:add(o);
end

--void RenderBlock::removePositionedObject(RenderBox* o)
function LayoutBlock:RemovePositionedObject(o)
    if (self.positionedObjects) then
        self.positionedObjects:remove(o);
	end
end

function LayoutBlock:LayoutPositionedObjects(relayoutChildren)
	
	if (not self.positionedObjects) then
        return false;
	end
--	if (hasColumns())
--        view()->layoutState()->clearPaginationInformation(); // Positioned objects are not part of the column flow, so they don't paginate with the columns.

    local didFloatingBoxRelayout = false;

    --RenderBox* r;
	local box = nil;
	local it = self.positionedObjects:Begin();
	while(it) do
		box = it();

		-- When a non-positioned block element moves, it may have positioned children that are implicitly positioned relative to the
        -- non-positioned block.  Rather than trying to detect all of these movement cases, we just always lay out positioned
        -- objects that are positioned implicitly like this.  Such objects are rare, and so in typical DHTML menu usage (where everything is
        -- positioned explicitly) this should not incur a performance penalty.
        if (relayoutChildren or (box:Style():HasStaticBlockPosition(self:IsHorizontalWritingMode()) and box:Parent() ~= self)) then
            box:SetChildNeedsLayout(true, false);
		end
            
        -- If relayoutChildren is set and the child has percentage padding or an embedded content box, we also need to invalidate the childs pref widths.
        if (relayoutChildren and box:NeedsPreferredWidthsRecalculation()) then
            box:SetPreferredLogicalWidthsDirty(true, false);
		end
        
        if (not box:NeedsLayout()) then
            box:MarkForPaginationRelayoutIfNeeded();
		end
        
        -- FIXME: Technically we could check the old placement and the new placement of the box and only invalidate if
        -- the margin box of the object actually changed.
        if (box:NeedsLayout() and box:IsFloating()) then
            didFloatingBoxRelayout = true;
		end

        -- We don't have to do a full layout.  We just have to update our position. Try that first. If we have shrink-to-fit width
        -- and we hit the available width constraint, the layoutIfNeeded() will catch it and do a full layout.
        if (box:NeedsPositionedMovementLayoutOnly() and box:TryLayoutDoingPositionedMovementOnly()) then
            box:SetNeedsLayout(false);
		end
            
        -- If we are in a flow thread, go ahead and compute a vertical position for our object now.
        -- If it's wrong we'll lay out again.
        local oldLogicalTop = 0;
        local checkForPaginationRelayout = box:NeedsLayout() and self:View():LayoutState():IsPaginated() and self:View():LayoutState():PageLogicalHeight(); 
        if (checkForPaginationRelayout) then
            if (self:IsHorizontalWritingMode() == box:IsHorizontalWritingMode()) then
                box:ComputeLogicalHeight();
            else
                box:ComputeLogicalWidth();
			end
            oldLogicalTop = self:LogicalTopForChild(box);
        end
            
        box:LayoutIfNeeded();
        -- Layout again if our estimate was wrong.
        if (checkForPaginationRelayout and self:LogicalTopForChild(box) ~= oldLogicalTop) then
            box:SetChildNeedsLayout(true, false);
            box:LayoutIfNeeded();
        end
		it = self.positionedObjects:next(it);
		
	end

    
    
--    if (hasColumns())
--        view()->layoutState()->m_columnInfo = columnInfo(); // FIXME: Kind of gross. We just put this back into the layout state so that pop() will work.
        
    return didFloatingBoxRelayout;
end

--@param o: RenderBlock;
function LayoutBlock:RemovePositionedObjects(o)
	if (not self.positionedObjects) then
        return;
	end
    
    --RenderBox* r;
	local r;
    
    local _end = self.positionedObjects:End();
    
    --Vector<RenderBox*, 16> deadObjects;
	local deadObjects = {};
	local it = self.positionedObjects:Begin();
	while(it ~= _end) do
		r = it();
        if (not o or r:IsDescendantOf(o)) then
            if (o) then
                r:SetChildNeedsLayout(true, false);
			end
            
            -- It is parent blocks job to add positioned child to positioned objects list of its containing block
            -- Parent layout needs to be invalidated to ensure this happens.
            local p = r:Parent();
            while (p and not p:IsLayoutBlock()) do
                p = p:Parent();
			end
            if (p) then
                p:SetChildNeedsLayout(true);
			end
            
            deadObjects[#deadObjects+1] = r;
        end


		it = self.positionedObjects:next(it);
	end

	for i = 1, #deadObjects do
		self.positionedObjects:remove(deadObjects[i]);
	end
end

--LayoutUnit startOffsetForContent(RenderRegion* region, LayoutUnit offsetFromLogicalTopOfFirstPage) const
--LayoutUnit startOffsetForContent(LayoutUnit blockOffset) const
--LayoutUnit startOffsetForContent() const 
function LayoutBlock:StartOffsetForContent(region, offsetFromLogicalTopOfFirstPage)
	if(region == nil and offsetFromLogicalTopOfFirstPage == nil) then
		if(self:Style():IsLeftToRightDirection()) then
			return self:LogicalLeftOffsetForContent()
		end
		return self:LogicalWidth() - self:LogicalRightOffsetForContent();
	end
	if(offsetFromLogicalTopOfFirstPage == nil) then
		region = self:RegionAtBlockOffset(region);
		offsetFromLogicalTopOfFirstPage = self:OffsetFromLogicalTopOfFirstPage();
	end
	if(self:Style():IsLeftToRightDirection()) then
		self:LogicalLeftOffsetForContent(region, offsetFromLogicalTopOfFirstPage)
	end
	return self:LogicalWidth() - self:LogicalRightOffsetForContent(region, offsetFromLogicalTopOfFirstPage);
end

--void RenderBlock::setStaticInlinePositionForChild(RenderBox* child, LayoutUnit blockOffset, LayoutUnit inlinePosition)
function LayoutBlock:SetStaticInlinePositionForChild(child, blockOffset, inlinePosition)
    if (self:InRenderFlowThread()) then
        -- Shift the inline position to exclude the region offset.
        inlinePosition = inlinePosition + self:StartOffsetForContent() - self:StartOffsetForContent(blockOffset);
    end
    child:Layer():SetStaticInlinePosition(inlinePosition);
end

function LayoutBlock:InitMaxMarginValues()
    if (self.m_rareData) then
        self.m_rareData.m_margins = MarginValues:new():init(RenderBlockRareData.PositiveMarginBeforeDefault(self) , RenderBlockRareData.NegativeMarginBeforeDefault(self),
                                                RenderBlockRareData.PositiveMarginAfterDefault(self), RenderBlockRareData.NegativeMarginAfterDefault(self));
        self.m_rareData.m_paginationStrut = 0;
    end
end

function LayoutBlock:PaginationStrut() 
	if(self.m_rareData) then
		return self.m_rareData.m_paginationStrut;
	end
	return 0;
end

function LayoutBlock:SetPaginationStrut(strut)
	if (not self.m_rareData) then
        if (strut == 0) then
            return;
		end
        self.m_rareData = RenderBlockRareData:new():init(self);
    end
    self.m_rareData.m_paginationStrut = strut;
end
    
-- The page logical offset is the object's offset from the top of the page in the page progression
-- direction (so an x-offset in vertical text and a y-offset for horizontal text).
function LayoutBlock:PageLogicalOffset() 
	if(self.m_rareData) then
		return self.m_rareData.m_pageLogicalOffset;
	end
	return 0;
end

function LayoutBlock:SetPageLogicalOffset(logicalOffset)
	if (not self.m_rareData) then
        if (logicalOffset == 0) then
            return;
		end
        self.m_rareData = RenderBlockRareData:new():init(self);
    end
    self.m_rareData.m_pageLogicalOffset = logicalOffset;
end

function LayoutBlock:DeleteLineBoxTree()
    self.lineBoxes:DeleteLineBoxTree(self:RenderArena());
end

--void RenderBlock::addPercentHeightDescendant(RenderBox* descendant)
function LayoutBlock:AddPercentHeightDescendant(descendant)
	-- TODO: add latter;
end

--void RenderBlock::layoutExcludedChildren(bool relayoutChildren)
function LayoutBlock:LayoutExcludedChildren(relayoutChildren)
	if (not self:IsFieldset()) then
        return;
	end

	-- TODO: add latter;
end

-- static bool canMergeContiguousAnonymousBlocks(RenderObject* oldChild, RenderObject* prev, RenderObject* next)
local function canMergeContiguousAnonymousBlocks(oldChild, prev, next)
    if (oldChild:DocumentBeingDestroyed() or oldChild:IsInline() or oldChild:VirtualContinuation()) then
        return false;
	end
    if (oldChild:Parent() and oldChild:Parent():IsDetails()) then
        return false;
	end

    if ((prev and (not prev:IsAnonymousBlock() or prev:ToRenderBlock():Continuation() or prev:ToRenderBlock():BeingDestroyed()))
        or (next and (not next:IsAnonymousBlock() or next:ToRenderBlock():Continuation() or next:ToRenderBlock():BeingDestroyed()))) then
        return false;
	end

    -- FIXME: This check isn't required when inline run-ins can't be split into continuations.
    if (prev and prev:FirstChild() and prev:FirstChild():IsInline() and prev:FirstChild():IsRunIn()) then
        return false;
	end

    if ((prev and (prev:IsRubyRun() or prev:IsRubyBase())) or (next and (next:IsRubyRun() or next:IsRubyBase()))) then
        return false;
	end

    if (not prev or not next) then
        return true;
	end

    -- Make sure the types of the anonymous blocks match up.
    return prev:IsAnonymousColumnsBlock() == next:IsAnonymousColumnsBlock()
           and prev:IsAnonymousColumnSpanBlock() == next:IsAnonymousColumnSpanBlock();
end



--void RenderBlock::removeChild(RenderObject* oldChild)
function LayoutBlock:RemoveChild(oldChild)
    -- If this child is a block, and if our previous and next siblings are
    -- both anonymous blocks with inline content, then we can go ahead and
    -- fold the inline content back together.
    local prev = oldChild:PreviousSibling();
    local next = oldChild:NextSibling();
    local canMergeAnonymousBlocks = canMergeContiguousAnonymousBlocks(oldChild, prev, next);
    if (canMergeAnonymousBlocks and prev and next) then
        prev:SetNeedsLayoutAndPrefWidthsRecalc();
        local nextBlock = next:ToRenderBlock();
        local prevBlock = prev:ToRenderBlock();
       
        if (prev:ChildrenInline() ~= next:ChildrenInline()) then
			local inlineChildrenBlock, blockChildrenBlock;
			if(prev:ChildrenInline()) then
				inlineChildrenBlock = prevBlock;
				blockChildrenBlock = nextBlock;
			else
				inlineChildrenBlock = nextBlock;
				blockChildrenBlock = prevBlock;
			end
            
            -- Place the inline children block inside of the block children block instead of deleting it.
            -- In order to reuse it, we have to reset it to just be a generic anonymous block.  Make sure
            -- to clear out inherited column properties by just making a new style, and to also clear the
            -- column span flag if it is set.
            local newStyle = ComputedStyle.CreateAnonymousStyle(self:Style());
            self:Children():RemoveChildNode(self, inlineChildrenBlock, inlineChildrenBlock:HasLayer());
            inlineChildrenBlock:SetStyle(newStyle);
            
            -- Now just put the inlineChildrenBlock inside the blockChildrenBlock.
			local beforeChild = nil;
			if(prev == inlineChildrenBlock) then
				beforeChild = blockChildrenBlock:FirstChild();
			end
            blockChildrenBlock:Children():InsertChildNode(blockChildrenBlock, inlineChildrenBlock, beforeChild,
                                                            inlineChildrenBlock:HasLayer() or blockChildrenBlock:HasLayer());
            next:SetNeedsLayoutAndPrefWidthsRecalc();
            
            -- inlineChildrenBlock got reparented to blockChildrenBlock, so it is no longer a child
            -- of "this". we null out prev or next so that is not used later in the function.
            if (inlineChildrenBlock == prevBlock) then
                prev = nil;
            else
                next = nil;
			end
        else
            -- Take all the children out of the |next| block and put them in
            -- the |prev| block.
            nextBlock:MoveAllChildrenTo(prevBlock, nextBlock:HasLayer() or prevBlock:HasLayer());        
            
            -- Delete the now-empty block's lines and nuke it.
            nextBlock:DeleteLineBoxTree();
            nextBlock:Destroy();
            next = nil;
        end
    end

    LayoutBlock._super.RemoveChild(self, oldChild)

    local child = if_else(prev, prev, next);
    if (canMergeAnonymousBlocks and child and not child:PreviousSibling() and not child:NextSibling() and not self:IsDeprecatedFlexibleBox()) then
        -- The removal has knocked us down to containing only a single anonymous
        -- box.  We can go ahead and pull the content right back up into our
        -- box.
        self:SetNeedsLayoutAndPrefWidthsRecalc();
        self:SetChildrenInline(child:ChildrenInline());
        local anonBlock = self:Children():RemoveChildNode(self, child, child:HasLayer()):ToRenderBlock();
        anonBlock:MoveAllChildrenTo(self, child:HasLayer());
        -- Delete the now-empty block's lines and nuke it.
        anonBlock:DeleteLineBoxTree();
        anonBlock:Destroy();
    end

    if (not self:FirstChild() and not self:DocumentBeingDestroyed()) then
        -- If this was our last child be sure to clear out our line boxes.
        if (self:ChildrenInline()) then
            self:LineBoxes():DeleteLineBoxes(self:RenderArena());
		end
    end
end

--LayoutUnit RenderBlock::nextFloatLogicalBottomBelow(LayoutUnit logicalHeight) const
function LayoutBlock:NextFloatLogicalBottomBelow(logicalHeight)
    if (not self.floatingObjects) then
        return logicalHeight;
	end

    --LayoutUnit bottom = numeric_limits<LayoutUnit>::max();
	local bottom = INT_MAX;
	
	local floatingObjectSet = self.floatingObjects:Set();
	local it = floatingObjectSet:Begin();
	while(it) do
		local floatingObject = it();
        local floatBottom = self:LogicalBottomForFloat(floatingObject);
        if (floatBottom > logicalHeight) then
            bottom = math.min(floatBottom, bottom);
		end
		
		it = floatingObjectSet:next(it);
	end

    return if_else(bottom == INT_MAX, logicalHeight, bottom);
end

--void RenderBlock::repaintOverhangingFloats(bool paintAllDescendants)
function LayoutBlock:RepaintOverhangingFloats(paintAllDescendants)
    -- Repaint any overhanging floats (if we know we're the one to paint them).
    -- Otherwise, bail out.
    if (not self:HasOverhangingFloats()) then
        return;
	end

    -- FIXME: Avoid disabling LayoutState. At the very least, don't disable it for floats originating
    -- in this block. Better yet would be to push extra state for the containers of other floats.
    --LayoutStateDisabler layoutStateDisabler(view());
	local floatingObjectSet = self.floatingObjects:Set();
	local it = floatingObjectSet:Begin();
	while(it) do
		local r = it();
		if (self:LogicalBottomForFloat(r) > self:LogicalHeight() and ((paintAllDescendants and r:Renderer():IsDescendantOf(self)) or r:ShouldPaint()) and not r:Renderer():HasSelfPaintingLayer()) then
            r:Renderer():Repaint();
            r:Renderer():RepaintOverhangingFloats();
        end
	
		it = floatingObjectSet:next(it);
	end
end

function LayoutBlock:AddPositionedFloats()
	if (not self.positionedObjects) then
		return;
	end


	local it = self.positionedObjects:Begin();
	while(it) do
		local positionedObject = it();
		if (not positionedObject:IsFloating()) then
			-- continue;
		else
			--ASSERT(!positionedObject->needsLayout());

			-- If we're a positioned float, then we need to insert ourselves as a floating object also. We only do
			-- this after the positioned object has received a layout, since otherwise the dimensions and placement
			-- won't be correct.
			local floatingObject = self:InsertFloatingObject(positionedObject);
			self:SetLogicalLeftForFloat(floatingObject, self:LogicalLeftForChild(positionedObject) - self:MarginLogicalLeftForChild(positionedObject));
			self:SetLogicalTopForFloat(floatingObject, self:LogicalTopForChild(positionedObject) - self:MarginBeforeForChild(positionedObject));
			self:SetLogicalHeightForFloat(floatingObject, self:LogicalHeightForChild(positionedObject) + self:MarginBeforeForChild(positionedObject) + self:MarginAfterForChild(positionedObject));

			self.floatingObjects:AddPlacedObject(floatingObject);
		
			self.hasPositionedFloats = true;
		end

		it = self.positionedObjects:next(it);
	end
end

--void RenderBlock::addIntrudingFloats(RenderBlock* prev, LayoutUnit logicalLeftOffset, LayoutUnit logicalTopOffset)
function LayoutBlock:AddIntrudingFloats(prev, logicalLeftOffset, logicalTopOffset)
	-- If the parent or previous sibling doesn't have any floats to add, don't bother.
	if (not prev.floatingObjects) then
		return;
	end

	logicalLeftOffset = logicalLeftOffset + if_else(self:IsHorizontalWritingMode(), self:MarginLeft(), self:MarginTop());

	local prevSet = prev.floatingObjects:Set();
	local it = prevSet:Begin();
	while(it) do
		--FloatingObject* r = *it;
		local r = it();
		if (self:LogicalBottomForFloat(r) > logicalTopOffset) then
			if (not self.floatingObjects or not self.floatingObjects:Set():contains(r)) then
				local leftOffset = if_else(self:IsHorizontalWritingMode(), logicalLeftOffset, logicalTopOffset);
				local topOffset = if_else(self:IsHorizontalWritingMode(), logicalTopOffset, logicalLeftOffset);
			
				local floatingObj = FloatingObject:new():init(r:Type(), LayoutRect:new(r:X() - leftOffset, r:Y() - topOffset, r:Width(), r:Height()));

				-- Applying the child's margin makes no sense in the case where the child was passed in.
				-- since this margin was added already through the modification of the |logicalLeftOffset| variable
				-- above.  |logicalLeftOffset| will equal the margin in this case, so it's already been taken
				-- into account.  Only apply this code if prev is the parent, since otherwise the left margin
				-- will get applied twice.
				if (prev ~= self:Parent()) then
					if (self:IsHorizontalWritingMode()) then
						floatingObj:SetX(floatingObj:X() + prev:MarginLeft());
					else
						floatingObj:SetY(floatingObj:Y() + prev:MarginTop());
					end
				end
		   
				floatingObj.shouldPaint = false;  -- We are not in the direct inheritance chain for this float. We will never paint it.
				floatingObj.renderer = r.renderer;
			
				-- We create the floating object list lazily.
				if (not self.floatingObjects) then
					self.floatingObjects = FloatingObjects:new():init(self:IsHorizontalWritingMode());
				end
				self.floatingObjects:Add(floatingObj);
			end
		end
	
		it = prevSet:next(it);
	end
end

--void RenderBlock::markLinesDirtyInBlockRange(LayoutUnit logicalTop, LayoutUnit logicalBottom, RootInlineBox* highest)
function LayoutBlock:MarkLinesDirtyInBlockRange(logicalTop, logicalBottom, highest)
	if (logicalTop >= logicalBottom) then
        return;
	end

    local lowestDirtyLine = self:LastRootBox();
    local afterLowest = lowestDirtyLine;
    while (lowestDirtyLine and lowestDirtyLine:LineBottomWithLeading() >= logicalBottom and logicalBottom < INT_MAX) do
        afterLowest = lowestDirtyLine;
        lowestDirtyLine = lowestDirtyLine:PrevRootBox();
    end

    while (afterLowest and afterLowest ~= highest and (afterLowest:LineBottomWithLeading() >= logicalTop or afterLowest:LineBottomWithLeading() < 0)) do
        afterLowest:MarkDirty();
        afterLowest = afterLowest:PrevRootBox();
    end
end

--void RenderBlock::removeFloatingObject(RenderBox* o)
function LayoutBlock:RemoveFloatingObject(o)
    if (self.floatingObjects) then
		local floatingObjectSet = self.floatingObjects:Set();
		local it = floatingObjectSet:find(FloatingObjectSetFindFunction, o);
		if(it) then
			--FloatingObject* r = *it;
			local r = it();
			
			if (self:ChildrenInline()) then
                local logicalTop = self:LogicalTopForFloat(r);
                local logicalBottom = self:LogicalBottomForFloat(r);

                -- Fix for https://bugs.webkit.org/show_bug.cgi?id=54995.
                if (logicalBottom < 0 or logicalBottom < logicalTop or logicalTop == INT_MAX) then
                    logicalBottom = INT_MAX;
                else
                    -- Special-case zero- and less-than-zero-height floats: those don't touch
                    -- the line that they're on, but it still needs to be dirtied. This is
                    -- accomplished by pretending they have a height of 1.
                    logicalBottom = math.max(logicalBottom, logicalTop + 1);
                end
                if (r.originatingLine) then
                    if (not self:SelfNeedsLayout()) then
                        --ASSERT(r->m_originatingLine->renderer() == this);
                        r.originatingLine:MarkDirty();
                    end
--#if !ASSERT_DISABLED
--                    r->m_originatingLine = 0;
--#endif
                end
                self:MarkLinesDirtyInBlockRange(0, logicalBottom);
            end
            self.floatingObjects:remove(r);
            --ASSERT(!r->m_originatingLine);
            --delete r;
		end
    end
end

--RenderStyle* RenderBlock::outlineStyleForRepaint() const
function LayoutBlock:OutlineStyleForRepaint()
    --return isAnonymousBlockContinuation() ? continuation()->style() : style();
	return self:Style();
end