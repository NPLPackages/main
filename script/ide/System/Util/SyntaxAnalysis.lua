--[[
Title: Syntax Analysis class
Author(s): LiPeng, 
Date: 2018/6/1
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/SyntaxAnalysis.lua");
local SyntaxAnalysis = commonlib.gettable("System.Util.SyntaxAnalysis");

------------------------------------------------------------
]]

local SyntaxAnalysis = commonlib.inherit(nil, commonlib.gettable("System.Util.SyntaxAnalysis"));

function SyntaxAnalysis:ctor()
	self.language = nil;	
end

function SyntaxAnalysis:init(language)
	self.language = language;
	return self;
end

function SyntaxAnalysis.CreateAnalyzer(language)
	if(language == "lua" or language == "npl") then
		return SyntaxAnalysis:new():init(language);
	end
end

local KEY_WORDS = {
	["and"] = true,
	["break"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["false"] = true,
	["for"] = true,
	["function"] = true,
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["nil"] = true,
	["not"] = true,
	["or"] = true,
	["repeat"] = true,
	["return"] = true,
	["then"] = true,
	["true"] = true,
	["until"] = true,
	["while"] = true,
}

local function beQuote(c)
	return c == "'" or c == '"';
end

local function beStringStart(uniStr, pos)
	local c = uniStr[pos];
	if(beQuote(c)) then
		return true, true, c;
	end
	if(c == "[") then
		if(uniStr[pos + 1] == "[") then
			return true, false, c;
		end
	end
	return false, nil, nil;
end

local function beStringEnd(uniStr, pos, start_c)
	local c = uniStr[pos];
	if(beQuote(start_c) and c == start_c) then
		return true, true;
	end
	if(start_c == "[" and c == "]") then
		if(uniStr[pos + 1] == "]") then
			return true, false;
		end
	end
	return false, nil;
end

local function beCommentStart(uniStr, pos)
	local beComment = false;
	local beSingle = true;
	if(uniStr[pos] == "-") then
		if(uniStr[pos + 1] == "-") then
			beComment = true;
			if(uniStr[pos + 2] == "[") then
				if(uniStr[pos + 3] == "[") then
					beSingle = false;
				end
			end
		end
	end
	return beComment, beSingle;
end

local function beCommentEnd(uniStr, pos)
	if(uniStr[pos] == "]") then
		if(uniStr[pos + 1] == "]") then
			return true;
		end
	end
	return false;
end

local function nextIdentifier(uniStr, len, pos)
	local start_pos, end_pos;
	local is_identifier = false;
	while(pos <= len) do
		local c = uniStr[pos];
		local c_num = string.byte(c);
		local is_letter = (c_num > 64 and c_num < 91) or  (c_num >96 and c_num < 123);
		if(not start_pos) then
			if(is_letter or c == "_") then
				start_pos = pos;
				is_identifier = true;
			elseif(c == "'" or c == "\"") then
				end_pos = pos - 1;
				break;
			elseif(c == "-") then
				local is_comment = beCommentStart(uniStr, pos);
				if(is_comment) then
					end_pos = pos - 1;
					break;
				end
			end
		else
			local is_number = c_num > 47 and c_num < 58;
			if(not is_letter and c ~= "_" and not is_number) then
				end_pos = pos - 1;
				break;
			end
		end
		pos = pos + 1;
	end
	if(start_pos) then
		return start_pos, end_pos or pos;
	end
	return nil, end_pos or pos;
end

local function tokenWrapper(type, spos, epos, color, bold)
	return {type = type, spos = spos, epos = epos, color = color, bold = bold};
end

local LUA_TEXT_CONFIG = {
	["comment"] = {color = "#008000", bold = false},
	["string"] = {color = "#808080", bold = false},
	["keyword"] = {color = "#0000FF", bold = false},
	["function"] = {color = "#800000", bold = false},
}

local inMultiComments = false;

function SyntaxAnalysis:GetToken(uniStr)
--local function getToken(uniStr)
	local pos = 0;
	local len = uniStr:length();
	local start_pos = 0;
	return function()
		pos = pos + 1;
		if(pos > len) then
			return;
		end
		if(inMultiComments) then
			while(pos < len) do
				if(beCommentEnd(uniStr, pos)) then
					inMultiComments = false;
					pos = pos + 1;
					return tokenWrapper("comment", 1, pos, LUA_TEXT_CONFIG["comment"]["color"], LUA_TEXT_CONFIG["comment"]["bold"]);
				end
				pos = pos + 1;
			end
			return tokenWrapper("comment", 1, len, LUA_TEXT_CONFIG["comment"]["color"], LUA_TEXT_CONFIG["comment"]["bold"]);
		end
		--c = uniStr[pos];
		--local c_num = string.byte(c);
		local is_string_start, is_quote, start_char = beStringStart(uniStr, pos);
		if(is_string_start) then
			start_pos = pos;
			pos = if_else(is_quote, pos, pos + 1);
			while(pos <= len) do
				pos = pos + 1;
				if(beStringEnd(uniStr, pos, start_char)) then
					pos = if_else(is_quote, pos, pos + 1);
					break;
				end
			end
			return tokenWrapper("string", start_pos, pos, LUA_TEXT_CONFIG["string"]["color"], LUA_TEXT_CONFIG["string"]["bold"]);
		end
		-- can't analysis multiple comments 
		local beComment, beSingle = beCommentStart(uniStr, pos);
		if(beComment) then
			if(not beSingle) then
				inMultiComments = true;
			end
			local start_pos = pos;
			pos = len;
			return tokenWrapper("comment", start_pos, len, LUA_TEXT_CONFIG["comment"]["color"], LUA_TEXT_CONFIG["comment"]["bold"]);
		end
		start_pos, pos = nextIdentifier(uniStr, len, pos);
		if(start_pos) then
			local identifier = uniStr:substr(start_pos, pos);
			if(KEY_WORDS[identifier]) then
				return tokenWrapper("keyword", start_pos, pos, LUA_TEXT_CONFIG["keyword"]["color"], LUA_TEXT_CONFIG["keyword"]["bold"]);	
			end
			-- is function
			if(uniStr[pos + 1] == "(") then
				return tokenWrapper("function", start_pos, pos, LUA_TEXT_CONFIG["function"]["color"], LUA_TEXT_CONFIG["function"]["bold"]);	
			end
		end
		if(pos < len) then
			return tokenWrapper();	
		end
		return;	
	end
end

