--[[
Title: remote procedure call
Author(s): LiXizhi@yeah.net
Date: 2017/2/8
Desc: Create RPC in current NPL thread. Internally it will use an existing or a virtual NPL activation file that can be invoked from any thread.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Concurrent/rpc.lua");
local rpc = commonlib.gettable("System.Concurrent.Async.rpc");
-- the third parameter is usually a file that contains the rpc init code (debug.getinfo(1, "S").source will do that)
-- you can also explicitly specify a shared central API file where all 
-- RPC functions in your application are defined, such as "XXX_API.lua"
rpc:new():init("Test.testRPC", function(self, msg) 
	LOG.std(nil, "info", "Test.testRPC", msg);
	msg.output=true; 
	return msg; 
end, debug.getinfo(1, "S").source)

-- if the third parameter is nil, the filename where init() function is called is used as activation file.
rpc:new():init("Test.testRPC2", function(self, msg) 
	LOG.std(nil, "info", "Test.testRPC2", msg);
	msg.output=true; 
	ParaEngine.Sleep(1);
	return msg; 
end)

Test.testRPC:MakePublic();

-- now we can invoke it anywhere in any thread or remote address.
Test.testRPC("", {"input"}, function(err, msg) 
	assert(msg.output == true and msg[1] == "input")
	echo(msg);
end);

-- This will time out in 500ms because of ParaEngine.Sleep(1)
Test.testRPC2("(worker1)", {"input"}, function(err, msg) 
	assert(err == "timeout" and msg==nil)
	echo(err);
end, 500);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/System.lua");
local rpc = commonlib.gettable("System.Concurrent.Async.rpc");

local rpc_instances = {};

function rpc:new(o)
	o = o or {};
	o.run_callbacks = {};
	o.next_run_id = 0;
	o.thread_name = format("(%s)", __rts__:GetName());
	setmetatable(o, rpc);
	return o;
end

-- @param funcName: global function name, such as "API.Auth"
-- @param handle_request_func: rpc handler function of function(self, msg)  end
-- @param publicFileName: the activation file, if nil, it defaults filename where the function is defined. 
-- usually this file should call rpc:init() when it is loaded. 
function rpc:init(funcName, handle_request_func, publicFileName)
	self:SetFuncName(funcName);
	self.handle_request = handle_request_func or echo;
	self:SetPublicFile(publicFileName or debug.getinfo(2, "S").source);
	return self;
end

-- @param funcName: global function name, such as "API.Auth"
function rpc:SetFuncName(funcName)
	self.fullname = funcName;
	self.filename = format("rpc/%s.lua", self.fullname);
	if(commonlib.getfield(funcName)) then
		LOG.std(nil, "warn", "rpc", "%s is overwritten", funcName);
	end
	commonlib.setfield(funcName, self);

	rpc.AddInstance(funcName, self);
end

-- The public filename is 
-- @param filename: the activation file, if nil, it defaults to rpc/[funcName].lua
function rpc:SetPublicFile(filename)
	filename = filename or format("rpc/%s.lua", self.fullname);
	self.filename = filename;

	NPL.this(function() 
		self:OnActivated(msg);
	end, {filename = self.filename});

	LOG.std(nil, "debug", "rpc", "%s installed to file %s", self.fullname, self.filename);
end

function rpc:__tostring()
	return format("%s: (rpc defined in %s)", self.fullname or "", self.filename or "");
end

-- static
function rpc.AddInstance(name, o)
	if(name)then
		rpc_instances[name] = o;
	end
end

-- static
function rpc.GetInstance(name)
	return rpc_instances[name or ""];
end

-- private: whenever a message arrives
function rpc:OnActivated(msg)
	if(msg.name) then
		local rpc_ = rpc.GetInstance(msg.name);
		if(type(rpc_) == "table" and rpc_.OnActivated) then
			msg.name = nil;
			return rpc_:OnActivated(msg);
		end
	end
	if(msg.type=="run") then
		local result = self:handle_request(msg.msg);
		NPL.activate(format("%s%s", msg.callbackThread, self.filename), {
			type="result", 
			name=self.fullname, 
			result = result, 
			err=nil, callbackId = msg.callbackId
		});
	elseif(msg.type== "result" and msg.callbackId) then
		self:InvokeCallback(msg.callbackId, msg.err, msg.result);
	end
end

-- private invoke callback and remove from queue, 
function rpc:InvokeCallback(callbackId, err, msg)
	local callback = self.run_callbacks[callbackId];
	if(callback) then
		if(callback.timer) then
			callback.timer:Change();
		end
		self.run_callbacks[callbackId] = nil;
		if(type(callback.callbackFunc) == "function") then
			callback.callbackFunc(err, msg);
		end
	end
end

-- smallest short value to avoid conflicts with manual id. 
local min_short_value = 100000;

-- by default, rpc can only be called from threads in the current process. 
-- in order to expose the API via NPL tcp protocol, one needs to call this function. 
function rpc:MakePublic()
	NPL.load("(gl)script/ide/System/Encoding/crc32.lua");
	local Encoding = commonlib.gettable("System.Encoding");
	local shortValue = Encoding.crc32(self.filename);
	if(shortValue < min_short_value) then
		shortValue = shortValue + min_short_value;
	end
	NPL.AddPublicFile(self.filename, shortValue);
end

-- @param address: if nil, it is current NPL thread. it can be thread name like "(worker1)"
-- if NPL thread worker1 is not created, it will be automatically created. 
-- Because NPL thread is reused, it is good practice to use only limited number of NPL threads per process.
-- for complete format, please see NPL.activate function. 
-- @param msg: any table object
-- @param callbackFunc: result from the rpc, function(err, msg) end
-- @param timeout:  time out in milliseconds. if nil, there is no timeout
-- if timed out callbackFunc("timeout", nil) is invoked on timeout
function rpc:activate(address, msg, callbackFunc, timeout)
	if(type(address) == "string") then
		local thread_name = address:match("^%((.+)%)$");
		if (thread_name) then
			self.workers = self.workers or {};
			if(not self.workers[address]) then
				self.workers[address] = true;
				NPL.CreateRuntimeState(thread_name, 0):Start();
			end
		end
	end
	
	local callbackId = self.next_run_id + 1;
	self.next_run_id = callbackId
	local callback = {
		callbackFunc = callbackFunc,
		timeout = timeout,
	};
	self.run_callbacks[callbackId] = callback;
	if(timeout and timeout>0) then
		callback.timer = callback.timer or commonlib.Timer:new({callbackFunc = function(timer)
			self:InvokeCallback(callbackId, "timeout", nil);
		end});
		callback.timer:Change(timeout, nil)
	end
	return NPL.activate(format("%s%s", address or "", self.filename), {
		type="run", 
		msg = msg, 
		name = self.fullname,
		callbackId = self.next_run_id, 
		callbackThread=self.thread_name,
	});
end

rpc.__call = rpc.activate;
rpc.__index = rpc;
