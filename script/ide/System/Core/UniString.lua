--[[
Title: UniString
Author(s): LiXizhi
Date: 2015/5/28
Desc: Unicode string wrapping a UTF8 string. mostly for text manipulations in editbox, etc. 

Reference: some function refer to qtextlayout and qtextengine in qt.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Core/UniString.lua");
local UniString = commonlib.gettable("System.Core.UniString");
local s1 = UniString:new("一二三四五");
echo("cursorToX"..s1:cursorToX(2))
echo("xToCursor"..s1:xToCursor(10))

assert(s1[3] == "三" and s1:at(3) == "三", "test index")
assert(s1:length() == 5, "test length")
assert(tostring(s1) == "一二三四五", "test eq")
assert(tostring(s1.."六") == "一二三四五六", "test concat")
assert(tostring(s1:sub(1,2)) == "一二", "test sub")
s1:insert(1,"insert");
assert(tostring(s1) == "一insert二三四五", "test insert")
s1:remove(2, 6);
assert(tostring(s1) == "一二三四五", "test remove")
------------------------------------------------------------
]]
local type = type;
local tostring = tostring;

local UniString = commonlib.gettable("System.Core.UniString");

local function ToString(str)
	if(type(str) == "table") then
		return str:GetText();
	else
		return str;
	end
end

-- @param str: a utf8 string or another UniString object. 
function UniString:new(str)
	if(type(str) == "table") then
		setmetatable(str, self);
		return str;
	else
		local o = {text=str or ""};
		setmetatable(o, self);
		return o;
	end
end

-- set utf8 string
function UniString:SetText(text)
	self.text = text or "";
end

-- get utf8 string
function UniString:GetText()
	return self.text;
end

function UniString:length()
	return ParaMisc.GetUnicodeCharNum(self.text);
end

function UniString:size()
	return ParaMisc.GetUnicodeCharNum(self.text);
end

-- measure text width in pixel using the given font 
-- @param font: if nil, it is the default font. 
function UniString:GetWidth(font)
	return UniString.GetTextWidth(self.text, font);
end

-- public static function.
function UniString.GetTextWidth(text, font)
	local textWidth = _guihelper.GetTextWidth(text, font);
	return textWidth;
end

-- return pixel X position at the given cursor position. 
-- @param cursor: cursor position
-- @param font: if nil, it is the default font. 
function UniString:cursorToX(cursor, font)
	if(cursor <= 0) then
		return 0;
	end
	local text = ParaMisc.UniSubString(self.text, 1, cursor)
	return UniString.GetTextWidth(text, font);
end

-- Returns the cursor position of the given x pixel value in relation to the displayed text.  
-- @param betweenOrOn: nil or "CursorBetweenCharacters", "CursorOnCharacter"
function UniString:xToCursor(x, betweenOrOn, font)
	if(x <= 0) then
		return 0;
	end
	local thisLine = _guihelper.GetTextObjectByFont(font);
	thisLine.text = self.text;
	local cursor, trail = thisLine:XYtoCP(x, 0, 0, 0);
	return cursor;
end


function UniString.__concat(left, right)
	return UniString:new(ToString(left)..ToString(right))
end

function UniString.__eq(left, right)
	return ToString(left) == Tostring(right);
end

function UniString.__tostring(t)
	return t.text;
end

function UniString.__index(t, key)
	if(type(key) == "number") then
		if(key >=1 and key <= t:length()) then
			return ParaMisc.UniSubString(t.text, key, key);
		end
	else
		return rawget(UniString, key);
	end
end

-- index start from 1. same as string.sub() in lua
function UniString:at(index)
	if(index >=1 and index <= self:length()) then
		return ParaMisc.UniSubString(self.text, index, index);
	end
end

function UniString:empty()
	return self.text == "";
end

function UniString:findFirstOf(str, initPos, bUseRegularExpression)
	initPos = initPos or 1;
	local beExist = false
	local text = self.text;
	local _start, _end = string.find(text, str, nil, not bUseRegularExpression)
	if(not _start) then
		return nil, nil;
	elseif(initPos == 1) then
		beExist = true;
	end
	local startPos, endPos;
	local i, uniPos = 1, 1;
	while true do
		if(not beExist and uniPos >= initPos) then
			_start, _end = string.find(text, str, i, not bUseRegularExpression)
			if(not _start) then
				break;
			else
				beExist = true;
			end
		end
        local curByte = string.byte(text, i)
		if(not curByte) then
			break;
		end
        local byteCount = 1
        if curByte > 239 then
            byteCount = 4  -- 4字节字符
        elseif curByte > 223 then
            byteCount = 3  -- 汉字
        elseif curByte > 128 then
            byteCount = 2  -- 双字节字符
        else
            byteCount = 1  -- 单字节字符
        end
		if(uniPos >= initPos) then
			if(i == _start) then
				startPos = uniPos;
			end
			if((byteCount == 1 and i == _end) or i + byteCount - 1 == _end) then
				endPos = uniPos;
				break;
			end
		end
		
        i = i + byteCount;
        uniPos = uniPos + 1;
        if i > #text then
            break;
        end
    end

	return startPos, endPos;
end

-- index start from 1. same as string.sub() in lua
-- return a new UniString() object.
function UniString:sub(from, to)
	return UniString:new(ParaMisc.UniSubString(self.text, from, to or -1));
end

-- same as sub, except that it returns standard string. 
function UniString:substr(from, to)
	return ParaMisc.UniSubString(self.text, from, to or -1);
end

-- index start from 1. same as string.sub() in lua
-- @param str: str can be standard string or UniString.
function UniString:insert(pos, str)
	self.text = ParaMisc.UniSubString(self.text, 1, pos)..tostring(str)..ParaMisc.UniSubString(self.text, pos+1, -1);
end

-- remove from give pos
function UniString:remove(pos, count)
	if(pos <= self:length()) then
		if(pos >= 1) then
			local s = self.text;
			self.text = ParaMisc.UniSubString(s, 1, pos-1);
			if(count) then
				self.text = self.text..ParaMisc.UniSubString(s, pos+count, -1);
			end
		else
			self.text = ParaMisc.UniSubString(self.text, 1, self:length()-1);
		end
	end
end

-- public static method: number of unicode chars in s
-- @param s: s can be standard string or UniString.
function UniString.GetTextLength(s)
	return ParaMisc.GetUnicodeCharNum(tostring(s));
end

-- @param s: can be standard string or UniString.
-- return the string of at most count unicode characters. the return type is same as s parameter.
function UniString.left(s, count)
	if type(count)~="number" then
		return s
	end
	if(type(s) == "table") then
		return UniString:new(ParaMisc.UniSubString(s.text, 1, count));
	elseif type(s)=="string" then
		return ParaMisc.UniSubString(s, 1, count);
	else
		return s
	end
end


-- special unicode character
local SpecialCharacter = {
    Null = 0x0000,
    Tabulation = 0x0009,
    LineFeed = 0x000a,
    CarriageReturn = 0x000d,
    Space = 0x0020,
    Nbsp = 0x00a0,
    SoftHyphen = 0x00ad,
    ReplacementCharacter = 0xfffd,
    ObjectReplacementCharacter = 0xfffc,
    ByteOrderMark = 0xfeff,
    ByteOrderSwapped = 0xfffe,
    ParagraphSeparator = 0x2029,
    LineSeparator = 0x2028,
    LastValidCodePoint = 0x10ffff
};

local unicode_space_chars = {
	[SpecialCharacter.Tabulation] = true,
	[SpecialCharacter.Space] = true,
	[SpecialCharacter.Nbsp] = true,
	[SpecialCharacter.LineSeparator] = true,
}

-- return true if character is a unicode space character
-- @param position: this is cursor pos. 0 means first character. length-1 means last. 
function UniString:atSpace(position)
    local c = self:at(position+1);
    return c and unicode_space_chars[string.byte(c, 1)];
end

local word_separators = {
	['.']=true,
	[',']=true,
	['?']=true,
	['!']=true,
	['@']=true,
	['#']=true,
	['$']=true,
	[':']=true,
	[';']=true,
	['-']=true,
	['<']=true,
	['>']=true,
	['[']=true,
	[']']=true,
	['(']=true,
	[')']=true,
	['{']=true,
	['}']=true,
	['=']=true,
	['/']=true,
	['+']=true,
	['%']=true,
	['&']=true,
	['^']=true,
	['*']=true,
	['\\']=true,
	['"']=true,
	['`']=true,
	['~']=true,
	['|']=true,
};

-- @param position: this is cursor pos. 0 means first character. length-1 means last. 
function UniString:atWordSeparator(position)
    local c = self:at(position+1);
    return c and word_separators[c];
end

-- @param position: this is cursor pos. 0 means first character. length-1 means last. 
function UniString:isValidCursorPosition(pos)
	if(pos < 0 or pos > self:length()) then
		return false;
	end
	return true;
end

-- Returns the next valid cursor position before oldPos that respects the given cursor mode.
-- @param mode: "SkipCharacters" or "SkipWords"
function UniString:nextCursorPosition(oldPos, mode)
	local len = self:length();
	if(oldPos < 0 or oldPos >= len) then
		return oldPos;
	end
	if (mode == "SkipCharacters") then
        oldPos = oldPos + 1;
    else
        if (oldPos<len and self:atWordSeparator(oldPos)) then
            oldPos = oldPos + 1;
            while (oldPos<len and self:atWordSeparator(oldPos)) do
				oldPos = oldPos + 1;
			end
        else
            while (oldPos<len and not self:atSpace(oldPos) and not self:atWordSeparator(oldPos)) do
				oldPos = oldPos + 1;
			end
        end
		while (oldPos<len and self:atSpace(oldPos)) do
            oldPos = oldPos + 1;
		end
    end
    return oldPos;
end

-- Returns the first valid cursor position before oldPos that respects the given cursor mode.
-- @param mode: cursorMode of either "SkipCharacters" or "SkipWords"
function UniString:previousCursorPosition(oldPos, mode)
	local len = self:length();
	if(oldPos <= 0 or oldPos > len) then
		return oldPos;
	end
	if (mode == "SkipCharacters") then
        oldPos = oldPos - 1;
    else
        while (oldPos>0 and self:atSpace(oldPos-1)) do
            oldPos = oldPos - 1;
		end

        if (oldPos>0 and self:atWordSeparator(oldPos-1)) then
            oldPos = oldPos - 1;
            while (oldPos>0 and self:atWordSeparator(oldPos-1)) do
				oldPos = oldPos - 1;
			end
        else
            while (oldPos>0 and not self:atSpace(oldPos-1) and not self:atWordSeparator(oldPos-1)) do
				oldPos = oldPos - 1;
			end
        end
    end
    return oldPos;
end

function UniString:leftCursorPosition(oldPos)
	return oldPos - 1;
end

function UniString:rightCursorPosition(oldPos)
	return oldPos + 1;
end

function UniString:wordEndPosition(oldPos)
	local end_pos = oldPos + 1;
	if(self:at(end_pos) == ' ') then
		while(self:at(end_pos + 1) == ' ')  do
			end_pos = end_pos + 1;
		end																																					   
		return end_pos;
	end
	local end_pos = self:nextCursorPosition(oldPos , "SkipWords")
	while(self:at(end_pos) == ' ')  do
		end_pos = end_pos - 1;
	end	
	return end_pos;
end

function UniString:getFirstWordPosition()
	for i=1, self:length() do
		if(self:at(i) ~= ' ') then
			return i-1;
		end
	end
	return self:length();
end

function UniString:wordBeginPosition(oldPos)
	local begin_pos = oldPos;
	if(self:at(begin_pos) == ' ') then
		begin_pos = begin_pos - 1;
		while(self:at(begin_pos) == ' ')  do
			begin_pos = begin_pos - 1;
		end
		return begin_pos;
	end
	begin_pos = self:previousCursorPosition(oldPos, "SkipWords")
	return begin_pos;
end

 function UniString:wordPosition(oldPos)
	local len = self:length();
	local begin_pos ;
	local end_pos ;
	if(oldPos <= 0 ) then
		begin_pos = oldPos;
		end_pos = self:wordEndPosition(oldPos);								
	elseif(oldPos >= len ) then															
		begin_pos = self:wordBeginPosition(oldPos);															 
		end_pos = len;
	else
		local prev_char = self:at(oldPos);
		local next_char = self:at(oldPos+1);
		if(prev_char == ' ' and next_char == ' ') then
			begin_pos = self:wordBeginPosition(oldPos);
			end_pos = self:wordEndPosition(oldPos);
		elseif(prev_char == ' ') then
			begin_pos = oldPos;
			end_pos = self:wordEndPosition(oldPos);		
		elseif(next_char == ' ') then
			begin_pos = self:wordBeginPosition(oldPos);
			end_pos = oldPos;
		else
			begin_pos = self:atWordSeparator(oldPos-1) and oldPos or self:wordBeginPosition(oldPos);
			end_pos = self:atWordSeparator(oldPos) and oldPos or self:wordEndPosition(oldPos);
		end
	end	
	return begin_pos,end_pos;
end
