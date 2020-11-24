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
	if(System.os.GetPlatform()=="win32") then
		filename = filename:gsub("/", "\\");
	else
		filename = filename:gsub("\\", "/");
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