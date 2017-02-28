--[[
Title: vector2d
Author(s): Skeleton
Date: 2016/11/26
Desc: 
Represents a Vector in 2D space.
-------------------------------------------------------
NPL.load("(gl)script/ide/math/vector2d.lua");
local vector2d = commonlib.gettable("mathlib.vector2d");

local v1 = vector2d:new(1,1);
local v2 = vector2d:new(2,2);
echo(v1:plus(v2));
echo(v1:minus(v2));
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/ide/math/vector.lua");

local vector3d = commonlib.gettable("mathlib.vector3d");

local type = type;
local vector2d = commonlib.gettable("mathlib.vector2d");
vector2d.__index = vector2d;

--------------------
-- private vector pool
--------------------
local VectorPool = {};
VectorPool.__index = VectorPool;

-- we will automatically reuse from beginning when reaching self value. 
VectorPool.maxPoolSize = 300;

function VectorPool:new()
	local o = {};
	-- Number of times self Pool has been cleaned
	o.numCleans = 0;
	-- List of vector stored in self Pool
	o.listVector2D = commonlib.vector:new();
	-- Next index to use when adding a Pool Entry.
	o.nextPoolIndex = 1;
	-- Largest index reached by self Pool since last CleanPool operation. 
	o.maxPoolIndex = 0;
	-- Largest index reached by self Pool since last Shrink operation. 
	o.maxPoolIndexFromLastShrink = 0;
	o.maxPoolSize = VectorPool.maxPoolSize;
	setmetatable(o, self);
	return o;
end

-- Creates a new Vector, or reuses one that's no longer in use. 
-- @param x,y,z:
-- returns from self function should only be used for one frame or tick, as after that they will be reused.
function VectorPool:GetVector(x,y)
    local vec2d;

    if (self.nextPoolIndex > self.listVector2D:size()) then
		vec2d = vector2d:new():set(x,y);
        self.listVector2D:add(vec2d);
    else
        vec2d = self.listVector2D:get(self.nextPoolIndex);
		vec2d:set(x,y);
    end

    self.nextPoolIndex = self.nextPoolIndex + 1;
	if(self.nextPoolIndex > self.maxPoolSize) then
		self.maxPoolIndex = self.maxPoolSize;
		self.nextPoolIndex = 1;
	end
    return vec2d;
end

local default_pool = VectorPool:new();

------------------------------------------
-- CSG Vector
------------------------------------------

function vector2d.fromAngle(radians)
   return vector2d.fromAngleRadians(radians);
end
function vector2d.fromAngleDegrees(degrees)
   local radians = math.pi * degrees / 180;
   return vector2d.fromAngleRadians(radians);
end
function vector2d.fromAngleRadians(radians)
   return vector2d:new(math.cos(radians), math.sin(radians));
end


-- create a new vector
-- @param x, y, z: if x is nil, it is a {0,0,0} vector; if x is table, it is an array of x,y,z. if x is number, then y, z must also be number. 
function vector2d:new(x,y)
	local o;
	local type_ = type(x);
	if(type_ == "number") then
		o = {x,y};
	elseif(type_ == "table") then
		o = x;
	else
		o = {0,0};
	end
	setmetatable(o, self);
	return o;
end

function vector2d:new_from_pool(x,y)
	return default_pool:GetVector(x,y);	
end

function vector2d:clone()
	return vector2d:new(self[1],self[2]);
end

function vector2d:clone_from_pool()
	return default_pool:GetVector(self[1],self[2]);
end


-- Returns the axis along which this vector is dominant 
-- @return number: 1 for x, 2 for y, 3 for z
function vector2d:dominantAxis()
	local xx = math.abs(self[1]);
	local yy = math.abs(self[2]);

	if (xx > yy) then
		return 1;
	end
	return 2;
end

-- get length
function vector2d:length()
	local len_sq = self:length2();
	if(len_sq>0) then
		return len_sq^0.5;
	else
		return 0;
	end
end

-- get length square
function vector2d:length2()
	return (self[1]^2 + self[2]^2);
end

function vector2d:normalize()
    local m = self:length()
    if m > 0.00001 then
        m = 1/m
        self[1] = self[1] * m
        self[2] = self[2] * m
    else
        self[1] = 0
        self[2] = 0
    end
    return self;
end

function vector2d:set(x,y)
    if y == nil then
        self[1] = x[1]
        self[2] = x[2]
    else
        self[1] = x
        self[2] = y
    end
	return self;
end

function vector2d:add(x,y)
    if y == nil then
        self[1] = self[1] + x[1]
        self[2] = self[2] + x[2]
    else
        self[1] = self[1] + x
        self[2] = self[2] + y
    end
	return self;
end

function vector2d.__add(a,b)
	return vector2d:new(a[1]+b[1], a[2]+b[2])
end

function vector2d:interpolate(x,y,a)
    if z == nil then
        self[1] = self[1] + (x[1] - self[1]) * y
        self[2] = self[2] + (x[2] - self[2]) * y
    else
        self[1] = self[1] + (x - self[1]) * a
        self[2] = self[2] + (y - self[2]) * a
    end
    return self
end

function vector2d:sub(x,y)
    if y == nil then
        self[1] = self[1] - x[1]
        self[2] = self[2] - x[2]
    else
        self[1] = self[1] - x
        self[2] = self[2] - y
    end
	return self;
end

function vector2d.__sub(a,b)
	return vector2d:new(a[1]-b[1], a[2]-b[2])
end

function vector2d:MulByFloat(a)
    self[1] = self[1] * a
    self[2] = self[2] * a
	return self;
end

-- @param a: vector2d
function vector2d:MulByVector(a)
    self[1] = self[1] * a[1]
    self[2] = self[2] * a[2]
	return self;
end

-- @param a: vector2d
-- @return a new vector
function vector2d:MulVector(a)
	return vector2d:new(self[1] * a[1], self[2] * a[2]);
end

-- transform by a float or Matrix4
-- @param b: can be number, vector2d or Matrix4
function vector2d.__mul(a,b)
	if(type(b) == "table") then
		if(#b == 16) then
			local x,y,z = a[1], 0, a[2];
			return vector2d:new(
				x*b[1] + y*b[5] + z*b[9] + b[13],
				--x*b[2] + y*b[6] + z*b[10] + b[14],
				x*b[3] + y*b[7] + z*b[11] + b[15]
				);
		end
		-- no cross product with a vector2d
	elseif(type(b) == "number") then
		return vector2d:new(a[1] * b, a[2] * b)
	end
end

-- @param x can be number or another vector 
function vector2d:dot(x,y)
	if not y then
        return self[1] * x[1] + self[2] * x[2];
    else
        return self[1] * x + self[2] * y
    end
end

function vector2d:get()
    return self[1],self[2]
end

-- distance square to a point
-- @param x can be number or another vector 
function vector2d:dist2(x,y)
    if not y then 
		return (self[1]-x[1])^2 + (self[2]-x[2])^2;
	else
		return (self[1]-x)^2 + (self[2]-y)^2;
	end
end


-- distance to a point
-- note param y can be nil. 
function vector2d:dist(x,y)
	local len_sq =  self:dist2(x,y);
    if(len_sq>0) then
		return len_sq^0.5;
	else
		return 0;
	end
end

function vector2d:tostring()
    return format("%f %f",self[1],self[2])
end

function vector2d:compare(v)
	return (self[1] == v[1] and self[2] == v[2]);
end

function vector2d:equals(v,epsilon)
	epsilon = epsilon or 0;
	if(epsilon==0) then
		return (self[1] == v[1]) and (self[2] == v[2]);
	end
	return (math.abs(self[1] - v[1])<=epsilon and math.abs(self[2] - v[2])<=epsilon);
end

-- the angle between self and dest
-- @param dest
-- return a value between 0,3.14
function vector2d:angleTo(dest)
	local lenProduct = self:length() * dest:length();
	-- Divide by zero check
	if (lenProduct < 0.000001) then
		lenProduct = 0.000001;
	end
	local f = self:dot(dest) / lenProduct;
	f = mathlib.clamp(f, -1.0, 1.0);
	return math.acos(f);
end

function vector2d:angle()
    return self:angleRadians();
end

function vector2d:angleDegrees()
    local radians = self:angleRadians();
    return 180 * radians / math.pi;
end

function vector2d:angleRadians()
    -- y=sin, x=cos
    local r = math.atan2(self[2], self[1]);
	if (r ~= r) then	-- test for nan
		r = 0;
	end
	return r;
end

-- Returns TRUE if the vectors are parallel, that is, pointing in
-- the same or opposite directions, but not necessarily of the same magnitude.
-- @param tolerance: default to a small number
function vector2d:isParallel(otherVector, tolerance)
	local factor = self:length() * otherVector:length();
	local dotPrd = self:dot(otherVector) / factor;
	return (math.abs(math.abs(dotPrd) - 1.0) <= (tolerance or 0.000001));
end

function vector2d:negated()
	self[1], self[2] = -self[1],-self[2];
	return self;
end

function vector2d:abs()
	self[1], self[2] = math.abs(self[1]),math.abs(self[2]);
	return self;
end

function vector2d:transform(m)
	local x,y,z = self[1], 0, self[2];
	self[1] = x*m[1] + y*m[5] + z*m[9] +  m[13];
	self[2] = x*m[3] + y*m[7] + z*m[11] + m[15];
	local w = x*m[4] + y*m[8] + z*m[12] + m[16];
	if (w ~= 1) then
        local invw = 1.0 / w;
        self[1] = self[1] * invw;
        self[2] = self[2] * invw;
    end
	return self;	
end
function vector2d:transform_normal(m)
	local x,y,z = self[1], 0, self[2];
	self[1] = x*m[1] + y*m[5] + z*m[9];
	self[2] = x*m[3] + y*m[7] + z*m[11];
	local w = x*m[4] + y*m[8] + z*m[12] + m[16];
	if (w ~= 1) then
        local invw = 1.0 / w;
        self[1] = self[1] * invw;
        self[2] = self[2] * invw;
    end
	return self;	
end

function vector2d:cross(a)
	return self[1] * a[2] - self[2] * a[1];
end

function vector2d:min(p)
	self[1], self[2] = 
		math.min(self[1], p[1]), math.min(self[2], p[2]);
	return self;
end

function vector2d:max(p)
	self[1], self[2] = 
		math.max(self[1], p[1]), math.max(self[2], p[2]);
	return self;
end

-- extend to a 3D vector by adding a y coordinate:
function vector2d:toVector3D(y)
    return vector3d:new(self[1], y, self[2]);
end

-- returns the vector rotated by 90 degrees clockwise
function vector2d:normal()
    return vector2d:new(self[2], -self[1]);
end

-- some static members.
vector2d.unit_x = vector2d:new(1,0);
vector2d.unit_z = vector2d:new(0,1);
vector2d.zero = vector2d:new();