--[[
Title: WebSocketServer
Author(s): LiXizhi
Date: 2026/2/20
Desc: this is a proxy server to accept websocket connection from client and 
forward the message to other NPL file by NPL.activate. the client (such as in H5) should send message in following json format:
{
    threadName: "main", // optional, default to main, the thread to activate on, e.g. "main" or "gl"
    filename: "script/path_to_your_file.lua", // the file to activate
    ... // other fields will be passed to the activated file as msg
}

## server side usage
in "script/path_to_your_file.lua", you should implement an OnActivate(msg) function to receive the message, e.g.:

```
local MyHandler = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
function MyHandler:OnActivate(msg)
    LOG.std(nil, "info", "MyHandler", "Received message from %s: %s", msg.nid, commonlib.Json.Encode(msg));
end
```

in your NPL http server you can call WebSocketServer:AddClient(tid, nid) when a new websocket connection is established
```
add_action('wp_ajax_handshake', function()
    -- Compute Sec-WebSocket-Accept
    NPL.load("(gl)script/ide/System/Encoding/sha1.lua");
    local Encoding = commonlib.gettable("System.Encoding");

    local key = request:header("Sec-WebSocket-Key");
    if not key or key == "" then
        response:status(400):send("missing Sec-WebSocket-Key");
        return;
    end

    key = key .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    key = Encoding.sha1(key, "base64");

    -- Send 101 Switching Protocols
    response.headers = {};
    response:add_header("status", "101 Switching Protocols");
    response:set_header("Connection", "Upgrade");
    response:set_header("Upgrade", "websocket");
    response:set_header("Sec-WebSocket-Accept", key);
    response:send_headers();

    -- Promote the raw TCP connection to WebSocket protocol
    local tid = request.nid;
    local nid = "ws_demo_" .. tostring(tid);
    
    NPL.load("(gl)script/ide/System/os/network/WebSocket/WebSocketServer.lua");
    local WebSocketServer = commonlib.gettable("System.os.network.WebSocketServer");
    WebSocketServer:AddClient(tid, nid);
    WebSocketServer:Broadcast({type = "system", text = nid .. " joined"}, nid);
    WebSocketServer:Send(nid, {type = "greeting", text = "Welcome!"});
end)
```

## javascript/client side usage
send message to a given file on the server in JSON format, e.g.:
```js
ws.send(JSON.stringify({ filename: "script/path_to_your_file.lua", text: "hello from client", ...}));
```

## Examples
- script/apps/WebServer/admin/wp-content/pages/demos/websocket_client.page
- script/apps/WebServer/admin/wp-content/pages/demos/websocket_demo_server.lua 

use the lib:
-------------------------------------------------------
NPL.load("script/ide/System/os/network/WebSocket/WebSocketServer.lua");
local WebSocketServer = commonlib.gettable("System.os.network.WebSocketServer");
WebSocketServer:AddClient(tid, nid);
WebSocketServer:Broadcast({type="system", text=nid.." joined"}, nid);
WebSocketServer:Send(nid, {type="greeting", text="Welcome!"});
-------------------------------------------------------
]] 
local WebSocketServer = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.os.network.WebSocketServer"));

function WebSocketServer:ctor()
end

WebSocketServer.isStarted = false

function WebSocketServer:Start(bForce)
    if not self.isStarted or bForce then
        self.isStarted = true
        LOG.std(nil, "info", "WebSocketServer", "WebSocketServer started and listening for connections...");
        NPL.AddPublicFile("script/ide/System/os/network/WebSocket/WebSocketServer.lua", -20);
        -- ParaScene.RegisterEvent("_n_websocket_network", ";System.os.network.WebSocketServer.OnNetworkEvent();");
        self:StartTimeoutTimer();
    end
end

-- NOT USED: Network event handler called by ParaScene event "_n_websocket_network"
function WebSocketServer.OnNetworkEvent()
end

-- clients table: nid -> {lastActivity = timestamp}, for all live WebSocket connections
WebSocketServer.clients = WebSocketServer.clients or {};

-- Client timeout in milliseconds (default 10 minutes)
WebSocketServer.clientTimeoutMs = WebSocketServer.clientTimeoutMs or (10 * 60 * 1000);

-- Set the client timeout in milliseconds
function WebSocketServer:SetClientTimeout(timeoutMs)
    self.clientTimeoutMs = timeoutMs;
end

-- Update client's last activity timestamp
function WebSocketServer:TouchClient(nid)
    if self.clients[nid] then
        self.clients[nid].lastActivity = commonlib.TimerManager.GetCurrentTime();
    end
end

-- Check and remove timed out clients
function WebSocketServer:CheckClientTimeouts()
    local now = commonlib.TimerManager.GetCurrentTime();
    local nidsToRemove = {};
    for nid, clientInfo in pairs(self.clients) do
        if (now - clientInfo.lastActivity) > self.clientTimeoutMs then
            nidsToRemove[#nidsToRemove + 1] = nid;
        end
    end
    for _, nid in ipairs(nidsToRemove) do
        LOG.std(nil, "info", "WebSocketServer", "Client %s timed out, removing", nid);
        self:CloseClient(nid);
    end
end

-- Start the timeout check timer
function WebSocketServer:StartTimeoutTimer()
    if self.timeoutTimer then return; end
    self.timeoutTimer = commonlib.Timer:new({callbackFunc = function()
        self:CheckClientTimeouts();
    end});
    -- Check every minute
    self.timeoutTimer:Change(60000, 60000);
end

-- Stop the timeout check timer
function WebSocketServer:StopTimeoutTimer()
    if self.timeoutTimer then
        self.timeoutTimer:Change();
        self.timeoutTimer = nil;
    end
end

-- Promote raw TCP connection tid to a named WebSocket client nid.
-- Calls NPL.accept + NPL.SetProtocol(1) and registers the client.
function WebSocketServer:AddClient(tid, nid)
    self:Start();
    NPL.accept(tid, nid);
    NPL.SetProtocol(nid, 1);
    self.clients[nid] = {lastActivity = commonlib.TimerManager.GetCurrentTime()};
    LOG.std(nil, "info", "WebSocketServer", "Client connected: %s", nid);
end

-- Remove a client from the registry.
function WebSocketServer:RemoveClient(nid)
    self.clients[nid] = nil;
    LOG.std(nil, "info", "WebSocketServer", "Client removed: %s", nid);
end

-- Close and remove a client connection.
function WebSocketServer:CloseClient(nid)
    NPL.reject(nid);
    self:RemoveClient(nid);
end

-- Number of connected clients.
function WebSocketServer:ClientCount()
    local n = 0;
    for _ in pairs(self.clients) do n = n + 1; end
    return n;
end

-- Send a table (serialised as JSON) to one specific client.
-- Returns false and removes the client if the send fails.
function WebSocketServer:Send(nid, data)
    local json = commonlib.Json.Encode(data);
    local ret = NPL.activate(string.format("%s:websocket", nid), json);
    if ret ~= 0 then
        LOG.std(nil, "warn", "WebSocketServer", "Send failed for %s (ret=%d), removing", nid, ret);
        self:RemoveClient(nid);
        return false;
    end
    return true;
end

-- Broadcast a table to every connected client.
-- except_nid (optional): skip this specific client.
-- nid_prefix (optional): only send to clients whose nid starts with this prefix.
function WebSocketServer:Broadcast(data, except_nid, nid_prefix)
    local nids = {};
    for nid in pairs(self.clients) do
        nids[#nids + 1] = nid;
    end
    for _, nid in ipairs(nids) do
        if nid ~= except_nid then
            if not nid_prefix or nid:sub(1, #nid_prefix) == nid_prefix then
                self:Send(nid, data);
            end
        end
    end
end

function WebSocketServer:SendMsg(nid, msg)
    local json_from = commonlib.Json.Encode(msg);
    local ret = NPL.activate(string.format("%s:websocket", nid), json_from);
    if ret ~= 0 then
        LOG.std(nil, "warn", "WebSocketServer", "SendMsg failed for %s (ret=%d), removing", nid, ret);
        self:RemoveClient(nid);
        return false;
    end
    return true;
end

local activateFileCache = {};
function WebSocketServer:GetActivateFile(neuron_file)
    if (neuron_file) then
        local cached = activateFileCache[neuron_file];
        if (cached) then
            return cached;
        end
        local handler = NPL.load(neuron_file);
        if (type(handler) == "table") then
            activateFileCache[neuron_file] = handler;
        end
        return handler;
    end
end
function WebSocketServer:OnConnect(msg)
    self:HandleMsg(msg);
end

function WebSocketServer:OnActivate(msg)
    if (not msg or not msg.nid) then return end

    local nid = msg.nid;

    -- Empty/nil payload means the client disconnected.
    if not msg[1] or msg[1] == "" then
        if self.clients[nid] then
            self:RemoveClient(nid);
            self:Broadcast({type = "system", text = nid .. " left"});
        end
        return;
    end

    -- Update client's last activity time
    self:TouchClient(nid);

    local json = msg[1];
    local out = {};
    if (NPL.FromJson(json, out)) then
        out.nid = nid;
        self:HandleMsg(out);
    end
end

local curThreadName = __rts__:GetName();
function WebSocketServer:HandleMsg(msg)
    local msgThreadName = msg.threadName or "main";
    local remoteNeuronFile = msg.filename or msg.remote_neuron_file;
    msgThreadName = msgThreadName == "gl" and "main" or msgThreadName;
    curThreadName = curThreadName == "gl" and "main" or curThreadName;
    
    if (msgThreadName ~= curThreadName) then
        NPL.activate(string.format("(%s)%s", msgThreadName, remoteNeuronFile), msg);
    else
        local handler = self:GetActivateFile(remoteNeuronFile);
        if (handler and handler.OnActivate) then
            handler:OnActivate(msg);
        end      
    end
end

WebSocketServer:InitSingleton()

NPL.this(function ()
	WebSocketServer:OnActivate(msg);
end)
