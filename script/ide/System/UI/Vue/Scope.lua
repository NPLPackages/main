--[[
Title: Timer
Author(s):  wxa
Date: 2021-06-01
Desc: 
use the lib:
------------------------------------------------------------
local Scope = NPL.load("script/ide/System/UI/Vue/Scope.lua");
------------------------------------------------------------
]]

local __global_index_callback__ = nil;
local __global_newindex_callback__ = nil;

local __len_meta_method_test_table__ = setmetatable({}, {__len = function() return 1 end });
local __is_support_len_meta_method__ = #__len_meta_method_test_table__ == 1;

local __is_support_pairs_meta_method__ = false;
local __is_support_ipairs_meta_method__ = false;
pairs(setmetatable({}, {__pairs = function() __is_support_pairs_meta_method__ = true end}));
ipairs(setmetatable({}, {__ipairs = function() __is_support_ipairs_meta_method__ = true end}));


local __global_newindex_list__ = {};                       -- 通知列表
local __is_activated__ = false;                            -- 是否已激活通知文件
local __activate_filename__ = "__is_actived_notify__";     -- 激活通知文件

local table_concat = table.concat;
local table_insert = table.insert;
local table_remove = table.remove;
local table_sort = table.sort;
local __pairs__ = pairs;
local __ipairs__ = ipairs;

local function Inherit(baseClass, inheritClass)
    if (type(baseClass) ~= "table") then baseClass = nil end
    
	-- 初始化派生类
    local inheritClass = inheritClass or {};
    local inheritClassMetaTable = { __index = inheritClass };

    -- 新建实例函数
    function inheritClass:___new___(o)
        local o = o or {}
        
        -- 递归基类构造函数
        if(baseClass and baseClass.___new___ ~= nil) then baseClass:___new___(o) end

        -- 设置实例元表
        setmetatable(o, rawget(inheritClass, "__metatable") or inheritClassMetaTable);
        
        -- 调用构造函数
        local __ctor__ = rawget(inheritClass, "__ctor__");
		if(__ctor__) then __ctor__(o) end
		
        return o;
    end

    -- 获取基类
    function inheritClass:__super_class__()
        return baseClass;
    end

    -- 设置基类
    if (baseClass ~= nil) then
        setmetatable(inheritClass, { __index = baseClass } )
    end

    return inheritClass
end

local Scope = Inherit(nil, NPL.export());

-- 基础函数
Scope.__inherit__ = Inherit;
-- 是否支持__len
Scope.__is_support_len_meta_method__= __is_support_len_meta_method__;
Scope.__is_support_pairs_meta_method__ = __is_support_pairs_meta_method__;
Scope.__is_support_ipairs_meta_method__ = __is_support_ipairs_meta_method__;

-- 获取值
local function __get_val__(val)
    -- 非普通表不做响应式
    if (type(val) ~= "table" or getmetatable(val) ~= nil or Scope:__is_scope__(val)) then return val end
    -- 普通表构建scope
    return Scope:__new__(val);
end

local function __to_plain_data__(val)
    if (Scope:__is_scope__(val)) then return val:ToPlainObject() end 
    return val;
end

-- 获取值
Scope.__get_val__ = __get_val__;
Scope.__to_plain_data__ = __to_plain_data__;

-- 设置全局读取回调
function Scope.__set_global_index__(__index__)
    __global_index_callback__ = __index__;
end

-- 设置全局写入回调
function Scope.__set_global_newindex__(__newindex__)
    __global_newindex_callback__ = __newindex__;
end

function Scope:__new__(obj)
    if (self:__is_scope__(obj)) then return obj end

    local metatable = self:___new___();

    -- 获取值
    metatable.__index = function(scope, key)
        return metatable:__get__(scope, key);
    end

    -- 设置值
    metatable.__newindex = function(scope, key, val)
        metatable:__set__(scope, key, val);
    end

    -- 遍历  若不支持__pairs 外部将无法遍历对象 只能通过ToPlainObject值去遍历
    if (__is_support_pairs_meta_method__) then
        metatable.__pairs = function(scope)
            return pairs(metatable.__data__);
        end
    end

    -- 遍历
    if (__is_support_ipairs_meta_method__ and __is_support_len_meta_method__) then
        metatable.__ipairs = function(scope)
            return ipairs(metatable.__data__);
        end
    end

    -- 长度
    if (__is_support_len_meta_method__) then
        metatable.__len = function(scope)
            return #metatable.__data__;
        end
    end

    -- 构建scope对象
    local scope = setmetatable({}, metatable);
    
    -- 设置scope
    metatable.__scope__ = scope;
    metatable.__metatable__ = metatable;

    -- 拷贝原始数据时, 禁止触发回调
    metatable.__enable_index_callback__ = false;
    metatable.__enable_newindex_callback__ = false;
    if (type(obj) == "table") then 
        for key, val in pairs(obj) do
            scope[key] = val;
        end
    end
    metatable.__enable_index_callback__ = true;
    metatable.__enable_newindex_callback__ = true;

    -- 新建触发一次读取
    metatable:__call_index_callback__(scope, nil);

    return scope;
end

local scopeId = 0;
-- 构造函数
function Scope:__ctor__()
    scopeId = scopeId + 1;
    self.__id__ = scopeId ;
    self.__data__ = {};                                 -- 数据表
    self.__length__ = 0;                                -- 列表长度
    self.__scope__ = self;                              -- 是否为Scope
    self.__metatable__ = self;                          -- scope 原表
    self.__parent_metatable__ = nil;                    -- 父原表
    self.__key__ = nil;                                 -- 在父scope中key
    self.__index_callback__ = nil;                      -- 读取回调
    self.__newindex_callback__ = nil;                   -- 写入回调   
    self.__enable_index_callback__ = true;              -- 使能index回调
    self.__enable_newindex_callback__ = true;           -- 使能newindex回调
    self.__watch__ = {};
end

-- 初始化
function Scope:__init__()
    return self;
end

-- 是否是Scope
function Scope:__is_scope__(scope)
    return type(scope) == "table" and scope.__scope__ ~= nil;
end

-- 获取scope元表
function Scope:__get_metatable__()
    return self.__metatable__;
end

-- 获取 Keys
function Scope:__get_keys__(key)
    local keys = {};
    local metatable = self.__metatable__;

    if (key ~= nil) then table.insert(keys, 1, key) end
    while (metatable and metatable.__key__) do
        table.insert(keys, 1, metatable.__key__);
        metatable = metatable.__parent_metatable__;
    end

    return keys;
end

function Scope:__set_metatable_index__(__metatable_index__)
    self.__metatable__.__metatable_index__ = __metatable_index__;
end

function Scope:__get_metatable_index__()
    return self.__metatable__.__metatable_index__;
end

-- 全局读取回调
function Scope:__call_global_index_callback__(scope, key)
    if (type(__global_index_callback__) == "function") then __global_index_callback__(scope, key) end
end

-- 设置读取回调
function Scope:__set_index_callback__(__index__)
    self.__metatable__.__index_callback__ = __index__;
end

-- 读取回调
function Scope:__call_self_index_callback__(scope, key)
    if (type(self.__metatable__.__index_callback__) == "function") then self.__metatable__.__index_callback__(scope, key) end
end

-- 读取回调
function Scope:__call_index_callback__(scope, key)
    if (not self.__metatable__.__enable_index_callback__) then return end

    -- print("__call_index_callback__", scope, key);

    local val = key and self.__metatable__.__data__[key];
    -- 值为scope触发本身读索引
    if (self:__is_scope__(val)) then return val:__call_index_callback__(val, nil) end

    -- 触发scope链的读回调
    local metatable = self;
    while (metatable) do
        metatable:__call_self_index_callback__(scope, key);
        metatable = metatable.__parent_metatable__;
    end

    -- 触发普通值的读索引
    self:__call_global_index_callback__(scope, key);
end

-- 获取键值
function Scope:__get__(scope, key)
    if (key == "__metatable__") then return self.__metatable__ end
    if (key == "__scope__") then return self.__metatable__.__scope__ end 
    
    if (self.__metatable__[key] ~= nil) then return self.__metatable__[key] end

    if (type(key) == "number") then 
        self:__call_index_callback__(scope, nil);  -- 针对列表触发列表整体更新
        return if_else(__is_support_len_meta_method__, self.__metatable__.__data__[key], rawget(scope, key));
    end

    -- 触发回调
    self:__call_index_callback__(scope, key);

    -- 返回数据值
    if (self.__metatable__.__data__[key]) then return self.__metatable__.__data__[key] end

    -- 返回用户自定的读取
    if (type(self.__metatable__.__metatable_index__) == "table") then return self.__metatable__.__metatable_index__[key] end
    if (type(self.__metatable__.__metatable_index__) == "function") then return self.__metatable__.__metatable_index__(scope, key) end
end

-- 写入回调   
function Scope:__call_global_newindex_callback__(scope, key, newval, oldval)
    if (type(__global_newindex_callback__) == "function") then __global_newindex_callback__(scope, key, newval, oldval) end
end

function Scope:__call_self_newindex_callback__(scope, key, newval, oldval)
    if (type(self.__metatable__.__newindex_callback__) == "function") then self.__metatable__.__newindex_callback__(scope, key, newval, oldval) end
end

-- 写入回调   
function Scope:__call_newindex_callback__(scope, key, newval, oldval)
    if (not self.__metatable__.__enable_newindex_callback__) then return end

    -- print("__call_newindex_callback__", scope, key);

    -- 触发监控回调 会触发依赖死循环应通过事件触发
    if (key ~= nil) then 
        __global_newindex_list__[#__global_newindex_list__ + 1] = {scope = scope, key = key, newval = newval, oldval = oldval};
        if (not __is_activated__) then
            __is_activated__ = true;
            NPL.activate(__activate_filename__);
        end
    end 

    -- 旧值为scope触发本身写索引
    if (key and self:__is_scope__(oldval)) then return oldval:__call_newindex_callback__(oldval, nil, newval, oldval) end
    
    -- 触发scope链的写索引回调
    local metatable = self.__metatable__;
    while (metatable) do
        metatable:__call_self_newindex_callback__(scope, key, newval, oldval);
        metatable = metatable.__parent_metatable__;
    end

    -- 触发全局写索引回调
    self:__call_global_newindex_callback__(scope, key, newval, oldval);
end

-- 设置写入回调   
function Scope:__set_newindex_callback__(__newindex__)
    self.__metatable__.__newindex_callback__ = __newindex__;
end

-- 设置键值
function Scope:__set__(scope, key, val)
    -- print("----__set__----", scope, key, val);

    if (self.__metatable__[key] ~= nil) then return print("built in properties cannot be set") end

    local oldval = nil;
    local newval = __get_val__(val);
    local isListIndex = type(key) == "number";

    -- 获取旧值更新新值
    if (not isListIndex or __is_support_len_meta_method__) then
        oldval = self.__metatable__.__data__[key];
        self.__metatable__.__data__[key] = newval;
    else
        oldval = rawget(scope, key);
        rawset(scope, key, newval);
    end

    -- 相同直接退出
    if (oldval == newval) then return end
    
    -- 新值为scope 不为当前scope(scope.key = scope) 则更改其父scope
    if (self:__is_scope__(newval) and newval.__metatable__ ~= self.__metatable__) then 
        newval.__metatable__.__parent_metatable__ = self.__metatable__;
        newval.__metatable__.__key__ = key;
    end

    -- 触发更新回调
    if (isListIndex) then
        self:__call_newindex_callback__(scope, nil, scope, scope);      -- 为数字则更新整个列表对象
    else
        self:__call_newindex_callback__(scope, key, newval, oldval);    -- 否则更新指定值
    end
end

-- 获取真实数据
function Scope:__get_data__()
    return self.__metatable__.__data__;
end

-- 设置真实数据
function Scope:__set_data__(data)
    if (type(data) ~= "table") then return end
    self.__metatable__.__data__ = data;
end

-- 获取列表
function Scope:__get_list__()
    return __is_support_len_meta_method__ and self.__metatable__.__data__ or self.__metatable__.__scope__;
end

-- 设置数据
function Scope:Set(key, val)
    self.__metatable__:__set__(self.__scope__, key, val);
end

-- 获取数据
function Scope:Get(key, default_value)
    local value = self.__metatable__:__get__(self.__scope__, key);
    if (value ~= nil or default_value == nil) then return value end 
    self:Set(key, default_value);
    return self.__metatable__:__get__(self.__scope__, key);
end

-- 获取列表长度 
function Scope:Length()
    return __is_support_len_meta_method__ and #(self.__metatable__) or #(self.__scope__);
end

-- 列表插入
function Scope:Insert(index, value)
    local __list__ = self:__get_list__();
    if (value == nil) then index, value = #__list__ + 1, index end
    table_insert(__list__, index, __get_val__(value));
    self:__call_newindex_callback__(self.__scope__, nil, self.__scope__, self.__scope__);
end

-- 列表移除
function Scope:Remove(index)
    local __list__ = self:__get_list__();
    table_remove(__list__, index);
    self:__call_newindex_callback__(self.__scope__, nil, self.__scope__, self.__scope__);
end

-- 排序
function Scope:Sort(comp, sort)
    local __list__ = self:__get_list__();
    sort = sort or table_sort;
    sort(__list__, comp);
    self:__call_newindex_callback__(self.__scope__, nil, self.__scope__, self.__scope__);
end

-- Pairs
function Scope:Pairs()
    local __list__ = self:__get_list__();
    return __pairs__(__list__);
end

-- IPairs
function Scope:IPairs()
    local __list__ = self:__get_list__();
    return __ipairs__(__list__);
end

-- 监控
function Scope:Watch(key, func)
    if (type(func) ~= "function") then return end
    local watch = self.__metatable__.__watch__[key] or {};
    self.__metatable__.__watch__[key] = watch;
    watch[func] = func;
end

-- 通知监控
function Scope:Notify(key, newval, oldval)
    local watch = self.__metatable__.__watch__[key];
    if (not watch) then return end
    for _, func in pairs(watch) do
        func(if_else(newval == nil, self.__scope__[key], newval), oldval);
    end
end

-- 转化为普通对象
function Scope:ToPlainObject()
    local __data__ = self.__metatable__.__data__;
    if (not __is_support_len_meta_method__) then
        for index, val in ipairs(self.__metatable__.__scope__) do
            __data__[index] = val;
        end
    end
    return __data__;
end

local __list__ = {};
NPL.this(function()
    -- print("清除依赖更新队列 结束: ", ClearDependItemUpdateQueueCount);
    -- print("--------------------trigger  notify----------------------");
    __is_activated__ = false;
    local size = #__global_newindex_list__;
    for i = 1, size do
        __list__[i] = __global_newindex_list__[i];
        __global_newindex_list__[i] = nil;
    end
    for i = 1, size do
        local item = __list__[i];
        item.scope:Notify(item.key, item.newval, item.oldval);
    end
end, {filename = __activate_filename__});

-- 测试
function Scope.Test()
    print("----------begin test------------")

    local scope = Scope:__new__();

    scope.key = 1;
    scope[1] = 2;
    print("----------end test------------")

    for key, val in scope:Pairs() do
        print("-----", key, val);
    end

    for key, val in scope:IPairs() do
        print("-----", key, val);
    end
end
