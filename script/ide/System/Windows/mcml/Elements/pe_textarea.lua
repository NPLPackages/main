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
local MultiLineEditbox = commonlib.gettable("System.Windows.Controls.MultiLineEditbox");

local pe_textarea = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_textarea"));
pe_textarea:Property({"class_name", "pe:textarea"});

function pe_textarea:ctor()
	self:SetTabIndex(0);
end

function pe_textarea:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	css.float = css.float or true;

	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	

	local lineheight = 20;
	if(css["line-height"]) then
		lineheight = tonumber(css["line-height"]);
	end
	local height = css.height;
	if(not height) then
		local rows = tonumber(self:GetAttributeWithCode("rows", 10, true));
		height = lineheight * rows;
		css.height = height;
	end
	local _this = self.control;
	if(not _this) then
		_this = MultiLineEditbox:new():init(parentElem);
		local uiname = self:GetAttributeWithCode("uiname", nil, true);
		if(uiname) then
			_this:SetUIName(uiname)
		end
		self:SetControl(_this);
	else
		_this:SetParent(parentElem);
	end

	_this:setMoveViewWhenAttachWithIME(self:GetBool("MoveViewWhenAttachWithIME", false));
	_this:SetAlwaysShowCurLineBackground(self:GetBool("AlwaysShowCurLineBackground", true));
	_this:ShowLineNumber(self:GetBool("ShowLineNumber",false));
	_this:SetEmptyText(self:GetAttributeWithCode("EmptyText", nil, true));
	_this:SetLanguage(self:GetAttributeWithCode("language", nil, true));
	
	_this:ViewPort():SetLineWrap(self:GetBool("LineWrap", false));
	
	if(not self:GetBool("InputMethodEnabled", true)) then
		_this:SetInputMethodEnabled(false);
	end

	_this:ApplyCss(css);
	_this:setReadOnly(self:GetBool("ReadOnly",false));
	local text = self:GetAttributeWithCode("value", nil, true)
	if(text) then
		_this:SetText(text);
	end
	pe_textarea._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css)
end

function pe_textarea:OnAfterChildLayout(layout, left, top, right, bottom)
	if(self.control) then
		self.control:setGeometry(left, top, right-left, bottom-top);
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