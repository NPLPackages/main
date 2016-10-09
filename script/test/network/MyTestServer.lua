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
NPL.load("(gl)script/ide/log.lua");

local server_address = {
	""
}
-- make these files accessible by other machines
--NPL.AddPublicFile("script/test/network/MyTestServer.lua", 1);
--NPL.AddPublicFile("script/test/network/MyTestSimpleClient.lua", 2);
--NPL.AddPublicFile("script/apps/NPLRouter/NPLRouter.lua", 3);
NPL.LoadPublicFilesFromXML("config/NPLPublicFiles.xml");

-- start the NPL  server with some worker NPL runtime states "worker1", "worker2", etc. 
-- %TESTCASE{"test_start_server", func = "test_start_server", input = {threadcount=1}, }%
function test_start_server(input)
	NPL.StartNetServer("192.168.0.251", "62001");	
	commonlib.applog("hello %s %d\n", "paraengine",300)
	
	input = input or {};

	local i, nCount = nil, input.threadcount or 10
	for i=1,nCount do
		local rts_name = "p"..i;
		local worker = NPL.CreateRuntimeState(rts_name, 0);
		worker:Start();
	end
	
	log("===== server is now started=========\n\n")
end



local function activate()
	if(not msg.nid) then
		-- quick authentication, just accept any connection as client
		msg.nid = "client";
		NPL.accept(msg.tid, msg.nid);
	end
	
--	commonlib.echo("id=" .. (msg.nid or msg.tid) .. ",rts_name=" .. (msg.rts_name or "p1"));
commonlib.echo({msg.my_nid,msg.user_nid,msg.game_nid,msg.ver,msg.data_table});
		
	if(msg.TestCase == "TP") then	
		-- throughput test, just echo everything
		--local res = NPL.activate(string.format("(%s)%s:script/test/network/MyTestClient.lua", msg.rts_name or "p1", msg.nid), {TestCase = "TP", rts_name = msg.rts_name, data=msg.data})
	end
end
NPL.this(activate)
