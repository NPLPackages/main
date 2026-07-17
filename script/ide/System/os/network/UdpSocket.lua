--[[
Title: UdpSocket
Author(s):  wuxiangan, lixizhi
Date: 2025-5-30
Desc: UdpSocket is a simple udp socket class based on NPL runtime. 
because udp socket is not client/server, but a stateless peer to peer network, the class is designed to be a singleton class. 
Upd can share the same port number with TCP, so the default port number is 8099, same as NPL runtime's default TCP server. 

Alternatively, NPL.activate support UDP unicast/multicase with its own message format. You can use NPL.activate directly without
using this class. However, if you want to use a callback function to handle non-NPL incoming data, you need to use this class.
e.g. to activate another NPL file using UDP, you can use the following code:
-- 1 is channel id, 2 is priority, 0 is for UDP UNRELIABLE
NPL.activate("(gl)filename", { your_data_table}, 1, 2, 0)
-- to broadcast to a given port, use following
NPL.activate("(gl)*8099:filename", { your_data_table}, 1, 2, 0)
-- to send to a given ip port, use following
NPL.activate("(gl)\\127.0.0.1 8099:filename", { your_data_table}, 1, 2, 0)
-- send with raw data. 
NPL.activate("\\127.0.0.1 8099:raw", "send raw data", 1, 2, 0)

use the lib:
------------------------------------------------------------
local UdpSocket = NPL.load("(gl)script/ide/System/os/network/UdpSocket.lua");

-- Once opened, both NPL and custom UDP messages will be received by UdpSocket's message handler. 
UdpSocket:Open(8099);

-- send and receive using custom functions, supporting all any message format. 
UdpSocket:Send("127.0.0.1", 1234, "hello world");
UdpSocket:Send("255.255.255.255", 1234, "hello world 255.255.255.255");
-- send using NPL message format via UDP, the receving side will get NPL file activation sautomatically. 
UdpSocket:Activate("127.0.0.1", 8099, "script/test/upd.lua", { a = 1 })

-- receive via singlethon callback, support only one receiver
UdpSocket:Recv(function(data)
	print(data)
end)
-- receive via signals supporting multiple listeners
UdpSocket:Connect("OnReceiveData", function(data)
	print(data)
end)
------------------------------------------------------------
]]
local UdpSocket = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
UdpSocket:Property("IgnoreSelfPacket", true, "IsIgnoreSelfPacket", "SetIgnoreSelfPacket"); -- ignore packet sent from self.
commonlib.setfield("System.os.network.UdpSocket", UdpSocket);

UdpSocket:Signal("OnReceiveData");

function UdpSocket:ctor()
    self.m_callback = nil;
    self.m_port = 8099;
end

function UdpSocket:OneTimeInit()
    if(self.m_bInited) then
		return
	end
    self.m_bInited = true;
    
    NPL.AddPublicFile("script/ide/System/os/network/UdpSocket.lua", -40);
end

function UdpSocket:RefreshIPList()
	local att = NPL.GetAttributeObject();
	NPL.load("(gl)script/ide/System/os/network/IPAddress.lua");
	local IPAddress = commonlib.gettable("System.os.network.IPAddress");
	local broadcastAddressList = IPAddress.GetBrodcastIps()
    self.m_broadcast_ips = broadcastAddressList or {};

	local externalIPList = IPAddress.ExternalIPList()
	self.externalIPList = externalIPList or {}
end

-- @param port: if nil, it will be a default port number (8099) when you call Open function.
-- Upd can share the same port number with TCP, so the default port number is 8099, same as NPL runtime's default TCP server. 
function UdpSocket:Open(port)
    self:OneTimeInit();
    self:RefreshIPList();

    port = port or self.m_port;
    if (self.m_open and self.m_port == port) then 
        return 
    end
    local att = NPL.GetAttributeObject();

    if (self.m_open and self.m_port ~= port) then
        att:CallField("DisableUDPServer");  -- this prevent crash if multiple clients open the same port
    end

    att:SetField("EnableUDPServer", port);
    self.m_port = port;
    self.m_open = true;

    LOG.std(nil, "info", "UdpSocket", "UdpSocket opened on port %d", port);
end

function UdpSocket:SetIgnoreSelfPacket(bIgnore)
    self.m_bIgnoreSelfPacket = bIgnore;
end

function UdpSocket:Close()
    local att = NPL.GetAttributeObject();
    att:CallField("DisableUDPServer");
    self.m_open = false;
    -- self.m_callback = nil;
end

-- @param ip: if nil or "*", it is broadcast. it can also be ipv4 address like "127.0.0.1"
-- @param port: if nil, it will be a default port number when you call Open function.
-- @param filename: string, the NPL file name to activate. To save bandwidth, it is recommended to call NPL.AddPublicFile(filename, id) on all computers.
-- so that id is used instead of long filename during transmission. Use id larger than 200 to avoid conflict with internal system.
-- @param data: any data table to send.
-- @param channel: channel id, if nil, default to 1
-- @param priority: priority, if nil, default to 2
  function UdpSocket:Activate(ip, port, filename, data, channel, priority)
    port = port or 8099
    channel = channel or 1
    priority = priority or 2
    if(not ip or ip == "*") then
        NPL.activate(string.format("(gl)*%s:%s", tostring(port), filename), data, channel, priority, 0);
    else
        NPL.activate(string.format("(gl)\\\\%s %s:%s", ip, tostring(port), filename), data, channel, priority, 0);
    end
end

-- send data to ip and port, data is string
-- @param data: raw string data to send.
-- @param ip: string, ip address. if nil or "" or "*", it will be broadcast message. 
-- @param port: if nil, it will be a default port number when you call Open function.
function UdpSocket:Send(ip, port, data)
    if (not self.m_open) then self:Open(port) end

    if(not ip or ip == "" or ip == "*") then
        self:Broadcast(data, port)
    else
        port = tostring(port or self.m_port);
        data = data or "";
        NPL.activate(string.format("\\\\%s %s:raw", ip, tostring(port)), data, 1, 2, 0);
    end
end

-- Broadcast data to all broadcast ips on this computer. 
-- Please note, this is not equal to Sending to 255.255.255.255. 
function UdpSocket:Broadcast(data, port)
    if (not self.m_open) then self:Open(port) end
   
    for _, ip in ipairs(self.m_broadcast_ips) do
        self:Send(ip, port or self.m_port, data);
    end
end

-- there can only be one callback, calling this multiple times will overwrite the previous callback.
-- use UdpSocket:Connect("OnReceiveData",...) for multiple callbacks
function UdpSocket:Recv(callback)
    self.m_callback = callback;
end

function UdpSocket:GetTid(ip, port) 
    -- string.format("~udp%s_%s", ip, port);  ~udp127.0.0.1_1234
    return "~udp" .. tostring(ip) .. "_" .. tostring(port); 
end

function UdpSocket:HandleMsg(msg) 
    local nid = msg.nid or msg.tid; 
    local data = msg.data;
    
    if(self:IsIgnoreSelfPacket() and self.externalIPList) then
        local ip, port = nid:match("^~udp([^_]+)_(%d+)");
        if(port) then
            port = tonumber(port);
            if(port == self.m_port) then
                for _, v in ipairs(self.externalIPList) do
			        if(ip == v) then
				        return;
			        end
		        end
            end
        end
    end

    if (self.m_callback) then self.m_callback(data) end
    self:OnReceiveData(data);
end

UdpSocket:InitSingleton();

NPL.this(function()
    UdpSocket:HandleMsg(msg);
end);