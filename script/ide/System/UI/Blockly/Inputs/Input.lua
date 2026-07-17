--[[
Title: Input
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Input = NPL.load("script/ide/System/UI/Blockly/Inputs/Input.lua");
-------------------------------------------------------
]]

local BlockInputField = NPL.load("../BlockInputField.lua");
local Connection = NPL.load("../Connection.lua");

local Input = commonlib.inherit(BlockInputField, NPL.export());

Input:Property("ClassName", "Input");
Input:Property("InputBlock");               -- 输入块
Input:Property("InputShadowBlock");               -- 输入块

function Input:ctor()
end

function Input:Init(block, opt)
    Input._super.Init(self, block, opt);
    
    self.inputConnection = Connection:new():Init(block, nil, opt.check);

    return self;
end

function Input:GetBlockly()
    return self:GetBlock():GetBlockly();
end

function Input:GetInputBlock()
    return self.inputConnection:GetConnectionBlock();
end

function Input:IsInput()
    return true;
end

function Input:GetNextBlock()
    return self:GetInputBlock();
end

function Input:GetFieldValue() 
    if (not self:GetInputBlock()) then return self:GetValue() end
    return self:GetInputBlock():GetAllCode();
end

function Input:GetValueAsString(field_value)
    return field_value or self:GetFieldValue();
end

-- 获取xmlNode
function Input:SaveToXmlNode()
    local xmlNode = {name = "Input", attr = {}};
    local attr = xmlNode.attr;
    
    attr.name = self:GetName();
    attr.label = self:GetLabel();
    attr.value = self:GetValue();

    local inputBlock = self:GetInputBlock();
    if (inputBlock) then table.insert(xmlNode, inputBlock:SaveToXmlNode()) end

    return xmlNode;
end

function Input:LoadFromXmlNode(xmlNode)
    local attr = xmlNode.attr;

    self:SetLabel(attr.label);
    self:SetValue(attr.value);
    self.inputConnection:Disconnection();
    
    if (self:IsSelectType()) then
        self:SetLabel(self:GetLabelByValue(self:GetValue(), self:GetLabel()));
        self:SetValue(self:GetValueByLablel(self:GetLabel(), self:GetValue()));
    end 

    local inputBlockXmlNode = xmlNode[1];
    if (not inputBlockXmlNode) then return end

    local inputBlock = self:GetBlock():GetBlockly():GetBlockInstanceByXmlNode(inputBlockXmlNode);
    if (not inputBlock) then return end
    if (self:GetType() == "input_value") then
        self.inputConnection:Connection(inputBlock.outputConnection);
    else
        self.inputConnection:Connection(inputBlock.previousConnection);
    end
    if (inputBlock:IsInputShadowBlock()) then
        inputBlock:SetProxyBlock(self:GetBlock());
        self:SetInputShadowBlock(inputBlock);
    end
end

function Input:ForEach(callback)
    Input._super.ForEach(self, callback);

    local inputBlock = self:GetInputBlock();
    if (inputBlock) then
        inputBlock:ForEach(callback);
    end
end

function Input:DisableRun()
    local block = self:GetInputBlock();
    if (not block) then return end
    block:DisableRun(true);
end

function Input:EnableRun()
    local block = self:GetInputBlock();
    if (not block) then return end
    block:EnableRun(true);
end

function Input:Save()
    local input_block = self:GetInputBlock();

    if (input_block) then return {block = input_block:Save()} end

    if (self:GetType() == "input_value") then
        if (self:IsNumberType()) then
            return {block = {type = "math_number", fields = {NUM = tonumber(self:GetValue()) or 0}}};
        elseif (self:IsSelectType()) then
            local options = self:GetOptions();
            local value = self:GetValue();
            for _, option in ipairs(options) do
                if (tostring(option[2]) == tostring(value) or tostring(option.value) == tostring(value)) then
                    return {block = {type = self:GetName() .. "Options", fields = {TEXT = tostring(value)}}};
                end
            end
            return {block = {type = "text", fields = {TEXT = self:GetValue() or ""}}};
        else
            return {block = {type = "text", fields = {TEXT = self:GetValue() or ""}}};
        end
    end
end

function Input:Load(input_field)
    if (not input_field) then return end
    local block = input_field.block or {};
    local options_block_type = self:GetName() .. "Options";
    if (block.type == "math_number") then
        self:SetValue(tostring(block.fields.NUM));
        if (self:IsSelectType()) then
            self:SetLabel(self:GetLabelByValue(self:GetValue(), self:GetValue()));
        else
            self:SetLabel(self:GetValue());
        end 
    elseif (block.type == "text" or block.type == options_block_type) then
        self:SetValue(tostring(block.fields.TEXT));
        if (self:IsSelectType()) then
            self:SetLabel(self:GetLabelByValue(self:GetValue(), self:GetValue()));
        else
            self:SetLabel(self:GetValue());
        end 
    else
        local inputBlock = self:GetBlock():GetBlockly():GetBlockInstanceByType(block.type);
        if (not inputBlock) then return end
        inputBlock:Load(block);
        if (self:GetType() == "input_value") then
            self.inputConnection:Connection(inputBlock.outputConnection);
        else
            self.inputConnection:Connection(inputBlock.previousConnection);
        end
        if (inputBlock:IsInputShadowBlock()) then
            inputBlock:SetProxyBlock(self:GetBlock());
            self:SetInputShadowBlock(inputBlock);
        end
    end
end