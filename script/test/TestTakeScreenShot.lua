--[[
Author: leio
Date: 2016/8/9
Desc: 
-----------------------------------------------
NPL.load("(gl)script/test/TestTakeScreenShot.lua");
local TestTakeScreenShot = commonlib.gettable("TestTakeScreenShot");
TestTakeScreenShot.TakeShot_1("test/test_takescreenshot_1.png");
TestTakeScreenShot.TakeShot_2("test/test_takescreenshot_2.png");
TestTakeScreenShot.TakeShot_3("test/test_takescreenshot_3.png",400,300);
TestTakeScreenShot.TakeShot_4("test/test_takescreenshot_4.png");
-----------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/timer.lua");
local TestTakeScreenShot = commonlib.gettable("TestTakeScreenShot");
function TestTakeScreenShot.Callback()
	commonlib.log("TestTakeScreenShot received a msg %s \n",commonlib.serialize(msg));
	local res = msg.res;
	local sequence = msg.s;
	local size = msg.size;
	local base64 = msg.base64;
end
function TestTakeScreenShot.TakeShot_1(filepath)
	filepath = filepath or "test/test_takescreenshot.png";
	ParaMovie.TakeScreenShot_Async(filepath,false, string.format("TestTakeScreenShot.Callback();%d",1));
end
function TestTakeScreenShot.TakeShot_2(filepath)
	filepath = filepath or "test/test_takescreenshot.png";
	ParaMovie.TakeScreenShot_Async(filepath,true, string.format("TestTakeScreenShot.Callback();%d",2));
end
function TestTakeScreenShot.TakeShot_3(filepath,w,h)
	w = w or 16;
	h = h or 16;
	filepath = filepath or "test/test_takescreenshot.png";
	ParaMovie.TakeScreenShot_Async(filepath,false, w, h, string.format("TestTakeScreenShot.Callback();%d",3));
end
function TestTakeScreenShot.TakeShot_4(filepath,w,h)
	filepath = filepath or "test/test_takescreenshot.png";
	w = w or 16;
	h = h or 16;
	ParaMovie.TakeScreenShot_Async(filepath,true,  w, h, string.format("TestTakeScreenShot.Callback();%d",4));
end
