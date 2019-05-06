--[[
Title: editbox
Author(s): LiXizhi
Date: 2015/5/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_editbox.lua");
Elements.pe_editbox:RegisterAs("editbox");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/EditBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutTextControlSingleLine.lua");
local LayoutTextControlSingleLine = commonlib.gettable("System.Windows.mcml.layout.LayoutTextControlSingleLine");
local EditBox = commonlib.gettable("System.Windows.Controls.EditBox");

local pe_editbox = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_editbox"));
pe_editbox:Property({"class_name", "pe:editbox"});

function pe_editbox:ctor()
	self:SetTabIndex(0);
end

function pe_editbox:CreateControl()
	local parentElem = self:GetParentControl();
	local _this = EditBox:new():init(parentElem);
	self:SetControl(_this);

	local type = self:GetAttributeWithCode("type", nil, true);
	_this:setEncrypted(type == "password");

	_this:SetText(self:GetAttributeWithCode("value", nil, true));
	_this:SetEmptyText(self:GetAttributeWithCode("EmptyText", nil, true));

	local beFocus = self:GetBool("autofocus");
	if(beFocus) then
		_this:setFocus("autofocus");
	end

	_this:Connect("textChanged", self, self.OnTextChanged)

	pe_editbox._super.CreateControl(self);
end


function pe_editbox:isPasswordButton()
	local type = self:GetAttributeWithCode("type", nil, true);
	if(type == "password") then
		return true;
	end
	return false;
end

function pe_editbox:OnTextChanged(actualText)
	local onchange = self:GetString("onchange");
	if(onchange) then
		local result = self:DoPageEvent(onchange, actualText, self);
		return result;
	end
end

-- this is a deprecated function. please use "GetValue" to replace it;
-- get UI value: get the value on the UI object with current node
-- @param instName: the page instance name. 
function pe_editbox:GetUIValue()
	if(self.control) then
		return self.control:GetText();
	end
end

-- this is a deprecated function. please use "SetValue" to replace it;
-- set UI value: set the value on the UI object with current node
function pe_editbox:SetUIValue(value)
	if(self.control) then
		return self.control:SetText(value);
	end
end


function pe_editbox:GetValue()
	if(self.control) then
		return self.control:GetText();
	else
		return self:GetAttribute("value");
	end
end

function pe_editbox:SetValue(value)
	value = tostring(value);
	if(self.control) then
		return self.control:SetText(value);
	end
end

function pe_editbox:attachLayoutTree()
	pe_editbox._super.attachLayoutTree(self);
	if (self:Renderer()) then
        self:Renderer():UpdateFromElement();
	end
end

function pe_editbox:CreateLayoutObject(arena, style)
	return LayoutTextControlSingleLine:new():init(self);
end

function pe_editbox:ValueWithDefault()
	return self:GetValue()
end