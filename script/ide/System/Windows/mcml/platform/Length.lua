--[[
Title: 
Author(s): LiPeng
Date: 2018/2/8
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
local Length = commonlib.gettable("System.Windows.mcml.platform.Length");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Util/EnumCreater.lua");
local EnumCreater = commonlib.gettable("System.Util.EnumCreater");

local Length = commonlib.gettable("System.Windows.mcml.platform.Length");
Length.__index = Length;

local type = type;
local string_match = string.match;

local intMaxForLength = 0x7ffffff; -- max value for a 28-bit int
local intMinForLength = (-0x7ffffff - 1); -- min value for a 28-bit int

local LengthTypeEnum = EnumCreater.Transform({"Auto", "Relative", "Percent", "Fixed", "Intrinsic", "MinIntrinsic", "Undefined"});
Length.LengthTypeEnum = LengthTypeEnum;

-- create a new length
-- Length(int v, LengthType t, bool q = false)
-- Length(LengthType t)
-- Length()
function Length:new(value, type, quirk)
	if(value ~= nil and type == nil) then
		type = value;
		value =  0;
	end

	local o = {};
	o.value = value or 0;
	o.type = type or LengthTypeEnum.Auto;
	o.quirk = if_else(quirk == nil, false, quirk);
    o.isFloat = nil;
	setmetatable(o, self);
	return o;
end

function Length:clone()
	local o = Length:new(self.value, self.type, self.quirk);
	return o;
end

function Length:Value()
	return self.value;
end

function Length:Percent()
	return self.value;
end

function Length:Type()
	return self.type;
end

function Length:Quirk()
	return self.quirk;
end

function Length:SetQuirk(quirk)
    self.quirk = quirk;
end

function Length:SetValue(type, value)
	if(not value) then
		self:SetValue(LengthTypeEnum.Fixed, type);
		return;
	end
	self.type = type;
	self.value = value;
end

-- Note: May only be called for Fixed, Percent and Auto lengths.
-- Other types will ASSERT in order to catch invalid length calculations.
--int calcValue(int maxValue, bool roundPercentages = false) const
function Length:CalcValue(maxValue, roundPercentages)
	roundPercentages = if_else(roundPercentages == nil, false, roundPercentages);
	local type = self.type;
	if(type == LengthTypeEnum.Fixed or type == LengthTypeEnum.Percent) then
		return self:CalcMinValue(maxValue, roundPercentages);
	elseif(type == LengthTypeEnum.Auto) then
		return maxValue;
	elseif(type == LengthTypeEnum.Relative or type == LengthTypeEnum.Intrinsic or type == LengthTypeEnum.MinIntrinsic or type == LengthTypeEnum.Undefined) then
		return 0;
	end
	return 0;
end

--int calcMinValue(int maxValue, bool roundPercentages = false) const
function Length:CalcMinValue(maxValue, roundPercentages)
	roundPercentages = if_else(roundPercentages == nil, false, roundPercentages);
	local type = self.type;
	if(type == LengthTypeEnum.Fixed) then
		return self:Value();
	elseif(type == LengthTypeEnum.Percent) then
		local value = maxValue * self:Percent() / 100;
		if (roundPercentages) then
			value = math.floor(value + 0.5);
		end
		return value;
	elseif(type == LengthTypeEnum.Auto) then
		return 0;
	elseif(type == LengthTypeEnum.Relative or type == LengthTypeEnum.Intrinsic or type == LengthTypeEnum.MinIntrinsic or type == LengthTypeEnum.Undefined) then
		return 0;
	end
	return 0;
end

--float calcFloatValue(int maxValue) const
function Length:CalcFloatValue(maxValue)
	local type = self.type;
	if(type == LengthTypeEnum.Fixed) then
		return self:Value();
	elseif(type == LengthTypeEnum.Percent) then
		local value = maxValue * self:Percent() / 100;
		return value;
	elseif(type == LengthTypeEnum.Auto) then
		return maxValue;
	elseif(type == LengthTypeEnum.Relative or type == LengthTypeEnum.Intrinsic or type == LengthTypeEnum.MinIntrinsic or type == LengthTypeEnum.Undefined) then
		return 0;
	end
	return 0;
end

function Length.__eq(a,b)
	-- return (m_type == o.m_type) && (m_quirk == o.m_quirk) && (isUndefined() || (getFloatValue() == o.getFloatValue()));
	return a.type == b.type and a.quirk == b.quirk and a.value == b.value;
end

function Length:IsUndefined()
	return self.type == LengthTypeEnum.Undefined;
end

function Length:IsZero()
	return self.value == 0;
end

function Length:IsPositive()
	if(self:IsUndefined()) then
		return false;
	end
	return self.value > 0;
end

function Length:IsNegative()
	if(self:IsUndefined()) then
		return false;
	end
	return self.value < 0;
end

function Length:IsAuto()
	return self.type == LengthTypeEnum.Auto;
end

function Length:IsRelative()
	return self.type == LengthTypeEnum.Relative;
end

function Length:IsPercent()
	return self.type == LengthTypeEnum.Percent;
end

function Length:IsFixed()
	return self.type == LengthTypeEnum.Fixed;
end

function Length:IsIntrinsicOrAuto()
	return self.type == LengthTypeEnum.Auto or self.type == LengthTypeEnum.MinIntrinsic or self.type == LengthTypeEnum.Intrinsic;
end

function Length:IsSpecified()
	return self.type == LengthTypeEnum.Fixed or self.type == LengthTypeEnum.Percent;
end

function Length.CreateFromCssLength(length_str)
	local value, isPercent = string.match(length_str, "([%+%-]?%d+[.]?%d*)([%%]?)");
	if(value) then
		value = tonumber(value);
		if(isPercent and isPercent ~= "") then
			return Length:new(value, LengthTypeEnum.Percent);
		end
		return Length:new(value, LengthTypeEnum.Fixed);
	end
	return nil;
end