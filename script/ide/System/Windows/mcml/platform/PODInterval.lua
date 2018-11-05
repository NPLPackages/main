--[[
Title: a implementation as the "PODInterval" of webkit in NPL
Author(s): LiPeng
Date: 2018.5.23
Desc:	simulate the implementation of the class "PODInterval" in webkit;
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/PODInterval.lua");
local PODInterval = commonlib.gettable("System.Windows.mcml.platform.PODInterval");

-------------------------------------------------------
]]
local PODInterval = commonlib.gettable("System.Windows.mcml.platform.PODInterval");
PODInterval.__index = PODInterval;

function PODInterval:new(o)
    o = o or {}
	o.m_low, o.m_high, o.m_data, o.m_maxHight = nil, nil, nil, nil;
	setmetatable(o, self);
	return o;
end

function PODInterval:init(low, high, data)
	self.m_low = low;
	self.m_high = high;
	self.m_data = data;
	self.m_maxHight = high;

	return self;
end

function PODInterval:low()
	return self.m_low;
end

function PODInterval:high()
	return self.m_high;
end

function PODInterval:data()
	return self.m_data;
end

function PODInterval:maxHigh()
	return self.m_maxHigh;
end

function PODInterval:setMaxHigh(maxHigh)
	self.m_maxHigh = maxHigh;
end

--bool overlaps(const T& low, const T& high) const
--bool overlaps(const PODInterval& other) const
function PODInterval:overlaps(low, high)
	if(high == nil) then
		local other = low;
		return self:overlaps(other:low(), other:high());
	end
    if (self.m_high < low) then
        return false;
	end
    if (high < self.m_low) then
        return false;
	end
    return true;
end

function PODInterval.__eq(a,b)
	return a:low() == b:low() and a:high() == b:high() and a:data() == b:data();
end

function PODInterval.__lt(a,b)
	return a:low() < b:low();
end
