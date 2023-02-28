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
        type = "nil",
        message0 = "nil",
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block) 
            return "nil";
        end,
    },
    {
        type = "boolean",
        message0 = "%1",
        arg0 = {
            {
                name = "field_dropdown",
                type = "field_dropdown",
                text = "true",
                options = {
                    {"真", "true"},
                    {"假", "false"},
                }
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block) 
            return block:GetFieldValue("field_dropdown");
        end,
    },
    {
        type = "number",
        message0 = "%1",
        arg0 = {
            {
                name = "field_number",
                type = "field_number",
                text = "0",
                min = 0,
                max = 100,
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block) 
            return block:GetValueAsString("field_number");
        end,
    },
    {
        type = "text",
        message0 = "\" %1 \"",
        arg0 = {
            {
                name = "field_input",
                type = "field_input",
                text = "文本",
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block) 
            return block:GetValueAsString("field_input");
        end,
    },
    {
        type = "textarea",
        message0 = "\" %1 \"",
        arg0 = {
            {
                name = "field_textarea",
                type = "field_textarea",
                text = "多行文本",
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block) 
            return block:GetValueAsString("field_textarea");
        end,
    },
    {
        type = "json",
        message0 = "JSON %1 ",
        arg0 = {
            {
                name = "field_json",
                type = "field_json",
                text = "{}",
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block) 
            local json = block:GetFieldValue("field_json");
            return commonlib.serialize_compact(commonlib.Json.Decode(json));
        end,
    },
    {
        type = "variable",
        message0 = "%1",
        arg0 = {
            {
                name = "field_variable",
                type = "field_variable",
                allowNewOption = true,
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block) 
            return block:GetValueAsString("field_variable");
        end,
    },
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
            return string.format('if(%s) then\n%s\nend\n', block:GetValueAsString('input_value'), block:GetValueAsString('input_statement'));
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
            return string.format('if(%s) then\n%s\nelse\n%s\nend\n', block:GetValueAsString('expression'), block:GetValueAsString('input_true'), block:GetValueAsString('input_else'));
        end,
    },
    {
        type = "for",
        message0 = "每个 %1 , %2 在 %3 %4",
        arg0 = {
            {
                name = "key",
                type = "input_value",
            },
            {
                name = "value",
                type = "input_value",
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
            return string.format('for %s, %s in pairs(%s) do\n    %s\nend\n', block:GetValueAsString('key'), block:GetValueAsString('value'), block:GetValueAsString('data'), block:GetValueAsString('input'));
        end,
    },
    {
        type = "for",
        message0 = "每个 %1 , %2 在数组 %3 %4",
        arg0 = {
            {
                name = "i",
                type = "input_value",
            },
            {
                name = "item",
                type = "input_value",
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
            return string.format('for %s, %s in ipairs(%s) do\n    %s\nend\n', block:GetValueAsString('i'), block:GetValueAsString('item'), block:GetValueAsString('data'), block:GetValueAsString('input'));
        end,
    },

    {
        type = "code",
        message0 = "代码块 %1",
        arg0 = {
            {
                name = "code",
                type = "field_textarea",
                text = "-- print('hello world')",
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            return block:GetFieldValue("code");
        end,
    },

    {
        type = "comment",
        message0 = "注释块 %1",
        arg0 = {
            {
                name = "code",
                type = "input_statement",
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            return string.format("--[[\n%s\n--]]",block:GetFieldValue("code"));
        end,
    },
});