--[[
Title: 读写本地缓存工具
Author(s): hyz
Date: 2022/7/6
Desc: 

------------------------------------------------------------
NPL.load("(gl)script/ide/System/localserver/LocalStorageUtil.lua");
local LocalStorageUtil = commonlib.gettable("System.localserver.LocalStorageUtil");
LocalStorageUtil.CheckFristInit()
-------------------------------------------------------
]]

local LocalStorageUtil = commonlib.gettable("System.localserver.LocalStorageUtil");

function LocalStorageUtil._loadFromLS(ls,name, default_value, bIsGlobal)
    if(not ls) then
		LOG.std(nil, "warn", "LocalStorageUtil", "LocalStorageUtil.LoadLocalData %s failed because userdata db is not valid", name)
		return default_value;
	end
	local url;
	-- make url
	if(not bIsGlobal) then
		url = NPL.EncodeURLQuery(name, {"nid", System.User.nid})
	else
		url = name;
	end
	
	local item = ls:GetItem(url)
			
	if(item and item.entry and item.payload) then
		local output_msg = commonlib.LoadTableFromString(item.payload.data);
		if(output_msg) then
			return output_msg.value;
		end
	end
	return default_value;
end

function LocalStorageUtil._saveWithLS(ls,name, value, bIsGlobal, bDeferSave)
    if(not ls) then
		return;
	end
	-- make url
	local url;
	if(not bIsGlobal) then
		url = NPL.EncodeURLQuery(name, {"nid", System.User.nid})
	else
		url = name;
	end
	
	-- make entry
	local item = {
		entry = System.localserver.WebCacheDB.EntryInfo:new({
			url = url,
		}),
		payload = System.localserver.WebCacheDB.PayloadInfo:new({
			status_code = System.localserver.HttpConstants.HTTP_OK,
			data = {value = value},
		}),
	}
	-- save to database entry
	local res = ls:PutItem(item, not bDeferSave);
	if(res) then 
		LOG.std("", "debug","LocalStorageUtil", "Local user data %s is saved to local server", tostring(url));
		return true;
	else	
		LOG.std("", "warn","LocalStorageUtil", "failed saving local user data %s to local server", tostring(url))
	end
end

function LocalStorageUtil._flushWithLS(ls)
    if(ls) then
		return ls:Flush();
	end
end

--因为存储位置改变，需要做一些迁移工作
function LocalStorageUtil.CheckFristInit()
    local bUserdbMoved = LocalStorageUtil.Load_localserver("bUserdbMoved",false,true)
    if not bUserdbMoved then --将原本的直接复制
        local name = if_else(System.options.version == "teen", "userdata.teen", "userdata")
        local fromPath = string.format("Database/%s.db",name)
        local toPath = string.format("%s/Database/%s.db",commonlib.Files.GetAppDataDirectory(), name)
        if ParaIO.DoesFileExist(fromPath) and not ParaIO.DoesFileExist(toPath) then
            ParaIO.CopyFile(fromPath,toPath,true)
            LocalStorageUtil.Save_localserver("bUserdbMoved",true,true)
        end
    end

    local bProjectIdMoved = LocalStorageUtil.Load_localserver("bProjectIdMoved",false,true)
    if not bProjectIdMoved then --projectId和projectInfo存到localserver
        NPL.load("(gl)script/ide/System/localserver/WebCacheDB.lua");
        local WebCacheDB = commonlib.gettable("System.localserver.WebCacheDB");
        local web_db = WebCacheDB:new({
            kFileName = string.format("Database/%s.db", "userdata"),
        });
        local worldIds = {} --记录的只读世界id
        local stmt = assert(web_db._db:prepare([[select Url,PayloadID from Entries where Url like 'pid%']]));
        local row;
        for row in stmt:rows() do
            table.insert(worldIds,{row.PayloadID,row.Url})
        end
        stmt:close();

        for k,obj in ipairs(worldIds) do
            local bodyId = obj[1]
            local pidStr = obj[2]
            local projectId = tonumber(string.match(pidStr,"[%d]+"))
            local cmd = string.format([[select Data from ResponseBodies where BodyId is %s ]],bodyId)
            local stmt = assert(web_db._db:prepare(cmd));
            for row in stmt:rows() do
                local projectInfo = commonlib.totable(row.Data)
                if not LocalStorageUtil.Load_localserver(pidStr,nil,true) then
                    local bDeferSave = true
                    LocalStorageUtil.Save_localserver(pidStr,projectInfo.value,true,bDeferSave)
                end 
            end
            stmt:close();
        end

        LocalStorageUtil.Save_localserver("bProjectIdMoved",true,true)
    end
end

function LocalStorageUtil.CreateUserDataStore()
    local dbPath = if_else(System.options.version == "teen", "userdata.teen", "userdata")
    dbPath = string.format("%s/Database/%s.db",commonlib.Files.GetAppDataDirectory(), dbPath)
	local ls = System.localserver.CreateStore(nil, 3, dbPath);
    return ls
end

--[[
    写userdata.db 用户相关的数据
    文件存在C:/用户/AppData/Local/Paracraft
]]
function LocalStorageUtil.Save_userdata(name, value, bIsGlobal, bDeferSave)
	local ls = LocalStorageUtil.CreateUserDataStore()
	LocalStorageUtil._saveWithLS(ls,name, value, bIsGlobal, bDeferSave)
end

--[[
    读userdata.db 用户相关的数据
    文件存在C:/用户/AppData/Local/Paracraft
]]
function LocalStorageUtil.Load_userdata(name, default_value, bIsGlobal)
	local ls = LocalStorageUtil.CreateUserDataStore()
	return LocalStorageUtil._loadFromLS(ls,name, default_value, bIsGlobal)
end

function LocalStorageUtil.Flush_userdata()
	local ls = LocalStorageUtil.CreateUserDataStore()
	if(ls) then
		return ls:Flush();
	end
end


--[[
    写localserver.db
    文件存在安装目录
]]
function LocalStorageUtil.Save_localserver(name, value, bIsGlobal, bDeferSave)
    local dbPath = nil

	local ls = System.localserver.CreateStore(nil, 3, dbPath);
	LocalStorageUtil._saveWithLS(ls,name, value, bIsGlobal, bDeferSave)
end

--[[
    读localserver.db
    文件存在安装目录
]]
function LocalStorageUtil.Load_localserver(name, default_value, bIsGlobal)
    local dbPath = nil

	local ls = System.localserver.CreateStore(nil, 3, dbPath);
	return LocalStorageUtil._loadFromLS(ls,name, default_value, bIsGlobal)
end

function LocalStorageUtil.Flush_localserver()
    local dbPath = nil
	local ls = System.localserver.CreateStore(nil, 3, dbPath);
	if(ls) then
		return ls:Flush();
	end
end