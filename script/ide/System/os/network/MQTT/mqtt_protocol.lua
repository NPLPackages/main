--[[
Title: MQTT generic protocol components module
Author(s): LiXizhi, ported from https://github.com/xHasKx/luamqtt
Date: 2023/6/26
Desc:
-------------------------------------------------------
-------------------------------------------------------
]]
local mqtt = commonlib.gettable("System.os.network.mqtt");

-- module table
local protocol = NPL.export();

-- load required stuff
local type = type
local error = error
local assert = assert
local require = require
local tostring = tostring
local setmetatable = setmetatable

local tbl_concat = table.concat
local unpack = unpack or table.unpack

local str_sub = string.sub
local str_char = string.char
local str_byte = string.byte
local str_format = string.format

local bor = mathlib.bit.bor
local band = mathlib.bit.band
local lshift = mathlib.bit.lshift
local rshift = mathlib.bit.rshift
local math_floor = math.floor

local div = function (x, y)
	return math_floor(x / y)
end

--- Create bytes of the uint8 value
-- @param number val - integer value to convert to bytes
-- @return string bytes of the value
function protocol.make_uint8(val)
	if val < 0 or val > 0xFF then
		error("value is out of range to encode as uint8: "..tostring(val))
	end
	return str_char(val)
end
local make_uint8 = protocol.make_uint8

--- Create bytes of the uint16 value
-- @param number val - integer value to convert to bytes
-- @return string bytes of the value
function protocol.make_uint16(val)
	if val < 0 or val > 0xFFFF then
		error("value is out of range to encode as uint16: "..tostring(val))
	end
	return str_char(rshift(val, 8), band(val, 0xFF))
end
local make_uint16 = protocol.make_uint16

--- Create bytes of the uint32 value
-- @param number val - integer value to convert to bytes
-- @return string bytes of the value
function protocol.make_uint32(val)
	if val < 0 or val > 0xFFFFFFFF then
		error("value is out of range to encode as uint32: "..tostring(val))
	end
	return str_char(rshift(val, 24), band(rshift(val, 16), 0xFF), band(rshift(val, 8), 0xFF), band(val, 0xFF))
end

--- Create bytes of the UTF-8 string value according to the MQTT spec.
-- Basically it's the same string with its length prefixed as uint16 value.
-- For MQTT v3.1.1:	<b>1.5.3 UTF-8 encoded strings</b>,
-- For MQTT v5.0:	<b>1.5.4 UTF-8 Encoded String</b>.
-- @param string str - string value to convert to bytes
-- @return string bytes of the value
function protocol.make_string(str)
	return make_uint16(str:len())..str
end

--- Maximum integer value (268435455) that can be encoded using variable-length encoding
protocol.max_variable_length = 268435455
local max_variable_length = protocol.max_variable_length

--- Create bytes of the integer value encoded as variable length field
-- For MQTT v3.1.1:	<b>2.2.3 Remaining Length</b>,
-- For MQTT v5.0:	<b>2.1.4 Remaining Length</b>.
-- @param number len - integer value to be encoded
-- @return string bytes of the value
function protocol.make_var_length(len)
	if len < 0 or len > max_variable_length then
		error("value is invalid for encoding as variable length field: "..tostring(len))
	end
	local bytes = {}
	local i = 1
	repeat
		local byte = len % 128
		len = div(len, 128)
		if len > 0 then
			byte = bor(byte, 128)
		end
		bytes[i] = byte
		i = i + 1
	until len <= 0
	return unpack(bytes)
end
local make_var_length = protocol.make_var_length

--- Make bytes for 1-byte value with only 0 or 1 value allowed
-- @param number value - integer value to convert to bytes
-- @return string bytes of the value
function protocol.make_uint8_0_or_1(value)
	if value ~= 0 and value ~= 1 then
		error("expecting 0 or 1 as value")
	end
	return make_uint8(value)
end

--- Make bytes for 2-byte value with nonzero check
-- @param number value - integer value to convert to bytes
-- @return string bytes of the value
function protocol.make_uint16_nonzero(value)
	if value == 0 then
		error("expecting nonzero value")
	end
	return make_uint16(value)
end

--- Make bytes for variable length value with nonzero value check
-- @param number value - integer value to convert to bytes
-- @return string bytes of the value
function protocol.make_var_length_nonzero(value)
	if value == 0 then
		error("expecting nonzero value")
	end
	return make_var_length(value)
end

--- Read string using given read_func function
-- @param function read_func - function to read some bytes from the network layer
-- @return string parsed string on success
-- @return OR false and error message on failure
function protocol.parse_string(read_func)
	assert(type(read_func) == "function", "expecting read_func to be a function")
	local len, err = read_func(2)
	if not len then
		return false, "failed to read string length: "..err
	end
	-- convert len string from 2-byte integer
	local byte1, byte2 = str_byte(len, 1, 2)
	len = bor(lshift(byte1, 8), byte2)
	-- and return string if parsed length
	return read_func(len)
end
local parse_string = protocol.parse_string

--- Parse uint8 value using given read_func
-- @param function read_func - function to read some bytes from the network layer
-- @return number parser value
-- @return OR false and error message on failure
function protocol.parse_uint8(read_func)
	assert(type(read_func) == "function", "expecting read_func to be a function")
	local value, err = read_func(1)
	if not value then
		return false, "failed to read 1 byte for uint8: "..err
	end
	return str_byte(value, 1, 1)
end
local parse_uint8 = protocol.parse_uint8

--- Parse uint8 value using given read_func with only 0 or 1 value allowed
-- @param function read_func - function to read some bytes from the network layer
-- @return number parser value
-- @return OR false and error message on failure
function protocol.parse_uint8_0_or_1(read_func)
	local value, err = parse_uint8(read_func)
	if not value then
		return false, err
	end
	if value ~= 0 and value ~= 1 then
		return false, "expecting only 0 or 1 but got: "..value
	end
	return value
end

--- Parse uint16 value using given read_func
-- @param function read_func - function to read some bytes from the network layer
-- @return number parser value
-- @return OR false and error message on failure
function protocol.parse_uint16(read_func)
	assert(type(read_func) == "function", "expecting read_func to be a function")
	local value, err = read_func(2)
	if not value then
		return false, "failed to read 2 byte for uint16: "..err
	end
	local byte1, byte2 = str_byte(value, 1, 2)
	return lshift(byte1, 8) + byte2
end
local parse_uint16 = protocol.parse_uint16

--- Parse uint16 non-zero value using given read_func
-- @param function read_func - function to read some bytes from the network layer
-- @return number parser value
-- @return OR false and error message on failure
function protocol.parse_uint16_nonzero(read_func)
	local value, err = parse_uint16(read_func)
	if not value then
		return false, err
	end
	if value == 0 then
		return false, "expecting non-zero value"
	end
	return value
end

--- Parse uint32 value using given read_func
-- @param function read_func - function to read some bytes from the network layer
-- @return number parser value
-- @return OR false and error message on failure
function protocol.parse_uint32(read_func)
	assert(type(read_func) == "function", "expecting read_func to be a function")
	local value, err = read_func(4)
	if not value then
		return false, "failed to read 4 byte for uint32: "..err
	end
	local byte1, byte2, byte3, byte4 = str_byte(value, 1, 4)
	return byte1 * (2 ^ 24) + lshift(byte2, 16) + lshift(byte3, 8) + byte4
end

-- Max multiplier of the variable length integer value
local max_mult = 128 * 128 * 128

--- Parse variable length field value using given read_func.
-- For MQTT v3.1.1:	<b>2.2.3 Remaining Length</b>,
-- For MQTT v5.0:	<b>2.1.4 Remaining Length</b>.
-- @param function read_func - function to read some bytes from the network layer
-- @return number parser value
-- @return OR false and error message on failure
function protocol.parse_var_length(read_func)
	assert(type(read_func) == "function", "expecting read_func to be a function")
	local mult = 1
	local val = 0
	repeat
		local byte, err = read_func(1)
		if not byte then
			return false, err
		end
		byte = str_byte(byte, 1, 1)
		val = val + band(byte, 127) * mult
		if mult > max_mult then
			return false, "malformed variable length field data"
		end
		mult = mult * 128
	until band(byte, 128) == 0
	return val
end
local parse_var_length = protocol.parse_var_length

--- Parse variable length field value using given read_func with non-zero constraint.
-- For MQTT v3.1.1:	<b>2.2.3 Remaining Length</b>,
-- For MQTT v5.0:	<b>2.1.4 Remaining Length</b>.
-- @param function read_func - function to read some bytes from the network layer
-- @return number parser value
-- @return OR false and error message on failure
function protocol.parse_var_length_nonzero(read_func)
	local value, err = parse_var_length(read_func)
	if not value then
		return false, err
	end
	if value == 0 then
		return false, "expecting non-zero value"
	end
	return value
end

--- Create bytes of the MQTT fixed packet header
-- For MQTT v3.1.1:	<b>2.2 Fixed header</b>,
-- For MQTT v5.0:	<b>2.1.1 Fixed Header</b>.
-- @param number ptype - MQTT packet type
-- @param number flags - MQTT packet flags
-- @param number len - MQTT packet length
-- @return string bytes of the fixed packet header
function protocol.make_header(ptype, flags, len)
	local byte1 = bor(lshift(ptype, 4), band(flags, 0x0F))
	return str_char(byte1, make_var_length(len))
end

--- Check if given value is a valid PUBLISH message QoS value
-- @param number val - QoS value
-- @return boolean true for valid QoS value, otherwise false
function protocol.check_qos(val)
	return (val == 0) or (val == 1) or (val == 2)
end

--- Check if given value is a valid Packet Identifier
-- For MQTT v3.1.1:	<b>2.3.1 Packet Identifier</b>,
-- For MQTT v5.0:	<b>2.2.1 Packet Identifier</b>.
-- @param number val - Packet ID value
-- @return boolean true for valid Packet ID value, otherwise false
function protocol.check_packet_id(val)
	return val >= 1 and val <= 0xFFFF
end

--- Returns the next Packet Identifier value relative to given current value.
-- If current is nil - returns 1 as the first possible Packet ID.
-- For MQTT v3.1.1:	<b>2.3.1 Packet Identifier</b>,
-- For MQTT v5.0:	<b>2.2.1 Packet Identifier</b>.
-- @param[opt] number curr - current Packet ID value
-- @return number next Packet ID value
function protocol.next_packet_id(curr)
	if not curr then
		return 1
	end
	assert(type(curr) == "number", "expecting curr to be a number")
	assert(curr >= 1, "expecting curr to be >= 1")
	curr = curr + 1
	if curr > 0xFFFF then
		curr = 1
	end
	return curr
end

--- MQTT protocol fixed header packet types.
-- For MQTT v3.1.1:	<b>2.2.1 MQTT Control Packet type</b>,
-- For MQTT v5.0:	<b>2.1.2 MQTT Control Packet type</b>.
protocol.packet_type = {
	CONNECT = 			1, 					-- 1
	CONNACK = 			2, 					-- 2
	PUBLISH = 			3, 					-- 3
	PUBACK = 			4, 					-- 4
	PUBREC = 			5, 					-- 5
	PUBREL = 			6, 					-- 6
	PUBCOMP = 			7, 					-- 7
	SUBSCRIBE = 		8, 					-- 8
	SUBACK = 			9, 					-- 9
	UNSUBSCRIBE = 		10, 				-- 10
	UNSUBACK = 			11, 				-- 11
	PINGREQ = 			12, 				-- 12
	PINGRESP = 			13, 				-- 13
	DISCONNECT = 		14, 				-- 14
	AUTH =				15, 				-- 15
	[1] = 				"CONNECT", 			-- "CONNECT"
	[2] = 				"CONNACK", 			-- "CONNACK"
	[3] = 				"PUBLISH", 			-- "PUBLISH"
	[4] = 				"PUBACK", 			-- "PUBACK"
	[5] = 				"PUBREC", 			-- "PUBREC"
	[6] = 				"PUBREL", 			-- "PUBREL"
	[7] = 				"PUBCOMP", 			-- "PUBCOMP"
	[8] = 				"SUBSCRIBE", 		-- "SUBSCRIBE"
	[9] = 				"SUBACK", 			-- "SUBACK"
	[10] = 				"UNSUBSCRIBE", 		-- "UNSUBSCRIBE"
	[11] = 				"UNSUBACK", 		-- "UNSUBACK"
	[12] = 				"PINGREQ", 			-- "PINGREQ"
	[13] = 				"PINGRESP", 		-- "PINGRESP"
	[14] = 				"DISCONNECT", 		-- "DISCONNECT"
	[15] =				"AUTH", 			-- "AUTH"
}
local packet_type = protocol.packet_type

-- Packet types requiring packet identifier field
-- DOCv3.1.1: 2.3.1 Packet Identifier
-- DOCv5.0: 2.2.1 Packet Identifier
local packets_requiring_packet_id = {
	[packet_type.PUBACK] 		= true,
	[packet_type.PUBREC] 		= true,
	[packet_type.PUBREL] 		= true,
	[packet_type.PUBCOMP] 		= true,
	[packet_type.SUBSCRIBE] 	= true,
	[packet_type.SUBACK] 		= true,
	[packet_type.UNSUBSCRIBE] 	= true,
	[packet_type.UNSUBACK] 		= true,
}

-- CONNACK return code/reason code strings
protocol.connack_rc = {
	-- MQTT v3.1.1 Connect return codes, DOCv3.1.1: 3.2.2.3 Connect Return code
	[0] = "Connection Accepted",
	[1] = "Connection Refused, unacceptable protocol version",
	[2] = "Connection Refused, identifier rejected",
	[3] = "Connection Refused, Server unavailable",
	[4] = "Connection Refused, bad user name or password",
	[5] = "Connection Refused, not authorized",

	-- MQTT v5.0 Connect reason codes, DOCv5.0: 3.2.2.2 Connect Reason Code
	[0x80] = "Unspecified error",
	[0x81] = "Malformed Packet",
	[0x82] = "Protocol Error",
	[0x83] = "Implementation specific error",
	[0x84] = "Unsupported Protocol Version",
	[0x85] = "Client Identifier not valid",
	[0x86] = "Bad User Name or Password",
	[0x87] = "Not authorized",
	[0x88] = "Server unavailable",
	[0x89] = "Server busy",
	[0x8A] = "Banned",
	[0x8C] = "Bad authentication method",
	[0x90] = "Topic Name invalid",
	[0x95] = "Packet too large",
	[0x97] = "Quota exceeded",
	[0x99] = "Payload format invalid",
	[0x9A] = "Retain not supported",
	[0x9B] = "QoS not supported",
	[0x9C] = "Use another server",
	[0x9D] = "Server moved",
	[0x9F] = "Connection rate exceeded",
}
local connack_rc = protocol.connack_rc

--- Check if Packet Identifier field are required for given packet
-- @param table args - args for creating packet
-- @return boolean true if Packet Identifier are required for the packet
function protocol.packet_id_required(args)
	assert(type(args) == "table", "expecting args to be a table")
	assert(type(args.type) == "number", "expecting .type to be a number")
	local ptype = args.type
	if ptype == packet_type.PUBLISH and args.qos and args.qos > 0 then
		return true
	end
	return packets_requiring_packet_id[ptype]
end

-- Metatable for combined data packet, should looks like a string
local combined_packet_mt = {
	-- Convert combined data packet to string
	__tostring = function(self)
		local strings = {}
		for i, part in ipairs(self) do
			strings[i] = tostring(part)
		end
		return tbl_concat(strings)
	end,

	-- Get length of combined data packet
	len = function(self)
		local len = 0
		for _, part in ipairs(self) do
			len = len + part:len()
		end
		return len
	end,

	-- Append part to the end of combined data packet
	append = function(self, part)
		self[#self + 1] = part
	end
}

-- Make combined_packet_mt table works like a class
combined_packet_mt.__index = function(_, key)
	return combined_packet_mt[key]
end

--- Combine several data parts into one
-- @param combined_packet_mt/string ... any amout of strings of combined_packet_mt tables to combine into one packet
-- @return combined_packet_mt table suitable to append packet parts or to stringify it into raw packet bytes
function protocol.combine(...)
	return setmetatable({...}, combined_packet_mt)
end

-- Convert any value to string, respecting strings and tables
local function value_tostring(value)
	local t = type(value)
	if t == "string" then
		return str_format("%q", value)
	elseif t == "table" then
		local res = {}
		for k, v in pairs(value) do
			if type(k) == "number" then
				res[#res + 1] = value_tostring(v)
			else
				if k:match("^[a-zA-Z_][_%w]*$") then
					res[#res + 1] = str_format("%s=%s", k, value_tostring(v))
				else
					res[#res + 1] = str_format("[%q]=%s", k, value_tostring(v))
				end
			end
		end
		return str_format("{%s}", tbl_concat(res, ", "))
	else
		return tostring(value)
	end
end

--- Render packet to string representation
-- @param packet_mt packet table to convert to string
-- @return string human-readable string representation of the packet
function protocol.packet_tostring(packet)
	local res = {}
	for k, v in pairs(packet) do
		res[#res + 1] = str_format("%s=%s", k, value_tostring(v))
	end
	return str_format("%s{%s}", tostring(packet_type[packet.type]), tbl_concat(res, ", "))
end
local packet_tostring = protocol.packet_tostring

--- Parsed packet metatable
protocol.packet_mt = {
	__tostring = packet_tostring, -- packet-to-human-readable-string conversion metamethod using protocol.packet_tostring()
}

--- Parsed CONNACK packet metatable
protocol.connack_packet_mt = {
	__tostring = packet_tostring, -- packet-to-human-readable-string conversion metamethod using protocol.packet_tostring()
	reason_string = function(self) -- Returns reason string for the CONNACK packet according to its rc field
		return connack_rc[self.rc]
	end,
}
protocol.connack_packet_mt.__index = protocol.connack_packet_mt


--- Start parsing a new packet
-- @param function read_func - function to read data from the network connection
-- @return number packet_type
-- @return number flags
-- @return table input - a table with fields "read_func" and "available" representing a stream-like object
-- to read already received packet data in chunks
-- @return OR false and error_message on failure
function protocol.start_parse_packet(read_func)
	assert(type(read_func) == "function", "expecting read_func to be a function")
	local byte1, err, len, data

	-- parse fixed header
	-- DOC[v3.1.1]: http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/errata01/os/mqtt-v3.1.1-errata01-os-complete.html#_Toc442180832
	-- DOC[v5.0]: https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901020
	byte1, err = read_func(1)
	if not byte1 then
		return false, "failed to read first byte: "..err
	end
	byte1 = str_byte(byte1, 1, 1)
	local ptype = rshift(byte1, 4)
	local flags = band(byte1, 0xF)
	len, err = parse_var_length(read_func)
	if not len then
		return false, "failed to parse remaining length: "..err
	end

	-- create packet parser instance (aka input)
	local input = {1, available = 0} -- input data offset and available size
	if len > 0 then
		data, err = read_func(len)
	else
		data = ""
	end
	if not data then
		return false, "failed to read packet data: "..err
	end
	input.available = data:len()

	-- read data function for the input instance
	input.read_func = function(size)
		if size > input.available then
			return false, "not enough data to read size: "..size
		end
		local off = input[1]
		local res = str_sub(data, off, off + size - 1)
		input[1] = off + size
		input.available = input.available - size
		return res
	end

	return ptype, flags, input
end

--- Parse CONNECT packet with read_func
-- @param function read_func - function to read data from the network connection
-- @param[opt] number version - expected protocol version constant or nil to accept both versions
-- @return packet on success or false and error message on failure
function protocol.parse_packet_connect(read_func, version)
	-- DOC[v3.1.1]: 3.1 CONNECT – Client requests a connection to a Server
	-- DOC[v5.0]: 3.1 CONNECT – Connection Request
	local ptype, flags, input = protocol.start_parse_packet(read_func)
	if ptype ~= packet_type.CONNECT then
		return false, "expecting CONNECT (1) packet type but got "..ptype
	end
	if flags ~= 0 then
		return false, "expecting CONNECT flags to be 0 but got "..flags
	end
	return protocol.parse_packet_connect_input(input, version)
end

--- Parse CONNECT packet from already received stream-like packet input table
-- @param table input - a table with fields "read_func" and "available" representing a stream-like object
-- @param[opt] number version - expected protocol version constant or nil to accept both versions
-- @return packet on success or false and error message on failure
function protocol.parse_packet_connect_input(input, version)
	-- DOC[v3.1.1]: 3.1 CONNECT – Client requests a connection to a Server
	-- DOC[v5.0]: 3.1 CONNECT – Connection Request
	local read_func = input.read_func
	local err, protocol_name, protocol_ver, connect_flags, keep_alive

	-- DOC: 3.1.2.1 Protocol Name
	protocol_name, err = parse_string(read_func)
	if not protocol_name then
		return false, "failed to parse protocol name: "..err
	end
	if protocol_name ~= "MQTT" then
		return false, "expecting 'MQTT' as protocol name but received '"..protocol_name.."'"
	end

	-- DOC[v3.1.1]: 3.1.2.2 Protocol Level
	-- DOC[v5.0]: 3.1.2.2 Protocol Version
	protocol_ver, err = parse_uint8(read_func)
	if not protocol_ver then
		return false, "failed to parse protocol level/version: "..err
	end
	if version ~= nil and version ~= protocol_ver then
		return false, "expecting protocol version "..version.." but received "..protocol_ver
	end

	-- DOC: 3.1.2.3 Connect Flags
	connect_flags, err = parse_uint8(read_func)
	if not connect_flags then
		return false, "failed to parse connect flags: "..err
	end
	if band(connect_flags, 0x1) ~= 0 then
		return false, "reserved 1st bit in connect flags are set"
	end
	local clean = (band(connect_flags, 0x2) ~= 0)
	local will = (band(connect_flags, 0x4) ~= 0)
	local will_qos = band(rshift(connect_flags, 3), 0x3)
	local will_retain = (band(connect_flags, 0x20) ~= 0)
	local password_flag = (band(connect_flags, 0x40) ~= 0)
	local username_flag = (band(connect_flags, 0x80) ~= 0)

	-- DOC: 3.1.2.10 Keep Alive
	keep_alive, err = parse_uint16(read_func)
	if not keep_alive then
		return false, "failed to parse keep alive field: "..err
	end

	-- continue parsing based on the protocol_ver

	-- preparing common connect packet fields
	local packet = {
		type = packet_type.CONNECT,
		version = protocol_ver,
		clean = clean,
		password = password_flag, -- NOTE: will be replaced
		username = username_flag, -- NOTE: will be replaced
		keep_alive = keep_alive,
	}
	if will then
		packet.will = {
			qos = will_qos,
			retain = will_retain,
			topic = "", -- NOTE: will be replaced
			payload = "", -- NOTE: will be replaced
		}
	end
	if protocol_ver == mqtt.v311 then
		return NPL.load("./mqtt_protocol4.lua")._parse_packet_connect_continue(input, packet)
	elseif protocol_ver == mqtt.v50 then
		return NPL.load("./mqtt_protocol5.lua")._parse_packet_connect_continue(input, packet)
	else
		return false, "unexpected protocol version to continue parsing: "..protocol_ver
	end
end
