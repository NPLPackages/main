--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Util/EnumCreater.lua");
local EnumCreater = commonlib.gettable("System.Util.EnumCreater");

local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");



--[[
 * WARNING:
 * --------
 *
 * The order of the values in the locals have to agree with the order specified
 * in CSSValueKeywords.in, otherwise some optimizations in the parser will fail,
 * and produce invalid results.
]]

-- The difference between two styles.  The following values are used:
-- (1) StyleDifferenceEqual - The two styles are identical
-- (2) StyleDifferenceRecompositeLayer - The layer needs its position and transform updated, but no repaint
-- (3) StyleDifferenceRepaint - The object just needs to be repainted.
-- (4) StyleDifferenceRepaintLayer - The layer and its descendant layers needs to be repainted.
-- (5) StyleDifferenceLayoutPositionedMovementOnly - Only the position of this positioned object has been updated
-- (6) StyleDifferenceSimplifiedLayout - Only overflow needs to be recomputed
-- (7) StyleDifferenceSimplifiedLayoutAndPositionedMovement - Both positioned movement and simplified layout updates are required.
-- (8) StyleDifferenceLayout - A full layout is required.
local StyleDifferenceEnum = EnumCreater.Transform({
    "StyleDifferenceEqual",
-- #if USE(ACCELERATED_COMPOSITING)
    "StyleDifferenceRecompositeLayer",
-- #endif
    "StyleDifferenceRepaint",
    "StyleDifferenceRepaintLayer",
    "StyleDifferenceLayoutPositionedMovementOnly",
    "StyleDifferenceSimplifiedLayout",
    "StyleDifferenceSimplifiedLayoutAndPositionedMovement",
    "StyleDifferenceLayout"
});
ComputedStyleConstants.StyleDifferenceEnum = StyleDifferenceEnum;

-- When some style properties change, different amounts of work have to be done depending on
-- context (e.g. whether the property is changing on an element which has a compositing layer).
-- A simple StyleDifference does not provide enough information so we return a bit mask of
-- StyleDifferenceContextSensitiveProperties from RenderStyle::diff() too.
local StyleDifferenceContextSensitivePropertyEnum = EnumCreater.Transform({
    --ContextSensitivePropertyNone = 0,
	"ContextSensitivePropertyNone",
    --ContextSensitivePropertyTransform = (1 << 0),
	"ContextSensitivePropertyTransform",
    --ContextSensitivePropertyOpacity = (1 << 1)
	"ContextSensitivePropertyOpacity"
});
ComputedStyleConstants.StyleDifferenceContextSensitivePropertyEnum = StyleDifferenceContextSensitivePropertyEnum;

-- Static pseudo styles. Dynamic ones are produced on the fly.
local PseudoIdEnum = EnumCreater.Transform({
    -- The order must be NOP ID, public IDs, and then internal IDs.
    "NOPSEUDO", "FIRST_LINE", "FIRST_LETTER", "BEFORE", "AFTER", "SELECTION", "FIRST_LINE_INHERITED", "SCROLLBAR",
    -- Internal IDs follow:
    "SCROLLBAR_THUMB", "SCROLLBAR_BUTTON", "SCROLLBAR_TRACK", "SCROLLBAR_TRACK_PIECE", "SCROLLBAR_CORNER", "RESIZER",
    "INPUT_LIST_BUTTON",
    "AFTER_LAST_INTERNAL_PSEUDOID",
    "FULL_SCREEN", "FULL_SCREEN_DOCUMENT", "FULL_SCREEN_ANCESTOR", "ANIMATING_FULL_SCREEN_TRANSITION",
    --"FIRST_PUBLIC_PSEUDOID = FIRST_LINE,
    --"FIRST_INTERNAL_PSEUDOID = SCROLLBAR_THUMB,
    --"PUBLIC_PSEUDOID_MASK = ((1 << FIRST_INTERNAL_PSEUDOID) - 1) & ~((1 << FIRST_PUBLIC_PSEUDOID) - 1)"
});
ComputedStyleConstants.PseudoIdEnum = PseudoIdEnum;

local BorderCollapseEnum = EnumCreater.Transform({ "BSEPARATE", "BCOLLAPSE"});
ComputedStyleConstants.BorderCollapseEnum = BorderCollapseEnum;

-- These have been defined in the order of their precedence for border-collapsing. Do
-- not change this order!
local BorderStyleEnum = EnumCreater.Transform({ "BNONE", "BHIDDEN", "INSET", "GROOVE", "OUTSET", "RIDGE", "DOTTED", "DASHED", "SOLID", "DOUBLE"});
ComputedStyleConstants.BorderStyleEnum = BorderStyleEnum;

local BorderPrecedenceEnum = EnumCreater.Transform({ "BOFF", "BTABLE", "BCOLGROUP", "BCOL", "BROWGROUP", "BROW", "BCELL"});
ComputedStyleConstants.BorderPrecedenceEnum = BorderPrecedenceEnum;

local OutlineIsAutoEnum = EnumCreater.Transform({ "AUTO_OFF", "AUTO_ON"});
ComputedStyleConstants.OutlineIsAutoEnum = OutlineIsAutoEnum;

local PositionEnum = EnumCreater.Transform({
    "StaticPosition", "RelativePosition", "AbsolutePosition", "StickyPosition", {"FixedPosition", 6}
});
ComputedStyleConstants.PositionEnum = PositionEnum;

local FloatEnum = EnumCreater.Transform({
    "NoFloat", "LeftFloat", "RightFloat", "PositionedFloat"
});
ComputedStyleConstants.FloatEnum = FloatEnum;

local MarginCollapseEnum = EnumCreater.Transform({ "MCOLLAPSE", "MSEPARATE", "MDISCARD"});
ComputedStyleConstants.MarginCollapseEnum = MarginCollapseEnum;

-- Box attributes. Not inherited.

local BoxSizingEnum = EnumCreater.Transform({ "CONTENT_BOX", "BORDER_BOX"});
ComputedStyleConstants.BoxSizingEnum = BoxSizingEnum;

-- Random visual rendering model attributes. Not inherited.

local OverflowEnum = EnumCreater.Transform({
    "OVISIBLE", "OHIDDEN", "OSCROLL", "OAUTO", "OOVERLAY", "OMARQUEE"
});
ComputedStyleConstants.OverflowEnum = OverflowEnum;

local VerticalAlignEnum = EnumCreater.Transform({
    "BASELINE", "MIDDLE", "SUB", "SUPER", "TEXT_TOP",
    "TEXT_BOTTOM", "TOP", "BOTTOM", "BASELINE_MIDDLE", "LENGTH"
});
ComputedStyleConstants.VerticalAlignEnum = VerticalAlignEnum;

local ClearEnum = EnumCreater.Transform({
	-- CNONE = 0, CLEFT = 1, CRIGHT = 2, CBOTH = 3
    "CNONE", "CLEFT", "CRIGHT", "CBOTH"
});
ComputedStyleConstants.ClearEnum = ClearEnum;

local TableLayoutEnum = EnumCreater.Transform({
    "TAUTO", "TFIXED"
});
ComputedStyleConstants.TableLayoutEnum = TableLayoutEnum;

-- CSS Text Layout Module Level 3: Vertical writing support
local WritingModeEnum = EnumCreater.Transform({
    "TopToBottomWritingMode", "RightToLeftWritingMode", "LeftToRightWritingMode", "BottomToTopWritingMode"
});
ComputedStyleConstants.WritingModeEnum = WritingModeEnum;

local TextCombineEnum = EnumCreater.Transform({
    "TextCombineNone", "TextCombineHorizontal"
});
ComputedStyleConstants.TextCombineEnum = TextCombineEnum;

local FillAttachmentEnum = EnumCreater.Transform({
    "ScrollBackgroundAttachment", "LocalBackgroundAttachment", "FixedBackgroundAttachment"
});
ComputedStyleConstants.FillAttachmentEnum = FillAttachmentEnum;

local FillBoxEnum = EnumCreater.Transform({
    "BorderFillBox", "PaddingFillBox", "ContentFillBox", "TextFillBox"
});
ComputedStyleConstants.FillBoxEnum = FillBoxEnum;

local FillRepeatEnum = EnumCreater.Transform({
    "RepeatFill", "NoRepeatFill", "RoundFill", "SpaceFill"
});
ComputedStyleConstants.FillRepeatEnum = FillRepeatEnum;

local FillLayerTypeEnum = EnumCreater.Transform({
    "BackgroundFillLayer", "MaskFillLayer"
});
ComputedStyleConstants.FillLayerTypeEnum = FillLayerTypeEnum;

-- CSS3 Background Values
local FillSizeTypeEnum = EnumCreater.Transform({ "Contain", "Cover", "SizeLength", "SizeNone"});
ComputedStyleConstants.FillSizeTypeEnum = FillSizeTypeEnum;

-- CSS3 Marquee Properties

local MarqueeBehaviorEnum = EnumCreater.Transform({ "MNONE", "MSCROLL", "MSLIDE", "MALTERNATE"});
ComputedStyleConstants.MarqueeBehaviorEnum = MarqueeBehaviorEnum;
-- enum EMarqueeDirection { MAUTO = 0, MLEFT = 1, MRIGHT = -1, MUP = 2, MDOWN = -2, MFORWARD = 3, MBACKWARD = -3 };
local MarqueeDirectionEnum = EnumCreater.Transform({ {"MAUTO", 0}, {"MLEFT", 1}, {"MRIGHT", -1}, {"MUP", 2}, {"MDOWN", -2}, {"MFORWARD", 3}, {"MBACKWARD", -3}});
ComputedStyleConstants.MarqueeDirectionEnum = MarqueeDirectionEnum;

-- Deprecated Flexible Box Properties

local BoxAlignmentEnum = EnumCreater.Transform({ "BSTRETCH", "BSTART", "BCENTER", "BEND", "BJUSTIFY", "BBASELINE"});
ComputedStyleConstants.BoxAlignmentEnum = BoxAlignmentEnum;
local BoxOrientEnum = EnumCreater.Transform({ "HORIZONTAL", "VERTICAL"});
ComputedStyleConstants.BoxOrientEnum = BoxOrientEnum;
local BoxLinesEnum = EnumCreater.Transform({ "SINGLE", "MULTIPLE"});
ComputedStyleConstants.BoxLinesEnum = BoxLinesEnum;
local BoxDirectionEnum = EnumCreater.Transform({ "BNORMAL", "BREVERSE"});
ComputedStyleConstants.BoxDirectionEnum = BoxDirectionEnum;

-- CSS3 Flexbox Properties

ComputedStyleConstants.AlignContentEnum = EnumCreater.Transform({ "AlignContentFlexStart", "AlignContentFlexEnd", "AlignContentCenter", "AlignContentSpaceBetween", "AlignContentSpaceAround", "AlignContentStretch" });
ComputedStyleConstants.FlexDirectionEnum  = EnumCreater.Transform({ "FlowRow", "FlowRowReverse", "FlowColumn", "FlowColumnReverse" });
ComputedStyleConstants.FlexWrapEnum = EnumCreater.Transform({ "FlexNoWrap", "FlexWrap", "FlexWrapReverse" });
ComputedStyleConstants.ItemPositionEnum = EnumCreater.Transform({ "ItemPositionAuto", "ItemPositionNormal", "ItemPositionStretch", "ItemPositionBaseline", "ItemPositionLastBaseline", "ItemPositionCenter", "ItemPositionStart", "ItemPositionEnd", "ItemPositionSelfStart", "ItemPositionSelfEnd", "ItemPositionFlexStart", "ItemPositionFlexEnd", "ItemPositionLeft", "ItemPositionRight" });
ComputedStyleConstants.OverflowAlignmentEnum = EnumCreater.Transform({ "OverflowAlignmentDefault", "OverflowAlignmentUnsafe", "OverflowAlignmentSafe" });
ComputedStyleConstants.ItemPositionTypeEnum = EnumCreater.Transform({ "NonLegacyPosition", "LegacyPosition" });
ComputedStyleConstants.ContentPositionEnum = EnumCreater.Transform({ "ContentPositionNormal", "ContentPositionBaseline", "ContentPositionLastBaseline", "ContentPositionCenter", "ContentPositionStart", "ContentPositionEnd", "ContentPositionFlexStart", "ContentPositionFlexEnd", "ContentPositionLeft", "ContentPositionRight" });
ComputedStyleConstants.ContentDistributionTypeEnum = EnumCreater.Transform({ "ContentDistributionDefault", "ContentDistributionSpaceBetween", "ContentDistributionSpaceAround", "ContentDistributionSpaceEvenly", "ContentDistributionStretch" });

local TextSecurityEnum = EnumCreater.Transform({
    "TSNONE", "TSDISC", "TSCIRCLE", "TSSQUARE"
});
ComputedStyleConstants.TextSecurityEnum = TextSecurityEnum;

-- CSS3 User Modify Properties

local UserModifyEnum = EnumCreater.Transform({
    "READ_ONLY", "READ_WRITE", "READ_WRITE_PLAINTEXT_ONLY"
});
ComputedStyleConstants.UserModifyEnum = UserModifyEnum;

-- CSS3 User Drag Values

local UserDragEnum = EnumCreater.Transform({
    "DRAG_AUTO", "DRAG_NONE", "DRAG_ELEMENT"
});
ComputedStyleConstants.UserDragEnum = UserDragEnum;

-- CSS3 User Select Values

local UserSelectEnum = EnumCreater.Transform({
    "SELECT_NONE", "SELECT_TEXT"
});
ComputedStyleConstants.UserSelectEnum = UserSelectEnum;

-- Word Break Values. Matches WinIE, rather than CSS3

local WordBreakEnum = EnumCreater.Transform({
    "NormalWordBreak", "BreakAllWordBreak", "BreakWordBreak"
});
ComputedStyleConstants.WordBreakEnum = WordBreakEnum;

local WordWrapEnum = EnumCreater.Transform({
    "NormalWordWrap", "BreakWordWrap"
});
ComputedStyleConstants.WordWrapEnum = WordWrapEnum;

local NBSPModeEnum = EnumCreater.Transform({
    "NBNORMAL", "SPACE"
});
ComputedStyleConstants.NBSPModeEnum = NBSPModeEnum;

local KHTMLLineBreakEnum = EnumCreater.Transform({
    "LBNORMAL", "AFTER_WHITE_SPACE"
});
ComputedStyleConstants.KHTMLLineBreakEnum = KHTMLLineBreakEnum;

local MatchNearestMailBlockquoteColorEnum = EnumCreater.Transform({
    "BCNORMAL", "MATCH"
});
ComputedStyleConstants.MatchNearestMailBlockquoteColorEnum = MatchNearestMailBlockquoteColorEnum;

local ResizeEnum = EnumCreater.Transform({
    "RESIZE_NONE", "RESIZE_BOTH", "RESIZE_HORIZONTAL", "RESIZE_VERTICAL"
});
ComputedStyleConstants.ResizeEnum = ResizeEnum;

-- The order of this enum must match the order of the list style types in CSSValueKeywords.in. 
local ListStyleTypeEnum = EnumCreater.Transform({
    "Disc",
    "Circle",
    "Square",
    "DecimalListStyle",
    "DecimalLeadingZero",
    "ArabicIndic",
    "BinaryListStyle",
    "Bengali",
    "Cambodian",
    "Khmer",
    "Devanagari",
    "Gujarati",
    "Gurmukhi",
    "Kannada",
    "LowerHexadecimal",
    "Lao",
    "Malayalam",
    "Mongolian",
    "Myanmar",
    "Octal",
    "Oriya",
    "Persian",
    "Urdu",
    "Telugu",
    "Tibetan",
    "Thai",
    "UpperHexadecimal",
    "LowerRoman",
    "UpperRoman",
    "LowerGreek",
    "LowerAlpha",
    "LowerLatin",
    "UpperAlpha",
    "UpperLatin",
    "Afar",
    "EthiopicHalehameAaEt",
    "EthiopicHalehameAaEr",
    "Amharic",
    "EthiopicHalehameAmEt",
    "AmharicAbegede",
    "EthiopicAbegedeAmEt",
    "CjkEarthlyBranch",
    "CjkHeavenlyStem",
    "Ethiopic",
    "EthiopicHalehameGez",
    "EthiopicAbegede",
    "EthiopicAbegedeGez",
    "HangulConsonant",
    "Hangul",
    "LowerNorwegian",
    "Oromo",
    "EthiopicHalehameOmEt",
    "Sidama",
    "EthiopicHalehameSidEt",
    "Somali",
    "EthiopicHalehameSoEt",
    "Tigre",
    "EthiopicHalehameTig",
    "TigrinyaEr",
    "EthiopicHalehameTiEr",
    "TigrinyaErAbegede",
    "EthiopicAbegedeTiEr",
    "TigrinyaEt",
    "EthiopicHalehameTiEt",
    "TigrinyaEtAbegede",
    "EthiopicAbegedeTiEt",
    "UpperGreek",
    "UpperNorwegian",
    "Asterisks",
    "Footnotes",
    "Hebrew",
    "Armenian",
    "LowerArmenian",
    "UpperArmenian",
    "Georgian",
    "CJKIdeographic",
    "Hiragana",
    "Katakana",
    "HiraganaIroha",
    "KatakanaIroha",
    "NoneListStyle"
});
ComputedStyleConstants.ListStyleTypeEnum = ListStyleTypeEnum;

local StyleContentTypeEnum = EnumCreater.Transform({
    "CONTENT_NONE", "CONTENT_OBJECT", "CONTENT_TEXT", "CONTENT_COUNTER", "CONTENT_QUOTE"
});
ComputedStyleConstants.StyleContentTypeEnum = StyleContentTypeEnum;

local QuoteTypeEnum = EnumCreater.Transform({
    "OPEN_QUOTE", "CLOSE_QUOTE", "NO_OPEN_QUOTE", "NO_CLOSE_QUOTE"
});
ComputedStyleConstants.QuoteTypeEnum = QuoteTypeEnum;

local BorderFitEnum = EnumCreater.Transform({ "BorderFitBorder", "BorderFitLines"});
ComputedStyleConstants.BorderFitEnum = BorderFitEnum;

local AnimationFillModeEnum = EnumCreater.Transform({ "AnimationFillModeNone", "AnimationFillModeForwards", "AnimationFillModeBackwards", "AnimationFillModeBoth"});
ComputedStyleConstants.AnimationFillModeEnum = AnimationFillModeEnum;

local AnimPlayStateEnum = EnumCreater.Transform({
    {"AnimPlayStatePlaying", 0x0},
    {"AnimPlayStatePaused", 0x1}
});
ComputedStyleConstants.AnimPlayStateEnum = AnimPlayStateEnum;

local WhiteSpaceEnum = EnumCreater.Transform({
    "NORMAL", "PRE", "PRE_WRAP", "PRE_LINE", "NOWRAP", "KHTML_NOWRAP"
});
ComputedStyleConstants.WhiteSpaceEnum = WhiteSpaceEnum;

local TextAlignEnum = EnumCreater.Transform({
    "TAAUTO", "LEFT", "RIGHT", "CENTER", "JUSTIFY", "WEBKIT_LEFT", "WEBKIT_RIGHT", "WEBKIT_CENTER", "TASTART", "TAEND"
});
ComputedStyleConstants.TextAlignEnum = TextAlignEnum;

local TextTransformEnum = EnumCreater.Transform({
    "CAPITALIZE", "UPPERCASE", "LOWERCASE", "TTNONE"
});
ComputedStyleConstants.TextTransformEnum = TextTransformEnum;

--static const size_t ETextDecorationBits = 4;
local TextDecorationEnum = EnumCreater.Transform({
    {"TDNONE", 0x0}, {"UNDERLINE", 0x1}, {"OVERLINE", 0x2}, {"LINE_THROUGH", 0x4}, {"BLINK", 0x8}
});
ComputedStyleConstants.TextDecorationEnum = TextDecorationEnum;
--inline ETextDecoration operator|(ETextDecoration a, ETextDecoration b) { return ETextDecoration(int(a) | int(b)); }
--inline ETextDecoration& operator|=(ETextDecoration& a, ETextDecoration b) { return a = a | b; }

local PageBreakEnum = EnumCreater.Transform({
    "PBAUTO", "PBALWAYS", "PBAVOID"
});
ComputedStyleConstants.PageBreakEnum = PageBreakEnum;

local EmptyCellEnum = EnumCreater.Transform({
    "SHOW", "HIDE"
});
ComputedStyleConstants.EmptyCellEnum = EmptyCellEnum;

local CaptionSideEnum = EnumCreater.Transform({
    "CAPTOP", "CAPBOTTOM", "CAPLEFT", "CAPRIGHT"
});
ComputedStyleConstants.CaptionSideEnum = CaptionSideEnum;

local ListStylePositionEnum = EnumCreater.Transform({ "OUTSIDE", "INSIDE"});
ComputedStyleConstants.ListStylePositionEnum = ListStylePositionEnum;

local VisibilityEnum = EnumCreater.Transform({ "VISIBLE", "HIDDEN", "COLLAPSE"});
ComputedStyleConstants.VisibilityEnum = VisibilityEnum;

local CursorEnum = EnumCreater.Transform({
    -- The following must match the order in CSSValueKeywords.in.
    "CURSOR_AUTO",
    "CURSOR_CROSS",
    "CURSOR_DEFAULT",
    "CURSOR_POINTER",
    "CURSOR_MOVE",
    "CURSOR_VERTICAL_TEXT",
    "CURSOR_CELL",
    "CURSOR_CONTEXT_MENU",
    "CURSOR_ALIAS",
    "CURSOR_PROGRESS",
    "CURSOR_NO_DROP",
    "CURSOR_NOT_ALLOWED",
    "CURSOR_WEBKIT_ZOOM_IN",
    "CURSOR_WEBKIT_ZOOM_OUT",
    "CURSOR_E_RESIZE",
    "CURSOR_NE_RESIZE",
    "CURSOR_NW_RESIZE",
    "CURSOR_N_RESIZE",
    "CURSOR_SE_RESIZE",
    "CURSOR_SW_RESIZE",
    "CURSOR_S_RESIZE",
    "CURSOR_W_RESIZE",
    "CURSOR_EW_RESIZE",
    "CURSOR_NS_RESIZE",
    "CURSOR_NESW_RESIZE",
    "CURSOR_NWSE_RESIZE",
    "CURSOR_COL_RESIZE",
    "CURSOR_ROW_RESIZE",
    "CURSOR_TEXT",
    "CURSOR_WAIT",
    "CURSOR_HELP",
    "CURSOR_ALL_SCROLL",
    "CURSOR_WEBKIT_GRAB",
    "CURSOR_WEBKIT_GRABBING",

    -- The following are handled as exceptions so don't need to match.
    "CURSOR_COPY",
    "CURSOR_NONE"
});
ComputedStyleConstants.CursorEnum = CursorEnum;

local DisplayEnum = EnumCreater.Transform({
    "INLINE", "BLOCK", "LIST_ITEM", "RUN_IN", "COMPACT", "INLINE_BLOCK",
    "TABLE", "INLINE_TABLE", "TABLE_ROW_GROUP",
    "TABLE_HEADER_GROUP", "TABLE_FOOTER_GROUP", "TABLE_ROW",
    "TABLE_COLUMN_GROUP", "TABLE_COLUMN", "TABLE_CELL",
    "TABLE_CAPTION", "BOX", "INLINE_BOX",
--#if ENABLE(CSS3_FLEXBOX)
    "FLEXBOX", "INLINE_FLEXBOX",
--#endif
    "NONE"
});
ComputedStyleConstants.DisplayEnum = DisplayEnum;

local InsideLinkEnum = EnumCreater.Transform({
    "NotInsideLink", "InsideUnvisitedLink", "InsideVisitedLink"
});
ComputedStyleConstants.InsideLinkEnum = InsideLinkEnum;
    
local PointerEventsEnum = EnumCreater.Transform({
    "PE_NONE", "PE_AUTO", "PE_STROKE", "PE_FILL", "PE_PAINTED", "PE_VISIBLE",
    "PE_VISIBLE_STROKE", "PE_VISIBLE_FILL", "PE_VISIBLE_PAINTED", "PE_ALL"
});
ComputedStyleConstants.PointerEventsEnum = PointerEventsEnum;

local TransformStyle3DEnum = EnumCreater.Transform({
    "TransformStyle3DFlat", "TransformStyle3DPreserve3D"
});
ComputedStyleConstants.TransformStyle3DEnum = TransformStyle3DEnum;

local BackfaceVisibilityEnum = EnumCreater.Transform({
    "BackfaceVisibilityVisible", "BackfaceVisibilityHidden"
});
ComputedStyleConstants.BackfaceVisibilityEnum = BackfaceVisibilityEnum;
    
local LineClampTypeEnum = EnumCreater.Transform({ "LineClampLineCount", "LineClampPercentage"});
ComputedStyleConstants.LineClampTypeEnum = LineClampTypeEnum;

local HyphensEnum = EnumCreater.Transform({ "HyphensNone", "HyphensManual", "HyphensAuto"});
ComputedStyleConstants.HyphensEnum = HyphensEnum;

local SpeakEnum = EnumCreater.Transform({ "SpeakNone", "SpeakNormal", "SpeakSpellOut", "SpeakDigits", "SpeakLiteralPunctuation", "SpeakNoPunctuation"});
ComputedStyleConstants.SpeakEnum = SpeakEnum;

local TextEmphasisFillEnum = EnumCreater.Transform({ "TextEmphasisFillFilled", "TextEmphasisFillOpen"});
ComputedStyleConstants.TextEmphasisFillEnum = TextEmphasisFillEnum;

local TextEmphasisMarkEnum = EnumCreater.Transform({ "TextEmphasisMarkNone", "TextEmphasisMarkAuto", "TextEmphasisMarkDot", "TextEmphasisMarkCircle", "TextEmphasisMarkDoubleCircle", "TextEmphasisMarkTriangle", "TextEmphasisMarkSesame", "TextEmphasisMarkCustom"});
ComputedStyleConstants.TextEmphasisMarkEnum = TextEmphasisMarkEnum;

local TextEmphasisPositionEnum = EnumCreater.Transform({ "TextEmphasisPositionOver", "TextEmphasisPositionUnder"});
ComputedStyleConstants.TextEmphasisPositionEnum = TextEmphasisPositionEnum;

local TextOverflowEnum = EnumCreater.Transform({ "TextOverflowClip", "TextOverflowEllipsis"});
ComputedStyleConstants.TextOverflowEnum = TextOverflowEnum;

local ImageRenderingEnum = EnumCreater.Transform({ "ImageRenderingAuto", "ImageRenderingOptimizeSpeed", "ImageRenderingOptimizeQuality", "ImageRenderingOptimizeContrast"});
ComputedStyleConstants.ImageRenderingEnum = ImageRenderingEnum;

local OrderEnum = EnumCreater.Transform({ "LogicalOrder", "VisualOrder"});
ComputedStyleConstants.OrderEnum = OrderEnum;

local RegionOverflowEnum = EnumCreater.Transform({ "AutoRegionOverflow", "BreakRegionOverflow"});
ComputedStyleConstants.RegionOverflowEnum = RegionOverflowEnum;

local PageSizeTypeEnum = EnumCreater.Transform({
    "PAGE_SIZE_AUTO", -- size: auto
    "PAGE_SIZE_AUTO_LANDSCAPE", -- size: landscape
    "PAGE_SIZE_AUTO_PORTRAIT", -- size: portrait
    "PAGE_SIZE_RESOLVED" -- Size is fully resolved.
});

ComputedStyleConstants.PageSizeTypeEnum = PageSizeTypeEnum;

local LineBoxContainEnum = EnumCreater.Transform({ {"LineBoxContainNone", 0x0}, {"LineBoxContainBlock", 0x1}, {"LineBoxContainInline", 0x2}, {"LineBoxContainFont", 0x4}, {"LineBoxContainGlyphs", 0x8},
                           {"LineBoxContainReplaced", 0x10}, {"LineBoxContainInlineBox", 0x20}});
ComputedStyleConstants.LineBoxContainEnum = LineBoxContainEnum;

ComputedStyleConstants.TextDirectionEnum = EnumCreater.Transform({ "RTL", "LTR" });

ComputedStyleConstants.UnicodeBidiEnum = EnumCreater.Transform({ 
	"UBNormal",
    "Embed",
    "Override",
    "Isolate",
    "Plaintext",
});


-- Must follow CSSValueKeywords.in order
ComputedStyleConstants.ControlPartEnum = EnumCreater.Transform({
    "NoControlPart", "CheckboxPart", "RadioPart", "NarrowPart", "PushButtonPart", "SquareButtonPart", "ButtonPart",
	"ButtonBevelPart", "DefaultButtonPart", "InnerSpinButtonPart", "InputSpeechButtonPart", "ListButtonPart", "ListboxPart", "ListItemPart",
	"MediaFullscreenButtonPart", "MediaMuteButtonPart", "MediaPlayButtonPart", "MediaSeekBackButtonPart",
	"MediaSeekForwardButtonPart", "MediaRewindButtonPart", "MediaReturnToRealtimeButtonPart", "MediaToggleClosedCaptionsButtonPart",
	"MediaSliderPart", "MediaSliderThumbPart", "MediaVolumeSliderContainerPart", "MediaVolumeSliderPart", "MediaVolumeSliderThumbPart",
	"MediaVolumeSliderMuteButtonPart", "MediaControlsBackgroundPart", "MediaControlsFullscreenBackgroundPart", "MediaCurrentTimePart", "MediaTimeRemainingPart",
	"MenulistPart", "MenulistButtonPart", "MenulistTextPart", "MenulistTextFieldPart", "MeterPart", "ProgressBarPart", "ProgressBarValuePart",
	"SliderHorizontalPart", "SliderVerticalPart", "SliderThumbHorizontalPart",
	"SliderThumbVerticalPart", "CaretPart", "SearchFieldPart", "SearchFieldDecorationPart",
	"SearchFieldResultsDecorationPart", "SearchFieldResultsButtonPart",
	"SearchFieldCancelButtonPart", "TextFieldPart",
	"RelevancyLevelIndicatorPart", "ContinuousCapacityLevelIndicatorPart", "DiscreteCapacityLevelIndicatorPart", "RatingLevelIndicatorPart",
	"TextAreaPart", "CapsLockIndicatorPart"
});