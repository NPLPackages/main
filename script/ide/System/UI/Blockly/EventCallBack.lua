--[[
Title: Options
Author(s): wxa
Date: 2020/6/30
Desc: Const
use the lib:
-------------------------------------------------------
local EventCallBack = NPL.load("script/ide/System/UI/Blockly/EventCallBack.lua");

function EventCallBack.OnClick(field, block)
    -- field 触发事件的字段
    -- block 触发事件的块

    local target_field_value = block:GetFieldValue("target_field_name");
    -- other code
    block:SetFieldValue("target_field_name", target_field_value);

    -- 若有更新值的字段则需要更新块布局
    block:GetTopBlock():UpdateLayout();
end
-------------------------------------------------------
]]


local EventCallBack = NPL.export();

function EventCallBack.mqtt_config(field, block)
    if not field or not block then
        return
    end
    local CodeMqttPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Mqtt/CodeBlock/CodeMqttPage.lua")
    CodeMqttPage.Show(block) 
end