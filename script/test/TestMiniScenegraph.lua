--[[
Author: Li,Xizhi
Date: 2007-9-26
Desc: testing ParaEngine miniscenegraph functions.
-----------------------------------------------
NPL.load("(gl)script/test/TestMiniSceneGraph.lua");
TestMiniSceneGraph();
-----------------------------------------------
]]
NPL.load("(gl)script/ide/event_mapping.lua");

-- passed 2007-10-26
-- test sets: active rendering, head on text, fog, skybox, mesh, character, camera
function TestMiniSceneGraph()
	local _this,_parent;
	
	_this=ParaUI.GetUIObject("MiniSceneGraph_test_cont");
	if(_this:IsValid() == false) then
		if(bShow == false) then return	end
		bShow = true;
		_this=ParaUI.CreateUIObject("container","MiniSceneGraph_test_cont","_lt",0,0,512,512);
		--_this.background="Texture/whitedot.png;0 0 0 0";
		_this:AttachToRoot();
		_parent = _this;
		
		local scene = ParaScene.GetMiniSceneGraph("testMiniSceneGraph");
	
		------------------------------------
		-- init render target
		------------------------------------
		-- reset scene, in case this is called multiple times
		scene:Reset();
		-- show display
		scene:ShowHeadOnDisplay(true);
		-- set size
		scene:SetRenderTargetSize(512, 512);
		-- enable camera and create render target
		scene:EnableCamera(true);
		-- render it each frame automatically. 
		-- Note: If content is static, one should disable this, and call scene:draw() in a script timer.
		scene:EnableActiveRendering(true);
		-- If one wants an over lay, here it is.
		--scene:SetMaskTexture(ParaAsset.LoadTexture("","anything you want.dds",1));
		
		local att = scene:GetAttributeObject();
		
		-- this color is shown only when no fog is specified. 
		att:SetField("BackgroundColor", {0, 0, 1});  -- blue background
		
		-- test fog
		att:SetField("EnableFog", true);
		att:SetField("FogColor", {1, 0, 0}); -- red fog
		att:SetField("FogStart", 5);
		att:SetField("FogEnd", 25);
		att:SetField("FogDensity", 0.5);
		
		-- test skybox
		att:SetField("ShowSky", true);
		scene:CreateSkyBox ("MySkybox", ParaAsset.LoadStaticMesh ("", "model/Skybox/Skybox1/Skybox1.x"), 100,100,100, 0);
		local attSky = scene:GetAttributeObject("sky");
		attSky:SetField("SkyColor", {1,1,1}); -- white sky
		
		
		-- test global lighting
		att:SetField("EnableLight", false)
		att:SetField("EnableSunLight", false)
		
		-- test time of day
		-- always in the range [-1,1], 0 means at noon, -1 is morning. 1 is night
		scene:SetTimeOfDaySTD(-1); -- so that if lighting is enable, the scene should be dark.
		
		------------------------------------
		-- init camera
		------------------------------------
		-- automatically adjust the camera to watch a sphere in its integrity. 
		-- Note: Alternatively, one can call scene:CameraSetLookAtPos() and scene:CameraSetEyePos() to gain precise control.
		--scene:CameraZoomSphere(0,0,0,3);
		
		scene:CameraSetLookAtPos(0,0,0);
		scene:CameraSetEyePos(5,0.5,5);
		
		------------------------------------
		-- init scene content
		------------------------------------
		local asset = ParaAsset.LoadStaticMesh("","model/06props/shared/pops/huaban.x")
		local assetTex = ParaAsset.LoadTexture("","Texture/sharedmedia/09.JPG",1);
		local assetTex2 = ParaAsset.LoadTexture("","Texture/sharedmedia/08.JPG",1);
		
		local obj,player;
		obj = ParaScene.CreateMeshPhysicsObject("cell_0_0", asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
		if( obj:IsValid())then
			obj:SetPosition(0,0,0);
			obj:GetAttributeObject():SetField("progress",1);
			
			-- test head on text
			obj:SetHeadOnText("李西峙 long text\n another line",0);
			obj:SetHeadOnTextColor("255 0 0",0);
			
			-- test other effect technique with mesh
			obj:GetAttributeObject():SetField("render_tech", render_tech.TECH_SIMPLE_MESH_NORMAL_UNLIT);

			scene:AddChild(obj);
		end	
		
		-- test for fog effect
		obj = ParaScene.CreateMeshPhysicsObject("large mesh for fog", asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
		if( obj:IsValid())then	
			obj:SetScale(20);
			obj:SetPosition(-5,-5,-5);
			
			-- test other effect technique with mesh
			--obj:GetAttributeObject():SetField("render_tech", render_tech.TECH_SIMPLE_MESH_NORMAL_UNLIT);
			
			scene:AddChild(obj);
		end
		
		------------------------------------
		-- assign the texture to UI
		------------------------------------
		local tmp = ParaUI.GetUIObject("MiniSceneGraph_test_cont");
		if(tmp:IsValid()) then
			tmp:SetBGImage(scene:GetTexture());
		end
		
	else
		if(bShow == nil) then
			bShow = (_this.visible == false);
		end
		_this.visible = bShow;
	end	
end

