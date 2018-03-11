--[[
Title: style color
Author(s): LiPeng
Date: 2017/11/3
Desc: css style color

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleSheet.lua");
local CSSStyleSheet = commonlib.gettable("System.Windows.mcml.css.CSSStyleSheet");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSParser.lua");
local CSSParser = commonlib.gettable("System.Windows.mcml.css.CSSParser");

local CSSStyleSheet = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.css.CSSStyleSheet"));

function CSSStyleSheet:ctor()
	self.filename = nil;
	-- CSSStyleRule 
	self.child_rules = {};
	-- determined self created from <pe:style> <style> <link> or external css file.
	self.is_inline_stylesheet = true;
end

function CSSStyleSheet:loadFromFile(filename)
	CSSParser:parse(filename, self);
	return self;
end

function CSSStyleSheet:loadFromString(str)
	CSSParser:LoadCssFromString(str, self);
	return self;
end

function CSSStyleSheet:loadFromTable(styles)
	CSSParser:LoadFromTable(styles, self);
	return self;
end


-- set file name. 
function CSSStyleSheet:SetFileName(filename)
	self.filename = filename;
end

-- get file name. 
function CSSStyleSheet:GetFileName()
	return self.filename;
end

-- @param rule: the CSSStyleRule object
function CSSStyleSheet:AddStyleRule(rule)
	self.child_rules[#self.child_rules + 1] = rule;
end

function CSSStyleSheet:ChildRules()
	return self.child_rules;
end

--function CSSStyleSheet:print()
--	for i = 1, #self.child_rules do
--		local rule = self.child_rules[i];
--		local sele
--	end
--end

