--[[
Title: IO thread
Author(s): LiXizhi, 
Date: 2016/5/11
Desc: This does all the IO works, usually runs in a separate writer thread(default to 'tdb'). 
There can only be one IO thread for TableDatabase. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Database/IOThread.lua");
local IOThread = commonlib.gettable("System.Database.IOThread");
IOThread:GetSingleton()
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
local TableDatabase = commonlib.gettable("System.Database.TableDatabase");

local IOThread = commonlib.inherit(nil, commonlib.gettable("System.Database.IOThread"));
local cbThreadName = "(%s)script/ide/System/Database/IORequest.lua";
local g_threadName = __rts__:GetName();

local g_singleton;

-- 10 seconds
IOThread.monitorPeriod = 10000;
-- true to log everything
IOThread.debug_log = false;

-- from db path to database instance
local databases = {};

function IOThread:ctor()
	-- start a monitor timer
	NPL.load("(gl)script/ide/timer.lua");
	self.mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		self:onTimer(timer);
	end})
	self.mytimer:Change(self.monitorPeriod, self.monitorPeriod);
	LOG.std(nil, "info", "TableDatabase", "IO thread started in NPL thread: %s", g_threadName);
end

-- monitor and close unused databases 
function IOThread:onTimer()
	-- TODO: 
end

function IOThread:GetSingleton()
	if(not g_singleton) then
		g_singleton = IOThread:new();
	end
	return g_singleton;
end

function IOThread:GetCallbackAddress(cb_thread)
	return format(cbThreadName, cb_thread);
end

-- get collection on server(io thread)
function IOThread:GetServerCollection(collectionData)
	if(collectionData and collectionData.name) then
		local db = self:GetDatabase(collectionData.db);
		if(db) then
			return db[collectionData.name];
		end
	end
end

function IOThread:GetReplyAddress(inMsg)
	return format(cbThreadName, inMsg.cb_thread or "main");
end

-- @param inMsg: the request incoming message.
function IOThread:SendResponse(err, data, inMsg)
	NPL.activate(self:GetReplyAddress(inMsg), {err = err, data = data, cb_idx = inMsg.cb_idx});
end

-- open on the server side. 
function IOThread:OpenDatabase(rootFolder)
	db = TableDatabase:new();
	db:SetWriterTheadName(g_threadName); -- this will force server mode for everything.
	db:open(rootFolder);
	return db;
end

function IOThread:GetDatabase(rootFolder)
	rootFolder = rootFolder or "temp/TableDatabase/";
	local db = databases[rootFolder];
	if(not db) then
		db = self:OpenDatabase(rootFolder)
		databases[rootFolder] = db;
	end
	return db;
end

function IOThread:handleConnect(msg)
	if(msg.query) then
		local rootFolder = msg.query.rootFolder;
		if(rootFolder) then
			local db = self:GetDatabase(rootFolder);
			self:SendResponse(db~=nil, nil, msg);
		end
	end
end

-- this is in IO thread now.
function IOThread:HandleRequest(msg)
	if(IOThread.debug_log) then
		LOG.std(nil, "debug", "IOThread received:", msg);
	end
	local query_type = msg.query_type;	
	if(msg.collection) then
		local collection = self:GetServerCollection(msg.collection);
		if(collection) then
			if(query_type == "findOne") then
				collection:findOne(msg.query, function(err, data)
					self:SendResponse(err, data, msg);
				end);
			elseif(query_type == "find") then
				collection:find(msg.query, function(err, data)
					self:SendResponse(err, data, msg);
				end);
			elseif(query_type == "insertOne") then
				collection:insertOne(msg.query, function(err, data)
					self:SendResponse(err, data, msg);
				end);
			elseif(query_type == "updateOne") then
				collection:updateOne(msg.query.query, msg.query.update, function(err, data)
					self:SendResponse(err, data, msg);
				end);
			elseif(query_type == "deleteOne") then
				collection:deleteOne(msg.query, function(err, data)
					self:SendResponse(err, data, msg);
				end);
			elseif(query_type == "makeEmpty") then
				collection:makeEmpty(msg.query, function(err, data)
					self:SendResponse(err, data, msg);
				end);
			elseif(query_type == "flush") then
				collection:flush(msg.query, function(err, data)
					self:SendResponse(err, data, msg);
				end);
			elseif(query_type == "waitflush") then
				collection:waitflush(msg.query, function(err, data)
					self:SendResponse(err, data, msg);
				end);
			elseif(query_type == "exec") then
				collection:exec(msg.query, function(err, data)
					self:SendResponse(err, data, msg);
				end);
			elseif(query_type == "silient") then
				collection:silient(msg.query);
			end
		end
	elseif(query_type == "connect") then
		self:handleConnect(msg);
	end
end

local function activate()
	IOThread:GetSingleton():HandleRequest(msg);
end
NPL.this(activate);