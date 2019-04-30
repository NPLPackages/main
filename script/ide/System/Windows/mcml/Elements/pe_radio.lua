--[[
Title: radio element
Author(s): LiPeng
Date: 2017/10/3
Desc: it handles HTML tags of <radio> in HTML. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_radio.lua");
System.Windows.mcml.Elements.pe_radio:RegisterAs("pe:radio","radio");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
local Button = commonlib.gettable("System.Windows.Controls.Button");
local mcml = commonlib.gettable("System.Windows.mcml");

local pe_radio = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_radio"));
pe_radio:Property({"class_name", "pe:radio"});

function pe_radio:ctor()
	self.groupName = nil;
	self:SetTabIndex(0);
end

function pe_radio:CreateControl()
	local parentElem = self:GetParentControl();
	local _this = Button:new():init(parentElem);
	self:SetControl(_this);

	local polygonStyle = self:GetAttributeWithCode("polygonStyle", nil, true);
	local direction = self:GetAttributeWithCode("direction", nil, true);
	_this:SetPolygonStyle(polygonStyle or "radio");
	_this:SetDirection(direction);

	_this:SetTooltip(self:GetAttributeWithCode("tooltip", nil, true));
	_this:setCheckable(self:GetBool("enabled",true));

	local checked = self:GetAttributeWithCode("checked", nil, true);
	if(checked) then
		checked = if_else(checked == "true" or checked == "checked",true,false);
		self:setChecked(checked);
	end

	self.groupName = self:GetAttribute("name") or "_defaultRadioGroup";
	self.buttonName = self:GetAttributeWithCode("name",nil,true);
	_this:Connect("clicked", self, self.OnClick, "UniqueConnection");
end

function pe_radio:setChecked(checked)
	if(self.control) then
		self.control:setChecked(checked);
	end
	checked = if_else(checked, "true", "false");
	self:SetAttribute("checked", checked);
end

function pe_radio:getChecked()
	local checked = self:GetAttributeWithCode("checked", nil, true);
	if(checked) then
		checked = if_else(checked == "true" or checked == "checked",true,false);
	end
	return checked;
end

function pe_radio:OnClick()
	local result;
	local value = self:GetAttributeWithCode("value", nil, true);
	
	local max = tonumber(self:GetAttributeWithCode("max", nil, true) or 1);
	local min = tonumber(self:GetAttributeWithCode("min", nil, true) or 1);

	local parentNode = self:GetParent("form") or self:GetParent("pe:editor") or self:GetRoot();
	if(parentNode) then
		local radios = parentNode:GetAllChildWithAttribute("name", self.groupName);
		if(radios) then
			local max_left = max - 1;
			local i, radio;
			local count = 0;
			local is_last_checked = true;
			for i, radio in ipairs(radios) do
				local ctl = radio:GetControl();
				if(ctl) then
					local radio_value = radio:GetAttributeWithCode("value", nil, true);
					if(radio_value ~= value) then
						if(max_left>0) then
							max_left = max_left - 1;
							count = count + 1;
						else
							radio:setChecked(false);
							--ctl:setChecked(false);
							--radio:SetAttribute("checked", "false");
						end
					elseif(radio_value == value) then
						is_last_checked = false;
						radio:setChecked(true);
						--ctl:setChecked(true);
						--radio:SetAttribute("checked", "true");
					end	
				end
			end
		end
		
	end

	local onclick = self.onclickscript or self:GetString("onclick");
	if(onclick == "")then
		onclick = nil;
	end
	if(onclick) then
		-- the callback function format is function(buttonName, self) end
		result = self:DoPageEvent(onclick, value, self);
	end

	return result;
end