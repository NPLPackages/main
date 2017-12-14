--[[
Title: 
Author(s): LiPeng
Date: 2017/11/3
Desc: CSS selector parser

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSSelectorParser.lua");
local CSSSelectorParser = commonlib.gettable("System.Windows.mcml.css.CSSSelectorParser");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSSelector.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleSheet.lua");
NPL.load("(gl)script/ide/math/StringUtil.lua");
local StringUtil = commonlib.gettable("mathlib.StringUtil");
local CSSStyleSheet = commonlib.gettable("System.Windows.mcml.css.CSSStyleSheet");
local CSSSelector = commonlib.gettable("System.Windows.mcml.css.CSSSelector");

local CSSSelectorParser = commonlib.gettable("System.Windows.mcml.css.CSSSelectorParser");

local isInited;
function CSSSelectorParser:StaticInit()
	if(isInited) then
		return
	end
	isInited = true;
end

function CSSSelectorParser:parse(str)
	self:StaticInit();
	return self:ConsumeCompoundSelector(str);
end

-- @param str: string,like as: "div.red#important input.redbutton#warning[type=\"button\"]"
function CSSSelectorParser:ConsumeCompoundSelector(str)
	-- consume the whitespace, tranfor the format like "p > h1" to "p>h1"
	str = string.gsub(str,"(%s*)([+>~])(%s*)","%2");

	local selectorInfos = {};
	for combinator,selectorStr in string.gmatch(str,"([%s+>~]?)([^%s+>~]+)") do
		selectorInfos[#selectorInfos+1] = {["combinator"] = combinator};
		local subselectors = selectorInfos[#selectorInfos];
		for flag,value in string.gfind(selectorStr,"([.#%[]?)([^.#%[]+)") do
			subselectors[#subselectors + 1] = {flag, value};
		end
	end

	local selector;
	local compound_selector,simple_selector;
	local relation;
	local combinator, flag, value;
	for i = #selectorInfos, 1, -1 do
		local selectorInfo = selectorInfos[i];
		for j = 1,#selectorInfo do
			local subselector = selectorInfo[j];
			local flag = subselector[1];
			local value = subselector[2];
			simple_selector = self:ConsumeSimpleSelector(flag, value);
			if(j == 1) then
				if(compound_selector) then
					compound_selector:AppendTagHistory(simple_selector,relation);
				end
			else
				if(compound_selector) then
					compound_selector:AppendTagHistory(simple_selector);
				end
			end
			selector = selector or simple_selector;
			compound_selector = simple_selector;
		end
		relation = self:GetRelationType(selectorInfo.combinator);
	end
	return selector;
end

function CSSSelectorParser:GetRelationType(combinator)
	local relationType = CSSSelector.RelationType.kSubSelector;
	if(combinator == " ") then
		relationType = CSSSelector.RelationType.kDescendant;
	elseif(combinator == ">") then
		relationType = CSSSelector.RelationType.kChild;
	elseif(combinator == "+") then
		relationType = CSSSelector.RelationType.kDirectAdjacent;
	elseif(combinator == "~") then
		relationType = CSSSelector.RelationType.kIndirectAdjacent;
	end
	return relationType;
end

function CSSSelectorParser:GetMatchType(flag)
	local matchType = CSSSelector.MatchType.kUnknown;
	if(flag == "") then
		matchType = CSSSelector.MatchType.kTag;
	elseif(flag == ".") then
		matchType = CSSSelector.MatchType.kClass;
	elseif(flag == "#") then
		matchType = CSSSelector.MatchType.kId;
	elseif(flag == "[") then
		matchType = CSSSelector.MatchType.kAttributeSet;
	end
	return matchType;
end

function CSSSelectorParser:GetAttribute(str)
	str = string.gsub(str, "]", "");
	local name,flag,value = string.match(str,"([^=|~*^$]+)([=|~*^$]*)([^^=|~*^$]*)");
	local matchtype = CSSSelector.MatchType.kAttributeSet;
	if(flag) then
		if(flag == "=") then
			matchType = CSSSelector.MatchType.kAttributeExact;
		elseif(flag == "|=") then
			matchType = CSSSelector.MatchType.kAttributeHyphen;
		elseif(flag == "~=") then
			matchType = CSSSelector.MatchType.kAttributeList;
		elseif(flag == "*=") then
			matchType = CSSSelector.MatchType.kAttributeContain;
		elseif(flag == "^=") then
			matchType = CSSSelector.MatchType.kAttributeBegin;
		elseif(flag == "$=") then
			matchType = CSSSelector.MatchType.kAttributeEnd;
		end
	end
	return name, value, matchtype;
end

-- @param flag: the selector flag, such as: ".", "#", "[", etc.
-- @param value:string the selector value.
function CSSSelectorParser:ConsumeSimpleSelector(flag, value)
	local matchtype = self:GetMatchType(flag);
	local attribute;
	if(matchtype == CSSSelector.MatchType.kAttributeSet) then
		local attribute_name,attribute_value,attribute_matchtype = self:GetAttribute(value);
		attribute = attribute_name;
		value = attribute_value;
		matchtype = attribute_matchtype;
	end
	return CSSSelector:new():init(value,matchtype,attribute);
end