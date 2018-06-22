--[[
Title: 
Author(s): LiPeng
Date: 2018/6/11
Desc: singleton class for CSSStyleApplyProperty. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleApplyProperty.lua");
local CSSStyleApplyProperty = commonlib.gettable("System.Windows.mcml.css.CSSStyleApplyProperty");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");


local ApplyPropertyBase = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.css.ApplyPropertyBase"));

--void applyValue(CSSStyleSelector*, CSSValue*)
function ApplyPropertyBase:ApplyValue(selector, css_value)

end

--virtual void applyInheritValue(CSSStyleSelector*) const = 0;
function ApplyPropertyBase:ApplyInheritValue(selector)

end

--virtual void applyInitialValue(CSSStyleSelector*) const = 0;
function ApplyPropertyBase:ApplyInitialValue(selector)

end

local ApplyPropertyExpanding = commonlib.inherit(commonlib.gettable("System.Windows.mcml.css.ApplyPropertyBase"), commonlib.gettable("System.Windows.mcml.css.ApplyPropertyExpanding"));

function ApplyPropertyExpanding:ctor()
	self.propertyMap = {};
end

--ApplyPropertyExpanding(ApplyPropertyBase* one = 0, ApplyPropertyBase* two = 0, ApplyPropertyBase *three = 0, ApplyPropertyBase* four = 0)
function ApplyPropertyExpanding:init(one, two, three, four)
	self.propertyMap[1] = one;
	self.propertyMap[2] = two;
	self.propertyMap[3] = three;
	self.propertyMap[4] = four;
	self.propertyMap[5] = nil;

	return self;
end

--virtual void applyInheritValue(CSSStyleSelector* selector) const
function ApplyPropertyExpanding:ApplyInheritValue(selector)
	for _, element in ipairs(self.propertyMap) do
		if(element) then
			element:ApplyInheritValue(selector);
		end
	end
end

--virtual void applyInitialValue(CSSStyleSelector* selector) const
function ApplyPropertyExpanding:ApplyInitialValue(selector)
    for _, element in ipairs(self.propertyMap) do
		if(element) then
			element:ApplyInitialValue(selector);
		end
	end
end

--virtual void applyValue(CSSStyleSelector* selector, CSSValue* value) const
function ApplyPropertyExpanding:ApplyValue(selector, value)
--    if (!expandValue)
--        return;

    for _, element in ipairs(self.propertyMap) do
		if(element) then
			element:ApplyValue(selector, value);
		end
	end
end

local ApplyPropertyDefaultBase = commonlib.inherit(commonlib.gettable("System.Windows.mcml.css.ApplyPropertyBase"), commonlib.gettable("System.Windows.mcml.css.ApplyPropertyDefaultBase"));

function ApplyPropertyDefaultBase:ctor()
	self.getter = nil;
	self.setter = nil;
	self.initial = nil;
end

function ApplyPropertyDefaultBase:init(getter, setter, initial)
	self.getter = getter;
	self.setter = setter;
	self.initial = initial;

	return self;
end

--void setValue(RenderStyle* style, SetterType value) const
function ApplyPropertyDefaultBase:SetValue(style, value)
    self.setter(style, value);
end

--GetterType value(RenderStyle* style) const
function ApplyPropertyDefaultBase:Value(style)
    return self.getter(style);
end

--InitialType initial() const
function ApplyPropertyDefaultBase:Initial()
	if(self.initial) then
		return self.initial();
	end
	return;
end

--virtual void applyInheritValue(CSSStyleSelector*) const = 0;
function ApplyPropertyDefaultBase:ApplyInheritValue(selector)
	self:SetValue(selector:Style(), self:Value(selector:ParentStyle()));
end

--virtual void applyInitialValue(CSSStyleSelector*) const = 0;
function ApplyPropertyDefaultBase:ApplyInitialValue(selector)
	self:SetValue(selector:Style(), self:Initial());
end


local ApplyPropertyDefault = commonlib.inherit(commonlib.gettable("System.Windows.mcml.css.ApplyPropertyDefaultBase"), commonlib.gettable("System.Windows.mcml.css.ApplyPropertyDefault"));

function ApplyPropertyDefault:ApplyValue(selector, value)
	self:SetValue(selector:Style(), value);
end


--local ApplyPropertyLength = commonlib.inherit(commonlib.gettable("System.Windows.mcml.css.ApplyPropertyDefault"), commonlib.gettable("System.Windows.mcml.css.ApplyPropertyLength"));
--
--function ApplyPropertyDefault:ApplyValue(selector, value)
--	self:SetValue(selector:Style(), value);
--end



local CSSStyleApplyProperty = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.css.CSSStyleApplyProperty"));

function CSSStyleApplyProperty:ctor()
	self.propertyMap = {};
end

function CSSStyleApplyProperty:init()
	self:SetPropertyHandler("color", ApplyPropertyDefault:new():init(ComputedStyle.Color, ComputedStyle.SetColor, ComputedStyle.initialColor));
	self:SetPropertyHandler("direction", ApplyPropertyDefault:new():init(ComputedStyle.Direction, ComputedStyle.SetDirection, ComputedStyle.initialDirection));

	self:SetPropertyHandler("background-image", ApplyPropertyDefault:new():init(ComputedStyle.BackgroundImage, ComputedStyle.SetBackgroundImage, ComputedStyle.initialBackgroundImage));
	self:SetPropertyHandler("background-color", ApplyPropertyDefault:new():init(ComputedStyle.BackgroundColor, ComputedStyle.SetBackgroundColor, ComputedStyle.initialBackgroundColor));

	self:SetPropertyHandler("border-bottom-color", ApplyPropertyDefault:new():init(ComputedStyle.BorderBottomColor, ComputedStyle.SetBorderBottomColor, ComputedStyle.initialColor));
	self:SetPropertyHandler("border-left-color", ApplyPropertyDefault:new():init(ComputedStyle.BorderLeftColor, ComputedStyle.SetBorderLeftColor, ComputedStyle.initialColor));
	self:SetPropertyHandler("border-right-color", ApplyPropertyDefault:new():init(ComputedStyle.BorderRightColor, ComputedStyle.SetBorderRightColor, ComputedStyle.initialColor));
	self:SetPropertyHandler("border-top-color", ApplyPropertyDefault:new():init(ComputedStyle.BorderTopColor, ComputedStyle.SetBorderTopColor, ComputedStyle.initialColor));

	self:SetPropertyHandler("border-bottom-style", ApplyPropertyDefault:new():init(ComputedStyle.BorderBottomStyle, ComputedStyle.SetBorderBottomColor, ComputedStyle.initialBorderStyle));
	self:SetPropertyHandler("border-left-style", ApplyPropertyDefault:new():init(ComputedStyle.BorderLeftStyle, ComputedStyle.SetBorderLeftColor, ComputedStyle.initialBorderStyle));
	self:SetPropertyHandler("border-right-style", ApplyPropertyDefault:new():init(ComputedStyle.BorderRightStyle, ComputedStyle.SetBorderRightColor, ComputedStyle.initialBorderStyle));
	self:SetPropertyHandler("border-top-style", ApplyPropertyDefault:new():init(ComputedStyle.BorderTopStyle, ComputedStyle.SetBorderTopColor, ComputedStyle.initialBorderStyle));

	self:SetPropertyHandler("border-bottom-width", ApplyPropertyDefault:new():init(ComputedStyle.BorderBottomWidth, ComputedStyle.SetBorderBottomWidth, ComputedStyle.initialBorderWidth));
	self:SetPropertyHandler("border-left-width", ApplyPropertyDefault:new():init(ComputedStyle.BorderLeftWidth, ComputedStyle.SetBorderLeftWidth, ComputedStyle.initialBorderWidth));
	self:SetPropertyHandler("border-right-width", ApplyPropertyDefault:new():init(ComputedStyle.BorderRightWidth, ComputedStyle.SetBorderRightWidth, ComputedStyle.initialBorderWidth));
	self:SetPropertyHandler("border-top-width", ApplyPropertyDefault:new():init(ComputedStyle.BorderTopWidth, ComputedStyle.SetBorderTopWidth, ComputedStyle.initialBorderWidth));

	self:SetPropertyHandler("border-style", ApplyPropertyExpanding:new():init(self:PropertyHandler("border-bottom-style"), self:PropertyHandler("border-left-style"), self:PropertyHandler("border-right-style"), self:PropertyHandler("border-top-style")));
	self:SetPropertyHandler("border-width", ApplyPropertyExpanding:new():init(self:PropertyHandler("border-bottom-width"), self:PropertyHandler("border-left-width"), self:PropertyHandler("border-right-width"), self:PropertyHandler("border-top-width")));
	self:SetPropertyHandler("border-color", ApplyPropertyExpanding:new():init(self:PropertyHandler("border-bottom-color"), self:PropertyHandler("border-left-color"), self:PropertyHandler("border-right-color"), self:PropertyHandler("border-top-color")));

	self:SetPropertyHandler("font-size", ApplyPropertyDefault:new():init(ComputedStyle.FontSize, ComputedStyle.SetFontSize));
	self:SetPropertyHandler("font-weight", ApplyPropertyDefault:new():init(ComputedStyle.FontBold, ComputedStyle.SetFontBold));
	self:SetPropertyHandler("font-family", ApplyPropertyDefault:new():init(ComputedStyle.FontFamily, ComputedStyle.SetFontFamily));

	self:SetPropertyHandler("overflow-x", ApplyPropertyDefault:new():init(ComputedStyle.OverflowX, ComputedStyle.SetOverflowX, ComputedStyle.initialOverflowX));
	self:SetPropertyHandler("overflow-y", ApplyPropertyDefault:new():init(ComputedStyle.OverflowY, ComputedStyle.SetOverflowY, ComputedStyle.initialOverflowY));
	self:SetPropertyHandler("overflow", ApplyPropertyExpanding:new():init(self:PropertyHandler("overflow-x"), self:PropertyHandler("overflow-y")));

	self:SetPropertyHandler("top", ApplyPropertyDefault:new():init(ComputedStyle.Top, ComputedStyle.SetTop, ComputedStyle.initialOffset));
	self:SetPropertyHandler("right", ApplyPropertyDefault:new():init(ComputedStyle.Right, ComputedStyle.SetRight, ComputedStyle.initialOffset));
	self:SetPropertyHandler("bottom", ApplyPropertyDefault:new():init(ComputedStyle.Bottom, ComputedStyle.SetBottom, ComputedStyle.initialOffset));
	self:SetPropertyHandler("left", ApplyPropertyDefault:new():init(ComputedStyle.Left, ComputedStyle.SetLeft, ComputedStyle.initialOffset));

	self:SetPropertyHandler("width", ApplyPropertyDefault:new():init(ComputedStyle.Width, ComputedStyle.SetWidth, ComputedStyle.initialSize));
	self:SetPropertyHandler("height", ApplyPropertyDefault:new():init(ComputedStyle.Height, ComputedStyle.SetHeight, ComputedStyle.initialSize));

	self:SetPropertyHandler("max-width", ApplyPropertyDefault:new():init(ComputedStyle.MaxWidth, ComputedStyle.SetMaxWidth, ComputedStyle.initialMaxSize));
	self:SetPropertyHandler("max-height", ApplyPropertyDefault:new():init(ComputedStyle.MaxHeight, ComputedStyle.SetMaxHeight, ComputedStyle.initialMaxSize));
	self:SetPropertyHandler("min-width", ApplyPropertyDefault:new():init(ComputedStyle.MinWidth, ComputedStyle.SetMinWidth, ComputedStyle.initialMinSize));
	self:SetPropertyHandler("min-height", ApplyPropertyDefault:new():init(ComputedStyle.MinHeight, ComputedStyle.SetMinHeight, ComputedStyle.initialMinSize));

	self:SetPropertyHandler("margin-top", ApplyPropertyDefault:new():init(ComputedStyle.MarginTop, ComputedStyle.SetMarginTop, ComputedStyle.initialMargin));
	self:SetPropertyHandler("margin-bottom", ApplyPropertyDefault:new():init(ComputedStyle.MarginBottom, ComputedStyle.SetMarginBottom, ComputedStyle.initialMargin));
	self:SetPropertyHandler("margin-left", ApplyPropertyDefault:new():init(ComputedStyle.MarginLeft, ComputedStyle.SetMarginLeft, ComputedStyle.initialMargin));
	self:SetPropertyHandler("margin-right", ApplyPropertyDefault:new():init(ComputedStyle.MarginRight, ComputedStyle.SetMarginRight, ComputedStyle.initialMargin));
	self:SetPropertyHandler("margin", ApplyPropertyExpanding:new():init(self:PropertyHandler("margin-top"), self:PropertyHandler("margin-bottom"), self:PropertyHandler("margin-left"), self:PropertyHandler("margin-right")));

	self:SetPropertyHandler("padding-top", ApplyPropertyDefault:new():init(ComputedStyle.PaddingTop, ComputedStyle.SetPaddingTop, ComputedStyle.initialPadding));
	self:SetPropertyHandler("padding-bottom", ApplyPropertyDefault:new():init(ComputedStyle.PaddingBottom, ComputedStyle.SetPaddingBottom, ComputedStyle.initialPadding));
	self:SetPropertyHandler("padding-left", ApplyPropertyDefault:new():init(ComputedStyle.PaddingLeft, ComputedStyle.SetPaddingLeft, ComputedStyle.initialPadding));
	self:SetPropertyHandler("padding-right", ApplyPropertyDefault:new():init(ComputedStyle.PaddingRight, ComputedStyle.SetPaddingRight, ComputedStyle.initialPadding));
	self:SetPropertyHandler("padding", ApplyPropertyExpanding:new():init(self:PropertyHandler("padding-top"), self:PropertyHandler("padding-bottom"), self:PropertyHandler("padding-left"), self:PropertyHandler("padding-right")));

	self:SetPropertyHandler("caret-color", ApplyPropertyDefault:new():init(ComputedStyle.CaretColor, ComputedStyle.SetCaretColor, ComputedStyle.initialColor));
	self:SetPropertyHandler("text-align", ApplyPropertyDefault:new():init(ComputedStyle.TextAlign, ComputedStyle.SetTextAlign, ComputedStyle.initialTextAlign));

	self:SetPropertyHandler("float", ApplyPropertyDefault:new():init(ComputedStyle.Float, ComputedStyle.SetFloat, ComputedStyle.initialFloat));
	self:SetPropertyHandler("position", ApplyPropertyDefault:new():init(ComputedStyle.Position, ComputedStyle.SetPosition, ComputedStyle.initialPosition));
	self:SetPropertyHandler("display", ApplyPropertyDefault:new():init(ComputedStyle.Display, ComputedStyle.SetDisplay, ComputedStyle.initialDisplay));
	self:SetPropertyHandler("visibility", ApplyPropertyDefault:new():init(ComputedStyle.Visibility, ComputedStyle.SetVisibility, ComputedStyle.initialVisibility));


	self:SetPropertyHandler("text-shadow", ApplyPropertyDefault:new():init(ComputedStyle.TextShadow, ComputedStyle.SetTextShadow));
	self:SetPropertyHandler("line-height", ApplyPropertyDefault:new():init(ComputedStyle.LineHeight, ComputedStyle.SetLineHeight, ComputedStyle.initialLineHeight));
	--self:SetPropertyHandler("border", ApplyPropertyExpanding:new():init(ComputedStyle.BorderTopWidth, ComputedStyle.SetBorderTopWidth, ComputedStyle.initialBorderWidth));
	--setPropertyHandler(CSSPropertyColor, new ApplyPropertyColor<InheritFromParent>(&RenderStyle::color, &RenderStyle::setColor,  &RenderStyle::setVisitedLinkColor, 0, RenderStyle::initialColor));

	return self;
end

--void setPropertyHandler(CSSPropertyID property, ApplyPropertyBase* value)
-- @param name: the property name
-- @param handler: the property apply handler
function CSSStyleApplyProperty:SetPropertyHandler(name, handler)
	self.propertyMap[name] = handler;
end

local cssStyleApplyPropertyInstance;

local function initSingleton()
	cssStyleApplyPropertyInstance = CSSStyleApplyProperty:new():init();
end

function CSSStyleApplyProperty:SharedCSSStyleApplyProperty()
	if(not cssStyleApplyPropertyInstance) then
		initSingleton();
	end
	return cssStyleApplyPropertyInstance;
end

--ApplyPropertyBase* propertyHandler(CSSPropertyID property) const
function CSSStyleApplyProperty:PropertyHandler(name)
    --ASSERT(valid(property));
    return self.propertyMap[name];
end