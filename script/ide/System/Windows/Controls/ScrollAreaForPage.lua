--[[
Title: ScrollAreaForPage
Author(s): LiPeng
Date: 2018/12/31
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/Primitives/ScrollAreaForPage.lua");
local ScrollAreaForPage = commonlib.gettable("System.Windows.Controls.ScrollAreaForPage");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
NPL.load("(gl)script/ide/math/Rect.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollBar.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Canvas.lua");
local Canvas = commonlib.gettable("System.Windows.Controls.Canvas");
local ScrollBar = commonlib.gettable("System.Windows.Controls.ScrollBar");
local Rect = commonlib.gettable("mathlib.Rect");
local Application = commonlib.gettable("System.Windows.Application");

local ScrollAreaForPage = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.Controls.ScrollAreaForPage"));
ScrollAreaForPage:Property("Name", "ScrollAreaForPage");

ScrollAreaForPage:Property({"AllowWheel", true, auto=true});

function ScrollAreaForPage:ctor()
	self.hbar = nil;
	self.vbar = nil;
end

--function ScrollAreaForPage:init(parent)
--	ScrollAreaForPage._super.init(self, parent);
--
--	self:initScrollBar();
--	self:initViewport();
--	return self;
--end

function ScrollAreaForPage:CreateScrollbar(direction)
	local scrollbar = ScrollBar:new():init(self);
	scrollbar:SetDirection(direction);
	if(direction == "horizontal") then
		self.hbar = scrollbar;
	end
	if(direction == "vertical") then
		self.vbar = scrollbar;
	end
	return scrollbar;
end

function ScrollAreaForPage:DestroyScrollbar(direction)
	--local scrollbar = if_else(direction == "horizontal", self.hbar, self.vbar);
	local scrollbar;
	if(direction == "horizontal") then
		scrollbar = self.hbar;
		self.hbar = nil;
	end
	if(direction == "vertical") then
		scrollbar = self.vbar;
		self.vbar = nil;
	end
	scrollbar:Destroy();
end

function ScrollAreaForPage:scrollToEnd()
	self.vbar:SetValue(self.vbar:GetMax(), true);
end

function ScrollAreaForPage:scrollToPos(hbarValue, vbarValue)
	hbarValue = hbarValue or self.hscroll;
	vbarValue = vbarValue or self.vscroll;
	self.hbar:SetValue(hbarValue, true);
	self.vbar:SetValue(vbarValue, true);
end

function ScrollAreaForPage:mousePressEvent(e)
	e:ignore();
end


function ScrollAreaForPage:mouseReleaseEvent(e)
	e:ignore();
end


function ScrollAreaForPage:mouseMoveEvent(e)
	e:ignore();
end


function ScrollAreaForPage:mouseWheelEvent(e)
	if(self.AllowWheel and self.vbar) then
		Application:sendEvent(self.vbar, e);
	end
end

function ScrollAreaForPage:keyPressEvent(e)
	e:ignore();
end

--function ScrollAreaForPage:ClipRegion()
--	return self:ViewRegion();
--end
--
---- clip region. 
--function ScrollAreaForPage:ViewRegion()
--	local w = self:width();
--	local h = self:height();
--	if(self.hbar) then
--		h = h - self.hbar:height();
--		--h = h - self.SliderSize;
--	end
--
--	if(self.vbar) then
--		w = w - self.vbar:width();
--		--w = w - self.SliderSize;
--	end
--	return Rect:new_from_pool(0, 0, w, h);
--end

function ScrollAreaForPage:paintEvent(painter)
	painter:SetPen(self:GetBackgroundColor());
	painter:DrawRectTexture(self:x(), self:y(), self:width(), self:height(), self:GetBackground());
end

