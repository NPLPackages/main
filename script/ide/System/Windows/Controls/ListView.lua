--[[
Title: ListView
Author(s): LiPeng
Date: 2017/8/16
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/ListView.lua");
local ListView = commonlib.gettable("System.Windows.Controls.ListView");
------------------------------------------------------------

test
------------------------------------------------------------

------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
local Rect = commonlib.gettable("mathlib.Rect");
local UniString = commonlib.gettable("System.Core.UniString");
local Application = commonlib.gettable("System.Windows.Application");
local FocusPolicy = commonlib.gettable("System.Core.Namespace.FocusPolicy");
local Point = commonlib.gettable("mathlib.Point");

local ListView = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.Controls.ListView"));
ListView:Property("Name", "ListView");

ListView:Property({"Background", "", auto=true});
ListView:Property({"BackgroundColor", "#cccccc", auto=true});
ListView:Property({"Color", "#000000", auto=true})
--ListView:Property({"CursorColor", "#33333388", auto=true})
ListView:Property({"SelectedBackgroundColor", "#006680", auto=true})
--ListView:Property({"CurLineBackgroundColor", "#87ceff", auto=true})
--ListView:Property({"m_cursor", 0, "cursorPosition", "setCursorPosition"})
--ListView:Property({"cursorVisible", false, "isCursorVisible", "setCursorVisible"})
--ListView:Property({"m_cursorWidth", 2,})
--ListView:Property({"m_blinkPeriod", 0, "getCursorBlinkPeriod", "setCursorBlinkPeriod"})
ListView:Property({"Font", "System;14;norm", auto=true})
ListView:Property({"Scale", nil, "GetScale", "SetScale", auto=true})
ListView:Property({"m_maxLength", 65535, "getMaxLength", "setMaxLength", auto=true})
--ListView:Property({"text", nil, "GetText", "SetText"})
ListView:Property({"lineWrap", nil, "GetLineWrap", "SetLineWrap", auto=true})
ListView:Property({"lineHeight", 20, "GetLineHeight", "SetLineHeight", auto=true})
ListView:Property({"SelectMultiple",false, auto=true})

--ListView:Signal("SizeChanged",function(width,height) end);
--ListView:Signal("PositionChanged");
ListView:Signal("clicked");

function ListView:ctor()
	self.items = commonlib.Array:new();

	--self.curLine = 0;
	self.selectIndex = nil;

--	self:setFocusPolicy(FocusPolicy.StrongFocus);
--	self:setAttribute("WA_InputMethodEnabled");
--	self:setMouseTracking(true);
end

--function ListView:init(parent)
--	ListView._super.init(self, parent);
--
--	self:initDoc();
--	self:initCursor();
--
--	return self;
--end
--
function ListView:CursorPos()
	return {line = self.cursorLine, pos = self.cursorPos};
end

function ListView:SelStart()
	return {line = self.m_selLineStart, pos = self.m_selPosStart};
end

function ListView:SelEnd()
	return {line = self.m_selLineEnd, pos = self.m_selPosEnd};
end

function ListView:getClip()
	local r = self.parent:ViewRegion();
	if(not self.mask) then
		self.mask = Rect:new():init(0,0,0,0);
	end
	self.mask:setRect(r:x() - self:x(), r:y() - self:y(), r:width(), r:height());
	return self.mask;
	--return Rect:new_from_pool(r:x() - self:x(), r:y() - self:y(), r:width(), r:height());
end

function ListView:AddItem(text)
	self:InsertItem(#self.items + 1, text);
end

function ListView:clear()
	self.items:clear();
end

function ListView:GetLine(index)
	if(index > #self.items) then
		return nil;
	end
	return self.items:get(index);
end

function ListView:SetValue(value)
	for i = 1, self.items:size() do
		local item = self.items:get(i);
		if(item.value == value) then
			self:SelectItem(i);
			return;
		end
	end

	for i = 1, self.items:size() do
		local item = self.items:get(i);
		if(tostring(item.text) == value) then
			self:SelectItem(i);
			return;
		end
	end
end

function ListView:GetLineText(index)
	local line = self:GetLine(index);
	if(line) then
		return line.text;
	end
	return nil;
end

function ListView:GetLineValue(index)
	local line = self:GetLine(index);
	if(line) then
		return line.value;
	end
	return nil;
end

function ListView:InsertItem(pos, text)
	text = text or "";
	local item;
	if(type(text) == "string") then
		local uniText = UniString:new(text);

		item = {
			text = uniText,
			selected = false,
		}
	else
		item = text;
--		item.text = item.text or "";
--		if(type(item.text) == "string") then
--			item.text = UniString:new(item.text);
--		end
--		if(type(item.selected) == "string") then
--			item.selected = if_else("true", true, false);
--		end
	end

	local width = self:GetLineWidth(item);

	if(pos > #self.items) then
		self.items:push_back(item);
		if(item.selected) then
			self.selectIndex = #self.items;
			self.parent:emitclicked();
		end
	else
		self.items:insert(pos, item);
		if(item.selected) then
			self.selectIndex = pos;
			self.parent:emitclicked();
		end
	end
	if(width > self:width()) then
		self:setWidth(width);
	end
	self:RecountHeight();

	self.needUpdate = true;
end

function ListView:RemoveItem(index)
	self.items:remove(index);

	self:RecountWidth();
	self:RecountHeight();

	self.needUpdate = true;
end

function ListView:GetRealWidth()
	local width = 0;
	for i = 1, self.items:size() do
		local itemText = self.items:get(i).text;
		local itemWidth = math.floor(self:naturalTextWidth(itemText)+0.5) + 1;
		if(itemWidth > width) then
			width = itemWidth;
		end
	end
	return width;
end

function ListView:GetRealHeight()
	return self.lineHeight * #self.items;
end

function ListView:RecountHeight()
	self:setHeight(self:GetRealHeight());
	--self:GetTextRect():setHeight(self.lineHeight * #self.items);
end

function ListView:RecountWidth()
	local width = self:GetRealWidth();
	self:setWidth(width);
--	if(width > self:width()) then
--		--self:GetTextRect():setWidth(width);
--		self:setWidth(width);
--	end
end

function ListView:setX(x, emitSingal)
	if(x == self:x()) then
		return;
	end
	ListView._super.setX(self, x);
	if(emitSingal) then
		self:emitPositionChanged();
	end
	
end

function ListView:setY(y, emitSingal)
	if(y == self:y()) then
		return;
	end
	ListView._super.setY(self, y);
	if(emitSingal) then
		self:emitPositionChanged();
	end
end

function ListView:setWidth(w)
	if(w == self:width()) then
		return;
	end
	if(w > self:width() or w > self:getClip():width()) then
		--self:setWidth(w);
		ListView._super.setWidth(self, w);
	end
	--self:emitSizeChanged();
end

function ListView:setHeight(h)
	if(h == self:height()) then
		return;
	end
	if(h > self:height() or h > self:getClip():height()) then
		--self.crect:setHeight(h);
		ListView._super.setHeight(self, h);
	end
	--self:emitSizeChanged();
end

function ListView:GetLineWidth(line)
	if(line and line.text) then
		return self:GetTextWidth(line.text);
	end
end

function ListView:GetTextWidth(text)
	if(text) then
		return math.floor(self:naturalTextWidth(text)+0.5) + 1;
	end
end

function ListView:naturalTextWidth(text)
	return text:GetWidth(self:GetFont());
end

function ListView:hValue()
	local clip = self:getClip();
	return clip:x();
end

function ListView:vValue()
	local clip = self:getClip();
	return clip:y()/self.lineHeight;
end

function ListView:mousePressEvent(e)
	local clip = self:getClip();
	if(e:button() == "left" and clip:contains(e:pos())) then
		local line = self:yToLine(e:pos():y());
		self:SelectItem(line);
		e:accept();
	end
end

function ListView:SelectItem(index)
	if(index > #self.items) then
		return false;
	end
	local beChanged = false;
	if(self.SelectMultiple) then
		self.items[index]["selected"] = not self.items[index]["selected"];
		beChanged = true;
	else
		if(self.selectIndex ~= index) then
			if(self.selectIndex) then
				self.items[self.selectIndex]["selected"] = false;
			end
			self.items[index]["selected"] = true;
			beChanged = true;
		end
	end
	self.selectIndex = index;
	self.parent:emitclicked();
	return beChanged;
end

--function ListView:mouseMoveEvent(e)
--	if(e:button() == "left") then
--		local select = true;
--		local line = self:yToLine(e:pos():y());
--		local text = self:GetLineText(line);
--		local pos = self:xToPos(text, e:pos():x());
--		self:moveCursor(line, pos, select, true);
--
--		e:accept();
--	end
--end
--
--function ListView:keyPressEvent(event)
--	local keyname = event.keyname;
--	local mark = event.shift_pressed;
--	local unknown = false;
--	if(keyname == "DIK_RETURN") then
--		if(self:hasAcceptableInput()) then
--			--self:accepted(); -- emit
--			self:newLine(mark);
--		end
--	elseif(keyname == "DIK_BACKSPACE") then
--		if (not self.parent:isReadOnly()) then
--			if(event.ctrl_pressed) then
--				self:cursorWordBackward(true);
--				self:del();
--			else
--				self:backspace();
--			end
--		end
--	elseif(event:IsKeySequence("SelectAll")) then
--		self:selectAll();
--	elseif(event:IsKeySequence("Copy")) then
--		self:copy();
--	elseif(event:IsKeySequence("Paste")) then
--		if (not self.parent:isReadOnly()) then
--			self:paste("Clipboard");
--		end
--	elseif(event:IsKeySequence("Cut")) then
--		if (not self.parent:isReadOnly()) then
--			self:copy();
--			self:del();
--		end
--	elseif(keyname == "DIK_HOME") then
--		if(event.ctrl_pressed) then
--			self:DocHome(mark);
--		else
--			self:LineHome(mark);
--		end
--	elseif(keyname == "DIK_END") then
--		
--		if(event.ctrl_pressed) then
--			self:DocEnd(mark);
--		else
--			self:LineEnd(mark);
--		end
--	elseif(keyname == "DIK_PAGE_UP") then
--		self:PreviousPage(mark);
--	elseif(keyname == "DIK_PAGE_DOWN") then
--		self:NextPage(mark);
--	elseif (event:IsKeySequence("MoveToNextChar")) then
--		if (self:hasSelectedText()) then
--			self:moveCursor(self.m_selLineEnd, self.m_selPosEnd, false, true);
--        else
--            self:cursorForward(false, 1);
--        end
--	elseif (event:IsKeySequence("SelectNextChar")) then
--        self:cursorForward(true, 1);
--	elseif (event:IsKeySequence("MoveToPreviousChar")) then
--		if (self:hasSelectedText()) then
--            self:moveCursor(self.m_selLineStart, self.m_selPosStart, false, true);
--        else
--            self:cursorForward(false, -1);
--        end
--	elseif (event:IsKeySequence("SelectPreviousChar")) then
--        self:cursorForward(true, -1);
--
--	elseif (event:IsKeySequence("MoveToNextWord")) then
--        if (self.parent:echoMode() == "Normal") then
--            self:cursorWordForward(false);
--        elseif (not self.parent:isReadOnly()) then
--            self:End(false);
--		end
--    elseif (event:IsKeySequence("MoveToPreviousWord")) then
--        if (self.parent:echoMode() == "Normal") then
--            self:cursorWordBackward(false);
--        elseif (not self.parent:isReadOnly()) then
--            self:Home(false);
--        end
--    elseif (event:IsKeySequence("SelectNextWord")) then
--        if (self.parent:echoMode() == "Normal") then
--            self:cursorWordForward(true);
--        else
--            self:End(true);
--		end
--    elseif (event:IsKeySequence("SelectPreviousWord")) then
--        if (self.parent:echoMode() == "Normal") then
--            self:cursorWordBackward(true);
--        else
--            self:Home(true);
--		end
--	elseif (event:IsKeySequence("MoveToPreviousLine")) then
--		self:cursorLineForward(false)
--	elseif (event:IsKeySequence("MoveToNextLine")) then
--		self:cursorLineBackward(false);
--	elseif (event:IsKeySequence("SelectToPreviousLine")) then
--		self:cursorLineForward(true)
--	elseif (event:IsKeySequence("SelectToNextLine")) then
--		self:cursorLineBackward(true);
--	elseif (event:IsKeySequence("ScrollToPreviousLine")) then
--		self:ScrollLineForward()
--	elseif (event:IsKeySequence("ScrollToNextLine")) then
--		self:ScrollLineBackward();
--    elseif (event:IsKeySequence("Delete")) then
--        if (not self.parent:isReadOnly()) then
--            self:del();
--		end
--	else
--		unknown = true;
--	end
--
--	if (unknown) then
--        event:ignore();
--    else
--        event:accept();
--	end
--end

function ListView:scrollX(offst_x)
	local x = math.min(0,self:x() + offst_x);
	self:setX(x, true);
end

function ListView:scrollY(offst_y)
	if(offst_y % self.lineHeight ~= 0) then
		local tmp_offset = math.ceil(math.abs(offst_y) / self.lineHeight) * self.lineHeight;
		offst_y = if_else(offst_y >0 ,tmp_offset ,-tmp_offset);
	end
	local y = math.min(0,self:y() + offst_y);
	self:setY(y, true);
end

function ListView:updatePos(hscroll, vscroll)
	local x = -hscroll;
	local y = -vscroll * self.lineHeight;
	self:setX(x);
	self:setY(y);
end

function ListView:ScrollLineForward()
	if((self:y() + self.lineHeight) <= self.parent:ViewRegion():y()) then
		self:scrollY(self.lineHeight);
		--self:setY(self:y() + self.lineHeight);

		local cursor_bottom = (self.cursorLine - 1) * self.lineHeight + self.cursor:height();
		if(cursor_bottom > self:getClip():y() + self:getClip():height()) then
			self.cursorLine = self.cursorLine - 1;
		end
	end
end

function ListView:ScrollLineBackward()
	if((self:y() + self:height() - self.lineHeight) > (self.parent:ViewRegion():y() + self.parent:ViewRegion():height())) then
		self:scrollY(-self.lineHeight);
		--self:setY(self:y() - self.lineHeight);
		local cursor_y = (self.cursorLine - 1) * self.lineHeight;
		if(cursor_y < self:getClip():y()) then
			self.cursorLine = self.cursorLine + 1;
		end
	end
end

function ListView:DocHome(mark) 
	self:moveCursor(1, 0, mark,true);
end

function ListView:DocEnd(mark)
	local line = #self.items;
	local pos = self:GetLineText(line):length();
	self:moveCursor(line, pos, mark,true);
	--self:moveCursor(self.m_text:length(), mark);
end

function ListView:GetRow()
	return #self.items;
end

function ListView:PreviousPage(mark)
	local row = self.parent:GetRow();
	local line = self.cursorLine - row;
	local pos = self.cursorPos;
	if(line < 1) then
		line = 1;
		pos = 0;
	end

	self:scrollY((self.cursorLine - line)*self.lineHeight);
	self:moveCursor(line, pos, mark);
end

function ListView:NextPage(mark)
	local row = self.parent:GetRow();
	local line = self.cursorLine + row;
	local pos = self.cursorPos;
	if(line > #self.items) then
		line = #self.items;
		pos = self:GetLineText(line):length();
	end
	
	self:scrollY((self.cursorLine - line)*self.lineHeight);
	self:moveCursor(line, pos, mark);
end

function ListView:del()
	--local priorState = self.m_undoState;
    if (self:hasSelectedText()) then
        self:removeSelectedText();
    else
        self:internalDelete();
    end
    --self:finishChange(priorState);
end

function ListView:scopeText(startLine, startPos, endLine, endPos, beUtf8)
	local text;

	if(startLine == endLine) then
		text = self:GetLineText(startLine):substr(startPos+1, endPos);
	else
		local startLineText = self:GetLineText(startLine);
		local endLineText = self:GetLineText(endLine);
		local insertText = "";
		for i = startLine, endLine do
			if(i == startLine) then
				text = startLineText:substr(startPos+1, startLineText:length());
				text = text.."\r\n";
			elseif(i == endLine) then
				text = text..endLineText:substr(1, endPos);
			else
				local lineText = self:GetLineText(i).text;
				text = text..lineText.."\r\n";
			end
		end
	end
	if(beUtf8) then
		text = commonlib.Encoding.Utf8ToDefault(tostring(text));
	end
	return text;
end

function ListView:selectedText()
	if(self:hasSelectedText()) then
		return self:scopeText(self.m_selLineStart, self.m_selPosStart, self.m_selLineEnd, self.m_selPosEnd, true);
	end
end

function ListView:copy()
	local t = self:selectedText()
	if(t) then
		ParaMisc.CopyTextToClipboard(t);
	end
end

function ListView:selectAll()
	self:internalDeselect();
	local line = #self.items;
	local text = self:GetLineText(line);
	self:moveCursor(1, 0, false, true);
	self:moveCursor(#self.items, text:length(), true, true);
end

function ListView:GetCurrentLine()
	return self.items:get(self.cursorLine);
end

function ListView:yToLine(y)
	local line = math.ceil(y/self.lineHeight);
	line = if_else(line > #self.items, #self.items, line);
	line = if_else(line > 1, line, 1);
	return line;
end

---- virtual: 
--function ListView:focusInEvent(event)
--	self:showCursor();
--end
--
---- virtual: 
--function ListView:focusOutEvent(event)
--	--self:hideCursor();
--end

function ListView:WordWidth()
	return self:CharWidth() * 4;
end

function ListView:CharWidth()
	return _guihelper.GetTextWidth("a", self:GetFont());
end

function ListView:emitPositionChanged()
	self:PositionChanged();
end

function ListView:emitSizeChanged()
	local w = self:GetRealWidth();
	local h = self:GetRealHeight();
	self:SizeChanged(w, h);
end

function ListView:updateGeometry()
	local clip = self.parent:ViewRegion();
	if(self:GetRealWidth() < clip:width()) then
		self:setX(clip:x(), true);
		self:setWidth(clip:width() - self:x());
		--self
	else
		local offset_r = (clip:x() + clip:width()) - (self:x() + self:width());
		if(offset_r > 0) then
			self:scrollX(offset_r);
		end
	end

	--local offset_y = self:y() + self:height();
	if(self:GetRealHeight() < clip:height()) then
		self:scrollY(clip:y() - self:y());
		--self:setY(clip:y());
		self:setHeight(clip:height() - self:y());
	else
		local offset_b = (clip:y() + clip:height()) - (self:y() + self:height());
		if(offset_b >= self.lineHeight) then
			self:scrollY(self.lineHeight * math.floor(offset_b / self.lineHeight));
		end
	end
end

function ListView:paintEvent(painter)
	self:updateGeometry();

	local clip =  self:getClip();
	local hasTextClipping = self:width() > clip:width() or self:height() > clip:height();

	if(hasTextClipping) then
		painter:Save();
		painter:SetClipRegion(self:x() +clip:x(), self:y() +clip:y(),clip:width(),clip:height());
	end

	if(not self.items:empty()) then
		local scale = self:GetScale();

		for i = 1, self.items:size() do
			local item = self.items:get(i);
			local offset_y = self.lineHeight * (i - 1);

			if(item.selected) then
				painter:SetPen(self:GetSelectedBackgroundColor());
				--painter:DrawRectTexture(self:x(), self:y() + offset_y, self:width(), self.lineHeight);
				painter:DrawRect(self:x(), self:y() + offset_y, self:width(), self.lineHeight);
			end

			local text = item.text:GetText();
			if(text and text~="") then
				painter:SetFont(self:GetFont());
				painter:SetPen(self:GetColor());
				
				painter:DrawTextScaled(self:x(), self:y() + offset_y, text, scale);
			end	
		end
	end

	if(hasTextClipping) then
		painter:Restore();
	end
end

