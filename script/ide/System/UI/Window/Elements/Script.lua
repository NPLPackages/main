--[[
Title: Script
Author(s): wxa
Date: 2020/8/14
Desc: 样式元素
-------------------------------------------------------
local Script = NPL.load("script/ide/System/UI/Window/Elements/Script.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua");
local Script = commonlib.inherit(Element, NPL.export());

-- Script:Property("Code");
Script:Property("BaseStyle", {
	NormalStyle = {
		["display"] = "none",
	}
});

function Script:ctor()
    self:SetName("Style");
    self:SetVisible(false);
end

function Script:Init(xmlNode, window, parent)
	self:InitElement(xmlNode, window, parent);

    self:GetWindow():ExecCode(self:GetInnerText());

	return self;
end
