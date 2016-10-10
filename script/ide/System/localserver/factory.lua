--[[
Title: creating instances of local servers
Author(s): LiXizhi
Date: 2008/2/27
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/localserver/factory.lua");
local store = System.localserver.CreateStore("WebserviceStore_sample", 2)
local store = System.localserver.CreateStore("ResourceStore_sample", 1)
local store = System.localserver.CreateStore("ManagedResourceStore_sample", 0)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/localserver/cache_policy.lua");

local localserver = commonlib.gettable("System.localserver");


local _Stores = {};
local _Stores_pools = {};
-- create or get a resource store using the default security origin. 
-- @param name: if name is nil, a default name "_default_" will be used for the type of store. In most cases, one should use the default store name
-- @param ServerType: see WebCacheDB.ServerType. If nil or 1, for resource store; 2 for web service store, 3 for URLResource store, 0 for managed resource store. 
-- @param db_name: web database file to use.normally this should be nil, where the default web db at "Database/localserver.db" is used; or it can also be "Database/[db_name].db".
-- return the ResourceStore local server instance. or nil if failed. 
function System.localserver.CreateStore(name, serverType, db_name)
	serverType = serverType or 1;
	if(not name) then name = "_default_"..serverType end
	local serverStore;
	
	-- we cache the result in memory, so that this function can be called repeatedly
	local serverStore = System.localserver.GetStore(name, db_name);
	if(serverStore) then
		return serverStore;
	end
	
	if(serverType == 1) then
		NPL.load("(gl)script/ide/System/localserver/ResourceStore.lua");
		
		serverStore = System.localserver.ResourceStore:new({db_name = db_name});
		-- TODO: using origin of the login user's server domain, currently it is just paraengine.com 
		-- TODO: use user info for cookies.  
		if(serverStore:CreateOrOpen("http://paraengine.com", name, "")) then
		end
	elseif(serverType == 2) then
		NPL.load("(gl)script/ide/System/localserver/WebserviceStore.lua");
		serverStore = System.localserver.WebserviceStore:new({db_name = db_name});
		if(serverStore:CreateOrOpen("http://paraengine.com", name, "")) then
		end
	elseif(serverType == 3) then
		NPL.load("(gl)script/ide/System/localserver/URLResourceStore.lua");
		serverStore = System.localserver.URLResourceStore:new({db_name = db_name});
		if(serverStore:CreateOrOpen("http://paraengine.com", name, "")) then
		end	
	elseif(serverType == 0)	then
		NPL.load("(gl)script/ide/System/localserver/ManagedResourceStore.lua");
		serverStore = System.localserver.ManagedResourceStore:new({db_name = db_name});
		if(serverStore:CreateOrOpen("http://paraengine.com", name, "")) then
		end
	end	
	
	if(serverStore and serverStore.is_initialized_) then
		-- add to memory cache, so that the next time the store is returned from the cache. 
		if(db_name == nil) then
			_Stores[name] = serverStore;
		else
			_Stores_pools[db_name] = _Stores_pools[db_name] or {};
			_Stores_pools[db_name][name] = serverStore;
		end	
		return serverStore;
	end	
end

-- get the loaded store. if the store is not loaded,it will return nil. To CreateGet a store, use CreateStore() instead. 
-- @param name: if name is nil, a default name "_default_" will be used for the type of store. In most cases, one should use the default store name
-- @param db_name: web database file to use.normally this should be nil, where the default web db at "Database/localserver.db" is used; or it can also be "Database/[db_name].db".
-- @return: nil if no store is created brefore. 
function System.localserver.GetStore(name, db_name)
	if(db_name == nil) then
		if(_Stores[name]) then
			-- hit memory cache first
			return _Stores[name]
		end	
	else
		_Stores_pools[db_name] = _Stores_pools[db_name] or {};
		return _Stores_pools[db_name][name];
	end	
end

-- force flushing all opened database servers. We usually call this function before closing or restarting the game. 
function System.localserver.FlushAll()
	if(System.localserver.WebCacheDB and System.localserver.WebCacheDB.FlushAll) then
		System.localserver.WebCacheDB.FlushAll();
	end	
end