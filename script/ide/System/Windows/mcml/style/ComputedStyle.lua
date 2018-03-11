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

NPL.load("(gl)script/ide/System/Core/ToolBase.lua");

NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleDeclaration.lua");
local CSSStyleDeclaration = commonlib.gettable("System.Windows.mcml.css.CSSStyleDeclaration");

local ComputedStyle = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Windows.mcml.style.ComputedStyle"));
ComputedStyle:Property("Name", "ComputedStyle");


ComputedStyle:Signal("Changed");
--ComputedStyle:Signal("PositionChanged");

function ComputedStyle:ctor()
	self.test_name = "ComputedStyle";
	-- the result merged the styles from "id", "class" and inline style (the atrr "style")
	self.properties = nil;
--	-- the inline style (the atrr "style") of the page_element
--	self.inlineStyleDecl = nil;
	-- whether the css selector changed, such as the pageElement attr "id" or "class".
	self.beClassChanged = false;
	-- record the inline style change
	self.changes = {};

	self.box = {
		width = nil,
		height = nil,

		min_width = nil,
		min_height = nil,

		max_width = nil,
		max_height = nil,
	}
	--[[
	Webkit 中 renderstyle的属性集合

	// non-inherited attributes
    DataRef<StyleBoxData> m_box;
    DataRef<StyleVisualData> visual;
    DataRef<StyleBackgroundData> m_background;
    DataRef<StyleSurroundData> surround;
    DataRef<StyleRareNonInheritedData> rareNonInheritedData;

    // inherited attributes
    DataRef<StyleRareInheritedData> rareInheritedData;
    DataRef<StyleInheritedData> inherited;

    // list of associated pseudo styles
    OwnPtr<PseudoStyleCache> m_cachedPseudoStyles;
	]]
end

function ComputedStyle:init(style_decl)
--	style_decl["computed_style"] = self;
--
--	local proxy = {}
--	proxy[index] = style_decl
--	setmetatable(proxy, mt)

	self.properties = style_decl;

	--self:initBox();

	--self:emitChanged();
	self.beClassChanged = true;
	return self;
end

function ComputedStyle:GetStyle()
	return self.properties;
end

function ComputedStyle:GetOriginValue(key)
	return;
end

function ComputedStyle:ChangeValue(key, value)
	if(value == nil) then
		value = self:GetOriginValue(key);
	end
	self.changes[key] = self.changes[key] or {};
	self.changes[key]["old"] = self.changes[key]["old"] or self.properties[key];
	self.changes[key]["new"] = value;
	self.properties[key] = value;
	self:emitChanged();
end

function ComputedStyle:emitChanged()
	self:Changed()
end

function ComputedStyle:BeChanged()
	if(next(self.changes) or self.beClassChanged) then
		return true;
	end
	return false;
end

function ComputedStyle:Diff()
	return self:GetStyle():Diff(self.changes);
end

-- this is called after refreshed the pageElement according the changes table;
function ComputedStyle:ClearChanges()
	self.beClassChanged = false;
	if(next(self.changes)) then
		table.clear(self.changes);
	end
end

--function ComputedStyle:ChangeType()
--	local chagne_type = "ApplyCSS";
--	local key, _ = next(self.changes);
--	while(key) do
--		if(CSSStyleDeclaration.isResetField(key)) then
--			chagne_type = "Layout";
--		end
--	end
--	return chagne_type;
--end

function ComputedStyle:initBox()
	local properties = self.properties;
	self.box.width = properties["width"];
	self.box.height = properties["height"];

	self.box.min_width = properties["min-width"];
	self.box.min_height = properties["min-height"];

	self.box.max_width = properties["max-width"];
	self.box.max_height = properties["max-height"];
end

function ComputedStyle:InheritFrom(style)
	
end

function ComputedStyle:IsFloating() 
	return self:Floating() ~= nil;
end

function ComputedStyle:HasMargin()
	return true;
end

function ComputedStyle:HasBorder()
	return true;
end

function ComputedStyle:HasPadding()
	return true;
end

function ComputedStyle:HasOffset()
	return true;
end

-- margin-left
function ComputedStyle:MarginLeft()
	return self.properties:margin_left();
end

-- margin-top
function ComputedStyle:MarginTop()
	return self.properties:margin_top();
end

-- margin-right
function ComputedStyle:MarginRight()
	return self.properties:margin_right();
end

-- margin-bottom
function ComputedStyle:MarginBottom()
	return self.properties:margin_bottom();
end

-- margins
function ComputedStyle:Margins()
	return self:MarginLeft(), self:MarginTop(), self:MarginRight(), self:MarginBottom();
end

function ComputedStyle:MarginBefore()
	local write_mode = self:WritingMode();
	if(write_mode ==  "TopToBottomWritingMode") then
		return self:MarginTop();
	elseif(write_mode ==  "BottomToTopWritingMode") then
		return self:MarginBottom();
	elseif(write_mode ==  "LeftToRightWritingMode") then
		return self:MarginLeft();
	elseif(write_mode ==  "RightToLeftWritingMode") then
		return self:MarginRight();
	end
	return self:MarginTop();
end

function ComputedStyle:MarginAfter()
	local write_mode = self:WritingMode();
	if(write_mode ==  "TopToBottomWritingMode") then
		return self:MarginBottom();
	elseif(write_mode ==  "BottomToTopWritingMode") then
		return self:MarginTop();
	elseif(write_mode ==  "LeftToRightWritingMode") then
		return self:MarginRight();
	elseif(write_mode ==  "RightToLeftWritingMode") then
		return self:MarginLeft();
	end
	return self:MarginBottom();
end

function ComputedStyle:MarginStart()
	local start_;
	if(self:IsHorizontalWritingMode()) then
		start_ = if_else(self:IsLeftToRightDirection(), self:MarginLeft(), self:MarginRight());
	else
		start_ = if_else(self:IsLeftToRightDirection(), self:MarginTop(), self:MarginBottom());
	end
	return start_;
end

function ComputedStyle:MarginEnd()
	local end_;
	if(self:IsHorizontalWritingMode()) then
		end_ = if_else(self:IsLeftToRightDirection(), self:MarginRight(), self:MarginLeft());
	else
		end_ = if_else(self:IsLeftToRightDirection(), self:MarginBottom(), self:MarginTop());
	end
	return end_;
end

function ComputedStyle:MarginBeforeUsing(otherStyle)
	local write_mode = otherStyle:WritingMode();
	if(write_mode ==  "TopToBottomWritingMode") then
		return self:MarginTop();
	elseif(write_mode ==  "BottomToTopWritingMode") then
		return self:MarginBottom();
	elseif(write_mode ==  "LeftToRightWritingMode") then
		return self:MarginLeft();
	elseif(write_mode ==  "RightToLeftWritingMode") then
		return self:MarginRight();
	end
	return self:MarginTop();
end

function ComputedStyle:MarginAfterUsing(otherStyle)
	local write_mode = otherStyle:WritingMode();
	if(write_mode ==  "TopToBottomWritingMode") then
		return self:MarginBottom();
	elseif(write_mode ==  "BottomToTopWritingMode") then
		return self:MarginTop();
	elseif(write_mode ==  "LeftToRightWritingMode") then
		return self:MarginRight();
	elseif(write_mode ==  "RightToLeftWritingMode") then
		return self:MarginLeft();
	end
	return self:MarginBottom();
end

function ComputedStyle:MarginStartUsing(otherStyle)
	local start_;
	if(otherStyle:IsHorizontalWritingMode()) then
		start_ = if_else(otherStyle:IsLeftToRightDirection(), self:MarginLeft(), self:MarginRight());
	else
		start_ = if_else(otherStyle:IsLeftToRightDirection(), self:MarginTop(), self:MarginBottom());
	end
	return start_;
end

function ComputedStyle:MarginEndUsing(otherStyle)
	local end_;
	if(otherStyle:IsHorizontalWritingMode()) then
		end_ = if_else(otherStyle:IsLeftToRightDirection(), self:MarginRight(), self:MarginLeft());
	else
		end_ = if_else(otherStyle:IsLeftToRightDirection(), self:MarginBottom(), self:MarginTop());
	end
	return end_;
end

-- borders
function ComputedStyle:Border()
	return;
end

-- border-left
function ComputedStyle:BorderLeft()
	--return self.properties:border_left();
end

-- border-top
function ComputedStyle:BorderTop()
	--return self.properties:border_top();
end

-- border-right
function ComputedStyle:BorderRight()
	--return self.properties:border_right();
end

-- border-bottom
function ComputedStyle:BorderBottom()
	--return self.properties:border_bottom();
end

function ComputedStyle:BorderBefore()
	return self:BorderTop();
end

function ComputedStyle:BorderAfter()
	return self:BorderBottom();
end

function ComputedStyle:BorderStart()
	return self:BorderLeft();
end

function ComputedStyle:BorderEnd()
	return self:BorderRight();
end

function ComputedStyle:BorderTopLeftRadius() 
	--return surround->border.topLeft();
end

function ComputedStyle:BorderTopRightRadius() 
	--return surround->border.topRight();
end

function ComputedStyle:BorderBottomLeftRadius()
	--return surround->border.bottomLeft(); 
end
function ComputedStyle:BorderBottomRightRadius()
	--return surround->border.bottomRight(); 
end
function ComputedStyle:HasBorderRadius() 
	--return surround->border.hasBorderRadius(); 
end

function ComputedStyle:BorderLeftWidth()
	return self.properties:border_left_width();
end

function ComputedStyle:BorderLeftStyle()
	return self.properties:border_left_style();
end

function ComputedStyle:BorderLeftIsTransparent() 
	return false;
end

function ComputedStyle:BorderRightWidth()
	return self.properties:border_right_width();
end

function ComputedStyle:BorderRightStyle()
	return self.properties:border_right_style();
end

function ComputedStyle:BorderRightIsTransparent() 
	return false;
end

function ComputedStyle:BorderTopWidth() 
	return self.properties:border_top_width();
end

function ComputedStyle:BorderTopStyle()
	return self.properties:border_top_style();
end

function ComputedStyle:BorderTopIsTransparent() 
	return false;
end

function ComputedStyle:BorderBottomWidth()
	return self.properties:border_bottom_width();
end

function ComputedStyle:BorderBottomStyle()
	return self.properties:border_bottom_style();
end

function ComputedStyle:BorderBottomIsTransparent()
	return false;
end

function ComputedStyle:BorderBeforeWidth()
	return self:BorderTopWidth();
end

function ComputedStyle:BorderAfterWidth()
	return self:BorderBottomWidth();
end

function ComputedStyle:BorderStartWidth()
	return self:BorderLeftWidth();
end

function ComputedStyle:BorderEndWidth()
	return self:BorderRightWidth();
end

-- padding-left
function ComputedStyle:PaddingLeft()
	return self.properties:padding_left();
end

-- padding-top
function ComputedStyle:PaddingTop()
	return self.properties:padding_top();
end

-- padding-right
function ComputedStyle:PaddingRight()
	return self.properties:padding_right();
end

-- padding-bottom
function ComputedStyle:PaddingBottom()
	return self.properties:padding_bottom();
end

-- paddings
function ComputedStyle:Paddings()
	return self:PaddingLeft(), self:PaddingTop(), self:PaddingRight(), self:PaddingBottom();
end

function ComputedStyle:PaddingBox()

end

function ComputedStyle:PaddingBefore()
	return self:PaddingTop();
end

function ComputedStyle:PaddingAfter()
	return self:PaddingBottom();
end

function ComputedStyle:PaddingStart()
	return self:PaddingLeft();
end

function ComputedStyle:PaddingEnd()
	return self:PaddingRight();
end

-- width
function ComputedStyle:Width()
	return self.properties:Width();
end

-- min-width
function ComputedStyle:MinWidth()
	return self.properties:MinWidth();
end

-- max-width
function ComputedStyle:MaxWidth()
	return self.properties:MaxWidth();
end

-- height
function ComputedStyle:Height()
	return self.properties:Height();
end

-- min-height
function ComputedStyle:MinHeight()
	return self.properties:MinHeight();
end

-- max-height
function ComputedStyle:MaxHeight()
	return self.properties:MaxHeight();
end

function ComputedStyle:LogicalWidth()
	if(self:IsHorizontalWritingMode()) then
		return self:Width();
	end
	return self:Height();
end

function ComputedStyle:LogicalHeight()
	if(self:IsHorizontalWritingMode()) then
		return self:Height();
	end
	return self:Width();
end

function ComputedStyle:LogicalMinWidth()
	if(self:IsHorizontalWritingMode()) then
		return self:MinWidth();
	end
	return self:MinHeight();
end

function ComputedStyle:LogicalMaxWidth()
	if(self:IsHorizontalWritingMode()) then
		return self:MaxWidth();
	end
	return self:MaxHeight();
end

function ComputedStyle:LogicalMinHeight()
	if(self:IsHorizontalWritingMode()) then
		return self:MinHeight();
	end
	return self:MinHeight();
end

function ComputedStyle:LogicalMaxHeight()
	if(self:IsHorizontalWritingMode()) then
		return self:MaxHeight();
	end
	return self:MaxWidth();
end

-- left
function ComputedStyle:Left()
	return self.properties:Left();
end

-- top
function ComputedStyle:Top()
	return self.properties:Top();
end

-- right
function ComputedStyle:Right()
	return self.properties:Right();
end

-- bottom
function ComputedStyle:Bottom()
	return self.properties:Bottom();
end

-- Accessors for positioned object edges that take into account writing mode.
function ComputedStyle:LogicalLeft()
	return if_else(self:IsHorizontalWritingMode(),self:Left(),self:Top());
end

function ComputedStyle:LogicalRight()
	return if_else(self:IsHorizontalWritingMode(),self:Right(),self:Bottom());
end

function ComputedStyle:LogicalTop()
	return if_else(self:IsHorizontalWritingMode(), self:Top(), self:Bottom());
	--return if_else(self:IsHorizontalWritingMode() ? (isFlippedBlocksWritingMode() ? bottom() : top()) : (isFlippedBlocksWritingMode() ? right() : left());
end

function ComputedStyle:LogicalBottom()
	return if_else(self:IsHorizontalWritingMode(), self:Bottom(), self:Top());
	--return isHorizontalWritingMode() ? (isFlippedBlocksWritingMode() ? top() : bottom()) : (isFlippedBlocksWritingMode() ? left() : right());
end

-- position
function ComputedStyle:Position()
	return self.properties:Position();
end

-- display
function ComputedStyle:Display()
	return self.properties:Display();
end

function ComputedStyle:OriginalDisplay()
	return "";
end

-- float
function ComputedStyle:Floating()
	return self.properties:Floating();
end

-- algin
function ComputedStyle:Align()
	return self.properties:Align();
end

-- valign
function ComputedStyle:Valign()
	return self.properties:Valign();
end


-----------------------------------------------------------------------------------------------------
----------------	webkit/chromium	function

function ComputedStyle:IsHorizontalWritingMode()
	return true;
end

function ComputedStyle:WritingMode()
	return "TopToBottomWritingMode";	
end

function ComputedStyle:OverflowX()
	return self.properties:OverflowX();
end

function ComputedStyle:OverflowY()
	return self.properties:OverflowY();
end

function ComputedStyle:Visibility()
	return self.properties:Visibility();
end
-- TextDirection, value can be "LTR", "RTL";
function ComputedStyle:Direction() 
	return self.properties:TextDirection();
end

function ComputedStyle:IsLeftToRightDirection()
	return self:Direction() == "LTR";
end

function ComputedStyle:AutoWrap()
	local ws = self:WhiteSpace();
	return ws ~= "nowrap" and ws ~= "pre";
end

function ComputedStyle:WhiteSpace()
	return "normal";
end

function ComputedStyle:BoxSizing()
	return "CONTENT_BOX"
end
-- property "text-overflow"
function ComputedStyle:TextOverflow()
	return "clip";
end

--// Static pseudo styles. Dynamic ones are produced on the fly.
--enum PseudoId {
--    // The order must be NOP ID, public IDs, and then internal IDs.
--    NOPSEUDO, FIRST_LINE, FIRST_LETTER, BEFORE, AFTER, SELECTION, FIRST_LINE_INHERITED, SCROLLBAR,
--    // Internal IDs follow:
--    SCROLLBAR_THUMB, SCROLLBAR_BUTTON, SCROLLBAR_TRACK, SCROLLBAR_TRACK_PIECE, SCROLLBAR_CORNER, RESIZER,
--    INPUT_LIST_BUTTON,
--    AFTER_LAST_INTERNAL_PSEUDOID,
--    FULL_SCREEN, FULL_SCREEN_DOCUMENT, FULL_SCREEN_ANCESTOR, ANIMATING_FULL_SCREEN_TRANSITION,
--    FIRST_PUBLIC_PSEUDOID = FIRST_LINE,
--    FIRST_INTERNAL_PSEUDOID = SCROLLBAR_THUMB,
--    PUBLIC_PSEUDOID_MASK = ((1 << FIRST_INTERNAL_PSEUDOID) - 1) & ~((1 << FIRST_PUBLIC_PSEUDOID) - 1)
--};
function ComputedStyle:StyleType()
	return "NOPSEUDO";
end

function ComputedStyle:SpecifiesColumns()
	return false;
end

function ComputedStyle:ColumnSpan()
	return false;
end

-- return: "HORIZONTAL", "VERTICAL"
function ComputedStyle:BoxOrient()
	return "HORIZONTAL";
end

--return: "BSTRETCH", "BSTART", "BCENTER", "BEND", "BJUSTIFY", "BBASELINE"
function ComputedStyle:BoxAlign()
	return "BSTRETCH";
end
--TAAUTO, LEFT, RIGHT, CENTER, JUSTIFY, WEBKIT_LEFT, WEBKIT_RIGHT, WEBKIT_CENTER, TASTART, TAEND
function ComputedStyle:TextAlign()
	return "TAAUTO";
end
-- return: "MCOLLAPSE", "MSEPARATE", "MDISCARD"
function ComputedStyle:MarginBeforeCollapse()
	return "MCOLLAPSE";
end
-- return: "MCOLLAPSE", "MSEPARATE", "MDISCARD"
function ComputedStyle:MarginAfterCollapse()
	return "MCOLLAPSE";
end

function ComputedStyle:HasAutoColumnCount()
	return true;
end

function ComputedStyle:HasAutoColumnWidth()
	return true;
end