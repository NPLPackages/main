--[[
Title: Global
Author(s): wxa
Date: 2020/6/30
Desc: 沙盒环境全局表
use the lib:
-------------------------------------------------------
local G = NPL.load("script/ide/System/UI/Blockly/Sandbox/G.lua");
-------------------------------------------------------
]]

local Log = NPL.load("./Log.lua", IsDevEnv);
local Event = NPL.load("./Event.lua", IsDevEnv);
local G = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

G:Property("G");

function G:ctor()
end

function G:Init(g)
    g = setmetatable(g or {}, {__index = _G});
    
    for method in pairs(G) do
        if (type(rawget(G, method)) == "function" and method ~= "ctor" and method ~= "Init") then
            g[method] = function(...) 
                return self[method](self, ...);
            end
        end
    end

    self:SetG(g);

    g.Log = Log:new():Init(g);
    g.Event = Event:new():Init(g);
    g._G = g;
    
    return g;
end

function G:Reset()
    local g = self:GetG();
    g.Log:Reset();
    g.Event:Reset();
end
