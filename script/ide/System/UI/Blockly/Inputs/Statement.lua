--[[
Title: Statement
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Statement = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Inputs/Statement.lua");
-------------------------------------------------------
]]

local Const = NPL.load("../Const.lua");
local Shape = NPL.load("../Shape.lua");
local Input = NPL.load("./Input.lua");
local Statement = commonlib.inherit(Input, NPL.export());

local StatementWidthUnitCount = Const.StatementWidthUnitCount;
local MinRenderHeightUnitCount = 14;
function Statement:ctor()
end

function Statement:OnSizeChange()
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
    local blockWidthUnitCount, blockHeightUnitCount = self:GetBlock():GetWidthHeightUnitCount();
    self.inputConnection:SetGeometry(leftUnitCount, topUnitCount - Const.ConnectionRegionHeightUnitCount / 2, blockWidthUnitCount, Const.ConnectionRegionHeightUnitCount);
end

function Statement:Init(block, opt)
    Statement._super.Init(self, block, opt);
    self.inputConnection:SetType("next_connection");
    return self;
end

function Statement:Render(painter)
    local UnitSize = self:GetUnitSize();
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
    local blockWidthUnitCount, blockHeightUnitCount = self:GetBlock():GetWidthHeightUnitCount();
    Shape:SetBrush(self:GetBlock():GetBrush());
    Shape:DrawInputStatement(painter, blockWidthUnitCount, math.max(self.heightUnitCount, MinRenderHeightUnitCount), self.leftUnitCount, self.topUnitCount);
    local inputBlock = self:GetInputBlock();
    if (not inputBlock) then return end
    inputBlock:Render(painter)
end

function Statement:UpdateWidthHeightUnitCount()
    local inputBlock = self:GetInputBlock();
    if (inputBlock) then 
        _, _, _, _, self.inputWidthUnitCount, self.inputHeightUnitCount = inputBlock:UpdateWidthHeightUnitCount();
    else
        self.inputWidthUnitCount, self.inputHeightUnitCount = 0, 10;
    end
    local widthUnitCount, heightUnitCount = StatementWidthUnitCount + self.inputWidthUnitCount, Const.ConnectionHeightUnitCount + Const.BlockEdgeHeightUnitCount * 2 + self.inputHeightUnitCount;
    return widthUnitCount, heightUnitCount, StatementWidthUnitCount, heightUnitCount;
end

function Statement:UpdateLeftTopUnitCount()
    local inputBlock = self:GetInputBlock();
    if (not inputBlock) then return end
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    inputBlock:SetLeftTopUnitCount(leftUnitCount + StatementWidthUnitCount, topUnitCount + Const.BlockEdgeHeightUnitCount);
    inputBlock:UpdateLeftTopUnitCount();
end

function Statement:ConnectionBlock(block)
    local inputBlock = self:GetInputBlock();
    local isConnection = inputBlock and inputBlock:ConnectionBlock(block);
    if (isConnection) then return true end 

    if (block.previousConnection and not block.previousConnection:IsConnection() and self.inputConnection:IsMatch(block.previousConnection)) then
        block:GetBlockly():RemoveBlock(block);
        local inputConnectionConnection = self.inputConnection:Disconnection();
        self.inputConnection:Connection(block.previousConnection);
        local blockLastNextBlock = block:GetLastNextBlock();
        if (blockLastNextBlock.nextConnection) then blockLastNextBlock.nextConnection:Connection(inputConnectionConnection) end
        block:GetTopBlock():UpdateLayout();
        return true;
    end
end

function Statement:GetMouseUI(x, y, event)
    local UnitSize = self:GetUnitSize();
    if (x >= self.left and x <= (self.left + self.width) and y >= self.top and y <= (self.top + self.height)) then return self end
    local block = self:GetBlock();
    if (x >= block.left and x <= (block.left + block.width)  and y >= self.top and y <= (self.top + Const.ConnectionHeightUnitCount * UnitSize)) then return self end
    local inputBlock = self:GetInputBlock();
    return inputBlock and inputBlock:GetMouseUI(x, y, event);
end


