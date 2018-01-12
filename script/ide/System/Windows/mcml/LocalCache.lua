--[[
Title: local cache
Author(s): LiPeng
Date: 2018/1/12
Desc: singleton class for local cache for mcml page resource. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/LocalCache.lua");
local LocalCache = commonlib.gettable("System.Windows.mcml.LocalCache");
LocalCache.getRemoteTexture_callback();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/localserver/factory.lua");
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/System/localserver/capture_task.lua");
local TaskManager = commonlib.gettable("System.localserver.TaskManager");
local LocalCache = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Windows.mcml.LocalCache"));

LocalCache.RemoteTexture_cache_policy = System.localserver.CachePolicy:new("access plus 1 hour");

local try_connect_period = 500;

function LocalCache:ctor()
	self.localserver = nil;
	self.urls = {};

	self.timer = self.timer or commonlib.Timer:new({callbackFunc = function(timer)
		self:Tick();
		--self:updateNeeded(); -- signal
	end})
end

function LocalCache:Tick()
	if(not next(self.urls)) then
		self.timer:Change();
		return;
	end
	for url,item in pairs(self.urls) do
		--local item = self.urls[i];
		item["load_times"] = item["load_times"] or 0;
		if(item["load_times"] > 4) then
			LOG.std(nil, "warn", "LocalCache", "connet url %s timeout", url);
			self:RemoveItem(url);
		else
			if(not TaskManager.urls[url]) then
				self:GetFile(url, item["cache_policy"]);
			end
		end
	end
end

function LocalCache:GetStore()
	if(not self.localserver) then
		self.localserver = System.localserver.CreateStore();
	end
	return self.localserver;
end

function LocalCache:CheckUrl(url,cache_policy,callback)
	local res = if_else(self.urls[url],true,false);
	self.urls[url] = self.urls[url] or {};
	local item = self.urls[url];
	item["cache_policy"] = cache_policy;
	item["callback"] = item["callback"] or {};
	item["load_times"] = item["load_times"] or 0;
	table.insert(item["callback"],callback);
	return res;
end

local function callbackComplete(entry)
	if(entry and entry.entry and entry.entry.url and entry.payload and entry.payload.cached_filepath) then
		local asset = ParaAsset.LoadTexture("", entry.payload.cached_filepath, 1);
		if(asset:IsValid()) then
			local item = LocalCache:GetItem(entry.entry.url);
			if(item and item["callback"]) then
				for i = 1, #item["callback"] do
					local callback = item["callback"][i];
					callback(entry);
				end
			end
			LocalCache:RemoveItem(entry.entry.url);
		end
	end
end

local function callbackProgressFunc(msg, url)
	if(msg~=nil and msg.DownloadState ~= "") then
		if(msg.DownloadState == "terminated" and msg.rcode == 404) then
			LOG.std(nil, "warn", "LocalCache", "url %s is not exist", callbackContext);
		else
			local item = LocalCache:GetItem(url);
			if(item) then
				-- 记录加载次数
				item["load_times"] = item["load_times"] or 0;
				item["load_times"] = item["load_times"] + 1;
			end	
		end
	end
end

function LocalCache:GetFile(url,cache_policy)
	local ls = self:GetStore();
	if(not ls) then
		log("error: failed creating local server resource store\n")
		return
	end
	ls:GetFile(cache_policy, url, callbackComplete, nil, callbackProgressFunc);
end

function LocalCache:GetRemoteTexture(url, cache_policy, callback)
	if(self:CheckUrl(url,cache_policy,callback)) then
		return;
	end
	self:GetFile(url, cache_policy);
	self.timer:Change(try_connect_period,try_connect_period);
end

function LocalCache:GetItem(url)
	return self.urls[url];
end

function LocalCache:RemoveItem(url)
	self.urls[url] = nil;
end

-- clear all cached textures. 
function LocalCache:ClearTextureCache()
	local ls = self:GetStore();
	if(not ls) then
		log("error: failed creating local server resource store\n")
		return
	end
	ls:DeleteAll();
	--self.urls = {};
end

LocalCache:InitSingleton();