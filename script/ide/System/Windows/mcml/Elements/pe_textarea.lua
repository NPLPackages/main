--[[
Title: textarea
Author(s): LiXizhi
Date: 2015/5/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_textarea.lua");
Elements.pe_textarea:RegisterAs("textarea");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/MultiLineEditbox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutTextControlMultiLine.lua");
local LayoutTextControlMultiLine = commonlib.gettable("System.Windows.mcml.layout.LayoutTextControlMultiLine");
local MultiLineEditbox = commonlib.gettable("System.Windows.Controls.MultiLineEditbox");

local pe_textarea = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_textarea"));
pe_textarea:Property({"class_name", "pe:textarea"});

local defaultRows = 2;
local defaultCols = 20;

function pe_textarea:ctor()
	self.m_rows = defaultRows;
	self.m_cols = defaultCols;

	self:SetTabIndex(0);
end

function pe_textarea:ParseMappedAttribute(attrName, value)
	if(attrName == "rows") then
		self.m_rows = tonumber(value) or self.m_rows;
	elseif(attrName == "cols") then
		self.m_cols = tonumber(value) or self.m_cols;
	end
	return pe_textarea._super.ParseMappedAttribute(self, attrName, value)
end

function pe_textarea:ControlClass()
	return MultiLineEditbox;
end

function pe_textarea:CreateControl()
	pe_textarea._super.CreateControl(self);

	local _this = self:GetControl();
	if(_this) then
		_this:ShowLineNumber(self:GetBool("ShowLineNumber",false));
		_this:SetEmptyText(self:GetAttributeWithCode("EmptyText", nil, true));
		_this:SetLanguage(self:GetAttributeWithCode("language", nil, true));
		if(not self:GetBool("InputMethodEnabled", true)) then
			_this:SetInputMethodEnabled(false);
		end

		_this:setReadOnly(self:GetBool("ReadOnly",false));
	end
end

-- get UI value: get the value on the UI object with current node
-- @param instName: the page instance name. 
function pe_textarea:GetUIValue(pageInstName)
	if(self.control) then
		return self.control:GetText();
	end
end

-- set UI value: set the value on the UI object with current node
function pe_textarea:SetUIValue(pageInstName, value)
	if(self.control) then
		return self.control:SetText(value);
	end
end

function pe_textarea:GetValue()
	if(self.control) then
		return self.control:GetText();
	end
end

function pe_textarea:SetValue(value)
	if(self.control) then
		return self.control:SetText(value);
	end
end

function pe_textarea:SetFocus()
	if(self.control and self.control.viewport) then
		self.control.viewport:setFocus("TabFocusReason");
	end
end

function pe_textarea:TabLostFocus()
	local tabLostFocus = nil;
	local showLineNumber = self:GetBool("ShowLineNumber",false);
	local language = self:GetAttributeWithCode("language", nil, true);
	if(showLineNumber or language) then
		tabLostFocus = false;
	end

	if(tabLostFocus == nil) then
		tabLostFocus = self:GetAttributeWithCode("TabLostFocus", true, true);
	end
	if(type(tabLostFocus) == "string") then
		if(tabLostFocus == "true") then
			tabLostFocus = true;
		elseif(tabLostFocus == "false") then
			tabLostFocus = false;
		end
	end
	return tabLostFocus;
end

function pe_textarea:Rows()
	return self.m_rows;
end

function pe_textarea:Cols()
	return self.m_cols;
end

function pe_textarea:CreateLayoutObject(arena, style)
	return LayoutTextControlMultiLine:new():init(self);
end