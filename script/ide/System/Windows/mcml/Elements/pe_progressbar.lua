--[[
Title: progressbar
Author(s): LiPeng
Date: 2017/10/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_progressbar.lua");
Elements.pe_progressbar:RegisterAs("pe:progressbar", "progressbar");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/progressbar.lua");
local ProgressBar = commonlib.gettable("System.Windows.Controls.ProgressBar");
local mcml = commonlib.gettable("System.Windows.mcml");

local pe_progressbar = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_progressbar"));
pe_progressbar:Property({"class_name", "pe:progressbar"});

function pe_progressbar:CreateControl()
	local parentElem = self:GetParentControl();
	local _this = ProgressBar:new():init(parentElem);
	self:SetControl(_this);

	_this:SetMin(self.min);
	_this:SetMax(self.max);
	_this:SetValue(tonumber(self:GetAttributeWithCode("Value", 0, true)));
	_this:SetDirection(if_else(self:GetBool("is_vertical",false) == true, "vertical" , "horizontal"));
	--_this:SetSliderBackground(self:GetAttributeWithCode("blockimage", nil, true) or css["blockimage"]);
	--_this:SetGrooveBackground(self:GetAttributeWithCode("background", nil, true) or css["background"]);
	local step = self:GetAttributeWithCode("Step", 10, true);
	_this:setStep(step, step * 10);

	--local buttonName = self:GetAttributeWithCode("name"); -- touch name

	_this:Connect("valueChanged", self, self.OnStep, "UniqueConnection")

	pe_progressbar._super.CreateControl(self);
end

function pe_progressbar:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	self.min = tonumber(self:GetAttributeWithCode("Minimum", 0, true));
	self.max = tonumber(self:GetAttributeWithCode("Maximum", 100, true));

	pe_progressbar._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css)
end

function pe_progressbar:SetValue(value)
	self:SetAttribute("Value", value);
	if(self.control) then
		self.control:SetValue(value, true);
	end
end

function pe_progressbar:GetValue()
	if(self.control) then
		return self.control:GetValue();
	end
end

function pe_progressbar:OnStep(value)
	local ctl = self:GetControl();
	local result;
	local onstep = self:GetString("onstep");
	if(onstep == "")then
		onstep = nil;
	end
	if(onstep) then
		local percentage;
		if(self.max <= self.min)then
			percentage = 0;
		else
			percentage = (value-self.min)/(self.max-self.min);
		end
		-- the callback function "onstep" format is "function (step) end", where step is (0-1]
		result = self:DoPageEvent(onstep, percentage, self);
	end
	return result;
end

