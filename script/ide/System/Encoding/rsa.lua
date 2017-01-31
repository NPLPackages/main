--[[
Title: RSA encryption and decryption library in pure Lua
Author(s): LiXizhi
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Encoding/rsa.lua");
local Encoding = commonlib.gettable("System.Encoding");
-- use `ssh-keygen -t rsa -b 4096 -C "your_email@example.com"` to generate one
local rsakey = Encoding.RSAKey:new():SetSSHPublicKey("ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/rPFkyJQSnJRNa/wnmNagqkSSYCW7ZEB4Oxsvc8SCHdzXB8K2R3/RK6XcZ2wmb2ycIttd364i653WyULL6B7CKIVjWaiQNw0OnG6gwokearDw1e0PNRndmnbIFrs5CcACS8HARmrAizVxg/Tu46UTM/0X1ZepviF694GwO8FieHAczoCS7yDlKvSBc3go54B8+7VG8uy/DDSYTbBHkFHQhuPV94uxp18UqcShXTrzOqsKeaJvQf2OkQi46htVO3smbBs91Sy/jD/b1NCb2pKq/qDoz0bsRF/VWarQbagUBLpXdTPlqtxBGFbWV6GnqoMNGWMj1fgErRqvGSKj5ClhiyUa7q8RamJ9zSKOjdBwNx/0p8vBNf4ERDlP5BBGJfpkudWD5iukhTIZOWqFNXz3qg5xg4meOTxDOlJpmOuOF5is+wvwP9DXAsneDGgMbqzA6WALfGOIwv3FiiNm8eIrxqo9g0pAPBJDKahLDtms1r9gB+DpoAKk2m8MQBc8EvZZWieYG8uC3EZcoKXloDdcTvxCcM49VP2YGA8dGXf86AhVXIkSjGkce+R4AtXaSdCDK6ODd1hS8bZKqJ9sDRePkuNbDXp+Xz728+LYIUwqEDMQbhfb9VtfTxaxsDOR2e1W9QkMD5iy0Mmx+AwaDLnp9oBRLn4+1lz6WyHAPZPDqw== your_email@example.com")
echo(Encoding.base64(rsakey:Encode("hello"))); -- any binary data or text

local rsakey = Encoding.RSAKey:new():SetPEMPublicKey("-----BEGIN RSA PUBLIC KEY-----\nMIGJAoGBAJNrHWRFgWLqgzSmLBq2G89exgi/Jk1NWhbFB9gHc9MLORmP3BOCJS9k\nonzT/+Dk1hdZf00JGgZeuJGoXK9PX3CIKQKRQRHpi5e1vmOCrmHN5VMOxGO4d+zn\nJDEbNHODZR4HzsSdpQ9SGMSx7raJJedEIbr0IP6DgnWgiA7R1mUdAgMBAAE=\n-----END RSA PUBLIC KEY-----");
echo(Encoding.base64(rsakey:Encode("hello")));
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/System/Encoding/bigint.lua");
local bigint = commonlib.gettable("System.Encoding.bigint");
local Encoding = commonlib.gettable("System.Encoding");


----------------------------
-- string conversion
----------------------------

-- e.g. binary_to_stringnumber("\255") == "255"
-- @param input: binary string
-- @param base: what is the base number that each byte in put represent. default to 256. 
-- @return string number
local function binary_to_stringnumber(input, base)
	if(type(input) == "number") then
		return tostring(input);
	end
	base = base or 256;
	local num = bigint(0)
	local bytes = {input:byte(1,-1)};
	for i = 1, #bytes do
		num = num * base + bytes[i];
	end
	return tostring(num)
end

-- @param num: bigint
-- @param base: default to 256. 
local function bigint_to_stringbinary(num, base)
	base = bigint(base or 256);
	local bytes = {};
	while(true) do
		if(num < base) then
			bytes[#bytes + 1] = string.char(tonumber(tostring(num)));
			break;
		else
			bytes[#bytes + 1] = string.char(tonumber(tostring(num % base)));
			num = num / base;
		end
	end
	return table.concat(bytes, "");
end

----------------------------
-- working with openssh rsa keys
----------------------------
NPL.load("(gl)script/ide/math/bit.lua");
local bit = mathlib.bit;

local function encodePrefix(body)
  if string.byte(body, 1) >= 128 then
    body = '\0' .. body
  end
  local len = #body
  return string.char(bit.band(bit.rshift(len, 24), 0xff))
      .. string.char(bit.band(bit.rshift(len, 16), 0xff))
      .. string.char(bit.band(bit.rshift(len, 8), 0xff))
      .. string.char(bit.band(len, 0xff))
      .. body
end

local function decodePrefix(input)
  local len = bit.bor(
    bit.lshift(string.byte(input, 1), 24),
    bit.lshift(string.byte(input, 2), 16),
    bit.lshift(string.byte(input, 3), 8),
               string.byte(input, 4))
  return string.sub(input, 5, 4 + len), string.sub(input, 5 + len)
end

-- Given a raw ssh-rsa key as a binary string, parse out e and n
-- For an ssh-rsa key, the PEM-encoded data is a series of (length, data) pairs. The length is encoded as four octets (in big-endian order). The values encoded are:
--   algorithm name (one of (ssh-rsa, ssh-dsa)). This duplicates the key type in the first field of the public key.
--   RSA exponent
--   RSA modulus
local function decode_ssh_rsa_key(input)
  local format, e, n
  format, input = decodePrefix(input)
  assert(format == "ssh-rsa")
  e, input = decodePrefix(input)
  n, input = decodePrefix(input)
  assert(input == "")
  return e, n;
end


-- Extract the raw data from a ssh public key file.
-- The OpenSSH public key format is fully documented RFC 4253. Briefly, an OpenSSH public key consists of three fields:
--   The key type
--   A chunk of PEM-encoded data
--   A comment
local function loadPublic(data)
  data = data:match("^ssh%-rsa ([^ ]+)")
  data = data and data:gsub("%s", "")
  return data and Encoding.unbase64(data)
end


----------------------------
-- RSA key class
----------------------------
local RSAKey = commonlib.inherit(nil, commonlib.gettable("System.Encoding.RSAKey"));

function RSAKey:SetPublic(e, n)
	self.n = bigint(n);
    self.e = bigint(e);
	return self;
end

local bigZero = bigint(0)
local bigOne = bigint(1)

local function modexp(base, exponent, modulus)
	local r = bigint(1);
	while true do
		if exponent % 2 == bigOne then
			r = (r * base) % modulus
		end
		exponent = exponent / 2

		if exponent == bigZero then
			break
		end
		base = base * base % modulus;
	end
	return r
end


-- @param msg: binary message data to encode
-- @return binary string output
function RSAKey:Encode(msg)
	if(msg) then
		msg = binary_to_stringnumber(msg);
		local res = modexp(bigint(msg), self.e, self.n);
		return bigint_to_stringbinary(res);
	end
end

-- @param publickey: this should be OpenSSH Public Key Format that must begin with ssh-rsa followed by base64 encoded data. 
-- The OpenSSH public key format is fully documented RFC 4253. Briefly, an OpenSSH public key consists of three fields:
--   The key type
--   A chunk of PEM-encoded data
--   A comment
function RSAKey:SetSSHPublicKey(publickey)
	local rawdata = loadPublic(publickey);
	if(rawdata) then
		local e, n = decode_ssh_rsa_key(rawdata);
		e = binary_to_stringnumber(e);
		n = binary_to_stringnumber(n);
		self:SetPublic(e, n);
	end
	return self;
end

-- @param publickey: RSA public key in PEM format + PKCS#1
-- the key should begin with -----BEGIN RSA PUBLIC KEY-----
function RSAKey:SetPEMPublicKey(publickey)
	local keytype;
	keytype, publickey = publickey:match("^%-+BEGIN (%w+)[^\r\n]+[\r\n]+(.*)");
	publickey = publickey:gsub("[\r\n]+(%-+[^\r\n]+[\r\n]*$", "");
	publickey = publickey:gsub("[\r\n]*", "");
	local rawdata = Encoding.unbase64(publickey);
	if(rawdata) then
		local e,n;
		-- n, e separated by \0
		NPL.load("(gl)script/ide/System/Encoding/asn1.lua");
		local Encoding = commonlib.gettable("System.Encoding");
		local decoder = Encoding.asn1.ASN1Decoder:new()
		local pos, data = decoder:decode(rawdata, 1);
		if(type(data) == "table" and data[1] and data[2]) then
			e = binary_to_stringnumber(data[2]);
			n = binary_to_stringnumber(data[1]);
			-- echo({e,n})
			self:SetPublic(e, n);
		elseif(type(data) == "string") then
			-- for an RSA public key, the OID is 1.2.840.113549.1.1.1 and there is a RSAPublicKey as the PublicKey key data bitstring.
			
		end
	end
	return self;
end
