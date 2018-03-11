--[[
Title: 
Author(s): LiPeng
Date: 2018/2/1
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/geometry/IntSize.lua");
local Size = commonlib.gettable("System.Windows.mcml.geometry.IntSize");
local sz1 = Size:new():init(0,0);
local sz2 = Size:new_from_pool(9,0);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL/RingBuffer.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/geometry/IntPoint.lua");
local Point = commonlib.gettable("System.Windows.mcml.geometry.IntPoint");
local temp_pool = commonlib.RingBuffer:new(); 
local type = type;
local Size = commonlib.gettable("System.Windows.mcml.geometry.IntSize");
Size.__index = Size;

-- create a new Size
-- @param w,h: if h is nil, w should be table or nil. 
function Size:new(w, h)
	local o;
	if(h) then
		o = {w, h};
	else
		o = w or {0,0};
	end
	setmetatable(o, self);
	return o;
end

function Size:init(w,h)
	self[1], self[2] = w or 0, h or 0;
	return self;
end

-- this is actually a ring buffer of 200, pay attention not to reach over this value in recursive calls. 
function Size:new_from_pool(w,h)
	if(temp_pool:size() >= 2000) then
		return temp_pool:next():init(w,h);
	else
		return temp_pool:add(Size:new():init(w,h));
	end
end

function Size:Create(w,h,beFromPool)
	if(beFromPool) then
		return Size:new_from_pool(w,h);
	end
	return Size:new(w,h);
end

-- make a clone 
function Size:clone()
    return Size:new(self[1], self[2]);
end

function Size:clone_from_pool()
	return self:new_from_pool(self[1], self[2]);
end

function Size:Width()
	return self[1];
end

function Size:Height()
	return self[2];
end

function Size:SetWidth(w)
	self[1] = w;
end

function Size:SetHeight(h)
	self[2] = h;
end

function Size:IsEmpty()
	return self[1] <= 0 or self[2] <= 0;
end

function Size:IsZero()
	return self[1] == 0 and self[2] == 0;
end

function Size:AspectRatio()
    return self[1]/self[2];
end

function Size:Expand(w, h)
    self[1] = self[1] + w;
	self[2] = self[2] + h;
end

function Size:Scale(w_scale, h_scale)
	h_scale = h_scale or w_scale;
    self[1] = math.round(self[1] * w_scale);
	self[2] = math.round(self[2] * h_scale);
end

function Size:ExpandTo(other, beFromPool)
	local w = if_else(self:Width() > other:Width(), self:Width(),other:Width());
	local h = if_else(self:Height() > other:Height(), self:Height(),other:Height());
	return Size:Create(w,h,beFromPool);
end

function Size:ShrunkTo(other, beFromPool)
	local w = if_else(self:Width() < other:Width(), self:Width(),other:Width());
	local h = if_else(self:Height() < other:Height(), self:Height(),other:Height());
	return Size:Create(w,h,beFromPool);
end

function Size:ClampNegativeToZero()
	local temp = self:ExpandTo(Size.zero, true);
	self[1] = temp[1];
	self[2] = temp[2];
end

function Size:ClampToMinimumSize(minimum_size)
	if(self:Width() < minimum_size:Width()) then
		self:SetWidth(minimum_size:Width());
	end
	if(self:Height() < minimum_size:Height()) then
		self:SetHeight(minimum_size:Height());
	end
end

function Size:Area()
	return self[1] * self[2];
end

function Size:DiagonalLengthSquared()
	return self[1] * self[1] + self[2] * self[2];
end

function Size:TransposedSize(beFromPool)
	return Size:Create(self:Height(),self:Width(),beFromPool);
end

function Size:ToPoint()
	return Point:new(self[1], self[2]);
end

function Size.__num(o)
	return Size:new(-o[1], -o[2]);
end

function Size.__add(a,b)
	return Size:new(a[1]+b[1], a[2]+b[2])
end

function Size.__sub(a,b)
	return Size:new(a[1]-b[1], a[2]-b[2])
end

function Size.__eq(a,b)
	return a[1] == b[1] and a[2] == b[2];
end

function Size:tostring()
    return format("%dx%d",self[1],self[2])
end


-- some static members.
Size.unit_x = Size:new(1,0);
Size.unit_y = Size:new(0,1);
Size.zero = Size:new(0, 0);