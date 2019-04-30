--[[
Title: checkbox element
Author(s): LiPeng
Date: 2017/10/3
Desc: it handles HTML tags of <checkbox> in HTML. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_checkbox.lua");
System.Windows.mcml.Elements.pe_checkbox:RegisterAs("pe:checkbox","checkbox");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
local Button = commonlib.gettable("System.Windows.Controls.Button");
local mcml = commonlib.gettable("System.Windows.mcml");

local pe_checkbox = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_checkbox"));
pe_checkbox:Property({"class_name", "pe:checkbox"});

function pe_checkbox:ctor()
	self:SetTabIndex(0);
end

function pe_checkbox:CreateControl()
	local parentElem = self:GetParentControl();
	local _this = Button:new():init(parentElem);
	self:SetControl(_this);

	local polygonStyle = self:GetAttributeWithCode("polygonStyle", nil, true);
	local direction = self:GetAttributeWithCode("direction", nil, true);
	_this:SetPolygonStyle(polygonStyle or "check");
	_this:SetDirection(direction);

	_this:SetTooltip(self:GetAttributeWithCode("tooltip", nil, true));
	_this:setCheckable(self:GetBool("enabled",true));

	local checked = self:GetAttributeWithCode("checked", nil, true);
	if(checked) then
		checked = if_else(checked == "true" or checked == "checked",true,false);
		self:setChecked(checked);
	end

	self.buttonName = self:GetAttributeWithCode("name",nil,true);
	_this:Connect("clicked", self, self.OnClick, "UniqueConnection");
end

function pe_checkbox:setChecked(checked)
	if(self.control) then
		self.control:setChecked(checked);
	end
	checked = if_else(checked, "true", "false");
	self:SetAttribute("checked", checked);
end

function pe_checkbox:getChecked()
	local checked = self:GetAttributeWithCode("checked", nil, true);
	if(checked) then
		checked = if_else(checked == "true" or checked == "checked",true,false);
	end
	return checked;
end

function pe_checkbox:OnClick()
	local ctl = self:GetControl();
	if(ctl and ctl:isCheckable()) then
		local checked = not (ctl:isChecked());
		ctl:setChecked(checked);
		self:SetAttribute("checked", if_else(checked, "true", "false"));
	end
	local result;
	local onclick = self.onclickscript or self:GetString("onclick");
	if(onclick == "")then
		onclick = nil;
	end
	if(onclick) then
		-- the callback function format is function(buttonName, self) end
		result = self:DoPageEvent(onclick, self:getChecked(), self);
	end
	return result;
end