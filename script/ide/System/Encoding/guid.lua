--[[
Title: GUID
Author(s): simple guid or uuid generation using random seed
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Encoding/guid.lua");
local guid = commonlib.gettable("System.Encoding.guid");
echo(guid.uuid());
echo(guid.uuid());
-------------------------------------------------------
]]
-- TODO: for more advanced seed
math.randomseed(ParaGlobal.timeGetTime()); 

local guid = commonlib.gettable("System.Encoding.guid");
local format = string.format;
local random = math.random

function guid.uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return format('%x', v)
    end)
end