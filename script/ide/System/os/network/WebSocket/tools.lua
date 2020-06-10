NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
local Encoding = commonlib.gettable("System.Encoding");

local base64 = Encoding.base64
local bit = mathlib.bit
local rol = bit.rol
local bxor = bit.bxor
local bor = bit.bor
local band = bit.band
local bnot = bit.bnot
local lshift = bit.lshift
local rshift = bit.rshift
local sunpack = string.unpack
local srep = string.rep
local schar = string.char
local tremove = table.remove
local tinsert = table.insert
local tconcat = table.concat
local mrandom = math.random

local read_n_bytes = function(str, pos, n)
  pos = pos or 1
  return pos+n, string.byte(str, pos, pos + n - 1)
end

local read_int8 = function(str, pos)
  return read_n_bytes(str, pos, 1)
end

local read_int16 = function(str, pos)
  local new_pos,a,b = read_n_bytes(str, pos, 2)
  return new_pos, lshift(a, 8) + b
end

local read_int32 = function(str, pos)
  local new_pos,a,b,c,d = read_n_bytes(str, pos, 4)
  return new_pos,
  lshift(a, 24) +
  lshift(b, 16) +
  lshift(c, 8 ) +
  d
end

local pack_bytes = string.char

local write_int8 = pack_bytes

local write_int16 = function(v)
  return pack_bytes(rshift(v, 8), band(v, 0xFF))
end

local write_int32 = function(v)
  return pack_bytes(
    band(rshift(v, 24), 0xFF),
    band(rshift(v, 16), 0xFF),
    band(rshift(v,  8), 0xFF),
    band(v, 0xFF)
  )
end

-- used for generate key random ops
math.randomseed(os.time())



local DEFAULT_PORTS = {ws = 80, wss = 443}

local parse_url = function(url)
  local protocol, address, uri = url:match('^(%w+)://([^/]+)(.*)$')
  if not protocol then error('Invalid URL:'..url) end
  protocol = protocol:lower()
  local host, port = address:match("^(.+):(%d+)$")
  if not host then
    host = address
    port = DEFAULT_PORTS[protocol]
  end
  if not uri or uri == '' then uri = '/' end
  return protocol, host, tonumber(port), uri
end

local generate_key = function()
  local r1 = mrandom(0,0xfffffff)
  local r2 = mrandom(0,0xfffffff)
  local r3 = mrandom(0,0xfffffff)
  local r4 = mrandom(0,0xfffffff)
  local key = write_int32(r1)..write_int32(r2)..write_int32(r3)..write_int32(r4)
  assert(#key==16,#key)
  return base64(key)
end

NPL.export({
    parse_url = parse_url,
    generate_key = generate_key,
    read_int8 = read_int8,
    read_int16 = read_int16,
    read_int32 = read_int32,
    write_int8 = write_int8,
    write_int16 = write_int16,
    write_int32 = write_int32,
})
