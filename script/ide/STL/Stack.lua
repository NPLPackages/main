--[[
Title: a similar implementation as STL (Standard Libaray) in NPL
Author(s): LiXizhi
Date: 2007/9/22
Desc: Uses a table as stack, use push and pop(). nil value can not be pushed. 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/STL.lua");
stack = commonlib.Stack:new()
-- push values on to the stack
stack:push("a")
-- pop values
stack:pop()
-------------------------------------------------------
]]
local Stack = commonlib.gettable("commonlib.Stack");

function Stack:new(o)
	local object = o or {};
	setmetatable(object, self);
	self.__index = self;
	return object;
end

-- obsoleted: static function. use new() instead. 
function Stack:Create()
	return Stack:new()
end

function Stack:push(v)
	self[#self + 1] = v;
end

-- pop and return value
function Stack:pop()
	local count = #self;
	if(count>0) then
		local v = self[count]
		self[count] = nil;
		return v;
	end
end

function Stack:size()
	return #self;
end