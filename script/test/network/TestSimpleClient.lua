--[[
Author: Li,Xizhi
Date: 2009-6-29
Desc: testing simple client
-----------------------------------------------
NPL.load("(gl)script/test/network/TestSimpleClient.lua");
test_start_simple_client();
-----------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included

-- make these files accessible by other machines
NPL.AddPublicFile("script/test/network/TestSimpleClient.lua", 1);
NPL.AddPublicFile("script/test/network/TestSimpleServer.lua", 2);

-- NPL simple client
-- %TESTCASE{"test_start_simple_client", func = "test_start_simple_client", input = {threadcount=1}, }%
function test_start_simple_client(input)
	NPL.StartNetServer("127.0.0.1", "60002");
	input = input or {};
	
	-- add the server address
	NPL.AddNPLRuntimeAddress({host="127.0.0.1", port="60001", nid="simpleserver"})
	
	-- push the first message to server
	local i, nCount = nil, input.threadcount or 1
	for i=1,nCount do
		local rts_name = "worker"..i;
		while( NPL.activate(string.format("(%s)simpleserver:script/test/network/TestSimpleServer.lua", rts_name), {TestCase = "TP", data="from client"}) ~=0 ) do end
	end
end

local function activate()
	if(msg.TestCase == "TP") then	
		log("client received: \n")
		commonlib.echo(msg)
	end
end
NPL.this(activate)