--[[
Title: stylesheet manager
Author(s): LiPeng
Date: 2017/11/3
Desc: singleton class for managing all file based stylesheets globally. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleSheetManager.lua");
local StyleSheetManager = commonlib.gettable("System.Windows.mcml.css.StyleSheetManager");
local stylesheet = StyleSheetManager:GetStyleSheet("script/ide/System/test/test_file_style.mcss");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleSheet.lua");
local CSSStyleSheet = commonlib.gettable("System.Windows.mcml.css.CSSStyleSheet");

local StyleSheetManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Windows.mcml.css.StyleSheetManager"));

function StyleSheetManager:ctor()
	self.stylesheets = {};
end

-- get style object from filename.
-- @param filename: usually have extension "*.mcss" or ".css"
function StyleSheetManager:GetStyleSheet(filename)
	local stylesheet =  self.stylesheets[filename];
	if(not stylesheet) then
		stylesheet = self:LoadStyleSheet(filename);
	end
	return stylesheet;
end

function StyleSheetManager:UnloadStyleSheet(filename)
	self.stylesheets[filename] = nil;
end

-- @param style: if nil, we will load from filename
function StyleSheetManager:LoadStyleSheet(filename)
	local stylesheet = CSSStyleSheet:new();
	stylesheet:loadFromFile(filename);
	self.stylesheets[filename] = stylesheet;
	return stylesheet;
end

StyleSheetManager:InitSingleton();