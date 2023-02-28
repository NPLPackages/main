--[[
Title: example map handler used in A(*) star, astar path finding
Author: LiXizhi, based on https://github.com/GloryFish/lua-astar/blob/master/astar.lua
Date: 2022/2/4
Desc: Note, a good map handler may be implemented in such as a way that it has no memory allocations for node and location tables. 
virtual functions:
- getNode(location)
- locationsAreEqual(a, b)
- getAdjacentNodes(curNode, destLocation, openNodes)

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/AStar.lua");
local AStar = commonlib.gettable("System.Util.AStar");

-- one should create its own map handler with map data. 
NPL.load("(gl)script/ide/System/Util/AStarMapHandler.lua");
local MapHandler = commonlib.gettable("System.Util.AStar.MapHandlerBase");

local astar = AStar:new():Init(MapHandler:new());
local path = astar:findPath({x=1,y=1}, {x=3,y=4}) -- fromLocation, toLocation
if(path) then
	for _m, node in ipairs(path:getNodes()) do
		echo(node.location)
	end
end
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Util/AStar.lua");
local AStar = commonlib.gettable("System.Util.AStar");
local MapHandler = commonlib.inherit(nil, commonlib.gettable("System.Util.AStar.MapHandlerBase"));

function MapHandler:ctor()
	self.tiles = {
		{1,1,1,1,},
		{1,0,0,0,},
		{1,1,1,1,},
		{1,1,1,1,},
	};
end

local function GetLocationId(x, y)
	return y * 100000 + x
end

-- virtual function:
-- Here you make sure the requested node is valid (i.e. on the map, not blocked)
-- if the location is not valid or blocked, return nil, otherwise return a new Node object
function MapHandler:getNode(location)
	-- Here you make sure the requested node is valid (i.e. on the map, not blocked)
	if location.x > #self.tiles[1] or location.y > #self.tiles then
		-- print 'location is outside of map on right or bottom'
		return nil
	end

	if location.x < 1 or location.y < 1 then
		-- print 'location is outside of map on left or top'
		return nil
	end

	if self.tiles[location.y][location.x] == 0 then
		-- print(string.format('location is solid: (%i, %i)', location.x, location.y))
		return nil
	end
	return AStar.Node:new():Init(location, 1, GetLocationId(location.x, location.y))
end

-- virtual function:
-- Here you check to see if two locations (not nodes) are equivalent
-- If you are using a vector for a location you may be able to simply return a == b
-- however, if your location is represented some other way, you can handle 
-- it correctly here without having to modufy the AStar class
function MapHandler:locationsAreEqual(a, b)
	return a.x == b.x and a.y == b.y
end

local result = {}
-- virtual function:
-- Given a node, return a table containing all adjacent nodes
-- The code here works for a 2d tile-based game but could be modified for other types of node graphs
-- @param dest: destination location
-- @param openNodes: all currently open nodes, one may reuse the same node object if needed. 
-- @param closedNodes: all currently closed nodes, one may reuse the same node object if needed. 
-- we can also disregard openNodes, closedNodes
-- @return array of nodes
function MapHandler:getAdjacentNodes(curNode, dest, openNodes, closedNodes)
	local cl = curNode.location
	local dl = dest
  
	local n
	result[4] = nil
	result[3] = nil
	result[2] = nil
	result[1] = nil
  
	n = self:_handleNode(cl.x + 1, cl.y, curNode, dl.x, dl.y, openNodes, closedNodes)
	if n then
		table.insert(result, n)
	end

	n = self:_handleNode(cl.x - 1, cl.y, curNode, dl.x, dl.y, openNodes, closedNodes)
	if n then
		table.insert(result, n)
	end

	n = self:_handleNode(cl.x, cl.y + 1, curNode, dl.x, dl.y, openNodes, closedNodes)
	if n then
		table.insert(result, n)
	end

	n = self:_handleNode(cl.x, cl.y - 1, curNode, dl.x, dl.y, openNodes, closedNodes)
	if n then
		table.insert(result, n)
	end
  
	return result
end

-- Fetch a Node for the given location and set its parameters
-- we can also disregard openNodes, closedNodes
function MapHandler:_handleNode(x, y, fromNode, destx, desty, openNodes, closedNodes)
	local locationId = GetLocationId(x, y)
	local lastNode = openNodes[locationId]
	if(closedNodes[locationId]) then
		return lastNode
	elseif(lastNode) then
		-- reuse existing node
		local mCost = fromNode.mCost + 1;
		if(mCost < lastNode.mCost) then
			lastNode.mCost = mCost;
			lastNode.score = lastNode.mCost + emCost
			lastNode.parent = fromNode
		end
		return lastNode;
	else
		local n = self:getNode({x=x, y=y})
		if n ~= nil then
			local dx = math.abs(x-destx)
			local dy = math.abs(y-desty)
			local emCost = dx + dy
    
			n.mCost = fromNode.mCost + 1;
			n.score = n.mCost + emCost
			n.parent = fromNode
    
			return n
		end
	end
end

