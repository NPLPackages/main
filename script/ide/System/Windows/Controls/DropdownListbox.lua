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
NPL.load("(gl)script/ide/System/Windows/UIStyleElement.lua");
NPL.load("(gl)script/ide/System/Core/UniString.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/EditBox.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
local UniString = commonlib.gettable("System.Core.UniString");
local EditBox = commonlib.gettable("System.Windows.Controls.EditBox");
--local Rect = commonlib.gettable("mathlib.Rect");
local Button = commonlib.gettable("System.Windows.Controls.Button");
local FocusPolicy = commonlib.gettable("System.Core.Namespace.FocusPolicy");

local DropdownListbox = commonlib.inherit(commonlib.gettable("System.Windows.UIStyleElement"), commonlib.gettable("System.Windows.Controls.DropdownListbox"));
DropdownListbox:Property("Name", "DropdownListbox");

DropdownListbox:Property({"BackgroundColor", "#cccccc", auto=true});
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
	self.selectedIndex = nil;

	self.needUpdateControl = true;

	self.items = {};
end

function DropdownListbox:init(parent)
	DropdownListbox._super.init(self,parent);

	self:initEditBox();
	self:initButton();
	self:initListBox();

	return self;
end

function DropdownListbox:SelectedIndex()
	return self.selectedIndex;
end

function DropdownListbox:selectItem(index)
	if(self.selectedIndex == index) then
		return;
	end
	self.selectedIndex = index;
	if(self.items) then
		self.text = self.items[index]["text"];
		self.value = self.items[index]["value"] or self.text;
	end
--	if(self.listbox) then
--		self.listbox:selectItem(index);
--	end
end

function DropdownListbox:initEditBox()
	self.editbox = EditBox:new():init(self);
	self.editbox:setFocusPolicy(FocusPolicy.NoFocus);
	self.editbox:SetBackgroundColor("#00000000");
	self.editbox:setReadOnly(true);
	self.editbox:Connect("editingFinished",function(event)
		self:SetValue(value);
	end);
end

function DropdownListbox:GetValue()
	return self.value;
end

--function DropdownListbox:SetValue(value)
--	for i = 1, #self.items do
--		if(value == self.items[i]["value"]) then
--			self:selectItem(i);
--			break;
--		end
--	end
--end

function DropdownListbox:GetText()
	return self.text;
end

function DropdownListbox:setGeometry(ax, ay, aw, ah)
	aw = aw or self:GetAdaptiveWidth();
	ah = ah or self:GetAdaptiveHeight();
	DropdownListbox._super.setGeometry(self, ax, ay, aw, ah);
end

function DropdownListbox:initButton()
	self.button = Button:new():init(self);
	self.button:setFocusPolicy(FocusPolicy.NoFocus);
	self.button:SetPolygonStyle("narrow");
	self.button:SetDirection("down");
	self.button:SetBackgroundColor("#ff0000");
	self.button:Connect("pressed", function ()
		self:Click();
	end)
end

function DropdownListbox:initListBox()
--	self.listbox = ListBox:new():init(self);
--	self.listbox:SetSize(self.maxVisibleItems);
	self.listbox = self:GetWindow():PopupMenu();
	self.listbox:Connect("clicked", function (index, value, text)
		self.listbox:hide();
		self.selectedIndex = index;
		self.value = value or text;
		self.text = text;
		self.editbox:SetText(text or "");
	end)
	--self.listbox:hide();
end

function DropdownListbox:Items()
	return self.items;
end

function DropdownListbox:AddItem(item)
	if(type(item) == "string") then
		local uniText = UniString:new(item);
		item = {
			text = uniText,
			selected = false,
		}
	end
	self.items[#self.items + 1] = item;
	self.needUpdateControl = true;
	--self.listbox:AddItem(item);
end

function DropdownListbox:AddItems(items)
	for i = 1,#items do
		self:AddItem(items[i]);
	end
	--self.listbox:AddItems(items);
end

function DropdownListbox:SetMaxVisibleItems(value)
	if(self.maxVisibleItems == value) then
		return;
	end
	self.maxVisibleItems = value;
end

function DropdownListbox:Click()
	self.listbox:Open(self, "SelectPressedFocusReason");
end

function DropdownListbox:mousePressEvent(e)
	if(e:button() == "left") then
		if(self.editbox:isReadOnly() and self.editbox:rect():contains(e:pos())) then
			self:Click();
			e:accept();			
			return;
		end
	end
	e:ignore();
end

function DropdownListbox:GetAdaptiveWidth()
	local items = self.items;
	local font = self:GetFont();
	local width = 0;
	for i = 1, #items do
		local text = items[i]["text"];
		width = math.max(width, text:GetWidth(font));
	end
	return width + self:GetButtonWidth();
	--return self.listbox:GetMaxWidth();
end

function DropdownListbox:GetAdaptiveHeight()
--	local size = self.listbox:Size();
--	if(size > self.maxVisibleItems) then
--		size = self.maxVisibleItems;
--	end
--
--	return self.EditHeight + self.listbox:GetItemHeight() * size;
	return self.EditHeight;
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
		if(not self.selectedIndex) then
			self:selectItem(1);
		end

		local textWidth = self:width() - self.ButtonWidth;

		self.editbox:setGeometry(0, 0, textWidth, self:height());
		self.editbox:SetText(self:GetText():GetText());

		self.button:setGeometry(textWidth, 0, self.ButtonWidth, self:height());	
	end
	self.needUpdateControl = false;
end

function DropdownListbox:paintEvent(painter)
	self:UpdateControls();
	DropdownListbox._super.paintEvent(self, painter);
end

function DropdownListbox:SetTextMargin(left, top, right, bottom)
	if(self.editbox) then
		self.editbox:SetTextMargin(left, top, right, bottom);
	end
	if(self.listbox) then
		self.listbox:SetTextMargin(left, top, right, bottom);
	end
end

function DropdownListbox:ApplyCss(css)
	DropdownListbox._super.ApplyCss(self, css);
	if(self.listbox) then
		self.listbox:ApplyCss(css);
	end
	if(self.editbox) then
		self.editbox:ApplyCss(css);
		self.editbox:SetBorders(nil);
	end
end