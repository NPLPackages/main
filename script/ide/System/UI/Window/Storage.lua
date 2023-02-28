--[[
Title: Storage
Author(s): wxa
Date: 2020/6/30
Desc: Storage
use the lib:
-------------------------------------------------------
local Storage = NPL.load("script/ide/System/UI/Window/Storage.lua");
-------------------------------------------------------
]]

local Storage = NPL.export{};

local __session_storage__ = {};
local SessionStorage = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), {});

function SessionStorage:ctor()
end

function SessionStorage:Init(domain)
    self.__domain__ = domain or "";
    __session_storage__[self.__domain__] = __session_storage__[self.__domain__] or {};
    self.__session_storage__ = __session_storage__[self.__domain__];
    return self;
end

function SessionStorage:SetItem(key, val)
    self.__session_storage__[key] = val;
end

function SessionStorage:GetItem(key)
    return self.__session_storage__[key];
end

function SessionStorage:Clear()
    __session_storage__[self.__domain__] = {};
    self.__session_storage__ = __session_storage__[self.__domain__];
end

Storage.SessionStorage = SessionStorage;


local LocalStorage = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), {});

function LocalStorage:Init(domain)
    self.__domain__ = domain or "";
    return self;
end

function LocalStorage:GetKey(key)
    return (string.format("%s_%s", self.__domain__, key or ""));
end

function LocalStorage:SetItem(key, val)
    return GameLogic.GetPlayerController():SaveLocalData(self:GetKey(key), val, true, false);
end

function LocalStorage:GetItem(key, defaultValue)
    return GameLogic.GetPlayerController():LoadLocalData(self:GetKey(key), defaultValue, true);
end

function LocalStorage:Clear()

end

Storage.LocalStorage = LocalStorage;
