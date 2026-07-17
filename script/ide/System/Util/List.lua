--[[
Title: List
Author(s):  wxa
Date: 2020-06-12
Desc: 列表相关操作
use the lib:
------------------------------------------------------------
local List = NPL.load("script/ide/System/Util/List.lua");
------------------------------------------------------------
]]

local List = NPL.export()

function List.GetIndexByItem(list, item)
    if (type(list) ~= "table") then return nil end
    for index, val in ipairs(list) do
        if (val == item) then return index end
    end
    return nil;
end

function List.IsExistItem(list, item)
    if (type(list) ~= "table") then return false end
    for index, val in ipairs(list) do
        if (val == item) then return true end
    end
    return false;
end

function List.Insert(list, index, item) 
    if (type(list) ~= "table") then return nil end
    if (index ~= nil and item == nil) then item, index = index, #list + 1 end
    return table.insert(list, index, item);
end

function List.Remove(list, index)
    if (type(list) ~= "table") then return nil end
    return table.remove(list, index);
end

function List.Length(list)
    if (type(list) ~= "table") then return 0 end
    return #(list);
end