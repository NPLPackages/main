--[[
Title: Camera
Author(s): LiXizhi@yeah.net
Date: 2015/8/19
Desc: Base class to camera
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Cameras/Camera.lua");
local Cameras = commonlib.gettable("System.Scene.Cameras");
echo(Cameras:GetCurrent():GetViewMatrix());
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Cameras/Cameras.lua");
NPL.load("(gl)script/ide/math/Matrix4.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
NPL.load("(gl)script/ide/math/ShapeRay.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local ShapeRay = commonlib.gettable("mathlib.ShapeRay");
local math3d = commonlib.gettable("mathlib.math3d");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local Screen = commonlib.gettable("System.Windows.Screen");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Camera = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Scene.Cameras.Camera"));

Camera:Property({"Name", "Camera"});
-- called after C++'s camera frame move is called, but before the scene is actually rendered. 
-- this is the best place for handling scene picking according to the final camera and current mouse position. 
Camera:Signal("beforeRenderFrameMoved");

function Camera:ctor()
	self.viewprojMatrix = Matrix4:new();
	self.viewMatrix = Matrix4:new();
	self.projMatrix = Matrix4:new();
	self.fieldOfView = 60/180*3.1415926;
end

function Camera:activate()
	System.Scene.Cameras:SetCurrent(self);
end

function Camera:GetViewProjMatrix()
	return self.viewprojMatrix;
end

function Camera:GetViewMatrix()
	return self.viewMatrix;
end

function Camera:GetProjMatrix()
	return self.projMatrix;
end

function Camera:GetEyePosition()
	return {0,0,0};
end

function Camera:GetRenderOrigin()
	return {0,0,0};
end

function Camera:GetFieldOfView()
	return self.fieldOfView;
end

local camera_params = {0,0,0};
function Camera:SetAdditionalCameraRotate(yaw, pitch, roll)
	local att = ParaCamera.GetAttributeObject();
	camera_params[1] = yaw or camera_params[1];
	camera_params[2] = pitch or camera_params[2];
	camera_params[3] = roll or camera_params[3];
	att:SetField("AdditionalCameraRotate", camera_params);
end


-- pretty slow, get it and cache it. return mouse ray in current scene viewport
-- @param mouse_x, mouse_y: if nil, default to current mouse position. 
-- @param matWorld: if nil, it will simply return the ray in view space. 
-- @return ShapeRay 
function Camera:GetMouseRay(mouse_x, mouse_y, matWorld)
	if(not mouse_x or not mouse_y) then
		mouse_x, mouse_y = Mouse:GetMousePosition();
	end
	local matProj = self:GetProjMatrix();
	if(not matProj) then
		return;
	end
	local viewport = ViewportManager:GetSceneViewport();
	local viewportUI = ViewportManager:GetGUIViewport();
	-- assume that scene viewport is always relative to UI viewport. 
	mouse_x = mouse_x - ((viewport:GetLeft()-viewportUI:GetLeft()) / Screen:GetUIScaling()[1])
	mouse_y = mouse_y - ((viewport:GetTop()-viewportUI:GetTop()) / Screen:GetUIScaling()[2]);
	local screenWidth = Screen:GetWidth() - ((viewport:GetMarginRight() - viewportUI:GetMarginRight() + viewport:GetLeft()-viewportUI:GetLeft()) / Screen:GetUIScaling()[1]);
	local screenHeight = Screen:GetHeight() - ((viewport:GetMarginBottom() - viewportUI:GetMarginBottom() + viewport:GetTop()-viewportUI:GetTop())/ Screen:GetUIScaling()[2]);
	-- Compute the vector of the pick ray in screen space
	local v = {
		 ( ( ( 2.0 * mouse_x ) / screenWidth  ) - 1 ) / matProj[1],
		-( ( ( 2.0 * mouse_y ) / screenHeight ) - 1 ) / matProj[6],
		 1.0
	};
	
	if(matWorld) then
		-- Get the inverse of the composite view and world matrix
		local m;
		local matView = self:GetViewMatrix();
		m = matWorld * matView;
		m = m:inverse();
		local vPickRayDir = vector3d:new({
			v[1]*m[1] + v[2]*m[5] + v[3]*m[9],
			v[1]*m[2] + v[2]*m[6] + v[3]*m[10],
			v[1]*m[3] + v[2]*m[7] + v[3]*m[11]
		});
		vPickRayDir:normalize();
		local vPickRayOrig = vector3d:new({m[13], m[14], m[15]});

		return ShapeRay:new():init(vPickRayOrig, vPickRayDir);
	else
		return ShapeRay:new():init(vector3d.zero, v);
	end
end

-- get the 3d point in world space from screen space.
-- @param x,y,z: the 3d point in world space.
-- @return x, y in screen space.
function Camera:CalculatePointInScreenSpace(x,y,z)
	local vec = vector3d:new({x,y,z});
	
	local viewMat = self:GetViewMatrix();
	local projMat = self:GetProjMatrix();
	local finalMat = viewMat*projMat;

	local viewport = ViewportManager:GetSceneViewport()
	local left, top, screenWidth, screenHeight = viewport:GetUIRect()
	local origin = self:GetRenderOrigin();
	vec[1] = vec[1] - origin[1]
	vec[2] = vec[2] - origin[2]
	vec[3] = vec[3] - origin[3]
	math3d.Vector4MultiplyMatrix(vec, vec, finalMat);
	vec:MulByFloat(1/vec[4]);
	vec[1] = ((vec[1]+1)*0.5) * screenWidth;
	vec[2] = ((1-vec[2])*0.5) * screenHeight;
	vec[3] = 0;
	vec[4] = nil;
	return math.floor(vec[1] + 0.5), math.floor(vec[2] + 0.5);
end

local uiname = "autoCameraMiniScene"
-- this function must be called in order for "beforeRenderFrameMoved" events to fire. 
function Camera:EnableCameraFrameMove(bEnable)
	if(bEnable) then
		-- tricky: we will create a dummy mini scenegraph, whose On_Paint callback is invoked 
		-- after camera is frame moved, but before any 3d scene is rendered. 
		if(not self.cameraMiniScene or not self.cameraMiniScene:IsValid()) then
			local scene = ParaScene.GetMiniSceneGraph(uiname);
			self.cameraMiniScene = scene;
			scene:SetRenderTargetSize(2, 2);
			scene:Reset();
			scene:EnableCamera(true);
			scene:EnableActiveRendering(true);
			local att = scene:GetAttributeObject();
			att:SetField("ShowSky", false);
			att:SetField("EnableFog", false)
			att:SetField("EnableLight", false)
			att:SetField("EnableSunLight", false)
			local rendertarget = att:QueryObject();
			rendertarget:SetScript("On_Paint", function()
				-- called after C++'s camera frame move is called, but before the scene is actually rendered. 
				self:OnBeforeRenderFrameMove();
			end)

			local _this = ParaUI.GetUIObject(uiname)
			if(not _this:IsValid()) then
				_this = ParaUI.CreateUIObject("button", uiname, "_lt", -10, -10, 1, 1);
				_this.enabled = false;
				_this:AttachToRoot();
			end
			_this:SetBGImage(scene:GetTexture());
		end
	else
		if(self.cameraMiniScene) then
			ParaUI.Destroy(uiname);
			ParaScene.DeleteMiniSceneGraph(uiname);
			self.cameraMiniScene = nil;
		end
	end
end

function Camera:OnBeforeRenderFrameMove()
	self:beforeRenderFrameMoved();
	if(self.frameMoveCallbacks) then
		for i=#self.frameMoveCallbacks, 1, -1 do
			local callbackFunc = self.frameMoveCallbacks[i]
			self.frameMoveCallbacks[i] = nil;
			callbackFunc();
		end
	end
end

-- call callbackFunc in the next frame move before scene rendering. 
function Camera:ScheduleCameraMove(callbackFunc)
	self.frameMoveCallbacks = self.frameMoveCallbacks or {}
	self.frameMoveCallbacks[#(self.frameMoveCallbacks) + 1] = callbackFunc;
	self:EnableCameraFrameMove(true)
end

function Camera:SetFacingToPosition(lookat_x, lookat_y, lookat_z)
	if(lookat_x and lookat_y and lookat_z) then
		local player = ParaScene.GetPlayer();
		if(player) then
			local camx,camy,camz = player:GetPosition();
			
			local facing = math.atan2(lookat_x - camx, lookat_z - camz);
			facing = facing - math.pi / 2;
			local att = ParaCamera.GetAttributeObject();
			att:SetField("CameraRotY", facing);
		end
	end
end