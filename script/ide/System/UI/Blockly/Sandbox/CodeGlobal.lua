--[[
Title: CodeGlobal
Author(s): wxa
Date: 2020/6/30
Desc: 扩展代码方块的全局表
use the lib:
-------------------------------------------------------
local CodeGlobal = NPL.load("script/ide/System/UI/Blockly/Sandbox/CodeGlobal.lua");
-------------------------------------------------------
]]


local  shared_API = GameLogic.GetCodeGlobal():GetSharedAPI();

local Table = shared_API.table;

function Table.getIndex(list, item)
    if (type(list) ~= "table") then return nil end
    for index, val in ipairs(list) do
        if (val == item) then return index end
    end
    return nil;
end