--[[
Title: AutoCamera
Author(s): LiXizhi@yeah.net
Date: 2015/8/19
Desc: a singleton wrapper to the C++ CAutoCamera class. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Cameras/AutoCamera.lua");
local Cameras = commonlib.gettable("System.Scene.Cameras");
echo(Cameras:GetCurrent():GetViewMatrix());
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Cameras/Camera.lua");
NPL.load("(gl)script/ide/math/Matrix4.lua");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local AutoCamera = commonlib.inherit(commonlib.gettable("System.Scene.Cameras.Camera"), commonlib.gettable("System.Scene.Cameras.AutoCamera"));

AutoCamera:Property({"Name", "AutoCamera"});

function AutoCamera:ctor()
	self.eye_pos = {0,0,0};
	self.renderOrigin = {0,0,0};
end

function AutoCamera:GetViewProjMatrix()
	return ParaCamera.GetAttributeObject():GetField("ViewProjMatrix", self.viewprojMatrix);
end

function AutoCamera:GetViewMatrix()
	return ParaCamera.GetAttributeObject():GetField("ViewMatrix", self.viewMatrix);
end

function AutoCamera:GetProjMatrix()
	return ParaCamera.GetAttributeObject():GetField("ProjMatrix", self.projMatrix);
end


function AutoCamera:GetEyePosition()
	return ParaCamera.GetAttributeObject():GetField("Eye position", self.eye_pos);
end

function AutoCamera:GetRenderOrigin()
	return ParaCamera.GetAttributeObject():GetField("RenderOrigin", self.renderOrigin);
end

function AutoCamera:GetFieldOfView()
	return ParaCamera.GetAttributeObject():GetField("FieldOfView", self.fieldOfView);
end

function AutoCamera:GetNearPlane()
	return ParaCamera.GetAttributeObject():GetField("NearPlane", 1);
end

function AutoCamera:GetFarPlane()
	return ParaCamera.GetAttributeObject():GetField("FarPlane", 100);
end

function AutoCamera:GetAspectRatio()
	return ParaCamera.GetAttributeObject():GetField("AspectRatio", 1);
end

AutoCamera:InitSingleton();
