--[[
Title: Index table for sqlitestore
Author(s): LiXizhi, 
Date: 2016/5/11
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Database/SqliteIndexTable.lua");
local IndexTable = commonlib.gettable("System.Database.SqliteStore.IndexTable");
------------------------------------------------------------
]]
local IndexTable = commonlib.inherit(nil, commonlib.gettable("System.Database.SqliteStore.IndexTable"));

local kIndexTableColumns = [[
	(name TEXT UNIQUE PRIMARY KEY,
	cid INTEGER)]];

function IndexTable:ctor()
end

function IndexTable:init(name, parent)
	self.name = name;
	self.parent = parent;
	return self;
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

-- When sqlite_master table(schema) is changed, such as when new index table is created, 
-- all cached statements becomes invalid. And this function should be called to purge all statements created before.
function IndexTable:ClearStatementCache()
	self.add_stat = nil;
	self.del_stat = nil;
	self.del_stat_if = nil;
	self.sel_row_stat = nil;
	self.select_stat = nil;
	self.sel_all_stat = nil;
end

-- get collection row id
-- @param value: value of the key to get
function IndexTable:getId(value)
	if(value) then
		value = tostring(value);
		local id;
		self.select_stat = self.select_stat or self:GetDB():prepare([[SELECT * FROM ]]..self:GetTableName()..[[ WHERE name=?]]);
		if(self.select_stat) then
			self.select_stat:bind(value);
			self.select_stat:reset();
			local row = self.select_stat:first_row();
			if(row) then
				id = row.cid;
			end
		else
			LOG.std(nil, "error", "IndexTable", "failed to create select statement");
		end
		return id;
	end
end

-- return collection row
-- return {id=numner, value=string}. or nil if not exist.
function IndexTable:getRow(value)
	if(value) then
		value = tostring(value);
		self.sel_row_stat = self.sel_row_stat or self:GetDB():prepare([[SELECT * FROM Collection WHERE id IS (SELECT cid FROM ]]..self:GetTableName()..[[ WHERE name=?)]]);
		if(self.sel_row_stat) then
			self.sel_row_stat:bind(value);
			self.sel_row_stat:reset();
			return self.sel_row_stat:first_row();
		else
			LOG.std(nil, "error", "IndexTable", "failed to create select row statement");
		end
	end
end

-- this will remove the index to collection db for the given keyvalue. 
-- but it does not remove the real data item in collection db.
-- @param value: value of the key to remove
-- @param cid: default to nil. if not nil we will only remove when collection row id matches this one. 
function IndexTable:removeIndex(value, cid)
	if(value) then
		value = tostring(value);
		if(cid) then
			self.del_stat_if = self.del_stat_if or self:GetDB():prepare([[DELETE FROM ]]..self:GetTableName()..[[ WHERE name=? AND cid=?]]);
			if(self.del_stat_if) then
				self.del_stat_if:bind(value, cid);
				self.del_stat_if:exec();
			else
				LOG.std(nil, "error", "IndexTable", "failed to create delete if statement");
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

-- add index to collection row id
-- @param value: value of the key 
-- @param cid: collection row id
function IndexTable:addIndex(value, cid)
	if(value and cid) then
		value = tostring(value);
		self.add_stat = self.add_stat or self:GetDB():prepare([[INSERT INTO ]]..self:GetTableName()..[[(name, cid) VALUES (?, ?)]]);
		self.add_stat:bind(value, cid);
		self.add_stat:exec();
	end
end

-- creating index for existing rows
function IndexTable:CreateTable()
	local stat = self:GetDB():prepare([[INSERT INTO Indexes (name, tablename) VALUES (?, ?)]]);
	stat:bind(self.name, self:GetTableName());
	stat:exec();
	stat:close();

	local sql = "CREATE TABLE IF NOT EXISTS ";
	sql = sql..self:GetTableName().." "
	sql = sql..kIndexTableColumns;
	self:GetDB():exec(sql);
	
	-- rebuild all indices
	NPL.load("(gl)script/ide/System/Database/Item.lua");
	local Item = commonlib.gettable("System.Database.Item");
	local item = Item:new();
	
	local indexmap = {};
	local name = self.name;
	self.parent:find(query, function(err, rows)
		if(rows) then
			for _, obj in ipairs(rows) do
				if(obj and obj[name]) then
					local keyValue = tostring(obj[name])
					if(keyValue~="") then
						indexmap[keyValue] = row._id;
					end
				end
			end
		end
	end)

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
	self.parent:ClearStatementCache();
end