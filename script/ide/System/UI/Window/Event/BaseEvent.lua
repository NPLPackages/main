--[[
Title: BaseEvent
Author(s): wxa
Date: 2020/6/30
Desc: Event
use the lib:
-------------------------------------------------------
local BaseEvent = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Event/BaseEvent.lua");
-------------------------------------------------------
]]

local BaseEvent = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

BaseEvent:Property("Window");    -- 事件窗口
BaseEvent:Property("Element");   -- 事件元素
BaseEvent:Property("Version");

--[[
0 -- 默认版本
1 -- 修复blockly 滚动反向问题
]]
BaseEvent.Version = {
	BlocklyToolBoxMouseWheelBug = 1,
	CurrentVersion = 1,
}

function BaseEvent:Init(event_type, window, params)
    self.last_event_type = self.event_type;
    self.event_type = event_type;
    self.accepted = nil;

    self:SetElement(nil);
    self:SetWindow(window);
	window:SetEvent(self);

	if (type(params) == "table" and type(params.version) == "number") then
		self:SetVersion(params.version);
	else
		self:SetVersion(self.Version.CurrentVersion);
	end

    return self;
end

function BaseEvent:GetEventType()
	return self.event_type;
end

function BaseEvent:GetType(event_type) 
	event_type = event_type or self:GetEventType();

	if (event_type == "onmousedown") then return "mousePressEvent"
    elseif (event_type == "onmouseup") then return "mouseReleaseEvent"
    elseif (event_type == "onmousemove") then return "mouseMoveEvent"
    elseif (event_type == "onmousewheel") then return "mouseWheelEvent"
    elseif (event_type == "onmouseleave") then return "mouseLeaveEvent"
    elseif (event_type == "onmouseenter") then return "mouseEnterEvent"
    elseif (event_type == "onkeydown") then return "keyPressEvent"
    elseif (event_type == "onkeyup") then return "keyReleaseEvent"
    elseif (event_type == "oninputmethod") then return "inputMethodEvent"
	else return event_type
    end
end

function BaseEvent:GetLastType()
    return self:GetType(self.last_event_type);
end

function BaseEvent:Accept()
	self.accepted = true;
end

function BaseEvent:Ignore()
	if(self.accepted == nil) then
		self.accepted = false;
	end
end

function BaseEvent:IsAccepted() 
	return self.accepted;
end

