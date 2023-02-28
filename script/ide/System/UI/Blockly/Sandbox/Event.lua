--[[
Title: Event
Author(s): wxa
Date: 2020/6/30
Desc: 沙盒环境全局表
use the lib:
-------------------------------------------------------
local Event = NPL.load("script/ide/System/UI/Blockly/Sandbox/Event.lua");
-------------------------------------------------------
]]

local Event = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Event:Property("G");

function Event:ctor()
    self:Reset();
end

function Event:Init(G)
    self:SetG(G);

    return self;
end

function Event:Reset()
    self.events = {};
end

function Event:On(eventName, callback, eventId)
    local event = self.events[eventName] or {};
    self.events[eventName] = event;
    event[eventId or callback] = callback;
end

function Event:Emit(eventName, data)
    local event = self.events[eventName] or {};
    for _, callback in pairs(event) do
        callback(data);
    end
end


