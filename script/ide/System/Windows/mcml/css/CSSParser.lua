--[[
Title: style color
Author(s): LiPeng
Date: 2017/11/3
Desc: css style color

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSParser.lua");
local CSSParser = commonlib.gettable("System.Windows.mcml.css.CSSParser");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSSelector.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleSheet.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleRule.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSSelectorParser.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleDeclaration.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/mcml.lua");
local mcml = commonlib.gettable("System.Windows.mcml");
local CSSStyleDeclaration = commonlib.gettable("System.Windows.mcml.css.CSSStyleDeclaration");
local CSSSelectorParser = commonlib.gettable("System.Windows.mcml.css.CSSSelectorParser");
local CSSStyleRule = commonlib.gettable("System.Windows.mcml.css.CSSStyleRule");
local CSSStyleSheet = commonlib.gettable("System.Windows.mcml.css.CSSStyleSheet");
local CSSSelector = commonlib.gettable("System.Windows.mcml.css.CSSSelector");

local CSSParser = commonlib.gettable("System.Windows.mcml.css.CSSParser");

local isInited;
function CSSParser:StaticInit()
	if(isInited) then
		return
	end
	isInited = true;
end

function CSSParser:parse(filename,stylesheet)
	self:StaticInit();
	--stylesheet = CSSStyleSheet:new():init(filename);
	if(string.match(filename,".mcss$")) then
		local styles = commonlib.LoadTableFromFile(filename);
		if(styles) then
			self:LoadFromTable(styles,stylesheet)
		else
			LOG.std(nil, "warn", "mcml style", "style file %s not found", filename);
		end
	else
		-- TODO: load .css format file
		local file = ParaIO.open(filename, "r");
		if(file:IsValid()) then
			local body = file:GetText();
			if(type(body)=="string") then
				self:LoadCssFromString(body, stylesheet);
			end
			file:close();
		end	
	end
	--return stylesheet;
end

-- merge properties from table
function CSSParser:LoadFromTable(styles, stylesheet)
	self:StaticInit();
	if(styles) then
		for flag, style in pairs(styles) do
			local matchtype;
--			if(mcml:isElementClass(flag)) then
--				matchtype = CSSSelector.MatchType.kClass;
--			else
--				matchtype = CSSSelector.MatchType.kTag;
--			end
			matchtype = CSSSelector.MatchType.kTag;
			local selector_list = {CSSSelector:new():init(flag, matchtype)};
			local properties = CSSStyleDeclaration:new(style);
			local rule = CSSStyleRule:new():init(selector_list, properties);
			stylesheet:AddStyleRule(rule);
		end
	end
end

--function Style:LoadFromString(code, type)
function CSSParser:LoadCssFromString(code, stylesheet)
	self:StaticInit();
	code = string.gsub(code,"/%*.-%*/","");
	for selector_str,declaration_str in string.gmatch(code,"([^{}]+){([^{}]+)}") do
		local selectors = self:ParseSelectors(selector_str);
		local properties = CSSStyleDeclaration:new();
		properties:AddString(declaration_str);
		stylesheet:AddStyleRule(CSSStyleRule:new():init(selectors,properties));
	end
end

function CSSParser:ParseSheet(cssString)

end

function CSSParser:ParseSelectors(selectorsString)
	local selector_list = {};
	for w in string.gmatch(selectorsString,"([^,]+),?") do
		local selectorString = string.match(w,"^%s*(.*)%s*$");
		local selector = CSSSelectorParser:parse(selectorString);
		selector_list[#selector_list+1] = selector;
	end
	return selector_list;
end

function CSSParser:ParseDeclarationList(selectorsString)

end