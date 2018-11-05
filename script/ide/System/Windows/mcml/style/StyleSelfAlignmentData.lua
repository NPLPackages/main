--[[
Title: 
Author(s): LiPeng
Date: 2018/6/6
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/style/StyleSelfAlignmentData.lua");
local StyleSelfAlignmentData = commonlib.gettable("System.Windows.mcml.style.StyleSelfAlignmentData");
------------------------------------------------------------
]]


NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");

local StyleSelfAlignmentData = commonlib.gettable("System.Windows.mcml.style.StyleSelfAlignmentData");
StyleSelfAlignmentData.__index = StyleSelfAlignmentData;

local memberAndInitialValues = 
{
	["m_position"] = 0,
	["m_positionType"] = 0,
	["m_overflow"] = 0,
};

local class_members = {
	
};

-- StyleSelfAlignmentData(ItemPosition position, OverflowAlignment overflow, ItemPositionType positionType = NonLegacyPosition)
function StyleSelfAlignmentData:new(position, overflow, positionType)
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
		self.m_positionType = positionType or ComputedStyleConstants.ItemPositionTypeEnum.NonLegacyPosition;
		self.m_overflow = overflow;
	end
	setmetatable(o, self);
	return o;
end

function StyleSelfAlignmentData:SetPosition(position) self.m_position = position; end
function StyleSelfAlignmentData:SetPositionType(positionType) self.m_positionType = positionType; end
function StyleSelfAlignmentData:SetOverflow(overflow) self.m_overflow = overflow; end

function StyleSelfAlignmentData:Position()  return self.m_position; end
function StyleSelfAlignmentData:PositionType()  return self.m_positionType; end
function StyleSelfAlignmentData:Overflow()  return self.m_overflow; end

function StyleSelfAlignmentData:clone()
	return StyleSelfAlignmentData:new(self);
end

function StyleSelfAlignmentData.__eq(a, b)
	for k in pairs(memberAndInitialValues) do
		if(a[k] ~= b[k]) then
			return false;
		end
	end
	return true;
end