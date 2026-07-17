--[[
Title: Html
Author(s): wxa
Date: 2020/8/14
Desc: Html 根元素
-------------------------------------------------------
local Html = NPL.load("script/ide/System/UI/Window/Elements/Html.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua");
local Html= commonlib.inherit(Element, NPL.export());

function Html:ctor()
    self:SetName("Html");
end
