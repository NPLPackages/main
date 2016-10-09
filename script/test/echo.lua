--[[
Title: usually used for testing NPL.activate 
Author: LiXizhi
Date: 2014-1-25
Desc: 
-----------------------------------------------
NPL.load("(gl)script/test/echo.lua");
-----------------------------------------------
]]

local function activate()
	echo("================test.echo================")
	echo(msg);
end

NPL.this(activate)