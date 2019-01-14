--[[
Title:
Author(s): LiPeng
Date: 2018/2/1
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntPoint.lua");
local Point = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");
local p1 = Point:new():init(0,0);
local p2 = Point:new_from_pool(9,0);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL/RingBuffer.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
local Size = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local temp_pool = commonlib.RingBuffer:new(); 
local type = type;
local Point = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");
Point.__index = Point;

-- create a new point
-- @param x,y: if y is nil, x should be table or nil. 
function Point:new(x, y)
	local o;
	if(y) then
		o = {x, y};
	else
		o = x or {0,0};
	end
	setmetatable(o, self);
	return o;
end

--function Point:init(x,y)
--	self:Reset(x,y);
--	return self;
--end

function Point:Reset(x,y)
	self[1], self[2] = x or 0, y or 0;
	return self;
end

-- this is actually a ring buffer of 200, pay attention not to reach over this value in recursive calls. 
function Point:new_from_pool(x,y)
	if(temp_pool:size() >= 2000) then
		return temp_pool:next():Reset(x,y);
	else
		return temp_pool:add(Point:new(x,y));
	end
end

function Point:Create(x,y,beFromPool)
	if(beFromPool) then
		return Point:new_from_pool(x,y);
	end
	return Point:new(x,y);
end

-- make a clone 
function Point:clone()
    return Point:new(self[1], self[2]);
end

function Point:clone_from_pool()
	return self:new_from_pool(self[1], self[2]);
end

function Point:X()
	return self[1];
end

function Point:Y()
	return self[2];
end

function Point:SetX(x)
	self[1] = x;
end

function Point:SetY(y)
	self[2] = y;
end

function Point:Move(x, y)
	if(not y) then
		local size = x;
		x = size:Width();
		y = size:Height();
	end
	self[1] = self[1] + x;
	self[2] = self[2] + y;
end

function Point:MoveBy(offset)
	self:Move(offset:X(), offset:Y());
end

function Point:Scale(sx, sy)
	self[1] = math.round(self[1] * sx);
	self[2] = math.round(self[2] * sy);
end

function Point:ExpandTo(other, beFromPool)
	local x = if_else(self:X() > other:X(), self:X(), other:X());
	local y = if_else(self:Y() > other:Y(), self:Y(), other:Y());
	return Point:Create(x,y,beFromPool);
end

function Point:ShrunkTo(other, beFromPool)
	local x = if_else(self:X() < other:X(), self:X(), other:X());
	local y = if_else(self:Y() < other:Y(), self:Y(), other:Y());
	return Point:Create(x,y,beFromPool);
end

function Point:ClampNegativeToZero()
	local temp = self:ExpandTo(Point.zero, true);
	self[1] = temp[1];
	self[2] = temp[2];
end

function Point:TransposedPoint(beFromPool)
	return Point:Create(self:Y(),self:X(),beFromPool);
end

function Point:ToSize()
	return Size:new(self[1], self[2]);
end

function Point:IsPoint()
	return true;
end

function Point:IsSize()
	return false;
end

function Point:IsRect()
	return false;
end

function Point:Type()
	return "Point";
end

function Point.__unm(o)
	return Point:new(-o[1], -o[2]);
end

-- when b is IntSize, b[1] is width, b[2] is height, this's ok also;
function Point.__add(a,b)
	return Point:new(a[1]+b[1], a[2]+b[2])
end

--inline IntSize operator-(const IntPoint& a, const IntPoint& b)
--inline IntPoint operator-(const IntPoint& a, const IntSize& b)
function Point.__sub(a,b)
	if(b:IsPoint()) then
		return Size:new(a[1]-b[1], a[2]-b[2]);
	end
	return Point:new(a[1]-b[1], a[2]-b[2])
end

function Point.__eq(a,b)
	return a[1] == b[1] and a[2] == b[2];
end

-- some static members.
Point.unit_x = Point:new(1,0);
Point.unit_y = Point:new(0,1);
Point.zero = Point:new(0, 0);