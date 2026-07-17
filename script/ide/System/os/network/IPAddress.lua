--[[
Title: ip address related
Author(s): LiXizhi
Date: 2021/11/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/os/network/IPAddress.lua");
local IPAddress = commonlib.gettable("System.os.network.IPAddress");
local external_ip = IPAddress.GetExternalIP()
IPAddress.IsPrivateIP(ip)
------------------------------------------------------------
]]
local IPAddress = commonlib.gettable("System.os.network.IPAddress");
-- check if IP is "intranet"
-- Class A: 10.x.x.x - 10.255.255.255 (CIDR - 10.0.0.0/8),255.0.0.0, 24 bit block
-- Class B: 172.16.x.x - 172.31.255.255 (CIDR - 172.16.0.0/12), 255.240.0.0, 20 bit block
-- Class C: 192.168.x.x - 192.168.255.255 (CIDR - 172.16.0.0/16), 255.255.0.0, 16 bit block
-- Class D: 127.0.x.x
-- @param ip: string like "127.0.0.1"
-- @return true if it is private ip
function IPAddress.IsPrivateIP(ip)
	if(ip) then
		local num1, num2 = ip:match("^(%d+)%.(%d+)");
		if(num2) then
			num1 = tonumber(num1)
			num2 = tonumber(num2)
			if( (num1 == 192 and num2 == 168) or (num1 == 127 and num2 == 0) or (num1 == 10) or (num1 == 172 and (num2 >= 16 and num2 <= 31))) then
				return true;
			end
		end
	end
end

function IPAddress.GetBrodcastIps()
	local att = NPL.GetAttributeObject();
	local broadcast_address_list = att:GetField("BroadcastAddressList");
    broadcast_address_list = commonlib.split(broadcast_address_list, ",");
	if System.os.GetPlatform() == "android" then
		local ip_address = ParaEngine.GetAttributeObject():GetField("MaxIPAddress","")

		local ipNums = commonlib.split(ip_address,".")
		local broadcast_address = ipNums[1].."."..ipNums[2].."."..ipNums[3]..".255"
		table.insert(broadcast_address_list, 1, broadcast_address)
	end
	return broadcast_address_list
end

function IPAddress.GetExternalIP()
	local external_ip = NPL.GetExternalIP()
	if System.os.GetPlatform() == "android" then
		local ip_address = ParaEngine.GetAttributeObject():GetField("MaxIPAddress","") 
		if ip_address and ip_address ~= "" then
			external_ip = ip_address
		end
	end
	return external_ip
end

function IPAddress.ExternalIPList()
	local att = NPL.GetAttributeObject();
	local ipList = att:GetField("ExternalIPList")
	ipList = commonlib.split(ipList, ",")
	if System.os.GetPlatform() == "android" then
		local ip_address = ParaEngine.GetAttributeObject():GetField("MaxIPAddress","")
		table.insert(ipList, 1, ip_address)
	end
	return ipList
end

