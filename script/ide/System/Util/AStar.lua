--[[
Title: A(*) star, astar path finding
Author: LiXizhi, based on https://github.com/GloryFish/lua-astar/blob/master/astar.lua
Date: 2022/2/4
Desc: 
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
local AStar = commonlib.inherit(nil, commonlib.gettable("System.Util.AStar"));

------------------
-- AStar Path
------------------
local Path = commonlib.inherit(nil, commonlib.gettable("System.Util.AStar.Path"));

function Path:Init(nodes, totalCost)
	self.nodes = nodes
	self.totalCost = totalCost
	return self;
end

function Path:getNodes()
	return self.nodes
end

function Path:getTotalMoveCost()
	return self.totalCost
end

------------------
-- AStar Node
------------------
local Node = commonlib.inherit(nil, commonlib.gettable("System.Util.AStar.Node"));
function Node:Init(location, mCost, locationId, parent)
	self.location = location -- Where is the node located
	self.mCost = mCost -- Total move cost to reach this node
	self.parent = parent -- Parent node
	self.score = 0 -- Calculated score for this node
	self.locationId = locationId -- set the location id - unique for each location in the map
	return self
end

function Node.__eq(a, b)
	return a.locationId == b.locationId
end

------------------
-- AStar
------------------
function AStar:ctor()
end

function AStar:Init(mapHandler) 
	self.mapHandler = mapHandler
	return self;
end

function AStar:_getBestOpenNode()
	local bestNode = nil
  
	for locationId, n in pairs(self.open) do
		if bestNode == nil then
			bestNode = n
		else
			if n.score <= bestNode.score then
				bestNode = n
			end
		end
	end
  
	return bestNode
end

function AStar:_tracePath(n)
	local nodes = {}
	local totalCost = n.mCost
	local p = n.parent
  
	table.insert(nodes, 1, n)
  
	while true do
		if p.parent == nil then
			break
		end
		table.insert(nodes, 1, p)
		p = p.parent
	end
  
	return Path:new():Init(nodes, totalCost)
end

function AStar:_handleNode(node, goal)
	self.open[node.locationId] = nil
	self.closed[node.locationId] = true
  
	assert(node.location ~= nil, 'About to pass a node with nil location to getAdjacentNodes')
  
	local nodes = self.mapHandler:getAdjacentNodes(node, goal, self.open, self.closed)

	for _, n in ipairs(nodes) do 
		if self.mapHandler:locationsAreEqual(n.location, goal) then
			return n
		elseif self.closed[n.locationId] then 
			-- Alread in close, skip this
		elseif self.open[n.locationId] ~= nil then 
			-- Already in open, check if better score   
			local on = self.open[n.locationId]
    
			if n.mCost < on.mCost then
				self.open[n.locationId] = n
			end
		else 
			-- New node, append to open list
			self.open[n.locationId] = n
		end
	end
  
	return nil
end

-- @param maxIterations: default to 1000. 
-- @return PathObject, iterationCount: return nil if no path is found. 
function AStar:findPath(fromLocation, toLocation, maxIterations)
	self.open = {}
	self.closed = {}

	maxIterations = maxIterations or 1000;

	local firstNode = self.mapHandler:getNode(fromLocation)

	local nextNode = nil

	if firstNode ~= nil then
		self.open[firstNode.locationId] = firstNode
		nextNode = firstNode
	end  
	local iterCount = 0;
	while nextNode ~= nil and iterCount < maxIterations do
		local finish = self:_handleNode(nextNode, toLocation)
    
		if finish then
			return self:_tracePath(finish), iterCount
		end
		nextNode = self:_getBestOpenNode()
		iterCount = iterCount + 1;
	end
  
	return nil, iterCount;
end