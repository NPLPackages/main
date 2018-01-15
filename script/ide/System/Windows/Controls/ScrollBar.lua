--[[
Title: ScrollBar
Author(s): LiPeng
Date: 2017/10/3
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollBar.lua");
local ScrollBar = commonlib.gettable("System.Windows.Controls.ScrollBar");
------------------------------------------------------------
test
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Window.lua");
NPL.load("(gl)script/ide/System/test/test_Windows.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollBar.lua");
local Window = commonlib.gettable("System.Windows.Window")	
local test_Windows = commonlib.gettable("System.Core.Test.test_Windows");
local ScrollBar = commonlib.gettable("System.Windows.Controls.ScrollBar");
local window = Window:new();
local scrollBar = ScrollBar:new():init(window);
--scrollBar:SetDirection("vertical");
scrollBar:setRange(0,100)
scrollBar:setStep(1,5);
scrollBar:setGeometry(50,50,200,30);
--scrollBar:setGeometry(50,50,30,200);
window:Show("my_window", nil, "_mt", 0,0, 600, 600);
test_Windows.window = window;


NPL.load("(gl)script/ide/System/Windows/Window.lua");
NPL.load("(gl)script/ide/System/test/test_Windows.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollBar.lua");
local Window = commonlib.gettable("System.Windows.Window")	
local test_Windows = commonlib.gettable("System.Core.Test.test_Windows");
local ScrollBar = commonlib.gettable("System.Windows.Controls.ScrollBar");
local window = Window:new();
local scrollBar = ScrollBar:vScrollBar(window)
window:Show("my_window", nil, "_mt", 0,0, 600, 600);
scrollBar:setGeometry(50,50,30,200);
test_Windows.window = window;
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/Primitives/SliderBase.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
local Button = commonlib.gettable("System.Windows.Controls.Button");
local Rect = commonlib.gettable("mathlib.Rect");

local ScrollBar = commonlib.inherit(commonlib.gettable("System.Windows.Controls.Primitives.SliderBase"), commonlib.gettable("System.Windows.Controls.ScrollBar"));
ScrollBar:Property("Name", "ScrollBar");


ScrollBar:Property({"grooveWidth", nil, nil, "SetGrooveWidth",auto=true});
ScrollBar:Property({"grooveHeight", nil, nil, "SetGrooveHeight",auto=true});
--ScrollBar:Property({"grooveBackground", "Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;456 396 16 16:4 4 4 4",auto=true});
ScrollBar:Property({"grooveBackground", nil,auto=true});

ScrollBar:Property({"sliderWidth", nil, nil, "SetSliderWidth",auto=true});
ScrollBar:Property({"sliderHeight", nil, nil, "SetSliderHeight",auto=true});
--ScrollBar:Property({"sliderBackground", "Texture/3DMapSystem/common/ThemeLightBlue/slider_button_16.png;5 5 5 5:1 1 1 1",auto=true});
ScrollBar:Property({"sliderBackground", nil,auto=true});

ScrollBar:Property({"buttonWidth", nil ,auto=true});
ScrollBar:Property({"buttonHeight", nil, auto=true});
--ScrollBar:Property({"PrevButtonBackground", "Texture/3DMapSystem/common/ThemeLightBlue/slider_button_16.png;5 5 5 5:1 1 1 1"});
--ScrollBar:Property({"NextButtonBackground", "Texture/3DMapSystem/common/ThemeLightBlue/slider_button_16.png;5 5 5 5:1 1 1 1"});
ScrollBar:Property({"PrevButtonBackground", nil});
ScrollBar:Property({"NextButtonBackground", nil});

function ScrollBar:ctor()
	self.groove = nil;
	self.slider = nil;
	self.prevButton = nil;
	self.nextButton = nil;
end

function ScrollBar:init(parent)
	ScrollBar._super.init(self,parent);
	self:initButton();
	return self;
end

function ScrollBar:initButton()
	self.prevButton = Button:new():init(self);
	self.prevButton:SetPolygonStyle("narrow");
	--self.prevButton:SetBackground(self.PrevButtonBackground);
	self.prevButton:Connect("pressed", function (event)
		self:SliderSingleStepSub();
	end)

	self.nextButton = Button:new():init(self);
	self.nextButton:SetPolygonStyle("narrow");
	--self.nextButton:SetBackground(self.NextButtonBackground);
	self.nextButton:Connect("pressed", function (event)
		self:SliderSingleStepAdd();
	end)

	self:UpdateButtonDirection();
end

function ScrollBar:UpdateButtonDirection()
	local direction = self.direction;
	if(direction == "horizontal") then
		self.prevButton:SetDirection("left");
		self.nextButton:SetDirection("right");
	elseif(direction == "vertical") then
		self.prevButton:SetDirection("up");
		self.nextButton:SetDirection("down");
	end
end

function ScrollBar:SetDirection(direction)
	ScrollBar._super.SetDirection(self, direction);
	self:UpdateButtonDirection();
end

function ScrollBar:vScrollBar(parent)
	local vscrollbar = self:new():init(parent);
	vscrollbar:SetDirection("vertical");
--	vscrollbar:SetBackground("Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;285 126 7 28:1 1 1 1");
--	vscrollbar:SetSliderBackground("Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;275 126 7 47:2 1 2 1");
--	vscrollbar:SetPrevButtonBackground("Texture/3DMapSystem/common/ThemeLightBlue/slider_button_16.png;5 5 5 5:1 1 1 1");
--	vscrollbar:SetNextButtonBackground("Texture/3DMapSystem/common/ThemeLightBlue/slider_button_16.png;5 5 5 5:1 1 1 1");
--	vscrollbar:SetPrevButtonBackground("Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;0 0 4 4:1 1 1 1");
--	vscrollbar:SetNextButtonBackground("Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;0 0 4 4:1 1 1 1");
	return vscrollbar;
end

function ScrollBar:hScrollBar(parent)
	local scrollbar = self:new():init(parent);
	scrollbar:SetDirection("horizontal");
--	scrollbar:SetBackground("Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;285 126 7 28:1 1 1 1");
--	scrollbar:SetSliderBackground("Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;275 126 7 47:2 1 2 1");
--	scrollbar:SetPrevButtonBackground("Texture/3DMapSystem/common/ThemeLightBlue/slider_button_16.png;5 5 5 5:1 1 1 1");
--	scrollbar:SetNextButtonBackground("Texture/3DMapSystem/common/ThemeLightBlue/slider_button_16.png;5 5 5 5:1 1 1 1");
--	scrollbar:SetPrevButtonBackground("Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;0 0 4 4:1 1 1 1");
--	scrollbar:SetNextButtonBackground("Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;0 0 4 4:1 1 1 1");
	return scrollbar;
end

-- @param pos: 
function ScrollBar:pixelPosToRangeValue(pos)
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

function ScrollBar:hitSlider(pos)
	--local rect = Rect:new_from_pool(0, 0, self.backgroundRect:width(), self:height());
    return self:Slider():contains(pos) == true;
end

function ScrollBar:PrevButton()
	--Rect:new_from_pool(self.prevButton:x(),self.prevButton:y(),)
end

function ScrollBar:NextButton()

end

function ScrollBar:Groove()
	if(not self.groove) then
		local x,y,w,h;
		if(self.direction == "horizontal") then
			w = self.grooveWidth or (self:width() - self.prevButton:width() - self.nextButton:width());
			h = self.grooveHeight or self:height();
			x = self.prevButton:width();
			y = 0;
		else
			w = self.grooveWidth or self:width();
			h = self.grooveHeight or (self:height() - self.prevButton:height() - self.nextButton:height());
			x = 0;
			y = self.prevButton:height();
		end
		self.groove = Rect:new():init(x,y,w,h);
	end
	return self.groove;
end

--function ScrollBar:countSliderWidth()
--	local range = self.max - self.min;
--	self:groove(): self.pageStep / range
--end

function ScrollBar:Slider()
	if(not self.slider) then
		local groove = self:Groove();
		local x,y,w,h;
		local range = self.max - self.min;
		local len = range + self.pageStep;
		if(self.direction == "horizontal") then
			--w = self.sliderWidth or 16;
			w = math.floor(groove:width() * self.pageStep / len + 0.5);
			h = self.sliderHeight or (self:height() - 4);
			x = self.prevButton:width();
			y = math.floor((self:height() - h)/2 + 0.5);
		else
			w = self.sliderWidth or (self:width() - 4);
			h = math.floor(groove:height() * self.pageStep / len + 0.5);
			--h = self.sliderHeight or 16;
			x = math.floor((self:width() - w)/2 + 0.5);
			y = self.prevButton:height();
		end
		self.slider = Rect:new():init(x,y,w,h);
	end
	return self.slider;
end

function ScrollBar:mousePressEvent(e)
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

function ScrollBar:mouseMoveEvent(e)
	if ((e:button() == "left") and self:Down()) then
		self:setSliderPosition(e:pos());
    end
	e:ignore();
end

-- virtual: 
function ScrollBar:mouseReleaseEvent(e)
    if (not self.down or e:button() ~= "left") then
        e:ignore();
        return;
    end
	self:setDown(false);
	e:accept();
end


function ScrollBar:setSliderPosition(pos)
	local value = self:pixelPosToRangeValue(pos);
	self:SetValue(value, true);
end

function ScrollBar:setDown(down)
	self.down = down;
end

function ScrollBar:updateSlider()
	local slider = self:Slider();
	local groove = self:Groove();
	local range = self.max - self.min;
	local len = range + self.pageStep;
	local span, pos;
	if(self.direction == "horizontal") then
		span = groove:width() - slider:width();
		pos = self:positionFromValue(self.value, span);
		slider:setX(groove:x() + pos);
		if(slider:width() > slider:height()) then
			local w = math.floor(groove:width() * self.pageStep / len + 0.5);
			slider:setWidth(w);
		end
	else
		span = groove:height() - slider:height();
		pos = self:positionFromValue(self.value, span);
		slider:setY(groove:y() + pos);
		if(slider:height() > slider:width()) then
			local h = math.floor(groove:height() * self.pageStep / len + 0.5);
			slider:setHeight(h);
		end
	end
end

function ScrollBar:updateGroove()
	--if(not self.groove) then
	local groove = self:Groove();
	local x,y,w,h;
	if(self.direction == "horizontal") then
		w = self.grooveWidth or (self:width() - self.prevButton:width() - self.nextButton:width());
		h = self.grooveHeight or self:height();
		x = self.prevButton:width();
		y = 0;
	else
		w = self.grooveWidth or self:width();
		h = self.grooveHeight or (self:height() - self.prevButton:height() - self.nextButton:height());
		x = 0;
		y = self.prevButton:height();
	end

	groove:setRect(x,y,w,h);

	--self.groove = Rect:new():init(x,y,w,h);
end

function ScrollBar:updateButtonGeometry()
	--if(not self.updateButton) then
		if(self.direction == "horizontal") then
			self.prevButton:setGeometry(0, 0, 16, self:height());
			self.nextButton:setGeometry(self:width() - 16, 0, 16, self:height());
		else
			self.prevButton:setGeometry(0, 0, self:width(), 16);
			self.nextButton:setGeometry(0, self:height() - 16, self:width(), 16);
		end

		self.updateButton = true;
	--end
end

function ScrollBar:paintEvent(painter)
	self:updateButtonGeometry();
	self:updateGroove();
	self:updateSlider();
	local groove = self:Groove();
	local groovBackground = self.grooveBackground;
	local groove_x, groove_y, groove_w, groove_h = groove:x(), groove:y(), groove:width(), groove:height();
	if(self.direction == "horizontal") then
		groove_x = 0;
		groove_w = self:width();
	elseif(self.direction == "vertical") then
		groove_y = 0;
		groove_h = self:height()
	end
	if(groovBackground and groovBackground~="") then
		painter:SetPen("#00ff00");
		--painter:DrawRectTexture(self:x() + groove:x(), self:y() + groove:y(), 4, groove:height(), groovBackground);
		--painter:DrawRectTexture(self:x() + groove:x(), self:y() + groove:y(), groove:width(), groove:height(), groovBackground);
		painter:DrawRectTexture(self:x() + groove_x, self:y() + groove_y, groove_w, groove_h, groovBackground);
	else
		painter:SetPen("#f1f1f1");
		--painter:DrawRectTexture(self:x() + groove:x(), self:y() + groove:y(), 4, groove:height(), groovBackground);
		--painter:DrawRectTexture(self:x() + groove:x(), self:y() + groove:y(), groove:width(), groove:height(), "");
		painter:DrawRectTexture(self:x() + groove_x, self:y() + groove_y, groove_w, groove_h, "");
	end

	local slider = self:Slider();
	local sliderBackground = self.sliderBackground;
	if(sliderBackground and sliderBackground~="") then
		painter:SetPen("#00ffff");
		painter:DrawRectTexture(self:x() + slider:x(), self:y() + slider:y(), slider:width(), slider:height(), sliderBackground);
	else
		painter:SetPen("#c1c1c1");
		painter:DrawRectTexture(self:x() + slider:x(), self:y() + slider:y(), slider:width(), slider:height(), "");
	end
end
