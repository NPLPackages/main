--[[
Title: common lib funcions
Author(s): LiXizhi
Date: 2006/11/25
Desc: basic debugging,serialization functions, etc. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/commonlib.lua");
-------------------------------------------------------
]]
if(not Map3DSystem) then 
	-- for backward compatibility: create deprecated Map3DSystem namespace
	System = System or {};
	Map3DSystem = System; 
end

if(not commonlib) then commonlib={}; end

---------------------------
-- lua5.1/5.2 compatibility
---------------------------
-- in case setn is not defined. we will redefine them to make it compatible with older lua libs.
-- this is useful when using luajit2 dll instead of lua51. 
if(not table.setn) then
	table.setn = function(t, n)
		t.n = n
	end
	table.getn = function(t)
		return t.n or #t
	end
end

if(not string.gfind) then
	string.gfind = string.gmatch; -- lua 5.1/5.2 has replaced gfind with gmatch. 
end
if(not math.mod) then
	math.mod = math.fmod; -- lua 5.1/5.2 has replaced mod with fmod. 
end

-- table.clear is available in luajit 2.1 and lua 5.3
if(not table.clear) then
	local ok, tc = pcall(require, "table.clear")
	if not ok then
		tc = function(tab)
			local k = next(tab)
			while k ~= nil do
			  tab[k] = nil
			  k = next(tab)
			end
		end 
	end
	table.clear = tc;
end


-- this function is a shortcut to if(bStatement) then A else B. 
-- e.g. 
-- local c = if_else(a>0, 1, 0)
-- c = a>0 and 1 or 0
function if_else(bStatement, true_value, false_value)
	if(bStatement) then
		return true_value;
	else
		return false_value;
	end
end

NPL.load("(gl)script/ide/ParaEngineLuaJitFFI.lua");
NPL.load("(gl)script/ide/oo.lua");
NPL.load("(gl)script/ide/log.lua");
NPL.load("(gl)script/ide/LibStub.lua");
NPL.load("(gl)script/ide/package/package.lua");
NPL.load("(gl)script/ide/debug.lua");
NPL.load("(gl)script/ide/serialization.lua");
NPL.load("(gl)script/ide/OneTimeAsset.lua");
NPL.load("(gl)script/ide/timer.lua");
NPL.load("(gl)script/ide/NPLExtension.lua");
NPL.load("(gl)script/ide/XPath.lua");
NPL.load("(gl)script/ide/rulemapping.lua");
NPL.load("(gl)script/ide/Encoding.lua");
NPL.load("(gl)script/ide/DateTime.lua");

-- called at the end of this function.
local function FooterLoader()
	NPL.load("(gl)script/ide/DataBinding.lua");
	NPL.load("(gl)script/ide/Files.lua");
end

local _G = _G
local ParaUI_GetUIObject; if(ParaUI and ParaUI.GetUIObject) then  ParaUI_GetUIObject = ParaUI.GetUIObject; end
local getmetatable = getmetatable
local setmetatable = setmetatable
local getfenv = getfenv
local setfenv = setfenv
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber
local error = error
local next = next
local type = type

local math_abs = math.abs
local math_floor = math.floor

local table_getn = table.getn
local table_insert = table.insert

local string_find = string.find;
local string_gfind = string.gfind;
local string_lower = string.lower;

---------------------------------------
-- some simple algorithms
---------------------------------------
if(not commonlib.algorithm) then
	commonlib.algorithm = {};
end
local algorithm = commonlib.algorithm;

-- in place sort of the input list. the item order is unchanged for those who passed and not passed the predicate test. 
-- @param input: a table array
-- @param predicate_func: a function(item) that should return true, if item should come before that that return false. 
function algorithm.sort_by_predicate(input, predicate_func)
	if(input and predicate_func) then
		local bad_ones = {};
		local good_count = 0;
		local count = #input;
		for i = 1, count do
			local item = input[i];
			if(predicate_func(item)) then
				good_count = good_count + 1;
				input[good_count] = item
			else
				bad_ones[#bad_ones+1] = item;
			end
		end
		count = #bad_ones;
		for i = 1, count do
			input[good_count+i] = bad_ones[i];
		end
	end
end

--in-place quicksort by LXZ
-- @param compareFunc: by default it is function(a, b) return a<b end
-- it does not change the original order if compareFunc(left, right) is true.
-- it only swap a, b if compareFunc(a, b) is FALSE. 
local function quicksort(t, compareFunc, start, endi)
	start, endi = start or 1, endi or #t
	--partition w.r.t. first element
	if(endi <= start) then return t end
	local pivot = start
	for i = start + 1, endi do
		if( (compareFunc and not compareFunc(t[pivot], t[i]) ) or (not compareFunc and t[i] <= t[pivot]) ) then
			local temp = t[pivot + 1]
			t[pivot + 1] = t[pivot]
			if(i == pivot + 1) then
				t[pivot] = temp
			else
				t[pivot] = t[i]
				t[i] = temp
			end
			pivot = pivot + 1
		end
	end
	t = quicksort(t, compareFunc, start, pivot - 1)
	return quicksort(t, compareFunc, pivot + 1, endi)
end
algorithm.quicksort = quicksort;

-- get an UI object by specifying a serie of names separated by #, such as childname#childname#childname, 
-- e.g. commonlib.GetUIObject("wndParent#button1");
-- @param name: e.g. "wndParent#button1", it can also be number id. if it is number, parent is ignored. 
-- @param parent: nil or a parent UI object inside which the name is searched. If nil, first childname is searched globally. 
-- @return: return the ParaUIObject found. if not found, the returned object IsValid() returns false. 
function commonlib.GetUIObject(name, parent)
	local childname;
	local name_type = type(name);
	if(name_type == "string") then
		for childname in string_gfind(name,"[^#]+") do
			if(parent == nil) then
				parent = ParaUI_GetUIObject(childname);
			else	
				parent = parent:GetChild(childname);
			end
			if(not parent:IsValid()) then
				break;
			end
		end
	elseif(name_type == "number") then
		parent = ParaUI_GetUIObject(childname);
	end
	return parent;
end

-- We rely on gfind, from the string library, to iterate over all words in f (where "word" is a sequence of one or more alphanumeric characters and underscores). 
-- @param f: f is a string like "a.b.c.d"
-- @param rootEnv: it can be a table from which to search for f, if nil, the global table _G is used. 
-- @return: return the field in LUA, it may be nil, a value, or a table, etc. 
function commonlib.getfield(f, rootEnv)
	if(not f) then return end
	local v = rootEnv or _G    -- start with the table of globals
	local w;
	local bFound;
	for w in string_gfind(f, "[%w_]+") do
		bFound = true;
		v = v[w]
		if(v==nil) then
			break
		end
	end
	if(bFound) then
		return v
	end
end

-- set a variable v to f, where f is a string
-- the call setfield("t.x.y", 10) creates a global table t, another table t.x, and assigns 10 to t.x.y
-- @param f: f is a string like "a.b.c.d"
-- @param rootEnv: it can be a table from which to search for f, if nil, the global table _G is used. 
function commonlib.setfield(f, v, rootEnv)
	if(not f) then return end
	local t = rootEnv or _G    -- start with the table of globals
	for w, d in string_gfind(f, "([%w_]+)(.?)") do
		if d == "." then      -- not last field?
			t[w] = t[w] or {}   -- create table if absent
			t = t[w]            -- get the table
		else                  -- last field
			t[w] = v            -- do the assignment
		end
	end
end

-- get a table f, where f is a string
-- @param f: f is a string like "a.b.c.d"
-- @param rootEnv: it can be a table from which to search for f, if nil, the global table _G is used. 
function commonlib.gettable(f, rootEnv)
	if(not f) then return end
	local t = rootEnv or _G    -- start with the table of globals
	for w, d in string_gfind(f, "([%w_]+)(.?)") do
		t[w] = t[w] or {}   -- create table if absent
		t = t[w]            -- get the table
	end
	return t;
end

-- create/get a table and init it with init_params
function commonlib.createtable(f, init_params, rootEnv)
	local tmp = commonlib.gettable(f, rootEnv);
	if(tmp and init_params) then
		commonlib.partialcopy(tmp, init_params);
	end
	return tmp;
end

-- reset the model asset
-- @param obj: model object 
-- @assetfilename: file name of the asset file
-- @return the new obj
function commonlib.ResetModelAsset(_obj, assetfilename)
	if(_obj and _obj:IsValid() == true) then
		-- save the model setting
		local x, y, z = _obj:GetPosition();
		local facing = _obj:GetFacing();
		local scale = _obj:GetScale();
		local quat = _obj:GetRotation({});
		local bPhysicsEnabled = _obj:IsPhysicsEnabled();
		local name = _obj.name;
		-- destroy the object
		ParaScene.Delete(_obj);
		-- create another object with the same params
		local asset = ParaAsset.LoadStaticMesh("", assetfilename);
		local obj = ParaScene.CreateMeshPhysicsObject(name, asset, 1,1,1, bPhysicsEnabled, "1,0,0,0,1,0,0,0,1,0,0,0");
		obj:GetAttributeObject():SetField("progress", 1);
		obj:SetPosition(x, y, z);
		obj:SetFacing(facing);
		obj:SetScale(scale);
		obj:SetRotation(quat);
		if(_obj:CheckAttribute(128)) then
			obj:SetAttribute(128, true);
		end
		ParaScene.Attach(obj);
		return obj;
	else
		return _obj;
	end
end

-- clone a obj using just meta table. It does not actually copy parameters. 
-- Note: one can not serialize a meta cloned object, because it is an empty table with the same meta table as input obj. 
function commonlib.MetaClone(obj)
	local o = {}
	setmetatable(o, obj)
	obj.__index = obj
	return o
end

--[[ code from: http://lua-users.org/wiki/CopyTable
This function returns a deep copy of a given table. The function below also copies the metatable to the new table if there is one, 
so the behaviour of the copied table is the same as the original. But the 2 tables share the same metatable, 
you can avoid this by changing this 'getmetatable(object)' to '_copy( getmetatable(object) )'.
]]
function commonlib.deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

-- alias for deepcopy
commonlib.clone = commonlib.deepcopy;

-- same as commonlib.clone except that it does not copy meta table. 
function commonlib.copy(object)
	local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return new_table;
    end
    return _copy(object)
end

-- this function simply does, dest = src, but it copies value from src to dest. 
-- It is mostly used with tables.It just copies what is in src to dest, but dest retains its other fields that does not exist in src.
function commonlib.partialcopy(dest, src)
    local function _assign(dest, src)
	    if type(src) =="table"  and type(dest) =="table"  then
			for key, value in pairs(src) do
				if(type(value) =="table") then
					if(type(dest[key]) == "table") then
						_assign(dest[key], value);
					else
						dest[key] = {};
						_assign(dest[key], value);
					end
				else
					dest[key] = value	
				end
			end
        end
    end
    return _assign(dest, src)
end

-- this function simply does, dest = src, but it copies value from src to dest. 
-- It is mostly used with tables.It only copies src field to dest field, if src field name does not exist in dest. In other words, dest will preserve all its named fields plus additional fields in dest
function commonlib.mincopy(dest, src)
    local function _assign(dest, src)
	    if type(src) =="table"  and type(dest) =="table"  then
			for key, value in pairs(src) do
				if(dest[key] == nil) then
					if(type(value) =="table") then
						dest[key] = {};
						_assign(dest[key], value);
					else
						dest[key] = value	
					end
				end	
			end
        end
    end
    return _assign(dest, src)
end
-- compares all fields in src with destination, value by value, if they are equal, true is returned. otherwise, return nil or false.
-- Note that if dest has more fields than src, yet all src fields equals to dest, then it will still return true.
-- Note: it also compare indexed array items
-- @param tolerance: if not nil, it will be used to compare number type values. smaller than this will be regarded as equal.
function commonlib.partialcompare(dest, src, tolerance)
	local function _compare(dest, src)
	    if type(src) == type(dest) then
			if(type(src) =="table")  then
				for key, value in pairs(src) do
					if(not _compare(dest[key], value) ) then
						return
					end
				end
				return true
			elseif(tolerance~=nil and type(src) =="number")  then
				return (math_abs(dest-src)<=tolerance)
			else	
				return (dest==src)
			end	
        end
    end
    return _compare(dest, src)
end
local partialcompare = commonlib.partialcompare;

-- compare all fields in dest with src and return true if equal.
function commonlib.partialfields(dest, src, fields)
	--TODO: 
end

-- strict compare all fields reccursively in dest and src, value by value
-- Note: it also compare indexed array items
-- @param tolerance: if not nil, it will be used to compare number type values. smaller than this will be regarded as equal.
-- @return true if equal.
function commonlib.compare(dest, src, tolerance)
	return partialcompare(dest, src, tolerance) and partialcompare(src, dest, tolerance) 
end


-- resize a table to a new size. It ensures that all elements are nil. 
-- this function uses table_getn() instead of #t, use table.resize for #t
function commonlib.resize(t, size, v)
	local curSize = table_getn(t);
	if(curSize > size) then
		for i=curSize, size+1, -1 do
			t[i] = nil;
		end
	elseif(curSize < size) then
		for i=curSize+1, size  do
			t[i] = v;
		end
	end
end

-- resize a table to a new size. It ensures that all elements are nil. 
-- @param t: table to resize
-- @param size: the new size
-- @param v: the item value;
function table.resize(t, size, v)
	local curSize = #t;
	if(curSize > size) then
		for i=curSize, size+1, -1 do
			t[i] = nil;
		end
	elseif(curSize < size) then
		for i=curSize+1, size  do
			t[i] = v;
		end
	end
end

-- remove an item from a table. The table size will be minored by 1. 
-- @param t: table array.
-- @param nIndex: 1 based index, at which to remove the item
function commonlib.removeArrayItem(t, nIndex)
	local nSize = table_getn(t);
	for k=nIndex, nSize do
		t[k] = t[k+1];
	end
end

-- insert an array item to a table array. The table size will be increased by 1. 
-- @param t: table array.
-- @param nIndex: 1 based index, at which to insert the item. if nil, it will inserted to the end
-- @return return 1 based index at which the item is inserted
function commonlib.insertArrayItem(t, nIndex, item)
	local nSize = table_getn(t);
	if(nIndex == nil) then
		nIndex = nSize+1;
		t[nIndex] = item;
	elseif(nIndex > nSize) then
		t[nIndex] = item;
	else
		local tmp = item;
		for k=nIndex, nSize+1 do
			--local tmp1 = t[k];
			--t[k] = tmp;
			--tmp = tmp1;
			t[k], tmp = tmp, t[k]
		end	
	end
	return nIndex;
end

-- remove all items that matches a certain criteria from an array table
-- e.g. 
--  commonlib.removeArrayItems({1,2,3,4,5,6}, function(i, item) return (i%2==0); end); --> {1,3,5}
-- @param t: table to be removed 
-- @param callback_func: the callback function(index, item) end. if the function returns true, then the table item at the given index will be removed from the table.
function commonlib.removeArrayItems(t, callback_func)
	local nCount = #(t);
	local nNextIndex = nil;
	for i = 1, nCount do
		if(callback_func(i,t[i])) then
			if(not nNextIndex) then
				nNextIndex = i;
			end
			t[i] = nil;
		elseif(nNextIndex) then
			t[nNextIndex] = t[i];
			t[i] = nil;
			nNextIndex = nNextIndex + 1;
		end
	end
end

-- swap two items in a table. 
function commonlib.swapArrayItem(t, nIndex1, nIndex2)
	--local tmp = t[nIndex1];
	--t[nIndex1] = t[nIndex2];
	--t[nIndex2] = tmp;
	t[nIndex1], t[nIndex2] = t[nIndex2], t[nIndex1]
end

-- move array item from one nIndex1 to nIndex2
function commonlib.moveArrayItem(t, nIndex1, nIndex2)
	if(nIndex1 > nIndex2) then
		local tmp = t[nIndex1];
		for k=nIndex1, nIndex2+1,-1 do
			t[k] = t[k-1];
		end
		t[nIndex2] = tmp;
	elseif(nIndex1 < nIndex2) then
		local tmp = t[nIndex1];
		for k=nIndex1, nIndex2-1 do
			t[k] = t[k+1];
		end
		t[nIndex2] = tmp;
	end
end

function commonlib.moveArrayItemWithNum(t, nNum) --用时间换空间O(n^2)
	local tNum = table_getn(t)
	local moveNum = math.abs(nNum)
	if moveNum >= tNum then
		return
	end
	if nNum < 0 then
		for i=1,moveNum do
			local temp = t[1]
			for j=1,tNum do
				t[j] = t[j+1]
			end
			t[tNum] = temp
		end
	else
		for i=1,moveNum do
			local temp = t[tNum]
			for j=tNum,1,-1 do
				t[j] = t[j - 1]
			end
			t[1] = temp
		end
	end
end

function commonlib.quickMoveArrayItemWithNum(t, nNum) --用空间换时间O(n)
	local tNum = table_getn(t)
	local moveNum = math.abs(nNum)
	if moveNum >= tNum then
		return
	end
	local move_index = nNum < 0 and moveNum or tNum - moveNum
	local tempArray = {}
	local tempArray1 = {} 
	for i=1,tNum do
		if i<= move_index then
			tempArray[#tempArray + 1] = commonlib.copy(t[i])
		else
			tempArray1[#tempArray1 + 1] = commonlib.copy(t[i])
		end
	end
	local tempIndex = #tempArray1
	for i=1,tNum do
		if i<= tempIndex then
			t[i] = tempArray1[i]
		else
			t[i] = tempArray[i - tempIndex]
		end
	end
end


-- empty a given table
commonlib.cleartable = table.clear;

-------------------------
-- a simple UTF8 lib
-- use: 
-- commonlib.utf8.len("abc");
-- commonlib.utf8.sub("abc", 1, nil)
-------------------------
local utf8 = {};
commonlib.utf8 = utf8;

-- return the number of characters in UTF8 encoding.
-- more info at: http://lua-users.org/wiki/LuaUnicode
function utf8.len(unicode_string)
	local _, count = string.gsub(unicode_string, "[^\128-\193]", "")
	return count;
end

-- similar to string.sub(), except that nFrom, nTo refers to characters, instead of byte
function utf8.sub(ustring, nFrom, nTo)
	local result;
	local uchar;
	local nCount = 1;
	for uchar in string_gfind(ustring, "([%z\1-\127\194-\244][\128-\191]*)") do
	  -- something
	  if(nTo~=nil and nCount>nTo) then
		break;
	  end
	  if(nCount>=nFrom) then
		if(not result) then
			result = uchar;
		else
			result = result..uchar;
		end
	  end
	  nCount = nCount +1;
	end
	return result;
end

-- OBSOLETED: use commonlib.Files.SearchFiles(), instead. 
function commonlib.SearchFiles(...)
	NPL.load("(gl)script/ide/Files.lua");
	return commonlib.Files.SearchFiles(...)
end

-- get the absolute of the given number, if param not number type return nil
function commonlib.Absolute(num)
	if(type(num) == "number") then
		if(num < 0) then
			return -num;
		else
			return num;
		end
	else
		log("Attempt to absolute against non number value");
		return nil;
	end
end

-- convert the string to number
-- this function will handle the string will additional "0" digits in the front of the string
-- e.x. input: "010" return: 10
function commonlib.tonumber(s)
	if(type(s) == "string") then
		local n;
		local dot = string_find(s, "%.");
		if(dot ~= nil) then
			n = dot - 1;
		else
			n = #(s);
		end
		local result = tonumber("1"..s);
		return result - math.pow(10, n);
	end
end

-- make all table fields (including fields of sub tables) lower cased. This is useful for case-insensitive table. 
-- @param o: it will modify on this table and its sub-tables. If it is string. this function will return the lower cased string. 
-- @return: return the modified input 
function commonlib.tolower(o)
	if(type(o) == "table") then
		local changed_keys;
		for key, value in pairs(o) do
			local key_lowered = string_lower(key);
			if (key_lowered ~= key) then
				changed_keys = changed_keys or {}
				changed_keys[key] = key_lowered;
				if(type(value)=="table") then
					commonlib.tolower(value);
				end
			end
		end
		if(changed_keys) then
			for key, value in pairs(changed_keys) do
				o[value] = o[key];
				o[key] = nil;
			end
		end
	elseif(type(o) == "string") then	
		return string_lower(o);
	end
	return o;
end

---random search a number of item from a list
--[[ 
local source_list = {
	{ label = 1, isEmpty = true, },
	{ label = 2, isEmpty = true, },
	{ label = 3, isEmpty = false, },
	{ label = 4, isEmpty = true, },
}
local goal_num = 5;
local result = commonlib.GetEmptyList(source_list,goal_num,true);
commonlib.echo(result);
--]]
---@param source_list: it is a table which will be searched
---@param goal_num:the number of search from source_list;
---NOTE:if #source_list < goal_num then goal_num = #source_list;
---return nil or a result table
function commonlib.GetEmptyList(source_list,goal_num,bSort)
	if(not source_list or not goal_num or goal_num < 1)then return end
	
	local canSearch = false;
	for k,v in ipairs(source_list) do
		if(v.isEmpty)then
			canSearch = true;
			break;
		end
	end
	if(not canSearch)then return end
	local empty_holes = {};
	for k,v in ipairs(source_list) do
		if(v.isEmpty)then
			table_insert(empty_holes,v);
		end
	end
	local len = table_getn(empty_holes);
	goal_num = math.min(len,goal_num);
	
	if(goal_num <= 0)then return end
	function getRandomItem(list)
		if(not list)then return end
		local len = table_getn(list);
		if(len == 0)then return end
		local r = math.random(len);
		local item = list[r];
		table.remove(list,r);
		return item;
	end
	local result_list = {};
	for k = 1, goal_num do
		local item = getRandomItem(empty_holes);
		if(item)then
			table_insert(result_list,item);
		end
	end
	if(bSort)then
		table.sort(result_list,function(a,b)
			if(a.label and b.label)then
				return a.label < b.label;
			end
		end)
	end
	return result_list;
end
--在一个范围内随机选取一定的数目
--goal_num = math.min(source_num,goal_num);
--返回一个table: result = {1,3,7}
--[[ 
local result = commonlib.GetRandomList(10,5,true);
commonlib.echo(result);
--]]
function commonlib.GetRandomList(source_num,goal_num,bSort)
	if(not source_num or not goal_num)then return end
	goal_num = math.min(source_num,goal_num);
	local source_list = {};
	for k = 1, source_num do
		source_list[k] = { label = k, isEmpty = true };
	end
	local temp_list = commonlib.GetEmptyList(source_list,goal_num);
	if(temp_list)then
		local result_list = {};
		if(bSort)then
			table.sort(temp_list,function(a,b)
				if(a.label and b.label)then
					return a.label < b.label;
				end
			end)
		end
		for k,v in ipairs(temp_list) do
			table_insert(result_list,v.label);
		end
		return result_list;
	end
end
--产生一个随机数
--@param range:随机的范围 大于等于0的整数
--@param excludeindex:不包含的整数
function commonlib.GetRandomIndex(range,excludeindex)
	if(not range or range <=1 )then return end
	if(excludeindex and excludeindex > range)then
		return
	end
	function madeRandom()
		local r = math.random(range);
		if(excludeindex and excludeindex == r)then
			return madeRandom()
		end
		return r;
	end
	local r = madeRandom();
	return r;
end

function commonlib.GetLimitLabel(text, maxCharCount)
    maxCharCount = maxCharCount or 13;
    local len = ParaMisc.GetUnicodeCharNum(text);
    if(len >= maxCharCount)then
	    text = ParaMisc.UniSubString(text, 1, maxCharCount-2) or "";
        return text .. "...";
    else
        return text;
    end
end

-- Use a private proxy environment for the module,
-- so that the module can access global variables.
--  + Global assignments inside module get placed in the module
--  + Lookups in the private module environment query first the module,
--    then the global namespace.
local function _seeall(_M)
  local priv = {}   -- private environment for module
  local privmt = {}
  privmt.__index = function(priv, k)
    return _M[k] or _G[k]
  end
  privmt.__newindex = _M
  setmetatable(priv, privmt)
  setfenv(3, priv)
end

-- define a module, replace the global environment _G with that of the table.
-- this function is same as commonlib.createtable, except that the global environment _G with that of the table.
-- @param modname: namespace for module
-- @return the module created
function commonlib.module(modname, ...)
	local _M = commonlib.createtable(modname, ...)     -- namespace for module
	setfenv(2, _M)
	-- see all environment
	_seeall(_M);
	return _M;
end
--[[
	local result = commonlib.split("a,b,c,d",",");
	echo(result);
--]]
function commonlib.split(str,delimiter)
	local result = {};
	if(not str or not delimiter)then 
		return result;
	end
	local line;
	local s = "([^"..delimiter.."]+)";
	for line in string.gfind(str, s) do
		table.insert(result,line);
	end
	return result;
end

--[[
	字符串切割
	local result = commonlib.split_by_str("aabaaba","ab");
	echo(result, true);
	输出 { "a", "a", "a" }
	commonlib.split 的话这种情况会输出 {}
--]]
function commonlib.split_by_str(str, delimiter)
	local star_index = 1
	local split_index = 1
	local split_array = {}
	while true do
	  local last_index = string.find(str, delimiter, star_index)
	  if not last_index then
		split_array[split_index] = string.sub(str, star_index, string.len(str))
		break
	  end

	  split_array[split_index] = string.sub(str, star_index, last_index - 1)
	  star_index = last_index + string.len(delimiter)
	  split_index = split_index + 1
	end

	return split_array
end

--- TODO self?
--- @param func function
--- @param delay number
--- @return function
function commonlib.debounce(func, delay)
	local timer;

	return function (...)
		local args = {...};

		if(timer) then
			timer:Change();
		end

		timer = commonlib.TimerManager.SetTimeout(function ()
			func(unpack(args));
		end, delay);
	end
end

function commonlib.find(arr, func)
	if(not arr) then 
		return nil;
	end;

	for index, item in ipairs(arr) do
		if(func(item)) then
			return item;
		end;
	end

	return nil;
end

function commonlib.map(arr, func)
	if(not arr) then 
		return nil;
	end;

	local items = {};
	for index, item in ipairs(arr) do
		table.insert(items, func(item))
	end
	return items;
end

function commonlib.filter(arr, filterFunc)
	if(not arr) then 
		return nil;
	end;

	local newItems = {};
	for index, item in ipairs(arr) do
		if(filterFunc(item)) then
			table.insert(newItems, item)
		end
	end

	return newItems;
end

--[[
	local t = 
	{
		["a"] = 1;
		["b"] = 2;
	};
	
	for k, v in commonlib.keysorted_pairs(t) do
		print(k, v);
	end
	
	local function sortFunc(a, b)
		if a.key == b.key then
			return a.value < b.value;
		else
			return a.key < b.key;
		end
	end
	for k, v in commonlib.keysorted_pairs(t, sortFunc) do	
		print(k, v);
	end
]]
function commonlib.keysorted_pairs(t, sortFunc)
	local sortTable = {};
	for k, v in pairs(t) do
		table.insert(sortTable, {key = k, value = v});
	end
	
	sortFunc = sortFunc or function(a, b)
		return a.key < b.key;
	end
	
	table.sort(sortTable, sortFunc);
	
	local index = 0;
	
	return function()
		index = index + 1;
		if index > #sortTable then
			return nil, nil;
		else
			local item = sortTable[index];
			return item.key, item.value;
		end
	end
end
-- echo(commonlib.ResolvePath("/a/b/c","d/e","f", "g/", "/h"))
function commonlib.ResolvePath(...)
	local result = "";
	local args = {...};
	local len = #args;
	for k, input in ipairs(args) do
		if(type(input) == "string") then
			input = input:gsub("^[/\\]+", "");
			input = input:gsub("[/\\]+$", "");
			
			if(k == 1)then
				result = input	
			else
				result = string.format("%s/%s", result, input)
			end	
		end
	end	
	result = result:gsub("\\", "/");
	return result;
end

--此方法转换后带有单位
---阿拉伯数字转中文大写
function commonlib.NumberToString(digit)
    local wordDigit = ""
    local digitLength = 0
    local iNum = 0
    local iAddZero = 0
    local digitUnit = {"", "十", "百", "千", "万", "十", "百", "千", "亿","十", "百", "千", "万", "十", "百", "千"}
    local wordFigure = {"零", "一", "二", "三", "四", "五", "六", "七", "八", "九"}
    if nil == tonumber(digit) then
        return tostring(digit)
    end
    digitLength =string.len(digit)
    if digitLength > 10 or digitLength == 0 or tonumber(digit) < 0 then
        return tostring(digit)
    end
    for i = 1, digitLength  do
        iNum = string.sub(digit,i,i)
        if iNum == 0 and i ~= digitLength then
            iAddZero = iAddZero + 1
        else
            if iAddZero > 0 then
            wordDigit = wordDigit..wordFigure[1]
        end
            wordDigit = wordDigit..wordFigure[iNum + 1] --//转换为相应的数字
            iAddZero = 0
        end
        if (iAddZero < 4) and (0 == (digitLength - i) % 4 or 0 ~= tonumber(iNum)) then
            wordDigit = wordDigit..digitUnit[digitLength-i+1]
        end
    end
    local function removeZero(num)
        --去掉末尾多余的 零
        num = tostring(num)
        local szLen = string.len(num)
        local zero_num = 0
        for i = szLen, 1, -3 do
            digit = string.sub(num,i-2,i)
            if digit == wordFigure[1] then
                zero_num = zero_num + 1
            else
                break
            end
        end
        num = string.sub(num, 1,szLen - zero_num * 3)
        digit = string.sub(num, 1,6)
        --- 开头的 "一十" 转成 "十" , 贴近人的读法
        if digit == wordFigure[2]..digitUnit[2] then
            num = string.sub(num, 4, string.len(num))
        end
        return num
    end
    return removeZero(wordDigit)
end

FooterLoader();