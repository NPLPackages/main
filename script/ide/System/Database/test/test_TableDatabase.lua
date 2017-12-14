--[[
Title: Test Table database
Author(s): LiXizhi, 
Date: 2016/5/11
Desc: 
]]

-- basic tabledb command testing with asserts
function TestSQLOperations()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	-- this will start both db client and db server if not.
	local db = TableDatabase:new():connect("temp/mydatabase/", function() end);
	
	-- Note: `db.User` will automatically create the `User` collection table if not.
	-- clear all data
	db.User:makeEmpty({}, function(err, count) echo("deleted"..(count or 0)) end);
	-- insert 1
	db.User:insertOne(nil, {name="1", email="1@1",}, function(err, data)  assert(data.email=="1@1") 	end)
	-- insert 1 with duplicate name
	db.User:insertOne(nil, {name="1", email="1@1.dup",}, function(err, data)  assert(data.email=="1@1.dup") 	end)
	
	-- find or findOne will automatically create index on `name` and `email` field.
	-- indices are NOT forced to be unique. The caller needs to ensure this see `insertOne` below. 
	db.User:find({name="1",}, function(err, rows) assert(#rows==2); end);
	db.User:find({name="1", email="1@1"}, function(err, rows) assert(rows[1].email=="1@1"); end);
	-- find with compound index of name and email
	db.User:find({ ["+name+email"] = {"1", "1@1"} }, function(err, rows) assert(#rows==1); end);
	
	-- force insert
	db.User:insertOne(nil, {name="LXZ", password="123"}, function(err, data)  assert(data.password=="123") 	end)
	-- this is an update or insert command, if the query has result, it will actually update first matching row rather than inserting one. 
	-- this is usually a good way to force uniqueness on key or compound keys, 
	db.User:insertOne({name="LXZ"}, {name="LXZ", password="1", email="lixizhi@yeah.net"}, function(err, data)  assert(data.password=="1") 	end)

	-- insert another one
	db.User:insertOne({name="LXZ2"}, {name="LXZ2", password="123", email="lixizhi@yeah.net"}, function(err, data)  assert(data.password=="123") 	end)
	-- update one
	db.User:updateOne({name="LXZ2",}, {name="LXZ2", password="2", email="lixizhi@yeah.net"}, function(err, data)  assert(data.password=="2") end)
	-- remove and update fields
	db.User:updateOne({name="LXZ2",}, {_unset = {"password"}, updated="with unset"}, function(err, data)  assert(data.password==nil and data.updated=="with unset") end)
	-- replace the entire document
	db.User:replaceOne({name="LXZ2",}, {name="LXZ2", email="lixizhi@yeah.net"}, function(err, data)  assert(data.updated==nil) end)
	-- force flush to disk, otherwise the db IO thread will do this at fixed interval
    db.User:flush({}, function(err, bFlushed) assert(bFlushed==true) end);
	-- select one, this will automatically create `name` index
	db.User:findOne({name="LXZ"}, function(err, user) assert(user.password=="1");	end)
	-- array field such as {"password", "1"} are additional checks, but does not use index. 
	db.User:findOne({name="LXZ", {"password", "1"}, {"email", "lixizhi@yeah.net"}}, function(err, user) assert(user.password=="1");	end)
	-- search on non-unqiue-indexed rows, this will create index `email` (not-unique index)
	db.User:find({email="lixizhi@yeah.net"}, function(err, rows) assert(#rows==2); end);
	-- search and filter result with password=="1"
	db.User:find({name="LXZ", email="lixizhi@yeah.net", {"password", "1"}, }, function(err, rows) assert(#rows==1 and rows[1].password=="1"); end);
	-- find all rows with custom timeout 1 second
	db.User:find({}, function(err, rows) assert(#rows==4); end, 1000);
	-- remove item
	db.User:deleteOne({name="LXZ2"}, function(err, count) assert(count==1);	end);
	-- wait flush may take up to 3 seconds
	db.User:waitflush({}, function(err, bFlushed) assert(bFlushed==true) end);
	-- set cache to 2000KB
	db.User:exec({CacheSize=-2000}, function(err, data) end);
	-- run select command from Collection 
	db.User:exec("Select * from Collection", function(err, rows) assert(#rows==3) end);
	-- remove index fields
	db.User:removeIndex({"email", "name"}, function(err, bSucceed) assert(bSucceed == true) end)
	-- full table scan without using index by query with array items.
	db.User:find({ {"name", "LXZ"}, {"password", "1"} }, function(err, rows) assert(#rows==1 and rows[1].name=="LXZ"); end);
	-- find with left subset of previously created compound key "+name+email"
	db.User:find({ ["+name"] = {"1", limit=2} }, function(err, rows) assert(#rows==2); end);
	-- return at most 1 row whose id is greater than -1
	db.User:find({ _id = { gt = -1, limit = 1, skip == 1} }, function(err, rows) assert(#rows==1); echo("all tests succeed!") end);
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

	npl_profiler.perf_begin("tableDB_InsertThroughputNoIndex", true)
	local total_times = 1000000; -- a million non-indexed insert operation
	local max_jobs = 1000; -- concurrent jobs count
	NPL.load("(gl)script/ide/System/Concurrent/Parallel.lua");
	local Parallel = commonlib.gettable("System.Concurrent.Parallel");
	local p = Parallel:new():init()
	p:RunManyTimes(function(count)
		db.insertNoIndex:insertOne(nil, {count=count, data=math.random()}, function(err, data)
			if(err) then
				echo({err, data});
			end
			p:Next();
		end)
	end, total_times, max_jobs):OnFinished(function(total)
		npl_profiler.perf_end("tableDB_InsertThroughputNoIndex", true)
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
			db.PerfTest:insertOne(nil, {count=count, data=math.random(), }, function(err, data)
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
			
			db.PerfTest:insertOne(nil, {count=count, data=math.random(), }, function(err, data)
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
				local id = nTimes+math.random(1,nTimes);
				db.PerfTest:insertOne({count=id}, {count=id}, next);
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
			db.TestBulkOps:insertOne({count=count}, {count=count, data=math.random(), }, function(err, data)
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
		local err, data = db.blockingAPI:insertOne(nil, {count=i, data=math.random()})
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

function TestRemoveIndex()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	local db = TableDatabase:new():connect("temp/mydatabase/");	
	db.testIndex:findOne({subkey1 = "", subkey2 = "", subkey3 = ""}, function() end)
	db.testIndex:removeIndex({"subkey1"}, function() end)
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


function TestRangedQuery()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");

    -- this will start both db client and db server if not.
	local db = TableDatabase:new():connect("temp/mydatabase/");	

	-- add some data
	for i=1, 100 do
		db.rangedTest:insertOne({i=i}, {i=i, data="data"..i}, function() end)
	end

	-- return at most 5 records with i > 90, skipping 2. result in ascending  order
	db.rangedTest:find({ i = { gt = 95, limit = 5, offset=2} }, function(err, rows)
		echo(rows); --> 98,99,100
	end);

	-- return at most 20 records with _id > 98, result in ascending order
	db.rangedTest:find({ _id = { gt = 98, limit = 20} }, function(err, rows)
		echo(rows); --> 99,100
	end);
	
	-- do a full table scan without using index
	db.rangedTest:find({ {"i", { gt = 55, limit=2, offset=1} }, {"data", {lt="data60"} }, }, function(err, rows)
		echo(rows); --> 57,58
	end);

	db.rangedTest:find({ {"i", { gt = 55} }, {"data", "data60"}, }, function(err, rows)
		echo(rows); --> 60
	end);

	db.rangedTest:exec("EXPLAIN QUERY PLAN select * from iIndex where name > 95 limit 3", function(err, rows)
		echo(rows); 
	end);

end


function TestPagination()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	local db = TableDatabase:new():connect("temp/mydatabase/");	

	-- add some data
	for i=1, 10000 do
		db.pagedUsers:insertOne({name="name"..i}, 
			{name="name"..i, company="company"..i, state="state"..i}, function() end)
	end

	-- Approach One: using offset
	-- page 1
	db.pagedUsers:find({_id = {gt=-1, limit=10, skip=0}}, function(err, users)  echo(users) end);
	-- page 2
	db.pagedUsers:find({_id = {gt=-1, limit=10, skip=10}}, function(err, users)  echo(users) end);
	-- page 3
	db.pagedUsers:find({_id = {gt=-1, limit=10, skip=20}}, function(err, users)  echo(users) end);

	-- page n
	local pagesize = 10; local n = 10;
	db.pagedUsers:find({_id = {gt=-1, limit=pagesize, skip=(n-1)*pagesize}}, function(err, users)  echo(users) end);


	-- Approach two: Using find Recursively

	-- page 1
	db.pagedUsers:find({_id = { gt = -1, limit=10}}, function(err, users)  
		echo(users)
		-- Find the id of the last document in this page
		local last_id = users[#users]._id;

		-- page 2
		db.pagedUsers:find({_id = { gt = last_id, limit=10}}, function(err, users)  
			echo(users)
		   -- Find the id of the last document in this page
		   local last_id = users[#users]._id;
		   -- page 3
		   -- ...
		end);
	end);
end

function TestCompoundIndex()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	local db = TableDatabase:new():connect("temp/mydatabase/");	
	
	db.compoundTest:removeIndex({}, function(err, bRemoved) end);

	-- compound keys
	for i=1, 100 do
		db.compoundTest:insertOne({name="name"..i}, { 
			name="name"..i, 
			company = (i%2 == 0) and "tatfook" or "paraengine", 
			state = (i%3 == 0) and "china" or "usa"}, function() end)
	end

	-- compound key can also be created on single field "+company". it differs from standard key "company". 
	db.compoundTest:find({["+company"] = {"paraengine", limit=5, skip=3}}, function(err, users)  
		assert(#users == 5)
	end);

	-- create a compound key on +company+name (only the right most key can be paged)
	-- `+` means index should use ascending order, `-` means descending. such as "+company-name"
	-- it will remove "+company" key, since the new component key already contains the "+company". 
	db.compoundTest:find({["+company+name"] = {"tatfook", gt="", limit=5, skip=3}}, function(err, users)  
		assert(#users == 5)
	end);

	-- a query of exact same left keys after a compound key is created will automatically use 
	-- the previously created compound key, so "+company",  "+company+name" in following query are the same.
	db.compoundTest:find({["+company"] = {"tatfook", limit=5, skip=3}}, function(err, users)  
		assert(#users == 5)
	end);

	-- the order of key names in compound index is important. for example:
	-- "+company+state+name" shares the same compound index with "+company" and "+company+state"
	-- "+state+name+company" shares the same compound index with "+state" and "+state+name"
	db.compoundTest:find({["+state+name+company"] = {"china", gt="name50", limit=5, skip=3}}, function(err, users)  
		assert(#users == 5)
	end);

	-- compound keys with descending order. Notice the "-" sign before `name`.
	db.compoundTest:find({["+state-name+company"] = {"china", limit=5, skip=3}}, function(err, users)  
		assert(#users == 5)
	end);

	-- updateOne with compound key
	db.compoundTest:updateOne({["+state-name+company"] = {"usa", "name1", "paraengine"}}, {name="name0_modified"}, function(err, user)  
		assert(user.name == "name0_modified")
	end);

	-- this query is ineffient since it uses intersection of single keys (with many duplications). 
	-- one should consider use "+state+company", instead of this. 
	db.compoundTest:find({state="china", company="tatfook"}, function(err, users)  
		assert(#users == 16)
	end);

	-- this query is ineffient since it uses intersection of single keys. 
	-- one should consider use "+state+company", instead of this. 
	db.compoundTest:count({state="china", company="tatfook"}, function(err, count)  
		assert(count == 16)
	end);
end

function TestCountAPI()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	local db = TableDatabase:new():connect("temp/mydatabase/");	
	
	db.countTest:removeIndex({}, function(err, bRemoved) end);

	for i=1, 100 do
		db.countTest:insertOne({name="name"..i}, { 
			name="name"..i, 
			company = (i%2 == 0) and "tatfook" or "paraengine", 
			state = (i%3 == 0) and "china" or "usa"}, function() end)
	end

	-- count all rows
	db.countTest:count({}, function(err, count)  
		assert(count == 100) 
	end);
	-- count with compound keys
	db.countTest:count({["+company"] = {"tatfook"}}, function(err, count)  
		assert(count == 50) 
	end);
	-- count with complex query
	db.countTest:count({["+state+name+company"] = {"china", gt="name50"}}, function(err, count)  
		assert(count == 19) 
	end);
end

function TestDelete()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	local db = TableDatabase:new():connect("temp/mydatabase/");	
	
	db.deleteTest:makeEmpty({}, function(err, count) echo("deleted"..(count or 0)) end);
	
	for i=1, 100 do
		db.deleteTest:insertOne(nil, { 
			name="name"..i, 
			company = (i%2 == 0) and "tatfook" or "paraengine", 
			state = (i%3 == 0) and "china" or "usa"}, function() end)
	end

	-- delete using any key
	db.deleteTest:deleteOne({name="name1"}, function(err, count)  
		assert(count == 1) 
	end);

	-- delete any
	for i=1, 97 do
		-- delete any one
		db.deleteTest:deleteOne({}, function(err, count)  
			assert(count == 1) 
		end);
	end
	-- delete remaining ones
	db.deleteTest:delete({}, function(err, count)
		assert(count == 2);
	end)

	-- insert duplicates
	db.deleteTest:insertOne(nil, {duplicated_name="1" }, function() end);
	db.deleteTest:insertOne(nil, {duplicated_name="1" }, function() end);

	-- remove multiple ones
	db.deleteTest:delete({duplicated_name="1"}, function(err, count)
		assert(count == 2);
	end)
end

function TestMultipleDB()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	-- this will start both db client and db server if not.
	local db_cluster1 = TableDatabase:new():connect("temp/mydatabase/db_cluster1/", function() end);
	local db_cluster2 = TableDatabase:new():connect("temp/mydatabase/db_cluster2/", function() end);
	db_cluster1.User:makeEmpty({}, function(err, count) echo("deleted"..(count or 0)) end);
	db_cluster2.User:makeEmpty({}, function(err, count) echo("deleted"..(count or 0)) end);
	
	db_cluster1.User:insertOne(nil, {name="db", email="db_cluster1@1",}, function(err, data)   	end)
	db_cluster2.User:insertOne(nil, {name="db", email="db_cluster2@1",}, function(err, data)   	end)
	
	db_cluster1.User:find({name="db",}, function(err, rows) assert(rows[1].email == "db_cluster1@1") end);
	db_cluster2.User:find({name="db",}, function(err, rows) assert(rows[1].email == "db_cluster2@1") end);
end

function TestOpenDatabase()
	NPL.load("(gl)script/ide/LuaXML.lua");
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");

	local config = { 
		name = "tabledb", 
		{
			name = "providers", 
			{ name = "provider", attr = { name = "raft", type = "TableDB.RaftSqliteStore", file = "(g1)npl_mod/TableDB/RaftSqliteStore.lua" }, "./,localhost,9004,4" }
		},
		{
			name = "tables",
			{ name = "table", attr = { provider = "raft", name = "RaftUsers" } }, 
			{ name = "table", attr = { provider = "raft", name = "RaftTemp" } },
			{ name = "table", attr = { provider = "raft", name = "default" } }, 
		}
	}

	local config_path = "temp/mydatabase/tabledb.config.xml";
	local str = commonlib.Lua2XmlString(config, true);
	ParaIO.CreateDirectory(config_path);
	local file = ParaIO.open(config_path, "w");
	if (file:IsValid()) then

		file:WriteString(str);
		file:close();

	end

	local db = TableDatabase:new():connect("temp/mydatabase/");	

end

function TestUpdateIndex()
	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	local db = TableDatabase:new():connect("temp/mydatabase/");	
	
	db.updateIndexTest:makeEmpty({}, function(err, count) echo("deleted"..(count or 0)) end);

	db.updateIndexTest:insertOne(nil, {name="user"}, function(err, data) assert(data.name=="user") end)
	db.updateIndexTest:insertOne(nil, {name="user", age=15}, function(err, data) assert(data.name=="user") end)
	db.updateIndexTest:insertOne(nil, {name="user"}, function(err, data) assert(data.name=="user") end)

	db.updateIndexTest:updateOne({name="user", age=15}, {name="user2"}, function(err, data) assert(data.name=="user2") end)
	
	db.updateIndexTest:find({name="user"}, function(err, rows) assert(#rows==2); end)
end

-- NPL.load("(gl)script/ide/commonlib.lua");
-- TestUpdateIndex();