--[[
Title: break row
Author(s): LiPeng
Date: 2017/10/3
Desc: it handles HTML tags of <br> . 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_select.lua");
System.Windows.mcml.Elements.pe_select:RegisterAs("select");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/DropdownListbox.lua");
local UniString = commonlib.gettable("System.Core.UniString");
local DropdownListbox = commonlib.gettable("System.Windows.Controls.DropdownListbox");
local ListBox = commonlib.gettable("System.Windows.Controls.ListBox");
local pe_select = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_select"));
pe_select:Property({"class_name", "pe:select"});

function pe_select:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
--function pe_select:LoadComponent(parentElem, parentLayout, css)
	css.float = css.float or true;

	local margin_left, margin_top, margin_bottom, margin_right = 
		(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
		(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	

	local rows =  self:GetNumber("size",1);

	local _this = self.control;
	if(not _this) then
		if(rows == 1) then
			_this = DropdownListbox:new():init(parentElem);
		else
			_this = ListBox:new():init(parentElem);
		end
		self:SetControl(_this);
	end
	_this:ApplyCss(css);
	--_this:SetText(self:GetAttributeWithCode("value", nil, true));
	_this:SetTooltip(self:GetAttributeWithCode("tooltip", nil, true));

	self:DataBind();
	if(rows == 1) then
		local width, height = _this:GetPreferredSize();
		css.width = width;
		css.height = height;
	end
	
	_this:Connect("onselect", self, self.OnSelect, "UniqueConnection")
end

function pe_select:DataBind()
	local ctl = self.control;
	if(ctl) then
		local items = nil;
		local name, value;
		local value = self:GetAttributeWithCode("value", nil, true);
		if(type(value) == "string") then
			name, value = value:match("^([%w_]+)%s+in%s+([^%s%(]+)");
			if(name and value) then
				items = self:GetScriptValue(value);
			end
		else
			items = self:GetAttributeWithCode("DataSource", nil, true);
			--name = "this";
		end
		if(type(items) == "function") then
			items = arrayValues();
		end

		items = items or {};
		
		for child in self:next("option") do
			local item = {};
			item.value = child:GetAttribute("value",nil);
			item.selected = child:GetAttribute("selected",nil);
			for textNode in child:next() do
				item.text = (item.text or "")..textNode.value;
			end
			items[#items + 1] = item;
		end

		for k,v in ipairs(items) do
			v["text"] = v["text"] or "";
			if(type(v["text"]) == "string") then
				v["text"] = UniString:new(v["text"]);
			end
			v["selected"] = if_else(v["selected"],true,false);
		end

		ctl:AddItems(items or {});
	end
end

function pe_select:GetValue()
	if(self.control) then
		return self.control:GetValue();
	end
end

function pe_select:GetText()
	if(self.control) then
		return self.control:GetText();
	end
end

function pe_select:SetValue(value)
	self:SetAttribute("value", value);
	if(self.control) then
		return self.control:SetValue(value);
	end
end

function pe_select:OnAfterChildLayout(layout, left, top, right, bottom)
	if(self.control) then
		self.control:setGeometry(left, top, right-left, bottom-top);
	end
end

function pe_select:OnSelect()
end