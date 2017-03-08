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