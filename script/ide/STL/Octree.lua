--[[
Title: Octree implementation
Author(s): HuangWeiQiang
Date: 2024.7.24
Desc: This is an Octree implementation in Lua.
Use Lib:
-------------------------------------------------------
local octree = commonlib.Octree:new(Octree:vector3(0, 0, 0), Octree:vector3(20000, 20000, 20000))
local object = { position = Octree:vector3(50, 50, 50) }
octree:insert(object)

-- Insert 1000 unique random points into the Octree
local insertedPoints = {}
local count = 0
while count < 1000 do
	local randomPoint = Octree:vector3(math.random(0, 20000), math.random(0, 20000), math.random(0, 20000))
	local key = string.format('%.2f,%.2f,%.2f', randomPoint.x, randomPoint.y, randomPoint.z)
	if not insertedPoints[key] then
		octree:insert({ position = randomPoint })
		insertedPoints[key] = true
		count = count + 1
	end
end

local point = { position = Octree:vector3(75, 75, 75) }
local closestPoint, closestDistance = octree:findClosestPoint(point)
print('Closest point:', closestPoint)
print('Closest distance:', closestDistance)
-------------------------------------------------------
]]

-- Define the Octree class
local Octree = commonlib.gettable('commonlib.Octree')
commonlib.Octree = Octree
Octree.__index = Octree

-- Create a new Octree
function Octree:new(min, max)
    local obj = setmetatable({}, self)
    obj.min = min
    obj.max = max
    obj.children = {}
    obj.objects = {}
    return obj
end

-- Get the number of points in the Octree
function Octree:getPointCount()
    local count = #self.objects

    -- Recursively count the points in the child nodes
    for _, child in ipairs(self.children) do
        count = count + child:getPointCount()
    end

    return count
end

-- Insert an object into the Octree
function Octree:insert(object)
    -- Check if the object is fully contained within the current node
    if self:contains(object) then
        -- Check if the current node is a leaf node
        if #self.children == 0 then
            table.insert(self.objects, object)
            -- Check if the node needs to be split
            if #self.objects > 8 then
                self:split()
            end
        else
            -- Insert the object into the first child node that contains it
            for _, child in ipairs(self.children) do
                if child:contains(object) then
                    child:insert(object)
                    break
                end
            end
        end
    end
end

-- Split the node into eight child nodes
function Octree:split()
    local min = self.min
    local max = self.max
    local mid = {
        x = (min.x + max.x) / 2,
        y = (min.y + max.y) / 2,
        z = (min.z + max.z) / 2,
    }

    -- Create eight child nodes
    self.children[1] = Octree:new(self:vector3(min.x, min.y, min.z), self:vector3(mid.x, mid.y, mid.z))
    self.children[2] = Octree:new(self:vector3(mid.x, min.y, min.z), self:vector3(max.x, mid.y, mid.z))
    self.children[3] = Octree:new(self:vector3(min.x, mid.y, min.z), self:vector3(mid.x, max.y, mid.z))
    self.children[4] = Octree:new(self:vector3(mid.x, mid.y, min.z), self:vector3(max.x, max.y, mid.z))
    self.children[5] = Octree:new(self:vector3(min.x, min.y, mid.z), self:vector3(mid.x, mid.y, max.z))
    self.children[6] = Octree:new(self:vector3(mid.x, min.y, mid.z), self:vector3(max.x, mid.y, max.z))
    self.children[7] = Octree:new(self:vector3(min.x, mid.y, mid.z), self:vector3(mid.x, max.y, max.z))
    self.children[8] = Octree:new(self:vector3(mid.x, mid.y, mid.z), self:vector3(max.x, max.y, max.z))

    -- Move objects from the parent node to the child nodes
    for _, object in ipairs(self.objects) do
        for _, child in ipairs(self.children) do
            child:insert(object)
        end
    end

    -- Clear objects in the parent node
    self.objects = {}
end

-- Check if the node contains an object
function Octree:contains(object)
    local position = object.position
    return position.x >= self.min.x and position.x <= self.max.x and
        position.y >= self.min.y and position.y <= self.max.y and
        position.z >= self.min.z and position.z <= self.max.z
end

-- Find the closest point to a given point in the Octree
function Octree:findClosestPoint(point)
    local closestPoint = nil
    local closestDistance = math.huge

    -- Recursively search for the closest point in the Octree
    local function search(node)
        -- Check if the node is a leaf node
        if #node.children == 0 then
            -- Iterate through the objects in the leaf node
            for _, obj in ipairs(node.objects) do
                local distance = self:calculateDistance(obj.position, point.position)
                -- Update the closest point and distance if necessary
                if distance < closestDistance then
                    closestPoint = obj
                    closestDistance = distance
                end
            end
        else
            -- Check which child node is closest to the point
            for _, child in ipairs(node.children) do
                search(child)
            end
        end
    end

    -- Start the search from the root node
    search(self)

    return closestPoint, closestDistance
end

function Octree:vector3(x, y, z)
    return { x = x, y = y, z = z }
end

-- Calculate the distance between two points
function Octree:calculateDistance(point1, point2)
    local dx = point2.x - point1.x
    local dy = point2.y - point1.y
    local dz = point2.z - point1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Usage example
-- local octree = Octree:new(Octree:vector3(0, 0, 0), Octree:vector3(20000, 20000, 20000))
-- local object = { position = Octree:vector3(50, 50, 50) }
-- octree:insert(object)

-- Insert 1000 unique random points into the Octree
-- local insertedPoints = {}
-- local count = 0
-- while count < 1000 do
--     local randomPoint = Octree:vector3(math.random(0, 20000), math.random(0, 20000), math.random(0, 20000))
--     local key = string.format('%.2f,%.2f,%.2f', randomPoint.x, randomPoint.y, randomPoint.z)
--     if not insertedPoints[key] then
--         octree:insert({ position = randomPoint })
--         insertedPoints[key] = true
--         count = count + 1
--     end
-- end

-- local point = { position = Octree:vector3(75, 75, 75) }
-- local closestPoint, closestDistance = octree:findClosestPoint(point)
-- print('Closest point:', closestPoint)
-- print('Closest distance:', closestDistance)
