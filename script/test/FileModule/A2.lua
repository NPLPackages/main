--[[
Author: Li,Xizhi
Date: 2017-2-26
Desc: testing NPL related functions.
-----------------------------------------------
NPL.load("(gl)script/test/TestNPLLoad.lua"):print();
-----------------------------------------------
]]
-- file module test with cyclic dependency. 
local TestNPL = NPL.load("./TestNPL.lua");
local TestNPLLoad = NPL.export();

function TestNPLLoad:print()
	echo( self:GetName() .. TestNPL:GetName() );
end

function TestNPLLoad:GetName()
	return "TestNPLLoad";
end

