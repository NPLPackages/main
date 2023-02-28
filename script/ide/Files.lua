--[[
Title: Files helper functions
Author(s):  LiXizhi
Date: 2009/2/4
Desc: file searching, etc
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/Files.lua");
local result = commonlib.Files.Find({}, "model/test", 0, 500, function(item)
	local ext = commonlib.Files.GetFileExtension(item.filename);
	if(ext) then
		return (ext == "x") or (ext == "dds")
	end
end)

-- search zip files using perl regular expression. like ":^xyz\\s+.*blah$"
local result = commonlib.Files.Find({}, "model/test", 0, 500, ":.*", "*.zip")

-- using lua file system
local lfs = commonlib.Files.GetLuaFileSystem();
echo(lfs.attributes("config/config.txt", "mode"))
------------------------------------------------------------
]]

-- file related
if(not commonlib) then commonlib={} end
if(not commonlib.Files) then commonlib.Files={} end
local Files = commonlib.Files;

-- get file extension. it will return nil if no extension is found. 
function Files.GetFileExtension(file)
	if(file) then
		return string.match(file, "%.(%w+)$")
	end
end

local lfs;

-- get lua file system (lfs), which is based on lfs: see http://keplerproject.github.com/luafilesystem/
-- created on first use. pay attention to security. 
function Files.GetLuaFileSystem()
	if(lfs) then
		return lfs;
	else
		lfs = luaopen_lfs();
		return lfs;
	end
end


function Files.IsAbsolutePath(filename)
	if(filename and (filename:match("^[/\\]") or filename:match(":"))) then
		return true;
	end
end

-- replace / with \ under win32, and vice versa on linux. 
function Files.ToCanonicalFilePath(filename)
	if type(filename)~="string" then
		return ""
	end
	filename = filename:gsub("\\","/")
	filename = filename:gsub("[/]+","/")
	if(System.os.GetPlatform()=="win32") then
		filename = filename:gsub("/", "\\");
	end
	return filename;
end

local dev_dir;
-- @return "" if no dev directory is specified. 
function Files.GetDevDirectory()
	if(not dev_dir) then
		dev_dir = ParaIO.GetCurDirectory(20) or "";
	end
	return dev_dir;
end


--预期获得 C:\Users\hyz\AppData\Local\Paracraft\
function Files.GetAppDataDirectory()
	local lfs = commonlib.Files.GetLuaFileSystem();
	if not Files._AppDataDirectory then		
		local ret = ParaIO.GetWritablePath()
		repeat 
			if System.os.GetPlatform()~="win32" then
				break
			end
			local env_appdata = os.getenv("localappdata")
			if env_appdata==nil then
				break
			end
			local temp = env_appdata.."/Paracraft/"
			temp = commonlib.Files.ToCanonicalFilePath(temp)
			if not ParaIO.DoesFileExist(temp) then
				if not lfs.mkdir(temp) then
					print("-----创建目录失败",temp)
					break
				end
			end
			ret = temp
		until true 
		Files._AppDataDirectory = ret
	end

	if ParaIO.GetWritablePath()~=Files._AppDataDirectory then
		local temp = Files._AppDataDirectory
		local subPaths = {"Database",}
		for _,val in ipairs(subPaths) do
			local temp = temp..val
			if not ParaIO.DoesFileExist(temp) then
				if not lfs.mkdir(temp) then
					print("-----创建目录失败",temp)
				end
			end
		end
	end
		
	return Files._AppDataDirectory
end

-- only return the sub folders of the current folder
-- @param output: table of output. if nil, an empty one is created and returned. each item is {filename,filesize,writedate, createdate, fileattr, accessdate}
-- @param rootfolder: the folder which will be searched. like "model", "worlds/MyWorlds/"
-- @param nMaxFileLevels: max file levels. 0 shows files in the current directory. it defaults to 0. 
-- This must be 0 when zipfile is not nil. However, one can use regular expressions (like ":.") to search deep in to sub folders in one query. 
-- @param nMaxFilesNum: one can limit the total number of files in the search result. Default value is 50. the search will stop at this value even there are more matching files.
-- @param filter: a function({filename, filesize, writedate}) return true or false end.  
--  it can also be a wildcard string, like "*.", "*", "world/*.abc", "*.*", 
--  or a regular expression that begins with ":", like ":." if zipfile is "*.zip"
-- @param zipfile: nil or "*.zip" or "*.*" or "[filepath].zip". if nil only disk files are searched. if "*.zip", all zip files are searched. It can also be a given zip file name. 
-- @return a table array containing relative to rootfolder file name.
function Files.Find(output, rootfolder,nMaxFileLevels, nMaxFilesNum, filter, zipfile)
	if(rootfolder == nil) then return; end
	local filterStr;
	if(type(filter) == "string") then 
		filterStr = filter 
		filter = nil;
	elseif(type(filter) == "function") then 	
		filterStr = "*.*";
	else
		filterStr = "*.";
	end
	
	if(rootfolder~="" and not string.find(rootfolder, "[/\\]$")) then
		rootfolder = rootfolder.."/"
	end
	
	output = output or {};
	local sInitDir;
	if((not zipfile or zipfile == "") and not Files.IsAbsolutePath(rootfolder)) then
		sInitDir = ParaIO.GetWritablePath() .. rootfolder;
	else
		sInitDir = rootfolder;
	end
	local search_result = ParaIO.SearchFiles(sInitDir,filterStr, zipfile or "", nMaxFileLevels or 0, nMaxFilesNum or 50, 0);
	local nCount = search_result:GetNumOfResult();		
	local nextIndex = #output+1;
	local i;
	local item;
	for i = 0, nCount-1 do 
		item = search_result:GetItemData(i, {});
		if (filter) then
			if(filter(item)) then
				output[nextIndex] = item
				nextIndex = nextIndex + 1;
			end
		else	
			output[nextIndex] = item
			nextIndex = nextIndex + 1;
		end
	end
	
	-- sort output by file.writedate
	table.sort(output, function(a, b)
		return (a.filename < b.filename)
	end)
	search_result:Release();
	return output;
end

--[[ search files and directories in a given path. Results are returned in a table array. 
e.g. commonlib.SearchFiles(o, "temp/", "*.txt", 0, 150, true)
Users can override the default behaviors of the UI controls. the Default behavior is this:
	listbox_dir shows directories, and is initialized to display sub directories of sInitDir.
	single click an item will display files in that directory in listbox_file.
	double click an item will display sub directories in listbox_dir.
@param output: values are stored in the out arrays. it must be a table.
@param sInitDir: the initial directory. it must ends with slash /
@param sFilePattern: e.g."*.", "*.x" or it could be table like {"*.lua", "*.raw"}
@param nMaxFileLevels: max file levels. 0 shows files in the current directory.
@param nMaxNumFiles: max number of files in file listbox. e.g. 150
@param listFile: True to include file. This can be nil. 
@param listDir: True to include directory. This can be nil. 
@param zipfile: nil or "*.zip" or "*.*" or "[filepath].zip". if nil only disk files are searched. if "*.zip", all zip files are searched. "*.*" search in disk and then zip
]]
function Files.SearchFiles(output, sInitDir, sFilePattern, nMaxFileLevels, nMaxNumFiles, listFile, listDir, zipfile)
	if(type(sFilePattern) == "table")then
		local i, sValue;
		for i, sValue in ipairs(sFilePattern) do
			Files.SearchFiles(output, sInitDir, sValue, nMaxFileLevels, nMaxNumFiles, listFile, listDir, zipfile);
		end
		return output;
	end
	
	if(listFile) then
		-- list all files in the initial directory.
		local search_result = ParaIO.SearchFiles(sInitDir,sFilePattern, zipfile or "", nMaxFileLevels, nMaxNumFiles, 0);
		local nCount = search_result:GetNumOfResult();
		
		local nextIndex = #(output)+1;
		local i;
		for i = 0, nCount-1 do 
			output[nextIndex] = search_result:GetItem(i);
			nextIndex = nextIndex + 1;
		end
		search_result:Release();
	end
	
	if(listDir ~=nil) then
		-- list all files in the initial directory.
		local search_result = ParaIO.SearchFiles(sInitDir,"*.", zipfile or "", 0, nMaxNumFiles, 0);
		local nCount = search_result:GetNumOfResult();
		
		local nextIndex = #(output)+1;
		local i;
		for i = 0, nCount-1 do 
			output[nextIndex] = search_result:GetItem(i);
			nextIndex = nextIndex + 1;
		end
		search_result:Release();
	end
	return output;
end


-- @param foldername: any local folder to be deleted
-- @return true if everything is deleted. 
function Files.DeleteFolder(foldername)
	local targetDir = foldername:gsub("[/\\]$", "");
	local bSucceed = ParaIO.DeleteFile(targetDir.."/*.*");
	bSucceed = ParaIO.DeleteFile(targetDir.."/") and bSucceed;
	if(bSucceed) then  
		return true;
	end
end

-- it will change the folder's modification time to current time. 
function Files.TouchFolder(foldername)
	-- this is tricky, we will simply create a temporary file and delete it. 
	local targetDir = foldername:gsub("[/\\]$", "");
	local tmpFilename = targetDir.."/_touch.timestamp";
	local file = ParaIO.open(tmpFilename, "w")
	file:close();
	ParaIO.DeleteFile(tmpFilename);
end

--[[
"WinterCamp2021-main/nplm.json" 
to:
"WinterCamp2021-main","nplm.json"
--]]
--https://github.com/moteus/lua-path/blob/master/lua/path.lua#L153
-- return: dir, name
function Files.splitPath(filepath)
     return string.match(filepath,"^(.-)[\\/]?([^\\/]*)$")
end
--[[
"WinterCamp2021-main/nplm.json" 
to:
"WinterCamp2021-main/nplm",".json"
--]]
-- return path, extension
function Files.splitText(filepath)
     local s1,s2 = string.match(filepath,"(.-[^\\/.])(%.[^\\/.]*)$")
    if s1 then return s1,s2 end
    return filepath, ''
end

function Files.CreateDirectory(path)
	local segmentationArray = {}

	for segmentation in string.gmatch(path, "[^/]+") do
		segmentationArray[#segmentationArray + 1] = segmentation;
	end

	local isRootAbsolutePath = false;

	if (System.os.GetPlatform() ~= "win32") then
		if string.match(path, '^/') then
			isRootAbsolutePath = true;
		end
	end

	local curFolder = "";

	for key, item in ipairs(segmentationArray) do
		curFolder = curFolder .. item .. "/"

		if (key == 1) then
			if (System.os.GetPlatform() ~= "win32") then
				if (isRootAbsolutePath) then
					curFolder = "/" .. curFolder;
				end
			end
		end

		if (not ParaIO.DoesFileExist(curFolder)) then
			ParaIO.CreateDirectory(curFolder);
		end
	end
end

function Files.CopyFolder(src, dest)
	if (not src or
		not dest or
		type(src) ~= "string" or
		type(dest) ~= "string") then
		return;
	end

	local finished = false;
	local curSrc = src;
	local curDest = dest;
	local folders = {};

	-- check dest folder exist
	if (not ParaIO.DoesFileExist(dest)) then
		Files.CreateDirectory(dest);
	end

	local function FindFiles()
		if (#folders > 0) then
			curSrc = folders[#folders].srcPath;
			curDest = folders[#folders].destPath;
			table.remove(folders);
		end

		local result = Files.Find({}, curSrc, 0, 10000, "*");

		for key, item in ipairs(result) do
			if (item.fileattr == 32) then
				-- file
				local srcFile = curSrc.."/"..item.filename;
				local destFile = curDest .. "/" .. item.filename;

				ParaIO.CopyFile(srcFile, destFile, true);
			else
				-- folder
				ParaIO.CreateDirectory(curDest .. "/" .. item.filename .. "/");

				folders[#folders + 1] = {
					srcPath = curSrc .. "/" .. item.filename,
					destPath = curDest .. "/" .. item.filename,
				}
			end
		end

		if (#folders == 0) then
			finished = true;
		end
	end

	while (not finished) do
		FindFiles();
	end
end

function Files.MoveFolder(src, dest)
	if (not src or
		not dest or
		type(src) ~= "string" or
		type(dest) ~= "string") then
		return;
	end

	if (not string.match(src, "/$")) then
		src = src .. "/"
	end

	local finished = false;
	local curSrc = src;
	local curDest = dest;
	local folders = {};

	-- check dest folder exist
	if (not ParaIO.DoesFileExist(dest)) then
		Files.CreateDirectory(dest);
	end

	local function FindFiles()
		if (#folders > 0) then
			curSrc = folders[#folders].srcPath;
			curDest = folders[#folders].destPath;
			table.remove(folders);
		end

		local result = Files.Find({}, curSrc, 0, 10000, "*");

		for key, item in ipairs(result) do
			if (item.fileattr == 32) then
				-- file
				local srcFile = curSrc.."/"..item.filename;
				local destFile = curDest .. "/" .. item.filename;

				ParaIO.MoveFile(srcFile, destFile);
			else
				-- folder
				ParaIO.CreateDirectory(curDest .. "/" .. item.filename .. "/");

				folders[#folders + 1] = {
					srcPath = curSrc .. "/" .. item.filename,
					destPath = curDest .. "/" .. item.filename,
				}
			end
		end

		if (#folders == 0) then
			finished = true;
		end
	end

	while (not finished) do
		FindFiles();
	end

	ParaIO.DeleteFile(src);
end

-- 获取文件内容
function Files.GetFileText(filename)
	if filename==nil or filename=="" then
		return
	end
    local file = ParaIO.open(filename , "rb");
	if(file:IsValid()) then
		local text = file:GetText(0, -1);
		file:close();
		return text;
    else
        file:close();
	end	
end

-- 写文件
function Files.WriteFile(filename, text)
    if text==nil or text=="" then
        return
    end
	filename = Files.ToCanonicalFilePath(filename)
    local div = (System.os.GetPlatform()=="win32") and "\\" or "/"
    local patt = string.format("[^%s]+%s",div,div)
    local temp = ""
    for k,v in string.gmatch(filename,patt) do
        temp = temp .. k
        if not ParaIO.DoesFileExist(temp) then
            ParaIO.CreateDirectory(temp);
        end
    end

    local file = ParaIO.open(filename , "wb");
	if(file:IsValid()) then
		file:WriteString(text, #text);
		file:close();
		return true
    else
        file:close();
	end	
end

-- 获取文件大小
function Files.GetFileSize(filename)
    local file = ParaIO.open(filename , "rb");
	if(file:IsValid()) then
		local size = file:GetFileSize();
		file:close();
		return size;
    else
        print("------不可用",filename)
        file:close();
	end	
    return 0
end

--[[
	下载远程text文件到本地，并保存eTag
	如有本地且没过期直接使用本地
	下次如果返回304代表文件没有变过，直接返回本地内容
	commonlib.Files.GetRemoteFileText({
		url = "",
		filepath = "D:/ass/jjj/kkk/xxx_full.p",
		cachePolicy = "access plus 10 minutes",
		callback = function(data)end
	})
]]
function Files.GetRemoteFileText(url,filepath,callback,tokenRequired)
	local cachePolicy
	if type(url)=="table" and filepath==nil and callback==nil then
		filepath = url.filepath
		callback = url.callback
		cachePolicy = url.cachePolicy
		tokenRequired = url.tokenRequired
		url = url.url 
	end

	if url==nil or url=="" then
		return
	end

	if (not filepath or filepath == "") then
		local filename = string.gsub(url, ".*/", "");
		filename = string.gsub(filename, "[%?#].*$", "");
		filename = string.gsub(filename, "[^%w_%-]", "");

		if (#filename > 15) then
			filename = string.sub(filename, 1, 15);
		end

		filepath = string.format("%s%s-%s", ParaIO.GetWritablePath().."temp/filecache/", ParaGlobal.GenerateUniqueID(), filename);
	end

	local onComplete = function(data,cachePath)
		if callback then
			callback(data,cachePath,filepath)
		end
		if cachePath and filepath~=cachePath then
			ParaIO.CopyFile(cachePath, filepath, true)
		end
	end

	local key = "Files.GetRemoteFileText:"..url
	local ls = System.localserver.CreateStore(nil, 1);
	local eTag = nil
	if ls then
		item = ls:GetItem(key)
	end
	
	local cp = System.localserver.CachePolicies["1 day"];
	if cachePolicy then
		cp = System.localserver.CachePolicy:new(cachePolicy)
	end

	local _cachedFilepath = filepath
	if item then
		if item.payload.cached_filepath then
			_cachedFilepath = item.payload.cached_filepath
		else
			local data = commonlib.LoadTableFromString(item.data)
			if data then
				_cachedFilepath = data.filepath
			end
		end
		if ParaIO.DoesFileExist(_cachedFilepath) then
			eTag = item.payload:GetHeader("ETag")
			local expireTime = item.payload.creation_date;
			if(not cp:IsExpired(expireTime)) then --没过期直接用
				local data = Files.GetFileText(_cachedFilepath)
				if data then
					onComplete(data,_cachedFilepath)
					return
				end
			end
		end
	end
	
	local input = {
		url = url,
		headers = {
			["If-None-Match"] = eTag
		}
	}
	if tokenRequired then
		local token = commonlib.getfield("System.User.keepworktoken")
		input.headers["Authorization"] = string.format("Bearer %s",token or "");
		input.json=true
		input.method="GET"
	end

	System.os.GetUrl(input, function(err, msg, data)
		-- print("------err",err)
		-- print("--msg",msg.header)
		if err==200 then
			repeat
				if not Files.WriteFile(filepath, data) then
					_cachedFilepath = nil
					break
				end
				if not ls then break end
				item = {
					entry = System.localserver.WebCacheDB.EntryInfo:new({
						url = key,
					}),
					payload = System.localserver.WebCacheDB.PayloadInfo:new({
						status_code = System.localserver.HttpConstants.HTTP_OK,
						headers = msg.header,
						cached_filepath = filepath,
						data = {
							filepath = filepath,
							url = url,
						}
					}),
				}
				if not ls:PutItem(item, false) then
				end
			until true
			onComplete(data,_cachedFilepath)
		elseif err==304 then --远程文件没有发生改变
			data = Files.GetFileText(_cachedFilepath)
			onComplete(data,_cachedFilepath)
		else
			data = Files.GetFileText(_cachedFilepath)
			onComplete(data,_cachedFilepath)
		end
	end)
end