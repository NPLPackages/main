--[[
Title: SHA1
Author(s): LiXizhi
Desc: 
The default implementation uses the C++ ParaMisc.sha1(). 
Encoding.Sha1ByScript is NPL version, which is based on https://gist.github.com/creationix/7ce3796e65b66549c4b0
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Encoding/sha1.lua");
local Encoding = commonlib.gettable("System.Encoding");
assert(Encoding.sha1("The quick brown fox jumps over the lazy dog", "hex") == "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12");
assert(Encoding.sha1("The quick brown fox jumps over the lazy dog", "base64") == "L9ThxnotKPzthJ7hu3bnORuT6xI=");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/math/bit.lua");
local Encoding = commonlib.gettable("System.Encoding");

local byte, char = string.byte, string.char
local floor = math.floor
local rshift = mathlib.bit.rshift
local lshift = mathlib.bit.lshift
local band = mathlib.bit.band
local bor = mathlib.bit.bor
local bnot = mathlib.bit.bnot
local bxor = mathlib.bit.bxor

local function leftrotate(num, b)
	return bor(lshift(num, b), rshift(num, 32 - b))
end

local function sha1(message)
	local len = #message
	local high = floor(len / 0x20000000)
	local low = (len * 8) % 100000000

	local function slot(g, o)
		local i = g + o
		if i <= len then
			return byte(message, i)
		elseif i == len + 1 then
			return 0x80
		elseif o <= 56 or len >= g + 56 then
			return 0
		elseif o <= 60 then
			return rshift(high, (60 - o) * 8) % 256
		else
			return rshift(low, (64 - o) * 8) % 256
		end
	end

	local h0, h1, h2, h3, h4 = 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0

	local w = {}
	for g = 0, len + 8, 64 do
		for i = 0, 15 do
		local b = i * 4
		w[i] = bor(
			lshift(slot(g, b + 1), 24),
			lshift(slot(g, b + 2), 16),
			lshift(slot(g, b + 3), 8),
			slot(g, b + 4)
		)
		end
		for i = 16, 79 do
		w[i] = leftrotate(bxor(w[i - 3], w[i - 8], w[i - 14], w[i - 16]), 1)
		end

		local a, b, c, d, e = h0, h1, h2, h3, h4
		local function process(f, k, s)
			a, b, c, d, e =
				leftrotate(a, 5) + f + e + k + s,
				a, leftrotate(b, 30), c, d
		end
		for i = 0, 19 do
			process(bor(band(b, c), band(bnot(b), d)), 0x5A827999, w[i])
		end
		for i = 20, 39 do
			process(bxor(b, c, d), 0x6ED9EBA1, w[i])
		end
		for i = 40, 59 do
			process(bor(band(b, c), band(b, d), band(c, d)), 0x8F1BBCDC, w[i])
		end
		for i = 60, 79 do
			process(bxor(b, c, d), 0xCA62C1D6, w[i])
		end
		h0 = rshift(h0 + a, 0)
		h1 = rshift(h1 + b, 0)
		h2 = rshift(h2 + c, 0)
		h3 = rshift(h3 + d, 0)
		h4 = rshift(h4 + e, 0)
	end

	return char(
		rshift(h0, 24),
		band(rshift(h0, 16), 0xff),
		band(rshift(h0, 8), 0xff),
		band(h0, 0xff),
		rshift(h1, 24),
		band(rshift(h1, 16), 0xff),
		band(rshift(h1, 8), 0xff),
		band(h1, 0xff),
		rshift(h2, 24),
		band(rshift(h2, 16), 0xff),
		band(rshift(h2, 8), 0xff),
		band(h2, 0xff),
		rshift(h3, 24),
		band(rshift(h3, 16), 0xff),
		band(rshift(h3, 8), 0xff),
		band(h3, 0xff),
		rshift(h4, 24),
		band(rshift(h4, 16), 0xff),
		band(rshift(h4, 8), 0xff),
		band(h4, 0xff)
	)
end

local function dump(hash)
  local hex = {}
  for i = 1, #hash do
    hex[i] = string.format("%02x", string.byte(hash, i))
  end
  return table.concat(hex)
end

-- @param format: nil or "hex" or "base64". if nil it is in binary format
function Encoding.sha1(message, format)
	if not format then
		return ParaMisc.sha1(message, true);
	elseif (format == "hex") then
		return ParaMisc.sha1(message, false);
	elseif (format == "base64") then
		return ParaMisc.base64(ParaMisc.sha1(message, true));
	end
end

-- @param format: nil or "hex" or "base64". if nil it is in binary format
function Encoding.Sha1ByScript(message, format)
	local hash = sha1(message);
	if(not format) then
		return hash;
	elseif(format == "hex") then
		return dump(hash);
	elseif(format == "base64") then
		return Encoding.base64(hash);
	end
end

if(not ParaMisc.sha1 or not ParaMisc.base64) then
	log("warning: C++ version of sha1 or base64 not available. Default to script implementation. \n");
	Encoding.sha1 = Encoding.Sha1ByScript;
end