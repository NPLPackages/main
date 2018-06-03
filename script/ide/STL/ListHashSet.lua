--[[
Title: a implementation as the "ListHashSet" of webkit in NPL
Author(s): LiPeng
Date: 2018.5.23
Desc:	simulate the implementation of the class "ListHashSet" in webkit;
----------------- 
webkit ListHashSet description
ListHashSet:  Just like HashSet, this class provides a Set
interface - a collection of unique objects with O(1) insertion,
removal and test for containership. However, it also has an
order - iterating it will always give back values in the order
in which they are added.

In theory it would be possible to add prepend, insertAfter
and an append that moves the element to the end even if already present,
but unclear yet if these are needed.
----------------
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/STL/ListHashSet.lua");
local listHashSet = commonlib.ListHashSet:new();
local item1 = {"item1"};
local item2 = {"item2"};
local item3 = {"item3"};
listHashSet:add(item1)
listHashSet:add(item2)
listHashSet:add(item3)

-------------------------------------------------------
]]
local ListHashSet = commonlib.gettable("commonlib.ListHashSet");
ListHashSet.__index = ListHashSet;


function ListHashSet:new(o)
    o = o or {}
	o.head, o.tail, o.nSize, o.set = nil, nil, 0, {};
	setmetatable(o, self);
	return o;
end

function ListHashSet:isEmpty()
	return self.nSize == 0;
end

-- get item count in the list
function ListHashSet:size()
	return self.nSize;
end

function ListHashSet:find(fun, ...)
	if(type(fun) == "function") then
		local it = self:Begin();
		while(it) do
			if(fun(it(), ...)) then
				return it;
			end
			it = self:next(it);
		end
		return nil;
	end
	return self.set[fun];
end

function ListHashSet:contains(item)
	if(self:find(item)) then
		return true;
	end
	return false;
end

function ListHashSet:addToSet(key, value)
	self.set[key] = value;
end

function ListHashSet:removeFromSet(key)
	self.set[key] = nil;
end

-- get the first item
function ListHashSet:first()
	return self.head.value;
end

-- get the last item
function ListHashSet:last()
	return self.tail.value;
end

-- get the next item of input item
-- @return nil if no next item. 
function ListHashSet:next(item)
	return item.next;
end

-- get the previous item of input item
-- @return nil if no previous item. 
function ListHashSet:prev(item)
	return item.prev;
end

function ListHashSet:Begin()
	return self.head;
end

function ListHashSet:End()
	return self.tail;
end

function ListHashSet:removeLast()
	if(self:isEmpty()) then
		return;
	end
	local last = self:last();
	if(last) then
		self:remove(last);
	end
end

--function ListHashSet:adjustEnd()
--	if(self.tail) then
--		self._end = self._end or {["next"] = nil, ["value"] = nil};
--		self._end.prev = self.tail;
--
--		self.tail.next = self._end;
--	end
--end

local mt = {
	__call = function(t)
		return t["value"];
	end
}

local function createInternalItem(item)
	item = {["value"] = item};
	setmetatable(item, mt);
	return item;
end

function ListHashSet:add(item)
	if(not item) then 
		LOG.std("", "warn", "ListHashSet", "ListHashSet:add() can not add nil item.");
		return nil, false; 
	end
	if(self:contains(item)) then
		return self:find(item), false;
	end

	self:addToSet(item, createInternalItem(item));
	--self.set[item] = createInternalItem(item);
	item = self:find(item);

	if(not self.tail) then
		-- the first item
		self.tail = item;
		item.prev = nil;
		item.next = nil;
		self.head = self.tail;
	else
		item.prev = self.tail;
		item.next = nil;
		self.tail.next = item;
		self.tail = item;	
	end
	self.nSize = self.nSize + 1;
	return item, true;
end

function ListHashSet:insertBefore(before_item, new_item)
	if(not new_item) then 
		LOG.std("", "warn", "ListHashSet", "ListHashSet:insertBefore() can not insert nil new_item.");
		return nil, false; 
	end
	if(not before_item or not self:contains(before_item)) then
		return self:add(new_item);
	end

	if(self:contains(new_item)) then
		return self:find(new_item), false;
	end

	self:addToSet(new_item, createInternalItem(new_item));
	--self.set[new_item] = createInternalItem(new_item);
	new_item = self:find(new_item);

	before_item = self:find(before_item);

	if(before_item.prev) then
		before_item.prev.next = new_item;
		new_item.prev = before_item.prev
	else
		self.head = new_item;
		new_item.prev = nil;
	end

	new_item.next = before_item;
	before_item.prev = new_item;
	self.nSize = self.nSize + 1;
	return new_item, true;
end

function ListHashSet:remove(item)
	if(not item) then 
		LOG.std("", "warn", "ListHashSet", "ListHashSet:remove() can not remove nil item.");
		return;
	end
	if(not self:contains(item)) then
		return;
	end

	item = self:find(item);

	local next = item.next;
	local prev = item.prev;
	if(prev) then
		prev.next = next
	else
		if(self.head == item) then
			self.head = next;
		else
			log("warning: you are trying to remove an item that does not belong to the listHashSet\n")
		end
	end
	
	if(next) then
		next.prev = prev;
	else
		if(self.tail == item) then
			self.tail = prev;
		else
			log("warning: you are trying to remove an item that does not belong to the listHashSet\n")
		end
	end
	item.next = nil;
	item.prev = nil;
	self.removeFromSet(item.value);
	--self.set[item.value] = nil;
	item.value = nil;

	self.nSize = self.nSize - 1;
end

function ListHashSet:clear()
	if(self:isEmpty()) then
		return;
	end
	for k, v in pairs(self.set) do
		self:remove(k);
	end
end

--function ListHashSet:clone()
--	local listHashSet = self;
--	local item = listHashSet:first();
--	local new_listHashSet = ListHashSet:new();
--	while (item) do
--		local last_next, last_prev = item.next, item.prev;
--		item.next, item.prev = nil, nil;
--		local new_item = commonlib.clone(item);
--		new_listHashSet:add(new_item);
--		item.next, item.prev = last_next, last_prev;
--		item = listHashSet:next(item);
--	end
--	return listHashSet;
--end
