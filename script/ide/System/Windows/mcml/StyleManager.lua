--[[
Title: style manager
Author(s): LiXizhi
Date: 2016/10/12
Desc: singleton class for managing all file based styles globally. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/StyleManager.lua");
local StyleManager = commonlib.gettable("System.Windows.mcml.StyleManager");
local style = StyleManager:GetStyle("script/ide/System/test/test_file_style.mcss");
assert(style:GetItem("default").color == "#ffffff");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/Style.lua");
local Style = commonlib.gettable("System.Windows.mcml.Style");

local StyleManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Windows.mcml.StyleManager"));

function StyleManager:ctor()
	self.styles = {};
end

-- get style object from filename.
-- @param filename: usually have extension "*.mcss", mcml css file
function StyleManager:GetStyle(filename)
	local style =  self.styles[filename];
	if(not style) then
		style = self:LoadStyle(filename);
	end
	return style;
end

function StyleManager:UnloadStyle(filename)
	self.styles[filename] = nil;
end

-- @param style: if nil, we will load from filename
function StyleManager:LoadStyle(filename, style)
	style = style or Style:new();
	style:LoadFromFile(filename);
	self.styles[filename] = style;
	return style;
end

StyleManager:InitSingleton();