--[[
Title: Data
Author(s): wxa
Date: 2020/6/30
Desc: Lua
use the lib:
-------------------------------------------------------
local Data = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Blocks/Data.lua");
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
        type = "object",
        message0 = "空对象 {}",
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block) 
            return "{}";
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
        type = "function",
        message0 = "定义函数 %1 (...) %2",
        arg0 = {
            {
                name = "funcname",
                type = "field_input",
                text = "funcname",
                validator = "FuncName",
            },
            {
                name = "funccode",
                type = "input_statement"
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local funcname = block:GetFieldValue("funcname");
            local funccode = block:GetValueAsString("funccode");
            return string.format('function %s(...)\n%s\nend\n', funcname, funccode);
        end,
    },
    {
        type = "function_args_n",
        message0 = "获取第 %1 个函数参数",
        arg0 = {
            {
                name = "arg_n",
                type = "field_select",
                text = "1",
                options = {{"1", "1"}, {"2", "2"}, {"3", "3"}, {"4", "4"}, {"5", "5"}, {"6", "6"}, {"7", "7"}, {"8", "8"}, {"9", "9"}},
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local arg_n = block:GetFieldValue("arg_n");
            return string.format('(select(%s, ...))', arg_n);
        end,
    },
    {
        type = "call_function_statement",
        message0 = "调用函数 %1",
        arg0 = {
            {
                name = "funcname",
                type = "field_input",
                validator = "FuncName",
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local funcname = block:GetFieldValue("funcname");
            return string.format('%s()\n', funcname);
        end,
    },
    {
        type = "call_function_output",
        message0 = "调用函数 %1",
        arg0 = {
            {
                name = "funcname",
                type = "field_input",
                validator = "FuncName",
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local funcname = block:GetFieldValue("funcname");
            return string.format('(%s())', funcname);
        end,
    },
});