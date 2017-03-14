--[[
Title: single thread memory cache
Author: LiXizhi
Date: 2015/6/14
Desc: this is the default memory cache class used by the admin site. 
One may replace it with other more advanced cache API, such as "memcached".
-----------------------------------------------
NPL.load("(gl)script/apps/WebServer/mem_cache.lua");
local mem_cache = commonlib.gettable("WebServer.mem_cache");
local obj_cache = mem_cache:GetInstance();
obj_cache:add("name", "value")
obj_cache:replace("name", "value1")
assert(obj_cache:get("name") == "value1");
obj_cache:remove_group("group1");
assert(obj_cache:get("name", "group1") == nil);
obj_cache:add("name", "value", "group1")
assert(obj_cache:get("name", "group1") == "value");

obj_cache:set("testexpire", "expire in 2 seconds", "group1", 2)
assert(obj_cache:get("testexpire", "group1") == "expire in 2 seconds");
ParaEngine.Sleep(3);
assert(obj_cache:get("testexpire", "group1") == nil);
-----------------------------------------------
]]

local mem_cache = commonlib.inherit(nil, commonlib.gettable("WebServer.mem_cache"));
local ParaGlobal_timeGetTime = ParaGlobal.timeGetTime

-- single threaded global instance
local s_singleton;

function mem_cache:ctor()
	-- group name to {key, value} store
	self.groups = {};
end


-- static public function. 
-- get global singleton
function mem_cache:GetInstance()
	if(s_singleton) then
		return s_singleton;
	else
		s_singleton = mem_cache:new();
		return s_singleton;
	end
end

-- @param expire: in milliseconds
-- @param curTime: in milliseconds, if nil the current time is used. 
-- @return true if expired 
local function checkExpire(expire, curTime)
	return expire and expire~=0 and (expire < (curTime or ParaGlobal_timeGetTime()));
end

-- Retrieves the cache contents from the cache by key and group.
-- @param key: What the contents in the cache are called
-- @param group: Where the cache contents are grouped
-- @param force: boolean Whether to force an update of the local cache from the persistent cache -- (default is false)
-- @return value: value stored in cache. nil if not found;
function mem_cache:get(name, group, force)
	local store = self.groups[group or ""];
	if(store) then
		local s = store[name];
		if(s ~= nil) then
			if(s.expire and checkExpire(s.expire)) then
				store[name] = nil
				return;
			else
				return s.value;
			end
		end
	end
end

-- Saves the data to the cache.
-- @param key: The cache key to use for retrieval later
-- @param data:  The data to add to the cache store. if nil, it will remove the item.
-- @param group: The group to add the cache to. default to ""
-- @param expire: When the cache data should be expired in seconds, if nil or 0 it will not expire. 
-- @return true on success
function mem_cache:set(key, data, group, expire)
	local store = self:getgroup(group);
	local s = store[key];
	if(data ~= nil) then
		if(not s) then
			s = {};
			store[key] = s;
		end
		s.value = data;
		if(expire) then
			s.expire = expire*1000 + ParaGlobal_timeGetTime();
		end
	else
		store[key] = nil;
	end
	return true;
end

-- Adds data to the cache, if the cache key doesn't already exist.
-- @param key: The cache key to use for retrieval later
-- @param data:  The data to add to the cache store
-- @param group: The group to add the cache to. default to ""
-- @param expire: When the cache data should be expired in seconds, if nil or 0 it will not expire. 
-- @return bool False if cache key and group already exist, true on success
function mem_cache:add(key, data, group, expire)
	if(self:get(key, group) == data) then
		return false;
	else
		self:set(key, data, group, expire);
		return true;
	end
end

-- Replaces the contents of the cache with new data.
-- @param key: The cache key to use for retrieval later
-- @param data:  The data to add to the cache store
-- @param group: The group to add the cache to. default to ""
-- @param expire: When the cache data should be expired in seconds, if nil or 0 it will not expire. 
-- @return bool False if not exists, true if contents were replaced
function mem_cache:replace(key, data, group, expire)
	if(self:get(key, group) ~= nil) then
		return self:set(key, data, group, expire);
	else
		return;
	end
end

-- get a given group
function mem_cache:getgroup(group)
	local store = self.groups[group or ""];
	if(not store) then
		store = {};
		self.groups[group or ""] = store;
	end
	return store;
end

-- set a given group
function mem_cache:remove_group(group)
	local store = self.groups[group or ""];
	if(store) then
		self.groups[group or ""] = nil;
	end
end