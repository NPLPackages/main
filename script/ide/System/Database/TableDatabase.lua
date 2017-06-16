--[[
Title: Table database
Author(s): LiXizhi, 
Date: 2016/5/11
Desc: 
## Introduction to Table Database
A schema-less, server-less, NoSQL database able to process big data in multiple NPL threads, with extremly intuitive table-like API, 
automatic indexing and extremly fast searching, keeping data and algorithm in one system *just like how the human brain works*.

## Performance
Following is tested on my Intel-i7-3GHZ CPU with HDD. See `test` folder for details.

### Run With Conservative Mode
Following is averaged value from 100000+ operations in a single thread

* Random non-index insert: `43478 inserts/second`
   * Async API tested with default configuration with 1 million records on a single thread.
* Round trip latency call: 
   * Blocking API: `20000 query/s`
   * Non-blocking API: `11ms` or `85 query/s` (due to NPL time slice)
   * i.e. Round strip means start next operation after previous one is returned. This is latency test.
* Random indexed inserts: `17953 query/s`
   * i.e. start next operation immediately, without waiting for the first one to return.
* Random select with auto-index: `18761 query/s`
   * i.e. same as above, but with findOne operation. 
* Randomly mixing CRUD operations: `965-7518` query/s
   * i.e. same as above, but randomly calling Create/Read/Update/Delete (CRUD) on the same auto-indexed table.
   * Mixing read/write can be slow when database grows bigger. e.g. you can get `18000 CRUD/s` for just 10000 records. 

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
	db.User:makeEmpty({}, function(err, count) echo("deleted"..(count or 0)) end);
	-- insert 1
	db.User:insertOne(nil, {name="1", email="1@1",}, function(err, data)  echo(data) 	end)
	-- insert 1 with duplicate name
	db.User:insertOne(nil, {name="1", email="1@1.dup",}, function(err, data)  echo(data) 	end)
	
	-- find or findOne will automatically create index on `name` and `email` field.
	-- indices are NOT forced to be unique. The caller needs to ensure this see `insertOne` below. 
	db.User:find({name="1",}, function(err, rows) echo(rows); end);
	db.User:find({name="1", email="1@1"}, function(err, rows) echo(rows); end);
	
	-- force insert
	db.User:insertOne(nil, {name="LXZ", password="123"}, function(err, data)  echo(data) 	end)
	-- this is an update or insert command, if the query has result, it will actually update first matching row rather than inserting one. 
	-- this is usually a good way to force uniqueness on key or compound keys, 
	db.User:insertOne({name="LXZ"}, {name="LXZ", password="1", email="lixizhi@yeah.net"}, function(err, data)  echo(data) 	end)

	-- insert another one
	db.User:insertOne({name="LXZ2"}, {name="LXZ2", password="123", email="lixizhi@yeah.net"}, function(err, data)  echo(data) 	end)
	-- update one
	db.User:updateOne({name="LXZ2",}, {name="LXZ2", password="2", email="lixizhi@yeah.net"}, function(err, data)  echo(data) end)
	-- remove and update fields
	db.User:updateOne({name="LXZ2",}, {_unset = {"password"}, updated="with unset"}, function(err, data)  echo(data) end)
	-- force flush to disk, otherwise the db IO thread will do this at fixed interval
    db.User:flush({}, function(err, bFlushed) echo("flushed: "..tostring(bFlushed)) end);
	-- select one, this will automatically create `name` index
	db.User:findOne({name="LXZ"}, function(err, user) echo(user);	end)
	-- array field such as {"password", "1"} are additional checks, but does not use index. 
	db.User:findOne({name="LXZ", {"password", "1"}, {"email", "lixizhi@yeah.net"}}, function(err, user) echo(user);	end)
	-- search on non-unqiue-indexed rows, this will create index `email` (not-unique index)
	db.User:find({email="lixizhi@yeah.net"}, function(err, rows) echo(rows); end);
	db.User:find({name="LXZ", email="lixizhi@yeah.net", {"password", "1"}, }, function(err, rows) echo(rows); end);
	-- find all rows with custom timeout 1 second
	db.User:find({}, function(err, rows) echo(rows); end, 1000);
	-- remove item
	db.User:deleteOne({name="LXZ2"}, function(err, count) echo(count);	end);
	-- wait flush may take up to 3 seconds
	db.User:waitflush({}, function(err, data) echo({data, "data is flushed"}) end);
	-- set cache to 2000KB
	db.User:exec({CacheSize=-2000}, function(err, data) end);
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

## About Transactions
Each write/insert operation is by default a write command (virtual transaction). 
We will periodically (default is 3 seconds, see `Store.AutoFlushInterval`) flush all queued commands into disk. 
Everything during these period will either succeed or fail. 
If you are worried about data lose, you can manually invoke `flush` command, however doing so 
will greatly compromise performance. Please note `flush` command will affect the overall throughput of the entire DB system.
In general, you can only get about 20-100 flush(real transactions) per second. Without enforcing transaction on each command, you 
can easily get a throughput of 6000 write commands per second (i.e. could be 100 times faster). 

> There is one solution to get both high throughput and transaction.
After issuing an really important group of commands, and you want to ensure that these commands 
are actually successful like a transaction, the client can issue a `waitflush` 
command to check if the previous commands are successful. Please note that `waitflush` 
command may take up to 3 seconds or `Store.AutoFlushInterval` to return. 
You can make all calls asynchronous, so 99.99% times user get a fast feed back, 
but there is a very low chance that user may be informed of failure after 3 seconds. 
On client side, you may also need to prevent user to issue next transaction in 3 seconds,
In most cases, users do not click mouse that quick, so this hidden logic goes barely noticed.

## Opinion on Software Achitecture
Like the brain, we recommend that each computer manages its own chunk of data. 
As modern computers are having more computing cores, it is possible for a single (virtual) machine 
to manage 100-500GB of data locally or 1000 requests per second. Using a local database engine is the best choice 
in such situation for both performance and ease of deployment. 

To scale up to even more data and requests, we devide data with machines and use higher level
programming logics for communications. In this way, we control all the logics with our own code, 
rather than using general-purpose solutions like memcached, MangoDB(NoSQL), or SQLServer, etc. 

## Sync Mode API
Table database provides both sync and asynchronous API, and they can be use simultaneously. 
However, sync interface is disabled by default. One has to manually enable it, such as during initialization.
In sync interface, if you do not provide a callback function, then the API block until result is returned, otherwise the API return AsyncTask object immediately. See following example:

```lua
-- enable sync mode once and for all in current thread.
db:EnableSyncMode(true);
-- synchronous call will block until data is fetched. 
local err, data = db.User:insertOne({name="LXZ2", email="sync mode"})
-- async call return a task object immediately without waiting result. 
local task = db.User:insertOne({name="LXZ2", email="sync mode"}, function(err, data) end)
```
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
-- TableDatabase.writerThread = "main"; -- this is for debugging in main thread
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

function TableDatabase:EnableSyncMode(bEnabled)
	IORequest.EnableSyncMode = bEnabled;
	LOG.std(nil, "system", "TableDatabase", "sync mode api is %s in thread %s", bEnabled and "enabled" or "disabled", __rts__:GetName());
end

-- create or get a collection on the client
function TableDatabase:collection(name, provider)
	if(name) then
		local collection = rawget(self, name);
		if(not collection) then
			collection = Collection:new_collection():init(name, self, provider);
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

NPL.load("(gl)script/ide/System/Database/StorageProvider.lua");
local StorageProvider = commonlib.gettable("System.Database.StorageProvider");
local config_filename = "/tabledb.config.xml";
-- automatically called from IO thread
function TableDatabase:open(rootFolder)
	self.rootFolder = rootFolder;

	ParaIO.CreateDirectory(rootFolder);

	local config = ParaIO.open(rootFolder..config_filename, "r");
	if config:IsValid() then
		local str = config:GetText(0, -1);
		local xml = ParaXML.LuaXML_ParseString(str);

		NPL.load("(gl)script/ide/System/Compiler/lib/util.lua");
		local util = commonlib.gettable("System.Compiler.lib.util")

		if xml[1] and xml[1].name == "tabledb" then
			for i,item in ipairs(xml[1]) do
				-- providers should always comes first
				if item.name == "providers" then
					for i,provider in ipairs(item) do
						if provider.name == "provider" then

							local t = commonlib.split(provider[1], ",")
							local init_args = {}
							if provider.attr.name == "raft" then
								init_args = {
									baseDir = t[1],
									localAddress = {
										host = t[2],
										port = t[3],
										id = t[4],
									},
								}
							end

							NPL.load(provider.attr.file);
							local storage = commonlib.gettable(provider.attr.type);
							StorageProvider:RegisterStorageClass(provider.attr.name, storage, init_args)

						end
					end
				end
				if item.name == "tables" then
					for i,table in ipairs(item) do
						if table.name == "table" then
							self:collection(table.attr.name, table.attr.provider);
						end
					end
				end
			end
		end
	end
	LOG.std(nil, "info", "TableDatabase", "table database: %s is opened.", rootFolder);	
	return self;
end