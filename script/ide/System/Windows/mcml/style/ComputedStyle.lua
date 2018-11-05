--[[
Title: style manager
Author(s): LiPeng
Date: 2018/1/16
Desc: singleton class for managing all file based styles globally. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");
------------------------------------------------------------
]]

--NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
--NPL.load("(gl)script/ide/math/bit.lua");
--NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleDeclaration.lua");
--NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
--local Length = commonlib.gettable("System.Windows.mcml.platform.Length");
--local CSSStyleDeclaration = commonlib.gettable("System.Windows.mcml.css.CSSStyleDeclaration");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/LengthSize.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/Color.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/BorderValue.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleContentAlignmentData.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleSelfAlignmentData.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/OutlineValue.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/LengthBox.lua");
local LengthBox = commonlib.gettable("System.Windows.mcml.platform.LengthBox");
local OutlineValue = commonlib.gettable("System.Windows.mcml.style.OutlineValue");
local StyleSelfAlignmentData = commonlib.gettable("System.Windows.mcml.style.StyleSelfAlignmentData");
local StyleContentAlignmentData = commonlib.gettable("System.Windows.mcml.style.StyleContentAlignmentData");
local BorderValue = commonlib.gettable("System.Windows.mcml.style.BorderValue");
local Color = commonlib.gettable("System.Windows.mcml.style.Color");
local LengthSize = commonlib.gettable("System.Windows.mcml.platform.LengthSize");
local Length = commonlib.gettable("System.Windows.mcml.platform.Length");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");


local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");
ComputedStyle.__index = ComputedStyle;

local LengthTypeEnum = Length.LengthTypeEnum;
local TextDirectionEnum = ComputedStyleConstants.TextDirectionEnum;
local UnicodeBidiEnum = ComputedStyleConstants.UnicodeBidiEnum;
local StyleDifferenceEnum = ComputedStyleConstants.StyleDifferenceEnum;
local DisplayEnum = ComputedStyleConstants.DisplayEnum;
local PositionEnum = ComputedStyleConstants.PositionEnum;
local WritingModeEnum = ComputedStyleConstants.WritingModeEnum;
local FloatEnum = ComputedStyleConstants.FloatEnum;
local WhiteSpaceEnum = ComputedStyleConstants.WhiteSpaceEnum;
local KHTMLLineBreakEnum = ComputedStyleConstants.KHTMLLineBreakEnum;
local WordBreakEnum = ComputedStyleConstants.WordBreakEnum;
local WordWrapEnum = ComputedStyleConstants.WordWrapEnum;
local PageSizeTypeEnum = ComputedStyleConstants.PageSizeTypeEnum;
local TextEmphasisMarkEnum = ComputedStyleConstants.TextEmphasisMarkEnum;
local LineBoxContainEnum = ComputedStyleConstants.LineBoxContainEnum;
local FlexDirectionEnum = ComputedStyleConstants.FlexDirectionEnum;
local FlexWrapEnum = ComputedStyleConstants.FlexWrapEnum;
local ControlPartEnum = ComputedStyleConstants.ControlPartEnum;
local ItemPositionEnum = ComputedStyleConstants.ItemPositionEnum;
local OverflowAlignmentEnum = ComputedStyleConstants.OverflowAlignmentEnum;
local ContentPositionEnum = ComputedStyleConstants.ContentPositionEnum;
local ContentDistributionTypeEnum = ComputedStyleConstants.ContentDistributionTypeEnum;
local VisibilityEnum = ComputedStyleConstants.VisibilityEnum;

-- Initial values for all the properties
function ComputedStyle.initialBorderCollapse() return ComputedStyleConstants.BorderCollapseEnum.BSEPARATE; end
function ComputedStyle.initialBorderStyle() return ComputedStyleConstants.BorderStyleEnum.BNONE; end
function ComputedStyle.initialOutlineStyleIsAuto() return ComputedStyleConstants.OutlineIsAutoEnum.AUTO_OFF; end
--function ComputedStyle.initialNinePieceImage() return NinePieceImage(); end
function ComputedStyle.initialBorderRadius() return LengthSize:new(Length:new(0, LengthTypeEnum.Fixed), Length:new(0, LengthTypeEnum.Fixed)); end
function ComputedStyle.initialCaptionSide() return ComputedStyleConstants.CaptionSideEnum.CAPTOP; end
function ComputedStyle.initialClear() return ComputedStyleConstants.ClearEnum.CNONE; end
--function ComputedStyle.initialColorSpace() return ColorSpaceDeviceRGB; end
function ComputedStyle.initialDirection() return TextDirectionEnum.LTR; end
function ComputedStyle.initialWritingMode() return ComputedStyleConstants.WritingModeEnum.TopToBottomWritingMode; end
function ComputedStyle.initialTextCombine() return ComputedStyleConstants.TextCombineEnum.TextCombineNone; end
--function ComputedStyle.initialTextOrientation() return TextOrientationVerticalRight; end
function ComputedStyle.initialDisplay() return ComputedStyleConstants.DisplayEnum.INLINE; end
function ComputedStyle.initialEmptyCells() return ComputedStyleConstants.EmptyCellEnum.SHOW; end
function ComputedStyle.initialFloating() return ComputedStyleConstants.FloatEnum.NoFloat; end
function ComputedStyle.initialListStylePosition() return ComputedStyleConstants.ListStylePositionEnum.OUTSIDE; end
function ComputedStyle.initialListStyleType() return ComputedStyleConstants.ListStyleTypeEnum.Disc; end
function ComputedStyle.initialOverflowX() return ComputedStyleConstants.OverflowEnum.OVISIBLE; end
function ComputedStyle.initialOverflowY() return ComputedStyleConstants.OverflowEnum.OVISIBLE; end
function ComputedStyle.initialPageBreak() return ComputedStyleConstants.PageBreakEnum.PBAUTO; end
function ComputedStyle.initialPosition() return ComputedStyleConstants.PositionEnum.StaticPosition; end
function ComputedStyle.initialTableLayout() return ComputedStyleConstants.TableLayoutEnum.TAUTO; end
function ComputedStyle.initialUnicodeBidi() return UnicodeBidiEnum.UBNormal; end
function ComputedStyle.initialTextTransform() return ComputedStyleConstants.TextTransformEnum.TTNONE; end
function ComputedStyle.initialVisibility() return VisibilityEnum.VISIBLE; end
function ComputedStyle.initialWhiteSpace() return ComputedStyleConstants.WhiteSpaceEnum.NORMAL; end
function ComputedStyle.initialHorizontalBorderSpacing() return 0; end
function ComputedStyle.initialVerticalBorderSpacing() return 0; end
function ComputedStyle.initialCursor() return ComputedStyleConstants.CursorEnum.CURSOR_AUTO; end
function ComputedStyle.initialColor() return Color.black; end
--function ComputedStyle.initialListStyleImage() return 0; end
function ComputedStyle.initialBorderWidth() return 3; end
function ComputedStyle.initialLetterWordSpacing() return 0; end
function ComputedStyle.initialSize() return Length:new(); end
function ComputedStyle.initialMinSize() return Length:new(0, LengthTypeEnum.Fixed); end
function ComputedStyle.initialMaxSize() return Length:new(LengthTypeEnum.Undefined); end
function ComputedStyle.initialOffset() return Length:new(); end
function ComputedStyle.initialMargin() return Length:new(LengthTypeEnum.Fixed); end
function ComputedStyle.initialPadding() return Length:new(LengthTypeEnum.Fixed); end
function ComputedStyle.initialTextIndent() return Length:new(LengthTypeEnum.Fixed); end
function ComputedStyle.initialVerticalAlign() return ComputedStyleConstants.VerticalAlignEnum.BASELINE; end
function ComputedStyle.initialWidows() return 2; end
function ComputedStyle.initialOrphans() return 2; end
function ComputedStyle.initialLineHeight() return Length:new(-100.0, LengthTypeEnum.Percent); end
function ComputedStyle.initialTextAlign() return ComputedStyleConstants.TextAlignEnum.TAAUTO; end
function ComputedStyle.initialTextDecoration() return ComputedStyleConstants.TextDecorationEnum.TDNONE; end
function ComputedStyle.initialZoom() return 1.0; end
function ComputedStyle.initialOutlineOffset() return 0; end
function ComputedStyle.initialOpacity() return 1.0; end
function ComputedStyle.initialBoxAlign() return ComputedStyleConstants.BoxAlignmentEnum.BSTRETCH; end
function ComputedStyle.initialBoxDirection() return ComputedStyleConstants.BoxDirectionEnum.BNORMAL; end
function ComputedStyle.initialBoxLines() return ComputedStyleConstants.BoxLinesEnum.SINGLE; end
function ComputedStyle.initialBoxOrient() return ComputedStyleConstants.BoxOrientEnum.HORIZONTAL; end
function ComputedStyle.initialBoxPack() return ComputedStyleConstants.BoxAlignmentEnum.BSTART; end
function ComputedStyle.initialBoxFlex() return 0.0; end
function ComputedStyle.initialBoxFlexGroup() return 1; end
function ComputedStyle.initialBoxOrdinalGroup() return 1; end
function ComputedStyle.initialBoxSizing() return ComputedStyleConstants.BoxSizingEnum.CONTENT_BOX; end
function ComputedStyle.initialBoxReflect() return nil; end

function ComputedStyle.initialFlexGrow() return 0; end
function ComputedStyle.initialFlexShrink() return 1; end
function ComputedStyle.initialFlexBasis() return Length:new(LengthTypeEnum.Auto); end
function ComputedStyle.initialOrder() return 0; end
function ComputedStyle.initialSelfAlignment() return StyleSelfAlignmentData:new(ItemPositionEnum.ItemPositionAuto, OverflowAlignmentEnum.OverflowAlignmentDefault); end
local function isCSSGridLayoutEnabled() return true; end
function ComputedStyle.initialDefaultAlignment() 
	local item_position = if_else(isCSSGridLayoutEnabled(), ItemPositionEnum.ItemPositionNormal, ItemPositionEnum.ItemPositionStretch);
	return StyleSelfAlignmentData:new(item_position, OverflowAlignmentEnum.OverflowAlignmentDefault); 
end
function ComputedStyle.initialContentAlignment() 
	return StyleContentAlignmentData:new(ContentPositionEnum.ContentPositionNormal, ContentDistributionTypeEnum.ContentDistributionDefault, OverflowAlignmentEnum.OverflowAlignmentDefault);
end
function ComputedStyle.initialFlexDirection() return FlexDirectionEnum.FlowRow; end
function ComputedStyle.initialFlexWrap() return FlexWrapEnum.FlexNoWrap; end

function ComputedStyle.initialMarqueeLoopCount() return -1; end
function ComputedStyle.initialMarqueeSpeed() return 85; end
function ComputedStyle.initialMarqueeIncrement() return Length:new(6, LengthTypeEnum.Fixed); end
function ComputedStyle.initialMarqueeBehavior() return ComputedStyleConstants.MarqueeBehaviorEnum.MSCROLL; end
function ComputedStyle.initialMarqueeDirection() return ComputedStyleConstants.MarqueeDirectionEnum.MAUTO; end
function ComputedStyle.initialUserModify() return ComputedStyleConstants.UserModifyEnum.READ_ONLY; end
function ComputedStyle.initialUserDrag() return ComputedStyleConstants.UserDragEnum.DRAG_AUTO; end
function ComputedStyle.initialUserSelect() return ComputedStyleConstants.UserSelectEnum.SELECT_TEXT; end
function ComputedStyle.initialTextOverflow() return ComputedStyleConstants.TextOverflowEnum.TextOverflowClip; end
function ComputedStyle.initialMarginBeforeCollapse() return ComputedStyleConstants.MarginCollapseEnum.MCOLLAPSE; end
function ComputedStyle.initialMarginAfterCollapse() return ComputedStyleConstants.MarginCollapseEnum.MCOLLAPSE; end
function ComputedStyle.initialWordBreak() return ComputedStyleConstants.WordBreakEnum.NormalWordBreak; end
function ComputedStyle.initialWordWrap() return ComputedStyleConstants.WordWrapEnum.NormalWordWrap; end
function ComputedStyle.initialNBSPMode() return ComputedStyleConstants.NBSPModeEnum.NBNORMAL; end
function ComputedStyle.initialKHTMLLineBreak() return ComputedStyleConstants.KHTMLLineBreakEnum.LBNORMAL; end
function ComputedStyle.initialMatchNearestMailBlockquoteColor() return ComputedStyleConstants.MatchNearestMailBlockquoteColorEnum.BCNORMAL; end
--function ComputedStyle.initialHighlight() return nullAtom; end
function ComputedStyle.initialSpeak() return ComputedStyleConstants.SpeakEnum.SpeakNormal; end
function ComputedStyle.initialHyphens() return ComputedStyleConstants.HyphensEnum.HyphensManual; end
function ComputedStyle.initialHyphenationLimitBefore() return -1; end
function ComputedStyle.initialHyphenationLimitAfter() return -1; end
function ComputedStyle.initialHyphenationLimitLines() return -1; end
--function ComputedStyle.initialHyphenationString() return nullAtom; end
--function ComputedStyle.initialLocale() return nullAtom; end
function ComputedStyle.initialBorderFit() return ComputedStyleConstants.BorderFitEnum.BorderFitBorder; end
function ComputedStyle.initialResize() return ComputedStyleConstants.ResizeEnum.RESIZE_NONE; end
function ComputedStyle.initialAppearance() return ControlPartEnum.NoControlPart; end
function ComputedStyle.initialRTLOrdering() return ComputedStyleConstants.OrderEnum.LogicalOrder; end
function ComputedStyle.initialTextStrokeWidth() return 0; end
function ComputedStyle.initialColumnCount() return 1; end
function ComputedStyle.initialColumnSpan() return false; end
function ComputedStyle.initialBackgroundColor() return Color.transparent; end
function ComputedStyle.initialBackgroundImage() return nil; end
function ComputedStyle.initialTextSecurity() return ComputedStyleConstants.TextSecurityEnum.TSNONE; end
function ComputedStyle.initialTextSizeAdjust() return true; end
function ComputedStyle.initialPointerEvents() return ComputedStyleConstants.PointerEventsEnum.PE_AUTO; end
function ComputedStyle.initialRegionOverflow() return ComputedStyleConstants.RegionOverflowEnum.AutoRegionOverflow; end
function ComputedStyle.initialTransformStyle3D() return ComputedStyleConstants.TransformStyle3DEnum.TransformStyle3DFlat; end
function ComputedStyle.initialBackfaceVisibility() return ComputedStyleConstants.BackfaceVisibilityEnum.BackfaceVisibilityVisible; end
function ComputedStyle.initialTextEmphasisMark() return TextEmphasisMarkEnum.TextEmphasisMarkNone; end
function ComputedStyle.initialLineBoxContain() return mathlib.bit.bor(mathlib.bit.bor(LineBoxContainEnum.LineBoxContainBlock, LineBoxContainEnum.LineBoxContainInline), LineBoxContainEnum.LineBoxContainReplaced); end

function ComputedStyle.initialFlowThread() return ""; end

function ComputedStyle.InitialBorderRadius() end;

-- inherit
local InheritedFlags = {};
InheritedFlags.__index = InheritedFlags;

function InheritedFlags:new(other)
	local o = {};

	if(other) then
		commonlib.mincopy(o, other);
	else
		o._empty_cells = ComputedStyle.initialEmptyCells();
		o._caption_side = ComputedStyle.initialCaptionSide();
		o._list_style_type = ComputedStyle.initialListStyleType();
		o._list_style_position = ComputedStyle.initialListStylePosition();
		o._visibility = ComputedStyle.initialVisibility();
		o._text_align = ComputedStyle.initialTextAlign();
		o._text_transform = ComputedStyle.initialTextTransform();
		o._text_decorations = ComputedStyle.initialTextDecoration();
		o._cursor_style = ComputedStyle.initialCursor();
		o._direction = ComputedStyle.initialDirection();
		o._border_collapse = ComputedStyle.initialBorderCollapse();
		o._white_space = ComputedStyle.initialWhiteSpace();
		o.m_rtlOrdering = ComputedStyle.initialRTLOrdering();
		o._box_direction = ComputedStyle.initialBoxDirection();
		o._force_backgrounds_to_white = false;
		o._pointerEvents = ComputedStyle.initialPointerEvents();
		o._insideLink = ComputedStyleConstants.InsideLinkEnum.NotInsideLink;
		o.m_writingMode = ComputedStyle.initialWritingMode();
	end

	setmetatable(o, self);
	return o;
end

function InheritedFlags.__eq(a, b)
	return (a._empty_cells == b._empty_cells)
                and (a._caption_side == b._caption_side)
                and (a._list_style_type == b._list_style_type)
                and (a._list_style_position == b._list_style_position)
                and (a._visibility == b._visibility)
                and (a._text_align == b._text_align)
                and (a._text_transform == b._text_transform)
                and (a._text_decorations == b._text_decorations)
                and (a._cursor_style == b._cursor_style)
                and (a._direction == b._direction)
                and (a._border_collapse == b._border_collapse)
                and (a._white_space == b._white_space)
                and (a._box_direction == b._box_direction)
                and (a.m_rtlOrdering == b.m_rtlOrdering)
                and (a._force_backgrounds_to_white == b._force_backgrounds_to_white)
                and (a._pointerEvents == b._pointerEvents)
                and (a._insideLink == b._insideLink)
                and (a.m_writingMode == b.m_writingMode);
end

function InheritedFlags:clone()
	return InheritedFlags:new(self);
end

-- don't inherit
local NonInheritedFlags = {};
NonInheritedFlags.__index = NonInheritedFlags;

function NonInheritedFlags:new(other)
	local o = {};

	if(other) then
		commonlib.mincopy(o, other);
	else
		o._effectiveDisplay = ComputedStyle.initialDisplay();
		o._originalDisplay = ComputedStyle.initialDisplay();
		o._overflowX = ComputedStyle.initialOverflowX();
		o._overflowY = ComputedStyle.initialOverflowY();
		o._vertical_align = ComputedStyle.initialVerticalAlign();
		o._clear = ComputedStyle.initialClear();
		o._position = ComputedStyle.initialPosition();
		o._floating = ComputedStyle.initialFloating();
		o._table_layout = ComputedStyle.initialTableLayout();
		o._page_break_before = ComputedStyle.initialPageBreak();
		o._page_break_after = ComputedStyle.initialPageBreak();
		o._page_break_inside = ComputedStyle.initialPageBreak();
		o._styleType = ComputedStyleConstants.PseudoIdEnum.NOPSEUDO;
		o._affectedByHover = false;
		o._affectedByActive = false;
		o._affectedByDrag = false;
		o._pseudoBits = 0;
		o._unicodeBidi = ComputedStyle.initialUnicodeBidi();
		o._isLink = false;
	end

	setmetatable(o, self);
	return o;
end

function NonInheritedFlags.__eq(a, b)
	 return a._effectiveDisplay == b._effectiveDisplay
                and a._originalDisplay == b._originalDisplay
                and a._overflowX == b._overflowX
                and a._overflowY == b._overflowY
                and a._vertical_align == b._vertical_align
                and a._clear == b._clear
                and a._position == b._position
                and a._floating == b._floating
                and a._table_layout == b._table_layout
                and a._page_break_before == b._page_break_before
                and a._page_break_after == b._page_break_after
                and a._page_break_inside == b._page_break_inside
                and a._styleType == b._styleType
                and a._affectedByHover == b._affectedByHover
                and a._affectedByActive == b._affectedByActive
                and a._affectedByDrag == b._affectedByDrag
                and a._pseudoBits == b._pseudoBits
                and a._unicodeBidi == b._unicodeBidi
                and a._isLink == b._isLink;
end

function NonInheritedFlags:clone()
	return NonInheritedFlags:new(self);
end


NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleRareNonInheritedData.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleBoxData.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleVisualData.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleBackgroundData.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleSurroundData.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleRareInheritedData.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleInheritedData.lua");
local StyleInheritedData = commonlib.gettable("System.Windows.mcml.style.StyleInheritedData");
local StyleRareInheritedData = commonlib.gettable("System.Windows.mcml.style.StyleRareInheritedData");
local StyleSurroundData = commonlib.gettable("System.Windows.mcml.style.StyleSurroundData");
local StyleBackgroundData = commonlib.gettable("System.Windows.mcml.style.StyleBackgroundData");
local StyleVisualData = commonlib.gettable("System.Windows.mcml.style.StyleVisualData");
local StyleBoxData = commonlib.gettable("System.Windows.mcml.style.StyleBoxData");
local StyleRareNonInheritedData = commonlib.gettable("System.Windows.mcml.style.StyleRareNonInheritedData");

function ComputedStyle:new(box, visual, background, surround, rareNonInheritedData, rareInheritedData, inherited, inherited_flags, noninherited_flags)
	local o = {};

	-- The following bitfield is 32-bits long, which optimizes padding with the
	-- int refCount in the base class. Beware when adding more bits.
	o.m_affectedByUncommonAttributeSelectors = false;
	o.m_unique = false;

	-- Bits for dynamic child matching.
	o.m_affectedByEmpty = false;
	o.m_emptyState = false;

	-- We optimize for :first-child and :last-child.  The other positional child selectors like nth-child or
	-- *-child-of-type, we will just give up and re-evaluate whenever children change at all.
	o.m_childrenAffectedByFirstChildRules = false;
	o.m_childrenAffectedByLastChildRules = false;
	o.m_childrenAffectedByForwardPositionalRules = false;
	o.m_childrenAffectedByBackwardPositionalRules = false;
	o.m_firstChildState = false;
	o.m_lastChildState = false;
	o.m_affectedByDirectAdjacentRules = false;
	o.m_childIndex = 0; -- Plenty of bits to cache an index.


	-- non-inherited attributes
    o.m_box = box or StyleBoxData:new();
    o.visual = visual or StyleVisualData:new();
    o.m_background = background or StyleBackgroundData:new();
    o.surround = surround or StyleSurroundData:new();
    o.rareNonInheritedData = rareNonInheritedData or StyleRareNonInheritedData:new();

    -- inherited attributes
    o.rareInheritedData = rareInheritedData or StyleRareInheritedData:new();
    o.inherited = inherited or StyleInheritedData:new();

    -- list of associated pseudo styles
    --o.m_cachedPseudoStyles = nil;

	--o.m_svgStyle = nil;

	o.inherited_flags = inherited_flags or InheritedFlags:new();

	o.noninherited_flags = noninherited_flags or NonInheritedFlags:new();

	setmetatable(o, self);
	return o;
end

function ComputedStyle:clone()
	local box = self.m_box:clone();
	local visual = self.visual:clone();
	local background = self.m_background:clone();
	local surround = self.surround:clone();
	local rareNonInheritedData = self.rareNonInheritedData:clone();
	local rareInheritedData = self.rareInheritedData:clone();
	local inherited = self.inherited:clone();
	local inherited_flags = self.inherited_flags:clone();
	local noninherited_flags = self.noninherited_flags:clone();
	return ComputedStyle:new(box, visual, background, surround, rareNonInheritedData, rareInheritedData, inherited, inherited_flags, noninherited_flags);
end

function ComputedStyle.__eq(a, b)
	return a.inherited_flags == b.inherited_flags
		and a.noninherited_flags == b.noninherited_flags
		and a.m_box == b.m_box
		and a.visual == b.visual
		and a.m_background == b.m_background
		and a.surround == b.surround
		and a.rareNonInheritedData == b.rareNonInheritedData
		and a.rareInheritedData == b.rareInheritedData
		and a.inherited == b.inherited;
end

--void RenderStyle::inheritFrom(const RenderStyle* inheritParent)
function ComputedStyle:InheritFrom(inheritParent)
    self.rareInheritedData = inheritParent.rareInheritedData:clone();
    self.inherited = inheritParent.inherited:clone();
    self.inherited_flags = inheritParent.inherited_flags:clone();
end

function ComputedStyle:InheritUnicodeBidiFrom(parent) 
	self.noninherited_flags._unicodeBidi = parent.noninherited_flags._unicodeBidi;
end

--static bool positionedObjectMoved(const LengthBox& a, const LengthBox& b)
local function positionedObjectMoved(a, b)
    -- If any unit types are different, then we can't guarantee
    -- that this was just a movement.
    if (a:Left():Type() ~= b:Left():Type()
        or a:Right():Type() ~= b:Right():Type()
        or a:Top():Type() ~= b:Top():Type()
        or a:Bottom():Type() ~= b:Bottom():Type()) then
        return false;
	end

    -- Only one unit can be non-auto in the horizontal direction and
    -- in the vertical direction.  Otherwise the adjustment of values
    -- is changing the size of the box.
    if (not a:Left():IsIntrinsicOrAuto() and not a:Right():IsIntrinsicOrAuto()) then
        return false;
	end
    if (not a:Top():IsIntrinsicOrAuto() and not a:Bottom():IsIntrinsicOrAuto()) then
        return false;
	end

    -- One of the units is fixed or percent in both directions and stayed
    -- that way in the new style.  Therefore all we are doing is moving.
    return true;
end

--StyleDifference RenderStyle::diff(const RenderStyle* other, unsigned& changedContextSensitiveProperties) const
function ComputedStyle:Diff(other, changedContextSensitiveProperties)
	changedContextSensitiveProperties = ComputedStyleConstants.StyleDifferenceContextSensitivePropertyEnum.ContextSensitivePropertyNone;

	if (self.m_box:Width() ~= other.m_box:Width()
			or self.m_box:MinWidth() ~= other.m_box:MinWidth()
			or self.m_box:MaxWidth() ~= other.m_box:MaxWidth()
			or self.m_box:Height() ~= other.m_box:Height()
			or self.m_box:MinHeight() ~= other.m_box:MinHeight()
			or self.m_box:MaxHeight() ~= other.m_box:MaxHeight()) then
        return StyleDifferenceEnum.StyleDifferenceLayout;
	end

	if (self.m_box:VerticalAlign() ~= other.m_box:VerticalAlign() or self.noninherited_flags._vertical_align ~= other.noninherited_flags._vertical_align) then
        return StyleDifferenceEnum.StyleDifferenceLayout;
	end

	if (self.m_box:BoxSizing() ~= other.m_box:BoxSizing()) then
        return StyleDifferenceEnum.StyleDifferenceLayout;
	end
	if ((self.surround.margin) ~= (other.surround.margin)) then
        return StyleDifferenceEnum.StyleDifferenceLayout;
	end

    if (self.surround.padding ~= other.surround.padding) then
        return StyleDifferenceEnum.StyleDifferenceLayout;
	end

--	if (self.rareNonInheritedData ~= other.rareNonInheritedData) then
--        if (rareNonInheritedData->m_appearance ~= other->rareNonInheritedData->m_appearance 
--            or rareNonInheritedData->marginBeforeCollapse ~= other->rareNonInheritedData->marginBeforeCollapse
--            or rareNonInheritedData->marginAfterCollapse ~= other->rareNonInheritedData->marginAfterCollapse
--            or rareNonInheritedData->lineClamp ~= other->rareNonInheritedData->lineClamp
--            or rareNonInheritedData->textOverflow ~= other->rareNonInheritedData->textOverflow)
--            return StyleDifferenceEnum.StyleDifferenceLayout;
--
--        if (rareNonInheritedData->m_regionOverflow ~= other->rareNonInheritedData->m_regionOverflow)
--            return StyleDifferenceEnum.StyleDifferenceLayout;
--
--        if (rareNonInheritedData->m_deprecatedFlexibleBox.get() ~= other->rareNonInheritedData->m_deprecatedFlexibleBox.get()
--            && *rareNonInheritedData->m_deprecatedFlexibleBox.get() ~= *other->rareNonInheritedData->m_deprecatedFlexibleBox.get())
--            return StyleDifferenceEnum.StyleDifferenceLayout;
--
--#if ENABLE(CSS3_FLEXBOX)
--        if (rareNonInheritedData->m_flexibleBox.get() ~= other->rareNonInheritedData->m_flexibleBox.get()
--            && *rareNonInheritedData->m_flexibleBox.get() ~= *other->rareNonInheritedData->m_flexibleBox.get())
--            return StyleDifferenceEnum.StyleDifferenceLayout;
--#endif
--
--        -- FIXME: We should add an optimized form of layout that just recomputes visual overflow.
--        if (!rareNonInheritedData->shadowDataEquivalent(*other->rareNonInheritedData.get()))
--            return StyleDifferenceEnum.StyleDifferenceLayout;
--
--        if (!rareNonInheritedData->reflectionDataEquivalent(*other->rareNonInheritedData.get()))
--            return StyleDifferenceEnum.StyleDifferenceLayout;
--
--        if (rareNonInheritedData->m_multiCol.get() ~= other->rareNonInheritedData->m_multiCol.get()
--            && *rareNonInheritedData->m_multiCol.get() ~= *other->rareNonInheritedData->m_multiCol.get())
--            return StyleDifferenceEnum.StyleDifferenceLayout;
--
--        if (rareNonInheritedData->m_transform.get() ~= other->rareNonInheritedData->m_transform.get()
--            && *rareNonInheritedData->m_transform.get() ~= *other->rareNonInheritedData->m_transform.get()) then
--#if USE(ACCELERATED_COMPOSITING)
--            changedContextSensitiveProperties |= ContextSensitivePropertyTransform;
--            -- Don't return; keep looking for another change
--#else
--            return StyleDifferenceEnum.StyleDifferenceLayout;
--#endif
--        end
--
--#if !USE(ACCELERATED_COMPOSITING)
--        if (rareNonInheritedData.get() ~= other->rareNonInheritedData.get()) then
--            if (rareNonInheritedData->m_transformStyle3D ~= other->rareNonInheritedData->m_transformStyle3D
--                or rareNonInheritedData->m_backfaceVisibility ~= other->rareNonInheritedData->m_backfaceVisibility
--                or rareNonInheritedData->m_perspective ~= other->rareNonInheritedData->m_perspective
--                or rareNonInheritedData->m_perspectiveOriginX ~= other->rareNonInheritedData->m_perspectiveOriginX
--                or rareNonInheritedData->m_perspectiveOriginY ~= other->rareNonInheritedData->m_perspectiveOriginY)
--                return StyleDifferenceEnum.StyleDifferenceLayout;
--        end
--#endif
--
--#if ENABLE(DASHBOARD_SUPPORT)
--        -- If regions change, trigger a relayout to re-calc regions.
--        if (rareNonInheritedData->m_dashboardRegions ~= other->rareNonInheritedData->m_dashboardRegions)
--            return StyleDifferenceEnum.StyleDifferenceLayout;
--#endif
--    end

    if (self.rareInheritedData ~= other.rareInheritedData) then
        --if (self.rareInheritedData.highlight ~= other.rareInheritedData.highlight
        if (self.rareInheritedData.indent ~= other.rareInheritedData.indent
            --or self.rareInheritedData.m_effectiveZoom ~= other.rareInheritedData.m_effectiveZoom
            or self.rareInheritedData.textSizeAdjust ~= other.rareInheritedData.textSizeAdjust
            or self.rareInheritedData.wordBreak ~= other.rareInheritedData.wordBreak
            or self.rareInheritedData.wordWrap ~= other.rareInheritedData.wordWrap
            or self.rareInheritedData.nbspMode ~= other.rareInheritedData.nbspMode
            or self.rareInheritedData.khtmlLineBreak ~= other.rareInheritedData.khtmlLineBreak
            or self.rareInheritedData.textSecurity ~= other.rareInheritedData.textSecurity
            or self.rareInheritedData.hyphens ~= other.rareInheritedData.hyphens
            --or self.rareInheritedData.hyphenationLimitBefore ~= other.rareInheritedData.hyphenationLimitBefore
            --or self.rareInheritedData.hyphenationLimitAfter ~= other.rareInheritedData.hyphenationLimitAfter
            --or self.rareInheritedData.hyphenationString ~= other.rareInheritedData.hyphenationString
            --or self.rareInheritedData.locale ~= other.rareInheritedData.locale
            or self.rareInheritedData.textEmphasisMark ~= other.rareInheritedData.textEmphasisMark
            or self.rareInheritedData.textEmphasisPosition ~= other.rareInheritedData.textEmphasisPosition) then
            --or self.rareInheritedData.textEmphasisCustomMark ~= other.rareInheritedData.textEmphasisCustomMark) then
            --or self.rareInheritedData.m_lineBoxContain ~= other.rareInheritedData.m_lineBoxContain) then
            return StyleDifferenceEnum.StyleDifferenceLayout;
		end

        if (not self.rareInheritedData:ShadowDataEquivalent(other.rareInheritedData)) then
            return StyleDifferenceEnum.StyleDifferenceLayout;
		end

--        if (textStrokeWidth() ~= other->textStrokeWidth())
--            return StyleDifferenceEnum.StyleDifferenceLayout;
    end

    if (self.inherited.line_height ~= other.inherited.line_height
        -- or inherited.list_style_image ~= other.inherited.list_style_image
        or self.inherited.font ~= other.inherited.font
        or self.inherited.horizontal_border_spacing ~= other.inherited.horizontal_border_spacing
        or self.inherited.vertical_border_spacing ~= other.inherited.vertical_border_spacing
        or self.inherited_flags._box_direction ~= other.inherited_flags._box_direction
        or self.inherited_flags.m_rtlOrdering ~= other.inherited_flags.m_rtlOrdering
        or self.noninherited_flags._position ~= other.noninherited_flags._position
        or self.noninherited_flags._floating ~= other.noninherited_flags._floating
        or self.noninherited_flags._originalDisplay ~= other.noninherited_flags._originalDisplay) then
        return StyleDifferenceEnum.StyleDifferenceLayout;
	end


    if (self.noninherited_flags._effectiveDisplay >= ComputedStyleConstants.DisplayEnum.TABLE) then
        if (self.inherited_flags._border_collapse ~= other.inherited_flags._border_collapse
            or self.inherited_flags._empty_cells ~= other.inherited_flags._empty_cells
            or self.inherited_flags._caption_side ~= other.inherited_flags._caption_side
            or self.noninherited_flags._table_layout ~= other.noninherited_flags._table_layout) then
            return StyleDifferenceEnum.StyleDifferenceLayout;
		end

        -- In the collapsing border model, 'hidden' suppresses other borders, while 'none'
        -- does not, so these style differences can be width differences.
		local BHIDDEN = ComputedStyleConstants.BorderStyleEnum.BHIDDEN;
		local BNONE = ComputedStyleConstants.BorderStyleEnum.BNONE;
        if (self.inherited_flags._border_collapse ~= ComputedStyleConstants.BorderCollapseEnum.BSEPARATE
            and ((self:BorderTopStyle() == BHIDDEN and other:BorderTopStyle() == BNONE)
                or (self:BorderTopStyle() == BNONE and other:BorderTopStyle() == BHIDDEN)
                or (self:BorderBottomStyle() == BHIDDEN and other:BorderBottomStyle() == BNONE)
                or (self:BorderBottomStyle() == BNONE and other:BorderBottomStyle() == BHIDDEN)
                or (self:BorderLeftStyle() == BHIDDEN and other:BorderLeftStyle() == BNONE)
                or (self:BorderLeftStyle() == BNONE and other:BorderLeftStyle() == BHIDDEN)
                or (self:BorderRightStyle() == BHIDDEN and other:BorderRightStyle() == BNONE)
                or (self:BorderRightStyle() == BNONE and other:BorderRightStyle() == BHIDDEN))) then
            return StyleDifferenceEnum.StyleDifferenceLayout;
		end
    end

--    if (noninherited_flags._effectiveDisplay == LIST_ITEM) then
--        if (inherited_flags._list_style_type ~= other->inherited_flags._list_style_type
--            or inherited_flags._list_style_position ~= other->inherited_flags._list_style_position)
--            return StyleDifferenceEnum.StyleDifferenceLayout;
--    end

    if (self.inherited_flags._text_align ~= other.inherited_flags._text_align
        or self.inherited_flags._text_transform ~= other.inherited_flags._text_transform
        or self.inherited_flags._direction ~= other.inherited_flags._direction
        or self.inherited_flags._white_space ~= other.inherited_flags._white_space
        or self.noninherited_flags._clear ~= other.noninherited_flags._clear
        or self.noninherited_flags._unicodeBidi ~= other.noninherited_flags._unicodeBidi) then
        return StyleDifferenceEnum.StyleDifferenceLayout;
	end

    -- Check block flow direction.
    if (self.inherited_flags.m_writingMode ~= other.inherited_flags.m_writingMode) then
        return StyleDifferenceEnum.StyleDifferenceLayout;
	end

    -- Check text combine mode.
    if (self.rareNonInheritedData.m_textCombine ~= other.rareNonInheritedData.m_textCombine) then
        return StyleDifferenceEnum.StyleDifferenceLayout;
	end

    -- Overflow returns a layout hint.
    if (self.noninherited_flags._overflowX ~= other.noninherited_flags._overflowX
        or self.noninherited_flags._overflowY ~= other.noninherited_flags._overflowY) then
        return StyleDifferenceEnum.StyleDifferenceLayout;
	end

    -- If our border widths change, then we need to layout.  Other changes to borders
    -- only necessitate a repaint.
    if (self:BorderLeftWidth() ~= other:BorderLeftWidth()
        or self:BorderTopWidth() ~= other:BorderTopWidth()
        or self:BorderBottomWidth() ~= other:BorderBottomWidth()
        or self:BorderRightWidth() ~= other:BorderRightWidth()) then
        return StyleDifferenceEnum.StyleDifferenceLayout;
	end

--    -- If the counter directives change, trigger a relayout to re-calculate counter values and rebuild the counter node tree.
--    const CounterDirectiveMap* mapA = rareNonInheritedData->m_counterDirectives.get();
--    const CounterDirectiveMap* mapB = other->rareNonInheritedData->m_counterDirectives.get();
--    if (!(mapA == mapB or (mapA && mapB && *mapA == *mapB)))
--        return StyleDifferenceEnum.StyleDifferenceLayout;
--    if (rareNonInheritedData->m_counterIncrement ~= other->rareNonInheritedData->m_counterIncrement
--        or rareNonInheritedData->m_counterReset ~= other->rareNonInheritedData->m_counterReset)
--        return StyleDifferenceEnum.StyleDifferenceLayout;
	local COLLAPSE = VisibilityEnum.COLLAPSE;
    if ((self:Visibility() == COLLAPSE) ~= (other:Visibility() == COLLAPSE)) then
        return StyleDifferenceEnum.StyleDifferenceLayout;
	end

    if ((self.rareNonInheritedData.opacity == 1 and other.rareNonInheritedData.opacity < 1)
        or (self.rareNonInheritedData.opacity < 1 and other.rareNonInheritedData.opacity == 1)) then
        -- FIXME: We would like to use SimplifiedLayout here, but we can't quite do that yet.
        -- We need to make sure SimplifiedLayout can operate correctly on RenderInlines (we will need
        -- to add a selfNeedsSimplifiedLayout bit in order to not get confused and taint every line).
        -- In addition we need to solve the floating object issue when layers come and go. Right now
        -- a full layout is necessary to keep floating object lists sane.
        return StyleDifferenceEnum.StyleDifferenceLayout;
    end

--#if ENABLE(SVG)
--    -- SVGRenderStyle::diff() might have returned StyleDifferenceRepaint, eg. if fill changes.
--    -- If eg. the font-size changed at the same time, we're not allowed to return StyleDifferenceRepaint,
--    -- but have to return StyleDifferenceLayout, that's why  this if branch comes after all branches
--    -- that are relevant for SVG and might return StyleDifferenceLayout.
--    if (svgChange ~= StyleDifferenceEqual)
--        return svgChange;
--#endif

    -- Make sure these left/top/right/bottom checks stay below all layout checks and above
    -- all visible checks.
    if (self:Position() ~= PositionEnum.StaticPosition) then
        if (self.surround.offset ~= other.surround.offset) then
             -- Optimize for the case where a positioned layer is moving but not changing size.
            if (self:Position() == PositionEnum.AbsolutePosition and positionedObjectMoved(self.surround.offset, other.surround.offset)) then
                return StyleDifferenceEnum.StyleDifferenceLayoutPositionedMovementOnly;
			end

            -- FIXME: We would like to use SimplifiedLayout for relative positioning, but we can't quite do that yet.
            -- We need to make sure SimplifiedLayout can operate correctly on RenderInlines (we will need
            -- to add a selfNeedsSimplifiedLayout bit in order to not get confused and taint every line).
            return StyleDifferenceEnum.StyleDifferenceLayout;
        elseif (self.m_box:ZIndex() ~= other.m_box:ZIndex() or self.m_box:HasAutoZIndex() ~= other.m_box:HasAutoZIndex()
                 or self.visual.clip ~= other.visual.clip or self.visual.hasClip ~= other.visual.hasClip) then
            return StyleDifferenceEnum.StyleDifferenceRepaintLayer;
		end
    end

--    if (rareNonInheritedData->opacity ~= other->rareNonInheritedData->opacity) then
--#if USE(ACCELERATED_COMPOSITING)
--        changedContextSensitiveProperties |= ContextSensitivePropertyOpacity;
--        -- Don't return; keep looking for another change.
--#else
--        return StyleDifferenceEnum.StyleDifferenceRepaintLayer;
--#endif
--    end

--    if (rareNonInheritedData->m_mask ~= other->rareNonInheritedData->m_mask
--        or rareNonInheritedData->m_maskBoxImage ~= other->rareNonInheritedData->m_maskBoxImage)
--        return StyleDifferenceEnum.StyleDifferenceRepaintLayer;
    if (self.inherited.color ~= other.inherited.color
        or self.inherited_flags._visibility ~= other.inherited_flags._visibility
        or self.inherited_flags._text_decorations ~= other.inherited_flags._text_decorations
        or self.inherited_flags._force_backgrounds_to_white ~= other.inherited_flags._force_backgrounds_to_white
        or self.inherited_flags._insideLink ~= other.inherited_flags._insideLink
        or self.surround.border ~= other.surround.border
        or self.m_background ~= other.m_background
        or self.visual.textDecoration ~= other.visual.textDecoration
        or self.rareInheritedData.userModify ~= other.rareInheritedData.userModify
        or self.rareInheritedData.userSelect ~= other.rareInheritedData.userSelect
        or self.rareNonInheritedData.userDrag ~= other.rareNonInheritedData.userDrag
        or self.rareNonInheritedData.m_borderFit ~= other.rareNonInheritedData.m_borderFit
        --or self.rareInheritedData.textFillColor ~= other.rareInheritedData.textFillColor
        --or self.rareInheritedData.textStrokeColor ~= other.rareInheritedData.textStrokeColor
        --or self.rareInheritedData.textEmphasisColor ~= other.rareInheritedData.textEmphasisColor
        or self.rareInheritedData.textEmphasisFill ~= other.rareInheritedData.textEmphasisFill) then
        --or self.rareInheritedData.m_imageRendering ~= other.rareInheritedData.m_imageRendering)
        return StyleDifferenceEnum.StyleDifferenceRepaint;
	end
        
        -- FIXME: The current spec is being reworked to remove dependencies between exclusions and affected 
        -- content. There's a proposal to use floats instead. In that case, wrap-shape should actually relayout 
        -- the parent container. For sure, I will have to revisit this code, but for now I've added this in order 
        -- to avoid having diff() == StyleDifferenceEqual where wrap-shapes actually differ.
        -- Tracking bug: https://bugs.webkit.org/show_bug.cgi?id=62991
--        if (rareNonInheritedData.m_wrapShape ~= other.rareNonInheritedData.m_wrapShape)
--            return StyleDifferenceEnum.StyleDifferenceRepaint;

--#if USE(ACCELERATED_COMPOSITING)
--    if (rareNonInheritedData.get() ~= other.rareNonInheritedData.get()) then
--        if (rareNonInheritedData.m_transformStyle3D ~= other.rareNonInheritedData.m_transformStyle3D
--            or rareNonInheritedData.m_backfaceVisibility ~= other.rareNonInheritedData.m_backfaceVisibility
--            or rareNonInheritedData.m_perspective ~= other.rareNonInheritedData.m_perspective
--            or rareNonInheritedData.m_perspectiveOriginX ~= other.rareNonInheritedData.m_perspectiveOriginX
--            or rareNonInheritedData.m_perspectiveOriginY ~= other.rareNonInheritedData.m_perspectiveOriginY)
--            return StyleDifferenceEnum.StyleDifferenceRecompositeLayer;
--    end
--#endif

    -- Cursors are not checked, since they will be set appropriately in response to mouse events,
    -- so they don't need to cause any repaint or layout.

    -- Animations don't need to be checked either.  We always set the new style on the RenderObject, so we will get a chance to fire off
    -- the resulting transition properly.
    return StyleDifferenceEnum.StyleDifferenceEqual;
end

function ComputedStyle:IsFloating() return self.noninherited_flags._floating ~= FloatEnum.NoFloat; end
function ComputedStyle:HasMargin() return self.surround.margin:NonZero(); end
function ComputedStyle:HasBorder() return self.surround.border:HasBorder(); end
function ComputedStyle:HasPadding() return self.surround.padding:NonZero(); end
function ComputedStyle:HasOffset() return self.surround.offset:NonZero(); end
function ComputedStyle:RtlOrdering() return self.inherited_flags.m_rtlOrdering; end
function ComputedStyle:SetRTLOrdering(o) self.inherited_flags.m_rtlOrdering = o; end

-- attribute getter methods
function ComputedStyle:Display() return self.noninherited_flags._effectiveDisplay; end
function ComputedStyle:OriginalDisplay() return self.noninherited_flags._originalDisplay; end
function ComputedStyle:Position() return self.noninherited_flags._position; end
function ComputedStyle:Floating() return self.noninherited_flags._floating; end
function ComputedStyle:OverflowX() return self.noninherited_flags._overflowX; end
function ComputedStyle:OverflowY() return self.noninherited_flags._overflowY; end
function ComputedStyle:Visibility() return self.inherited_flags._visibility; end
function ComputedStyle:VerticalAlign() return self.noninherited_flags._vertical_align; end
function ComputedStyle:VerticalAlignLength() return self.m_box:VerticalAlign(); end
function ComputedStyle:ClipLeft() return self.visual.clip:Left(); end
function ComputedStyle:ClipRight() return self.visual.clip:Right(); end
function ComputedStyle:ClipTop() return self.visual.clip:Top(); end
function ComputedStyle:ClipBottom() return self.visual.clip:Bottom(); end
function ComputedStyle:Clip() return self.visual.clip; end
function ComputedStyle:HasClip() return self.visual.hasClip; end
function ComputedStyle:UnicodeBidi() return self.noninherited_flags._unicodeBidi; end
function ComputedStyle:Clear() return self.noninherited_flags._clear; end
function ComputedStyle:Font() return self.inherited.font; end
function ComputedStyle:FontMetrics() return self.inherited.font:FontMetrics(); end
function ComputedStyle:FontSize() return self.inherited.font.size; end
function ComputedStyle:FontBold() return self.inherited.font.bold; end
function ComputedStyle:FontFamily() return self.inherited.font.family; end
function ComputedStyle:TextIndent() return self.rareInheritedData.indent; end
function ComputedStyle:TextAlign() return self.inherited_flags._text_align; end
function ComputedStyle:WordSpacing() return self.inherited.font:WordSpacing(); end
function ComputedStyle:LetterSpacing() return self.inherited.font:LetterSpacing(); end
function ComputedStyle:Direction() return self.inherited_flags._direction; end
function ComputedStyle:IsLeftToRightDirection() return self:Direction() == TextDirectionEnum.LTR; end
function ComputedStyle:LineHeight() return self.inherited.line_height; end
function ComputedStyle:WhiteSpace() return self.inherited_flags._white_space; end
function ComputedStyle:TextShadow() return self.rareInheritedData.textShadow; end

function ComputedStyle:OutlineOffset()
    if (self.m_background:Outline():Style() == ComputedStyleConstants.BorderStyleEnum.BNONE) then
        return 0;
	end
    return self.m_background:Outline():Offset();
end

function ComputedStyle:Opacity() return self.rareNonInheritedData.opacity; end
function ComputedStyle:Appearance() return self.rareNonInheritedData.m_appearance; end
function ComputedStyle:BoxAlign() return self.rareNonInheritedData.m_deprecatedFlexibleBox.align; end
function ComputedStyle:BoxDirection() return self.inherited_flags._box_direction; end
function ComputedStyle:BoxFlex() return self.rareNonInheritedData.m_deprecatedFlexibleBox.flex; end
function ComputedStyle:BoxFlexGroup() return self.rareNonInheritedData.m_deprecatedFlexibleBox.flex_group; end
function ComputedStyle:BoxLines() return self.rareNonInheritedData.m_deprecatedFlexibleBox.lines; end
function ComputedStyle:BoxOrdinalGroup() return self.rareNonInheritedData.m_deprecatedFlexibleBox.ordinal_group; end
function ComputedStyle:BoxOrient() return self.rareNonInheritedData.m_deprecatedFlexibleBox.orient; end
function ComputedStyle:BoxPack() return self.rareNonInheritedData.m_deprecatedFlexibleBox.pack; end

function ComputedStyle:BoxShadow()	return self.rareNonInheritedData.m_boxShadow; end

function ComputedStyle:BoxSizing() return self.m_box:BoxSizing(); end
function ComputedStyle:UserModify() return self.rareInheritedData.userModify; end
function ComputedStyle:UserDrag() return self.rareNonInheritedData.userDrag; end
function ComputedStyle:UserSelect() return self.rareInheritedData.userSelect; end
function ComputedStyle:TextOverflow() return self.rareNonInheritedData.textOverflow; end
function ComputedStyle:MarginBeforeCollapse() return self.rareNonInheritedData.marginBeforeCollapse; end
function ComputedStyle:MarginAfterCollapse() return self.rareNonInheritedData.marginAfterCollapse; end
function ComputedStyle:WordBreak() return self.rareInheritedData.wordBreak; end
function ComputedStyle:WordWrap() return self.rareInheritedData.wordWrap; end
function ComputedStyle:CaretColor() return self.rareInheritedData.caretColor; end
function ComputedStyle:NbspMode() return self.rareInheritedData.nbspMode; end
function ComputedStyle:KhtmlLineBreak() return self.rareInheritedData.khtmlLineBreak; end
function ComputedStyle:MatchNearestMailBlockquoteColor() return self.rareNonInheritedData.matchNearestMailBlockquoteColor; end
function ComputedStyle:Hyphens() return self.rareInheritedData.hyphens; end
function ComputedStyle:BorderFit() return self.rareNonInheritedData.m_borderFit; end
function ComputedStyle:TextCombine() return self.rareNonInheritedData.m_textCombine; end
function ComputedStyle:HasTextCombine() return self:TextCombine() ~= ComputedStyleConstants.TextCombineEnum.TextCombineNone; end
function ComputedStyle:FlowThread() return self.rareNonInheritedData.m_flowThread; end
function ComputedStyle:WritingMode() return self.inherited_flags.m_writingMode; end
function ComputedStyle:IsHorizontalWritingMode() return self:WritingMode() == WritingModeEnum.TopToBottomWritingMode or self:WritingMode() == WritingModeEnum.BottomToTopWritingMode; end
function ComputedStyle:IsFlippedLinesWritingMode() return self:WritingMode() == WritingModeEnum.LeftToRightWritingMode or self:WritingMode() == WritingModeEnum.BottomToTopWritingMode; end
function ComputedStyle:IsFlippedBlocksWritingMode() return self:WritingMode() == WritingModeEnum.RightToLeftWritingMode or self:WritingMode() == WritingModeEnum.BottomToTopWritingMode; end
function ComputedStyle:AutoWrap(ws)
	ws = ws or self:WhiteSpace();
	return ws ~= WhiteSpaceEnum.NOWRAP and ws ~= WhiteSpaceEnum.PRE;
end
function ComputedStyle:PreserveNewline(ws)
	ws = ws or self:WhiteSpace();
	return ws ~= WhiteSpaceEnum.NORMAL and ws ~= WhiteSpaceEnum.NOWRAP;
end
function ComputedStyle:CollapseWhiteSpace(ws)
    -- Pre and prewrap do not collapse whitespace.
	ws = ws or self:WhiteSpace();
    return ws ~= WhiteSpaceEnum.PRE and ws ~= WhiteSpaceEnum.PRE_WRAP;
end
function ComputedStyle:BreakOnlyAfterWhiteSpace()
    return self:WhiteSpace() == WhiteSpaceEnum.PRE_WRAP or self:KhtmlLineBreak() == KHTMLLineBreakEnum.AFTER_WHITE_SPACE;
end
function ComputedStyle:BreakWords()
	return self:WordBreak() == WordBreakEnum.BreakWordBreak or self:WordWrap() == WordWrapEnum.BreakWordWrap;
end
function ComputedStyle:IsCollapsibleWhiteSpace(c)
	if(c == " " or c == "\t") then
		return self:CollapseWhiteSpace();
	elseif(c == "\n") then
		return not self:PreserveNewline();
	end
    return false;
end
function ComputedStyle:ComputedLineHeight()
	local lh = self:LineHeight();
	-- Negative value means the line height is not set.  Use the font's built-in spacing.
	if (lh:IsNegative()) then
		return self:FontMetrics():lineSpacing();
		--return math.floor(self:FontSize() * 1.3 + 0.5);
	end

	if (lh:IsPercent()) then
		return lh:CalcMinValue(self:FontSize());
	end

	return lh:Value();
end


function ComputedStyle:Left() return self.surround.offset:Left(); end
function ComputedStyle:Right() return self.surround.offset:Right(); end
function ComputedStyle:Top() return self.surround.offset:Top(); end
function ComputedStyle:Bottom() return self.surround.offset:Bottom(); end

-- Accessors for positioned object edges that take into account writing mode.
function ComputedStyle:LogicalLeft() return if_else(self:IsHorizontalWritingMode() , self:Left() , self:Top()); end
function ComputedStyle:LogicalRight() return if_else(self:IsHorizontalWritingMode() , self:Right() , self:Bottom()); end
function ComputedStyle:LogicalTop() 
	if(self:IsHorizontalWritingMode()) then
		if(self:IsFlippedBlocksWritingMode()) then
			return self:Bottom();
		end
		return self:Top();
	end
	if(self:IsFlippedBlocksWritingMode()) then
		return self:Right();
	end
	return self:Left();
end
function ComputedStyle:LogicalBottom() 
	if(self:IsHorizontalWritingMode()) then
		if(self:IsFlippedBlocksWritingMode()) then
			return self:Top();
		end
		return self:Bottom();
	end
	if(self:IsFlippedBlocksWritingMode()) then
		return self:Left();
	end
	return self:Right();
end
-- Whether or not a positioned element requires normal flow x/y to be computed
-- to determine its position.
function ComputedStyle:HasAutoLeftAndRight() return self:Left():IsAuto() and self:Right():IsAuto(); end
function ComputedStyle:HasAutoTopAndBottom() return self:Top():IsAuto() and self:Bottom():IsAuto(); end
function ComputedStyle:HasStaticInlinePosition(horizontal) return if_else(horizontal , self:HasAutoLeftAndRight() , self:HasAutoTopAndBottom()); end
function ComputedStyle:HasStaticBlockPosition(horizontal) return if_else(horizontal , self:HasAutoTopAndBottom() , self:HasAutoLeftAndRight()); end

function ComputedStyle:Width() return self.m_box:Width(); end
function ComputedStyle:Height() return self.m_box:Height(); end
function ComputedStyle:MinWidth() return self.m_box:MinWidth(); end
function ComputedStyle:MaxWidth() return self.m_box:MaxWidth(); end
function ComputedStyle:MinHeight() return self.m_box:MinHeight(); end
function ComputedStyle:MaxHeight() return self.m_box:MaxHeight(); end
function ComputedStyle:LogicalWidth()
    if (self:IsHorizontalWritingMode()) then
        return self:Width();
	end
    return self:Height();
end
function ComputedStyle:LogicalHeight()
    if (self:IsHorizontalWritingMode()) then
        return self:Height();
	end
    return self:Width();
end
function ComputedStyle:LogicalMinWidth()
    if (self:IsHorizontalWritingMode()) then
        return self:MinWidth();
	end
    return self:MinHeight();
end
function ComputedStyle:LogicalMaxWidth()
    if (self:IsHorizontalWritingMode()) then
        return self:MaxWidth();
	end
    return self:MaxHeight();
end
function ComputedStyle:LogicalMinHeight()
    if (self:IsHorizontalWritingMode()) then
        return self:MinHeight();
	end
    return self:MinWidth();
end
function ComputedStyle:LogicalMaxHeight()
    if (self:IsHorizontalWritingMode()) then
        return self:MaxHeight();
	end
    return self:MaxWidth();
end

function ComputedStyle:MarginTop() return self.surround.margin:Top(); end
function ComputedStyle:MarginBottom() return self.surround.margin:Bottom(); end
function ComputedStyle:MarginLeft() return self.surround.margin:Left(); end
function ComputedStyle:MarginRight() return self.surround.margin:Right(); end
function ComputedStyle:MarginBefore()
    local writingMode = self:WritingMode();
    if (WritingModeEnum.TopToBottomWritingMode) then
        return self:MarginTop();
    elseif (WritingModeEnum.BottomToTopWritingMode) then
        return self:MarginBottom();
    elseif (WritingModeEnum.LeftToRightWritingMode) then
        return self:MarginLeft();
    elseif (WritingModeEnum.RightToLeftWritingMode) then
        return self:MarginRight();
    end
    -- ASSERT_NOT_REACHED();
    return self:MarginTop();
end
function ComputedStyle:MarginAfter()
    local writingMode = self:WritingMode();
    if (WritingModeEnum.TopToBottomWritingMode) then
        return self:MarginBottom();
    elseif (WritingModeEnum.BottomToTopWritingMode) then
        return self:MarginTop();
    elseif (WritingModeEnum.LeftToRightWritingMode) then
        return self:MarginRight();
    elseif (WritingModeEnum.RightToLeftWritingMode) then
        return self:MarginLeft();
    end
    -- ASSERT_NOT_REACHED();
    return self:MarginBottom();
end
function ComputedStyle:MarginBeforeUsing(otherStyle)
    local writingMode = otherStyle:WritingMode();
    if (WritingModeEnum.TopToBottomWritingMode) then
        return self:MarginTop();
    elseif (WritingModeEnum.BottomToTopWritingMode) then
        return self:MarginBottom();
    elseif (WritingModeEnum.LeftToRightWritingMode) then
        return self:MarginLeft();
    elseif (WritingModeEnum.RightToLeftWritingMode) then
        return self:MarginRight();
    end
    -- ASSERT_NOT_REACHED();
    return self:MarginTop();
end
function ComputedStyle:MarginAfterUsing(otherStyle)
    local writingMode = otherStyle:WritingMode();
    if (WritingModeEnum.TopToBottomWritingMode) then
        return self:MarginBottom();
    elseif (WritingModeEnum.BottomToTopWritingMode) then
        return self:MarginTop();
    elseif (WritingModeEnum.LeftToRightWritingMode) then
        return self:MarginRight();
    elseif (WritingModeEnum.RightToLeftWritingMode) then
        return self:MarginLeft();
    end
    -- ASSERT_NOT_REACHED();
    return self:MarginBottom();
end
function ComputedStyle:MarginStart()
    if (self:IsHorizontalWritingMode()) then
        return if_else(self:IsLeftToRightDirection() , self:MarginLeft() , self:MarginRight());
	end
    return if_else(self:IsLeftToRightDirection() , self:MarginTop() , self:MarginBottom());
end
function ComputedStyle:MarginEnd()
    if (self:IsHorizontalWritingMode()) then
        return if_else(self:IsLeftToRightDirection() , self:MarginRight() , self:MarginLeft());
	end
    return if_else(self:IsLeftToRightDirection() , self:MarginBottom() , self:MarginTop());
end   
function ComputedStyle:MarginStartUsing(otherStyle)
    if (otherStyle:IsHorizontalWritingMode()) then
        return if_else(otherStyle:IsLeftToRightDirection() , self:MarginLeft() , self:MarginRight());
	end
    return if_else(otherStyle:IsLeftToRightDirection() , self:MarginTop() , self:MarginBottom());
end
function ComputedStyle:MarginEndUsing(otherStyle)
    if (otherStyle:IsHorizontalWritingMode()) then
        return if_else(otherStyle:IsLeftToRightDirection() , self:MarginRight() , self:MarginLeft());
	end
    return if_else(otherStyle:IsLeftToRightDirection() , self:MarginBottom() , self:MarginTop());
end

function ComputedStyle:PaddingBox() return self.surround.padding; end
function ComputedStyle:PaddingTop() return self.surround.padding:Top(); end
function ComputedStyle:PaddingBottom() return self.surround.padding:Bottom(); end
function ComputedStyle:PaddingLeft() return self.surround.padding:Left(); end
function ComputedStyle:PaddingRight() return self.surround.padding:Right(); end
function ComputedStyle:PaddingBefore()
    local writingMode = self:WritingMode();
    if (WritingModeEnum.TopToBottomWritingMode) then
        return self:PaddingTop();
    elseif (WritingModeEnum.BottomToTopWritingMode) then
        return self:PaddingBottom();
    elseif (WritingModeEnum.LeftToRightWritingMode) then
        return self:PaddingLeft();
    elseif (WritingModeEnum.RightToLeftWritingMode) then
        return self:PaddingRight();
    end
    -- ASSERT_NOT_REACHED();
    return self:PaddingTop();
end
function ComputedStyle:PaddingAfter()
    local writingMode = self:WritingMode();
    if (WritingModeEnum.TopToBottomWritingMode) then
        return self:PaddingBottom();
    elseif (WritingModeEnum.BottomToTopWritingMode) then
        return self:PaddingTop();
    elseif (WritingModeEnum.LeftToRightWritingMode) then
        return self:PaddingRight();
    elseif (WritingModeEnum.RightToLeftWritingMode) then
        return self:PaddingLeft();
    end
    -- ASSERT_NOT_REACHED();
    return self:PaddingBottom();
end
function ComputedStyle:PaddingStart()
    if (self:IsHorizontalWritingMode()) then
        return if_else(self:IsLeftToRightDirection() , self:PaddingLeft() , self:PaddingRight());
	end
    return if_else(self:IsLeftToRightDirection() , self:PaddingTop() , self:PaddingBottom());
end
function ComputedStyle:PaddingEnd()
    if (self:IsHorizontalWritingMode()) then
        return if_else(self:IsLeftToRightDirection() , self:PaddingRight() , self:PaddingLeft());
	end
    return if_else(self:IsLeftToRightDirection() , self:PaddingBottom() , self:PaddingTop());
end

function ComputedStyle:Border()  return self.surround.border; end
function ComputedStyle:BorderLeft()  return self.surround.border:Left(); end
function ComputedStyle:BorderRight()  return self.surround.border:Right(); end
function ComputedStyle:BorderTop()  return self.surround.border:Top(); end
function ComputedStyle:BorderBottom()  return self.surround.border:Bottom(); end
function ComputedStyle:BorderTopLeftRadius()  return self.surround.border:TopLeft(); end
function ComputedStyle:BorderTopRightRadius()  return self.surround.border:TopRight(); end
function ComputedStyle:BorderBottomLeftRadius()  return self.surround.border:BottomLeft(); end
function ComputedStyle:BorderBottomRightRadius()  return self.surround.border:BottomRight(); end
function ComputedStyle:HasBorderRadius()  return self.surround.border:HasBorderRadius(); end
function ComputedStyle:BorderLeftWidth()  return self.surround.border:BorderLeftWidth(); end
function ComputedStyle:BorderLeftStyle()  return self.surround.border:Left():Style(); end
function ComputedStyle:BorderLeftIsTransparent()  return self.surround.border:Left():IsTransparent(); end
function ComputedStyle:BorderRightWidth()  return self.surround.border:BorderRightWidth(); end
function ComputedStyle:BorderRightStyle()  return self.surround.border:Right():Style(); end
function ComputedStyle:BorderRightIsTransparent()  return self.surround.border:Right():IsTransparent(); end
function ComputedStyle:BorderTopWidth()  return self.surround.border:BorderTopWidth(); end
function ComputedStyle:BorderTopStyle()  return self.surround.border:Top():Style(); end
function ComputedStyle:BorderTopIsTransparent()  return self.surround.border:Top():IsTransparent(); end
function ComputedStyle:BorderBottomWidth()  return self.surround.border:BorderBottomWidth(); end
function ComputedStyle:BorderBottomStyle()  return self.surround.border:Bottom():Style(); end
function ComputedStyle:BorderBottomIsTransparent()  return self.surround.border:Bottom():IsTransparent(); end
function ComputedStyle:BorderBefore()
    local writingMode = self:WritingMode();
    if (WritingModeEnum.TopToBottomWritingMode) then
        return self:BorderTop();
    elseif (WritingModeEnum.BottomToTopWritingMode) then
        return self:BorderBottom();
    elseif (WritingModeEnum.LeftToRightWritingMode) then
        return self:BorderLeft();
    elseif (WritingModeEnum.RightToLeftWritingMode) then
        return self:BorderRight();
    end
    -- ASSERT_NOT_REACHED();
    return self:BorderTop();
end
function ComputedStyle:BorderAfter()
    local writingMode = self:WritingMode();
    if (WritingModeEnum.TopToBottomWritingMode) then
        return self:BorderBottom();
    elseif (WritingModeEnum.BottomToTopWritingMode) then
        return self:BorderTop();
    elseif (WritingModeEnum.LeftToRightWritingMode) then
        return self:BorderRight();
    elseif (WritingModeEnum.RightToLeftWritingMode) then
        return self:BorderLeft();
    end
    -- ASSERT_NOT_REACHED();
    return self:BorderBottom();
end
function ComputedStyle:BorderStart()
    if (self:IsHorizontalWritingMode()) then
        return if_else(self:IsLeftToRightDirection() , self:BorderLeft() , self:BorderRight());
	end
    return if_else(self:IsLeftToRightDirection() , self:BorderTop() , self:BorderBottom());
end
function ComputedStyle:BorderEnd()
    if (self:IsHorizontalWritingMode()) then
        return if_else(self:IsLeftToRightDirection() , self:BorderRight() , self:BorderLeft());
	end
    return if_else(self:IsLeftToRightDirection() , self:BorderBottom() , self:BorderTop());
end
function ComputedStyle:BorderBeforeWidth()
    local writingMode = self:WritingMode();
    if (WritingModeEnum.TopToBottomWritingMode) then
        return self:BorderTopWidth();
    elseif (WritingModeEnum.BottomToTopWritingMode) then
        return self:BorderBottomWidth();
    elseif (WritingModeEnum.LeftToRightWritingMode) then
        return self:BorderLeftWidth();
    elseif (WritingModeEnum.RightToLeftWritingMode) then
        return self:BorderRightWidth();
    end
    -- ASSERT_NOT_REACHED();
    return self:BorderTopWidth();
end
function ComputedStyle:BorderAfterWidth()
    local writingMode = self:WritingMode();
    if (WritingModeEnum.TopToBottomWritingMode) then
        return self:BorderBottomWidth();
    elseif (WritingModeEnum.BottomToTopWritingMode) then
        return self:BorderTopWidth();
    elseif (WritingModeEnum.LeftToRightWritingMode) then
        return self:BorderRightWidth();
    elseif (WritingModeEnum.RightToLeftWritingMode) then
        return self:BorderLeftWidth();
    end
    -- ASSERT_NOT_REACHED();
    return self:BorderBottomWidth();
end
function ComputedStyle:BorderStartWidth()
    if (self:IsHorizontalWritingMode()) then
        return if_else(self:IsLeftToRightDirection() , self:BorderLeftWidth() , self:BorderRightWidth());
	end
    return if_else(self:IsLeftToRightDirection() , self:BorderTopWidth() , self:BorderBottomWidth());
end
function ComputedStyle:BorderEndWidth()
    if (self:IsHorizontalWritingMode()) then
        return if_else(self:IsLeftToRightDirection() , self:BorderRightWidth() , self:BorderLeftWidth());
	end
    return if_else(self:IsLeftToRightDirection() , self:BorderBottomWidth() , self:BorderTopWidth());
end

function ComputedStyle:OutlineSize() return math.max(0, self:OutlineWidth() + self:OutlineOffset()); end
function ComputedStyle:OutlineWidth()
	if (self.m_background:Outline():Style() == ComputedStyleConstants.BorderStyleEnum.BNONE) then
		return 0;
	end
	return self.m_background:Outline():Width();
end
function ComputedStyle:HasOutline() return self:OutlineWidth() > 0 and self:OutlineStyle() > ComputedStyleConstants.BorderStyleEnum.BHIDDEN; end
function ComputedStyle:OutlineStyle() return self.m_background:Outline():Style(); end
function ComputedStyle:OutlineStyleIsAuto() return if_else(self.m_background:Outline():IsAuto(), ComputedStyleConstants.OutlineIsAutoEnum.AUTO_ON, ComputedStyleConstants.OutlineIsAutoEnum.AUTO_OFF); end

function ComputedStyle:BorderLeftColor() return self.surround.border:Left():Color(); end
function ComputedStyle:BorderRightColor() return self.surround.border:Right():Color(); end
function ComputedStyle:BorderTopColor() return self.surround.border:Top():Color(); end
function ComputedStyle:BorderBottomColor() return self.surround.border:Bottom():Color(); end
function ComputedStyle:BackgroundColor() return self.m_background:Color(); end
function ComputedStyle:BackgroundImage() return self.m_background:Image(); end
function ComputedStyle:Color() return self.inherited.color; end
function ComputedStyle:ZIndex() return self.m_box:ZIndex(); end
function ComputedStyle:HasAutoZIndex() return self.m_box:HasAutoZIndex(); end
function ComputedStyle:Unique() return self.m_unique; end
function ComputedStyle:HasAutoColumnCount() return self.rareNonInheritedData.m_multiCol.m_autoCount; end
function ComputedStyle:HasAutoColumnWidth() return self.rareNonInheritedData.m_multiCol.m_autoWidth; end
function ComputedStyle:ColumnSpan() return self.rareNonInheritedData.m_multiCol.m_columnSpan; end

function ComputedStyle:FontAscent(baselineType)
	baselineType = baselineType or "AlphabeticBaseline"
	return math.floor(self:FontSize() - self:FontSize() / 2 + 0.5);
end
function ComputedStyle:FontDescent(baselineType)
	baselineType = baselineType or "AlphabeticBaseline"
	return math.floor(self:FontSize() / 2 + 0.5);
end

function ComputedStyle:HasMask() return false; end
function ComputedStyle:SpecifiesColumns() return not self:HasAutoColumnCount() or not self:HasAutoColumnWidth(); end
function ComputedStyle:TextEmphasisMark()
	--return "TextEmphasisMarkNone"
	local mark = self.rareInheritedData.textEmphasisMark;
	if(mark ~= TextEmphasisMarkEnum.TextEmphasisMarkAuto) then
		return mark;
	end
	if (self:IsHorizontalWritingMode()) then
		
        return TextEmphasisMarkEnum.TextEmphasisMarkDot;
	end
    return TextEmphasisMarkEnum.TextEmphasisMarkSesame;
end
function ComputedStyle:MarqueeBehavior() return self.rareNonInheritedData.m_marquee.behavior; end
function ComputedStyle:StyleType() return self.noninherited_flags._styleType; end
function ComputedStyle:Locale() return nil; end
function ComputedStyle:LineBoxContain() return self.rareInheritedData.m_lineBoxContain; end

function ComputedStyle:Order()  return self.rareNonInheritedData.order; end
function ComputedStyle:FlexGrow()  return self.rareNonInheritedData.flexibleBox.flexGrow; end
function ComputedStyle:FlexShrink()  return self.rareNonInheritedData.flexibleBox.flexShrink; end
function ComputedStyle:FlexBasis()  return self.rareNonInheritedData.flexibleBox.flexBasis; end
function ComputedStyle:AlignContent()  return self.rareNonInheritedData.alignContent; end
function ComputedStyle:AlignItems()  return self.rareNonInheritedData.alignItems; end
function ComputedStyle:AlignSelf()  return self.rareNonInheritedData.alignSelf; end
function ComputedStyle:FlexDirection()  return self.rareNonInheritedData.flexibleBox.flexDirection; end
function ComputedStyle:IsColumnFlexDirection()  return self:FlexDirection() == FlexDirectionEnum.FlowColumn or self:FlexDirection() == FlexDirectionEnum.FlowColumnReverse; end
function ComputedStyle:IsReverseFlexDirection()  return self:FlexDirection() == FlexDirectionEnum.FlowRowReverse or self:FlexDirection() == FlexDirectionEnum.FlowColumnReverse; end
function ComputedStyle:FlexWrap()  return self.rareNonInheritedData.flexibleBox.flexWrap; end
function ComputedStyle:JustifyContent()  return self.rareNonInheritedData.justifyContent; end
function ComputedStyle:JustifyItems()  return self.rareNonInheritedData.justifyItems; end
function ComputedStyle:JustifySelf()  return self.rareNonInheritedData.justifySelf; end

-- attribute setter methods

function ComputedStyle:SetDisplay(v) self.noninherited_flags._effectiveDisplay = v; end
function ComputedStyle:SetOriginalDisplay(v) self.noninherited_flags._originalDisplay = v; end
function ComputedStyle:SetPosition(v) self.noninherited_flags._position = v; end
function ComputedStyle:SetFloating(v) self.noninherited_flags._floating = v; end

function ComputedStyle:SetLeft(v) self.surround.offset.m_left = v; end
function ComputedStyle:SetRight(v) self.surround.offset.m_right = v; end
function ComputedStyle:SetTop(v) self.surround.offset.m_top = v; end
function ComputedStyle:SetBottom(v) self.surround.offset.m_bottom = v; end

function ComputedStyle:SetWidth(v) self.m_box.m_width = v; end
function ComputedStyle:SetHeight(v) self.m_box.m_height = v; end

function ComputedStyle:SetMinWidth(v) self.m_box.m_minWidth = v; end
function ComputedStyle:SetMaxWidth(v) self.m_box.m_maxWidth = v; end
function ComputedStyle:SetMinHeight(v) self.m_box.m_minHeight = v; end
function ComputedStyle:SetMaxHeight(v) self.m_box.m_maxHeight = v; end

function ComputedStyle:ResetBorder() self:ResetBorderImage(); self:ResetBorderTop(); self:ResetBorderRight(); self:ResetBorderBottom(); self:ResetBorderLeft(); self:ResetBorderRadius(); end
function ComputedStyle:ResetBorderImage()  end
function ComputedStyle:ResetBorderTop() self.surround.border.m_top = BorderValue:new(); end
function ComputedStyle:ResetBorderRight() self.surround.border.m_right = BorderValue:new(); end
function ComputedStyle:ResetBorderBottom() self.surround.border.m_bottom = BorderValue:new(); end
function ComputedStyle:ResetBorderLeft() self.surround.border.m_left = BorderValue:new(); end
function ComputedStyle:ResetBorderRadius() self:ResetBorderTopLeftRadius(); self:ResetBorderTopRightRadius(); self:ResetBorderBottomLeftRadius(); self:ResetBorderBottomRightRadius(); end
function ComputedStyle:ResetBorderTopLeftRadius() self.surround.border.m_topLeft = self:InitialBorderRadius(); end
function ComputedStyle:ResetBorderTopRightRadius() self.surround.border.m_topRight = self:InitialBorderRadius(); end
function ComputedStyle:ResetBorderBottomLeftRadius() self.surround.border.m_bottomLeft = self:InitialBorderRadius(); end
function ComputedStyle:ResetBorderBottomRightRadius() self.surround.border.m_bottomRight = self:InitialBorderRadius(); end

function ComputedStyle:ResetOutline() self.m_background.m_outline = OutlineValue:new(); end

function ComputedStyle:SetBackgroundColor(v) self.m_background.m_color = v; end
function ComputedStyle:SetBackgroundImage(v) self.m_background.background = v; end

function ComputedStyle:SetBorderTopLeftRadius(s) self.surround.border.m_topLeft = s; end
function ComputedStyle:SetBorderTopRightRadius(s) self.surround.border.m_topRight = s; end
function ComputedStyle:SetBorderBottomLeftRadius(s) self.surround.border.m_bottomLeft = s; end
function ComputedStyle:SetBorderBottomRightRadius(s) self.surround.border.m_bottomRight = s; end

function ComputedStyle:SetBorderLeftWidth(v) self.surround.border.m_left.m_width = v; end
function ComputedStyle:SetBorderLeftStyle(v) self.surround.border.m_left.m_style = v; end
function ComputedStyle:SetBorderLeftColor(v) self.surround.border.m_left.m_color = v; end
function ComputedStyle:SetBorderRightWidth(v) self.surround.border.m_right.m_width = v; end
function ComputedStyle:SetBorderRightStyle(v) self.surround.border.m_right.m_style = v; end
function ComputedStyle:SetBorderRightColor(v) self.surround.border.m_right.m_color = v; end
function ComputedStyle:SetBorderTopWidth(v) self.surround.border.m_top.m_width = v; end
function ComputedStyle:SetBorderTopStyle(v) self.surround.border.m_top.m_style = v; end
function ComputedStyle:SetBorderTopColor(v) self.surround.border.m_top.m_color = v; end
function ComputedStyle:SetBorderBottomWidth(v) self.surround.border.m_bottom.m_width = v; end
function ComputedStyle:SetBorderBottomStyle(v) self.surround.border.m_bottom.m_style = v; end
function ComputedStyle:SetBorderBottomColor(v) self.surround.border.m_bottom.m_color = v; end

function ComputedStyle:SetOutlineWidth(v) self.m_background.m_outline.m_width = v; end
function ComputedStyle:SetOutlineStyleIsAuto(isAuto) self.m_background.m_outline.m_isAuto = isAuto; end
function ComputedStyle:SetOutlineStyle(v) self.m_background.m_outline.m_style = v; end
function ComputedStyle:SetOutlineColor(v) self.m_background.m_outline.m_color = v; end

function ComputedStyle:SetOverflowX(v) self.noninherited_flags._overflowX = v; end
function ComputedStyle:SetOverflowY(v) self.noninherited_flags._overflowY = v; end
function ComputedStyle:SetVisibility(v) self.inherited_flags._visibility = v; end
function ComputedStyle:SetVerticalAlign(v) self.noninherited_flags._vertical_align = v; end
function ComputedStyle:SetVerticalAlignLength(l) self.m_box.m_verticalAlign = l; end

function ComputedStyle:SetClipLeft(v) self.visual.clip.m_left = v; end
function ComputedStyle:SetClipRight(v) self.visual.clip.m_right = v; end
function ComputedStyle:SetClipTop(v) self.visual.clip.m_top = v; end
function ComputedStyle:SetClipBottom(v) self.visual.clip.m_bottom = v; end
function ComputedStyle:SetClip(box) self.visual.clip = box; end

function ComputedStyle:SetUnicodeBidi(b) self.noninherited_flags._unicodeBidi = b; end

function ComputedStyle:SetClear(v) self.noninherited_flags._clear = v; end
function ComputedStyle:SetTableLayout(v) self.noninherited_flags._table_layout = v; end
function ComputedStyle:SetColor(v) self.inherited.color = v; end
function ComputedStyle:SetTextIndent(v) self.rareInheritedData.indent = v; end
function ComputedStyle:SetTextAlign(v) self.inherited_flags._text_align = v; end

function ComputedStyle:SetDirection(v) self.inherited_flags._direction = v; end
function ComputedStyle:SetLineHeight(v) self.inherited.line_height = v; end

function ComputedStyle:SetWhiteSpace(v) self.inherited_flags._white_space = v; end

function ComputedStyle:SetWordSpacing(v) self.inherited.font:SetWordSpacing(v); end
function ComputedStyle:SetLetterSpacing(v) self.inherited.font:SetLetterSpacing(v); end

function ComputedStyle:SetFontSize(v) self.inherited.font:SetSize(v); end
function ComputedStyle:SetFontBold(v) self.inherited.font.bold = v; end
function ComputedStyle:SetFontFamily(v) self.inherited.font.family = v; end

function ComputedStyle:SetBorderCollapse(collapse) self.inherited_flags._border_collapse = collapse; end
function ComputedStyle:SetHorizontalBorderSpacing(v) self.inherited.horizontal_border_spacing = v; end
function ComputedStyle:SetVerticalBorderSpacing(v) self.inherited.vertical_border_spacing = v; end
function ComputedStyle:SetEmptyCells(v) self.inherited_flags._empty_cells = v; end
function ComputedStyle:SetCaptionSide(v) self.inherited_flags._caption_side = v; end


function ComputedStyle:ResetMargin() self.surround.margin = LengthBox:new("type", LengthTypeEnum.Fixed); end
function ComputedStyle:SetMarginTop(v) self.surround.margin.m_top = v; end
function ComputedStyle:SetMarginBottom(v) self.surround.margin.m_bottom = v; end
function ComputedStyle:SetMarginLeft(v) self.surround.margin.m_left = v; end
function ComputedStyle:SetMarginRight(v) self.surround.margin.m_right = v; end
function ComputedStyle:SetMarginStart(margin)
    if (self:IsHorizontalWritingMode()) then
        if (self:IsLeftToRightDirection()) then
            self:SetMarginLeft(margin);
        else
            self:SetMarginRight(margin);
		end
    else
        if (self:IsLeftToRightDirection()) then
            self:SetMarginTop(margin);
        else
            self:SetMarginBottom(margin);
		end
    end
end
function ComputedStyle:SetMarginEnd(margin)
    if (self:IsHorizontalWritingMode()) then
        if (self:IsLeftToRightDirection()) then
            self:SetMarginRight(margin);
        else
            self:SetMarginLeft(margin);
		end
    else
        if (self:IsLeftToRightDirection()) then
            self:SetMarginBottom(margin);
        else
            self:SetMarginTop(margin);
		end
    end
end


function ComputedStyle:ResetPadding() self.surround.padding = LengthBox:new("type", LengthTypeEnum.Auto); end
function ComputedStyle:SetPaddingBox(b) self.surround.padding = b; end
function ComputedStyle:SetPaddingTop(v) self.surround.padding.m_top = v; end
function ComputedStyle:SetPaddingBottom(v) self.surround.padding.m_bottom = v; end
function ComputedStyle:SetPaddingLeft(v) self.surround.padding.m_left = v; end
function ComputedStyle:SetPaddingRight(v) self.surround.padding.m_right = v; end

function ComputedStyle:SetHasAutoZIndex() self.m_box.m_hasAutoZIndex = true; self.m_box.m_zIndex = 0; end
function ComputedStyle:SetZIndex(v) self.m_box.m_hasAutoZIndex = false; self.m_box.m_zIndex = v; end

function ComputedStyle:SetWidows(w) self.rareInheritedData.widows = w; end
function ComputedStyle:SetOrphans(o) self.rareInheritedData.orphans = o; end
function ComputedStyle:SetPageBreakInside(b) self.noninherited_flags._page_break_inside = b; end
function ComputedStyle:SetPageBreakBefore(b) self.noninherited_flags._page_break_before = b; end
function ComputedStyle:SetPageBreakAfter(b) self.noninherited_flags._page_break_after = b; end
function ComputedStyle:SetOpacity(f) self.rareNonInheritedData.opacity = f; end
function ComputedStyle:SetAppearance(a) self.rareNonInheritedData.m_appearance = a; end

function ComputedStyle:SetBoxAlign(a) self.rareNonInheritedData.m_deprecatedFlexibleBox.align = a; end
function ComputedStyle:SetBoxDirection(d) self.inherited_flags._box_direction = d; end
function ComputedStyle:SetBoxFlex(f) self.rareNonInheritedData.m_deprecatedFlexibleBox.flex = f; end
function ComputedStyle:SetBoxFlexGroup(fg) self.rareNonInheritedData.m_deprecatedFlexibleBox.flex_group = fg; end
function ComputedStyle:SetBoxLines(l) self.rareNonInheritedData.m_deprecatedFlexibleBox.lines = l; end
function ComputedStyle:SetBoxOrdinalGroup(og) self.rareNonInheritedData.m_deprecatedFlexibleBox.ordinal_group = og; end
function ComputedStyle:SetBoxOrient(o) self.rareNonInheritedData.m_deprecatedFlexibleBox.orient = o; end
function ComputedStyle:SetBoxPack(p) self.rareNonInheritedData.m_deprecatedFlexibleBox.pack = p; end

function ComputedStyle:SetUserModify(u) self.rareInheritedData.userModify = u; end
function ComputedStyle:SetUserDrag(d) self.rareNonInheritedData.userDrag = d; end
function ComputedStyle:SetUserSelect(s) self.rareInheritedData.userSelect = s; end
function ComputedStyle:SetTextOverflow(overflow) self.rareNonInheritedData.textOverflow = overflow; end
function ComputedStyle:SetMarginBeforeCollapse(c) self.rareNonInheritedData.marginBeforeCollapse = c; end
function ComputedStyle:SetMarginAfterCollapse(c) self.rareNonInheritedData.marginAfterCollapse = c; end
function ComputedStyle:SetWordBreak(b) self.rareInheritedData.wordBreak = b; end
function ComputedStyle:SetWordWrap(b) self.rareInheritedData.wordWrap = b; end
function ComputedStyle:SetCaretColor(v) self.rareInheritedData.caretColor = v; end
function ComputedStyle:SetNBSPMode(b) self.rareInheritedData.nbspMode = b; end
function ComputedStyle:SetKHTMLLineBreak(b) self.rareInheritedData.khtmlLineBreak = b; end
function ComputedStyle:SetMatchNearestMailBlockquoteColor(c) self.rareNonInheritedData.matchNearestMailBlockquoteColor = c; end

function ComputedStyle:SetHyphens(h) self.rareInheritedData.hyphens = h; end
function ComputedStyle:SetLocale(locale) self.rareInheritedData.locale = locale; end
function ComputedStyle:SetBorderFit(b) self.rareNonInheritedData.m_borderFit = b; end
function ComputedStyle:SetResize(r) self.rareInheritedData.resize = r; end

function ComputedStyle:SetSpeak(s) self.rareInheritedData.speak = s; end
function ComputedStyle:SetTextCombine(v) self.rareNonInheritedData.m_textCombine = v; end
function ComputedStyle:SetTextEmphasisColor(c) self.rareInheritedData.textEmphasisColor = c; end
function ComputedStyle:SetTextEmphasisFill(fill) self.rareInheritedData.textEmphasisFill = fill; end
function ComputedStyle:SetTextEmphasisMark(mark) self.rareInheritedData.textEmphasisMark = mark; end
function ComputedStyle:SetTextEmphasisCustomMark(mark) self.rareInheritedData.textEmphasisCustomMark = mark; end
function ComputedStyle:SetTextEmphasisPosition(position) self.rareInheritedData.textEmphasisPosition = position; end

function ComputedStyle:SetPageSize(s) self.rareNonInheritedData.m_pageSize = s; end
function ComputedStyle:SetPageSizeType(t) self.rareNonInheritedData.m_pageSizeType = t; end
function ComputedStyle:ResetPageSizeType() self.rareNonInheritedData.m_pageSizeType = PageSizeTypeEnum.PAGE_SIZE_AUTO; end

function ComputedStyle:SetWritingMode(v) self.inherited_flags.m_writingMode = v; end

function ComputedStyle:SetUnique() self.m_unique = true; end

function ComputedStyle:SetOutlineOffset(v) self.m_background.m_outline.m_offset = v; end
--void setTextShadow(PassOwnPtr<ShadowData>, bool add = false);
function ComputedStyle:SetTextShadow(shadowData, add)
	add = if_else(add == nil, false, add);
    --ASSERT(!shadowData || (!shadowData->spread() && shadowData->style() == Normal));

    local rareData = self.rareInheritedData;
    if (not add) then
        rareData.textShadow = shadowData;
        return;
    end

    --shadowData->setNext(rareData->textShadow.release());
    rareData.textShadow = shadowData;
end


--bool RenderStyle::inheritedNotEqual(const RenderStyle* other) const
function ComputedStyle:InheritedNotEqual(other)
    return self.inherited_flags ~= other.inherited_flags
           or inherited ~= other.inherited
--#if ENABLE(SVG)
--           || m_svgStyle->inheritedNotEqual(other->m_svgStyle.get())
--#endif
           or rareInheritedData ~= other.rareInheritedData;
end

function ComputedStyle:IsDisplayReplacedType()
	local display = self:Display();
	return display == DisplayEnum.INLINE_BLOCK or display == DisplayEnum.INLINE_BOX or display == DisplayEnum.INLINE_TABLE;
end

function ComputedStyle:IsDisplayInlineType()
	return self:Display() == DisplayEnum.INLINE or self:IsDisplayReplacedType();
end

function ComputedStyle:IsOriginalDisplayInlineType()
	local originalDisplay = self:OriginalDisplay();
	return originalDisplay == DisplayEnum.INLINE or originalDisplay == DisplayEnum.INLINE_BLOCK
		or originalDisplay == DisplayEnum.INLINE_BOX or originalDisplay == DisplayEnum.INLINE_TABLE;
end

function ComputedStyle:SetBorderRadius(s)
	self:SetBorderTopLeftRadius(s);
	self:SetBorderTopRightRadius(s);
	self:SetBorderBottomLeftRadius(s);
	self:SetBorderBottomRightRadius(s);
end
function ComputedStyle:SetBorderRadius(s)
	self:SetBorderRadius(LengthSize:new(Length:new(s:Width(), LengthTypeEnum.Fixed), Length:new(s:Height(), LengthTypeEnum.Fixed)));
end

function ComputedStyle:SetHasClip(b) 
	b = if_else(b == nil, true, b);
	self.visual.hasClip = b;
end

function ComputedStyle:HasAppearance() 
	return self:Appearance() ~= ControlPartEnum.NoControlPart;
end

function ComputedStyle:HasBackgroundImage()
	local image = self:BackgroundImage();
	return image and image ~= "";
end

function ComputedStyle:HasBackground()
	local color = self.m_background.m_color;
    if (color:IsValid() and color:Alpha() > 0) then
        return true;
	end
    return self:HasBackgroundImage();
end

--void RenderStyle::setClip(Length top, Length right, Length bottom, Length left)
function ComputedStyle:SetClip(top, right, bottom, left)
    local data = self.visual;
    data.clip.m_top = top;
    data.clip.m_right = right;
    data.clip.m_bottom = bottom;
    data.clip.m_left = left;
end

function ComputedStyle:SetFlexGrow(f) self.rareNonInheritedData.flexibleBox.flexGrow = f; end
function ComputedStyle:SetFlexShrink(f) self.rareNonInheritedData.flexibleBox.flexShrink = f; end
function ComputedStyle:SetFlexBasis(length) self.rareNonInheritedData.flexibleBox.flexBasis = length:clone(); end
function ComputedStyle:SetOrder(o) self.rareNonInheritedData.order = o; end
function ComputedStyle:SetAlignContent(data) self.rareNonInheritedData.alignContent = data:clone(); end
function ComputedStyle:SetAlignItems(data) self.rareNonInheritedData.alignItems = data:clone(); end
function ComputedStyle:SetAlignItemsPosition(position) self.rareNonInheritedData.alignItems:SetPosition(position); end
function ComputedStyle:SetAlignSelf(data) self.rareNonInheritedData.alignSelf = data:clone(); end
function ComputedStyle:SetAlignSelfPosition(position) self.rareNonInheritedData.alignSelf:SetPosition(position); end
function ComputedStyle:SetFlexDirection(direction) self.rareNonInheritedData.flexibleBox.flexDirection = direction; end
function ComputedStyle:SetFlexWrap(w) self.rareNonInheritedData.flexibleBox.flexWrap = w; end
function ComputedStyle:SetJustifyContent(data) self.rareNonInheritedData.justifyContent = data:clone(); end
function ComputedStyle:SetJustifyContentPosition(position) self.rareNonInheritedData.justifyContent:SetPosition(position); end
function ComputedStyle:SetJustifyItems(data) self.rareNonInheritedData.justifyItems = data:clone(); end
function ComputedStyle:SetJustifySelf(data) self.rareNonInheritedData.justifySelf = data:clone(); end
function ComputedStyle:SetJustifySelfPosition(position) self.rareNonInheritedData.justifySelf:SetPosition(position); end


--PassRefPtr<RenderStyle> RenderStyle::createAnonymousStyle(const RenderStyle* parentStyle)
function ComputedStyle.CreateAnonymousStyle(parentStyle)
    local newStyle = ComputedStyle:new();
    newStyle:InheritFrom(parentStyle);
    newStyle:InheritUnicodeBidiFrom(parentStyle);
	newStyle:SetBackgroundColor(ComputedStyle.initialBackgroundColor());
	newStyle:SetBackgroundImage(ComputedStyle.initialBackgroundImage());
    return newStyle;
end