--[[
Title: File System Watcher
Author(s):  LiXizhi
Date: 2010/3/29
Desc: Monitoring file changes in a given directory recursively. It uses IO completion port under windows and inotify under linux. 
This is useful for monitoring asset or script file changes and reload them automatically at development time. 
KNOW LIMITATIONS:
	- only a single low level watcher object can be available per thread. Hence self.name must be unique. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/FileSystemWatcher.lua");
-- watch files under model/ and character/ directory and Refresh it in case they are changed
local watcher = commonlib.FileSystemWatcher:new()
watcher.filter = function(filename)
	return string.find(filename, ".*") and not string.find(filename, "%.svn")
end
watcher:AddDirectory("model/")
watcher:AddDirectory("character/")
watcher:SetMonitorAll(true);
watcher.OnFileChanged = function (msg)
	if(msg.type == "modified" or msg.type == "added" or msg.type=="renamed_new_name") then
		commonlib.log("File %s is %s in dir %s\n", msg.fullname, msg.type, msg.dirname)
		ParaAsset.Refresh(msg.fullname);
	end
end

-- this is a handy function that does above things
commonlib.FileSystemWatcher.EnableAssetFileWatcher()
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/timer.lua");

local FileSystemWatcher = {
	-- multiple watcher with the same name will share the same low level watcher object. 
	-- KNOWN ISSUES: only a single low level watcher object can be available per thread. Hence self.name must be unique. 
	name = "default",
	-- regular expression to filter file name. or it can also be a function(filename) ... end that returns true if the input file is accepted. 
	filter = ".*",
	-- how many milliseconds to delay before we fire an event. in case some program is writing to the file very frequently, we may receive many messages
	-- by using delay time, we will delete duplicated messages for the same file during the delay interval. 
	DelayInterval = 3000,
}
commonlib.FileSystemWatcher = FileSystemWatcher

local watcher_dirs = {}


-- mapping from watcher name to a list of instances. 
local call_backs = {}

local function registerCallback(name, o)
	local instances = call_backs[name];
	if(o) then
		if(not instances) then
			instances = {};
			call_backs[name] = instances;
			local watcher = ParaIO.GetFileSystemWatcher(name);
			watcher:AddCallback(string.format("commonlib.FileSystemWatcher.OnFileCallback(%q);", name));
		end
		instances[#instances + 1] = o;
	end
end

local function unregisterCallback(name, o)
	local instances = call_backs[name];
	if(instances) then
		for i, instance in ipairs(instances) do
			if(instance == o) then
				commonlib.removeArrayItem(instances, i);
				break;
			end
		end
		if(#instances == 0) then
			ParaIO.DeleteFileSystemWatcher(name);
			call_backs[name] = nil;
		end
	end
end

-- a new watcher class, do not create too many of this class, since they are never deleted. 
function FileSystemWatcher:new(o)
	o = o or {};
	setmetatable(o, self)
	self.__index = self
	o.msgs = {};
	o.timer = commonlib.Timer:new({callbackFunc = function(timer)
		FileSystemWatcher.DispatchEvent(o);
	end});
	
	-- add to call back instances
	registerCallback(o.name, o);
	return o
end

-- remove this file watcher. 
function FileSystemWatcher:Destroy()
	self:RemoveAllDirectories();
	unregisterCallback(self.name, self);
	
	if( not call_backs[self.name]) then
		watcher_dirs[self.name] = nil;
	end
end


local type_to_name = {
	[0] = "null", 
    [1] = "added",
    [2] = "removed",
    [3] = "modified",
    [4] = "renamed_old_name",
    [5] = "renamed_new_name",
}

-- on file callback
function FileSystemWatcher.OnFileCallback(name)
	if(msg and msg.filename) then
		msg.type = type_to_name[msg.type] or msg.type;
		msg.dirname = string.gsub(msg.dirname, "\\", "/");
		msg.filename = string.gsub(msg.filename, "\\", "/");
		msg.fullname = msg.dirname..msg.filename;
		-- debugging purposes
		LOG.std(nil, "debug", "FileSystemWatcher", "File %s is %s in dir %s", msg.fullname, msg.type, msg.dirname)
		local instances = call_backs[name];
		if(instances) then
			for i, instance in pairs(instances) do
				instance:AddMessage(msg);
			end
		end
	end	
end

-- whether to monitor all registered system file changes. 
function FileSystemWatcher:IsMonitorAll()
	return self.bMonitorAll;
end

function FileSystemWatcher:SetMonitorAll(bMonitorAll)
	self.bMonitorAll = bMonitorAll;
end

-- add message 
function FileSystemWatcher:AddMessage(msg)
	local bAcceptFile;
	local dir = self:NormalizeDirectory(msg.dirname);
	if(self:IsMonitorAll() or self:hasParentDirectory(dir)) then
		-- filter the message.
		if(type(self.filter) == "function") then
			bAcceptFile = self.filter(msg.filename);
		elseif(type(self.filter) == "string") then
			bAcceptFile = string.find(msg.filename, self.filter);
		end
		if(bAcceptFile) then
			self.msg = self.msg or {};
			self.msg[msg.fullname] = msg;
			if(not self.timer:IsEnabled()) then
				self.timer:Change(self.DelayInterval, nil);
			end
		end	
	end	
end

-- DispatchEvent all queued events in the last interval. 
function FileSystemWatcher:DispatchEvent()
	if(self.msg) then
		for filename, msg in pairs(self.msg) do
			-- modified
			if(self.OnFileChanged) then
				self.OnFileChanged(msg)
			end
		end
		self.msg = nil;
	end
end

-- always ends with `/`
function FileSystemWatcher:NormalizeDirectory(dir)
	if(dir) then
		if(#dir>=1 and not dir:match("[/]$")) then
			dir = dir.."/";
		end
	end
	return dir;
end

-- see if any parent directory that is already being watched.
function FileSystemWatcher:hasParentDirectory(dir)
	self.dirs = self.dirs or {};
	if(self.dirs[dir]) then
		return true;
	else
		while (dir) do
			local dirParent = dir:gsub("[^/]+/$", "")
			if(dir ~= dirParent) then
				if(self.dirs[dirParent]) then
					return true;
				else
					dir = dirParent;
				end
			else
				break;
			end
		end
	end
end

-- add a dir to monitor
-- @param dir: such as "script/", "model/", "character"
function FileSystemWatcher:AddDirectory(dir)
	dir = self:NormalizeDirectory(dir);
	if(not self:hasParentDirectory(dir)) then
		self.dirs[dir] = true;
		
		watcher_dirs[self.name] = watcher_dirs[self.name] or {};
		if(not watcher_dirs[self.name][dir]) then
			watcher_dirs[self.name][dir] = 1;
			local watcher = ParaIO.GetFileSystemWatcher(self.name);
			watcher:AddDirectory(dir);
		else
			watcher_dirs[self.name][dir] = watcher_dirs[self.name][dir]+ 1;	
		end	
	end
end

-- remove a dir to watch 
function FileSystemWatcher:RemoveDirectory(dir)
	self.dirs = self.dirs or {};
	if(self.dirs[dir]) then
		self.dirs[dir] = nil;
		
		watcher_dirs[self.name] = watcher_dirs[self.name] or {};
		
		if(watcher_dirs[self.name][dir]>=1) then
			if(watcher_dirs[self.name][dir] == 1) then
				local watcher = ParaIO.GetFileSystemWatcher(self.name);
				watcher:RemoveDirectory(self:NormalizeDirectory(dir));
			else
				watcher_dirs[self.name][dir] = watcher_dirs[self.name][dir] -1;
			end	
		end	
	end
end

-- unwatch all directories
function FileSystemWatcher:RemoveAllDirectories()
	while(true) do
		local dir = next(self.dirs, nil);
		if(dir) then
			self:RemoveDirectory(dir);
		else
			break;
		end
	end
end

-- because it is so common to watch for asset file changes, we added the following function
-- call this at any time to start watching for files
function FileSystemWatcher.EnableAssetFileWatcher()
	if(not FileSystemWatcher.AssetFileWatcher) then
		-- watch files under model/ and character/ directory and Refresh it in case they are changed
		local watcher = commonlib.FileSystemWatcher:new()
		watcher.filter = function(filename)
			return string.find(filename, ".*") and not string.find(filename, "%.svn")
		end
		watcher:AddDirectory("model/")
		watcher:AddDirectory("character/")
		watcher:AddDirectory("Texture/")
		watcher.OnFileChanged = function (msg)
			if(msg.type == "modified" or msg.type == "added" or msg.type=="renamed_new_name") then
				if(ParaAsset.Refresh(msg.fullname)) then
					commonlib.log("AssetMonitor: File %s is refreshed in dir %s\n", msg.fullname, msg.dirname)
				end
			end
		end

		FileSystemWatcher.AssetFileWatcher = watcher;
	end
end

