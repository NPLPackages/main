--[[
Title: 
Author(s): LiPeng
Date: 2018/10/18
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutTheme.lua");
local LayoutTheme = commonlib.gettable("System.Windows.mcml.layout.LayoutTheme");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
local Length = commonlib.gettable("System.Windows.mcml.platform.Length");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");

local LayoutTheme = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.LayoutTheme"));

local ControlPartEnum = ComputedStyleConstants.ControlPartEnum;
local LengthTypeEnum = Length.LengthTypeEnum;

function LayoutTheme:ctor()

end

local default_theme = nil;

function LayoutTheme:DefaultTheme()
	if(not default_theme) then
		default_theme = LayoutTheme:new();
	end
	return default_theme;
end

--void RenderTheme::adjustStyle(CSSStyleSelector* selector, RenderStyle* style, Element* e,
--                              bool UAHasAppearance, const BorderData& border, const FillLayer& background, const Color& backgroundColor)
function LayoutTheme:AdjustStyle(selector, style, e, UAHasAppearance, border, background, backgroundColor)
	

	if (not style:HasAppearance()) then
        return;
	end

	local part = style:Appearance();
	if(part == ControlPartEnum.CheckboxPart) then
		return self:AdjustCheckboxStyle(selector, style, e);
	end
	if(part == ControlPartEnum.RadioPart) then
		return self:AdjustRadioStyle(selector, style, e);
	end
end

--void RenderTheme::adjustCheckboxStyle(CSSStyleSelector*, RenderStyle* style, Element*) const
function LayoutTheme:AdjustCheckboxStyle(selector, style, element)
    -- A summary of the rules for checkbox designed to match WinIE:
    -- width/height - honored (WinIE actually scales its control for small widths, but lets it overflow for small heights.)
    -- font-size - not honored (control has no text), but we use it to decide which control size to use.
    self:SetCheckboxSize(style);

    -- padding - not honored by WinIE, needs to be removed.
    style:ResetPadding();

    -- border - honored by WinIE, but looks terrible (just paints in the control box and turns off the Windows XP theme)
    -- for now, we will not honor it.
    style:ResetBorder();

    --style->setBoxShadow(nullptr);
end

--void RenderThemeWin::setCheckboxSize(RenderStyle* style) const
function LayoutTheme:SetCheckboxSize(style)
    -- If the width and height are both specified, then we have nothing to do.
    if (not style:Width():IsIntrinsicOrAuto() and not style:Height():IsAuto()) then
        return;
	end

    -- FIXME:  A hard-coded size of 13 is used.  This is wrong but necessary for now.  It matches Firefox.
    -- At different DPI settings on Windows, querying the theme gives you a larger size that accounts for
    -- the higher DPI.  Until our entire engine honors a DPI setting other than 96, we can't rely on the theme's
    -- metrics.
    if (style:Width():IsIntrinsicOrAuto()) then
        style:SetWidth(Length:new(13, LengthTypeEnum.Fixed));
	end
    if (style:Height():IsAuto()) then
        style:SetHeight(Length:new(13, LengthTypeEnum.Fixed));
	end
end

--void RenderThemeWin::setCheckboxSize(RenderStyle* style) const
function LayoutTheme:SetRadioSize(style)
	self:SetCheckboxSize(style);
end

--void RenderTheme::adjustRadioStyle(CSSStyleSelector*, RenderStyle* style, Element*) const
function LayoutTheme:AdjustRadioStyle(selector, style, element)
    -- A summary of the rules for checkbox designed to match WinIE:
    -- width/height - honored (WinIE actually scales its control for small widths, but lets it overflow for small heights.)
    -- font-size - not honored (control has no text), but we use it to decide which control size to use.
    self:SetRadioSize(style);

    -- padding - not honored by WinIE, needs to be removed.
    style:ResetPadding();

    -- border - honored by WinIE, but looks terrible (just paints in the control box and turns off the Windows XP theme)
    -- for now, we will not honor it.
    style:ResetBorder();

    --style->setBoxShadow(nullptr);
end

--bool RenderTheme::isControlContainer(ControlPart appearance) const
function LayoutTheme:IsControlContainer(appearance)
    -- There are more leaves than this, but we'll patch this function as we add support for
    -- more controls.
    return appearance ~= ControlPartEnum.CheckboxPart and appearance ~= ControlPartEnum.RadioPart;
end

--int RenderTheme::baselinePosition(const RenderObject* o) const
function LayoutTheme:BaselinePosition(o)
    if (not o:IsBox()) then
        return 0;
	end

    local box = o:ToRenderBox();

--#if USE(NEW_THEME)
--    return box->height() + box->marginTop() + m_theme->baselinePositionAdjustment(o->style()->appearance()) * o->style()->effectiveZoom();
--#else
    --return math.floor(box:Height()*0.95+0.5);
	return box:MarginTop();
--#endif
end