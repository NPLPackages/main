--[[
Title: Mouse
Author(s): LiXizhi
Date: 2015/4/23
Desc: Singleton object
The Mouse class provides mouse related events, methods and, properties which provide information regarding the state of the mouse.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Mouse.lua");
local Mouse = commonlib.gettable("System.Windows.Mouse");
Mouse:Capture(uiElement);
Mouse:SetCursorFromFile(filename, offsetX, offsetY)

-- for WebXR emulation, we can send virtual mouse events.
Mouse:SendMouseButtonEvent(500, 500, "left", "down")
Mouse:SendMouseMoveEvent(500, 500)
Mouse:SendMouseButtonEvent(500, 500, "left", "up")
Mouse:SendMouseWheelEvent(120)
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/math/Point.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Screen = commonlib.gettable("System.Windows.Screen");
local Point = commonlib.gettable("mathlib.Point");

local Mouse = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Windows.Mouse"));
Mouse:Property("Name", "Mouse");

function Mouse:ctor()
end

-- Gets the element that has captured the mouse. 
function Mouse:GetCapture()
	return self.capturedElement;
end

-- When an element captures the mouse, it receives mouse input whether or not the cursor is within its borders.
-- To release mouse capture, call Capture passing nil as the element to capture.
-- @param element: if nil, it means release mouse capture. 
function Mouse:Capture(element)
	self.capturedElement = element;
end

-- Gets the state of the left button of the mouse. true if pressed. 
function Mouse:LeftButton()
	return ParaUI.IsMousePressed(0);
end

-- Gets the state of the right button of the mouse. true if pressed. 
function Mouse:RightButton()
	return ParaUI.IsMousePressed(1);
end

-- Gets the element the mouse pointer is directly over.
function Mouse:DirectlyOver()
	-- TODO:	
end

-- get Point object. 
function Mouse:pos()
	-- global pos of the mouse
	return Point:new_from_pool(ParaUI.GetMousePosition());
end

-- return x, y in GUI screen coordinate
function Mouse:GetMousePosition()
	return ParaUI.GetMousePosition()
end

-- return true if left/right mouse button should be swapped. 
function Mouse:IsMouseButtonSwapped()
	return Screen:GetGUIRoot():GetField("MouseButtonSwapped", false);
end

-- set if left/right mouse button should be swapped. 
function Mouse:SetMouseButtonSwapped(bSwapped)
	Screen:GetGUIRoot():SetField("MouseButtonSwapped", bSwapped==true);
end

-- if false, the left touch is left mouse button.
function Mouse:IsTouchButtonSwapped()
	return Screen:GetGUIRoot():GetField("TouchButtonSwapped", false);
end

-- if false, the left touch is left mouse button.
function Mouse:SetTouchButtonSwapped(bSwapped)
	Screen:GetGUIRoot():SetField("TouchButtonSwapped", bSwapped==true);
end

-- set root cursor file
-- @param filename: this needs to be a tga file 
-- @param offsetX, offsetY: default to 0, 0
function Mouse:SetCursorFromFile(filename, offsetX, offsetY)
	offsetX, offsetY = offsetX or 0, offsetY or 0
	local root_ = ParaUI.GetUIObject("root");
	if(root_.SetCursor) then
		ParaUI.SetCursorFromFile(filename, offsetX, offsetY)
		root_:SetCursor(filename, offsetX, offsetY);
	else
		root_.cursor = filename;
	end
end

function Mouse:SetMousePosition(x, y)
	ParaUI.SetMousePosition(x, y);
end

-- sending virtual mouse events
-- @param button: "left", "right", "middle"
-- @param button_state: "down", "up" or "press" "release"
function Mouse:SendMouseButtonEvent(x, y, button, button_state)
	if(button == "left") then
		button = 0;
	elseif(button == "right") then
		button = 1;
	elseif(button == "middle") then
		button = 2;
	end
	if(button_state == "down" or button_state == "press") then
		button_state = 0;
	elseif(button_state == "up" or button_state == "release") then
		button_state = 1;
	end
	if(not x or not y) then
		x, y = self:GetMousePosition();
	end
	Screen:GetGUIRoot():SetField("SendMouseButtonEvent", {x, y, button or 0, button_state or 0});
end
function Mouse:SendMouseMoveEvent(x, y)
	Screen:GetGUIRoot():SetField("SendMouseMoveEvent", {x, y});
end
function Mouse:SendMouseWheelEvent(delta)
	Screen:GetGUIRoot():SetField("SendMouseWheelEvent", delta);
end

-- this is a singleton class
Mouse:InitSingleton();