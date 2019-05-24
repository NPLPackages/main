--[[
Title: ScrollAreaBase
Author(s): LiPeng
Date: 2017/10/3
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/Primitives/ScrollAreaBase.lua");
local ScrollAreaBase = commonlib.gettable("System.Windows.Controls.Primitives.ScrollAreaBase");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/UIStyleElement.lua");
NPL.load("(gl)script/ide/math/Rect.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollBar.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Canvas.lua");
local Canvas = commonlib.gettable("System.Windows.Controls.Canvas");
local ScrollBar = commonlib.gettable("System.Windows.Controls.ScrollBar");
local Rect = commonlib.gettable("mathlib.Rect");
local Application = commonlib.gettable("System.Windows.Application");

local ScrollAreaBase = commonlib.inherit(commonlib.gettable("System.Windows.UIStyleElement"), commonlib.gettable("System.Windows.Controls.Primitives.ScrollAreaBase"));
ScrollAreaBase:Property("Name", "ScrollAreaBase");

ScrollAreaBase:Property({"SliderSize", 16, auto=true});
ScrollAreaBase:Property({"AllowWheel", true, auto=true});
-- the "scrollBarPolicy" values: "AlwaysOn", "AlwaysOff", "Auto"
ScrollAreaBase:Property({"horizontalScrollBarPolicy", "AlwaysOff", "getHorizontalScrollBarPolicy", "setHorizontalScrollBarPolicy", auto=true});
ScrollAreaBase:Property({"verticalScrollBarPolicy", "Auto", "getVerticalScrollBarPolicy", "setVerticalScrollBarPolicy", auto=true});

function ScrollAreaBase:ctor()

	self.hbar = nil;
	self.vbar = nil;
	self.hscroll = 0;
	self.vscroll = 0;

	self.viewport = nil;
	self.needUpdate = true;

	
	self.scrollbarGeometryDirty = true;
	self.scrollbarRangeDirty = true;
	self.scrollbarValueDirty = true;

	self.viewWidth = 0;
	self.viewHeight = 0;
end

function ScrollAreaBase:init(parent)
	ScrollAreaBase._super.init(self, parent);

	self:initScrollBar();
	self:initViewport();
	self:AddViewportEventListener();
	return self;
end

-- virtual function
function ScrollAreaBase:AddViewportEventListener()
	if(self.viewport) then
		self.viewport:Connect("SizeChanged", function (width, height)
			self.scrollbarGeometryDirty = true;
			self.scrollbarRangeDirty = true;
			self.viewWidth = width;
			self.viewHeight = height;
		end);
		self.viewport:Connect("PositionChanged", function()
			self.scrollbarValueDirty = true;
		end);
	end
end

-- virtual function
function ScrollAreaBase:initViewport()

end

function ScrollAreaBase:initScrollBar()
	--self.hbar = ScrollBar:hbarBar(self);
	self.hbar = ScrollBar:new():init(self);
	--self.hbar:
	self.hbar:Connect("valueChanged", function(value)
		self.hscroll = value;
		self:updateViewportPos();
	end);
	self.hbar:setRange(0,0,false);
	--self.hbar:hide();
	self:horizontalScrollBarHide();

	self.vbar = ScrollBar:new():init(self);
	self.vbar:SetDirection("vertical");
	self.vbar:Connect("valueChanged", function(value)
		self.vscroll = value;
		self:updateViewportPos();
	end);
	self.vbar:setRange(0,0,false);
	--self.vbar:hide();
	self:verticalScrollBarHide();
end

function ScrollAreaBase:scrollToEnd()
	self.vbar:SetValue(self.vbar:GetMax(), true);
end

function ScrollAreaBase:scrollToPos(hbarValue, vbarValue)
	hbarValue = hbarValue or self.hscroll;
	vbarValue = vbarValue or self.vscroll;
	self.hbar:SetValue(hbarValue, true);
	self.vbar:SetValue(vbarValue, true);
end

function ScrollAreaBase:horizontalScrollBarShow()
	self:setScrollBarVisible("horizontal", nil, true);
end

function ScrollAreaBase:horizontalScrollBarHide()
	self:setScrollBarVisible("horizontal", nil, false);
end

function ScrollAreaBase:verticalScrollBarShow()
	self:setScrollBarVisible("vertical", nil, true);
end

function ScrollAreaBase:verticalScrollBarHide()
	self:setScrollBarVisible("vertical", nil, false);
end

function ScrollAreaBase:setScrollBarVisible(direction, policy, visible)
	local scrollbar;
	if(direction == "horizontal") then
		scrollbar = self.hbar;
		if(not policy) then
			policy = self.horizontalScrollBarPolicy;
		end
	else
		scrollbar = self.vbar;
		if(not policy) then
			policy = self.verticalScrollBarPolicy;
		end
	end

	if(policy == "AlwaysOn") then
		visible = true;
	elseif(policy == "AlwaysOff") then
		visible = false;
	elseif(visible == nil) then
		return;
	end
	if(visible) then
		scrollbar:show();
	else
		scrollbar:hide();
	end
end

--the "policy" value can be: "AlwaysOn", "AlwaysOff", "Auto"
function ScrollAreaBase:setHorizontalScrollBarPolicy(policy)
	self.horizontalScrollBarPolicy = policy;
	if(policy == "AlwaysOn" or policy == "AlwaysOff") then
		self:setScrollBarVisible("horizontal", policy);
	end
end

--the "policy" value can be: "AlwaysOn", "AlwaysOff", "Auto"
function ScrollAreaBase:setVerticalScrollBarPolicy(policy)
	self.verticalScrollBarPolicy = policy;
	if(policy == "AlwaysOn" or policy == "AlwaysOff") then
		self:setScrollBarVisible("vertical", policy);
	end
end

function ScrollAreaBase:updateViewportPos()
	
end

--function ScrollAreaBase:viewport()
--	return self.viewport;
--end

--function ScrollAreaBase:viewport()
--	if(self.viewport) then
--		self.viewport:Destroy();
--	end
--end

-- virtual:this is called when the scroll bars are moved by x,y, and consequently the viewport's contents should be scrolled accordingly
function ScrollAreaBase:scrollContentsBy(x,y)
	
end

function ScrollAreaBase:hslide(value)
	
end

function ScrollAreaBase:vslide(value)
	
end

function ScrollAreaBase:mousePressEvent(e)
	e:ignore();
end


function ScrollAreaBase:mouseReleaseEvent(e)
	e:ignore();
end


function ScrollAreaBase:mouseMoveEvent(e)
	e:ignore();
end


function ScrollAreaBase:mouseWheelEvent(e)
	if(self.AllowWheel) then
		Application:sendEvent(self.vbar, e);
	end
end

function ScrollAreaBase:keyPressEvent(e)
	e:ignore();
end

-- clip region. 
function ScrollAreaBase:ViewRegion()
	local w = self:width();
	local h = self:height();
	if(self.hbar and not self.hbar:isHidden()) then
		--h = h - self.hbar:height();
		h = h - self.SliderSize;
	end

	if(self.vbar and not self.vbar:isHidden()) then
		--w = w - self.vbar:width();
		w = w - self.SliderSize;
	end
	return Rect:new_from_pool(0, 0, w, h);
end

function ScrollAreaBase:updateScrollInfo()
	local clip = self:ViewRegion();
	self.hbar:setRange(0, self.viewport:GetRealWidth() - clip:width() - 1);
	self.hbar:setStep(self.viewport:WordWidth(), clip:width());
	self.hbar:SetValue(self.viewport:hValue());

	self.vbar:setRange(0, self.viewport:GetRow() - self:GetRow());
	self.vbar:setStep(1, self:GetRow());
	self.vbar:SetValue(self.viewport:vValue());
end

function ScrollAreaBase:updateScrollStatus(textbox_w, textbox_h)
	local clip = self:ViewRegion();
	if(textbox_w > clip:width()) then
		self:horizontalScrollBarShow();
	else
		self:horizontalScrollBarHide();
	end

	clip = self:ViewRegion();
	if(textbox_h > clip:height()) then
		self:verticalScrollBarShow();
		clip = self:ViewRegion();
		if(textbox_w > clip:width()) then
			self:horizontalScrollBarShow();
		else
			self:horizontalScrollBarHide();
		end
	else
		self:verticalScrollBarHide();
	end

	self:updateScrollInfo();
end

function ScrollAreaBase:UpdateScrollbarGeometry()
	if(not self.scrollbarGeometryDirty) then
		return;
	end
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
	self.scrollbarGeometryDirty = false;
end

function ScrollAreaBase:UpdateScrollbarRange()
	if(not self.scrollbarRangeDirty) then
		return;
	end
	self:updateScrollStatus(self.viewWidth, self.viewHeight);

	self.scrollbarRangeDirty = false;
end

function ScrollAreaBase:UpdateScrollbarValue()
	if(not self.scrollbarValueDirty) then
		return;
	end
	if(not self.hbar:isHidden()) then
		self.hbar:SetValue(self.viewport:hValue());
	end

	if(not self.vbar:isHidden()) then
		self.vbar:SetValue(self.viewport:vValue());
	end

	self.scrollbarValueDirty = false;
end

function ScrollAreaBase:UpdateScrollbar()
	self:UpdateScrollbarRange();
	self:UpdateScrollbarValue();
	self:UpdateScrollbarGeometry();
end

function ScrollAreaBase:paintEvent(painter)
	ScrollAreaBase._super.paintEvent(self, painter);
	self:UpdateScrollbar();
end

