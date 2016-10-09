--[[
Author: Li,Xizhi
Date: 2014-7-29
Desc: testing NPL related functions.
-----------------------------------------------
NPL.load("(gl)script/test/TestNPLMono.lua");
Test_NPL_Mono();
Test_NPL_Mono_WinForm();
-----------------------------------------------
]]


function Test_NPL_Mono()
	NPL.activate("NPLMonoInterface.dll/NPLMonoInterface.cs", {data="test NPLMonoInterface"});
	NPL.CreateRuntimeState("db1", 0):Start();
	NPL.activate("(db1)NPLMonoInterface.dll/NPLMonoInterface.cs", {data="test from another thread"});
end


function Test_NPL_Mono_WinForm()
	NPL.CreateRuntimeState("ui", 0):Start();
	NPL.activate("(ui)SampleMonoWinForm.dll/SampleMonoWinForm.MainWindow.cs", {});
end

local function activate()
	echo("====================")
	echo(msg);
	if(msg and msg.uimsg) then
		_guihelper.MessageBox(msg.uimsg);
	end
end
NPL.this(activate)
