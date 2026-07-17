--[[
Title: BlueTooth
Author(s): dummy, big
CreateDate: 2023.10.30
ModifyDate: 2024.4.29
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/os/BlueTooth.lua");
local BlueTooth = commonlib.gettable("System.os.BlueTooth");
------------------------------------------------------------
BlueTooth:init();
BlueTooth:setupBluetoothDelegate();
BlueTooth:setDeviceName("hello_ble");
BlueTooth:reconnectBlu();
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/API/FileDownloader.lua");
local FileDownloader = commonlib.gettable("MyCompany.Aries.Creator.Game.API.FileDownloader");

local WebSocketClient = NPL.load("(gl)script/ide/System/os/network/WebSocket/WebSocketClient.lua");

local BlueTooth = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.os.BlueTooth"));

BlueTooth:Signal("setBlueStatus");
BlueTooth:Signal("checkDevice");
BlueTooth:Signal("onReadBlueGattUUid");
BlueTooth:Signal("onReadCharacteristicFinished");
BlueTooth:Signal("onCharacteristic");
BlueTooth:Signal("onDescriptor");
BlueTooth:Signal("onService");

BlueTooth.source_url = "https://cdn.keepwork.com/paracraft/esp32/ParaBLEServer_v1.0.5.exe";
BlueTooth.defaultParaBLEServerToolPath = "plugins/ParaBLEServer_v1.0.5.exe";
BlueTooth.paraBLEServerPort = 8089;
BlueTooth.cache_policy = "access plus 1 year";

local platform = System.os.GetPlatform();

-- native<-->script 互调
local BLUETOOTH_SYSTEM_CALL = {
    CHECK_DEVICE = 1101;
    SET_BLUE_STATUS = 1102;
    ON_READ_CHARACTERISTIC_FINSHED = 1103;
    ON_CHARACTERISTIC = 1104;
    ON_DESCRIPTOR = 1105;
    ON_READ_ALL_GATT = 1106;
    ON_SERVICE = 1107;
    RECEIVE_CHARACTERISTIC_NOTIFY = 1108;
}

function BlueTooth:init(callback)
    LOG.std(nil, "info", "BlueTooth", "init BlueTooth");
    if (not self.Single) then
        self.Single = self;
        self.regNplEngineBridge(callback);
        self:initProtocolFunc();
    else
        if (callback and type(callback) == "function") then
            callback();
        end
    end
end

function BlueTooth.GetSingle()
    return BlueTooth.Single;
end

local LocalService = {callBacks = {}};
function BlueTooth:initProtocolFunc()
    LocalService.RegisterProtocolCallBacks = function(pid, pfunc)
        LocalService.callBacks[pid] = pfunc;
    end

    -- 设置蓝牙状态
    local function setBlueStatus(pId, pData)
        self.isConnected = ("1" == pData);
        -- bluetooth connect finished.

        self:setBlueStatus(self.isConnected);

        if (not self.isConnected) then
            self.serUUID = nil;
            self.chaUUID = nil;

            if (platform == "mac" or platform == "ios") then
                self.isNotify = nil;
            end
        else
            if ((platform == "mac" or platform == "ios") and self.serUUID and self.chaUUID) then
                self:setCharacteristicNotification(self.serUUID, self.chaUUID, true);
            elseif (platform == "android") then
                local timer = commonlib.Timer:new({callbackFunc = function(timer)
                    if (self.serUUID and self.chaUUID) then
                        self:setCharacteristicNotification(self.serUUID, self.chaUUID, true);
                        timer:Change();
                    end
                end});
                timer:Change(500, 500);
            end
        end
    end
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.SET_BLUE_STATUS, setBlueStatus);

    local function checkDevice(pId, pData)
        local device_params = commonlib.Json.Decode(pData);
        self:linkDevice(device_params.addr);
        self:checkDevice();
    end
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.CHECK_DEVICE, checkDevice);

    local function onReadBlueGattUUid(pId, pData)
        self.blueGattUUidMap = commonlib.Json.Decode(pData);
        self:onReadBlueGattUUid();
    end
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.ON_READ_ALL_GATT, onReadBlueGattUUid);

    local function onReadCharacteristicFinished(pId, pData)
        self:onReadCharacteristicFinished();
    end
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.ON_READ_CHARACTERISTIC_FINSHED, onReadCharacteristicFinished);

    local function onCharacteristic(pId, pData)
        local chaParams = commonlib.Json.Decode(pData);
        if (chaParams and type(chaParams) == "table") then
            self.chaUUID = chaParams.uuid;
        end

        self:onCharacteristic();
    end	
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.ON_CHARACTERISTIC, onCharacteristic);

    local function onDescriptor(pId, pData)
        local desc_params = commonlib.Json.Decode(pData);
        self:onDescriptor();
    end	
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.ON_DESCRIPTOR, onDescriptor);

    local function onService(pId, pData)
        local serParams = commonlib.Json.Decode(pData);
        if (serParams and type(serParams) == "table") then
            self.serUUID = serParams.uuid;
        end

        self:onService();
    end
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.ON_SERVICE, onService);

    local function receiveCharacteristicNotify(pId, pData)
        local chaParams = commonlib.Json.Decode(pData);

        -- reconnection is required.
        if (chaParams and chaParams.uuid) then
            self.chaUUID = chaParams.uuid;
        end

        if (chaParams and chaParams.data) then
            if (platform == "mac" or platform == "ios") then
                if (self.isNotify) then
                    local data = commonlib.Json.Decode(chaParams.data);
                    self:ReceiveCharacteristicNotify(data.data);
                end

                self.isNotify = true;
            elseif (platform == "android") then
                self:ReceiveCharacteristicNotify(chaParams.data);
            end
        end
    end
    LocalService.RegisterProtocolCallBacks(BLUETOOTH_SYSTEM_CALL.RECEIVE_CHARACTERISTIC_NOTIFY, receiveCharacteristicNotify)
end

---- npl call engine
local g_engine_call_Lua;
function BlueTooth.regNplEngineBridge(callback)
    if (platform == "win32") then
        if (WebSocketClient.state == "OPEN" or WebSocketClient.state == "CONNECTING") then
            return;
        end

        local websocketUrl = string.format("ws://localhost:%s", BlueTooth.paraBLEServerPort);

        if (not BlueTooth.isParaBLEServerStarted) then
            BlueTooth:StartParaBLEServer(function()
                WebSocketClient.BlueToothOnOpen = callback;
                WebSocketClient.BlueToothOnMsg = BlueTooth.ParaBLEServerReceiveMsg;
                WebSocketClient.BlueToothOnClose = BlueTooth.ParaBLEServerOnClose;
                WebSocketClient.Connect(websocketUrl);
            end);
        else
            WebSocketClient.BlueToothOnOpen = callback;
            WebSocketClient.BlueToothOnMsg = BlueTooth.ParaBLEServerReceiveMsg;
            WebSocketClient.BlueToothOnClose = BlueTooth.ParaBLEServerOnClose;
            WebSocketClient.Connect(websocketUrl);
        end
    elseif (platform == "android") then
        if (LuaJavaBridge) then
            return;
        end	

        if (LuaJavaBridge == nil) then
            NPL.call("LuaJavaBridge.cpp", {});
        end

        if (LuaJavaBridge) then
            local LuaJavaBridge = LuaJavaBridge;
            local callJavaStaticMethod = LuaJavaBridge.callJavaStaticMethod;

            local args = {luaPath = "(gl)script/ide/System/os/BlueTooth.lua"};
            local sigs = "(Ljava/lang/String;)V"; -- 传入string参数，无返回值
            local ret = callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "registerLuaCall", sigs, args);
        end
    elseif (platform == "ios" or platform == "mac") then
        NPL.call("LuaObjcBridge.cpp", {});
        local args = {luaPath = "(gl)script/ide/System/os/BlueTooth.lua"}
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "registerLuaCall", args);
    end

    if (not g_engine_call_Lua) then
        g_engine_call_Lua = function(pData)
            local splt_pos = string.find(pData, "_");
            if (splt_pos) then
                local extData = string.sub(pData, splt_pos + 1);
                local extId = tonumber(string.sub(pData, 1, splt_pos - 1));

                -- LOG.std(nil, "debug", "BlueTooth", string.format("lua id:%s, data:%s", extId, extData));

                if (LocalService and LocalService.callBacks) then
                    if (LocalService.callBacks[extId]) then
                        LocalService.callBacks[extId](extId, extData);
                    end
                end
            end
        end
    end	
end

function BlueTooth:setDeviceName(name)
    if (platform == "win32") then
        self:ParaBLEServerSendMsg("setDeviceName", { deviceName = name });
    elseif (platform == "android") then
        local args = {name};
        local sigs = "(Ljava/lang/String;)V";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "setDeviceName", sigs, args);
    elseif (platform == "ios" or platform == "mac") then
        local args = {name = name};
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "setDeviceName", args);
    end
end

function BlueTooth:setCharacteristicsUuid(serUUID, chaUUID)
    if (platform == "win32") then
        self:ParaBLEServerSendMsg("setCharacteristicsUuid", { serUUID = serUUID, chaUUID = chaUUID });
    elseif (platform == "android") then
        local args = { serUUID, chaUUID };
        local sigs = "(Ljava/lang/String;Ljava/lang/String;)V";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "setCharacteristicsUuid", sigs, args);
    elseif (platform == "ios") then
        local args = { serUuid = serUUID, chaUuid = chaUUID };
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "setCharacteristicsUuid", args);
    end
end

function BlueTooth:setupBluetoothDelegate()
    if (platform == "win32") then
        self:ParaBLEServerSendMsg("setupBluetoothDelegate");
    elseif (platform == "ios" or platform == "mac") then
        local args = {}
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "setupBluetoothDelegate", args);
    end
end

function BlueTooth:readAllBlueGatt()
    if (platform == "android") then
        local args = {};
        local sigs = "()Ljava/lang/String;";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "readAllBlueGatt", sigs, args);
        if (type(ret.result) == "string") then
            ret.result = commonlib.Json.Decode(ret.result);
        end
        return ret.result;
    elseif (platform == "ios") then
        local args = {};
        local _, ret = LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "readAllBlueGatt", args);
        if (type(ret) == "string") then
            ret = commonlib.Json.Decode(ret);
        end
        return ret;
    end
end

function BlueTooth:reconnectBlueTooth()
    if (platform == "win32") then
        self:ParaBLEServerSendMsg("reconnectBlueTooth")
    elseif (platform == "android") then
        local args = {};
        local sigs = "()V";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "reconnectBlueTooth", sigs, args);
    elseif (platform == "ios" or platform == "mac") then
        local args = {luaPath = "(gl)script/ide/System/os/BlueTooth.lua"}
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "reconnectBlueTooth", args);
    end
end

function BlueTooth:disconnectBlueTooth()
    if (platform == "android") then
        local args = {};
        local sigs = "()V";
        local let = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "disconnectBlueTooth", sigs, args);
    elseif (platform == "ios") then
        local args = {luaPath = "(gl)script/ide/System/os/BlueTooth.lua"};
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "disconnectBlueTooth", args);
    end
end

-- NPL.this function
NPL.this(function()
    -- LOG.std(nil, "debug", "BlueTooth", "BlueTooth NPL.this:" .. tostring(msg));
    if (g_engine_call_Lua) then
        local msg = msg;
        g_engine_call_Lua(msg);
    end
end);

function BlueTooth:linkDevice(addr)
    if (platform == "android") then
        local args = {addr};
        local sigs = "(Ljava/lang/String;)V";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "connectDevice", sigs, args);
    elseif (platform == "ios" or platform == "mac") then
        local args = {addr = addr};
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "linkDevice", args);
    end
end

function BlueTooth:writeToCharacteristic(serUUID, chaUUID, writeByte, reset, isShortMsg)
    if (platform == "win32") then
        local args = {serUUID = serUUID or self.serUUID, chaUUID = chaUUID or self.chaUUID, writeByte = writeByte, reset = reset, isShortMsg = isShortMsg};
        self:ParaBLEServerSendMsg("writeToCharacteristic", args);
    elseif (platform == "android") then
        local args = {serUUID or self.serUUID, chaUUID or self.chaUUID, writeByte, isShortMsg};
        local sigs = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Z)V";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "writeToCharacteristic", sigs, args);
    elseif (platform == "ios" or platform == "mac") then
        local args = {serUUID = serUUID or self.serUUID, chaUUID = chaUUID or self.chaUUID, writeByte = writeByte, reset = reset, isShortMsg = isShortMsg};
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "writeToCharacteristic", args);
    end
end

function BlueTooth:characteristicGetStrValue(serUUID, chaUUID)
    if (platform == "android") then
        local args = {serUUID, chaUUID};
        local sigs = "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "characteristicGetStrValue", sigs, args);	
        if (type(ret.result) == "string") then
            ret.result = commonlib.Json.Decode(ret.result);
        end
        return ret.result;
    elseif (platform == "ios" or platform == "mac") then
        local args = {ser_uuid = serUUID, cha_uuid = chaUUID};
        local ret = LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "characteristicGetStrValue", args);
        return ret.result;
    end
end

function BlueTooth:readCharacteristic(serUUID, chaUUID)
    if (platform == "android") then
        local args = {serUUID, chaUUID};
        local sigs = "(Ljava/lang/String;Ljava/lang/String;)V";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "readCharacteristic", sigs, args);
    elseif (platform == "ios" or platform == "mac") then
        local args = {ser_uuid = serUUID, cha_uuid = chaUUID};
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "readCharacteristic", args);
    end	
end	

function BlueTooth:setCharacteristicNotification(serUUID, chaUUID, isNotify)
    if (platform == "android") then
        local args = {serUUID, chaUUID, isNotify}; 
        local sigs = "(Ljava/lang/String;Ljava/lang/String;Z)V";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "setCharacteristicNotification", sigs, args);
    elseif (platform == "ios" or platform == "mac") then
        local args = {ser_uuid = serUUID, cha_uuid = chaUUID, isNotify = isNotify};
        LuaObjcBridge.callStaticMethod("InterfaceBluetooth", "setCharacteristicNotification", args);
    end
end

function BlueTooth:setDescriptorNotification(serUUID, chaUUID, descUUID)
    if (platform == "android") then
        local args = {serUUID, chaUUID, descUUID} ;
        local sigs = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V";
        local ret = LuaJavaBridge.callJavaStaticMethod("com/tatfook/plugin/bluetooth/InterfaceBluetooth" , "setDescriptorNotification", sigs, args);
    elseif (platform == "ios") then
        -- not need
    end
end

function BlueTooth:ParaBLEServerSendMsg(action, args)
    args = NPL.ToJson(args);
    WebSocketClient.SendPacket(action .. "|" .. args);
end

function BlueTooth:RegisterParaBLEServerReceiveEvent(callback)
    self.AllParaBLEServeReceiveEvent = self.AllParaBLEServeReceiveEvent or {};
    table.insert(self.AllParaBLEServeReceiveEvent, callback);
end

function BlueTooth:RemoveParaBLEServerReceiveEvent(callback)
    if (not self.AllParaBLEServeReceiveEvent) then
        return;
    end

    for i, cb in ipairs(self.AllParaBLEServeReceiveEvent) do
        if cb == callback then
            table.remove(self.AllParaBLEServeReceiveEvent, i)
            return;
        end
    end
end

function BlueTooth:ReceiveCharacteristicNotify(data)
    for _, callback in pairs(BlueTooth.AllParaBLEServeReceiveEvent) do
        if (callback and type(callback) == "function") then
            callback(data);
        end
    end
end

function BlueTooth.ParaBLEServerOnClose()
    BlueTooth.Single = nil;
    BlueTooth.isParaBLEServerStarted = false;
    LocalService.callBacks[BLUETOOTH_SYSTEM_CALL.SET_BLUE_STATUS](nil, "2");
end

function BlueTooth.ParaBLEServerReceiveMsg(msg)
    if (msg.action == "setStatus") then
        if (msg.data.isWin32Connected) then
            LocalService.callBacks[BLUETOOTH_SYSTEM_CALL.ON_SERVICE](nil, NPL.ToJson({ uuid = msg.data.serUUID }));
            LocalService.callBacks[BLUETOOTH_SYSTEM_CALL.ON_CHARACTERISTIC](nil, NPL.ToJson({ uuid = msg.data.chaUUID }));
            LocalService.callBacks[BLUETOOTH_SYSTEM_CALL.SET_BLUE_STATUS](nil, "1");
        else
            LocalService.callBacks[BLUETOOTH_SYSTEM_CALL.SET_BLUE_STATUS](nil, "2");
        end
    elseif (msg.action == "receiveCharacteristicNotify") then
        LOG.std(nil, "debug", "BlueTooth", "receiveCharacteristicNotify: %s", msg.data)
        BlueTooth:ReceiveCharacteristicNotify(msg.data);
    end
end

function BlueTooth:StartParaBLEServer(callback)
    if (self.isParaBLEServerStarted) then
        return;
    end

    for i = 1, 20 do
        if (ParaGlobal.IsPortAvailable("0.0.0.0", self.paraBLEServerPort)) then
            break;
        else
            self.paraBLEServerPort = self.paraBLEServerPort + 1;
        end
    end

    local function StartServer()
        local cmd = string.format([[
echo "Starting ParaBLEServer ..." >con
pushd "%s"
"%s" "%s" >con 2>&1
popd
timeout /t 5 >nul
]], ParaIO.GetWritablePath(), self.defaultParaBLEServerToolPath, self.paraBLEServerPort);
        LOG.std(nil, "info", "BlueTooth", "run: %s", cmd);
        System.os.runAsync(cmd);

        commonlib.TimerManager.SetTimeout(function()
            BlueTooth.isParaBLEServerStarted = true;
    
            if (callback and type(callback) == "function") then
                callback();
            end
        end, 3000);
    end

    if (not ParaIO.DoesFileExist(BlueTooth.defaultParaBLEServerToolPath)) then
        -- download exe file.
        self:OnStartDownload(StartServer);
    else
        -- start server.
        StartServer();
    end
end

function BlueTooth:OnStartDownload(callback)
	if(BlueTooth.is_loading)then
		return 
	end
	BlueTooth.is_loading = true;
	GameLogic.AddBBS(nil, L"正在下载ParaBLEServer，请稍等", 3000, "255 0 0");
	BlueTooth.loader = BlueTooth.loader or FileDownloader:new();
	BlueTooth.loader:SetSilent();

	local destFileName = BlueTooth:GetParaBLEServerToolPath();
	ParaIO.CreateDirectory(destFileName);
	BlueTooth.loader:Init(nil, BlueTooth.source_url, destFileName, function(b, msg)
		BlueTooth.is_loading = false;
		BlueTooth.loader:Flush();
		GameLogic.AddBBS(nil, L"下载完成", 3000, "0 255 0");
		if (b) then
			if (callback) then
				callback(destFileName);
			end
		else
			GameLogic.AddBBS(nil, L"下载失败"..": ParaBLEServer.exe", 3000, "255 0 0");
		end
	end, BlueTooth.cache_policy);
end

function BlueTooth:GetParaBLEServerToolPath()
	BlueTooth.ParaBLEServerToolPath = BlueTooth.ParaBLEServerToolPath or string.format("%s%s", ParaIO.GetWritablePath(), BlueTooth.defaultParaBLEServerToolPath);
	return BlueTooth.ParaBLEServerToolPath;
end
