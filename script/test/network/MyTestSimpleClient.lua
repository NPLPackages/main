--[[
Author: Li,Xizhi
Date: 2009-6-29
Desc: testing simple client
-----------------------------------------------
NPL.load("(gl)script/test/network/MyTestSimpleClient.lua");
test_start_simple_client();
-----------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included

-- make these files accessible by other machines
--NPL.AddPublicFile("script/test/network/MyTestServer.lua", 1);
	NPL.LoadPublicFilesFromXML("config/NPLPublicFiles.xml");
	
	NPL.StartNetServer("127.0.0.1", "60002");
	
	-- add the server address
	NPL.AddNPLRuntimeAddress({host="192.168.0.251", port="60001", nid="routerserver"})

-- NPL simple client
-- %TESTCASE{"test_start_simple_client", func = "test_start_simple_client", input = {threadcount=1}, }%
function test_start_simple_client(input)
	input = input or {};
	
	-- push the first message to server
	local i, nCount = nil, input.threadcount or 1
	for i=1,nCount do
		local rts_name = i; 
		log("activate server here.\n");
		--i am db server
		--while( NPL.activate(string.format("(%s)routerserver:script/apps/NPLRouter/NPLRouter.lua",rts_name), {ver="1.0",my_nid=2001,game_nid=2001,user_nid=10089,data_table={name1="value1",name2="value2",},}) ~=0 ) do end
		
		--i am game server
		while( NPL.activate(string.format("routerserver:script/apps/NPLRouter/NPLRouter.lua"), {ver="1.0",dest="db",d_rts="1",game_nid=2001,user_nid=10089,data_table={name1="value1",name2="value2",},}) ~=0 ) do end
		log("activate server end.\n");
		
	end
end

local function activate()
	if(msg.TestCase == "TP") then	
		log("client received: \n")
		commonlib.echo(msg)
	end
end
NPL.this(activate)