--[[
Title: DropdownListbox
Author(s): LiPeng
Date: 2017/10/3
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/DropdownListbox.lua");
local DropdownListbox = commonlib.gettable("System.Windows.Controls.DropdownListbox");
------------------------------------------------------------

test
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Window.lua");
NPL.load("(gl)script/ide/System/test/test_Windows.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/DropdownListbox.lua");
local Window = commonlib.gettable("System.Windows.Window")	
local test_Windows = commonlib.gettable("System.Core.Test.test_Windows");
local DropdownListbox = commonlib.gettable("System.Windows.Controls.DropdownListbox");
local window = Window:new();
local DropdownListbox = DropdownListbox:new():init(window);

local items = {"test1","test2","test3","test4","test5","test6","test7","test8","test7","test10"};
DropdownListbox:AddItems(items);
DropdownListbox:SetMaxVisibleItems(5);
--local items = {"test1","test2"};

DropdownListbox:setGeometry(20, 20, 60, 20);
window:Show("my_window", nil, "_mt", 0,0, 600, 600);
test_Windows.windows = {window};
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ListBox.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/EditBox.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
local ListBox = commonlib.gettable("System.Windows.Controls.ListBox");
local EditBox = commonlib.gettable("System.Windows.Controls.EditBox");
--local Rect = commonlib.gettable("mathlib.Rect");
local Button = commonlib.gettable("System.Windows.Controls.Button");
local DropdownListbox = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.Controls.DropdownListbox"));
DropdownListbox:Property("Name", "DropdownListbox");

DropdownListbox:Property({"maxVisibleItems", 10, "GetMaxVisibleItems", "SetMaxVisibleItems", auto=true});
DropdownListbox:Property({"value", nil, "GetValue", "SetValue", auto=true});
DropdownListbox:Property({"text", nil, "GetText"});
DropdownListbox:Property({"Font", "System;14;norm", auto=true})
DropdownListbox:Property({"Color", "#000000", auto=true})
DropdownListbox:Property({"Scale", nil, "GetScale", "SetScale", auto=true})

DropdownListbox:Property({"ButtonWidth", 16, auto=true});

DropdownListbox:Property({"EditHeight", 20, auto=true});

--DropdownListbox:Property({"ButtonBackground", "Texture/Aries/Common/ThemeKid/btn_thick_hl_32bits.png:1 1 1 1",auto=true});


function DropdownListbox:ctor()
	self.editbox = nil;
	self.button = nil;
	self.listbox = nil;
	self.index = nil;

	self.needUpdateControl = true;
end

function DropdownListbox:init(parent)
	DropdownListbox._super.init(self,parent);

	self:initEditBox();
	self:initButton();
	self:initListBox();

	return self;
end

function DropdownListbox:selectItem(index)
	if(self.listbox) then
		self.listbox:selectItem(index);
	end
end

function DropdownListbox:initEditBox()
	self.editbox = EditBox:new():init(self);
	--self.editbox:SetleftTextMargin(4);
	self.editbox:setReadOnly(true);
	self.editbox:Connect("editingFinished",function(event)
		self:SetValue(value);
	end);
end

function DropdownListbox:GetValue()
	return self.value;
end

function DropdownListbox:SetValue(value)
	if(self.listbox) then
		self.listbox:SetValue(value);
	end
end

function DropdownListbox:GetText()
	return self.text;
end

function DropdownListbox:setGeometry(ax, ay, aw, ah)
	local w = self:GetAdaptiveWidth();
	w = if_else(aw > w, aw, w);
	local h = ah;
	if(self.listbox and not self.listbox:isHidden()) then
		h = h + self:GetListBoxHeight();
	end
	DropdownListbox._super.setGeometry(self, ax, ay, w, h);
end

function DropdownListbox:initButton()
	self.button = Button:new():init(self);
	self.button:SetPolygonStyle("narrow");
	self.button:SetDirection("down");
	self.button:SetBackgroundColor("#ff0000");
	self.button:Connect("clicked", function (event)
		if(self.listbox:isHidden()) then
			self.listbox:show();
		else
			self.listbox:hide();
		end
	end)
end

function DropdownListbox:initListBox()
	self.listbox = ListBox:new():init(self);
	self.listbox:SetSize(self.maxVisibleItems);
	self.listbox:Connect("clicked", function (index, value, text)
		self.listbox:hide();
		self.index = index;
		self.value = value or text;
		self.text = text;
		self.editbox:SetText(text or "");
	end)
	self.listbox:hide();
end

function DropdownListbox:AddItem(item)
	self.listbox:AddItem(item);
end

function DropdownListbox:AddItems(items)
	self.listbox:AddItems(items);
end

function DropdownListbox:SetMaxVisibleItems(value)
	if(self.maxVisibleItems == value) then
		return;
	end
	self.maxVisibleItems = value;
	self.listbox:SetSize(value);
end

function DropdownListbox:mousePressEvent(e)
	if(e:button() == "left") then
		if(self.editbox:isReadOnly() and self.editbox:rect():contains(e:pos())) then
			if(self.listbox:isHidden()) then
				self.listbox:show();
			else
				self.listbox:hide();
			end
			e:accept();			
			return;
		end
	end
	e:ignore();
end

function DropdownListbox:GetAdaptiveWidth()
	return self.listbox:GetMaxWidth() + self.ButtonWidth;
end

function DropdownListbox:GetAdaptiveHeight()
	local size = self.listbox:Size();
	if(size > self.maxVisibleItems) then
		size = self.maxVisibleItems;
	end

	return self.EditHeight + self.listbox:GetItemHeight() * size;
end

function DropdownListbox:GetPreferredSize()
	return self:GetAdaptiveWidth(), self.EditHeight;
end

function DropdownListbox:GetListBoxHeight()
	local size = self.listbox:Size();
	if(size > self.maxVisibleItems) then
		size = self.maxVisibleItems;
	end
	return self.listbox:GetItemHeight() * size;
end

function DropdownListbox:UpdateControls()
	if(self.needUpdateControl) then
--		echo({0, 0, self:width(), self.EditHeight});
		
		--self.editbox:SetText(tostring(self.listbox:GetValue() or ""));

		

		local size = self.listbox:Size();
		if(size > self.maxVisibleItems) then
			size = self.maxVisibleItems;
		end

		local listbox_w, listbox_h = self:GetAdaptiveWidth(), self.listbox:GetItemHeight() * size;
		self.listbox:setGeometry(0, self.EditHeight, listbox_w, listbox_h);

		self.editbox:setGeometry(0, 0, listbox_w, self.EditHeight);

		self:resize(listbox_w, self:height() + listbox_h);

		self.button:setGeometry(self:width() - self.ButtonWidth, 0, self.ButtonWidth, self.EditHeight);
	end
	self.needUpdateControl = false;
end

function DropdownListbox:paintEvent(painter)
	self:UpdateControls();
end

