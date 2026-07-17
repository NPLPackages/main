
--[[
Title: String
Author(s):  wxa
Date: 2020-06-12
Desc: String 
use the lib:
------------------------------------------------------------
local String = NPL.load("script/ide/System/Util/String.lua");
------------------------------------------------------------
]]

local String = NPL.export();

function String.Trim(str, ch)
    ch = ch or "%s";
    str = string.gsub(str, "^" .. ch .. "*", "");
    str = string.gsub(str, ch .. "*$", "");
    return str;
end

function String.Find(str, substr)
    return string.find(str, substr, 1, true);
end

-- concartinate param1 and param2
-- @param param1: if param1 is table we will use table.concat to concartinate the table
function String.join(param1, param2)
    if(type(params) == "table") then
        return table.concat(param1, param2)
    else
        return tostring(param1 or "")..tostring(param2 or "");
    end
end

