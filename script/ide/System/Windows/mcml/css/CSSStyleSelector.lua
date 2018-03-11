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
local SelectorChecker = commonlib.gettable("System.Windows.mcml.css.SelectorChecker");
local CSSStyleDefault = commonlib.gettable("System.Windows.mcml.css.CSSStyleDefault");
local RuleSet = commonlib.gettable("System.Windows.mcml.css.RuleSet");
local StyleSheetManager = commonlib.gettable("System.Windows.mcml.css.StyleSheetManager");
local CSSStyleSheet = commonlib.gettable("System.Windows.mcml.css.CSSStyleSheet");
local CSSStyleDeclaration = commonlib.gettable("System.Windows.mcml.css.CSSStyleDeclaration");

local CSSStyleSelector = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.css.CSSStyleSelector"));

local function LoalDefaultStyle()
	local rule_set = RuleSet:new();

	local stylesheet = CSSStyleSheet:new():loadFromTable(CSSStyleDefault.items);
	rule_set:AddRulesFromSheet(stylesheet);

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


	-- 应该是存储匹配结果，暂时没用到
	self.matchedDels = nil;
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

function CSSStyleSelector:ApplyToStyleDeclaration(style_decl, pageElement)
	if(style_decl and pageElement) then
		self:MatchUARules(style_decl, pageElement);
		self:MatchAuthorRules(style_decl, pageElement);
	end
end

-- user agent rule: here is default style
function CSSStyleSelector:MatchUARules(style_decl, pageElement)
	self:MatchRules(style_decl, pageElement, defaultStyle);
end

function CSSStyleSelector:MatchAuthorRules(style_decl, pageElement)
	self:MatchRules(style_decl, pageElement, self.authorStyle);
end

function CSSStyleSelector:MatchRules(style_decl, pageElement, rule_set)
	if(not rule_set) then
		return;
	end
	local id = pageElement:GetAttributeWithCode("id",nil,true);
	if(id) then
		self:MatchRulesForList(style_decl, pageElement,rule_set:idRules()[id]);
	end

	local classNames = pageElement:GetClassNames();
	if(classNames) then
		for class, _ in pairs(classNames) do
			--local class = classNames[i];
			self:MatchRulesForList(style_decl, pageElement,rule_set:classRules()[class]);
		end
	end

	local tag = pageElement.name;
	self:MatchRulesForList(style_decl, pageElement,rule_set:tagRules()[tag]);
	self:MatchRulesForList(style_decl, pageElement,rule_set:universalRules());
end

function CSSStyleSelector:MatchRulesForList(style_decl, pageElement, rule_list)
	if(rule_list) then
		for i = 1,#rule_list do
			local rule_data = rule_list[i];
			if(self:checkSelector(rule_data, pageElement)) then
				style_decl:Merge(rule_data:Rule():GetProperties());
			end
		end
	end
end

function CSSStyleSelector:checkSelector(rule_data, pageElement)
	if(rule_data) then
		if(rule_data:hasFastCheckableSelector()) then
			return SelectorChecker:fastCheckSelector(rule_data:Selector(), pageElement);
		end
		return SelectorChecker:checkSelector(rule_data:Selector(), pageElement);
	end
	return false;
end