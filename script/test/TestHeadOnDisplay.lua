--[[
Author: Li,Xizhi
Date: 2007-9-3
Desc: testing ParaEngine extension functions.
-----------------------------------------------
NPL.load("(gl)script/test/TestHeadOnDisplay.lua");
-----------------------------------------------
]]
NPL.load("(gl)script/ide/UnitTest/luaunit.lua");

function TestHeadOnDisplay()
	ParaScene.ShowHeadOnDisplay(true);
	local player = ParaScene.GetPlayer()
	player:SetHeadOnText("中文 long text\n another line",0);
	player:SetHeadOnTextColor("255 0 0",0);
	player:SetHeadOnOffset(0,0.3,0,0);
	player:SetHeadOnUITemplateName("headtext_line1",0);

	player:SetHeadOnText("Multiple template",1);
	player:SetHeadOnTextColor("0 255 0",1);
	player:SetHeadOnOffset(0,0.3,0,1);
	player:SetHeadOnUITemplateName("headtext_line2",1);

	player:SetHeadOnOffset(0,0.3,0,2);
	player:SetHeadOnText("1",2);
	player:SetHeadOnUITemplateName("headtext_button",2);

	if(not ParaUI.GetUIObject("headtext_line1"):IsValid()) then
		-- users can create their own UI template in NPL.
		local _this=ParaUI.CreateUIObject("text","headtext_line1", "_lt",-100,-20,200,15);
		_this.visible = false;
		_this.font = "System;15";
		_this:GetFont("text").color = "255 0 0";
		_this:GetFont("text").format = 1+256; -- center and no clip
		_this:AttachToRoot();
	end	
	if(not ParaUI.GetUIObject("headtext_line2"):IsValid()) then
		-- users can create their own UI template in NPL.
		local _this=ParaUI.CreateUIObject("text","headtext_line2", "_lt",-100,-40,200,15);
		_this.visible = false;
		_this.font = "System;15";
		_this:GetFont("text").color = "255 0 0";
		_this:GetFont("text").format = 1+256; -- center and no clip
		_this:AttachToRoot();
	end	
	if(not ParaUI.GetUIObject("headtext_button"):IsValid()) then
		-- users can create their own UI template in NPL.
		local _this=ParaUI.CreateUIObject("button","headtext_button", "_lt",-16,-72,32,32);
		_this.visible = false;
		_this.background = "Texture/Aries/Quest/Question_Mark_32bits.png";
		_this:AttachToRoot();
	end	
	
	local tmp = ParaUI.GetUIObject("_HeadOnDisplayText_");
	if(tmp:IsValid()) then
		-- user can also change the default head on display text here
	end
end

function TestHeadOnDisplayForMiniscenegraph()
	local _this,_parent;
	
	_this=ParaUI.GetUIObject("Map3DCanvas_cont");
	if(_this:IsValid() == false) then
		if(bShow == false) then return	end
		bShow = true;
		_this=ParaUI.CreateUIObject("container","Map3DCanvas_cont","_lt",0,0,512,512);
		--_this.background="Texture/whitedot.png;0 0 0 0";
		_this:AttachToRoot();
		_parent = _this;
		
		local scene = ParaScene.GetMiniSceneGraph("testheadondisplay");
	
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
		
		------------------------------------
		-- init camera
		------------------------------------
		-- automatically adjust the camera to watch a sphere in its integrity. 
		-- Note: Alternatively, one can call scene:CameraSetLookAtPos() and scene:CameraSetEyePos() to gain precise control.
		scene:CameraZoomSphere(0,0,0,3);
		
		------------------------------------
		-- init scene content
		------------------------------------
		local asset = ParaAsset.LoadStaticMesh("","model/06props/v5/06combat/Common/WarBanner/WarBanner_Gray.x")
		local assetTex = ParaAsset.LoadTexture("","Texture/sharedmedia/09.JPG",1);
		local assetTex2 = ParaAsset.LoadTexture("","Texture/sharedmedia/08.JPG",1);
		
		local obj,player;
		obj = ParaScene.CreateMeshPhysicsObject("cell_0_0", asset, 1,1,1, false, "1,0,0,0,1,0,0,0,1,0,0,0");
		if( obj:IsValid())then
			obj:SetPosition(0,0,0);
			obj:GetAttributeObject():SetField("progress",1);
			
			obj:SetHeadOnText("李西峙 long text\n another line",0);
			obj:SetHeadOnTextColor("255 0 0",0);

			scene:AddChild(obj);
		end	
		
		------------------------------------
		-- assign the texture to UI
		------------------------------------
		local tmp = ParaUI.GetUIObject("Map3DCanvas_cont");
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

function TestExternalAnimation()
	NPL.load("(gl)script/ide/action_table.lua");
	action_table.TestExternalAnimation()
end
