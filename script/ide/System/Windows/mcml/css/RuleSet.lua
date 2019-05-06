--[[
Title: style color
Author(s): LiPeng
Date: 2017/11/3
Desc: css style color

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/css/RuleSet.lua");
local RuleSet = commonlib.gettable("System.Windows.mcml.css.RuleSet");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleSheet.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/RuleData.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSSelector.lua");
local CSSSelector = commonlib.gettable("System.Windows.mcml.css.CSSSelector");
local RuleData = commonlib.gettable("System.Windows.mcml.css.RuleData");
local CSSStyleSheet = commonlib.gettable("System.Windows.mcml.css.CSSStyleSheet");

local RuleSet = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.css.RuleSet"));

function RuleSet:ctor()
	self.id_rules = {};
	self.class_rules = {};
	self.tag_rules = {};

	self.universal_rules = {};
--[[
	Map结构的规则集合，key是字符串格式的id或class或者tag，value是一个RuleData的数组 
	PendingRuleMap id_rules;
    PendingRuleMap class_rules;
    PendingRuleMap tag_rules;
]]
end

function RuleSet:idRules()
	return self.id_rules;
end

function RuleSet:classRules()
	return self.class_rules;
end

function RuleSet:tagRules()
	return self.tag_rules;
end

function RuleSet:universalRules()
	return self.universal_rules;
end

function RuleSet:AddToRuleSet(key, map, rule_data)
	local rules = map[key];
	if(not rules) then
		rules = {};
		map[key] = rules;
	end
	rules[#rules+1] = rule_data;
	--rule_data:SetFastCheckableSelector(true);
end

function RuleSet:AddRulesFromSheet(stylesheet)
	if(stylesheet) then
		self:AddChildRules(stylesheet:ChildRules());
	end
end

function RuleSet:AddChildRules(rules)
	for rule_index = 1,#rules do
		local rule = rules[rule_index];
		local selector_list =  rule:GetSelectorList();
		for selector_index = 1,#selector_list do
			--local selector = selector_list[selector_index];
			self:AddRule(rule,selector_index);
		end
	end
end

function RuleSet:AddRule(rule,selector_index)
	local rule_data = RuleData:new():init(rule,selector_index);
	if(not self:FindBestRuleSetAndAdd(rule_data:Selector(),rule_data)) then
		self.universal_rules[#self.universal_rules+1] = rule_data;
	end
end

local selector_info = {
	id = nil,
	class_name = nil,
	tag_name = nil
};

local function ExtractSelectorValues(selector)
	if(selector) then
		if(selector:Match() == CSSSelector.MatchType.kId) then
			selector_info.id = selector:Value();
		elseif(selector:Match() == CSSSelector.MatchType.kClass) then
			selector_info.class_name = selector:Value();
		elseif(selector:Match() == CSSSelector.MatchType.kTag) then
			selector_info.tag_name = selector:Value();
		elseif(selector:Match() == CSSSelector.MatchType.kPseudoClass or 
			selector:Match() == CSSSelector.MatchType.kPseudoElement or 
			selector:Match() == CSSSelector.MatchType.kPagePseudoClass) then
				-- TODO: latter handle the pseudo_class and pseudo_element selector
		end
	end
end

function RuleSet:FindBestRuleSetAndAdd(selector, rule_data)
	selector_info.id, selector_info.class_name, selector_info.tag_name = nil, nil, nil;
	while(selector and selector:Relation() == CSSSelector.RelationType.kSubSelector) do
		ExtractSelectorValues(selector);
		selector = selector:TagHistory();
	end
	ExtractSelectorValues(selector);
	local id, class_name, tag_name = selector_info.id, selector_info.class_name, selector_info.tag_name;
	if(id and id~="") then
		self:AddToRuleSet(id, self.id_rules, rule_data);
		return true;
	end
	if(class_name and class_name~="") then
		self:AddToRuleSet(class_name, self.class_rules, rule_data);
		return true;
	end
	if(tag_name and tag_name~="") then
		self:AddToRuleSet(tag_name, self.tag_rules, rule_data);
		return true;
	end
	return false;
end
