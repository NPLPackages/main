--[[
Author: WangTian
Date: 2008/1/21
Desc: testing GridView3D.
-----------------------------------------------
NPL.load("(gl)script/test/TestGridView3D.lua");
TestGridView3D();
-----------------------------------------------
]]

function TestGridView3D()
	------------------------
	-- basic node testing
	------------------------
	
	NPL.load("(gl)script/ide/GridView3D.lua");
	local ctl = CommonCtrl.GridView3D:new{
		name = "GridView3D11",
		alignment = "_lt",
		left = 0, top = 30,
		width = 256,
		height = 128,
		cellWidth = 64,
		cellHeight = 64,
		parent = nil,
		columns = 4,
		rows = 2,
		
		renderTargetSize = 512,
		
		DrawCellHandler = DrawCCSItemCellHandler,
		};
	
	--local i, j;	
	--for i = 0, 9 do
		--for j = 0, 9 do
			--local cell = CommonCtrl.GridCell:new{
				--GridView = nil,
				--name = i.."-"..j,
				--text = i.."-"..j,
				--column = 1,
				--row = 1,
				--};
			--ctl:InsertCell(cell, "Right");
		--end
	--end
	
	local CCSdbfile = "Database/characters.db";
	
	local db = sqlite3.open(Map3DSystem.UI.CCS.DB.dbfile);
	local row;
	
	local i;
	for i = 1, table.getn(Map3DSystem.UI.CCS.Inventory.Items) do
		local index = Map3DSystem.UI.CCS.Inventory.Items[i];
		
		local model, skin;
		for row in db:rows(string.format("select Model, Skin from ItemDisplayDB where ItemDisplayID = %d", index)) do
			model = row.Model;
			skin = row.Skin;
		end
		
		local row = math.ceil(i/4);
		local column = i - (row - 1) * 4;
		
		local cell = CommonCtrl.GridCell3D:new{
			GridView = nil,
			name = row.."-"..column,
			text = row.."-"..column,
			column = column,
			row = row,
			-- CCS item specified info
			type = "head",
			model = model,
			skin = skin,
			};
		ctl:InsertCell(cell, "Right");
	end
	
	
	db:close();
	
	ctl:Show();
	
end


function DrawCCSItemCellHandler(_parent, cell)
	-- simply attach a drawing board on the position	
	local scene = cell.GridView3D:GetMiniSceneGraph();
	--scene:RemoveObject(obj);
	
	if(cell ~= nil) then
		local _this = ParaUI.CreateUIObject("button", cell.text, "_fi", 2, 2, 2, 2);
		_this.background = "";
		_this.onclick = string.format([[;_guihelper.MessageBox("GridView3D Click: %s  %s  %s");]], 
				cell.GridView3D.name, cell.row, cell.column);
		--_this.onmouseenter = "";
		--_this.onmouseleave = "";
		_parent:AddChild(_this);
	end
	
	local model, skin;
	model = cell.model;
	skin = cell.skin;
	if(string.find(model, ".x") == nil and string.find(model, ".X") == nil) then
		model = model..".x";
	end
	--local _assetName = "model/common/ccs_unisex/shirt06_TU1_TL2_AU3_AL4.x";
	
	local _assetName;
	if(cell.type == "head") then
		_assetName = "character/v3/Item/ObjectComponents/Head/"..model;
	elseif(cell.type == "shoulder") then
		_assetName = "character/v3/Item/ObjectComponents/Shoulder/"..model;
	elseif(cell.type == "weapon" or cell.type == "lefthand" or cell.type == "righthand") then
		_assetName = "character/v3/Item/ObjectComponents/Weapon/"..model;
	elseif(cell.type == "cape") then
		-- TODO: unisex unirace cape model
		_assetName = "character/v3/Item/ObjectComponents/Cape/"..model;
	end
	
	local _asset = ParaAsset.LoadStaticMesh("", _assetName);
	local obj = ParaScene.CreateMeshPhysicsObject("fddewqsa", _asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	if(obj:IsValid()) then
		obj:SetFacing(1.57);
		obj:GetAttributeObject():SetField("progress", 1);
		
		local aabb = {};
		_asset:GetBoundingBox(aabb);
		local dx = math.abs(aabb.max_x - aabb.min_x);
		local dy = math.abs(aabb.max_y - aabb.min_y);
		local dz = math.abs(aabb.max_z - aabb.min_z);
		
		local max = math.max(dx, dy);
		max = math.max(max, dz);
		
		obj:SetPosition(cell.logicalX, cell.logicalY, 0);
		
		--obj:SetPosition(3.2, -6.4, 0);
		obj:SetScale(6.4/max);
		local att = obj:GetAttributeObject();
		att:SetField("render_tech", 10);
		
		scene:AddChild(obj);
		
		--local _Head = "character/v3/Item/TextureComponents/TorsoLowerTexture/MomoMale05_he_TL_U.DDS"
		
		
		--local _texName;
		--
		--if(cell.type == "head") then
			--_texName = "character/v3/Item/ObjectComponents/Head/"..skin;
		--elseif(cell.type == "shoulder") then
			--_texName = "character/v3/Item/ObjectComponents/Shoulder/"..skin;
		--elseif(cell.type == "weapon" or cell.type == "lefthand" or cell.type == "righthand") then
			--_texName = "character/v3/Item/ObjectComponents/Weapon/"..skin;
		--elseif(cell.type == "cape") then
			---- TODO: unisex unirace cape model
			--_texName = "character/v3/Item/ObjectComponents/Cape/"..skin;
		--end
		--
		--local _texture = ParaAsset.LoadTexture("", _texName, 1);
		--obj:SetReplaceableTexture(0, _texture);
	end
end