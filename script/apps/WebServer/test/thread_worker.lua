--[[
Title: example of npl_script_handler
Author: LiXizhi
Date: 2015/6/9
Desc: Unlike standard NPL activation, this file is protected by webserver configuration. 
It is possible to configure this file to run in multiple NPL threads to reduce server load. 
-----------------------------------------------
NPL.load("(gl)script/apps/WebServer/test/helloworld.lua");
-----------------------------------------------
]]

local function run(req, res)
	-- test cookie
	local num = tonumber(req:get_cookie("counter") or 0);
	res:set_cookie("counter", num + 1);
	
	local num2 = tonumber(req:get_cookie("testcookie") or 0);
	res:set_cookie("testcookie", { 
		value = num2 + 1, 
		expires = os.time() + 1200, 
		path = "/;HttpOnly"
	});
	
	res:sendsome(format("<html><body>hello world threaded! %d, %d</body></html>", num, num2));
	
	res:finish();
end

local function activate()
	LOG.std(nil, "info", "thread_worker", msg); 
	local req = WebServer.request:new():init(msg);
	run(req, req.response);
end
NPL.this(activate);