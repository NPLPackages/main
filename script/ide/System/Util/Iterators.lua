--[[
Title: Iterators
Author(s): LiXizhi, 
Date: 2023/2/20
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/Iterators.lua");
local Iterators = commonlib.gettable("System.Util.Iterators");
for dx, dy, dz in Iterators.Spiral3d(3) do 
	echo({dx, dy, dz}) 
end
for dx, dy in Iterators.Spiral2d(2) do 
	echo({dx, dy}) 
end
for dx, dy in Iterators.SpiralSquare(2) do 
	echo({dx, dy}) 
end
for dx, dy in Iterators.SpiralCircle(2) do 
	echo({dx, dy}) 
end
------------------------------------------------------------
]]
local Iterators = commonlib.gettable("System.Util.Iterators");

local index_caches = {}

-- a simple and fast algorithm to traverse a 3D array using Manhattan distance from small to big. e.g.
-- for dx, dy, dz in Iterators.Spiral3d(3) do echo({dx, dy, dz}) end
-- @param radius: [0, N] radius or Manhattan distance, so that the returned x+y+z=radius
-- @param bNoCache: [true|false|nil] true to disable caching index for iterators with same radius. 
-- if nil, this value will default to true if radius is bigger than 16, and false otherwise.
-- @return iterator of 3d coordinates inside out. 
-- Distance:0 [0,0,0] 
-- Distance:1 [0,0,1] [0,0,-1] [0,1,0] [0,-1,0] [1,0,0] [-1,0,0] 
function Iterators.Spiral3d(radius, bNoCache)
	-- rise the distance by one each iteration
	local cache = index_caches["Spiral3d"..radius]
	if(not cache) then
		cache = {{}, {}, {}};
		if(bNoCache ~= true and radius < 16) then
			index_caches["Spiral3d"..radius] = cache;
		end
		local arrayX, arrayY, arrayZ = cache[1], cache[2], cache[3];
		local size = 0;
		for distance = 0, radius do
			for x = 0, distance do
				for y = 0, distance-x do
					local z = distance - (x + y);  -- distance=x+y+z
					size = size + 1;
					arrayX[size], arrayY[size], arrayZ[size] = x,y,z
					if(x~=0) then
						size = size + 1;
						arrayX[size], arrayY[size], arrayZ[size] = -x,y,z
					end
					if(y~=0) then
						size = size + 1;
						arrayX[size], arrayY[size], arrayZ[size] = x,-y,z
					end
					if(z~=0) then
						size = size + 1;
						arrayX[size], arrayY[size], arrayZ[size] = x,y,-z
					end
					if(x~=0 and y~=0) then 
						size = size + 1;
						arrayX[size], arrayY[size], arrayZ[size] = -x,-y,z
					end
					if(x~=0 and z~=0) then 
						size = size + 1;
						arrayX[size], arrayY[size], arrayZ[size] = -x,y,-z
					end
					if(y~=0 and z~=0) then 
						size = size + 1;
						arrayX[size], arrayY[size], arrayZ[size] = x,-y,-z
					end
					if(y~=0 and y~=0 and z~=0) then
						size = size + 1;
						arrayX[size], arrayY[size], arrayZ[size] = -x,-y,-z
					end
				end
			end
		end
	end
	local i = 0
	local n = #(cache[1])
	return function ()
		i = i + 1
		if i <= n then 
			return cache[1][i], cache[2][i], cache[3][i]
		end
	end
end

-- a simple and fast algorithm to traverse a 3D array using Manhattan distance from small to big. e.g.
-- for dx, dy, dz in Iterators.Spiral2d(3) do echo({dx, dy}) end
-- @param radius: [0, N] radius or Manhattan distance, so that the returned x+y=radius
-- @param bNoCache: [true|false|nil] true to disable caching index for iterators with same radius. 
-- if nil, this value will default to true if radius is bigger than 16, and false otherwise.
-- Distance:0 [0,0] 
-- Distance:1 [0,1] [0,-1] [1,0] [-1,0]
function Iterators.Spiral2d(radius, bNoCache)
	-- rise the distance by one each iteration
	local cache = index_caches["Spiral2d"..radius]
	if(not cache) then
		cache = {{}, {}};
		if(bNoCache ~= true and radius < 16) then
			index_caches["Spiral2d"..radius] = cache;
		end
		local arrayX, arrayY = cache[1], cache[2];
		for distance = 0, radius do
			for x = 0, distance do
				y = distance - x;  -- distance=x+y
				arrayX[#arrayX + 1] = x
				arrayY[#arrayY + 1] = y
				if(x~=0) then
					arrayX[#arrayX + 1] = -x
					arrayY[#arrayY + 1] = y
				end
				if(y~=0) then
					arrayX[#arrayX + 1] = x
					arrayY[#arrayY + 1] = -y
				end
				if(x~=0 and y~=0) then 
					arrayX[#arrayX + 1] = -x
					arrayY[#arrayY + 1] = -y
				end
			end
		end
	end
	local i = 0
	local n = #(cache[1])
	return function ()
		i = i + 1
		if i <= n then 
			return cache[1][i], cache[2][i]
		end
	end
end

-- traverse an array with square spiral fashion 
-- @param radius: [0, N] radius or spiral. This is also the maximum value of output coordinate value. 
-- @param bNoCache: [true|false|nil] true to disable caching index for iterators with same radius. 
-- if nil, this value will default to true if radius is bigger than 16, and false otherwise.
-- @return if radius is 1, it returns in following order: {0,0}{0,-1}{1,-1}{1,0}{1,1}{0,1}{-1,1}{-1,0}{-1,-1}
function Iterators.SpiralSquare(radius, bNoCache)
	local cache = index_caches["SpiralSquare"..radius]
	if(not cache) then
		cache = {{}, {}};
		if(bNoCache ~= true and radius < 16) then
			index_caches["SpiralSquare"..radius] = cache;
		end
		local arrayX, arrayY = cache[1], cache[2];
		arrayX[#arrayX + 1] = 0 
		arrayY[#arrayY + 1] = 0
		local i, j = -1, -1
		for r = 1, radius do
			while i < r do
				i = i + 1
				arrayX[#arrayX + 1] = i
				arrayY[#arrayY + 1] = j
			end
			while j < r do
				j = j + 1
				arrayX[#arrayX + 1] = i
				arrayY[#arrayY + 1] = j
			end
			while i > -r do
				i = i - 1
				arrayX[#arrayX + 1] = i
				arrayY[#arrayY + 1] = j
			end
			while j > -r do
				j = j - 1
				arrayX[#arrayX + 1] = i
				arrayY[#arrayY + 1] = j
			end
			j = j - 1
			arrayX[#arrayX + 1] = i
			arrayY[#arrayY + 1] = j
		end
		if(radius > 0) then
			arrayX[#arrayX] = nil
			arrayY[#arrayY] = nil
		end
	end
	local i = 0
	local n = #(cache[1])
	return function ()
		i = i + 1
		if i <= n then 
			return cache[1][i], cache[2][i]
		end
	end
end

-- @param radius: [0, N] radius or spiral. This is also the maximum value of output coordinate value. 
-- @param bNoCache: [true|false|nil] true to disable caching index for iterators with same radius. 
-- if nil, this value will default to true if radius is bigger than 16, and false otherwise.
-- return 2d coordinate in spiral circle£º e.g. for radius=2, it returns in following order {0,0}{0,-1}{0,1}{1,0}{-1,0}{-1,1}{1,1}{-1,-1}{1,-1}{-2,0}{0,-2}{0,2}{2,0,}
function Iterators.SpiralCircle(radius, bNoCache)
	local cache = index_caches["SpiralCircle"..radius]
	if(not cache) then
		cache = {};
		if(bNoCache ~= true and radius < 16) then
			index_caches["SpiralCircle"..radius] = cache;
		end
		local radiusSq = radius*radius;
		for x = -radius, radius do
			for y = -radius, radius do
				local r_sq = (x^2) + (y^2)
				if(r_sq <= radiusSq ) then
					cache[#cache + 1] = {x, y, r_sq}
				end
			end
		end
		table.sort(cache, function(a, b)
			return a[3] < b[3];
		end)
	end
	local i = 0
	local n = #(cache)
	return function()
		i = i + 1
		if i <= n then 
			local coord = cache[i]
			return coord[1], coord[2]
		end
	end
end