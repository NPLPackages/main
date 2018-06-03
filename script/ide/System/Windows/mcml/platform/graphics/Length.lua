--[[
Title: 
Author(s): LiPeng
Date: 2018/2/8
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/Length.lua");
local Length = commonlib.gettable("System.Windows.mcml.platform.graphics.Length");
-------------------------------------------------------
]]
local Length = commonlib.gettable("System.Windows.mcml.platform.graphics.Length");
local type = type;
local string_match = string.match;

function Length.IsFixed(length)
	if(length and type(length) == "number") then
		return true;
	end
	return false;
end

function Length.IsAuto(length)
	if(length == nil) then
		return true;
	end
	return false;
end

function Length.IsPercent(length)
	if(length and type(length) == "string" and string_match(length,"%%$")) then
		return true;
	end
	return false;
end

function Length.IsUndefined(length)
	if(length == nil) then
		return true;
	end
	return false;
end

function Length.IsSpecified(length)
	if(Length.IsFixed(length) and Length.IsPercent(length)) then
		return true;
	end
	return false;
end

function Length.IsIntrinsicOrAuto(length)
	return Length.IsAuto(length);
end

function Length.IsPositive(length)
	return length > 0
end

function Length.IsNegative(length)
	return length < 0;
end

function Length.IsZero(length)
	return length == 0;
end
-- enum LengthType { Auto, Relative, Percent, Fixed, Intrinsic, MinIntrinsic, Undefined };
function Length.Type(length)
	if(Length.IsAuto(length)) then
		return "Auto";
	elseif(Length.IsFixed(length)) then
		return "Fixed";
	elseif(Length.IsPercent(length)) then
		return "Percent";
	end
	return "Undefined";
end

function Length.CalcMinValue(length, maxValue, roundPercentages)
	roundPercentages = if_else(roundPercentages == nil, false, true);
	local type = Length.Type(length);
	if(type == "Fixed") then
		return length;
	elseif(type == "Percent") then
		local percent = tonumber(length:match("(%d+[.]?%d*)%%"));
		local value = maxValue * percent / 100;
		if (roundPercentages) then
			value = math.floor(value + 0.5);
		end
		return value;
	end
	return 0;
--        switch (type()) {
--            case Fixed:
--                return value();
--            case Percent:
--                if (roundPercentages)
--                    return static_cast<int>(round(maxValue * percent() / 100.0f));
--                // Don't remove the extra cast to float. It is needed for rounding on 32-bit Intel machines that use the FPU stack.
--                return static_cast<int>(static_cast<float>(maxValue * percent() / 100.0f));
--            case Auto:
--                return 0;
--            case Relative:
--            case Intrinsic:
--            case MinIntrinsic:
--            case Undefined:
--                ASSERT_NOT_REACHED();
--                return 0;
--        }
--        ASSERT_NOT_REACHED();
--        return 0;
end