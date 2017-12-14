--[[
Title: TextControl
Author(s): LiPeng
Date: 2017/8/16
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/TextControl.lua");
local TextControl = commonlib.gettable("System.Windows.Controls.TextControl");
------------------------------------------------------------

test
------------------------------------------------------------

------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
NPL.load("(gl)script/ide/System/Core/UniString.lua");
local Rect = commonlib.gettable("mathlib.Rect");
local UniString = commonlib.gettable("System.Core.UniString");
local Application = commonlib.gettable("System.Windows.Application");
local FocusPolicy = commonlib.gettable("System.Core.Namespace.FocusPolicy");
local Point = commonlib.gettable("mathlib.Point");

local TextControl = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.Controls.TextControl"));
TextControl:Property("Name", "TextControl");

TextControl:Property({"Background", "", auto=true});
TextControl:Property({"BackgroundColor", "#cccccc", auto=true});
TextControl:Property({"Color", "#000000", auto=true})
TextControl:Property({"CursorColor", "#000000", auto=true})
TextControl:Property({"SelectedBackgroundColor", "#99c9ef", auto=true})
TextControl:Property({"CurLineBackgroundColor", "#e5ebf1e0", auto=true})
TextControl:Property({"m_cursor", 0, "cursorPosition", "setCursorPosition"})
TextControl:Property({"cursorVisible", false, "isCursorVisible", "setCursorVisible"})
TextControl:Property({"m_readOnly", false, "isReadOnly", "setReadOnly", auto=true})
TextControl:Property({"m_cursorWidth", 2,})
TextControl:Property({"m_blinkPeriod", 0, "getCursorBlinkPeriod", "setCursorBlinkPeriod"})
TextControl:Property({"Font", "System;14;norm", auto=true})
TextControl:Property({"Scale", nil, "GetScale", "SetScale", auto=true})
TextControl:Property({"m_maxLength", 65535, "getMaxLength", "setMaxLength", auto=true})
TextControl:Property({"text", nil, "GetText", "SetText"})
TextControl:Property({"lineWrap", nil, "GetLineWrap", "SetLineWrap", auto=true})
TextControl:Property({"lineHeight", 20, "GetLineHeight", "SetLineHeight", auto=true})
TextControl:Property({"AutoTabToSpaces", true, "IsAutoTabToSpaces", "SetAutoTabToSpaces", auto=true})

--TextControl:Signal("SizeChanged",function(width,height) end);
--TextControl:Signal("PositionChanged");

-- undo/redo handling
local Command = commonlib.inherit(nil, {});
--@param t: Separator, Insert, Remove, Delete, RemoveSelection, DeleteSelection, InsertItem, RemoveItem ,SetSelection
function Command:init(cmd_type, pos, str, select_start, select_end, moveCursor)
    self.type = cmd_type;
    self.uc = str;
    self.pos = pos;
	self.selStart = select_start;
	self.selEnd = select_end;
	self.move = moveCursor;
	return self;
end

function TextControl:ctor()
	self.items = commonlib.Array:new();

	-- cursor info
	--self.cursor = nil;
	self.cursorLine = 1;
	self.cursorLastLine = 1;
	self.cursorPos = 0;
	self.cursorLastPos = 0;

	-- select
	self.m_selLineStart = 0;
	self.m_selPosStart = 0;
	self.m_selLineEnd = 0;
	self.m_selPosEnd = 0;

	self.m_undoState = 0;
	self.m_history = commonlib.Array:new();

	self.needRecomputeTextWidth = true;
	self.needRecomputeTextHeight = true;

	self:setFocusPolicy(FocusPolicy.StrongFocus);
	self:setAttribute("WA_InputMethodEnabled");
	self:setMouseTracking(true);
end

function TextControl:init(parent)
	TextControl._super.init(self, parent);

	self:initDoc();

	return self;
end

-- private: Adds the given command to the undo history
-- of the line control.  Does not apply the command.
function TextControl:addCommand(cmd)
    if (self.m_separator and self.m_undoState>0 and self.m_history[self.m_undoState].type ~= "Separator") then
		self.m_history:resize(self.m_undoState + 2);
		self.m_undoState = self.m_undoState + 1;
        self.m_history[self.m_undoState] = Command:new():init("Separator", self:CursorPos(), "", self:SelStart(), self:SelEnd());
	else
		self.m_history:resize(self.m_undoState + 1);
    end
    self.m_separator = false;
	self.m_undoState = self.m_undoState + 1;
    self.m_history[self.m_undoState] = cmd;
end

function TextControl:separate()
	self.m_separator = true;
end

function TextControl:CursorPos()
	return {line = self.cursorLine, pos = self.cursorPos};
end

function TextControl:SelStart()
	return {line = self.m_selLineStart, pos = self.m_selPosStart};
end

function TextControl:SelEnd()
	return {line = self.m_selLineEnd, pos = self.m_selPosEnd};
end

-- clip region. 
function TextControl:ClipRegion()
	local r = self.parent:ClipRegion();
	r:setX(r:x() - self:x());
	r:setY(r:y() - self:y());
	return r;
end

function TextControl:initDoc()
	local item = {
		text = UniString:new();
	}
	self.items:push_back(item);
end

function TextControl:setReadOnly(bReadOnly)
	self.m_readOnly = bReadOnly;
	if (bReadOnly) then
        self:setCursorBlinkPeriod(0);
    else
        self:setCursorBlinkPeriod(Application:cursorFlashTime());
	end
end

-- virtual: 
function TextControl:focusInEvent(event)
	-- Application:inputMethod():show();
	self:setCursorVisible(true);
	self:setCursorBlinkPeriod(Application:cursorFlashTime());
end

-- virtual: 
function TextControl:focusOutEvent(event)
	-- Application:inputMethod():hide();
	self:setCursorVisible(false);
	self:setCursorBlinkPeriod(0);
end

function TextControl:setCursorVisible(visible)
    if (self.cursorVisible == visible) then
        return;
	end
    self.cursorVisible = visible;
    self:update();
end

function TextControl:isCursorVisible()
	return self.cursorVisible;
end

function TextControl:getCursorBlinkPeriod()
	return self.m_blinkPeriod;
end

function TextControl:setCursorBlinkPeriod(msec)
    if (msec == self.m_blinkPeriod) then
        return;
	end
    if (self.m_blinkTimer) then
        self.m_blinkTimer:Change();
    end
    if (msec > 0 and not self.m_readOnly) then
        self.m_blinkTimer = self.m_blinkTimer or commonlib.Timer:new({callbackFunc = function(timer)
			self.m_blinkStatus = not self.m_blinkStatus;
			--self:updateNeeded(); -- signal
		end})
		self.m_blinkTimer:Change(msec / 2, msec / 2);
        self.m_blinkStatus = 1;
    else
        -- self.m_blinkTimer = nil;
        if (self.m_blinkStatus == 1) then
            --self:updateNeeded(); -- signal
		end
    end
    self.m_blinkPeriod = msec;
end

function TextControl:SetText(text)
	self.items:clear();
	self.m_history:clear();
	self.m_undoState = 0;

	local line_text, breaker_text;
	for line_text, breaker_text in string.gfind(text or "", "([^\r\n]*)(\r?\n?)") do
		-- DONE: the current one will not ignore empty lines. such as \r\n\r\n. Empty lines are recognised.  
		if(breaker_text ~= "" or line_text~="") then
			self:AddItem(line_text);
		end	
	end
	if(self:GetRow() == 0) then
		self:initDoc();
	end
end

function TextControl:GetText()
	local text = "";
	for i = 1, #self.items do
		local lineText = tostring(self:GetLineText(i));
		text = text..lineText;
		if(i ~= #self.items) then
			text = text.."\r\n";
		end
	end
	return text;
end

function TextControl:AddItem(text)
	self:InsertItem(#self.items + 1, text);
end

function TextControl:clear()
--    self.m_selstart = 0;
--    self.m_selend = self.m_text:length();
--    self:removeSelectedText();
--    self:separate();
    --self:finishChange(priorState, false, false);
end

function TextControl:GetLine(index)
	if(index > #self.items) then
		return nil;
	end
	return self.items:get(index);
end

function TextControl:GetLineText(index)
	local line = self:GetLine(index);
	if(line) then
		return line.text;
	end
	return nil;
end

function TextControl:InsertItem(pos, text)
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
	end

	if(pos > #self.items) then
		self.items:push_back(item);
	else
		self.items:insert(pos, item);
	end

	-- TODO: optimize this to avoid width calculation
	local width = self:GetLineWidth(item);
	if(width > self:GetRealWidth()) then
		self:SetRealWidth(width);
	end
	self.needRecomputeTextHeight = true;
end

function TextControl:RemoveItem(index)
	local width = self:GetLineWidth(self:GetLine(index)) or 0;
	-- only reset width when width is bigger than real width.
	if(width >= self:GetRealWidth()) then
		self.needRecomputeTextWidth = true;
	end
	self.needRecomputeTextHeight = true;

	self.items:remove(index);
end

function TextControl:SetRealWidth(width)
	if(self.m_realWidth ~= width) then
		self.m_realWidth = width;
		self.needUpdateControlSize = true;
	end
end

function TextControl:GetRealWidth()
	return self.m_realWidth or 0;
end

function TextControl:GetRealHeight()
	return self.m_realHeight or 0;
end

function TextControl:SetRealHeight(height)
	if(self.m_realHeight ~= height) then
		self.m_realHeight = height;
		self.needUpdateControlSize = true;
	end
end

-- recompute real height (total text width)
function TextControl:RecomputeTextHeight()
	self:SetRealHeight(self.lineHeight * (#self.items))
end

-- recompute real width (total text width, the longest line)
function TextControl:RecomputeTextWidth()
	local width = 0;
	for i = 1, self.items:size() do
		local itemText = self.items:get(i).text;
		local itemWidth = math.floor(self:naturalTextWidth(itemText)+0.5) + 1;
		if(itemWidth > width) then
			width = itemWidth;
		end
	end
	self:SetRealWidth(width);
end

function TextControl:setX(x, emitSingal)
	if(x == self:x()) then
		return;
	end
	TextControl._super.setX(self, x);
	if(emitSingal) then
		self:emitPositionChanged();
	end
end

function TextControl:setY(y, emitSingal)
	if(y == self:y()) then
		return;
	end
	TextControl._super.setY(self, y);
	if(emitSingal) then
		self:emitPositionChanged();
	end
end

function TextControl:setWidth(w)
	if(w == self:width()) then
		return;
	end
	if(w > self:width() or w > self:ClipRegion():width()) then
		TextControl._super.setWidth(self, w);
	end
	self:emitSizeChanged();
end

function TextControl:setHeight(h)
	if(h == self:height()) then
		return;
	end
	if(h > self:height() or h > self:ClipRegion():height()) then
		TextControl._super.setHeight(self, h);
	end
	self:emitSizeChanged();
end

function TextControl:GetLineWidth(line)
	if(line and line.text) then
		return self:GetTextWidth(line.text);
	end
end

function TextControl:GetTextWidth(text)
	if(text) then
		return math.floor(self:naturalTextWidth(text)+0.5) + 1;
	end
end

-- this function is slow, avoid calling it. 
function TextControl:naturalTextWidth(text)
	return text:GetWidth(self:GetFont());
end

function TextControl:hValue()
	local clip = self:ClipRegion();
	return clip:x();
end

function TextControl:vValue()
	local clip = self:ClipRegion();
	return clip:y()/self.lineHeight;
end

function TextControl:mousePressEvent(e)
	local clip = self:ClipRegion();
	if(e:button() == "left" and clip:contains(e:pos())) then
		local line = self:yToLine(e:pos():y());
		local text = self:GetLineText(line);
		local pos = self:xToPos(text, e:pos():x());
		local mark = e.shift_pressed;
		self:moveCursor(line,pos,mark,true);
		--self:adjustCursor();
		e:accept();
		self:docPos();
	end
end

function TextControl:mouseMoveEvent(e)
	if(e:button() == "left") then
		local select = true;
		local line = self:yToLine(e:pos():y());
		local text = self:GetLineText(line);
		local pos = self:xToPos(text, e:pos():x());
		self:moveCursor(line, pos, select, true);

		e:accept();
	end
end

function TextControl:inputMethodEvent(event)
	if(self:isReadOnly()) then
		event:ignore();
		return;
	end

	local commitString = event:commitString();

	local char1 = string.byte(commitString, 1);
	if(char1 <= 31) then
		-- ignore control characters
		event:ignore();
		return;
	end

	--self:InsertTextAddToCommand(commitString, nil, nil, true);
	self:InsertTextInCursorPos(commitString);
	
end

function TextControl:keyPressEvent(event)
	local keyname = event.keyname;
	local mark = event.shift_pressed;
	local unknown = false;
	if(keyname == "DIK_RETURN") then
		if(self:hasAcceptableInput()) then
			--self:accepted(); -- emit
			self:newLine(mark);
		end
	elseif(keyname == "DIK_BACKSPACE") then
		if (not self:isReadOnly()) then
			if(event.ctrl_pressed) then
				self:cursorWordBackward(true);
				self:del();
			else
				self:backspace();
			end
		end
	elseif(event:IsKeySequence("SelectAll")) then
		self:selectAll();
	elseif(event:IsKeySequence("Copy")) then
		self:copy();
	elseif(event:IsKeySequence("Paste")) then
		if (not self:isReadOnly()) then
			self:paste("Clipboard");
		end
	elseif(event:IsKeySequence("Cut")) then
		if (not self:isReadOnly()) then
			self:copy();
			self:del();
		end
	elseif(keyname == "DIK_HOME") then
		if(event.ctrl_pressed) then
			self:DocHome(mark);
		else
			self:LineHome(mark);
		end
	elseif(keyname == "DIK_END") then
		
		if(event.ctrl_pressed) then
			self:DocEnd(mark);
		else
			self:LineEnd(mark);
		end
	elseif(keyname == "DIK_PAGE_UP") then
		self:PreviousPage(mark);
	elseif(keyname == "DIK_PAGE_DOWN") then
		self:NextPage(mark);
	elseif (event:IsKeySequence("MoveToNextChar")) then
		if (self:hasSelectedText()) then
			self:moveCursor(self.m_selLineEnd, self.m_selPosEnd, false, true);
        else
            self:cursorForward(false, 1);
        end
	elseif (event:IsKeySequence("SelectNextChar")) then
        self:cursorForward(true, 1);
	elseif (event:IsKeySequence("MoveToPreviousChar")) then
		if (self:hasSelectedText()) then
            self:moveCursor(self.m_selLineStart, self.m_selPosStart, false, true);
        else
            self:cursorForward(false, -1);
        end
	elseif (event:IsKeySequence("SelectPreviousChar")) then
        self:cursorForward(true, -1);

	elseif (event:IsKeySequence("MoveToNextWord")) then
        if (self.parent:echoMode() == "Normal") then
            self:cursorWordForward(false);
        elseif (not self:isReadOnly()) then
            self:End(false);
		end
    elseif (event:IsKeySequence("MoveToPreviousWord")) then
        if (self.parent:echoMode() == "Normal") then
            self:cursorWordBackward(false);
        elseif (not self:isReadOnly()) then
            self:Home(false);
        end
    elseif (event:IsKeySequence("SelectNextWord")) then
        if (self.parent:echoMode() == "Normal") then
            self:cursorWordForward(true);
        else
            self:End(true);
		end
    elseif (event:IsKeySequence("SelectPreviousWord")) then
        if (self.parent:echoMode() == "Normal") then
            self:cursorWordBackward(true);
        else
            self:Home(true);
		end
	elseif (event:IsKeySequence("MoveToPreviousLine")) then
		self:cursorLineForward(false)
	elseif (event:IsKeySequence("MoveToNextLine")) then
		self:cursorLineBackward(false);
	elseif (event:IsKeySequence("SelectToPreviousLine")) then
		self:cursorLineForward(true)
	elseif (event:IsKeySequence("SelectToNextLine")) then
		self:cursorLineBackward(true);
	elseif (event:IsKeySequence("ScrollToPreviousLine")) then
		self:ScrollLineForward()
	elseif (event:IsKeySequence("ScrollToNextLine")) then
		self:ScrollLineBackward();
    elseif (event:IsKeySequence("Delete")) then
        if (not self:isReadOnly()) then
            self:del();
		end
	elseif(event:IsKeySequence("Undo")) then
		if (not self:isReadOnly()) then
			self:undo();
		end
	elseif(event:IsKeySequence("Redo")) then
		if (not self:isReadOnly()) then
			self:redo();
		end
	else
		unknown = true;
	end

	if (unknown) then
        event:ignore();
    else
        event:accept();
	end
end

function TextControl:resetInputMethod()
	if (self:hasFocus()) then
        Application:inputMethod():reset();
    end
end

function TextControl:undo()
	self:resetInputMethod();
	self:internalUndo(); 
	--self:finishChange(-1, true);
end

function TextControl:redo()
	self:resetInputMethod();
	self:internalRedo(); 
	--self:finishChange();
end

-- For security reasons undo is not available in any password mode (NoEcho included)
-- with the exception that the user can clear the password with undo.
function TextControl:isUndoAvailable()
    return not self:isReadOnly() and self.m_undoState>0
           and (self.parent:echoMode() == "Normal" or self.m_history[self.m_undoState].type == "Insert");
end

-- Same as with undo. Disabled for password modes.
function TextControl:isRedoAvailable()
    return not self:isReadOnly() and self.parent:echoMode() == "Normal" and self.m_undoState < self.m_history:size();
end

-- @param untilPos: default to -1
function TextControl:internalUndo(untilPos)
	untilPos = untilPos or -1;
	if (not self:isUndoAvailable()) then
        return;
	end
    self:internalDeselect();

--    -- Undo works only for clearing the line when in any of password the modes
--    if (self.parent:echoMode() ~= "Normal") then
--        self:clear();
--        return;
--    end
    while (self.m_undoState>0 and self.m_undoState > untilPos) do
        local cmd = self.m_history[self.m_undoState];
		self.m_undoState = self.m_undoState - 1;

		if(cmd.type == "Insert") then
			self:RemoveTextNotAddToCommand(cmd.selStart.line, cmd.selStart.pos, cmd.selEnd.line, cmd.selEnd.pos, cmd.move);
		elseif(cmd.type == "Remove") then
			self:InsertTextNotAddToCommand(cmd.uc, cmd.pos.line, cmd.pos.pos, cmd.move);
		elseif(cmd.type == "Select") then
			self:setSelect(cmd.selStart, cmd.selEnd, cmd.pos, true);
		end
		if(cmd.type ~= "Separator") then
			if (untilPos < 0 and self.m_undoState>0) then
				local next = self.m_history[self.m_undoState];
				if (next.type ~= cmd.type and next.type == "Separator") then
					break;
				end
			end
		end
    end
    --self.m_textDirty = true;
    self:emitCursorPositionChanged();
end

function TextControl:internalRedo()
	if (not self:isRedoAvailable()) then
        return;
	end
    self:internalDeselect();
    while (self.m_undoState < self.m_history:size()) do
        local cmd = self.m_history[self.m_undoState+1];
		self.m_undoState = self.m_undoState + 1;

		if(cmd.type == "Insert") then
			self:InsertTextNotAddToCommand(cmd.uc, cmd.pos.line, cmd.pos.pos, cmd.move);
		elseif(cmd.type == "Remove") then
			self:RemoveTextNotAddToCommand(cmd.selStart.line, cmd.selStart.pos, cmd.selEnd.line, cmd.selEnd.pos, cmd.move);
		elseif(cmd.type == "Select") then
			self:setSelect(cmd.selStart, cmd.selEnd, cmd.pos, true);
		end

		if (self.m_undoState < self.m_history:size()) then
            local next = self.m_history[self.m_undoState+1];
            if (next.type ~= cmd.type and next.type == "Separator") then
				break;
			end
        end
    end
    --self.m_textDirty = true;
    self:emitCursorPositionChanged();
end

function TextControl:scrollX(offst_x)
	local x = math.min(0,self:x() + offst_x);
	self:setX(x, true);
end

function TextControl:scrollY(offst_y)
	if(offst_y % self.lineHeight ~= 0) then
		local tmp_offset = math.ceil(math.abs(offst_y) / self.lineHeight) * self.lineHeight;
		offst_y = if_else(offst_y >0 ,tmp_offset ,-tmp_offset);
	end
	local y = math.min(0,self:y() + offst_y);
	self:setY(y, true);
end

function TextControl:updatePos(hscroll, vscroll)
	local x = -hscroll;
	local y = -vscroll * self.lineHeight;
	self:setX(x);
	self:setY(y);
end

function TextControl:ScrollLineForward()
	if((self:y() + self.lineHeight) <= self.parent:ClipRegion():y()) then
		self:scrollY(self.lineHeight);
		--self:setY(self:y() + self.lineHeight);

		local cursor_bottom = (self.cursorLine - 1) * self.lineHeight + self.lineHeight;
		if(cursor_bottom > self:ClipRegion():y() + self:ClipRegion():height()) then
			self.cursorLine = self.cursorLine - 1;
		end
	end
end

function TextControl:ScrollLineBackward()
	if((self:y() + self:height() - self.lineHeight) > (self.parent:ClipRegion():y() + self.parent:ClipRegion():height())) then
		self:scrollY(-self.lineHeight);
		--self:setY(self:y() - self.lineHeight);
		local cursor_y = (self.cursorLine - 1) * self.lineHeight;
		if(cursor_y < self:ClipRegion():y()) then
			self.cursorLine = self.cursorLine + 1;
		end
	end
end

function TextControl:cursorLineForward(mark)
	local pos = self.cursorPos;
	local line = self.cursorLine;
	if(line > 1) then
		line = line - 1;
		local len = self:GetLineText(line):length();
		pos = math.min(len, pos);
	end
	self:moveCursor(line,pos,mark,true);	
end

-- @param mark: bool, if mark for selection. 
function TextControl:cursorLineBackward(mark)
	
	local pos = self.cursorPos;
	local line = self.cursorLine;
	if(line < #self.items) then
		line = line + 1;
		local len = self:GetLineText(line):length();
		pos = math.min(len, pos);
	end
	self:moveCursor(line,pos,mark,true);	
end

function TextControl:LineHome(mark) 
	self:moveCursor(self.cursorLine, 0, mark,true);
end

function TextControl:DocHome(mark) 
	self:moveCursor(1, 0, mark,true);
end

function TextControl:LineEnd(mark)
	local pos = self:GetCurrentLine().text:length();
	self:moveCursor(self.cursorLine, pos, mark,true);
	--self:moveCursor(self.m_text:length(), mark);
end

function TextControl:DocEnd(mark)
	local line = #self.items;
	local pos = self:GetLineText(line):length();
	self:moveCursor(line, pos, mark,true);
	--self:moveCursor(self.m_text:length(), mark);
end

function TextControl:GetRow()
	return #self.items;
end

function TextControl:PreviousPage(mark)
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

function TextControl:NextPage(mark)
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

-- @param mark: bool, if mark for selection. 
function TextControl:cursorWordBackward(mark)
	local pos = self.cursorPos;
	local line = self.cursorLine;
	local len = self:GetCurrentLine().text:length();
	if(pos == 0) then
		if(line > 1) then
			line = line - 1;
			pos = self:GetLineText(line):length();
		end		
	else
		local text = self:GetCurrentLine().text;
		pos = text:previousCursorPosition(pos, "SkipWords");
	end
	self:moveCursor(line,pos,mark,true);	
end

function TextControl:cursorWordForward(mark)
	local pos = self.cursorPos;
	local line = self.cursorLine;
	local len = self:GetCurrentLine().text:length();
	if(pos == len) then
		if(line ~= #self.items) then
			line = line + 1;
			pos = 0;
		end		
	else
		local text = self:GetCurrentLine().text;
		pos = text:nextCursorPosition(pos, "SkipWords");
	end
	self:moveCursor(line,pos,mark,true);	
end


-- @param mark: bool, if mark for selection. 
function TextControl:cursorForward(mark, steps)
	local pos = self.cursorPos;
	local line = self.cursorLine;
	local len = self:GetCurrentLine().text:length();

	pos = pos + steps;
    if (steps > 0) then
		while(pos > len) do
			if(line + 1 > #self.items) then
				pos = len;
				break;
			end
			line = line + 1;
			pos = pos - len - 1;
			len = self:GetLineText(line):length();
		end
    elseif (steps < 0) then
		while(pos < 0) do
			if(line <= 1) then
				pos = 0;
				break;
			end
			line = line - 1;
			len = self:GetLineText(line):length();
			pos = len + pos + 1;
		end
	end
	self:moveCursor(line,pos,mark,true);
end

function TextControl:del()
	--local priorState = self.m_undoState;
    if (self:hasSelectedText()) then
		self:separate();
        self:removeSelectedText();
    else
        self:internalDelete();
    end
    --self:finishChange(priorState);
end

function TextControl:paste(mode)
	local clip = ParaMisc.GetTextFromClipboard();
	if(clip and self:IsAutoTabToSpaces()) then
		clip = clip:gsub("\t", "    ");
	end
	if(clip or self:hasSelectedText()) then
		--self:separate(); -- make it a separate undo/redo command
        --self:InsertTextAddToCommand(clip);
		self:InsertTextInCursorPos(clip);
        --self:separate();
	end
end

function TextControl:docPos(line, pos)
	line = line or self.cursorLine;
	pos = pos or self.cursorPos;
	local docPos = 0;
	for i = 1, line do
		if(i == line) then
			docPos = docPos + pos;
		else
			local lineText = self:GetLineText(i);
			-- "\r\n" length is 2.
			docPos = docPos + lineText:length() + 2;
		end
	end
	return docPos;
end

function TextControl:InsertTextInCursorPos(text)
	self:separate();
	self:removeSelectedText();
	--self:RemoveTextAddToCommand(self.m_selLineStart, self.m_selPosStart, self.m_selLineEnd, self.m_selPosEnd);
	self:InsertTextAddToCommand(text, self.cursorLine, self.cursorPos, true);
end

function TextControl:InsertTextAddToCommand(text, line, pos, moveCursor)
	self:InsertText(text, line, pos, true, moveCursor);
end

function TextControl:InsertTextNotAddToCommand(text, line, pos, moveCursor)
	--self:RemoveTextNotAddToCommand(self.m_selLineStart, self.m_selPosStart, self.m_selLineEnd, self.m_selPosEnd);
	self:InsertText(text, line, pos, false, moveCursor);
end

function TextControl:InsertText(text, line, pos , addToCommand, moveCursor)
	if(text == "" or not text) then
		return;
	end

	local cursorLine = line;
	local cursorPos = pos;

	local before_pos = {line = line, pos = pos};
	if(string.find(text,"\n")) then
		local newLines = {};
		
		for line_text, breaker_text in string.gfind(text or "", "([^\r\n]*)(\r?\n?)") do
			if(line_text ~= "" or breaker_text ~= "") then
				if(#newLines > 0) then
					newLines[#newLines] = line_text;
				else
					newLines[#newLines + 1] = line_text;
				end
				
				if(breaker_text == "\r" or breaker_text == "\n" or breaker_text == "\r\n") then
					newLines[#newLines + 1] = "";
				end
			end
			-- DONE: the current one will not ignore empty lines. such as \r\n\r\n. Empty lines are recognised.  
		end
		local cursorLineText = self:GetLineText(line);
		local newLineText = cursorLineText:substr(pos + 1,cursorLineText:length());
		self:lineInternalRemove(self:GetLine(line), pos + 1);
		local lineIndex = line;
		for i = 1,#newLines do
			if(i == 1) then
				local insertLine = self:GetLine(lineIndex);
				local lineText = insertLine.text;
				self:lineInternalInsert(insertLine,lineText:length(),newLines[i]);
			elseif(i == #newLines) then
				self:InsertItem(lineIndex,newLines[i]..newLineText);
			else
				self:InsertItem(lineIndex,newLines[i]);
			end
			lineIndex = lineIndex + 1;
		end
		if(moveCursor) then
			cursorLine = line + #newLines - 1;
			cursorPos = ParaMisc.GetUnicodeCharNum(newLines[#newLines]);
		end
	else
		local s = self:lineInternalInsert(self:GetLine(line), pos, text);
		if(s and moveCursor) then
			cursorPos = pos + s:length();
		end
	end

	if(moveCursor) then
		self:moveCursor(cursorLine,cursorPos, false, true);
	end

	local after_pos = {line = cursorLine, pos = cursorPos};


	if(addToCommand) then
		self:addCommand(Command:new():init("Insert", before_pos, text, before_pos, after_pos, moveCursor));
	end
end

function TextControl:scopeText(startLine, startPos, endLine, endPos)
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
	return text;
end

function TextControl:selectedText()
	if(self:hasSelectedText()) then
		return self:scopeText(self.m_selLineStart, self.m_selPosStart, self.m_selLineEnd, self.m_selPosEnd);
	end
end

function TextControl:copy()
	local t = self:selectedText()
	if(t) then
		ParaMisc.CopyTextToClipboard(t);
	end
end

function TextControl:selectAll()
	self:internalDeselect();
	local line = #self.items;
	local text = self:GetLineText(line);
	self:moveCursor(1, 0, false, true);
	self:moveCursor(#self.items, text:length(), true, true);
end

function TextControl:RemoveTextAddToCommand(startLine, startPos, endLine, endPos, moveCursor)
	self:RemoveText(startLine, startPos, endLine, endPos, true, moveCursor);
end

function TextControl:RemoveTextNotAddToCommand(startLine, startPos, endLine, endPos, moveCursor)
	self:RemoveText(startLine, startPos, endLine, endPos, false, moveCursor);
end

function TextControl:RemoveText(startLine, startPos, endLine, endPos , addToCommand, moveCursor)
	if(startLine == endLine and startPos == endPos ) then
		return;
	end

	local selStart = {line = startLine, pos = startPos};
	local selEnd = {line = endLine, pos = endPos};

	--local move = not (self.cursorLine == startLine and self.cursorPos == startPos);

	local text = self:scopeText(startLine, startPos, endLine, endPos);

	if(startLine == endLine) then
		self:lineInternalRemove(self:GetLine(startLine), startPos+1, endPos - startPos);
	else
		local firstLine = self:GetLine(startLine);
		local lastLine = self:GetLine(endLine);
		local firstLineText = firstLine.text;
		local lastLineText = lastLine.text;
		local insertText = "";
		for i = endLine, startLine, -1 do
			if(i == startLine) then
				self:lineInternalRemove(firstLine, startPos+1, firstLineText:length() - startPos)
				self:lineInternalInsert(firstLine, firstLineText:length(), insertText)
			elseif(i == endLine) then
				insertText = lastLineText:substr(endPos+1, lastLineText:length());
				self:RemoveItem(i);
			else
				self:RemoveItem(i);
			end
		end
	end
	if(moveCursor) then
		self:moveCursor(startLine, startPos, false, true);
	end

	if(addToCommand) then
		self:addCommand(Command:new():init("Remove", self:CursorPos(), text, selStart, selEnd, moveCursor));
	end	
end

function TextControl:removeSelectedText()
	if(self:hasSelectedText()) then
		self:addCommand(Command:new():init("Select", self:CursorPos(), nil, self:SelStart(), self:SelEnd()));
		self:RemoveTextAddToCommand(self.m_selLineStart, self.m_selPosStart, self.m_selLineEnd, self.m_selPosEnd, true);
		self:internalDeselect();
	end
end

function TextControl:backspace()
    --local priorState = m_undoState;
    if (self:hasSelectedText()) then
		self:separate();
        self:removeSelectedText();
    else
		self:internalDelete(true);
    end
    --self:finishChange(priorState);
end

function TextControl:internalDelete(wasBackspace)
	if(self.cursorLine == 1 and self.cursorPos == 0) then
		return;
	end
	self:separate();
	local startLine, startPos, endLine, endPos;
	local anchorLine, anchorPos;

	if(wasBackspace) then
		if(self.cursorPos > 0) then
			anchorLine = self.cursorLine;
			anchorPos = self.cursorPos - 1;
		else
			anchorLine = self.cursorLine - 1;
			anchorPos = self:GetLineText(anchorLine):length();
		end
	else
		local len = self:GetLineText(self.cursorLine):length();
		if(self.cursorPos < len) then
			anchorLine = self.cursorLine;
			anchorPos = self.cursorPos + 1;
		else
			anchorLine = self.cursorLine + 1;
			anchorPos = 0;
		end
	end

	if(anchorLine == self.cursorLine) then
		startLine = anchorLine;
		startPos = math.min(anchorPos, self.cursorPos);
		endLine = anchorLine;
		endPos = math.max(anchorPos, self.cursorPos);
	else
		startLine = math.min(anchorLine, self.cursorLine);
		endLine = math.max(anchorLine, self.cursorLine);
		if(startLine == anchorLine) then
			startPos = anchorPos;
			endPos = self.cursorPos;
		else
			startPos = self.cursorPos;
			endPos = anchorPos;
		end
	end

	self:RemoveTextAddToCommand(startLine, startPos, endLine, endPos, wasBackspace);
end

function TextControl:lineInternalRemove(line, pos, count)
	local text = line.text;
	local width = self:GetLineWidth(line);
	text:remove(pos, count);
	
	if(width >= self:GetRealWidth()) then
		self.needRecomputeTextWidth = true;
	end
end

function TextControl:newLine(mark)
	self:InsertTextInCursorPos("\r\n");
end

function TextControl:hasAcceptableInput(str)
--	str = str or self:GetText();
--
--	-- TODO: validate text?
	return true;
end

function TextControl:updateDisplayText()
	
end

function TextControl:emitCursorPositionChanged()
--	local cix = math.floor(self:cursorToX()+0.5);
--	if
--

--	if (self.m_cursorLine ~= self.m_lastCursorLine or self.m_cursor ~= self.m_lastCursorPos) then
--		local oldLastLine = self.m_cursorLine;
--		self.m_lastCursorLine = self.m_cursorLine;
--        local oldLastCursor = self.m_lastCursorPos;
--        self.m_lastCursorPos = self.m_cursor;
--        self:cursorPositionChanged(oldLastLine, self.m_cursorLine, oldLast, self.m_cursor);
--	end
end


function TextControl:lineInternalInsert(line, pos, s)
	s = UniString:new(s);
	local lineText = line.text;
	local remaining = self.m_maxLength - lineText:length();
    if (remaining > 0) then
		s = s:left(remaining);
        lineText:insert(pos, s);

		local width = self:GetLineWidth(line);
		if(width > self:GetRealWidth()) then
			self:SetRealWidth(width);
		end
		return s;
    end
	return nil;
end

function TextControl:hasSelectedText() 
	if(self.m_selLineStart == self.m_selLineEnd and self.m_selPosStart == self.m_selPosEnd) then
		return false;
	end
	return true;
end

function TextControl:setSelect(selStart, selEnd, cursorPos, adjustCursor)
	local startCursorPos, endCursorPos;
	if(cursorPos.line == selStart.line and cursorPos.pos == selStart.pos) then
		startCursorPos = selEnd;
		endCursorPos = selStart;
	else
		startCursorPos = selStart;
		endCursorPos = selEnd;
	end
	self:moveCursor(startCursorPos.line, startCursorPos.pos, false, adjustCursor);
	self:moveCursor(endCursorPos.line, endCursorPos.pos, true, adjustCursor);
end

function TextControl:moveCursor(line, pos, mark, adjustCursor)
	if (mark) then
		local anchorLine,anchorPos;
		if(self.m_selLineStart == self.cursorLine and self.m_selPosStart == self.cursorPos) then
			anchorLine = self.m_selLineEnd;
			anchorPos = self.m_selPosEnd;
		elseif(self.m_selLineEnd == self.cursorLine and self.m_selPosEnd == self.cursorPos) then
			anchorLine = self.m_selLineStart;
			anchorPos = self.m_selPosStart;
		else
			anchorLine = self.cursorLine;
			anchorPos = self.cursorPos;
		end

		if(anchorLine == line) then
			self.m_selLineStart = line;
			self.m_selLineEnd = line;
			self.m_selPosStart = math.min(anchorPos, pos);
			self.m_selPosEnd = math.max(anchorPos, pos);
		else
			self.m_selLineStart = math.min(anchorLine, line);
			self.m_selLineEnd = math.max(anchorLine, line);
			if(self.m_selLineStart == line) then
				self.m_selPosStart = pos;
				self.m_selPosEnd = anchorPos;
			else
				self.m_selPosStart = anchorPos;
				self.m_selPosEnd = pos;
			end
		end
    else
        self:internalDeselect();
    end

	if(self.cursorLine ~= line or self.cursorPos ~= pos) then
		self.cursorLine = line;
		self.cursorPos = pos;
		self.m_blinkStatus = 1;
		--self.cursor:setStatus(true);
	end
	if(adjustCursor) then
		self:adjustCursor();
	end
end

function TextControl:internalDeselect()
	--self.m_selDirty = self.m_selDirty or (self.m_selend > self.m_selstart);
	self.m_selLineStart = 0;
	self.m_selPosStart = 0;
	self.m_selLineEnd = 0;
	self.m_selPosEnd = 0;
end

function TextControl:GetCurrentLine()
	return self.items:get(self.cursorLine);
end

function TextControl:yToLine(y)
	local line = math.ceil(y/self.lineHeight);
	line = if_else(line > #self.items, #self.items, line);
	line = if_else(line > 1, line, 1);
	return line;
end

function TextControl:xToPos(text, x, betweenOrOn)
	local text = text or self:GetCurrentLine().text;
    return text:xToCursor(x, betweenOrOn, self:GetFont());
end

function TextControl:cursorToX(text)
	local text = text or self:GetCurrentLine().text;
	local x = text:cursorToX(self.cursorPos, self:GetFont());
	return math.floor(x + 0.5);
end

function TextControl:cursorMinPosX()
	return self:ClipRegion():x();
end

function TextControl:cursorMaxPosX()
	return self:ClipRegion():x() + self:ClipRegion():width();
end

function TextControl:cursorMinPosY()
	return self:ClipRegion():y();
end

function TextControl:cursorMaxPosY()
	return self:ClipRegion():y() + self:ClipRegion():height() - self.lineHeight;
end

function TextControl:adjustCursor()
	local clip = self:ClipRegion();
	local cursor_x_to_clip;

	local cursor_x_to_self = self:cursorToX();

	local min_cursor_x = self:cursorMinPosX();
	local max_cursor_x = self:cursorMaxPosX();

	if(cursor_x_to_self < min_cursor_x or cursor_x_to_self > max_cursor_x) then
		if(cursor_x_to_self < min_cursor_x) then
			local word_width = self:WordWidth();
			local line_width = self:GetLineWidth(self:GetCurrentLine());
			local text = self:GetCurrentLine().text:sub(1, self.cursorPos);
			local cursor_to_line_start = self:GetTextWidth(text);
			if(line_width < clip:width() or cursor_to_line_start < word_width) then
				cursor_x_to_clip = cursor_x_to_self;
			else
				cursor_x_to_clip = word_width;
			end
		end

		if(cursor_x_to_self > max_cursor_x) then
			cursor_x_to_clip = clip:width() - 2;
		end

		local clip_x_to_self = cursor_x_to_self - cursor_x_to_clip;
		local self_x = self.parent:ClipRegion():x() - clip_x_to_self;
		self:setX(self_x, true);
	end

	local cursor_y = (self.cursorLine - 1) * self.lineHeight;
	local max_cursor_y = self:cursorMaxPosY();
	local min_cursor_y = self:cursorMinPosY();

	--local offset_y = 0;
	local new_y = self:y();
	if(cursor_y > max_cursor_y) then
		new_y = self:y() + max_cursor_y - (self.cursorLine - 1) * self.lineHeight;
	elseif(cursor_y < min_cursor_y) then
		new_y = self:y() + min_cursor_y - (self.cursorLine - 1) * self.lineHeight;
	end
	if(new_y ~= self:y()) then
		self:scrollY(new_y - self:y());
	end
end

function TextControl:WordWidth()
	return self:CharWidth() * 4;
end

function TextControl:CharWidth()
	if(not self.m_charWidth or self.m_lastCharWidthFont ~= self:GetFont()) then
		-- cache width here to increase performance 
		self.m_lastCharWidthFont = self:GetFont();
		self.m_charWidth = _guihelper.GetTextWidth("a", self.m_lastCharWidthFont);
	end
	return self.m_charWidth or 5;
end

function TextControl:emitPositionChanged()
	self:PositionChanged();
end

function TextControl:emitSizeChanged()
	local w = self:GetRealWidth();
	local h = self:GetRealHeight();
	self:SizeChanged(w, h);
end

function TextControl:updateGeometry()
	if(self.needRecomputeTextWidth) then
		self:RecomputeTextWidth();	
		self.needRecomputeTextWidth = false;
	end

	if(self.needRecomputeTextHeight) then
		self:RecomputeTextHeight();	
		self.needRecomputeTextHeight = false;
	end

	if(self.needUpdateControlSize) then
		self.needUpdateControlSize = false;
		local clip = self.parent:ClipRegion();
		if(self:GetRealWidth() < clip:width()) then
			self:setX(clip:x(), true);
			self:setWidth(clip:width() - self:x());
		else
			self:setWidth(self:GetRealWidth());
		end

		if(self:GetRealHeight() < clip:height()) then
			self:scrollY(clip:y() - self:y());
			self:setHeight(clip:height() - self:y());
		else
			self:setHeight(self:GetRealHeight());
		end
	end
end

function TextControl:paintEvent(painter)
	if(self.needRecomputeTextHeight or self.needRecomputeTextWidth or self.needUpdateControlSize) then
		self:updateGeometry();
	end
	local clipRegion = self:ClipRegion();
	local from_line = math.max(1, 1 + math.floor((-self:y()) / self.lineHeight)); 
	local to_line = math.min(self.items:size(), 1 + math.ceil((-self:y() + clipRegion:height()) / self.lineHeight));


	if(self.cursorVisible and self:hasFocus() and not self:isReadOnly()) then
		-- the curor line backgroud
		local curline_x, curline_y = 0, (self.cursorLine - 1) * self.lineHeight;
		painter:SetPen(self:GetCurLineBackgroundColor());
		painter:DrawRect(self:x() + curline_x, self:y() + curline_y, self:width(), self.lineHeight);
	end

	if (self:hasSelectedText()) then
		-- render selection
		local sel_x = 0;
		local sel_y = 0;
		local sel_start, sel_end;
		local sel_width = 0;

		if(self.m_selLineStart == self.m_selLineEnd) then
			local lineIndex = self.m_selLineStart;
			if(self.m_selPosStart ~= self.m_selPosEnd) then
				local text = self:GetLineText(lineIndex);
				local beforeSelectText = text:sub(1, self.m_selPosStart);
				if(not beforeSelectText:empty()) then
					local textWidth = beforeSelectText:GetWidth(self:GetFont());
					sel_x = textWidth * (self:GetScale() or 1);
				end
				local selectText = text:sub(self.m_selPosStart + 1, self.m_selPosEnd);
				if(not selectText:empty()) then
					local textWidth = selectText:GetWidth(self:GetFont());
					sel_width = textWidth * (self:GetScale() or 1);
				end
				if(sel_width>0) then
					sel_y = self.lineHeight * (lineIndex - 1);
					painter:SetPen(self:GetSelectedBackgroundColor());
					painter:DrawRect(self:x() + sel_x, self:y() + sel_y, sel_width, self.lineHeight);
				end
			end
		else
			for i = math.max(from_line, self.m_selLineStart), math.min(to_line, self.m_selLineEnd) do
				if(i == self.m_selLineEnd and self.m_selPosEnd == 0) then
					break;
				end
				sel_x = 0;
				
				local text = self:GetLineText(i);
				if(i == self.m_selLineStart) then
					sel_start = self.m_selPosStart;
					sel_end = text:length();
				elseif(i == self.m_selLineEnd) then
					sel_start = 0;
					sel_end = self.m_selPosEnd;
				else
					sel_start = 0;
					sel_end = text:length();
				end

			
				local beforeSelectText = text:sub(1, sel_start);
				if(not beforeSelectText:empty()) then
					local textWidth = beforeSelectText:GetWidth(self:GetFont());
					sel_x = textWidth * (self:GetScale() or 1);
				end

				local selectText = text:sub(sel_start+1, sel_end);
				if(not selectText:empty()) then
					local textWidth = selectText:GetWidth(self:GetFont());
					sel_width = textWidth * (self:GetScale() or 1);
					if(i ~= self.m_selLineEnd) then
						sel_width = sel_width + self:CharWidth();
					end
				else
					sel_width = self:CharWidth();
				end
				if(sel_width>0) then
					sel_y = self.lineHeight * (i - 1);
					painter:SetPen(self:GetSelectedBackgroundColor());
					painter:DrawRect(self:x() + sel_x, self:y() + sel_y, sel_width, self.lineHeight);
				end
			end
		end
	end

	if(not self.items:empty()) then
		painter:SetPen(self:GetColor());
		painter:SetFont(self:GetFont());
		local scale = self:GetScale();
		for i = from_line, to_line do
			local item = self.items:get(i);
			painter:DrawTextScaled(self:x(), self:y() + self.lineHeight * (i - 1), item.text:GetText(), scale);
		end
	end

	if(self.cursorVisible and self:hasFocus() and not self:isReadOnly()) then
		-- draw cursor
		if(self.m_blinkPeriod==0 or self.m_blinkStatus) then
			local cursor_x = self:cursorToX();
			local cursor_y = (self.cursorLine - 1) * self.lineHeight;
			painter:SetPen(self:GetCursorColor());
			painter:DrawRect(self:x() + cursor_x, self:y() + cursor_y, self.m_cursorWidth, self.lineHeight);
		end
	end
end

