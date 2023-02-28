--[[
Title: Event
Author(s): wxa
Date: 2020/6/30
Desc: Lua
use the lib:
-------------------------------------------------------
local Event = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Blocks/Event.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");

NPL.export({
    {
        type = "Event:On",
        message0 = "当收到 %1 消息时 ( msg ) %2",
        arg0 = {
            {
                name = "msgname",
                type = "field_input",
                text = "msgname"
            },
            {
                name = "msgcode",
                type = "input_statement"
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local msgname = block:GetFieldValue("msgname");
            local msgcode = block:GetFieldValue("msgcode");
            return string.format('Event:On("%s", function(msg)\n    %s\nend)\n', msgname, msgcode);
        end,
        category = "Event",
        keywords = {"事件", "Event", "消息", "msg", "message"},   -- 搜索关键词
    },
    {
        type = "Event:Emit",
        message0 = "广播 %1 消息 ( %2 ) ",
        arg0 = {
            {
                name = "msgname",
                type = "field_input",
                text = "msgname"
            },
            {
                name = "msgvalue",
                type = "input_value"
            },
        },
        previousStatement = true,
	    nextStatement = true,
        color = StyleColor.ConvertTo16("rgb(160,110,254)"),
        ToNPL = function(block)
            local msgname = block:GetFieldValue("msgname");
            local msgvalue = block:GetValueAsString("msgvalue");
            return string.format('Event:Emit("%s", %s)\n', msgname, msgvalue);
        end,
        category = "Event",
        keywords = {"事件", "Event", "消息", "msg", "message"},   -- 搜索关键词
    },
});