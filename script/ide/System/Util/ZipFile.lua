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

-- @param destinationFolder: default to zip file's parent folder + [filename]/
-- return the number of file unziped
function ZipFile:unzip(destinationFolder)
	if(not self.zip_archive) then
		return;
	end
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
	commonlib.Files.Find(filesOut, "", 0, 10000, ":.", self.filename);

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
				local destFileName = destinationFolder..item.filename;
				local outFile = ParaIO.open(destFileName, "w")
				if(outFile:IsValid()) then
					outFile:WriteString(binData, #binData);
					outFile:close();
					fileCount = fileCount + 1;
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

