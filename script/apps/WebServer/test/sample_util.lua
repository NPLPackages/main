--[[
Title: sample npl/lua file
Author: LiXizhi
Date: 2015/6/9
Desc: when loading npl/lua file in a page file, the file is only loaded once per application.
It is faster to use file based modules for shared logics, because it is NOT loaded per request. 
-----------------------------------------------
local sample_util = NPL.load("./sample_util.lua");
echo(sample_util:hello());
-----------------------------------------------
]]

local sample_util = NPL.export()

local load_time = ParaGlobal.timeGetTime();

function sample_util:hello()
	return "hello: sample_util.lua is loaded at time "..load_time;
end
