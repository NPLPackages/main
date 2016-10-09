--[[
Author: WangTian
Date: 2008-1-29
Desc: testing BagCtl.
-----------------------------------------------
NPL.load("(gl)script/test/TestBagCtl.lua");
TestBagCtl();
-----------------------------------------------
]]

function TestBagCtl()
	
	local _this = ParaUI.CreateUIObject("container", "TestBagCtl", "_lt", 200, 200, 600, 400);
	_this:AttachToRoot();
	
	NPL.load("(gl)script/kids/3DMapSystemApp/Inventory/BagCtl.lua");
	
	-- root bag
	local rootBag = Map3DSystem.App.Inventory.Bag:new({})
	rootBag.objects = {};
	rootBag:AddObject({name = "1", ButtonText = "R1", IsTradable = nil, icon = "Texture/3DMapSystem/Inventory/TempIcons/Icon1.png; 0 0 48 48"});
	rootBag:AddObject({name = "2", ButtonText = "R2", IsTradable = nil, icon = "Texture/3DMapSystem/Inventory/TempIcons/Icon2.png; 0 0 48 48"});
	rootBag:AddObject({name = "3", ButtonText = "R3", IsTradable = nil, icon = "Texture/3DMapSystem/Inventory/TempIcons/Icon3.png; 0 0 48 48"});
	
	-- mini bag
	local miniBag = Map3DSystem.App.Inventory.Bag:new({})
	miniBag.objects = {};
	miniBag:AddObject({name = "1", ButtonText = "M1", IsTradable = nil, icon = "Texture/3DMapSystem/Inventory/TempIcons/Icon1.png; 0 0 48 48"});
	miniBag:AddObject({name = "2", ButtonText = "M2", IsTradable = nil, icon = "Texture/3DMapSystem/Inventory/TempIcons/Icon2.png; 0 0 48 48"});
	miniBag:AddObject({name = "3", ButtonText = "M3", IsTradable = nil, icon = "Texture/3DMapSystem/Inventory/TempIcons/Icon3.png; 0 0 48 48"});
	
	-- exchange bag
	local exchangeBag = Map3DSystem.App.Inventory.Bag:new({})
	exchangeBag.objects = {};
	exchangeBag:AddObject({name = "1", ButtonText = "E1", IsTradable = nil, icon = "Texture/3DMapSystem/Inventory/TempIcons/Icon1.png; 0 0 48 48"});
	exchangeBag:AddObject({name = "2", ButtonText = "E2", IsTradable = nil, icon = "Texture/3DMapSystem/Inventory/TempIcons/Icon2.png; 0 0 48 48"});
	exchangeBag:AddObject({name = "3", ButtonText = "E3", IsTradable = nil, icon = "Texture/3DMapSystem/Inventory/TempIcons/Icon3.png; 0 0 48 48"});
	
	
	local ctl = Map3DSystem.App.Inventory.BagCtl:new{
		name = "CurrentUserRootBagCtl",
		left = 20,
		top = 20,
		
		slotBG = "Texture/3DMapSystem/Inventory/SlotBG.png",
		highLightBG = "",
		
		type = nil,
		rows = 3,
		columns = 4,
		itemwidth = 64,
		itemheight = 64,
		parent = _this,
		
		bag = rootBag,
	};
	ctl:Show();
	
	local ctl = Map3DSystem.App.Inventory.BagCtl:new{
		name = "TestMiniBagCtl",
		left = 350,
		top = 40,
		
		slotBG = "Texture/3DMapSystem/Inventory/SlotBG.png",
		highLightBG = "",
		
		type = nil,
		rows = 4,
		columns = 3,
		itemwidth = 64,
		itemheight = 64,
		parent = _this,
		
		bag = miniBag,
	};
	ctl:Show();
	
	local ctl = Map3DSystem.App.Inventory.BagCtl:new{
		name = "TestExchangeBagCtl",
		left = 30,
		top = 250,
		
		slotBG = "Texture/3DMapSystem/Inventory/SlotBG.png",
		highLightBG = "",
		
		type = nil,
		rows = 2,
		columns = 2,
		itemwidth = 64,
		itemheight = 64,
		parent = _this,
		
		bag = exchangeBag,
	};
	ctl:Show();
end