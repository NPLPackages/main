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
local Mouse = commonlib.gettable("System.Windows.Mouse");
local Screen = commonlib.gettable("System.Windows.Screen");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Camera = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Scene.Cameras.Camera"));

Camera:Property({"Name", "Camera"});

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

-- pretty slow, get it and cache it. return mouse ray in current scene viewport
-- @param mouse_x, mouse_y: if nil, default to current mouse position. 
-- @param matWorld: if nil, it will simply return the ray in view space. 
-- @return ShapeRay 
function Camera:GetMouseRay(mouse_x, mouse_y, matWorld)
	if(not mouse_x or not mouse_y) then
		mouse_x, mouse_y = Mouse:GetMousePosition();
	end
	local matProj = self:GetProjMatrix();
	local viewport = ViewportManager:GetSceneViewport();
	mouse_x, mouse_y = mouse_x - (viewport:GetLeft() / Screen:GetUIScaling()[1]), mouse_y-(viewport:GetTop() / Screen:GetUIScaling()[2]);
	local screenWidth, screenHeight = Screen:GetWidth()-(viewport:GetMarginRight() / Screen:GetUIScaling()[1]), Screen:GetHeight() - (viewport:GetMarginBottom() / Screen:GetUIScaling()[2]);
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
