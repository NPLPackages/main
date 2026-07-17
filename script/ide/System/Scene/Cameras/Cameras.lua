--[[
Title: Cameras
Author(s): LiXizhi@yeah.net
Date: 2015/8/19
Desc: For getting the current camera in the scene, usually the AutoCamera. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Cameras/Cameras.lua");
local Cameras = commonlib.gettable("System.Scene.Cameras");
echo(Cameras:GetCurrent():GetViewMatrix());
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Cameras/AutoCamera.lua");
local AutoCamera = commonlib.gettable("System.Scene.Cameras.AutoCamera");

local Cameras = commonlib.gettable("System.Scene.Cameras");

-- default to autocamera if no camera is set. 
function Cameras:GetCurrent()
	return self.Current or AutoCamera;
end

-- @param cam: if nil, it will be the default AutoCamera.
function Cameras:SetCurrent(cam)
	if(self.Current~=cam and self.Current) then
		if(self.Current.OnDeactivate) then
			self.Current:OnDeactivate();
		end
	end
	self.Current = cam;
end
