--[[
Title: Zip/Unzip helper class
Author(s): LiXizhi, 
Date: 2017/7/20
Desc: unzip/zip zip or paraengine's pkg file. pkg file is auto discovered in file header.
use the lib:
------------------------------------------------------------
-- unzip zip file to disk
NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
local ZipFile = commonlib.gettable("System.Util.ZipFile");
local zipFile = ZipFile:new();
if(zipFile:open("temp/test.zip")) then
	zipFile:unzip();
	zipFile:close();
end

-- static functions
ZipFile.GeneratePkgFile("temp/test.zip")
ZipFile.GeneratePkgFile("temp/test.xml", "temp/test.xml")
echo(ZipFile.IsZipFile("temp/test.bin"))

-- create zip file
NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
local ZipFile = commonlib.gettable("System.Util.ZipFile");
local zipFile = ZipFile:new();
if(zipFile:open("d:\\simple.zip", "w")) then
	zipFile:ZipAdd("test/version.txt", "version.txt");
	zipFile:ZipAddData("hello.txt", "hello world");
	zipFile:ZipAddFolder("test");
	zipFile:AddDirectory("worlds/", ParaIO.GetWritablePath().."worlds/*.", 4);
	zipFile:AddDirectory("worlds/", ParaIO.GetWritablePath().."worlds/*.*", 2);
	zipFile:close();
	zipFile:SaveAsPKG()
end

-- create zip from package list file
NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
local ZipFile = commonlib.gettable("System.Util.ZipFile");
local zipFile = ZipFile:new();
if(zipFile:open("d:\\simple.zip", "w")) then
	zipFile::SetAutoCompileNPLFile(true)
	zipFile:AddFromPackageList({"bin/script/test/*.o", "!bin/script/test/network/"})
	--zipFile:AddFromPackageListFile("packages/redist/paracraft-mini.txt")
	zipFile:close();
end
------------------------------------------------------------
]]
local ZipFile = commonlib.inherit(nil, commonlib.gettable("System.Util.ZipFile"));

function ZipFile:ctor()
end

-- public static function
-- @return true if filename is zip or pkg file
function ZipFile.IsZipFile(path)
	local file = ParaIO.open(path, "r")
    local fileType = nil
    if (file:IsValid()) then
        local o = {}
        file:ReadBytes(4, o)
        if (o[1] == 80 and o[2] == 75) then
            fileType = "zip"
		elseif (o[1] == 0x2e and o[2] == 0x70 and o[3] == 0x6b and o[4] == 0x67) then -- 2e 70 6b 67 is hex of ".pkg"
            fileType = "pkg"
        end
        file:close()
    end
    return fileType ~= nil
end

-- open or create a zip file
-- @param filename: usually absolute file path in utf8 encoding
-- @param mode: if nil, default to "r", read-only mode, or "w", which is write mode. 
function ZipFile:open(filename, mode)
	self:close()
	mode = mode or "r"
	self.filename = filename;
	if(mode == "r") then
		if(ParaAsset.OpenArchive(self.filename, true)) then
			self.zip_archive = ParaEngine.GetAttributeObject():GetChild("AssetManager"):GetChild("CFileManager"):GetChild(self.filename);
			-- 	zipParentDir is usually the parent directory "temp/" of zip file. 
			self.zipParentDir = self.zip_archive:GetField("RootDirectory", "");
			return true;
		end
	elseif(mode == "w") then
		self.zip_writer = ParaIO.CreateZip(filename, "");
		return true;
	end
end

function ZipFile:close()
	if(self.zip_archive) then
		ParaAsset.CloseArchive(self.filename);
		self.zip_archive = nil;
	end
	if(self.zip_writer) then
		self.zip_writer:close()
		self.zip_writer = nil
	end
end

------------------------
-- writer functions
------------------------

-- add a zip file to the zip. file call this for each file to be added to the zip.
-- @param destName: destName in zip file
-- @param fromFile: full disk path. if this is nil, destName is used, and its file name is used as destName 
-- @return: 0 if succeed.
function ZipFile:ZipAdd(destName, fromFile)
	if(self.zip_writer and destName) then
		if(not fromFile) then
			fromFile = destName;
			destName = destName:match("[^/\\]+$");
		end
		return self.zip_writer:ZipAdd(destName, fromFile);
	end
end

-- add a binary data to the zip.
-- @param destName: destName in zip file
-- @param fileData: binary data as string
-- @return: 0 if succeed.
function ZipFile:ZipAddData(destName, fileData)
	if(self.zip_writer and destName and fileData) then
		return self.zip_writer:ZipAddData(destName, fileData);
	end
end

-- add a zip folder to the zip file. call this for each folder to be added to the zip.
-- @return: 0 if succeed.
function ZipFile:ZipAddFolder(destZipFolderName)
	if(self.zip_writer and destZipFolderName) then
		return self.zip_writer:ZipAddFolder(destZipFolderName)
	end
end

-- add everything in side a directory to the zip.
-- e.g. AddDirectory("myworld/", "worlds/myworld/ *.*", 10);
-- @param dstzn: all files in fn will be appended with this string to be saved in the zip file.
-- @param filepattern: file patterns, which can include wild characters in the file portion.
-- @param nSubLevel: sub directory levels. default to 0, 0 means only files at parent directory.
-- @return: 0 if succeed.
function ZipFile:AddDirectory(destName, filepattern, nSubLevel)
	if(self.zip_writer and destName and filepattern) then
		nSubLevel = nSubLevel or 0;
		return self.zip_writer:AddDirectory(destName, filepattern, nSubLevel)
	end
end

-- @param destName: such as "test.pkg", if nil, we will generate pkg in self.filename source directory. 
function ZipFile:SaveAsPKG(destName)
	ZipFile.GeneratePkgFile(self.filename, destName)
end

-- auto compile script/*.lua to bin/script/*.o
function ZipFile:SetAutoCompileNPLFile(bEnable)
	self.bAutoCompileNPLFile = bEnable;
end

-- virtual function
-- @param list: mapping from disk file name to local filename
function ZipFile:OnAfterGeneratePackageList(list)
	if(self.bAutoCompileNPLFile) then
		local compiledFiles = {}
		for diskFilename, filename in pairs(list) do
			if(filename:match("^script/.*%.lua$")) then
				compiledFiles[diskFilename] = filename;
			end
		end
		for diskFilename, filename in pairs(compiledFiles) do
			if(NPL.CompileFiles(filename, "-stripcomments")) then
				list[diskFilename] = nil;
				local compiledFilename = filename:gsub("^(.+)(lua)$", "bin/%1o")
				local compiledDiskFilename = (diskFilename:sub(1, #diskFilename - #filename) or "") .. compiledFilename
				list[compiledDiskFilename] = compiledFilename;
			else
				self.errorCount = (self.errorCount or 0) + 1
				LOG.std(nil, "error", "ZipFile", "failed to compile: %s", filename);
			end
		end
	end
end

-- @param filename: the file format is like .gitignore, but has the opposite meaning. 
function ZipFile:AddFromPackageListFile(filename)
	filename = filename or "packages/redist/paracraft-mini.txt"
	local line;
	local file = ParaIO.open(filename, "r");
	local filterStr;
	if(file:IsValid()) then
		local list = {};
		line=file:readline();
		while line~=nil do 		
			if(string.find(line, "%[packageName%]")~=nil) then
								
			elseif(string.find(line, "%[packagePath%]")~=nil) then
								
			elseif(string.find(line, "%[packageVersion%]")~=nil) then
				
			elseif(string.find(line, "%[filterList%]")~=nil) then
				local __,__,_filterStr = string.find(line,"%s-%[filterList%]%s-=%s-([^%s]+)%s-");
				filterStr= _filterStr
			elseif(string.find(line, "^%s*%-%-")~=nil) then
				-- ignore comments
			else
				if(line~="")then
					list[#list+1] = line;
				end
			end
				
			line=file:readline();
		end
		file:close();
		
		local filterList = {};
		if(filterStr) then
			for f in string.gfind(filterStr, "([^%s;]+)") do
				table.insert(filterList,f);
			end
		end
		return self:AddFromPackageList(list, filterList)
	else
		file:close();
	end
end

-- @param list: array of text lines, like {"bin/*.o", "textures/*.png", "!*.txt"}
-- @param filterList: can be nil. array like {"*.x", "*.png", "*.dds"} only apply to folders, not on files. 
-- @return stats: {totalFiles, errorCount} 
function ZipFile:AddFromPackageList(list, filterList)
	local writer = self.zip_writer
	if(writer) then
		self.errorCount = 0;
		local output = self:GenerateFileList(list)
		self:OnAfterGeneratePackageList(output)
		local totalFiles = 0;
		for absFilename, filename in pairs(output) do
			totalFiles = totalFiles + 1
			writer:ZipAdd(filename, absFilename);
			-- LOG.std(nil, "debug", "ZipAdd", filename); 
		end
		return {totalFiles = totalFiles, errorCount = self.errorCount or 0}
	end
end

-- @param searchpath: examples
-- [exclude]aaa/bbb/*.x ; exclude all files like *.x from directory  /aaa/bbb/ , include all subdirectory under it
-- !aaa/bbb/*.x ; same as above
-- [exclude1]aaa/bbb/*.x ; exclude files like *.x only in directory  /aaa/bbb/ , not include any subdirectory under it
-- !/aaa/bbb/*.x ; same as above
-- [exclude3]aaa/bbb/*.x ; exclude files like *.x from directory  /aaa/bbb/ , include subdirectory under it maxdepth 3 levels
-- @return excludeOption, filepath: where excludeOption is nil | "exclude" | "exclude1" | "exclude2" | "exclude3" | ...
function ZipFile:GetExcludeOptionFromString(searchpath)
	local exclude_option, filepattern = searchpath:match("^%[(%w+)%](.*)$");
	if(not exclude_option) then
		exclude_option, filepattern = searchpath:match("^(!/?)(.*)$");
		if(exclude_option) then
			exclude_option = exclude_option == "!" and "exclude" or "exclude1"
		end
	end
	return exclude_option, filepattern or searchpath;
end

-- "*.txt" is converted to ".*%.txt"
function ZipFile:FromWildCardToSearchPattern(pattern)
	local output = {}
	for i = 1, #pattern do
		local c = pattern:sub(i, i)
		if(c == "*") then
			output[#output+1] = ".*"
		elseif(c == "." or c == "(" or c == ")"  or c == "%" or c == "+" or c == "-" or c == "?") then
			output[#output+1] = "%"
			output[#output+1] = c
		else
			output[#output+1] = c
		end
	end
	return table.concat(output);
end

-- the format is like .gitignore, but has the opposite meaning. 
-- @param list: array of text lines, each line is like a line in .gitignore file
-- @param filterList: can be nil
-- @param rootPath: can be nil, this is appended before all files
-- @return output: table mapping from absolute file path to relative file path
function ZipFile:GenerateFileList(list, filterList, rootPath)
	rootPath = rootPath or ""
	
	NPL.load("(gl)script/ide/Files.lua");
	
	local output = {};
	for _, searchpath in ipairs(list) do
		local exclude_option, searchpath = self:GetExcludeOptionFromString(searchpath)
		if(not exclude_option) then
			local parent_dir, file_pattern = searchpath:match("^(.*)/([^/]+)$");
			if(parent_dir and file_pattern) then
				local parent_dir_abs = rootPath..parent_dir
				local result = commonlib.Files.Find({}, parent_dir_abs, 20, 50000, file_pattern)
				for _, item in ipairs(result) do
					if((item.filesize or 0) > 0) then
						local filename = parent_dir_abs.."/"..item.filename;
						output[filename] = parent_dir.."/"..item.filename;
					end
				end
			end
		else
			local parent_dir, file_pattern = searchpath:match("^(.*/)([^/]*)$");
			if(not parent_dir) then
				parent_dir = ""
				file_pattern = searchpath
			end
			if(file_pattern == "" and parent_dir ~= "") then
				file_pattern = "*";
			end
			if(file_pattern) then
				local pattern = self:FromWildCardToSearchPattern(file_pattern)
				pattern = "^"..pattern.."$"
				
				local excludeFiles = {}
				for absFilename, filename in pairs(output) do
					if(#filename > #parent_dir) then
						local isInFolder = true;
						for i=1, #parent_dir do
							if(filename:byte(i) ~= parent_dir:byte(i)) then
								isInFolder = false
								break
							end
						end
						if(isInFolder) then
							local relFilename = filename:sub(#parent_dir + 1, -1)
							if(exclude_option ~= "exclude1") then
								-- recursive search in parent folder
								relFilename = relFilename:match("([^/]+)$");
								if(relFilename and relFilename:match(pattern)) then
									excludeFiles[#excludeFiles+1] = absFilename;
								end
							else
								-- non-recursive search in parent folder
								if(relFilename:match(pattern)) then
									excludeFiles[#excludeFiles+1] = absFilename;
								end
							end
						end
					end
				end
				for _, filename in ipairs(excludeFiles) do
					output[filename] = nil;
				end
			end
		end
	end
	return output;
end


-- static function: convert from zip to pkg file. this function is NOT thread safe. 
-- @param fromFile: must be a zip file
-- @param toFile: if nil, we will replace fromFile's file extension from zip to pkg
-- @return true if succeed.
function ZipFile.GeneratePkgFile(fromFile, toFile)
	if(not toFile and fromFile) then
		toFile = fromFile:gsub("%.zip", ".pkg")
	end
	local result;
	if(fromFile ~= toFile) then
		return ParaAsset.GeneratePkgFile(fromFile, toFile);
	elseif(fromFile) then
		local tempFile = ParaIO.GetWritablePath().."temp/temp.pkg";
		if(ParaAsset.GeneratePkgFile(fromFile, tempFile)) then
			ParaIO.CreateDirectory(toFile);
			if(ParaIO.MoveFile(tempFile, toFile)) then
				result = true
			end
			ParaIO.DeleteFile(tempFile);
		end
	end
	return result
end

------------------------
-- reader functions
------------------------

-- just in case the zip file contains utf8 file names, we will add default encoding alias
-- so that open file will work with both file encodings in zip archive
function ZipFile:addUtf8ToDefaultAlias()
	if(self.zip_archive) then
		local IsIgnoreCase = self.zip_archive:GetField("IsIgnoreCase",true)
		-- search just in a given zip archive file
		local filesOut = {};
		-- ":.", any regular expression after : is supported. `.` match to all strings. 
		commonlib.Files.Find(filesOut, "", 0, 10000, ":.", self.filename);
		for i = 1,#filesOut do
			local item = filesOut[i];
			if(item.filesize > 0) then
				local defaultEncodingFilename = commonlib.Encoding.Utf8ToDefault(item.filename)
				if(defaultEncodingFilename ~= item.filename) then
					if(commonlib.Encoding.DefaultToUtf8(defaultEncodingFilename) == item.filename) then
						-- this item may be utf8 coded and not in ansi code page, we will add an alias
						if IsIgnoreCase then 
							self.zip_archive:SetField("AddAliasFrom", string.lower(defaultEncodingFilename))
							self.zip_archive:SetField("AddAliasTo", string.lower(item.filename))
						else
							self.zip_archive:SetField("AddAliasFrom", defaultEncodingFilename)
							self.zip_archive:SetField("AddAliasTo", item.filename)
						end
					end
				end
			end
		end
	end
end

-- @param destinationFolder: default to zip file's parent folder + [filename]/
-- return the number of file unziped
function ZipFile:unzip(destinationFolder,maxCnt)
	if(not self.zip_archive) then
		return;
	end
    maxCnt = maxCnt or 500000;
	if(not destinationFolder) then
		local parentFolder, filename = self.filename:match("^(.-)([^/\\]+)$");
		if(filename) then
			filename = filename:gsub("%.%w+$", "")
			destinationFolder = parentFolder .. filename .. "/";
		end
	end
	if(not destinationFolder) then
		return;
	end
	ParaIO.CreateDirectory(destinationFolder);

	-- search just in a given zip archive file
	local filesOut = {};
	-- ":.", any regular expression after : is supported. `.` match to all strings. 
	commonlib.Files.Find(filesOut, "", 0, maxCnt, ":.", self.filename);
	LOG.std(nil, "info", "ZipFile", "%s ( %d entries)", self.filename, #filesOut); 
	local fileCount = 0;
	-- print all files in zip file
	for i = 1, #filesOut do
		local item = filesOut[i];
		if(item.filesize > 0) then
			local file = ParaIO.open(self.zipParentDir..item.filename, "r")
			if(file:IsValid()) then
				-- get binary data
				local binData = file:GetText(0, -1);
				-- dump the first few characters in the file
				local destFileName;

				-- tricky: we do not know which encoding the filename in the zip archive is,
				-- so we will assume it is utf8, we will convert it to default and then back to utf8.
				-- if the file does not change, it might be utf8. 
				local defaultEncodingFilename = commonlib.Encoding.Utf8ToDefault(item.filename)
				if(defaultEncodingFilename == item.filename) then
					destFileName = destinationFolder..item.filename;
				else
					if(commonlib.Encoding.DefaultToUtf8(defaultEncodingFilename) == item.filename) then
						destFileName = destinationFolder..defaultEncodingFilename;
					else
						destFileName = destinationFolder..item.filename;
					end
				end

				do 
					local patt = "[^/]+/"
					local temp = ""
					for k,v in string.gmatch(destFileName,patt) do
						temp = temp .. k
						if not ParaIO.DoesFileExist(temp) then
							ParaIO.CreateDirectory(temp);
						end
					end
				end

				local outFile = ParaIO.open(destFileName, "w")
				if(outFile:IsValid()) then
					outFile:WriteString(binData, #binData);
					outFile:close();
					fileCount = fileCount + 1;
				else
					print("---------unzip error",destFileName)
				end
				file:close();
			end
		else
			-- this is a folder
			ParaIO.CreateDirectory(destinationFolder..item.filename.."/");
		end
	end

	LOG.std(nil, "info", "ZipFile", "%s is unziped to %s ( %d files)", self.filename, destinationFolder, fileCount); 
end
