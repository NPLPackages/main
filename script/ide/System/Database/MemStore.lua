--[[
Title: In-memory database
Author(s): LiXizhi, 
Date: 2016/5/11
Desc: completely in-memory data store. It also allows you to load or save to a disk file.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Database/MemStore.lua");
local MemStore = commonlib.gettable("System.Database.MemStore");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Database/Store.lua");
local MemStore = commonlib.inherit(commonlib.gettable("System.Database.Store"), commonlib.gettable("System.Database.MemStore"));

function MemStore:ctor()
end

function MemStore:init(collection)
	MemStore._super.init(self, collection);
	return self;
end