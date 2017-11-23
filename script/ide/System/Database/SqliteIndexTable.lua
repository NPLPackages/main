--[[
Title: Index table for sqlitestore
Author(s): LiXizhi, 
Date: 2016/5/11
Desc: mostly for index-intersection, this is very different from CompoundIndex.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Database/SqliteIndexTable.lua");
local IndexTable = commonlib.gettable("System.Database.SqliteStore.IndexTable");
------------------------------------------------------------
]]
local IndexTable = commonlib.inherit(nil, commonlib.gettable("System.Database.SqliteStore.IndexTable"));
local tostring = tostring;
local kIndexTableColumns = [[
	(name BLOB UNIQUE PRIMARY KEY,
	cid TEXT)]];

function IndexTable:ctor()
	self.names = {};
	self.statements = {};
end

function IndexTable:init(name, parent)
	self.name = name;
	self:AddKeyName(name);
	self.parent = parent;
	return self;
end

function IndexTable:GetName()
	return self.name;
end

-- get all key names {name=true, ...}, where this index can be used for query
function IndexTable:GetKeyNames()
	return self.names;
end

function IndexTable:AddKeyName(name)
	self.names[name] = true;
end

-- return true if this index support query for the given key name
function IndexTable:HasKeyName(name)
	return name and self.names[name];
end

-- check if this index fully contains another index. 
function IndexTable:isSuperSetOf(otherIndex)
	for name, _ in pairs(otherIndex:GetKeyNames()) do
		if(not self:HasKeyName(name)) then
			return false;
		end
	end
	return true;
end

function IndexTable:GetDB()
	return self.parent._db;
end

function IndexTable:GetTableName()
	if(not self.tableName) then
		-- TODO: normalize name?
		self.tableName = self.name.."Index";
	end
	return self.tableName;
end

function IndexTable:CloseSQLStatement(name)
	if(self[name]) then
		self[name]:close();
		self[name] = nil;
	end
end

-- get cached sql statement
function IndexTable:GetStatement(sql)
	local stat = self.statements[sql];
	if(not stat) then
		local err;
		stat, err = self:GetDB():prepare(sql);
		if(not stat and err) then
			LOG.std(nil, "error", "SqliteStore", "error for sql statement %s, reason: %s", sql, tostring(err));
		end
		self.statements[sql] = stat;
	end
	return stat;
end

-- When sqlite_master table(schema) is changed, such as when new index table is created, 
-- all cached statements becomes invalid. And this function should be called to purge all statements created before.
function IndexTable:ClearStatementCache()
	self:CloseSQLStatement("add_stat");
	self:CloseSQLStatement("del_stat");
	self:CloseSQLStatement("select_stat");
	self:CloseSQLStatement("select_gt_stat");
	self:CloseSQLStatement("select_ids_stat");
	self:CloseSQLStatement("sel_all_stat");
	self:CloseSQLStatement("update_stat");

	if(next(self.statements)) then
		for name, stat in pairs(self.statements) do
			stat:close();
		end
		self.statements = {};
	end
end

-- get first matching row id
-- @param value: value of the key to get
-- @return id: where id is the collection id number or nil if not found
function IndexTable:getId(value)
	local ids = self:getIds(value);
	if(ids) then
		return tonumber(ids:match("^%d+"));
	end
end

-- get total key count. 
-- @param value: value of the key to get
function IndexTable:getCount(value)
	local ids = self:getIds(value);
	if(ids) then
		local count = 1;
		for _ in ids:gmatch(",") do
			count = count + 1;
		end
		return count
	else
		return 0;
	end
end

-- @param value: any number or string value. or table { [1]=value, gt = value, lt=value, limit = number, offset|skip=number }.
-- value.gt: greater than this value, result in accending order
-- value.lt: less than this value
-- value[1]: equal to this value
-- value.limit: max number of rows to return, default to 20. if there are duplicated items, it may exceed this number. 
-- value.offset|skip: default to 0.
-- return all ids as commar separated string
function IndexTable:getIds(value)
	if(value) then
		local greaterthan, lessthan, eq, limit, offset;
		if(type(value) == "table") then
			greaterthan = value["gt"];
			lessthan = value["lt"];
			eq = value[1];
			limit = value.limit or 20;
			offset = value.offset or value.skip or 0;

			if(not greaterthan and not lessthan and not eq) then
				LOG.std(nil, "error", "IndexTable", "operator not found");
				return;
			end
		else
			eq = value;
		end
		
		if(eq~=nil and not greaterthan and not lessthan) then
			self.select_stat = self.select_stat or self:GetDB():prepare([[SELECT cid FROM ]]..self:GetTableName()..[[ WHERE name=?]]);
			if(self.select_stat) then
				self.select_stat:bind(eq);
				self.select_stat:reset();
				local row = self.select_stat:first_row();
				if(row) then
					return row.cid;
				end
			else
				LOG.std(nil, "error", "IndexTable", "failed to create select statement");
			end
		elseif(greaterthan) then
			
			if(not self.select_gt_stat) then
				self.select_gt_stat = self:GetDB():prepare([[SELECT cid FROM ]]..self:GetTableName()..[[ WHERE name>? ORDER BY name ASC LIMIT ?,?]]);
			end
			
			if(self.select_gt_stat) then
				self.select_gt_stat:bind(greaterthan, offset, limit);
				self.select_gt_stat:reset();
				local cid;
				for row in self.select_gt_stat:rows() do
					cid = cid and (cid .. "," .. row.cid) or tostring(row.cid);
				end
				return cid;
			else
				LOG.std(nil, "error", "IndexTable", "failed to create select statement");
			end
		else
			LOG.std(nil, "error", "IndexTable", "unknown operator %s", tostring(operator));
		end
	end
end

-- @param cid: collection id
-- @param newRow: can be partial row containing the changed value
-- @param oldRow: can be partial row containing the old value
function IndexTable:updateIndex(cid, newRow, oldRow)
	if(newRow) then
		local newIndexValue = newRow[self.name];
		if(newIndexValue~=nil) then
			if(newRow and oldRow) then
				local oldIndexValue = oldRow[self.name];
				if(newIndexValue ~= oldIndexValue) then
					if(oldIndexValue~=nil) then
						self:removeIndex(oldRow, cid);
					end
					self:addIndex(newRow, cid);
				end
			else
				self:addIndex(newRow, cid);
			end
		end
	end
end

-- add index to collection row id
-- @param row: row data
-- @param cid: collection row id
function IndexTable:addIndex(row, cid)
	local value;
	if(type(row) == "table") then
		value = row[self.name];
	end
	if(value~=nil and cid) then
		cid = tostring(cid);
		local ids = self:getIds(value);
		if(not ids) then
			self.add_stat = self.add_stat or self:GetDB():prepare([[INSERT INTO ]]..self:GetTableName()..[[(name, cid) VALUES (?, ?)]]);
			self.add_stat:bind(value, cid);
			self.add_stat:exec();
		elseif(ids ~= cid and not self:hasIdInIds(cid, ids)) then
			ids = self:addIdToIds(cid, ids);
			self.update_stat = self.update_stat or self:GetDB():prepare([[UPDATE ]]..self:GetTableName()..[[  Set cid=? Where name=?]]);
			self.update_stat:bind(ids, value);
			self.update_stat:exec();
		end
	end
end

-- this will remove the index to collection db for the given keyvalue. 
-- but it does not remove the real data item in collection db.
-- @param row: table row
-- @param cid: default to nil. if not nil we will only remove when collection row id matches this one. 
function IndexTable:removeIndex(row, cid)
	local value;
	if(type(row) == "table") then
		value = row[self.name];
	end
	if(value~=nil) then
		if(cid) then
			cid = tostring(cid);
			local ids = self:getIds(value);
			if(ids) then
				if(ids == cid) then
					self:removeIndex(row);
				else
					local new_ids = self:removeIdInIds(cid, ids);
					if(new_ids ~= ids) then
						if(new_ids ~= "") then
							self.update_stat = self.update_stat or self:GetDB():prepare([[UPDATE ]]..self:GetTableName()..[[  Set cid=? Where name=?]]);
							self.update_stat:bind(new_ids, value);
							self.update_stat:exec();
						else
							self:removeIndex(row);
						end
					else
						-- no index found
					end
				end
			end
		else
			self.del_stat = self.del_stat or self:GetDB():prepare([[DELETE FROM ]]..self:GetTableName()..[[ WHERE name=?]]);
			if(self.del_stat) then
				self.del_stat:bind(value);
				self.del_stat:exec();
			else
				LOG.std(nil, "error", "IndexTable", "failed to create delete statement");
			end
		end
	end
end

-- private:
-- @param cid, ids: must be string
-- return true if cid string is in ids string.
function IndexTable:hasIdInIds(cid, ids)
	if(cid == ids) then
		return true;
	else
		-- TODO: optimize this function with C++
		ids = ","..ids..",";
		return ids:match(","..cid..",") ~= nil;
	end
end

-- private:
-- @param cid, ids: must be string
-- @return ids: new ids with cid removed
function IndexTable:removeIdInIds(cid, ids)
	if(cid == ids) then
		return "";
	else
		-- TODO: optimize this function with C++
		local tmp_ids = ","..ids..",";
		local new_ids = tmp_ids:gsub(",("..cid..",)", ",");
		if(new_ids~=tmp_ids) then
			return new_ids:gsub("^,", ""):gsub(",$", "");
		else
			return ids;
		end
	end
end

function IndexTable:addIdToIds(cid, ids)
	return ids..(","..cid)
end

-- creating index for existing rows
function IndexTable:CreateTable()
	self.parent:FlushAll();

	-- fetch all index before creating table, otherwise  we will need to call ClearStatementCache twice. 
	local indexmap = {};
	local name = self.name;
	self.parent:find({}, function(err, rows)
		if(rows) then
			for _, row in ipairs(rows) do
				if(row and row[name]) then
					local keyValue = row[name]
					if(keyValue) then
						if(not indexmap[keyValue]) then
							indexmap[keyValue] = tostring(row._id);
						else
							indexmap[keyValue] = indexmap[keyValue]..(","..tostring(row._id));
						end
					end
				end
			end
		end
	end)

	-- create table
	local stat = self:GetDB():prepare([[INSERT INTO Indexes (name, tablename) VALUES (?, ?)]]);
	stat:bind(self.name, self:GetTableName());
	stat:exec();
	stat:close();

	local sql = "CREATE TABLE IF NOT EXISTS ";
	sql = sql..self:GetTableName().." "
	sql = sql..kIndexTableColumns;
	self:GetDB():exec(sql);
	
	-- rebuild all indices
	self.parent:Begin();
	local count = 0;
	local stmt = self:GetDB():prepare([[INSERT INTO ]]..self:GetTableName()..[[ (name, cid) VALUES (?, ?)]]);
	for name, cid in pairs(indexmap) do
		stmt:bind(name, cid);
		stmt:exec();
		count = count + 1;
	end
	stmt:close();
	LOG.std(nil, "info", "SqliteStore", "index table is created for `%s` with %d records", self.name, count);
	self.parent:End();
	self.parent:FlushAll();

	-- after inserting tables, all statements shoudl be purged
	self.parent:ClearStatementCache();
end

function IndexTable:Destroy()
	self.parent:FlushAll();
	self:ClearStatementCache();

	self:GetDB():exec(format("DELETE FROM Indexes WHERE name='%s'", self.name));
	self:GetDB():exec("DROP TABLE "..self:GetTableName()); 
	-- self:GetDB():exec("DELETE FROM "..self:GetTableName());
	LOG.std(nil, "info", "SqliteStore", "index `%s` removed from %s", self.name, self.parent:GetFileName());
	self.parent:ClearStatementCache();
end