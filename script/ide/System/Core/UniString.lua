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
function UniString:GetWidth(font, from, len)
	local text = self.text;
	if(from and len) then
		text = self:substr(from, from + len);
	end
	local textWidth = _guihelper.GetTextWidth(text, font);
	return textWidth;
end

function UniString.GetSpaceWidth(font)
	local textWidth = _guihelper.GetTextWidth(" ", font);
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
	return _guihelper.GetTextWidth(text, font);
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
	if(type(s) == "table") then
		return UniString:new(ParaMisc.UniSubString(s.text, 1, count));
	else
		return ParaMisc.UniSubString(s, 1, count);
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
	[SpecialCharacter.LineFeed] = true,
}

UniString.SpecialCharacter = SpecialCharacter;
-- param c: the char
-- param SpecialCharacter: member of the "UniString.SpecialCharacter" table
function UniString.IsSpecialCharacter(c, SpecialCharacter)
	return string.byte(c, 1) == SpecialCharacter;
end

-- return true if character is a unicode space character
-- @param position: this is cursor pos. 0 means first character. length-1 means last. 
function UniString:atSpace(position)
    local c = self:at(position+1);
    return c and unicode_space_chars[string.byte(c, 1)];
end

local function isASCIIAlphanumeric(ch)
	local ch_num = string.byte(ch);
	if(ch_num > 0x7f) then
		return false;
	end
	return (ch_num > 47 and ch_num < 58) or (ch_num > 64 and ch_num < 91) or (ch_num > 96 and ch_num < 123);
end

local function shouldBreakAfter(lastCh, ch, nextCh)
	if(ch == "-" and isASCIIAlphanumeric(lastCh) and isASCIIAlphanumeric(nextCh)) then
		return true;
	end
	return false;
end

local function needsLineBreakIterator(ch)
	local ch_num = string.byte(ch);
    return ch_num > 127;
end

function UniString:nextBreakablePosition(position)
	local len = self:length();
	local ch, lastCh, lastLastCh = nil, 0, 0;
	if(position > 1) then
		lastCh = self:at(position - 1);
	end
	if(position > 2) then
		lastLastCh = self:at(position - 2);
	end
	while (position <= len) do
		ch = self:at(position);
		if(self:atSpace(position - 1) or shouldBreakAfter(lastLastCh, lastCh, ch)) then
			break;
		end
		if(needsLineBreakIterator(ch) or needsLineBreakIterator(lastCh)) then
			break;
		end
		lastLastCh = lastCh;
		lastCh = ch;

        position = position + 1;
	end
	return position;
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

function UniString:ContainsOnlyWhitespace()
	local len = self:length();
	for i = 1, len do
		if (not UniString.IsASCIISpace(self:at(i))) then
			return false;
		end
	end
--	for (unsigned i = 0; i < m_length; i++)
--        if (!isASCIISpace(m_data[i]))
--            return false;
    return true;
end

function UniString.IsASCIISpace(c)
	if(not c) then
		return false;
	end
	local numC = string.byte(c);
	return c == " " or (numC <= 0xD and numC >= 0x9);
end

function UniString.IsSpaceOrNewline(c)
	-- Use isASCIISpace() for basic Latin-1.
    -- This will include newlines, which aren't included in Unicode DirWS.
    -- return c <= 0x7F ? WTF::isASCIISpace(c) : WTF::Unicode::direction(c) == WTF::Unicode::WhiteSpaceNeutral;
	return UniString.IsASCIISpace(c);
end