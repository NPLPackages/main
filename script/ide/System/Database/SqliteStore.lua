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
local IndexTable = commonlib.gettable("System.Database.SqliteStore.IndexTable");

local SqliteStore = commonlib.inherit(commonlib.gettable("System.Database.Store"), commonlib.gettable("System.Database.SqliteStore"));
SqliteStore.kCurrentVersion = 3;

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
	self.transaction_count_ = 0
	self.transaction_labels_ = {}
	self.queued_transaction_count = 0;

	self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
		if(self:FlushAll()) then
			timer:Change();
		end
	end})
end

-- When sqlite_master table(schema) is changed, such as when new index table is created, 
-- all cached statements becomes invalid. And this function should be called to purge all statements created before.
-- Note: current prepare binding use old sqlite_prepare(), in future I may switch to  
-- sqlite_prepare_v2() which will automatically recompile all statements when schema changes, and this function would not be necessary.
function SqliteStore:ClearStatementCache()
	self.add_stat = nil;
	self.del_stat = nil;
	self.del_stat_if = nil;
	self.select_stat = nil;
	self.sel_row_stat = nil;
	self.sel_all_stat = nil;
	self.update_stat = nil;

	for name, indexTable in pairs(self.indexes) do
		indexTable:ClearStatementCache();
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
		if(self.IgnoreOSCrash) then
			self:exec({IgnoreOSCrash = true});
		end
		if(self.IgnoreAppCrash) then
			self:exec({IgnoreAppCrash = true});
		end
		if(self.CacheSize and self.CacheSize~=-2000) then
			self:exec({CacheSize = self.CacheSize});
		end
		LOG.std(nil, "info", "SqliteStore", "collection %s opened", self:GetCollection():GetName());
	end
	return self;
end

function SqliteStore:Close()
	if(self._db) then
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
				LOG.std(nil, "info", "SqliteStore", "%s is is removed from db.", name);
			end
		end
	self:End(); -- commit changes
end

function SqliteStore:FetchIndexes()
	local stmt = assert(self._db:prepare([[SELECT * FROM Indexes]]));
	for row in stmt:rows() do
		if(row.name) then
			self.indexes[row.name] = IndexTable:new(row):init(row.name, self);
		end
	end
	stmt:close();
end

-- return SqliteIndexTable object or nil. 
function SqliteStore:GetIndex(name, bCreateIfNotExist)
	local indexTable = self.indexes[name];
	if(not indexTable) then
		if(bCreateIfNotExist and name~="_id") then
			indexTable = IndexTable:new():init(name, self);
			indexTable:CreateTable();
			self.indexes[name] = indexTable;
		end
	end
	return indexTable;
end

-- get index Table from query
-- @param bAutoCreateIndex: if true, index is automatically created.
-- @return:  indexTable, value: indexTable is nil if there is no index found or _id is found in query. 
function SqliteStore:GetIndexFromQuery(query, bAutoCreateIndex)
	local id = query._id;
	if(id) then
		return nil, id;
	else
		for name, value in pairs(query) do
			if(value and value~="") then
				local indexTable = self:GetIndex(name, bAutoCreateIndex);
				if(indexTable) then
					return indexTable, value;
				end
			end
		end
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
				value = NPL.LoadTableFromString(row.value);
			end
			return value;
		else
			LOG.std(nil, "error", "SqliteStore", "failed to create select statement");
		end
	end
end

-- internally it will use just a single statement to search both index and collection table.
-- so it is faster than using two statements for each table.
-- return nil or the row object. _id is injected.
function SqliteStore:findCollectionRow(query, bAutoIndex)
	local indexTable, value = self:GetIndexFromQuery(query, bAutoIndex);
	local err, data;
	if(value) then
		if(indexTable) then
			local row = indexTable:getRow(value);
			if(row) then
				return self:InjectID(NPL.LoadTableFromString(row.value), row.id);
			end
		else
			local id = value;
			return self:InjectID(self:getCollectionRow(id), id);
		end
	end
end

-- auto indexed
function SqliteStore:findOne(query, callbackFunc)
	self:AddStat("select", 1);

	local err, data;
	if(query) then
		data = self:findCollectionRow(query, true);
		--local id = self:GetRowId(query, true);
		--if(id) then
			--data = self:InjectID(self:getCollectionRow(id), id);
		--end
	end
	return self:InvokeCallback(callbackFunc, err, data);
end

-- this is usually used for changing database settings, such as cache size and sync mode. 
-- this function is specific to store implementation. 
-- @param query: string or {sql=string, CacheSize=number, IgnoreOSCrash=bool, IgnoreAppCrash=bool} 
function SqliteStore:exec(query, callbackFunc)
	self:AddStat("exec", 1);
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
	if(sql) then
		local firstCmd = string.lower(sql:match("^%w+") or "");
		if(firstCmd == "select") then
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

-- find will not automatically create index on query fields. 
-- Use findOne for fast index-based search. It simply does a raw search.
-- @param query: if nil or {}, it will return all the rows
function SqliteStore:find(query, callbackFunc)
	query = query or {};
	local err, data;
	local id = self:GetRowId(query, false);
	if(id ~= nil) then
		data = self:InjectID(self:getCollectionRow(id), id);
		return self:InvokeCallback(callbackFunc, err, {data});
	else
		-- full linear search. this is slow!!!
		local rows = {};
		local name = self.name;
		self.sel_all_stat = self.sel_all_stat or self._db:prepare([[SELECT * FROM Collection]]);
		if(self.sel_all_stat) then
			self.sel_all_stat:reset();
			local obj;
			for row in self.sel_all_stat:rows() do
				obj = NPL.LoadTableFromString(row.value) or {};
				if(obj) then
					if(commonlib.partialcompare(obj, query)) then
						rows[#rows+1] = self:InjectID(obj, row.id);
					end
				end
			end
			--self.sel_all_stat:close();
			--self.sel_all_stat = nil;
		else
			LOG.std(nil, "error", "SqliteStore",  "failed to create select all statement");
		end
		return self:InvokeCallback(callbackFunc, err, rows);
	end
end

function SqliteStore:deleteOne(query, callbackFunc)
	self:AddStat("select", 1);
end

-- get just one row id from query string.
-- @param bAutoCreateIndex: if true, index is automatically created.
-- @return nil if there is no index. false if the record does not exist in collection. otherwise return the row id.
function SqliteStore:GetRowId(query, bAutoCreateIndex)
	local id = query._id;
	if(id) then
		return id;
	else
		for name, value in pairs(query) do
			if(value and value~="") then
				local indexTable = self:GetIndex(name, bAutoCreateIndex);
				if(indexTable) then
					local id = indexTable:getId(value);
					if(id) then
						return id;
					end
					return false;
				end
			end
		end
	end
end

function SqliteStore:updateOne(query, update, callbackFunc)
	self:AddStat("update", 1);
	update = update or query;
	local err, data;
	local id = self:GetRowId(query, false);
	if(id) then
		update._id = nil;
		data = self:getCollectionRow(id);
		if(data) then
			self:Begin();
			-- just in case some index value is changed, update index first
			for name, indexTable in pairs(self.indexes) do
				local oldIndexValue = data[name];
				local newIndexValue = update[name];
				if(newIndexValue~= oldIndexValue and newIndexValue and newIndexValue~="") then
					if(oldIndexValue and oldIndexValue~="") then
						indexTable:removeIndex(oldIndexValue, id);
					end
					indexTable:addIndex(newIndexValue, id);
				end
			end

			-- update row
			commonlib.partialcopy(data, update);
			self.update_stat = self.update_stat or self._db:prepare([[UPDATE Collection Set value=? Where id=?]]);
			if(self.update_stat) then
				local data_str = commonlib.serialize_compact(data);
				self.update_stat:bind(data_str, id);
				self.update_stat:exec();
			else
				LOG.std(nil, "error", "SqliteStore",  "failed to create update statement");
			end

			self:End();
		else
			-- remove index, since row does not exist. This should only happen for corrupted index table.
			if(not query._id) then
				for name, value in pairs(query) do
					local keyValue = query[name];
					if(keyValue and keyValue~="") then
						local indexTable = self:GetIndex(name, false);
						if(indexTable) then
							indexTable:removeIndex(keyValue, id);
							break;
						end
					end
				end
			end
		end
	end
	return self:InvokeCallback(callbackFunc, err, self:InjectID(data, id));
end

local query_by_id = {_id = id};
function SqliteStore:insertOne(query, callbackFunc)
	-- if row id is found, we will need to get row id and turn this query into update
	local id = self:GetRowId(query, false);
	if(id) then
		query_by_id._id = id;
		return self:updateOne(query_by_id, query, callbackFunc);
	end
	
	self:AddStat("insert", 1);
	local err, data;
	self.insert_stat = self.insert_stat or self._db:prepare([[INSERT INTO Collection (value) VALUES (?)]]);
	
	if(self.insert_stat) then
		self:Begin();
		local query_str = commonlib.serialize_compact(query);
		self.insert_stat:bind(query_str);
		self.insert_stat:exec();
		-- get row id. 
		id = self._db:last_insert_rowid();
		data = query;
		-- update all index
		for name, indexTable in pairs(self.indexes) do
			local keyValue = query[name];
			if(keyValue and keyValue~="") then
				indexTable:addIndex(keyValue, id);
			end
		end
		self:End();
	else
		LOG.std(nil, "warn", "SqliteStore", "failed to create insert statement");
	end
	return self:InvokeCallback(callbackFunc, err, self:InjectID(data, id));
end

function SqliteStore:deleteOne(query, callbackFunc)
	self:AddStat("delete", 1);
	local _, err, data;
	local id = self:GetRowId(query, false);
	if(id) then
		local obj = self:getCollectionRow(id);
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
				local keyValue = obj[name];
				if(keyValue and keyValue~="") then
					indexTable:removeIndex(keyValue, id);
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

-- flush all transactions to database. 
-- return true if committed. 
function SqliteStore:FlushAll()
	if(self._db and self.queued_transaction_count > 0 and self.transaction_count_ == 0) then
		LOG.std(nil, "debug", "SqliteStore", "flushing %d queued database transactions :%s", self.queued_transaction_count, self.kFileName);
		self.queued_transaction_count = 0;
		-- flush now
		self._db:exec("END")
		return true;
	end
end

-- begin transaction: it emulates nested transactions. 
function SqliteStore:Begin(label, mode)
	self.transaction_count_ = (self.transaction_count_ or 0) + 1;
	
	if(self.transaction_count_ == 1) then
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

	if(self.transaction_count_ == 0) then
		LOG.std(nil, "warn", "SqliteStore", "unbalanced transactions");
	end
	self.transaction_count_ = self.transaction_count_-1;
	local _, err;
	if(self.transaction_count_ == 0) then
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
