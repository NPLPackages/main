--[[
Title: CommonLib
Author(s):  wxa
Date: 2020-06-12
Desc: 公共函数库
use the lib:
------------------------------------------------------------
local CommonLib = NPL.load("(gl)script/ide/System/Util/CommonLib.lua");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/DateTime.lua");
NPL.load("(gl)script/ide/commonlib.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/HttpFiles.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/SoundManager.lua");
NPL.load("(gl)script/ide/AudioEngine/AudioEngine.lua");
NPL.load("(gl)script/ide/OpenFileDialog.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
local Encoding = commonlib.gettable("System.Encoding");
local lfs = commonlib.Files.GetLuaFileSystem();
local AudioEngine = commonlib.gettable("AudioEngine");
local SoundManager = commonlib.gettable("MyCompany.Aries.Game.Sound.SoundManager");
local HttpFiles = commonlib.gettable("MyCompany.Aries.Game.Common.HttpFiles");

local List = NPL.load("./List.lua");
local Table = NPL.load("./Table.lua");
local EventEmitter = NPL.load("./EventEmitter.lua");
local String = NPL.load("./String.lua");

local __event_emitter__ = EventEmitter:new();

local CommonLib = NPL.export();

CommonLib.List = List;
CommonLib.Table = Table;
CommonLib.String = String;
CommonLib.EventEmitter = EventEmitter;

function CommonLib.PlayVoiceText(text, speed, lang, callback)
    local function finish(...) 
        if (type(callback) == "function") then callback(...) end 
    end
    
    if (not text or text == "") then return finish(0) end

    speed = speed or 5;
    lang = lang or "zh";

    local url = format("https://tts.baidu.com/text2audio?per=1&lan=%s&ie=UTF-8&spd=%d&text=%s", lang, speed, commonlib.Encoding.url_encode(text));
    HttpFiles.GetHttpFilePath(url, function(err, diskfilename) 
        if (not diskfilename) then return finish(0) end
        local sound_name = diskfilename:match("[^/\\]+$");
        SoundManager:PlaySound(sound_name, diskfilename);
        local sound = AudioEngine.CreateGet(sound_name);
        local total_time = tonumber(sound:GetSource().TotalAudioTime);
        finish(math.floor(total_time * 1000));
    end)
end


local temp_keys = {};
function CommonLib.ClearTable(t)
    local size = 0;
    for key in pairs(t) do
        size = size + 1;
        temp_keys[size] = key;
    end

    for i = 1, size do
        t[temp_keys[i]] = nil;
        temp_keys[i] = nil;
    end
end

function CommonLib.IsWin32Platform()
    return System.os.GetPlatform() == "win32";
end

function CommonLib.ToCanonicalFilePath(filename, platform)
    platform = platform or System.os.GetPlatform();

	if(platform == "win32") then
        filename = string.gsub(filename, "/+", "\\");
		filename = string.gsub(filename, "\\+", "\\");
	else
		filename = string.gsub(filename, "\\+", "/");
        filename = string.gsub(filename, "/+", "/");
	end
	
    return filename;
end

local TextureFilters = {
    {"全部文件(*.png,*.jpg)",  "*.png;*.jpg"},
    {"png(*.png)",  "*.png"},
    {"jpg(*.jpg)",  "*.jpg"},
};
function CommonLib.OpenTextureFileDialog(filters, title, directory)
    local install_directory = ParaIO.GetCurDirectory(0);
    local world_directory = ParaWorld.GetWorldDirectory();
    local filename = CommonCtrl.OpenFileDialog.ShowDialog_Win32(filters or TextureFilters,  title or "", directory or world_directory);

    if (not filename) then return filename end
    
    if (string.sub(world_directory, 1, string.len(install_directory)) ~= install_directory) then world_directory = install_directory .. world_directory end
    install_directory = CommonLib.ToCanonicalFilePath(install_directory);
    world_directory = CommonLib.ToCanonicalFilePath(world_directory);

    if (string.sub(filename, 1, string.len(world_directory)) == world_directory) then
        filename = "@" .. string.sub(filename, string.len(world_directory) + 1);
    elseif (string.sub(filename, 1, string.len(install_directory)) == install_directory) then
        filename = string.sub(filename, string.len(install_directory) + 1);
    end

    return filename;
end

function CommonLib.IsExistFile(filename)
    return ParaIO.DoesFileExist(filename, false);
end

-- 获取文件内容
function CommonLib.GetFileText(filename)
    local file = ParaIO.open(filename , "rb");
	if(file:IsValid()) then
		local text = file:GetText(0, -1);
		file:close();
		return text;
    else
        file:close();
	end	
end
-- 获取文件大小
function CommonLib.GetFileSize(filename)
    local file = ParaIO.open(filename , "rb");
	if(file:IsValid()) then
		local size = file:GetFileSize();
		file:close();
		return size;
    else
        print("------不可用",filename)
        file:close();
	end	
    return 0
end

-- 写文件
function CommonLib.WriteFile(filename, text)
    if text==nil or text=="" then
        return
    end
    local div = CommonLib.IsWin32Platform() and "\\" or "/"
    local patt = string.format("[^%s]+%s",div,div)
    local temp = ""
    for k,v in string.gmatch(filename,patt) do
        temp = temp .. k
        if not ParaIO.DoesFileExist(temp) then
            ParaIO.CreateDirectory(temp);
        end
    end

    local file = ParaIO.open(filename , "wb");
	if(file:IsValid()) then
		file:WriteString(text, #text);
		file:close();
    else
        file:close();
	end	
end

-- 计算文本MD5值
function CommonLib.MD5(text)
    return ParaMisc.md5(text or "");
end

-- 获取文件MD5
function CommonLib.GetFileMD5(filename)
    return ParaMisc.md5(CommonLib.GetFileText(filename) or "");
end

-- 获取根目录即安装目录
function CommonLib.GetRootDirectory()
    return ParaIO.GetWritablePath();
end

-- 创建目录
function CommonLib.CreateDirectory(directory, bDeleteIfExist)
    if (bDeleteIfExist) then CommonLib.DeleteDirectory(directory) end 
    ParaIO.CreateDirectory(directory);
end

-- 删除目录
function CommonLib.DeleteDirectory(directory)
    ParaIO.DeleteFile(CommonLib.ToCanonicalFilePath(directory .. "/", "linux"));
end

-- 获取Temp
function CommonLib.GetTempDirectory()
    local install_directory = ParaIO.GetCurDirectory(0);
    return CommonLib.ToCanonicalFilePath(install_directory .. "/" .. "temp");
end

-- 获取世界路径
function CommonLib.GetWorldDirectory()
    local world_directory = ParaWorld.GetWorldDirectory();
    if (string.match(world_directory, "^[\\/]")) then return world_directory end 
    local install_directory = ParaIO.GetCurDirectory(0);
    if (string.find(world_directory, install_directory, 1, true) == 1) then return world_directory end 
    return CommonLib.ToCanonicalFilePath(install_directory .. "/" .. world_directory);
end

-- 拷贝目录
function CommonLib.CopyDirectory(src_dir, dst_dir, recursive)
    src_dir = CommonLib.ToCanonicalFilePath(src_dir .. "/");
    dst_dir = CommonLib.ToCanonicalFilePath(dst_dir .. "/");
    ParaIO.CreateDirectory(dst_dir);
    for filename in lfs.dir(src_dir) do
        if (filename ~= "." and filename ~= "..") then
            local src_file = CommonLib.ToCanonicalFilePath(src_dir .. "/" .. filename);
            local dst_file = CommonLib.ToCanonicalFilePath(dst_dir .. "/" .. filename);
            local fileattr = lfs.attributes(src_file);
            if (fileattr.mode == "directory") then
                if (recursive) then CommonLib.CopyDirectory(src_file, dst_file, recursive) end
            else
                ParaIO.CopyFile(src_file, dst_file, true);
            end
        end
    end
end

function CommonLib.GetDirectory(filepath)
    return string.gsub(filepath or "", "([^\\/]*)$", "");
end

function CommonLib.GetFileName(filepath)
    return string.match(filepath or "", "([^\\/]*)$");
end

-- 获取文件
function CommonLib.GetFileList(directory, md5, recursive)
    directory = CommonLib.ToCanonicalFilePath(directory);
    local list = {};
    local size = string.len(CommonLib.GetDirectory(directory));

    local function GetFileList(directory, md5, recursive)
        for filename in lfs.dir(directory) do
            if (filename ~= "." and filename ~= "..") then
                local file_path = CommonLib.ToCanonicalFilePath(directory .. "/" .. filename);
                local fileattr = lfs.attributes(file_path);
                if (fileattr.mode == "directory") then
                    if (recursive) then GetFileList(file_path, md5, recursive) end
                else
                    table.insert(list, #list + 1, {file_path = file_path, file_md5 = md5 and CommonLib.GetFileMD5(file_path),file_size = md5 and CommonLib.GetFileSize(file_path)});
                end
            end
        end
    end

    if (not CommonLib.IsDirectory(directory)) then
        -- 是文件直接返回
        table.insert(list, #list + 1, {file_path = directory, file_md5 = md5 and CommonLib.GetFileMD5(directory),file_size=md5 and CommonLib.GetFileSize(directory)});
    else 
        -- 是目录 
        GetFileList(directory, md5, recursive);
    end
    
    for _, item in ipairs(list) do
        item.file_rel_path = string.sub(item.file_path, size + 1);   -- 相对路径
    end

    return list;
end

function CommonLib.IsDirectory(filename)
    local fileattr = lfs.attributes(filename);
    return fileattr and fileattr.mode == "directory";
end


CommonLib.EncodeBase64 = Encoding.base64;
CommonLib.DecodeBase64 = Encoding.unbase64;

-- 格式化文件名
local AliasPathMap = {};
function CommonLib.SetAliasPath(alias, path)
    AliasPathMap[alias] = path;
end

function CommonLib.GetFullPath(filename, alias_path_map)
    alias_path_map = alias_path_map or AliasPathMap;
    local path = string.gsub(filename or "", "%%(.-)%%", function(alias)
        local path = AliasPathMap[string.lower(alias)];
        if (type(path) == "string") then return path end
        if (type(path) == "function") then return path() end
        return "";
    end);
    path = string.gsub(path, "^@", CommonLib.GetWorldDirectory());
    return CommonLib.ToCanonicalFilePath(path);
end

-- 下载文件
function CommonLib.Download(url, path, calback)
end

-- 添加地址
local __nids__ = {};
function CommonLib.AddNPLRuntimeAddress(ip, port)
    ip = tostring(ip or "127.0.0.1");
	port = tostring(port or "9000");
	local nid = string.format("%s_%s", ip, port);
    if (not __nids__[nid]) then  
        NPL.AddNPLRuntimeAddress({host = ip, port = port, nid = nid});
        __nids__[nid] = nid;
    end 
    return nid;
end

-- 网络事件
commonlib.setfield("__CommonLib__", CommonLib);
NPL.RegisterEvent(0, "_n_Connections_network", ";__CommonLib__.__OnNetworkEvent__();");
-- Lua NetworkEvent
function CommonLib.OnNetworkEvent(callback)
    __event_emitter__:RegisterEventCallBack("__OnNetworkEvent__", callback);
end
-- C++ NetworkEvent
function CommonLib.__OnNetworkEvent__()
    __event_emitter__:TriggerEventCallBack("__OnNetworkEvent__", msg);
end

-- Lua Thread NetworkEvent
function CommonLib.RegisterNetworkEvent(callback)
	__event_emitter__:RegisterEventCallBack("NetworkEvent", callback);
end

function CommonLib.RemoveNetworkEvent(callback)
    __event_emitter__:RemoveEventCallBack("NetworkEvent", callback);
end

function CommonLib.TriggerNetworkEvent(data)
    __event_emitter__:TriggerEventCallBack("NetworkEvent", data);
end

-- NPL_OK = 0, 
-- NPL_Error = 1, 
-- NPL_ConnectionNotEstablished = 2,
-- NPL_QueueIsFull = 3,
-- NPL_StreamError = 4,
-- NPL_RuntimeState_NotExist = 5,
-- NPL_FailedToLoadFile = 6,
-- NPL_RuntimeState_NotReady = 7,
-- NPL_FileAccessDenied = 8,
-- NPL_ConnectionEstablished = 9,
-- NPL_UnableToResolveName = 10,
-- NPL_ConnectionTimeout = 11,
-- NPL_ConnectionDisconnected = 12,
-- NPL_ConnectionAborted = 13,
-- NPL_Command = 14,
-- NPL_WrongProtocol = 15

function CommonLib.IsServerStarted()
    return NPL.GetAttributeObject():GetField("IsServerStarted", false);
end

function CommonLib.GetServerPort()
    return NPL.GetAttributeObject():GetField("HostIP");
end

function CommonLib.GetServerIp()
    return NPL.GetAttributeObject():GetField("HostPort");
end

function CommonLib.GetServerIpAndPort()
    return CommonLib.GetServerIp(), CommonLib.GetServerPort(); 
end

function CommonLib.StartNetServer(ip, port)
    if (CommonLib.IsServerStarted()) then return end
    
    local att = NPL.GetAttributeObject();
	att:SetField("TCPKeepAlive", true);
	att:SetField("KeepAlive", true);
	att:SetField("IdleTimeout", false);
	att:SetField("IdleTimeoutPeriod", 1200000);
	NPL.SetUseCompression(true, true);
	att:SetField("CompressionLevel", -1);
	att:SetField("CompressionThreshold", 1024*16);
	att:SetField("UDPIdleTimeoutPeriod", 1200000);
	att:SetField("UDPCompressionLevel", -1);
	att:SetField("UDPCompressionThreshold", 1024*16);
	__rts__:SetMsgQueueSize(500);

    NPL.StartNetServer(ip or "0.0.0.0", tostring(port or "9000"));
end

-- String
function CommonLib.StringTrim(str, ch)
    return String.Trim(str, ch)
end

-- Timer
function CommonLib.SetInterval(interval, callback)
    local timer = commonlib.Timer:new({callbackFunc = callback});
	timer:Change(interval, interval);
    return timer;
end

function CommonLib.SetTimeout(timeout, callback)
	local timer = commonlib.Timer:new({callbackFunc = callback});
    timer:Change(timeout);
    return timer;
end

-- DateTime
function CommonLib.GetTimeStampByDateTime(datetime)
    return commonlib.timehelp.GetTimeStampByDateTime(datetime);
end

function CommonLib.GetTimeStamp()
    return ParaGlobal.timeGetTime();
end

-- table.pack table.unpack, select 
local __arguments__ = {n = 0};
local __select__ = select;
function CommonLib.pack(...)
	-- 先清除旧参数
	for i = 1, __arguments__.n do __arguments__[i] = nil end 
	-- 获取新参数大小
	__arguments__.n = __select__("#", ...);
	-- 设置新参数
	for i = 1, __arguments__.n do __arguments__[i] = __select__(i, ...) end 

	return CommonLib.unpack();
end

function CommonLib.unpack()
	return __arguments__[1], __arguments__[2], __arguments__[3], __arguments__[4], __arguments__[5], __arguments__[6], __arguments__[7], __arguments__[8], __arguments__[9];
end

function CommonLib.select(index)
	if (index == "#") then return __arguments__.n end 
	index = tonumber(index) or 1;
    return __arguments__[index], __arguments__[index + 1], __arguments__[index + 2], __arguments__[index + 3], __arguments__[index + 4], __arguments__[index + 5], __arguments__[index + 6], __arguments__[index + 7], __arguments__[index + 8], __arguments__[index + 9];
end


local function ParseOption(cmd_text)
	local value, cmd_text_remain = cmd_text:match("^%s*%-([%w_]+%S+)%s*(.*)$");
	if(value) then
		return value, cmd_text_remain;
	end
	return nil, cmd_text;
end

local function ParseOptions(cmd_text)
	local options = {};
	local option, cmd_text_remain = nil, cmd_text;
	while(cmd_text_remain) do
		option, cmd_text_remain = ParseOption(cmd_text_remain);
		if(option) then
			key, value = option:match("([%w_]+)=?(%S*)");
			if (value == "true" or key == option) then 
				options[key] = true;
			elseif (value == "false") then 
				options[key] = false;
			else
				options[key] = value;
			end
		else
			break;
		end
	end
	return options, cmd_text_remain;
end
CommonLib.ParseOptions = ParseOptions;


local _Byte = string.byte("_");
local aByte = string.byte("a");
local zByte = string.byte("z");
local AByte = string.byte("A");
local ZByte = string.byte("Z");
local _0Byte = string.byte("0");
local _9Byte = string.byte("9");
function CommonLib.ToVarFuncName(str)
    local newstr = "";
    for i = 1, #str do
        local byte = string.byte(str, i, i);
        if (_Byte == byte or (aByte <= byte and byte <=zByte) or (AByte <= byte and byte <=ZByte) or (_0Byte <= byte and byte <= _9Byte)) then
            newstr = newstr .. string.char(byte);
        else 
            newstr = newstr .. string.format("_%X", byte)
        end
    end
    return newstr;
end

--返回值： ver_1 - ver_2
function CommonLib.CompareVer(ver_1,ver_2)
    local function get_versions(version_str)
        local result = {};
        for s in string.gfind(version_str or "", "%d+") do
            table.insert(result, tonumber(s));
		end
        while(#result<3)do 
            table.insert(result,0)
        end
        return result;
    end
    local list_1 = get_versions(ver_1)
    local list_2 = get_versions(ver_2)
    if(list_1[1] == list_2[1])then
        if(list_1[2] == list_2[2])then
            return list_1[3] - list_2[3]
        else
            return list_1[2] - list_2[2]
        end
    else
        return list_1[1] - list_2[1]
    end
end
