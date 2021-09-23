--[[
Title: operating system parent file
Author(s): LiXizhi
Date: 2016/1/9
Desc: all os module files are included here. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/os/os.lua");
echo(System.os.GetPlatform()=="win32");
echo(System.os.args("bootstrapper", ""));
echo(System.os.GetCurrentProcessId());
echo(System.os.GetPCStats());
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/os/run.lua");
NPL.load("(gl)script/ide/System/os/GetUrl.lua");
NPL.load("(gl)script/ide/System/os/options.lua");
local os = commonlib.gettable("System.os");

-- @return "win32", "linux", "android", "ios", "mac"
function os.GetPlatform()
	if(not os.platform) then
		local platform = ParaEngine.GetAttributeObject():GetField("Platform", 0);
		if(platform == 3) then
			return "win32";
		elseif(platform == 1) then
			return "ios";
		elseif(platform == 2) then
			return "android";
		elseif(platform == 5) then
			return "linux";
		elseif(platform == 8) then
			return "mac";
		elseif(platform == 13) then
			return "wp8";
		elseif(platform == 14) then
			return "winrt";
		elseif(platform == 0) then
			return "unknown";
		end
	end
	return os.platform;
end

local isWindowsXP;
-- if it is old system
function os.IsWindowsXP()
	if(isWindowsXP == nil) then
		isWindowsXP = false;
		if(os.GetPlatform() == "win32") then
			local stats = System.os.GetPCStats();
            if(stats and stats.os) then
                if(stats.os:lower():match("windows xp")) then
                    isWindowsXP = true;
                end
            end
		end
	end
	return isWindowsXP;
end
				

-- return true if is mobile device
function os.IsMobilePlatform()
	if (os.GetPlatform() == "ios" or os.GetPlatform() == "android") then
		return true;
	else
		return false;
	end
end

-- return true if touch mode
function os.IsTouchMode()
	if (os.GetPlatform() == "ios" or os.GetPlatform() == "android") then
		return true;
	else
		return false;
	end
end

-- return true if it is 64 bits system. 
function os.Is64BitsSystem()
	if(os.Is64BitsSystem_ == nil) then
		os.Is64BitsSystem_ = ParaEngine.GetAttributeObject():GetField("Is64BitsSystem", false);
	end
	return os.Is64BitsSystem_;
end

-- get command line argument
-- @param name: argument name
-- @param default_value: default value
function os.args(name, default_value)
	return ParaEngine.GetAppCommandLineByParam(name, default_value);
end

-- get process id
function os.GetCurrentProcessId()
	if(not os.pid) then
		os.pid = ParaEngine.GetAttributeObject():GetField("ProcessId", 0)
	end
	return os.pid;
end

local externalStoragePath;
-- this is "" on PC, but is valid on android/ios mobile devices. 
-- this will always ends with "/"
function os.GetExternalStoragePath()
	if(not externalStoragePath) then
		externalStoragePath = ParaIO.GetCurDirectory(22);

		if(ParaIO.GetCurDirectory(0) == externalStoragePath) then
			externalStoragePath = "";
		else
			if(externalStoragePath ~= "" and not externalStoragePath:match("[/\\]$")) then
				externalStoragePath = externalStoragePath .. "/";
			end
		end
	end
	return externalStoragePath;
end


-- a writable directory. on Android,iOS this is the default app internal storage. 
-- when app is uninstalled, data in this directory will be gone. 
function os.GetWritablePath()
	return ParaIO.GetWritablePath();
end

local pc_stats;
-- get a table containing all kinds of stats for this computer. 
-- @return {videocard, os, memory, ps, vs}
function os.GetPCStats()
	if(not pc_stats) then
		pc_stats = {};
		pc_stats.videocard = ParaEngine.GetStats(0);
		pc_stats.os = ParaEngine.GetStats(1);
		
		local att = ParaEngine.GetAttributeObject();
		local sysInfoStr = att:GetField("SystemInfoString", "");
		local name, value, line;
		for line in sysInfoStr:gmatch("[^\r\n]+") do
			name,value = line:match("^(.*):(.*)$");
			if(name == "TotalPhysicalMemory") then
				value = tonumber(value)/1024;
				pc_stats.memory = value;
			else
				-- TODO: other OS settings
			end
		end
		pc_stats.ps = att:GetField("PixelShaderVersion", 0);
		pc_stats.vs = att:GetField("VertexShaderVersion", 0);
		pc_stats.memory = pc_stats.memory or 4086;

		-- uncomment to test low shader 
		--pc_stats.ps = 1;
		--pc_stats.memory = 300

		local att = ParaEngine.GetAttributeObject();
		pc_stats.IsFullScreenMode = att:GetField("IsFullScreenMode", false);
		pc_stats.resolution_x = tonumber(att:GetDynamicField("ScreenWidth", 1020)) or 1020;
		pc_stats.resolution_y = tonumber(att:GetDynamicField("ScreenHeight", 680)) or 680;
		-- pc_stats.IsWebBrowser = System.options and System.options.IsWebBrowser;
	end
	return pc_stats;
end

if(os.IsWindowsXP()) then
	local NPL_AppendURLRequest = NPL.AppendURLRequest;

	NPL.AppendURLRequest = function(urlParams, sCallback, sForm, sPoolName)
		if(type(urlParams) == "table" and urlParams.url) then
			-- libcurl.dll under windows XP does not support openssl protocol, we will try using http instead. 
			urlParams.url = urlParams.url:gsub("^https://", "http://")
		elseif(type(urlParams) == "string") then
			urlParams = urlParams:gsub("^https://", "http://")
		end
		return NPL_AppendURLRequest(urlParams, sCallback, sForm, sPoolName)
	end
end