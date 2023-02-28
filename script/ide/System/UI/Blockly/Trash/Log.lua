--[[
Title: Log
Author(s): wxa
Date: 2020/6/30
Desc: Lua
use the lib:
-------------------------------------------------------
local Log = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Blocks/Log.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");


NPL.export({
    {
        type = "Log:Log",
        message0 = "打印日志 %1 %2",
        arg0 = {
            {
                name = "level",
                type = "field_select",
                options = {
                    {"调试", "Debug"},
                    {"信息", "Info"},
                    {"警告", "Warn"},
                    {"错误", "Error"},
                }
            },
            {
                name = "value",
                type = "input_value",
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local level = block:GetFieldValue("level");
            local value = block:GetValueAsString("value");
            return string.format('Log:%s(%s)\n', level, value);
        end,
        category = "Log",
        keywords = {"日志", "Log", "打印", "输出"},   -- 搜索关键词
    },
    {
        type = "Log:SetLevel",
        message0 = "设置日志级别 %1",
        arg0 = {
            {
                name = "level",
                type = "field_select",
                options = {
                    {"调试", "Debug"},
                    {"信息", "Info"},
                    {"警告", "Warn"},
                    {"错误", "Error"},
                }
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local level = block:GetFieldValue("level");
            return string.format('Log:SetLevel("%s")\n', level, value);
        end,
        keywords = {"日志", "Log", "日志级别"},     -- 搜索关键词
    },
});