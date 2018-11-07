--[[
Title: NPL thread handler 
Author: LiXizhi
Date: 2018-3-2
Desc: This is similar to npl_script_handler, except that each request will use a new real NPL thread to process. When request is done, the thread is reused for future requests. 
This threaded model is ideal for applications which must use sync-mode API like MySQL for its data interface. 
We will normally allocate like 40 threads per process to handle incoming requests. The server will pick the next free thread to process.
Because of the threaded nature, nothing is shared between those worker threads, one must implement sql based session instead of using memory objects.  

During dev time, we can force using the main thread for all requests, so that we can debug our code, but in real production servers, 
all requests are processed via one of the worker thread. And it is up to the developer to ensure that a request does not take too long to process. 
-----------------------------------------------
NPL.load("(gl)script/apps/WebServer/npl_thread_handler.lua");
local thread_handler = commonlib.gettable("WebServer.thread_handler");
thread_handler:StartWorkerThreads(max_worker_thread_count);
-----------------------------------------------
]]
NPL.load("(gl)script/ide/System/System.lua");
NPL.load("(gl)script/apps/WebServer/WebServer.lua");
NPL.load("(gl)script/apps/WebServer/npl_http.lua");
NPL.load("(gl)script/apps/WebServer/npl_common_handlers.lua");
local common_handlers = commonlib.gettable("WebServer.common_handlers");
local thread_handler = commonlib.gettable("WebServer.thread_handler");

local filename = "script/apps/WebServer/npl_thread_handler.lua";
thread_handler.worker_states = {};
thread_handler.worker_count = 0;

function thread_handler:SetWorkerThreadCount(max_worker_thread_count)
	self.worker_count = max_worker_thread_count or 0;
end

function thread_handler:GetWorkerThreadCount()
	return self.worker_count;
end

function thread_handler:StartThreadMonitor()
	if(self.monitor) then
		return 
	end
	LOG.std(nil, "system", "WebServer", "WebServer is enabled")
	NPL.load("(gl)script/ide/NPLStatesMonitor.lua");
	self.monitor = self.monitor or commonlib.NPLStatesMonitor:new();
		
	local worker_states_names = {};
	for i, node in ipairs(self.worker_states) do
		worker_states_names[#worker_states_names + 1] = node.name;
	end	
	self.monitor:start({npl_states = worker_states_names, update_interval = 2000, load_sample_interval = 10000,
		enable_log = true, log_interval = 20000,
		candidate_percentage = 0.8,
		});
end

local last_req = 1;
function thread_handler:GetNextFreeThreadName()
	local worker_name;
	if(self.monitor) then
		worker_name = self.monitor:GetNextFreeState(); -- this gives more accurate free stat. 
	else
		last_req = last_req + 1;
		worker_name = self.worker_states[last_req % (self.worker_count) + 1].name;
	end
	return worker_name;
end

-- start all worker states up to max_count
-- this function can be called multiple times even after server is started. 
-- @param npl_queue_size: optional npl queue size for the thread. 
function thread_handler:StartWorkerThreads(max_count, npl_queue_size)
	for i=1, max_count or 0 do 
		local node = self.worker_states[i];
		if(not node) then
			node = {name = "worker"..i};
			self.worker_states[i] = node;
		end
		if(not node.started) then
			node.started = true;
			local worker = NPL.CreateRuntimeState(node.name, 0);
			worker:Start();
			if(npl_queue_size) then
				NPL.activate(format("(%s)script/ide/config/NPLStateConfig.lua", node.name), {type="SetAttribute", attr={MsgQueueSize=npl_queue_size,}});
			end
			NPL.activate(format("(%s)%s", node.name, filename), {type="init"});
		end
	end
	self:SetWorkerThreadCount(max_count or 0);
	LOG.std(nil, "info", "npl_thread_handler", "%d worker threads created", self:GetWorkerThreadCount());
end

-- public: file handler maker. it returns a handler that serves files in the baseDir dir
-- @param params: string or {docroot, }the directory from which to serve files. 
function WebServer.npl_thread_handler(params)
	local self = thread_handler;
	local config = WebServer:GetConfig();
	self:StartWorkerThreads(config.max_worker_thread_count, config.NPLRuntime and config.NPLRuntime.npl_queue_size);
	if(config.use_worker_monitor) then
		self:StartThreadMonitor();
	end

	local docroot="";
	if type(params) == "string" then 
		docroot = params;
	elseif type(params) == "table" then 
		docroot = params.docroot;
	end

	if(self:GetWorkerThreadCount() == 0) then
		-- if this is 0, use the main thread, mostly at dev time.  
		return function(req, res)
			local filename = common_handlers.GetValidNPLFileName(docroot, req.relpath);
			if(filename) then
				req:send(filename);
			end
		end 
	else
		-- use multi-threaded handler
		return function(req, res)
			local filename = common_handlers.GetValidNPLFileName(docroot, req.relpath);
			if(filename) then
				req:send(format("(%s)%s", thread_handler:GetNextFreeThreadName(), filename));
			end
		end 
	end
end

NPL.this(function()
	-- just for loading some default library.
	LOG.std(nil, "info", "npl_thread", "started");
end);