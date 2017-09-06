--[[
Title: MultiLineEditbox
Author(s): LiXizhi
Date: 2015/4/29
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/MultiLineEditbox.lua");
local MultiLineEditbox = commonlib.gettable("System.Windows.Controls.MultiLineEditbox");
------------------------------------------------------------

test
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Window.lua");
NPL.load("(gl)script/ide/System/test/test_Windows.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/MultiLineEditbox.lua");
local MultiLineEditbox = commonlib.gettable("System.Windows.Controls.MultiLineEditbox");
local Window = commonlib.gettable("System.Windows.Window")	
local test_Windows = commonlib.gettable("System.Core.Test.test_Windows");

local window = Window:new();
local mulLine = MultiLineEditbox:new():init(window);
--mulLine:SetRows(2);
mulLine:setGeometry(100, 100, 200, 20 * 10+10);
mulLine:AddItem("我是第一行");
mulLine:AddItem("我是第二行");
mulLine:AddItem("我是第三行");
mulLine:AddItem("我是第四行");
mulLine:AddItem("我是第五行");
mulLine:AddItem("我是第六行");
mulLine:AddItem("我是第七行");
mulLine:AddItem("我是第八行");
mulLine:AddItem("我是第九行");
mulLine:AddItem("我是第十行");
--mulLine:SetBackgroundColor("#cccccc");

window:Show("my_window", nil, "_mt", 0,0, 600, 600);
test_Windows.windows = {window};
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollArea.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollBar.lua");
NPL.load("(gl)script/ide/math/Point.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/TextControl.lua");
local TextControl = commonlib.gettable("System.Windows.Controls.TextControl");
local Point = commonlib.gettable("mathlib.Point");
local Rect = commonlib.gettable("mathlib.Rect");
local UniString = commonlib.gettable("System.Core.UniString");
local Application = commonlib.gettable("System.Windows.Application");
local FocusPolicy = commonlib.gettable("System.Core.Namespace.FocusPolicy");
local ScrollBar = commonlib.gettable("System.Windows.Controls.ScrollBar");

local MultiLineEditbox = commonlib.inherit(commonlib.gettable("System.Windows.Controls.ScrollArea"), commonlib.gettable("System.Windows.Controls.MultiLineEditbox"));
MultiLineEditbox:Property("Name", "MultiLineEditbox");

MultiLineEditbox:Property({"Background", "", auto=true});
MultiLineEditbox:Property({"BackgroundColor", "#cccccc", auto=true});
MultiLineEditbox:Property({"Color", "#000000", auto=true})
MultiLineEditbox:Property({"CursorColor", "#33333388", auto=true})
MultiLineEditbox:Property({"SelectedBackgroundColor", "#00006680", auto=true})
MultiLineEditbox:Property({"m_cursor", nil, "cursorPosition", "setCursorPosition"})
MultiLineEditbox:Property({"cursorVisible", false, "isCursorVisible", "setCursorVisible"})
MultiLineEditbox:Property({"m_cursorWidth", 2,})
MultiLineEditbox:Property({"m_blinkPeriod", 0, "getCursorBlinkPeriod", "setCursorBlinkPeriod"})
--MultiLineEditbox:Property({"m_readOnly", false, "isReadOnly", "setReadOnly", auto=true})
MultiLineEditbox:Property({"m_echoMode", "Normal", "echoMode", "setEchoMode"})
MultiLineEditbox:Property({"Font", "System;14;norm", auto=true})
MultiLineEditbox:Property({"Scale", nil, "GetScale", "SetScale", auto=true})
MultiLineEditbox:Property({"horizontalMargin", 0});
MultiLineEditbox:Property({"leftTextMargin", 2});
MultiLineEditbox:Property({"topTextMargin", 2});
MultiLineEditbox:Property({"rightTextMargin", 2});
MultiLineEditbox:Property({"bottomTextMargin", 2});
--MultiLineEditbox:Property({"m_readOnly", false, "  ", "setReadOnly"})
--MultiLineEditbox:Property({"m_maxLength", 65535, "getMaxLength", "setMaxLength", auto=true})
--MultiLineEditbox:Property({"rows", nil, "GetRows", "SetRows"})
MultiLineEditbox:Property({"lineWrap", nil, "GetLineWrap", "SetLineWrap", auto=true})
MultiLineEditbox:Property({"ItemHeight",20, auto=true})

MultiLineEditbox:Property({"SliderSize", 16, auto=true});
--MultiLineEditbox:Property({"vSliderWidth", 20, auto=true});
--MultiLineEditbox:Property({"hSliderHeight", 20, auto=true});
--MultiLineEditbox:Property({"vSliderWidth", nil, auto=true});
--MultiLineEditbox:Property({"hSliderHeight", nil, auto=true});

--MultiLineEditbox:Signal("resetInputContext");
MultiLineEditbox:Signal("selectionChanged");
MultiLineEditbox:Signal("cursorPositionChanged", function(oldLine, newLine, oldPos, newPos) end);
MultiLineEditbox:Signal("textChanged");
--MultiLineEditbox:Signal("accepted");
--MultiLineEditbox:Signal("editingFinished");
--MultiLineEditbox:Signal("updateNeeded");


function MultiLineEditbox:ctor()
--	self:setFocusPolicy(FocusPolicy.StrongFocus);
--	self:setAttribute("WA_InputMethodEnabled");
--	self:setMouseTracking(true);
end

function MultiLineEditbox:init(parent)
	MultiLineEditbox._super.init(self, parent);

	self.viewport = TextControl:new():init(self);
	self.viewport:Connect("sizeChanged", self, "updateScrollStatus");
	self.viewport:Connect("positionChanged", self, "updateScrollValue");

	return self;
end

function MultiLineEditbox:echoMode()
    return self.m_echoMode;
end


function MultiLineEditbox:setEchoMode(mode)
	if(self.m_echoMode == mode) then
		return;
	end
    self.m_echoMode = mode;
	self:Update();
end

function MultiLineEditbox:reset()

end

--function MultiLineEditbox:SetRows(value)
--	self.rows = value;
--	--local height = self.rows * self.itemHeight + leftTextMargin;
--	local height = self.rows * self.itemHeight;
--	self:resize(self:width(), height);
--end

function MultiLineEditbox:GetRows()
	return math.floor(self:ViewPort():height()/self.ItemHeight);
end

function MultiLineEditbox:SetPosition(x, y)
	self:setGeometry(x, y, 200, 20 * 5);
end

function MultiLineEditbox:ViewPort()
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

function MultiLineEditbox:setReadOnly(bReadOnly)
	--self.m_readOnly = bReadOnly;
	if(self.viewport) then
		self.viewport:setReadOnly(bReadOnly);
	end
end

function MultiLineEditbox:isReadOnly()
	if(self.viewport) then
		self.viewport:isReadOnly();
	end
end

function MultiLineEditbox:SetText(text)
	self.viewport:SetText(text);
end

function MultiLineEditbox:GetText()
	return self.viewport:GetText();
end

function MultiLineEditbox:AddItem(text)
	self.viewport:AddItem(text);
end

function MultiLineEditbox:RemoveItem(index)
	self.viewport:RemoveItem(index);
end

function MultiLineEditbox:contains(x,y)
	return self:rect():contains(x,y);
end

function MultiLineEditbox:offsetX()
	return self:sliderPositionFromValue(0, 1000, self.hscroll, self.length);
end

function MultiLineEditbox:offsetY()
	return self:sliderPositionFromValue(0, 1000, self.vscroll, self.items:size() * self.ItemHeight);
end

function MultiLineEditbox:Clip()
	local w = self:width();
	local h = self:height();
	if(not self.hbar:isHidden()) then
		h = h - self.SliderSize;
	end

	if(not self.vbar:isHidden()) then
		w = w - self.SliderSize;
	end
	return Rect:new_from_pool(0, 0, w, h);
end

function MultiLineEditbox:updateViewportPos()
	self.viewport:updatePos(self.hscroll, self.vscroll);
end

function MultiLineEditbox:GetRow()
	return math.floor(self:Clip():height()/self.viewport:GetLineHeight());
end

function MultiLineEditbox:updateScrollInfo()
	local clip = self:Clip();
	if(not self.hbar:isHidden()) then
		self.hbar:setRange(0, self.viewport:GetRealWidth() - clip:width() - 1);
		self.hbar:setStep(self.viewport:WordWidth(), clip:width());
		self.hbar:SetValue(self.viewport:hValue());
	end

	if(not self.vbar:isHidden()) then
		self.vbar:setRange(0, self.viewport:GetRow() - self:GetRow());
		self.vbar:setStep(1, self:GetRow());
		self.vbar:SetValue(self.viewport:vValue());
	end
end

function MultiLineEditbox:updateScrollValue()
	if(not self.hbar:isHidden()) then
		self.hbar:SetValue(self.viewport:hValue());
	end

	if(not self.vbar:isHidden()) then
		self.vbar:SetValue(self.viewport:vValue());
	end
end

function MultiLineEditbox:updateScrollStatus(textbox_w, textbox_h)
	local clip = self:Clip();
	if(textbox_w > clip:width()) then
		self.hbar:show();
	else
		self.hbar:hide();
	end

	clip = self:Clip();
	if(textbox_h > clip:height()) then
		self.vbar:show();

		clip = self:Clip();
		if(textbox_w > clip:width()) then
			self.hbar:show();
		else
			self.hbar:hide();
		end
	else
		self.vbar:hide();
	end

	self:updateScrollInfo();
end

function MultiLineEditbox:updateScrollGeometry()
	if(not self.hbar:isHidden()) then
		if(self.vbar:isHidden()) then
			self.hbar:setGeometry(0, self:height() - self.SliderSize, self:width(), self.SliderSize);
		else
			self.hbar:setGeometry(0, self:height() - self.SliderSize, self:width() - self.SliderSize, self.SliderSize);
		end
	end

	if(not self.vbar:isHidden()) then
		if(self.hbar:isHidden()) then
			self.vbar:setGeometry(self:width() - self.SliderSize, 0, self.SliderSize, self:height());
		else
			self.vbar:setGeometry(self:width() - self.SliderSize, 0, self.SliderSize, self:height() - self.SliderSize);
		end
	end
end

function MultiLineEditbox:paintEvent(painter)
	self:updateScrollGeometry();
	painter:SetPen(self:GetBackgroundColor());
	painter:DrawRectTexture(self:x(), self:y(), self:width(), self:height(), self:GetBackground());
end

