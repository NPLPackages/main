--[[
Title: Item
Author(s): LiXizhi, 
Date: 2016/5/11
Desc: Represent a single resource or document or record. 
Each item has a uniqud self._id field when inserted to the collection. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Database/Item.lua");
local Item = commonlib.gettable("System.Database.Item");
------------------------------------------------------------
]]

local Item = commonlib.inherit(nil, commonlib.gettable("System.Database.Item"));

function Item:ctor()
end

-- @param parent: parent collection object
function Item:init(parent, data)
	self.parent = parent;
	self.data = data;
	return self;
end

function Item:Merge(data)
	if(type(data) == "table") then
		commonlib.partialcopy(self.data, data);
	end
end

-- @param timeout: default to 5 seconds
function Item:save(callbackFunc, timeout)
	if(callbackFunc) then
		return self.parent:insertOne(self.data, function(err, data)
				self:Merge(data);
				callbackFunc(err, data);
			end, timeout);
	else
		local err, data = self.parent:insertOne(self.data, nil, timeout);
		self:Merge(data);
		return err, data;
	end
end

