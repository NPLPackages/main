--[[
Title: TextCursor
Author(s): LiXizhi
Date: 2015/4/29
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/TextCursor.lua");
local TextCursor = commonlib.gettable("System.Windows.Controls.TextCursor");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
local Application = commonlib.gettable("System.Windows.Application");
local TextCursor = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.Controls.TextCursor"));
TextCursor:Property("Name", "TextCursor");
TextCursor:Property({"Color", "#33333388", auto=true})
TextCursor:Property({"line", 1, "GetLine", "SetLine",  auto=true})
TextCursor:Property({"position", 0, "GetPosition", "SetPosition",  auto=true})
TextCursor:Property({"interval", 0, "GetInterval", "SetInterval",  auto=true})

TextCursor:Property({"Width", 2,})

--TextCursor:Property({"m_blinkPeriod", 0, "getCursorBlinkPeriod", "setCursorBlinkPeriod"})

function TextCursor:ctor()
	self.m_blinkStatus = true;

	self.m_blinkTimer = commonlib.Timer:new({callbackFunc = function(timer)
		self.m_blinkStatus = not self.m_blinkStatus;
		--self:updateNeeded(); -- signal
	end})

	self.interval = Application:cursorFlashTime();

	self.m_blinkTimer:Change(self.interval / 2, self.interval / 2);
    
end

function TextCursor:setStatus(value)
	self.m_blinkStatus = value;
end

function TextCursor:paintEvent(painter)
	--if(self.m_blinkPeriod==0 or self.m_blinkStatus) then
	if(self.m_blinkStatus) then
		painter:SetPen(self:GetColor());
		painter:DrawRect(self:x(), self:y(), self.Width or self:width(), self:height());
	end
end

