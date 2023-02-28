--[[
	Title: CheckSkin
	Author(s): cf
	Date: 2021/7/19
	Desc: 玩学课堂选择页
	Use Lib:
        local CheckSkin = NPL.load("(gl)Mod/GeneralGameServerMod/UI/Vue/Page/User/CheckSkin.lua");
        CheckSkin.Show(function() end, "80001;84078;81018;88014;85098;", function() end) 
        CheckSkin.Hide();
--]]

local CheckSkin = NPL.export();
local page;
local pe_gridview = commonlib.gettable("Map3DSystem.mcml_controls.pe_gridview");
local RedSummerCampMainPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/RedSummerCamp/RedSummerCampMainPage.lua");
local StudyPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/StudyPage.lua");
local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua");
local KeepWorkItemManager = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/KeepWorkItemManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CustomCharItems.lua");
local CustomCharItems = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CustomCharItems")
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local Keepwork = NPL.load("(gl)script/apps/Aries/Creator/HttpAPI/Keepwork.lua");
CustomCharItems:Init()

CheckSkin.SKIN_ITEM_TYPE = {
	FREE = "0",
	VIP = "1",
	ONLY_BEANS_CAN_PURCHASE = "2",
	ACTIVITY_GOOD = "3",
	-- 套装部件
	SUIT_PART = "5"
}

-- 知识豆购买的皮肤数据在serverData字段
CheckSkin.ONLY_BEANS_CAN_PURCHASE_GSID = 17;
CheckSkin.BEAN_GSID = 998;

CheckSkin.DS = {
	-- percent; remainingdays; price; processBarVal; itemType; icon
	items = {},
	totalPrice = 0,
}

-- { itemId:int, category:string, price:int, startAt:DateString }
CheckSkin.ServerDataClother = nil;
CheckSkin.closeFunc = nil;
CheckSkin.CloseWithoutChange = nil;
-- default skin, head;eye;month;
CheckSkin.DEFAULT_SKIN = "80001;81018;88014;";

function CheckSkin.OnInit()
	page = document:GetPageCtrl();
	page.OnCreate = CheckSkin.OnCreate
end

function CheckSkin.Show(closeFunc, skin, CloseWithoutChange) 
	CheckSkin.closeFunc = closeFunc;
	CheckSkin.CloseWithoutChange = CloseWithoutChange;
	CheckSkin.InitData(skin);
end;

function CheckSkin.ShowPage()

	local params = {
		url = "script/ide/System/UI/Vue/Page/User/CheckSkin.html",
		name = "CheckSkin.Show", 
		isShowTitleBar = false,
		DestroyOnClose = true,
		style = CommonCtrl.WindowFrame.ContainerStyle,
		allowDrag = true,
		enable_esc_key = true,
		zorder = 0,
		-- app_key = MyCompany.Aries.Creator.Game.Desktop.App.app_key, 
		directPosition = true,
		align = "_ct",
		x = -768/2,
		y = -470/2,
		width = 768,
		height = 470,
	};
	System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function CheckSkin.GetCheckInfoFromSkin(items, callback)
	keepwork.user.getCheckInfoFromSkin({
		clothes = items,
		totalPrice = totalPrice
	}, callback)
end

--- @param skin string: curSkin 试穿skin
function CheckSkin.InitData(skin)

	if (skin:match("^%d+#")) then
		skin = CustomCharItems:SkinStringToItemIds(skin);
	end
	LOG.std(nil, 'info', 'curSkin', skin);
	LOG.std(nil, 'info', 'CheckSkin.GetClothesOfServerData()', CheckSkin.GetClothesOfServerData());
	
	KeepWorkItemManager.GetUserInfoExtraSkinFromDataBase(function (skin)
		LOG.std(nil, 'info', 'GetUserInfoExtraSkinFromDataBase', skin);
	end)
	
	-- init data
	CheckSkin.DS.items = {};
	CheckSkin.DS.totalPrice = 0;
	local itemIds = commonlib.split(skin, ";");
	local DEFAULT_HEAD_SKIN = "80001";

	if (itemIds and #itemIds > 0) then
		local items = {};
		for _, id in ipairs(itemIds) do
			local data = CustomCharItems:GetItemById(id);
			if (data) then
				local val = {
					id = id,
					icon = data.icon,
					type = data.type,
					price = data.price or "0",
					name = data.name,
					category = data.category,
				}
	
				if(id ~= DEFAULT_HEAD_SKIN) then
					table.insert( items, val )
				end
			end
		end

		LOG.std(nil, 'info', 'items', items);
		local req = commonlib.map(items, function (item)
			return {
				category = item.category,
				itemId = item.id,
				price = item.price,
			}
		end)
		LOG.std(nil, 'info', 'req', req);

		-- 获取结算清单明细
		CheckSkin.GetCheckInfoFromSkin(req, function (code, msg, data)
			LOG.std(nil, 'info', 'code', code);
			LOG.std(nil, 'info', 'msg', msg);
			LOG.std(nil, 'info', 'data', data);
			local clothes = data.clothes;
			local isVip = KeepWorkItemManager.IsVip()
			local isDefaultSkin = skin == CheckSkin.DEFAULT_SKIN
			local diffSkins = CheckSkin.DiffFromSkin(skin, originSkin)

			CheckSkin.DS.items = commonlib.map(clothes, function (item)
				local data = CustomCharItems:GetItemById(tostring(item.itemId));
				local val = {
					-- 需要支付的价格
					price = item.payPrice,
					remainingdays = item.durability,
					itemId = item.itemId,
					category = data.category,
					icon = data.icon,
					type = data.type,
					name = data.name,
					is_vip_use = false,
				}
				-- 设置文案
				if(data.type == CheckSkin.SKIN_ITEM_TYPE.FREE) then
					val.price = "免费使用"
				end
				if(data.type == CheckSkin.SKIN_ITEM_TYPE.SUIT_PART) then
					if(CheckSkin.IsUserOwnedThisSuitPartTypeSkin(item.itemId)) then
						val.price = "免费使用"
					else
						val.price = "仅VIP可用"
						val.is_vip_use = true
					end
				end
				if(data.type == CheckSkin.SKIN_ITEM_TYPE.VIP) then
					val.price = "仅VIP可用"
					val.is_vip_use = true
				end
				if(data.type == CheckSkin.SKIN_ITEM_TYPE.ACTIVITY_GOOD) then
					if (data.gsid and not KeepWorkItemManager.HasGSItem(data.gsid)) then
						val.price = "需活动获得"
					else
						val.price = "免费使用"
					end;
				end

				if(data.type == CheckSkin.SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE) then
					-- 总金额
					CheckSkin.DS.totalPrice = CheckSkin.DS.totalPrice+ (item.payPrice or 0)
				end

				return val;
			end);
	
			-- 没有替换 & VIP 则直接关闭
			if(diffSkins == "" or isVip or isDefaultSkin or (CheckSkin.DS.totalPrice == 0)) then
				CheckSkin.closeFunc()
			else
				CheckSkin.ShowPage()
				CheckSkin.Update()
			end;
		end)
	else
		-- 切换套装时
		CheckSkin.closeFunc()
	end
end

function CheckSkin.DiffFromSkin(curSkin, oriSkin)
	local curItemIds = commonlib.split(curSkin, ";");
	local oriItemIds = commonlib.split(oriSkin, ";");
	local skin = "";
	local map = {};
	LOG.std(nil, 'info', 'curItemIds', curItemIds);
	LOG.std(nil, 'info', 'oriItemIds', oriItemIds);

	for _, oriId in ipairs(oriItemIds) do
		map[oriId] = 1;
	end

	for _, curId in ipairs(curItemIds) do
		if(not map[curId]) then
			skin = skin..curId..";"
		end
	end

	return skin;
end

--- @return table: 获取需要知识豆购买类型的skin
function CheckSkin.GetClothesOfServerData()
	local bOwn, id, bagId, copies, item = KeepWorkItemManager.HasGSItem(CheckSkin.ONLY_BEANS_CAN_PURCHASE_GSID);

	LOG.std(nil, 'info', 'GetClothesOfServerData', item);
	if(item and item.serverData) then
		return item.serverData.clothes
	end

	return nil;
end

function CheckSkin.Purchase()
	local items = {};
	for _, v in ipairs(CheckSkin.DS.items) do
		if(v.type == CheckSkin.SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE) then
			table.insert(items, {
				category = v.category,
				itemId = v.itemId,
				price = v.price
			});
		end
	end;

	LOG.std(nil, 'info', 'CheckSkin.Purchase_items', items);
	local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(CheckSkin.BEAN_GSID)
	local myBean = copies or 0;
	local totalPrice = CheckSkin.DS.totalPrice;

	if(myBean < totalPrice) then
		_guihelper.MessageBox("知识豆不足, 无法购买~", function ()
			CheckSkin.Close()
			CheckSkin.closeFunc();
		end);
		return;
	end

	if(#items > 0) then
		keepwork.user.buySkinUsingBean({
			clothes = items,
			totalPrice = totalPrice
		},	function(code, msg, data)
			LOG.std(nil, 'info', 'code', code);
			LOG.std(nil, 'info', 'msg', msg);
			LOG.std(nil, 'info', 'data', data);
	
			-- 购买成功 更新皮肤
			if code == 200 then
				-- refresh user goods
				KeepWorkItemManager.LoadItems(nil, CheckSkin.closeFunc)
				CheckSkin.Close()
			else
				_guihelper.MessageBox("系统异常", CheckSkin.Close);
				CheckSkin.closeFunc();
			end
		end)
	else
		CheckSkin.closeFunc()
		CheckSkin.Close()
	end
end

function CheckSkin.Update()
	if(page) then
		page:Refresh(0)
	end

	local rightContainer = page:GetNode("item_gridview");
	pe_gridview.SetDataSource(
		rightContainer, 
		page.name, 
		CheckSkin.DS.items);
	pe_gridview.DataBind(rightContainer, page.name, false);

	CheckSkin.RefreshBeanNum()
end

-- 非VIP的情况，删除未拥有的skin
function CheckSkin.RemoveAllUnvalidItems(skin)
	LOG.std(nil, 'info', 'removeAllUnvalidItems');
	LOG.std(nil, 'info', 'before skin', skin);
	local currentSkin = skin;
	local itemIds = commonlib.split(skin, ";");
	-- get user goods
	local clothes = CheckSkin.GetClothesOfServerData() or {};
	LOG.std(nil, 'info', 'user clothes', clothes);

	if (itemIds and #itemIds > 0) then
		for _, id in ipairs(itemIds) do
			local data = CustomCharItems:GetItemById(id);
			if (data) then
				-- 活动商品
				if(data.type == CheckSkin.SKIN_ITEM_TYPE.ACTIVITY_GOOD) then
					if(not KeepWorkItemManager.HasGSItem(data.gsid)) then
						currentSkin = CustomCharItems:RemoveItemInSkin(currentSkin, id);
					end;
				end;

				-- 免费
				if(data.type == CheckSkin.SKIN_ITEM_TYPE.FREE) then
					--
				end;

				-- 套装部件
				if(data.type == CheckSkin.SKIN_ITEM_TYPE.SUIT_PART) then
					-- 先查询拥有套装，再查询拥有套装下的皮肤，--
					if(not CheckSkin.IsUserOwnedThisSuitPartTypeSkin(id)) then
						currentSkin = CustomCharItems:RemoveItemInSkin(currentSkin, id);
					end
				end;

				-- VIP可用
				if(data.type == CheckSkin.SKIN_ITEM_TYPE.VIP) then
					currentSkin = CustomCharItems:RemoveItemInSkin(currentSkin, id);
				end;

				-- 知识豆可购买类型
				if(data.type == CheckSkin.SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE) then
					-- 用户是否拥有该皮肤
					local serverDataSkin = commonlib.find(clothes, function (item)
						return item.itemId == tonumber(id)
					end);
					LOG.std(nil, 'info', 'serverDataSkin', serverDataSkin);
					LOG.std(nil, 'info', 'data id', id);

					if(not serverDataSkin) then
						currentSkin = CustomCharItems:RemoveItemInSkin(currentSkin, id);
					end;
				end;
			end
		end
	end

	LOG.std(nil, 'info', 'after skin', currentSkin);
	return currentSkin;
end

-- 套装部件的特殊处理
function CheckSkin.IsUserOwnedThisSuitPartTypeSkin(id)
	local AllAssets = CheckSkin.GetAllAssetsAndSkin()
	local ownedAsset = commonlib.filter(AllAssets, function (item)
		return item.owned
	end);

	for index, value in ipairs(ownedAsset) do
		-- 判断是否套装部件
		local skinStringIds = CustomCharItems.ReplaceableAvatars[value.modelUrl]
		if(skinStringIds) then
			local itemIds = commonlib.split(skinStringIds, ";");
			LOG.std(nil, 'info', 'itemIds', itemIds);
			for index, skinId in ipairs(itemIds) do
				if(skinId == tostring(id)) then
					return true;
				end
			end
		end
	end
	
	return false;
end

--- 清除未拥有的活动商品
function CheckSkin.RemoveActivityItems(skin)
	LOG.std(nil, 'info', 'removeActivityItems');
	LOG.std(nil, 'info', 'before skin', skin);
	local currentSkin = skin;
	local itemIds = commonlib.split(skin, ";");
	
	if (itemIds and #itemIds > 0) then
		for _, id in ipairs(itemIds) do
			local data = CustomCharItems:GetItemById(id);
			if (data 
				and (data.type == CheckSkin.SKIN_ITEM_TYPE.ACTIVITY_GOOD)
				and data.gsid
				-- 未拥有
				and (not KeepWorkItemManager.HasGSItem(data.gsid))
			) then
				currentSkin = CustomCharItems:RemoveItemInSkin(currentSkin, id);
			end
		end
	end

	LOG.std(nil, 'info', 'after skin', currentSkin);
	return currentSkin;
end

function CheckSkin.Close()
	if(page) then
		page:CloseWindow(0);
	end
end

function CheckSkin.ShowVip()
    local VipPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/VipPage.lua");
    VipPage.ShowPage("ChangeAvatarSkin", "尽享精彩形象");
end 

function CheckSkin.ClosePage()
	CheckSkin.Close();
	CheckSkin.CloseWithoutChange()
end

function CheckSkin.UpdateTotalPrice()
	local totalPrice = 0
	for key, v in pairs(CheckSkin.DS.items) do
		if(v.type == CheckSkin.SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE) then
			-- 总金额
			totalPrice = totalPrice+v.price
		end
	end
	CheckSkin.DS.totalPrice = totalPrice
end

function CheckSkin.DeleteSelf(index)
	local item = CheckSkin.DS.items[index]
	if item == nil then
		return
	end

	table.remove(CheckSkin.DS.items, index)
	CheckSkin.UpdateTotalPrice()
	CheckSkin.Update()
end

function CheckSkin.OnCreate()
	CheckSkin.RefreshBeanNum()
end

function CheckSkin.RefreshBeanNum()
    local bHas,guid,bagid,copies = KeepWorkItemManager.HasGSItem(CheckSkin.BEAN_GSID)
    copies = copies or 0;
	page:SetValue("bean_label", copies)
end

function CheckSkin.CheckUserSkin()
	local user_skin = GameLogic.GetPlayerController():GetSkinTexture()

	-- 没皮肤的话不检查
	if not user_skin or user_skin == "" then
		return
	end

	-- 默认裸装的皮肤的话不检查
	local default_skin = CustomCharItems:SkinStringToItemIds(CustomCharItems.defaultSkinString);
	if user_skin == default_skin then
		return
	end

	-- 看看是否vip 是vip的话 只需管活动物品
	local isVip = KeepWorkItemManager.IsVip()
	if isVip then
		user_skin = CheckSkin.RemoveActivityItems(user_skin);
		return
	end

	local itemIds = commonlib.split(user_skin, ";");
	local DEFAULT_HEAD_SKIN = "80001";
	if (itemIds and #itemIds > 0) then
		local items = {};
		
		for _, id in ipairs(itemIds) do
			local data = CustomCharItems:GetItemById(id);
			if (data) then
				local val = {
					id = id,
					icon = data.icon,
					type = data.type,
					price = data.price or "0",
					name = data.name,
					category = data.category,
				}
	
				if(id ~= DEFAULT_HEAD_SKIN) then
					table.insert( items, val )
				end
			end
		end

		local req = commonlib.map(items, function (item)
			return {
				category = item.category,
				itemId = item.id,
				price = item.price,
			}
		end)

		-- 获取结算清单明细
		CheckSkin.GetCheckInfoFromSkin(req, function (code, msg, data)
			local clothes = data.clothes or {};

			-- 找出不能使用了的皮肤,替换掉
			local result_skin = user_skin
			for index, item in ipairs(clothes) do
				local data = CustomCharItems:GetItemById(tostring(item.itemId));
				if(data.type ~= CheckSkin.SKIN_ITEM_TYPE.FREE) then
					-- val.price = "免费使用"
					if data.type == CheckSkin.SKIN_ITEM_TYPE.VIP then
						result_skin = CustomCharItems:RemoveItemInSkin(result_skin, item.itemId)
					elseif(data.type == CheckSkin.SKIN_ITEM_TYPE.SUIT_PART) then
						-- 不是可免费使用的部件
						if not CheckSkin.IsUserOwnedThisSuitPartTypeSkin(item.itemId) then
							result_skin = CustomCharItems:RemoveItemInSkin(result_skin, item.itemId)
						end
					elseif(data.type == CheckSkin.SKIN_ITEM_TYPE.ACTIVITY_GOOD) then
						if (data.gsid and not KeepWorkItemManager.HasGSItem(data.gsid)) then
							result_skin = CustomCharItems:RemoveItemInSkin(result_skin, item.itemId)
						end
					elseif(data.type == CheckSkin.SKIN_ITEM_TYPE.ONLY_BEANS_CAN_PURCHASE) then
						-- 知识豆购买的 看看是否还有时间
						
						if item.durability and item.durability == 0 then
							result_skin = CustomCharItems:RemoveItemInSkin(result_skin, item.itemId)
						end
					end
				end
			end

			if result_skin ~= user_skin then
				local playerEntity = GameLogic.GetPlayerController():GetPlayer();
				if playerEntity then
					playerEntity:SetSkin(result_skin); 
				end
				GameLogic.options:SetMainPlayerSkins(result_skin);

				CheckSkin.UpdatePlayerEntityInfo()
				GameLogic.GetFilters():apply_filters("user_skin_change", result_skin);
			end


			-- local result_items = commonlib.map(clothes, function (item)
			-- 	local data = CustomCharItems:GetItemById(tostring(item.itemId));
			-- 	local val = {
			-- 		-- 需要支付的价格
			-- 		price = item.payPrice,
			-- 		remainingdays = item.durability,
			-- 		itemId = item.itemId,
			-- 		category = data.category,
			-- 		icon = data.icon,
			-- 		type = data.type,
			-- 		name = data.name,
			-- 		is_vip_use = false,
			-- 	}
			-- 	-- 设置文案
			-- 	if(data.type == CheckSkin.SKIN_ITEM_TYPE.FREE) then
			-- 		val.price = "免费使用"
			-- 	end
			-- 	if(data.type == CheckSkin.SKIN_ITEM_TYPE.SUIT_PART) then
			-- 		if(CheckSkin.IsUserOwnedThisSuitPartTypeSkin(item.itemId)) then
			-- 			val.price = "免费使用"
			-- 		else
			-- 			val.price = "仅VIP可用"
			-- 			val.is_vip_use = true
			-- 		end
			-- 	end
			-- 	if(data.type == CheckSkin.SKIN_ITEM_TYPE.VIP) then
			-- 		val.price = "仅VIP可用"
			-- 		val.is_vip_use = true
			-- 	end
			-- 	if(data.type == CheckSkin.SKIN_ITEM_TYPE.ACTIVITY_GOOD) then
			-- 		if (data.gsid and not KeepWorkItemManager.HasGSItem(data.gsid)) then
			-- 			val.price = "需活动获得"
			-- 		else
			-- 			val.price = "免费使用"
			-- 		end;
			-- 	end

			-- 	return val;
			-- end);

			-- print("xxxxxxxxxxxxwww")
			-- echo(result_items, true)
		end)
	else
		-- 切换套装时
		CheckSkin.closeFunc()
	end
end

function CheckSkin.GetAllAssetsAndSkin()
    local bagId, bagNo = 0, 1007;
    local assets = {}; 
    for _, bag in ipairs(KeepWorkItemManager.bags) do
        if (bagNo == bag.bagNo) then 
            bagId = bag.id;
            break;
        end
    end
    
    local userAssets = CheckSkin.GetUserAssets();
    local isVip = GameLogic.IsVip()

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
                    icon = CheckSkin.GetItemIcon(tpl),
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
    
    return assets;
end

function CheckSkin.GetUserAssets()
    local bagNo = 1007;
    local assets = {};

    for _, item in ipairs(KeepWorkItemManager.items) do
        if (item.bagNo == bagNo) then
            local tpl = KeepWorkItemManager.GetItemTemplate(item.gsId);
            if (tpl) then
                table.insert(assets, {
                    id = tpl.id,
                    modelUrl = tpl.modelUrl,
                    icon = CheckSkin.GetItemIcon(tpl),
                    name = tpl.name,
                    skin = tpl.extra and tpl.extra.skin;
            });
            end
        end
    end

    return assets;
end

function CheckSkin.GetItemIcon(item, suffix)
    local icon = item.icon;
    if(not icon or icon == "" or icon == "0") then icon = string.format("Texture/Aries/Creator/keepwork/items/item_%d%s_32bits.png", item.gsId, suffix or "") end
    return icon;
end

function CheckSkin.UpdatePlayerEntityInfo()
	local userinfo = Keepwork:GetUserInfo();
    local AuthUserId = userinfo.id;
    -- 更新用户信息
    --local player = GameLogic.GetPlayerController():GetPlayer();
    local asset = MyCompany.Aries.Game.PlayerController:GetMainAssetPath()
    local skin = MyCompany.Aries.Game.PlayerController:GetSkinTexture()
    local extra = userinfo.extra or {};
    extra.ParacraftPlayerEntityInfo = extra.ParacraftPlayerEntityInfo or {};
    extra.ParacraftPlayerEntityInfo.asset = asset;
    extra.ParacraftPlayerEntityInfo.skin = skin;
    -- extra.ParacraftPlayerEntityInfo.assetSkinGoodsItemId = GlobalScope:Get("AssetSkinGoodsItemId");
    keepwork.user.setinfo({
        router_params = {id = AuthUserId},
        extra = extra,
    }, function(status, msg, data) 
        if (status < 200 or status >= 300) then return echo("更新玩家实体信息失败") end
        local userinfo = KeepWorkItemManager.GetProfile();
        userinfo.extra = extra;
    end);
end 