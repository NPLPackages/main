--[[
Title: a implementation as the "PODIntervalTree" of webkit in NPL
Author(s): LiPeng
Date: 2018.5.23
Desc:	simulate the implementation of the class "PODIntervalTree" in webkit;
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/PODIntervalTree.lua");
local PODIntervalTree = commonlib.gettable("System.Windows.mcml.platform.PODIntervalTree");

-------------------------------------------------------
]]

local PODIntervalSearchAdapter = {};
PODIntervalSearchAdapter.__index = PODIntervalSearchAdapter;

function PODIntervalSearchAdapter:new(o)
    o = o or {};
	o.m_result = nil;
	o.m_lowValue, o.m_highValue = nil, nil;
	setmetatable(o, self);
	return o;
end

function PODIntervalSearchAdapter:init(result, lowValue, highValue)
	--Vector<IntervalType>& m_result;
	self.m_result = result;
	self.m_lowValue = lowValue;
	self.m_highValue = highValue;
	return self;
end

function PODIntervalSearchAdapter:lowValue()
	return self.m_lowValue;
end

function PODIntervalSearchAdapter:highValue()
	return self.m_highValue;
end

--void collectIfNeeded(const IntervalType& data) const
function PODIntervalSearchAdapter:collectIfNeeded(data)
    if (data:overlaps(self.m_lowValue, self.m_highValue)) then
        self.m_result:append(data);
	end
end


local IntervalSearchAdapterType = PODIntervalSearchAdapter;

NPL.load("(gl)script/ide/System/Windows/mcml/platform/PODRedBlackTree.lua");
local PODRedBlackTree = commonlib.gettable("System.Windows.mcml.platform.PODRedBlackTree");
local platform = commonlib.gettable("System.Windows.mcml.platform");

local PODIntervalTree = PODRedBlackTree:new();
platform.PODIntervalTree = PODIntervalTree;

PODIntervalTree.__index = PODIntervalTree;
PODIntervalTree._super = PODRedBlackTree;

function PODIntervalTree:new(o)
    o = o or {};
	setmetatable(o, self);
	return o;
end

function PODIntervalTree:init()
	self:setNeedsFullOrderingComparisons(true);
	return self;
end

-- Returns all intervals in the tree which overlap the given query
-- interval. The returned intervals are sorted by increasing low
-- endpoint.
--Vector<IntervalType> allOverlaps(const IntervalType& interval) const
function PODIntervalTree:allOverlaps(interval)
	--Vector<IntervalType> result;
	local result = commonlib.vector:new();
	self:allOverlaps(interval, result);
	return result;
end

-- Returns all intervals in the tree which overlap the given query
-- interval. The returned intervals are sorted by increasing low
-- endpoint.
--void allOverlaps(const IntervalType& interval, Vector<IntervalType>& result) const
function PODIntervalTree:allOverlaps(interval, result)
	-- Explicit dereference of "this" required because of
	-- inheritance rules in template classes.
	local adapter = IntervalSearchAdapterType:new():init(result, interval:low(), interval:high());
	self:searchForOverlapsFrom(self:root(), adapter);
end

--template <class AdapterType>
--void allOverlapsWithAdapter(AdapterType& adapter) const
function PODIntervalTree:allOverlapsWithAdapter(adapter)
	-- Explicit dereference of "this" required because of
	-- inheritance rules in template classes.
	self:searchForOverlapsFrom(self:root(), adapter);
end

--virtual bool checkInvariants() const
function PODIntervalTree:checkInvariants()
	if (not PODIntervalTree._super.checkInvariants(self)) then
		return false;
	end
	if (not self:root()) then
		return true;
	end
	local b, _ = self:checkInvariantsFromNode(self:root());
	return b;
end


local IntervalNode = PODRedBlackTree.Node;


-- Starting from the given node, adds all overlaps with the given
-- interval to the result vector. The intervals are sorted by
-- increasing low endpoint.
--template <class AdapterType>
--void searchForOverlapsFrom(IntervalNode* node, AdapterType& adapter) const
function PODIntervalTree:searchForOverlapsFrom(node, adapter)
	if (not node) then
		return;
	end
	-- Because the intervals are sorted by left endpoint, inorder
	-- traversal produces results sorted as desired.

	-- See whether we need to traverse the left subtree.
	local left = node:left();
	-- This is phrased this way to avoid the need for operator
	-- <= on type T.
	if (left and not (left:data():maxHigh() < adapter:lowValue())) then
		self:searchForOverlapsFrom(left, adapter);
	end
	-- Check for overlap with current node.
	adapter:collectIfNeeded(node:data());

	-- See whether we need to traverse the right subtree.
	-- This is phrased this way to avoid the need for operator <=
	-- on type T.
	if (not (adapter:highValue() < node:data():low())) then
		self:searchForOverlapsFrom(node:right(), adapter);
	end
end

--virtual bool updateNode(IntervalNode* node)
function PODIntervalTree:updateNode(node)
	-- Would use const T&, but need to reassign this reference in this
	-- function.
	--const T* curMax = &node:data().high();
	local curMax = node:data():high();
	local left = node:left();
	if (left) then
		if (curMax < left:data():maxHigh()) then
			curMax = left:data():maxHigh();
		end
	end
	local right = node:right();
	if (right) then
		if (curMax < right:data():maxHigh()) then
			curMax = right:data():maxHigh();
		end
	end
	-- This is phrased like this to avoid needing operator~= on type T.
	if (not (curMax == node:data():maxHigh())) then
		node:data():setMaxHigh(curMax);
		return true;
	end
	return false;
end

--bool checkInvariantsFromNode(IntervalNode* node, T* currentMaxValue) const
function PODIntervalTree:checkInvariantsFromNode(node, currentMaxValue)
	-- These assignments are only done in order to avoid requiring
	-- a default constructor on type T.
	local leftMaxValue = node:data():maxHigh();
	local rightMaxValue = node:data():maxHigh();
	local left = node:left();
	local right = node:right();
	if (left) then
		local b, leftMaxValue = self:checkInvariantsFromNode(left, leftMaxValue);
		if (not b) then
			return false, currentMaxValue;
		end
	end
	if (right) then
		local b, rightMaxValue = self:checkInvariantsFromNode(right, rightMaxValue);
		if (not b) then
			return false, currentMaxValue;
		end
	end
	if (not left and not right) then
		-- Base case.
		if (currentMaxValue) then
			currentMaxValue = node:data():high();
		end
		return (node:data():high() == node:data():maxHigh()), currentMaxValue;
	end
	local localMaxValue = node:data():maxHigh();
	if (not left or not right) then
		if (left) then
			localMaxValue = leftMaxValue;
		else
			localMaxValue = rightMaxValue;
		end
	else
		localMaxValue = if_else(leftMaxValue < rightMaxValue, rightMaxValue, leftMaxValue);
	end
	if (localMaxValue < node:data():high()) then
		localMaxValue = node:data():high();
	end
	if (not (localMaxValue == node:data():maxHigh())) then 
		return false, currentMaxValue;
	end
	if (currentMaxValue) then
		currentMaxValue = localMaxValue;
	end
	return true, currentMaxValue;
end