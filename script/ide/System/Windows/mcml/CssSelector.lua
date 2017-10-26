--[[
Title: selector of css style
Author(s): LiPeng
Date: 2017/10/23
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/CssSelector.lua");
local CssSelector = commonlib.gettable("System.Windows.mcml.CssSelector");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/CssSelectorItem.lua");
local CssSelectorItem = commonlib.gettable("System.Windows.mcml.CssSelectorItem");
local CssSelector = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.CssSelector"));

function CssSelector:ctor()
	self.element = nil;
	--self.ancestor = nil;
end

-- init a css selector with the params which content name, class, id, attr infomations;
-- @param name: 
function CssSelector:init(name, classes, id, attrs)
	if(classes or id or attrs) then
		self.element = CssSelectorItem:new();
		self.element:init(name, classes, id, attrs);
	else
		self:parse(name);
	end
	return self;
end

function CssSelector:match(pageElement)
	return self.element:match(pageElement);
end

-- @param str: string,like as: "div.red#important input.redbutton#warning[type=\"button\"]"
function CssSelector:parse(str)
	local elements_info = {};
	for element_info in string.gmatch(str,"[^%s]+") do
		elements_info[#elements_info+1] = element_info;
	end
	self:init_recursive(elements_info);
end

function CssSelector:init_recursive(elements_info)
	local element;
	for i = #elements_info,1,-1 do
		if(not element) then
			self.element = CssSelectorItem:new():init(elements_info[i]);
			element = self.element;
		else
			element.ancestor = CssSelectorItem:new():init(elements_info[i]);
			element = element.ancestor;
		end
	end
end

