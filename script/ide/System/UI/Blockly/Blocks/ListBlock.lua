--[[
Title: ListBlock
Author(s): wxa
Date: 2021/3/1
Desc: Lua
use the lib:
-------------------------------------------------------
local ListBlock = NPL.load("Mod/GeneralGameServerMod/App/UI/Blockly/Blocks/ListBlock.lua");
-------------------------------------------------------
]]


local ListBlock = NPL.export();

local ListMethod = [[
    function List_GetIndexByItem(list, item)
        if (type(list) ~= "table") then return nil end
        for index, val in ipairs(list) do
            if (val == item) then return index end
        end
        return nil;
    end
    
    function List_IsExistItem(list, item)
        if (type(list) ~= "table") then return false end
        for index, val in ipairs(list) do
            if (val == item) then return true end
        end
        return false;
    end

    function List_Insert(list, index, item) 
        if (type(list) ~= "table") then return nil end
        if (index ~= nil and item == nil) then item, index = index, #list + 1 end
        return table.insert(list, index, item);
    end

    function List_Remove(list, index)
        if (type(list) ~= "table") then return nil end
        return table.remove(list, index);
    end

    function List_Length(list)
        if (type(list) ~= "table") then return 0 end
        return #(list);
    end
]]

local NPL_List_Create = {};
function NPL_List_Create.ToCode(block)
    local cache = block:GetToCodeCache();
    local field_list = block:GetFieldValue("LIST");
    
    local code = string.format("local %s = {}\n", field_list);

    if (not cache.isDefineListMethod) then
        cache.isDefineListMethod = true;
        code = ListMethod .. "\n" .. code;
    end

    return code;
end

ListBlock.NPL_List_Create = NPL_List_Create;