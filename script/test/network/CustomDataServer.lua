--[[
Author: leio
Date: 2020/10/29
Desc: testing simple server
-----------------------------------------------
NPL.load("(gl)script/test/network/CustomDataServer.lua");
test_start_simple_server();
-----------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included

-- for sending data to client by npl protocol
NPL.AddPublicFile("script/test/network/FakeClient.lua", 1);
-- for receiving data from client
NPL.AddPublicFile("script/test/network/CustomDataServer.lua", 2);

function test_start_simple_server()
	NPL.StartNetServer("127.0.0.1", "60001");
	input = input or {};
	local rts_name = "worker1";
	local worker = NPL.CreateRuntimeState(rts_name, 0);
	worker:Start();
	
	log("=====simple server is now started=========\n\n")
end

local function activate()
	log("server received: \n")
	commonlib.echo(msg);

    local user_id = "simpleclient";
	if(not msg.nid) then
		-- quick authentication, just accept any connection as simpleclient
		msg.nid = user_id;
		NPL.accept(msg.tid, msg.nid);
	end
    local data = {
        title = "hello world from server"
    }
    -- send data by npl protocol
    NPL.SetProtocol(user_id,0);
	NPL.activate("simpleclient:script/test/network/FakeClient.lua", {data})
    -- send data by custom protocol
    NPL.SetProtocol(user_id,2);
    local json = NPL.ToJson(data, true)
	NPL.activate("simpleclient:tcp", {json});
end
NPL.this(activate)