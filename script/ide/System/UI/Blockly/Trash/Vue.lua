--[[
Title: Vue
Author(s): wxa
Date: 2020/6/30
Desc: Lua
use the lib:
-------------------------------------------------------
local Vue = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Blocks/Vue.lua");
-------------------------------------------------------
]]

NPL.export({
    {
        type = "Vue:RegisterComponent",
        message0 = "注册元素 标签名 %1 文件路径 %2",
        arg0 = {
            {
                name = "tagname",
                type = "field_input",
            },
            {
                name = "filename",
                type = "field_input"
            },
        },
        previousStatement = true,
	    nextStatement = true,
        ToNPL = function(block)
            local tagname = block:GetValueAsString("tagname");
            local filename = block:GetValueAsString("filename");
            return string.format('RegisterComponent(%s, %s)\n', tagname, filename);
        end,
    },
    {
        type = "Vue:CloseWindow",
        message0 = "关闭当前窗口",
        arg0 = {
        },
        previousStatement = true,
	    nextStatement = true,
        ToNPL = function(block)
            return string.format('CloseWindow()\n');
        end,
    },
    {
        type = "Vue:SetWindowSize",
        message0 = "设置窗口大小 宽 %1 高 %2",
        arg0 = {
            {
                name = "width",
                type = "field_number",
            },
            {
                name = "height",
                type = "field_number"
            },
        },
        previousStatement = true,
	    nextStatement = true,
        ToNPL = function(block)
            local width = block:GetFieldValue("width");
            local height = block:GetFieldValue("height");
            return string.format('SetWindowSize(%s, %s)\n', width, height);
        end,
    },
});