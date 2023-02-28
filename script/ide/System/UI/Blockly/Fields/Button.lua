--[[
Title: Button
Author(s): wxa
Date: 2020/6/30
Desc: 按钮字段
use the lib:
-------------------------------------------------------
local Button = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Button.lua");
-------------------------------------------------------
]]

local Const = NPL.load("../Const.lua");
local Field = NPL.load("./Field.lua");

local Button = commonlib.inherit(Field, NPL.export());

Button:Property("BackgroundColor", "#cccccc");

function Button:IsCanEdit()
    return false;
end

function Button:OptionCallBack(eventName)
    local option = self:GetOption();
    local callback = option[eventName];
    if (type(callback) ~= "function") then return end
    return callback(self);
end

function Button:OnClick()
    self:OptionCallBack("OnClick");
end

