--[[
Title: sliderbar
Author(s): LiPeng
Date: 2017/10/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_sliderbar.lua");
Elements.pe_sliderbar:RegisterAs("pe:sliderbar", "sliderbar");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/SliderBar.lua");
local mcml = commonlib.gettable("System.Windows.mcml");
local SliderBar = commonlib.gettable("System.Windows.Controls.SliderBar");

local pe_sliderbar = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_sliderbar"));
pe_sliderbar:Property({"class_name", "pe:sliderbar"});

function pe_sliderbar:CreateControl()
	local parentElem = self:GetParentControl();
	local _this = SliderBar:new():init(parentElem);
	self:SetControl(_this);

	_this:SetMin(self:GetAttributeWithCode("min", 1, true));
	_this:SetMax(self:GetAttributeWithCode("max", 100, true));
	_this:SetValue(self:GetAttributeWithCode("value", 0, true));
	local min_step = self:GetAttributeWithCode("min_step", 1, true);
	_this:SetDirection(self:GetAttributeWithCode("direction", nil, true));
	_this:setStep(min_step, min_step * 10);
	_this:SetSliderBackground(self:GetAttributeWithCode("button_bg", nil, true));
	_this:SetSliderWidth(self:GetNumber("button_width", nil));
	_this:SetSliderHeight(self:GetNumber("button_height", nil));
	--_this:SetGrooveBackground(self:GetAttributeWithCode("background", nil, true) or css["background"]);
	_this:SetGrooveWidth(self:GetNumber("background_width", nil));
	_this:SetGrooveHeight(self:GetNumber("background_height", nil));

	--local buttonName = self:GetAttributeWithCode("name"); -- touch name

	_this:Connect("valueChanged", self, self.OnChange, "UniqueConnection")

	pe_sliderbar._super.CreateControl(self);
end

function pe_sliderbar:SetValue(value)
	self:SetAttribute("value", value);
	if(self.control) then
		self.control:SetValue(value, true);
	end
end

function pe_sliderbar:GetValue()
	if(self.control) then
		return self.control:GetValue();
	end
end

function pe_sliderbar:OnChange(value)
	local ctl = self:GetControl();
	local result;
	local onchange = self:GetString("onchange");
	if(onchange == "")then
		onchange = nil;
	end
	if(onchange) then
		-- the callback function format is function(buttonName, self) end
		result = self:DoPageEvent(onchange, value, self);
	end
	return result;
end

