--[[
Title: div element
Author(s): LiXizhi
Date: 2015/4/27
Desc: div element
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_div.lua");
System.Windows.mcml.Elements.pe_div:RegisterAs("pe:mcml", "div", "pe:div");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollAreaForPage.lua");
local ScrollAreaForPage = commonlib.gettable("System.Windows.Controls.ScrollAreaForPage");
local PageElement = commonlib.gettable("System.Windows.mcml.PageElement");

local pe_div = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_div"));
pe_div:Property({"class_name", "pe:div"});

function pe_div:ctor()
	
end

function pe_div:CreateControl()
	local parentElem = self:GetParentControl();
	local _this = ScrollAreaForPage:new():init(parentElem);
	self:SetControl(_this);
end

function pe_div:OnClick()
	local bindingContext;
	local onclick = self.onclickscript or self:GetAttributeWithCode("onclick",nil,true);
	if(onclick == "")then
		onclick = nil;
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
			result = self:DoPageEvent(onclick, self.buttonName, self)
		end
	end

	local onclick_for = self:GetAttribute("for");
	if(onclick_for == "") then
		onclick_for = nil;
	end
	if(onclick_for) then
		if(type(onclick_for) == "string") then
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
		elseif(type(onclick_for) == "table") then
			onclick_for:OnClick();
		end
	end
	return result;
end