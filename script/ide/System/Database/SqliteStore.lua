--[[
Title: Sqlite3 store
Author(s): LiXizhi, 
Date: 2016/5/11
Desc: Each collection data is saved in a single sqlite3 database file with the same name. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Database/SqliteStore.lua");
local SqliteStore = commonlib.gettable("System.Database.SqliteStore");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Database/Store.lua");
NPL.load("(gl)script/ide/System/Database/SqliteIndexTable.lua");
NPL.load("(gl)script/ide/System/Database/SqliteCompoundIndex.lua");
NPL.load("(gl)script/ide/System/Database/IdSet.lua");
local IdSet = commonlib.gettable("System.Database.IdSet");
local IndexTable = commonlib.gettable("System.Database.SqliteStore.IndexTable");
local type = type;
local SqliteStore = commonlib.inherit(commonlib.gettable("System.Database.Store"), commonlib.gettable("System.Database.SqliteStore"));
SqliteStore.kCurrentVersion = 6;
SqliteStore.journelMode = "WAL";

-- SQL create table command columns
SqliteStore.kTables ={
	{ 
		table_name = "SystemInfo",
		columns = [[
			(id INTEGER PRIMARY KEY AUTOINCREMENT,
			name TEXT UNIQUE,
			value TEXT)]]
	},
	{
		table_name = "Indexes",
		columns = [[
			(id INTEGER PRIMARY KEY AUTOINCREMENT,
			name TEXT UNIQUE,
			tablename TEXT)]]
	},
	{
		table_name = "Collection",
		columns = [[
			(id INTEGER PRIMARY KEY AUTOINCREMENT,
			value TEXT)]]
	},
}

function SqliteStore:ctor()
	self.indexes = {};
	self.info = {};
	-- total number of commands executed
	self.totalCmd = 0; 
	self.lastTickCount = 0;
	self.transaction_depth_ = 0; -- nested transaction count
	self.transaction_labels_ = {}
	self.queued_transaction_count = 0;
	self.waitflush_queue = {};
	self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
		if(self:FlushAll()) then
			timer:Change();
		end
	end})
	self.checkpoint_timer = self.checkpoint_timer or commonlib.Timer:new({callbackFunc = function(timer)
		if self._db then
			self:exec({checkpoint=true});
			timer:Change();
		end
	end})
end

-- called when a single command is finished. 
function SqliteStore:CommandTick(commandname)
	if(commandname) then
		self:AddStat(commandname, 1);
	end
	self.totalCmd = self.totalCmd + 1;

	-- tick timers every 1 thousand operation. 
	if((self.totalCmd - self.lastTickCount) > 1000) then
		self.lastTickCount = self.totalCmd;
		self:TickTimers();
	end
end

-- sometimes timer is not accurate when server is very busy, such as during bulk operations. 
-- this function is called every 1 thousand operations to make the timer accurate. 
function SqliteStore:TickTimers()
	local nTickCount = ParaGlobal.timeGetTime();
	if(self.timer:IsEnabled()) then
		self.timer:Tick(nTickCount);
	end
	if(self.checkpoint_timer:IsEnabled()) then
		self.checkpoint_timer:Tick(nTickCount);
	end
end

function SqliteStore:CloseSQLStatement(name)
	if(self[name]) then
		self[name]:close();
		self[name] = nil;
	end
end

-- When sqlite_master table(schema) is changed, such as when new index table is created, 
-- all cached statements becomes invalid. And this function should be called to purge all statements created before.
-- Note: current prepare binding use old sqlite_prepare(), in future I may switch to  
-- sqlite_prepare_v2() which will automatically recompile all statements when schema changes, and this function would not be necessary.
function SqliteStore:ClearStatementCache()
	self:CloseSQLStatement("add_stat");
	self:CloseSQLStatement("del_stat");
	self:CloseSQLStatement("del_stat_if");
	self:CloseSQLStatement("select_stat");
	self:CloseSQLStatement("sel_row_stat");
	self:CloseSQLStatement("sel_all_stat");
	self:CloseSQLStatement("select_gt_stat");
	self:CloseSQLStatement("select_any_stat");
	self:CloseSQLStatement("update_stat");
	self:CloseSQLStatement("insert_stat");
	
	for name, indexTable in pairs(self.indexes) do
		if(indexTable:GetName() == name) then
			indexTable:ClearStatementCache();
		end
	end
end

function SqliteStore:init(collection)
	SqliteStore._super.init(self, collection);
	NPL.load("(gl)script/sqlite/sqlite3.lua");

	self.kFileName = collection:GetParent():GetRootFolder() .. collection:GetName() .. ".db";

	local err;
	self._db, err = sqlite3.open(self.kFileName);
	if(self:ValidateDB(true)) then
		self:FetchIndexes();
	end

	if(self._db) then
		-- http://stackoverflow.com/questions/1711631/improve-insert-per-second-performance-of-sqlite
		self:exec({journelMode = self.journelMode, IgnoreOSCrash = self.IgnoreOSCrash, IgnoreAppCrash = self.IgnoreAppCrash});
		if(self.CacheSize and self.CacheSize~=-2000) then
			self:exec({CacheSize = self.CacheSize});
		end
		LOG.std(nil, "info", "SqliteStore", "collection %s opened", self:GetCollection():GetName());
	end
	return self;
end

function SqliteStore:CheckOpen()
	if(not self.db) then
		self:Reopen();
	end
end

-- reopen connection, this is necessary when we drop index. 
function SqliteStore:Reopen()
	if(self.kFileName) then
		self:Close();
		self._db, err = sqlite3.open(self.kFileName);
		if(self._db) then
			-- http://stackoverflow.com/questions/1711631/improve-insert-per-second-performance-of-sqlite
			self:exec({journelMode = self.journelMode, IgnoreOSCrash = self.IgnoreOSCrash, IgnoreAppCrash = self.IgnoreAppCrash});
			if(self.CacheSize and self.CacheSize~=-2000) then
				self:exec({CacheSize = self.CacheSize});
			end
			LOG.std(nil, "info", "SqliteStore", "collection %s reopened", self:GetCollection():GetName());
		end
	end
end

function SqliteStore:Close()
	if(self._db) then
		self:ClearStatementCache();
		self._db:close();
		self._db = nil;
	end
end

-- check if database is up to date.
-- @param bAutoFix: if true, we will automatically create or upgrade the database
function SqliteStore:ValidateDB(bAutoFix)
	if(self._db) then
		local stmt, err = self._db:prepare([[SELECT * FROM SystemInfo]]);
		if(stmt) then
			for row in stmt:rows() do
				if(row.name) then
					if(row.value and row.value:match("^%d+$")) then
						row.value = tonumber(row.value);
					end
					self.info[row.name] = row.value;
				end
			end
			stmt:close();
			self.info.version = self.info.version or 0;
			if(self.info.version == SqliteStore.kCurrentVersion) then
				return true;
			elseif(self.info.version > SqliteStore.kCurrentVersion) then
				LOG.std(nil, "warn", "SqliteStore", "your runtime version is lower than the db version for %s.", self.kFileName);
				return true;
			end
		end
	end
	if(bAutoFix) then
		return self:CreateOrUpgradeDatabase();
	end
end

function SqliteStore:GetFileName()
	return self.kFileName or "";
end

-- currently only support upgrading Info and Indexes table.
function SqliteStore:CreateOrUpgradeDatabase()
	if(self._db) then
		self._db:close();
	end
	-- create the database. 
	local err;
	self._db, err = sqlite3.open( self.kFileName);
	if( self._db == nil)then
		LOG.std(nil, "error", "SqliteStore", "error: failed connecting to localserver db"..tostring(err));
	end

	self:Begin();
		-- drop all tables. 
		self:DropAllMetaTables();
	
		-- create all tables
		self:CreateTables();

		-- insert version infos
		local insert_stmt = assert(self._db:prepare("INSERT INTO SystemInfo (Name, Value) VALUES(?, ?)"));
		insert_stmt:bind("version", SqliteStore.kCurrentVersion);
		insert_stmt:exec();
		insert_stmt:bind("author", "NPLRuntime");
		insert_stmt:exec();
		insert_stmt:bind("name", self:GetCollection():GetName());
		insert_stmt:exec();
		insert_stmt:close();

	self:End();
	self:FlushAll();
	LOG.std(nil, "system", "SqliteStore", "%s is recreated either because it does not exist or needs update", self.kFileName);
	return self:ValidateDB();
end

function SqliteStore:CreateTables()
	for _, table in ipairs(SqliteStore.kTables) do
		local sql = "CREATE TABLE IF NOT EXISTS ";
		sql = sql..table.table_name.." "
		sql = sql..table.columns;
		self._db:exec(sql);
	end
end


-- Drop all, but never drop `Collection` table. 
function SqliteStore:DropAllMetaTables()
	if(not self._db) then return end
	local _db = self._db;

	-- use a transaction
	self:Begin();
		local tablenames = {};
		
		for row in _db:rows("SELECT name FROM sqlite_master WHERE type = 'table'") do
			-- Some tables internal to sqlite may not be dropped, for example sqlite_sequence. We ignore this error.
			if(string.find(row.name, "^sqlite_sequence")) then
			else
				table.insert(tablenames, row.name);
			end
		end
		
		for _, name in ipairs(tablenames) do
			-- always skip Collection table.
			if(name ~= "Collection") then
				_db:exec("DROP TABLE "..name);
				LOG.std(nil, "info", "SqliteStore", "%s is removed from db.", name);
			end
		end
	self:End(); -- commit changes
end

function SqliteStore:LoadIndexByName(name)
	local indexTable;
	if(name:match("^[%+%-]")) then
		indexTable = SqliteStore.CompoundIndexTable:new():init(name, self);
	else
		indexTable = SqliteStore.IndexTable:new():init(name, self);
	end
	return indexTable;
end

function SqliteStore:FetchIndexes()
	local stmt = assert(self._db:prepare([[SELECT * FROM Indexes]]));
	for row in stmt:rows() do
		if(row.name) then
			self:AddIndexTableImp(self:LoadIndexByName(row.name))
		end
	end
	stmt:close();
end

-- return SqliteIndexTable object or nil. 
function SqliteStore:GetIndex(name, bCreateIfNotExist)
	local indexTable = self.indexes[name];
	if(not indexTable) then
		if(bCreateIfNotExist and name~="_id") then
			indexTable = self:LoadIndexByName(name);
			indexTable:CreateTable();
			self:AddIndexTableImp(indexTable);
		end
	end
	return indexTable;
end

function SqliteStore:AddIndexTableImp(indexTable)
	if(indexTable) then	
		for key, _ in pairs(indexTable:GetKeyNames()) do
			local oldIndex = self.indexes[key];
			if(oldIndex and oldIndex~=indexTable) then
				if(indexTable:isSuperSetOf(oldIndex)) then
					-- destroy old index.
					LOG.std(nil, "info", "SqliteStore", "old index %s will be replaced by new index %s", oldIndex:GetName(),  indexTable:GetName());
					self:RemoveIndexImp(oldIndex:GetName());
				end
			end
			self.indexes[key] = indexTable;
		end
	end
end

-- @param name: if nil all indices are removed. 
function SqliteStore:RemoveIndexImp(name)
	if(not name) then
		-- remove all indices
		local names = {};
		for name, indexTable in pairs(self.indexes) do
			names[indexTable:GetName()] = true;
		end
		for name, _ in pairs(names) do
			self:RemoveIndexImp(name);
		end
	else
		local indexTable = self:GetIndex(name);
		if(indexTable) then
			indexTable:Destroy();
			for key, _ in pairs(indexTable:GetKeyNames()) do
				if(self.indexes[key] == indexTable) then
					self.indexes[key] = nil;
				end
			end
		end
	end
end

-- get index Table from query skipping first nSkipCount
-- @param bAutoCreateIndex: if true, index is automatically created.
-- @param nSkipCount: skip this number of index, default to 0, which returns the first index found. 
-- @return: indexTable, queryValue: indexTable is nil if there is no index found or _id is found in query. 
-- queryValue can be the value or a table containing more query info. 
function SqliteStore:FindIndexFromQuery(query, bAutoCreateIndex, nSkipCount)
	nSkipCount = nSkipCount or 0;
	local id = query._id;
	if(id) then
		if(nSkipCount == 0) then
			return nil, id;
		end
	else
		local count = 0;
		for name, value in pairs(query) do
			if(type(name)=="string" and name~="_unset") then
				local indexTable = self:GetIndex(name, bAutoCreateIndex);
				if(indexTable) then
					if(nSkipCount == count) then
						return indexTable, value;
					else
						count = count + 1;
					end
				end
			end
		end
	end
end

-- get just one row id from query string.
-- @param bAutoCreateIndex: if true, index is automatically created.
-- @return nil if there is no index. false if the record does not exist in collection. otherwise return the row id.
function SqliteStore:FindRowId(query, bAutoCreateIndex)
	if(type(query._id) == "number") then
		return query._id;
	else
		local ids = self:findRowIds(query, bAutoCreateIndex)
		if(ids) then
			if(#ids>0) then
				return ids[1];
			else
				return false;
			end
		end
	end
end

-- internally it will use just a single statement to search both index and collection table.
-- so it is faster than using two statements for each table.
-- return nil or the row object. _id is injected.
function SqliteStore:findCollectionRow(query, bAutoCreateIndex)
	local id = self:FindRowId(query, bAutoCreateIndex)
	if(id) then
		local row = self:InjectID(self:getCollectionRow(id), id);
		return self:filterRowByQuery(row, query);
	end
end

function SqliteStore:getCollectionRow(id)
	if(id) then
		local value;
		self.select_stat = self.select_stat or self._db:prepare([[SELECT * FROM Collection WHERE id=?]]);
		
		if(self.select_stat) then
			self.select_stat:bind(id);
			self.select_stat:reset();
			local row = self.select_stat:first_row();
			if(row) then
				value = NPL.LoadTableFromString(row.value) or {};
			end
			return value;
		else
			LOG.std(nil, "error", "SqliteStore", "failed to create select statement");
		end
	end
end


-- auto indexed
function SqliteStore:findOne(query, callbackFunc)
	self:CommandTick("select");
	
	local err, data;
	if(query) then
		data = self:findCollectionRow(query, true);
	end
	return self:InvokeCallback(callbackFunc, err, data);
end

-- virtual: 
function SqliteStore:removeIndex(query, callbackFunc)
	if(not query or not next(query)) then
		self:RemoveIndexImp();
	else
		for name, value in pairs(query) do
			if(type(name) == "string") then
				value = name;
			end
			if(type(value) == "string") then
				self:RemoveIndexImp(value);
			end
		end
	end
	return self:InvokeCallback(callbackFunc, nil, true);
end

-- this is usually used for changing database settings, such as cache size and sync mode. 
-- this function is specific to store implementation. 
-- @param query: string or {sql=string, CacheSize=number, IgnoreOSCrash=bool, IgnoreAppCrash=bool, QueueSize=number, SyncMode=boolean} 
-- query.QueueSize: set the message queue size for both the calling thread and db processor thread. 
-- query.SyncMode: default to false. if true, table api is will pause until data arrives.
function SqliteStore:exec(query, callbackFunc)
	self:CommandTick("exec");
	local err, data, _;
	local sql;
	if(type(query) == "string") then
		sql = query;
	elseif(type(query) == "table") then
		sql = query.sql;
		if(query.CacheSize) then
			self:FlushAll();
			_, err = self._db:exec("PRAGMA cache_size="..tostring(query.CacheSize)); -- skip app crash
			LOG.std(nil, "debug", "SqliteStore", "db: %s set cache_size= %d", self.kFileName, query.CacheSize);
		end
		if(query.checkpoint) then
			self:FlushAll();
			local nBeginTime = ParaGlobal.timeGetTime();
			_, err = self._db:exec("PRAGMA wal_checkpoint;"); 
			local nDuration = ParaGlobal.timeGetTime() - nBeginTime;
			LOG.std(nil, "debug", "SqliteStore", "db: %s CHECKPOINT takes %dms", self.kFileName, nDuration);
		end
		if(query.journelMode == "WAL") then
			-- https://www.sqlite.org/pragma.html#pragma_wal_checkpoint
			self:FlushAll();
			_, err = self._db:exec("PRAGMA journal_mode=WAL;"); -- ignore durability of trasactions. 
			_, err = self._db:exec("PRAGMA synchronous=NORMAL;"); 
			-- auto checkpoint off?
			-- _, err = self._db:exec("PRAGMA wal_autocheckpoint=0;"); 
			-- _, err = self._db:exec("PRAGMA wal_autocheckpoint=1000;"); 
			
			-- Do checkpoint every 60 seconds or 1000 pages?
			-- _, err = self._db:exec("PRAGMA wal_checkpoint;"); 

			LOG.std(nil, "debug", "SqliteStore", "db: %s PRAGMA journal_mode WAL", self.kFileName);
		else
			if(query.IgnoreOSCrash~=nil) then
				self:FlushAll();
				_, err = self._db:exec("PRAGMA synchronous="..(query.IgnoreOSCrash and "OFF" or "ON")); -- skip OS crash 
				LOG.std(nil, "debug", "SqliteStore", "db: %s PRAGMA synchronous", self.kFileName);
			end
			if(query.IgnoreAppCrash~=nil) then
				self:FlushAll();
				_, err = self._db:exec("PRAGMA journal_mode="..(query.IgnoreAppCrash and "MEMORY" or "PERSIST")); -- skip app crash
				LOG.std(nil, "debug", "SqliteStore", "db: %s PRAGMA journal_mode", self.kFileName);
			end
		end
		if(query.QueueSize) then
			__rts__:SetMsgQueueSize(query.QueueSize);
			LOG.std(nil, "system", "NPL", "NPL input queue size of thread (%s) is changed to %d", __rts__:GetName(), query.QueueSize);
		end
	end
	if(sql) then
		local firstCmd = string.lower(sql:match("^%w+") or "");
		firstCmd = string.lower(firstCmd);
		if(firstCmd == "select" or firstCmd == "explain") then
			data = {};
			for row in self._db:rows(sql) do
				data[#data+1] = row;
			end
		elseif(firstCmd == "insert") then
			_, err = self._db:exec(sql);
			data = self._db:last_insert_rowid();
		else
			_, err = self._db:exec(sql);
		end
	end
	return self:InvokeCallback(callbackFunc, err, data);
end

function SqliteStore:InjectID(data, id)
	if(data) then
		data._id = id;
	end
	return data;
end

-- convert right to typeLeft, where typeLeft is "number" or "string"
local function convertToType(typeLeft, right)
	if(typeLeft ~= type(right) and right) then
		if(typeLeft == "number") then
			right = tonumber(right) or -1;
		else
			right = tostring(right);
		end
	end
	return right;
end

-- return true if equal. currently only number and string type can use ranged compare 
local function compareValue_(left, right, greaterthan, lessthan)
	if(not greaterthan and not lessthan) then
		return left == right;
	else
		local typeLeft = type(left);
		if((typeLeft=="number" or typeLeft=="string")) then
			return (not greaterthan or left>convertToType(typeLeft, greaterthan)) and 
			       (not lessthan or left<convertToType(typeLeft, lessthan));
		else
			return false; -- can not be compared
		end
	end
end

-- transform the input query into select one query that return only one result. 
-- @return the input query
function SqliteStore:makeSelectOneQuery(query)
	if(query and not query._id)then
		local bFoundIndex;
		for name, item in pairs(query) do
			if(type(name) == "string" and name~="_unset")then
				if(type(item) == "table") then
					item.limit = item.limit or 1;
				else
					query[name] = {item, limit = 1};
				end
				bFoundIndex = true;
				break;
			end
		end
		if(not bFoundIndex) then
			query._id = { limit=1 };
		end
	end
	return query;
end

-- only the limit and offset is honored, all others are ignored. 
function SqliteStore:getQueryLimit(query)
	local limit, offset;
	for name, item in pairs(query) do
		if(type(item) == "table") then
			if(type(name) == "number")then
				if(type(item[2]) == "table") then
					limit = limit or item[2].limit;
					offset = offset or item[2].offset;
				end
			else
				limit = limit or item.limit;
				offset = offset or item.offset;
			end
		end
	end
	return limit, offset;
end

-- check additional fields in query's array fields. 
-- return row if row matched all query field, otherwise it will return nil.
function SqliteStore:filterRowByQuery(row, query)
	if(row and query) then
		for i, item in ipairs(query) do
			if(type(item) == "table")then
				local key = item[1];
				local value = item[2];
				if(key) then
					if(type(value) == "table") then
						local greaterthan, lessthan;
						greaterthan = value["gt"];
						lessthan = value["lt"];
						if(compareValue_(row[key], value["eq"], greaterthan, lessthan)) then
						else
							return;
						end
					elseif(row[key] ~= value) then
						return;
					end
				end
			end
		end
	end
	return row;
end
-- @param value: any number or string value. or table { gt = value, lt=value, limit = number, offset|skip=number }.
-- value.gt: greater than this value, result in accending order
-- value.lt: less than this value
-- value.limit: max number of rows to return, default to 20. if there are duplicated items, it may exceed this number. 
-- value.offset|skip: default to 0.
-- return all ids as commar separated string
function SqliteStore:getIds(value)
	if(type(value) == "table") then
		local greaterthan, lessthan;
		greaterthan = value["gt"];
		lessthan = value["lt"];
		local limit = value.limit or 20;
		local offset = value.offset or value.skip or 0;

		if(greaterthan) then
			greaterthan = tostring(greaterthan);
			self.select_gt_stat = self.select_gt_stat or self._db:prepare([[SELECT id FROM Collection WHERE id>? ORDER BY id LIMIT ?,?]]);
			if(self.select_gt_stat) then
				self.select_gt_stat:bind(greaterthan, offset, limit);
				self.select_gt_stat:reset();
				local cid;
				for row in self.select_gt_stat:rows() do
					cid = cid and (cid .. "," .. row.id) or tostring(row.id);
				end
				return cid;
			else
				LOG.std(nil, "error", "IndexTable", "failed to create select statement");
			end
		else
			self.select_any_stat = self.select_any_stat or self._db:prepare([[SELECT id FROM Collection ORDER BY id LIMIT ?,?]]);
			if(self.select_any_stat) then
				self.select_any_stat:bind(offset, limit);
				self.select_any_stat:reset();
				local cid;
				for row in self.select_any_stat:rows() do
					cid = cid and (cid .. "," .. row.id) or tostring(row.id);
				end
				return cid;
			else
				LOG.std(nil, "error", "IndexTable", "failed to create select statement");
			end
			-- LOG.std(nil, "error", "IndexTable", "unknown operator %s", tostring(operator));
		end
	else
		return tostring(value);
	end
end

-- if return nil, it means no index is found, so a table scan may be used later
-- return nil or {} or array of row ids. 
function SqliteStore:findRowIds(query, bAutoCreateIndex)
	local final_set = IdSet:new();
	local hasIndex;
	if(query._id) then
		if(type(query._id) == "table") then
			hasIndex = true;
			local ids = self:getIds(query._id);
			final_set:union(ids);
		else
			return {query._id};
		end
	end
	
	-- if no index, return nil to inform brutal force search
	for name, value in pairs(query) do
		if(type(name)=="string" and name~="_unset") then
			local indexTable = self:GetIndex(name, bAutoCreateIndex);
			if(indexTable) then
				hasIndex = true;
				local ids = indexTable:getIds(value);
				final_set:intersect(ids);
			end
		end
	end
	return hasIndex and final_set:getArray();
end

-- try to execute query with indices. 
-- return rows that satisfied one or more indexed query fields. 
-- Please note: non-indexed fields are not verified and caller must filter them afterwards. 
-- In case of multiple query fields, we will return rows with the intersection of ids.
-- if no indexed field is found, we will return nil and the caller should fallback to brutal force linear search
-- return array of rows {} or nil.
function SqliteStore:findRowsViaIndex(query, bAutoCreateIndex)
	if(type(query._id) == "number") then
		local data = self:findCollectionRow(query);
		return {data};
	else
		local ids = self:findRowIds(query, bAutoCreateIndex)
		if(ids) then
			if(#ids>0) then
				local sIds = table.concat(ids, ",");
				local rows = {};
				for row in self._db:rows("SELECT * FROM Collection WHERE id IN ("..sIds..")") do
					local row = self:InjectID(NPL.LoadTableFromString(row.value) or {}, row.id);
					row = self:filterRowByQuery(row, query);
					if(row) then
						rows[#rows+1] = row;
					end
				end
				-- sort result in the same order of ids
				if(#rows == #ids) then
					local count = #rows;
					for i = 1, count do
						if(rows[i]._id ~= ids[i]) then
							local tid = ids[i];
							for j = i+1, count do
								if(rows[j]._id == tid) then
									rows[i], rows[j] = rows[j], rows[i];
								end
							end
						end
					end
				end
				return rows;
			else
				return ids; -- this is empty {}
			end
		end
	end
end

-- find by linear full table scan
function SqliteStore:findRowsViaTableScan(query)
	local rows = {};
	local name = self.name;
	self.sel_all_stat = self.sel_all_stat or self._db:prepare([[SELECT * FROM Collection]]);
	if(self.sel_all_stat) then
		self.sel_all_stat:reset();
		if(not next(query)) then
			for row in self.sel_all_stat:rows() do
				local obj = NPL.LoadTableFromString(row.value) or {};
				rows[#rows+1] = self:InjectID(obj, row.id);		
			end
		else
			local limit, offset = self:getQueryLimit(query)

			local matchCount = 0;
			for row in self.sel_all_stat:rows() do
				local obj = NPL.LoadTableFromString(row.value) or {};
				obj = self:filterRowByQuery(obj, query);
				if(obj) then
					local bMatched = true;
					for name, value in pairs(query) do
						if(type(name)=="string" and obj[name] ~= value) then
							bMatched = false;
						end
					end
					if(bMatched) then
						matchCount = matchCount + 1;
						if(not offset or matchCount > offset) then
							if(not limit or #rows < limit) then
								rows[#rows+1] = self:InjectID(obj, row.id);		
							else
								break;
							end
						end
					end
				end
			end
		end
	else
		LOG.std(nil, "error", "SqliteStore",  "failed to create select all statement");
	end
	return rows;
end


-- virtual: 
-- counting the number of rows in a query. this will always do a table scan using an index. 
-- avoiding calling this function for big table. 
-- @param callbackFunc: function(err, count) end
function SqliteStore:count(query, callbackFunc)
	query = query or {};
	local err, count;
	
	local indexTable, queryValue = self:FindIndexFromQuery(query, true)
	if(queryValue) then
		local id;
		if(indexTable) then
			-- support multiple query fields
			if(self:FindIndexFromQuery(query, true, 1)) then
				-- this one should be avoided as much as possible and use single ids instead. 
				local ids = self:findRowIds(query, true);
				if(ids) then
					count = #ids;
				end
			else
				count = indexTable:getCount(queryValue);
			end
		else
			id = queryValue;
			count = self:getCollectionRow(id) and 1 or 0;
		end
	else
		local row, err = self._db:first_row("SELECT count(*) as count FROM Collection");
		if(row) then
			count = row.count;
		end
	end
	return self:InvokeCallback(callbackFunc, err, count or 0);
end

-- find will not automatically create index on query fields. 
-- Use findOne for fast index-based search. It simply does a raw search.
-- @param query: if nil or {}, it will return all the rows
function SqliteStore:find(query, callbackFunc)
	query = query or {};
	local err, data;
	local rows = self:findRowsViaIndex(query, true) or 
				self:findRowsViaTableScan(query);
	return self:InvokeCallback(callbackFunc, err, rows);
end

-- virtual: 
-- Replaces a single document within the collection based on the query filter.
-- it will not auto create index if key does not exist.
-- @param query: key, value pair table, such as {name="abc"}. 
-- @param replacement: wholistic fields to be replace any existing doc. 
function SqliteStore:replaceOne(query, replacement, callbackFunc)
	self:CommandTick("update");
	replacement = replacement or query;
	local err, data;
	query = self:makeSelectOneQuery(query);
	local id = self:FindRowId(query, true);
	if(id) then
		if(replacement._id and replacement._id~=id) then
			err = "_id not match";
		else
			replacement._id = nil;
			data = self:getCollectionRow(id);
			data = self:filterRowByQuery(data, query);
			if(data) then
				self:Begin();
				-- just in case some index value is changed, update index first
				for name, indexTable in pairs(self.indexes) do
					if(indexTable:GetName() == name) then
						if(replacement[name] == nil and data[name]~=nil) then
							indexTable:removeIndex(data, id);
						elseif(replacement[name]~=nil) then
							indexTable:updateIndex(id, replacement, data)
						end
					end
				end
				-- replace document completely
				data = replacement;

				self.update_stat = self.update_stat or self._db:prepare([[UPDATE Collection Set value=? Where id=?]]);
				if(self.update_stat) then
					local data_str = commonlib.serialize_compact(data);
					self.update_stat:bind(data_str, id);
					self.update_stat:exec();
				else
					LOG.std(nil, "error", "SqliteStore",  "failed to create update statement");
				end

				self:End();
			end	
		end
	end
	return self:InvokeCallback(callbackFunc, err, self:InjectID(data, id));
end

-- update one will not create index
function SqliteStore:updateOne(query, update, callbackFunc)
	self:CommandTick("update");
	update = update or query;
	local _unset = update and update._unset;
	if(_unset) then
		update._unset = nil;
	end
	local err, data;
	query = self:makeSelectOneQuery(query);
	local id = self:FindRowId(query, true);
	if(id) then
		update._id = nil;
		data = self:getCollectionRow(id);
		
		if(not data) then
			-- remove index, since row does not exist. This should only happen for corrupted index table.
			if(not query._id) then
				for name, value in pairs(query) do
					if(type(name)=="string") then
						local indexTable = self:GetIndex(name, false);
						if(indexTable) then
							indexTable:removeIndex(query, id);
							LOG.std(nil, "warn", "SqliteStore",  "corrupted index: remove index for non-exist row %d", id);
						end
					end
				end
			end
		end

		data = self:filterRowByQuery(data, query);
		if(data) then
			self:Begin();
			-- just in case some index value is changed, update index first
			for name, indexTable in pairs(self.indexes) do
				if(indexTable:GetName() == name) then
					indexTable:updateIndex(id, update, data)
				end
			end
			-- update row
			for key, value in pairs(update) do
				data[key] = value	
			end

			-- unset rows if requested by user
			if(_unset) then
				for name, value in pairs(_unset) do
					name = (type(name) == "number") and value or name;
					local indexTable = self.indexes[name];
					if(indexTable) then
						indexTable:removeIndex(data, id);
					end
					data[name] = nil;
				end
			end

			self.update_stat = self.update_stat or self._db:prepare([[UPDATE Collection Set value=? Where id=?]]);
			if(self.update_stat) then
				local data_str = commonlib.serialize_compact(data);
				self.update_stat:bind(data_str, id);
				self.update_stat:exec();
			else
				LOG.std(nil, "error", "SqliteStore",  "failed to create update statement");
			end

			self:End();
		end
	end
	return self:InvokeCallback(callbackFunc, err, self:InjectID(data, id));
end

local query_by_id = {_id = nil};
function SqliteStore:insertOne(query, update, callbackFunc)
	if(not update) then
		return;
	end
	-- if row id is found, we will need to get row id and turn this query into update
	if(query and next(query)) then
		local ids = self:findRowIds(query, true);
		if(ids and #ids>0) then
			query_by_id._id = ids[1];
			return self:updateOne(query_by_id, update, callbackFunc);
		end
	end
	
	self:CommandTick("insert");
	local err, data;
	self.insert_stat = self.insert_stat or self._db:prepare([[INSERT INTO Collection (value) VALUES (?)]]);
	
	if(self.insert_stat) then
		self:Begin();
		local query_str = commonlib.serialize_compact(update);
		self.insert_stat:bind(query_str);
		self.insert_stat:exec();
		-- get row id. 
		id = self._db:last_insert_rowid();

		data = update;
		-- update all index
		for name, indexTable in pairs(self.indexes) do
			if(indexTable:GetName() == name) then
				indexTable:addIndex(update, id);
			end
		end
		self:End();
	else
		LOG.std(nil, "warn", "SqliteStore", "failed to create insert statement");
	end
	return self:InvokeCallback(callbackFunc, err, self:InjectID(data, id));
end

function SqliteStore:delete(query, callbackFunc)
	local count = 0;
	local deleteSucceed = true;
	local err;
	local function callback_(err, cnt)
		if(cnt ~= nil) then
			count = count + 1;
		else
			deleteSucceed = false;
		end
	end
	query = self:makeSelectOneQuery(query);
	while(deleteSucceed) do
		self:deleteOne(query, callback_)
	end
	return self:InvokeCallback(callbackFunc, err, count);
end

function SqliteStore:deleteOne(query, callbackFunc)
	self:CommandTick("delete");
	query = query or {};
	local _, err, data;
	query = self:makeSelectOneQuery(query);
	local id = self:FindRowId(query, true);
	if(id) then
		local obj = self:getCollectionRow(id);
		obj = self:filterRowByQuery(obj, query);
		
		if(obj) then
			self:Begin();
			self.del_stat = self.del_stat or self._db:prepare([[DELETE FROM Collection WHERE id=?]]);
			if(self.del_stat) then
				self.del_stat:bind(id);
				_, err = self.del_stat:exec();
			else
				LOG.std(nil, "error", "SqliteStore", "failed to create delete statement");
			end
			
			if(not err) then
				data = 1;
			end

			-- delete all indexes
			for name, indexTable in pairs(self.indexes) do
				if(indexTable:GetName() == name) then
					indexTable:removeIndex(obj, id);
				end
			end
			
			self:End();
		else
			err = "not_found";
		end
	end
	return self:InvokeCallback(callbackFunc, err, data);
end

-- virtual: 
function SqliteStore:flush(query, callbackFunc)
	local res = self:FlushAll();
	return self:InvokeCallback(callbackFunc, err, res);
end

-- after issuing an really important group of commands, and you want to ensure that 
-- these commands are actually successful like a transaction, the client can issue a waitflush 
-- command to check if the previous commands are successful. Please note that waitflush command 
-- may take up to 3 seconds or Store.AutoFlushInterval to return. 
-- @param callbackFunc: function(err, fFlushed) end
function SqliteStore:waitflush(query, callbackFunc)
	if(callbackFunc) then
		self.waitflush_queue[#(self.waitflush_queue) + 1] = callbackFunc;
	end
end

-- flush all transactions to database. 
-- return true if committed. 
function SqliteStore:FlushAll()
	if(self._db and self.queued_transaction_count > 0 and self.transaction_depth_ == 0) then
		-- LOG.std(nil, "debug", "SqliteStore", "flushing %d queued database transactions :%s", self.queued_transaction_count, self.kFileName);
		self.queued_transaction_count = 0;
		-- flush now
		local _, err = self._db:exec("END");
		self:NotifyEndTransaction(err);
		return true;
	else
		return (self.queued_transaction_count or 0) == 0;
	end
end

function SqliteStore:NotifyEndTransaction(err)
	local data = not err;
	if (#(self.waitflush_queue) > 0) then
		for i, callbackFunc in ipairs(self.waitflush_queue) do
			self:InvokeCallback(callbackFunc, err, data);
		end
		self.waitflush_queue = {};
	end
end

-- begin transaction: it emulates nested transactions. 
function SqliteStore:Begin(label, mode)
	self.transaction_depth_ = (self.transaction_depth_ or 0) + 1;
	
	if(self.transaction_depth_ == 1) then
		if(self.EnableLazyWriting) then
			if(self.queued_transaction_count == 0) then
				self._db:exec("BEGIN");
			end	
		else
			self._db:exec("BEGIN");
		end
	end	
	return true;
end

-- end transaction
-- @param bRollback: if true, it will rollback on last root pair. 
-- @param bForceFlush: default to nil. if true, we will flush to database immediate when nested transaction is 0.
function SqliteStore:End(bRollback, bForceFlush)
	if(bRollback) then
		self.needs_rollback_ = true;
	end
	if(bForceFlush) then
		self.bForceFlush = true;
	end

	if(self.transaction_depth_ == 0) then
		LOG.std(nil, "warn", "SqliteStore", "unbalanced transactions");
	end
	self.transaction_depth_ = self.transaction_depth_-1;
	local _, err;
	if(self.transaction_depth_ == 0) then
		if(not self.needs_rollback_) then
			-- we are closing the last transaction, commit provided rollback has not been called.
			if(self.EnableLazyWriting) then
				self.queued_transaction_count = self.queued_transaction_count + 1;
				if(self.bForceFlush) then
					self.bForceFlush = false;
					if(self:FlushAll()) then
						LOG.std(nil, "debug", "SqliteStore", "force flush called for %s", self.kFileName);
						self.timer:Change();
					end
				else
					if(not self.timer:IsEnabled()) then
						-- The logics is changed: we will start the timer at fixed interval.
						-- self.timer:Change(self.AutoFlushInterval, nil);
						self.timer:Change(self.AutoFlushInterval, self.AutoFlushInterval);
					end	
				end
			else
				_,err = self._db:exec("END");
				self:NotifyEndTransaction(err);
			end
			if(not self.checkpoint_timer:IsEnabled()) then
				self.checkpoint_timer:Change(self.AutoCheckPointInterval, self.AutoCheckPointInterval);
			end	
		else
			-- Rollback is necessary, 
			_,err = self._db:exec("ROLLBACK");
			LOG.std(nil, "debug", "SqliteStore", "rollback called for %s", self.kFileName);
		end
		self.needs_rollback_ = false;
	end
	if(not err) then
		return true;
	end
end
