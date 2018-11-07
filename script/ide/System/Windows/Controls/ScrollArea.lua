--[[
Title: ScrollArea
Author(s): LiPeng
Date: 2017/10/3
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollArea.lua");
local ScrollArea = commonlib.gettable("System.Windows.Controls.ScrollArea");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/Primitives/ScrollAreaBase.lua");
NPL.load("(gl)script/ide/math/Rect.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollBar.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Canvas.lua");
local Canvas = commonlib.gettable("System.Windows.Controls.Canvas");
local ScrollBar = commonlib.gettable("System.Windows.Controls.ScrollBar");
local Rect = commonlib.gettable("mathlib.Rect");
local Application = commonlib.gettable("System.Windows.Application");

local ViewPort = commonlib.inherit(commonlib.gettable("System.Windows.Controls.Canvas"), commonlib.gettable("System.Windows.Controls.ViewPort"));
ViewPort:Property("Name", "ViewPort");

function ViewPort:ctor()
	self.clip = true;
end

-- clip region. 
function ViewPort:ClipRegion()
	local r = self.parent:ViewRegion();
	if(r) then
		r:setX(r:x() - self:x());
		r:setY(r:y() - self:y());
		return r;
	end
end

function ViewPort:hValue()
	local clip = self:ClipRegion();
	if(clip) then
		return clip:x();
	end
end

function ViewPort:vValue()
	local clip = self:ClipRegion();
	if(clip) then
		return clip:y();
	end
end

function ViewPort:updatePos(hscroll, vscroll)
	local x = -hscroll;
	local y = -vscroll;
	self:setX(x);
	self:setY(y);
end

function ViewPort:paintEvent(painter)
	local background = self:GetBackground();
	local x, y = self:x(), self:y();
	--if(background and background~="") then
		painter:SetPen(self:GetBackgroundColor());
		painter:DrawRectTexture(x, y, self:width(), self:height(), self:GetBackground());
	--end
end


local ScrollArea = commonlib.inherit(commonlib.gettable("System.Windows.Controls.Primitives.ScrollAreaBase"), commonlib.gettable("System.Windows.Controls.ScrollArea"));
ScrollArea:Property("Name", "ScrollArea");

function ScrollArea:ctor()

end

function ScrollArea:initViewport()
	self.viewport = ViewPort:new():init(self);
	self.viewport:Connect("SizeChanged", self, "updateScrollStatus");
--	self.viewport:Connect("PositionChanged", self, "updateScrollValue");
end

function ScrollArea:ViewPort()
	if(not self.viewport) then
--		local x = self.leftTextMargin;
--		local y = self.topTextMargin;
--		local w = self:width() - self.leftTextMargin;
--		local h = self:height() - self.topTextMargin;
		local x = 0;
		local y = 0;
		local w = self:width();
		local h = self:height();
		self.viewport = Rect:new():init(x, y, w, h);
	end
	return self.viewport;
end

function ScrollArea:contains(x,y)
	return self:rect():contains(x,y);
end

function ScrollArea:updateViewportPos()
	self.viewport:updatePos(self.hscroll, self.vscroll);
end

function ScrollArea:updateScrollInfo()
	local clip = self:ViewRegion();
	--if(not self.hbar:isHidden()) then
		self.hbar:setRange(0, self.viewport:width() - clip:width() - 1);
		self.hbar:setStep(clip:width()/10, clip:width());
		self.hbar:SetValue(self.viewport:hValue());
	--end

	--if(not self.vbar:isHidden()) then
		self.vbar:setRange(0, self.viewport:height() - clip:height() - 1);
		self.vbar:setStep(clip:height()/10, clip:height());
		self.vbar:SetValue(self.viewport:vValue());
	--end
end

function ScrollArea:updateScrollValue()
	if(not self.hbar:isHidden()) then
		self.hbar:SetValue(self.viewport:hValue());
	end

	if(not self.vbar:isHidden()) then
		self.vbar:SetValue(self.viewport:vValue());
	end
end

function ScrollArea:updateScrollStatus(textbox_w, textbox_h)
	local clip = self:ViewRegion();
	if(textbox_w > clip:width()) then
		--self.hbar:show();
		self:horizontalScrollBarShow();
	else
		--self.hbar:hide();
		self:horizontalScrollBarHide();
	end

	clip = self:ViewRegion();
	if(textbox_h > clip:height()) then
		--self.vbar:show();
		self:verticalScrollBarShow();
		clip = self:ViewRegion();
		if(textbox_w > clip:width()) then
			--self.hbar:show();
			self:horizontalScrollBarShow();
		else
			--self.hbar:hide();
			self:horizontalScrollBarHide();
		end
	else
		--self.vbar:hide();
		self:verticalScrollBarHide();
	end

	self:updateScrollInfo();
end

function ScrollArea:updateScrollGeometry()
	if(not self.hbar:isHidden()) then
		if(self.vbar:isHidden()) then
			self.hbar:setGeometry(0, self:height() - self.SliderSize, self:width(), self.SliderSize);
		else
			self.hbar:setGeometry(0, self:height() - self.SliderSize, self:width() - self.SliderSize, self.SliderSize);
		end
	end

	if(not self.vbar:isHidden()) then
		if(self.hbar:isHidden()) then
			self.vbar:setGeometry(self:width() - self.SliderSize, 0, self.SliderSize, self:height());
		else
			self.vbar:setGeometry(self:width() - self.SliderSize, 0, self.SliderSize, self:height() - self.SliderSize);
		end
	end
end

function ScrollArea:ApplyCss(css)
	if(self.viewport) then
		self.viewport:ApplyCss(css);
	end
end

function ScrollArea:paintEvent(painter)
	self:updateScrollGeometry();
--	painter:SetPen(self:GetBackgroundColor());
--	painter:DrawRectTexture(self:x(), self:y(), self:width(), self:height(), self:GetBackground());
end

