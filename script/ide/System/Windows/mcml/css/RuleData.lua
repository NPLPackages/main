--[[
Title: style color
Author(s): LiPeng
Date: 2017/11/3
Desc: css style color

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/css/RuleData.lua");
local RuleData = commonlib.gettable("System.Windows.mcml.css.RuleData");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleRule.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/SelectorChecker.lua");
local SelectorChecker = commonlib.gettable("System.Windows.mcml.css.SelectorChecker");

local RuleData = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.css.RuleData"));

function RuleData:ctor()
	-- self.rule 是一个CSSStyleRule对象。
	self.rule = nil;
	-- self.selector_index 是 当前selector在rule中的selector_list的索引
	self.selector_index = nil;
	self.selector = nil;
	self.isFastCheckableSelector = nil;
end

function RuleData:init(rule, selector_index)
	self.rule = rule;
	self.selector_index = selector_index;

	local selector = self:Selector();
	if(selector) then
		self.isFastCheckableSelector = SelectorChecker:isFastCheckableSelector(selector)
	else
		self.isFastCheckableSelector = false;
	end
	return self;
end

function RuleData:hasFastCheckableSelector()
	return self.isFastCheckableSelector;
end

function RuleData:Rule()
	return self.rule;
end

function RuleData:Selector()
	if(not self.selector) then
		if(self.rule and self.selector_index) then
			self.selector = self.rule:SelectorAt(self.selector_index);
		end
	end
	return self.selector;
end