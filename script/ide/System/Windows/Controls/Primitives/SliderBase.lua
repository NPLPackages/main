--[[
Title: SliderBase
Author(s): LiPeng
Date: 2017/10/3
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/Primitives/SliderBase.lua");
local SliderBase = commonlib.gettable("System.Windows.Controls.Primitives.SliderBase");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
NPL.load("(gl)script/ide/math/Rect.lua");
local Rect = commonlib.gettable("mathlib.Rect");

local SliderBase = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.Controls.Primitives.SliderBase"));
SliderBase:Property("Name", "SliderBase");

SliderBase:Property({"value", 1, "GetValue", "SetValue", auto=true});
--SliderBase:Property({"verValue", nil, auto=true});
SliderBase:Property({"min", 1, "GetMin", "SetMin", auto=true});
SliderBase:Property({"max", 100, "GetMax", "SetMax", auto=true});
SliderBase:Property({"singleStep", 1, "GetSingleStep", "SetSingleStep", auto=true});
SliderBase:Property({"pageStep", 10, "GetPageStep", "SetPageStep", auto=true});
SliderBase:Property({"sliderPosition", 1, "GetSliderPosition", "SetSliderPosition", auto=true});
-- nil, "vertical" or "horizontal". If nil it will deduce from the width and height. 
SliderBase:Property({"direction", "horizontal", nil, "SetDirection", auto=true});
SliderBase:Property({"down", false, "Down", auto=true});



SliderBase:Signal("sliderMoved",function(pos) end);
SliderBase:Signal("valueChanged",function(value) end);



function SliderBase:ctor()
	-- the position for parent
--	self.groove = Rect:new():init(0,0,0,0);
--	self.slider = Rect:new():init(0,0,0,0);
end

function SliderBase:SetDirection(direction)
	if(direction and (direction == "horizontal" or direction == "vertical")) then
		self.direction = direction;
	end
end

function SliderBase:SetMin(min)
	self:setRange(min, self.max);
end

function SliderBase:SetMax(max)
	self:setRange(self.min, max);
end

function SliderBase:setRange(min, max, emitSingal)
	if(emitSingal ~= false) then
		emitSingal = true;
	end
	self.min = min;
	self.max = max;
	self:SetValue(self.value, emitSingal);
end

function SliderBase:setStep(single, page)
	self.singleStep = single;
	self.pageStep = page;
	--self:SetValue(value);
end


function SliderBase:SetValue(value, emitSingal)
	value = self:bound(value);
	if(value == self.value) then
		return;
	end
	self.value = value;
	if(emitSingal) then
		self:emitValueChanged();
	end
end

function SliderBase:GetValue()
	return self.value;
end

function SliderBase:bound(value)
	return math.max(self.min, math.min(self.max, value));
end

function SliderBase:SliderSingleStepAdd()
	self:SetValue(self.value + self.singleStep, true);
end

function SliderBase:SliderSingleStepSub()
	self:SetValue(self.value - self.singleStep, true);
end

function SliderBase:SliderPageStepAdd()
	self:SetValue(self.value + self.pageStep, true);
end

function SliderBase:SliderPageStepSub()
	self:SetValue(self.value - self.pageStep, true);
end

function SliderBase:SliderToMin()
	self:SetValue(self.min, true);
end

function SliderBase:SliderToMax()
	self:SetValue(self.max, true);
end

function SliderBase:valueFromPosition(pos, span)
	local min = self.min;
	local max = self.max;
	if(pos <= 0 or span <= 0) then
		return min;
	end
	if(pos >= span) then
		return max;
	end

	local range = max - min;

    if (span > range) then
        local tmp = math.floor(range * pos/span + 0.5);
        return tmp + min;
	else
        local div = math.floor(range / span);
        local mod = range % span;
        local tmp = pos * div + math.floor(mod * pos/span + 0.5);
        return tmp + min;
    end
end

function SliderBase:positionFromValue(val, span)
	local min = self.min;
	local max = self.max;
	if(val <= 0 or span <= 0 or max <= min) then
		return 0;
	end
	if(val >= max) then
		return span;
	end

	local range = max - min;

	local offset_val = val - min;

	 if (range > span) then
        return math.floor(span * offset_val/range+ 0.5);
	else
        local div = math.floor(span / range);
        local mod = span % range;
        return offset_val * div + math.floor(mod * offset_val/range + 0.5);
    end
end

function SliderBase:pixelPosToRangeValue(pos)
	
end

function SliderBase:mapToValue(x,y)

end

function SliderBase:mouseWheelEvent(e)
	local delta = e:GetDelta();
	self:scrollByDelta(delta);
	e:accept();
end

function SliderBase:scrollByDelta(delta)
	delta = -delta;
	local offset = delta / 120;
	local stepToScroll = math.floor(self.pageStep * offset + 0.5);
	if(stepToScroll == 0) then
		stepToScroll = if_else(delta > 0, self.singleStep, -self.singleStep);
	else
		stepToScroll = math.max(-self.pageStep, math.min(self.pageStep, stepToScroll));
	end
	self:SetValue(self.value + stepToScroll, true);
end


function SliderBase:emitValueChanged()
	self:valueChanged(self.value);
end