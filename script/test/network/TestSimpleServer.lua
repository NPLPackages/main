--[[
Author: Li,Xizhi
Date: 2009-6-29
Desc: testing simple server
-----------------------------------------------
NPL.load("(gl)script/test/network/TestSimpleServer.lua");
test_start_simple_server();
-----------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included

-- make these files accessible by other machines
NPL.AddPublicFile("script/test/network/TestSimpleClient.lua", 1);
NPL.AddPublicFile("script/test/network/TestSimpleServer.lua", 2);

-- start the NPL simple server with some worker NPL runtime states "worker1", "worker2", etc. 
-- %TESTCASE{"test_start_simple_server", func = "test_start_simple_server", input = {threadcount=1}, }%
function test_start_simple_server(input)
	NPL.StartNetServer("127.0.0.1", "60001");
	input = input or {};

	local i, nCount = nil, input.threadcount or 1
	for i=1,nCount do
		local rts_name = "worker"..i;
		local worker = NPL.CreateRuntimeState(rts_name, 0);
		worker:Start();
	end
	
	log("=====simple server is now started=========\n\n")
end

local function activate()
	if(msg.TestCase == "TP") then	
		log("server received: \n")
		commonlib.echo(msg);
		if(not msg.nid) then
			-- quick authentication, just accept any connection as simpleclient
			msg.nid = "simpleclient";
			NPL.accept(msg.tid, msg.nid);
		end
		NPL.activate("simpleclient:script/test/network/TestSimpleClient.lua", {TestCase = "TP", data="from server"})
	end
end
NPL.this(activate)