--[[
Title: Helper
Author(s): wxa
Date: 2020/6/30
Desc: 辅助类, 一些工具函数实现
use the lib:
-------------------------------------------------------
local Helper = NPL.load("script/ide/System/UI/Vue/Helper.lua");
-------------------------------------------------------
]]

local Helper = (NPL and NPL.export) and NPL.export() or {};

-- such as %ui% when including file
local PathAliasMap = {
    ["ggs"] = "Mod/GeneralGameServerMod/",
    ["ui"] = "script/ide/System/UI",
    ["tutorial"] = "Mod/GeneralGameServerMod/Tutorial",
    ["vue"] = "script/ide/System/UI/Vue",
    ["gi"] = "Mod/GeneralGameServerMod/GI",
    ["world_directory"] = function() 
        return GameLogic.GetWorldDirectory();
    end
}; 

local function ToCanonicalFilePath(filename)
	filename = string.gsub(filename, "\\+", "/");
    filename = string.gsub(filename, "//+", "/");
	return filename;
end

local FileCacheMap = {};

function Helper.SetPathAlias(alias, path)
    PathAliasMap[string.lower(alias)] = path or "";
end

-- 格式化文件名
function Helper.FormatFilename(filename)
    local path = string.gsub(filename or "", "%%(.-)%%", function(alias)
        local path = PathAliasMap[string.lower(alias)];
        if (type(path) == "string") then return path end
        if (type(path) == "function") then return path() end
        return "";
    end);
    path = string.gsub(path, "^@", GameLogic.GetWorldDirectory());
    return string.gsub(path, "/+", "/");
end

-- 获取脚本文件
function Helper.ReadFile(filename)
	-- filename = commonlib.Encoding.Utf8ToDefault(filename);
    filename = ToCanonicalFilePath(Helper.FormatFilename(filename));
    if (not filename or filename ==  "") then return end
    if (not IsDevEnv and FileCacheMap[filename]) then return FileCacheMap[filename] end
    
    -- GGS.INFO("读取文件: " .. filename);
    local filepath = NPL.GetScriptDiskFilepath(filename)
    if(filepath) then
        local text;
	    local file = ParaIO.open(filepath, "r");
        if(file:IsValid()) then
            text = file:GetText(0, -1);
            file:close();
        end
        FileCacheMap[filename] = text;
        return text;
    else
        echo(string.format("ERROR: read file failed: %s ", filename));
    end
end

local BeginTime = 0;
function Helper.BeginTime()
    BeginTime = ParaGlobal.timeGetTime();
end

function Helper.EndTime(action, isResetBeginTime)
    local curTime = ParaGlobal.timeGetTime();
    GGS.INFO.Format("%s 耗时: %sms", action or "", curTime - BeginTime);
    if (isResetBeginTime) then BeginTime = curTime end
end


-- local Page = NPL.load("script/ide/System/UI/Page.lua");
-- --Page.ShowVueTestPage(nil, { url = "@/code/ui/测试.html", draggable=false, width = "80%",  height = "80%" });
-- Page.ShowVueTestPage({}, { url = "%vue%/Example/Canvas.html",  });

