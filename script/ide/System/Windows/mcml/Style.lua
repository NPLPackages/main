--[[
Title: base class of css style sheet
Author(s): LiXizhi
Date: 2015/5/4
Desc: css style contains a collection of StyleItem.
To change mcml default style, call mcml:SetStyle() before mcml page is loaded. We usually do this on startup.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Style.lua");
local Style = commonlib.gettable("System.Windows.mcml.Style");
local styles = {
	["pe:button"] = {padding=5}
}
mcml:SetStyle(Style:new():LoadFromTable(styles));
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/StyleItem.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/CssSelector.lua");
local CssSelector = commonlib.gettable("System.Windows.mcml.CssSelector");
local StyleItem = commonlib.gettable("System.Windows.mcml.StyleItem");

local Style = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.Style"));

function Style:ctor()
	self.items = {};
	self.references = {};
	self.css_items = {};
	self.css_references = {};

	self.page = nil;
end

function Style:init(page)
	self.page = page;
	return self;
end

function Style:SetPage(page)
	if(self.page == page) then
		return;
	end
	self.page = page;
end

-- @param name: the css class name
function Style:GetItem(name)
	if(name) then
		local item = self.items[name];
		if(not item) then
			local references = self.references;
			for i=#(references), 1, -1 do
				item = references[i]:GetItem(name);
				if(item) then
					break;
				end
			end
		end
		return item;
	end
end

-- apply to styleItem for all matching classes
function Style:ApplyToStyleItem(styleItem, name)
	local references = self.references;
	for i=1, #(references) do
		references[i]:ApplyToStyleItem(styleItem, name);
	end
	styleItem:Merge(self.items[name]);
end

-- apply to styleItem for all matching classes
function Style:ApplyCssStyleToStyleItem(styleItem, pageElement)
	local references = self.css_references;
	for i=1, #(references) do
		references[i]:ApplyCssStyleToStyleItem(styleItem, pageElement);
	end
	for i = 1,#self.css_items do
		local css_item = self.css_items[i];
		local selectors = css_item.selectors;
		for j = 1,#selectors do
			local selector = selectors[j];
			if(selector:match(pageElement)) then
				styleItem:Merge(css_item.style);
			end
		end
	end
	--styleItem:Merge(style);
end

-- @param name: the css class name
-- @param bOverwrite: true to overwrite if exist
function Style:SetItem(name, style, bOverwrite)
	if(bOverwrite or not self:GetItem(name)) then
		self.items[name] = style;
	end
end

-- merge styleitems from table
function Style:LoadFromTable(styles)
	if(styles) then
		for name, style in pairs(styles) do
			self:SetItem(name, StyleItem:new(style):init(self), true);
		end
	end
	return self;
end

-- merge styleitems from table string
function Style:LoadFromString(code, type)
	if(code~=nil and code~="") then
		if(not type or type == "mcss") then
			local styles = commonlib.LoadTableFromString(code);
			if(styles) then
				self:LoadFromTable(styles);
			end
		else
			self:LoadCssFromString(code);
		end
	end
end

-- @param filename: file content should be a pure NPL table like { ["div"] = {background="", },  }
-- see also: script/ide/System/test/test_file_style.mcss
function Style:LoadFromFile(filename)
	self:SetFileName(filename);
	if(string.match(filename,".mcss$")) then
		local styles = commonlib.LoadTableFromFile(filename);
		if(styles) then
			self:LoadFromTable(styles)
		else
			LOG.std(nil, "warn", "mcml style", "style file %s not found", filename);
		end
	else
		-- TODO: load .css format file
		local file = ParaIO.open(filename, "r");
		if(file:IsValid()) then
			local body = file:GetText();
			if(type(body)=="string") then
				self:LoadCssFromString(body);
			end
			file:close();
		end	
	end
end

-- TODO: touch all textures used in the style. 
function Style:PreloadAllTextures()
end

local auto_id = 1;

-- get filename, if no filename is given a default unqiue name will be created. 
function Style:GetFileName()
	if(not self.filename) then
		self.filename = "inline_"..tostring(auto_id);
		auto_id = auto_id + 1;
	end
	return self.filename;
end

-- set file name of this style. 
function Style:SetFileName(filename)
	self.filename = filename;
end

-- it does not copy and merge items in the given style, it simply add a reference to the given style
function Style:AddReference(style, type)
	local references;
	if(not type or type == "mcss") then
		references = self.references;
	elseif(type == "css") then
		references = self.css_references;
	end
	if(style) then
		--local references = self.references;
		for i=1, #(references) do
			if(references[i] == style) then
				break;
			end
		end
		references[#references+1] = style;
	end
end

-- remove a given reference
function Style:RemoveReference(style)
	local references = self.references;
	local index;
	for i=1, #(references) do
		if(references[i] == style) then
			index = i;
			break;
		end
	end
	commonlib.removeArrayItem(references, index);
end

function Style:parseSelectors(selectorsString)
	local selectors = {};
	for w in string.gmatch(selectorsString,"([^,]+),?") do
		local selectorString = string.match(w,"^%s*(.*)%s*$");
		local selector = CssSelector:new():init(selectorString);
		selectors[#selectors+1] = selector;
	end
	return selectors;
end


--function Style:LoadFromString(code, type)
function Style:LoadCssFromString(code)
	code = string.gsub(code,"/%*.-%*/","");
	for selector_str,declaration_str in string.gmatch(code,"([^{}]+){([^{}]+)}") do
		local selectors = self:parseSelectors(selector_str);
		local style = StyleItem:new():init(self);
		style:AddString(declaration_str);
		self.css_items[#self.css_items + 1] = {
			["selectors"] = selectors,
			["style"] = style,
		};
	end
end