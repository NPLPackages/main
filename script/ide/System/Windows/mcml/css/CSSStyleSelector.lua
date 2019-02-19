--[[
Title: style color
Author(s): LiPeng
Date: 2017/11/3
Desc: css style color

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleSelector.lua");
local CSSStyleSelector = commonlib.gettable("System.Windows.mcml.css.CSSStyleSelector");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleDeclaration.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleSheet.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleSheetManager.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/RuleSet.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleDefault.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/SelectorChecker.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleApplyProperty.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutTheme.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local LayoutTheme = commonlib.gettable("System.Windows.mcml.layout.LayoutTheme");
local CSSStyleApplyProperty = commonlib.gettable("System.Windows.mcml.css.CSSStyleApplyProperty");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");
local SelectorChecker = commonlib.gettable("System.Windows.mcml.css.SelectorChecker");
local CSSStyleDefault = commonlib.gettable("System.Windows.mcml.css.CSSStyleDefault");
local RuleSet = commonlib.gettable("System.Windows.mcml.css.RuleSet");
local StyleSheetManager = commonlib.gettable("System.Windows.mcml.css.StyleSheetManager");
local CSSStyleSheet = commonlib.gettable("System.Windows.mcml.css.CSSStyleSheet");
local CSSStyleDeclaration = commonlib.gettable("System.Windows.mcml.css.CSSStyleDeclaration");

local OverflowEnum = ComputedStyleConstants.OverflowEnum;
local PositionEnum = ComputedStyleConstants.PositionEnum;

local MatchedStyleDeclaration = {};
MatchedStyleDeclaration.__index = MatchedStyleDeclaration;

function MatchedStyleDeclaration:new(decl, type)
	local o = {};
	o.styleDeclaration = decl;
	o.linkMatchType = type;
	setmetatable(o, self);
	return o;
end


local CSSStyleSelector = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.css.CSSStyleSelector"));

local function LoalDefaultStyle()
	local rule_set = RuleSet:new();

--	local stylesheet = CSSStyleSheet:new():loadFromTable(CSSStyleDefault.items);
--	rule_set:AddRulesFromSheet(stylesheet);

	stylesheet = CSSStyleSheet:new():loadFromFile("script/ide/System/Windows/mcml/css/html.css")
	rule_set:AddRulesFromSheet(stylesheet);


	return rule_set;
end

local defaultStyle;

function CSSStyleSelector:ctor()
	-- defaultStyle,authorStyle is RuleSet
	if(not defaultStyle) then
		defaultStyle = LoalDefaultStyle();
	end

	self.authorStyle = nil;
	
	self.stylesheets = {};


	-- store the MatchedStyleDeclaration object;
	self.matchedDecls = commonlib.vector:new();

	self.style = nil;
	self.parentStyle = nil;

	self.element = nil;

	self.parentNode = nil;

	self.applyProperty = CSSStyleApplyProperty:SharedCSSStyleApplyProperty();
end

function CSSStyleSelector:Style()
	return self.style;
end

--RenderStyle* parentStyle() const { return m_parentStyle; }
function CSSStyleSelector:ParentStyle()
	return self.parentStyle;
end

function CSSStyleSelector:AddStyleSheetFromFile(filename)
	if(filename) then
		local stylesheet = StyleSheetManager:GetStyleSheet(filename);
		self:AddStyleSheet(stylesheet);
	end
end

-- @param code: code should be a pure NPL table like { ["div"] = {background="", },  }
function CSSStyleSelector:AddStyleSheetFromTable(tab)
	if(tab) then
		local stylesheet = CSSStyleSheet:new():loadFromTable(tab);
		self:AddStyleSheet(stylesheet);
	end
end

-- @param code: code should be a css style sheet string like  h1, h2 {color:red;margin:5px; }
function CSSStyleSelector:AddStyleSheetFromString(str)
	if(str and str ~= "") then
		local stylesheet = CSSStyleSheet:new():loadFromString(str);
		self:AddStyleSheet(stylesheet);	
	end
end

function CSSStyleSelector:AddStyleSheet(stylesheet)
	if(stylesheet) then
		local stylesheets = self.stylesheets;
		for i=1, #(stylesheets) do
			if(stylesheets[i] == stylesheet) then
				return;
			end
		end
		stylesheets[#stylesheets+1] = stylesheet;
		self:MapStyleSheetToRuleSet(stylesheet);	
	end
end

-- remove a given reference
function CSSStyleSelector:RemoveStyleSheet(stylesheet)
	if(stylesheet) then
		local stylesheets = self.stylesheets;
		local index;
		for i=1, #(stylesheets) do
			if(stylesheets[i] == stylesheet) then
				index = i;
				break;
			end
		end
		commonlib.removeArrayItem(stylesheets, index);
	end
end

function CSSStyleSelector:MapStyleSheetToRuleSet(stylesheet)
	if(not self.authorStyle) then
		self.authorStyle = RuleSet:new();
	end
	self.authorStyle:AddRulesFromSheet(stylesheet);
end

--void CSSStyleSelector::matchAllRules(MatchResult& result)
function CSSStyleSelector:MatchAllRules(result)
	self:MatchUARules(result);
	self:MatchAuthorRules(result);

	local attributeMap = self.element:AttributeMap();
	for attrName, styleDecl in pairs(attributeMap) do
		self:AddMatchedDeclaration(styleDecl);
	end

	local inlineDecl = self.element:InlineStyleDecl();
	if(inlineDecl) then
		self:AddMatchedDeclaration(inlineDecl);
	end
end

-- user agent rule: here is default style
function CSSStyleSelector:MatchUARules()
	self:MatchRules(defaultStyle);
end

function CSSStyleSelector:MatchAuthorRules()
	self:MatchRules(self.authorStyle);
end

function CSSStyleSelector:MatchRules(rule_set)
	if(not rule_set) then
		return;
	end
	local id = self.element:GetAttributeWithCode("id",nil,true);
	if(id) then
		self:MatchRulesForList(rule_set:idRules()[id]);
	end

	local classNames = self.element:GetClassNames();
	if(classNames) then
		for class, _ in pairs(classNames) do
			self:MatchRulesForList(rule_set:classRules()[class]);
		end
	end

	local tag = self.element:TagName();
	echo(tag)
	self:MatchRulesForList(rule_set:tagRules()[tag]);
	self:MatchRulesForList(rule_set:universalRules());
end

--void CSSStyleSelector::addMatchedDeclaration(CSSMutableStyleDeclaration* decl, unsigned linkMatchType)
function CSSStyleSelector:AddMatchedDeclaration(decl, linkMatchType)
    self.matchedDecls:append(MatchedStyleDeclaration:new(decl, linkMatchType));
end

function CSSStyleSelector:MatchRulesForList(rule_list)
	if(self.element.name == "pe:container") then
		echo("CSSStyleSelector:checkSelector failed")
		echo(rule_list)
	end
	if(rule_list) then
		for i = 1,#rule_list do
			local rule_data = rule_list[i];
			if(self:checkSelector(rule_data, self.element)) then
				self:AddMatchedDeclaration(rule_data:Rule():GetProperties());
				--style_decl:Merge(rule_data:Rule():GetProperties());
			else
				
			end
		end
	end
end

function CSSStyleSelector:checkSelector(rule_data, pageElement)
	if(rule_data) then
		if(not SelectorChecker:TagMatches(pageElement, rule_data:Selector())) then
			return false;
		end
		if(rule_data:hasFastCheckableSelector()) then
			return SelectorChecker:fastCheckSelector(rule_data:Selector(), pageElement);
		end
		return SelectorChecker:checkSelector(rule_data:Selector(), pageElement);
	end
	return false;
end

--void CSSStyleSelector::initElement(Element* e)
function CSSStyleSelector:InitElement(e)
	if(e ~= self.element) then
		self.element = e;
	end
end

--inline void CSSStyleSelector::initForStyleResolve(Element* e, RenderStyle* parentStyle, PseudoId pseudoID)
function CSSStyleSelector:InitForStyleResolve(e, parentStyle, pseudoID)
    --m_checker.setPseudoStyle(pseudoID);

	if(e) then
		self.parentNode = e:ParentNodeForRenderingAndStyle();
	end
    

    if (parentStyle) then
        self.parentStyle = parentStyle;
    elseif(self.parentNode) then
        self.parentStyle = self.parentNode:GetComputedStyle();
	end

--    Node* docElement = e ? e->document()->documentElement() : 0;
--    RenderStyle* docStyle = m_checker.document()->renderStyle();
--    m_rootElementStyle = docElement && e != docElement ? docElement->renderStyle() : docStyle;

    self.style = nil;

    self.matchedDecls:clear();

--    m_pendingImageProperties.clear();
--
--    m_ruleList = 0;
--
--    m_fontDirty = false;
end

--PassRefPtr<RenderStyle> CSSStyleSelector::styleForElement(Element* element, RenderStyle* defaultParent, bool allowSharing, bool resolveForRootDefault)
function CSSStyleSelector:StyleForElement(element, defaultParent, allowSharing, resolveForRootDefault)
	echo("CSSStyleSelector:StyleForElement")
	echo(element.name)
	allowSharing = if_else(allowSharing == nil, true, allowSharing);
	resolveForRootDefault = if_else(resolveForRootDefault == nil, false, resolveForRootDefault);

	self:InitElement(element);
	self:InitForStyleResolve(element, defaultParent);

--	if (allowSharing) {
--        RenderStyle* sharedStyle = locateSharedStyle();
--        if (sharedStyle)
--            return sharedStyle;
--    }
	self.style = ComputedStyle:new();

	if (self.parentStyle) then
        self.style:InheritFrom(self.parentStyle);
--    else
--        m_parentStyle = style();
--        // Make sure our fonts are initialized if we don't inherit them from our parent style.
--        m_style->font().update(0);
	end
	
	local matchResult;
	self:MatchAllRules(matchResult);

	self:ApplyMatchedDeclarations(matchResult);
	-- Clean up our style object's display and text decorations (among other fixups).
    self:AdjustRenderStyle(self:Style(), self.parentStyle, element);
	self:InitElement();	-- Clear out for the next resolve.
	return self.style;
end

--void CSSStyleSelector::applyMatchedDeclarations(const MatchResult& matchResult)
function CSSStyleSelector:ApplyMatchedDeclarations(matchResult)
	local matchedDecls = self.matchedDecls;
	local size = matchedDecls:size();
	for i = 1, size do
		self:ApplyDeclaration(matchedDecls:get(i).styleDeclaration);
	end
end

--void CSSStyleSelector::adjustRenderStyle(RenderStyle* style, RenderStyle* parentStyle, Element *e)
function CSSStyleSelector:AdjustRenderStyle(style, parentStyle, e)
	-- Cache our original display.
    style:SetOriginalDisplay(style:Display());
	-- TODO: add latter;

	-- Make sure our z-index value is only applied if the object is positioned.
    if (style:Position() == PositionEnum.StaticPosition) then
        style:SetHasAutoZIndex();
	end

	-- Auto z-index becomes 0 for the root element and transparent objects.  This prevents
    -- cases where objects that should be blended as a single unit end up with a non-transparent
    -- object wedged in between them.  Auto z-index also becomes 0 for objects that specify transforms/masks/reflections.
    if (style:HasAutoZIndex() and ((e and e:Document():DocumentElement() == e) or style:Opacity() < 1
        --or style:HasTransformRelatedProperty() or style:HasMask() or style:BoxReflect())) then
		or style:HasMask())) then
        style:SetZIndex(0);
	end

	-- Textarea considers overflow visible as auto.
    if (e and e:HasTagName("textarea")) then
        style:SetOverflowX(if_else(style:OverflowX() == OverflowEnum.OVISIBLE, OverflowEnum.OAUTO, style:OverflowX()));
        style:SetOverflowY(if_else(style:OverflowY() == OverflowEnum.OVISIBLE, OverflowEnum.OAUTO, style:OverflowY()));
    end

	-- If either overflow value is not visible, change to auto.
    if (style:OverflowX() == OverflowEnum.OMARQUEE and style:OverflowY() ~= OverflowEnum.OMARQUEE) then
        style:SetOverflowY(OverflowEnum.OMARQUEE);
    elseif (style:OverflowY() == OverflowEnum.OMARQUEE and style:OverflowX() ~= OverflowEnum.OMARQUEE) then
        style:SetOverflowX(OverflowEnum.OMARQUEE);
    elseif (style:OverflowX() == OverflowEnum.OVISIBLE and style:OverflowY() ~= OverflowEnum.OVISIBLE) then
        style:SetOverflowX(OverflowEnum.OAUTO);
    elseif (style:OverflowY() == OverflowEnum.OVISIBLE and style:OverflowX() ~= OverflowEnum.OVISIBLE) then
        style:SetOverflowY(OverflowEnum.OAUTO);
	end

	-- Let the theme also have a crack at adjusting the style.
    if (style:HasAppearance()) then
        --RenderTheme::defaultTheme()->adjustStyle(this, style, e, m_hasUAAppearance, m_borderData, m_backgroundData, m_backgroundColor);
		LayoutTheme:DefaultTheme():AdjustStyle(self, style, e);
	end
end


function CSSStyleSelector:ApplyDeclaration(styleDeclaration)
	for property in styleDeclaration:Next() do
		self:ApplyProperty(property:Name(), property:CreateValueFromCssString());
	end
end

function CSSStyleSelector:ApplyProperty(name, value)
	local isInherit = self.parentNode ~= nil and value == "inherit";
	local isInitial = value == "initial" or (self.parentNode == nil and value == "inherit");

	local handler = self.applyProperty:PropertyHandler(name);
	if(handler) then
		if(isInherit) then
			handler:ApplyInheritValue(self);
		elseif (isInitial) then
            handler:ApplyInitialValue(self);
		else
			handler:ApplyValue(self, value);
		end
	end
end