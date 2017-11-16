--[[
Title: ProgressBar
Author(s): LiXizhi
Date: 2015/4/29
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/ProgressBar.lua");
local ProgressBar = commonlib.gettable("System.Windows.Controls.ProgressBar");
------------------------------------------------------------
]]
--NPL.load("(gl)script/ide/math/Rect.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Primitives/SliderBase.lua");
local Rect = commonlib.gettable("mathlib.Rect");

local ProgressBar = commonlib.inherit(commonlib.gettable("System.Windows.Controls.Primitives.SliderBase"), commonlib.gettable("System.Windows.Controls.ProgressBar"));
ProgressBar:Property("Name", "ProgressBar");


ProgressBar:Property({"grooveWidth", nil, nil, "SetGrooveWidth",auto=true});
ProgressBar:Property({"grooveHeight", nil, nil, "SetGrooveHeight",auto=true});
ProgressBar:Property({"grooveBackground", "Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;456 396 16 16:4 4 4 4",auto=true});

ProgressBar:Property({"sliderBackground", "Texture/3DMapSystem/common/ThemeLightBlue/slider_button_16.png;5 5 5 5:1 1 1 1",auto=true});

function ProgressBar:ctor()
	self.groove = nil;
	self.slider = nil;
end

-- @param pos: 
function ProgressBar:pixelPosToRangeValue(pos)
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

function ProgressBar:SetGrooveBackground(bg)
	if(bg and bg ~= "") then
		self.grooveBackground = bg;
	end
end

function ProgressBar:SetSliderBackground(bg)
	if(bg and bg ~= "") then
		self.sliderBackground = bg;
	end
end

function ProgressBar:hitSlider(pos)
	--local rect = Rect:new_from_pool(0, 0, self.backgroundRect:width(), self:height());
    return self:Slider():contains(pos) == true;
end

function ProgressBar:Groove()
	if(not self.groove) then
		self.groove = self:rect();
	end
	return self.groove;
end

function ProgressBar:Slider()
	if(not self.slider) then
		self.slider = Rect:new():init(0,0,0,0);
	end
	return self.slider;
end

function ProgressBar:mouseWheelEvent(e)
	e:ignore();
end

function ProgressBar:setSliderPosition(pos)
	local value = self:pixelPosToRangeValue(pos);
	self:SetValue(value, true);
end

function ProgressBar:setDown(down)
	self.down = down;
end

function ProgressBar:updateSlider()
	local slider = self:Slider();
	local span, pos;
	if(self.direction == "horizontal") then
		span = self:width();
		pos = self:positionFromValue(self.value, span);
		--slider:setX(pos);
		slider:setRect(0, 0, pos, self:height());
	else
		span = self:height();
		pos = span - self:positionFromValue(self.value, span);
		--slider:setY(pos);
		slider:setRect(0, 0, self:width(), pos);
	end
end

function ProgressBar:paintEvent(painter)
	self:updateSlider();
	local groove = self:Groove();
	local groovBackground = self.grooveBackground;
	if(groovBackground and groovBackground~="") then
		painter:SetPen("#ff0000");
		painter:DrawRectTexture(self:x() + groove:x(), self:y() + groove:y(), groove:width(), groove:height(), groovBackground);
	end

	local slider = self:Slider();
	local sliderBackground = self.sliderBackground;
	if(sliderBackground and sliderBackground~="" and slider:width() > 0 and slider:height() > 0) then
		painter:SetPen("#ffffff");
		painter:DrawRectTexture(self:x() + slider:x(), self:y() + slider:y(), slider:width(), slider:height(), sliderBackground);
	end
end


