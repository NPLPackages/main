--[[
Title: Blue Tooth Code API
Author(s): big
CreateDate: 2024.2.27
ModifyDate: 2024.3.4
Desc:
------------------------------------------------------------
local BlueToothCodeAPI = NPL.load("(gl)script/ide/System/os/BlueToothCodeAPI.lua");
------------------------------------------------------------
GameLogic.All.BlueTooth:StartBluetooth() -- start Bluetooth service
GameLogic.All.BlueTooth:SendEvent("test", {a = 1}) -- send event message
GameLogic.All.BlueTooth:RegisterEvent("test", function(msg) echo(msg, true) end) -- register event messages

GameLogic.All.BlueTooth:Send("0")
GameLogic.All.BlueTooth:SetChaUUID("00002a6f")
GameLogic.All.BlueTooth:RegisterBLEReceiveEvent(instance.callback)
GameLogic.All.BlueTooth:RemoveBLEReceiveEvent(instance.callback)
]]

NPL.load("(gl)script/ide/System/os/BlueTooth.lua");
local BlueTooth = commonlib.gettable("System.os.BlueTooth");

local BlueToothCodeAPI = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

BlueToothCodeAPI.isAutoReconnection = true;
BlueToothCodeAPI.isUseWebBlueTooth = false;

function BlueToothCodeAPI:ctor()
    self.m_on_bluetooth_msg = function(msgdata)
        local action = msgdata.action;
        if (action == "connect") then
            self:OnSetBlueToothStatus(true);            
        elseif (action == "close") then
            self:OnSetBlueToothStatus(false);
        elseif (action == "recv") then
            self.Receive(msgdata);
        end        
    end

    if (System.os.IsEmscripten()) then
        local Emscripten = NPL.load("(gl)script/apps/Aries/Creator/Game/Emscripten/Emscripten.lua");
        self.m_emscripten_instance = Emscripten;
        self.m_emscripten_instance:OnMsg("BlueTooth", self.m_on_bluetooth_msg);
    else
        if (self.isUseWebBlueTooth) then
            local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
            self.m_npljs_instance = NPLJS;  
        end
    end
end

function BlueToothCodeAPI:Destroy()
end

function BlueToothCodeAPI:SetAutoReconnection(isAutoReconnection)
    self.isAutoReconnection = isAutoReconnection;
end

function BlueToothCodeAPI:StopBluetooth()
    if (self.isAutoReconnection) then
        self.m_npljs_instance:Close();
    end
end

function BlueToothCodeAPI:StartBluetooth(deviceName, service_uuid)
    if (self:IsConnected()) then
        return;
    end

    if (System.os.GetPlatform() == "win32") then
        if (self.isUseWebBlueTooth) then
            self.m_npljs_instance:Open("http://127.0.0.1:8088/html/bluetooth/index.html", function()
                self.m_npljs_instance:OnMsg("BlueTooth", self.m_on_bluetooth_msg);
                self.m_npljs_instance:SendMsg("BlueTooth", {action = "connect", name = deviceName or "paracraft_ble", service_uuid = service_uuid});
            end, 0, 0, 400, 300);
        else
            BlueTooth:init(function()
                BlueTooth:setDeviceName(deviceName or "paracraft_ble");
                BlueTooth:setupBluetoothDelegate();
                BlueTooth:reconnectBlueTooth();
                BlueTooth:Connect("setBlueStatus", BlueToothCodeAPI, BlueToothCodeAPI.OnSetBlueToothStatus, "UniqueConnection");
                self:RegisterBLEReceiveEvent(self.Receive);
            end);
        end

    elseif (System.os.IsEmscripten()) then
        self.m_emscripten_instance:SendMsg("BlueTooth", {action = "connect", name = deviceName or "paracraft_ble", service_uuid = service_uuid});
    else
        BlueTooth:init();
        BlueTooth:setDeviceName(deviceName or "paracraft_ble");
        BlueTooth:setupBluetoothDelegate();
        BlueTooth:reconnectBlueTooth();
        BlueTooth:Connect("setBlueStatus", BlueToothCodeAPI, BlueToothCodeAPI.OnSetBlueToothStatus, "UniqueConnection");
        self:RegisterBLEReceiveEvent(self.Receive);
    end
end

function BlueToothCodeAPI:OnSetBlueToothStatus(isConnected)
    BlueToothCodeAPI.isConnected = isConnected;

    if (not BlueToothCodeAPI.isConnected) then
        if (self.isAutoReconnection) then
            if (System.os.GetPlatform() == "win32") then
                BlueTooth:setupBluetoothDelegate();
            end

            BlueTooth:reconnectBlueTooth();
        else
            BlueTooth:Disconnect("setBlueStatus", BlueToothCodeAPI, BlueToothCodeAPI.OnSetBlueToothStatus);
            self:RemoveBLEReceiveEvent(self.Receive);
            self.serUUID = nil;
            self.chaUUID = nil;
        end
    end
end

function BlueToothCodeAPI:IsConnected()
    return self.isConnected == true;
end

-- function BlueToothCodeAPI:SetSerUUID(uuid)
--     self.serUUID = uuid;
-- end

function BlueToothCodeAPI:SetCharacteristicUUID(uuid)
    local separatorIndex = BlueTooth.serUUID:find("-");
    local seconedPart = BlueTooth.serUUID:sub(separatorIndex + 1);

    self.chaUUID = uuid .. "-" .. seconedPart;
    BlueTooth:setCharacteristicsUuid(BlueTooth.serUUID, self.chaUUID);
end

function BlueToothCodeAPI:Send(code)
    if (not self:IsConnected() or not code) then
        return;
    end

    BlueTooth:writeToCharacteristic(self.serUUID, self.chaUUID, code, nil, true);
end

function BlueToothCodeAPI:RegisterBLEReceiveEvent(callback)
    if (not callback) then
        return;
    end

    BlueTooth:RegisterParaBLEServerReceiveEvent(callback);
end

function BlueToothCodeAPI:RemoveBLEReceiveEvent(callback)
    if (not callback) then
        return;
    end

    BlueTooth:RemoveParaBLEServerReceiveEvent(callback);
end

function BlueToothCodeAPI.Receive(msg)
    local eventName, data = nil, nil;
    if (type(msg) == "string") then
        eventName, data = string.match(msg, "([^|]+)|(.+)");
    elseif (type(msg) == "table") then
        eventName, data = msg.name, msg.data;
    end

    BlueToothCodeAPI.AllEvents = BlueToothCodeAPI.AllEvents or {};
    if (eventName and BlueToothCodeAPI.AllEvents[eventName]) then
        BlueToothCodeAPI.AllEvents[eventName](data);
    end
end

-- message format: eventName|{"a":1}
function BlueToothCodeAPI:SendEvent(eventName, msg)
    if (System.os.IsEmscripten()) then
        self.m_emscripten_instance:SendMsg("BlueTooth", {action = "send", name = eventName, data = msg});
        return;
    else 
        if (self.isUseWebBlueTooth) then
            self.m_npljs_instance:SendMsg("BlueTooth", {action = "send", name = eventName, data = msg});
            return;
        end
    end   

    msg = NPL.ToJson(msg);
    msg = eventName .. "|" .. msg
    LOG.std(nil, "debug", "BlueToothCodeAPI", "msg: %s", msg);

    self:Send(msg);
end

function BlueToothCodeAPI:RegisterEvent(eventName, callback)
    BlueToothCodeAPI.AllEvents = BlueToothCodeAPI.AllEvents or {};
    BlueToothCodeAPI.AllEvents[eventName] = callback
end

function BlueToothCodeAPI:UnRegisterEvent(eventName)
    BlueToothCodeAPI.AllEvents = BlueToothCodeAPI.AllEvents or {};
    BlueToothCodeAPI.AllEvents[eventName] = nil;
end

BlueToothCodeAPI:InitSingleton();
