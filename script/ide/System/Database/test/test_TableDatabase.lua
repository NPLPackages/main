--[[
Title: Test Table database
Author(s): LiXizhi, 
Date: 2016/5/11
Desc: 
]]


function TestSQLOperations()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	-- this will start both db client and db server if not.
	local db = TableDatabase:new():connect("temp/mydatabase/", function() end);
	
	-- Note: `db.User` will automatically create the `User` collection table if not.
	-- clear all data
	db.User:makeEmpty({}, function(err, count) echo("deleted"..(count or 0)) end);
	-- this will automatically create `name` index
	db.User:findOne({name="this will create auto index"}, function(err, user) end)
	-- add record
	local user = db.User:new({name="LXZ", password="123"});
	user:save(function(err, data)  echo(data) end);
	-- implicit update record
	local user = db.User:new({name="LXZ", password="1", email="lixizhi@yeah.net"});
	user:save(function(err, data)  echo(data) end);
	-- insert another one
	db.User:insertOne({name="LXZ2", password="123", email="lixizhi@yeah.net"}, function(err, data)  echo(data) 	end)
	-- update one
	db.User:updateOne({name="LXZ2",}, {name="LXZ2", password="2", email="lixizhi@yeah.net"}, function(err, data)  echo(data) end)
	-- remove and update fields
	db.User:updateOne({name="LXZ2",}, {_unset = {"password"}, email="2@yeah.net"}, function(err, data)  echo(data) end)
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
	-- wait flush may take up to 3 seconds
	db.User:waitflush({}, function(err, data) echo({data, "data is flushed"}) end);
	-- find all rows
	db.User:find({}, function(err, rows) echo(rows); end);
	-- set cache to 2000KB, turn synchronous IO off, and use in-memory journal and 
	db.User:exec({CacheSize=-2000, IgnoreOSCrash=true, IgnoreAppCrash=true}, function(err, data) end);
	-- run sql command 
	db.User:exec("PRAGMA synchronous = ON", function(err, data) echo("mode changed") end);
	-- run select command from Collection 
	db.User:exec("Select * from Collection", function(err, rows) echo(rows) end);
end


-- takes 23 seconds with 1 million record, on my HDD, CPU i7.
function TestInsertThroughputNoIndex()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");

    -- this will start both db client and db server if not.
	local db = TableDatabase:new():connect("temp/mydatabase/");
	
	db.insertNoIndex:makeEmpty({});
	db.insertNoIndex:flush({});
		
	NPL.load("(gl)script/ide/Debugger/NPLProfiler.lua");
	local npl_profiler = commonlib.gettable("commonlib.npl_profiler");
	npl_profiler.perf_reset();

	npl_profiler.perf_begin("tableDB_BlockingAPILatency", true)
	local total_times = 1000000; -- a million non-indexed insert operation
	local max_jobs = 1000; -- concurrent jobs count
	NPL.load("(gl)script/ide/System/Concurrent/Parallel.lua");
	local Parallel = commonlib.gettable("System.Concurrent.Parallel");
	local p = Parallel:new():init()
	p:RunManyTimes(function(count)
		db.insertNoIndex:insertOne({count=count, data=math.random()}, function(err, data)
			if(err) then
				echo({err, data});
			end
			p:Next();
		end)
	end, total_times, max_jobs):OnFinished(function(total)
		npl_profiler.perf_end("tableDB_BlockingAPILatency", true)
		log(commonlib.serialize(npl_profiler.perf_get(), true));			
	end);
end

function TestPerformance()
	NPL.load("(gl)script/ide/Debugger/NPLProfiler.lua");
	local npl_profiler = commonlib.gettable("commonlib.npl_profiler");
	npl_profiler.perf_reset();

	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	
	-- how many times for each CRUD operations.
	local nTimes = 10000; 
	local max_jobs = 1000; -- concurrent jobs count
	local insertFlush, testRoundTrip, randomCRUD, findMany;
	
	-- this will start both db client and db server if not.
	local db = TableDatabase:new():connect("temp/mydatabase/");

	-- this not necessary now, but put here as an example.
	db.User:exec({QueueSize=10001}, function(err, data) end);

	-- use at most 200MB memory, instead of the default 2MB
	-- db.User:exec({CacheSize=-200000}, function(err, data) end);

	-- uncomment to test aggressive mode
	-- db.User:exec({CacheSize=-2000, IgnoreOSCrash=true, IgnoreAppCrash=true}, function(err, data) end);

	NPL.load("(gl)script/ide/System/Concurrent/Parallel.lua");
	local Parallel = commonlib.gettable("System.Concurrent.Parallel");

    db.PerfTest:makeEmpty({}, function() 
		echo("emptied");
		-- this will force creating index on `name`
		db.PerfTest:findOne({name = ""}, function() 
			db.PerfTest:flush({}, function()
				insertFlush();
			end);
		end);
    end);
    
	local lastTime = ParaGlobal.timeGetTime();
	local function CheckTickLog(...)
		if ((ParaGlobal.timeGetTime() - lastTime) > 1000) then
			LOG.std(nil, "info", ...);
			lastTime = ParaGlobal.timeGetTime();
		end
	end
	insertFlush = function()
		npl_profiler.perf_begin("insertFlush", true)
		local p = Parallel:new():init();
		p:RunManyTimes(function(count)
			db.PerfTest:insertOne({count=count, data=math.random(), }, function(err, data)
				if(err) then echo({err, data}) end
				p:Next();
			end)
		end, nTimes, max_jobs):OnFinished(function(total)
			npl_profiler.perf_end("insertFlush", true)
			testRoundTrip();
		end);
	end
	
	local nRoundTimes = 100;
	local count = 0;
	-- latency: about 11ms
	testRoundTrip = function()
		if(count == 0) then
			npl_profiler.perf_begin("testRoundTrip", true)
		end
		if(count < nRoundTimes) then
			count = count + 1;
			
			db.PerfTest:insertOne({count=count, data=math.random(), }, function(err, data)
				CheckTickLog("roundtrip", "%d %s", count, err);
				testRoundTrip();
			end)
		else
			-- force flush
			db.PerfTest:flush({}, function()
				npl_profiler.perf_end("testRoundTrip", true)
				randomCRUD();
			end)
		end
	end

	-- randome CRUD operations
	randomCRUD = function()
		npl_profiler.perf_begin("randomCRUD", true)

		local p = Parallel:new():init();

		local function next(err, data)
			p:Next();
		end
		p:RunManyTimes(function(count)
			local nCrudType = math.random(1, 4);
			if(nCrudType == 1) then
				db.PerfTest:updateOne({count=math.random(1,nTimes)}, {data="updated"}, next);
			elseif(nCrudType == 2) then
				db.PerfTest:insertOne({count=nTimes+math.random(1,nTimes)}, next);
			elseif(nCrudType == 3) then
				db.PerfTest:deleteOne({count=math.random(1,nTimes)}, next);
			else
				db.PerfTest:findOne({count=math.random(1,nTimes)}, next);
			end
		end, nTimes, max_jobs):OnFinished(function(total)
			npl_profiler.perf_end("randomCRUD", true)
			findMany();
		end);
	end

	findMany = function()
		npl_profiler.perf_begin("findMany", true)

		local p = Parallel:new():init();
		p:RunManyTimes(function(count)
			db.PerfTest:findOne({count=math.random(1,nTimes)}, function(err, data)
				if(err) then echo({err, data}) end
				p:Next();
			end)
		end, nTimes, max_jobs):OnFinished(function(total)
			echo("finished.......")
			npl_profiler.perf_end("findMany", true)
			log(commonlib.serialize(npl_profiler.perf_get(), true));
		end);
	end
end

-- This is example of bulk operation. 
-- Please use 'System.Concurrent.Parallel' in real world test case
-- See above `TestInsertThroughputNoIndex()` code.
function TestBulkOperations()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	local db = TableDatabase:new():connect("temp/mydatabase/");
	db.TestBulkOps:makeEmpty({}, function()  end);

	local total_records = 100000;
	local chunk_size = 1000;

	local count = 0;
	local function DoNextChunk()
		local finished = 0;
		for i=1, chunk_size do
			count = count + 1;
			if(count > total_records) then
				break;
			end
			db.TestBulkOps:insertOne({count=count, data=math.random(), }, function(err, data)
				finished = finished +1;
				if(count == total_records) then
					echo({"all operations are finished"});
				elseif(finished == chunk_size) then
					echo({"a chunk is done", count});
					DoNextChunk();
				end
			end)
		end
	end
	DoNextChunk();
end

function TestTimeout()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	-- this will start both db client and db server if not.
	local db = TableDatabase:new():connect("temp/mydatabase/");
	
	db.User:silient({name="will always timeout"}, function(err, data) echo(err, data) end);
	db.User:silient({name="will always timeout"}, function(err, data) echo(err, data) end);
end


function TestBlockingAPI()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");

	-- this will start both db client and db server if not.
	local db = TableDatabase:new():connect("temp/mydatabase/");
	
	-- enable sync mode once and for all in current thread.
    db:EnableSyncMode(true);

	-- clear all data
	local err, data = db.User:makeEmpty({});

	-- add record
	local user = db.User:new({name="LXZ", password="123"});
	local err, data = user:save();   
	echo(data);
	
	-- implicit update record
	local user = db.User:new({name="LXZ", password="1", email="lixizhi@yeah.net"});
	local err, data = user:save();   
	echo(data);
end

-- it can do about 12000/s with sync API. 
function TestBlockingAPILatency()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");

    -- this will start both db client and db server if not.
	local db = TableDatabase:new():connect("temp/mydatabase/");
	-- enable sync mode once and for all in current thread.
    db:EnableSyncMode(true);

	db.blockingAPI:makeEmpty({});
	db.blockingAPI:flush({});
	db.blockingAPI:exec({QueueSize=10001});
		
	NPL.load("(gl)script/ide/Debugger/NPLProfiler.lua");
	local npl_profiler = commonlib.gettable("commonlib.npl_profiler");
	npl_profiler.perf_reset();

	npl_profiler.perf_begin("tableDB_BlockingAPILatency", true)
	local count = 10000;
	for i=1, count do
		local err, data = db.blockingAPI:insertOne({count=i, data=math.random()})
		-- echo(data);
	end
	npl_profiler.perf_end("tableDB_BlockingAPILatency", true)
	log(commonlib.serialize(npl_profiler.perf_get(), true));		
end

function TestSqliteStore()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	NPL.load("(gl)script/ide/System/Database/SqliteStore.lua");
	local SqliteStore = commonlib.gettable("System.Database.SqliteStore");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	local db = TableDatabase:new():connect("temp/mydatabase/", function()  echo("connected1") end);
	local store = SqliteStore:new():init(db.User);

	-- testing adding record
	local user = db.User:new({name="LXZ", password="123"});
	user:save(function(err, data) echo(data) end);

	store:findOne({name="npl"}, function(err, data) echo(err, data) end);

	store:Close();
end

function TestConnect()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	local db1 = TableDatabase:new():connect("temp/mydatabase/", function()  echo("connected1") end);
	local db2 = TableDatabase:new():connect("temp/mydatabase/", function()  echo("connected2") end);
	db1.User:findOne({name="npl"}, function(err, data) echo(data) end);
	db2.User:findOne({name="npl"}, function(err, data) echo(data) end);
	db1.User:findOne({name="npl"}, function(err, data) echo(data) end);
end

function TestTable()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	-- this will start both db client and db server if not.
	local db = TableDatabase:new():connect("temp/mydatabase/", function()  echo("connected") end);
	local c1 = db("c1");
	local c2 = db.c2; 
	assert(c2.name == "c2");
	assert(db.c3.name == "c3");
	assert(db:GetCollectionCount() == 3);

	-- testing adding record
	local user = db.User:new({name="LXZ", password="123"});
	user:save(function(err, data)  echo(data) end);

	-- test select, automatically add index on `name`
	db.User:findOne({name="LXZ"}, function(err, user)
		assert(user.name == "LXZ" and user.password=="123");
	end)
end

function TestTableDatabase()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	-- this will start both db client and db server if not.
	local db = TableDatabase:new():connect("temp/mydatabase/");
	-- this will automatically create the `User` collection table if not.
	local User = db.User; 
	-- another way to create/get User table.
	local User = db("User");

	-- select with automatic indexing
	-- Async Non-Blocking API (Recommended)
	User:findOne({name="LXZ"}, function(err, user)
		echo(user);
	end)
	-- Blocking API
	local user = User:findOne({name="LXZ"});

	-- insert/update 
	local user = User:new({name="LXZ", password="123"});
	-- Async save
	user:save(function()  end);
	-- Blocking API
	user:save();

	User:updateOne({name="LXZ"}, {password="312"}, function(err)	end);
end