--[[
Title: radio element
Author(s): LiPeng
Date: 2015/4/29
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
end

function pe_radio:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	local default_css = mcml:GetStyleItem(self.class_name);
	css.float = css.float or true;
	css.width = css.width or default_css.iconSize;
	css.height = css.height or default_css.iconSize;
	css["background"] = self:GetAttributeWithCode("UncheckedBG", nil, true) or default_css["background"];
	css["background_checked"] = self:GetAttributeWithCode("CheckedBG", nil, true) or default_css["background_checked"];

	local polygonStyle = self:GetAttributeWithCode("polygonStyle", nil, true);

	local _this = self.control;
	if(not _this) then
		_this = Button:new():init(parentElem);
		_this:SetPolygonStyle(polygonStyle or "radio");
		self:SetControl(_this);
	end
	
	_this:setCheckable(true);
	_this:ApplyCss(css);
	_this:SetText(self:GetAttributeWithCode("Label", nil, true));
	_this:SetTooltip(self:GetAttributeWithCode("tooltip", nil, true));

	local checked = self:GetAttributeWithCode("checked", nil, true);
	if(checked) then
		_this:setChecked(true);
	end

	self.groupName = self:GetAttribute("name") or "_defaultRadioGroup";
	local buttonName = self:GetAttributeWithCode("name",nil,true);
	_this:Connect("clicked", function()
		self:OnClick(buttonName);
	end);
end

function pe_radio:OnClick(buttonName)
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
							ctl:setChecked(false);
							radio:SetAttribute("checked", nil);
						end
					elseif(radio_value == value) then
						is_last_checked = false;
						ctl:setChecked(true);
						radio:SetAttribute("checked", "true");
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
		result = self:DoPageEvent(onclick, buttonName, self);
	end

	return result;
end

-- virtual function: 
-- after child node layout is updated
function pe_radio:OnAfterChildLayout(layout, left, top, right, bottom)
	if(self.control) then
		self.control:setGeometry(left, top, right-left, bottom-top);
	end
end