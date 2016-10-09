--[[
Author: LiXizhi
Date: 2011.7.12
Desc: testing NPL monitor
-----------------------------------------------
NPL.load("(gl)script/test/TestNPLMonitor.lua");
-----------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/UnitTest/luaunit.lua");
NPL.load("(gl)script/ide/NPLStatesMonitor.lua");

TestNPLMonitor = {} --class

function TestNPLMonitor:setUp()
    
end

-- test the global log interface
function TestNPLMonitor:test_NPL_monitor_queue_size()
	NPL.load("(gl)script/ide/NPLStatesMonitor.lua");

	local worker = NPL.CreateRuntimeState("r1", 0);
	worker:Start();

	local monitor = commonlib.NPLStatesMonitor:new()
	monitor:start({npl_states={"r1"}, update_interval = 200, load_sample_interval=5000, enable_log = true, log_interval = 200, candidate_percentage = 0.8})

	NPL.activate(format("(%s)script/test/TestNPLMonitor.lua", "r1"), {type="start_busy", });
end

-- run test monitor
if(__rts__:GetName() == "main") then
	LuaUnit:run("TestNPLMonitor")
end

NPL.this(function() 
	local msg = msg;
	if(msg.type== "start_busy") then
		LOG.std(nil, "system", "TestNPLMonitor", "busy timer started")
		NPL.activate("script/test/TestNPLMonitor.lua", {type="tick"});
	elseif(msg.type== "tick") then
		ParaEngine.Sleep(0.5);
		NPL.activate("script/test/TestNPLMonitor.lua", {type="tick"});
	end
end);