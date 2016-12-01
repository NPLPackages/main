--[[
Title: run command lines
Author(s): LiXizhi
Date: 2016/1/8
Desc: run command lines (windows batch or linux bash commands). 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/os/run.lua");
if(System.os.GetPlatform()=="win32") then
	-- any lines of windows batch commands
	echo(System.os("dir *.exe \n svn info"));
	-- this will popup confirmation window, so there is no way to get its result. 
	System.os.runAsAdmin('reg add "HKCR\\paracraft" /ve /d "URL:paracraft" /f');
else
	-- any lines of linux bash shell commands
	echo(System.os.run("ls -al | grep total\ngit | grep commit"));
end
-- async run command in worker thread
for i=1, 10 do
	System.os.runAsync("echo hello", function(err, result)   echo(result)  end);
end
echo("waiting run async reply ...")
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/ide/System/os/os.lua");
local os = commonlib.gettable("System.os");

local thisFileName = "script/ide/System/os/run.lua";
local thisThreadName = __rts__:GetName();

-- same as os.run(cmd);
setmetatable(os, { __call = function(self, ...) return os.run(...); end})

-- @param cmd: one or more lines of command
-- @param cmd_filename: default to "temp.bat" or "temp.sh"
-- @param output_filename: default to cmd_filename..".txt", if "", it will output to default standard output
-- @return the full path of the temp bat file and output file.
local function PrepareTempShellFile(cmd, cmd_filename, output_filename)
	if(os.GetPlatform()=="win32") then
		cmd_filename = cmd_filename or "temp.bat";
		if(not output_filename) then
			output_filename = cmd_filename..".txt";
		end
		local cmd_fullpath = ParaIO.GetWritablePath()..cmd_filename;
		local output_fullpath = ParaIO.GetWritablePath()..output_filename;
		ParaIO.DeleteFile(output_filename)
		ParaIO.CreateDirectory(cmd_filename);
		local file = ParaIO.open(cmd_filename, "w");
		if(file:IsValid()) then
			file:WriteString(format([[
@echo off
call :sub %s
exit /b
:sub
]], output_filename == "" and "" or format([[>"%%~dp0%s"]], output_filename:gsub(".+[/\\]", "")) ));
			file:WriteString(cmd);
			file:close();
		else
			LOG.std(nil, "warn", "os.run", "failed to create file at %s", cmd_filename);
		end
		return cmd_fullpath, output_fullpath, output_filename;
	else
		cmd_filename = cmd_filename or "temp.sh";
		if(not output_filename) then
			output_filename = cmd_filename..".txt";
		end
		local cmd_fullpath = ParaIO.GetWritablePath()..cmd_filename;
		local output_fullpath = ParaIO.GetWritablePath()..output_filename;
		ParaIO.DeleteFile(output_filename)
		ParaIO.CreateDirectory(cmd_filename);
		local file = ParaIO.open(cmd_filename, "w");
		if(file:IsValid()) then
			local content = format([[#!/bin/bash
subfunc() {
  %s
}
subfunc %s
]], cmd, output_filename == "" and "" or format([[> "`dirname \"$0\"`/%s"]], output_filename:gsub(".+[/\\]", "")) );
			-- convert to linux line ending
			content = content:gsub("\r\n", "\n");
			file:WriteString(content);
			file:close();

			-- chmod +x to make it executable
			local file = io.popen("chmod +x "..cmd_fullpath, 'r');
			if(file) then
				file:read("*all");
				file:close();
			end
		else
			LOG.std(nil, "warn", "os.run", "failed to create file at %s", cmd_filename);
		end
		return cmd_fullpath, output_fullpath, output_filename;
	end
end

local run_callbacks = {};
local next_run_id = 0;
-- same as os.run() except that it enqueues and runs in one or more separate worker thread. 
-- for long running task it is better to use os.runAsync instead of os.run
-- @param thread_name: default to "osAsync", any name is fine. 
-- @param callbackFunc: a callback function(err, result)  end
-- A new NPL thread with message queue will be created. all runAsync calls with the same `thread_name` will be processed 
-- by the same NPL thread from its message queue. 
-- e.g. 
--		System.os.runAsync("dir", function(err, result)   echo(result)  end);
function os.runAsync(cmd, callbackFunc, thread_name)
	thread_name = thread_name or "osAsync";
	NPL.CreateRuntimeState(thread_name, 0):Start();
	next_run_id = next_run_id + 1;
	run_callbacks[next_run_id] = callbackFunc;
	return NPL.activate(format("(%s)%s", thread_name, thisFileName), {type="run", cmd=cmd, callbackId = next_run_id, callbackAddress=format("(%s)%s", thisThreadName, thisFileName)});
end

local tempPrefix;
local function GetTempFilePrefix()
	if(not tempPrefix) then
		tempPrefix = "temp/"..thisThreadName.."_";
	end
	return tempPrefix;
end

-- run command line using default OS shell script.
-- @param cmd: any command lines (can be multiple lines), such as "dir \n svn info"
-- @param bPrintToLog: true to print to log file, default to false
-- @param bDeleteTempFile: true to delete temp file, default to false
-- @return text string returned by the cmd as if it is standard output.
function os.run(cmd, bPrintToLog, bDeleteTempFile)
	if(os.GetPlatform()=="win32") then
		-- window 32 desktop platform uses batch command line
		-- write command script to a temp file and redirect all of its output to another temp file

		local cmd_fullpath, output_fullpath, output_filename = PrepareTempShellFile(cmd, GetTempFilePrefix().."temp.bat");
		local stdout_text = nil;
		-- we will use ShellExecuteEx to wait for the process to terminate and then retrieve output. 
		if(ParaGlobal.ShellExecute("wait", cmd_fullpath, cmd_fullpath, "", 1)) then
			-- get output
			local file = ParaIO.open(output_filename, "r");
			if(file:IsValid()) then
				stdout_text = file:GetText();
				file:close();
			end
			ParaIO.DeleteFile(output_filename);

			-- output to log.txt
			if(bPrintToLog and stdout_text and stdout_text~="") then
				commonlib.log(stdout_text);
			end
		end
		if(bDeleteTempFile) then
			ParaIO.DeleteFile(cmd_filename);
		end
		return stdout_text;
	else
		-- linux bash shell
		local cmd_fullpath, output_fullpath, output_filename = PrepareTempShellFile(cmd, GetTempFilePrefix().."temp.sh");
		local stdout_text = nil;
		-- we will use popen(process open)
		local file = io.popen(cmd_fullpath, 'r');
		if(file) then
			local output = file:read('*all')
			file:close()
			-- get output
			local file = ParaIO.open(output_filename, "r");
			if(file:IsValid()) then
				stdout_text = file:GetText();
				file:close();
			end
			ParaIO.DeleteFile(output_filename);

			-- output to log.txt
			if(bPrintToLog and stdout_text and stdout_text~="") then
				if(bPrintToLog and output and output~="") then
					commonlib.log(output);
				end
				commonlib.log(stdout_text);
			end
		end
		if(bDeleteTempFile) then
			ParaIO.DeleteFile(cmd_filename);
		end
		return stdout_text;
	end
end

-- run as administrator. only works on windows, tested on win10. 
-- it will pop up a dialog asking for permission. 
-- @return please note, since another process is created. this function does not return the output of the command
-- and this function may return before the command is finished. 
function os.runAsAdmin(cmd, bPrintToLog, bDeleteTempFile)
	if(os.GetPlatform()=="win32") then
		local cmd_filename = "temp.bat";
		local cmd_fullpath, output_fullpath, output_filename = PrepareTempShellFile(cmd, cmd_filename);
	
		cmd_fullpath = cmd_fullpath:gsub("/", "\\")
		
		local cmd_admin = [[
@echo off

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
IF '%PROCESSOR_ARCHITECTURE%' EQU 'amd64' (
	>nul 2>&1 "%SYSTEMROOT%\SysWOW64\icacls.exe" "%SYSTEMROOT%\SysWOW64\config"
	) ELSE (
	>nul 2>&1 "%SYSTEMROOT%\system32\icacls.exe" "%SYSTEMROOT%\system32\config"
)

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
	echo Requesting administrative privileges...
	goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
	echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
	set params = %*:"=""
	echo UAC.ShellExecute "cmd.exe", "/c ""%~dp0]]..cmd_filename..[["" %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

	"%temp%\getadmin.vbs"
	del "%temp%\getadmin.vbs"
	exit /B

:gotAdmin
	pushd "%CD%"
	CD /D "%~dp0"
:--------------------------------------
"%~dp0]]..cmd_filename..[["]];

		local cmd_admin_fullpath, output_fullpath = PrepareTempShellFile(cmd_admin, "tempAdmin.bat", "");
		if(ParaGlobal.ShellExecute("wait", cmd_admin_fullpath, cmd_admin_fullpath, "", 1)) then
			if(bPrintToLog) then
				-- get output
				local file = ParaIO.open(output_filename, "r");
				if(file:IsValid()) then
					stdout_text = file:GetText();
					file:close();
				end
				-- since it may be used by another elevated process, do not delete it.
				-- ParaIO.DeleteFile(output_filename); 

				-- since another process is created. this function does not return the output of the command
				-- and this function may return before the command is finished. 
				if(stdout_text and stdout_text~="") then
					commonlib.log(stdout_text);
				end
			end
		end
		if(bDeleteTempFile) then
			ParaIO.DeleteFile(cmd_filename);
		end
		return stdout_text;
	else
		-- TODO: elevate access right in linux?
		return os.run(cmd, bPrintToLog, bDeleteTempFile);
	end
end

NPL.this(function()
	if(msg.type== "run" and msg.cmd and msg.callbackAddress) then
		-- LOG.std(nil, "debug", "os.runAsync", "request received");
		local result = os.run(msg.cmd);
		NPL.activate(msg.callbackAddress, {type="result", result = result, err=nil, callbackId = msg.callbackId});
	elseif(msg.type== "result" and msg.callbackId) then
		local callbackFunc = run_callbacks[msg.callbackId];
		run_callbacks[msg.callbackId] = nil;
		if(type(callbackFunc) == "function") then
			callbackFunc(msg.err, msg.result);
		end
	end
end);