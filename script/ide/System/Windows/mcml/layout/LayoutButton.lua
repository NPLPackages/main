--[[
Title: 
Author(s): LiPeng
Date: 2018/1/23
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutButton.lua");
local LayoutButton = commonlib.gettable("System.Windows.mcml.layout.LayoutButton");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlock.lua");
local LayoutButton = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBlock"), commonlib.gettable("System.Windows.mcml.layout.LayoutButton"));

function LayoutButton:ctor()
	self.name = "LayoutButton";
end

function LayoutButton:OnBeforeChildrenLayout(layout)
	local css = self:Style():GetStyle();
	local font, font_size, scale = css:GetFontSettings();
	local width, height;
	if(not css.width) then
		local text = self.pageElement:GetValue();
		width = _guihelper.GetTextWidth(text,font);
	end
	if(not css.height) then
		height = font_size*scale;
	end
	if(width or height) then
		layout:AddObject(width or 0, height or 0);
	end
end
