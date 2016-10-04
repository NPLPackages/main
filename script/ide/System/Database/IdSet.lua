--[[
Title: Set of id
Author(s): LiXizhi, 
Date: 2016/10/4
Desc: manipulation of set of ids, such as union or intersection. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Database/IdSet.lua");
local IdSet = commonlib.gettable("System.Database.IdSet");
local s1 = IdSet:new():init("1,2,3,4,5");
assert(s1:union("4,5,6"):tostring() == "1,2,3,4,5,6");
assert(s1:intersect("4,5,6,7,8,9"):tostring() == "4,5,6");
------------------------------------------------------------
]]
local IdSet = commonlib.inherit(nil, commonlib.gettable("System.Database.IdSet"));
local tonumber = tonumber;
local type = type;

function IdSet:ctor()
	self.array = {};
	self.map = {};
end

function IdSet:clear()
	self.array = {};
	self.map = {};
end

-- @param ids: nil or ids as commar separated string
function IdSet:init(ids)
	return self:union(ids);
end

function IdSet:empty()
	return #(self.array) == 0;
end

function IdSet:remove(id)
	id = tonumber(id);
	if(id and self.map[id]) then
		self.map[id] = nil;
		local array = self.array;
		for i=1, #array do
			if(array[i] == id) then
				commonlib.removeArrayItem(array, i);
				break;
			end
		end
	end
end

function IdSet:getArray()
	return self.array;
end

function IdSet:getMap()
	return self.map;
end

function IdSet:tostring()
	return table.concat(self.array, ",");
end

function IdSet:intersect(ids)
	if(type(ids) == "string") then
		if(self:empty()) then
			self:union(ids);
		else
			local map = self.map;
			local array = {};
			local newmap = {};
			for id in ids:gmatch("%d+") do
				id = tonumber(id);
				if(map[id]) then
					array[#array+1] = id;
					newmap[id] = true;
				end
			end
			self.array = array;
			self.map = newmap;
		end
	end
	return self;
end

function IdSet:union(ids)
	if(type(ids) == "string") then
		local array = self.array;
		local map = self.map;
		for id in ids:gmatch("%d+") do
			id = tonumber(id);
			if(not map[id]) then
				map[id] = true;
				array[#array+1] = tonumber(id);
			end
		end
	end
	return self;
end