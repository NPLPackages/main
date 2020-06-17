--[[
Title: npl client for connecting socketio server
Author: leio
Date: 2020/4/26
Desc: 

refrences:
luasocketio: https://github.com/smiirl/luasocketio
lua-websockets: https://github.com/lipp/lua-websockets

socket.io-client: https://github.com/Automattic/socket.io-client
socket.io: https://github.com/socketio/socket.io

engine.io: https://github.com/socketio/engine.io
engine.io-parser: https://github.com/socketio/engine.io-parser

ws: https://github.com/websockets/ws

-----------------------------------------------
test example: https://github.com/socketio/socket.io/blob/master/examples/chat/index.js#L33

local SocketIOClient = NPL.load("(gl)script/ide/System/os/network/SocketIO/SocketIOClient.lua");
local url = "http://localhost:3000";
local client = SocketIOClient:new()
client:AddEventListener("OnOpen",function(self)
    commonlib.echo("===========OnOpen");
end,client)
client:AddEventListener("OnMsg",function(self,msg)
    commonlib.echo("===========msg.data");
    commonlib.echo(msg.data);
end,client)
client:Connect_Polling(url)


SocketIOClient.client = client;

local SocketIOClient = NPL.load("(gl)script/ide/System/os/network/SocketIO/SocketIOClient.lua");
SocketIOClient.client:Send("add user","leio 1")


local url = "http://socket-dev.kp-para.cn";
local userId = 135;
local token = "eyJhbGciOiJIUzEiLCJ0eXAiOiJKV1QifQ.eyJ1c2VySWQiOjEzNSwicm9sZUlkIjowLCJ1c2VybmFtZSI6ImtldmlueGZ0IiwiZXhwIjoxNTg4Mzg3MzU2LjI5M30.bW9sOU5OYVFUcVJvcmUvMUx6VGhpcmNuWkpNPQ";

local SocketIOClient = NPL.load("(gl)script/ide/System/os/network/SocketIO/SocketIOClient.lua");
local client = SocketIOClient:new();
client.callback = function (msg)
    commonlib.echo("==========HandleMsg");
    commonlib.echo(msg);
end
client:Connect(url,nil,{ userId = userId, token = token, });
client:Send("app/join",{
    room: "room 1",
});
client:Send("app/leave",{
    room: "room 1",
});
-----------------------------------------------
]]
NPL.load("(gl)script/ide/EventDispatcher.lua");
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/socket/url.lua");
local socket_url = commonlib.gettable("commonlib.socket.url")
local packet = require("./packet")
local tools = NPL.load("../WebSocket/tools");
local frame = NPL.load("../WebSocket/frame");
local handshake = NPL.load("../WebSocket/handshake");

local SocketIOClient = commonlib.inherit(commonlib.gettable("commonlib.EventSystem"), NPL.export());

local ack_id_counter = -1;

local SocketIOClient_Maps = {};

function SocketIOClient:ctor()
    self.keepalive_interval = 10000;
    self.address_id = "id_" .. ParaGlobal.GenerateUniqueID();

    SocketIOClient_Maps[self.address_id] = self;
end
function SocketIOClient:GetAddressID()
    return self.address_id;
end
function SocketIOClient:GetServerAddr()
	local server_addr = string.format("%s:tcp", self:GetAddressID());
    return server_addr;
end
--- Build the URL to call for a given transport and a given session id, if
-- defined. The returned URL is ensured to be unique, as a timestamp and an
-- incrementing counter is included, as specitifed by the socket.io protocol.
-- @param url The socket.io URL server
-- @param transport The transport which will use the URL
-- @param session_id If defined, the session ID. Else nil.
-- @return A string being the url
function SocketIOClient:BuildURL(url, transport, session_id, moreQuery)
    local parsed_url = socket_url.parse(url)

    if not parsed_url then
        return nil
    end

    parsed_url.path = "/socket.io/"

    local query = {}
    table.insert(query, "EIO=" .. tostring(packet.ENGINEIO_PROTOCOL_VERSION))

	local now = commonlib.TimerManager.GetCurrentTime();
    table.insert(query, string.format("t=%s", tostring(now)))

    table.insert(query, "transport=" .. transport)

    if session_id then
        table.insert(query, "sid=" .. session_id)
    end
    
    parsed_url.query = table.concat(query, "&")
    if(moreQuery)then
        local s = "";
        for k,v in pairs(moreQuery) do
            s = string.format("%s&%s=%s",s, k,tostring(v));
        end
        parsed_url.query = parsed_url.query .. s;
    end
    return socket_url.build(parsed_url)
end

-- create a connection by steps:
-- 1. polling for a session id from socketio server with a http request
-- 2. handshake websocket with session id(sid)
-- 3. send "upgrade" msg to server
function SocketIOClient:Connect_Polling(url,moreQuery)
    local polling_url = self:BuildURL(url, "polling", nil, moreQuery);
	LOG.std("", "info", "SocketIOClient", "polling_url:%s", polling_url);
    System.os.GetUrl({
        url = polling_url, 
        headers = {
        },
    }, 
    function(err, msg, data)
        if(err ~= 200)then
            LOG.std("", "error", "SocketIOClient", "polling failed:%s %s", err, commonlib.serialize(msg));
            return
        end	
        -- "96:0{\"sid\":\"V9BrbdhptLDBYlkFAAAQ\",\"upgrades\":[\"websocket\"],\"pingInterval\":25000,\"pingTimeout\":5000}2:40"
        local value = string.match(data,"%d:%d{(.+)}")
        if(not value)then
		    LOG.std("", "error", "SocketIOClient", "pasing sid failed:%s", data);
            return
        end
        value = string.format("{%s}",value);
        local out = {};
        if(NPL.FromJson(value, out)) then
            local sid = out.sid;
            if(out.pingInterval)then
                --self.keepalive_interval = out.pingInterval;
            end
            self:Connect(url,sid,moreQuery)
        end
    end);


end
function SocketIOClient:Connect(url,sid,moreQuery)
    url = self:BuildURL(url,"websocket",sid,moreQuery);
    local protocol,host,port,uri = tools.parse_url(url);
    port = port or 80;
    local key = tools.generate_key();
	LOG.std("", "info", "SocketIOClient", "Connect:%s", url);
    local token;
    if(moreQuery)then
        token = moreQuery.token;
    end
    local req = handshake.upgrade_request({
            key = key,
            host = host,
            port = port,
            protocols = {},
            origin = "",
            uri = uri,
            token = token,
    })
    self.key = key;
    self.state = "CONNECTING";

    NPL.AddPublicFile("script/ide/System/os/network/SocketIO/SocketIOClient.lua", -30);
	NPL.StartNetServer("0.0.0.0", "0");
	NPL.AddNPLRuntimeAddress({host = host, port = tostring(port), nid = self:GetAddressID()})
	

    if(NPL.activate_with_timeout(2, self:GetServerAddr(), req) == 0) then
    end
end
-- send a packet to server by tcp connection
-- encode steps:
-- 1. packet.encode for socketio protocol
-- 2. frame.encode for websocket protocol
-- @param {table} pkt: input msg
function SocketIOClient:SendPacket(pkt)
    if(not self:IsConnected())then
	    LOG.std(nil, "error", "SocketIOClient", "can't send packet, the connection is lost");
        return
    end
    local ok, pkt = packet.encode(pkt)
    if(ok)then
        local buffer = pkt;
        local encoded = frame.encode(buffer,frame.TEXT,true)
        local result = NPL.activate(self:GetServerAddr(),encoded);
        return result; 
    end
end
function SocketIOClient:Ping()
    local pkt = {
        eio_pkt_name = "ping",
    }
    local result = self:SendPacket(pkt);
    if(result ~= 0)then
        self.state = "CLOSED";
    end
end
function SocketIOClient:GetArgs(name, ...)
    local args = {name}
    local cb

    -- iterate over arguments and extract arguments and callback, if any.
    for i = 1, select("#", ...) do
        local v = select(i, ...)

        if type(v) == "function" then
            assert(not cb, "callback already defined")
            cb = v
        else
            table.insert(args, v)
        end
    end
    return args;
end

-- send msg to socketio server
--@param name: message key on server
function SocketIOClient:Send(name,...)
    local args = self:GetArgs(name, ...);

    ack_id_counter = ack_id_counter + 1;
    local pkt = {
        eio_pkt_name = "message",
        sio_pkt_name = "event",
        body = args,
        ack_id = ack_id_counter,
    }
    self:SendPacket(pkt);
end
function SocketIOClient:HandleOpen()
    self.state = "OPEN";
    local pkt = {
        eio_pkt_name = "upgrade",
    }
    self:SendPacket(pkt);
    self:KeepAlive();

    self:DispatchEvent({type = "OnOpen" });
end
function SocketIOClient:KeepAlive()
    if(not self.timer)then
        self.timer = commonlib.Timer:new({callbackFunc = function(timer)
           
	        if(self.state == "OPEN")then
                self:Ping();
            end
        end})
        self.timer:Change(0, self.keepalive_interval);
    end
end
function SocketIOClient:HandleClose()
    self.state = "CLOSED";
    self:DispatchEvent({type = "OnClose" });
end
function SocketIOClient:HandleMsg(msg)
    self:DispatchEvent({type = "OnMsg", data = msg });
end
function SocketIOClient:IsConnected()
    return self.state == "OPEN";
end
local function activate()
	--LOG.std("", "debug", "SocketIOClient OnMsg", msg);
    local nid = msg.nid;
    if(not nid)then
		LOG.std("", "error", "SocketIOClient", "activate nid is nil");
        return
    end
    local client = SocketIOClient_Maps[nid];
    if(not client)then
        return
    end
    local response = msg[1];
    -- waitting for handshake
    if(client.state == "CONNECTING")then
        local headers = handshake.http_headers(response)
		LOG.std("", "info", "SocketIOClient", "waitting for handshake:%s", client.key);
        local expected_accept = handshake.sec_websocket_accept(client.key)
        if (headers["sec-websocket-accept"] ~= expected_accept) then
            client.state = "CLOSED"
            return
        end
        client:HandleOpen();
    else
        local decoded,fin,opcode = frame.decode(response);
        if(opcode == frame.CLOSE)then
            client:HandleClose(nid)
            return
        end
        if(opcode == frame.TEXT)then
            local b, response = packet.decode(decoded);
            if(b)then
                client:HandleMsg(response)
            else
		        LOG.std("", "error", "SocketIOClient", "%s packet.decode failed:%s", nid, decoded);
            end
        else
		    LOG.std("", "error", "SocketIOClient", "%s received an unknown msg with opcode:%s", tostring(nid), tostring(opcode));
        end
    end
    
end
NPL.this(activate)