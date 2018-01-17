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
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
NPL.load("(gl)script/ide/math/Rect.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollBar.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Canvas.lua");
local Canvas = commonlib.gettable("System.Windows.Controls.Canvas");
local ScrollBar = commonlib.gettable("System.Windows.Controls.ScrollBar");
local Rect = commonlib.gettable("mathlib.Rect");
local Application = commonlib.gettable("System.Windows.Application");

local ScrollAreaBase = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.Controls.Primitives.ScrollAreaBase"));
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
end

function ScrollAreaBase:init(parent)
	ScrollAreaBase._super.init(self, parent);

	self:initScrollBar();
	self:initViewport();
	return self;
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
		--echo("show srcoll bar");
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
--	echo("ScrollAreaBase:ClipRegion");
--	echo("self.hbar is Hidden:"..tostring(self.hbar:isHidden()));
--	echo("self.vbar is Hidden:"..tostring(self.vbar:isHidden()));
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

function ScrollAreaBase:paintEvent(painter)

end

