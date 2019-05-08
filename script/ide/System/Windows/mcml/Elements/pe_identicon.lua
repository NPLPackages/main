--[[
Title: identicon
Author(s): LiXizhi
Date: 2015/10/4
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_identicon.lua");
Elements.pe_identicon:RegisterAs("button");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/Identicon.lua");
local Identicon = commonlib.gettable("System.Windows.Controls.Identicon");

local pe_identicon = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_identicon"));
pe_identicon:Property({"class_name", "pe:identicon"});

function pe_identicon:ControlClass()
	return Identicon;
end

function pe_identicon:CreateControl()
	pe_identicon._super.CreateControl(self);

	local _this = self:GetControl();
	if(_this) then
		_this:SetText(self:GetAttributeWithCode("value", nil, true));
	end
end

function pe_identicon:SetValue(value)
	self:SetAttribute("value", value);
end

function pe_identicon:GetValue()
	return self:GetAttribute("value");
end

