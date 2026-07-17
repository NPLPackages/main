--[[
Title: TCP connection
Author(s): LiXizhi
Date: 2023/6/26
Desc: interface is similar to luasocket, but implemented in NPL.
Note: it always works in non-blocking mode with timeout == 0. So if you are polling for data, it will always return immediately with true, "timeout"
-------------------------------------------------------
NPL.load("(gl)script/ide/System/os/network/TcpConnection.lua");
local TcpConnection = commonlib.gettable("System.os.network.TcpConnection");

-- usage 1: low-level static api
NPL.AddNPLRuntimeAddress({host = "server.com", port = tostring(8080), nid = "YourServerNid"})
TcpConnection.AddConnectionHandler("YourServerNid", function(msg)
	echo({nid = msg.nid, data = msg[1]})
end)

-- usage 2: object oriented api, with async pattern
local conn = TcpConnection:new():Init("127.0.0.1", 8099)
conn:onReceive(function(data)
	echo(data)
end)
conn:Connect(function(bConnected)
	if(bConnected) then
		conn:Send("hello")
	end
end)

-- usage 3: coroutine api to write code in synchrounous pattern
local conn = TcpConnection:new():Init("paracraft.cn", 80)
conn:SetTimeout(0.5);
conn:SetMainLoopCoroutine(function()
	conn:Send("GET / HTTP/1.1\nHost: paracraft.cn\nConnection: Keep-Alive\n\n")
	while true do
		local packet, err = conn:Receive(20)
		if not packet then
		    if(err == "closed") then
			    break
			end
		end
		echo(packet or "timeout")
	end
	echo("connection closed")
end)
conn:Connect(function(bConnected) end);

-------------------------------------------------------
]]
NPL.load("(gl)script/ide/event_mapping.lua");

-- module table
local TcpConnection = commonlib.inherit(nil, commonlib.gettable("System.os.network.TcpConnection"));

-- mapping from serverNid to activation callback. 
local serverHandlers = {};

-- this is low-level static api to be used together with NPL.AddNPLRuntimeAddress({host = "server.com", port = tostring(8080), nid = "YourServerNid"})
-- @param serverNid: string, the server nid
-- @param callbackFunc: function(msg) end, the callback function to be called when some TCP data is received. 
function TcpConnection.AddConnectionHandler(serverNid, callbackFunc)
	TcpConnection.OneTimeInit();
	serverHandlers[serverNid] = callbackFunc;
end

function TcpConnection:ctor()
	self.timeout = 0;
end

local next_id = 0;
-- from existing server to nid map. 
local existingServer = {};

function TcpConnection:CreateNidByHostAndPort(host, port)
	host = host or "";
	port = tostring(port or 80);
	
	local name = string.format("tcp://%s:%s", host, port);
	-- local exitingNid = existingServer[name]
	next_id = next_id + 1;
	local nid = string.format("server%d", next_id)
	-- existingServer[name] = nid;
	return nid;
end

-- @param host: ip address or domain name
-- @param port: port number
-- @param onReceiveCallback: function(bConnected) end
function TcpConnection:Init(host, port, onReceiveCallback)
	self.host = host or "";
	self.port = tostring(port or 80);
	self.nid = self:CreateNidByHostAndPort(self.host, self.port)
	self.address = string.format("%s:tcp", self.nid);
	self.onReceiveCallback = onReceiveCallback;

	TcpConnection.OneTimeInit()
	return self;
end

function TcpConnection:onReceive(onReceiveCallback)
	self.isConnected = true;
	self.onReceiveCallback = onReceiveCallback;
end

-- @param callbackFunc: function(bConnected) end, this function is called when connection is established or timed out.
function TcpConnection:onConnect(onConnectCallback)
	self.isConnected = true;
	self.onConnectCallback = onConnectCallback;
end

function TcpConnection:GetServerNid()
	return self.nid;
end

-- Open network connection 
-- @param callbackFunc: function(bConnected) end, this function is called when connection is established or timed out.
-- @param timeoutSeconds: default to 2 seconds. if 0, it will return immediately.
function TcpConnection:Connect(callbackFunc, timeoutSeconds)
	TcpConnection.OneTimeInit()
	if(self.nid) then
		NPL.AddNPLRuntimeAddress({host = self.host, port = tostring(self.port), nid = self.nid})
		serverHandlers[self.nid] = function(msg)
			if(msg[1]) then
				if(self.onReceiveCallback) then
					self.onReceiveCallback(msg[1]);
				else
					self.receivedData = (self.receivedData or "")..msg[1];
				end
				if(self.isReceiving and self.co) then
					coroutine.resume(self.co);
				end
			else
				if(msg.code == NPLReturnCode.NPL_ConnectionEstablished) then
					LOG.std("", "system", "TcpConnection", "TCP Connection is established with %s", msg.nid);
					self.isConnected = true;
				elseif(msg.code == NPLReturnCode.NPL_ConnectionDisconnected) then
					LOG.std("", "system", "TcpConnection", "TCP Connection is disconnected with %s", msg.nid);
					self.isConnected = false;
				end
			end
		end
		NPL.activate_async_with_timeout(timeoutSeconds or 2, self.address, "", function(bConnected)
			self.isConnected = true;
			if(self.onConnectCallback) then
				self.onConnectCallback(bConnected);
			end
			if(callbackFunc) then
				callbackFunc(bConnected);
			end
			if(self.co) then
				coroutine.resume(self.co);
			end
		end)
		if(not self.isConnected and self.co) then
			if(coroutine.status(self.co) == "running") then
				coroutine.yield();
			end
		end
		return self.isConnected;
	end
end

function TcpConnection.OneTimeInit()
	if(TcpConnection.inited) then
		return
	end
	TcpConnection.inited = true;
	
	ParaScene.RegisterEvent("_n_tcp_network", ";System.os.network.TcpConnection.OnReceiveMsg();");

	NPL.AddPublicFile("script/ide/System/os/network/TcpConnection.lua", -30);
    NPL.StartNetServer("0.0.0.0", "0");
    
	LOG.std("", "info", "TcpConnection", "global listener initialized");
end

-- Shutdown network connection
function TcpConnection:Shutdown()
	NPL.reject(self.nid);
	serverHandlers[self.nid] = nil;
	self.isConnected = false;
end

-- Send data to network connection
-- data is the string to be sent. The optional arguments i and j work exactly like the 
-- standard string.sub Lua function to allow the selection of a substring to be sent.
-- Note: data is not buffered. For small strings, it is always better to concatenate them (with the '..' operator) 
-- and send the result in one call instead of calling the method several times.
function TcpConnection:Send(data, i, j)
	if i then
		data = string.sub(data, i, j)
	end
	if(NPL.activate(self.address, data) == 0)  then
		self.isConnected = true;
		return true
	else
		self.isConnected = false;
	end
end

-- return true if nByteCount data is received. othewise, false, if timed out. 
function TcpConnection:YieldForReceivedData(nByteCount)
	if(self.co) then
		if(self.timeout == nil) then
			while(not self.receivedData or (#self.receivedData)<nByteCount) do
				if(self.isConnected) then
					self.isReceiving = true;
					coroutine.yield()
					self.isReceiving = false;
				else
					return
				end
			end
			return true
		elseif(self.timeout == 0) then
			return true
		elseif(self.timeout > 0) then
			local time = ParaGlobal.timeGetTime();
			self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
				if(self.isReceiving and self.co) then
					coroutine.resume(self.co);
				end
			end})
			while(not self.receivedData or (#self.receivedData)<nByteCount) do
				if((ParaGlobal.timeGetTime() - time) > ((self.timeout or 0)*1000)) then
					return
				end
				if(self.isConnected) then
					self.timer:Change((self.timeout or 0)*1000, nil);
					self.isReceiving = true;
					coroutine.yield()
					self.isReceiving = false;
				else
					return
				end
			end
			return true
		end
	end
end

-- Set the main loop coroutine or main function and run it if connected, or whenever connection is established.  
-- @param co: coroutine object, or it can also be a main loop function, if it is a function, then a new couroutine will be created.
function TcpConnection:SetMainLoopCoroutine(co)
	if(type(co) == "function") then
		co = coroutine.create(co);
	end
	self.co = co;
	if(self.isConnected) then
		coroutine.resume(self.co);
	end
end

-- Receive given amount of data from network connection. 
-- This funciton is mostly used with SetMainLoopCoroutine, which allows you to write main loop in a synchrounous way. 
-- this function is not used if you provide a onReceiveCallback.
-- @param nByteCount: if nil, we will receive all data.
-- @param data, err: nil, "closed": it means connection is closed.
-- nil, "timeout|closed": the second parameter is "timeout" if there was a timeout during the operation.
-- the second parameter is "closed" if connection is closed.
function TcpConnection:Receive(nByteCount)
	if(self.co) then
		-- there is always a small timeout when using coroutine main loop. 
		if((self.timeout or 0) <= 0) then
			self.timeout = 0.01;
		end
		if(coroutine.status(self.co) ~= "running") then
			LOG.std("", "warn", "TcpConnection", "Receive is called outside of main loop coroutine. You must call it inside SetMainLoopCoroutine.");
			return nil, "timeout";
		end
	end
	local data = self.receivedData;
	if(data == nil) then
		if(nByteCount and nByteCount > 0) then
			if(self:YieldForReceivedData(nByteCount)) then
				return self:Receive(nByteCount);
			end
		elseif(self.co) then
			if(self:YieldForReceivedData(1)) then
				return self:Receive();
			end
		end
		if(self.isConnected) then
			return nil, "timeout"
		else
			return nil, "closed"
		end
	else
		if(nByteCount and nByteCount>0) then
			if(nByteCount < #(data)) then
				self.receivedData = string.sub(data, nByteCount+1);
				data = string.sub(data, 1, nByteCount);
			elseif(nByteCount == #(data)) then
				self.receivedData = nil;
			else -- if(nByteCount > #(data)) then
				if(self:YieldForReceivedData(nByteCount)) then
					return self:Receive(nByteCount);
				else
					if(self.isConnected) then
						return nil, "timeout"
					else
						return nil, "closed"
					end
				end
			end
		else
			self.receivedData = nil;
		end
		return data;
	end
end

-- Set connection's socket to non-blocking mode and set a timeout for it, if 0 means non-blocking. 
-- there is always a small timeout when using SetMainLoopCoroutine
-- @param timeout: seconds to timeout, default to 0. if nil, it will block forever until data is received.
function TcpConnection:SetTimeout(timeout)
	self.timeout = timeout
end

function TcpConnection.OnReceiveMsg()
	local serverNid = msg.nid or ""
	local handlerCallback = serverHandlers[serverNid]
	if(handlerCallback) then
		handlerCallback(msg);
	end
end
NPL.this(TcpConnection.OnReceiveMsg)