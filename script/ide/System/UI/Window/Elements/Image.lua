--[[
Title: Image
Author(s): wxa
Date: 2020/8/14
Desc: 图片
-------------------------------------------------------
local Image = NPL.load("script/ide/System/UI/Window/Elements/Image.lua");
-------------------------------------------------------
]]

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local Element = NPL.load("../Element.lua");
local Image = commonlib.inherit(Element, NPL.export());

Image:Property("Name", "Image");

function Image:ctor()
end

function Image:GetBackground()
    local src = self:GetAttrStringValue("src");
    if (not src) then return Image._super.GetBackground(self) end 

    return CommonLib.GetFullPath(src);
end