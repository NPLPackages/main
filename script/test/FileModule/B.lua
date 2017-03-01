--[[
Author: Li,Xizhi
Date: 2017-2-26
Desc: test Module Cyclic Reference
-----------------------------------------------
-----------------------------------------------
]]
local A = NPL.load("./A.lua")
local B = NPL.export();
function B.print(s)
  echo(s..type(A));
end