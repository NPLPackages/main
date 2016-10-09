--[[
Author: Li,Xizhi
Date: 2009-6-1
Desc: testing multithreaded NPL runtime environment

Tests results are run by CPU 2.5G with 4 cores on windows XP, so 25% CPU usage means 1 CPU core is 100% busy. 
the msg is a about 100 bytes each, by default 300,000 msg is tested, unless explicitly specified.  

==note==: The final results should be multiplied by 10% in RPS, since the recent memory optimizations. 

---+++ test_MultithreadedTimers()
Timers work as expected. Timer ids are not shared among different runtime states.

---++++ Use 4 threads to flush local message queue, 1 msg at a time
test_MultithreadedThroughput_Local({threadcount=4})
Result: msg_per_second=64000
CPU is 100%, thread count matches CPU cores, performance is great. 

---++++ Use 20 threads to flush local message queue, 1 msg at a time
test_MultithreadedThroughput_Local({threadcount=20})
Result: msg_per_second=25000
CPU is 40%, too many context switch that CPU is low.

---+++ test_MultithreadedThroughput
---++++ throughput using the loopback interface using 1 thread via 127.0.0.1
test_MultithreadedThroughput({threadcount=1})
Result: msg_per_second=31685
with mad computation, it drops to 6000
with 3 local socket connections, it drops to 24000, but CPU is also dropped to 30%

---++++ throughput using the loopback interface using 4 thread via 127.0.0.1
test_MultithreadedThroughput({threadcount=4})
Result: msg_per_second=29200

---++++ throughput using the loopback interface using 10 thread via 127.0.0.1 with mad computation
test_MultithreadedThroughput({threadcount=10})
Result: msg_per_second=18000

---++++ throughput using the loopback interface using 1 thread via 127.0.0.1
test_MultithreadedThroughput({threadcount=1, data="300 Bytes data|...................................................................................................||...................................................................................................||...................................................................................................|"})
Result: msg_per_second=17114
test_MultithreadedThroughput({threadcount=4, data="1000 Bytes data|...................................................................................................||...................................................................................................||...................................................................................................|300 Bytes data|...................................................................................................||...................................................................................................||...................................................................................................|300 Bytes data|...................................................................................................||...................................................................................................||...................................................................................................|"})
Result: msg_per_second=28000
test_MultithreadedThroughput({threadcount=4, data="2000 Bytes data|...................................................................................................||...................................................................................................||...................................................................................................|300 Bytes data|...................................................................................................||...................................................................................................||...................................................................................................|300 Bytes data|...................................................................................................||...................................................................................................||...................................................................................................||...................................................................................................||...................................................................................................||...................................................................................................|300 Bytes data|...................................................................................................||...................................................................................................||...................................................................................................|300 Bytes data|...................................................................................................||...................................................................................................||...................................................................................................|"})
Result: msg_per_second=21000

---++++ throughput using the loopback interface using 1 thread via 127.0.0.1
test_MultithreadedThroughput({threadcount=4, data="300 Bytes data|...................................................................................................||...................................................................................................||...................................................................................................|"})
Result: msg_per_second=28000

---+++ test_MultithreadedLoopback()
Combined test of epoll socket and message queue
---++++ 1 thread loop back test via localhost(127.0.0.1) 
Result: msg_per_second=11531

---++++ 1 producer, 3 consumers, double echo 1 msg at a time, using localhost(127.0.0.1) 
test_MultithreadedLoopback({threadcount=4})
Result: msg_per_second=11742

---++++ 1 producer, 3 consumers, double echo 1 msg at a time with MAD computation, using localhost(127.0.0.1) 
The mad computation code is as follow: 
local strCat = ""; for i=1,100 do strCat = strCat..i; end
test_MultithreadedLoopback({threadcount=4})

Result: msg_per_second=9922

---++++ 1 producer, 20 consumers, double echo 1 msg at a time with MAD computation, using localhost(127.0.0.1) 
test_MultithreadedLoopback({threadcount=20})
Result: msg_per_second=10094

---++++ 1 producer, 20 consumers, double echo 1 BIG msg at a time
test_MultithreadedLoopback({threadcount=20, data="300 Bytes data|...................................................................................................||...................................................................................................||...................................................................................................|"})
Result: msg_per_second=9785

---+++ test_LocalAsyncProcedureCall_echo()
This shows throughput of a one produer with multiple consumers looping-back echo performance (this is the worst-case semaphore performance). 
this is about the number of CPU context switches per second. 

---++++ 1 producer, 1 consumers, double echo 1 msg at a time
test_LocalAsyncProcedureCall_echo({consumer_count=1})
Result: msg_per_second=9846


---++++ 1 producer, 3 consumers, double echo 1 msg at a time
test_LocalAsyncProcedureCall_echo({consumer_count=3})
Even 4 threads are active, only 50% CPU usage is observed. Most times are spent on context switch. 
Result: msg_per_second=18079

---++++ 1 producer, 3 consumers, double echo 1 BIG msg at a time
test_LocalAsyncProcedureCall_echo({consumer_count=3, data="300 Bytes data|...................................................................................................||...................................................................................................||...................................................................................................|"})
Result: msg_per_second=15384

---++++ 1 producer, 20 consumers, double echo 1 msg at a time
test_LocalAsyncProcedureCall_echo({consumer_count=20})
Even 20 threads are active, only 50% CPU usage is observed. Most times are spent on context switch. 
Result: msg_per_second=13196


---++++ 1 producer, 3 consumers, double echo 3 msg at a time
this will cause msg to flood exponentially, until message queue of each runtime state is full. 
This gives the echo throughput when all producer/consumers message queues are full(overflowed). 
Result: msg_per_second=10207

---++++ 1 producer, 3 consumers, with 300Bytes big msg and 100 new string mad concartenation per msg in each consumer. 
The mad computation code is as follow: 
local strCat = ""; for i=1,100 do strCat = strCat..i; end
Result: msg_per_second=13061
			
-----------------------------------------------
NPL.load("(gl)script/test/TestMultithreaded.lua");
test_MultithreadedThroughput_Local({threadcount=1});
test_MultithreadedThroughput();
test_MultithreadedLoopback();
test_LocalAsyncProcedureCall_echo();
test_MultithreadedTimers();
-----------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua"); -- many sub dependency included
-- this is necessary to allow the file to be visible by remote computers. 
NPL.AddPublicFile("script/test/TestMultithreaded.lua", 1);

-- Test multithreaded runtime states in several(3 by default) worker threads each with a timer object. 
-- %TESTCASE{"test_MultithreadedTimers", func = "test_MultithreadedTimers", input = {}, }%
function test_MultithreadedTimers(input)
	-- create and start each of the worker runtime states. 
	local i, nCount = nil, 3
	for i=1,nCount do
		local rts_name = "worker"..i;
		local worker = NPL.CreateRuntimeState(rts_name, 0);
		worker:Start();
		NPL.activate(string.format("(%s)script/test/TestMultithreaded.lua", rts_name), {TestCase = "MT_Timers", rts_name=rts_name})
	end
end

-- Testing NPL socket layer throughput. Use one or several threads to flush localhost via 127.0.0.1, until the queue is full.
-- %TESTCASE{"test_MultithreadedThroughput", func = "test_MultithreadedThroughput", input = {threadcount=1}, }%
function test_MultithreadedThroughput(input)
	-- start the NPL server
	NPL.StartNetServer("127.0.0.1", "60001");
	--NPL.StartNetServer("192.168.0.107", "60001");
	input = input or {};
	
	local i, nCount = nil, input.threadcount or 1
	for i=1,nCount do
		local rts_name = "p"..i;
		local producer = NPL.CreateRuntimeState(rts_name, 0);
		producer:Start();
		-- start the producer
		local k, kSize = nil, math.floor(1000/nCount);
		for k=1, kSize do
			if(nCount > 1) then
				while( NPL.activate(string.format("(%s)localhost:script/test/TestMultithreaded.lua", rts_name), {TestCase = "TP", rts_name=rts_name, data=input.data}) ~=0 ) do end
			else
				-- please note: "localhost", "local", "127.0.0.1" are three internal names for the loop back socket interface, however they also present three different socket connections to the loopback NPL server.
				while( NPL.activate(string.format("(%s)localhost:script/test/TestMultithreaded.lua", rts_name), {TestCase = "TP", data=input.data})  ~=0 ) do end
				while( NPL.activate(string.format("(%s)local:script/test/TestMultithreaded.lua", rts_name), {TestCase = "TP", data=input.data})  ~=0 ) do end
				while( NPL.activate(string.format("(%s)127.0.0.1:script/test/TestMultithreaded.lua", rts_name), {TestCase = "TP", data=input.data})  ~=0 ) do end
			end	
		end	
	end	
end

-- Use one or several threads to flush local message queue
-- %TESTCASE{"test_MultithreadedThroughput_Local", func = "test_MultithreadedThroughput_Local", input = {threadcount=1}, }%
function test_MultithreadedThroughput_Local(input)
	-- start the NPL server
	input = input or {};
	
	local i, nCount = nil, input.threadcount or 1
	for i=1,nCount do
		local rts_name = "p"..i;
		local producer = NPL.CreateRuntimeState(rts_name, 0);
		producer:Start();
		-- start the producer
		local k, kSize = nil, 1 or math.floor(1000/nCount);
		for k=1, kSize do
			while( NPL.activate(string.format("(%s)script/test/TestMultithreaded.lua", rts_name), {TestCase = "TPL", rts_name=rts_name, data=input.data}) ~=0 ) do end
		end	
	end	
end

-- NPL socket loop back test. If threadcount == 1, it is pure loop back test. if threadcount>1, it will be producer-consumer test using the loop back interface. 
-- %TESTCASE{"test_MultithreadedLoopback", func = "test_MultithreadedLoopback", input = {threadcount=1}, }%
function test_MultithreadedLoopback(input)
	-- start the NPL server
	NPL.StartNetServer("127.0.0.1", "60001");
	
	input = input or {};
	
	-- create a producer state
	local producer = NPL.CreateRuntimeState("producer", 0);
	producer:Start();
	
	if(not input.threadcount or input.threadcount==1) then
		while( NPL.activate("(producer)localhost:script/test/TestMultithreaded.lua", {TestCase = "LP", data=input.data}) ~=0 ) do end
	else
		-- create 3 consumer runtime states. 
		local i, nCount = nil, input.threadcount-1
		for i=1,nCount do
			local rts_name = "consumer"..i;
			local worker = NPL.CreateRuntimeState(rts_name, 0);
			worker:Start();
			-- start from the producer
			while( NPL.activate("(producer)localhost:script/test/TestMultithreaded.lua", {TestCase = "LP", type="p", rts_name=rts_name, data=input.data})  ~=0 ) do end
		end	
	end
end


-- Test local async procedure call loopback echo throughput (this is limited by context switches a CPU does in a second).  
-- 1. a producer thread send a message to each of the three consumer threads.
-- 2. the consumer thread echoes the message upon receive to the producer thread.
-- 3. Unpon receiving the reply, the producer will send another message to the thread. go to 1.
-- The test shows the worst-case semaphore performance. 
-- Note: all above messages are routed between message queues of the local NPL runtime state threads(both producer and consumers are NPL runtime states)
-- %TESTCASE{"test_LocalAsyncProcedureCall", func = "test_LocalAsyncProcedureCall", input = {consumer_count=3, data=1}, }%
function test_LocalAsyncProcedureCall_echo(input)
	-- create a producer state
	local producer = NPL.CreateRuntimeState("producer", 0);
	producer:Start();
	
	input = input or {};
	
	-- create 3 consumer runtime states. 
	local i, nCount = nil, input.consumer_count or 3
	
	for i=1,nCount do
		local rts_name = "consumer"..i;
		local worker = NPL.CreateRuntimeState(rts_name, 0);
		worker:Start();
		-- start from the producer
		while( NPL.activate("(producer)script/test/TestMultithreaded.lua", {TestCase = "LAPC", type="p", rts_name=rts_name, data=input.data}) ~=0 ) do end
	end
end

local mytimer;

-- a function that only returns after specified time. 
-- @param nSecondToComplete: how many seconds to complete the job. 
local function BigJob(nSecondToComplete, msg)
	nSecondToComplete = nSecondToComplete or 20
	for i=1,nSecondToComplete do
		commonlib.echo(i);
		commonlib.echo(msg);
		ParaEngine.Sleep(1);
	end
end

local LAPC_stats = {
	-- number of messages received by producers
	counter = 0,
	start_time = 0,
	end_time = 0,
	-- test will stop after max_count messsages are echoed by the producer. 
	max_count = 100000, 
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

-- the receiver for remote activation. 
local function activate()
	if(msg.TestCase == "MT_Timers") then
		if(mytimer == nil) then
			mytimer = commonlib.Timer:new({
				callbackFunc = function(timer)
					commonlib.log(string.format("threaded timer %s: msg=%s\n", timer.id, msg.rts_name));
				end});
			-- start the timer after 0 milliseconds, and signal every 500 millisecond
			mytimer:Change(0, 500)
		else
			BigJob(20, msg);
		end
	elseif(msg.TestCase == "TP") then	
		-- throughput test
		if(TickStat(LAPC_stats)) then
			local i,echoes_count = nil, 1;
			for i=1,echoes_count do 
				local res;
				if(msg.rts_name) then
					local nid = "localhost"
					res = NPL.activate(string.format("(%s)%s:script/test/TestMultithreaded.lua", msg.rts_name or "p1", nid), {TestCase = "TP", rts_name = msg.rts_name, data=msg.data})
				else
					-- please note: "localhost", "local", "127.0.0.1" are three internal names for the loop back socket interface, however they also present three different socket connections to the loopback NPL server.
					local nid_map = {"localhost", "local", "127.0.0.1" };
					local nid = nid_map[LAPC_stats.counter%1+1];
					res = NPL.activate(string.format("(%s)%s:script/test/TestMultithreaded.lua", msg.rts_name or "p1", nid), {TestCase = "TP", rts_name = msg.rts_name, data=msg.data})
				end
				if(res ~= 0 )then 
					-- commonlib.echo(res);
					break;
				end
				-- Uncommend to add some mad computations with 100 new string concartenations. 
				-- local strCat = ""; local i; for i=1,100 do strCat = strCat..i; end
			end	
		end
	elseif(msg.TestCase == "TPL") then	
		-- through put local
		if(TickStat(LAPC_stats)) then
			res = NPL.activate(string.format("(%s)script/test/TestMultithreaded.lua", msg.rts_name), {TestCase = "TPL", rts_name = msg.rts_name, data=msg.data})
		end
	elseif(msg.TestCase == "LP") then
		-- loop back test
		if(not msg.type) then
			if(TickStat(LAPC_stats)) then
				NPL.activate("(producer)localhost:script/test/TestMultithreaded.lua", {TestCase = "LP", data=msg.data})
			end	
		elseif(msg.type=="p") then
			if(TickStat(LAPC_stats)) then
				NPL.activate(string.format("(%s)localhost:script/test/TestMultithreaded.lua", msg.rts_name), {TestCase = "LP", type="c", rts_name = msg.rts_name, data=msg.data})
			end	
		elseif(msg.type=="c") then
			-- consumers echoes producer asynchronously 
			NPL.activate("(producer)script/test/TestMultithreaded.lua", {TestCase = "LP", type="p", rts_name = msg.rts_name,data=msg.data})
			-- Uncommend to add some mad computations with 100 new string concartenations. 
			-- local strCat = ""; local i; for i=1,100 do strCat = strCat..i; end
		end
	elseif(msg.TestCase == "LAPC") then
		if(msg.type=="p") then
			if(TickStat(LAPC_stats)) then
				local i,echoes_count = nil, 1;
				for i=1,echoes_count do 
					if(type(msg.rts_name)=="string") then
						NPL.activate(string.format("(%s)script/test/TestMultithreaded.lua", msg.rts_name), {TestCase = "LAPC", type="c", rts_name = msg.rts_name, data=msg.data})
					end	
				end	
			end
		elseif(msg.type=="c") then
			-- consumers echoes producer asynchronously 
			NPL.activate("(producer)script/test/TestMultithreaded.lua", {TestCase = "LAPC", type="p", rts_name = msg.rts_name,data=msg.data})
			
			-- Uncommend to add some mad computations with 100 new string concartenations. 
			--local strCat = ""; local i; for i=1,100 do strCat = strCat..i; end
		end
	elseif(msg.TestCase == "dump") then	
		-- this is for debugging purposes. 
		commonlib.echo(LAPC_stats);
	end
end
NPL.this(activate)