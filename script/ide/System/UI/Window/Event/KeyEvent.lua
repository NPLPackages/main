--[[
Title: KeyEvent
Author(s): wxa
Date: 2020/6/30
Desc: Event
use the lib:
-------------------------------------------------------
local MouseEvent = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Event/MouseEvent.lua");
-------------------------------------------------------
]]

local BaseEvent = NPL.load("./BaseEvent.lua");

local KeyEvent = commonlib.inherit(BaseEvent, NPL.export());
-- KeyEvent:Property("CommitString");

-- return current mouse event object. 
-- @param event_type: "keyDownEvent", "keyPressedEvent", "keyReleaseEvent"
function KeyEvent:Init(event_type, window, params)
	KeyEvent._super.Init(self, event_type, window, params);

	self.virtual_key = virtual_key;   -- 全局变量
	self.keyname = VirtualKeyToScaneCodeStr[virtual_key];
	self.shift_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LSHIFT) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RSHIFT);
	self.ctrl_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LCONTROL) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RCONTROL);
	self.alt_pressed = ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_LMENU) or ParaUI.IsKeyPressed(DIK_SCANCODE.DIK_RMENU);
	self.key_sequence = self:GetKeySequence();

	if (type(params) == "table") then
		self.keyname, self.shift_pressed, self.alt_pressed, self.ctrl_pressed, self.key_sequence = params.keyname or self.keyname, params.shift_pressed or self.shift_pressed, params.alt_pressed or self.alt_pressed, params.ctrl_pressed or self.ctrl_pressed, params.key_sequence or self.key_sequence;
		-- self:SetCommitString(params.commit_string);
	end

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

function KeyEvent:IsKeyEvent()
	return true;
end
