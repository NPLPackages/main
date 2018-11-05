--[[
Title: a implementation as the "PODRedBlackTree" of webkit in NPL
Author(s): LiPeng
Date: 2018.5.23
Desc:	simulate the implementation of the class "PODRedBlackTree" in webkit;
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/PODRedBlackTree.lua");
local PODRedBlackTree = commonlib.gettable("System.Windows.mcml.platform.PODRedBlackTree");

-------------------------------------------------------
]]

local Color ={
    ["Red"] = 1,
    ["Black"] = 2,
};

local Node = commonlib.gettable("System.Windows.mcml.platform.PODRedBlackTree.Node");
Node.__index = Node;

function Node:new(o)
    o = o or {}
	o.m_left, o.m_right, o.m_parent, o.m_color, o.m_data = nil, nil, nil, Color.Red, nil;
	setmetatable(o, self);
	return o;
end

function Node:init(data)
	self.m_data = data;
	return self;
end

function Node:color()
	return self.m_color;
end

function Node:setColor(color)
	self.m_color = color;
end

function Node:data()
	return self.m_data;
end

function Node:copyFrom(src)
	self.m_data = src:data();
end

function Node:left()
	return self.m_left;
end

function Node:setLeft(node)
	self.m_left = node;
end

function Node:right()
	return self.m_right;
end

function Node:setRight(node)
	self.m_right = node;
end

function Node:parent()
	return self.m_parent;
end

function Node:setParent(node)
	self.m_parent = node;
end

function Node:PrintInfo()
	if(self:left()) then
		echo("left not nil")
	else
		echo("left nil")
	end

	if(self:right()) then
		echo("right not nil")
	else
		echo("right nil")
	end
end


local Visitor = {};
Visitor.__index = Visitor;

function Visitor:new(o)
    o = o or {}
	setmetatable(o, self);
	return o;
end
-- virtual function
function Visitor:visit(node)
	
end

local Counter = Visitor:new();
Counter.__index = Counter;
Counter._super = Visitor;

function Counter:new(o)
    o = o or {}
	o.m_count = 0;
	setmetatable(o, self);
	return o;
end

function Counter:visit(node)
	self.m_count = self.m_count + 1;
end

function Counter:count()
	return self.m_count;
end



local PODRedBlackTree = commonlib.gettable("System.Windows.mcml.platform.PODRedBlackTree");
PODRedBlackTree.__index = PODRedBlackTree;

function PODRedBlackTree:new(o)
    o = o or {}
	o.m_root = nil;
	o.m_needsFullOrderingComparisons = false;
	o.m_isInitialized = false;
	setmetatable(o, self);
	return o;
end

function PODRedBlackTree:clear()
	self.m_root = nil;
	self.m_isInitialized = false;
end

function PODRedBlackTree:isInitialized()
	return self.m_isInitialized;
end

function PODRedBlackTree:initIfNeeded()
    if (not self.m_isInitialized) then
        self.m_isInitialized = true;
	end
end

function PODRedBlackTree:add(data)
    --ASSERT(isInitialized());
    local node = Node:new():init(data);
    self:insertNode(node);
end

function PODRedBlackTree:remove(data)
	local node = self:treeSearch(data);
    if (node) then
        self:deleteNode(node);
        return true;
    end
    return false;
end

function PODRedBlackTree:contains(data)
    --ASSERT(isInitialized());
    return self:treeSearch(data);
end

function PODRedBlackTree:visitInorder(visitor)
    --ASSERT(isInitialized());
    if (not self.m_root) then
        return;
	end
    self:visitInorderImpl(self.m_root, visitor);
end

function PODRedBlackTree:setNeedsFullOrderingComparisons(needsFullOrderingComparisons)
    self.m_needsFullOrderingComparisons = needsFullOrderingComparisons;
end

function PODRedBlackTree:size()
    --ASSERT(isInitialized());
    local counter = Counter:new();
    self:visitInorder(counter);
    return counter:count();
end

function PODRedBlackTree:root()
	return self.m_root;
end

-- Searches the tree for the given datum.
function PODRedBlackTree:treeSearch(data)
    if (self.m_needsFullOrderingComparisons) then
        return self:treeSearchFullComparisons(self.m_root, data);
	end
    return self:treeSearchNormal(self.m_root, data);
end

-- Searches the tree using the normal comparison operations,
-- suitable for simple data types such as numbers.
--Node* treeSearchNormal(Node* current, const T& data) const
function PODRedBlackTree:treeSearchNormal(current, data)
	while (current) do
		if (current:data() == data) then
			return current;
		end
		if (data < current:data()) then
			current = current:left();
		else
			current = current:right();
		end
	end
	return nil;
end

-- Searches the tree using multiple comparison operations, required
-- for data types with more complex behavior such as intervals.
--Node* treeSearchFullComparisons(Node* current, const T& data) const
function PODRedBlackTree:treeSearchFullComparisons(current, data)
	if (not current) then
		return nil;
	end
	if (data < current:data()) then
		return self:treeSearchFullComparisons(current:left(), data);
	end
	if (current:data() < data) then
		return self:treeSearchFullComparisons(current:right(), data);
	end
	if (data == current:data()) then
		return current;
	end
	-- We may need to traverse both the left and right subtrees.
	local result = self:treeSearchFullComparisons(current:left(), data);
	if (not result) then
		result = self:treeSearchFullComparisons(current:right(), data);
	end
	return result;
end

--void insertNode(Node* x)
function PODRedBlackTree:insertNode(x)
	self:treeInsert(x);
	x:setColor(Color.Red);
	self:updateNode(x);

	--logIfVerbose("  PODColor.RedColor.BlackTree::InsertNode");

	-- The node from which to start propagating updates upwards.
	local updateStart = x:parent();

	while (x ~= self.m_root and x:parent():color() == Color.Red) do
		if (x:parent() == x:parent():parent():left()) then
			local y = x:parent():parent():right();
			if (y and y:color() == Color.Red) then
				-- Case 1
				--logIfVerbose("  Case 1/1");
				x:parent():setColor(Color.Black);
				y:setColor(Color.Black);
				x:parent():parent():setColor(Color.Red);
				self:updateNode(x:parent());
				x = x:parent():parent();
				self:updateNode(x);
				updateStart = x:parent();
			else
				if (x == x:parent():right()) then
					--logIfVerbose("  Case 1/2");
					-- Case 2
					x = x:parent();
					self:leftRotate(x);
				end
				-- Case 3
				--logIfVerbose("  Case 1/3");
				x:parent():setColor(Color.Black);
				x:parent():parent():setColor(Color.Red);
				local newSubTreeRoot = self:rightRotate(x:parent():parent());
				updateStart = newSubTreeRoot:parent();
			end
		else
			-- Same as "then" clause with "right" and "left" exchanged.
			local y = x:parent():parent():left();
			if (y and y:color() == Color.Red) then
				-- Case 1
				--logIfVerbose("  Case 2/1");
				x:parent():setColor(Color.Black);
				y:setColor(Color.Black);
				x:parent():parent():setColor(Color.Red);
				self:updateNode(x:parent());
				x = x:parent():parent();
				self:updateNode(x);
				updateStart = x:parent();
			else
				if (x == x:parent():left()) then
					-- Case 2
					--logIfVerbose("  Case 2/2");
					x = x:parent();
					self:rightRotate(x);
				end
				-- Case 3
				--logIfVerbose("  Case 2/3");
				x:parent():setColor(Color.Black);
				x:parent():parent():setColor(Color.Red);
				local newSubTreeRoot = self:leftRotate(x:parent():parent());
				updateStart = newSubTreeRoot:parent();
			end
		end
	end

	self:propagateUpdates(updateStart);

	self.m_root:setColor(Color.Black);
end

--void treeInsert(Node* z)
function PODRedBlackTree:treeInsert(z)
    local y = nil;
    local x = self.m_root;
    while (x) do
        y = x;
        if (z:data() < x:data()) then
            x = x:left();
        else
            x = x:right();
		end
    end
    z:setParent(y);
    if (y == nil) then
        self.m_root = z;
    else
        if (z:data() < y:data()) then
            y:setLeft(z);
        else
            y:setRight(z);
		end
    end
end

function PODRedBlackTree:updateNode(node)
	return false;
end

-- Left-rotates the subtree rooted at x.
-- Returns the new root of the subtree (x's right child).
--Node* leftRotate(Node* x)
function PODRedBlackTree:leftRotate(x)
	-- Set y.
	local y = x:right();

	-- Turn y's left subtree into x's right subtree.
	x:setRight(y:left());
	if (y:left()) then
		y:left():setParent(x);
	end

	-- Link x's parent to y.
	y:setParent(x:parent());
	if (not x:parent()) then
		self.m_root = y;
	else
		if (x == x:parent():left()) then
			x:parent():setLeft(y);
		else
			x:parent():setRight(y);
		end
	end

	-- Put x on y's left.
	y:setLeft(x);
	x:setParent(y);

	-- Update nodes lowest to highest.
	self:updateNode(x);
	self:updateNode(y);
	return y;
end

-- Right-rotates the subtree rooted at y.
-- Returns the new root of the subtree (y's left child).
--Node* rightRotate(Node* y)
function PODRedBlackTree:rightRotate(y)
	-- Set x.
	local x = y:left();

	-- Turn x's right subtree into y's left subtree.
	y:setLeft(x:right());
	if (x:right()) then
		x:right():setParent(y);
	end

	-- Link y's parent to x.
	x:setParent(y:parent());
	if (not y:parent()) then
		self.m_root = x;
	else
		if (y == y:parent():left()) then
			y:parent():setLeft(x);
		else
			y:parent():setRight(x);
		end
	end

	-- Put y on x's right.
	x:setRight(y);
	y:setParent(x);

	-- Update nodes lowest to highest.
	self:updateNode(y);
	self:updateNode(x);
	return x;
end

-- Helper for maintaining the augmented red-black tree.
--void propagateUpdates(Node* start)
function PODRedBlackTree:propagateUpdates(start)
    local shouldContinue = true;
    while (start ~= nil and shouldContinue) do
        shouldContinue = self:updateNode(start);
        start = start:parent();
	end
end

-- Finds the node following the given one in sequential ordering of
-- their data, or null if none exists.
--Node* treeSuccessor(Node* x)
function PODRedBlackTree:treeSuccessor(x)
    if (x:right()) then
        return self:treeMinimum(x:right());
	end
    local y = x:parent();
    while (y and x == y:right()) do
        x = y;
        y = y:parent();
    end
    return y;
end

-- Finds the minimum element in the sub-tree rooted at the given
-- node.
--Node* treeMinimum(Node* x)
function PODRedBlackTree:treeMinimum(x)
    while (x:left()) do
        x = x:left();
	end
    return x;
end

-- Restores the red-black property to the tree after splicing out
-- a node. Note that x may be null, which is why xParent must be
-- supplied.
--void deleteFixup(Node* x, Node* xParent)
function PODRedBlackTree:deleteFixup(x, xParent)
	while (x ~= self.m_root and (not x or x:color() == Color.Black)) do
		if (x == xParent:left()) then
			-- Note: the text points out that w can not be null.
			-- The reason is not obvious from simply looking at
			-- the code; it comes about from the properties of the
			-- red-black tree.
			local w = xParent:right();
			--ASSERT(w); -- x's sibling should not be null.
			if (w:color() == Color.Red) then
				-- Case 1
				w:setColor(Color.Black);
				xParent:setColor(Color.Red);
				self:leftRotate(xParent);
				w = xParent:right();
			end
			if ((not w:left() or w:left():color() == Color.Black)
				and (not w:right() or w:right():color() == Color.Black)) then
				-- Case 2
				w:setColor(Color.Red);
				x = xParent;
				xParent = x:parent();
			else
				if (not w:right() or w:right():color() == Color.Black) then
					-- Case 3
					w:left():setColor(Color.Black);
					w:setColor(Color.Red);
					self:rightRotate(w);
					w = xParent:right();
				end
				-- Case 4
				w:setColor(xParent:color());
				xParent:setColor(Color.Black);
				if (w:right()) then
					w:right():setColor(Color.Black);
				end
				self:leftRotate(xParent);
				x = self.m_root;
				xParent = x:parent();
			end
		else
			-- Same as "then" clause with "right" and "left"
			-- exchanged.

			-- Note: the text points out that w can not be null.
			-- The reason is not obvious from simply looking at
			-- the code; it comes about from the properties of the
			-- red-black tree.
			local w = xParent:left();
			--ASSERT(w); -- x's sibling should not be null.
			if (w:color() == Color.Red) then
				-- Case 1
				w:setColor(Color.Black);
				xParent:setColor(Color.Red);
				self:rightRotate(xParent);
				w = xParent:left();
			end
			if ((not w:right() or w:right():color() == Color.Black)
				and (not w:left() or w:left():color() == Color.Black)) then
				-- Case 2
				w:setColor(Color.Red);
				x = xParent;
				xParent = x:parent();
			else
				if (not w:left() or w:left():color() == Color.Black) then
					-- Case 3
					w:right():setColor(Color.Black);
					w:setColor(Color.Red);
					self:leftRotate(w);
					w = xParent:left();
				end
				-- Case 4
				w:setColor(xParent:color());
				xParent:setColor(Color.Black);
				if (w:left()) then
					w:left():setColor(Color.Black);
				end
				self:rightRotate(xParent);
				x = self.m_root;
				xParent = x:parent();
			end
		end
	end
	if (x) then
		x:setColor(Color.Black);
	end
end

-- Deletes the given node from the tree. Note that this
-- particular node may not actually be removed from the tree;
-- instead, another node might be removed and its contents
-- copied into z.
--void deleteNode(Node* z)
function PODRedBlackTree:deleteNode(z)
	-- Y is the node to be unlinked from the tree.
	local y = nil;
	if (not z:left() or not z:right()) then
		y = z;
	else
		y = self:treeSuccessor(z);
	end

	-- Y is guaranteed to be non-null at this point.
	local x = nil;
	if (y:left()) then
		x = y:left();
	else
		x = y:right();
	end

	-- X is the child of y which might potentially replace y in
	-- the tree. X might be null at this point.
	local xParent = nil;
	if (x) then
		x:setParent(y:parent());
		xParent = x:parent();
	else
		xParent = y:parent();
	end
	if (not y:parent()) then
		self.m_root = x;
	else
		if (y == y:parent():left()) then
			y:parent():setLeft(x);
		else
			y:parent():setRight(x);
		end
	end
	if (y ~= z) then
		z:copyFrom(y);
		-- This node has changed location in the tree and must be updated.
		self:updateNode(z);
		-- The parent and its parents may now be out of date.
		self:propagateUpdates(z:parent());
	end

	-- If we haven't already updated starting from xParent, do so now.
	if (xParent and xParent ~= y and xParent ~= z) then
		self:propagateUpdates(xParent);
	end
	if (y:color() == Color.Black) then
		self:deleteFixup(x, xParent);
	end
end

-- Visits the subtree rooted at the given node in order.
--void visitInorderImpl(Node* node, Visitor* visitor) const
function PODRedBlackTree:visitInorderImpl(node, visitor)
	if (node:left()) then
		self:visitInorderImpl(node:left(), visitor);
	end
	visitor:visit(node:data());
	if (node:right()) then
		self:visitInorderImpl(node:right(), visitor);
	end
end

--virtual bool checkInvariants() const
function PODRedBlackTree:checkInvariants()
	--ASSERT(isInitialized());
	local blackCount = 0;
	local b, blackCount = self:checkInvariantsFromNode(self.m_root, blackCount);
	return b;
end

-- Returns in the "blackCount" parameter the number of black
-- children along all paths to all leaves of the given node.
--bool checkInvariantsFromNode(Node* node, int* blackCount) const
function PODRedBlackTree:checkInvariantsFromNode(node, blackCount)
	-- Base case is a leaf node.
	if (not node) then
		blackCount = 1;
		return true, blackCount;
	end

	-- Each node is either red or black.
	if (not (node:color() == Color.Red or node:color() == Color.Black)) then
		return false, blackCount;
	end
	-- Every leaf (or null) is black.

	if (node:color() == Color.Red) then
		-- Both of its children are black.
		if (not ((not node:left() or node:left():color() == Color.Black))) then
			return false, blackCount;
		end
		if (not ((not node:right() or node:right():color() == Color.Black))) then
			return false, blackCount;
		end
	end

	-- Every simple path to a leaf node contains the same number of
	-- black nodes.
	local leftCount, rightCount = 0, 0;
	local leftValid, leftCount = self:checkInvariantsFromNode(node:left(), leftCount);
	local rightValid, rightCount = self:checkInvariantsFromNode(node:right(), rightCount);
	if (not leftValid or not rightValid) then
		return false, blackCount;
	end
	blackCount = leftCount + if_else(node:color() == Color.Black, 1, 0);
	return leftCount == rightCount, blackCount;
end