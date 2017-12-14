--[[
Title: string utility
Author(s): LiXizhi
Date: 2015/2/5
Desc: string helper functions
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/math/StringUtil.lua");
local StringUtil = commonlib.gettable("mathlib.StringUtil");
-------------------------------------------------------
]]
local StringUtil = commonlib.gettable("mathlib.StringUtil");

--Given two non-empty strings as parameters, this method will return the length of the longest substring common to both parameters. 
function StringUtil.LongestCommonSubstring(str1, str2)
	if (not str1  or not str2) then
		return 0;
	end
	local num = {};
	for i = 1 , #str1 do
		num[i] = {};
	end

	local maxlen = 0;
	for i = 1 , #str1 do
		for j = 1, #str2 do
			if (str1[i] ~= str2[j]) then
				num[i][j] = 0;
			else
				local count = 0;
				if ((i == 1) or (j == 1)) then
					count = 1;
				else
					count = 1 + num[i - 1][j - 1];
				end
				if (count > maxlen) then
					maxlen = count;
				end
				num[i][j] = count;
			end
		end
	end
	return maxlen;
end

function StringUtil.Compare(str1, str2)
	if(not str1 or not str2 or type(str1) ~= "string" or type(str2) ~= "string") then
		LOG.error(nil, "error", "StringUtil.Compare", "parameters is nil or format is wrong!");
		return 0;
	end
	if(str1 == str2) then
		return 0;
	end
	if(str1 == "") then
		return -1;
	end

	if(str2 == "") then
		return 1;
	end

	local index = 1;
	local len1 = string.len(str1);
	local len2 = string.len(str2);
	if(len1 < len2) then
		if(string.sub(str2,1,len1) == str1) then
			return -1;
		end
	elseif(len1 > len2) then
		if(string.sub(str1,1,len2) == str2) then
			return 1;
		end
	end
	local len = if_else(len1<len2,len1,len2);
	for i = 1,len do
		if(string.byte(str1,i) < string.byte(str2,i)) then
			return -1;
		elseif(string.byte(str1,i) > string.byte(str2,i)) then
			return 1;
		end
	end
	return 0;
end

