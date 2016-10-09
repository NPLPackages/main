--[[
Author: Li,Xizhi
Date: 2013-5-5
Desc: testing NPL related functions.
-----------------------------------------------
NPL.load("(gl)script/test/TestIPCDebugger.lua");
tests.TestIPCDebugger.TestReturnFunctionStackLevel();
-----------------------------------------------
]]
NPL.load("(gl)script/ide/UnitTest/luaunit.lua");
NPL.load("(gl)script/ide/STL.lua");

local TestIPCDebugger = commonlib.gettable("tests.TestIPCDebugger");

local function ReturnStackFunctions()
	return 1,2,3;
end

function TestIPCDebugger.TestReturnFunctionStackLevel()
	local function B()
		log("b1\n")
		return 1;
	end
	local function A()
		log("a1\n")
		return B();
	end
	
	log("1\n")
	A();
	log("2\n")
	echo("can not step here");
end

