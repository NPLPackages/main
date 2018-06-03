--[[
Title: Enum helper class
Author(s): LiPeng, 
Date: 2018/6/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/EnumCreater.lua");
local EnumCreater = commonlib.gettable("System.Util.EnumCreater");
local t = { "Auto", "Relative", "Percent", "Fixed", "Intrinsic", "MinIntrinsic", "Undefined" };
local enum = EnumCreater.Transform(t);
------------------------------------------------------------
]]

local EnumCreater = commonlib.gettable("System.Util.EnumCreater");

local type = type;

local i = -1;

local function AutoEnum(start)
	if(start) then
		i = start;
	else
		i = i + 1;
	end
	return i;
end

local function ResetStartEnum()
	i = -1;
end

-- @param t: t is array of string, like as { "Auto", "Relative", "Percent", "Fixed", "Intrinsic", "MinIntrinsic", "Undefined" }. 
--			if isn't continuous , can be { "Auto", "Relative", "Percent", {"Fixed", 10}, "Intrinsic", "MinIntrinsic", "Undefined" }. 
function EnumCreater.Transform(t)
	if(#t == 0) then
		return;
	end
	ResetStartEnum();
	local enum = {};
	for i = 1, #t do
		local key = t[i];
		if(type(key) == "table") then
			enum[key[1]] = AutoEnum(key[2]);
		else
			enum[key] = AutoEnum();
		end
	end
	return enum;
end
