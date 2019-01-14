--[[
Title: selector checker
Author(s): LiPeng
Date: 2017/11/3
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/css/SelectorChecker.lua");
local SelectorChecker = commonlib.gettable("System.Windows.mcml.css.SelectorChecker");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSSelector.lua");
local CSSSelector = commonlib.gettable("System.Windows.mcml.css.CSSSelector");

local SelectorChecker = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.css.SelectorChecker"));

function SelectorChecker:ctor()
	self.selector = nil;
	self.pageElement = nil;
end

-- match complex selector; 
function SelectorChecker:checkSelector()
	return false;
end

-- in fastCheckSelector mode ,the relationtype must be one of the "kDescendant","kChild", "kSubSelector"
function SelectorChecker:fastCheckSelector(selector, pageElement)
	while(selector) do
		if(not self:fastCheckRightmostSelector(selector, pageElement)) then
			return false;
		end
		
		if (selector:Relation() ~= CSSSelector.RelationType.kSubSelector) then
			local beMatched,newPageElement = self:fastCheckSingleSelector(selector:TagHistory(),pageElement:GetParent());
			if(not beMatched) then
				return false;
			else
				pageElement = newPageElement;
			end
		end
		selector = selector:TagHistory();
	end
	return true;
end

function SelectorChecker:fastCheckRightmostSelector(selector, pageElement)
	if(not selector or not pageElement) then
		return false;
	end
	local value = selector:Value();
	local matchtype = selector:Match();
	if(matchtype == CSSSelector.MatchType.kUnknown) then
		return true;
	elseif(matchtype == CSSSelector.MatchType.kTag) then
		return pageElement:TagName() == value;
	elseif(matchtype == CSSSelector.MatchType.kId) then
		local id = pageElement:GetAttributeWithCode("id",nil,true);
		return id == value;
	elseif(matchtype == CSSSelector.MatchType.kClass) then
		local classNames = pageElement:GetClassNames();
		if(classNames) then
			return classNames[value];
		end
		return false;
	elseif(matchtype >= CSSSelector.MatchType.kAttributeExact or matchtype <= CSSSelector.MatchType.kAttributeEnd) then
		return self:CheckAttribute(selector, pageElement);
	end
	return false;
end

function SelectorChecker:fastCheckSingleSelector(selector, pageElement)
	if(not pageElement) then
		return false;
	end
	if (selector:Relation() == CSSSelector.RelationType.kDescendant) then
		if(not self:fastCheckRightmostSelector(selector,pageElement)) then
			return self:fastCheckSingleSelector(selector, pageElement:GetParent());
		end
	elseif (selector:Relation() == CSSSelector.RelationType.kChild) then
		if(not self:fastCheckRightmostSelector(selector,pageElement)) then
			return false;
		end
	end
	return true, pageElement;
end

function SelectorChecker:CheckAttribute(selector, pageElement)
	local attribute = selector:Attribute();
	local value = selector:Value();
	local matchtype = selector:Match();
	local attribute_value = pageElement:GetAttributeWithCode(attribute,nil,true);
	if(matchtype == CSSSelector.MatchType.kAttributeExact) then
		return value == attribute_value;
	elseif(matchtype == CSSSelector.MatchType.kAttributeSet) then
		return if_else(attribute_value,true,false);
	end
	return false;
end

-- static function check the selector can check fastly.
function SelectorChecker:isFastCheckableSelector(selector)
	if (not self:isFastCheckableRightmostSelector(selector)) then
        return false;
	end
	selector = selector:TagHistory();
	while(selector) do
		if (not self:isFastCheckableRelation(selector:Relation())) then
            return false;
		end
        if (not self:isFastCheckableMatch(selector)) then
            return false;
		end
		selector = selector:TagHistory()
	end
    return true;
end

function SelectorChecker:isFastCheckableRightmostSelector(selector)
	 if (not self:isFastCheckableRelation(selector:Relation())) then
        return false;
	end
	return self:isFastCheckableMatch(selector);
    --return slef:isFastCheckableMatch(selector) || SelectorChecker::isCommonPseudoClassSelector(selector);
end

function SelectorChecker:isFastCheckableRelation(relation)
    return relation == CSSSelector.RelationType.kDescendant or relation == CSSSelector.RelationType.kChild or relation == CSSSelector.RelationType.kSubSelector;
end

function SelectorChecker:isFastCheckableMatch(selector)
	local matchtype = selector:Match();
	if (matchtype == CSSSelector.MatchType.kAttributeSet or matchtype == CSSSelector.MatchType.kAttributeExact) then
        return true;
	end
    return matchtype == matchtype == CSSSelector.MatchType.kUnknown or matchtype == CSSSelector.MatchType.kId or matchtype == CSSSelector.MatchType.kClass or matchtype == CSSSelector.MatchType.kTag;
end

--inline bool SelectorChecker::tagMatches(const Element* element, const CSSSelector* selector)
function SelectorChecker:TagMatches(element, selector)
    if (not selector:HasTag()) then
        return true;
	end	
	--local tag = string.gsub(selector:Tag(),"pe:","");
	local tag = selector:Tag();
	return tag == element:TagName();
--    const AtomicString& localName = selector->tag().localName();
--    if (localName != starAtom && localName != element->localName())
--        return false;
--    const AtomicString& namespaceURI = selector->tag().namespaceURI();
--    return namespaceURI == starAtom || namespaceURI == element->namespaceURI();
end