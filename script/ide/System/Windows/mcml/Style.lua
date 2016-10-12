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
local StyleItem = commonlib.gettable("System.Windows.mcml.StyleItem");

local Style = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.Style"));

function Style:ctor()
	self.items = {};
	self.references = {};
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
			self:SetItem(name, StyleItem:new(style), true);
		end
	end
	return self;
end

-- merge styleitems from table string
function Style:LoadFromString(code)
	if(code~=nil and code~="") then
		local styles = commonlib.LoadTableFromString(code);
		if(styles) then
			self:LoadFromTable(styles);
		end
	end
end

-- @param filename: file content should be a pure NPL table like { ["div"] = {background="", },  }
-- see also: script/ide/System/test/test_file_style.mcss
function Style:LoadFromFile(filename)
	self:SetFileName(filename);
	local styles = commonlib.LoadTableFromFile(filename);
	if(styles) then
		self:LoadFromTable(styles)
	else
		LOG.std(nil, "warn", "mcml style", "style file %s not found", filename);
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
function Style:AddReference(style)
	if(style) then
		local references = self.references;
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