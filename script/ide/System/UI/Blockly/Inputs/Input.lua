--[[
Title: Input
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Input = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Inputs/Input.lua");
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

function Input:GetValueAsString()
    return self:GetFieldValue();
end

-- 获取xmlNode
function Input:SaveToXmlNode()
    local xmlNode = {name = "Input", attr = {}};
    local attr = xmlNode.attr;
    
    attr.name = self:GetName();
    attr.label = self:GetLabel();
    attr.value = self:GetValue();

    local inputBlock = self:GetInputBlock();

    if (not inputBlock and self:GetType() == "input_statement") then return nil end
    
    if (inputBlock) then table.insert(xmlNode, inputBlock:SaveToXmlNode()) end

    return xmlNode;
end

function Input:LoadFromXmlNode(xmlNode)
    local attr = xmlNode.attr;

    self:SetLabel(attr.label);
    self:SetValue(attr.value);
    
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
