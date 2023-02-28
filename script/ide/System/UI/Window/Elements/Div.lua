--[[
Title: Div
Author(s): wxa
Date: 2020/8/14
Desc: Div 元素
-------------------------------------------------------
local Div = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Div.lua");
-------------------------------------------------------
]]


local Element = NPL.load("../Element.lua");
local Div = commonlib.inherit(Element, NPL.export());

Div:Property("Name", "Div");

function Div:ctor()
end
