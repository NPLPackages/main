--[[
Title: UIManager
Author(s): wxa
Date: 2020/6/30
Desc: 文件管理器
use the lib:
-------------------------------------------------------
local UIManager = NPL.load("script/ide/System/UI/Blockly/Pages/UIManager.lua");
-------------------------------------------------------
]]

local UIManager = NPL.export();

local lfs = commonlib.Files.GetLuaFileSystem();
local inited = false;
local UIMap = {};
local WorldUIDirectory = "";
local CurrentFileName = "";

local function LoadUIFile(filepath)
    local io = ParaIO.open(filepath, "r");
    if(not io:IsValid()) then return nil end 
    local text = io:GetText();
    io:close();
    local ui = NPL.LoadTableFromString(text);
    return ui;
end

local function LoadUIFiles(directory)
    -- 确保目存在
    ParaIO.CreateDirectory(directory);
    -- 重置列表
    UIMap = {};
    for filename in lfs.dir(directory) do
        if (filename ~= "." and filename ~= "..") then
            local filepath = CommonLib.ToCanonicalFilePath(directory .. "/" .. filename);
            local fileattr = lfs.attributes(filepath);
            if (fileattr.mode ~= "directory") then
                local ui = LoadUIFile(filepath);
                if (ui) then UIMap[filename] = ui end
            end
        end
    end
end

local function OnWorldLoaded()
    local directory = CommonLib.ToCanonicalFilePath(CommonLib.GetWorldDirectory() .. "/blockly/ui/");
    if (directory == WorldUIDirectory) then return end
    --保存目录    
    WorldUIDirectory = directory;
    --加载数据
    LoadUIFiles(WorldUIDirectory);
end

local function OnWorldUnloaded()
end

function UIManager.StaticInit()
    if (inited) then return UIManager end
    inited = true;
    GameLogic:Connect("WorldLoaded", nil, OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", nil, OnWorldUnloaded, "UniqueConnection");
    
    OnWorldLoaded();

    return UIManager;
end

function UIManager.GetUIByFileName(filename)
    if (not filename or filename == "") then return end
    return UIMap[filename];
end

function UIManager.SetUIByFileName(filename, ui)
    if (not filename or filename == "") then return end
    UIMap[filename] = ui;
end

function UIManager.SaveUI(filename)
    ui = UIManager.GetUIByFileName(filename);
    if (not ui) then return false end
    UIMap[filename] = ui;
    local filepath = CommonLib.ToCanonicalFilePath(WorldUIDirectory ..  "/" .. filename);
    local text = commonlib.serialize_compact(ui);
    local io = ParaIO.open(filepath, "w");
	io:WriteString(text);
    io:close();
    return true;
end

function UIManager.DeleteUI(filename)
    local ui = UIManager.GetUIByFileName(filename);
    if (not ui) then return end
    ParaIO.DeleteFile(ui.filepath);
end

function UIManager.SetCurrentFileName(filename)
    CurrentFileName = filename;
end

function UIManager.GetFileNameList()
    local filenames = {};
    for filename in pairs(UIMap) do
        filenames[#filenames + 1] = filename;
    end
    return filenames;
end

UIManager.StaticInit();

