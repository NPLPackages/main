--[[
Title: Keyboard
Author(s): LiXizhi
Date: 2015/9/3
Desc: Singleton object
The Keyboard class provides Keyboard related events, methods and, properties which provide information regarding the state of the Keyboard.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Screen = commonlib.gettable("System.Windows.Screen");

local Keyboard = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Windows.Keyboard"));
Keyboard:Property("Name", "Keyboard");

Keyboard.emulatedKeys = {};
function Keyboard:ctor()
end

-- @return emulatedKeys: {alt_pressed=nil, ctrl_pressed, shift_pressed}
function Keyboard:GetEmulatedKeys()
	return Keyboard.emulatedKeys;
end

function Keyboard:IsAltKeyPressed()
	return Keyboard.emulatedKeys.alt_pressed or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU);
end

function Keyboard:IsCtrlKeyPressed()
	return Keyboard.emulatedKeys.ctrl_pressed or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
end

function Keyboard:IsShiftKeyPressed()
	return Keyboard.emulatedKeys.shift_pressed or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
end

-- send a simulated raw key event to paraengine. 
-- @param event_type: "keyDownEvent", "keyUpEvent"
-- @param vKey: virtual key like DIK_SPACE
function Keyboard:SendKeyEvent(event_type, vKey)
	if(event_type == "keyDownEvent") then
		Screen:GetGUIRoot():SetField("SendKeyDownEvent", vKey);
	elseif(event_type == "keyUpEvent") then
		Screen:GetGUIRoot():SetField("SendKeyUpEvent", vKey);
	end
end


-- whether to enable system IME for all edit box control. 
-- sometimes, we will prefer virtual keyboard in NPL, instead of system IME. 
function Keyboard:EnableIME(bEnabled)
	Screen:GetGUIRoot():SetField("EnableIME", bEnabled == true);
end

function Keyboard:attachWithIME(ctrlBottom, curText, SelStart, SelEnd)
	ctrlBottom = ctrlBottom or 0;

	local root = Screen:GetGUIRoot();
	root:SetField("CurEditString", curText or "");
	root:SetField("SelStart", SelStart or 0);
	root:SetField("SelEnd", SelEnd or 0);
	root:SetField("ControlBottom", ctrlBottom);
	root:SetField("IMEKeyboardState", true);
end

function Keyboard:detachWithIME(ctrlBottom)	
	if (System.os.CompareParaEngineVersion("1.3.1.0")) then
		local root = Screen:GetGUIRoot();
		root:SetField("ControlBottom", 0);
		root:SetField("IMEKeyboardState", false);
	else
		ctrlBottom = ctrlBottom or 0;
	
		local root = Screen:GetGUIRoot();
		root:SetField("ControlBottom", ctrlBottom);
		root:SetField("IMEKeyboardState", false);
	end
end

-- emulate the IME 
function Keyboard:SendInputMethodEvent(str)
	if(str) then
		Screen:GetGUIRoot():SetField("SendInputMethodEvent", str);
	end
end

-- whether any of the UI has key focus
function Keyboard:HasKeyFocus()
	return Screen:GetGUIRoot():GetField("HasKeyFocus", false);
end

-- return the ParaUIObject that is currently have key focus or nil. 
function Keyboard:GetKeyFocus()
	local id = Screen:GetGUIRoot():GetField("KeyFocusObjectId", -1);
	if(id >= 0 ) then
		return ParaUI.GetUIObject(id);
	end
end




-- this is a singleton class
Keyboard:InitSingleton();
