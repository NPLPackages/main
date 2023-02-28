--[[
Title: CheckBoxGroup
Author(s): wxa
Date: 2020/8/14
Desc: 复选框
-------------------------------------------------------
local CheckBoxGroup = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/CheckBoxGroup.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua", IsDevEnv);
local CheckBoxGroup = commonlib.inherit(Element, NPL.export());

CheckBoxGroup:Property("Name", "CheckBoxGroup");

function CheckBoxGroup:ctor()
    self.value = {};
end

function CheckBoxGroup:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);
    self:InitChildElement(xmlNode, window, parent);

    self:SetValue(self:GetAttrValue("value"));

    self:ForEach(function(childElement)
        if (childElement:GetName() == "CheckBox") then
            childElement:SetGroupElement(self);
        end
    end);

    return self;
end

function CheckBoxGroup:OnAttrValueChange(attrName, attrValue)
    if (attrName ~= "value") then return end
    self:SetValue(attrValue);
end

function CheckBoxGroup:GetValue()
    return self.value;
end

function CheckBoxGroup:IsCheckedValue(value)
    for idx, val in ipairs(self.value) do
        if (val == value) then return true, idx end
    end
    return false, #(self.value) + 1;
end

function CheckBoxGroup:AddCheckedValue(value)
    local exist, idx = self:IsCheckedValue(value);
    if (exist) then return end
    table.insert(self.value, idx, value);
    self:OnChange(self.value);
end

function CheckBoxGroup:RemoveCheckedValue(value)
    local exist, idx = self:IsCheckedValue(value);
    if (not exist) then return end
    table.remove(self.value, idx, value);
    self:OnChange(self.value);
end

function CheckBoxGroup:SetValue(value)
    if (type(value) ~= "table") then value = {value} end

    local oldValue = self.value;
    self.value = value;

    if (oldValue ~= value) then
        self:OnChange(value);
    end

    self:ForEach(function(childElement) 
        if (childElement:GetName() ~= "CheckBox") then return end
        childElement.checked = self:IsCheckedValue(childElement:GetAttrValue("value", ""));
    end);
end