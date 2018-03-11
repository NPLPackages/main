--[[
Title: style color
Author(s): LiPeng
Date: 2017/11/3
Desc: css style color

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleRule.lua");
local CSSStyleRule = commonlib.gettable("System.Windows.mcml.css.CSSStyleRule");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleDeclaration.lua");
local CSSStyleDeclaration = commonlib.gettable("System.Windows.mcml.css.CSSStyleDeclaration");

local CSSStyleRule = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.css.CSSStyleRule"));

function CSSStyleRule:ctor()
	self.selector_list = nil;
	self.properties = nil;
	--[[
	-- selector列表 
	CSSSelectorList selector_list_;
	-- property 集合，对应 CSSStyleDeclaration 对象
	mutable Member<CSSPropertyValueSet> properties_;
	mutable Member<CSSLazyPropertyParser> lazy_property_parser_;
	]]
end

function CSSStyleRule:init(selector_list, properties)
	self.selector_list = selector_list;
	self.properties = properties;
	return self;
end

function CSSStyleRule:GetSelectorList()
	if(not self.selector_list) then
		self.selector_list = {};
	end
	return self.selector_list;
end

function CSSStyleRule:SelectorAt(index)
	local selector_list = self:GetSelectorList();
	if(index > #selector_list) then
		return;
	end
	return selector_list[index];
end

function CSSStyleRule:GetProperties()
	if(not self.properties) then
		self.properties = CSSStyleDeclaration:new();
	end
	return self.properties;
end

