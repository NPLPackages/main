--[[
Title: Field
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Field = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Field.lua");
-------------------------------------------------------
]]

local Const = NPL.load("../Const.lua");
local Shape = NPL.load("../Shape.lua");
local BlockInputField = NPL.load("../BlockInputField.lua");
local Field = commonlib.inherit(BlockInputField, NPL.export());

local MinEditFieldWidth = 120;
local TextMarginUnitCount = Const.TextMarginUnitCount;    -- 文本边距

Field:Property("ClassName", "Field");
Field:Property("Type");                     -- label text, value
Field:Property("Color", "#000000");
Field:Property("BackgroundColor", "#ffffff");

function Field:ctor()
end

function Field:Render(painter)
    painter:SetPen(self:GetBlock():GetColor());

    local offsetX, offsetY = self:GetOffset();
    painter:SetPen(self:GetColor());
    painter:Translate(offsetX, offsetY);
    self:RenderContent(painter);
    painter:Translate(-offsetX, -offsetY);
end

function Field:RenderContent(painter)
    if (self:IsEdit()) then 
        -- Shape:SetBrush("#ffffff");
        -- Shape:DrawInputValue(painter, self.widthUnitCount + 2, self.heightUnitCount + 2, -1, -1);

        if (not self:IsEditRender()) then return end
    end

    local UnitSize = self:GetUnitSize();
    
    Shape:SetBrush(self:GetBackgroundColor());
    Shape:DrawInputValue(painter, self.widthUnitCount, self.heightUnitCount);

    -- input
    painter:SetFont(self:GetFont());
    if (self:GetShowText() == "") then
        painter:SetPen("#66666680");
        painter:DrawText((Const.BlockEdgeWidthUnitCount + TextMarginUnitCount) * UnitSize, (self.height - self:GetSingleLineTextHeight()) / 2, self:GetPlaceholder());
    else
        painter:SetPen(self:GetColor());
        painter:DrawText((Const.BlockEdgeWidthUnitCount + TextMarginUnitCount) * UnitSize, (self.height - self:GetSingleLineTextHeight()) / 2, self:GetShowText());
    end
end

function Field:UpdateWidthHeightUnitCount()
    local text = self:GetLabel();
    if (text == "") then text = self:GetPlaceholder() end 
    local widthUnitCount = self:GetTextWidthUnitCount(text) + (TextMarginUnitCount + Const.BlockEdgeWidthUnitCount) * 2;
    return math.min(math.max(widthUnitCount, Const.MinTextShowWidthUnitCount), Const.MaxTextShowWidthUnitCount), Const.LineHeightUnitCount;
end

function Field:IsField()
    return true;
end

function Field:IsCanEdit()
    return true;
end

function Field:IsEditRender()
    return false;
end

function Field:GetBlockly()
    return self:GetBlock():GetBlockly();
end

function Field:GetFieldValue()
    local value = self:GetValue();
    if (self:IsNumberType()) then
        return self:GetNumberValue();
    elseif (self:IsCodeType()) then
        return value ~= "" and value or "nil"; 
    else 
        return self:GetValue();
    end
end

function Field:GetValueAsString()
    local value = self:GetValue();
    if (self:IsNumberType()) then
        return string.format('%s', tonumber(value) or 0);
    elseif (self:IsCodeType()) then
        return string.format('%s', value == "" and "nil" or value);
    else 
        return string.format("'%s'", value);  
    end
    return value;
end

-- 获取xmlNode
function Field:SaveToXmlNode()
    local fieldName = self:GetName();
    if (not fieldName or fieldName == "") then return nil end

    local xmlNode = {name = "Field", attr = {}};
    local attr = xmlNode.attr;
    
    attr.name = fieldName;
    attr.label = self:GetLabel();
    attr.value = self:GetValue();

    if (attr.value and commonlib.Encoding.HasXMLEscapeChar(attr.value)) then
        table.insert(xmlNode, {name = "value", [1] = {name="![CDATA[", [1] = attr.value}});
        attr.value = nil;
    end

    if (attr.label and commonlib.Encoding.HasXMLEscapeChar(attr.label)) then
        table.insert(xmlNode, {name = "label", [1] = {name="![CDATA[", [1] = attr.label}});
        attr.label = nil;
    end

    return xmlNode;
end

function Field:LoadFromXmlNode(xmlNode)
    local attr = xmlNode.attr;

    self:SetLabel(attr.label);
    self:SetValue(attr.value);
    
    for _, subXmlNode in ipairs(xmlNode) do
        if (subXmlNode.name == "value") then
            self:SetValue(subXmlNode[1]);
        end
        if (subXmlNode.name == "label") then
            self:SetLabel(subXmlNode[1]);
        end
    end

    if (self:IsSelectType()) then
        self:SetLabel(self:GetLabelByValue(self:GetValue(), self:GetLabel()));
        self:SetValue(self:GetValueByLablel(self:GetLabel(), self:GetValue()));
    end 
end