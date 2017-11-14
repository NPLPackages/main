--[[
Title: pe_label
Author(s): LiXizhi
Date: 2015/4/29
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
	return self.value;
end

-- set value: it is usually one of the editor tag, such as <input>
function pe_label:SetValue(value)
	self.value = tostring(value);
	if(self.control) then
		return self.control:SetText(self.value);
	end
end

function pe_label:OnAfterChildLayout(layout, left, top, right, bottom)
	if(self.control) then
		local text_width = self.control:CalculateTextWidth();
		local x, y, w, h = left, top, right-left, bottom-top;
		local css = self:GetStyle();
		if(css["text-align"]) then
--			if(css["text-singleline"] == "true") then
--				alignFormat = alignFormat + 32;
--			end
--			if(css["text-noclip"] == "true") then
--				alignFormat = alignFormat + 256;
--			end
--			if(css["text-valign"] == "center") then
--				alignFormat = alignFormat + 4;
--			end
			if(css["text-align"] == "right") then
				if(text_width < w) then
					x = x + w - text_width;
				end
			elseif(css["text-align"] == "center") then
				if(text_width < w) then
					x = x + math.floor((w - text_width)/2);
				end
			end
		end

		self.control:setGeometry(x, y, w, h);
	end
end

