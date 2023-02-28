--[[
Title: Log
Author(s): wxa
Date: 2020/6/30
Desc: 沙盒环境全局表
use the lib:
-------------------------------------------------------
local Log = NPL.load("script/ide/System/UI/Blockly/Sandbox/Log.lua");
-------------------------------------------------------
]]

local Log = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Log:Property("G");

local Levels = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    FATAL = 4,
    ERROR = 5,
}

function Log:ctor()
    self:Reset();
end

function Log:Init(G)
    self:SetG(G);

    return self;
end

function Log:Reset()
    self.out = "";
    self.level = Levels["DEBUG"];
end

function Log:SetLevel(level)
    self.level = Levels[string.upper(level)] or self.level;
end

function Log:Log(level, msg)
    level = string.upper(level);
    
    if ((Levels[level] or 0) < self.level) then return end

    self.out = self.out .. (string.format("[%s] ", level)) .. tostring(msg) .. "\n";

end

function Log:Debug(msg)
    self:Log("DEBUG", msg);
end

function Log:Info(msg)
    self:Log("INFO", msg);
end

function Log:Warn(msg)
    self:Log("WARN", msg);
end

function Log:Fatal(msg)
    self:Log("FATAL", msg);
end

function Log:Error(msg)
    self:Log("ERROR", msg);
end

function Log:GetText()
    return self.out;
end

function Log:Clear()
    out = "";
end