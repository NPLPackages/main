--[[
Title: RadioGroup
Author(s): wxa
Date: 2020/8/14
Desc: 按钮组
-------------------------------------------------------
local RadioGroup = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/RadioGroup.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua", IsDevEnv);
local RadioGroup = commonlib.inherit(Element, NPL.export());

RadioGroup:Property("Name", "RadioGroup");

function RadioGroup:ctor()
    self.value = nil;
end

function RadioGroup:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);
    self:InitChildElement(xmlNode, window, parent);

    self:SetValue(self:GetAttrValue("value"));

    self:ForEach(function(childElement)
        if (childElement:GetName() == "Radio") then
            childElement:SetGroupElement(self);
        end
    end);

    return self;
end

function RadioGroup:OnAttrValueChange(attrName, attrValue)
    if (attrName ~= "value") then return end
    self:SetValue(attrValue);
end

function RadioGroup:GetValue()
    return self.value;
end

function RadioGroup:SetValue(value)
    local oldValue = self.value;
    self.value = value;

    if (oldValue ~= value) then
        self:OnChange(value);
    end

    self:ForEach(function(childElement) 
        if (childElement:GetName() ~= "Radio") then return end
        if (childElement:GetAttrValue("value", "") == self.value) then
            childElement.checked = true;
        else 
            childElement.checked = false;
        end
    end);
end
