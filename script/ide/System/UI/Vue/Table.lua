--[[
Title: Table
Author(s): wxa
Date: 2020/6/30
Desc: 表
use the lib:
-------------------------------------------------------
local Table = NPL.load("script/ide/System/UI/Vue/Table.lua");
-------------------------------------------------------
]]


local Table = NPL.export();
local Scope = NPL.load("./Scope.lua");

local TableConcat = table.concat;
local TableInsert = table.insert;
local TableRemove = table.remove;
local TableSort = table.sort;
local TablePairs = pairs;
local TableIpairs = ipairs;

function Table.concat(table_, sep, start, end_)
    if (not Scope:__is_scope__(table_)) then return TableConcat(table_, sep, start, end_) end

    local __data__ = if_else(Scope.__is_support_len_meta_method__, table_:__get_data__(), table_);
    local result = TableConcat(__data__, sep, start, end_);
    
    table_:__call_index_callback__(table_, nil);
    
    return result;
end

function Table.insert(table_, pos, value)
    if (value == nil) then value, pos = pos, Table.len(table_) + 1 end 
    if (not Scope:__is_scope__(table_)) then return TableInsert(table_, pos, value) end

    local __data__ = if_else(Scope.__is_support_len_meta_method__, table_:__get_data__(), table_);
    local result = TableInsert(__data__, pos, Scope.__get_val__(value));
    
    table_:__call_newindex_callback__(table_, nil);
    
    return result;
end

function Table.remove(table_, pos)
    if (not Scope:__is_scope__(table_)) then return TableRemove(table_, pos) end

    local __data__ = if_else(Scope.__is_support_len_meta_method__, table_:__get_data__(), table_);
    local result = TableRemove(__data__, pos);

    table_:__call_newindex_callback__(table_, nil);
    
    return result;
end

function Table.sort(table_, comp)
    if (not Scope:__is_scope__(table_)) then return TableSort(table_, comp) end

    local __data__ = if_else(Scope.__is_support_len_meta_method__, table_:__get_data__(), table_);
    local result = TableSort(__data__, comp);
    
    table_:__call_index_callback__(table_, nil);
    
    return result;
end

function Table.set(table_, key, val)
    if (not Scope:__is_scope__(table_)) then 
        table_[key] = val;
        return 
    end

    table_:__set__(table_, key, val);

    return;
end

function Table.get(table_, key, val)
    if (not Scope:__is_scope__(table_)) then return table_[key] end

    return table_:__get__(table_, key);
end

function Table.len(table_)
    if (type(table_) ~= "table") then return 0 end
    if (not Scope:__is_scope__(table_)) then return #table_ end

    local __data__ = if_else(Scope.__is_support_len_meta_method__, table_:__get_data__(), table_);
    return #__data__;
end

function Table.pairs(table_)
    if (not Scope:__is_scope__(table_)) then return TablePairs(table_) end
    
    return TablePairs(table_:ToPlainObject());
end

function Table.ipairs(table_)
    if (not Scope:__is_scope__(table_)) then return TableIpairs(table_) end
    local __data__ = if_else(Scope.__is_support_len_meta_method__, table_:__get_data__(), table_);
    return TableIpairs(__data__);
end
