--[[
Title: 
Author(s): LiPeng
Date: 2018/2/8
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/geometry/Length.lua");
local Length = commonlib.gettable("System.Windows.mcml.geometry.Length");
-------------------------------------------------------
]]
local Length = commonlib.gettable("System.Windows.mcml.geometry.Length");
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