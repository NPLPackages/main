--[[
Title: vector3d pool
Author(s): LiXizhi
Date: 2014/6/14
Desc: useful when creating lots of pool objects in a single frame. 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/math/VectorPool.lua");
local VectorPool = commonlib.gettable("mathlib.VectorPool");
local vec3d_pool = VectorPool.GetSingleton();
-- create from pool. 
local vecPool = vec3d_pool:GetVector(x,y,z)
-- called between tick(not necessary if maxPoolSize is used)
vecPool:CleanPool();
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/math/vector.lua");
local vector3d = commonlib.gettable("mathlib.vector3d");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine")
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types")
local GameLogic = commonlib.gettable("MyCompany.Aries.Game.GameLogic")
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");

local VectorPool = commonlib.gettable("mathlib.VectorPool");
VectorPool.__index = VectorPool;

-- we will automatically reuse from beginning when reaching this value. 
-- such that CleanPool() is not a must-call function. Depending on usage pattern.
VectorPool.startOfChunk = 500;

function VectorPool:new()
	local o = {};
	-- List of vector stored in this Pool
	o.listVector3D = commonlib.vector:new();
	-- Next index to use when adding a Pool Entry.
	o.nextPoolIndex = 1;

	setmetatable(o, self);
	return o;
end

local default_pool;
function VectorPool.GetSingleton()
	if(default_pool) then
		return default_pool;
	else
		default_pool = VectorPool:new();
		default_pool:enlarge(VectorPool.startOfChunk);
		return default_pool;
	end
end

function VectorPool:enlarge(n)
	local i;
	local vec3d;

	for i=#self.listVector3D,n-1,1 do
		vec3d = vector3d:new();
        self.listVector3D:add(vec3d);
	end
end

-- Creates a new Vector, or reuses one that's no longer in use. 
-- @param x,y,z:
-- returns from this function should only be used for one frame or tick, as after that they will be reused.
function VectorPool:GetVector(x,y,z)
    local vec3d;

    if (self.nextPoolIndex > self.listVector3D:size()) then
		self:enlarge(#self.listVector3D * 2);
    end

    local vec3d = self.listVector3D:get(self.nextPoolIndex);
	vec3d:set(x,y,z);
	self.nextPoolIndex = self.nextPoolIndex + 1;
    return vec3d;
end


-- Clears the VectorPool
function VectorPool:clearPool()
    self.nextPoolIndex = 1;
end

-- Clean the VectorPool
function VectorPool:cleanPool()
    self.nextPoolIndex = 1;
    self.listVector3D:clear();
end

function VectorPool:getSize()
	return self.listVector3D:size();
end