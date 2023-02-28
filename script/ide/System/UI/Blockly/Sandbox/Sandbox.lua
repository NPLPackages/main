--[[
Title: Sandbox
Author(s): wxa
Date: 2020/6/30
Desc: npl 代码执行环境
use the lib:
-------------------------------------------------------
local Sandbox = NPL.load("script/ide/System/UI/Blockly/Sandbox/Sandbox.lua");
-------------------------------------------------------
]]

local G = NPL.load("./G.lua", IsDevEnv);
local FileManager = NPL.load("../Pages/FileManager");
local Blockly = NPL.load("../Blockly.lua");

local Sandbox = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

Sandbox:Property("G");
Sandbox:Property("BlocklyInstance");

function Sandbox:ctor()
    self:SetG(G:new():Init(nil, self));
    self:SetBlocklyInstance(Blockly:new());
end

function Sandbox:Init()
    if (self.inited) then return end
    self.inited = true;

    GameLogic:Connect("WorldLoaded", self, self.OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", self, self.OnWorldUnloaded, "UniqueConnection");
end

function Sandbox:OnWorldLoaded()
    FileManager:SwitchDirectory();
    FileManager:LoadAll();
    local blocklyInstance = self:GetBlocklyInstance();
    local allcode = "";
    FileManager:Each(function(file)
        local text = file.text;
        blocklyInstance:LoadFromXmlNodeText(text);
        allcode =  allcode .. (string.format("\n-- %s\n", file.filename)) .. blocklyInstance:GetCode();
    end);
    allcode = allcode .. "\n--noitfy ready\nEvent:Emit('__ready__')";
    self:ExecCode(allcode);
end

function Sandbox:OnWorldUnloaded()

end

function Sandbox:ExecCode(code)
    -- 清空输出缓存区
    local G = self:GetG();
    G:Reset();

    if (type(code) ~= "string" or code == "") then return "" end

    local func, errmsg = loadstring(code);
    if (not func) then 
        print("===============================Exec Code Error=================================", errmsg) 
        return "";
    end

    setfenv(func, G);

    xpcall(function()
        func();
    end, function(errinfo) 
        print("ERROR:", errinfo)
        DebugStack();
    end);

    return G.Log:GetText();
end


-- 初始化成单列模式
Sandbox:InitSingleton();