--[[
Title: test MySQL interface
Author(s): 
Date: 2013/1/31
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/mysql/test/test_mysql.lua");
local tests = commonlib.gettable("commonlib.mysql.tests");
tests.GeneralTest()
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/mysql/mysql.lua");
local luasql = commonlib.luasql;

local tests = commonlib.gettable("commonlib.mysql.tests");

function tests.GeneralTest()
	
end