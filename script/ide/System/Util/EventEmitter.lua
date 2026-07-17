--[[
Title: EventEmitter
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local EventEmitter = NPL.load("script/ide/System/Util/EventEmitter.lua");
------------------------------------------------------------
]]

local EventEmitter = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

function EventEmitter:ctor()
    self.__callbacks__ = {};
    self.__once_callbacks__ = {};
end

function EventEmitter:RegisterEventCallBack(eventType, callback, prefix)
    if (type(callback) ~= "function" or eventType == nil) then return end 
    local key = tostring(prefix) .. "_" .. tostring(callback);
    self.__callbacks__[eventType] = self.__callbacks__[eventType] or {};
    self.__callbacks__[eventType][key] = callback;
end

function EventEmitter:RemoveEventCallBack(eventType, callback, prefix)
    if (type(callback) ~= "function" or eventType == nil) then return end 
    local key = tostring(prefix) .. "_" .. tostring(callback);
    
    self.__callbacks__[eventType] = self.__callbacks__[eventType] or {};
    self.__callbacks__[eventType][key] = nil;
end

function EventEmitter:TriggerEventCallBack(eventType, ...)
    if (eventType == nil) then return end
    self.__callbacks__[eventType] = self.__callbacks__[eventType] or {};
    for _, callback in pairs(self.__callbacks__[eventType]) do
        callback(...);
    end

    self:TriggerOnceEventCallBack(eventType, ...);
end

function EventEmitter:RegisterOnceEventCallBack(eventType, callback, prefix)
    if (type(callback) ~= "function" or eventType == nil) then return end 
    local key = tostring(prefix) .. "_" .. tostring(callback);
    self.__once_callbacks__[eventType] = self.__once_callbacks__[eventType] or {};
    self.__once_callbacks__[eventType][key] = callback;
end

function EventEmitter:RemoveOnceEventCallBack(eventType, callback, prefix)
    if (type(callback) ~= "function" or eventType == nil) then return end 
    local key = tostring(prefix) .. "_" .. tostring(callback);
    
    self.__once_callbacks__[eventType] = self.__once_callbacks__[eventType] or {};
    self.__once_callbacks__[eventType][key] = nil;
end

function EventEmitter:TriggerOnceEventCallBack(eventType, ...)
    local callbacks = self.__once_callbacks__[eventType];
    if (not callbacks) then return end

    for _, callback in pairs(callbacks) do
        callback(...);
    end
    self.__once_callbacks__[eventType] = nil;
end