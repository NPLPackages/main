--[[
Title: Table database
Author(s): LiXizhi, 
Date: 2016/5/11
Desc: 
## Introduction to Table Database
A schema-less, server-less, NoSQL database able to process big data in multiple NPL threads, with extremly intuitive table-like API, 
automatic indexing and extremly fast searching, keeping data and algorithm in one system *just like how the human brain works*.

## Performance
Following is tested on my Intel-i7-3GHZ CPU. See `test` folder for details.

### Run With Conservative Mode
Averaged value from 10000 operations in each test:

* Random inserts: 6329 query/s
   * i.e. start next operation immediately, without waiting for the first one to return.
* Random select with auto-index: 7000 query/s
   * i.e. same as above, but with findOne operation. 
* Randomly mixing CRUD operations: 7518 query/s
   * i.e. same as above, but randomly calling Create/Read/Update/Delete (CRUD) on the same auto-indexed table.
* Round trip latency: 11ms or 85 query/s
   * i.e. Round strip means start next operation after previous one is returned. This is latency test.

### Run With Aggressive Mode
One can also use in-memory journal file or ignore OS disk write feedback to further increase DB throughput by 30-100% percent.
See `Store.lua` for details. By default, this feature is off.

Code Examples:
```lua
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	-- this will start both db client and db server if not.
	local db = TableDatabase:new():connect("temp/mydatabase/", function() end);
	
	-- Note: `db.User` will automatically create the `User` collection table if not.
	-- clear all data
	db.User:makeEmpty({}, function(err, count) end);
	-- add record
	local user = db.User:new({name="LXZ", password="123"});
	user:save(function(err, data)  echo(data) end);
	-- implicit update record
	local user = db.User:new({name="LXZ", password="1", email="lixizhi@yeah.net"});
	user:save(function(err, data)  echo(data) end);
	-- insert another one
	db.User:insertOne({name="LXZ2", password="123", email="lixizhi@yeah.net"}, function(err, data)  echo(data) 	end)
	-- update one
	db.User:updateOne({name="LXZ2", password="2", email="lixizhi@yeah.net"}, function(err, data)  echo(data) end)
	-- force flush to disk, otherwise the db IO thread will do this at fixed interval
    db.User:flush({}, function(err, bFlushed) echo("flushed: "..tostring(bFlushed)) end);
	-- select one, this will automatically create `name` index
	db.User:findOne({name="LXZ"}, function(err, user) echo(user);	end)
	-- search on non-indexed rows
	db.User:find({password="2"}, function(err, rows) echo(rows); end);
	-- find all rows with custom timeout 1 second
	db.User:find({}, function(err, rows) echo(rows); end, 1000);
	-- remove item
	db.User:deleteOne({name="LXZ2"}, function(err, count) echo(count);	end);
	-- find all rows
	db.User:find({}, function(err, rows) echo(rows); end);
	-- set cache to 2000KB, turn synchronous IO off, and use in-memory journal and 
	db.User:exec({CacheSize=-2000, IgnoreOSCrash=true, IgnoreAppCrash=true}, function(err, data) end);
	-- run sql command 
	db.User:exec("PRAGMA synchronous = ON", function(err, data) echo("mode changed") end);
	-- run select command from Collection 
	db.User:exec("Select * from Collection", function(err, rows) echo(rows) end);
```

## Why A New Database System?
Current SQL/NoSQL implementation can not satisfy following requirements at the same time.
* Keeping data close to computation, much like our brain. 
* Store arbitrary data without schema. 
* Automatic indexing based on query usage.
* Provide both blocking/non-blocking API.
* Multithreaded architecture without using network connections for maximum local performance.
* Capable of storing hundreds of Giga Bytes of data locally.
* Native document storage format for NPL tables. 
* Super easy client API just like manipulating standard NPL/lua tables.
* Easy to setup and deploy with NPL runtime.
* No server configuration, calling client API will automatically start the server on first use. 

## Implementation Details
* Each data table(collections of data) is stored in a single sqlite database file.
* Each database file contains a indexed mapping from object-id to object-table(document). 
* Each database file contains a schema table telling additional index keys used. 
* Each database file contains a key to object-id table for each custom index key. 
* All DB IO operations are performanced in a single dedicated NPL thread. 

## Opinion on Software Achitecture
Like the brain, we recommend that each computer manages its own chunk of data. 
As modern computers are having more computing cores, it is possible for a single (virtual) machine 
to manage 100-500GB of data locally or 1000 requests per second. Using a local database engine is the best choice 
in such situation for both performance and ease of deployment. 

To scale up to even more data and requests, we devide data with machines and use higher level
programming logics for communications. In this way, we control all the logics with our own code, 
rather than using general-purpose solutions like memcached, MangoDB(NoSQL), or SQLServer, etc. 
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Database/Collection.lua");
NPL.load("(gl)script/ide/System/Database/Item.lua");
NPL.load("(gl)script/ide/System/Database/IORequest.lua");
local IORequest = commonlib.gettable("System.Database.IORequest");
local Item = commonlib.gettable("System.Database.Item");
local Collection = commonlib.gettable("System.Database.Collection");

local type = type;
local g_threadName = __rts__:GetName();


local TableDatabase = commonlib.gettable("System.Database.TableDatabase");

-- writing NPL thread name
TableDatabase.writerThread = "tdb";
--TableDatabase.writerThread = "main"; -- this is for debugging in main thread
TableDatabase.isServer = 0;
TableDatabase.rootFolder = "temp/TableDatabase/";

function TableDatabase:new()
	local o = {
		collections = {},
	};
	setmetatable(o, self);
	return o;
end

function TableDatabase:__call(...)
	return TableDatabase.collection(self, ...);
end

function TableDatabase:__index(name)
	return rawget(self, name) or TableDatabase[name] or TableDatabase.collection(self, name);
end

-- whether this is a server thread
function TableDatabase:IsServer()
	return self.isServer == 1;
end

function TableDatabase:SetWriterTheadName(name)
	name = name or "main";
	self.writerThread = name;
	self.isServer = (name == g_threadName) and 1 or 0;
end

function TableDatabase:GetWriterThreadName()
	return self.writerThread;
end

-- create or get a collection on the client
function TableDatabase:collection(name)
	if(name) then
		local collection = rawget(self, name);
		if(not collection) then
			collection = Collection:new_collection():init(name, self);
			rawset(self, name, collection);
			self.collections[#(self.collections)+1] = collection;
		end
		return collection;
	end
end

function TableDatabase:GetCollectionCount()
	return #(self.collections);
end

function TableDatabase:GetRootFolder()
	return self.rootFolder;
end

-- call this on client thread
-- @param rootFolder: if nil, default to "temp/TableDatabase/"
function TableDatabase:connect(rootFolder, callbackFunc)
	self.rootFolder = rootFolder;
	IORequest:Send("connect", self, {rootFolder = self.rootFolder}, function(...)
		if(callbackFunc) then
			callbackFunc(...);
		end
	end);
	return self;
end

function TableDatabase:ToData()
	-- should always return nil;
end

-- automatically called from IO thread
function TableDatabase:open(rootFolder)
	self.rootFolder = rootFolder;
	ParaIO.CreateDirectory(rootFolder);
	LOG.std(nil, "info", "TableDatabase", "table database: %s is opened.", rootFolder);	
	return self;
end