--[[
Title: G
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Shape = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Shape.lua");
-------------------------------------------------------
]]

local Const = NPL.load("./Const.lua");
local Shape = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local Triangle = {{0,0,0}, {0,0,0}, {0,0,0}};       -- 三角形

Shape:Property("Pen", "#ffffff");              -- 画笔
Shape:Property("Brush", "#ffffff");            -- 画刷
Shape:Property("Painter");                     -- 绘图类
Shape:Property("UnitSize", Const.UnitSize);

local LineHeight = 2;

function Shape:DrawStartEdge(painter, widthUnitCount, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    self:DrawBefore(painter, offsetXUnitCount, offsetYUnitCount);
    painter:DrawRectTexture(0, -4 * UnitSize, widthUnitCount * UnitSize, (Const.ConnectionHeightUnitCount + 4) * UnitSize, self:GetStartTexture());
    self:DrawAfter(painter, offsetXUnitCount, offsetYUnitCount);
end

-- 绘制上边及凹陷部分 占据高度 2 * UnitSize
function Shape:DrawPrevConnection(painter, widthUnitCount, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    self:DrawBefore(painter, offsetXUnitCount, offsetYUnitCount);
    painter:DrawRectTexture(0, Const.ConnectionHeightUnitCount * UnitSize - LineHeight / 2, widthUnitCount * UnitSize, LineHeight, self:GetLineTexture());
    painter:DrawRectTexture(0, 0, widthUnitCount * UnitSize, Const.ConnectionHeightUnitCount * UnitSize, self:GetPrevConnectionTexture());
    self:DrawAfter(painter, offsetXUnitCount, offsetYUnitCount);
end

-- 绘制下边及突出部分 占据高度 4 * UnitSize
function Shape:DrawNextConnection(painter, widthUnitCount, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    self:DrawBefore(painter, offsetXUnitCount, offsetYUnitCount);
    painter:DrawRectTexture(0, 0, widthUnitCount * UnitSize, Const.ConnectionHeightUnitCount * 2 * UnitSize, self:GetNextConnectionTexture());
    self:DrawAfter(painter, offsetXUnitCount, offsetYUnitCount);
end

-- 绘制输出块
function Shape:DrawOutput(painter, widthUnitCount, heightUnitCount, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    self:DrawBefore(painter, offsetXUnitCount, offsetYUnitCount);
    painter:DrawRectTexture(0, 0, widthUnitCount * UnitSize, heightUnitCount * UnitSize, self:GetOutputTexture());
    self:DrawAfter(painter, offsetXUnitCount, offsetYUnitCount);
end

-- 绘制矩形
function Shape:DrawRect(painter, widthUnitCount, heightUnitCount, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    self:DrawBefore(painter, offsetXUnitCount, offsetYUnitCount);
    painter:DrawRectTexture(0, heightUnitCount * UnitSize - LineHeight / 2 , widthUnitCount * UnitSize, LineHeight, self:GetLineTexture());
    painter:DrawRectTexture(0, 0, widthUnitCount * UnitSize, heightUnitCount * UnitSize, self:GetRectTexture());
    self:DrawAfter(painter, offsetXUnitCount, offsetYUnitCount);
end

-- 绘制输入语句
function Shape:DrawInputStatement(painter, widthUnitCount, heightUnitCount, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    self:DrawBefore(painter, offsetXUnitCount, offsetYUnitCount);
    painter:DrawRectTexture(0, heightUnitCount * UnitSize - LineHeight / 2 , widthUnitCount * UnitSize, LineHeight, self:GetLineTexture());
    painter:DrawRectTexture(0, 0, widthUnitCount * UnitSize, heightUnitCount * UnitSize, self:GetInputStatementTexture());
    self:DrawAfter(painter, offsetXUnitCount, offsetYUnitCount);
end

-- 绘制输入值
function Shape:DrawInputValue(painter, widthUnitCount, heightUnitCount, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    self:DrawBefore(painter, offsetXUnitCount, offsetYUnitCount);
    painter:DrawRectTexture(0, 0, widthUnitCount * UnitSize, heightUnitCount * UnitSize, self:GetInputValueTexture());
    self:DrawAfter(painter, offsetXUnitCount, offsetYUnitCount);
end

-- 绘制线条
function Shape:DrawLine(painter, x1, y1, x2, y2)
    local UnitSize = self:GetUnitSize();
    local painter = painter or self:GetPainter();
    painter:SetPen(self:GetPen());
    painter:DrawLine(x1 * UnitSize, y1 * UnitSize, x2 * UnitSize, y2 * UnitSize);
end

function Shape:DrawBefore(painter, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    painter:SetPen(self:GetBrush());
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(offsetXUnitCount * UnitSize, offsetYUnitCount * UnitSize);
end

function Shape:DrawAfter(painter, offsetXUnitCount, offsetYUnitCount)
    local UnitSize = self:GetUnitSize();
    offsetXUnitCount, offsetYUnitCount = offsetXUnitCount or 0, offsetYUnitCount or 0;
    painter:Translate(-offsetXUnitCount * UnitSize, -offsetYUnitCount * UnitSize);
end

function Shape:DrawShadowBlock(painter, leftUnitCount, topUnitCount, widthUnitCount, heightUnitCount)
    local UnitSize = self:GetUnitSize();
    painter:SetPen(self:GetBrush());
    painter:DrawRectTexture(leftUnitCount * UnitSize, topUnitCount * UnitSize, widthUnitCount * UnitSize, heightUnitCount * UnitSize, self:GetShadowBlockTexture());
end

function Shape:GetPrevConnectionTexture()
    if (Const.UnitSize == 3) then return "Texture/Aries/Creator/keepwork/ggs/blockly/statement_block_54X42_32bits.png#0 0 54 6:42 3 3 3" end
    return "Texture/Aries/Creator/keepwork/ggs/blockly/statement_block_72X56_32bits.png#0 0 72 8:56 8 8 8";
end

function Shape:GetLineTexture()
    if (Const.UnitSize == 3) then return "Texture/Aries/Creator/keepwork/ggs/blockly/statement_block_54X42_32bits.png#0 12 54 2:6 1 6 1" end
    return "Texture/Aries/Creator/keepwork/ggs/blockly/statement_block_72X56_32bits.png#0 16 72 2:8 1 8 1";
end

function Shape:GetRectTexture()
    if (Const.UnitSize == 3) then return "Texture/Aries/Creator/keepwork/ggs/blockly/statement_block_54X42_32bits.png#0 12 54 12:3 3 3 3" end
    return "Texture/Aries/Creator/keepwork/ggs/blockly/statement_block_72X56_32bits.png#0 16 72 16:4 4 4 4";
end

function Shape:GetNextConnectionTexture()
    if (Const.UnitSize == 3) then return "Texture/Aries/Creator/keepwork/ggs/blockly/statement_block_54X42_32bits.png#0 30 54 12:42 3 9 9" end
    return "Texture/Aries/Creator/keepwork/ggs/blockly/statement_block_72X56_32bits.png#0 40 72 16:56 4 12 12";
end

function Shape:GetOutputTexture()
    if (Const.UnitSize == 3) then return "Texture/Aries/Creator/keepwork/ggs/blockly/value_input_26X24_32bits.png#0 0 26 24:12 2 12 2" end
    return "Texture/Aries/Creator/keepwork/ggs/blockly/output_block_34X32_32bits.png#0 0 34 32:16 2 16 2";
end

function Shape:GetInputValueTexture()
    if (Const.UnitSize == 3) then return "Texture/Aries/Creator/keepwork/ggs/blockly/value_input_26X24_32bits.png#0 0 26 24:12 2 12 2" end
    return "Texture/Aries/Creator/keepwork/ggs/blockly/output_block_34X32_32bits.png#0 0 34 32:16 2 16 2";
end

function Shape:GetInputStatementTexture()
    if (Const.UnitSize == 3) then return "Texture/Aries/Creator/keepwork/ggs/blockly/statement_input_63X48_32bits.png#0 0 63 48:54 15 6 15" end
    return "Texture/Aries/Creator/keepwork/ggs/blockly/statement_input_84X64_32bits.png#0 0 84 64:72 20 8 20";
end

function Shape:GetShadowBlockTexture()
    if (Const.UnitSize == 3) then return "Texture/Aries/Creator/keepwork/ggs/blockly/statement_block_54X42_32bits.png#0 0 54 42:42 3 3 3" end
    return "Texture/Aries/Creator/keepwork/ggs/blockly/statement_block_72X56_32bits.png#0 0 72 56:56 8 8 8";
end

function Shape:GetCloseTexture()
    return "Texture/Aries/Creator/keepwork/ggs/dialog/guanbi_22X22_32bits.png#0 0 22 22";
end

function Shape:GetStartTexture()
    return "Texture/Aries/Creator/keepwork/ggs/blockly/start_96x54_32bits.png#0 0 96 18:80 18 12 12";
end