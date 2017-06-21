--[[
Title: Collection
Author(s): LiXizhi, 
Date: 2016/5/11
Desc: Collection is like a sql table in standard database.
A database contains many collections.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Database/Collection.lua");
local Collection = commonlib.gettable("System.Database.Collection");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Database/Item.lua");
NPL.load("(gl)script/ide/System/Database/StorageProvider.lua");
NPL.load("(gl)script/ide/System/Database/IORequest.lua");
NPL.load("(gl)script/ide/System/Database/Store.lua");
local Store = commonlib.gettable("System.Database.Store");
local IORequest = commonlib.gettable("System.Database.IORequest");
local StorageProvider = commonlib.gettable("System.Database.StorageProvider");
local Item = commonlib.gettable("System.Database.Item");
local type = type;

local Collection = commonlib.gettable("System.Database.Collection");
Collection.__index = Collection;

function Collection:new_collection(o)
	o = o or {};
	setmetatable(o, self);
	return o;
end

-- create a new object
function Collection:new(data)
	return Item:new():init(self, data);
end

-- @param parent: the parent table database
function Collection:init(name, parent)
	self.name = name or "default";
	self.parent = parent;
	self.isServer = parent:IsServer();
	self.writerThread = parent.writerThread;
	if(self:IsServer()) then
		self.storageProvider = StorageProvider:CreateStorage(self);
	end
	return self;
end

function Collection:ToData()
	if(not self.data) then
		self.data = {name=self.name, db=self.parent:GetRootFolder()};
	end
	return self.data;
end

function Collection:GetParent()
	return self.parent;
end

function Collection:GetName()
	return self.name;
end

function Collection:GetProviderName()
	return self.parent:FindProvider(self.name);
end


-- whether this is a server thread
function Collection:IsServer()
	return self.isServer;
end

function Collection:GetWriterThreadName()
	return self.writerThread or "main";
end

-- find by internal id.
function Collection:findById(id, callbackFunc, timeout)
	return self:findOne({_id = id}, callbackFunc, timeout);
end

-- Similar to `find` except that it just return one row.
-- Find will automatically create index on query fields. 
-- To force not-using index on query field, please use array table. e.g. 
-- query = {name="a", {"email", "a@abc.com"}}, field `name` is indexed, whereas "email" is NOT. 
-- @param query: key, value pair table, such as {name="abc"}. if nil or {}, it will return all the rows
-- it may also contain array items which means non-indexed query fields, which is used to filter the result after
-- fetching other queried fields. 
--@param callbackFunc: function(err, row) end, where row._id is the internal row id.
function Collection:findOne(query, callbackFunc, timeout)
	if(self:IsServer()) then
		return self.storageProvider:findOne(query, callbackFunc);
	else
		return IORequest:Send("findOne", self, query, callbackFunc, timeout);
	end
end

-- Find will automatically create index on query fields. 
-- To force not-using index on query fields, please use array table. e.g. 
-- query = {name="a", {"email", "a@abc.com"}}, field `name` is indexed, whereas "email" is NOT. 
-- @param query: key, value pair table, such as {name="abc"}. if nil or {}, it will return all the rows
-- it may also contain array items which means non-indexed query fields, which is used to filter the result after
-- fetching other queried fields. 
-- @param callbackFunc: function(err, rows) end, where rows is array of rows found
function Collection:find(query, callbackFunc, timeout)
	if(self:IsServer()) then
		return self.storageProvider:find(query, callbackFunc);
	else
		return IORequest:Send("find", self, query, callbackFunc, timeout);
	end
end

-- @param query: key, value pair table, such as {name="abc"}. 
function Collection:deleteOne(query, callbackFunc, timeout)
	if(self:IsServer()) then
		return self.storageProvider:deleteOne(query, callbackFunc);
	else
		return IORequest:Send("deleteOne", self, query, callbackFunc, timeout);
	end
end

-- this function will assume query contains at least one valid index key. 
-- it will not auto create index if key does not exist.
-- @param query: key, value pair table, such as {name="abc", _unset={"fieldname_to_remove", "another_name"}}. 
--  _unset may contain array or map of field names to remove. 
-- @param update: additional fields to be merged with existing data; this can also be callbackFunc
function Collection:updateOne(query, update, callbackFunc, timeout)
	if(type(update) == "function") then
		callbackFunc = update;
		update = nil;
	end
	if(self:IsServer()) then
		return self.storageProvider:updateOne(query, update, callbackFunc);
	else
		return IORequest:Send("updateOne", self, {query = query, update = update}, callbackFunc, timeout);
	end
end

function Collection:update(query, update, callbackFunc, timeout)
	if(type(update) == "function") then
		callbackFunc = update;
		update = nil;
	end
	if(self:IsServer()) then
		return self.storageProvider:update(query, update, callbackFunc);
	else
		return IORequest:Send("update", self, {query = query, update = update}, callbackFunc, timeout);
	end
end

-- Replaces a single document within the collection based on the query filter.
-- it will not auto create index if key does not exist.
-- @param query: key, value pair table, such as {name="abc"}. 
-- @param replacement: wholistic fields to be replace any existing doc. 
function Collection:replaceOne(query, replacement, callbackFunc, timeout)
	if(self:IsServer()) then
		return self.storageProvider:replaceOne(query, replacement, callbackFunc);
	else
		return IORequest:Send("replaceOne", self, {query = query, replacement = replacement}, callbackFunc, timeout);
	end
end

-- if there is already one ore more records with query, this function falls back to updateOne().
-- otherwise it will insert and return full data with internal row _id.
-- @param query: nil or query fields. if nil, it will insert a new record regardless of key uniqueness check. 
-- if it contains query fields, it will first do a findOne() first, and turns into updateOne if a row is found. 
-- please note, index-fields are created for queried fields just like in `find` command. 
-- @param update: the actuall fields
function Collection:insertOne(query, update, callbackFunc, timeout)
	if(type(update) == "function") then
		callbackFunc = update;
		update = query;
		query = nil;
	end
	if(self:IsServer()) then
		return self.storageProvider:insertOne(query, update, callbackFunc);
	else
		return IORequest:Send("insertOne", self, {query = query, update = update}, callbackFunc, timeout);
	end
end

-- remove one or more or all index
-- @param query: array of keys {keyname, ...}
function Collection:removeIndex(query, callbackFunc, timeout)
	if(self:IsServer()) then
		return self.storageProvider:removeIndex(query, callbackFunc);
	else
		return IORequest:Send("removeIndex", self, query, callbackFunc, timeout);
	end
end

-- normally one does not need to call this function.
-- the store should flush at fixed interval.
-- @param callbackFunc: function(err, fFlushed) end
function Collection:flush(query, callbackFunc, timeout)
	if(self:IsServer()) then
		return self.storageProvider:flush(query, callbackFunc);
	else
		return IORequest:Send("flush", self, query, callbackFunc, timeout);
	end
end

-- after issuing an really important group of commands, and you want to ensure that 
-- these commands are actually successful like a transaction, the client can issue a waitflush 
-- command to check if the previous commands are successful. Please note that waitflush command 
-- may take up to 3 seconds or Store.AutoFlushInterval to return. 
-- @param callbackFunc: function(err, fFlushed) end
function Collection:waitflush(query, callbackFunc, timeout)
	if(self:IsServer()) then
		return self.storageProvider:waitflush(query, callbackFunc);
	else
		timeout = timeout or (Store.AutoFlushInterval + 3000);
		return IORequest:Send("waitflush", self, query, callbackFunc, timeout);
	end
end

-- danger: call this function will remove everything, including indices
-- @param callbackFunc: function(err, rowDeletedCount)  end
function Collection:makeEmpty(query, callbackFunc, timeout)
	if(self:IsServer()) then
		return self.storageProvider:makeEmpty(query, callbackFunc);
	else
		return IORequest:Send("makeEmpty", self, query, callbackFunc, timeout);
	end
end

-- this is usually used for changing database settings, such as cache size and sync mode. 
-- this function is specific to store implementation. 
-- @param query: string or {sql=string, CacheSize=number, IgnoreOSCrash=bool, IgnoreAppCrash=bool, QueueSize=number, SyncMode=boolean} 
-- query.QueueSize: set the message queue size for both the calling thread and db processor thread. 
-- query.SyncMode: default to false. if true, table api is will pause until data arrives.
-- @param callbackFunc: function(err, data)  end
function Collection:exec(query, callbackFunc, timeout)
	if(self:IsServer()) then
		return self.storageProvider:exec(query, callbackFunc);
	else
		if(type(query) == "table") then
			-- also make the caller's message queue size twice as big at least
			if(query.QueueSize) then
				local value = query.QueueSize*2;
				if(__rts__:GetMsgQueueSize() < value) then
					__rts__:SetMsgQueueSize(value);
					LOG.std(nil, "system", "NPL", "NPL input queue size of thread (%s) is changed to %d", __rts__:GetName(), value);
				end
			end
			if(query.SyncMode~=nil) then
				IORequest.EnableSyncMode = query.SyncMode;
				LOG.std(nil, "system", "TableDatabase", "sync mode api is %s in thread %s", query.SyncMode and "enabled" or "disabled", __rts__:GetName());
			end
		end
		return IORequest:Send("exec", self, query, callbackFunc, timeout);
	end
end

-- calling this function will always timeout, since the server will not reply 
function Collection:silient(query, callbackFunc, timeout)
	if(self:IsServer()) then
		return self.storageProvider:silient(query, callbackFunc);
	else
		return IORequest:Send("silient", self, query, callbackFunc, timeout);
	end
end

-- calling this function will always timeout, since the server will not reply 
function Collection:count(query, callbackFunc, timeout)
	if(self:IsServer()) then
		return self.storageProvider:count(query, callbackFunc);
	else
		return IORequest:Send("count", self, query, callbackFunc, timeout);
	end
end

-- calling this function will always timeout, since the server will not reply 
function Collection:delete(query, callbackFunc, timeout)
	if(self:IsServer()) then
		return self.storageProvider:delete(query, callbackFunc);
	else
		return IORequest:Send("delete", self, query, callbackFunc, timeout);
	end
end
