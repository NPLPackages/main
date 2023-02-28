--[[
Title: Label
Author(s): wxa
Date: 2020/8/14
Desc: Label
-------------------------------------------------------
local Label = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Label.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua", IsDevEnv);
local Label = commonlib.inherit(Element, NPL.export());

Label:Property("Name", "Label");
Label:Property("BaseStyle", {
    ["NormalStyle"] = {
        ["display"] = "inline",
    }
});

function Label:OnClick(event)
    local forAttrValue = self:GetAttrStringValue("for");
    if (not forAttrValue) then return end
    local forElement = self:GetWindow():GetElementById(forAttrValue);
    if (not forElement) then return end
    forElement:OnClick(event);
end
