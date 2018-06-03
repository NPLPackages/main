--[[
Title: a implementation as the "PODIntervalTree" of webkit in NPL
Author(s): LiPeng
Date: 2018.5.23
Desc:	simulate the implementation of the class "PODIntervalTree" in webkit;
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/STL/PODIntervalTree.lua");
local PODIntervalTree = commonlib.PODIntervalTree;

-------------------------------------------------------
]]
NPL.load("(gl)script/ide/STL/ListHashSet.lua");
local ListHashSet = commonlib.ListHashSet;

local PODInterval = commonlib.gettable("commonlib.PODInterval");
PODInterval.__index = PODInterval;

function PODInterval:new(o)
    o = o or {}
	self.low, self.high, self.data, self.maxHight = nil, nil, nil, nil;
	setmetatable(o, self);
	return o;
end

function PODInterval:init(low, high, data)
	self.low = low;
	self.high = high;
	self.data = data;
	self.maxHight = high;

	return self;
end

function PODInterval:Low()
	return self.low;
end

function PODInterval:High()
	return self.high;
end

function PODInterval:Data()
	return self.data;
end

function PODInterval:MaxHigh()
	return self.maxHigh;
end

function PODInterval:SetMaxHigh(maxHigh)
	self.maxHigh = maxHigh;
end

--bool overlaps(const T& low, const T& high) const
--bool overlaps(const PODInterval& other) const
function PODInterval:Overlaps(low, high)
	if(high == nil) then
		local other = low; -- other is PODInterval;
		low = other:Low();
		high = other:High();
	end
    if (self.high < low) then
        return false;
	end
    if (high < self.low) then
        return false;
	end
    return true;
end

function PODInterval.__eq(a,b)
	return a:Low() == b:Low() and a:High() == b:High() and a:Data() == b:Data();
end



local PODIntervalTree = ListHashSet:new();

commonlib.PODIntervalTree = PODIntervalTree

PODIntervalTree.__index = PODIntervalTree;
PODIntervalTree._super = ListHashSet;

function PODIntervalTree:new(o)
    o = o or {};
	setmetatable(o, self);
	return o;
end

function PODIntervalTree:addToSet(key, value)
	key = key.data;
	self.set[key] = value;
end

function PODIntervalTree:removeFromSet(key)
	key = key.data;
	self.set[key] = nil;
end

function PODIntervalTree:find(fun, ...)
	if(type(fun) ~= "function") then
		fun = fun.data;
	end
	return PODIntervalTree._super.find(self, fun, ...);
end

--void allOverlapsWithAdapter(AdapterType& adapter)
function PODIntervalTree:allOverlapsWithAdapter(adapter)
	if(self:isEmpty()) then
		return;
	end
	for k, v in pairs(self.set) do
		--self:remove(k);
		local item = v();
		adapter:CollectIfNeeded(item);
	end
end