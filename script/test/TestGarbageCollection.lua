--[[
Author: LiXizhi
Date: 2010.12.25
Desc: testing GC
-----------------------------------------------
NPL.load("(gl)script/test/TestGarbageCollection.lua");
-----------------------------------------------
]]
NPL.load("(gl)script/ide/UnitTest/luaunit.lua");

TestGarbageCollection = {} --class

function TestGarbageCollection:setUp()
    -- set up tests
end

-- called when receives garbage collection request 
-- input msg is like {type="gc", opt="step", args={}, reply_file="(main)"}
-- 
-- "stop": stops the garbage collector.
-- "restart": restarts the garbage collector. 
-- "collect": performs a full garbage-collection cycle. 
-- "step": performs a garbage-collection step. The step "size" is controlled by arg (larger values mean more steps) in a non-specified way. 
-- "setpause": The garbage-collector pause controls how long the collector waits before starting a new cycle. 
--    Larger values make the collector less aggressive. Values smaller than 100 mean the collector will not wait to start a new cycle. 
--    The default,200, means that the collector waits for the total memory in use to double before starting a new cycle.
-- "setstepmul": The step multiplier controls the relative speed of the collector relative to memory allocation. 
--    Larger values make the collector more aggressive but also increase the size of each incremental step. 
--    Values smaller than 100 make the collector too slow and can result in the collector never finishing a cycle. 
--    The default, 200, means that the collector runs at "twice" the speed of memory allocation. 
function TestGarbageCollection:OnGarbageCollect(msg)
	msg.args = msg.args or {};
	local tick_before = ParaGlobal.timeGetTime();
	local before_count = collectgarbage("count");
	local gc_result = collectgarbage(msg.opt, msg.args[1], msg.args[2]);
	local after_count = collectgarbage("count");
	local tick_after = ParaGlobal.timeGetTime();
	if(msg.reply_file) then
		NPL.activate(msg.reply_file, {type="gc_reply", before_count = before_count, gc_result = gc_result, after_count = after_count, rts = __rts__:GetName(), gc_time = tick_after - tick_before,})	
	end
end

-- print all GC results
function TestGarbageCollection:OnPrintGCResult()
	if(self.gc_results) then
		local total_before, total_after = 0,0;
		local rts_name, msg
		for rts_name, msg in pairs(self.gc_results) do
			total_before = total_before + msg.before_count;
			total_after = total_after + msg.after_count;
			LOG.std(nil, "system", "GC", "Thread: %s | before: %d KB | after %d KB | finished cycle: %s | time used: %d", msg.rts, msg.before_count, msg.after_count, tostring(msg.gc_result), msg.gc_time);
		end
		LOG.std(nil, "system", "GC", "Total Mem | before: %d KB | after %d KB | ", total_before, total_after);
	end
end

local global_temp;
function TestGarbageCollection:test_GC_params()
	collectgarbage("setpause", 90);
	collectgarbage("setstepmul", 300);

	local before_count = collectgarbage("count");
	LOG.std(nil, "info", "GC", " now: %d KB |", before_count);

	NPL.load("(gl)script/ide/STL.lua");
	global_temp = commonlib.List:new();

	local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		local outer_i;
		local temp = {};
		for outer_i = 1, 25 do
			local random_string = "";
			local i;
			for i=1,100 do
				random_string = random_string..tostring(math.random(1,1000000000));
				temp[#temp+1] = {randomstring = random_string};
			end
		end
		global_temp:add(temp);
		if(global_temp:size() > 400) then
			global_temp:remove(global_temp:first());
		end
	end})

	mytimer:Change(100, 0);

	local time_before = ParaGlobal.timeGetTime();

	-- printer
	local mytimer_printer = commonlib.Timer:new({callbackFunc = function(timer)
		local before_count = collectgarbage("count");
		local time_after = ParaGlobal.timeGetTime();
		LOG.std(nil, "info", "GC", " now: %8d KB | time elapsed: %d", before_count, (time_after-time_before)/1000);
	end})
	mytimer_printer:Change(0, 2000)

	-- now stops everything and clear memory. 
	local mytimer_stop = commonlib.Timer:new({callbackFunc = function(timer)
		mytimer_printer:Change();
		mytimer:Change();
		-- this will clear the 300MB sized object. 
		global_temp = nil;
		local time_before = ParaGlobal.timeGetTime();
		collectgarbage("collect");
		local time_after = ParaGlobal.timeGetTime();
		local before_count = collectgarbage("count");
		LOG.std(nil, "info", "GC", " GC complete--------now: %d KB | time used: %d|", before_count, time_after-time_before);

	end})
	mytimer_stop:Change(20000, nil)
end

LuaUnit:run("TestGarbageCollection:test_GC_params")
-- LuaUnit:run("TestGarbageCollection")