--[[
Author: Gosling
Date: 2009-7-13
Desc: testing router
-----------------------------------------------
NPL.load("(gl)script/test/TestRouter.lua");
router_start_server();
-----------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included
NPL.load("(gl)script/ide/log.lua");

local dbserver_addresses = {
{
	host = "192.168.0.251",
	port = "61001",
	nid = "1001",
},
{
	host = "192.168.0.251",
	port = "61002",
	nid = "1002",
},
{
	host = "192.168.0.251",
	port = "61003",
	nid = "1003",
},
};
-- make these files accessible by other machines
NPL.AddPublicFile("script/test/network/MyTestClient.lua", 1);
NPL.AddPublicFile("script/test/network/MyTestServer.lua", 2);

-- start the NPL  server with some worker NPL runtime states "worker1", "worker2", etc. 
-- %TESTCASE{"test_start_server", func = "test_start_server", input = {threadcount=1}, }%
function router_start_server(input)
	NPL.StartNetServer("192.168.0.251", "60001");	
	
	local i;
	for i=1, #dbserver_addresses do
		NPL.AddNPLRuntimeAddress(dbserver_addresses[i]);
	end
	
	--commonlib.applog("hello %s %d\n", "paraengine",300)
	
	input = input or {};

	local i, nCount = nil, input.threadcount or 10
	for i=1,nCount do
		local rts_name = "p"..i;
		local worker = NPL.CreateRuntimeState(rts_name, 0);
		worker:Start();
	end
	
	log("===== router server is now started=========\n\n")
end

local function activate()
	if(not msg.nid) then
		-- quick authentication, just accept any connection as client
		msg.nid = "client";
		NPL.accept(msg.tid, msg.nid);
	end
	NPL.activate("NPLRouter.dll", {data = msg.data});
end
NPL.this(activate)
