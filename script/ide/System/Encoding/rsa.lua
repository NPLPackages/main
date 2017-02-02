--[[
Title: RSA encryption and decryption library in pure Lua
Author(s): LiXizhi
Desc: 
Note current implementation is slow for big exponent, such as during decoding. 
## More Information on RSA
- http://www.di-mgt.com.au/rsa_alg.html

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Encoding/rsa.lua");
local Encoding = commonlib.gettable("System.Encoding");
-- use `ssh-keygen -t rsa -b 4096 -C "your_email@example.com"` to generate one
local rsakey = Encoding.RSAKey:new():SetSSHPublicKey("ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/rPFkyJQSnJRNa/wnmNagqkSSYCW7ZEB4Oxsvc8SCHdzXB8K2R3/RK6XcZ2wmb2ycIttd364i653WyULL6B7CKIVjWaiQNw0OnG6gwokearDw1e0PNRndmnbIFrs5CcACS8HARmrAizVxg/Tu46UTM/0X1ZepviF694GwO8FieHAczoCS7yDlKvSBc3go54B8+7VG8uy/DDSYTbBHkFHQhuPV94uxp18UqcShXTrzOqsKeaJvQf2OkQi46htVO3smbBs91Sy/jD/b1NCb2pKq/qDoz0bsRF/VWarQbagUBLpXdTPlqtxBGFbWV6GnqoMNGWMj1fgErRqvGSKj5ClhiyUa7q8RamJ9zSKOjdBwNx/0p8vBNf4ERDlP5BBGJfpkudWD5iukhTIZOWqFNXz3qg5xg4meOTxDOlJpmOuOF5is+wvwP9DXAsneDGgMbqzA6WALfGOIwv3FiiNm8eIrxqo9g0pAPBJDKahLDtms1r9gB+DpoAKk2m8MQBc8EvZZWieYG8uC3EZcoKXloDdcTvxCcM49VP2YGA8dGXf86AhVXIkSjGkce+R4AtXaSdCDK6ODd1hS8bZKqJ9sDRePkuNbDXp+Xz728+LYIUwqEDMQbhfb9VtfTxaxsDOR2e1W9QkMD5iy0Mmx+AwaDLnp9oBRLn4+1lz6WyHAPZPDqw== your_email@example.com")
echo(Encoding.base64(rsakey:Encode("hello"))); -- any binary data or text

local rsakey = Encoding.RSAKey:new():SetPEMPublicKey("-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCDuT7xILG8uC1op2XwppqHbsz0\n6bMKKupXboY/T3QPE3D6uSNls/uojdyQ8sps8yfwcsR5AotmsLkzZFqyu0egSZ8P\nU0UUz7D91yIfNIQrUmo4XZ0r+XzKQjfGMjx5/c2gT/SaWn7pgyWopfUsgPI/1b50\nG7T8yow3NXsHQt4LzQIDAQAB\n-----END PUBLIC KEY-----");
echo(Encoding.base64(rsakey:Encode("hello")));

-- this may take 30 seconds due to big decoding exponent
local rsakey = Encoding.RSAKey:new():SetPEMPrivateKey("-----BEGIN RSA PRIVATE KEY-----\nMIICWgIBAAKBgGJPxUXU8Xpg/qAauL6Lv6DGo8itOatjSoyah/PC7g/tBXIoYTGD\nn9JmudYylC4P4maGa1pDqH8dYI5WTk2pX7DWBoo7iDePE0DuNuX+Q+o/Z9rT7AIS\nSRElwA+v6OfsCv77NQx6zDOx8bX0G1h1iEBUhE4I5ZkAKis90xFtfVeXAgMBAAEC\ngYA/WVOu+dZYm2O320AsWHS0rwse5rCAhcyl6XWtV3B7hqm5s9ddRomX1GXvZkwh\nmk6y7e8DDRHoRw/O6EIwvPFRfxJV3SsH8sPY/et0IgzwTi05FFDUBArJGst79KTl\nmo07zbVjx+p9pfVH5Z+1yBp2bdTBanVxmD8VOGNbLk1g8QJBAKW8G126w9fXU1Gs\nIQUDgTWB4f1DmgU2ykckgqBp3I3UYEdtbOJvLm8coafxsN4uDH9DhBHJ1PnmW54y\nkPDjzOUCQQCX2w46diPFUtHlsjJV+3JFPIfFqRI+YAu+MkXnTL12RktRuZ+J7AO+\nKj1eUJnOqTMj4fiWTfih+4SzLfr9kobLAkBfI4V+H7lOzQ/KQYpO630fryiAj275\n8ULa5g2KclqmnDSMrDcmIPbB1+jAlNCYKk0IPUSyRW9Z6S/Mt3BWqB41AkAf+nBX\nnVNRFWzAKzNwaeAZdnK9DCqcWgt/BQU1fTKUup7X2fgfykTLggekWeLZ40Wys75u\noILQUbATL4agaX/bAkB4PCdzr2vXNuDxqUJavPsk+6vbKh6jx2Hw5DJpuEJ5Tz2I\n/PDccoEJb+nsuPMIpklsW2n9ay2EOl+pQeH/xkhm\n-----END RSA PRIVATE KEY-----");
assert(rsakey:Decode(rsakey:Encode("hello")) == "hello");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/System/Encoding/bigint.lua");
local bigint = commonlib.gettable("System.Encoding.bigint");
local Encoding = commonlib.gettable("System.Encoding");
local binary_to_stringnumber = commonlib.gettable("System.Encoding.binary_to_stringnumber");
local bigint_to_stringbinary = commonlib.gettable("System.Encoding.bigint_to_stringbinary");

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

function RSAKey:SetPrivate(n, public_e, private_e)
	self.n = bigint(n);
	self.e = bigint(public_e);
	self.private_e = bigint(private_e);
	return self;
end

local bigZero = bigint(0)
local bigOne = bigint(1)

local function modexp(base, exponent, modulus)
	local r = bigint(1);
	--echo("1111111")
	--local from = ParaGlobal.timeGetTime();
	while true do
		if exponent % 2 == bigOne then
			r =(r * base) % modulus
		end
		exponent = exponent / 2
		
		if exponent == bigZero then
			break
		end
		base = base * base % modulus;
		--local cur = ParaGlobal.timeGetTime();
		--echo({cur-from})
	end
	return r
end


-- in real world, we need to use a random session key with random padding text. 
-- Note current implementation is slow for big exponent, such as during decoding. 
-- @param msg: binary message data to encode
-- @return binary string output
function RSAKey:Encode(msg)
	return self:Crypt(msg, self.n, self.e);
end

-- similar to Encode, except that we use private_e (d or decoding exponent)
function RSAKey:Decode(msg)
	return self:Crypt(msg, self.n, self.private_e);
end

-- return (m^e) % n
-- @param m: message of binary string, 1 < m < n-1
-- @param n: modulus of bigint
-- @param e: exponent of bigint
function RSAKey:Crypt(m, n, e)
	if(m) then
		m = binary_to_stringnumber(m);
		local res = modexp(bigint(m), e, n);
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


-- @param publickey: RSA public key in PEM format
-- the key can begin with -----BEGIN RSA PUBLIC KEY----- or just its inner base64 text
function RSAKey:SetPEMPublicKey(publickey)
	local keytype, publickey2 = publickey:match("^%-+BEGIN (%w+)[^\r\n]+[\r\n]+(.*)");
	publickey = publickey:gsub("%-%-+[^\r\n]+[\r\n]+", "");
	publickey = publickey:gsub("[\r\n]+", "");
	local rawdata = Encoding.unbase64(publickey);
	if(rawdata) then
		local e, n;
		NPL.load("(gl)script/ide/System/Encoding/asn1.lua");
		local Encoding = commonlib.gettable("System.Encoding");
		local decoder = Encoding.asn1.ASN1Decoder:new()
		local pos, data = decoder:decode(rawdata, 1);
		if(data and data[1] and data[2]) then
			if(type(data[1]) ~= "table") then
				e = binary_to_stringnumber(data[2]);
				n = binary_to_stringnumber(data[1]);
				-- echo({e,n})
				self:SetPublic(e, n);
			elseif(type(data[2]) == "string") then
				local data = data[2];
				if(data:byte(1, 1) == 0) then
					data = data:sub(2, -1);
				end
				-- for an RSA public key, the OID is 1.2.840.113549.1.1.1 and there is a RSAPublicKey as the PublicKey key data bitstring.
				local pos, data = decoder:decode(data, 1);
				if(data and data[1] and data[2]) then
					if(type(data[1]) ~= "table") then
						e = binary_to_stringnumber(data[2]);
						n = binary_to_stringnumber(data[1]);
						-- echo({"11111111", e, n})
						self:SetPublic(e, n);
					end
				end
			end
		end
	end
	return self;
end

-- private key that begins with "-----BEGIN RSA PRIVATE KEY-----"
function RSAKey:SetPEMPrivateKey(publickey)
	local keytype, publickey2 = publickey:match("^%-+BEGIN (%w+)[^\r\n]+[\r\n]+(.*)");
	publickey = publickey:gsub("%-%-+[^\r\n]+[\r\n]+", "");
	publickey = publickey:gsub("[\r\n]+", "");
	local rawdata = Encoding.unbase64(publickey);
	if(rawdata) then
		NPL.load("(gl)script/ide/System/Encoding/asn1.lua");
		local Encoding = commonlib.gettable("System.Encoding");
		local decoder = Encoding.asn1.ASN1Decoder:new()
		local pos, data = decoder:decode(rawdata, 1);
		if(data and #data > 3) then
			self.binary_n = data[2];
			local n = binary_to_stringnumber(self.binary_n);
			local public_e = binary_to_stringnumber(data[3]);
			local private_e = binary_to_stringnumber(data[4]);
			-- echo({n, public_e, private_e});
			self:SetPrivate(n, public_e, private_e);
		end
	end
	return self;
end
