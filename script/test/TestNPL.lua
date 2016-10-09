--[[
Author: Li,Xizhi
Date: 2007-3-1
Desc: testing NPL related functions.
-----------------------------------------------
NPL.load("(gl)script/test/TestNPL.lua");
TestNPL.Run("dir \n svn info")
-----------------------------------------------
]]
NPL.load("(gl)script/ide/UnitTest/luaunit.lua");

local TestNPL = commonlib.gettable("TestNPL");

function TestNPL.TestSerialization()
	local o = {a=1, b="string"};
	-- serialize to string
	local str = commonlib.serialize_compact(o)
	-- write string to log.txt
	log(str); 
	-- string to NPL table again
	local o = NPL.LoadTableFromString(str);
	-- echo to output any object to log.txt
	echo(o); 
end

function TestNPL.TestFormatting()
	log(string.format("succeed: test case %.3f for %s\r\n", 1/3, "hello"));
	-- format is faster than string.format, but only support limited place holder like %s and %d. 
	log(format("succeed: test case %d for %s\r\n", 1, "hello"));
end

function Test_NPL_EncodeURLQuery()
	commonlib.echo(NPL.EncodeURLQuery("http://www.paraengine.com", {"name1", "value1", "name2", "ÖÐÎÄ",}))
end

-- tested on 2007.3.1, LiXizhi
local function OutputResult(i, name, bSuc)
	if(bSuc) then
		log(string.format("succeed: test case %d for %s\r\n", i, name));
	else
		log(string.format("FAILED: test case %d for %s\r\n", i, name));
	end	
end

-- dump webservice result
function DumpWSResult(str)
	if(msg == nil) then
		log(str.." has WS callback: nil \r\n");
	else
		log(str.." has WS callback:"..commonlib.serialize(msg).."\r\n");
	end	
end

local function SCodeSafetyTest()
	local i, bSuc=0, nil;
	
	bSuc = NPL.IsSCodePureData([[
msg={viewbox={pos_y=-0.655,pos_x=258.918,},type=1.000,scale=1.771,}
	]]);
	OutputResult(i, "SCodeSafetyTest", bSuc);i=i+1;
	
	bSuc = NPL.IsSCodePureData([[
msg = {a=12};
	]]);
	OutputResult(i, "SCodeSafetyTest", bSuc);i=i+1;
	
	
	bSuc = NPL.IsSCodePureData("msg = {[1]=[[OK]], [\"stringkey\"]=\"stringvalue\", truevalue=true, nilvalue = nil,};");
	OutputResult(i, "SCodeSafetyTest", bSuc);i=i+1;
	
	bSuc = not NPL.IsSCodePureData([[
msg = {func=function end,};
	]]);
	OutputResult(i, "SCodeSafetyTest", bSuc);i=i+1;
	
	bSuc = not NPL.IsSCodePureData([[
msg1 = "string";
	]]);
	OutputResult(i, "SCodeSafetyTest", bSuc);i=i+1;
	
	bSuc = NPL.IsSCodePureData([[
msg = 1;
	]]);
	OutputResult(i, "SCodeSafetyTest", bSuc);i=i+1;
	
end

-- tested on 2007.3.2, LiXizhi
local function WebserviceMessageTest()
	NPL.load("(gl)script/ide/commonlib.lua");
	local msg = {
		a=[[b"\\hi"<a>x</a>]], 
		b=21.123, 
		tablein = {x=4, asd="ssd",},
		c=false, [0]=21.0, ["asd"]=""
	};
	local address = "http://localhost:1979/WebServiceSite/NPLWebServiceProxy.asmx";
	NPL.RegisterWSCallBack(address, [[log("WS callback:"..commonlib.serialize(msg).."\r\n");]]);
	NPL.activate(address, msg);
	
	-- testing single message
	local msg = 21
	NPL.activate(address, msg);
	
	-- testing nil, string is not allowed"
	local msg = "just a string"
	NPL.activate(address, msg);
	
	-- testing string in string
	local msg = [[msg = "oked"]];
	NPL.activate(address, msg);
	
	log("WebserviceMessageTest passed.\r\n");
end

-- tested on 2007.3.23, LiXizhi
local function GetIPTest()
	local RootSite = "http://localhost:1979/WebServiceSite/";
	-- local RootSite = "http://www.kids3dmovie.com/";
	local address = RootSite.."GetIP.asmx";
	
	NPL.load("(gl)script/ide/commonlib.lua");
	
	-- test SetIP of a name
	NPL.RegisterWSCallBack(address, [[DumpWSResult("SetIP of LiXizhi");]]);
	NPL.activate(address, {op="set", username = "LiXizhi", password = "1234567", gameserver = "lxz_game", spaceserver="lxz_space"});
	
	-- test GetIP of a valid name
	NPL.RegisterWSCallBack(address, [[DumpWSResult("GetIP of LiXizhi");]]);
	NPL.activate(address, {op="get", username = "LiXizhi"});
	
	-- test GetIP of a invalid name
	NPL.RegisterWSCallBack(address, [[DumpWSResult("GetIP of invalid_name");]]);
	NPL.activate(address, {op="get", username = "invalid_namesX"});
	
	-- test SetIP
	log("GetIPTest passed.\r\n");
end

local function TestBase64BinaryWithWebservice()
	local file = ParaIO.open("temp/charequip.txt", "r");
	local test = {
		filedata = file,
	}
	log(NPL.SerializeToSCode("msg", test).."\n\n");
	file:close();
end


-- tested on 2007.6.5, LiXizhi
local function TestNPLDownloader()
	DownloadCallback = function ()
		NPL.load("(gl)script/ide/commonlib.lua");
		log(commonlib.serialize(msg));
	end;
	
	log("Testing downloading...\n");
	NPL.AsyncDownload("http://www.kids3dmovie.com/uploads/LiXizhi/auto2.jpg", "temp/renamed.jpg", "DownloadCallback()", "test1");
	--NPL.AsyncDownload("http://www.invalidURL.com/invalidURL.jpg", "c:\\temp", "DownloadCallback()", "test1");
end	

-- tested on 2007.6.5, LiXizhi
local function TestNPLSyncFile()
	DownloadCallback = function ()
		NPL.load("(gl)script/ide/commonlib.lua");
		log(commonlib.serialize(msg));
	end;
	log("Testing downloading...\n");
	
	NPL.load("(gl)script/ide/NPLExtension.lua");
	NPL.SyncFile("http://www.kids3dmovie.com/uploads/LiXizhi/auto2.jpg?CRC32=507094163", "temp\\renamed.jpg", "DownloadCallback()", "test1");
end


local function IsPureData()
	assert(NPL.IsPureData([[
		{"string1", "string2\r\n", 213, nil,["A"]="B", true, false, {"another table", "field1"}}
	]]))
	log("NPL.IsPureData test succeed\n")
end

-- IsPureData();
--WebserviceMessageTest();
--SCodeSafetyTest();
--GetIPTest();
-- TestNPLDownloader();
--TestNPLSyncFile();

function TestNPL_OnTimer()
	commonlib.log("ping: gametime:%s, systime: %s\n",tostring(ParaGlobal.GetGameTime()), tostring(ParaGlobal.timeGetTime()))
end

-- test NPL timer
function TestNPL_Timer()
	commonlib.log("NPL.SetTimer: "..tostring(ParaGlobal.GetGameTime()).."\n")
	local id = 1001;
	NPL.SetTimer(id, 1, ";TestNPL_OnTimer();")
	NPL.ChangeTimer(id, 5000, 1000)
end

function TestNPL_LoadTableFromString()
	commonlib.echo(NPL.LoadTableFromString([[{nid=10, name="value", tab={name1="value1"}}]]));
end

function TestNPL_FromJson()
	local json=[[{"name1":"value1","empty_array":[], "name3":null,"name2":[1,false,true,23.54,"a \u0015 string"]}]];
	local out = {};
	if(NPL.FromJson(json, out)) then
		commonlib.echo(out)
	end
end

function TestNPL_Logger()
	local logger = ParaGlobal.GetLogger("ServiceLog");
	logger:SetLevel(0);
	logger:log(0,"this is a test message1")
	logger:log(0,"this is a test message2")
	logger:log(1,"this is a test message3")
	logger:log(-1,"this is a test message4")
end

-- LiXizhi 2009.7.15: Currently works on both linux and windows in ParaEngineServer. However multiple states only works on linux. It seems to be a bug of mono embed in windows, especailly its garbage collector.
function TestNPL_NPLMono()
	-- NPL.activate("NPLMono.dll", nil);
	-- NPL.activate("NPLMonoInterface.dll/NPLMonoInterface.cs", {data = "C# mono dll test1"});
	--NPL.activate("NPLMonoInterface.dll/NPLMonoInterface.cs", {data = "C# mono dll test2"});
	--NPL.activate("NPLMonoInterface.dll/ParaMono.NPLMonoInterface.cs", {data = "C# mono dll test3"});
	--NPL.activate("NPLMonoInterface.dll/ParaMono.NPLMonoInterface.cs", {data = "C# mono dll test4"});
	
	-- push the first message to server
	local thread_count = 1;
	local i, nCount = nil, thread_count
	for i=1, nCount do
		local rts_name = "p"..i;
		local producer = NPL.CreateRuntimeState(rts_name, 0);
		producer:Start();
	end
	
	local k, kSize = nil, 1; -- math.floor(20/nCount);
	for k=1, kSize do
		local i, nCount = nil, thread_count
		for i=1, nCount do
			local rts_name = "p"..i;
			NPL.activate(string.format("(%s)NPLMonoInterface.dll/NPLMonoInterface.cs", rts_name), {rts_name=rts_name, counter=k});
		end	
	end	
end

-- 2009.9.24
function TestIPAddress()
	_guihelper.MessageBox(NPL.GetExternalIP());
end

-- 2009.9.25
function TestVirtualTimers()
	NPL.load("(gl)script/ide/timer.lua");
	
	-- normal timer
	local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		commonlib.applog(timer.id.." on timer\n")
	end})
	-- start the timer after 0 milliseconds, and signal every 1000 millisecond
	mytimer:Change(0, 5000)

	-- one time timer
	local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		commonlib.applog(timer.id.." One time timer\n")
	end})
	-- start the timer after 1000 milliseconds, and stop it immediately.
	mytimer:Change(1000, nil)

	-- one time timer
	local mytimer = commonlib.Timer:new({callbackFunc = function(timer)
		commonlib.applog(timer.id.." Kill Time timer\n")
		-- now kill the timer. 
		timer:Change()
	end})
	-- start the timer after 1000 milliseconds, and stop it immediately.
	mytimer:Change(0, 30)
end	

TestNPLEvents = {} --class

function TestNPLEvents:setUp()
end

function TestNPLEvents.NPLEventCallback()
	commonlib.applog(commonlib.serialize(msg))
end

function TestNPLEvents:test_Events()
	NPL.RegisterEvent(0, "testnetwork", "script/test/TestNPL.lua;TestNPLEvents.NPLEventCallback()")
	NPL.UnregisterEvent(0, "testnetwork")
	NPL.RegisterEvent(0, "testnetwork", "script/test/TestNPL.lua;TestNPLEvents.NPLEventCallback()")
end

function TestNPLEvents:test_Stats()
	local stats = NPL.GetStats({connection_count = true, nids_str=true, nids = true});
	
	log("TestNPLEvents:test_Stats is called\n")
	commonlib.echo(stats);
end

function Test_fast_double_to_string()
	local i;
	for i=-2,2, 0.001 do
		log(format("%f", i).."\n");
	end
end

function TestNPL.TestCPPReturnValue()
	local nTime = ParaGlobal.GetGameTime();
	nTime = nTime+1;
	echo(nTime);
	nTime = nTime+1;
end

-- run command line
-- @param cmd: any command lines, such as "dir \n svn info"
-- @param waitSec: how many seconds to wait
function TestNPL.Run(cmd, waitSec)
	-- write command script to a temp file and redirect all of its output to another temp file
	local cmd_filename = "temp/temp.bat";
	local output_filename = "temp/temp.txt";
	local cmd_fullpath = ParaIO.GetWritablePath()..cmd_filename;
	local output_fullpath = ParaIO.GetWritablePath()..output_filename;
	ParaIO.DeleteFile(output_filename)
	local file = ParaIO.open(cmd_filename, "w");
	if(file:IsValid()) then
		file:WriteString(format([[
@echo off
call :sub >%s
exit /b
:sub
]], output_fullpath));
		file:WriteString(cmd);
		file:close();
	end	
	
	ParaGlobal.ShellExecute("open", cmd_fullpath, cmd_fullpath, "", 1);

	if(waitTime~=0) then
		ParaEngine.Sleep(waitTime or 1);
	end

	-- get output
	local stdout_text = nil;
	local file = ParaIO.open(output_filename, "r");
	if(file:IsValid()) then
		stdout_text = file:GetText();
		file:close();
	end

	-- output to log.txt
	if(stdout_text and stdout_text~="") then
		commonlib.log(stdout_text);
	end
	return stdout_text;
end

-- compress/decompress test
function TestNPL.Compress()
	-- using gzip
	local content = "abc";
	local dataIO = {content=content, method="gzip"};
	if(NPL.Compress(dataIO)) then
		echo(dataIO);
		if(dataIO.result) then
			dataIO.content = dataIO.result; dataIO.result = nil;
			if(NPL.Decompress(dataIO)) then
				echo(dataIO);
				assert(dataIO.result == content);
			end
		end
	end

	-- using zlib and deflate
	local content = "abc";
	local dataIO = {content=content, method="zlib", windowBits=-15, level=3};
	if(NPL.Compress(dataIO)) then
		echo(dataIO);
		if(dataIO.result) then
			dataIO.content = dataIO.result; dataIO.result = nil;
			if(NPL.Decompress(dataIO)) then
				echo(dataIO);
				assert(dataIO.result == content);
			end
		end
	end
end



local function activate()
	commonlib.applog(commonlib.serialize(msg))
	-- test return value
	return 100;
end
NPL.this(activate)

-- select test suite to run
-- LuaUnit:run("TestNPLEvents")
-- TestBase64BinaryWithWebservice()