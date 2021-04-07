--[[
Title: a similar implementation as STL (Standard Libaray) in NPL
Author(s): LiXizhi
Date: 2009.10.8(List, LinkedList)
Desc:  two directional linked list that use the item itself for data keeping. 
Therefore data item can only be tables without prev and next fields. 
Note: use commonlib.LinkedList if one wants linked list for any data types. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/STL.lua");
---+++ List example
local list = commonlib.List:new();
list:add({"item1"})
list:add({"item2"})
list:add({"item3"})
local item = list:first();
list:remove(item.next);
item = list:first();
while (item) do
	commonlib.echo(item[1])
	item = list:next(item)
end
echo(list:Clone():size())
-------------------------------------------------------
]]
local table_insert = table.insert;
local table_remove = table.remove;
local type, ipairs, pairs, unpack = type, ipairs, pairs, unpack;


commonlib = commonlib or {}
commonlib.List = commonlib.List or {};
local List = commonlib.List;

List.__index = List;

function List:new(o)
    o = o or {}
	o.head, o.tail, o.nSize = nil, nil, 0;
	setmetatable(o, self);
	return o;
end

-- get the first item
function List:first()
	return self.head;
end

-- get the last item
function List:last()
	return self.tail;
end

-- get the next item of input item
-- @return nil if no next item. 
function List:next(item)
	return item.next;
end

-- get the previous item of input item
-- @return nil if no previous item. 
function List:prev(item)
	return item.prev;
end

-- add a new item to the end of the list. It takes o(1) time to add.
-- @param item: item must be table. The table fields item.prev and item.next are reserved for list data keeping. 
-- @return item is returned for handy use. 
function List:addtail(item)
	if(not item) then 
		LOG.std("", "warn", "STL", "List:addtail() can not add nil item. Item must be a table");
		return 
	end
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
	return item
end
List.add = List.addtail;
List.push_back = List.addtail;

-- add a new item to the head of the list. It takes o(1) time to add.
-- @param item: item must be table. The table fields item.prev and item.next are reserved for list data keeping. 
-- @return item is returned for handy use. 
function List:push_front(item)
	if(not item) then 
		LOG.std("", "warn", "STL", "List:addtail() can not add nil item. Item must be a table");
		return 
	end
	if(not self.tail) then
		-- the first item
		self.tail = item;
		item.prev = nil;
		item.next = nil;
		self.head = self.tail;
	else
		item.prev = nil;
		item.next = self.head;
		self.head.prev = item;
		self.head = item;
	end
	self.nSize = self.nSize + 1;
	return item
end

-- insert item before before_item
function List:insert_before(item, before_item)
	if(not before_item) then
		return self:push_front(item);
	end
	
	if(before_item.prev) then
		before_item.prev.next = item;
		item.prev = before_item.prev
	else
		self.head = item;
		item.prev = nil;
	end

	item.next = before_item;
	before_item.prev = item;
	self.nSize = self.nSize + 1;
	return item;
end

-- insert item after after_item
function List:insert_after(item, after_item)
	if(not after_item) then
		return self:push_back(item);
	end
	
	if(after_item.next) then
		after_item.next.prev = item;
		item.next = after_item.next;
	else
		self.tail = item;
		item.next = nil;
	end
	item.prev = after_item;
	after_item.next = item;
	self.nSize = self.nSize + 1;
	return item;
end

local function changePrev(item, prev)
	item.prev = prev;
	if(prev) then
		prev.next = item;
	end
end

local function changeNext(item, next)
	item.next = next;
	if(next) then
		next.prev = item;
	end
end

function List:swapAdjoin(prev_item, next_item)
	changePrev(next_item, prev_item.prev);
	changeNext(prev_item, next_item.next);

	prev_item.prev = next_item;
	next_item.next = prev_item;
end


function List:swap(item1, item2)
	if(item1 and item2) then
		if(item1.next == item2) then
			self:swapAdjoin(item1, item2);
		elseif(item2.next == item1) then
			self:swapAdjoin(item2, item1);
		else
			local temp = item1.prev;
			changePrev(item1, item2.prev);
			changePrev(item2, temp);

			temp = item1.next;
			changeNext(item1, item2.next);
			changeNext(item2, temp);
		end
		self.head = if_else(not item1.prev, item1, self.head);
		self.head = if_else(not item2.prev, item2, self.head);

		self.tail = if_else(not item1.next, item1, self.tail);
		self.tail = if_else(not item2.next, item2, self.tail);
	end
end

-- remove an item from the list. It takes o(1) time to remove.
-- if item is not from list. the item will be removed. however if item is head or tail, it may make the container list invalid. 
-- @param item: item must be table. The table fields item.prev and item.next are reserved for list data keeping. 
-- @return the next item of the remove item. 
function List:remove(item)
	if(not item) then
		return
	end
	self.nSize = self.nSize - 1;
	local next = item.next;
	local prev = item.prev;
	if(prev) then
		prev.next = next
	else
		if(self.head == item) then
			self.head = next;
		end
	end
	
	if(next) then
		next.prev = prev;
	else
		if(self.tail == item) then
			self.tail = prev;
		end
	end
	item.next = nil;
	item.prev = nil;
	return next;
end

-- return the poped object or nil.
function List:pop()
	local last = self:last();
	if(last) then
		self:remove(last);
		return last;
	end
end

-- clear all items
function List:clear()
	local item = self:first();
	while (item) do
		self:remove(item);
		item = self:first()
	end
end

-- get item count in the list
function List:size()
	return self.nSize;
end

-- if empty
function List:empty()
	return self.nSize == 0;
end


-- return an iterator of item
function List:each()
	local item = self:first();
	return function ()
		if(item) then
			local curItem = item;
			item = self:next(curItem);
			return curItem;
		end
	end
end

-- clone this list 
-- @return a new cloned list. 
function List:Clone()
	local list = self;
	local item = list:first();
	local new_list = List:new();
	while (item) do
		local last_next, last_prev = item.next, item.prev;
		item.next, item.prev = nil, nil;
		local new_item = commonlib.clone(item);
		new_list:add(new_item);
		item.next, item.prev = last_next, last_prev;
		item = list:next(item);
	end
	return new_list;
end

local function less(item1, item2)
	return item1[1] <= item2[1];
end

function List:sort(compFun)
	compFun = compFun or less;
	local begin_item = self:first();
	while(begin_item) do
		local before_begin_item = begin_item.prev;
		local next_item = self:next(begin_item);
		while(next_item) do
			local next_next_item = next_item.next;		
			if(not compFun(begin_item, next_item)) then
				self:swap(begin_item, next_item);
				if(before_begin_item) then
					begin_item = self:next(before_begin_item);
				else
					begin_item = self:first();
				end
			end
			next_item = next_next_item;
		end
		begin_item = self:next(begin_item);
	end
end

--[[ test and example
function List:TestMe()
	-- case1: add, remove
	commonlib.applog("should export item1 item3")
	local list = commonlib.List:new();
	list:add({"item1"})
	list:add({"item2"})
	list:add({"item3"})
	local item = list:first();
	list:remove(item.next);
	item = list:first();
	while (item) do
		commonlib.echo(item[1])
		item = list:next(item)
	end
	
	-- case2: clear, size
	commonlib.applog("should export ok1 and size=1")
	list:clear();
	list:add({"ok1"})
	item = list:first();
	while (item) do
		commonlib.echo(item[1])
		item = list:next(item)
	end
	commonlib.echo({size=list:size()})
end]]