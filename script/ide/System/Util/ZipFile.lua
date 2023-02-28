--[[
Title: Zip/Unzip helper class
Author(s): LiXizhi, 
Date: 2017/7/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
local ZipFile = commonlib.gettable("System.Util.ZipFile");
local zipFile = ZipFile:new();
if(zipFile:open("temp/test.zip")) then
	zipFile:unzip();
	zipFile:close();
end

ZipFile.GeneratePkgFile("temp/test.zip")
ZipFile.GeneratePkgFile("temp/test.xml", "temp/test.xml")

--unzip pkg file
local pkgPath = "D:/ass/01.03_1/main150727(1).pkg"

NPL.load("(gl)script/ide/System/Util/ZipFile.lua");
local ZipFile = commonlib.gettable("System.Util.ZipFile");
local zipFile = ZipFile:new();
if(zipFile:open(pkgPath)) then
	local num = zipFile:unzip(nil,10000*1000);
	zipFile:close();
end
------------------------------------------------------------
]]

local ZipFile = commonlib.inherit(nil, commonlib.gettable("System.Util.ZipFile"));


function ZipFile:ctor()
end

function ZipFile:open(filename)
	self.filename = filename;
	if(ParaAsset.OpenArchive(self.filename, true)) then
		self.zip_archive = ParaEngine.GetAttributeObject():GetChild("AssetManager"):GetChild("CFileManager"):GetChild(self.filename);
		-- 	zipParentDir is usually the parent directory "temp/" of zip file. 
		self.zipParentDir = self.zip_archive:GetField("RootDirectory", "");
		return true;
	end
end

function ZipFile:close()
	if(self.zip_archive) then
		ParaAsset.CloseArchive(self.filename);
		self.zip_archive = nil;
	end
end

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
    maxCnt = maxCnt or 10000;
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

	local fileCount = 0;
	-- print all files in zip file
	for i = 1,#filesOut do
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