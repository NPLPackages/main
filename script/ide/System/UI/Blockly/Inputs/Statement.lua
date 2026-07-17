--[[
Title: Statement
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Statement = NPL.load("script/ide/System/UI/Blockly/Inputs/Statement.lua");
-------------------------------------------------------
]]

local Const = NPL.load("../Const.lua");
local Shape = NPL.load("../Shape.lua");
local Input = NPL.load("./Input.lua");
local Helper = NPL.load("../Helper.lua");
local FoldedBlock = NPL.load("../FoldedBlock.lua");

local Statement = commonlib.inherit(Input, NPL.export());

local StatementWidthUnitCount = Const.StatementWidthUnitCount;
local MinRenderHeightUnitCount = 14;
function Statement:ctor()
    self.m_indent_count = 1;
end

function Statement:OnSizeChange()
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
    local blockWidthUnitCount, blockHeightUnitCount = self:GetBlock():GetWidthHeightUnitCount();
    self.inputConnection:SetGeometry(leftUnitCount, topUnitCount - Const.ConnectionRegionHeightUnitCount / 2, blockWidthUnitCount, Const.ConnectionRegionHeightUnitCount);
end

function Statement:Init(block, opt)
    Statement._super.Init(self, block, opt);
    self.m_indent_count = tonumber(opt.indent_count or 1) or 1;
   
    self:SetValue("");
    self:SetLabel("");
    self.inputConnection:SetType("next_connection");

    local xmlnode = Helper.XmlString2Lua(opt.xml_text or "");
    local is_folded = opt.is_folded ~= false;
    local is_folded_draggable = opt.is_folded_draggable ~= false;
    if (type(xmlnode) == "table") then
        local folded_block = block:GetBlockly():GetBlockInstanceByXmlNode(xmlnode[1]);
        if (folded_block and is_folded_draggable == false) then
            folded_block:DisableDraggable(true);
        end
        if (folded_block and not folded_block:IsFoldedBlock() and is_folded) then
            folded_block = FoldedBlock:new():Init(folded_block:GetBlockly(), folded_block);
        end
        if (folded_block and folded_block.previousConnection) then
            self.inputConnection:Connection(folded_block.previousConnection);
        end
    end
    return self;
end

function Statement:GetFieldValue() 
    local blockIndent = self:GetBlock():GetIndent();
    for i = 1, self.m_indent_count do
        blockIndent = blockIndent .. Const.Indent;
    end
    if (not self:GetInputBlock()) then return blockIndent .. self:GetValue() end
    return self:GetInputBlock():GetAllCode(blockIndent);
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

    if ((not inputBlock or inputBlock:IsDraggable()) and block.previousConnection and not block.previousConnection:IsConnection() and self.inputConnection:IsMatch(block.previousConnection)) then
        -- block:GetBlockly():RemoveBlock(block);
        -- local inputConnectionConnection = self.inputConnection:Disconnection();
        -- self.inputConnection:Connection(block.previousConnection);
        -- local blockLastNextBlock = block:GetLastNextBlock();
        -- if (blockLastNextBlock.nextConnection) then blockLastNextBlock.nextConnection:Connection(inputConnectionConnection) end
        -- block:GetTopBlock():UpdateLayout();

        -- if (self:GetBlock():IsDisableRun() and not block.isShadowBlock) then block:DisableRun(true) end

        local __self__ = self;
        local target_block = block;
        local distance = math.abs(__self__.leftUnitCount + StatementWidthUnitCount - target_block.leftUnitCount);
        if (not target_block.m_connection_distance or distance < target_block.m_connection_distance) then
            target_block.m_connection_distance = distance;
            target_block.m_connection_callback = function()
                target_block:GetBlockly():RemoveBlock(target_block);
                local inputConnectionConnection = __self__.inputConnection:Disconnection();
                __self__.inputConnection:Connection(target_block.previousConnection);
                local blockLastNextBlock = target_block:GetLastNextBlock();
                if (blockLastNextBlock.nextConnection) then blockLastNextBlock.nextConnection:Connection(inputConnectionConnection) end
                target_block:GetTopBlock():UpdateLayout();
        
                if (__self__:GetBlock():IsDisableRun() and not target_block.isShadowBlock) then target_block:DisableRun(true) end
            end
        end        
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

