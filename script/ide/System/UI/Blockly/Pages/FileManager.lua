--[[
Title: FileManager
Author(s): wxa
Date: 2020/6/30
Desc: 文件管理器
use the lib:
-------------------------------------------------------
local FileManager = NPL.load("script/ide/System/UI/Blockly/Pages/FileManager.lua");
-------------------------------------------------------
]]

local FileManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local lfs = commonlib.Files.GetLuaFileSystem();
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");

FileManager:Property("Directory", "");  -- 目录
FileManager:Property("FileName", "");   -- 当前文件名
FileManager:Property("Blockly");        -- Blockly
FileManager:Property("DefaultFileName", "index.xml");  -- 默认文件

local function ToCanonicalFilePath(filename)
	if(System.os.GetPlatform()=="win32") then
        filename = string.gsub(filename, "/+", "\\");
		filename = string.gsub(filename, "\\+", "\\");
	else
		filename = string.gsub(filename, "\\+", "/");
        filename = string.gsub(filename, "/+", "/");
	end
	return filename;
end

function FileManager:ctor()
    self.files = {};
end

function FileManager:GetDefaultDirectory()
    return ToCanonicalFilePath(ParaIO.GetCurDirectory(0) .. ParaWorld.GetWorldDirectory() .. "/blockly/");
end

function FileManager:Init(blockly)
    if (self.inited) then return end
    self.inited = true;

    self:SetBlockly(blockly);

    local directory = self:GetDefaultDirectory();

    -- 确保目存在
    ParaIO.CreateDirectory(directory);

    self:SwitchDirectory(directory);

    return self;
end

-- 新建文件
function FileManager:NewFile(filename)
    if (not string.match(filename, "%.xml$")) then filename = filename .. ".xml" end

    if (self.files[filename]) then return end

    self.files[filename] = {
        filepath = ToCanonicalFilePath(self:GetDirectory() .. "/" .. filename),
        filename = filename,
        text = ""
    }

    return self.files[filename];
end

-- 移除文件
function FileManager:DeleteFile(filename)
    local file = self.files[filename];
    if (not file) then return end
    ParaIO.DeleteFile(file.filepath);
end

-- 编辑
function FileManager:EditFile(filename)
    if (filename == self:GetFileName()) then return end
    
    -- print("-----------edit file---------------", filename);
    
    self:Save();

    self:SetFileName(filename);

    local text = self:Load();

    local blockly = self:GetBlockly();
    if (not blockly) then return end

    blockly:LoadFromXmlNodeText(text);
end

-- 切换目录
function FileManager:SwitchDirectory(directory)
    directory = directory or self:GetDefaultDirectory();

    if (self:GetDirectory() == directory) then return end

    self:SetDirectory(directory);

    self.files = {};
    for filename in lfs.dir(directory) do
        if (filename ~= "." and filename ~= "..") then
            local filepath = ToCanonicalFilePath(directory .. "/" .. filename);
            local fileattr = lfs.attributes(filepath);

            if (fileattr.mode ~= "directory" and string.match(filename, "%.xml$")) then
                self.files[filename] = {
                    filename = filename,
                    filepath = filepath,
                };
            end
        end
    end

    local defaultFileName = self:GetDefaultFileName();
    if (not self.files[defaultFileName]) then
        self.files[defaultFileName] = {
            filepath = ToCanonicalFilePath(self:GetDirectory() .. "/" .. defaultFileName);
            filename = defaultFileName,
            text = "",
        }
    end
end

-- 获取默认文件
function FileManager:GetDefaultFile()
    return self.files[self:GetDefaultFileName()];
end

-- 编辑默认文件
function FileManager:EditDefaultFile()
    return self:EditFile(self:GetDefaultFileName());
end 

-- 获取文件集
function FileManager:GetFileList()
    local filelist = {};
    for filename in pairs(self.files) do table.insert(filelist, {filename = filename}) end
    return filelist;
end

-- 保存当前文件
function FileManager:Save(text)
    local filename = self:GetFileName();
    local file = self.files[filename];
    if (not file) then return false end
    file.text = text or file.text or "";
    local io = ParaIO.open(file.filepath, "w");
	io:WriteString(file.text);
    io:close();
    return true;
end

-- 加载文件
function FileManager:Load(filename)
    filename = filename or self:GetFileName();
    if (not filename) then return "" end
    local file = self.files[filename];
    if (file and file.text) then return file.text end
    local io = ParaIO.open(file.filepath, "r");
    local text = "";
    if(io:IsValid()) then 
        text = io:GetText();
        io:close();
    end
    file.text = text;
    return file.text;
end

-- 加载所有文件
function FileManager:LoadAll()
    for filename in pairs(self.files) do 
        self:Load(filename);
    end
end

-- 遍历
function FileManager:Each(callback)
    for _, file in pairs(self.files) do
        callback(file);
    end
end

function FileManager:Show(Blockly)
    self:SetBlockly(Blockly);
    Page.Show({
        Blockly = Blockly,
        FileManager = FileManager,
    }, {
        url = "%ui%/Blockly/Pages/FileManager.html",
        width = 600,
        height = 500,
        zorder = 1,
    });
end

FileManager:InitSingleton():Init();