--[[
Title: Const
Author(s): wxa
Date: 2020/6/30
Desc: Const
use the lib:
-------------------------------------------------------
local Validator = NPL.load("script/ide/System/UI/Blockly/Validator.lua");
-------------------------------------------------------
]]

local Validator = NPL.export();

local _Byte = string.byte("_");
local aByte = string.byte("a");
local zByte = string.byte("z");
local AByte = string.byte("A");
local ZByte = string.byte("Z");
local _0Byte = string.byte("0");
local _9Byte = string.byte("9");

local function VarFuncName(str)
    local newstr = "";
    for i = 1, #str do
        local byte = string.byte(str, i, i);
        if (_Byte == byte or (aByte <= byte and byte <=zByte) or (AByte <= byte and byte <=ZByte) or (_0Byte <= byte and byte <= _9Byte)) then
            newstr = newstr .. string.char(byte);
        else 
            newstr = newstr .. string.format("_%X", byte)
        end
    end
    return newstr;
end

function Validator.VarName(str)
    return VarFuncName(str);
end

function Validator.FuncName(str)
    return VarFuncName(str);
end