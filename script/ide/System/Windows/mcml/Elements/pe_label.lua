--[[
Title: pe_label
Author(s): LiPeng
Date: 2017/10/3
Desc: it handles HTML tags of <label> . 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_label.lua");
System.Windows.mcml.Elements.pe_label:RegisterAs("label","pe:label");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Label.lua");
local Label = commonlib.gettable("System.Windows.Controls.Label");
local pe_label = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_label"));
pe_label:Property({"class_name", "pe:label"});

function pe_label:ctor()
end

function pe_label:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	css.float = css.float or true;

	local _this = self.control;
	if(not _this) then
		_this = Label:new():init(parentElem);
		self:SetControl(_this);
	end
	_this:ApplyCss(css);
	_this:SetText(self:GetAttributeWithCode("value", nil, true));
	_this:SetTooltip(self:GetAttributeWithCode("tooltip", nil, true));
end

-- get value: it is usually one of the editor tag, such as <input>
function pe_label:GetValue()
	return self:GetAttribute("value");
end

-- set value: it is usually one of the editor tag, such as <input>
function pe_label:SetValue(value)
	self:SetAttribute("value", value);
	if(self.control) then
		return self.control:SetText(value);
	end
end

function pe_label:OnBeforeChildLayout(layout)
	if(self.control) then
		local css = self:GetStyle();
		local width, height;
		if(not css.width) then
			width = self.control:CalculateTextWidth();
		end
		if(not css.height) then
			height = self.control:CalculateTextHeight();
		end
		if(width or height) then
			layout:AddObject(width or 0, height or 0);
		end
	end
end

function pe_label:OnAfterChildLayout(layout, left, top, right, bottom)
	if(self.control) then
		self.control:setGeometry(left, top, right-left, bottom-top);
	end
end

