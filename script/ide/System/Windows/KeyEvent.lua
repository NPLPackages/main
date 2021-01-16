--[[
Title: KeyEvent
Author(s): LiXizhi
Date: 2015/4/21
Desc: KeyEvent is singleton object
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/KeyEvent.lua");
local KeyEvent = commonlib.gettable("System.Windows.KeyEvent");
local event = KeyEvent:init("keyPressedEvent");
echo({event.x, event.y, event.button});
echo(event:IsKeySequence("Undo");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Keyboard.lua");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local KeyEvent = commonlib.inherit(commonlib.gettable("System.Core.Event"), commonlib.gettable("System.Windows.KeyEvent"));

function KeyEvent:ctor()
end

-- return current mouse event object. 
-- @param event_type: "keyDownEvent", "keyPressedEvent", "keyReleaseEvent"
function KeyEvent:init(event_type, vKey)
	KeyEvent._super.init(self, event_type);
	-- global position. 
	self.virtual_key = vKey or virtual_key;
	-- key string.
	self.keyname = VirtualKeyToScaneCodeStr[virtual_key];
	self.shift_pressed = Keyboard:IsShiftKeyPressed();
	self.ctrl_pressed = Keyboard:IsCtrlKeyPressed();
	self.alt_pressed = Keyboard:IsAltKeyPressed();
	self.key_sequence = self:GetKeySequence();
	self.accepted = nil;
	self.recorded = nil;
	return self;
end

local ctrl_seq_map = {
	["DIK_Z"] = "Undo",
	["DIK_Y"] = "Redo",
	["DIK_A"] = "SelectAll",
	["DIK_C"] = "Copy",
	["DIK_V"] = "Paste",
	["DIK_X"] = "Cut",
	["DIK_F"] = "Search",
	["DIK_HOME"] = "MoveToStartOfWord",
	["DIK_END"] = "MoveToEndOfWord",
	["DIK_UP"] = "ScrollToPreviousLine",
	["DIK_DOWN"] = "ScrollToNextLine",
	["DIK_LEFT"] = "MoveToPreviousWord",
	["DIK_RIGHT"] = "MoveToNextWord",
}

local shift_seq_map = {
	["DIK_HOME"] = "SelectStartOfLine",
	["DIK_END"] = "SelectEndOfLine",
	["DIK_UP"] = "SelectToPreviousLine",
	["DIK_DOWN"] = "SelectToNextLine",
	["DIK_LEFT"] = "SelectPreviousChar",
	["DIK_RIGHT"] = "SelectNextChar",
	["DIK_DELETE"] = "Cut",
}

local ctrl_shift_seq_map = {
	["DIK_HOME"] = "SelectStartOfBlock",
	["DIK_END"] = "SelectEndOfBlock",
	["DIK_LEFT"] = "SelectPreviousWord",
	["DIK_RIGHT"] = "SelectNextWord",
}

local std_seq_map = {
	["DIK_HOME"] = "MoveToStartOfLine",
	["DIK_END"] = "MoveToEndOfLine",
	["DIK_UP"] = "MoveToPreviousLine",
	["DIK_DOWN"] = "MoveToNextLine",
	["DIK_LEFT"] = "MoveToPreviousChar",
	["DIK_RIGHT"] = "MoveToNextChar",
	["DIK_DELETE"] = "Delete",
}

local function_key_map = {
	["DIK_F1"] = true,
	["DIK_F2"] = true,
	["DIK_F3"] = true,
	["DIK_F4"] = true,
	["DIK_F5"] = true,
	["DIK_F6"] = true,
	["DIK_F7"] = true,
	["DIK_F8"] = true,
	["DIK_F9"] = true,
	["DIK_F10"] = true,
	["DIK_F11"] = true,
	["DIK_F12"] = true,
}

local CtrlShiftAlt_key_map = {
	["DIK_LSHIFT"] = true,
	["DIK_RSHIFT"] = true,
	["DIK_LCONTROL"] = true,
	["DIK_RCONTROL"] = true,
	["DIK_LMENU"] = true,
	["DIK_RMENU"] = true,
	-- also disable win key
	["DIK_WIN_LWINDOW"] = true,
	["DIK_WIN_RWINDOW"] = true,
}


-- win32 sequence map
function KeyEvent:GetKeySequence()
	if(self.ctrl_pressed and self.shift_pressed) then
		return ctrl_shift_seq_map[self.keyname];
	elseif(self.ctrl_pressed) then
		return ctrl_seq_map[self.keyname];
	elseif(self.shift_pressed) then
		return shift_seq_map[self.keyname];
	else
		return std_seq_map[self.keyname];
	end
end

-- @param keySequence: "Undo", "Redo", "SelectAll", "Copy", "Paste"
function KeyEvent:IsKeySequence(keySequence)
	return self.key_sequence == keySequence;
end

function KeyEvent:IsFunctionKey()
	return function_key_map[self.keyname];
end

function KeyEvent:IsShiftCtrlAltKey()
	return CtrlShiftAlt_key_map[self.keyname]
end

function KeyEvent:KeyName()
	return self.keyname;
end



