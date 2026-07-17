--[[
Title:  mqtt connection on NPL/tcp connection
Author(s): LiXizhi
Date: 2023/6/26
Desc: 
-------------------------------------------------------
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/os/network/TcpConnection.lua");
local TcpConnection = commonlib.gettable("System.os.network.TcpConnection");

local MqttConnection = NPL.export();

local next_id = 0;
-- Open network connection to .host and .port in conn table
-- Store opened socket to conn table
-- Returns true on success, or false and error text on failure
function MqttConnection.connect(conn, callbackFunc)
	local sock = TcpConnection:new():Init(conn.host, conn.port)
	sock:Connect(function(bConnected)
		if(bConnected) then
			conn.sock = sock;
			if(callbackFunc) then
				callbackFunc(true);
			end
		end
	end)
end

-- Shutdown network connection
function MqttConnection.shutdown(conn)
	conn.sock:Shutdown()
end

-- Send data to network connection
function MqttConnection.send(conn, data, i, j)
	return conn.sock:Send(data, i, j)
end

-- Receive given amount of data from network connection
function MqttConnection.receive(conn, size)
	return conn.sock:Receive(size)
end

-- Set connection's socket to non-blocking mode and set a timeout for it
function MqttConnection.settimeout(conn, timeout)
	conn.sock:SetTimeout(timeout)
end

function MqttConnection.SetMainLoopCoroutine(conn, mainloopFunc)
	conn.sock:SetMainLoopCoroutine(mainloopFunc)
end