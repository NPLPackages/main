--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleContentAlignmentData.lua");
local StyleContentAlignmentData = commonlib.gettable("System.Windows.mcml.style.StyleContentAlignmentData");
------------------------------------------------------------
]]


NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");

local StyleContentAlignmentData = commonlib.gettable("System.Windows.mcml.style.StyleContentAlignmentData");
StyleContentAlignmentData.__index = StyleContentAlignmentData;

local memberAndInitialValues = 
{
	["m_position"] = 0,
	["m_distribution"] = 0,
	["m_overflow"] = 0,
};

local class_members = {
	
};

-- StyleContentAlignmentData(ContentPosition position, ContentDistributionType distribution, OverflowAlignment overflow = OverflowAlignmentDefault)
function StyleContentAlignmentData:new(position, distribution, overflow)
	local o = {};
	if(type(position) == "table") then
		for k, v in pairs(memberAndInitialValues) do
			if(other) then
				v = other[k];
			end
			if(class_members[k]) then
				v = v:clone();
			end
			o[k] = v;
		end
	else
		self.m_position = position;
		self.m_distribution = distribution;
		self.m_overflow = overflow or ComputedStyleConstants.OverflowAlignmentEnum.OverflowAlignmentDefault;
	end
	setmetatable(o, self);
	return o;
end

function StyleContentAlignmentData:SetPosition(position) self.m_position = position; end
function StyleContentAlignmentData:SetDistribution(distribution) self.m_distribution = distribution; end
function StyleContentAlignmentData:SetOverflow(overflow) self.m_overflow = overflow; end

function StyleContentAlignmentData:Position()  return self.m_position; end
function StyleContentAlignmentData:Distribution()  return self.m_distribution; end
function StyleContentAlignmentData:Overflow()  return self.m_overflow; end

function StyleContentAlignmentData:clone()
	return StyleContentAlignmentData:new(self);
end

function StyleContentAlignmentData.__eq(a, b)
	for k in pairs(memberAndInitialValues) do
		if(a[k] ~= b[k]) then
			return false;
		end
	end
	return true;
end