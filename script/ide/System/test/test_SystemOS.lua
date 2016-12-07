--[[
Title: test System.os
Author(s): LiXizhi
Date: 2015/4/21
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/test/test_SystemOS.lua");
local test_SystemOS = commonlib.gettable("System.Core.Test.test_SystemOS");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/System.lua");
-- define a new class
local test_SystemOS = commonlib.gettable("System.Core.Test.test_SystemOS");

function test_SystemOS:TestSendEmail()
	-- The following uses enterprise email service from qq
	System.os.SendEmail({
		url="smtp://smtp.exmail.qq.com", 
		username="lixizhi@paraengine.com", password="XXXX", 
		-- ca_info = "/path/to/certificate.pem",
		from="lixizhi@paraengine.com", to="lixizhi@yeah.net", cc="xizhi.li@gmail.com", 
		subject = "title here",
		body = "any body content here. can be very long",
	}, function(err, msg) echo(msg) end);
end

function test_SystemOS:TestLinuxRunCommands()
	NPL.load("(gl)script/ide/System/System.lua");
	echo(System.os.run("ls -al | grep total\ngit | grep commit"));

	-- async run command in worker thread
	for i=1, 10 do
		System.os.runAsync("dir", function(err, result)   echo(result)  end);
	end
	echo("waiting run async reply ...")
end