--[[
Title: Math
Author(s): wxa
Date: 2020/6/30
Desc: Lua
use the lib:
-------------------------------------------------------
local Math = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Blocks/Math.lua");
-------------------------------------------------------
]]


NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");

NPL.export({
    {
        type = "Math:TwoOp",
        message0 = "%1 %2 %3",
        arg0 = {
            {
                name = "left",
                type = "input_value",
                editable = false,
            },
            {
                name = "op",
                type = "field_dropdown",
                options = {
                    { "+", "+" },{ "-", "-" },{ "*", "*" },{ "/", "/" },{ "%", "%" },
                    { ">", ">" },{ ">=", ">=" },{ "==", "==" },{ "~=", "~=" },{ "<", "<" },{ "<=", "<=" },
                    { "and", "and" },{ "or", "or" }, {"..", ".." }, 
                },
            },
            {
                name = "right",
                type = "input_value",
                editable = false,
            },
        },
	    output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local op = block:GetFieldValue("op");
            local left = block:GetValueAsString("left");
            local right = block:GetValueAsString("right");
            return string.format('(%s) %s (%s)', left, op, right);
        end,
        category = "Math",
        keywords = {"数学", "运算", "二元元素"},   -- 搜索关键词
    },

    {
        type = "Math:OneOp",
        message0 = "%1 %2",
        arg0 = {
            {
                name = "op",
                type = "field_dropdown",
                options = {
                    { "逻辑非", "not"},
                    { "转成数字", "tonumber"},
                    { "转成字符串", "tostring"},
                    { "向上取整", "math.ceil"},
                    { "向下取整", "math.floor"},
                    { "开根号", "math.sqrt" },
                    { "绝对值", "math.abs"},
                    { "sin", "math.sin"},
                    { "cos", "math.cos"},
                    { "asin", "math.asin"},
                    { "acos", "math.acos"},
                    { "tab", "math.tan"},
                    { "atan", "math.atan"},
                    { "sin", "math.exp"},
                    { "log10", "math.log10"},
                    { "exp", "math.exp"},
                },
            },
            {
                name = "value",
                type = "input_value",
                editable = false,
            },
        },
	    output = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local op = block:GetFieldValue("op");
            local value = block:GetValueAsString("value");
            return string.format('(%s (%s))', op, value);
        end,
        category = "Math",
        keywords = {"数学", "运算", "一元运算"},   -- 搜索关键词
    },
   

});