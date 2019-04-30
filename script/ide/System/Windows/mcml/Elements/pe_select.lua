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
NPL.load("(gl)script/ide/System/Windows/Controls/ListBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutMenuList.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutListBox.lua");
local LayoutListBox = commonlib.gettable("System.Windows.mcml.layout.LayoutListBox");
local LayoutMenuList = commonlib.gettable("System.Windows.mcml.layout.LayoutMenuList");
local UniString = commonlib.gettable("System.Core.UniString");
local DropdownListbox = commonlib.gettable("System.Windows.Controls.DropdownListbox");
local ListBox = commonlib.gettable("System.Windows.Controls.ListBox");

local pe_select = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_select"));
pe_select:Property({"class_name", "pe:select"});

function pe_select:ctor()
	self.m_size = 1;
	--self.m_multiple = false;
	--self.m_listItems = commonlib.vector:new();
	self.items = nil;
end

function pe_select:Size()
	return self.m_size;
end

function pe_select:Multiple()
	--return self.m_multiple;
	return self.m_size > 1
end

function pe_select:UsesMenuList()
	--return not self.m_multiple and self.m_size <= 1;
	return self.m_size == 1;
end

function pe_select:ParseMappedAttribute(attrName, value)
	if(attrName == "size") then
		self.m_size = self:GetNumber("size", 1);
--		local oldSize = self.m_size;
--		local size =  self:GetNumber("size", 1);
	else
		pe_select._super.ParseMappedAttribute(self, attrName, value)
	end
end

--RenderObject* HTMLSelectElement::createRenderer(RenderArena* arena, RenderStyle*)
function pe_select:CreateLayoutObject(arena, style)
    if (self:UsesMenuList()) then
        return LayoutMenuList:new():init(self, style);
	end
	return LayoutListBox:new():init(self, style);
end

function pe_select:CreateControl()
	local rows = self.m_size;

	local parentElem = self:GetParentControl();
	local _this;

	if(rows == 1) then
		_this = DropdownListbox:new():init(parentElem);
	else
		_this = ListBox:new():init(parentElem);
	end
	self:SetControl(_this);

	self:DataBind();

	_this:SetTooltip(self:GetAttributeWithCode("tooltip", nil, true));

	_this:Connect("onselect", self, self.OnSelect, "UniqueConnection")
end

function pe_select:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	self:DataBind();

	pe_select._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css)
end

function pe_select:DataBind()
	if(not self.items) then
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

		self.items = items;


	end

	local ctl = self.control;
	if(ctl) then
		ctl:AddItems(self.items or {});
	end
end

function pe_select:ListItems()
	return self.items;
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

function pe_select:SelectedIndex()
	if(self.control) then
		return self.control:SelectedIndex();
	end
	return -1;
end

function pe_select:SetSelectedIndex(index)
	if(self.control) then
		return self.control:selectItem(index);
	end
end

function pe_select:SetValue(value)
	if(not self.items) then
		return;
	end
	for i = 1, #self.items do
		if(value == self.items[i]) then
			self:SetSelectedIndex(i);
			break;
		end
	end
end

function pe_select:OnSelect()
end