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
mulLine:setGeometry(100, 100, 200, 20 * 5+10);
mulLine:AddItem("我是第一行");
mulLine:AddItem("");
mulLine:AddItem("我是第三行");
mulLine:AddItem("我是第四行");
mulLine:AddItem("我是第五行");
mulLine:AddItem("我是第六行");
--mulLine:AddItem("我是第七行");
--mulLine:AddItem("我是第八行");
--mulLine:AddItem("我是第九行");
--mulLine:AddItem("我是第十行");
--mulLine:SetBackgroundColor("#cccccc");

window:Show("my_window", nil, "_mt", 0,0, 600, 600);
test_Windows.window = window;
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollArea.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollBar.lua");
NPL.load("(gl)script/ide/math/Point.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/TextCursor.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/TextControl.lua");
local TextControl = commonlib.gettable("System.Windows.Controls.TextControl");
local Point = commonlib.gettable("mathlib.Point");
local Rect = commonlib.gettable("mathlib.Rect");
local UniString = commonlib.gettable("System.Core.UniString");
local Application = commonlib.gettable("System.Windows.Application");
local FocusPolicy = commonlib.gettable("System.Core.Namespace.FocusPolicy");
local ScrollBar = commonlib.gettable("System.Windows.Controls.ScrollBar");
local TextCursor = commonlib.gettable("System.Windows.Controls.TextCursor");

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
MultiLineEditbox:Property({"m_readOnly", false, "isReadOnly", "setReadOnly", auto=true})
MultiLineEditbox:Property({"m_echoMode", "Normal", "echoMode", "setEchoMode"})
MultiLineEditbox:Property({"Font", "System;14;norm", auto=true})
MultiLineEditbox:Property({"Scale", nil, "GetScale", "SetScale", auto=true})
MultiLineEditbox:Property({"horizontalMargin", 0});
MultiLineEditbox:Property({"leftTextMargin", 2});
MultiLineEditbox:Property({"topTextMargin", 2});
MultiLineEditbox:Property({"rightTextMargin", 2});
MultiLineEditbox:Property({"bottomTextMargin", 2});
MultiLineEditbox:Property({"m_readOnly", false, "  ", "setReadOnly"})
--MultiLineEditbox:Property({"m_maxLength", 65535, "getMaxLength", "setMaxLength", auto=true})
--MultiLineEditbox:Property({"rows", nil, "GetRows", "SetRows"})
MultiLineEditbox:Property({"lineWrap", nil, "GetLineWrap", "SetLineWrap", auto=true})
MultiLineEditbox:Property({"ItemHeight",20, auto=true})

MultiLineEditbox:Property({"SliderSize", 20, auto=true});
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
	self.hbar = nil;
	self.vbar = nil;
--	self.hscroll = 500;
--	self.vscroll = 500;
	self.hscroll = 0;
	self.vscroll = 0;

	self:setFocusPolicy(FocusPolicy.StrongFocus);
	self:setAttribute("WA_InputMethodEnabled");
	self:setMouseTracking(true);
end



function MultiLineEditbox:init(parent)
	MultiLineEditbox._super.init(self, parent);

	self.viewport = TextControl:new():init(self);

	self:initScrollBar();

	return self;
end

function MultiLineEditbox:initScrollBar()
--	local vscrollbar = ScrollBar:vScrollBar(self); 
----	vscrollbar:Connect("scroll", function(event)
----		self.beginIndex = vscrollbar:GetRoundValue();
----		vscrollbar:SetValue(self.beginIndex);
----		self:update();
----	end);
--
--	self.vbar = vscrollbar;
--
--	local hscrollbar = ScrollBar:hScrollBar(self); 
----	vscrollbar:Connect("scroll", function(event)
----		self.beginIndex = vscrollbar:GetRoundValue();
----		vscrollbar:SetValue(self.beginIndex);
----		self:update();
----	end);
--
--	self.hbar = hscrollbar;
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
	self.m_readOnly = bReadOnly;
	if (bReadOnly) then
        self:setCursorBlinkPeriod(0);
    else
        self:setCursorBlinkPeriod(Application:cursorFlashTime());
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

function MultiLineEditbox:UpdateScrollBar()
	if(not self.needUpdate) then
		return;
	end
	if(#self.items > self.rows) then
		self.vscroll:show();

		self.vscroll:setGeometry(self:width() - self.ScrollBarWidth, 0, self.ScrollBarWidth, self:height());
		if(#self.items > 0) then
			local slider_height = (self:height() - 2 * self.ScrollBarWidth) * self.rows / #self.items;
			self.vscroll:SetSliderHeight(slider_height);	
		end
		self.vscroll:SetMin(self.beginIndex);
		self.vscroll:SetMax(#self.items - self.rows + self.beginIndex);
		self.vscroll:SetValue(self.beginIndex);
	else
		self.vscroll:hide();
	end

	self.needUpdate = false;
end

function MultiLineEditbox:adjustedScrollBar()
	
end

function MultiLineEditbox:sliderValueFromPosition(min, max, pos, space)
	local value = (max - min) * pos / space + min;
	return math.floor(value + 0.5);
end

function MultiLineEditbox:sliderPositionFromValue(min, max, val, space)
	local pos = (val - min)/(max - min) * space;
	return math.floor(pos + 0.5);
end

function MultiLineEditbox:contains(x,y)
	return self:rect():contains(x,y);
end

function MultiLineEditbox:isReadOnly()
	return self.m_readOnly;
end

function MultiLineEditbox:setReadOnly(bReadOnly)
	self.m_readOnly = bReadOnly;
	if (bReadOnly) then
        self.viewport:hideCursor();
    else
        self.viewport:showCursor();
	end
end

function MultiLineEditbox:offsetX()
	return self:sliderPositionFromValue(0, 1000, self.hscroll, self.length);
end

function MultiLineEditbox:offsetY()
	return self:sliderPositionFromValue(0, 1000, self.vscroll, self.items:size() * self.ItemHeight);
end

function MultiLineEditbox:backspace()
    local priorState = m_undoState;
    if (self:hasSelectedText()) then
        --self:removeSelectedText();
    else
		self:internalDelete(true);
--		if(self.cursor:GetPosition() > 0) then
--			self.m_cursor = self.m_cursor - 1;
--			self:internalDelete(true);
--		end
    end
    self:finishChange(priorState);
end

function MultiLineEditbox:Clip()
	return Rect:new_from_pool(0, 0, self:width(), self:height());
end

function MultiLineEditbox:paintEvent(painter)
	painter:SetPen(self:GetBackgroundColor());
	painter:DrawRectTexture(self:x(), self:y(), self:width(), self:height(), self:GetBackground());
end

