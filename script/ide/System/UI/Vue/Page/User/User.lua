
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
local Debug = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Debug.lua");
local Compare = NPL.load("(gl)Mod/WorldShare/service/SyncService/Compare.lua");
local CheckSkin = NPL.load("(gl)Mod/GeneralGameServerMod/UI/Vue/Page/User/CheckSkin.lua");
local Encoding = commonlib.gettable("System.Encoding");
local SelfProjectList = {};
local AuthUser = KeepWorkItemManager.GetProfile();
local player = GameLogic.GetPlayerController():GetPlayer();
local GlobalScope = GetGlobalScope();
local PageSize = 40;

-- 组件全局变量初始化
GlobalScope:Set("AuthUsername", AuthUser.username);
GlobalScope:Set("AuthUserId", AuthUser.id or 0);
GlobalScope:Set("isLogin", System.User.keepworkUsername and true or false);
GlobalScope:Set("isAuthUser", false);
GlobalScope:Set("UserDetail", {username = "", createdAt = "2020-01-01", rank = {}});
GlobalScope:Set("ProjectList", {});                      -- 用户项目列表
GlobalScope:Set("ProjectListLoadFinish", false);
GlobalScope:Set("ProjectListType", "works");
GlobalScope:Set("MainAsset", player and player:GetMainAssetPath());
GlobalScope:Set("MainSkin", player and player:GetSkin());
GlobalScope:Set("AssetSkinGoodsItemId", 0);
GlobalScope:Set("IsFollow", false);
GlobalScope:Set("HonorList", {});
GlobalScope:Set("AvatarItems", {});
GlobalScope:Set("AvatarIcons", {});
GlobalScope:Set("CharacterTabIndex", HeaderTabIndex or "works"); -- 当前选择项

local ProjectMap = {};

local function IsExistScopeProjectList(projectId)
    local ScopePorjectList = GlobalScope:Get("ProjectList");
    for _, project in ipairs(ScopePorjectList) do
        if (project.id == projectId) then return true end
    end
    return false;
end

local function AddPojectListToScopeProjectList(ProjectList)
    local ScopePorjectList = GlobalScope:Get("ProjectList");
    for _, project in ipairs(ProjectList) do
        if (not IsExistScopeProjectList(project.id)) then
            table.insert(ScopePorjectList, project);
        end
    end
end

local function GetProjectListPageFunc()
    -- 获取项目列表
    local page, pageSize = 1, PageSize;
    local isFinish = false;
    local isRequest = false;
    
    return function() 
        if (isFinish or isRequest) then return end
        local userId = GlobalScope:Get("UserId");
        local AuthUserId = GlobalScope:Get("AuthUserId");
        if (not userId) then return end
        local BeginTime = GetTime();
        isRequest = true;
        keepwork.project.list({
            -- 请求参数
            userId = userId,                    -- 用户ID
            type = 1,                           -- 取世界项目
            -- 分页控制
            ["x-page"] = page,                  -- 页数
            ["x-per-page"] = pageSize,          -- 页大小
            ["x-order"] = "updatedAt-desc",     -- 按更新时间降序
        }, function(status, msg, data)
            if (status ~= 200) then 
                isFinish = true;
                GlobalScope:Set("ProjectListLoadFinish", isFinish);
                return echo("获取用户项目列表失败, userId " .. tostring(userId));
            end
            local total = tonumber(string.match(msg.header or "", "x-total:%s*(%d+)"));
            local ProjectList = data;

            local projectIds, projects = {}, {};

            for i, project in ipairs(ProjectList) do
                projectIds[i] = project.id;
                projects[project.id] = project;
                project.isFavorite = false;
                project.selected = false;
                project.user = GlobalScope:Get("UserDetail");
            end

            if (AuthUserId and AuthUserId > 0) then
                keepwork.project.favorite_search({
                    objectType = 5,
                    objectId = {
                        ["$in"] = projectIds,
                    }, 
                    userId = AuthUserId,
                }, function(status, msg, data)
                    local rows = data.rows or {};
                    for _, row in ipairs(rows) do projects[row.objectId].isFavorite = true end
                    local EndTime = GetTime();
                    -- print("耗时: ", EndTime - BeginTime);
                    AddPojectListToScopeProjectList(ProjectList);
                end);
            else
                AddPojectListToScopeProjectList(ProjectList);
            end
            local ScopePorjectList = GlobalScope:Get("ProjectList");
            if (total) then
                isFinish = (#ScopePorjectList) >= total;
            else
                isFinish = (#ProjectList) < pageSize; 
            end
            GlobalScope:Set("ProjectListLoadFinish", isFinish);

            Log.Format("page = %s, pageSize = %s, curCount = %s, realCount = %s, total = %s, isFinish = %s", page, pageSize, #ProjectList, #ScopePorjectList, total, isFinish);

            page = page + 1;
            isRequest = false;
        end)
    end
end

local function GetFavoriteProjectListPageFunc()
    -- 获取项目列表
    local page, pageSize = 1, PageSize;
    local isFinish = false;
    local isRequest = false;
    
    return function() 
        if (isFinish or isRequest) then return end
        local userId = GlobalScope:Get("AuthUserId");
        if (not userId) then return end
        isRequest = true;
        keepwork.project.list_favorite({
            -- 请求参数
            userId = userId,                    -- 用户ID
            type = 1,                           -- 取世界项目
            -- 分页控制
            ["x-page"] = page,                  -- 页数
            ["x-per-page"] = pageSize,          -- 页大小
            ["x-order"] = "updatedAt-desc",     -- 按更新时间降序
        }, function(status, msg, data)
            if (status ~= 200) then 
                isFinish = true;
                GlobalScope:Set("ProjectListLoadFinish", isFinish);
                return echo("获取用户项目列表失败, userId " .. tostring(userId));
            end
            local ProjectList = data.rows;
            local total = data.count;
            -- echo(data, true);
            if (#ProjectList < pageSize) then isFinish = true end
            for _, project in ipairs(ProjectList) do 
                project.isFavorite = true;
                project.selected = false;
            end
            AddPojectListToScopeProjectList(ProjectList);
            local ScopePorjectList = GlobalScope:Get("ProjectList");
            if (total) then
                isFinish = (#ScopePorjectList) >= total;
            else
                isFinish = (#ProjectList) < pageSize; 
            end
            GlobalScope:Set("ProjectListLoadFinish", isFinish);
            page = page + 1;
            isRequest = false;
        end)
    end
end

-- 取消收藏
local function UnfavoriteProject(projectId)
    local ScopePorjectList = GlobalScope:Get("ProjectList");
    for i, project in ipairs(ScopePorjectList) do
        if (project.id == projectId) then 
            project.isFavorite = false;
            if (GetProjectListType() == "favorite") then
                table.remove(ScopePorjectList, i);
            end
            break;
        end
    end
    
    -- GlobalScope:Set("ProjectList", ScopePorjectList);

    keepwork.world.unfavorite({objectType = 5, objectId = projectId}, function(status)
        if (status < 200 or status >= 300) then
            Log("无法取消收藏");
        end
    end);
end

-- 收藏
local function FavoriteProject(projectId)
    local ScopePorjectList = GlobalScope:Get("ProjectList");
    for i, project in ipairs(ScopePorjectList) do
        if (project.id == projectId) then 
            project.isFavorite = true;
            break;
        end
    end
    
    -- GlobalScope:Set("ProjectList", ScopePorjectList);

    keepwork.world.favorite({objectType = 5, objectId = projectId}, function(status)
        if (status < 200 or status >= 300) then
            Log("无法收藏");
        end
    end);
end

_G.UnfavoriteProject = UnfavoriteProject;
_G.FavoriteProject = FavoriteProject;
_G.NextPageProjectList = GetProjectListPageFunc();
_G.SetProjectListType = function(projectListType)
    GlobalScope:Set("ProjectList", {});
    GlobalScope:Set("ProjectListType", projectListType);
    if (projectListType == "favorite") then
        _G.NextPageProjectList = GetFavoriteProjectListPageFunc();
    else
        _G.NextPageProjectList = GetProjectListPageFunc();
    end
    NextPageProjectList();
end
_G.GetProjectListType = function()
    return GlobalScope:Get("ProjectListType");
end

-- SetProjectListType("works");



local function GetItemIcon(item, suffix)
    local icon = item.icon;
    if(not icon or icon == "" or icon == "0") then icon = string.format("Texture/Aries/Creator/keepwork/items/item_%d%s_32bits.png", item.gsId, suffix or "") end
    return icon;
end


-- 加载用户信息
function LoadUserInfo()
    local payload = {};
    if (self.userId) then payload.userId = self.userId 
    elseif (self.username) then payload.username = self.username 
    else  payload.username = System.User.keepworkUsername or "xiaoyao" end
    local id = "kp" .. Encoding.base64(commonlib.Json.Encode(payload));
    -- 获取用户信息
    keepwork.user.getinfo({
        cache_policy = "access plus 0",
        router_params = {id = id},
    }, function(status, msg, data) 
        if (status ~= 200) then return echo("获取用户详情失败...") end
        local UserDetail = data;
        -- echo(UserDetail)
        -- 设置知识豆
        _, _, _, UserDetail.bean = KeepWorkItemManager.HasGSItem(998);

        local extra = UserDetail.extra or {};
        local ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo or {};
        
        UserDetail.realnickname = UserDetail.nickname;
        UserDetail.nickname = UserDetail.nickname or UserDetail.username;
        -- 设置模型
        GlobalScope:Set("UserDetail", UserDetail);
        GlobalScope:Set("UserId", UserDetail.id);
        GlobalScope:Set("AssetSkinGoodsItemId", ParacraftPlayerEntityInfo.assetSkinGoodsItemId or 0);
        
        -- echo(UserDetail.paraMini, true);
        -- echo(UserDetail.schoolParaWorld, true);

        -- echo(data)
        if (System.User.keepworkUsername == UserDetail.username) then
            GlobalScope:Set("AuthUserId", UserDetail.id);
            GlobalScope:Set("isAuthUser", true);

            -- make true load all user items, so KeepWorkItemManager.items is the latest data
            KeepWorkItemManager.LoadItems(nil, function ()
                GetAllAssets();
            end);
            -- echo("--------------------------------IsAuthUser------------------------------------");
        end
       
        local ParacraftPlayerEntityInfo = UserDetail.extra and UserDetail.extra.ParacraftPlayerEntityInfo or {};
        
        if (ParacraftPlayerEntityInfo.asset) then 
            GlobalScope:Set("MainAsset", ParacraftPlayerEntityInfo.asset) 
            GlobalScope:Set("DefaulMainAsset", ParacraftPlayerEntityInfo.asset)
        end 
        if (ParacraftPlayerEntityInfo.skin) then 
            GlobalScope:Set("MainSkin", ParacraftPlayerEntityInfo.skin) 
            GlobalScope:Set("DefaulMainSkin", ParacraftPlayerEntityInfo.skin)
        end 
        
        NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/CustomSkinPage.lua");
        local CustomSkinPage = commonlib.gettable("MyCompany.Aries.Game.Movie.CustomSkinPage");
        local avtarIcons = {};
	    for i = 1, #CustomSkinPage.category_ds do
		    avtarIcons[i] = {id = "", icon = "", name = ""}; 
	    end
        if (ParacraftPlayerEntityInfo.asset == CustomCharItems.defaultModelFile and not CustomCharItems:CheckAvatarExist(ParacraftPlayerEntityInfo.skin)) then
	        local items = CustomCharItems:GetUsedItemsBySkin(ParacraftPlayerEntityInfo.skin);
	        for _, item in ipairs(items) do
		        local index = CustomSkinPage.GetIconIndexFromName(item.name);
		        if (index > 0) then
			        avtarIcons[index].id = item.id;
			        avtarIcons[index].name = item.name;
			        avtarIcons[index].icon = item.icon;
		        end
	        end
        end

        -- avtarIcons DS
        -- { { icon="Texture/Aries/Creator/keepwork/Avatar/icons/mouth_boy_07_01_32bits.png", id="89001", name="pet" }
        GlobalScope:Set("AvatarIcons", avtarIcons);

        -- 获取用户荣誉
        keepwork.user.honors({userId = UserDetail.id}, function(status, msg, data)
            if (status ~= 200) then return end
            
            local list = data.rows or {};
            local honors, honor_map = {}, {};
            for _, item in ipairs(list) do
                local itemTpl = KeepWorkItemManager.GetItemTemplate(item.gsId);
                if (itemTpl) then
                    local extra = itemTpl.extra or {};
                    table.insert(honors, {
                        gsId = item.gsId,
                        icon = GetItemIcon(itemTpl),
                        name = itemTpl.name,
                        desc = itemTpl.desc,
                        createdAt = item.createdAt,
                        certurl = extra.picture,
                        description = extra.description,
                        worldId = extra.worldId,
                        has = true,
                    });
                    honor_map[item.gsId] = honors[#honors];
                end
            end

            if (System.User.keepworkUsername == UserDetail.username) then
                for _, itemTpl in ipairs(KeepWorkItemManager.globalstore) do
                    if (not honor_map[itemTpl.gsId] and itemTpl.bagNo == 1006) then
                        local extra = itemTpl.extra or {};
                        table.insert(honors, {
                            gsId = itemTpl.gsId,
                            icon = GetItemIcon(itemTpl, "_gray"),
                            name = itemTpl.name,
                            desc = itemTpl.desc,
                            -- createdAt = item.createdAt,
                            certurl = extra.picture,
                            description = extra.description,
                            worldId = extra.worldId,
                            has = false,
                        });
                    end
                end
            end
            -- commonlib.echo(honors, true);
            -- "Texture/Aries/Creator/keepwork/SummerCamp/zhengshu/hongxingshangshang_32bits.png"  
            -- "Texture/Aries/Creator/keepwork/items/item_70009_32bits.png"
            -- "Texture/Aries/Creator/keepwork/items/item_70009_gray_32bits.png"
            GlobalScope:Set("HonorList", honors);
        end);

        -- 先拉取第一页
        NextPageProjectList();
        if (GlobalScope:Get("isAuthUser") or not GlobalScope:Get("isLogin")) then return end
        -- 获取是否关注
        keepwork.user.isfollow({
            objectId = UserDetail.id,
            objectType = 0,
        }, function(status, msg, data) 
            if (status ~= 200) then return end
            if (data and data ~= "false" and tonumber(data) ~= 0) then
                GlobalScope:Set("IsFollow", true);
            end
        end)
    end)
end

_G.GetUserAssets = function()
    local bagNo = 1007;
    local assets = {};

    for _, item in ipairs(KeepWorkItemManager.items) do
        if (item.bagNo == bagNo) then
            local tpl = KeepWorkItemManager.GetItemTemplate(item.gsId);
            if (tpl) then
                table.insert(assets, {
                    id = tpl.id,
                    modelUrl = tpl.modelUrl,
                    icon = GetItemIcon(tpl),
                    name = tpl.name,
                    skin = tpl.extra and tpl.extra.skin;
            });
            end
        end
    end

    return assets;
end

PlayerAssetList = {
    {
        id = 1,
        icon = "Texture/Aries/Creator/keepwork/ggs/user/renwuqiehuan/nan_108X176_32bits.png#0 0 108 176",
        modelUrl = "character/CC/02human/paperman/boy01.x",
        modelOrder = 3,
        owned = true,
    },
    {
        id = 2,
        icon = "Texture/Aries/Creator/keepwork/ggs/user/renwuqiehuan/nan_108X176_32bits.png#0 0 108 176",
        modelUrl = "character/CC/02human/paperman/boy02.x",
        modelOrder = 6,
        owned = false,
    },
    {
        id = 3,
        icon = "Texture/Aries/Creator/keepwork/ggs/user/renwuqiehuan/nan_108X176_32bits.png#0 0 108 176",
        modelUrl = "character/CC/02human/paperman/boy03.x",
        modelFrom = "模型商城",
        modelOrder = 1,
        owned = true,
    },
    {
        id = 4,
        icon = "Texture/Aries/Creator/keepwork/ggs/user/renwuqiehuan/nan_108X176_32bits.png#0 0 108 176",
        modelUrl = "character/CC/02human/paperman/boy04.x",
        modelOrder = 4,
        owned = true,
    },
}; 

_G.GetAllAssets = function()
    local bagId, bagNo = 0, 1007;
    local assets = {}; 
    for _, bag in ipairs(KeepWorkItemManager.bags) do
        if (bagNo == bag.bagNo) then 
            bagId = bag.id;
            break;
        end
    end
    
    local userAssets = _G.GetUserAssets();
    local userinfo = GlobalScope:Get("UserDetail");
    local isVip = userinfo.vip == 1;

    -- Log(userinfo)

    local function IsOwned(item)
        local vip_enabled = (item.extra or {}).vip_enabled;
        if (isVip and vip_enabled) then return true end
        for _, asset in ipairs(userAssets) do
            if (asset.id == item.id) then return true end
        end
        return false;
    end

    for _, tpl in ipairs(KeepWorkItemManager.globalstore) do
        local extra = tpl.extra or {};
        -- echo(extra, true)
        if (tpl.bagId == bagId and extra.modelFrom) then
            -- 客户端临时处理 下架套装
            if(tpl.id ~= 5087 and tpl.id ~= 5067 and tpl.id ~= 5090 and tpl.id ~= 5077) then
                table.insert(assets, {
                    id = tpl.id,
                    gsId = tpl.gsId,
                    modelUrl = tpl.modelUrl,
                    modelFrom = if_else(not extra.modelFrom or extra.modelFrom == "", nil, extra.modelFrom),
                    modelOrder = tonumber(extra.modelOrder or 0) or 0,
                    icon = GetItemIcon(tpl),
                    name = tpl.name,
                    desc = tpl.desc,
                    owned = IsOwned(tpl),
                    requireVip = tpl.extra and tpl.extra.vip_enabled,
                    skin = tpl.extra and tpl.extra.skin;
                });
            end
        end
    end

    -- assets = PlayerAssetList;
    -- Log(assets, true);

    table.sort(assets, function(asset1, asset2) 
        -- return (not asset2.owned and asset1.owned) or asset1.modelOrder < asset2.modelOrder;
        return asset1.modelOrder < asset2.modelOrder;
    end);
    
    GlobalScope:Set("AllAssets", assets);
    return assets;
end
CheckSkin.GetAllAssets = GetAllAssets;

_G.GetUserShowGoods = function()
    local bagNo = 1001;
    local goods = {}; 
    for _, item in ipairs(KeepWorkItemManager.items) do
        local copies = item.copies or 0;
        if (item.bagNo == bagNo and copies > 0) then
            local itemTpl = KeepWorkItemManager.GetItemTemplate(item.gsId);
            if (itemTpl) then
                table.insert(goods, {
                    icon = GetItemIcon(itemTpl),
                    copies = copies,
                    name = itemTpl.name,
                    desc = itemTpl.desc,
                });
                if ((itemTpl.extra or {}).VIP_cloth_7days and itemTpl.expiredSeconds) then
                    local timestamp = commonlib.timehelp.GetTimeStampByDateTime(item.expireTime);
                    local obj = os.date("*t", timestamp - itemTpl.expiredSeconds);
                    local datetime = string.format("%s/%s/%s", obj.year, obj.month, obj.day);
                    local goods_item = goods[#goods];
                    goods_item.desc = (goods_item.desc or "") .. string.format("\n开始日期: %s\n有效期剩余: %s 小时", datetime, math.floor((timestamp - os.time()) / 3600));
                end
            end
        end
    end
    return goods;
end

_G.GetUserHonors = function ()
    local bagNo = 1006;
    local honors = {}; 
    for _, item in ipairs(KeepWorkItemManager.items) do
        if (item.bagNo == bagNo) then
            local itemTpl = KeepWorkItemManager.GetItemTemplate(item.gsId);
            if (itemTpl) then
                table.insert(honors, {
                    icon = GetItemIcon(itemTpl),
                    name = itemTpl.name,
                    desc = itemTpl.desc,
                });
            end
        end
    end
    return honors;
end


_G.UpdatePlayerEntityInfo = function()
    local isAuthUser = GlobalScope:Get("isAuthUser");
    local AuthUserId = GlobalScope:Get("AuthUserId");
    -- 更新用户信息
    if (not isAuthUser) then return end
    --local player = GameLogic.GetPlayerController():GetPlayer();
    local asset = MyCompany.Aries.Game.PlayerController:GetMainAssetPath()
    local skin = MyCompany.Aries.Game.PlayerController:GetSkinTexture()
    print("asset:" , asset);
    print("skin:", skin);
    local extra = UserDetail.extra or {};
    extra.ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo or {};
    extra.ParacraftPlayerEntityInfo.asset = asset;
    extra.ParacraftPlayerEntityInfo.skin = skin;
    extra.ParacraftPlayerEntityInfo.assetSkinGoodsItemId = GlobalScope:Get("AssetSkinGoodsItemId");
    keepwork.user.setinfo({
        router_params = {id = AuthUserId},
        extra = extra,
    }, function(status, msg, data) 
        if (status < 200 or status >= 300) then return echo("更新玩家实体信息失败") end
        local userinfo = KeepWorkItemManager.GetProfile();
        userinfo.extra = extra;
    end);
end 

-- _G.SetScrollElement = function(el)
--     local verticalScrollBar = el and el:GetVerticalScrollBar();
--     if (not verticalScrollBar) then return end
--     verticalScrollBar:SetStyleValue("background-color", "#ffffff00");
--     verticalScrollBar:GetThumb():SetStyleValue("background", "Texture/Aries/Creator/keepwork/ggs/dialog/xiala_12X38_32bits.png#0 0 12 38:2 5 2 5");
--     verticalScrollBar:GetThumb():SetStyleValue("min-height", 10);
-- end

_G.GetAvatarItems = function(category)
    local asset = GetGlobalScope():Get("MainAsset");
    local skin = GetGlobalScope():Get("MainSkin");
    local items = CustomCharItems:GetModelItems(asset, category, skin, true);
    GlobalScope:Set("AvatarItems", items);
    -- commonlib.echo("info of items");
    -- commonlib.echo(items, true);
    return items;
end

LoadUserInfo();