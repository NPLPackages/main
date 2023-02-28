--[[
Title: ActivateEvent
Author(s): wxa
Date: 2020/6/30
Desc: Event
use the lib:
-------------------------------------------------------
local ActivateEvent = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Event/ActivateEvent.lua");
-------------------------------------------------------
]]

local BaseEvent = NPL.load("./BaseEvent.lua");

local ActivateEvent = commonlib.inherit(BaseEvent, NPL.export());

ActivateEvent:Property("Activate", false, "IsActivate");

function ActivateEvent:Init(event_type, window, bActivate)
    ActivateEvent._super.Init(self, event_type, window);

    self:SetActivate(bActivate);

	return self;
end

function ActivateEvent:IsActivateEvent()
    return true;
end
