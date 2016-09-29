--[[
Title: Postgre SQL interface
Author(s): luasql ported to NPL by LiXizhi. 
Date: 2013/1/31
Desc: Please install mysql client first, see here
https://github.com/LiXizhi/luasql

Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/mysql/postgresql.lua");
local postgresql = commonlib.getfield("commonlib.postgresql");
-------------------------------------------------------
]]
commonlib.setfield("commonlib.postgresql", require("luasql.postgres"));

