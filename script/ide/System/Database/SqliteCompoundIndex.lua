--[[
Title: CompoundIndex table for sqlitestore
Author(s): LiXizhi, 
Date: 2016/10/2
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Database/SqliteCompoundIndex.lua");
local IndexTable = commonlib.gettable("System.Database.SqliteStore.CompoundIndexTable");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Database/SqliteIndexTable.lua");
local IndexTable = commonlib.inherit(commonlib.gettable("System.Database.SqliteStore.IndexTable"), commonlib.gettable("System.Database.SqliteStore.CompoundIndexTable"));
local tostring = tostring;
local kIndexTableColumns = [[(cid INTEGER UNIQUE PRIMARY KEY, %s)]];

-- max number of sub keys supported. 
local max_subkey_count = 4;
-- default page size when finding record.
local default_limit = 20;

function IndexTable:ctor()
	-- array of {name=keyname, order=[1|-1]}
	self.subkeys = {};
end

-- @param name: such as "+key1+key2+key3", where "+key1+key2", +key1" are also added. 
function IndexTable:init(name, parent)
	self.name = name;
	
	local curName = ""; 
	for i=1, max_subkey_count do
		local order, subname;
		order, subname, name = name:match("^([%+%-])([^%+%-]+)(.*)$");
		if(subname) then
			curName = curName..order..subname;
			self:AddKeyName(curName);

			self.subkeys[#self.subkeys+1] = {name = subname, order = order == "+" and 1 or -1};
		end
		if(not name or name == "") then
			break;
		end
	end

	self.parent = parent;
	return self;
end

function IndexTable:GetTableName()
	if(not self.tableName) then
		self.tableName = self.name:gsub("%+", "_a_"):gsub("%-", "_d_").."Index";
	end
	return self.tableName;
end

-- @param value: any number or string value. or table {value1, value2,  gt = value, lt=value, limit = number, offset|skip=number }.
-- value.gt: greater than this value, result in accending order
-- value.lt: less than this value
-- value.limit: max number of rows to return, default to 20. if there are duplicated items, it may exceed this number. 
-- value.offset|skip: default to 0.
-- return all ids as commar separated string
function IndexTable:getIds(value)
	if(type(value) ~= "table") then
		value = {value}
	end
	if(value) then
		local params = {};
		local greaterthan, lessthan;
		greaterthan = value["gt"];
		lessthan = value["lt"];
		local rangedKeyIndex = 1;
		local sql = "SELECT cid FROM "..self:GetTableName().." WHERE ";
		for i, subkey in ipairs(self.subkeys) do
			if(value[i] ~= nil) then
				sql = sql..format("%sname%d=? ", i==1 and "" or "AND ",  i);
				params[#params+1] = value[i];
				rangedKeyIndex = rangedKeyIndex+1;
			else
				break;
			end
		end
		rangedKeyIndex = math.min(rangedKeyIndex, self:GetSubKeyCount());

		if(greaterthan or lessthan) then
			if(greaterthan) then
				sql = sql..format("%sname%d>? ", #params==0 and "" or "AND ", rangedKeyIndex);
				params[#params+1] = greaterthan;
			end
			if(lessthan) then
				sql = sql..format("%sname%d<? ",  greaterthan and "AND " or "", rangedKeyIndex);
				params[#params+1] = lessthan;
			end
		end
		local limit = value.limit or default_limit;
		local offset = value.offset or value.skip or 0;
		sql = sql..format(" ORDER BY name%d LIMIT ?,?", rangedKeyIndex);
		params[#params+1] = offset;
		params[#params+1] = limit;

		local stat = self:GetStatement(sql);
		stat:bind(unpack(params));
		stat:reset();
		local cid;
		for row in stat:rows() do
			cid = cid and (cid .. "," .. row.cid) or tostring(row.cid);
		end
		return cid;
	end
end

-- @param cid: collection id
-- @param newRow: can be partial row containing the changed value
-- @param oldRow: can be partial row containing the old value
function IndexTable:updateIndex(cid, newRow, oldRow)
	if(newRow and cid) then
		local sql = "UPDATE "..self:GetTableName().." SET ";
		local values = {};
		local params = {};
		for i, subkey in ipairs(self.subkeys) do
			local newIndexValue = newRow[subkey.name];
			if(newIndexValue~=nil) then
				if(not oldRow or newIndexValue ~= oldRow[subkey.name]) then
					sql = sql..format("%sname%d=?", (#params==0 and "" or ","), i);
					params[#params+1] = newIndexValue;
				end
			end
		end
		if(#params > 0) then
			sql = sql.." WHERE cid=?";
			params[#params+1] = cid;

			local stat = self:GetStatement(sql);
			stat:bind(unpack(params));
			stat:exec();
		end
	end
end

-- add index to collection row id
-- @param row: row data
-- @param cid: collection row id
function IndexTable:addIndex(row, cid)
	if(row and cid) then
		local sql = "INSERT INTO "..self:GetTableName();
		local values = {};
		local params = {};
		local names = "";
		local placeholders = "";
		params[#params+1] = cid;
		for i, subkey in ipairs(self.subkeys) do
			local newIndexValue = row[subkey.name];
			if(newIndexValue~=nil) then
				names = names..format(",name%d", i);
				placeholders = placeholders..",?";
				params[#params+1] = newIndexValue;
			end
		end
		sql = sql..format(" (cid%s) VALUES(?%s)", names, placeholders);

		local stat = self:GetStatement(sql);
		stat:bind(unpack(params));
		stat:exec();
	end
end

-- this will remove the index to collection db for the given keyvalue. 
-- but it does not remove the real data item in collection db.
-- @param row: table row
-- @param cid: default to nil. if not nil we will only remove when collection row id matches this one. 
function IndexTable:removeIndex(row, cid)
	if(not cid) then
		local values = {};
		for i, subkey in ipairs(self.subkeys) do
			values[i] = row[subkey.name];
		end
		cid = self:getId(values);
	end
	if(cid) then
		self.del_stat = self.del_stat or self:GetDB():prepare([[DELETE FROM ]]..self:GetTableName()..[[ WHERE cid=?]]);
		if(self.del_stat) then
			self.del_stat:bind(cid);
			self.del_stat:exec();
		else
			LOG.std(nil, "error", "IndexTable", "failed to create delete statement");
		end
	end
end

function IndexTable:GetSubKeyCount()
	return #(self.subkeys);
end

-- creating index for existing rows
function IndexTable:CreateTable()
	self.parent:FlushAll();

	-- fetch all index before creating table, otherwise  we will need to call ClearStatementCache twice. 
	local allrows = {};
	local name = self.name;
	self.parent:find({}, function(err, rows)
		if(rows) then
			allrows = rows;
		end
	end)

	-- create table
	local stat = self:GetDB():prepare([[INSERT INTO Indexes (name, tablename) VALUES (?, ?)]]);
	stat:bind(self.name, self:GetTableName());
	stat:exec();
	stat:close();
	
	local names, namefields, values;
	for i, subkey in ipairs(self.subkeys) do
		names = names and (names..",name"..i) or ("name"..i);
		namefields = namefields and (namefields..",name"..i.." BLOB") or ("name"..i.." BLOB");
		values = values and (values..",?") or "?";
	end

	local sql = "CREATE TABLE IF NOT EXISTS ";
	sql = sql..self:GetTableName().." "
	sql = sql..format(kIndexTableColumns, namefields);
	self:GetDB():exec(sql);
	
	-- also create compositive key on sqlite
	local sql = format([[CREATE INDEX IF NOT EXISTS tabledb_%s_cpIdx on %s(%s)]], self:GetTableName(), self:GetTableName(), names);
	self:GetDB():exec(sql);
	
	-- rebuild all indices
	self.parent:Begin();
	local count = 0;

	local stmt = self:GetDB():prepare(format([[INSERT INTO %s (cid, %s) VALUES (?,%s)]], self:GetTableName(), names, values));
	local subkeycount = self:GetSubKeyCount();
	local subkeys = self.subkeys;
	for _, row in ipairs(allrows) do
		if(subkeycount == 1) then
			stmt:bind(row._id, row[subkeys[1].name]);
		elseif(subkeycount == 2) then
			stmt:bind(row._id, row[subkeys[1].name], row[subkeys[2].name]);
		elseif(subkeycount == 3) then
			stmt:bind(row._id, row[subkeys[1].name], row[subkeys[2].name], row[subkeys[3].name]);
		elseif(subkeycount == 4) then
			stmt:bind(row._id, row[subkeys[1].name], row[subkeys[2].name], row[subkeys[3].name], row[subkeys[4].name]);
		else
			break;
		end
		stmt:exec();
		count = count + 1;
	end
	stmt:close();

	LOG.std(nil, "info", "SqliteStore", "compound index table is created for `%s` (subkey count %d) with %d records", self.name, #(self.subkeys), count);
	self.parent:End();
	self.parent:FlushAll();

	-- after inserting tables, all statements shoudl be purged
	self.parent:ClearStatementCache();
end

