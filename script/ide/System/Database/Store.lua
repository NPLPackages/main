--[[
Title: base class for store
Author(s): LiXizhi, 
Date: 2016/5/11
Desc: Derived class should implement at least following functions for the database store provider.
virtual functions:
	findOne
	find
	deleteOne
	updateOne
	insertOne
	removeIndex

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Database/Store.lua");
local Store = commonlib.gettable("System.Database.Store");
------------------------------------------------------------
]]
local Store = commonlib.inherit(nil, commonlib.gettable("System.Database.Store"));

-- whether to use lazy writing, when lazy writing is enabled, we will not commit to database immediately, but will batch many commit in a single Flush. 
-- it will increase the speed by 100 times, if we have many mini transactions to deal with. It is highly recommended to turn this on. 
Store.EnableLazyWriting = true;
-- increase db speed by 30% but OS crashes may corrupt the db. Flush journal files to disk without waiting for OS API to return.
Store.IgnoreOSCrash = false;
-- increase db speed by 30% but App crashes may corrupt the db. Use in-memory journal files.
Store.IgnoreAppCrash = false;
-- cache size per database table, default to 2000KB. Positive value means page size, negative is KB
Store.CacheSize = -2000;

-- how many logs to write to log.txt. default to 0, which output the least logs.
Store.LogLevel = 0;
-- We will wait for this many milliseconds when meeting the first non-queued command before commiting to disk. So if there are many commits in quick succession, it will not be IO bound. 
Store.AutoFlushInterval = 50;
Store.AutoCheckPointInterval = 5000;
function Store:ctor()
	self.stats = {
		select = 0,
		update = 0,
		insert = 0,
		delete = 0,
	};
end

function Store:init(collection)
	self.collection = collection;
	return self;
end

-- called when a single command is finished. 
function Store:CommandTick(commandname)
	if(commandname) then
		self:AddStat(commandname, 1);
	end
end

function Store:GetCollection()
	return self.collection;
end

function Store:GetStats()
	return self.stats;
end

-- add statistics for a given name
-- @param name: such as "select", "update", "insert", "delete"
-- @param count: if nil it is 1.
function Store:AddStat(name, count)
	name = name or "unknown";
	local stats = self:GetStats();
	stats[name] = (stats[name] or 0) + (count or 1);
end

-- get current count for a given stats name
-- @param name: such as "select", "update", "insert", "delete"
function Store:GetStat(name)
	name = name or "unknown";
	local stats = self:GetStats();
	return (stats[name] or 0);
end

function Store:InvokeCallback(callbackFunc, err, data)
	if(callbackFunc) then
		callbackFunc(err, data);
	else
		return data;
	end
end

-- virtual: 
-- please note, index will be automatically created for query field if not exist.
--@param query: key, value pair table, such as {name="abc"}
--@param callbackFunc: function(err, row) end, where row._id is the internal row id.
function Store:findOne(query, callbackFunc)
end

-- virtual: 
-- find will not automatically create index on query fields. 
-- Use findOne for fast index-based search. This function simply does a raw search, if no index is found on query string.
-- @param query: key, value pair table, such as {name="abc"}. if nil or {}, it will return all the rows
-- @param callbackFunc: function(err, rows) end, where rows is array of rows found
function Store:find(query, callbackFunc)
end

-- virtual: 
-- @param query: key, value pair table, such as {name="abc"}. 
function Store:deleteOne(query, callbackFunc)
end

-- virtual: 
-- this function will assume query contains at least one valid index key. 
-- it will not auto create index if key does not exist.
-- @param query: key, value pair table, such as {name="abc"}. 
-- @param update: additional fields to be merged with existing data; this can also be callbackFunc
function Store:updateOne(query, update, callbackFunc)
end

-- virtual: 
-- if there is already one ore more records with query, this function falls back to updateOne().
-- otherwise it will insert and return full data with internal row _id.
-- @param query: nil or query fields. if it contains query fields, it will first do a findOne(), 
-- if there is record, this function actually falls back to updateOne. 
function Store:insertOne(query, update, callbackFunc)
end

-- virtual: 
-- counting the number of rows in a query. this will always do a table scan using an index. 
-- avoiding calling this function for big table. 
-- @param callbackFunc: function(err, count) end
function Store:count(query, callbackFunc)
end

-- virtual: 
-- normally one does not need to call this function.
-- the store should flush at fixed interval.
-- @param callbackFunc: function(err, fFlushed) end
function Store:flush(query, callbackFunc)
end

-- virtual:
-- @param query: {"indexName"}
-- @param callbackFunc: function(err, bRemoved) end
function Store:removeIndex(query, callbackFunc)
end


-- virtual:
-- after issuing an really important group of commands, and you want to ensure that 
-- these commands are actually successful like a transaction, the client can issue a waitflush 
-- command to check if the previous commands are successful. Please note that waitflush command 
-- may take up to 3 seconds or Store.AutoFlushInterval to return. 
-- @param callbackFunc: function(err, fFlushed) end
function Store:waitflush(query, callbackFunc, timeout)
	
end

-- virtual:
-- this is usually used for changing database settings, such as cache size and sync mode. 
-- this function is specific to store implementation. 
-- @param query: string or {sql=string, CacheSize=number, IgnoreOSCrash=bool, IgnoreAppCrash=bool} 
function Store:exec(query, callbackFunc)
end

-- virtual:
-- this function never reply. the client will always timeout
function Store:silient(query)
end

-- virtual: 
function Store:makeEmpty(query, callbackFunc)
	self:removeIndex({}, function(err, bRemoved)
		self:find({}, function(err, rows)
			local count = 0;
			if(rows) then
				for _, row in ipairs(rows) do
					self:deleteOne(row, function() 
						count = count + 1;
					end)
				end
			end
			self:flush({}, function(err, bFlushed)
				if(not bFlushed) then
					LOG.std(nil, "warn", "makeEmpty", "failed to flush");
				end
				if(callbackFunc) then
					callbackFunc(nil, count);
				end
			end)
		end)
	end);
end
