--[[
Title: SliderBar
Author(s): LiPeng
Date: 2017/10/3
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/SliderBar.lua");
local SliderBar = commonlib.gettable("System.Windows.Controls.SliderBar");
------------------------------------------------------------
test
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Window.lua");
NPL.load("(gl)script/ide/System/test/test_Windows.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/SliderBar.lua");
local Window = commonlib.gettable("System.Windows.Window")	
local test_Windows = commonlib.gettable("System.Core.Test.test_Windows");
local SliderBar = commonlib.gettable("System.Windows.Controls.SliderBar");
local window = Window:new();
local sliderbar = SliderBar:new():init(window);
sliderbar:setGeometry(100,100,200,32);
--sliderbar:SetDirection("vertical");
--sliderbar:setGeometry(50,50,32,200);
window:Show("my_window", nil, "_mt", 0,0, 500, 500);
test_Windows.window = window;
test_Windows.sliderbar = sliderbar;

NPL.load("(gl)script/ide/System/test/test_Windows.lua");
local test_Windows = commonlib.gettable("System.Core.Test.test_Windows");
local sliderbar = test_Windows.sliderbar;
sliderbar:SetShowEditor(false);
sliderbar:SetShowButton(false);
------------------------------------------------------------
]]
--NPL.load("(gl)script/ide/math/Rect.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Primitives/SliderBase.lua");
local Rect = commonlib.gettable("mathlib.Rect");

local SliderBar = commonlib.inherit(commonlib.gettable("System.Windows.Controls.Primitives.SliderBase"), commonlib.gettable("System.Windows.Controls.SliderBar"));
SliderBar:Property("Name", "SliderBar");


SliderBar:Property({"grooveWidth", nil, nil, "SetGrooveWidth",auto=true});
SliderBar:Property({"grooveHeight", nil, nil, "SetGrooveHeight",auto=true});
SliderBar:Property({"grooveBackground", nil,auto=true});

SliderBar:Property({"sliderWidth", nil, nil, "SetSliderWidth",auto=true});
SliderBar:Property({"sliderHeight", nil, nil, "SetSliderHeight",auto=true});
SliderBar:Property({"sliderBackground", nil,auto=true});

function SliderBar:ctor()
	self.groove = nil;
	self.slider = nil;
end

-- @param pos: 
function SliderBar:pixelPosToRangeValue(pos)
	local slider = self:Slider();
	local span, value;
	if(self.direction == "horizontal") then
		local x = pos[1];
		span = self:width() - slider:width();
		value = self:valueFromPosition(x - slider:width()/2, span);
	else
		local y = pos[2];
		span = self:height() - slider:height();
		value = self:valueFromPosition(y - slider:height()/2, span);
	end
	return value;
end

function SliderBar:SetSliderBackground(bg)
	if(bg and bg ~= "") then
		self.sliderBackground = bg;
	end
end

function SliderBar:hitSlider(pos)
	--local rect = Rect:new_from_pool(0, 0, self.backgroundRect:width(), self:height());
    return self:Slider():contains(pos) == true;
end

function SliderBar:Groove()
	if(not self.groove) then
		local x,y,w,h;
		if(self.direction == "horizontal") then
			w = self.grooveWidth or self:width();
			h = self.grooveHeight or 4;
			x = 0;
			y = math.floor((self:height() - h)/2 + 0.5);
		else
			w = self.grooveWidth or 4;
			h = self.grooveHeight or self:height();
			x = math.floor((self:width() - w)/2 + 0.5);
			y = 0;
		end
		self.groove = Rect:new():init(x,y,w,h);
	end
	return self.groove;
end

---- the position for self
--function SliderBar:Groove()
--	local groove = self:Groove();
--	local xp = groove:x() - self:x();
--	local yp = groove:y() - self:y();
--	return Rect:new_from_pool(xp, yp, groove:width(), groove:height());
--end

function SliderBar:Slider()
	if(not self.slider) then
		local x,y,w,h;
		if(self.direction == "horizontal") then
			w = self.sliderWidth or 16;
			h = self.sliderHeight or self:height();
			x = 0;
			y = math.floor((self:height() - h)/2 + 0.5);
		else
			w = self.sliderWidth or self:width();
			h = self.sliderHeight or 16;
			x = math.floor((self:width() - w)/2 + 0.5);
			y = 0;
		end
		self.slider = Rect:new():init(x,y,w,h);
	end
	return self.slider;
end

function SliderBar:mousePressEvent(e)
	if (e:button() ~= "left") then
        e:ignore();
        return;
    end

	if(self:hitSlider(e:pos())) then
		self:setDown(true);
	else
		self:setSliderPosition(e:pos());
	end
	e:accept();
end

function SliderBar:mouseMoveEvent(e)
	if ((e:button() == "left") and self:Down()) then
		self:setSliderPosition(e:pos());
    end
	e:ignore();
end

-- virtual: 
function SliderBar:mouseReleaseEvent(e)
    if (not self.down or e:button() ~= "left") then
        e:ignore();
        return;
    end
	self:setDown(false);
	e:accept();
end


function SliderBar:setSliderPosition(pos)
	local value = self:pixelPosToRangeValue(pos);
	self:SetValue(value, true);
end

function SliderBar:setDown(down)
	self.down = down;
end

function SliderBar:updateSlider()
	local slider = self:Slider();
	local span, pos;
	if(self.direction == "horizontal") then
		span = self:width() - slider:width();
		pos = self:positionFromValue(self.value, span);
		slider:setX(pos);
	else
		span = self:height() - slider:height();
		pos = self:positionFromValue(self.value, span);
		slider:setY(pos);
	end
end

function SliderBar:paintEvent(painter)
	self:updateSlider();
	local groove = self:Groove();
	local groovBackground = self.grooveBackground;
	if(groovBackground and groovBackground~="") then
		painter:SetPen("#ff0000");
		painter:DrawRectTexture(self:x() + groove:x(), self:y() + groove:y(), groove:width(), groove:height(), groovBackground);
	end

	local slider = self:Slider();
	local sliderBackground = self.sliderBackground;
	if(sliderBackground and sliderBackground~="") then
		painter:SetPen("#ffffff");
		painter:DrawRectTexture(self:x() + slider:x(), self:y() + slider:y(), slider:width(), slider:height(), sliderBackground);
	end
end


