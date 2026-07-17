--[[
Title: serial
Author(s): LiXizhi
Date: 2023/5/26
Desc: Serial and SerialPort provides attributes and methods for finding and connecting to serial ports.
Note: ESP32 requires a PC driver: https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers?tab=downloads
Microbit does not require a PC driver, and emulated via COM automatically. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/os/Serial.lua");
local Serial = commonlib.gettable("System.os.Serial");
local ports = Serial:GetPortNames();
if(ports) then
	for _, name in ipairs(ports) do
		local file = Serial:OpenPort(name)
		if(file) then
			-- file:send("some_data")
			file:Connect("dataReceived", function(data)
				echo(data)
			end)
			file:Connect("lineReceived", function(line)
				echo("line:" .. line)
			end)
		end
	end
end

local usbVendorId = 0xabcd;
Serial:RequestPort({filters = {{usbVendorId}}})
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/os/os.lua");
NPL.load("(gl)script/ide/System/os/SerialPort.lua");
local SerialPort = commonlib.gettable("System.os.SerialPort");

local Serial = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.os.Serial"));

Serial:Signal("connect")
Serial:Signal("disconnect")

function Serial:ctor()
end

-- one time init
function Serial:Init()
	if(self.inited) then
		return;
	end
	self.inited = true
	-- start event listener for connect and disconnect
	-- TODO: 
end

-- @param options: {filters = {{usbVendorId, usbProductId}, ...}, }
-- filters: array of objects containing vendor and product IDs used to search for attached devices. 
-- The USB Implementors Forum assigns IDs to specific companies. Each company assigns IDs to its products. 
-- Filters contain the following values: 
--    usbVendorId: An unsigned short integer that identifies a USB device vendor.
--    usbProductId: An unsigned short integer that identifies a USB device.
-- @param callback: function(serialPort) end
function Serial:RequestPort(options, callback)
	-- TODO: SerialPort:new():Init();
end

-- @param filename: "com1", "com16" or "COM1:\\Device\\Serial2"
-- @param baud_rate: default to 115200
-- @return return port or nil if can not open
function Serial:OpenPort(...)
	local file = SerialPort:new():init(...);
	if(file:open()) then
		return file;
	end
end

-- @param name: "COM1:\\Device\\Serial2"
-- @return "COM1"
function Serial:GetNameFromFullName(name)
	if(name) then
		name = name:match("^[^:]+")
	end
	return name;
end

-- return an array of SerialPort objects representing serial ports connected to the host which the origin has permission to access.
-- @param callback : function(ports)  end
-- @return array of port names. 
function Serial:GetPortNames(callback)
	Serial:Init()
	self.allPortNames = {};
	self.getPortCallback = callback;
	-- if (not System.os.IsEmscripten()) then
		NPL.call("script/serialport.cpp", {cmd="GetPortNames", callback="script/ide/System/os/Serial.lua"})
	-- end
	return self.allPortNames;
end

Serial:InitSingleton();

NPL.this(function()
	Serial.allPortNames = msg;
	if(Serial.getPortCallback) then
		Serial.getPortCallback(msg);
		Serial.getPortCallback = nil;
	end
end)