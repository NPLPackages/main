--[[
Title: Var
Author(s): wxa
Date: 2020/6/30
Desc: Lua
use the lib:
-------------------------------------------------------
local Var = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Blocks/Var.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");

NPL.export({
    {
        type = "Var_Define",
        message0 = "定义变量 %1 值为 %2",
        arg0 = {
            {
                name = "varname",
                type = "field_input",
                text = "varname",
                validator = "VarName",

            },
            {
                name = "varvalue",
                type = "input_value",
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local varname = block:GetFieldValue("varname");
            local varvalue = block:GetValueAsString("varvalue");
            return string.format('local %s = %s\n', varname, varvalue);
        end,
        category = "Var",
        keywords = {"变量", "var"},   -- 搜索关键词
    },

    {
        type = "Var_Set",
        message0 = "变量 %1 赋值为 %2",
        arg0 = {
            {
                name = "varname",
                type = "field_input",
                validator = "VarName",
            },
            {
                name = "varvalue",
                type = "input_value",
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local varname = block:GetFieldValue("varname");
            local varvalue = block:GetValueAsString("varvalue");
            return string.format('%s = %s\n', varname, varvalue);
        end,
        category = "Var",
        keywords = {"变量", "var", "赋值"},   -- 搜索关键词
    },

    {
        type = "Var_Get",
        message0 = "获取变量 %1 值",
        arg0 = {
            {
                name = "varname",
                type = "field_input",
                text = "varname",
                validator = "VarName",
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local varname = block:GetFieldValue("varname");
            return string.format('%s', varname);
        end,
        category = "Var",
        keywords = {"变量值", "var"},   -- 搜索关键词
    },

    {
        type = "Var_Global_Set",
        message0 = "全局变量 %1 赋值为 %2",
        arg0 = {
            {
                name = "varname",
                type = "field_input",
                text = "varname",
                validator = "VarName",
            },
            {
                name = "varvalue",
                type = "input_value",
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local varname = block:GetFieldValue("varname");
            local varvalue = block:GetValueAsString("varvalue");
            return string.format('_G["%s"] = %s\n', varname, varvalue);
        end,
        category = "Var",
        keywords = {"全局变量", "var", "赋值"},   -- 搜索关键词
    },
    
    {
        type = "Var_Global_Get",
        message0 = "获取全局变量 %1 值",
        arg0 = {
            {
                name = "varname",
                type = "field_input",
                validator = "VarName",
            },
        },
        output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local varname = block:GetFieldValue("varname");
            return string.format('_G["%s"]', varname);
        end,
        category = "Var",
        keywords = {"变量值", "var"},   -- 搜索关键词
    },

    {
        type = "Var_Object_Set",
        message0 = "设置对象 %1 属性 %2 值为 %3",
        arg0 = {
            {
                name = "objname",
                type = "field_input",
                validator = "VarName",
            },
            {
                name = "objkey",
                type = "input_value",
            },
            {
                name = "objval",
                type = "input_value",
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local objname = block:GetFieldValue("objname");
            local objkey = block:GetValueAsString("objkey");
            local objval = block:GetValueAsString("objval");
            return string.format('%s[%s] = %s\n', objname, objkey, objval);
        end,
        category = "Var",
        keywords = {"对象", "表", "table", "object"},   -- 搜索关键词
    },

    {
        type = "Var_Object_Get",
        message0 = "获取对象 %1 属性 %2 值",
        arg0 = {
            {
                name = "objname",
                type = "field_input",
                validator = "VarName",
            },
            {
                name = "objkey",
                type = "input_value",
            },
          
        },
	    output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local objname = block:GetFieldValue("objname");
            local objkey = block:GetValueAsString("objkey");
            return string.format('%s[%s]', objname, objkey);
        end,
        category = "Var",
        keywords = {"对象", "表", "table", "object"},   -- 搜索关键词
    },
});