--[[
Title: Value
Author(s): wxa
Date: 2020/6/30
Desc: 值字段 仅用于存贮数据用
use the lib:
-------------------------------------------------------
local Value = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Value.lua");
-------------------------------------------------------
]]

local Const = NPL.load("../Const.lua");
local Field = NPL.load("./Field.lua", IsDevEnv);
local Value = commonlib.inherit(Field, NPL.export());

function Value:RenderContent(painter)
end

function Value:UpdateWidthHeightUnitCount()
    return 0, 0;
end

function Value:SetFieldValue(value)
    self:SetValue(value);
    self:SetLabel("");
end