--[[
Title: ScrollArea
Author(s): LiXizhi
Date: 2015/4/29
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollArea.lua");
local ScrollArea = commonlib.gettable("System.Windows.Controls.ScrollArea");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
NPL.load("(gl)script/ide/math/Rect.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollBar.lua");
local ScrollBar = commonlib.gettable("System.Windows.Controls.ScrollBar");
local Rect = commonlib.gettable("mathlib.Rect");
local Application = commonlib.gettable("System.Windows.Application");

local ScrollArea = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.Controls.ScrollArea"));
ScrollArea:Property("Name", "ScrollArea");

--ScrollArea:Property({"horValue", nil, "HorizontalValue", "SetHorizontalValue", auto=true});
--ScrollArea:Property({"horValue", nil, auto=true});
--ScrollArea:Property({"verValue", nil, auto=true});
--ScrollArea:Property({"BackgroundColor", "#ffffff", auto=true});
--ScrollArea:Property({"Background", nil, auto=true});

function ScrollArea:ctor()
		self.hbar = nil;
	self.vbar = nil;
--	self.hscroll = 500;
--	self.vscroll = 500;
	self.hscroll = 0;
	self.vscroll = 0;

	self.viewport = nil;
	self.needUpdate = true;
end

function ScrollArea:init(parent)
	ScrollArea._super.init(self, parent);

--	self.hbar = ScrollBar:hbarBar(self);
--	self.hbar:Connect("scroll", function(event)
--		self.horValue = self.hbar:GetValue();
--	end);
--	self.hbar:hide();
--
--	self.vbar = ScrollBar:vbarBar(self);
--	self.vbar:Connect("scroll", function(event)
--		self.verValue = self.vbar:GetValue();
--	end);
--	self.vbar:hide();
--
--	self.viewport = nil;

	return self;
end

--function ScrollArea:viewport()
--	return self.viewport;
--end

--function ScrollArea:viewport()
--	if(self.viewport) then
--		self.viewport:Destroy();
--	end
--end

-- virtual:this is called when the scroll bars are moved by x,y, and consequently the viewport's contents should be scrolled accordingly
function ScrollArea:scrollContentsBy(x,y)
	
end

function ScrollArea:hslide(value)
	
end

function ScrollArea:vslide(value)
	
end

function ScrollArea:mousePressEvent(e)
	e:ignore();
end


function ScrollArea:mouseReleaseEvent(e)
	e:ignore();
end


function ScrollArea:mouseMoveEvent(e)
	e:ignore();
end


function ScrollArea:mouseWheelEvent(e)
	Application:sendEvent(self.vbar, e);
end

function ScrollArea:keyPressEvent(e)
	e:ignore();
end

function ScrollArea:paintEvent(painter)
--	local background = self:GetBackground();
--	local x, y = self:x(), self:y();
--	if(background and background~="") then
--		painter:SetPen(self:GetBackgroundColor());
--		painter:DrawRectTexture(x, y, self:width(), self:height(), self:GetBackground());
--	end
end

