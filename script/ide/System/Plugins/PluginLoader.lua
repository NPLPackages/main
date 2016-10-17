--[[
Title: PluginLoader
Author(s): LiXizhi, onedou
Desc: Download or Load plugins from local folders
Plugins are usually loaded from sub folders or zip files in "Mod/" directory.
"Mod/ModsConfig.xml" contains latest plugin options and where they should be enabled.

Naming plugins, suppose you have a plugin in "Mod/MyPlugin/main.lua", then the plugin must be 
defining its table in namespace "Mod.MyPlugin".

Use Lib: 
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Plugins/PluginLoader.lua");
local PluginLoader = commonlib.gettable("System.Plugins.PluginLoader");
local loader = PluginLoader:new();
loader:InstallFromZipBinary("test", "some data here")
loader:InstallFromUrl("https://github.com/tatfook/NPLCAD/archive/master.zip", function(bSucceed, msg) echo(msg) end);
loader = loader:init(pluginManager, "Mod/");
local list = loader:RebuildModuleList()
loader:LoadAllPlugins();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/System/Plugins/PluginConfig.lua");
NPL.load("(gl)script/ide/System/Plugins/PluginManager.lua");
NPL.load("(gl)script/ide/System/localserver/factory.lua");

local PluginManager = commonlib.gettable("System.Plugins.PluginManager");
local PluginConfig = commonlib.gettable("System.Plugins.PluginConfig");

local PluginLoader = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Plugins.PluginLoader"));

PluginLoader:Property({"Name", "PluginLoader"});
PluginLoader:Property({"PluginFolder", "Mod/", auto=true, desc="default plugin folder"});

local allInstances = {};

function PluginLoader:ctor()
	-- array list of existing plugin (there may be fewer items than in modTable)
	-- in format {text = modname, name = modname, checked = checked, isZip=isZip}
	self.modList = {};
	-- mapping from modname to PluginConfig. Please note that a plugin may be removed but its config is never deleted. 
	self.modTable = {};
	-- the world where plugins are used in. if "nil"  or "global", the plugins are used in global range;
	self.curWorld = nil;
	-- current download info {...}
	self.currentDownload = {status=-1,currentFileSize=0,totalFileSize=0};
	-- current download status
	self.downloadQueue	 = {lock=0,waitCount=0,downloadStatus=0,currentPackagesId=0,currentProjectName='',waitPackages={}};
end

-- @param pluginFolder: if nil, default to "Mod/"
function PluginLoader:init(pluginManager, pluginFolder)
	if(pluginManager) then
		self.pluginManager = pluginManager;
	end
	if(pluginFolder) then
		self:SetPluginFolder(pluginFolder);
	end
	return self;
end

function PluginLoader:GetDownloadQueue()
	return self.downloadQueue;
end

function PluginLoader:SetDownloadQueue(_downloadQueue)
	self.downloadQueue = _downloadQueue;
end

function PluginLoader:GetDownloadInfo()
	return self.currentDownload;
end

function PluginLoader:SetDownloadInfo(downloadInfo)
	--echo(downloadInfo);
	self.currentDownload = downloadInfo or {};
end

function PluginLoader:GetPluginManager()
	return self.pluginManager;
end

function PluginLoader:IsDevMode()
	return System.options.isDevEnv;
end

-- @param filename: if nil, it will use the file GetPluginFolder()+"ModsConfig.xml"
function PluginLoader:GetConfigFilename(filename)
	if(not filename) then
		filename = self.configFilename or (self:GetPluginFolder().."ModsConfig.xml");
	end
	self.configFilename = filename;
	return filename;
end

-- calling this will always refresh the mod table from local disk file. 
-- @param filename: if nil, it will use the file GetPluginFolder()+"ModsConfig.xml"
function PluginLoader:LoadModTableFromFile(filename)
	filename = self:GetConfigFilename(filename);

	local curModTable = {};

	if(not ParaIO.DoesAssetFileExist(filename, true))then
		return;
	end
	local modXML = ParaXML.LuaXML_ParseFile(filename);
	if(modXML) then
		for modnode in commonlib.XPath.eachNode(modXML,"/mods/mod") do
			local modname = modnode.attr.name;
			curModTable[modname] = PluginConfig:new():LoadFromXmlNode(modnode);
		end
	end
	self.modTable = curModTable;
end

function PluginLoader:SaveModTableToFile(filename)
	local curModTable = self.modTable;
	filename = self:GetConfigFilename(filename);
	ParaIO.CreateDirectory(self:GetPluginFolder());
	local file = ParaIO.open(filename, "w");

	if(file:IsValid()) then
		local root = {name='mods',}
		for modname, PluginConfig in pairs(curModTable) do 
			local modnode = PluginConfig:SaveToXmlNode();
			if(modnode) then
				root[#root+1] = modnode;
			end
		end
		if(root) then
			file:WriteString(commonlib.Lua2XmlString(root,true) or "");
		end
		file:close();
	end
end

-- load from disk folder and return an array list of plugins {name, checked, text, isZipped}
function PluginLoader:SearchAllModules()
	local modList = {};
	-- add all explicit plugins in "Mod/" folder. 
	local folderPath = self:GetPluginFolder();
	local output = commonlib.Files.Find(nil, folderPath, 0, 50000, "*.");
	if(output and #output>0) then
		for _, item in ipairs(output) do
			local filename = format("%s%s/main.lua", folderPath, item.filename);
			if(ParaIO.DoesFileExist(filename, false)) then
				self:AddModuleToList(item.filename, modList);
			--else
				--local filename = format("%s%s/%s%s/main.lua", folderPath, item.filename, folderPath, item.filename);
				--if(ParaIO.DoesFileExist(filename, false)) then
					--self:AddModuleToList(format("%s/%s%s", item.filename, folderPath, item.filename), modList);
				--end
			end
		end
	end
	-- add *.zip plugins in "Mod/" folder. 
	if(not self:IsDevMode()) then
		local output = commonlib.Files.Find(nil, folderPath, 0, 50000, "*.zip");
		if(output and #output>0) then
			for _, item in ipairs(output) do
				self:AddModuleToList(item.filename, modList);
			end
		end
	end
	return modList;
end

-- current world filter name, where plugins should be used. 
function PluginLoader:GetWorldFilterName()
	return self.curWorld or "global";
end

function PluginLoader:GetPluginConfig(modname, bCreateIfNotExist)
	local pluginConfig = self.modTable[modname];
	if(not pluginConfig and bCreateIfNotExist) then
		pluginConfig = PluginConfig:new():init(modname);
		self.modTable[modname] = pluginConfig;
	end
	return pluginConfig;
end

-- private:
function PluginLoader:AddModuleToList(modname, modList)
	local checked = false;
	local pluginConfig = self:GetPluginConfig(modname, true);
	if(pluginConfig) then
		checked = pluginConfig:IsEnabled(self:GetWorldFilterName());
	end
	local isZip = modname:match("%.(zip)$") == "zip";
	local item = {text = modname, name = modname, checked = checked==true, isZip=isZip};
	modList[#modList+1] = item;
end

-- Update the modlist from the directory "Mod/" for the current world filter
-- this function is slow and does a file searching, only call this in manager UI
-- @param worldFilterName: if nil, it means "global".
function PluginLoader:RebuildModuleList(worldFilterName)
	if(not self.configLoaded) then
		self.configLoaded = true;
		self:LoadModTableFromFile();
	end	
	self.curWorld = worldFilterName;
	self.modList = self:SearchAllModules();
	return self.modList;
end

-- get the current plugin list since last RebuildModuleList() call. 
function PluginLoader:GetModuleList()
	return self.modList;
end

-- enable a plugin for current world
function PluginLoader:EnablePlugin(modname, bChecked)
	local pluginConfig = self:GetPluginConfig(modname, bChecked == true);
	if(pluginConfig) then
		pluginConfig:SetEnabled(self:GetWorldFilterName(), bChecked);
		for i, item in ipairs(self.modList) do
			if(item.name == modname) then
				item.bChecked = true;
			end
		end
	end
end

-- @param modname: it is either the folder name or zip file name. such as "STLExporter.zip"
-- it should be relative to self:GetPluginFolder() or "Mod/" folder
function PluginLoader:LoadPlugin(modname)
	local filename = self:GetPluginFolder()..modname;
	if( modname:match("%.(zip)$") == "zip") then
		if(ParaIO.DoesAssetFileExist(filename, true))then
			ParaAsset.OpenArchive(filename,false);	
			-- try find main file in "Mod/*/main.lua"
			local output = commonlib.Files.Find(nil, "", 0, 10000, self:GetPluginFolder().."*/main.lua", filename)
			if(output and #output>0) then
				local main_filename = output[1].filename;
				return self:LoadPluginImp(modname, main_filename);
			end
			-- try find main file in "*/Mod/*/main.lua"
			local output = commonlib.Files.Find(nil, "", 0, 10000, "*/"..self:GetPluginFolder().."*/main.lua", filename)
			if(output and #output>0) then
				-- just in case, the user has zipped everything in a folder, such as downloading from github as a zip file. 
				local base_folder_name, main_filename = output[1].filename:match("^([^/]+)/(%w+/[^/]+/main.lua)");
				if(main_filename) then
					local zip_archive = ParaEngine.GetAttributeObject():GetChild("AssetManager"):GetChild("CFileManager"):GetChild(filename);
					zip_archive:SetField("SetBaseDirectory", base_folder_name);
					return self:LoadPluginImp(modname, main_filename);
				end
			end
		end
	else
		local main_filename = filename.."/main.lua";
		return self:LoadPluginImp(modname, main_filename);
	end
end

function PluginLoader:LoadPluginImp(modname, main_filename)
	local module_classname = main_filename:match("^%w+/([^/]+)");
	local module_class = self:FindPluginClass(module_classname);
	if(not module_class) then
		NPL.load(main_filename);
		module_class = self:FindPluginClass(module_classname);
		if(module_class) then
			if(self:GetPluginManager()) then
				self:GetPluginManager():AddMod(modname, module_class);
			end
			return true;
		end
	else
		LOG.std(nil, "warn", "Modules", "mod: %s ignored, because another module_class %s already exist", modname, module_classname); 
	end
end

-- this matches the plugin folder name. All plugins must be defined in the namespace "Mod.XXX"
function PluginLoader:GetRootTable()
	if (not self.rootTable) then
		local tableName = self:GetPluginFolder():gsub("/$", ""):gsub("/", ".");
		self.rootTable = commonlib.gettable(tableName);
	end
	return self.rootTable;
end

-- Naming plugins, suppose you have a plugin in "Mod/MyPlugin/main.lua", then the plugin must be 
-- defining its table in namespace "Mod.MyPlugin".
-- @param module_classname: case insensitive module name
function PluginLoader:FindPluginClass(module_classname)
	if(module_classname) then
		module_classname = string.lower(module_classname);
		for name, value in pairs(self:GetRootTable()) do
			if(string.lower(name) == module_classname) then
				if(type(value) == "table") then
					return value;
				end
			end
		end
	end
end

-- return the modname that is loaded from command line mod="modname"
function PluginLoader:ForceLoadModFromCommandline()
	if(self:IsDevMode()) then
		local modname = ParaEngine.GetAppCommandLineByParam("mod","");
		if(modname and modname ~= "") then
			self:LoadPlugin(modname);
			return modname;
		end
	end
end

-- load all plugins. This function does not search mod folder, 
-- but only use plugin config file to load enabled plugins. 
function PluginLoader:LoadAllPlugins(bForceReload)
	if(self.isLoaded and not bForceReload) then
		return;
	end
	self.isLoaded = true;

	local skip_modname = self:ForceLoadModFromCommandline();

	self:LoadModTableFromFile();
	
	local curWorldname = self:GetWorldFilterName();
	local failedMods;
	for modname, pluginInfo in pairs(self.modTable) do
		if(pluginInfo:IsEnabled(curWorldname)) then
			if(skip_modname ~= modname) then
				if(not self:LoadPlugin(modname)) then
					LOG.std(nil, "warn", "PluginLoader", "failed to load plugin %s", modname);
					failedMods = failedMods or {};
					failedMods[#failedMods+1] = modname;
				end
			end
		end
	end

	if(failedMods) then
		for _, modname in ipairs(failedMods) do
			self.modTable[modname]:SetEnabled(curWorldname, false);
		end
		self:SaveModTableToFile();
	end
end

function PluginLoader:StartDownloader(src, dest, callbackFunc, cachePolicy)
	local function OnSucceeded(filename)
		self.isFetching = false;
		if(callbackFunc) then
			callbackFunc(true, filename)
		end
	end

	local function OnFail(msg)
		self.isFetching = false;
		if(callbackFunc) then
			callbackFunc(false, msg);
		end
	end
	
	local ls = System.localserver.CreateStore(nil, 1);

	if(self.isFetching) then
		OnFail("a previous download is not finished");
		return;
	end
	self.isFetching = true;

	local res = ls:GetFile(System.localserver.CachePolicy:new(cachePolicy or "access plus 5 days"),
		src,
		function (entry)
			--log({"entry",entry});

			if(dest) then
				if(ParaIO.CopyFile(entry.payload.cached_filepath, dest, true)) then
					local cached_filepath = entry.payload.cached_filepath;
					ParaIO.DeleteFile(cached_filepath);
					--  download complete
					LOG.std(nil, "info", "PluginLoader", "successfully downloaded file from %s to %s", src, dest);
					OnSucceeded(dest);
				else
					LOG.std(nil, "info", "PluginLoader", "failed copy file from %s to %s", src, dest);
					OnFail("failed to copy file to dest folder. The file may be in use.");
				end	
			else
				LOG.std(nil, "info", "PluginLoader", "successfully downloaded file to %s", entry.payload.cached_filepath);
				OnSucceeded(entry.payload.cached_filepath);
			end
		end,
		nil,
		function (msg, url)
			local totalFileSize   = msg['totalFileSize'];
			local currentFileSize = msg['currentFileSize'];
			local DownloadState   = msg['DownloadState'];
			local status		  = 0;

			if(DownloadState == 'complete') then
				local downloadQueue = self:GetDownloadQueue();

				downloadQueue.downloadStatus	 = 0;
				downloadQueue.currentPackagesId  = 0;
				downloadQueue.currentProjectName = 'Not yet!';

				self:SetDownloadQueue(downloadQueue);

				status = 1;
			end

			self:SetDownloadInfo({status=status,currentFileSize=currentFileSize,totalFileSize=totalFileSize});

			-----------

			local text;
			self.DownloadState = self.DownloadState;

			if(msg.DownloadState == "") then
				text = "Downloading ..."
				if(msg.totalFileSize) then
					self.totalFileSize = msg.totalFileSize;
					self.currentFileSize = msg.currentFileSize;
					text = string.format("Downloading: %d/%dKB", math.floor(msg.currentFileSize/1024), math.floor(msg.totalFileSize/1024));
				end
			elseif(msg.DownloadState == "complete") then
				text = "Download completed!";
			elseif(msg.DownloadState == "terminated") then
				text = "Download terminated";
				OnFail(text);
			end

			if(text) then
				--log({"text",text}); -- TODO: display in UI?
			end
		end
	);

	if(not res) then
		OnFail("Duplicated download");
	end
end

function PluginLoader:ComputeLocalFileName(url)
	local filename = self:GetPluginFolder()..url:gsub("[%W%s]+", "_"):gsub("_zip$", ".zip");
	if(not filename:match("%.zip$")) then
		filename = filename..".zip";
	end
	return filename;
end

-- install from url to Mod/ folder 
-- @param url: download and overwrite existing file. 
-- @param callbackFunc: function (bSucceed, dest) end
-- @param refreshMode: nil|"auto"|"never"|"force".  
-- if "never", we will never download again if there is already a local cached file. 
-- if "auto" or nil, we will compare Last-Modified or Content-Length in http headers, before download full file. 
-- if "force", we will always download the file. 
function PluginLoader:InstallFromUrl(url, callbackFunc, refreshMode)

	refreshMode = refreshMode or "auto";
	callbackFunc = callbackFunc or echo;
	
	-- destination file path
	local dest = self:ComputeLocalFileName(url);

	-- get http headers only
	System.os.GetUrl(url, function(err, msg)
		echo({"GetUrl",url,dest});
		if(msg.rcode ~= 200 or not msg.header) then
			LOG.std(nil, "info", "PluginLoader", "remote plugin can not be fetched from %s, a previous downloaded one at %s is used", url, dest);
			callbackFunc(-1, dest);
		else
			local content_length = msg.header:match("Content%-Length: (%d+)");

			if(content_length) then
				local local_filesize = ParaIO.GetFileSize(dest);

				if(local_filesize == tonumber(content_length)) then
					-- we will only compare file size: since github/master does not provide "Last-Modified: " header.
					LOG.std(nil, "info", "PluginLoader", "remote plugin size not changed, previously downloaded one %s is used", dest);

					callbackFunc(0, dest);
				else

					callbackFunc(1, dest);
					
					--LOG.std(nil, "info", "PluginLoader", "remote(%d) and local(%d) file size differs", content_length, local_filesize);
					--self:StartDownloader(url, dest, callbackFunc);
				end
			else
				LOG.std(nil, "info", "PluginLoader", "content_length is empty");
				callbackFunc(-1, dest);
			end
		end
	end, "-I");
end

-- install from raw binary content to Mod/ folder
-- Usage: use Javascript to download from web browser 
-- and post the binary content to NPL server for installation. 
-- @param name: mod filename
-- @param data: binary zipped data
function PluginLoader:InstallFromZipBinary(name, data)
	if(not data or not name) then return end
	-- destination file path
	local dest = self:ComputeLocalFileName(name);
	
	local file = ParaIO.open(dest, "w");
	if(file:IsValid()) then
		file:write(data, #data);
		file:close();
	end
end