--[[
Title: CSSSelector
Author(s): LiPeng
Date: 2017/10/23
Desc: 

References: CSSSelector class in chromium

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSSelector.lua");
local CSSSelector = commonlib.gettable("System.Windows.mcml.css.CSSSelector");
------------------------------------------------------------
]]
local CSSSelector = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.css.CSSSelector"));

local MatchType = {
    "kUnknown",
	-- Example: div
    "kTag",               
	-- Example: #id
    "kId",                
	-- example: .class
    "kClass",             
	-- Example:  :nth-child(2)
    "kPseudoClass",       
	-- Example:  ::first-line
    "kPseudoElement",     
	-- ??
    "kPagePseudoClass",   
	-- Example: E[foo="bar"]
    "kAttributeExact",    
	-- Example: E[foo]
    "kAttributeSet",      
	-- Example: E[foo|="bar"]
    "kAttributeHyphen",   
	-- Example: E[foo~="bar"]
    "kAttributeList",     
	-- css3: E[foo*="bar"]
    "kAttributeContain",  
	-- css3: E[foo^="bar"]
    "kAttributeBegin",    
	-- css3: E[foo$="bar"]
    "kAttributeEnd",      
--    "kFirstAttributeSelectorMatch = kAttributeExact,
  };

local RelationType = {
	-- No combinator
    "kSubSelector",
	-- "Space" combinator
    "kDescendant",       
	-- ">" combinator
    "kChild",        
	-- "+" combinator     
    "kDirectAdjacent",  
	-- "~" combinator  
    "kIndirectAdjacent", 
--    // Special cases for shadow DOM related selectors.
--    kShadowPiercingDescendant,  // >>> combinator
--    kShadowDeep,                // /deep/ combinator
--    kShadowDeepAsDescendant,    // /deep/ as an alias for descendant
--    kShadowPseudo,              // ::shadow pseudo element
--    kShadowSlot                 // ::slotted() pseudo element
  };

--local AttributeMatchType = {
--    "kCaseSensitive",
--    "kCaseInsensitive",
--  };


local function CreatEnumTable(tbl, index) 
    if(type(tbl) ~= "table") then
		return;
	end
    local enumtbl = {} 
    local enumindex = index or 0 
    for i, v in ipairs(tbl) do 
        enumtbl[v] = enumindex + i 
    end 
    return enumtbl;
end

CSSSelector.MatchType = CreatEnumTable(MatchType);
CSSSelector.RelationType = CreatEnumTable(RelationType);
--CSSSelector.AttributeMatchType = CreatEnumTable(AttributeMatchType);

function CSSSelector:ctor()
	self.value = nil;

	self.relation = CSSSelector.RelationType.kSubSelector;
	
	self.match = CSSSelector.MatchType.kUnknown;

	self.is_last_in_tag_history = nil;
	self.is_last_in_selector_list = nil;

	

	-- attribute selector 
	self.attribute = nil;
--	self.AttributeMatchType = nil;

	self.tag_history = nil;

	self.tag = "*";
end

function CSSSelector:Tag()
	return self.tag;
end

function CSSSelector:SetTag(tag)
	self.tag = tag;
end

function CSSSelector:HasTag()
	return self.tag ~= "*";
end

function CSSSelector:Value()
	return self.value;
end

function CSSSelector:SetValue()
	self.value = value;
end

function CSSSelector:Attribute()
	return self.attribute;
end

function CSSSelector:SetRelationType(relation)
	self.relation = relation;
end

function CSSSelector:Relation()
	return self.relation;
end

function CSSSelector:Match()
	return self.match;
end

function CSSSelector:SetMatch(match)
	self.match = match;
end

-- init a css selector with the params which content name, class, id, attr infomations;
function CSSSelector:init(value, match, attribute, tag)
	self.value = value or self.value;

	self.match = match or self.match;
	-- attribute selector 
	self.attribute = attribute or self.attribute;
	self.tag = tag;
	return self;
end

function CSSSelector:IsLastInTagHistory()
	return if_else(self.tag_history, false, true);
end

function CSSSelector:IsLastInSelectorList() 
	return self.is_last_in_selector_list; 
end

-- The TagHistory is a linked list that stores combinator separated compound
-- selectors from right-to-left. Yet, within a single compound selector,
-- stores the simple selectors from left-to-right.
function CSSSelector:TagHistory()
	return self.tag_history;
end

function CSSSelector:SetTagHistory(selector)
	self.tag_history = selector;
end

function CSSSelector:AppendTagHistory(selector, relation)
	local end_selector = self;
	while(not end_selector:IsLastInTagHistory()) do
		end_selector = end_selector:TagHistory();
	end
	end_selector:SetRelationType(relation or CSSSelector.RelationType.kSubSelector);
	end_selector:SetTagHistory(selector);
end

function CSSSelector:print()
	if(self.tag_history) then
		self.tag_history:print();
	end
end

