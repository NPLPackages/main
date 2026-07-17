--[[
Title: Image
Author(s): wxa
Date: 2020/8/14
Desc: 图片
-------------------------------------------------------
local Image = NPL.load("script/ide/System/UI/Window/Elements/Image.lua");
-------------------------------------------------------
]]

local CommonLib = NPL.load("(gl)script/ide/System/Util/CommonLib.lua");
local Element = NPL.load("../Element.lua");
local Image = commonlib.inherit(Element, NPL.export());

Image:Property("Name", "Image");

function Image:ctor()
end

function Image:GetBackground()
    local src = self:GetAttrStringValue("src");
    if (not src) then return Image._super.GetBackground(self) end 
    if (src and string.find(src, "_texture", 1, true) == 1) then return src end
    return CommonLib.GetFullPath(src);
end