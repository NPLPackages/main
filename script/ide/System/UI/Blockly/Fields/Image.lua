--[[
Title: Image
Author(s): wxa
Date: 2020/6/30
Desc: 按钮字段
use the lib:
-------------------------------------------------------

local Image = NPL.load("script/ide/System/UI/Blockly/Fields/Image.lua");
-------------------------------------------------------
]] NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local EventCallBack = NPL.load("../EventCallBack.lua");
local Const = NPL.load("../Const.lua");
local Field = NPL.load("./Field.lua");

local Image = commonlib.inherit(Field, NPL.export());

function Image:Init(block, option)
    Image._super.Init(self, block, option);
    local value = Files.GetWorldFilePath(self:GetValue());
    value = value or self:GetValue();
    local width, height = string.match(value, "#%d+ %d+ (%d+) (%d+)");
    self.m_image_width = tonumber(width) or tonumber(option.width) or Const.ImageWidth;
    self.m_image_height = tonumber(height) or tonumber(option.height) or Const.ImageHeight;
    self.m_image_color = option.color or "#ffffffff";

    self:SetValue(value);

    return self;
end

function Image:IsCanEdit() return false; end

function Image:RenderContent(painter)
    painter:SetPen(self.m_image_color);
    local x = self.m_image_width < self.width and (self.width - self.m_image_width) / 2 or 0;
    local y = self.m_image_height < self.height and (self.height - self.m_image_height) / 2 or 0;
    painter:DrawRectTexture(x, y, self.m_image_width, self.m_image_height, self:GetValue());
end

function Image:UpdateWidthHeightUnitCount()
    local width = math.max(self.m_image_width, Const.ImageWidth);
    local height = math.max(self.m_image_height, Const.ImageHeight);
    return math.ceil(width / self:GetUnitSize()), math.ceil(height / self:GetUnitSize());
end

function Image:OptionCallBack(eventName)
    local option = self:GetOption();
    local callback = option[eventName];
    if (type(callback) == "string") then callback = EventCallBack[callback] end
    if (type(callback) ~= "function") then return end
    return callback(self, self:GetBlock());
end

function Image:OnClick() self:OptionCallBack("OnClick"); end

-- "Texture/Aries/Creator/keepwork/ggs/blockly/plus_13x13_32bits.png#0 0 13 13"
