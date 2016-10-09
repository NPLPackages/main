--[[
Author: Li,Xizhi
Date: 2009-7-2
Desc: testing server
-----------------------------------------------
NPL.load("(gl)script/test/network/TestServer.lua");
test_start_server();
-----------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included

local server_address = {
	""
}
-- make these files accessible by other machines
NPL.AddPublicFile("script/test/network/TestClient.lua", 1);
NPL.AddPublicFile("script/test/network/TestServer.lua", 2);

-- start the NPL  server with some worker NPL runtime states "worker1", "worker2", etc. 
-- %TESTCASE{"test_start_server", func = "test_start_server", input = {threadcount=1}, }%
function test_start_server(input)
	NPL.StartNetServer("192.168.0.115", "60001");
	input = input or {};

	local i, nCount = nil, input.threadcount or 2
	for i=1,nCount do
		local rts_name = "p"..i;
		local worker = NPL.CreateRuntimeState(rts_name, 0);
		worker:Start();
	end
	
	log("===== server is now started=========\n\n")
end

local function test_adapter_info()
	local mac = ParaEngine.GetAttributeObject():GetField("MaxMacAddress","")
	local ip = ParaEngine.GetAttributeObject():GetField("MaxIPAddress","")
	echo({mac, ip});
end


local function activate()
	if(not msg.nid) then
		-- quick authentication, just accept any connection as client
		msg.nid = "client";
		NPL.accept(msg.tid, msg.nid);
	end
		
	if(msg.TestCase == "TP") then	
		-- throughput test, just echo everything
		local res = NPL.activate(string.format("(%s)%s:script/test/network/TestClient.lua", msg.rts_name or "p1", msg.nid), {TestCase = "TP", rts_name = msg.rts_name, data=msg.data})
	end
end
NPL.this(activate)
