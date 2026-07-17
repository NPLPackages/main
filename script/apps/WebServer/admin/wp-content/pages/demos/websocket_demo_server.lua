--[[
Title: WebSocket Demo Server
Author: LiXizhi
Date: 2026/2/20
Desc: Minimal WebSocket server for the demo using WebSocketServer.
  - Delegates client management and message routing to WebSocketServer.
  - Broadcasts chat messages to all connected clients.
]]

NPL.load("(gl)script/ide/System/os/network/WebSocket/WebSocketServer.lua");
local WebSocketServer = commonlib.gettable("System.os.network.WebSocketServer");

local WS = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

-- Handler called by WebSocketServer when a message arrives for this demo
function WS:OnActivate(msg)
    if not msg or not msg.nid then return; end

    local nid = msg.nid;

    LOG.std(nil, "debug", "WS_Demo", "From %s: %s", nid, tostring(msg.text));

    -- Broadcast the exact text to all other connected clients
    WebSocketServer:Broadcast({text = msg.text}, nid);
end
