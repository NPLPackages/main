--[[
Title: InputMethodEvent
Author(s): wxa
Date: 2020/6/30
Desc: Event
use the lib:
-------------------------------------------------------
local InputMethodEvent = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Event/InputMethodEvent.lua");
-------------------------------------------------------
]]

local BaseEvent = NPL.load("./BaseEvent.lua");

local InputMethodEvent = commonlib.inherit(BaseEvent, NPL.export());

InputMethodEvent:Property("CommitString");

function InputMethodEvent:Init(event_type, window, commitString)
    InputMethodEvent._super.Init(self, event_type, window);

    self:SetCommitString(commitString or msg);
    
	return self;
end

function InputMethodEvent:IsInputMethodEvent()
    return true;
end
