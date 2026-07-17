--[[
Author: Li,Xizhi
Date: 2009-5-3
Desc: some test scripts for ParaScene
-----------------------------------------------
NPL.load("(gl)script/test/TestScene.lua");
TestParaScene:test_FBX_player()
-----------------------------------------------
]]
NPL.load("(gl)script/ide/event_mapping.lua");
NPL.load("(gl)script/ide/UnitTest/luaunit.lua");

TestParaScene = {}

-- create a player
function TestParaScene:test_CreatePlayer()
	local player = ParaScene.CreateCharacter ("MyPlayer", ParaAsset.LoadParaX("","character/v3/Elf/Female/ElfFemale.x"), "", true, 0.35, 0, 1.0);
	player:SetPosition(ParaScene.GetPlayer():GetPosition());
	ParaScene.Attach(player);
end	

function TestParaScene:test_CreateObjecct()
	local obj = ParaScene.CreateObject("BlockPieceParticle", "", 0, 0, 0);
	obj:SetPosition(ParaScene.GetPlayer():GetPosition());
	ParaScene.Attach(obj);
end

function TestParaScene.GameObjectEvent_OnFrameMove1()
	log("framemove1: "..ParaGlobal.GetTimeFormat(nil).."\n")
end

function TestParaScene.GameObjectEvent_OnFrameMove2()
	log("framemove2: "..ParaGlobal.GetTimeFormat(nil).."\n")
end

function TestParaScene:test_GameObjectEvent()

	local player = ParaScene.CreateCharacter ("MyPlayer1", ParaAsset.LoadParaX("","character/v3/Elf/Female/ElfFemale.x"), "", true, 0.35, 0, 1.0);
	player:SetPosition(ParaScene.GetPlayer():GetPosition());
	ParaScene.Attach(player);
	player:SetField("AlwaysSentient", true);
	player:SetField("Sentient", true);
	player:SetField("FrameMoveInterval", 500);
	player:SetField("On_FrameMove", [[;TestParaScene.GameObjectEvent_OnFrameMove1();]]);
	
	
	local player = ParaScene.CreateCharacter ("MyPlayer2", ParaAsset.LoadParaX("","character/v3/Elf/Female/ElfFemale.x"), "", true, 0.35, 0, 1.0);
	player:SetPosition(ParaScene.GetPlayer():GetPosition());
	ParaScene.Attach(player);
	player:SetField("AlwaysSentient", true);
	player:SetField("Sentient", true);
	player:SetField("On_FrameMove", [[;TestParaScene.GameObjectEvent_OnFrameMove2();]]);
	
end

function TestParaScene:test_GameObject_DistanceFunctions()

	local player = ParaScene.CreateCharacter ("MyPlayer1", ParaAsset.LoadParaX("","character/v3/Elf/Female/ElfFemale.x"), "", true, 0.35, 0, 1.0);
	local x, y, z = ParaScene.GetPlayer():GetPosition(); 
	x = x + 1;
	z = z + 1;
	player:SetPosition(x, y, z);
	ParaScene.Attach(player);

	-- test distance functions
	commonlib.echo(player:DistanceToSq(ParaScene.GetPlayer()));
	commonlib.echo(player:DistanceToCameraSq());
	commonlib.echo(player:DistanceToPlayerSq());
end

function TestParaScene:test_CtorProgress()
	local asset = ParaAsset.LoadStaticMesh("","model/common/editor/z.x")
	local obj = ParaScene.CreateMeshPhysicsObject("blueprint_center", asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	obj:SetPosition(ParaScene.GetPlayer():GetPosition());
	obj:SetField("progress",1);
	ParaScene.Attach(obj);
end

-- player density. 
function TestParaScene:test_PlayerDensityTest()
	local player = ParaScene.GetPlayer();
	-- floating on water. 90% of physics height under water
	player:SetDensity(0.9);
	-- flying on air. 
	-- player:SetDensity(0);
end

-- echo:return { alpha=19, b=63, g=82, r=19, rgb=164 }
-- in terrain tile config file, we can define any number of region layers:
--		NumOfRegions=1
--		(sound, %WORLD%/config/flatgrassland_0_0.png)
function TestParaScene:test_TerrainRegionTest()

	-- get a pixel value of a given region layer.
	local x, _, y = ParaScene.GetPlayer():GetPosition();
	commonlib.echo( { 
		alpha = ParaTerrain.GetRegionValue("sound", x, y, "a"),
		r = ParaTerrain.GetRegionValue("sound", x, y, "r"),
		g = ParaTerrain.GetRegionValue("sound", x, y, "g"),
		b = ParaTerrain.GetRegionValue("sound", x, y, "b"),
		rgb = ParaTerrain.GetRegionValue("sound", x, y, "rgb"),
		})

	-- iterate and display all region layers
	local att = ParaTerrain.GetAttributeObjectAt(x,y);
	att:SetField("CurrentRegionIndex", 0);
	commonlib.echo{ 
		NumOfRegions = att:GetField("NumOfRegions", 0), 
		CurrentRegionName = att:GetField("CurrentRegionName", ""),
		CurrentRegionFilepath = att:GetField("CurrentRegionFilepath", ""),
	};
	
	--create a region layer if not done before. 
	att:SetField("CurrentRegionName", "move");
	att:SetField("CurrentRegionFilepath", "%WORLD%/config/move_0_0.png");
	commonlib.echo{ 
		CurrentRegionName = att:GetField("CurrentRegionName", ""),
		CurrentRegionFilepath = att:GetField("CurrentRegionFilepath", ""),
		NumOfRegions = att:GetField("NumOfRegions", 0), 
	};
end

-- physics height
function TestParaScene:test_PhysicsHeight()
	local player = ParaScene.GetPlayer();

	player:SetPhysicsRadius(0.25);
	commonlib.echo({radius = player:GetPhysicsRadius(), height = player:GetPhysicsHeight()});--echo:return { height=1, radius=0.25 }
	
	player:SetPhysicsRadius(0.5);
	commonlib.echo({radius = player:GetPhysicsRadius(), height = player:GetPhysicsHeight()});--echo:return { height=2, radius=0.5 }
	
	player:SetPhysicsHeight(5);
	commonlib.echo({radius = player:GetPhysicsRadius(), height = player:GetPhysicsHeight()});--echo:return { height=5, radius=0.5 }
end

-- 3d position 
function TestParaScene:test_GetScreenPosFrom3DPoint()
	local player = ParaScene.GetPlayer();
	local x,y,z = player:GetPosition();
	y = y + 3;
	local output = {x,y,z, visible, distance};
	ParaScene.GetScreenPosFrom3DPoint(x,y,z,output)
	_guihelper.MessageBox(output);
end	


function TestParaScene:test_GameUseGlobalTime()

	local player = ParaScene.CreateCharacter ("MyPlayer1", ParaAsset.LoadParaX("","character/v3/Elf/Female/ElfFemale.x"), "", true, 0.35, 0, 1.0);
	local x,y,z = ParaScene.GetPlayer():GetPosition()
	player:SetPosition(x,y,z);
	ParaScene.Attach(player);
	Map3DSystem.Animation.PlayAnimationFile("character/Animation/v5/LoopedDance.x", player)
	player:SetField("UseGlobalTime", true);
	
	
	local player = ParaScene.CreateCharacter ("MyPlayer2", ParaAsset.LoadParaX("","character/v3/Elf/Female/ElfFemale.x"), "", true, 0.35, 0, 1.0);
	player:SetPosition(x+10,y,z);
	ParaScene.Attach(player);
	Map3DSystem.Animation.PlayAnimationFile("character/Animation/v5/LoopedDance.x", player)
	player:SetField("UseGlobalTime", true);
end


-- set animation and anim frame of a given character or model 
-- @param obj: the object itself or object name. 
-- @param AnimID: 
-- @param AnimFrame: 
function TestParaScene:test_SetAnimationDetail(obj, AnimID, AnimFrame)
	
	local x,y,z = ParaScene.GetPlayer():GetPosition()
	local player = ParaScene.CreateCharacter ("MyPlayer2", ParaAsset.LoadParaX("","character/v3/Elf/Female/ElfFemale.x"), "", true, 0.35, 0, 1.0);
	player:SetPosition(x+10,y,z);
	ParaScene.Attach(player);
	Map3DSystem.Animation.PlayAnimationFile("character/Animation/v5/LoopedDance.x", player)
	
	local att = ParaScene.GetObject("MyPlayer2"):GetAttributeObject();
	att:SetField("UseGlobalTime", true);
	att:SetField("AnimID", 0);
	att:SetField("AnimFrame", 0);
	

	
	-- local asset = ParaAsset.LoadStaticMesh("","model/01building/v5/01house/SkyWheel/SkyWheel.x")
	local asset = ParaAsset.LoadStaticMesh("","model/01building/v5/01house/BigDipper/BigDipper.x")
	local obj = ParaScene.CreateMeshPhysicsObject("g_globalTestModel", asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	obj:SetPosition(ParaScene.GetPlayer():GetPosition());
	obj:SetField("progress",1);
	ParaScene.Attach(obj);
	
	local att = ParaScene.GetObject("g_globalTestModel"):GetAttributeObject();
	att:SetField("UseGlobalTime", true);
	att:SetField("AnimID", 0);
	att:SetField("AnimFrame", 0);
	
	local nMountID = 20; -- value between [20, 39]
	ParaScene.GetPlayer():ToCharacter():MountOn(ParaScene.GetObject("g_globalTestModel"), nMountID)
	ParaScene.GetPlayer():ToCharacter():UnMount();


	local x,y,z = ParaScene.GetPlayer():GetPosition()
	local player = ParaScene.CreateCharacter ("block1", ParaAsset.LoadParaX("","character/v6/09effect/Block_Piece/Block_piece.x"), "", true, 0.35, 0, 1.0);
	player:SetReplaceableTexture(2, ParaAsset.LoadTexture("","Texture/tileset/blocks/top_ice_three.dds",1));
	player:SetPosition(x+4,y+3,z);
	ParaScene.Attach(player);
	player:SetField("AnimID", 0);
	player:SetField("AnimFrame", 0);
	player:SetField("IsAnimPaused", true);

	ParaScene.GetObject("block1"):SetField("AnimFrame", 10);

	local params = player:GetEffectParamBlock();
	params:SetFloat("g_opacity", 0.8);

end

function TestParaScene:test_BigStaticMesh()
	local asset = ParaAsset.LoadStaticMesh("","model/01building/v5/01house/BigDipper/BigDipper.x")
	local obj = ParaScene.CreateMeshPhysicsObject("g_globalTestModel", asset, 20,20,20, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	obj:SetPosition(ParaScene.GetPlayer():GetPosition());
	obj:SetAttribute(8192, true); -- 8192 stands for big static mesh
	obj:SetField("progress",1);
	ParaScene.Attach(obj);
end

function TestParaScene:test_CameraUseCharacterLookup()
	local asset = ParaAsset.LoadStaticMesh("","model/01building/v5/01house/BigDipper/BigDipper.x")
	local obj = ParaScene.CreateMeshPhysicsObject("g_globalTestModel", asset, 20,20,20, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	obj:SetPosition(ParaScene.GetPlayer():GetPosition());
	obj:SetAttribute(8192, true); -- 8192 stands for big static mesh
	obj:SetField("progress",1);
	ParaScene.Attach(obj);
		
	ParaScene.GetPlayer():ToCharacter():MountOn(ParaScene.GetObject("g_globalTestModel"), 20)
	ParaCamera.SetField("UseCharacterLookup" ,false);
	ParaCamera.SetField("UseCharacterLookupWhenMounted" ,true);
end

-- for camera testing
TestParaCamera = {}

-- 2010.6.13 by LXZ: camera pitch/yaw/roll
function TestParaCamera:test_TestCameraRoll()
	NPL.load("(gl)script/ide/timer.lua");
	ParaCamera.SetField("CameraRotZ", 0.4);

	self.timer_roll = self.timer_roll or commonlib.Timer:new({callbackFunc = function(timer)
		local att = ParaCamera.GetAttributeObject();
		local rot_z = att:GetField("CameraRotZ", 0);
		rot_z = rot_z + 0.02;
		local range = 3.14; -- to loop, this value should be 3.14 
		if(rot_z>range) then
			rot_z = -range
		end
		att:SetField("CameraRotZ", rot_z);
	end})
	self.timer_roll:Change(0,30)
end

function TestParaScene:test_AttachmentAnimation()
	-- when we attach a model to the main character, the attached model will share the same animation id as the main character. If there is no such an animation on the attached model, the default standing animation is used. 
	local player = ParaScene.CreateCharacter ("MyPlayer1", ParaAsset.LoadParaX("","character/v3/Elf/Female/ElfFemale.x"), "", true, 0.35, 0, 1.0);
	local x,y,z = ParaScene.GetPlayer():GetPosition()
	player:SetPosition(x,y,z);
	ParaScene.Attach(player);
	
	local asset = ParaAsset.LoadParaX("","character/v3/Pet/XM/XM.xml");
	player:ToCharacter():AddAttachment(asset, 11);
end

function TestParaScene:test_RenderDistance()
	ParaScene.GetPlayer():SetField("RenderDistance", 10);
end
--LuaUnit:run('TestParaScene')
--LuaUnit:run('TestParaCamera')
-- LuaUnit:run('TestParaCamera:test_TestCameraRoll')

--LuaUnit:run('TestParaScene:test_GameObjectEvent')

function TestParaScene:testIges()
	--local asset = ParaAsset.LoadStaticMesh("","model/Test/screw.step");
	--local asset = ParaAsset.LoadStaticMesh("","model/Test/linkrods.step");
	local asset = ParaAsset.LoadStaticMesh("","model/Test/bearing.iges");
	--local asset = ParaAsset.LoadStaticMesh("","model/Test/hammer.iges");
	local obj = ParaScene.CreateMeshPhysicsObject("igesTest", asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	obj:SetPosition(ParaScene.GetPlayer():GetPosition());
	obj:SetField("progress",1);
	ParaScene.Attach(obj);
end

function TestParaScene:test_FBX_player()
	-- local asset = ParaAsset.LoadParaX("","character/test/FBX/animation.fbx");
	local asset = ParaAsset.LoadParaX("","character/test/FBX/vertexcolor.fbx");
	local player = ParaScene.CreateCharacter ("MyFBX", asset, "", true, 0.35, 0, 1.0);
	player:SetPosition(ParaScene.GetPlayer():GetPosition());
	ParaScene.Attach(player);
end	

function TestParaScene:test_PostRenderQueueOrder()
	local asset = ParaAsset.LoadStaticMesh("","model/common/editor/z.x")
	local obj = ParaScene.CreateMeshPhysicsObject("blueprint_center", asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
	obj:SetPosition(ParaScene.GetPlayer():GetPosition());
	obj:SetField("progress",1);
	obj:GetEffectParamBlock():SetBoolean("ztest", false);
	obj:SetField("RenderOrder", 101)
	ParaScene.Attach(obj);

	local player = ParaScene.CreateCharacter ("MyPlayer1", ParaAsset.LoadParaX("","character/v3/Elf/Female/ElfFemale.x"), "", true, 0.35, 0, 1.0);
	local x,y,z = ParaScene.GetPlayer():GetPosition()
	player:SetPosition(x+1,y,z);
	player:SetField("RenderOrder", 100)
	player:GetEffectParamBlock():SetBoolean("ztest", false);
	ParaScene.Attach(player);
end

function TestParaScene:test_ParaVoxelMesh()
	--local model = GetEntity():GetInnerObject():GetPrimaryAsset():GetAttributeObject():GetChildAt(0):GetChild("VoxelModel")
	local model = ParaScene.GetPlayer():GetPrimaryAsset():GetAttributeObject():GetChildAt(0):GetChild("VoxelModel")
	model:SetField("MinVoxelPixelSize", 4);

	local function SetModelblock(x, y, z, level, color)
		model:SetField("SetBlock", format("%d,%d,%d,%d,%d", x, y, z, level, color or -1));
	end
	local function PaintModelblock(x, y, z, level, color)
		model:SetField("PaintBlock", format("%d,%d,%d,%d,%d", x, y, z, level, color or -1));
	end
	local function DumpModel()
		model:CallField("DumpOctree");
	end
	model:SetField("SetBlock", "0,0,0,1,-1");

	-- test case1£º 
	for x=0,0 do
		for z = 0,2 do
			SetModelblock(x, 0, z, 8, 0xffff)
			SetModelblock(x, 1, z, 8, 0xffff)
		end
	end
	SetModelblock(1, 0, 0, 8, 0xffff)
	SetModelblock(1, 1, 0, 8, 0xffff)
	SetModelblock(1, 0, 1, 8, 0xffff)

	SetModelblock(1, 1, 1, 8, 0xffff)

	
	-- test case: split a block
	SetModelblock(3, 0, 4, 8, 0xff0000)
	SetModelblock(8, 0, 8, 16, 0xff0000)
	SetModelblock(0, 0, 0, 2, 0xffff)
	SetModelblock(1, 0, 0, 2, 0xffff)

	-- test case: cube merge
	for y=0,7 do
		for x = 0,7 do
			for z = 0,7 do
				SetModelblock(x, y, z, 8, 0xffff)
			end
			--wait(0.1)
		end
	end

	-- test case: paint blocks
	for y=0,63 do
		for x = 0,63 do
			for z = 0,0 do
				SetModelblock(x, y, z, 64, 0xffffff)
			end
		end
	end
	for y=32,32 do
		for x = 0,1 do
			for z = 0,0 do
				PaintModelblock(x, y, z, 64, 2*x*256+2*y)
			end
		end
	end

	-- test case: color LOD merge
	for y=8,15 do
		for x = 0,7 do
			for z = 0,0 do
				SetModelblock(x, y, z, 64, 0x0)
			end
		end
	end
	for y=4,7 do
		for x = 0,3 do
			for z = 0,0 do
				PaintModelblock(x, y, z, 32, 0xff0000)
			end
		end
	end

	-- test case: load/save to file
	SetModelblock(1, 1, 1, 4, 0xffffff)
	model:SetField("SaveToFile", "temp/voxel.bin");
	model:SetField("LoadFromFile", "temp/voxel.bin"); 

	-- test case: run cmd list
	model:SetField("RunCommandList", "setblock 0,0,0,4,255");

	-- test case: setrect and paintrect
	model:SetField("run", "color 0;level 64;setrect 0,0,0,63,63,0");
	model:SetField("run", "level=4;paintrect 0,0,0:2,0,0:#ff0000#00ff00#ff");
	model:SetField("run", "level=4;paintrect 2,1,0:0,1,0:#ff0000#00ff00#ff");
	-- also able to load png or jpg files directly from base64 encoded string.
	-- this makes forwarding data from camera or mp4 to bmax faster. 
	-- model:SetField("run", "paintrect 0,0,0,64,64,0,data:image/png;base64,.............");
	

	-- test case: print noise with setrect and paintrect
	local width, height, z = 64, 64, 31
	local level = 64
	model:SetField("run", format("level %d setrect %d,%d,%d,%d,%d,%d", level, 0,0, z, width-1, height-1, z));
	local data = {};
	for x = 0, width-1 do
		for y = 0, height-1 do
			data[#data+1] = math.random(0, 0xffffff)
		end
	end
	local imageData = table.concat(data," ")
	model:SetField("run", string.format("level %d paintrect %d,%d,%d,%d,%d,%d %s", level, width-1, height-1, z, 0, 0, z, imageData));

	model:SetField("run", "setblock 0,0,0,1,-1 level 8 color #ff0000 set 0,0,0,1,1,1,0,1,0");
	model:SetField("run", "offset 4,4,4 level 8 color #ff0000 setwithoffset");
	model:SetField("run", "0,0,0,1,1,1,0,1,0");
	-- , ; # are all valid separators
	model:SetField("run", "setxyzcolor 6,6,6,#ff,6 6 7#00ffff");
	
	
	-- test case2£º 
	log("clear model to empty\n")
	model:SetField("SetBlock", "0,0,0,1,-1");
	model:CallField("DumpOctree");
	log("set depth 3 to 7/8\n")
	model:SetField("SetBlock", "7,7,6,8,254");
	model:SetField("SetBlock", "7,6,6,8,254");
	model:SetField("SetBlock", "7,6,7,8,254");
	model:SetField("SetBlock", "6,7,7,8,254");
	model:SetField("SetBlock", "6,7,6,8,254");
	model:SetField("SetBlock", "6,6,6,8,254");
	model:SetField("SetBlock", "6,6,7,8,254");
	model:CallField("DumpOctree");
	log("set depth 3 to 8/8, should merge depth3 to depth 2\n")
	model:SetField("SetBlock", "7,7,7,8,254");
	model:CallField("DumpOctree");
	log("clear a block on depth 3, since block colors are the same, it should remain on depth 2 only blockmask changes\n")
	model:SetField("SetBlock", "7,7,7,8,-1");
	model:CallField("DumpOctree");
	log("set a block with different color on depth 3, should generate depth3 node, but depth 2 retains its last color.\n")
	model:SetField("SetBlock", "7,7,7,8,123123");
	model:CallField("DumpOctree");
	log("paint blocks on depth 2 to the same color, should collapse to depth 2.\n")
	model:SetField("PaintBlock", "3,3,3,4,123");
	model:CallField("DumpOctree");
	log("paint blocks on depth 1 to the same new color, should collapse to depth 2.\n")
	model:SetField("PaintBlock", "0,0,0,1,456");
	model:CallField("DumpOctree");
end