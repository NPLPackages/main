--[[
Title: Thread Pool
Author(s): LiXizhi@yeah.net
Date: 2023/5/18
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Concurrent/ThreadPool.lua");
local ThreadPool = commonlib.gettable("System.Concurrent.ThreadPool");
local worker = ThreadPool.CreateGetWorker();

ThreadPool.SetMaxWorkerCount(2)

ThreadPool.CreateWorkerByName(name)

for _, worker in ThreadPool.AllWorkerPairs() do
end
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Concurrent/ThreadWorker.lua");
local ThreadWorker = commonlib.gettable("System.Concurrent.ThreadWorker");
local ThreadPool = commonlib.gettable("System.Concurrent.ThreadPool");
ThreadPool.maxWorkerCount = 2;

local next_worker_index = 1;
-- index to worker info Worker table {name, }
local workers = {};
-- name to worker table
local nameToWorkers = {};

-- the worker pool size, default to 2
function ThreadPool.SetMaxWorkerCount(maxWorkerCount)
	ThreadPool.maxWorkerCount = maxWorkerCount;
end

function ThreadPool.GetMaxWorkerCount()
	return ThreadPool.maxWorkerCount
end

function ThreadPool.CreateWorkerByName(name)
	return nameToWorkers[name];
end

-- return iterator for all name to worker pair
function ThreadPool.AllWorkerPairs()
	return pairs(nameToWorkers);
end

-- @param index: if nil, we will use round robin to return the next worker name in the worker pool
-- it should be a value in range[1, maxWorkerCount]. It can also be a string name of the worker thread, which will be created if not exist.
function ThreadPool.CreateGetWorker(index)
    local worker, name;
	if(type(index) == "string") then
		name = index;
		worker = nameToWorkers[name]
	else
		if(not index) then
			next_worker_index = (next_worker_index % ThreadPool.maxWorkerCount) + 1
			index = next_worker_index;
		end
		worker = workers[index]
		if(not worker) then
			name = "worker"..index;
		end
	end
	if(not worker) then
		worker = ThreadWorker:new():Init(name);
		workers[index] = worker;
		nameToWorkers[name] = worker;
		if(name ~= "main") then
			NPL.CreateRuntimeState(name, 0):Start();
		end
	end
	return worker;
end
