--[[
Title: ValueList
Author(s): wxa
Date: 2020/6/30
Desc: 按钮字段
use the lib:
-------------------------------------------------------
local ValueList = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Inputs/ValueList.lua");
-------------------------------------------------------
]]

local Const = NPL.load("../Const.lua");
local Input = NPL.load("./Input.lua");
local Value = NPL.load("./Value.lua");

local ValueList = commonlib.inherit(Input, NPL.export());

function ValueList:Render(painter)
    local offsetX, offsetY = self:GetOffset();
    painter:Translate(offsetX, offsetY);
    self:RenderContent(painter);
    painter:Translate(-offsetX, -offsetY);
end

function ValueList:RenderContent(painter)
    painter:DrawRectTexture(6, 6, 13, 13, "Texture/Aries/Creator/keepwork/ggs/blockly/plus_13x13_32bits.png#0 0 13 13");
end

function ValueList:UpdateWidthHeightUnitCount()
    return Const.LineHeightUnitCount, Const.LineHeightUnitCount;
end

function ValueList:SaveToXmlNode()
    return nil;
end

function ValueList:LoadFromXmlNode(xmlNode)
end

function ValueList:IsCanEdit()
    return false;
end

function ValueList:OnClick()
    self:AddInputValue();
    self:GetTopBlock():UpdateLayout();
end

function ValueList:AddInputValue()
    local InputFieldContainer = self:GetInputFieldContainer();
    local index = InputFieldContainer:GetInputFieldIndex(self);
    local inputValue = Value:new():Init(self:GetBlock(), {type = "input_value", shadow_type="field_input", text = ""});
    InputFieldContainer:AddInputField(inputValue, true, index);
    inputValue:SetCanDelete(true);
    inputValue:SetValueListItem(true);
    return inputValue;
end

function ValueList:GetInputValueList()
    local InputFieldContainer = self:GetInputFieldContainer();
    local index = InputFieldContainer:GetInputFieldIndex(self);
    local list = {};
    for i = index -1, 1, -1 do
        local inputfield = InputFieldContainer.inputFields[i];
        local clasaname = inputfield:GetClassName();
        if (clasaname == "FieldSpace") then
        elseif (clasaname == "InputValue" and inputfield:IsValueListItem()) then 
            table.insert(list, 1, inputfield);
        else
            return list;
        end
    end
    return list;
end

function ValueList:SaveToXmlNode()
    local xmlNode = {name = "InputValueList", attr = {name = self:GetName()}};
    
    local list = self:GetInputValueList();
    for _, inputValue in ipairs(list) do
        local subXmlNode = inputValue:SaveToXmlNode();
        table.insert(xmlNode, subXmlNode);
    end
    return xmlNode;
end

function ValueList:LoadFromXmlNode(xmlNode)
    for _, childXmlNode in ipairs(xmlNode) do
        self:AddInputValue():LoadFromXmlNode(childXmlNode);        
    end
end

function ValueList:GetFieldValue()
    local option = self:GetOption();
    local inputValues = self:GetInputValueList();
    local list = {};
    for i, inputValue in ipairs(inputValues) do
        local value = inputValue:GetFieldValue();
        if (value ~= "") then table.insert(list, #list + 1, value) end 
    end
    return table.concat(list, option.separator or ",");
end

function ValueList:GetValueAsString()
    local option = self:GetOption();
    local inputValues = self:GetInputValueList();
    local list = {};
    for i, inputValue in ipairs(inputValues) do
        list[i] = inputValue:GetValueAsString();
    end
    
    return table.concat(list, option.separator or ",");
end