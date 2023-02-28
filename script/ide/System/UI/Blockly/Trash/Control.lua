--[[
Title: Lua
Author(s): wxa
Date: 2020/6/30
Desc: Lua
use the lib:
-------------------------------------------------------
local Lua = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Blocks/Lua.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");

NPL.export({
    {
        type = "if",
        message0 = "如果 %1 那么",
        arg0 = {
            {
                name = "input_value",
                type = "input_value",
            },
        },
        message1 = "%1",
        arg1 = {
            {
                name = "input_statement",
                type = "input_statement"
            }
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            return string.format('if(%s) then\n%s\nend\n', block:GetFieldValue('input_value'), block:GetValueAsString('input_statement'));
        end,
    },
    {
        type = "if_else",
        message0 = "如果 %1 那么 %2 否则 %3",
        arg0 = {
            {
                name = "expression",
                type = "input_value",
            },
            {
                name = "input_true",
                type = "input_statement"
            },
            {
                name = "input_else",
                type = "input_statement"
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            return string.format('if(%s) then\n%s\nelse\n%s\nend\n', block:GetFieldValue('expression'), block:GetValueAsString('input_true'), block:GetValueAsString('input_else'));
        end,
    },
    {
        type = "for_object",
        message0 = "每个 %1 , %2 在 %3 %4",
        arg0 = {
            {
                name = "key",
                type = "field_input",
            },
            {
                name = "value",
                type = "field_input",
            },
            {
                name = "data",
                type = "input_value",
            },
            {
                name = "input",
                type = "input_statement"
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            return string.format('for %s, %s in pairs(%s) do\n    %s\nend\n', block:GetFieldValue('key'), block:GetFieldValue('value'), block:GetFieldValue('data'), block:GetValueAsString('input'));
        end,
    },
    {
        type = "for_array",
        message0 = "每个 %1 , %2 在数组 %3 %4",
        arg0 = {
            {
                name = "i",
                type = "field_input",
            },
            {
                name = "item",
                type = "field_input",
            },
            {
                name = "data",
                type = "input_value",
            },
            {
                name = "input",
                type = "input_statement"
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            return string.format('for %s, %s in ipairs(%s) do\n    %s\nend\n', block:GetFieldValue('i'), block:GetFieldValue('item'), block:GetFieldValue('data'), block:GetValueAsString('input'));
        end,
    },
});