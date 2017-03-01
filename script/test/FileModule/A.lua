--[[
Author: Li,Xizhi
Date: 2017-2-26
Desc: test Module Cyclic Reference
-----------------------------------------------
-----------------------------------------------
]]
local B = NPL.load("./B.lua")
local A = NPL.export();
function A.print(s)
	B.print(s)
end
