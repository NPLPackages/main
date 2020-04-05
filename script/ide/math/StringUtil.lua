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

local byte = string.byte;

--Given two non-empty strings as parameters, this method will return the length of the longest substring common to both parameters. 
function StringUtil.LongestCommonSubstring(str1, str2)
	if (not str1  or not str2) then
		return 0;
	end
	local num = {};

	local maxlen = 0;
	for i = 1 , #str1 do
		num[i] = {};
		for j = 1, #str2 do
			if (byte(str1, i) == byte(str2, j)) then
				local count = 0;
				if ((i == 1) or (j == 1)) then
					count = 1;
				else
					count = 1 + (num[i - 1][j - 1] or 0);
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

function StringUtil.join(ary, separator)
	return table.concat(ary, separator);
end

function StringUtil.trim(str)
	return str and str:gsub("^%s+",""):gsub("%s+$","");
end

-- @param code: text to search in
-- @param text: text to search
-- return true, filename, filenames: if the file text is found. filename contains the full filename
-- if multiple results are found, return filenames which is array of filename
function StringUtil.FindTextInLine(code, text, bExactMatch)
	if(code) then
		if(bExactMatch and code == text) then
			return true, text;
		elseif(not bExactMatch) then
			local nFromIndex = 1;
			local filename, filenames;
			local lineNumber = 1;
			local lastEnter;
			while(nFromIndex) do
				local from = code:find(text, nFromIndex)
				if(from) then
					local line = "";
					if(from > 2) then
						while(true) do
							local nEnterPos = code:find("\n", (lastEnter or 0)+1)
							if(nEnterPos) then
								if(nEnterPos > from) then
									break;
								else
									lastEnter = nEnterPos;
									lineNumber = (lineNumber or 1) + 1;
								end
							else
								break;
							end
						end
						if(lastEnter) then
							line = code:sub(lastEnter+1, from-1);
						else
							line = code:sub(math.max(1, from-50), from-1);
						end
					end
					local lineText = code:sub(from, from + 100);
					local lastEnter = lineText:find("\n")
					if(lastEnter) then
						lineText = lineText:sub(1, lastEnter-1)
						nFromIndex = math.max(from + lastEnter + 1, nFromIndex + 1);
					else
						nFromIndex = code:find("\n", from+100+1);
						if(nFromIndex) then
							nFromIndex = nFromIndex + 1;
						end
					end
					line = format("%d: %s%s", lineNumber or 1, line, lineText);
					if(not filename) then
						filename = line;
					else
						if(not filenames) then
							filenames = {filename}
						end
						filenames[#filenames+1] = line
					end
				else
					nFromIndex = nil;
				end
			end
			if(filename) then
				return true, filename, filenames
			end
		end
	end
end