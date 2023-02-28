--[[
Title: Event
Author(s): wxa
Date: 2020/6/30
Desc: Event
use the lib:
-------------------------------------------------------
local Event = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Event/Event.lua");
-------------------------------------------------------
]]

local BaseEvent = NPL.load("./BaseEvent.lua", IsDevEnv);
local InputMethodEvent = NPL.load("./InputMethodEvent.lua", IsDevEnv);
local KeyEvent = NPL.load("./KeyEvent.lua", IsDevEnv);
local MouseEvent = NPL.load("./MouseEvent.lua", IsDevEnv);
local ActivateEvent = NPL.load("./ActivateEvent.lua", IsDevEnv);

local Event = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());


Event.BaseEvent = BaseEvent;
Event.InputMethodEvent = InputMethodEvent;
Event.KeyEvent = KeyEvent;
Event.MouseEvent = MouseEvent;
Event.ActivateEvent = ActivateEvent;

function Event:ctor()
    self.BaseEvent = BaseEvent:new();
    self.InputMethodEvent = InputMethodEvent:new();
    self.KeyEvent = KeyEvent:new();
    self.MouseEvent = MouseEvent:new();
end

function Event:Init(event_type, window, event_args)
	local event = nil;
	if (event_type == "onmousedown" or event_type == "onmouseup" or event_type == "onmousemove" or event_type == "onmousewheel" or event_type == "onmouseleave" or event_type == "onmouseenter") then
		event = self.MouseEvent:Init(event_type, window, event_args);
	elseif (event_type == "onkeydown" or event_type == "onkeyup") then 
		event = self.KeyEvent:Init(event_type, window, event_args);
	elseif (event_type == "oninputmethod") then
		event = self.InputMethodEvent:Init(event_type, window, event_args or msg);
	elseif (event_type == "onactivate") then
		event = self.ActivateEvent:Init(event_type, window, if_else(event_args == nil, param1 and param1 > 0, event_args));
	elseif (event_type == "onfocusin" or event_type == "onfocusout") then
		event = self.ActivateEvent:Init(event_type, window, if_else(event_args == nil, event_type == "onfocusin", event_args));
	else
		event = self.BaseEvent:Init(event_type, window);
	end 

	return event;
end

