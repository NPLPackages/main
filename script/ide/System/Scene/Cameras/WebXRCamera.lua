--[[
Title: WebXR camera
Author(s): LiXizhi@yeah.net, big
CreateDate: 2024/6/19
ModifyDate: 2024/7/26
Desc: singleton class for WebXR camera.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Cameras/WebXRCamera.lua");
local WebXRCamera = commonlib.gettable("System.Scene.Cameras.WebXRCamera");
WebXRCamera:activate();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Cameras/Cameras.lua");
NPL.load("(gl)script/ide/System/Scene/Cameras/Camera.lua");
NPL.load("(gl)script/ide/math/Matrix4.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
NPL.load("(gl)script/ide/math/ShapeRay.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
NPL.load("(gl)script/ide/System/Scene/Overlays/Overlay.lua");
NPL.load("(gl)script/ide/System/Windows/MouseEvent.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/SelectionManager.lua");
local Quaternion = commonlib.gettable("mathlib.Quaternion");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local Overlay = commonlib.gettable("System.Scene.Overlays.Overlay");
local ShapeRay = commonlib.gettable("mathlib.ShapeRay");
local Mouse = commonlib.gettable("System.Windows.Mouse");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local Screen = commonlib.gettable("System.Windows.Screen");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local vector3d = commonlib.gettable("mathlib.vector3d");
local MouseEvent = commonlib.gettable("System.Windows.MouseEvent");
local SelectionManager = commonlib.gettable("MyCompany.Aries.Game.SelectionManager");

local WebXRCamera = commonlib.inherit(commonlib.gettable("System.Scene.Cameras.Camera"), commonlib.gettable("System.Scene.Cameras.WebXRCamera"));

WebXRCamera:Property({"Name", "WebXRCamera"});
WebXRCamera:Property({"guiToEyeDist", 2});
WebXRCamera:Property({"gui3DModeScaling", 1}); 
WebXRCamera:Property({"leftHandRayLength", 2});
WebXRCamera:Property({"rightHandRayLength", 2});

WebXRCamera.DirectionKey = {
	Up = { DIK_SCANCODE.DIK_W },
	Down ={ DIK_SCANCODE.DIK_S },
	Left = { DIK_SCANCODE.DIK_LEFT },
	Right = { DIK_SCANCODE.DIK_RIGHT },
    A = { DIK_SCANCODE.DIK_A },
    D = { DIK_SCANCODE.DIK_D },
	UpLeft = { DIK_SCANCODE.DIK_W , DIK_SCANCODE.DIK_A },
	UpRight = { DIK_SCANCODE.DIK_W , DIK_SCANCODE.DIK_D },
	DownLeft = { DIK_SCANCODE.DIK_S , DIK_SCANCODE.DIK_A },
	DownRight = { DIK_SCANCODE.DIK_S , DIK_SCANCODE.DIK_D },
}

WebXRCamera.KeyMapping = {
    -- LEFT HAND --
    LeftKey0Press = function(self)
        self.useLeftHand = true;
        self:PressMouseKey("left");
    end,
    LeftKey0Release = function(self)
        self:ReleaseMouseKey("left");
        self.isMoving = false;
        self.isMovingMouse = false;
        if (self.moveTimer) then
            self.moveTimer:Change();
            self.moveTimer = nil;
        end
    end,
    LeftKey1Press = function(self)
        self.useLeftHand = true;
        self.lockCameraYaw = true;
    end,
    LeftKey1Release = function(self)
        self.lockCameraYaw = false;

        if (self.isMovingMouse) then
            self:ReleaseMouseKey("left");
        else
            self:PressMouseKey("right");
            self:ReleaseMouseKey("right");
        end

        self.isMoving = false;
        self.isMovingMouse = false;
        if (self.moveTimer) then
            self.moveTimer:Change();
            self.moveTimer = nil;
        end
    end,
    LeftKey2Press = function(self) end,
    LeftKey2Release = function(self) end,
    LeftKey3Press = function(self) self:SendKeyEvent({ DIK_SCANCODE.DIK_SPACE }, true); end,
    LeftKey3Release = function(self) self:SendKeyEvent({ DIK_SCANCODE.DIK_SPACE }, false); end,
    LeftKey4Press = function(self)
        self.useLeftHand = true;

        if (self.viewTimer) then
            self.viewTimer:Change();
            self.viewTimer = nil;
        end

        self.viewTimer = commonlib.Timer:new({callbackFunc = function(timer)
            self.changeView = true;
            self.viewTimer = nil;
        end});
        self.viewTimer:Change(500, nil);
    end,
    LeftKey4Release = function(self)
        if (self.viewTimer) then
            self.viewTimer:Change();
            self.viewTimer = nil;
        end

        if (self.changeView) then
            if (self.personMode == "third") then
                self:SetPersonMode("first");
            else
                self:SetPersonMode("third");
            end
        else
            self:SendKeyEvent({ DIK_SCANCODE.DIK_ESCAPE }, true);
            self:SendKeyEvent({ DIK_SCANCODE.DIK_ESCAPE }, false);
        end

        self.changeView = false;
    end,
    LeftKey5Press = function(self)
        self.useLeftHand = true;

        -- fly.
        if (self.flyTimer) then
            self.flyTimer:Change();
            self.flyTimer = nil;
        end

        self.flyTimer = commonlib.Timer:new({callbackFunc = function(timer)
            self.canFly = true;
            self.flyTimer = nil;
        end});
        self.flyTimer:Change(500, nil);
    end,
    LeftKey5Release = function(self)
        if (self.flyTimer) then
            self.flyTimer:Change();
            self.flyTimer = nil;
        end

        if (self.canFly) then
            GameLogic.ToggleFly();
        else
            if (self.keyboardShowFlag) then
                self:ShowVirtualKeyboard(false);
                self.keyboardShowFlag = false;
            else
                self:ShowVirtualKeyboard(true);
                self.keyboardShowFlag = true;
            end
        end

        self.canFly = false;
    end,
    LeftKey6Press = function(self)  end,
    LeftKey6Release = function(self) end,

    -- RIGHT HAND --
    RightKey0Press = function(self)
        self.useLeftHand = false;
        self:PressMouseKey("left");
    end,
    RightKey0Release = function(self)
        self:ReleaseMouseKey("left");
        self.isMoving = false;
        self.isMovingMouse = false;
        if (self.moveTimer) then
            self.moveTimer:Change();
            self.moveTimer = nil;
        end
    end,
    RightKey1Press = function(self)
        self.useLeftHand = false;
        self.lockCameraYaw = true;
    end,
    RightKey1Release = function(self)
        self.lockCameraYaw = false;

        if (self.isMovingMouse) then
            self:ReleaseMouseKey("left");
        else
            self:PressMouseKey("right");
            self:ReleaseMouseKey("right");
        end

        self.isMoving = false;
        self.isMovingMouse = false;
        if (self.moveTimer) then
            self.moveTimer:Change();
            self.moveTimer = nil;
        end
    end,
    RightKey2Press = function(self) end,
    RightKey2Release = function(self) end,
    RightKey3Press = function(self) self:SendKeyEvent({ DIK_SCANCODE.DIK_SPACE }, true); end,
    RightKey3Release = function(self) self:SendKeyEvent({ DIK_SCANCODE.DIK_SPACE }, false); end,
    RightKey4Press = function(self)
        self.useLeftHand = false;

        if (self.viewTimer) then
            self.viewTimer:Change();
            self.viewTimer = nil;
        end

        self.viewTimer = commonlib.Timer:new({callbackFunc = function(timer)
            self.changeView = true;
            self.viewTimer = nil;
        end});
        self.viewTimer:Change(500, nil);
    end,
    RightKey4Release = function(self)
        if (self.viewTimer) then
            self.viewTimer:Change();
            self.viewTimer = nil;
        end

        if (self.changeView) then
            if (self.personMode == "third") then
                self:SetPersonMode("first");
            else
                self:SetPersonMode("third");
            end
        else
            self:SendKeyEvent({ DIK_SCANCODE.DIK_ESCAPE }, true);
            self:SendKeyEvent({ DIK_SCANCODE.DIK_ESCAPE }, false);
        end

        self.changeView = false;
    end,
    RightKey5Press = function(self)
        self.useLeftHand = false;

        -- fly.
        if (self.flyTimer) then
            self.flyTimer:Change();
            self.flyTimer = nil;
        end

        self.flyTimer = commonlib.Timer:new({callbackFunc = function(timer)
            self.canFly = true;
            self.flyTimer = nil;
        end});
        self.flyTimer:Change(500, nil);
    end,
    RightKey5Release = function(self)
        if (self.flyTimer) then
            self.flyTimer:Change();
            self.flyTimer = nil;
        end

        if (self.canFly) then
            GameLogic.ToggleFly();
        else
            if (self.keyboardShowFlag) then
                self:ShowVirtualKeyboard(false);
                self.keyboardShowFlag = false;
            else
                self:ShowVirtualKeyboard(true);
                self.keyboardShowFlag = true;
            end
        end

        self.canFly = false;
    end,
    RightKey6Press = function(self) end,
    RightKey6Release = function(self) end,
}

function WebXRCamera:ctor()
    GameLogic:Connect("WorldLoaded", self, self.OnWorldLoad, "UniqueConnection");
    self.webXR = ParaEngine.GetAttributeObject():GetChild("ViewportManager"):GetChild("WebXR");

    self.viewprojMatrix = Matrix4:new();
    self.viewMatrix = Matrix4:new();
    self.projMatrix = Matrix4:new();
    self.fieldOfView = 75 / 180 * math.pi;

    self.eye_pos = mathlib.vector3d:new();
    self.eye_pos1 = mathlib.vector3d:new();
    self.lookat_pos = mathlib.vector3d:new();
    self.webXRLeftEyePosition = mathlib.vector3d:new();
    self.webXRRightEyePosition = mathlib.vector3d:new();
    self.webXRLeftEyeOrientation = mathlib.Quaternion:new();
    self.webXRRightEyeOrientation = mathlib.Quaternion:new();
    self.webXRLeftHandPosition = mathlib.vector3d:new();
    self.webXRRightHandPosition = mathlib.vector3d:new();
    self.webXRLeftHandOrientation = mathlib.Quaternion:new();
    self.webXRRightHandOrientation = mathlib.Quaternion:new();
    self.webXRLeftAxes = { 0, 0, 0, 0 };
    self.webXRRightAxes = { 0, 0, 0, 0 };
    self.leftHandPos = {};
    self.rightHandPos = {};
    self.leftHandDir = {};
    self.rightHandDir = {};
    self.renderOrigin = { 0, 0, 0 };
    self.webXRHeadYaw = 0;

    self.deviceLeftHandKeyDown = {};
    self.leftHandKeyDown = {};
    self.leftHandKeyDown[0] = false;
    self.leftHandKeyDown[1] = false;
    self.leftHandKeyDown[2] = false;
    self.leftHandKeyDown[3] = false;
    self.leftHandKeyDown[4] = false;
    self.leftHandKeyDown[5] = false;
    self.leftHandKeyDown[6] = false; 

    self.deviceRightHandKeyDown = {};
    self.rightHandKeyDown = {};
    self.rightHandKeyDown[0] = false;
    self.rightHandKeyDown[1] = false;
    self.rightHandKeyDown[2] = false;
    self.rightHandKeyDown[3] = false;
    self.rightHandKeyDown[4] = false;
    self.rightHandKeyDown[5] = false;
    self.rightHandKeyDown[6] = false;

    self.isLeftAxesReleased = true;
    self.isRightAxesReleased = true;
    self.autoHideHandsWhenStill = true;

    self.personMode = "first";

    self.useLeftHand = true;
    -- default hand direction tilt down.
    local q = mathlib.Quaternion:new():FromAngleAxis(-math.pi / 12, {1, 0, 0});
    self.defaultHandDirection = q * mathlib.vector3d:new({0, 0, -1});

    self.smoothMoveFactor = 0.3; -- 1 no smooth.
    self.smoothAngleFactor = 0.3; -- 1 no smooth.
    self.defaultRayLength = 2;
    self.defaultMaxRayLength = 20;

    -- current follow camera parameters.
    self.camobjDist, self.LiftupAngle, self.CameraRotY = 10, 0.717, 0;

    -- overlay
    self.entities = {};

    -- for render
    self.pen = {width=0.01, color="#ffffff"};

    if (System.os.GetPlatform() == "win32" or System.os.GetPlatform() == "mac") then
        self.autoHideHandsWhenStill = false;
        self.webXRIsXREmulate = false;
        self.webXRTimeEmulate = 0;
        self.webXRLeftPositionEmulate = {0, 1.6, 0};
        self.webXRRightPositionEmulate = {0, 1.6, 0};
        self.webXRLeftOrientationEmulate = {0, 0, 0, 1};
        self.webXRRightOrientationEmulate = {0, 0, 0, 1};
        self.webXRLeftHandPositionEmulate = {-0.5, 1.5, -1};
        self.webXRRightHandPositionEmulate = {0.5, 1.5, -1};
        self.webXRLeftHandOrientationEmulate = {0, 0, 0, 1};
        self.webXRRightHandOrientationEmulate = {0, 0, 0, 1};
        self.leftHandKey0Emulate = false;
        self.leftHandKey1Emulate = false;
        self.leftHandKey2Emulate = false;
        self.leftHandKey3Emulate = false;
        self.leftHandKey4Emulate = false;
        self.leftHandKey5Emulate = false;
        self.leftHandKey6Emulate = false;
        self.rightHandKey0Emulate = false;
        self.rightHandKey1Emulate = false;
        self.rightHandKey2Emulate = false;
        self.rightHandKey3Emulate = false;
        self.rightHandKey4Emulate = false;
        self.rightHandKey5Emulate = false;
        self.rightHandKey6Emulate = false;
        self.webXRLeftAxesEmulate = {0, 0, 0, 0};
        self.webXRRightAxesEmulate = {0, 0, 0, 0};
    end
end

function WebXRCamera:GetSubEntity(index)
    local entity = self.entities[index or 1]
    if(not entity) then
		entity = Overlay:new():init();
        entity.EnableZPass = true;
        entity.ZPassOpacity = 1;
        entity:SetBoundRadius(2);
        entity.paintEvent = function(overlay, painter)
            return self:OnPaintEntity(index, overlay, painter);
        end
		self.entities[index or 1] = entity;
	end
    return entity;
end

function WebXRCamera:GetLeftHandEntity()
    return self:GetSubEntity(1)
end

function WebXRCamera:GetRightHandEntity()
    return self:GetSubEntity(2)
end

function WebXRCamera:RemoveAllSubEntity()
    for i = 1, #self.entities do
		self.entities[i]:Destroy();
	end
	self.entities = {};
end

-- @param nIndex: 1 for left hand, 2 for right hand
-- @param overlay: the overlay entity
function WebXRCamera:OnPaintEntity(nIndex, overlay, painter)
    if(overlay:IsPickingPass()) then
		return;
	end
    painter:Save();
	painter:PushMatrix();

    -- tricky: following code is to make the entity relative to the camera at render rate.
    local att = ParaCamera.GetAttributeObject();
    local x, y, z = overlay:GetPosition();

    self.eye_pos = att:GetField("Eye position", self.eye_pos);
    painter:TranslateMatrix(self.eye_pos[1] - x, self.eye_pos[2] - y, self.eye_pos[3] - z);

    -- local quatCamera = Quaternion:new():FromEulerAnglesSequence(0, 0, self.CameraRotY, "zxy") 
    -- painter:PushMatrix(quatCamera:ToRotationMatrix());
    local camobjDist, LiftupAngle, CameraRotY = ParaCamera.GetEyePos();
    painter:RotateMatrix(CameraRotY + math.pi / 2, 0, 1, 0);
    local cameraRotateQuat = mathlib.Quaternion:new();
    cameraRotateQuat:FromAngleAxis(CameraRotY + math.pi / 2, {0, 1, 0});

    self:SetBrushColor(nIndex, painter);

	local webXRAverageEyeRot = (self.webXRLeftEyeOrientation + self.webXRRightEyeOrientation):Normalize();
    -- TODO: calculate the hand position and orientation, relative to the camera.
    local eyeCenterPos = (self.webXRLeftEyePosition + self.webXRRightEyePosition) * 0.5;
    local webXREyeRot = (self.webXRLeftEyeOrientation + self.webXRRightEyeOrientation):Normalize();
    local handDistance = 0.5;

    -- LEFT HAND
    local leftHandPos = self.webXRLeftHandPosition - eyeCenterPos;
    -- z axis in paracraft is in opposite direction of webxr.
    leftHandPos[3] = -leftHandPos[3];
    local webXRLeftHandOrientation = commonlib.clone(self.webXRLeftHandOrientation);

    local roll, pitch, yaw = webXRLeftHandOrientation:ToEulerAnglesSequence("zxy");
    local x = handDistance * math.sin(yaw);
    local z = handDistance * math.cos(yaw);
    leftHandPos[1] = leftHandPos[1] - x;
    leftHandPos[3] = leftHandPos[3] + z;

    local leftHandDir = mathlib.vector3d:new(webXRLeftHandOrientation * self.defaultHandDirection);
    local leftRayLength = self.leftHandRayLength;

    leftHandDir[3] = -leftHandDir[3];
    leftHandDir = leftHandDir * leftRayLength;

    local leftHandFrom = leftHandPos;
    local leftHandTo = leftHandPos + leftHandDir;

    if (nIndex == 1) then
        ShapesDrawer.DrawLine(painter, leftHandFrom[1], leftHandFrom[2], leftHandFrom[3], leftHandTo[1], leftHandTo[2], leftHandTo[3]);
    end

    local leftHandToWorld = mathlib.vector3d:new(cameraRotateQuat * leftHandTo);
    leftHandToWorld:add(self.eye_pos1);
    local pX, pY, pZ = leftHandToWorld[1], leftHandToWorld[2], leftHandToWorld[3];

    local leftHandFromWorld = mathlib.vector3d:new(cameraRotateQuat * leftHandFrom);
    leftHandFromWorld:add(self.eye_pos1);

    self.leftHandPos = leftHandFromWorld;
    self.leftHandDir = (leftHandToWorld - leftHandFromWorld):normalize();

    local leftPosX, leftPosY = self:CalculatePointInScreenSpace(pX, pY, pZ);

    -- RIGHT HAND
    local rightHandPos = self.webXRRightHandPosition - eyeCenterPos;
    -- z axis in paracraft is in opposite direction of webxr.
    rightHandPos[3] = -rightHandPos[3];
    local webXRRightHandOrientation = commonlib.clone(self.webXRRightHandOrientation);

    local roll, pitch, yaw = webXRRightHandOrientation:ToEulerAnglesSequence("zxy");
    local x = handDistance * math.sin(yaw);
    local z = handDistance * math.cos(yaw);
    rightHandPos[1] = rightHandPos[1] - x;
    rightHandPos[3] = rightHandPos[3] + z;

    local rightHandDir = mathlib.vector3d:new(webXRRightHandOrientation  * self.defaultHandDirection);
    local rightRayLength = self.rightHandRayLength;

    rightHandDir[3] = -rightHandDir[3];
    rightHandDir = rightHandDir * rightRayLength;

    local rightHandFrom = rightHandPos;
    local rightHandTo = rightHandPos + rightHandDir;

    if (nIndex == 2) then
        ShapesDrawer.DrawLine(painter, rightHandPos[1], rightHandPos[2], rightHandPos[3], rightHandTo[1], rightHandTo[2], rightHandTo[3]);
    end

    local rightHandToWorld = mathlib.vector3d:new(cameraRotateQuat * rightHandTo);
    rightHandToWorld:add(self.eye_pos1);
    local pX, pY, pZ = rightHandToWorld[1], rightHandToWorld[2], rightHandToWorld[3];

    local rightHandFromWorld = mathlib.vector3d:new(cameraRotateQuat * rightHandFrom);
    rightHandFromWorld:add(self.eye_pos1);

    self.rightHandPos = rightHandFromWorld;
    self.rightHandDir = (rightHandToWorld - rightHandFromWorld):normalize();

    local rightPosX, rightPosY = self:CalculatePointInScreenSpace(pX, pY, pZ);

    self:SetMousePosition(leftPosX, leftPosY, rightPosX, rightPosY);

    self:CalculateRayLength(nIndex);

    if (self:IsPressLeftKey(0) or self:IsPressLeftKey(1) or self:IsPressRightKey(0) or self:IsPressRightKey(1)) then
         -- move mouse.
        if (not self.isMoving) then
            self.isMoving = true;
            if (self.moveTimer) then
                self.moveTimer:Change();
            end

            self.moveTimer = commonlib.Timer:new({callbackFunc = function(timer)
                if (self:IsPressRightKey(1) or self:IsPressLeftKey(1)) then
                    self:PressMouseKey("left");
                end

                self.isMovingMouse = true;
                self.moveTimer = nil;
            end});
            self.moveTimer:Change(500, nil);
        else
            if (self.isMovingMouse) then
                self:MoveMouse();
            end
        end
    end

    painter:PopMatrix();
	painter:Restore();
end

function WebXRCamera.OnWorldLoad()
    local self = WebXRCamera;
    if self:IsXR() then
        self:RemoveAllSubEntity();
        self:LockCamera(true)
        self.camobjDist, self.LiftupAngle, self.CameraRotY = ParaCamera.GetEyePos();

        ParaCamera.GetAttributeObject():SetField("CameraLiftupAngle", 0);
        ParaCamera.GetAttributeObject():SetField('FieldOfView', self.fieldOfView);

        -- render GUI in 3D space fixed at self.guiToEyeDist meters in front of the eye.
        local root = ParaUI.GetUIObject("root")
        root:SetField("3DGUIMode", true);
        root:SetField("GUIToEyeDist", self.guiToEyeDist or 10);
        root:SetField("GUI3DModeScaling", self.gui3DModeScaling or 1);

        GameLogic.options:SetStereoConvergenceOffset(45);
        GameLogic.options:SetStereoEyeSeparationDist(0.06);

        commonlib.TimerManager.SetTimeout(function()
            self:SetPersonMode("first");
            NPL.load("(gl)script/apps/Aries/Creator/Game/SceneContext/AllContext.lua");
            local AllContext = commonlib.gettable("MyCompany.Aries.Game.AllContext");
            AllContext:ResetContext();
        end, 3000);
    end
end

-- this function should be called when WebXR mode is exited.
function WebXRCamera:OnDeactivate()
    self:RemoveAllSubEntity();
    local root = ParaUI.GetUIObject("root")
    root:SetField("3DGUIMode", false);
end

function WebXRCamera:activate()
	if not self:IsXR() then
        self:SetXR(true);
        self:LockCamera(true)
        self.camobjDist, self.LiftupAngle, self.CameraRotY = ParaCamera.GetEyePos();

        ParaCamera.GetAttributeObject():SetField("CameraLiftupAngle", 0);
        ParaCamera.GetAttributeObject():SetField('FieldOfView', self.fieldOfView);

        -- render GUI in 3D space fixed at self.guiToEyeDist meters in front of the eye.
        local root = ParaUI.GetUIObject("root")
        root:SetField("3DGUIMode", true);
        root:SetField("GUIToEyeDist", self.guiToEyeDist or 10);
        root:SetField("GUI3DModeScaling", self.gui3DModeScaling or 1);

        GameLogic.options:SetStereoConvergenceOffset(45);
        GameLogic.options:SetStereoEyeSeparationDist(0.06);

        System.Scene.Cameras:SetCurrent(self);

        if (System.os.GetPlatform() == "win32" or System.os.GetPlatform() == "mac") then
            self:SimulatorPage(true);
            self:UpdateFromEmulate();
        else
            self:UpdateFromDevice();
        end

        LOG.std(nil, "info", "WebXRCamera", "activate WebXR mode");

        self:SetPersonMode("first");

        NPL.load("(gl)script/apps/Aries/Creator/Game/Mobile/MobileUIRegister.lua");
        local MobileUIRegister = commonlib.gettable("MyCompany.Aries.Creator.Game.Mobile.MobileUIRegister");

        if (MobileUIRegister.emsShowMobileUITimer) then
            MobileUIRegister.emsShowMobileUITimer:Change();
        end
        MobileUIRegister.SetMobileUIEnable(false);

        commonlib.TimerManager.SetTimeout(function()
            local TouchVirtualKeyboardIcon = GameLogic.GetFilters():apply_filters("TouchVirtualKeyboardIcon");
            if not TouchVirtualKeyboardIcon then
                NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchVirtualKeyboardIcon.lua");
                TouchVirtualKeyboardIcon = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboardIcon");
	        end
            TouchVirtualKeyboardIcon.ShowSingleton(false);
        end, 500);
    end
end

function WebXRCamera:deactivate()
    if self:IsXR() then
        self:SetXR(false);
        self:LockCamera(false)
        self:SimulatorPage(false);
        self:SetPersonMode("third");
    end
end

function WebXRCamera:IsXR()
    if (System.os.GetPlatform() == "win32" or System.os.GetPlatform() == "mac") then
        return self.webXRIsXREmulate;
    else
        return self.webXR:GetField("isXR", false);
    end
end

function WebXRCamera:SetXR(isXR)
    if (System.os.GetPlatform() == "win32" or System.os.GetPlatform() == "mac") then
        self.webXRIsXREmulate = isXR;
    else
        self.webXR:SetField("isXR", isXR);
    end
end

function WebXRCamera:SetAdditionalCameraRotate(yaw, pitch, roll)
	-- disable it
end

function WebXRCamera:UpdateKeyState()
    -- LEFT HAND EVENT --
    if (self:IsPressLeftKey(0) and not self.leftHandKeyDown[0]) then
        self.leftHandKeyDown[0] = true;
        self.KeyMapping["LeftKey0Press"](self);
    elseif (not self:IsPressLeftKey(0) and self.leftHandKeyDown[0]) then
        self.leftHandKeyDown[0] = false;
        self.KeyMapping["LeftKey0Release"](self);
    end

    if (self:IsPressLeftKey(1) and not self.leftHandKeyDown[1]) then
        self.leftHandKeyDown[1] = true;
        self.KeyMapping["LeftKey1Press"](self);
    elseif (not self:IsPressLeftKey(1) and self.leftHandKeyDown[1]) then
        self.leftHandKeyDown[1] = false;
        self.KeyMapping["LeftKey1Release"](self);
    end

    if (self:IsPressLeftKey(2) and not self.leftHandKeyDown[2]) then
        self.leftHandKeyDown[2] = true;
        self.KeyMapping["LeftKey2Press"](self);
    elseif (not self:IsPressLeftKey(2) and self.leftHandKeyDown[2]) then
        self.leftHandKeyDown[2] = false;
        self.KeyMapping["LeftKey2Release"](self);
    end

    if (self:IsPressLeftKey(3) and not self.leftHandKeyDown[3]) then
        self.leftHandKeyDown[3] = true;
        self.KeyMapping["LeftKey3Press"](self);
    elseif (not self:IsPressLeftKey(3) and self.leftHandKeyDown[3]) then
        self.leftHandKeyDown[3] = false;
        self.KeyMapping["LeftKey3Release"](self);
    end

    -- left A(X) button.
    if (self:IsPressLeftKey(4) and not self.leftHandKeyDown[4]) then
        self.leftHandKeyDown[4] = true;
        self.KeyMapping["LeftKey4Press"](self);
    elseif (not self:IsPressLeftKey(4) and self.leftHandKeyDown[4]) then
        self.leftHandKeyDown[4] = false;
        self.KeyMapping["LeftKey4Release"](self);
    end

    if (self:IsPressLeftKey(5) and not self.leftHandKeyDown[5]) then
        self.leftHandKeyDown[5] = true;
        self.KeyMapping["LeftKey5Press"](self);
    elseif (not self:IsPressLeftKey(5) and self.leftHandKeyDown[5]) then
        self.leftHandKeyDown[5] = false;
        self.KeyMapping["LeftKey5Release"](self);
    end

    if (self:IsPressLeftKey(6) and not self.leftHandKeyDown[6]) then
        self.leftHandKeyDown[6] = true;
        self.KeyMapping["LeftKey6Press"](self);
    elseif (not self:IsPressLeftKey(6) and self.leftHandKeyDown[6]) then
        self.leftHandKeyDown[6] = false;
        self.KeyMapping["LeftKey6Release"](self);
    end

    -- RIGHT HAND EVENT --
    if (self:IsPressRightKey(0) and not self.rightHandKeyDown[0]) then
        self.rightHandKeyDown[0] = true;
        self.KeyMapping["RightKey0Press"](self);
    elseif (not self:IsPressRightKey(0) and self.rightHandKeyDown[0]) then
        self.rightHandKeyDown[0] = false;
        self.KeyMapping["RightKey0Release"](self);
    end

    if (self:IsPressRightKey(1) and not self.rightHandKeyDown[1]) then
        self.rightHandKeyDown[1] = true;
        self.KeyMapping["RightKey1Press"](self);
    elseif (not self:IsPressRightKey(1) and self.rightHandKeyDown[1]) then
        self.rightHandKeyDown[1] = false;
        self.KeyMapping["RightKey1Release"](self);
    end

    if (self:IsPressRightKey(2) and not self.rightHandKeyDown[2]) then
        self.rightHandKeyDown[2] = true;
        self.KeyMapping["RightKey2Press"](self);
    elseif (not self:IsPressRightKey(2) and self.rightHandKeyDown[2]) then
        self.rightHandKeyDown[2] = false;
        self.KeyMapping["RightKey2Release"](self);
    end

    if (self:IsPressRightKey(3) and not self.rightHandKeyDown[3]) then
        self.rightHandKeyDown[3] = true;
        self.KeyMapping["RightKey3Press"](self);
    elseif (not self:IsPressRightKey(3) and self.rightHandKeyDown[3]) then
        self.rightHandKeyDown[3] = false;
        self.KeyMapping["RightKey3Release"](self);
    end

    -- right A button.
    if (self:IsPressRightKey(4) and not self.rightHandKeyDown[4]) then
        self.rightHandKeyDown[4] = true;
        self.KeyMapping["RightKey4Press"](self);
    elseif (not self:IsPressRightKey(4) and self.rightHandKeyDown[4]) then
        self.rightHandKeyDown[4] = false;
        self.KeyMapping["RightKey4Release"](self);
    end

    if (self:IsPressRightKey(5) and not self.rightHandKeyDown[5]) then
        self.rightHandKeyDown[5] = true;
        self.KeyMapping["RightKey5Press"](self);
    elseif (not self:IsPressRightKey(5) and self.rightHandKeyDown[5]) then
        self.rightHandKeyDown[5] = false;
        self.KeyMapping["RightKey5Release"](self);
    end

    if (self:IsPressRightKey(6) and not self.rightHandKeyDown[6]) then
        self.rightHandKeyDown[6] = true;
        self.KeyMapping["RightKey6Press"](self);
    elseif (not self:IsPressRightKey(6) and self.rightHandKeyDown[6]) then
        self.rightHandKeyDown[6] = false;
        self.KeyMapping["RightKey6Release"](self);
    end

    -- right axes.
    if (self.webXRRightAxes[3] ~= 0 or self.webXRRightAxes[4] ~= 0) then
        self.isRightAxesReleased = false;
        self.rightAxesReleasedCount = 0;
        self:SendKeyEvent(self.rightKeyNameList or {}, false);
        local direction = self:GetDirectionState({ self.webXRRightAxes[3], self.webXRRightAxes[4] });
        self.rightKeyNameList = self.DirectionKey[direction] or {};
        self:SendKeyEvent(self.rightKeyNameList, true);
    else
        if (not self.isRightAxesReleased) then
            self:SendKeyEvent(self.rightKeyNameList or {}, false);
            self.isRightAxesReleased = true;
        end
    end

    -- left axes.
    if (self.webXRLeftAxes[3] ~= 0 or self.webXRLeftAxes[4] ~= 0) then
        self.isLeftAxesReleased = false;
        self.leftAxesReleasedCount = 0;
        self:SendKeyEvent(self.leftKeyNameList or {}, false);
        local direction = self:GetDirectionState({ self.webXRLeftAxes[3], self.webXRLeftAxes[4] });
        self.leftKeyNameList = self.DirectionKey[direction] or {};
        self:SendKeyEvent(self.leftKeyNameList, true);
    else
        if (not self.isLeftAxesReleased) then
            self:SendKeyEvent(self.leftKeyNameList or {}, false);
            self.isLeftAxesReleased = true;
        end
    end
end

function WebXRCamera:UpdateCameraPosition()
    local att = ParaCamera.GetAttributeObject();
    self.lookat_pos = att:GetField("Lookat position", self.lookat_pos);
    self.eye_pos = att:GetField("Eye position", self.eye_pos);
    self.camobjDist, self.LiftupAngle, self.CameraRotY = ParaCamera.GetEyePos();

    local eyeX, eyeY, eyeZ = self.eye_pos[1], self.eye_pos[2], self.eye_pos[3];

    self:GetLeftHandEntity():SetPosition(eyeX, eyeY, eyeZ);
    self:GetRightHandEntity():SetPosition(eyeX, eyeY, eyeZ);

    local webXRAverageEyeRot = (self.webXRLeftEyeOrientation + self.webXRRightEyeOrientation):Normalize();
    local roll, pitch, yaw = webXRAverageEyeRot:ToEulerAnglesSequence("zxy");

    self.webXRHeadYaw = yaw;

    -- tricky: pitch shall use absolute value from webXR.
    att:SetField("AdditionalCameraRotate", {yaw, self.LiftupAngle + pitch, -roll});
end

function WebXRCamera:SetMousePosition(leftHandX, leftHandY, rightHandX, rightHandY)
    if (self.useLeftHand) then
        Mouse:SetMousePosition(leftHandX, leftHandY);
    else
        Mouse:SetMousePosition(rightHandX, rightHandY);
    end

    local sx, sy = Screen:GetUIScale();
    self.lastLeftHandDeviceMouseX = leftHandX * sx;
    self.lastLeftHandDeviceMouseY = leftHandY * sy;
    self.lastRightHandDeviceMouseX = rightHandX * sx;
    self.lastRightHandDeviceMouseY = rightHandY * sy;
end

function WebXRCamera:PressMouseKey(keyName)
    if (self.useLeftHand) then
        Mouse:SendMouseButtonEvent(self.lastLeftHandDeviceMouseX, self.lastLeftHandDeviceMouseY, keyName, "down");
    else
        Mouse:SendMouseButtonEvent(self.lastRightHandDeviceMouseX, self.lastRightHandDeviceMouseY, keyName, "down");
    end
end

function WebXRCamera:ReleaseMouseKey(keyName)
    if (self.useLeftHand) then
        Mouse:SendMouseButtonEvent(self.lastLeftHandDeviceMouseX, self.lastLeftHandDeviceMouseY, keyName, "up");
    else
        Mouse:SendMouseButtonEvent(self.lastRightHandDeviceMouseX, self.lastRightHandDeviceMouseY, keyName, "up");
    end
end

function WebXRCamera:MoveMouse()
    if (self.useLeftHand) then
        Mouse:SendMouseMoveEvent(self.lastLeftHandDeviceMouseX, self.lastLeftHandDeviceMouseY);
    else
        Mouse:SendMouseMoveEvent(self.lastRightHandDeviceMouseX, self.lastRightHandDeviceMouseY);
    end
end

function WebXRCamera:SetPersonMode(mode)
    if (mode == "first") then
        self.personMode = "first";
        GameLogic.RunCommand("/camerapitch 0");
        GameLogic.RunCommand("/cameradist 1");
        GameLogic.RunCommand("/hide");
    elseif (mode == "third") then
        self.personMode = "third";
        GameLogic.RunCommand("/show");
        GameLogic.RunCommand("/camerapitch 0");
        GameLogic.RunCommand("/cameradist 10");
    end
end

local lastPositionX = 0;
local isDragStarted = false;
function WebXRCamera:SetDragToRotate(isDrag, isLeft)
    local curPositionX = 0;
    if (isLeft) then
        curPositionX = self.webXRLeftHandPosition[1];
    else
        curPositionX = self.webXRRightHandPosition[1];
    end

    if (isDrag) then
        if (not isDragStarted) then
            lastPositionX = curPositionX;
        end
        isDragStarted = true;
        local difference = lastPositionX - curPositionX;

        if (not ParaEngine.GetAttributeObject():GetField("IsMouseInverse", false)) then
            difference = -difference;
        end

        lastPositionX = curPositionX;
        local cameraRotY = ParaCamera.GetAttributeObject():GetField("CameraRotY", 0);

        cameraRotY = cameraRotY + (difference * 16)
        ParaCamera.GetAttributeObject():SetField("CameraRotY", cameraRotY);
    else
        isDragStarted = false;
    end
end

local lastPositionY = 0;
local isDragLiftupStarted = false;
function WebXRCamera:SetDragToLiftup(isDrag, isLeft)
    if (isDrag) then
        if (self.liftUpTimer) then
            self.liftUpTimer:Change();
        end

        self.liftUpTimer = commonlib.Timer:new({callbackFunc = function(timer)
            local curPositionY = 0;
            if (isLeft) then
                curPositionY = self.webXRLeftHandPosition[2];
            else
                curPositionY = self.webXRRightHandPosition[2];
            end

            if (not isDragLiftupStarted) then
                lastPositionY = curPositionY;
            end
            isDragLiftupStarted = true;
            local difference = lastPositionY - curPositionY;

            if (not ParaEngine.GetAttributeObject():GetField("IsMouseInverse", false)) then
                difference = -difference;
            end

            lastPositionY = curPositionY;
            local cameraLiftupAngle = ParaCamera.GetAttributeObject():GetField("CameraLiftupAngle", 0);

            cameraLiftupAngle = cameraLiftupAngle + (difference * 6);

            if (cameraLiftupAngle <= -1.57) then
                cameraLiftupAngle = -1.57;
            elseif (cameraLiftupAngle >= 1.57) then
                cameraLiftupAngle = 1.57;
            end

            ParaCamera.GetAttributeObject():SetField("CameraLiftupAngle", cameraLiftupAngle);
        end})

        self.liftUpTimer:Change(0, 16);
    else
        isDragLiftupStarted = false;
        if (self.liftUpTimer) then
            self.liftUpTimer:Change();
        end
    end
end

function WebXRCamera:SendKeyEvent(keyNameList, isKeyDown)
    for _, vKey in pairs(keyNameList) do
        Keyboard:SendKeyEvent(isKeyDown and "keyDownEvent" or "keyUpEvent", vKey);
    end
end

-- 顺序: z -> y -> x | pitch yaw roll
-- local roll, yaw, pitch = self.webXRLeftHandOrientation:ToEulerAnglesSequence("zyx")
-- echo({"zyx", { yaw_zyx, pitch_zyx, roll_zyx }}, true)
local lastTime = os.clock();
function WebXRCamera:UpdateFromDevice()
    if (self:IsXR()) then
        self.webXRLeftEyeOrientation = self.webXR:GetField("webXRLeftOrientation", self.webXRLeftEyeOrientation);
        self.webXRRightEyeOrientation = self.webXR:GetField("webXRRightOrientation", self.webXRRightEyeOrientation);

        self.webXRLeftEyePosition = self.webXR:GetField("webXRLeftPosition", self.webXRLeftEyePosition);
        self.webXRRightEyePosition = self.webXR:GetField("webXRRightPosition", self.webXRRightEyePosition);

        local currentTime = os.clock();
        local deltaTime = currentTime - lastTime;
        lastTime = currentTime;
        local smoothMoveFactor = math.max(1, self.smoothMoveFactor * (deltaTime * 60));

        -- position
        self.lastWebXRLeftHandPosition = commonlib.clone(self.webXRLeftHandPosition) or mathlib.vector3d:new();
        self.webXRLeftHandPosition = self.webXR:GetField("webXRLeftHandPosition", self.webXRLeftHandPosition);
        self.webXRLeftHandPosition = self.lastWebXRLeftHandPosition * (1 - smoothMoveFactor) + self.webXRLeftHandPosition * smoothMoveFactor;

        self.lastWebXRRightHandPosition = commonlib.clone(self.webXRRightHandPosition) or mathlib.vector3d:new();
        self.webXRRightHandPosition = self.webXR:GetField("webXRRightHandPosition", self.webXRRightHandPosition);
        self.webXRRightHandPosition = self.lastWebXRRightHandPosition * (1 - smoothMoveFactor) + self.webXRRightHandPosition * smoothMoveFactor;

        -- orientation
        self.lastWebXRLeftHandOrientation = commonlib.clone(self.webXRLeftHandOrientation) or mathlib.Quaternion:new();
        self.webXRLeftHandOrientation = self.webXR:GetField("webXRLeftHandOrientation", self.webXRLeftHandOrientation);
        self.webXRLeftHandOrientation = mathlib.Quaternion:new():slerp(self.lastWebXRLeftHandOrientation, self.webXRLeftHandOrientation, self.smoothAngleFactor);

        self.lastWebXRRightHandOrientation = commonlib.clone(self.webXRRightHandOrientation) or mathlib.Quaternion:new();
        self.webXRRightHandOrientation = self.webXR:GetField("webXRRightHandOrientation", self.webXRRightHandOrientation);
        self.webXRRightHandOrientation = mathlib.Quaternion:new():slerp(self.lastWebXRRightHandOrientation, self.webXRRightHandOrientation, self.smoothAngleFactor);

        self.webXRLeftAxes = self.webXR:GetField("webXRLeftAxes", {});
        self.webXRRightAxes = self.webXR:GetField("webXRRightAxes", {});

        self:UpdateCameraPosition();
        self:ReadAllDeviceKeysToBuffer();
        self:UpdateKeyState();
        Screen:GetUIScale(true)
    else
        System.Scene.Cameras:SetCurrent(System.Scene.Cameras.AutoCamera);
    end
end

function WebXRCamera:UpdateFromEmulate()
    if (self.webXRIsXREmulate) then
        self.webXRLeftEyeOrientation = mathlib.Quaternion:new(self.webXRLeftOrientationEmulate);
        self.webXRRightEyeOrientation = mathlib.Quaternion:new(self.webXRRightOrientationEmulate);

        self.webXRLeftEyePosition = mathlib.vector3d:new(self.webXRLeftPositionEmulate);
        self.webXRRightEyePosition = mathlib.vector3d:new(self.webXRRightPositionEmulate);

        -- position
        self.lastWebXRLeftHandPosition = commonlib.clone(self.webXRLeftHandPosition) or mathlib.vector3d:new();
        self.webXRLeftHandPosition = mathlib.vector3d:new(self.webXRLeftHandPositionEmulate);
        self.webXRLeftHandPosition = self.lastWebXRLeftHandPosition * (1 - self.smoothMoveFactor) + self.webXRLeftHandPosition * self.smoothMoveFactor;

        self.lastWebXRRightHandPosition = commonlib.clone(self.webXRRightHandPosition) or mathlib.vector3d:new();
        self.webXRRightHandPosition = mathlib.vector3d:new(self.webXRRightHandPositionEmulate);
        self.webXRRightHandPosition = self.lastWebXRRightHandPosition * (1 - self.smoothMoveFactor) + self.webXRRightHandPosition * self.smoothMoveFactor;

        -- orientation
        self.lastWebXRLeftHandOrientation = commonlib.clone(self.webXRLeftHandOrientation) or mathlib.Quaternion:new();
        self.webXRLeftHandOrientation = mathlib.Quaternion:new(self.webXRLeftHandOrientationEmulate);
        self.webXRLeftHandOrientation = mathlib.Quaternion:new():slerp(self.lastWebXRLeftHandOrientation, self.webXRLeftHandOrientation, self.smoothAngleFactor);
        
        self.lastWebXRRightHandOrientation = commonlib.clone(self.webXRRightHandOrientation) or mathlib.Quaternion:new();
        self.webXRRightHandOrientation = mathlib.Quaternion:new(self.webXRRightHandOrientationEmulate);
        self.webXRRightHandOrientation = mathlib.Quaternion:new():slerp(self.lastWebXRRightHandOrientation, self.webXRRightHandOrientation, self.smoothAngleFactor);

        self.webXRLeftAxes = self.webXRLeftAxesEmulate;
        self.webXRRightAxes = self.webXRRightAxesEmulate;

        self:UpdateCameraPosition();
        self:ReadAllDeviceKeysToBufferEmulate();
        self:UpdateKeyState();
        Screen:GetUIScale(true)
    else
        System.Scene.Cameras:SetCurrent(System.Scene.Cameras.AutoCamera);
    end
end

function WebXRCamera:SimulatorPage(bShow)
    if (bShow) then
        if (self.simulatorParams) then
            self.simulatorParams._page:CloseWindow();
        end

        local params = {
            url = "script/ide/System/Scene/Cameras/WebXRSimulator.html",
            name = "ide.System.Scene.Cameras.WebXRSimulator",
            isShowTitleBar = false,
            DestroyOnClose = true,
            style = CommonCtrl.WindowFrame.ContainerStyle,
            zorder = 1,
            allowDrag = true,
            bShow = true,
            directPosition = true,
            align = '_lt',
            x = 0,
            y = 0,
            width = 430,
            height = 340,
            cancelShowAnimation = true,
            bToggleShowHide = false,
            click_through = true,
        }

        System.App.Commands.Call('File.MCMLWindowFrame', params);
        self.simulatorParams = params;
    else
        if (self.simulatorParams) then
            self.simulatorParams._page:CloseWindow();
        end
    end
end

function WebXRCamera:GetDirectionState(mouse_pos)
	local param_x = mouse_pos[1] - 0;
	local param_y = mouse_pos[2] - 0;

	local rotation = math.atan2(-param_y,  param_x) * 180 / math.pi;
    local webXRHeadYawDegree = self.webXRHeadYaw * (180 / math.pi);

	if rotation < 22.5 and rotation >= -22.5 then
        if (self.lockCameraYaw) then
            if webXRHeadYawDegree < 22.5 and webXRHeadYawDegree >= -22.5 then
                return "D";
            elseif webXRHeadYawDegree < -22.5 and webXRHeadYawDegree >= -67.5 then
                return "DownRight";
            elseif webXRHeadYawDegree < -67.5 and webXRHeadYawDegree >=  -112.5 then
                return "Down";
            elseif webXRHeadYawDegree < -112.5 and webXRHeadYawDegree >= -157.5 then
                return "DownLeft";
            elseif webXRHeadYawDegree < -157.5 or webXRHeadYawDegree >= 157.5 then
                return "A";
            elseif webXRHeadYawDegree < 157.5 and webXRHeadYawDegree >= 112.5 then
                return "UpLeft";
            elseif webXRHeadYawDegree < 112.5 and webXRHeadYawDegree >= 67.5 then
                return "Up";
            elseif webXRHeadYawDegree < 67.5 and webXRHeadYawDegree >= 22.5 then
                return "UpRight";
            end
        else
            return "Right";
        end
	elseif rotation < -22.5 and rotation >= -67.5 then
        if webXRHeadYawDegree < 22.5 and webXRHeadYawDegree >= -22.5 then -- default down right.
            return "DownRight";
        elseif webXRHeadYawDegree < -22.5 and webXRHeadYawDegree >= -67.5 then
            return "Down";
        elseif webXRHeadYawDegree < -67.5 and webXRHeadYawDegree >=  -112.5 then
            return "DownLeft";
        elseif webXRHeadYawDegree < -112.5 and webXRHeadYawDegree >= -157.5 then
            return "A";
        elseif webXRHeadYawDegree < -157.5 or webXRHeadYawDegree >= 157.5 then
            return "UpLeft";
        elseif webXRHeadYawDegree < 157.5 and webXRHeadYawDegree >= 112.5 then
            return "Up";
        elseif webXRHeadYawDegree < 112.5 and webXRHeadYawDegree >= 67.5 then
            return "UpRight";
        elseif webXRHeadYawDegree < 67.5 and webXRHeadYawDegree >= 22.5 then
            return "D";
        end
	elseif rotation < -67.5 and rotation >= -112.5 then
        if webXRHeadYawDegree < 22.5 and webXRHeadYawDegree >= -22.5 then -- default down.
            return "Down";
        elseif webXRHeadYawDegree < -22.5 and webXRHeadYawDegree >= -67.5 then
            return "DownLeft";
        elseif webXRHeadYawDegree < -67.5 and webXRHeadYawDegree >=  -112.5 then
            return "A";
        elseif webXRHeadYawDegree < -112.5 and webXRHeadYawDegree >= -157.5 then
            return "UpLeft";
        elseif webXRHeadYawDegree < -157.5 or webXRHeadYawDegree >= 157.5 then
            return "Up";
        elseif webXRHeadYawDegree < 157.5 and webXRHeadYawDegree >= 112.5 then
            return "UpRight";
        elseif webXRHeadYawDegree < 112.5 and webXRHeadYawDegree >= 67.5 then
            return "D";
        elseif webXRHeadYawDegree < 67.5 and webXRHeadYawDegree >= 22.5 then
            return "DownRight";
        end
	elseif rotation < -112.5 and rotation >= -157.5 then
        if webXRHeadYawDegree < 22.5 and webXRHeadYawDegree >= -22.5 then -- default down left.
            return "DownLeft";
        elseif webXRHeadYawDegree < -22.5 and webXRHeadYawDegree >= -67.5 then
            return "A";
        elseif webXRHeadYawDegree < -67.5 and webXRHeadYawDegree >=  -112.5 then
            return "UpLeft";
        elseif webXRHeadYawDegree < -112.5 and webXRHeadYawDegree >= -157.5 then
            return "Up";
        elseif webXRHeadYawDegree < -157.5 or webXRHeadYawDegree >= 157.5 then
            return "UpRight";
        elseif webXRHeadYawDegree < 157.5 and webXRHeadYawDegree >= 112.5 then
            return "D";
        elseif webXRHeadYawDegree < 112.5 and webXRHeadYawDegree >= 67.5 then
            return "DownRight";
        elseif webXRHeadYawDegree < 67.5 and webXRHeadYawDegree >= 22.5 then
            return "Down";
        end
	elseif rotation < -157.5 or rotation >= 157.5 then
        if (self.lockCameraYaw) then
            if webXRHeadYawDegree < 22.5 and webXRHeadYawDegree >= -22.5 then
                return "A";
            elseif webXRHeadYawDegree < -22.5 and webXRHeadYawDegree >= -67.5 then
                return "UpLeft";
            elseif webXRHeadYawDegree < -67.5 and webXRHeadYawDegree >=  -112.5 then
                return "Up";
            elseif webXRHeadYawDegree < -112.5 and webXRHeadYawDegree >= -157.5 then
                return "UpRight";
            elseif webXRHeadYawDegree < -157.5 or webXRHeadYawDegree >= 157.5 then
                return "D";
            elseif webXRHeadYawDegree < 157.5 and webXRHeadYawDegree >= 112.5 then
                return "DownRight";
            elseif webXRHeadYawDegree < 112.5 and webXRHeadYawDegree >= 67.5 then
                return "Down";
            elseif webXRHeadYawDegree < 67.5 and webXRHeadYawDegree >= 22.5 then
                return "DownLeft";
            end
        else
            return "Left";
        end
	elseif rotation < 157.5 and rotation >= 112.5 then
        if webXRHeadYawDegree < 22.5 and webXRHeadYawDegree >= -22.5 then -- default up left;
            return "UpLeft";
        elseif webXRHeadYawDegree < -22.5 and webXRHeadYawDegree >= -67.5 then
            return "Up";
        elseif webXRHeadYawDegree < -67.5 and webXRHeadYawDegree >=  -112.5 then
            return "UpRight";
        elseif webXRHeadYawDegree < -112.5 and webXRHeadYawDegree >= -157.5 then
            return "D";
        elseif webXRHeadYawDegree < -157.5 or webXRHeadYawDegree >= 157.5 then
            return "DownRight";
        elseif webXRHeadYawDegree < 157.5 and webXRHeadYawDegree >= 112.5 then
            return "Down";
        elseif webXRHeadYawDegree < 112.5 and webXRHeadYawDegree >= 67.5 then
            return "DownLeft";
        elseif webXRHeadYawDegree < 67.5 and webXRHeadYawDegree >= 22.5 then
            return "A";
        end
	elseif rotation < 112.5 and rotation >= 67.5 then
        if webXRHeadYawDegree < 22.5 and webXRHeadYawDegree >= -22.5 then -- default up.
            return "Up"
        elseif webXRHeadYawDegree < -22.5 and webXRHeadYawDegree >= -67.5 then
            return "UpRight"
        elseif webXRHeadYawDegree < -67.5 and webXRHeadYawDegree >=  -112.5 then
            return "D";
        elseif webXRHeadYawDegree < -112.5 and webXRHeadYawDegree >= -157.5 then
            return "DownRight";
        elseif webXRHeadYawDegree < -157.5 or webXRHeadYawDegree >= 157.5 then
            return "Down";
        elseif webXRHeadYawDegree < 157.5 and webXRHeadYawDegree >= 112.5 then
            return "DownLeft";
        elseif webXRHeadYawDegree < 112.5 and webXRHeadYawDegree >= 67.5 then
            return "A";
        elseif webXRHeadYawDegree < 67.5 and webXRHeadYawDegree >= 22.5 then
            return "UpLeft";
        end
	elseif rotation < 67.5 and rotation >= 22.5 then
        if webXRHeadYawDegree < 22.5 and webXRHeadYawDegree >= -22.5 then -- default up right.
            return "UpRight";
        elseif webXRHeadYawDegree < -22.5 and webXRHeadYawDegree >= -67.5 then
            return "D";
        elseif webXRHeadYawDegree < -67.5 and webXRHeadYawDegree >=  -112.5 then
            return "DownRight";
        elseif webXRHeadYawDegree < -112.5 and webXRHeadYawDegree >= -157.5 then
            return "Down";
        elseif webXRHeadYawDegree < -157.5 or webXRHeadYawDegree >= 157.5 then
            return "DownLeft";
        elseif webXRHeadYawDegree < 157.5 and webXRHeadYawDegree >= 112.5 then
            return "A";
        elseif webXRHeadYawDegree < 112.5 and webXRHeadYawDegree >= 67.5 then
            return "UpLeft";
        elseif webXRHeadYawDegree < 67.5 and webXRHeadYawDegree >= 22.5 then
            return "Up";
        end
	end
end

function WebXRCamera:ShowVirtualKeyboard(showFlag)
    if (not self.keyboard) then
        NPL.load("(gl)script/apps/Aries/Creator/Game/GUI/TouchVirtualKeyboard.lua");
        local TouchVirtualKeyboard = commonlib.gettable("MyCompany.Aries.Game.GUI.TouchVirtualKeyboard");
        local Screen = commonlib.gettable('System.Windows.Screen');
        local screenWidth = Screen:GetWidth();
        local screenHeight = Screen:GetHeight();
        local keyboardWidth = 900;
    
        local left, top = (screenWidth - keyboardWidth) / 2, screenHeight - 400;

        self.keyboard = TouchVirtualKeyboard:new():Init("TouchVirtualKeyboard", left, top, keyboardWidth);
        self.keyboard:SetTransparency(0.5);
        self.keyboard:Connect("hidden", self, function()
            
        end);
        self.keyboard:GetUIControl().visible = false;
    end

    if (showFlag) then
        self.keyboard:Show(true);
    else
        self.keyboard:Show(false);
        self.keyboard:Destroy();
        self.keyboard = nil;
    end
end

function WebXRCamera:ReadAllDeviceKeysToBuffer()
    self.deviceLeftHandKeyDown[0] = self.webXR:GetField("leftHandKey0", false);
    self.deviceLeftHandKeyDown[1] = self.webXR:GetField("leftHandKey1", false);
    self.deviceLeftHandKeyDown[2] = self.webXR:GetField("leftHandKey2", false);
    self.deviceLeftHandKeyDown[3] = self.webXR:GetField("leftHandKey3", false);
    self.deviceLeftHandKeyDown[4] = self.webXR:GetField("leftHandKey4", false);
    self.deviceLeftHandKeyDown[5] = self.webXR:GetField("leftHandKey5", false);
    self.deviceLeftHandKeyDown[6] = self.webXR:GetField("leftHandKey6", false);

    self.deviceRightHandKeyDown[0] = self.webXR:GetField("rightHandKey0", false);
    self.deviceRightHandKeyDown[1] = self.webXR:GetField("rightHandKey1", false);
    self.deviceRightHandKeyDown[2] = self.webXR:GetField("rightHandKey2", false);
    self.deviceRightHandKeyDown[3] = self.webXR:GetField("rightHandKey3", false);
    self.deviceRightHandKeyDown[4] = self.webXR:GetField("rightHandKey4", false);
    self.deviceRightHandKeyDown[5] = self.webXR:GetField("rightHandKey5", false);
    self.deviceRightHandKeyDown[6] = self.webXR:GetField("rightHandKey6", false);
end

function WebXRCamera:ReadAllDeviceKeysToBufferEmulate()
    self.deviceLeftHandKeyDown[0] = self.leftHandKey0Emulate;
    self.deviceLeftHandKeyDown[1] = self.leftHandKey1Emulate;
    self.deviceLeftHandKeyDown[2] = self.leftHandKey2Emulate;
    self.deviceLeftHandKeyDown[3] = self.leftHandKey3Emulate;
    self.deviceLeftHandKeyDown[4] = self.leftHandKey4Emulate;
    self.deviceLeftHandKeyDown[5] = self.leftHandKey5Emulate;
    self.deviceLeftHandKeyDown[6] = self.leftHandKey6Emulate;

    self.deviceRightHandKeyDown[0] = self.rightHandKey0Emulate;
    self.deviceRightHandKeyDown[1] = self.rightHandKey1Emulate;
    self.deviceRightHandKeyDown[2] = self.rightHandKey2Emulate;
    self.deviceRightHandKeyDown[3] = self.rightHandKey3Emulate;
    self.deviceRightHandKeyDown[4] = self.rightHandKey4Emulate;
    self.deviceRightHandKeyDown[5] = self.rightHandKey5Emulate;
    self.deviceRightHandKeyDown[6] = self.rightHandKey6Emulate;
end

function WebXRCamera:IsPressLeftKey(index)
    if (self.deviceLeftHandKeyDown[index]) then
        return true;
    else
        return false;
    end
end

function WebXRCamera:IsPressRightKey(index)
    if (self.deviceRightHandKeyDown[index]) then
        return true;
    else
        return false;
    end
end

function WebXRCamera:FrameMoveCameraControl()
    self:OnFrameMove();
end

function WebXRCamera:IsDragging()
end

function WebXRCamera:OnFrameMove()
    if (System.os.GetPlatform() == "win32" or System.os.GetPlatform() == "mac") then
        self:UpdateFromEmulate();
    else
        self:UpdateFromDevice();
    end
end

function WebXRCamera:GetViewProjMatrix()
    return ParaCamera.GetAttributeObject():GetField("ViewProjMatrix", self.viewprojMatrix);
end

function WebXRCamera:GetViewMatrix()
    return ParaCamera.GetAttributeObject():GetField("ViewMatrix", self.viewMatrix);
end

function WebXRCamera:GetProjMatrix()
    return ParaCamera.GetAttributeObject():GetField("ProjMatrix", self.projMatrix);
end

function WebXRCamera:GetEyePosition()
    return ParaCamera.GetAttributeObject():GetField("Eye position", self.eye_pos1);
end

function WebXRCamera:GetRenderOrigin()
    local eye_pos = self:GetEyePosition();

	self.renderOrigin[1] = mathlib.FloatToInt(mathlib.DoubleToFloat(eye_pos[1]));
	self.renderOrigin[2] = mathlib.FloatToInt(mathlib.DoubleToFloat(eye_pos[2]));
	self.renderOrigin[3] = mathlib.FloatToInt(mathlib.DoubleToFloat(eye_pos[3]));
	return self.renderOrigin;
	--return ParaCamera.GetAttributeObject():GetField("RenderOrigin", self.renderOrigin);
end

-- function WebXRCamera:GetFieldOfView()
--     return self.fieldOfView;
-- end

function WebXRCamera:GetFieldOfView()
	return ParaCamera.GetAttributeObject():GetField("FieldOfView", self.fieldOfView);
end

function WebXRCamera:GetNearPlane()
	return ParaCamera.GetAttributeObject():GetField("NearPlane", 1);
end

function WebXRCamera:GetFarPlane()
	return ParaCamera.GetAttributeObject():GetField("FarPlane", 100);
end

function WebXRCamera:GetAspectRatio()
	return ParaCamera.GetAttributeObject():GetField("AspectRatio", 1);
end

function WebXRCamera:ToggleFly(bFly)
    NPL.load("(gl)script/apps/Aries/Creator/Game/GameRules/GameMode.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
    NPL.load("(gl)script/apps/Aries/Creator/Game/World/WebXRCamera.lua");
    local GameMode = commonlib.gettable("MyCompany.Aries.Game.GameLogic.GameMode");
    local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
    local WebXRCamera = commonlib.gettable("MyCompany.Aries.Game.WebXRCamera");

    if (GameMode:CanFly()) then
        GameLogic.GetPlayerController().force_can_fly = true;
		local entity = EntityManager.GetFocus();

        if (entity) then
            if (entity.disable_toggle_fly) then
                return;
            end

            if (entity:ToggleFly()) then
                GameLogic.picking_dist = GameLogic.options.picking_dist_flymode;
                WebXRCamera.ToggleFly(true);
            else
                GameLogic.picking_dist = GameLogic.options.picking_disk_walkmode;
                WebXRCamera.ToggleFly(false);
            end
        end
    end
end

function WebXRCamera:CalculateRayLength(nIndex)
    if (nIndex == 1) then
        -- LEFT HAND
        local rayLength = self.defaultRayLength;
        if (self.leftHandPos and self.leftHandPos[1]) then
            -- use the closer of scene and 3d ui picking
            local dist, result = SelectionManager:RayPicking(
                self.leftHandPos[1], self.leftHandPos[2], self.leftHandPos[3],
                self.leftHandDir[1], self.leftHandDir[2], self.leftHandDir[3],
                self.defaultMaxRayLength);

            rayLength = dist or rayLength;

            if (ParaUI.Pick) then
                local params = {
                    rayX = self.leftHandPos[1], rayY = self.leftHandPos[2], rayZ = self.leftHandPos[3],
                    dirX = self.leftHandDir[1], dirY = self.leftHandDir[2], dirZ = self.leftHandDir[3], 
                    maxDistance = 99999,
                    filterFunc = "",
                    hitDist = nil
                };
                local uiObj = ParaUI.Pick(params);
                if (uiObj and uiObj:IsValid()) then
                    rayLength = params.hitDist;
                end
            end
        end

        self.leftHandRayLength = rayLength;
    else
        -- RIGHT HAND
        local rayLength = self.defaultRayLength;
        if (self.rightHandPos and self.rightHandPos[1]) then
            -- use the closer of scene and 3d ui picking.
            local dist, result = SelectionManager:RayPicking(
                self.rightHandPos[1], self.rightHandPos[2], self.rightHandPos[3],
                self.rightHandDir[1], self.rightHandDir[2], self.rightHandDir[3],
                self.defaultMaxRayLength);

            rayLength = dist or rayLength;

            if (ParaUI.Pick) then
                local params = {
                    rayX = self.rightHandPos[1], rayY = self.rightHandPos[2], rayZ = self.rightHandPos[3],
                    dirX = self.rightHandDir[1], dirY = self.rightHandDir[2], dirZ = self.rightHandDir[3],
                    maxDistance = 99999,
                    filterFuc = "",
                    hitDist = nil
                };
                local uiObj = ParaUI.Pick(params);
                if (uiObj and uiObj:IsValid()) then
                    rayLength = params.hitDist;
                end
            end
        end

        self.rightHandRayLength = rayLength;
    end
end

function WebXRCamera:SetBrushColor(nIndex, painter)
    painter:SetPen(self.pen);

    if (nIndex == 1) then
        -- LEFT HAND
        local leftHandDistance = 0;
        local leftHandDegrees = 0;

        if (self.lastWebXRLeftHandPosition and self.webXRLeftHandPosition) then
            leftHandDistance = (self.lastWebXRLeftHandPosition - self.webXRLeftHandPosition):length();
        end

        if (self.lastWebXRLeftHandOrientation and self.webXRLeftHandOrientation) then
            local q1 = self.lastWebXRLeftHandOrientation;
            local q2 = self.webXRLeftHandOrientation;

            local dotProduct = q1[1] * q2[1] + q1[2] * q2[2] + q1[3] * q2[3] + q1[4] * q2[4];
            dotProduct = math.min(math.max(dotProduct, -1), 1);

            local angleDifference = 2 * math.acos(dotProduct);
            leftHandDegrees = angleDifference * (180 / math.pi);
        end

        if (self.autoHideHandsWhenStill and leftHandDistance < 0.01 and leftHandDegrees < 0.1) then
            if (not self.leftStopTime or self.leftStopTime == 0) then
                self.leftStopTime = os.time();
            end

            if (math.abs(self.leftStopTime - os.time()) >= 15) then
                painter:SetBrush("#ff000000");
            else
                painter:SetBrush("#ff0000");
            end
        else
            painter:SetBrush("#ff0000");
            self.leftStopTime = 0;
        end
    else
        -- RIGHT HAND
        local rightHandDistance = 0;
        local rightHandDegrees = 0;

        if (self.lastWebXRRightHandPosition and self.webXRRightHandPosition) then
            rightHandDistance = (self.lastWebXRRightHandPosition - self.webXRRightHandPosition):length();
        end

        if (self.lastWebXRRightHandOrientation and self.webXRRightHandOrientation) then
            local q1 = self.lastWebXRRightHandOrientation;
            local q2 = self.webXRRightHandOrientation;

            local dotProduct = q1[1] * q2[1] + q1[2] * q2[2] + q1[3] * q2[3] + q1[4] * q2[4];
            dotProduct = math.min(math.max(dotProduct, -1), 1);

            local angleDifference = 2 * math.acos(dotProduct);
            rightHandDegrees = angleDifference * (180 / math.pi);
        end

        if (self.autoHideHandsWhenStill and rightHandDistance < 0.01 and rightHandDegrees < 0.1) then
            if (not self.rightStopTime or self.rightStopTime == 0) then
                self.rightStopTime = os.time();
            end

            if (math.abs(self.rightStopTime - os.time()) >= 15) then
                painter:SetBrush("#0000ff00");
            else
                painter:SetBrush("#0000ff");
            end
        else
            painter:SetBrush("#0000ff");
            self.rightStopTime = 0;
        end
    end
end

-- pretty slow, get it and cache it. return mouse ray in current scene viewport
-- @param mouse_x, mouse_y: if nil, default to current mouse position. 
-- @param matWorld: if nil, it will simply return the ray in view space. 
-- @return ShapeRay
function WebXRCamera:GetMouseRay(mouse_x, mouse_y, matWorld)
    if (not mouse_x or not mouse_y) then
        mouse_x, mouse_y = Mouse:GetMousePosition();
    end

    local matProj = self:GetProjMatrix();
    local viewport = ViewportManager:GetSceneViewport();
    local viewportUI = ViewportManager:GetGUIViewport();

    -- assume that scene viewport is always relative to UI viewport. 
    mouse_x = mouse_x - ((viewport:GetLeft() - viewportUI:GetLeft()) / Screen:GetUIScaling()[1]);
    mouse_y = mouse_y - ((viewport:GetTop() - viewportUI:GetTop()) / Screen:GetUIScaling()[2]);
    local screenWidth = Screen:GetWidth() - ((viewport:GetMarginRight() - viewportUI:GetMarginRight() + viewport:GetLeft() - viewportUI:GetLeft()) / Screen:GetUIScaling()[1]);
    local screenHeight = Screen:GetHeight() - ((viewport:GetMarginBottom() - viewportUI:GetMarginBottom() + viewport:GetTop() - viewportUI:GetTop()) / Screen:GetUIScaling()[2]);

    -- Compute the vector of the pick ray in screen space
    local v = {
    	 ( ( ( 2.0 * mouse_x ) / screenWidth  ) - 1 ) / matProj[1],
    	-( ( ( 2.0 * mouse_y ) / screenHeight ) - 1 ) / matProj[6],
    	 1.0
    };

    if (matWorld) then
        -- Get the inverse of the composite view and world matrix
        local m;
        local matView = self:GetViewMatrix();
        m = matWorld * matView;
        m = m:inverse();
        local vPickRayDir = vector3d:new({
            v[1] * m[1] + v[2] * m[5] + v[3] * m[9],
            v[1] * m[2] + v[2] * m[6] + v[3] * m[10],
            v[1] * m[3] + v[2] * m[7] + v[3] * m[11]
        });
        vPickRayDir:normalize();
        local vPickRayOrig = vector3d:new({m[13], m[14], m[15]});

        return ShapeRay:new():init(vPickRayOrig, vPickRayDir);
    else
        return ShapeRay:new():init(vector3d.zero, v);
    end
end

function WebXRCamera:LockCamera(is_lock)
	self.is_lock_camera = is_lock

    local att = ParaCamera.GetAttributeObject();
	
	if is_lock then
		if self.lock_temp_data == nil then
			self.lock_temp_data = {}
			self.lock_temp_data.enable_mouse_wheel = att:GetField("EnableMouseWheel");
			self.lock_temp_data.enable_mouse_right_drag = att:GetField("EnableMouseRightDrag");
			self.lock_temp_data.enable_mouse_left_drag = att:GetField("EnableMouseLeftDrag");
		end

		att:SetField("EnableMouseWheel", false);
		att:SetField("EnableMouseRightDrag", false);
		att:SetField("EnableMouseLeftDrag", false);
	else
		local temp_data = self.lock_temp_data or {}
		att:SetField("EnableMouseWheel", temp_data.enable_mouse_wheel or false);
		att:SetField("EnableMouseRightDrag", temp_data.enable_mouse_right_drag or true);
		att:SetField("EnableMouseLeftDrag", temp_data.enable_mouse_left_drag or true);

		self.lock_temp_data = nil
	end
end

WebXRCamera:InitSingleton();
