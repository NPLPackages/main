--[[
Title: Async Task
Author(s): LiXizhi@yeah.net
Date: 2023/5/16
Desc: Async task provide an easy API to run small tasks in NPL worker threads.
By default, there are 2 NPL worker threads in total. It will serialize function to string and send to worker threads. 
It will serialize and send function between threads only once per function. 
Code needs to be static because we will cache all past task functions in memory. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Concurrent/AsyncTask.lua");
local AsyncTask = commonlib.gettable("System.Concurrent.AsyncTask");

-- input function should not use any up-values, default timeout is 10000 milliseconds
AsyncTask.RunTask(function(param1, param2)
	echo({"from worker thread", param1, param2})
	return "OK"
end, "param1", "param2"):OnFinish(function(result)
	echo("result is "..result)
end)

local task = AsyncTask.CreateTask(function(param1, param2)
	echo({"from worker thread", param1, param2})
	return "OK"
end, "param1", "param2")
-- force running on a given thread index or name
task:Run("MyThreadName"):OnFinish(function(result)
	echo("result is "..result)
end):OnError(function(errMsg, msgType)
	if(msgType == "timeout") then
		echo("task timed out")
	else
		echo("error: "..errMsg)
	end)
end)

-- we can let the code to run in a given env. This function is executed before each task and returns an environment table.
AsyncTask.RegisterSandBoxEnvFunc("CodeAPI", function()
	if(not _G.CodeAPIEnv) then
		local env = {
			checkyield = function() end,
			echo = function(text) print(tostring(text).."\n------\n") end,
		};
		local meta = {__index = _G};
		setmetatable(env, meta);
		_G.CodeAPIEnv = env;
	end
	return _G.CodeAPIEnv;
end)
task:Run(nil, "CodeAPI")

------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/System.lua");
NPL.load("(gl)script/ide/System/Concurrent/ThreadPool.lua");
local ThreadPool = commonlib.gettable("System.Concurrent.ThreadPool");
local AsyncTask = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Concurrent.AsyncTask"));
AsyncTask:Signal("beforeSetWorkerEnv")
AsyncTask.maxWorkerCount = 2;
-- default time out in 10000 milliseconds
AsyncTask.defaultTimeout = 10000;
-- name to function map, the function should return the sandbox env. if no sandbox env is returned, it will use the default sandbox env.
AsyncTask.sandboxEnvFuncs = {}
local allTasks = {};
local tasksToStr = {};
local next_task_id = 0;
local current_thread_name = __rts__:GetName();

-- provide an empty implementation to translation service. 
if(not L) then
	L = function(text) return text end
end

----------------------------
-- private task class
----------------------------
local Task = commonlib.inherit();

function Task:ctor()
	self.type = "runtask"
	next_task_id = next_task_id + 1;
	self.id = next_task_id
	self.from = current_thread_name;
end

-- @param type_: default to "runtask", other types include "regEnv", "result", "timeout"
function Task:SetType(type_)
	self.type = type_;
end

function Task:SetEnvName(name)
	self.envName = name;
end

-- default to 10000 milliseconds.
function Task:SetTimeout(timeout)
	self.timeout = timeout;
end

function Task:OnFinish(callbackFunc)
	self.OnFinishCallBack = callbackFunc;
	return self;
end

-- @param callbackFunc: function(errMsg, msgType) end, msgType can be "timeout" or "result"
function Task:OnError(callbackFunc)
	self.OnErrorCallBack = callbackFunc;
	return self;
end

-- @param threadIndexOrName: if nil, we will use round robin to return the next worker name in the worker pool.
-- It can also be a string name of the worker thread, which will be created if not exist. If "main", it means the main thread.
-- @param sandboxEnvName: if nil, we will use the default sandbox env. Otherwise, it should be a string name of the sandbox env which is registered by AsyncTask.RegisterSandBoxEnvFunc
function Task:Run(threadIndexOrName, sandboxEnvName)
	local worker = AsyncTask.CreateGetWorker(threadIndexOrName)
	if(worker) then
		self:SetEnvName(sandboxEnvName)
		if(sandboxEnvName and worker:GetSandboxEnvFunc(sandboxEnvName) ~= AsyncTask.GetSandBoxEnvFunc(sandboxEnvName)) then
			-- if sandbox environment has changed, we need to send env update task to this worker thread before running the task.
			local funEnv = AsyncTask.GetSandBoxEnvFunc(sandboxEnvName)
			if(funEnv) then
				AsyncTask:beforeSetWorkerEnv(worker, sandboxEnvName);
				worker:SetSandboxEnvFunc(sandboxEnvName, funEnv)
				local task = AsyncTask.CreateTask(funEnv)
				task:SetType("regEnv");
				task.regEnvName = sandboxEnvName;
				task:Run(worker:GetName()):OnError(function()
					LOG.std(nil, "error", "AsyncTask", "failed to register Sandbox env %s for thread: %s registered", sandboxEnvName, worker:GetName());
				end);
			end
		end
		-- TODO check queue size and reject full queue or timed out request.  worker:GetCurrentMsgQueueSize()
		self.mainFunc = worker:GetFunctionId(self.mainFunc) or self.mainFunc;
		allTasks[self.id] = self;
		NPL.activate(format("(%s)script/ide/System/Concurrent/AsyncTask.lua", worker.name), self)
		self.startTime = commonlib.TimerManager.GetCurrentTime();
		AsyncTask.StartCheckTimeoutTimer();
	end
	return self;
end

function Task:OnFinished(msg)
	allTasks[self.id] = nil;
	if(msg.from) then
		local worker = ThreadPool.CreateWorkerByName(msg.from);
		if(worker and msg.funcId and type(self.mainFunc) == "string") then
			worker:SetFunctionId(self.mainFunc, msg.funcId);
		end
	end
	if(msg.ok) then
		if(self.OnFinishCallBack) then
			self.OnFinishCallBack(msg.result);
		end
	else
		if(self.OnErrorCallBack) then
			self.OnErrorCallBack(msg.result, msg.type);
		else
			if(msg.type ~= "timeout") then
				LOG.std(nil, "error", "AsyncTask", "failed to run task function %s", tostring(msg.result));
			end
		end
	end
end

----------------------------
-- AsyncTask static functions
----------------------------

-- the worker pool size
function AsyncTask.SetMaxWorkerCount(maxWorkerCount)
	ThreadPool.SetMaxWorkerCount(maxWorkerCount)
end

function AsyncTask.GetMaxWorkerCount()
	return ThreadPool.GetMaxWorkerCount()
end

-- @param index: if nil, we will use round robin to return the next worker name in the worker pool
-- it should be a value in range[1, maxWorkerCount]. It can also be a string name of the worker thread, which will be created if not exist.
function AsyncTask.CreateGetWorker(index)
	return ThreadPool.CreateGetWorker(index)
end

function AsyncTask.CreateTask(mainFunction, ...)
	local mainFuncStr = tasksToStr[mainFunction];
	if(not mainFuncStr) then
		mainFuncStr = string.dump(mainFunction);
		tasksToStr[mainFunction] = mainFuncStr;
	end
	local task = Task:new({
		args = {...},
		mainFunc = mainFuncStr,
		filename = debug.getinfo(2, "S").source,
	});
	return task;
end

-- @param mainFunction: function(...) end, ... are the arguments passed to RunTask.
function AsyncTask.RunTask(mainFunction, ...)
	local task = AsyncTask.CreateTask(mainFunction, ...)
	return task:Run();
end

function AsyncTask.StartCheckTimeoutTimer()
	AsyncTask.timer = AsyncTask.timer or commonlib.Timer:new({callbackFunc = function(timer)
		local now = commonlib.TimerManager.GetCurrentTime();
		local timeoutTasks;
		for id, task in pairs(allTasks) do
			if(task.startTime and (now - task.startTime) > (task.timeout or AsyncTask.defaultTimeout) ) then
				LOG.std(nil, "warn", "AsyncTask", "task %s is timed out", tostring(task.id));
				timeoutTasks = timeoutTasks or {}
				timeoutTasks[#timeoutTasks+1] = task;
			end
		end
		if(timeoutTasks) then
			for _, task in ipairs(timeoutTasks) do
				task:OnFinished({ok = false, type = "timeout"});
			end
		end
	end})
	if(not AsyncTask.timer:IsEnabled()) then
		AsyncTask.timer:Change(1000, 1000);
	end
end

-- the default environment is _G plus some frequently used functions. 
function AsyncTask.CreateGetDefaultSandBoxEnv()
	if(not AsyncTask.defaultEnv) then
		local env = {
			checkyield = function() end,
			AsyncTask = AsyncTask,
		};
		local meta = {__index = _G};
		setmetatable(env, meta);
		AsyncTask.defaultEnv = env;
	end
	return AsyncTask.defaultEnv;
end

-- @param name: the name of the sandbox env
-- @param func: function(state) env={}; return env; end, env is the sandbox env table. See AsyncTask.CreateGetDefaultSandBoxEnv() for an example.
-- function's first state parameter can be "unload" or nil. If it is unload, it means that something is calling UnRegisterSandBoxEnvFunc.
-- Please note the function is serialized and sent to worker thread to executed for every task in worker thread when a given env name is requested in a lazy load fashion. 
-- no sandbox environment is registered at the time of running task, the default AsyncTask.CreateGetDefaultSandBoxEnv() is used.
-- This function also gives each task an opportunity to do something before task is executed. 
function AsyncTask.RegisterSandBoxEnvFunc(name, func)
	if(name) then
		AsyncTask.sandboxEnvFuncs[name] = func;
	end
end

-- unregister a given environment from all workers. 
function AsyncTask.UnRegisterSandBoxEnvFunc(name)
	if(name) then
		local envFunc = AsyncTask.GetSandBoxEnvFunc(name);
		if(envFunc) then
			AsyncTask.sandboxEnvFuncs[name] = nil;
			if(NPL.IsMainThread()) then
				for _, worker in ThreadPool.AllWorkerPairs() do
					if(worker:GetSandboxEnvFunc(name)) then
						worker:SetSandboxEnvFunc(name, nil)
						if(worker:GetName() ~= "main") then
							-- send a task to remove from this worker
							local task = AsyncTask.CreateTask(function(name)
								local AsyncTask = commonlib.gettable("System.Concurrent.AsyncTask");
								AsyncTask.UnRegisterSandBoxEnvFunc(name);
							end, name)
							task:Run(worker:GetName()):OnError(function()
								LOG.std(nil, "error", "AsyncTask", "failed to unregister Sandbox env %s for thread: %s registered", name, worker:GetName());
							end);
						end
					end
				end
			else
				-- remove locally 
				envFunc("unload")
				LOG.std(nil, "info", "AsyncTask", "Unregistered sandbox env %s for thread: %s", name, current_thread_name);
			end
		end
	end
end

function AsyncTask.GetSandBoxEnvFunc(name)
	return name and AsyncTask.sandboxEnvFuncs[name];
end

local idToFunctions = {}
local FunctionStrToIds = {}
local nextFuncId = 0;
local dummyFunc = function() end

-- private function: 
function AsyncTask.GetMainFunction(msg)
	local mainFunc, funcId;
	if(type(msg.mainFunc) == "number") then
		funcId = msg.mainFunc
		mainFunc = idToFunctions[funcId]
	elseif(type(msg.mainFunc) == "string") then
		local mainFuncStr = msg.mainFunc
		funcId = FunctionStrToIds[mainFuncStr]
		if(funcId) then
			mainFunc = idToFunctions[funcId]
		elseif(not mainFunc) then
			nextFuncId = nextFuncId + 1;
			funcId = nextFuncId
			FunctionStrToIds[mainFuncStr] = funcId;
			local errMsg;
			mainFunc, errmsg = loadstring(mainFuncStr, msg.filename);
			if(not mainFunc) then
				mainFunc = dummyFunc;
				LOG.std(nil, "error", "AsyncTask", "failed to load task function %s", errmsg);
			else
				LOG.std(nil, "debug", "AsyncTask", "a new task function with %d is registered in thread %s", funcId, current_thread_name);
			end
			idToFunctions[funcId] = mainFunc;
		end
	end
	return mainFunc, funcId;
end

function AsyncTask.handleTaskMsg(msg)
	local mainFunc, funcId = AsyncTask.GetMainFunction(msg)
	local ok, result
	if(mainFunc) then
		local envFunc = AsyncTask.GetSandBoxEnvFunc(msg.envName) or AsyncTask.CreateGetDefaultSandBoxEnv
		if(envFunc) then
			setfenv(mainFunc, envFunc())
		end
		ok, result = pcall(mainFunc, unpack(msg.args))
	end
	NPL.activate(format("(%s)script/ide/System/Concurrent/AsyncTask.lua", msg.from), {type="result", ok=ok, result = result, id = msg.id, funcId = funcId, from = current_thread_name})
end

function AsyncTask.handleResultMsg(msg)
	local task = allTasks[msg.id]
	if(task) then
		task:OnFinished(msg)
	end
end

function AsyncTask.handleRegisterEnvMsg(msg)
	local mainFunc, funcId = AsyncTask.GetMainFunction(msg)
	if(mainFunc) then
		setfenv(mainFunc, AsyncTask.CreateGetDefaultSandBoxEnv())
		AsyncTask.RegisterSandBoxEnvFunc(msg.regEnvName, mainFunc)
		NPL.activate(format("(%s)script/ide/System/Concurrent/AsyncTask.lua", msg.from), {type="result", ok=true, result = "registered", id = msg.id, funcId = funcId, from = current_thread_name})
		LOG.std(nil, "info", "AsyncTask", "thread env registered (%s)%s", current_thread_name, msg.regEnvName);
	end
end

AsyncTask:InitSingleton();

NPL.this(function()
	local msg = msg;
	if(msg.type=="runtask") then
		AsyncTask.handleTaskMsg(msg)
	elseif(msg.type=="result") then
		AsyncTask.handleResultMsg(msg)
	elseif(msg.type=="regEnv") then
		AsyncTask.handleRegisterEnvMsg(msg)
	end
end, {MsgQueueSize=500});