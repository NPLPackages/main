--[[
-------------------------------------------------------
local FoldedBlock = NPL.load("script/ide/System/UI/Blockly/FoldedBlock.lua");
-------------------------------------------------------
]]

local Const = NPL.load("./Const.lua");
local Shape = NPL.load("./Shape.lua");
local Block = NPL.load("./Block.lua");

local FoldedBlock = commonlib.inherit(Block, NPL.export());

function FoldedBlock:Init(blockly, block)
    local block_text = block:GetText();
    local next_block = block:GetNextBlock();
    while (next_block ~= nil) do
        block_text = block_text .. " " .. next_block:GetText();
        next_block = next_block:GetNextBlock();
    end
    FoldedBlock._super.Init(self, blockly, {
        type = "__folded_block__",
        previousStatement = block.previousConnection and true or false,
        nextStatement = block.nextConnection and true or false,
        output = block.outputConnection and true or false,
        color = block:GetColor(),
        message = "%1 %2",
        arg = {
            {
                type = "field_label",
                text = "▶",
                color = "#000000",
            },
            {
                type = "field_label",
                text = block_text,            
            }
        },
    });

    self.m_folded_block = block;
    self.m_folded_block_size = block_size;
    self.m_folded_block_text = block_text;

    local previousNextConnection = block.previousConnection and block.previousConnection:Disconnection();
    local outputInputConnection = block.outputConnection and block.outputConnection:Disconnection();
    if (previousNextConnection) then
        previousNextConnection:Connection(self.previousConnection);
    end
    if (outputInputConnection) then
        outputInputConnection:Connection(self.outputConnection);
    end
    return self;
end

function FoldedBlock:Clone(clone, isAll)
    clone = FoldedBlock:new():Init(self:GetBlockly(), self.m_folded_block:Clone(nil, true));
    if (isAll) then 
        local nextBlock = self:GetNextBlock();
        local nextCloneBlock = nextBlock and nextBlock:Clone(nil, true);
        if (nextCloneBlock) then
            clone.nextConnection:Connection(nextCloneBlock.previousConnection);
        end
    end
    return clone;
end

function FoldedBlock:IsFoldedBlock()
    return true;
end

function FoldedBlock:GetFoldedBlock(indent)
    return self.m_folded_block;
end

function FoldedBlock:GetCode()
    return self.m_folded_block and self.m_folded_block:GetAllCode(indent) or "";
end
