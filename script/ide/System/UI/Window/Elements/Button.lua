--[[
Title: Button
Author(s): wxa
Date: 2020/8/14
Desc: 按钮
-------------------------------------------------------
local Button = NPL.load("script/ide/System/UI/Window/Elements/Button.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua");
local Button = commonlib.inherit(Element, NPL.export());

Button:Property("Active", false, "IsActive");            -- 是否激活
Button:Property("Hover", false, "IsHover");              -- 是否鼠标悬浮

Button:Property("BaseStyle", {
	NormalStyle = {
		["display"] = "inline-flex",
		["justify-content"] = "center",
		["align-items"] = "center",
		["background-color"] = "#e6e6e6",
		["color"] = "#000000",
		["font-size"] = "12px",
		["width"] = "80px",
		["height"] = "32px",
		["overflow"] = "none",
		-- ["border-width"] = 1,
		-- ["border-color"] = "#171717",
	},
	HoverStyle = {
		["background-color"] = "#ffffff",
	},
	ActiveStyle = {
		["outline_border"] = "#000000",
		["background"] = "#242424"
	},
});

local ButtonElementDebug = System.Util.Debug.GetModuleDebug("ButtonElementDebug");

function Button:ctor()
	self:SetName("Button");
end

function Button:OnMouseEnter(event)
    self._super:OnMouseEnter(event)
    event:Accept();
end

function Button:OnMouseLeave(event)
    self._super:OnMouseLeave(event)
    event:Accept();
end




