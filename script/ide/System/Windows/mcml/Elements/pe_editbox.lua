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
local EditBox = commonlib.gettable("System.Windows.Controls.EditBox");

local pe_editbox = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_editbox"));
pe_editbox:Property({"class_name", "pe:editbox"});

function pe_editbox:ctor()
	self:SetTabIndex(0);
end

function pe_editbox:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	css.float = css.float or true;

	local _this = self.control;
	if(not _this) then
		_this = EditBox:new():init(parentElem);
		local uiname = self:GetAttributeWithCode("uiname", nil, true);
		if(uiname) then
			_this:SetUIName(uiname)
		end
		self:SetControl(_this);
	else
		_this:SetParent(parentElem);
	end

	_this:SetText(self:GetAttributeWithCode("value", nil, true));
	_this:ApplyCss(css);
	
	_this:SetEmptyText(self:GetAttributeWithCode("EmptyText", nil, true));
	_this:SetTooltip(self:GetAttributeWithCode("tooltip", nil, true));
	
	_this:setMoveViewWhenAttachWithIME(self:GetBool("MoveViewWhenAttachWithIME", false));

	local type = self:GetAttributeWithCode("type", nil, true);
	_this:setEncrypted(type == "password");

	_this:Connect("textChanged", self, self.OnTextChanged, "UniqueConnection")

	self:UpdateGetters();

	pe_editbox._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css)
end

function pe_editbox:OnAddGetter(name, func, bindingContext)
	if(name == "value") then
		bindingContext:AddGetter(self.control, "SetText", func)
	elseif(name == "tooltip") then
		bindingContext:AddGetter(self.control, "SetTooltip", func)
	end
end


function pe_editbox:isPasswordButton()
	local type = self:GetAttributeWithCode("type", nil, true);
	if(type == "password") then
		return true;
	end
	return false;
end


function pe_editbox:OnLoadComponentAfterChild(parentElem, parentLayout, css)
	local beFocus = self:GetBool("autofocus");
	if(beFocus) then
		local ctrl = self:GetControl();
		if(ctrl) then
			ctrl:setFocus("autofocus");
		end
	end
end

function pe_editbox:OnTextChanged(actualText)
	local code, bindingContext = self:GetSetter("value")
	if(code) then
		bindingContext:SetValue(code, actualText)
	end

	local onchange = self:GetString("onchange");
	if(onchange) then
		local result = self:DoPageEvent(onchange, actualText, self);
		return result;
	end
end

function pe_editbox:OnAfterChildLayout(layout, left, top, right, bottom)
	if(self.control) then
		self.control:setGeometry(left, top, right-left, bottom-top);
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
	end
end

function pe_editbox:SetValue(value)
	if(self.control) then
		return self.control:SetText(value);
	end
end