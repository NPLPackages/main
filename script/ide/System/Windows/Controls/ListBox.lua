--[[
Title: ListBox
Author(s): LiPeng
Date: 2017/10/3
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/ListBox.lua");
local ListBox = commonlib.gettable("System.Windows.Controls.ListBox");
------------------------------------------------------------

test
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Window.lua");
NPL.load("(gl)script/ide/System/test/test_Windows.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ListBox.lua");
local ListBox = commonlib.gettable("System.Windows.Controls.ListBox");
local Window = commonlib.gettable("System.Windows.Window")	
local test_Windows = commonlib.gettable("System.Core.Test.test_Windows");

local window = Window:new();
local listbox = ListBox:new():init(window);
listbox:setSelectMultiple(true);
--listbox:SetRows(2);
listbox:setGeometry(100, 100, 200, 20 * 5);
listbox:AddItem("我是1");
listbox:AddItem("我是12");
listbox:AddItem("我是123");
listbox:AddItem("我是1234");
listbox:AddItem("我是12345");
listbox:AddItem("我是123456");
listbox:AddItem("我是1234567");
listbox:AddItem("我是12345678");
listbox:AddItem("我是123456789");
listbox:AddItem("我是12345678910");
--listbox:SetBackgroundColor("#cccccc");

window:Show("my_window", nil, "_mt", 0,0, 600, 600);

test_Windows.windows = {window};
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/Primitives/ScrollAreaBase.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollBar.lua");
NPL.load("(gl)script/ide/math/Point.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ListView.lua");
local ListView = commonlib.gettable("System.Windows.Controls.ListView");
local Point = commonlib.gettable("mathlib.Point");
local Rect = commonlib.gettable("mathlib.Rect");
local UniString = commonlib.gettable("System.Core.UniString");
local Application = commonlib.gettable("System.Windows.Application");
local FocusPolicy = commonlib.gettable("System.Core.Namespace.FocusPolicy");
local ScrollBar = commonlib.gettable("System.Windows.Controls.ScrollBar");

local ListBox = commonlib.inherit(commonlib.gettable("System.Windows.Controls.Primitives.ScrollAreaBase"), commonlib.gettable("System.Windows.Controls.ListBox"));
ListBox:Property("Name", "ListBox");

ListBox:Property({"Background", "", auto=true});
ListBox:Property({"BackgroundColor", "#cccccc", auto=true});
ListBox:Property({"SelectedBackgroundColor", "#00006680", auto=true})
ListBox:Property({"Font", "System;14;norm", auto=true})
ListBox:Property({"Scale", nil, "GetScale", "SetScale", auto=true})
ListBox:Property({"horizontalMargin", 0});
ListBox:Property({"leftTextMargin", 2});
ListBox:Property({"topTextMargin", 2});
ListBox:Property({"rightTextMargin", 2});
ListBox:Property({"bottomTextMargin", 2});
--ListBox:Property({"m_readOnly", false, "  ", "setReadOnly"})
--ListBox:Property({"rows", nil, "GetRows", "SetRows"})
ListBox:Property({"lineWrap", nil, "GetLineWrap", "SetLineWrap", auto=true})
ListBox:Property({"ItemHeight", 20, "GetItemHeight", "SetItemHeight"})

ListBox:Property({"SliderSize", 16, auto=true});

--ListBox:Signal("resetInputContext");
ListBox:Signal("selectionChanged");
ListBox:Signal("clicked",function(index, value, text) end);
--ListBox:Signal("accepted");
--ListBox:Signal("editingFinished");
--ListBox:Signal("updateNeeded");


function ListBox:ctor()
--	self:setFocusPolicy(FocusPolicy.StrongFocus);
--	self:setAttribute("WA_InputMethodEnabled");
--	self:setMouseTracking(true);
end

--function ListBox:init(parent)
--	ListBox._super.init(self, parent);
--
--	return self;
--end

function ListBox:initViewport()
	self.viewport = ListView:new():init(self);
end

function ListBox:selectItem(index)
	if(self.viewport) then
		self.viewport:SelectItem(index);
	end
end

function ListBox:SetValue(value)
	if(self.viewport) then
		self.viewport:SetValue(value);
	end
end

function ListBox:setSelectMultiple(value)
	if(self.viewport) then
		self.viewport:SetSelectMultiple(value);
	end
end

function ListBox:reset()

end

function ListBox:GetMaxWidth()
	if(self.viewport) then
		local w = self.viewport:GetRealWidth();
		local row = math.ceil(self:height()/self.ItemHeight);
		if(#self.viewport.items > row) then
			w = w + self.SliderSize;
		end
		return w;
	end
end

function ListBox:SetItemHeight(value)
	self.ItemHeight = value;
	if(self.viewport) then
		self.viewport:SetLineHeight(value);
	end
end

function ListBox:GetItemHeight()
	return self.ItemHeight;
end

function ListBox:SetRow(num)
	local height = num * self.ItemHeight;
	self:setHeight(height);
end

function ListBox:SetSize(num)
	self:SetRow(num);
end

function ListBox:clear()
	if(self.viewport) then
		self.viewport:clear();
	end
end

function ListBox:Size()
	if(self.viewport) then
		return #self.viewport.items;
	end
end

function ListBox:SetPosition(x, y)
	self:setGeometry(x, y, 200, 20 * 5);
end

function ListBox:ViewPort()
	if(not self.viewport) then
--		local x = self.leftTextMargin;
--		local y = self.topTextMargin;
--		local w = self:width() - self.leftTextMargin;
--		local h = self:height() - self.topTextMargin;
		local x = 0;
		local y = 0;
		local w = self:width();
		local h = self:height();
		self.viewport = Rect:new():init(x, y, w, h);
	end
	return self.viewport;
end

function ListBox:AddItems(items)
	for i = 1,#items do
		self:AddItem(items[i]);
	end
end

function ListBox:AddItem(text)
	self.viewport:AddItem(text);
end

function ListBox:RemoveItem(index)
	self.viewport:RemoveItem(index);
end

function ListBox:contains(x,y)
	return self:rect():contains(x,y);
end

function ListBox:updateViewportPos()
	self.viewport:updatePos(self.hscroll, self.vscroll);
end

function ListBox:GetRow()
	return math.floor(self:ViewRegion():height()/self.viewport:GetLineHeight());
end

function ListBox:emitclicked()
	local index = self.viewport.selectIndex;
	local value = self.viewport:GetLineValue(index);
	local text = tostring(self.viewport:GetLineText(index));
	self:clicked(index, value, text);
end

function ListBox:selectIndex()
	if(self.viewport) then
		return self.viewport.selectIndex;
	end
end

function ListBox:paintEvent(painter)
	ListBox._super.paintEvent(self, painter);
end

function ListBox:ApplyCss(css)
	ListBox._super.ApplyCss(self, css);
	self:SetItemHeight(css:ComputedLineHeight());
	if(self.viewport) then
		self.viewport:ApplyCss(css);
	end
end

function ListBox:SetTextMargin(left, top, right, bottom)
	self.leftTextMargin = left or self.leftTextMargin;
	self.topTextMargin = top or self.topTextMargin;
	self.rightTextMargin = right or self.rightTextMargin;
	self.bottomTextMargin = bottom or self.bottomTextMargin;
end