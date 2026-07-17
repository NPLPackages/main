--[[
Title: Label
Author(s): wxa
Date: 2020/6/30
Desc: 输入字段
use the lib:
-------------------------------------------------------
local Label = NPL.load("script/ide/System/UI/Blockly/Fields/Label.lua");
-------------------------------------------------------
]]
local InputElement = NPL.load("../../Window/Elements/Input.lua");

local Const = NPL.load("../Const.lua");
local Shape = NPL.load("../Shape.lua");
local Field = NPL.load("./Field.lua");
local Input = commonlib.inherit(Field, NPL.export());

Input:Property("ClassName", "FieldInput");     -- 类名

function Input:GetFieldEditType()
    return "input";
end

