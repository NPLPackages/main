--[[
Title: encoding functions
Author(s): LiXizhi
Date: 2008/12/10
Desc: file encoding is a very complicated issue. if the npl file encoding is set to utf8 ( usually without signature), then to display a file, one usually needs to 
convert from system default encoding to utf8 and vice versa. However, it is still impossible to display a file name created in one encoding system and opened in another.  
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/Encoding.lua");
local Encoding = commonlib.gettable("commonlib.Encoding");
assert(Encoding.Utf8ToDefault("a") == "a");
assert(Encoding.DefaultToUtf8("a") == "a")
assert(Encoding.Utf16ToUtf8(Encoding.Utf8ToUtf16("中文")) == "中文")

print(commonlib.Encoding.SortCSVString("Cword,Aword,Bword"))
-------------------------------------------------------
]]
local string_match = string.match;
local string_gsub = string.gsub;
local string_format = string.format;
local string_sub = string.sub;
local tostring = tostring
local tonumber = tonumber
local math_floor = math.floor;

if(not commonlib) then commonlib={}; end
if(not commonlib.Encoding) then commonlib.Encoding={}; end

local Encoding = commonlib.Encoding;

function Encoding.Utf8ToDefault(text)
	return text and ParaMisc.EncodingConvert("utf-8", "", text);
end

function Encoding.DefaultToUtf8(text)
	return text and ParaMisc.EncodingConvert("", "utf-8", text)
end

function Encoding.Utf8ToUtf16(text)
	return text and ParaMisc.UTF8ToUTF16(text);
end

function Encoding.Utf16ToUtf8(text)
	return text and ParaMisc.UTF16ToUTF8(text)
end


-- sort commar separated vector (CSV) string alphabetically
-- @param fields: string such as "C,B,A", or a table containing string arrays such as {"C", "B", "A"}
-- @return return a new CSV string "A,B,C"
function Encoding.SortCSVString(fields)
	if(type(fields) == "string") then
		local fieldTable = {}
		local w;
		for w in string.gfind(fields, "%w+") do
			table.insert(fieldTable, w)
		end
		fields = fieldTable;
	end	
	if(type(fields) == "table") then	
		table.sort(fields);
		local csvNew;
		local _,w
		for _,w in ipairs(fields) do
			if(not csvNew) then
				csvNew = w
			else
				csvNew = csvNew..","..w
			end
		end
		return csvNew
	end
end
function Encoding.EncodeStr(s)
	local s = tostring(s);
	if(not s)then return end
	s = string_gsub(s, "&", "&amp;");
	s = string_gsub(s, "\'", "&apos;");
	s = string_gsub(s, "<", "&lt;");
	s = string_gsub(s, ">", "&gt;");
	s = string_gsub(s, "\"", "&quot;");
	return s;
end

function Encoding.EncodeHTMLInnerText(s)
	local s = tostring(s);
	if(not s)then return end
	s = string_gsub(s, "&", "&amp;");
	-- s = string_gsub(s, "\'", "&apos;");
	s = string_gsub(s, "<", "&lt;");
	s = string_gsub(s, ">", "&gt;");
	-- s = string_gsub(s, "\"", "&quot;");
	return s;
end

function Encoding.HasXMLEscapeChar(s)
	if(string.match(s, "[&'<>\"\n]")) then
		return true;
	end
end

-----------------------------------------------------------------------------
-- Public constants
-----------------------------------------------------------------------------
Encoding.LINEWIDTH = 76

-----------------------------------------------------------------------------
-- Break a string in lines of equal size
-- Input 
--   data: string to be broken 
--   eol: end of line marker
--   width: width of output string lines
-- Returns
--   string broken in lines
-----------------------------------------------------------------------------
function Encoding.split(data, eol, width)
    width = width or (Encoding.LINEWIDTH - string.len(eol) + 2)
    eol = eol or "\r\n"
	-- this looks ugly,  but for lines with less  then 200 columns,
	-- it is more efficient then using strsub and the concat module
	local line = "(" .. string.rep(".", width) .. ")"
    local repl = "%1" .. eol
	return string_gsub(data, line, repl)
end

-----------------------------------------------------------------------------
-- Encodes a string into its base64 representation
-- Input 
--   s: binary string to be encoded
--   single: single line output?
-- Returns
--   string with corresponding base64 representation
-----------------------------------------------------------------------------
function Encoding.base64(s, single)
	if(s) then
		local result = ParaMisc.base64(s);
		if single then 
			return result
		else 
			return Encoding.split(result, Encoding.LINEWIDTH) 
		end
	end
end

-----------------------------------------------------------------------------
-- Decodes a string from its base64 representation
-- Input 
--   s: base64 string
-- Returns
--   decoded binary string
-----------------------------------------------------------------------------
function Encoding.unbase64(s)
	return s and ParaMisc.unbase64(s);
end

local mac_string;

local function get_mac_string()
	if(not mac_string) then
		mac_string = ParaEngine.GetAttributeObject():GetField("MaxMacAddress","")
	end
	return mac_string;
end

-- encode with mac address. 
function Encoding.PasswordEncodeWithMac(text)
	if(text) then
		local mac_key = get_mac_string();
		return ParaMisc.SimpleEncode(string.format("{%q,%q}", mac_key, text))
	end
end

-- return nil if mac address does not match with the local one. 
function Encoding.PasswordDecodeWithMac(text)
	if(text) then
		text = ParaMisc.SimpleDecode(text)
		if(text:match("^{.*}$")) then
			local tmp = NPL.LoadTableFromString(text);
			if(tmp) then
				if(tmp[1] == get_mac_string() and tmp[2]) then
					return tmp[2];
				else
					-- mac address mismatch
					return;
				end
			end
		end
		return text;
	end
end

-- used in poweritem api ChangeItem. 
-- @param input:either string or table. 
-- @return the server data string or nil.
function Encoding.EncodeServerData(input)
	if(type(input) == "table") then
		-- input = commonlib.serialize_compact(input);
		input = commonlib.Json.Encode(input);
	end
	if(type(input) == "string") then
		input = string_gsub(input,",","@");
		input = string_gsub(input,"|","#");
		input = string_gsub(input,"~","*");
		return input;
	end
end

function Encoding.DecodeServerData(input)
	if(type(input) ~= "string" or input == "")then
		return
	end
	input = string_gsub(input,"@",",");
	input = string_gsub(input,"#","|");
	input = string_gsub(input,"*","~");
	--input = commonlib.LoadTableFromString(input);
	local parsed_serverdata = {};
	NPL.FromJson(input, parsed_serverdata);
	return parsed_serverdata;
end

function Encoding.EncodeServerDataString(input)
	if(type(input) == "string") then
		input = string_gsub(input,"[,|~]"," ");
	end
	return input
end

-- Decode an URL-encoded string
-- (Note that you should only decode a URL string after splitting it; this allows you to correctly process quoted "?" characters in the query string or base part, for instance.) 
function Encoding.url_decode(str)
	str = string_gsub (str, "+", " ")
	str = string_gsub (str, "%%(%x%x)",
		function(h) return string.char(tonumber(h,16)) end)
	str = string_gsub (str, "\r\n", "\n")
	return str
end

-- URL-encode a string
function Encoding.url_encode(str)
	if (str) then
		str = string_gsub (str, "\n", "\r\n")
		str = string_gsub (str, "([^%w ])",
			function (c) return string.format ("%%%02X", string.byte(c)) end)
		str = string_gsub (str, " ", "+")
	end
	return str
end