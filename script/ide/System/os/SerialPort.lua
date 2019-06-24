--[[
Title: serial port 
Author(s): LiXizhi
Date: 2019/6/24
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/os/SerialPort.lua");
local SerialPort = commonlib.gettable("System.os.SerialPort");
local file = SerialPort:new():init("com1"):open();
file:Connect("receivedData", function(data)
	file:send("some_data")
end)
------------------------------------------------------------
]]

local SerialPort = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.os.SerialPort"));

SerialPort:Signal("receivedData", function() end)

local allfiles = {}

function SerialPort:ctor()
end

-- @param filename: "com1", "com16"
function SerialPort:init(filename)
	self.filename = filename or "com1";
	self.event_name = string.format("_%s_serialport", self.filename);
end

function SerialPort:open()
	allfiles[self.event_name] = self;
	ParaScene.RegisterEvent(self.event_name, ";System.os.OnSerialPortReceive();");
	-- open port file
	NPL.activate("script/serialport.cpp", {cmd="open", filename=self.filename})
end

function SerialPort:close()
	allfiles[self.event_name] = nil;
	ParaScene.UnregisterEvent(self.event_name);
	-- close port file
	NPL.activate("script/serialport.cpp", {cmd="close", filename=self.filename})
end

local send_msg = {filename="com1", data="binary_data"};
function SerialPort:send(data)
	send_msg.filename = self.filename;
	send_msg.data = data;
	NPL.activate("script/serialport.cpp", send_msg)
end

-- virtual function:
function SerialPort:OnReceive(data)
	file:receivedData(msg.data); --signal data
end

-- static function: for handling all incoming messages
function System.os.OnSerialPortReceive()
	local msg =  msg;
	if(msg.filename) then
		local file = allfiles[msg.filename]
		if(file) then
			file:OnReceive(data)
		else
			LOG.std(nil, "warn", "serial port", "no callback found for %s", msg.filename);
			ParaScene.UnregisterEvent(string.format("_%s_serialport", msg.filename));
		end
	end
end

