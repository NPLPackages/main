
--[[
Title: BlocklyBlock
Author(s): wxa
Date: 2020/6/30
Desc: 
use the lib:
-------------------------------------------------------
local BlocklyBlock = NPL.load("script/ide/System/UI/Blockly/BlocklyBlock.lua");
-------------------------------------------------------
]]
local Blockly = NPL.load("script/ide/System/UI/Blockly/Blockly.lua");
local BlocklyBlock = commonlib.inherit(Blockly, NPL.export());

function BlocklyBlock:Init(xmlNode, window, parent)
    BlocklyBlock._super.Init(self, xmlNode, window, parent);
    self.isHideToolBox = true;
    self.isHideIcons = true;
    self:SetReadOnly(true);
    return self;
end

function BlocklyBlock:OnAttrValueChange(attrName, attrValue, oldAttrValue)
    BlocklyBlock._super.OnAttrValueChange(self, attrName, attrValue, oldAttrValue);

    if (attrName == "block") then
        local blockOption = attrValue;
        self:DefineBlock(commonlib.deepcopy(blockOption))
        local block = self:GetBlockInstanceByType(blockOption.type, true)
        self:ClearBlocks()
        block:SetLeftTopUnitCount(0, 0)
        block:UpdateLayout()
        self:AddBlock(block)
    end 
end

function BlocklyBlock:OnUpdateLayout()
    local block = self.blocks[1];
    if (not block) then return self:GetLayout():SetWidthHeight(0, 0) end
	self:GetLayout():SetWidthHeight(block.width, block.height);
end

function BlocklyBlock:RenderContent(painter)
    local block = self.blocks[1];
    if (not block) then return end
    local x, y, w, h = self:GetContentGeometry();
    painter:Translate(x, y);
    block:Render(painter);
    painter:Flush();
    painter:Translate(-x, -y);
end
