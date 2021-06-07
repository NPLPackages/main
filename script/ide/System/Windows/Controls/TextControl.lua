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
]]
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
NPL.load("(gl)script/ide/System/Core/UniString.lua");
NPL.load("(gl)script/ide/System/Util/SyntaxAnalysis.lua");

local SyntaxAnalysis = commonlib.gettable("System.Util.SyntaxAnalysis");
local Rect = commonlib.gettable("mathlib.Rect");
local UniString = commonlib.gettable("System.Core.UniString");
local Application = commonlib.gettable("System.Windows.Application");
local Keyboard = commonlib.gettable("System.Windows.Keyboard");
local FocusPolicy = commonlib.gettable("System.Core.Namespace.FocusPolicy");
local Point = commonlib.gettable("mathlib.Point");

local TextControl = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.Controls.TextControl"));
TextControl:Property("Name", "TextControl");

TextControl:Property({"Background", "", auto=true});
TextControl:Property({"BackgroundColor", "#cccccc", auto=true});
TextControl:Property({"Color", "#000000", auto=true})
TextControl:Property({"CursorColor", "#000000", auto=true})
TextControl:Property({"StaticCursorColor", "#00000033", auto=true})
TextControl:Property({"EmptyTextColor", "#888888", auto=true})
TextControl:Property({"SelectedBackgroundColor", "#99c9ef", auto=true})
TextControl:Property({"CurLineBackgroundColor", "#e5ebf1e0", auto=true})
TextControl:Property({"AlwaysShowCurLineBackground", true, "isAlwaysShowCurLineBackground", "SetAlwaysShowCurLineBackground", auto=true})
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
TextControl:Property({"EmptyText", nil, "GetEmptyText", "SetEmptyText", auto=true})
TextControl:Property({"language", nil, "Language", "SetLanguage", auto=true})
TextControl:Property({"m_bMoveViewWhenAttachWithIME", false, "isMoveViewWhenAttachWithIME", "setMoveViewWhenAttachWithIME"});


--TextControl:Signal("SizeChanged",function(width,height) end);
--TextControl:Signal("PositionChanged");
TextControl:Signal("mouseOverWordChanged");
-- user input some char or string
TextControl:Signal("userTyped", function(txtCtrl, str) end);
TextControl:Signal("keyPressed", function(txtCtrl, event) end);
TextControl:Signal("rightClicked", function(txtCtrl, event) end);



local TAB_CHAR = "    ";
local tab_len = string.len(TAB_CHAR);

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

	self.from_line= 0;
	self.to_line= 0;

	self.m_undoState = 0;
	self.m_history = commonlib.Array:new();

	self.needRecomputeTextWidth = true;
	self.needRecomputeTextHeight = true;

	self.syntaxAnalyzer = nil;

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

function TextControl:setMoveViewWhenAttachWithIME(bMove)
	self.m_bMoveViewWhenAttachWithIME = bMove;
end

function TextControl:isMoveViewWhenAttachWithIME()
	return self.m_bMoveViewWhenAttachWithIME;
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
	local r = self.parent:ViewRegion();
	r:setX(r:x() - self:x());
	r:setY(r:y() - self:y());
	return r;
end

function TextControl:initDoc()
	local item = {
		text = UniString:new();
	}
	self:AddItem(item);
end

function TextControl:setReadOnly(bReadOnly)
	self.m_readOnly = bReadOnly;
	if (bReadOnly) then
        self:setCursorBlinkPeriod(0);
    else
        self:setCursorBlinkPeriod(Application:cursorFlashTime());
	end
end

function TextControl:PageElement()
	return self.parent:PageElement();
end

function TextControl:attachWithIME()
	if (self:isMoveViewWhenAttachWithIME()) then
		local pos = Point:new_from_pool(0, self:y() + self:height());
		pos = self:mapToGlobal(pos);
		
		Keyboard:attachWithIME(pos:y());
	else
		Keyboard:attachWithIME(nil);
	end	
end

function TextControl:detachWithIME()
	if (self:isMoveViewWhenAttachWithIME()) then
		local pos = Point:new_from_pool(0, self:y() + self:height());
		pos = self:mapToGlobal(pos);
		
		Keyboard:detachWithIME(pos:y());
	else
		Keyboard:detachWithIME(nil);
	end
end

-- virtual: 
function TextControl:focusInEvent(event)
	self:setCursorVisible(true);
	self:setCursorBlinkPeriod(Application:cursorFlashTime());
	
	if(self:IsInputMethodEnabled()) then
		self:attachWithIME();
	end

	TextControl._super.focusInEvent(self, event)
end

-- virtual: 
function TextControl:focusOutEvent(event)

	self:detachWithIME();
	
	self:setCursorVisible(false);
	self:setCursorBlinkPeriod(0);

	TextControl._super.focusOutEvent(self, event)
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
	if(self.syntaxAnalyzer) then
		self.syntaxAnalyzer:Reset()
	end
	self.items:clear();
	self.m_history:clear();
	self.m_undoState = 0;
	self:internalDeselect();
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
	if(self.cursorLine>#self.items) then
		self.cursorLine = #self.items;
	end

	local clip = self.parent:ViewRegion();
	self:scrollX(clip:x() - self:x());
	--self:setX(clip:x(), true);
end

function TextControl:GetText()
	local lines = {};
	local lineCount = #self.items
	for i = 1, lineCount do
		lines[i] = tostring(self:GetLineText(i));
	end
	if(lineCount > 1 and lines[lineCount] == "") then
		-- if the last line is "", we will add a trailing \r\n
		lines[lineCount+1] = ""
	end
	return table.concat(lines, "\r\n");
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

function TextControl:AddHighLightBlock(lineItem, begin_pos, end_pos, font, color, scale)
	if(lineItem) then
		lineItem.highlightBlocks = lineItem.highlightBlocks or {};
		for i = 1,#lineItem.highlightBlocks do 
			local highlight_block = lineItem.highlightBlocks[i];
			if(not (begin_pos >= highlight_block.end_pos or end_pos <= highlight_block.begin_pos)) then
				return;
			end
		end
		local block = {begin_pos = begin_pos, end_pos = end_pos, font = font, color = color, scale = scale};
		lineItem.highlightBlocks[#lineItem.highlightBlocks+1] =  block;
	end
end

function TextControl:setLinePosColor(line, begin_pos, end_pos, font, color, scale)
	if(not begin_pos or not end_pos or begin_pos == end_pos or begin_pos > end_pos) then
		return;
	end
	local lineItem = self:GetLine(line)
	self:AddHighLightBlock(lineItem, begin_pos, end_pos, font, color, scale);
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

	item.changed = true;

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

function TextControl:setX(x, emitSignal)
	if(x == self:x()) then
		return;
	end
	TextControl._super.setX(self, x);
	if(emitSignal) then
		self:emitPositionChanged();
	end
end

function TextControl:setY(y, emitSignal)
	if(y == self:y()) then
		return;
	end
	TextControl._super.setY(self, y);
	if(emitSignal) then
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
	return math.floor(clip:y()/self.lineHeight+0.5);
end

function TextControl:mousePressEvent(e)
	local clip = self:ClipRegion();
	if(e:button() == "left" and clip:contains(e:pos())) then
		local line = self:yToLine(e:pos():y());
		local text = self:GetLineText(line);
		local pos = self:xToPos(text, e:pos():x());
		if(self:IsAutoTabToSpaces()) then
			if(text) then
				local firstWordPos = text:getFirstWordPosition()
				if(firstWordPos > pos) then
					pos = firstWordPos;
				end
			end
		end
		local mark = e.shift_pressed;
		self:moveCursor(line,pos,mark,true);

   		if(e.isTripleClick) then	
			-- triple click select the line
			self:moveCursor(line,0, false);
		   	self:moveCursor(line,text:length(), true);
		elseif(e.isDoubleClick) then
			-- double click select the word
			local begin_pos,end_pos = self:GetLineText(line):wordPosition(pos);
			self:moveCursor(line,begin_pos, false);
	   		self:moveCursor(line,end_pos, true);
		end
		e:accept();
		self:docPos();
		self.isLeftMouseDown = true;
		
		if (self:hasFocus() and not e.isDoubleClick and self:IsInputMethodEnabled()) then
			self:attachWithIME();
		end
	end
end

function TextControl:mouseReleaseEvent(event)
	self.isLeftMouseDown = false;
	if(event:button() == "right") then
		self:rightClicked(event);
	end
	event:accept();
end


-- @param word: word can be nil or text
-- @from lineText: UniString class object
function TextControl:setMouseOverWord(word, lineText, fromPos, toPos)
	if(self.lastMouseOverWord ~= word) then
		self.lastMouseOverWord = word;
		self.lastMouseOverInfo = {word=word, lineText=lineText, fromPos=fromPos, toPos=toPos};
		self:mouseOverWordChanged(word, lineText, fromPos, toPos);
	end
end

-- return table of {word, lineText, fromPos, toPos} where word may be nil
function TextControl:getMouseOverWordInfo()
	return self.lastMouseOverInfo;
end

function TextControl:mouseMoveEvent(e)
	if(e:button() == "left" and self.isLeftMouseDown) then

		if(not e.isTripleClick and not e.isDoubleClick) then
			local select = true;
			local line = self:yToLine(e:pos():y());
			local text = self:GetLineText(line);
			local pos = self:xToPos(text, e:pos():x());
			self:moveCursor(line, pos, select, true);
		end

		e:accept();
	else
		local line = math.ceil(e:pos():y()/self.lineHeight);
		if(line>=1 and line<=(#self.items)) then
			local text = self:GetLineText(line);
			if(text) then
				local pos = self:xToPos(text, e:pos():x());
				if(pos and pos>=0 and pos < text:length()) then
					local from,to = text:wordPosition(pos);
					if(from and from < to) then
						local word = text:substr(from+1, to);
						self:setMouseOverWord(word, text, from, to)
						return
					end
				end
			end
		end
		self:setMouseOverWord(nil)
	end
end

function TextControl:mouseLeaveEvent(event)
	self:setMouseOverWord(nil)
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
	self:userTyped(self, commitString);
	event:accept();
end

function TextControl:keyPressEvent(event)
	local keyname = event.keyname;
	local mark = event.shift_pressed;
	local unknown = false;
	self:keyPressed(self, event); -- signal
	if(event:isAccepted()) then
		return;
	end
	if(keyname == "DIK_RETURN") then
		if(not self:isReadOnly()) then
			if(self:hasAcceptableInput()) then
				--self:accepted(); -- emit
				self:newLine(mark);
				self:userTyped(self);
			end
		end
	elseif(keyname == "DIK_BACKSPACE") then
		if (not self:isReadOnly()) then
			if(event.ctrl_pressed) then
				self:cursorWordBackward(true);
				self:del();
			else
				self:backspace();
			end
			self:userTyped(self);
		end
	elseif(keyname == "DIK_TAB") then
		self:ProcessTab(mark);
		self:userTyped(self);
	elseif(event:IsKeySequence("SelectAll")) then
		self:selectAll();
	elseif(event:IsKeySequence("Copy")) then
		self:copy();
	elseif(event:IsKeySequence("Paste")) then
		if (not self:isReadOnly()) then
			self:paste("Clipboard");
			self:userTyped(self);
		end
	elseif(event:IsKeySequence("Cut")) then
		if (not self:isReadOnly()) then
			self:copy();
			self:del(true);
			self:userTyped(self);
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
			self:userTyped(self);
		end
	elseif(event:IsKeySequence("Undo")) then
		if (not self:isReadOnly()) then
			self:undo();
			self:userTyped(self);
		end
	elseif(event:IsKeySequence("Redo")) then
		if (not self:isReadOnly()) then
			self:redo();
			self:userTyped(self);
		end
	elseif(event:IsKeySequence("Search")) then
		local selectedText = self:selectedText();
		self.parent:Search(selectedText);
	elseif(keyname == "DIK_F3") then
		if(event.ctrl_pressed) then
			local selectedText = self:selectedText();
			self.parent:Search(selectedText);
			self.parent:SearchNext();
		elseif(event.shift_pressed) then
			self.parent:SearchPrevious()
		else
			self.parent:SearchNext();
		end
		
	elseif(keyname == "DIK_ESCAPE") then
		unknown = true;
	elseif(keyname == "DIK_L" and event.ctrl_pressed) then
		if(self.parent and self.parent:GetName() == "MultiLineEditbox") then
			self.parent:OnClickToggleIME();
		end
	else
		if(event:IsFunctionKey() or event.ctrl_pressed) then
			unknown = true;
		end
	end

	if (unknown) then
        event:ignore();
    else
        event:accept();
	end
end

function TextControl:ProcessTab(bIsShiftPressed)
	if(bIsShiftPressed) then
		if (self:hasSelectedText() and self.m_selLineStart ~= self.m_selLineEnd) then
			-- if multiple lines are selected, we will add tab in front of all selected lines
			self:separate();
			for i=self.m_selLineStart, self.m_selLineEnd do 
				local text = self:GetLineText(i);
				if(text) then
					local pos = math.min(tab_len, text:getFirstWordPosition());
					self:RemoveTextAddToCommand(i, 0, i, pos);
				end
			end
			return
		end

		local text = self:GetLineText(self.cursorLine);
		local nextCursorPos;
		for i = 1,tab_len do
			if(text and self.cursorPos - i > 0 and text[self.cursorPos - i] == " ") then
				nextCursorPos = self.cursorPos - i;
			end
		end
		if(nextCursorPos) then
			self:separate();
			self:RemoveTextAddToCommand(self.cursorLine, nextCursorPos, self.cursorLine, self.cursorPos, true);
		end
	else
		if (self:hasSelectedText() and self.m_selLineStart ~= self.m_selLineEnd) then
			-- if multiple lines are selected, we will add tab in front of all selected lines
			self:separate();
			for i=self.m_selLineStart, self.m_selLineEnd do 
				self:InsertTextAddToCommand(TAB_CHAR, i, 0);
			end
			return
		end

		if(self:IsAutoTabToSpaces()) then
			local text = self:GetLineText(self.cursorLine);
			local firstWordPos = text:getFirstWordPosition();
			if(text and self.cursorPos>0 and self.cursorPos<=firstWordPos)then
				local nSpaceCount = tab_len - firstWordPos%tab_len;
				if(nSpaceCount ~= tab_len) then
					self:InsertTextInCursorPos(TAB_CHAR:sub(1,nSpaceCount));
					return;
				end
			end
		end
		self:InsertTextInCursorPos(TAB_CHAR)
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

function TextControl:scrollX(offset_x)
	local min_x = self.parent:ViewRegionOffsetX();
	local x = math.min(min_x,self:x() + offset_x);
	self:setX(x, true);
end

function TextControl:scrollY(offset_y)
	if(offset_y % self.lineHeight ~= 0) then
		local tmp_offset = math.ceil(math.abs(offset_y) / self.lineHeight) * self.lineHeight;
		offset_y = if_else(offset_y >0 ,tmp_offset ,-tmp_offset);
	end
	local min_y = self.parent:ViewRegionOffsetY();
	local y = math.min(min_y,self:y() + offset_y);
	self:setY(y, true);
end

function TextControl:updatePos(hscroll, vscroll)
	local x = -hscroll + self.parent:ViewRegionOffsetX();
	local y = -vscroll * self.lineHeight + self.parent:ViewRegionOffsetY();
	self:setX(x);
	self:setY(y);
end

function TextControl:ScrollLineForward()
	if((self:y() + self.lineHeight) <= self.parent:ViewRegion():y()) then
		self:scrollY(self.lineHeight);
		--self:setY(self:y() + self.lineHeight);

		local cursor_bottom = (self.cursorLine - 1) * self.lineHeight + self.lineHeight;
		if(cursor_bottom > self:ClipRegion():y() + self:ClipRegion():height()) then
			self.cursorLine = self.cursorLine - 1;
		end
	end
end

function TextControl:ScrollLineBackward()
	if((self:y() + self:height() - self.lineHeight) > (self.parent:ViewRegion():y() + self.parent:ViewRegion():height())) then
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
		local text = self:GetLineText(line)
		local len = text:length();
		pos = math.min(len, pos);
		pos = math.max(pos, text:getFirstWordPosition());
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
	local text = self:GetLineText(self.cursorLine);
	if(not text) then
		return
	end
	if(self.cursorPos == 0) then
		if(text:atSpace(0)) then
			self:cursorWordForward(mark);
		end
	else
		local firstWordPos = text:getFirstWordPosition();
		if(firstWordPos < self.cursorPos) then
			self:moveCursor(self.cursorLine, firstWordPos, mark,true);
		else
			self:moveCursor(self.cursorLine, 0, mark,true);
		end
	end
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
	if(not self:GetCurrentLine()) then
		return
	end
	local len = self:GetCurrentLine().text:length();

	if(self:IsAutoTabToSpaces()) then
		local text = self:GetCurrentLine().text;
		local nFirstWordPos = text:getFirstWordPosition();
		if(steps == 1 and self.cursorPos<nFirstWordPos)then
			steps = tab_len - (self.cursorPos%tab_len);
			if(self.cursorPos+steps > nFirstWordPos) then
				steps = nFirstWordPos - self.cursorPos;
			end
		elseif(steps == -1 and self.cursorPos>1 and self.cursorPos<=nFirstWordPos)then
			steps = self.cursorPos%tab_len;
			steps = (steps==0) and -tab_len or -steps;
		end
	end

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

function TextControl:del(mark)
	--local priorState = self.m_undoState;
    if (self:hasSelectedText()) then
		self:separate();
        self:removeSelectedText();
	elseif(mark) then
		self:separate();

		local lineStart, posStart, lineEnd, posEnd = self.cursorLine, 0, self.cursorLine + 1, 0;
		if(#self.items == self.cursorLine) then
			lineEnd = self.cursorLine;
			posEnd = self:GetLineText(lineEnd):length();
		end

		self:RemoveTextAddToCommand(lineStart, posStart, lineEnd, posEnd, true);
    else
		if(self:IsAutoTabToSpaces()) then
			local text = self:GetLineText(self.cursorLine);
			local firstWordPos = text:getFirstWordPosition();
			if(text and self.cursorPos>=0 and (self.cursorPos%tab_len)==0 and self.cursorPos<firstWordPos)then
				local count = firstWordPos%tab_len;
				count = (count == 0) and 4 or count;
				if(count>0) then
					self:moveCursor(self.cursorLine, self.cursorPos+count, true,true);
					self:del();
				end
				return;
			end
		end
        self:internalDelete();
    end
    --self:finishChange(priorState);
end

function TextControl:paste(mode)
	local clip = ParaMisc.GetTextFromClipboard();
	if(clip and self:IsAutoTabToSpaces()) then
		clip = clip:gsub("\t", TAB_CHAR);
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
	local linewrap = self:GetLineWrap();
	if (not linewrap) then
		-- 旧逻辑  不换行
		self:separate();
		self:removeSelectedText();
		self:InsertTextAddToCommand(text, self.cursorLine, self.cursorPos, true);
		--self:RemoveTextAddToCommand(self.m_selLineStart, self.m_selPosStart, self.m_selLineEnd, self.m_selPosEnd);
		return ;
	end
	-- TODO 做自动换行处理
	
	-- 移除选择
	self:removeSelectedText();

	local unistr = UniString:new(text);   
	local textlen = unistr:length();
	local linewidth = self:width();
	local i = 1; 
	while (i <= textlen) do
		local char = unistr:sub(i, i).text;
		local linetext = self:GetLineText(self.cursorLine) or "";
		local textwidth = self:GetTextWidth(linetext .. char);
		if (textwidth >= linewidth) then
			self:InsertTextNotAddToCommand("\r\n", self.cursorLine, self.cursorPos, true);
		end
		self:InsertTextNotAddToCommand(char, self.cursorLine, self.cursorPos, true);
		i = i + 1;
	end
end

function TextControl:InsertTextAddToCommand(text, line, pos, moveCursor)
	self:InsertText(text, line, pos, true, moveCursor);
end

function TextControl:InsertTextNotAddToCommand(text, line, pos, moveCursor)
	--self:RemoveTextNotAddToCommand(self.m_selLineStart, self.m_selPosStart, self.m_selLineEnd, self.m_selPosEnd);
	self:InsertText(text, line, pos, false, moveCursor);
end

function TextControl:InsertText(text, line, pos, addToCommand, moveCursor)
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
	if(not t) then
		local lineStart, posStart, lineEnd, posEnd = self.cursorLine, 0, self.cursorLine + 1, 0;
		if(#self.items == self.cursorLine) then
			lineEnd = self.cursorLine;
			posEnd = self:GetLineText(lineEnd):length();
		end
		t = self:scopeText(lineStart, posStart, lineEnd, posEnd);
	end
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
		if(self:IsAutoTabToSpaces()) then
			local text = self:GetLineText(self.cursorLine);
			if(text and self.cursorPos>0 and self.cursorPos<=text:getFirstWordPosition())then
				local newCursorPos = math.max(0, self.cursorPos-tab_len);
				newCursorPos = math.ceil(newCursorPos/tab_len)*tab_len;
				self:moveCursor(self.cursorLine, newCursorPos, true,true);
				self:del();
				return;
			end
		end
		self:internalDelete(true);
    end
    --self:finishChange(priorState);
end

function TextControl:internalDelete(wasBackspace)
	if(self.cursorLine == 1 and self.cursorPos == 0 and wasBackspace) then
		return;
	end

	local lastLineIndex = #self.items;
	local lastLineLength = self:GetLineText(lastLineIndex):length();
	if(self.cursorLine == lastLineIndex and self.cursorPos == lastLineLength and not wasBackspace) then
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
	line.changed = true;
	text:remove(pos, count);
	
	if(width >= self:GetRealWidth()) then
		self.needRecomputeTextWidth = true;
	end
end

-- @param line: if nil, it means the current line. 
-- return nil or spaces string
function TextControl:GetHeadingSpaces(line)
	local text = self:GetLineText(line or self.cursorLine);
	if(text) then
		text = tostring(text);
		return text:match("^([ \t]+)");
	end
end

function TextControl:newLine(mark)
	local newLineText = "\r\n";

	-- add heading spaces of the current line to the newline
	local headingSpaces = self:GetHeadingSpaces(self.cursorLine)
	if(headingSpaces) then
		newLineText = newLineText..headingSpaces;
	end
	self:InsertTextInCursorPos(newLineText);
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
		line.changed = true;

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

function TextControl:searchNext(text)
	local lineIndex = self.cursorLine;
	local initPos = self.cursorPos + 1;
	local lineUniStr = self:GetLineText(lineIndex)

	local count = 0;

	local sPos, ePos;
	while(not sPos or not ePos) do
		if(initPos > lineUniStr:length()) then
			if(lineIndex == #self.items) then
				lineIndex = 1;
			else
				lineIndex = lineIndex + 1;
			end
			lineUniStr = self:GetLineText(lineIndex);
			initPos = 1;
		end
		if((self.cursorLine ~= #self.items and lineIndex == self.cursorLine + 1) or 
			(self.cursorLine == #self.items and lineIndex == 1)) then
			count = count + 1;
			if(count > 1) then
				break;
			end
		end

		sPos, ePos = lineUniStr:findFirstOf(text, initPos);

		initPos = lineUniStr:length() + 1;
	end

	if(lineIndex and sPos and ePos) then
		local selStart = {line = lineIndex, pos = sPos - 1};
		local selEnd = {line = lineIndex, pos = ePos};
		self:setSelect(selStart, selEnd, selEnd, true);
	end

	self.parent:SearchResult(sPos ~= nil);
end

function TextControl:searchPrevious(text)
	local lineIndex = self.cursorLine;
	local initPos = self.cursorPos + 1;
	local lineUniStr = self:GetLineText(lineIndex)

	local count = 0;

	local sPos, ePos;
	while(not sPos or not ePos) do
		if(initPos > lineUniStr:length()) then
			if(lineIndex == 1) then
				lineIndex = #self.items;
			else
				lineIndex = lineIndex - 1;
			end
			lineUniStr = self:GetLineText(lineIndex);
			initPos = 1;
		end
		if((self.cursorLine ~= 1 and lineIndex == self.cursorLine - 1) or 
			(self.cursorLine == 1 and lineIndex == #self.items)) then
			count = count + 1;
			if(count > 1) then
				break;
			end
		end

		sPos, ePos = lineUniStr:findFirstOf(text, initPos);

		initPos = lineUniStr:length() + 1;
	end

	if(lineIndex and sPos and ePos) then
		local selStart = {line = lineIndex, pos = sPos - 1};
		local selEnd = {line = lineIndex, pos = ePos};
		self:setSelect(selStart, selEnd, selEnd, true);
	end

	self.parent:SearchResult(sPos ~= nil);
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
	if(line > #self.items) then
		line = #self.items;
		pos = 0;
	end

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
	line = (line > #self.items) and #self.items or line;
	line = (line > 1) and line or 1;
	return line;
end

function TextControl:xToPos(text, x, betweenOrOn)
	local text = text or self:GetCurrentLine().text;
    return text:xToCursor(x, betweenOrOn, self:GetFont());
end

function TextControl:cursorToX(text)
	if(text == nil) then
		if(self:GetCurrentLine()) then
			text = self:GetCurrentLine().text;
		else
			return 0;
		end
	end
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
		local self_x = self.parent:ViewRegion():x() - clip_x_to_self;
		self:scrollX(self_x - self:x());
		--self:setX(self_x, true);
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
		local clip = self.parent:ViewRegion();
		
		if(self:GetRealWidth() < clip:width()) then
			self:scrollX(clip:x() - self:x());	
			self:setWidth(clip:width());
		else
			self:setWidth(self:GetRealWidth());
		end

		if(self:GetRealHeight() < clip:height()) then
			self:scrollY(clip:y() - self:y());			
			self:setHeight(clip:height());
		else
			if(self:y() == 0) then
				self:scrollY(clip:y() - self:y());
			end
			self:setHeight(self:GetRealHeight());
		end
	end
end

function TextControl:CalculateTextWidth(text,font)
	return _guihelper.GetTextWidth(text, font);
end

function TextControl:DrawTextScaledWithPosition(painter, x, y, text, font, color, scale)
	font = font or self:GetFont();
	scale = scale or self:GetScale();
	color = color or self:GetColor();
	painter:SetFont(font);
	painter:SetPen(color);
	painter:DrawTextScaled(x, y, text, scale);
end

function TextControl:LanguageFormat(lineItem)
	if(self.language and lineItem.changed) then
		self.syntaxAnalyzer = self.syntaxAnalyzer or SyntaxAnalysis.CreateAnalyzer(self.language);
		if(not self.syntaxAnalyzer) then
			return;
		end

		lineItem.highlightBlocks = {};
		
		local uniStr = lineItem.text;
		for token in self.syntaxAnalyzer:GetToken(uniStr) do
			if(token.type) then
				-- we will add non-token to highlight blocks as well. 
				local count = #(lineItem.highlightBlocks);
				if(count == 0) then
					if(token.spos > 1) then
						self:AddHighLightBlock(lineItem, 1, token.spos);
					end
				else
					local lastItem = lineItem.highlightBlocks[count];
					if((lastItem.end_pos + 1) < token.spos) then
						self:AddHighLightBlock(lineItem, lastItem.end_pos + 1, token.spos-1);
					end
				end

				local font = self:GetFont();
				if(token.bold) then
					font = string.gsub(font,"(%a+;%d+;)(%a+)","%1bold")
				end
				self:AddHighLightBlock(lineItem, token.spos, token.epos, font, token.color, nil);
			end
		end
		local count = #(lineItem.highlightBlocks);
		if(count > 0) then
			local lastItem = lineItem.highlightBlocks[count];
			local length = uniStr:length();
			if(lastItem.end_pos < length) then
				self:AddHighLightBlock(lineItem, lastItem.end_pos+1, length);
			end
		end
		lineItem.changed = false;
	end
end

function TextControl:ApplyCss(css)
	TextControl._super.ApplyCss(self, css);
	if(css["caret-color"]) then
		self:SetCursorColor(css["caret-color"]);
	end
	local font, fontSize, fontScale = css:GetFontSettings();
	if (font) then self:SetFont(font) end
	if (fontScale) then self:SetScale(fontScale) end
	if (css["color"]) then self:SetColor(css["color"]) end
	css["line-height"] = css["line-height"] or math.floor(1.5 * (fontSize or 14));
	self:SetLineHeight(css["line-height"]);
end

function TextControl:GetCursorPositionInClient()
	local cursor_x = self:cursorToX();
	local cursor_y = (self.cursorLine - 1) * self.lineHeight;
	return cursor_x, cursor_y
end

function TextControl:GetFromLine()
	return self.from_line
end

function TextControl:SetFromLine(from_line)
	-- we need to wait for next paint event for from_line to take effect
	if(from_line > #self.items ) then
		from_line = #self.items;
	end
	self.target_from_line = from_line;
end


function TextControl:paintEvent(painter)
	if(self.needRecomputeTextHeight or self.needRecomputeTextWidth or self.needUpdateControlSize) then
		self:updateGeometry();
	end
	if(self.target_from_line) then
		local from_line = self.target_from_line;
		self.target_from_line = nil;
		self:setY(-((self.lineHeight * math.max(0, from_line -1)) - self.parent:ViewRegionOffsetY()), true)	
	end
	local clipRegion = self:ClipRegion();
	self.from_line = math.max(1, 1 + math.floor((-(self:y() - self.parent:ViewRegionOffsetY())) / self.lineHeight)); 
	self.to_line = math.min(self.items:size(), 1 + math.ceil((-self:y() + clipRegion:height()) / self.lineHeight));

	
	if(not self:isReadOnly() and (self:isAlwaysShowCurLineBackground() or (self.cursorVisible and self:hasFocus()))) then
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
			for i = math.max(self.from_line, self.m_selLineStart), math.min(self.to_line, self.m_selLineEnd) do
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
		for i = self.from_line, self.to_line do
			local item = self.items:get(i);	
			local text = item.text;
			local next_block;

			self:LanguageFormat(item);

			if(item.highlightBlocks and next(item.highlightBlocks)) then
				-- this line have highlight blocks;				
				for j = 1, #item.highlightBlocks do
					local block = item.highlightBlocks[j];						
					if(not block.text) then
						--  cache text on first draw
						block.text = text:substr(block.begin_pos, block.end_pos);
					end
					if(not block.x) then
						-- cache text width on first draw
						-- tricky: it is important to calculate by all heading text instead of adding all text width together
						-- since there could be rounding errors on MaxOS for special chars like "".
						-- and in XtoCursor function, we also assume text position is calculated in this way.
						if(block.begin_pos > 1) then
							local leftText = text:substr(1, block.begin_pos - 1);
							block.x = self:CalculateTextWidth(leftText, self:GetFont());
						else
							block.x = 0;
						end
					end
					self:DrawTextScaledWithPosition(painter, self:x() + block.x, self:y() + self.lineHeight * (i - 1), block.text, block.font, block.color, block.scale);
				end							
			else
				self:DrawTextScaledWithPosition(painter, self:x(), self:y() + self.lineHeight * (i - 1), item.text:GetText());
			end
		end
	else
		local EmptyText = self:GetEmptyText();
		if(EmptyText and EmptyText~="" and not self:hasFocus()) then
			local i = 1;
			painter:SetPen(self:GetEmptyTextColor());
			for line_text, breaker_text in string.gfind(EmptyText, "([^\r\n]*)(\r?\n?)") do
				if(line_text ~= "") then
					self:DrawTextScaledWithPosition(painter, self:x(), self:y() + self.lineHeight * (i - 1), line_text);
				end	
				i = i + 1;
			end
		end
	end

	-- draw cursor even for readonly mode, since we will allow selection and copy paste
	if(self.cursorVisible and self:hasFocus()) then
		-- draw cursor
		if(self.m_blinkPeriod==0 or self.m_blinkStatus) then
			local cursor_x = self:cursorToX();
			local cursor_y = (self.cursorLine - 1) * self.lineHeight;
			painter:SetPen(self:GetCursorColor());
			painter:DrawRect(self:x() + cursor_x, self:y() + cursor_y, self.m_cursorWidth, self.lineHeight);
		end
	elseif(self:isAlwaysShowCurLineBackground()) then
		local cursor_x = self:cursorToX();
		local cursor_y = (self.cursorLine - 1) * self.lineHeight;
		painter:SetPen(self:GetStaticCursorColor());
		painter:DrawRect(self:x() + cursor_x, self:y() + cursor_y, self.m_cursorWidth, self.lineHeight);
	end
end
