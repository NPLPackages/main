--[[
Title: Storage Provider
Author(s): LiXizhi, 
Date: 2016/5/11
Desc: Singleton class for creating storage object for collections. 
This class should only be used in the IO thread see `IOThread.lua`. 
By default, we use SqliteStore for all collections, unless we have set other preferences.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Database/StorageProvider.lua");
local StorageProvider = commonlib.gettable("System.Database.StorageProvider");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Database/MemStore.lua");
NPL.load("(gl)script/ide/System/Database/SqliteStore.lua");
local SqliteStore = commonlib.gettable("System.Database.SqliteStore");
local MemStore = commonlib.gettable("System.Database.MemStore");

local StorageProvider = commonlib.gettable("System.Database.StorageProvider");

-- by default use sqlite store
StorageProvider.DefaultStorage = SqliteStore;

function StorageProvider:GetStorageClass(name)
	return StorageProvider.DefaultStorage;
end

function StorageProvider:SetStorageClass(storageProvider)
	StorageProvider.DefaultStorage = storageProvider;
end


function StorageProvider:CreateStorage(collection)
	local store_class = self:GetStorageClass(collection:GetName());
	if(store_class) then
		return store_class:new():init(collection);
	end
end

