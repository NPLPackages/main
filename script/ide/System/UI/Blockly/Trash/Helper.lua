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
            return string.format("--[[\n%s\n--]]\n",block:GetFieldValue("code"));
        end,
    },
});