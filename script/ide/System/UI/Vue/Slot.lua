--[[
Title: Slot
Author(s): wxa
Date: 2020/6/30
Desc: Slot
use the lib:
-------------------------------------------------------
local Slot = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Vue/Slot.lua");
-------------------------------------------------------
]]

local Component = NPL.load("./Component.lua");

local Slot = commonlib.inherit(Component, NPL.export());

function Slot:ctor()
    self:SetName("Slot");
end

function Slot:Init(xmlNode, window, parent)
    local component = xmlNode.component or parent;
    while (component and (not component.IsComponent or not component:IsComponent())) do
        parentComponent = parentComponent:GetParentElement();
    end
    if (not component) then return end
    local slotName = xmlNode.attr and xmlNode.attr.name or "default";
    local slotXmlNode = component.slotXmlNodes[slotName];
    if (not slotXmlNode) then return end
    self:InitByXmlNode(xmlNode, slotXmlNode);
    self:InitElement(xmlNode, window, parent);
    self:InitComponent();
    self:InitChildElement(slotXmlNode, window);
    self:GetComponentScope():__set_metatable_index__(component:GetComponentScope());
    return self;
end
