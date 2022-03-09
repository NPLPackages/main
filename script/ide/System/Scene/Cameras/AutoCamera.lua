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
Cameras:GetCurrent():EnableCameraFrameMove(true)
Cameras:GetCurrent():Connect("beforeRenderFrameMoved", function()
	echo(commonlib.TimerManager.GetCurrentTime())
end, "UniqueConnection");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Cameras/Camera.lua");
NPL.load("(gl)script/ide/math/Matrix4.lua");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local AutoCamera = commonlib.inherit(commonlib.gettable("System.Scene.Cameras.Camera"), commonlib.gettable("System.Scene.Cameras.AutoCamera"));

AutoCamera:Property({"Name", "AutoCamera"});
-- called after C++'s camera frame move is called, but before the scene is actually rendered. 
-- this is the best place for handling scene picking according to the final camera and current mouse position. 
AutoCamera:Signal("beforeRenderFrameMoved");

function AutoCamera:ctor()
	self.eye_pos = {0,0,0};
	self.renderOrigin = {0,0,0};

	-- followings are for auto camera controller that emulates the C++'s CAutoCamera class in script. 
	self.m_vRotVelocity = {x=0,y=0};
	self.m_fRotationScaler = 0.01;
	self.m_vMouseDelta = {x=0, y=0};
	self.m_fFramesToSmoothMouseData = 2.0;
	self.m_bInvertPitch = false;
	self.CAMERA_Y_ANGLE_SPEED = 5.0 -- the rotation speed of the camera around the Y axis.
	self.MAX_CAM_LIFTUP_UPANGLE = math.pi*0.45
	self.MIN_CAM_LIFTUP_UPANGLE = -math.pi*0.45
	self.lastMousePos = {x=0, y=0}
	self.curMousePos = {x=0, y=0}
	self.isDragging = false
	self.ptCurMouseDelta = {x=0,y=0};
end

local uiname = "autoCameraMiniScene"
-- this function must be called in order for "beforeRenderFrameMoved" events to fire. 
function AutoCamera:EnableCameraFrameMove(bEnable)
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

function AutoCamera:OnBeforeRenderFrameMove()
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
function AutoCamera:ScheduleCameraMove(callbackFunc)
	self.frameMoveCallbacks = self.frameMoveCallbacks or {}
	self.frameMoveCallbacks[#(self.frameMoveCallbacks) + 1] = callbackFunc;
	self:EnableCameraFrameMove(true)
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
	local eye_pos = self:GetEyePosition()
	self.renderOrigin[1] = mathlib.FloatToInt(mathlib.DoubleToFloat(eye_pos[1]));
	self.renderOrigin[2] = mathlib.FloatToInt(mathlib.DoubleToFloat(eye_pos[2]));
	self.renderOrigin[3] = mathlib.FloatToInt(mathlib.DoubleToFloat(eye_pos[3]));
	return self.renderOrigin;
	--return ParaCamera.GetAttributeObject():GetField("RenderOrigin", self.renderOrigin);
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


function AutoCamera:UpdateMouseDelta(nDX, nDY)
	-- Calc how far it's moved since last frame
	self.ptCurMouseDelta.x = nDX;
	self.ptCurMouseDelta.y = nDY;
	
	local attr = ParaCamera.GetAttributeObject()
	self.m_fRotationScaler = attr:GetField("RotationScaler", self.m_fRotationScaler);

	-- Smooth the relative mouse data over a few frames so it isn't 
	-- jerky when moving slowly at low frame rates.
	local fPercentOfNew =  1.0 / self.m_fFramesToSmoothMouseData;
	local fPercentOfOld =  1.0 - fPercentOfNew;
	self.m_vMouseDelta.x = self.m_vMouseDelta.x * fPercentOfOld + self.ptCurMouseDelta.x * fPercentOfNew;
	self.m_vMouseDelta.y = self.m_vMouseDelta.y * fPercentOfOld + self.ptCurMouseDelta.y * fPercentOfNew;
	if (math.abs(self.m_vMouseDelta.x - self.ptCurMouseDelta.x) <= 1.0) then
		self.m_vMouseDelta.x = self.ptCurMouseDelta.x;
	end
	if (math.abs(self.m_vMouseDelta.y - self.ptCurMouseDelta.y) <= 1.0) then
		self.m_vMouseDelta.y = self.ptCurMouseDelta.y;
	end
	self.m_vRotVelocity.x = self.m_vMouseDelta.x * self.m_fRotationScaler;
	self.m_vRotVelocity.y = self.m_vMouseDelta.y * self.m_fRotationScaler;
end

-- this function should be called for all mouse event if one wants to handle camera control by script. 
-- so that we can emulate mouse dragging by script. One also needs to call FrameMoveCameraControl() for this to take effect. 
function AutoCamera:handleMouseEvent(event)
	local attr = ParaCamera.GetAttributeObject()
	local touchSession = event:GetTouchSession()

	if(touchSession and touchSession.id and type(self.isDragging) == "number") then
		if(touchSession.id == self.isDragging) then
			self.curMousePos.x, self.curMousePos.y = event.x, event.y;
			if(event:isAccepted() or not touchSession:IsEnabled()) then
				self.isDragging = false;
				self.touchSession = nil;
				return
			end
		else
			return;
		end
	else
		self.curMousePos.x, self.curMousePos.y = event.x, event.y;
		if(event:isAccepted()) then
			self.isDragging = false;
			self.touchSession = nil;
			return
		end
	end

	if(event:GetType() == "mousePressEvent") then
		local bStartDragging;
		if(event:button()=="left" and attr:GetField("EnableMouseLeftDrag", false)) then
			bStartDragging = true;
		end
		if(event:button()=="right" and attr:GetField("EnableMouseRightDrag", false)) then
			bStartDragging = true;
		end
		if(bStartDragging) then
			if(touchSession and touchSession.id) then
				self.isDragging = touchSession.id
				self.touchSession = touchSession;
			else
				self.isDragging = true;
				self.touchSession = nil;
			end
			self.lastMousePos.x, self.lastMousePos.y = self.curMousePos.x, self.curMousePos.y;
		end
	elseif(event:GetType() == "mouseReleaseEvent") then
		if(touchSession and touchSession.id) then
			if(self.isDragging == touchSession.id) then
				self.isDragging = false;
				self.touchSession = nil;
			end
		else
			self.isDragging = false;
			self.touchSession = nil;
		end
	elseif(event:GetType() == "mouseMoveEvent") then
	end
end

-- get the touch session that is dragging the view
function AutoCamera:GetTouchSession()
	return self.touchSession;
end

function AutoCamera:IsDragging()
	if(self.touchSession and self.touchSession:IsClosed()) then
		return false;
	end
	return self.isDragging;
end

-- this function should be called at 60FPS if one wants to handle camera control by script. 
-- one also needs to call handleMouseEvent() for this to take effect. 
function AutoCamera:FrameMoveCameraControl()
	self:UpdateMouseDelta(self.curMousePos.x - self.lastMousePos.x, self.curMousePos.y - self.lastMousePos.y)
	self.lastMousePos.x, self.lastMousePos.y = self.curMousePos.x, self.curMousePos.y;

	if(self.m_vRotVelocity.y ~= 0 or self.m_vRotVelocity.x~=0) then
		if(self:IsDragging()) then

			local attr = ParaCamera.GetAttributeObject()
			self.m_fCameraLiftupAngle, self.m_fCameraRotY = attr:GetField("CameraLiftupAngle", 0), attr:GetField("CameraRotY", 0);

			if(self.m_vRotVelocity.y ~= 0) then
				local fLiftUpAngle = self.m_vRotVelocity.y / 2;
				if (self.m_bInvertPitch) then
					fLiftUpAngle = -fLiftUpAngle;
				end
				fLiftUpAngle = self.m_fCameraLiftupAngle + fLiftUpAngle;
				-- angle constraint
				fLiftUpAngle = math.max(self.MIN_CAM_LIFTUP_UPANGLE, fLiftUpAngle);
				fLiftUpAngle = math.min(self.MAX_CAM_LIFTUP_UPANGLE, fLiftUpAngle);
				self.m_fCameraLiftupAngle = fLiftUpAngle;
				attr:SetField("CameraLiftupAngle", self.m_fCameraLiftupAngle)
			end

			if(self.m_vRotVelocity.x ~= 0) then
				-- if camera is locked, the mouse x delta will move the camera
				self.m_fCameraRotY = mathlib.ToStandardAngle(self.m_fCameraRotY + self.m_vRotVelocity.x);
				attr:SetField("CameraRotY", self.m_fCameraRotY)
			end
		end
	end
end

AutoCamera:InitSingleton();
