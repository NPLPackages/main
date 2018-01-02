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
NPL.load("(gl)script/ide/System/Windows/Shapes/Rectangle.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
local Button = commonlib.gettable("System.Windows.Controls.Button");
local Rectangle = commonlib.gettable("System.Windows.Shapes.Rectangle");

local pe_div = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_div"));
pe_div:Property({"class_name", "pe:div"});

function pe_div:ctor()
	
end

function pe_div:LoadComponent(parentElem, parentLayout, style)
	local ignore_onclick, ignore_tooltip, ignore_background;
	local onclick, ontouch;
	local onclick_for;
	if(not ignore_onclick) then
		onclick = self:GetString("onclick");
		if(onclick == "") then
			onclick = nil;
		end
		onclick_for = self:GetAttribute("for");
		if(onclick_for == "") then
			onclick_for = nil;
		end
		ontouch = self:GetString("ontouch");
		if(ontouch == "") then
			ontouch = nil;
		end
	end


	local _this = self.control;
	if(not _this) then
		if(onclick_for or onclick or tooltip or ontouch) then
			_this = Button:new():init(parentElem);
			_this:SetPolygonStyle("none");
			self.buttonName = self:GetAttributeWithCode("name",nil,true);
			_this:Connect("clicked", self, self.OnClick, "UniqueConnection");
		else
			_this = Rectangle:new():init(parentElem);
		end

		self:SetControl(_this);
	end

	pe_div._super.LoadComponent(self, _this, parentLayout, style);
end

function pe_div:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
--	local ignore_onclick, ignore_tooltip, ignore_background;
--	local onclick, ontouch;
--	local onclick_for;
--	if(not ignore_onclick) then
--		onclick = self:GetString("onclick");
--		if(onclick == "") then
--			onclick = nil;
--		end
--		onclick_for = self:GetString("for");
--		if(onclick_for == "") then
--			onclick_for = nil;
--		end
--		ontouch = self:GetString("ontouch");
--		if(ontouch == "") then
--			ontouch = nil;
--		end
--	end
--	local tooltip
--	if(not ignore_tooltip) then
--		tooltip = self:GetAttributeWithCode("tooltip",nil,true);
--		if(tooltip == "") then
--			tooltip = nil;
--		end
--	end

--	if(css["background-color"] and not ignore_background) then
--		if(not background and not css.background2) then
--			background = "Texture/whitedot.png";
--		end
--	end

	if(not css.background and not css.background2) then
		if(css["background-color"]) then
			css.background = "Texture/whitedot.png";	
		else
			css["background-color"] = "#ffffff00";
		end
	end

	local _this = self.control;
	if(_this) then
		_this:SetTooltip(self:GetAttributeWithCode("tooltip", nil, true));
		_this:ApplyCss(css);
	end


--	if(onclick_for or onclick or tooltip or ontouch) then
--		-- if there is onclick event, the inner nodes will not be interactive.
--		local _this = self.control;
--		if(not _this) then
--			_this = Button:new():init(parentElem);
--			self:SetControl(_this);
--			--self.control._page_element = self;
--		end
--		echo("div button");
--		_this:SetTooltip(self:GetAttributeWithCode("tooltip", nil, true));
--		_this:ApplyCss(css);
--		_this:Connect("clicked", self, self.OnClick)
--
--		if(css.background and css.background~="") then
--			if(css["background-rotation"]) then
--				_this:SetRotation(tonumber(css["background-rotation"]));
--			end
--			if(css["background-repeat"] == "repeat") then
--				_this:SetRotation("UVWrappingEnabled", true);
--			end
--		end
--		local zorder = self:GetNumber("zorder");
--		if(zorder) then
--			_this.zorder = zorder;
--		end
--	else
--		local _this = self.control;
--		if(not _this) then
--			_this = Rectangle:new():init(parentElem);
--			_this:SetBackground("Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;3 3 3 3:1 1 1 1");
--			self:SetControl(_this);
--		end
--		if(css.background) then
--			_this:SetTooltip(self:GetAttributeWithCode("tooltip", nil, true));
--			_this:ApplyCss(css);
--			if(css.background and css.background~="") then
--				if(css["background-rotation"]) then
--					_this:SetRotation(tonumber(css["background-rotation"]));
--				end
--				if(css["background-repeat"] == "repeat") then
--					_this:SetRotation("UVWrappingEnabled", true);
--				end
--			end
--			local zorder = self:GetNumber("zorder");
--			if(zorder) then
--				_this.zorder = zorder;
--			end
--		else
--			_this:SetBackgroundColor();
--		end
--	end
end

function pe_div:OnBeforeChildLayout(layout)
	if(#self ~= 0) then
		local myLayout = layout:new();
		local css = self:GetStyle();
		local width, height = layout:GetPreferredSize();
		local padding_left, padding_top = css:padding_left(),css:padding_top();
		myLayout:reset(padding_left,padding_top,width+padding_left, height+padding_top);
		self:UpdateChildLayout(myLayout);
		width, height = myLayout:GetUsedSize();
		width = width - padding_left;
		height = height - padding_top;
		layout:AddObject(width, height);
	end
	return true;
end

-- virtual function: 
-- after child node layout is updated
function pe_div:OnAfterChildLayout(layout, left, top, right, bottom)
	if(self.control) then
		self.control:setGeometry(left, top, right-left, bottom-top);
	end
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