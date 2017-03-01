--[[
Author: Li,Xizhi
Date: 2017-2-26
Desc: testing NPL related functions.
-----------------------------------------------
NPL.load("(gl)script/test/FileModule/TestNPLLoad.lua")
test_FileModule_CyclicDependency()
test_Delayed_file_export()
-----------------------------------------------
]]


function test_FileModule_CyclicDependency()
	local A = NPL.load("./A.lua")
	A.print("test") -- output testtable
end

function test_Delayed_file_export()
	assert(NPL.filename() == debug.getinfo(1, "S").source)
	local TestNPLLoad = NPL.export();
	TestNPLLoad.name = "TestNPLLoad"; 
	assert(NPL.export().name == TestNPLLoad.name);
end