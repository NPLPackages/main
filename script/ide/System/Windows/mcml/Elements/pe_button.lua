--[[
Title: button
Author(s): LiXizhi
Date: 2015/5/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_button.lua");
Elements.pe_button:RegisterAs("button");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutButton.lua");
local LayoutButton = commonlib.gettable("System.Windows.mcml.layout.LayoutButton");
local Button = commonlib.gettable("System.Windows.Controls.Button");

local pe_button = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_button"));
pe_button:Property({"class_name", "pe:button"});

function pe_button:ctor()
--	self.value = ""
	self:SetTabIndex(0);
end

--function pe_button:ParseMappedAttribute(attrName, value)
--	if(attrName == "value") then
--		self.value = value;
--	end
--	return pe_button._super.ParseMappedAttribute(self, attrName, value)
--end

function pe_button:ControlClass()
	return Button;
end

function pe_button:CreateControl()
	pe_button._super.CreateControl(self);

	local _this = self:GetControl();
	if(_this) then
		local polygonStyle = self:GetAttributeWithCode("polygonStyle", nil, true);
		local direction = self:GetAttributeWithCode("direction", nil, true);
		local type = self:GetAttributeWithCode("type", nil, true);
		if(type == "narrow") then
			polygonStyle = polygonStyle or "narrow";
		end
		_this:SetPolygonStyle(polygonStyle);
		_this:SetDirection(direction);

		self.buttonName = self:GetAttributeWithCode("name",nil,true); -- touch name
		_this:Connect("clicked", self, self.OnClick, "UniqueConnection")
	end
end

function pe_button:SetAttribute(attrName, value, notifyChanged)
	if(attrName == "value") then
		if(self:GetAttributeWithCode("value",nil,true) == value) then
			return;
		end
		pe_button._super.SetAttribute(self, attrName, value, notifyChanged)
		if (self:Renderer()) then
			self:Renderer():SetText(value);
			self:SetNeedsStyleRecalc();
		end
		return;
	end
	pe_button._super.SetAttribute(self, attrName, value, notifyChanged)
end

function pe_button:SetValue(value)
	self:SetAttribute("value", value);
end

function pe_button:GetValue()
	return self:GetAttributeWithCode("value",nil,true);
end

function pe_button:OnClick()
	local bindingContext;
	local onclick = self.onclickscript or self:GetAttributeWithCode("onclick",nil,true);
	if(onclick == "")then
		onclick = nil;
	end
	local onclick_for = self:GetString("for");
	if(onclick_for == "") then
		onclick_for = nil;
	end
	local result;
	if(onclick) then
		local btnType = self:GetString("type");
		if( btnType=="submit") then
			-- user clicks the normal button. 
			-- the callback function format is function(buttonName, values, bindingContext, self) end
			local values;
			--if(bindingContext) then
				--bindingContext:UpdateControlsToData();
				--values = bindingContext.values
			--end	
			result = self:DoPageEvent(onclick, self.buttonName, self);
		else
			-- user clicks the button, yet without form info
			-- the callback function format is function(buttonName, self) end
			result = self:DoPageEvent(onclick, self:GetAttribute("name"), self)
		end
	end
	if(onclick_for) then
		-- call the OnClick method of the mcml control by id or name
		local pageCtrl = self:GetPageCtrl();
		if(pageCtrl) then
			local target_node = pageCtrl:GetNodeByID(onclick_for);
			if(target_node) then
				if(target_node ~= self) then
					target_node:InvokeMethod("HandleClickFor", self, bindingContext);
				else
					LOG.std(nil, "warn", "mcml", "the for target of %s can not be itself", onclick_for);	
				end
			else
				LOG.std(nil, "warn", "mcml", "the for target of %s is not found in the page", onclick_for);
			end
		end
	end
	return result;
end

function pe_button:ValueWithDefault()
	return self:GetValue()
end

function pe_button:CreateLayoutObject(arena, style)
	return LayoutButton:new():init(self);
end

function pe_button:attachLayoutTree()
	pe_button._super.attachLayoutTree(self);
	if (self:Renderer()) then
        self:Renderer():UpdateFromElement();
	end
end