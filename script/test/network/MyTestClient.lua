--[[
Author: Li,Xizhi
Date: 2009-6-29
Desc: testing  client
---+++ test cases
Computer 2.5G (4 cores) 2GB memory, running windows XP, and opensuse 11(using vmware).
The client is on winXP, the server is on linux vmware, both on the same machine. 10,000 messsages (100bytes per msg) is sent per thread. 

All server states just echoes the client's messages. Each client state counts the replies.
   * 1 thread: 8000 msg/sec
   * 2 thread: 4750*2 = 9500 msg/sec
 
-----------------------------------------------
NPL.load("(gl)script/test/network/TestClient.lua");
test_start_client();
-----------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included

local server_address = {
	host = "192.168.0.251",
	port = "60001",
	nid = "server001",
}

-- make these files accessible by other machines
NPL.AddPublicFile("script/test/network/MyTestClient.lua", 1);
NPL.AddPublicFile("script/test/network/MyTestServer.lua", 2);

-- NPL  client
-- %TESTCASE{"test_start_client", func = "test_start_client", input = {threadcount=1}, }%
function test_start_client(input)
	NPL.StartNetServer("127.0.0.1", "60002");
	input = input or {};
	
	
	-- add the server address
	NPL.AddNPLRuntimeAddress(server_address);
	
	-- push the first message to server
	local i, nCount = nil, input.threadcount or 10
	for i=1, nCount do
		local rts_name = "p"..i;
		local producer = NPL.CreateRuntimeState(rts_name, 0);
		producer:Start();
		
		-- start the producer
		local k, kSize = nil, math.floor(20/nCount);
		for k=1, kSize do
			--commonlib.echo("k=" .. k .. ",rts_name=" .. rts_name);
			while( NPL.activate(string.format("(%s)%s:script/test/network/MyTestServer.lua", rts_name, server_address.nid), {TestCase = "TP", data="from client", rts_name=rts_name, }) ~=0 ) do end
		end	
	end
end


local LAPC_stats = {
	-- number of messages received by producers
	counter = 0,
	start_time = 0,
	end_time = 0,
	-- test will stop after max_count messsages are echoed by the producer. 
	max_count = 1000, 
	--max_count = 15,
	rts_name = __rts__:GetName(),
}

-- @param stat: a table containing statistics, see LAPC_stats
-- return true if this is a normal activate
local function TickStat(stat)
	stat.counter = (stat.counter or 0) + 1;
	if(stat.counter == 1) then
		-- record the test start time
		stat.start_time = ParaGlobal.timeGetTime();
	end	
	if(stat.counter < stat.max_count) then
		return true;
	elseif(stat.counter == stat.max_count) then
		-- let us report stats, when max_count is reached.
		stat.end_time = ParaGlobal.timeGetTime();
		stat.elapsed_time = stat.end_time - stat.start_time;
		stat.msg_per_second = stat.counter/stat.elapsed_time*1000;
		commonlib.echo(stat);
	end
end

local function activate()
	if(msg.TestCase == "TP") then	
		if(TickStat(LAPC_stats)) then
			local i,echoes_count = nil, 1;
			for i=1,echoes_count do 
				--commonlib.echo("id=" .. (msg.nid or msg.tid) .. ",rts_name=" .. (msg.rts_name or "p1"));
				local res = NPL.activate(string.format("(%s)%s:script/test/network/MyTestServer.lua", msg.rts_name or "p1", msg.nid or msg.tid), {TestCase = "TP", rts_name = msg.rts_name, data=msg.data})
				if(res ~= 0 )then 
					commonlib.echo("break");
					break;
				end
				-- Uncommend to add some mad computations with 100 new string concartenations. 
				-- local strCat = ""; local i; for i=1,100 do strCat = strCat..i; end
			end	
		end
	end
end
NPL.this(activate)