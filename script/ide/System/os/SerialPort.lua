--[[
Title: serial port 
Author(s): LiXizhi
Date: 2023/5/26
Desc: this class is used to open a serial port and send/receive data.
For chips like MicroPython on the ESP32, with proper firmware installed, 
we can simply run python code like `help()\r\n` via serial port with no PC-side driver installed. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/os/SerialPort.lua");
local SerialPort = commonlib.gettable("System.os.SerialPort");
local file = SerialPort:new():init("com1")
if(file:open()) then
	file:Connect("dataReceived", function(data, file)
		echo(data)
	end)
	file:Connect("lineReceived", function(line, file)
		echo("line:" .. line)
	end)
	commonlib.TimerManager.SetTimeout(function()  
	    file:send("help()\r\n")
	end, 3000)
end
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/Json.lua");
local SerialPort = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.os.SerialPort"));

SerialPort:Signal("dataReceived");
SerialPort:Signal("lineReceived");
SerialPort.isUseRateControl = true;
SerialPort.maxSendCount = 1024;
-- assume 1/3 of the baud rate is the actual upload rate.
SerialPort.uploadRateFactor = 1/3; 

local thisFilename = "script/ide/System/os/SerialPort.lua";
local allports = {};

function SerialPort:ctor()
end

-- @param filename: "com1", "com16" or "COM1:\\Device\\Serial2"
-- @param baud_rate: default to 115200
function SerialPort:init(filename, baud_rate)
	self.fullname = filename;
	local shortName, deviceName = filename:match("^([^:]+):?(.*)");
	self.filename = shortName or "com1";
	self.deviceName = deviceName;
	self.baud_rate = baud_rate or 115200;
	return self;
end

function SerialPort:GetFullname()
	return self.fullname or self.filename;
end

function SerialPort:GetFilename()
	return self.filename;
end

-- @return true if opened
function SerialPort:open()
	allports[self.filename] = self;
	self.isPortOpen = true;
	-- open port file
	NPL.call("script/serialport.cpp", {
		cmd = "open",
		filename = self.filename,
		callback = thisFilename, 
		baud_rate = self.baud_rate or 115200
	});
	if (self.isPortOpen) then
		LOG.std(nil, "system", "SerialPort", "opened port: %s", self.filename);
	end
	return self.isPortOpen;
end

function SerialPort:isOpen()
	return self.isPortOpen;
end

function SerialPort:close()
	if(self.isPortOpen) then
		self.isPortOpen = false;
		NPL.activate("script/serialport.cpp", {cmd="close", filename=self.filename})
	end
end

function SerialPort:UpdateRemainingBytes(newBytes)
	self.totalBytesSent = (self.totalBytesSent or 0) + (newBytes or 0);
	local lastTime = self.lastCheckTime or commonlib.TimerManager.GetCurrentTime();
	self.lastCheckTime = commonlib.TimerManager.GetCurrentTime();
	local maxBytesSent = (self.lastCheckTime - lastTime) / 1000 * (self.baud_rate / 8 * self.uploadRateFactor);
	self.remainingBytes = math.max(0, (self.remainingBytes or 0)- maxBytesSent);
	self.remainingBytes = self.remainingBytes + (newBytes or 0);
	return self.remainingBytes;
end

-- @return remaining bytes to be sent. return 0 if all bytes are sent.
function SerialPort:GetRemainingBytes()
	if(self.remainingBytes and self.remainingBytes > 0) then
		return self:UpdateRemainingBytes();
	else
		return 0;
	end
end

local send_msg = {filename="com1", cmd="send"};
function SerialPort:send(data)
	if(self.isUseRateControl) then
		if(data) then
			self.queuedData = self.queuedData or {};
			while(#data >self.maxSendCount) do
				local first_data = data:sub(1, self.maxSendCount);
				data = data:sub(self.maxSendCount+1, #data);
				self.queuedData[#self.queuedData + 1] = first_data;
			end
			self.queuedData[#self.queuedData + 1] = data;
		end
		if((self:GetRemainingBytes()) >= self.maxSendCount) then
			commonlib.TimerManager.SetTimeout(function(timer)  
				self:send();
			end, 100);
			return
		else
			data = self.queuedData[1];
			table.remove(self.queuedData, 1)
		end
	end
	if(data) then
		send_msg.filename = self.filename;
		send_msg.data = data;
		local count = #data;
		self:UpdateRemainingBytes(count);
		-- LOG.std(nil, "debug", "SerialPort", "send %d bytes", count);
		--NPL.activate("script/serialport.cpp", send_msg)
		NPL.call("script/serialport.cpp", send_msg); -- activate now immediately

		if(self.isUseRateControl and #self.queuedData > 0) then
			commonlib.TimerManager.SetTimeout(function(timer)  
				self:send();
			end, 100);
		end
	end
end

function SerialPort:OnReceive(data)
	self:dataReceived(data, self);

	-- process line by line
	local remaining = (self.lineBuffer or "")..data;
	while (remaining) do
		local line, remaining2 = remaining:match("^([^\r\n]*)[\r\n]+(.*)$")
		if(line) then
			self:lineReceived(line, self);
			remaining = remaining2;
		else
			break;
		end
	end
	self.lineBuffer = remaining;
end

function SerialPort:OnError(msg)
	if(msg.cmd == "open") then
		LOG.std(nil, "warn", "serial port", "failed to open %s", msg.filename);
		self.isPortOpen = false;
	else		
		LOG.std(nil, "error", "serial port", "error on %s: %s", msg.filename, msg.error);
	end
end


NPL.this(function()
	local msg = msg;

	if (not msg.filename and msg.data) then
		msg = commonlib.Json.Decode(msg.data) or {};
	end

	if(msg.filename) then
		local serialPort = allports[msg.filename]
		if(serialPort) then
			if(msg.error) then
				serialPort:OnError(msg);
			else
				serialPort:OnReceive(msg.data)
			end
		else
			LOG.std(nil, "warn", "serial port", "no callback found for %s", msg.filename);
		end
	end
end)

