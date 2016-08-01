--[[
Title: IO request
Author(s): LiXizhi, 
Date: 2016/5/11
Desc: send request to IO thread
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Database/IORequest.lua");
local IORequest = commonlib.gettable("System.Database.IORequest");
------------------------------------------------------------
]]
local IORequest = commonlib.gettable("System.Database.IORequest");
local ioThreadName = "(%s)script/ide/System/Database/IOThread.lua";
local g_threadName = __rts__:GetName();

local callbackQueue = {};

-- if callbackFunc is not provided, we will use sync mode. By default, sync mode is disabled.
IORequest.EnableSyncMode = false;
-- if IO thread's message queue is full, the sender is also paused. This only happens when database is really busy. 
-- setting to false will simply drop the message and return "queue_full" error.
IORequest.WaitOnBusyDB = true;
-- how many seconds to wait on busy database, before we send "queue_full" error. This parameter only takes effect when self.WaitOnBusyDB is true.
IORequest.MaxWaitSeconds = 5;
-- default time out for a given request. default to 5 seconds
IORequest.DefaultTimeout = 5000;
-- internal timer period
IORequest.monitorPeriod = 5000;
-- true to log everything.
IORequest.debug_log = false;

function IORequest:OneTimeInit()
	if(self.inited) then
		return;
	end
	self.inited = true;
	NPL.load("(gl)script/ide/timer.lua");
	self.mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		self:CheckTimedOutRequests();
	end})
	self.mytimer:Change(self.monitorPeriod, self.monitorPeriod);
end

-- remove any timed out request.
function IORequest:CheckTimedOutRequests()
	local curTime = ParaGlobal.timeGetTime();
	local timeout_pool;
	for i, cb in pairs(callbackQueue) do
		if((curTime - cb.startTime) > (cb.timeout or self.DefaultTimeout) ) then
			timeout_pool = timeout_pool or {};
			timeout_pool[i] = cb;
		end
	end
	if(timeout_pool) then
		for i, cb in pairs(timeout_pool) do
			callbackQueue[i] = nil;
			if(cb.callbackFunc) then
				cb.callbackFunc("timeout", nil);
			end
		end
	end
end

local next_id = 0;
function getNextId()
	next_id = next_id + 1;
	return next_id;
end
-- get next callback pool index. may return nil if max queue size is reached. 
-- @return index or nil
function IORequest:PushCallback(callbackFunc, timeout)
	if(not callbackFunc) then
		return -1;
	end
	local index = getNextId();
	callbackQueue[index] = {callbackFunc = callbackFunc, startTime = ParaGlobal.timeGetTime(), timeout=timeout};
	return index;
end

function IORequest:PopCallback(index)
	if(index) then
		local cb = callbackQueue[index];
		if(cb) then
			callbackQueue[index] = nil;
			return cb;
		end
	end
end

-- return err, data.
function IORequest:WaitForSyncModeReply(timeout)
	timeout = timeout or self.DefaultTimeout;
	local thread = __rts__;
	local reply_msg;
	local startTime = ParaGlobal.timeGetTime();
	while (not reply_msg) do
		local nSize = thread:GetCurrentQueueSize();
		for i=0, nSize-1 do
			local msg = thread:PeekMessage(i, {filename=true});
			if(msg.filename == "script/ide/System/Database/IORequest.lua") then
				local msg = thread:PopMessageAt(i, {filename=true, msg=true});
				local out_msg = msg.msg;
				if(out_msg.cb_idx == -1) then
					reply_msg = out_msg;
					break;
				end
			end
		end
		if( (ParaGlobal.timeGetTime() - startTime) > timeout) then
			LOG.std(nil, "warn", "IORequest", "timed out");
			return "timeout", nil;
		end
		if(reply_msg == nil) then
			if(ParaEngine.GetAttributeObject():GetField("HasClosingRequest", false) == true) then
				return "app_exit", nil;
			end
			if(thread:GetCurrentQueueSize() == nSize) then
				thread:WaitForMessage(nSize);
			end
		end
	end
	if(reply_msg) then
		return reply_msg.err, reply_msg.data;
	end
end

-- @param query_method: the query method: can be "findOne", "find", "deleteOne", "updateOne", "insertOne", "connect","removeIndex"
-- @param collection: the source collection object or tabledatabase object.
-- @param query: the query object
-- @param callbackFunc: function(err, ...)  end, if nil it will go in sync mode
-- @param timeout: if nil, default to 5 seconds
-- @return if callbackFunc is nil, this function blocks and return the result.
function IORequest:Send(query_type, collection, query, callbackFunc, timeout)
	self:OneTimeInit();
	local index = self:PushCallback(callbackFunc);
	if(index) then
		local msg = {
			query_type = query_type, 
			collection = collection:ToData(),
			query = query, 
			cb_idx = index, cb_thread = g_threadName, 
		};
		local address = self:GetWriterAddress(collection);
		if(NPL.activate(address, msg) ~= 0) then
			-- in case of error
			if(callbackFunc) then
				if(not self.WaitOnBusyDB or NPL.activate_with_timeout(self.MaxWaitSeconds, address, msg)~=0) then
					self:HandleResponse({cb_idx = index, err="queue_full", data = nil});
				end
			else
				return "queue_full", nil;
			end
		end;
	end

	if(not callbackFunc and IORequest.EnableSyncMode) then
		return self:WaitForSyncModeReply();
	end
end

local io_writers = {};
function IORequest:WaitupWriter(writerName)
	writerName = writerName or "main";
	if(not io_writers[writerName]) then
		io_writers[writerName] = true;
		if(writerName~="main" and writerName~="") then
			-- try create and start the writer thread if not yet
			NPL.CreateRuntimeState(writerName, 0):Start();
		end
	end
end

function IORequest:GetWriterAddress(collection)
	local writerName = collection:GetWriterThreadName();
	self:WaitupWriter(writerName);
	return format(ioThreadName, writerName);
end

-- this is reply in requester's thread.
function IORequest:HandleResponse(msg)
	if(IORequest.debug_log) then
		LOG.std(nil, "debug", "IORequest received:", msg);
	end
	local cb = self:PopCallback(msg.cb_idx);
	if(cb and cb.callbackFunc) then
		cb.callbackFunc(msg.err, msg.data);
	end
end

local function activate()
	IORequest:HandleResponse(msg);
end
NPL.this(activate);