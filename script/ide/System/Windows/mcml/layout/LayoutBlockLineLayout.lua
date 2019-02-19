--[[
Title: 
Author(s): LiPeng
Date: 2018/2/9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlockLineLayout.lua");
local LayoutBlock = commonlib.gettable("System.Windows.mcml.layout.LayoutBlock");
LayoutBlock:new():init();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlock.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/InLineIterator.lua");
--NPL.load("(gl)script/ide/System/Windows/mcml/platform/Length.lua");
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Core/UniString.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObject.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/text/BidiResolver.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/text/TextBreakIterator.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/BreakLines.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/BidiRun.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/RootInlineBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
local Size = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local BidiRun = commonlib.gettable("System.Windows.mcml.layout.BidiRun");
local InlineBidiResolver = commonlib.gettable("System.Windows.mcml.layout.InlineBidiResolver");
local BreakLines = commonlib.gettable("System.Windows.mcml.layout.BreakLines");
local LazyLineBreakIterator = commonlib.gettable("System.Windows.mcml.platform.text.LazyLineBreakIterator");
local InlineIterator = commonlib.gettable("System.Windows.mcml.layout.InlineIterator");
local BidiStatus = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.platform.text.BidiStatus"));
local BidiResolver = commonlib.gettable("System.Windows.mcml.platform.text.BidiResolver");
local UniString = commonlib.gettable("System.Core.UniString");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");
--local Length = commonlib.gettable("System.Windows.mcml.platform.Length");
local InlineWalker = commonlib.gettable("System.Windows.mcml.layout.InlineWalker");
local LayoutBlock = commonlib.gettable("System.Windows.mcml.layout.LayoutBlock");
local FloatingObject = commonlib.gettable("System.Windows.mcml.layout.LayoutBlock.FloatingObject");
local FloatWithRect = commonlib.gettable("System.Windows.mcml.layout.LayoutBlock.FloatWithRect");
local TrailingFloatsRootInlineBox = commonlib.gettable("System.Windows.mcml.layout.TrailingFloatsRootInlineBox");
local MidpointState = commonlib.gettable("System.Windows.mcml.platform.text.MidpointState");

local LineMidpointState = MidpointState;

local WhiteSpaceEnum = ComputedStyleConstants.WhiteSpaceEnum;
local ClearEnum = ComputedStyleConstants.ClearEnum;
local NBSPModeEnum = ComputedStyleConstants.NBSPModeEnum;
local WordBreakEnum = ComputedStyleConstants.WordBreakEnum;
local UnicodeBidiEnum = ComputedStyleConstants.UnicodeBidiEnum;
local TextAlignEnum = ComputedStyleConstants.TextAlignEnum;
local OrderEnum = ComputedStyleConstants.OrderEnum;
local TextDirectionEnum = ComputedStyleConstants.TextDirectionEnum;

local IntRect, IntSize = Rect, Size;

local INT_MAX = 0xffffffff;

local LineWidth = commonlib.inherit(nil, {});
local LineBreaker = commonlib.inherit(nil, {});
local LineLayoutState = commonlib.inherit(nil, {});
local LineInfo = commonlib.inherit(nil, {});
local TrailingObjects = commonlib.inherit(nil, {});

function TrailingObjects:ctor()
	self.m_whitespace = nil;
	self.m_boxes = commonlib.vector:new();
end


--inline void TrailingObjects::setTrailingWhitespace(RenderText* whitespace)
function TrailingObjects:SetTrailingWhitespace(whitespace)
    --ASSERT(whitespace);
    self.m_whitespace = whitespace;
end

function TrailingObjects:Clear()
    self.m_whitespace = nil;
    self.m_boxes:clear();
end

--inline void TrailingObjects::appendBoxIfNeeded(RenderBox* box)
function TrailingObjects:AppendBoxIfNeeded(box)
    if (self.m_whitespace) then
        self.m_boxes:append(box);
	end
end

--static void checkMidpoints(LineMidpointState& lineMidpointState, InlineIterator& lBreak)
local function checkMidpoints(lineMidpointState, lBreak)
    -- Check to see if our last midpoint is a start point beyond the line break.  If so,
    -- shave it off the list, and shave off a trailing space if the previous end point doesn't
    -- preserve whitespace.
    if (lBreak.obj and lineMidpointState.numMidpoints ~= 0 and (lineMidpointState.numMidpoints % 2) == 0) then
        local midpoints = lineMidpointState.midpoints;
        local endpoint = midpoints[lineMidpointState.numMidpoints - 2];
        local startpoint = midpoints[lineMidpointState.numMidpoints - 1];
        local currpoint = endpoint;
        while (not currpoint:AtEnd() and currpoint ~= startpoint and currpoint ~= lBreak) do
            currpoint:Increment();
		end
        if (currpoint == lBreak) then
            -- We hit the line break before the start point.  Shave off the start point.
            lineMidpointState.numMidpoints = lineMidpointState.numMidpoints - 1;
            if (endpoint.obj:Style():CollapseWhiteSpace()) then
                endpoint.pos = endpoint.pos - 1;
			end
        end
    end
end

--static void addMidpoint(LineMidpointState& lineMidpointState, const InlineIterator& midpoint)
local function addMidpoint(lineMidpointState, midpoint)
--    if (lineMidpointState.midpoints.size() <= lineMidpointState.numMidpoints)
--        lineMidpointState.midpoints.grow(lineMidpointState.numMidpoints + 10);

    local midpoints = lineMidpointState.midpoints;
	lineMidpointState.numMidpoints = lineMidpointState.numMidpoints + 1;
    midpoints[lineMidpointState.numMidpoints] = midpoint;
end

--void TrailingObjects::updateMidpointsForTrailingBoxes(LineMidpointState& lineMidpointState, const InlineIterator& lBreak, CollapseFirstSpaceOrNot collapseFirstSpace)
function TrailingObjects:UpdateMidpointsForTrailingBoxes(lineMidpointState, lBreak, collapseFirstSpace)
    if (not self.m_whitespace) then
        return;
	end

    -- This object is either going to be part of the last midpoint, or it is going to be the actual endpoint.
    -- In both cases we just decrease our pos by 1 level to exclude the space, allowing it to - in effect - collapse into the newline.
    if (lineMidpointState.numMidpoints % 2 ~= 0) then
        -- Find the trailing space object's midpoint.
        local trailingSpaceMidpoint = lineMidpointState.numMidpoints - 1;
		while(trailingSpaceMidpoint > 0 and lineMidpointState.midpoints[trailingSpaceMidpoint].obj ~= self.m_whitespace) do
			trailingSpaceMidpoint = trailingSpaceMidpoint - 1;
		end
        --for ( ; trailingSpaceMidpoint > 0 && lineMidpointState.midpoints[trailingSpaceMidpoint].m_obj != m_whitespace; --trailingSpaceMidpoint) { }
        --ASSERT(trailingSpaceMidpoint >= 0);
        if (collapseFirstSpace == "CollapseFirstSpace") then
            lineMidpointState.midpoints[trailingSpaceMidpoint].pos = lineMidpointState.midpoints[trailingSpaceMidpoint].pos - 1;
		end

        -- Now make sure every single trailingPositionedBox following the trailingSpaceMidpoint properly stops and starts
        -- ignoring spaces.
        local currentMidpoint = trailingSpaceMidpoint + 1;
        --for (size_t i = 0; i < m_boxes.size(); ++i) {
		for i = 1, self.m_boxes:size() do
            if (currentMidpoint >= lineMidpointState.numMidpoints) then
                -- We don't have a midpoint for this box yet.
                local ignoreStart = InlineIterator:new():init(nil, self.m_boxes[i], 1);
                addMidpoint(lineMidpointState, ignoreStart); -- Stop ignoring.
                addMidpoint(lineMidpointState, ignoreStart); -- Start ignoring again.
            else
                --ASSERT(lineMidpointState.midpoints[currentMidpoint].m_obj == m_boxes[i]);
                --ASSERT(lineMidpointState.midpoints[currentMidpoint + 1].m_obj == m_boxes[i]);
            end
            currentMidpoint = currentMidpoint + 2;
        end
    elseif (not lBreak.obj) then
        --ASSERT(m_whitespace->isText());
        --ASSERT(collapseFirstSpace == CollapseFirstSpace);
        -- Add a new end midpoint that stops right at the very end.
        local length = self.m_whitespace:TextLength();
        local pos = if_else(length >= 2 , length - 2, INT_MAX);
        local endMid=InlineIterator:new():init(nil, self.m_whitespace, pos);
        addMidpoint(lineMidpointState, endMid);
        for i = 1, self.m_boxes:size() do
            local ignoreStart = InlineIterator:new():init(nil, self.m_boxes[i], 1);
            addMidpoint(lineMidpointState, ignoreStart); -- Stop ignoring spaces.
            addMidpoint(lineMidpointState, ignoreStart); -- Start ignoring again.
        end
    end
end

function LineBreaker:ctor()
	self.block = nil;
    self.hyphenated = nil;
    self.clear = nil;
    self.positionedObjects = commonlib.vector:new();
end

function LineBreaker:init(block)
	self.block = block;
	self:Reset();
	return self;
end

function LineBreaker:Reset()
	self.positionedObjects:clear();
    self.hyphenated = false;
    self.clear = ClearEnum.CNONE;
end

local cMaxLineDepth = 200;

local function borderPaddingMarginStart(child)
    return child:MarginStart() + child:PaddingStart() + child:BorderStart();
end

local function borderPaddingMarginEnd(child)
    return child:MarginEnd() + child:PaddingEnd() + child:BorderEnd();
end

local function inlineLogicalWidth(child, _start, _end)
	_start = if_else(_start == nil, true, _start);
	_end = if_else(_end == nil, true, _end);
    local lineDepth = 1;
    local extraWidth = 0;
    local parent = child:Parent();
	while(parent:IsLayoutInline() and lineDepth < cMaxLineDepth) do
		local parentAsRenderInline = parent;
		if (_start and not child:PreviousSibling()) then
            extraWidth = extraWidth + borderPaddingMarginStart(parentAsRenderInline);
		end
        if (_end and not child:NextSibling()) then
            extraWidth = extraWidth + borderPaddingMarginEnd(parentAsRenderInline);
		end
        child = parent;
        parent = child:Parent();

		lineDepth = lineDepth + 1;
	end
    return extraWidth;
end
-- @param text: LayoutText
local function textWidth(text, from, len, font)
	local uniText = text:Characters();
	return uniText:GetWidth(font, from, len);
end

--static bool inlineFlowRequiresLineBox(RenderInline* flow)
local function inlineFlowRequiresLineBox(flow)
    -- FIXME: Right now, we only allow line boxes for inlines that are truly empty.
    -- We need to fix this, though, because at the very least, inlines containing only
    -- ignorable whitespace should should also have line boxes.
    --return !flow->firstChild() && flow->hasInlineDirectionBordersPaddingOrMargin();
	return flow:FirstChild() == nil and flow:HasInlineDirectionBordersPaddingOrMargin();
end

-- This is currently just used for list markers and inline flows that have line boxes. Neither should
-- have an effect on whitespace at the start of the line.
--static bool shouldSkipWhitespaceAfterStartObject(RenderBlock* block, RenderObject* o, LineMidpointState& lineMidpointState)
local function shouldSkipWhitespaceAfterStartObject(block, obj, lineMidpointState)
    local next = InlineWalker.BidiNextSkippingEmptyInlines(block, obj);
    if (next ~= nil and (not next:IsBR()) and next:IsText() and next:TextLength() > 0) then
        local nextText = next;
        local nextChar = nextText:Characters()[0];
        if (nextText:Style():IsCollapsibleWhiteSpace(nextChar)) then
            addMidpoint(lineMidpointState, InlineIterator:new():init(nil, o, 1));
            return true;
        end
    end

    return false;
end

function LineBreaker:NextLineBreak(resolver, lineInfo, lineBreakIteratorInfo, lastFloatFromPreviousLine, consecutiveHyphenatedLines)
	echo("LineBreaker:NextLineBreak")
	self:Reset();

	local appliedStartWidth = resolver:Position().pos > 1;
    local includeEndWidth = true;
	local lineMidpointState = resolver:MidpointState();

	local width = LineWidth:new():init(self.block, lineInfo:IsFirstLine());

	self:SkipLeadingWhitespace(resolver, lineInfo, lastFloatFromPreviousLine, width);
	if (resolver:Position():AtEnd()) then
        return resolver:Position();
	end

	local ignoringSpaces = false;
	local ignoreStart = InlineIterator:new();

	-- This variable tracks whether the very last character we saw was a space.  We use
    -- this to detect when we encounter a second space so we know we have to terminate
    -- a run.
    local currentCharacterIsSpace = false;
    local currentCharacterIsWS = false;
    --TrailingObjects trailingObjects;
	local trailingObjects = TrailingObjects:new();

	local lBreak = resolver:Position():Clone();

	-- FIXME: It is error-prone to split the position object out like this.
    -- Teach this code to work with objects instead of this split tuple.
    local current = resolver:Position():Clone();
    local last = current.obj;
	local atStart = true;

	local startingNewParagraph = lineInfo:PreviousLineBrokeCleanly();
    lineInfo:SetPreviousLineBrokeCleanly(false);

    local autoWrapWasEverTrueOnLine = false;
    local floatsFitOnLine = true;

	local allowImagesToBreak = not self.block:IsTableCell() or not self.block:Style():LogicalWidth():IsIntrinsicOrAuto();

	local currWS = self.block:Style():WhiteSpace();
    local lastWS = currWS;

	local go_to_end = false;
	while (current.obj) do
		echo("while (current.obj) do")
		current.obj:PrintNodeInfo();
		if(current.obj:Parent()) then
			current.obj:Parent():PrintNodeInfo();
		else
			echo("current.obj:Parent() not exist")
		end
		if(go_to_end) then
			break;
		end
		local next = InlineWalker.BidiNextSkippingEmptyInlines(self.block, current.obj);
        if (next and next:Parent() and not next:Parent():IsDescendantOf(current.obj:Parent())) then
            includeEndWidth = true;
		end

		if(current.obj:IsReplaced()) then
			currWS = current.obj:Parent():Style():WhiteSpace()
		else
			currWS = current.obj:Style():WhiteSpace()	
		end

		if(last:IsReplaced()) then
			lastWS = last:Parent():Style():WhiteSpace();
		else
			lastWS = last:Style():WhiteSpace();
		end

        local autoWrap = ComputedStyle:AutoWrap(currWS);
        autoWrapWasEverTrueOnLine = autoWrapWasEverTrueOnLine or autoWrap;

        local preserveNewline = ComputedStyle:PreserveNewline(currWS);

        local collapseWhiteSpace = ComputedStyle:CollapseWhiteSpace(currWS);

		if (current.obj:IsBR()) then
			if (width:FitsOnLine()) then
                lBreak:MoveToStartOf(current.obj);
                lBreak:Increment();

                -- A <br> always breaks a line, so don't let the line be collapsed
                -- away. Also, the space at the end of a line with a <br> does not
                -- get collapsed away.  It only does this if the previous line broke
                -- cleanly.  Otherwise the <br> has no effect on whether the line is
                -- empty or not.
                if (startingNewParagraph) then
                    lineInfo:SetEmpty(false, self.block, width);
				end
                trailingObjects:Clear();
                lineInfo:SetPreviousLineBrokeCleanly(true);

                if (not lineInfo:IsEmpty()) then
                    self.clear = current.obj:Style():Clear();
				end
            end

			go_to_end = true;
			break;
		end

		if (current.obj:IsFloating()) then
			echo("current.obj:IsFloating()")
			local floatBox = current.obj;
            local f = self.block:InsertFloatingObject(floatBox);
            -- check if it fits in the current line.
            -- If it does, position it now, otherwise, position
            -- it after moving to next line (in newLine() func)
            if (floatsFitOnLine and width:FitsOnLine(self.block:LogicalWidthForFloat(f))) then
                self.block:PositionNewFloatOnLine(f, lastFloatFromPreviousLine, lineInfo, width);
                if (lBreak.obj == current.obj) then
                    --ASSERT(!lBreak.m_pos);
                    lBreak:Increment();
                end
            else
                floatsFitOnLine = false;
			end
			echo("LayoutBlock:PositionNewFloatOnLine end")
			f:Renderer():PrintNodeInfo()
			echo(f:Renderer().frame_rect)
		elseif(current.obj:IsPositioned()) then

		elseif(current.obj:IsLayoutInline()) then
			-- Right now, we should only encounter empty inlines here.
            --ASSERT(!current.m_obj->firstChild());

            local flowBox = current.obj;

            -- Now that some inline flows have line boxes, if we are already ignoring spaces, we need
            -- to make sure that we stop to include this object and then start ignoring spaces again.
            -- If this object is at the start of the line, we need to behave like list markers and
            -- start ignoring spaces.
            if (inlineFlowRequiresLineBox(flowBox)) then
                lineInfo:SetEmpty(false, self.block, width);
                if (ignoringSpaces) then
                    trailingObjects:Clear();
                    addMidpoint(lineMidpointState, InlineIterator:new():init(nil, current.obj, 1)); -- Stop ignoring spaces.
                    addMidpoint(lineMidpointState, InlineIterator:new():init(nil, current.obj, 1)); -- Start ignoring again.
                elseif (self.block:Style():CollapseWhiteSpace() and resolver:Position().obj == current.obj
                    and shouldSkipWhitespaceAfterStartObject(m_block, current.m_obj, lineMidpointState)) then
                    -- Like with list markers, we start ignoring spaces to make sure that any
                    -- additional spaces we see will be discarded.
                    currentCharacterIsSpace = true;
                    currentCharacterIsWS = true;
                    ignoringSpaces = true;
                end
            end

            width:AddUncommittedWidth(borderPaddingMarginStart(flowBox) + borderPaddingMarginEnd(flowBox));
		elseif(current.obj:IsReplaced()) then
			local replacedBox = current.obj;

            -- Break on replaced elements if either has normal white-space.
            if ((autoWrap or ComputedStyle:AutoWrap(lastWS)) and (not current.obj:IsImage() or allowImagesToBreak)) then
                width:Commit();
                lBreak:MoveToStartOf(current.obj);
            end

            if (ignoringSpaces) then
                addMidpoint(lineMidpointState, InlineIterator:new():init(nil, current.obj, 1));
			end

            lineInfo:SetEmpty(false, self.block, width);
            ignoringSpaces = false;
            currentCharacterIsSpace = false;
            currentCharacterIsWS = false;
            trailingObjects:Clear();

            -- Optimize for a common case. If we can't find whitespace after the list
            -- item, then this is all moot.
            local replacedLogicalWidth = self.block:LogicalWidthForChild(replacedBox) + self.block:MarginStartForChild(replacedBox) + self.block:MarginEndForChild(replacedBox) + inlineLogicalWidth(current.obj);
            if (current.obj:IsListMarker()) then
                if (self.block:Style():CollapseWhiteSpace() and shouldSkipWhitespaceAfterStartObject(self.block, current.obj, lineMidpointState)) then
                    -- Like with inline flows, we start ignoring spaces to make sure that any
                    -- additional spaces we see will be discarded.
                    currentCharacterIsSpace = true;
                    currentCharacterIsWS = true;
                    ignoringSpaces = true;
                end
--                if (toRenderListMarker(current.obj)->isInside())
--					width.addUncommittedWidth(replacedLogicalWidth);
            else
                width:AddUncommittedWidth(replacedLogicalWidth);
			end
            if (current.obj:IsRubyRun()) then
                --width.applyOverhang(toRenderRubyRun(current.obj), last, next);
			end
		elseif(current.obj:IsText()) then
			echo("current.obj:IsText()")
			echo(current.obj:Characters())
			if (current.pos ~= 1) then
				appliedStartWidth = false;
			end

			--RenderText* t = toRenderText(current.m_obj);
			local t = current.obj:ToRenderText();

			local style = t:Style(lineInfo:IsFirstLine());
			--            if (style->hasTextCombine() && current.m_obj->isCombineText())
			--              toRenderCombineText(current.m_obj)->combineText();

			local f = style:Font():ToString();
			--bool canHyphenate = style->hyphens() == HyphensAuto && WebCore::canHyphenate(style->locale());
			local canHyphenate = false;

			local lastSpace = current.pos;
            local wordSpacing = current.obj:Style():WordSpacing();
            local lastSpaceWordSpacing = 0;

			-- Non-zero only when kerning is enabled, in which case we measure words with their trailing
            -- space, then subtract its width.
            --float wordTrailingSpaceWidth = f.typesettingFeatures() & Kerning ? f.width(constructTextRun(t, f, &space, 1, style)) + wordSpacing : 0;
			local wordTrailingSpaceWidth = 0;
			
			local wrapW = width:UncommittedWidth() + inlineLogicalWidth(current.obj, not appliedStartWidth, true);
			local breakNBSP = autoWrap and current.obj:Style():NbspMode() == NBSPModeEnum.SPACE;
			local breakWords = current.obj:Style():BreakWords() and ((autoWrap and width:CommittedWidth() == 0) or currWS == WhiteSpaceEnum.PRE);
			local midWordBreak = false;
			local breakAll = current.obj:Style():WordBreak() == WordBreakEnum.BreakAllWordBreak and autoWrap;
			--float hyphenWidth = 0;

			if (t:IsWordBreak()) then
				width:Commit();
				lBreak:MoveToStartOf(current.obj);
				--ASSERT(current.m_pos == t->textLength());
			end

			local extraWidth = 0;

			while(current.pos <= t:TextLength()) do
				echo("current.pos")
				echo(current.pos)
				local previousCharacterIsSpace = currentCharacterIsSpace;
				local previousCharacterIsWS = currentCharacterIsWS;
				local c = current:Current();
				local c_str = tostring(c);
				currentCharacterIsSpace = c_str == " " or c_str == "\t" or (not preserveNewline and (c_str == "\n"));

				if (not collapseWhiteSpace or not currentCharacterIsSpace) then
                    lineInfo:SetEmpty(false, self.block, width);
				end

--				if (c == softHyphen && autoWrap && !hyphenWidth && style->hyphens() != HyphensNone) {
--                    hyphenWidth = measureHyphenWidth(t, f);
--                    width.addUncommittedWidth(hyphenWidth);
--                }

				local applyWordSpacing = false;

                currentCharacterIsWS = currentCharacterIsSpace or (breakNBSP and UniString.IsSpecialCharacter(UniString.SpecialCharacter.Nbsp));
				if (lineBreakIteratorInfo.first ~= t) then
                    lineBreakIteratorInfo.first = t;
                    lineBreakIteratorInfo.second:Reset(t:Characters(), t:TextLength(), style:Locale());
                end

--				local betweenWords = c == "\n" or (currWS ~= "PRE" and not atStart and isBreakable(lineBreakIteratorInfo.second, current.m_pos, current.m_nextBreakablePosition, breakNBSP)
--                    and (self:Style:Hyphens() ~= "HyphensNone" or (current:PreviousInSameNode() ~= "softHyphen")));
				local isBreakable;
				isBreakable, current.nextBreakablePosition = BreakLines.IsBreakable(lineBreakIteratorInfo.second, current.pos, current.nextBreakablePosition, breakNBSP);
				echo({isBreakable, current.nextBreakablePosition})
				local betweenWords = c_str == "\n" or (currWS ~= WhiteSpaceEnum.PRE and not atStart and isBreakable);
				echo({betweenWords, midWordBreak, ignoringSpaces, currentCharacterIsSpace})
				if((betweenWords or midWordBreak) and ignoringSpaces and currentCharacterIsSpace) then
					-- Just keep ignoring these spaces.
					--continue;
				else
					if(betweenWords or midWordBreak) then
						local stoppedIgnoringSpaces = false;
						if (ignoringSpaces) then
							if (not currentCharacterIsSpace) then
								-- Stop ignoring spaces and begin at this new point.
								ignoringSpaces = false;
								lastSpaceWordSpacing = 0;
								lastSpace = current.pos; -- e.g., "Foo    goo", don't add in any of the ignored spaces.
								addMidpoint(lineMidpointState, InlineIterator:new():init(nil, current.obj, current.pos));
								stoppedIgnoringSpaces = true;
							end
						end

						if(string.byte(c_str, 1) > 127) then
							extraWidth = textWidth(t, current.pos, 0, f);
						end
						echo("extraWidth")
						echo(extraWidth)
						echo({wordTrailingSpaceWidth, currentCharacterIsSpace})
						echo({lastSpace})
						local additionalTmpW;
						if (wordTrailingSpaceWidth ~= 0 and currentCharacterIsSpace) then
							additionalTmpW = textWidth(t, lastSpace, current.pos - lastSpace + 1 - 1, f) - wordTrailingSpaceWidth + lastSpaceWordSpacing;
						else
							additionalTmpW = textWidth(t, lastSpace, current.pos - lastSpace - 1, f) + lastSpaceWordSpacing;
						end
						width:AddUncommittedWidth(additionalTmpW);
						if (not appliedStartWidth) then
							width:AddUncommittedWidth(inlineLogicalWidth(current.obj, true, false));
							appliedStartWidth = true;
						end

						applyWordSpacing =  wordSpacing ~= 0 and currentCharacterIsSpace and not previousCharacterIsSpace;

						if (width:CommittedWidth() == 0 and autoWrap and not width:FitsOnLine()) then
							width:FitBelowFloats();
						end

						echo("width info")
						echo({width:CommittedWidth(), width:UncommittedWidth(), width:AvailableWidth()})
						if (autoWrap or breakWords) then
							local lineWasTooWide = false;
--							if (width.fitsOnLine() && currentCharacterIsWS && current.m_obj->style()->breakOnlyAfterWhiteSpace() && !midWordBreak) {
--								float charWidth = textWidth(t, current.m_pos, 1, f, width.currentWidth(), isFixedPitch, collapseWhiteSpace) + (applyWordSpacing ? wordSpacing : 0);
--								// Check if line is too big even without the extra space
--								// at the end of the line. If it is not, do nothing.
--								// If the line needs the extra whitespace to be too long,
--								// then move the line break to the space and skip all
--								// additional whitespace.
--								if (!width.fitsOnLine(charWidth)) {
--									lineWasTooWide = true;
--									lBreak.moveTo(current.m_obj, current.m_pos, current.m_nextBreakablePosition);
--									skipTrailingWhitespace(lBreak, lineInfo);
--								}
--							}
							if (lineWasTooWide or not width:FitsOnLine()) then
								if (canHyphenate and not width:FitsOnLine()) then
--									tryHyphenating(t, f, style->locale(), consecutiveHyphenatedLines, m_block->style()->hyphenationLimitLines(), style->hyphenationLimitBefore(), style->hyphenationLimitAfter(), lastSpace, current.m_pos, width.currentWidth() - additionalTmpW, width.availableWidth(), isFixedPitch, collapseWhiteSpace, lastSpaceWordSpacing, lBreak, current.m_nextBreakablePosition, m_hyphenated);
--									if (m_hyphenated)
--										goto end;
								end
								if (lBreak:AtTextParagraphSeparator()) then
									if (not stoppedIgnoringSpaces and current.pos > 0) then
										-- We need to stop right before the newline and then start up again.
										addMidpoint(lineMidpointState, InlineIterator:new():init(nil, current.obj, current.pos - 1)); -- Stop
										addMidpoint(lineMidpointState, InlineIterator:new():init(nil, current.obj, current.pos)); -- Start
									end
									lBreak:Increment();
									lineInfo:SetPreviousLineBrokeCleanly(true);
								end
--								if (lBreak.m_obj && lBreak.m_pos && lBreak.m_obj->isText() && toRenderText(lBreak.m_obj)->textLength() && toRenderText(lBreak.m_obj)->characters()[lBreak.m_pos - 1] == softHyphen && style->hyphens() != HyphensNone)
--									m_hyphenated = true;
								go_to_end = true; -- Didn't fit. Jump to the end.
								echo("1111111111111111111")
								break;
							else
								if (not betweenWords or (midWordBreak and not autoWrap)) then
									width:AddUncommittedWidth(-additionalTmpW);
								end
--								if (hyphenWidth) {
--									// Subtract the width of the soft hyphen out since we fit on a line.
--									width.addUncommittedWidth(-hyphenWidth);
--									hyphenWidth = 0;
--								}
							end
						end

						if (c == "\n" and preserveNewline) then
							if (not stoppedIgnoringSpaces and current.pos > 0) then
								-- We need to stop right before the newline and then start up again.
								addMidpoint(lineMidpointState, InlineIterator:new():init(nil, current.obj, current.pos - 1)); -- Stop
								addMidpoint(lineMidpointState, InlineIterator:new():init(nil, current.obj, current.pos)); -- Start
							end
							lBreak:MoveTo(current.obj, current.pos, current.nextBreakablePosition);
							lBreak:Increment();
							lineInfo:SetPreviousLineBrokeCleanly(true);
							return lBreak;
						end

						if (autoWrap and betweenWords) then
							width:Commit();
							wrapW = 0;
							echo("lBreak:MoveTo")
							lBreak:MoveTo(current.obj, current.pos, current.nextBreakablePosition);
							-- Auto-wrapping text should not wrap in the middle of a word once it has had an opportunity to break after a word.
							breakWords = false;
						end

--						if (midWordBreak && !U16_IS_TRAIL(c) && !(category(c) & (Mark_NonSpacing | Mark_Enclosing | Mark_SpacingCombining))) {
--							// Remember this as a breakable position in case
--							// adding the end width forces a break.
--							lBreak.moveTo(current.m_obj, current.m_pos, current.m_nextBreakablePosition);
--							midWordBreak &= (breakWords || breakAll);
--						end

						if (betweenWords) then
							lastSpaceWordSpacing = if_else(applyWordSpacing, wordSpacing, 0);
							lastSpace = current.pos;
						end
						if (not ignoringSpaces and current.obj:Style():CollapseWhiteSpace()) then
							-- If we encounter a newline, or if we encounter a
							-- second space, we need to go ahead and break up this
							-- run and enter a mode where we start collapsing spaces.
							if (currentCharacterIsSpace and previousCharacterIsSpace) then
								ignoringSpaces = true;

--								// We just entered a mode where we are ignoring
--								// spaces. Create a midpoint to terminate the run
--								// before the second space.
								addMidpoint(lineMidpointState, ignoreStart);
								trailingObjects:UpdateMidpointsForTrailingBoxes(lineMidpointState, InlineIterator:new(), "DoNotCollapseFirstSpace");
							end
						end
					elseif (ignoringSpaces) then
						-- Stop ignoring spaces and begin at this new point.
						ignoringSpaces = false;
						lastSpaceWordSpacing = if_else(applyWordSpacing, wordSpacing, 0);
						lastSpace = current.pos; -- e.g., "Foo    goo", don't add in any of the ignored spaces.
						addMidpoint(lineMidpointState, InlineIterator:new():init(nil, current.obj, current.pos));
					end

					if (currentCharacterIsSpace and not previousCharacterIsSpace) then
						ignoreStart.obj = current.obj;
						ignoreStart.pos = current.pos;
					end

					if (not currentCharacterIsWS and previousCharacterIsWS) then
						if (autoWrap and current.obj:Style():BreakOnlyAfterWhiteSpace()) then
							lBreak:MoveTo(current.obj, current.pos, current.nextBreakablePosition);
						end
					end

					if (collapseWhiteSpace and currentCharacterIsSpace and not ignoringSpaces) then
						trailingObjects:SetTrailingWhitespace(current.obj:ToRenderText());
					elseif (not current.obj:Style():CollapseWhiteSpace() or not currentCharacterIsSpace) then
						trailingObjects:Clear();
					end

					atStart = false;
				end
				current:FastIncrementInTextNode();
			end
			if(go_to_end) then
				break;
			end

			-- IMPORTANT: current.m_pos is > length here!
            local additionalTmpW = if_else(ignoringSpaces, 0, textWidth(t, lastSpace, current.pos - lastSpace - 1, f) + lastSpaceWordSpacing);
            width:AddUncommittedWidth(additionalTmpW + inlineLogicalWidth(current.obj, not appliedStartWidth, includeEndWidth));
            includeEndWidth = false;

			if (not width:FitsOnLine()) then
--                if (canHyphenate)
--                    tryHyphenating(t, f, style->locale(), consecutiveHyphenatedLines, m_block->style()->hyphenationLimitLines(), style->hyphenationLimitBefore(), style->hyphenationLimitAfter(), lastSpace, current.m_pos, width.currentWidth() - additionalTmpW, width.availableWidth(), isFixedPitch, collapseWhiteSpace, lastSpaceWordSpacing, lBreak, current.m_nextBreakablePosition, m_hyphenated);

--                if (!m_hyphenated && lBreak.previousInSameNode() == softHyphen && style->hyphens() != HyphensNone)
--                    m_hyphenated = true;

--                if (m_hyphenated)
--                    goto end;
            end
		else
			--ASSERT_NOT_REACHED();
		end
		echo("lBreak 1111111111111")
		if(lBreak.obj) then
			lBreak.obj:PrintNodeInfo()
			if(lBreak.obj:IsText()) then
				echo(lBreak.obj:Characters())
				echo(lBreak.pos)
			end
		end
		echo({width:CommittedWidth(), width:UncommittedWidth(), width:FitsOnLine()})
		local checkForBreak = autoWrap;
        if (width:CommittedWidth() ~= 0 and not width:FitsOnLine() and lBreak.obj and currWS == WhiteSpaceEnum.NOWRAP) then
			echo("3333333333333333333333333333")
            checkForBreak = true;
        elseif (next and current.obj:IsText() and next:IsText() and not next:IsBR() and (autoWrap or (next:Style():AutoWrap()))) then
			echo("44444444444")
            if (currentCharacterIsSpace) then
                checkForBreak = true;
            else
                local nextText = next;
                if (nextText:TextLength()) then
                    local c = nextText:Characters()[0];
                    checkForBreak = (c == " " or c == "\t" or (c == "\n" and not next:PreservesNewline()));
                    -- If the next item on the line is text, and if we did not end with
                    -- a space, then the next text run continues our word (and so it needs to
                    -- keep adding to |tmpW|. Just update and continue.
                elseif (nextText:IsWordBreak()) then
                    checkForBreak = true;
				end

                if (not width:FitsOnLine() and width:CommittedWidth() == 0) then
                    width:FitBelowFloats();
				end

                local canPlaceOnLine = width:FitsOnLine() or not autoWrapWasEverTrueOnLine;
                if (canPlaceOnLine and checkForBreak) then
                    width:Commit();
                    lBreak:MoveToStartOf(next);
                end
            end
        end
		if (checkForBreak and not width:FitsOnLine()) then
            -- if we have floats, try to get below them.
            if (currentCharacterIsSpace and not ignoringSpaces and current.obj:Style():CollapseWhiteSpace()) then
                trailingObjects:Clear();
			end
			echo("5555555555555555");
            if (width:CommittedWidth() ~= 0) then
                go_to_end = true;
				break;
			end

            width:FitBelowFloats();

            -- |width| may have been adjusted because we got shoved down past a float (thus
            -- giving us more room), so we need to retest, and only jump to
            -- the end label if we still don't fit on the line. -dwh
            if (not width:FitsOnLine()) then
				go_to_end = true;
				break;
			end
        end

        if (not current.obj:IsFloatingOrPositioned()) then
            last = current.obj;
            --if (last:IsReplaced() and autoWrap and (not last:IsImage() or allowImagesToBreak) && (!last->isListMarker() || toRenderListMarker(last)->isInside())) {
			if (last:IsReplaced() and autoWrap and (not last:IsImage() or allowImagesToBreak)) then
                width:Commit();
                lBreak:MoveToStartOf(next);
            end
        end

        -- Clear out our character space bool, since inline <pre>s don't collapse whitespace
        -- with adjacent inline normal/nowrap spans.
        if (not collapseWhiteSpace) then
            currentCharacterIsSpace = false;
		end
        current:MoveToStartOf(next);
        atStart = false;
	end

	echo("lBreak go_to_end before")
	echo(go_to_end)
	if(lBreak.obj) then
		lBreak.obj:PrintNodeInfo()
		if(lBreak.obj:IsText()) then
			echo(lBreak.obj:Characters())
			echo(lBreak.pos)
		end
	end

	if(not go_to_end) then
		if (width:FitsOnLine() or lastWS == WhiteSpaceEnum.NOWRAP) then
			lBreak:Clear();
		end
	end
	echo("resolver:Position")
	resolver:Position().obj:PrintNodeInfo()
	if(resolver:Position().obj:IsText()) then
		echo(resolver:Position().obj:Characters())
	end
	echo(resolver:Position().pos)
	echo("lBreak")
	if(lBreak.obj) then
		lBreak.obj:PrintNodeInfo()
		if(lBreak.obj:IsText()) then
			echo(lBreak.obj:Characters())
		end
		echo(lBreak.pos)
	end
	if (lBreak:Equal(resolver:Position()) and (not lBreak.obj or not lBreak.obj:IsBR())) then
        -- we just add as much as possible
        if (self.block:Style():WhiteSpace() == WhiteSpaceEnum.PRE) then
            -- FIXME: Don't really understand this case.
            if (current.pos) then
                -- FIXME: This should call moveTo which would clear m_nextBreakablePosition
                -- this code as-is is likely wrong.
                lBreak.obj = current.obj;
                lBreak.pos = current.pos - 1;
            else
                lBreak:MoveTo(last, if_else(last:IsText(), last:Length(), 1));
			end
        elseif (lBreak.obj) then
            -- Don't ever break in the middle of a word if we can help it.
            -- There's no room at all. We just have to be on this line,
            -- even though we'll spill out.
            lBreak:MoveTo(current.obj, current.pos);
        end
    end

    -- make sure we consume at least one char/object.
    if (lBreak:Equal(resolver:Position())) then
        lBreak:Increment();
	end

    -- Sanity check our midpoints.
    checkMidpoints(lineMidpointState, lBreak);

    trailingObjects:UpdateMidpointsForTrailingBoxes(lineMidpointState, lBreak, "CollapseFirstSpace");

    -- We might have made lBreak an iterator that points past the end
    -- of the object. Do this adjustment to make it point to the start
    -- of the next object instead to avoid confusing the rest of the
    -- code.
    if (lBreak.pos > 1) then
        lBreak.pos = lBreak.pos - 1;
        lBreak:Increment();
    end
	echo("lBreak")
	if(lBreak.obj) then
		lBreak.obj:PrintNodeInfo()
		if(lBreak.obj:IsText()) then
			echo(lBreak.obj:Characters())
			echo(lBreak.pos)
		end
	end

--	if(lBreak.obj and lBreak.obj:IsText()) then
--		local ch = tostring(lBreak:Current())
--		if(string.byte(ch, 1) > 127) then
--			lBreak:Increment();
--		end
--	end
	
    return lBreak;
end

function LineBreaker:LineWasHyphenated()
	return self.hyphenated;
end

function LineBreaker:PositionedObjects()
	return self.positionedObjects;
end

function LineBreaker:Clear() 
	return self.clear;
end

-- @param flow: LayoutInline
local function InlineFlowRequiresLineBox(flow)
    -- FIXME: Right now, we only allow line boxes for inlines that are truly empty.
    -- We need to fix this, though, because at the very least, inlines containing only
    -- ignorable whitespace should should also have line boxes.
    return not flow:FirstChild() and flow:HasInlineDirectionBordersPaddingOrMargin();
end
-- @param whitespacePosition: "LeadingWhitespace", "TrailingWhitespace";
local function shouldCollapseWhiteSpace(style, lineInfo, whitespacePosition)
	-- CSS2 16.6.1
    -- If a space (U+0020) at the beginning of a line has 'white-space' set to 'normal', 'nowrap', or 'pre-line', it is removed.
    -- If a space (U+0020) at the end of a line has 'white-space' set to 'normal', 'nowrap', or 'pre-line', it is also removed.
    -- If spaces (U+0020) or tabs (U+0009) at the end of a line have 'white-space' set to 'pre-wrap', UAs may visually collapse them.
    return style:CollapseWhiteSpace()
        or (whitespacePosition == "TrailingWhitespace" and style:WhiteSpace() == WhiteSpaceEnum.PRE_WRAP and (not lineInfo:IsEmpty() or not lineInfo:PreviousLineBrokeCleanly()));
end

local noBreakSpace = UniString.SpecialCharacter.Nbsp;
local softHyphen = UniString.SpecialCharacter.SoftHyphen;

-- @param it:InlineIterator
local function skipNonBreakingSpace(it, lineInfo)
	-- if (it.m_obj->style()->nbspMode() != SPACE || it.current() != noBreakSpace)
    if (it.obj:Style():NbspMode() ~= NBSPModeEnum.SPACE or string.byte(it:Current(),1) ~= noBreakSpace) then
        return false;
	end
    -- FIXME: This is bad.  It makes nbsp inconsistent with space and won't work correctly
    -- with m_minWidth/m_maxWidth.
    -- Do not skip a non-breaking space if it is the first character
    -- on a line after a clean line break (or on the first line, since previousLineBrokeCleanly starts off
    -- |true|).
    if (lineInfo:IsEmpty() and lineInfo:PreviousLineBrokeCleanly()) then
        return false;
	end
    return true;
end

-- @param it:InlineIterator
-- static bool requiresLineBox(const InlineIterator& it, const LineInfo& lineInfo = LineInfo(), WhitespacePosition whitespacePosition = LeadingWhitespace)
local function requiresLineBox(it, lineInfo, whitespacePosition)
	lineInfo = lineInfo or LineInfo:new();
	whitespacePosition = whitespacePosition or "LeadingWhitespace";
    if (it.obj:IsFloatingOrPositioned()) then
        return false;
	end

    if (it.obj:IsLayoutInline() and not InlineFlowRequiresLineBox(it.obj)) then
        return false;
	end

    if (not shouldCollapseWhiteSpace(it.obj:Style(), lineInfo, whitespacePosition) or it.obj:IsBR()) then
        return true;
	end
    local current = it:Current();
	local current_str = if_else(current, tostring(current), "");
	echo("current_str")
	echo(current_str)
    return current_str ~= " " and current_str ~= "\t" and string.byte(current_str, 1) ~= softHyphen and (current_str ~= "\n" or it.obj:PreservesNewline()) and not skipNonBreakingSpace(it, lineInfo);
end

--static inline bool isCollapsibleSpace(UChar character, RenderText* renderer)
local function isCollapsibleSpace(character, renderer)
    if (character == " " or character == "\t" or character == softHyphen) then
        return true;
	end
    if (character == "\n") then
        return not renderer:Style():PreserveNewline();
	end
    if (character == noBreakSpace) then
        return renderer:Style():NbspMode() == NBSPModeEnum.SPACE;
	end
    return false;
end

--static void setStaticPositions(RenderBlock* block, RenderBox* child)
local function setStaticPositions(block, child)
	-- FIXME: The math here is actually not really right. It's a best-guess approximation that
    -- will work for the common cases
    local containerBlock = child:Container();
    local blockHeight = block:LogicalHeight();
    if (containerBlock:IsLayoutInline()) then
--        // A relative positioned inline encloses us. In this case, we also have to determine our
--        // position as though we were an inline. Set |staticInlinePosition| and |staticBlockPosition| on the relative positioned
--        // inline so that we can obtain the value later.
--        toRenderInline(containerBlock)->layer()->setStaticInlinePosition(block->startAlignedOffsetForLine(child, blockHeight, false));
--        toRenderInline(containerBlock)->layer()->setStaticBlockPosition(blockHeight);
    end

	if (child:Style():IsOriginalDisplayInlineType()) then
        block:SetStaticInlinePositionForChild(child, blockHeight, block:StartAlignedOffsetForLine(child, blockHeight, false));
    else
        block:SetStaticInlinePositionForChild(child, blockHeight, block:StartOffsetForContent(blockHeight));
	end
    child:Layer():SetStaticBlockPosition(blockHeight);
end

function LineBreaker:SkipTrailingWhitespace(iterator, lineInfo)
	while (not iterator:AtEnd() and not requiresLineBox(iterator, lineInfo, TrailingWhitespace)) do
        local object = iterator.obj;
        if (object:IsFloating()) then
            self.block:InsertFloatingObject(object:ToRenderBox());
        elseif (object:IsPositioned()) then
            setStaticPositions(self.block, object:ToRenderBox());
		end
        iterator:Increment();
    end
end

function LineBreaker:SkipLeadingWhitespace(resolver, lineInfo, lastFloatFromPreviousLine, width)
	echo("LineBreaker:SkipLeadingWhitespace")
	while (not resolver:Position():AtEnd() and not requiresLineBox(resolver:Position(), lineInfo, "LeadingWhitespace")) do
		echo("while (not resolver:Position():AtEnd")
        local object = resolver:Position().obj;
        if (object:IsFloating()) then
            self.block:PositionNewFloatOnLine(self.block:InsertFloatingObject(object), lastFloatFromPreviousLine, lineInfo, width);
			echo("object.frame_rect")
			echo(object.frame_rect)

        elseif (object:IsPositioned()) then
            setStaticPositions(self.block, object);
		end
        resolver:Increment();
    end
end


function LineLayoutState:ctor()
	self.floats = commonlib.vector:new();
	self.lastFloat = nil;
	self.endLine = nil;
	self.lineInfo = LineInfo:new();
    self.floatIndex = 1;
    self.endLineLogicalTop = 0;
    self.endLineMatched = false;
    self.checkForFloatsFromLastLine = false;
    
    self.isFullLayout = nil;

    -- FIXME: Should this be a range object instead of two ints?
    self.repaintLogicalTop = nil;
    self.repaintLogicalBottom = nil;
    
    --self.usesRepaintBounds = false;
	self.usesRepaintBounds = true;



--	Vector<RenderBlock::FloatWithRect> m_floats;
--    RenderBlock::FloatingObject* m_lastFloat;
--    RootInlineBox* m_endLine;
--    LineInfo m_lineInfo;
--    unsigned m_floatIndex;
--    int m_endLineLogicalTop;
--    bool m_endLineMatched;
--    bool m_checkForFloatsFromLastLine;
--    
--    bool m_isFullLayout;
--
--    // FIXME: Should this be a range object instead of two ints?
--    int& m_repaintLogicalTop;
--    int& m_repaintLogicalBottom;
--    
--    bool m_usesRepaintBounds;
end

function LineLayoutState:init(fullLayout, repaintLogicalTop, repaintLogicalBottom)
	self.isFullLayout = fullLayout;
	self.repaintLogicalTop = repaintLogicalTop;
    self.repaintLogicalBottom = repaintLogicalBottom;

	return self;
end

function LineLayoutState:MarkForFullLayout()
	self.isFullLayout = true;
end

function LineLayoutState:IsFullLayout()
	return self.isFullLayout;
end


function LineLayoutState:UsesRepaintBounds()
	return self.usesRepaintBounds;
end


function LineLayoutState:SetRepaintRange(logicalHeight)
	self.usesRepaintBounds = true;
	self.repaintLogicalTop = logicalHeight; 
	self.repaintLogicalBottom = logicalHeight; 
end

function LineLayoutState:RepaintLogicalTop()
	return self.repaintLogicalTop;
end

function LineLayoutState:RepaintLogicalBottom()
	return self.repaintLogicalBottom;
end

function LineLayoutState:UpdateRepaintRangeFromBox(box, paginationDelta)
	paginationDelta = paginationDelta or 0;
	self.usesRepaintBounds = true;
	self.repaintLogicalTop = math.min(self.repaintLogicalTop, box:LogicalTopVisualOverflow() + math.min(paginationDelta, 0));
	self.repaintLogicalBottom = math.max(self.repaintLogicalBottom, box:LogicalBottomVisualOverflow() + math.max(paginationDelta, 0));
end

function LineLayoutState:EndLineMatched()
	return self.endLineMatched;
end

function LineLayoutState:SetEndLineMatched(endLineMatched)
	self.endLineMatched = endLineMatched;
end


function LineLayoutState:CheckForFloatsFromLastLine()
	return self.checkForFloatsFromLastLine;
end

function LineLayoutState:SetCheckForFloatsFromLastLine(check)
	self.checkForFloatsFromLastLine = check;
end


function LineLayoutState:LineInfo()
	return self.lineInfo;
end

function LineLayoutState:EndLineLogicalTop()
	return self.endLineLogicalTop;
end

function LineLayoutState:SetEndLineLogicalTop(logicalTop)
	self.endLineLogicalTop = logicalTop;
end


function LineLayoutState:EndLine()
	return self.endLine;
end

function LineLayoutState:SetEndLine(line)
	self.endLine = line;
end


function LineLayoutState:LastFloat()
	return self.lastFloat;
end

function LineLayoutState:SetLastFloat(lastFloat)
	self.lastFloat = lastFloat;
end


function LineLayoutState:Floats()
	return self.floats;
end


function LineLayoutState:FloatIndex()
	return self.floatIndex;
end

function LineLayoutState:SetFloatIndex(floatIndex)
	self.floatIndex = floatIndex;
end

function LineWidth:ctor()
	self.block = nil;
    self.uncommittedWidth = 0;
    self.committedWidth = 0;
    self.overhangWidth = 0; -- The amount by which |m_availableWidth| has been inflated to account for possible contraction due to ruby overhang.
    self.left = 0;
    self.right = 0;
    self.availableWidth = 0;
    self.isFirstLine = false;
end

function LineWidth:init(block, isFirstLine)
	self.block = block;
	self.isFirstLine = isFirstLine;
	--ASSERT(block);
	self:UpdateAvailableWidth();

	return self;
end

function LineWidth:PrintInfo()
	echo({self.committedWidth, self.uncommittedWidth, self.availableWidth, self.left, self.right})
end

function LineWidth:FitsOnLine(extra, currentWidth)
	extra = extra or 0;
	-- we use "currentWidth", because "self.committedWidth","self.uncommittedWidth" is invalid data;
	currentWidth = currentWidth or self:CurrentWidth();
	return currentWidth + extra <= self.availableWidth;
end

function LineWidth:CurrentWidth()
	return self.committedWidth + self.uncommittedWidth;
end

-- FIXME: We should eventually replace these three functions by ones that work on a higher abstraction.
function LineWidth:UncommittedWidth()
	return self.uncommittedWidth;
end

function LineWidth:CommittedWidth()
	return self.committedWidth;
end

function LineWidth:AvailableWidth()
	return self.availableWidth;
end

function LineWidth:UpdateAvailableWidth()
	local height = self.block:LogicalHeight();
    self.left = self.block:LogicalLeftOffsetForLine(height, self.isFirstLine);
    self.right = self.block:LogicalRightOffsetForLine(height, self.isFirstLine);

    self:ComputeAvailableWidthFromLeftAndRight();
end

function LineWidth:ShrinkAvailableWidthForNewFloatIfNeeded(newFloat)
	local height = self.block:LogicalHeight();
    if (height < self.block:LogicalTopForFloat(newFloat) or height >= self.block:LogicalBottomForFloat(newFloat)) then
        return;
	end

    if (newFloat:Type() == FloatingObject.FloatType.FloatLeft) then
        self.left = self.block:LogicalRightForFloat(newFloat);
        if (self.isFirstLine and self.block:Style():IsLeftToRightDirection()) then
            self.left = self.left + self.block:TextIndentOffset();
		end
    else
        self.right = self.block:LogicalLeftForFloat(newFloat);
        if (self.isFirstLine and not self.block:Style():IsLeftToRightDirection()) then
            self.right = self.right - self.block:TextIndentOffset();
		end
    end

    self:ComputeAvailableWidthFromLeftAndRight();
end

function LineWidth:AddUncommittedWidth(delta)
	self.uncommittedWidth = self.uncommittedWidth + delta;
end

function LineWidth:Commit()
    self.committedWidth = self.committedWidth + self.uncommittedWidth;
    self.uncommittedWidth = 0;
end

function LineWidth:ApplyOverhang(rubyRun, startRenderer, endRenderer)
	--TODO: fixed this function
end

function LineWidth:FitBelowFloats()
	--TODO: fixed this function
--    ASSERT(!m_committedWidth);
--    ASSERT(!fitsOnLine());
--
--    int floatLogicalBottom;
--    int lastFloatLogicalBottom = m_block->logicalHeight();
--    float newLineWidth = m_availableWidth;
--    float newLineLeft = m_left;
--    float newLineRight = m_right;
--    while (true) {
--        floatLogicalBottom = m_block->nextFloatLogicalBottomBelow(lastFloatLogicalBottom);
--        if (floatLogicalBottom <= lastFloatLogicalBottom)
--            break;
--
--        newLineLeft = m_block->logicalLeftOffsetForLine(floatLogicalBottom, m_isFirstLine);
--        newLineRight = m_block->logicalRightOffsetForLine(floatLogicalBottom, m_isFirstLine);
--        newLineWidth = max(0.0f, newLineRight - newLineLeft);
--        lastFloatLogicalBottom = floatLogicalBottom;
--        if (newLineWidth >= m_uncommittedWidth)
--            break;
--    }
--
--    if (newLineWidth > m_availableWidth) {
--        m_block->setLogicalHeight(lastFloatLogicalBottom);
--        m_availableWidth = newLineWidth + m_overhangWidth;
--        m_left = newLineLeft;
--        m_right = newLineRight;
--    }
end

function LineWidth:ComputeAvailableWidthFromLeftAndRight()
	self.availableWidth = math.max(0, self.right - self.left) + self.overhangWidth;
end


function LineInfo:ctor()
	self.isFirstLine = true;
    self.isLastLine = false;
    self.isEmpty = true;
    self.previousLineBrokeCleanly = true;
    self.floatPaginationStrut = 0;
end

function LineInfo:IsFirstLine()
	return self.isFirstLine;
end

function LineInfo:IsLastLine()
	return self.isLastLine;
end

function LineInfo:IsEmpty()
	return self.isEmpty;
end

function LineInfo:PreviousLineBrokeCleanly()
	return self.previousLineBrokeCleanly;
end

function LineInfo:FloatPaginationStrut()
	return self.floatPaginationStrut;
end

function LineInfo:SetFirstLine(firstLine)
	self.isFirstLine = firstLine;
end

function LineInfo:SetLastLine(lastLine)
	self.isLastLine = lastLine;
end

function LineInfo:SetEmpty(empty, block, lineWidth)
    if (self.isEmpty == empty) then
        return;
	end
    self.isEmpty = empty;
    if (not empty and block and self:FloatPaginationStrut() ~= 0) then
        block:SetLogicalHeight(block:LogicalHeight() + self:FloatPaginationStrut());
        self:SetFloatPaginationStrut(0);
		if(lineWidth) then
			lineWidth:UpdateAvailableWidth();
		end
   end
end

function LineInfo:SetPreviousLineBrokeCleanly(previousLineBrokeCleanly)
	self.previousLineBrokeCleanly = previousLineBrokeCleanly;
end

function LineInfo:SetFloatPaginationStrut(strut)
	self.floatPaginationStrut = strut;
end


function LayoutBlock:DeleteEllipsisLineBoxes()
	--TODO: fixed this function
end

local function dirtyLineBoxesForRenderer(o, fullLayout)
	if (o:IsText()) then
        if (o:PreferredLogicalWidthsDirty() and (o:IsCounter() or o:IsQuote())) then
            o:ComputePreferredLogicalWidths(0); -- FIXME: Counters depend on this hack. No clue why. Should be investigated and removed.
		end
        o:DirtyLineBoxes(fullLayout);
    else
        o:DirtyLineBoxes(fullLayout);
	end
end

function LayoutBlock:LayoutInlineChildren(relayoutChildren, repaintLogicalTop, repaintLogicalBottom)
	echo("LayoutBlock:LayoutInlineChildren")
	self.overflow = nil;

    self:SetLogicalHeight(self:BorderBefore() + self:PaddingBefore());
	local isFullLayout = not self:FirstLineBox() or self:SelfNeedsLayout() or relayoutChildren;
	local layoutState = LineLayoutState:new():init(isFullLayout, repaintLogicalTop, repaintLogicalBottom);
	if (isFullLayout) then
        self:LineBoxes():DeleteLineBoxes(self:RenderArena());
	end

	-- Text truncation only kicks in if your overflow isn't visible and your text-overflow-mode isn't
    -- clip.
    -- FIXME: CSS3 says that descendants that are clipped must also know how to truncate.  This is insanely
    -- difficult to figure out (especially in the middle of doing layout), and is really an esoteric pile of nonsense
    -- anyway, so we won't worry about following the draft here.
	local hasTextOverflow = self:Style():TextOverflow() and self:HasOverflowClip();

    -- Walk all the lines and delete our ellipsis line boxes if they exist.
    if (hasTextOverflow) then
         self:DeleteEllipsisLineBoxes();
	end

	if (self:FirstChild()) then
        -- layout replaced elements
        local hasInlineChild = false;
		local walker = InlineWalker:new():init(self);
		while(not walker:AtEnd()) do
		echo("while(not walker:AtEnd()) do")
			local o = walker:Current();
            if (not hasInlineChild and o:IsInline()) then
                hasInlineChild = true;
			end

            if (o:IsReplaced() or o:IsFloating() or o:IsPositioned()) then
				echo("o:IsReplaced() or o:IsFloating() or o:IsPositioned()")
				--RenderBox* box = toRenderBox(o);
				local box = o;

                if (relayoutChildren or o:Style():Width():IsPercent() or o:Style():Height():IsPercent()) then
                    o:SetChildNeedsLayout(true, false);
				end

                -- If relayoutChildren is set and the child has percentage padding or an embedded content box, we also need to invalidate the childs pref widths.
                if (relayoutChildren and box:NeedsPreferredWidthsRecalculation()) then
                    o:SetPreferredLogicalWidthsDirty(true, false);
				end

                if (o:IsPositioned()) then
                    o:ContainingBlock():InsertPositionedObject(box);
                elseif (o:IsFloating()) then
                    layoutState:Floats():append(FloatWithRect:new():init(box));
                elseif (layoutState:IsFullLayout() or o:NeedsLayout()) then
                    -- Replaced elements
					echo("o:LayoutIfNeeded();")
					echo({layoutState:IsFullLayout(), o:NeedsLayout()})
                    o:DirtyLineBoxes(layoutState:IsFullLayout());
					
                    o:LayoutIfNeeded();
                end
            elseif (o:IsText() or (o:IsLayoutInline() and not walker:AtEndOfInline())) then
                if (not o:IsText()) then
                    o:UpdateAlwaysCreateLineBoxes(layoutState:IsFullLayout());
				end
                if (layoutState:IsFullLayout() or o:SelfNeedsLayout()) then
                    dirtyLineBoxesForRenderer(o, layoutState:IsFullLayout());
				end
                o:SetNeedsLayout(false);
            end
			walker:Advance();
		end
        self:LayoutRunsAndFloats(layoutState, hasInlineChild);
    end

	-- Expand the last line to accommodate Ruby and emphasis marks.
    local lastLineAnnotationsAdjustment = 0;
--    if (lastRootBox()) {
--        int lowestAllowedPosition = max(lastRootBox()->lineBottom(), logicalHeight() + paddingAfter());
--        if (!style()->isFlippedLinesWritingMode())
--            lastLineAnnotationsAdjustment = lastRootBox()->computeUnderAnnotationAdjustment(lowestAllowedPosition);
--        else
--            lastLineAnnotationsAdjustment = lastRootBox()->computeOverAnnotationAdjustment(lowestAllowedPosition);
--    }

    -- Now add in the bottom border/padding.
    self:SetLogicalHeight(self:LogicalHeight() + lastLineAnnotationsAdjustment + self:BorderAfter() + self:PaddingAfter() + self:ScrollbarLogicalHeight());

    if (not self:FirstLineBox() and self:HasLineIfEmpty()) then
        --self:SetLogicalHeight(self:LogicalHeight() + self:LineHeight(true, isHorizontalWritingMode() ? HorizontalLine : VerticalLine, PositionOfInteriorLineBoxes));
	end

    -- See if we have any lines that spill out of our block.  If we do, then we will possibly need to
    -- truncate text.
    if (hasTextOverflow) then
        self:CheckLinesForTextOverflow();
	end

	return layoutState:RepaintLogicalTop(), layoutState:RepaintLogicalBottom();
end

function LayoutBlock:DetermineStartPosition(layoutState, resolver)
	echo("LayoutBlock:DetermineStartPosition")
	local curr = nil;
    local last = nil;

    -- FIXME: This entire float-checking block needs to be broken into a new function.
    local dirtiedByFloat = false;

	if (not layoutState:IsFullLayout()) then
        -- Paginate all of the clean lines.
        --bool paginated = view()->layoutState() && view()->layoutState()->isPaginated();
		local paginated = false;
		if(self:View():LayoutState()) then
			paginated = self:View():LayoutState():IsPaginated();
		end
        local paginationDelta = 0;
        local floatIndex = 1;
		curr = self:FirstRootBox();
		while(curr ~= nil and not curr:IsDirty()) do
			if (paginated) then
--                if (lineWidthForPaginatedLineChanged(curr)) {
--                    curr->markDirty();
--                    break;
--                }
--                paginationDelta -= curr->paginationStrut();
--                adjustLinePositionForPagination(curr, paginationDelta);
--                if (paginationDelta) {
--                    if (containsFloats() || !layoutState.floats().isEmpty()) {
--                        // FIXME: Do better eventually.  For now if we ever shift because of pagination and floats are present just go to a full layout.
--                        layoutState.markForFullLayout();
--                        break;
--                    }
--
--                    layoutState.updateRepaintRangeFromBox(curr, paginationDelta);
--                    curr->adjustBlockDirectionPosition(paginationDelta);
--                }
            end

            -- If a new float has been inserted before this line or before its last known float, just do a full layout.
            local encounteredNewFloat = false;
            floatIndex, encounteredNewFloat, dirtiedByFloat = self:CheckFloatsInCleanLine(curr, layoutState:Floats(), floatIndex, encounteredNewFloat, dirtiedByFloat);
            if (encounteredNewFloat) then
                layoutState:MarkForFullLayout();
			end

            if (dirtiedByFloat or layoutState:IsFullLayout()) then
                break;
			end

			curr = curr:NextRootBox();
		end

        
        -- Check if a new float has been inserted after the last known float.
        if (curr == nil and floatIndex < layoutState:Floats():size()) then
            layoutState:MarkForFullLayout();
		end
    end

	if (layoutState:IsFullLayout()) then
        -- FIXME: This should just call deleteLineBoxTree, but that causes
        -- crashes for fast/repaint tests.
        local arena = self:RenderArena();
        curr = self:FirstRootBox();
        while (curr) do
            -- Note: This uses nextRootBox() insted of nextLineBox() like deleteLineBoxTree does.
            next = curr:NextRootBox();
            curr:DeleteLine(arena);
            curr = next;
        end
        --ASSERT(!firstLineBox() && !lastLineBox());
    else
        if (curr) then
            -- We have a dirty line.
			local prevRootBox = curr:PrevRootBox();
            if (prevRootBox) then
                -- We have a previous line.
                if (not dirtiedByFloat and (not prevRootBox:EndsWithBreak() or (prevRootBox:LineBreakObj():IsText() and prevRootBox:LineBreakPos() >= prevRootBox:LineBreakObj():TextLength()))) then
                    -- The previous line didn't break cleanly or broke at a newline
                    -- that has been deleted, so treat it as dirty too.
                    curr = prevRootBox;
				end
            end
        else
            -- No dirty lines were found.
            -- If the last line didn't break cleanly, treat it as dirty.
            if (self:LastRootBox() ~= nil and not self:LastRootBox():EndsWithBreak()) then
                curr = self:LastRootBox();
			end
        end

        -- If we have no dirty lines, then last is just the last root box.
		if(curr) then
			last = curr:PrevRootBox();
		else
			last = self:LastRootBox();
		end
    end

	local numCleanFloats = 1;
	if (not layoutState:Floats():empty()) then
        local savedLogicalHeight = self:LogicalHeight();
        -- Restore floats from clean lines.
        local line = self:FirstRootBox();
        while (line ~= curr) do
			local cleanLineFloats = line:FloatsPtr();
            if (cleanLineFloats) then
				for i = 1,cleanLineFloats:size() do
					local f = cleanLineFloats:get(i);
					local floatingObject = self:InsertFloatingObject(f);
                    --ASSERT(!floatingObject->m_originatingLine);
                    floatingObject.originatingLine = line;
                    self:SetLogicalHeight(self:LogicalTopForChild(f) - self:MarginBeforeForChild(f));
                    self:PositionNewFloats();
                    --ASSERT(layoutState.floats()[numCleanFloats].object == *f);
                    numCleanFloats = numCleanFloats + 1;
				end
            end
            line = line:NextRootBox();
        end
        self:SetLogicalHeight(savedLogicalHeight);
    end

	layoutState:SetFloatIndex(numCleanFloats);
    --layoutState:LineInfo():SetFirstLine(not last);
	layoutState:LineInfo():SetFirstLine(not if_else(last, true, false));
    layoutState:LineInfo():SetPreviousLineBrokeCleanly(not if_else(last, true, false) or last:EndsWithBreak());
	if (last) then
        self:SetLogicalHeight(last:LineBottomWithLeading());
        resolver:SetPosition(InlineIterator:new():init(self, last:LineBreakObj(), last:LineBreakPos()));
        resolver:SetStatus(last:LineBreakBidiStatus());
    else
        local direction = self:Style():Direction();
        if (self:Style():UnicodeBidi() == UnicodeBidiEnum.Plaintext) then
            -- FIXME: Why does "unicode-bidi: plaintext" bidiFirstIncludingEmptyInlines when all other line layout code uses bidiFirstSkippingEmptyInlines?
            --determineParagraphDirection(direction, InlineIterator(this, bidiFirstIncludingEmptyInlines(this), 0));
        end
        resolver:SetStatus(BidiStatus:new():init(direction, self:Style():UnicodeBidi() == UnicodeBidiEnum.Override));
		resolver:SetPosition(InlineIterator:new():init(self, InlineWalker.BidiFirstSkippingEmptyInlines(self, resolver), 1));
    end
    return curr;
end

local level = 0;

local function printLineBoxsInfo(box)
	level = level + 1;
	echo("-----------------------printLineBoxsInfo"..level.." begin-----------------------------");
	while(box) do
		echo("while(box) do");
		echo(box:BoxName());
		box.renderer:PrintNodeInfo();
		echo(box.topLeft);
		echo(box:Size())
		if(box:IsRootInlineBox()) then
			echo("RootInlineBox info");
			echo(box.lineTop);
			echo(box.lineBottom);
		end
--			echo(box:IsInlineFlowBox());
--			if(box:FirstChild() == nil) then
--				echo("box:FirstChild() is nil");
--			end
		if(box:IsInlineFlowBox()) then
			printLineBoxsInfo(box:FirstChild());
		elseif(box:IsInlineTextBox()) then
			echo("InlineTextBox info");
			echo(tostring(box.renderer:Characters()));
			echo(box.start);
			echo(box.len);
			echo(box.topLeft);
			echo(box.logicalWidth);
			local font = box.renderer:Style():Font():ToString();
			echo(box.renderer:Characters():GetWidth(font, box.start, box.len));
			echo(font);
		else
			echo("not any box");
		end

		if(box:IsInlineFlowBox()) then
			box = box:NextOnLine();
		else
			box = box:Next();
		end
	end
	echo("-----------------------printLineBoxsInfo"..level.." end-----------------------------");
	level = level - 1;
end

-- static void deleteLineRange(LineLayoutState& layoutState, RenderArena* arena, RootInlineBox* startLine, RootInlineBox* stopLine = 0)
local function deleteLineRange(layoutState, arena, startLine, stopLine)
	echo("deleteLineRange")
    local boxToDelete = startLine;
    while (boxToDelete and boxToDelete ~= stopLine) do
        layoutState:UpdateRepaintRangeFromBox(boxToDelete);
        -- Note: deleteLineRange(renderArena(), firstRootBox()) is not identical to deleteLineBoxTree().
        -- deleteLineBoxTree uses nextLineBox() instead of nextRootBox() when traversing.
        local next = boxToDelete:NextRootBox();
        boxToDelete:DeleteLine(arena);
        boxToDelete = next;
    end
end

function LayoutBlock:LayoutRunsAndFloats(layoutState, hasInlineChild)
	echo("LayoutBlock:LayoutRunsAndFloats")
	-- We want to skip ahead to the first dirty line
    local resolver = InlineBidiResolver:new():init();
    local startLine = self:DetermineStartPosition(layoutState, resolver);
	
	local consecutiveHyphenatedLines = 0;
    if (startLine) then
		line = startLine:PrevRootBox();
		while(line and line:IsHyphenated()) do
			consecutiveHyphenatedLines = consecutiveHyphenatedLines + 1;
			line = line:PrevRootBox();
		end
    end
	-- FIXME: This would make more sense outside of this function, but since
    -- determineStartPosition can change the fullLayout flag we have to do this here. Failure to call
    -- determineStartPosition first will break fast/repaint/line-flow-with-floats-9.html.
    if (layoutState:IsFullLayout() and hasInlineChild and not self:SelfNeedsLayout()) then
        self:SetNeedsLayout(true, false);  -- Mark ourselves as needing a full layout. This way we'll repaint like we're supposed to.
        local v = self:View();
        if (v and not v:DoingFullRepaint() and self:HasLayer()) then
            -- Because we waited until we were already inside layout to discover
            -- that the block really needed a full layout, we missed our chance to repaint the layer
            -- before layout started.  Luckily the layer has cached the repaint rect for its original
            -- position and size, and so we can use that to make a repaint happen now.
            self:RepaintUsingContainer(self:ContainerForRepaint(), self:Layer():RepaintRect());
        end
    end
    if (self.floatingObjects and not self.floatingObjects:Set():isEmpty()) then
        layoutState:SetLastFloat(self.floatingObjects:Set():last());
	end

--	-- We also find the first clean line and extract these lines.  We will add them back
--    -- if we determine that we're able to synchronize after handling all our dirty lines.
    local cleanLineStart = InlineIterator:new();
    local cleanLineBidiStatus = BidiStatus:new();
    if (not layoutState:IsFullLayout() and startLine ~= nil) then
        cleanLineStart, cleanLineBidiStatus = self:DetermineEndPosition(layoutState, startLine, cleanLineStart, cleanLineBidiStatus);
	end
    if (startLine) then
        if (not layoutState:UsesRepaintBounds()) then
            layoutState:SetRepaintRange(self:Logicalheight());
		end
        deleteLineRange(layoutState, self:RenderArena(), startLine);

    end

    if (not layoutState:IsFullLayout() and self:LastRootBox() ~= nil and self:LastRootBox():EndsWithBreak()) then
        -- If the last line before the start line ends with a line break that clear floats,
        -- adjust the height accordingly.
        -- A line break can be either the first or the last object on a line, depending on its direction.
		local lastLeafChild = self:LastRootBox():LastLeafChild();
        if (lastLeafChild) then
            local lastObject = lastLeafChild:Renderer();
            if (not lastObject:IsBR()) then
                lastObject = self:LastRootBox():FirstLeafChild():Renderer();
			end
            if (lastObject:IsBR()) then
                local clear = lastObject:Style():Clear();
                if (clear ~= ClearEnum.CNONE) then
                    self:NewLine(clear);
				end
            end
        end
    end
	self:LayoutRunsAndFloatsInRange(layoutState, resolver, cleanLineStart, cleanLineBidiStatus, consecutiveHyphenatedLines);

	local firstLineBox = self:FirstLineBox();
	local lastLineBox = self:LastLineBox();
	echo("LayoutRunsAndFloats printLineBoxsInfo")
	self:PrintNodeInfo()
	local lineBox = firstLineBox;
	while(lineBox) do
		echo("while(lineBox) do")
		printLineBoxsInfo(lineBox);
		lineBox = lineBox:NextRootBox();
	end
	self:LinkToEndLineIfNeeded(layoutState);
    self:RepaintDirtyFloats(layoutState:Floats());
end



--static inline void constructBidiRuns(InlineBidiResolver& topResolver, BidiRunList<BidiRun>& bidiRuns, const InlineIterator& endOfLine, VisualDirectionOverride override, bool previousLineBrokeCleanly)
local function constructBidiRuns(topResolver, bidiRuns, endOfLine, override, previousLineBrokeCleanly)
	-- FIXME: We should pass a BidiRunList into createBidiRunsForLine instead
    -- of the resolver owning the runs.
    --ASSERT(&topResolver.runs() == &bidiRuns);
    topResolver:CreateBidiRunsForLine(endOfLine, override, previousLineBrokeCleanly);

--    while (!topResolver.isolatedRuns().isEmpty()) {
--        // It does not matter which order we resolve the runs as long as we resolve them all.
--        BidiRun* isolatedRun = topResolver.isolatedRuns().last();
--        topResolver.isolatedRuns().removeLast();
--
--        // Only inlines make sense with unicode-bidi: isolate (blocks are already isolated).
--        RenderInline* isolatedSpan = toRenderInline(isolatedRun->object());
--        InlineBidiResolver isolatedResolver;
--        isolatedResolver.setStatus(statusWithDirection(isolatedSpan->style()->direction()));
--
--        // FIXME: The fact that we have to construct an Iterator here
--        // currently prevents this code from moving into BidiResolver.
--        RenderObject* startObj = bidiFirstSkippingEmptyInlines(isolatedSpan, &isolatedResolver);
--        isolatedResolver.setPosition(InlineIterator(isolatedSpan, startObj, 0));
--
--        // FIXME: isolatedEnd should probably equal end or the last char in isolatedSpan.
--        InlineIterator isolatedEnd = endOfLine;
--        // FIXME: What should end and previousLineBrokeCleanly be?
--        // rniwa says previousLineBrokeCleanly is just a WinIE hack and could always be false here?
--        isolatedResolver.createBidiRunsForLine(isolatedEnd, NoVisualOverride, previousLineBrokeCleanly);
--        // Note that we do not delete the runs from the resolver.
--        bidiRuns.replaceRunWithRuns(isolatedRun, isolatedResolver.runs());
--
--        // If we encountered any nested isolate runs, just move them
--        // to the top resolver's list for later processing.
--        if (!isolatedResolver.isolatedRuns().isEmpty()) {
--            topResolver.isolatedRuns().append(isolatedResolver.isolatedRuns());
--            isolatedResolver.isolatedRuns().clear();
--        }
--    }
end

--static inline InlineBox* createInlineBoxForRenderer(RenderObject* obj, bool isRootLineBox, bool isOnlyRun = false)
local function createInlineBoxForRenderer(obj, isRootLineBox, isOnlyRun)
	isOnlyRun = if_else(isOnlyRun == nil, false, isOnlyRun);
    if (isRootLineBox) then
        return obj:CreateAndAppendRootInlineBox();
	end

    if (obj:IsText()) then
        local textBox = obj:CreateInlineTextBox();
        -- We only treat a box as text for a <br> if we are on a line by ourself or in strict mode
        -- (Note the use of strict mode.  In "almost strict" mode, we don't treat the box for <br> as text.)
        if (obj:IsBR()) then
            textBox:SetIsText(isOnlyRun);
		end
        return textBox;
    end

    if (obj:IsBox()) then
        return obj:CreateInlineBox();
	end

    return obj:CreateAndAppendInlineFlowBox();
end

function LayoutBlock:TextAlignmentForLine(endsWithSoftBreak)
    local alignment = self:Style():TextAlign();
    if (not endsWithSoftBreak and alignment == TextAlignEnum.JUSTIFY) then
        alignment = TextAlignEnum.TAAUTO;
	end
    return alignment;
end

--local function setLogicalWidthForTextRun(RootInlineBox* lineBox, BidiRun* run, RenderText* renderer, float xPos, const LineInfo& lineInfo, GlyphOverflowAndFallbackFontsMap& textBoxDataMap, VerticalPositionCache& verticalPositionCache)
local function setLogicalWidthForTextRun(lineBox, run, renderer, xPos, lineInfo, textBoxDataMap, verticalPositionCache)
--	HashSet<const SimpleFontData*> fallbackFonts;
--  GlyphOverflow glyphOverflow;
	local fallbackFonts;
	local glyphOverflow;
    
    -- Always compute glyph overflow if the block's line-box-contain value is "glyphs".
    if (lineBox:FitsToGlyphs()) then
--        // If we don't stick out of the root line's font box, then don't bother computing our glyph overflow. This optimization
--        // will keep us from computing glyph bounds in nearly all cases.
--        bool includeRootLine = lineBox->includesRootLineBoxFontOrLeading();
--        int baselineShift = lineBox->verticalPositionForBox(run->m_box, verticalPositionCache);
--        int rootDescent = includeRootLine ? lineBox->renderer()->style(lineInfo.isFirstLine())->font().fontMetrics().descent() : 0;
--        int rootAscent = includeRootLine ? lineBox->renderer()->style(lineInfo.isFirstLine())->font().fontMetrics().ascent() : 0;
--        int boxAscent = renderer->style(lineInfo.isFirstLine())->font().fontMetrics().ascent() - baselineShift;
--        int boxDescent = renderer->style(lineInfo.isFirstLine())->font().fontMetrics().descent() + baselineShift;
--        if (boxAscent > rootDescent ||  boxDescent > rootAscent)
--            glyphOverflow.computeBounds = true; 
    end

	local hyphenWidth = 0;
--    if (toInlineTextBox(run->m_box)->hasHyphen()) {
--        const Font& font = renderer->style(lineInfo.isFirstLine())->font();
--        hyphenWidth = measureHyphenWidth(renderer, font);
--    }
	echo("run.box:SetLogicalWidth")
	echo({run.start, run.stop, })
    run.box:SetLogicalWidth(renderer:Width(run.start, run.stop - run.start - 1, xPos, lineInfo:IsFirstLine(), fallbackFonts, glyphOverflow) + hyphenWidth);
	if(not textBoxDataMap[run.box:ToInlineTextBox()]) then
		textBoxDataMap[run.box:ToInlineTextBox()] = {};
	end
	local size = #(textBoxDataMap[run.box:ToInlineTextBox()]);
	textBoxDataMap[run.box:ToInlineTextBox()][size+1] = renderer:Style(lineInfo:IsFirstLine()):Font();

--	if (!fallbackFonts.isEmpty()) {
--        ASSERT(run->m_box->isText());
--        GlyphOverflowAndFallbackFontsMap::iterator it = textBoxDataMap.add(toInlineTextBox(run->m_box), make_pair(Vector<const SimpleFontData*>(), GlyphOverflow())).first;
--        ASSERT(it->second.first.isEmpty());
--        copyToVector(fallbackFonts, it->second.first);
--        run->m_box->parent()->clearDescendantsHaveSameLineHeightAndBaseline();
--    }
--    if ((glyphOverflow.top || glyphOverflow.bottom || glyphOverflow.left || glyphOverflow.right)) {
--        ASSERT(run->m_box->isText());
--        GlyphOverflowAndFallbackFontsMap::iterator it = textBoxDataMap.add(toInlineTextBox(run->m_box), make_pair(Vector<const SimpleFontData*>(), GlyphOverflow())).first;
--        it->second.second = glyphOverflow;
--        run->m_box->clearKnownToHaveNoOverflow();
--    }
end

--static void updateLogicalWidthForLeftAlignedBlock(bool isLeftToRightDirection, BidiRun* trailingSpaceRun, float& logicalLeft, float& totalLogicalWidth, float availableLogicalWidth)
local function updateLogicalWidthForLeftAlignedBlock(isLeftToRightDirection, trailingSpaceRun, logicalLeft, totalLogicalWidth, availableLogicalWidth)
    -- The direction of the block should determine what happens with wide lines.
    -- In particular with RTL blocks, wide lines should still spill out to the left.
    if (isLeftToRightDirection) then
        if (totalLogicalWidth > availableLogicalWidth and trailingSpaceRun) then
            trailingSpaceRun.box:SetLogicalWidth(math.max(0, trailingSpaceRun.box:LogicalWidth() - totalLogicalWidth + availableLogicalWidth));
		end
        return logicalLeft, totalLogicalWidth;
    end

    if (trailingSpaceRun) then
        trailingSpaceRun.box:SetLogicalWidth(0);
    elseif (totalLogicalWidth > availableLogicalWidth) then
        logicalLeft = logicalLeft - (totalLogicalWidth - availableLogicalWidth);
	end
	return logicalLeft, totalLogicalWidth;
end

--static void updateLogicalWidthForRightAlignedBlock(bool isLeftToRightDirection, BidiRun* trailingSpaceRun, float& logicalLeft, float& totalLogicalWidth, float availableLogicalWidth)
local function updateLogicalWidthForRightAlignedBlock(isLeftToRightDirection, trailingSpaceRun, logicalLeft, totalLogicalWidth, availableLogicalWidth)
    -- Wide lines spill out of the block based off direction.
    -- So even if text-align is right, if direction is LTR, wide lines should overflow out of the right
    -- side of the block.
    if (isLeftToRightDirection) then
        if (trailingSpaceRun) then
            totalLogicalWidth = totalLogicalWidth - trailingSpaceRun.box:LogicalWidth();
            trailingSpaceRun.box:SetLogicalWidth(0);
        end
        if (totalLogicalWidth < availableLogicalWidth) then
            logicalLeft = logicalLeft + availableLogicalWidth - totalLogicalWidth;
		end
        return logicalLeft, totalLogicalWidth;
    end

    if (totalLogicalWidth > availableLogicalWidth and trailingSpaceRun) then
        trailingSpaceRun.box:SetLogicalWidth(math.max(0, trailingSpaceRun.box:LogicalWidth() - totalLogicalWidth + availableLogicalWidth));
        totalLogicalWidth = totalLogicalWidth - trailingSpaceRun.box:LogicalWidth();
    else
        logicalLeft = logicalLeft + availableLogicalWidth - totalLogicalWidth;
	end
	return logicalLeft, totalLogicalWidth;
end

--static void updateLogicalWidthForCenterAlignedBlock(bool isLeftToRightDirection, BidiRun* trailingSpaceRun, float& logicalLeft, float& totalLogicalWidth, float availableLogicalWidth)
local function updateLogicalWidthForCenterAlignedBlock(isLeftToRightDirection, trailingSpaceRun, logicalLeft, totalLogicalWidth, availableLogicalWidth)
	echo("updateLogicalWidthForCenterAlignedBlock")
	echo({isLeftToRightDirection, logicalLeft, totalLogicalWidth, availableLogicalWidth})
    local trailingSpaceWidth = 0;
    if (trailingSpaceRun) then
        totalLogicalWidth = totalLogicalWidth - trailingSpaceRun.box:LogicalWidth();
        trailingSpaceWidth = math.min(trailingSpaceRun.box:LogicalWidth(), (availableLogicalWidth - totalLogicalWidth + 1) / 2);
        trailingSpaceRun.box:SetLogicalWidth(math.max(0, trailingSpaceWidth));
    end
    if (isLeftToRightDirection) then
        logicalLeft = logicalLeft + math.max((availableLogicalWidth - totalLogicalWidth) / 2, 0);
    else
        logicalLeft = logicalLeft + if_else(totalLogicalWidth > availableLogicalWidth, (availableLogicalWidth - totalLogicalWidth), (availableLogicalWidth - totalLogicalWidth) / 2 - trailingSpaceWidth);
	end
	echo("logicalLeft, totalLogicalWidth")
	echo({logicalLeft, totalLogicalWidth})
	return logicalLeft, totalLogicalWidth;
end

--void RenderBlock::updateLogicalWidthForAlignment(const ETextAlign& textAlign, BidiRun* trailingSpaceRun, float& logicalLeft, float& totalLogicalWidth, float& availableLogicalWidth, int expansionOpportunityCount)
function LayoutBlock:UpdateLogicalWidthForAlignment(textAlign, trailingSpaceRun, logicalLeft, totalLogicalWidth, availableLogicalWidth, expansionOpportunityCount)
	echo("LayoutBlock:UpdateLogicalWidthForAlignment")
	self:PrintNodeInfo()
	echo(textAlign)
    -- Armed with the total width of the line (without justification),
    -- we now examine our text-align property in order to determine where to position the
    -- objects horizontally. The total width of the line can be increased if we end up
    -- justifying text.
    if(textAlign == TextAlignEnum.LEFT or textAlign == TextAlignEnum.WEBKIT_LEFT) then
        logicalLeft, totalLogicalWidth = updateLogicalWidthForLeftAlignedBlock(self:Style():IsLeftToRightDirection(), trailingSpaceRun, logicalLeft, totalLogicalWidth, availableLogicalWidth);
    elseif(textAlign == TextAlignEnum.JUSTIFY) then
--        adjustInlineDirectionLineBounds(expansionOpportunityCount, logicalLeft, availableLogicalWidth);
--        if (expansionOpportunityCount) then
--            if (trailingSpaceRun) then
--                totalLogicalWidth -= trailingSpaceRun.box:LogicalWidth();
--                trailingSpaceRun.box:SetLogicalWidth(0);
--            end
--            break;
--        end
        -- fall through
    elseif(textAlign == TextAlignEnum.TAAUTO) then
        -- for right to left fall through to right aligned
        if (self:Style():IsLeftToRightDirection()) then
            if (totalLogicalWidth > availableLogicalWidth and trailingSpaceRun) then
                trailingSpaceRun.box:SetLogicalWidth(math.max(0, trailingSpaceRun.box:LogicalWidth() - totalLogicalWidth + availableLogicalWidth));
            end
        end
    elseif(textAlign == TextAlignEnum.RIGHT or textAlign == TextAlignEnum.WEBKIT_RIGHT) then
        logicalLeft, totalLogicalWidth = updateLogicalWidthForRightAlignedBlock(self:Style():IsLeftToRightDirection(), trailingSpaceRun, logicalLeft, totalLogicalWidth, availableLogicalWidth);
    elseif(textAlign == TextAlignEnum.CENTER or textAlign == TextAlignEnum.WEBKIT_CENTER) then
        logicalLeft, totalLogicalWidth = updateLogicalWidthForCenterAlignedBlock(self:Style():IsLeftToRightDirection(), trailingSpaceRun, logicalLeft, totalLogicalWidth, availableLogicalWidth);
    elseif(textAlign == TextAlignEnum.TASTART) then
        if (self:Style():IsLeftToRightDirection()) then
            logicalLeft, totalLogicalWidth = updateLogicalWidthForLeftAlignedBlock(self:Style():IsLeftToRightDirection(), trailingSpaceRun, logicalLeft, totalLogicalWidth, availableLogicalWidth);
        else
            logicalLeft, totalLogicalWidth = updateLogicalWidthForRightAlignedBlock(self:Style():IsLeftToRightDirection(), trailingSpaceRun, logicalLeft, totalLogicalWidth, availableLogicalWidth);
        end
    elseif(textAlign == TextAlignEnum.TAEND) then
        if (self:Style():IsLeftToRightDirection()) then
            logicalLeft, totalLogicalWidth = updateLogicalWidthForRightAlignedBlock(self:Style():IsLeftToRightDirection(), trailingSpaceRun, logicalLeft, totalLogicalWidth, availableLogicalWidth);
        else
            logicalLeft, totalLogicalWidth = updateLogicalWidthForLeftAlignedBlock(self:Style():IsLeftToRightDirection(), trailingSpaceRun, logicalLeft, totalLogicalWidth, availableLogicalWidth);
        end
    end
	return logicalLeft, totalLogicalWidth;
end

--static inline void computeExpansionForJustifiedText(BidiRun* firstRun, BidiRun* trailingSpaceRun, Vector<unsigned, 16>& expansionOpportunities, unsigned expansionOpportunityCount, float& totalLogicalWidth, float availableLogicalWidth)
local function computeExpansionForJustifiedText(firstRun, trailingSpaceRun, expansionOpportunities, expansionOpportunityCount, totalLogicalWidth, availableLogicalWidth)
    if (expansionOpportunityCount == 0 or availableLogicalWidth <= totalLogicalWidth) then
        return;
	end
--    size_t i = 0;
--    for (BidiRun* r = firstRun; r; r = r->next()) {
--        if (!r->m_box || r == trailingSpaceRun)
--            continue;
--        
--        if (r->m_object->isText()) {
--            unsigned opportunitiesInRun = expansionOpportunities[i++];
--            
--            ASSERT(opportunitiesInRun <= expansionOpportunityCount);
--            
--            // Only justify text if whitespace is collapsed.
--            if (r->m_object->style()->collapseWhiteSpace()) {
--                InlineTextBox* textBox = toInlineTextBox(r->m_box);
--                int expansion = (availableLogicalWidth - totalLogicalWidth) * opportunitiesInRun / expansionOpportunityCount;
--                textBox->setExpansion(expansion);
--                totalLogicalWidth += expansion;
--            }
--            expansionOpportunityCount -= opportunitiesInRun;
--            if (!expansionOpportunityCount)
--                break;
--        }
--    }
end

--void RenderBlock::computeInlineDirectionPositionsForLine(RootInlineBox* lineBox, const LineInfo& lineInfo, BidiRun* firstRun, BidiRun* trailingSpaceRun, bool reachedEnd,
--                                                         GlyphOverflowAndFallbackFontsMap& textBoxDataMap, VerticalPositionCache& verticalPositionCache)
function LayoutBlock:ComputeInlineDirectionPositionsForLine(lineBox, lineInfo, firstRun, trailingSpaceRun, reachedEnd, textBoxDataMap, verticalPositionCache)
	local textAlign = self:TextAlignmentForLine(not reachedEnd and not lineBox:EndsWithBreak());
    local logicalLeft = self:LogicalLeftOffsetForLine(self:LogicalHeight(), lineInfo:IsFirstLine());
    local availableLogicalWidth = self:LogicalRightOffsetForLine(self:LogicalHeight(), lineInfo:IsFirstLine()) - logicalLeft;

    local needsWordSpacing = false;
    local totalLogicalWidth = lineBox:GetFlowSpacingLogicalWidth();
    local expansionOpportunityCount = 0;
    local isAfterExpansion = true;
    --Vector<unsigned, 16> expansionOpportunities;
	local expansionOpportunities = {};
    local previousObject = nil;

	local r = firstRun;
	while(r) do
		if (r.box == nil or r.object:IsPositioned() or r.box:IsLineBreak()) then
            -- Positioned objects are only participating to figure out their
            -- correct static x position.  They have no effect on the width.
            -- Similarly, line break boxes have no effect on the width.
		else
			if (r.object:IsText()) then
				local rt = r.object;
				if (textAlign == TextAlignEnum.JUSTIFY and r ~= trailingSpaceRun) then
					if (not isAfterExpansion) then
						r.box:SetCanHaveLeadingExpansion(true);
					end
--					unsigned opportunitiesInRun = Font::expansionOpportunityCount(rt->characters() + r->m_start, r->m_stop - r->m_start, r->m_box->direction(), isAfterExpansion);
--					expansionOpportunities.append(opportunitiesInRun);
--					expansionOpportunityCount += opportunitiesInRun;
				end
				local length = rt:TextLength();
				if (length ~= 0) then
					if (r.start == 0 and needsWordSpacing and UniString.IsSpaceOrNewline(rt:Characters()[r.start])) then
						totalLogicalWidth = totalLogicalWidth + rt:Style(lineInfo:IsFirstLine()):WordSpacing();
					end
					needsWordSpacing = not UniString.IsSpaceOrNewline(rt:Characters()[r.stop - 1]) and r.stop == length;
				end

				setLogicalWidthForTextRun(lineBox, r, rt, totalLogicalWidth, lineInfo, textBoxDataMap, verticalPositionCache);
			else
				isAfterExpansion = false;
				if (not r.object:IsLayoutInline()) then
					--RenderBox* renderBox = toRenderBox(r->m_object);
					local renderBox = r.object;
--					if (renderBox->isRubyRun())
--						setMarginsForRubyRun(r, toRenderRubyRun(renderBox), previousObject, lineInfo);
					echo("r.box:SetLogicalWidth")
					r.box:SetLogicalWidth(self:LogicalWidthForChild(renderBox));
					totalLogicalWidth = totalLogicalWidth + self:MarginStartForChild(renderBox) + self:MarginEndForChild(renderBox);
				end
			end

			totalLogicalWidth = totalLogicalWidth + r.box:LogicalWidth();
			previousObject = r.object;
		end
		r = r:Next();
	end

--	if (isAfterExpansion && !expansionOpportunities.isEmpty()) {
--        expansionOpportunities.last()--;
--        expansionOpportunityCount--;
--    }

	logicalLeft, totalLogicalWidth = self:UpdateLogicalWidthForAlignment(textAlign, trailingSpaceRun, logicalLeft, totalLogicalWidth, availableLogicalWidth, expansionOpportunityCount);

    computeExpansionForJustifiedText(firstRun, trailingSpaceRun, expansionOpportunities, expansionOpportunityCount, totalLogicalWidth, availableLogicalWidth);

    -- The widths of all runs are now known.  We can now place every inline box (and
    -- compute accurate widths for the inline flow boxes).
    needsWordSpacing = false;
    lineBox:PlaceBoxesInInlineDirection(logicalLeft, needsWordSpacing, textBoxDataMap);
end

--void RenderBlock::computeBlockDirectionPositionsForLine(RootInlineBox* lineBox, BidiRun* firstRun, GlyphOverflowAndFallbackFontsMap& textBoxDataMap,
--                                                        VerticalPositionCache& verticalPositionCache)
function LayoutBlock:ComputeBlockDirectionPositionsForLine(lineBox, firstRun, textBoxDataMap, verticalPositionCache)
	echo("LayoutBlock:ComputeBlockDirectionPositionsForLine")
	self:PrintNodeInfo()
	self:SetLogicalHeight(lineBox:AlignBoxesInBlockDirection(self:LogicalHeight(), textBoxDataMap, verticalPositionCache));
	-- Now make sure we place replaced render objects correctly.
	local r = firstRun;
	while(r) do
		--ASSERT(r->m_box);
        if (not r.box) then
            -- Skip runs with no line boxes.
		else
			-- Align positioned boxes with the top of the line box.  This is
			-- a reasonable approximation of an appropriate y position.
			if (r.object:IsPositioned()) then
				r.box:SetLogicalTop(self:LogicalHeight());
			end
			-- Position is used to properly position both replaced elements and
			-- to update the static normal flow x/y of positioned elements.
			if (r.object:IsText()) then
				r.object:PositionLineBox(r.box);
			elseif (r.object:IsBox()) then
				r.object:PositionLineBox(r.box);
			end
		end

		r = r:Next();
	end
    
    -- Positioned objects and zero-length text nodes destroy their boxes in
    -- position(), which unnecessarily dirties the line.
    lineBox:MarkDirty(false);
end

local function parentIsConstructedOrHaveNext(parentBox)
	if (parentBox:IsConstructed() or parentBox:NextOnLine() ~= nil) then
        return true;
	end
    parentBox = parentBox:Parent();
	while(parentBox) do
		if (parentBox:IsConstructed() or parentBox:NextOnLine() ~= nil) then
			return true;
		end
		parentBox = parentBox:Parent();
	end
    return false;
end

--function LayoutBlock:CreateLineBoxes(RenderObject* obj, const LineInfo& lineInfo, InlineBox* childBox)
function LayoutBlock:CreateLineBoxes(obj, lineInfo, childBox)
	-- See if we have an unconstructed line box for this object that is also
    -- the last item on the line.
    local lineDepth = 1;
    local parentBox = nil;
    local result = nil;
    local hasDefaultLineBoxContain = self:Style():LineBoxContain() == ComputedStyle.initialLineBoxContain();
	--local hasDefaultLineBoxContain = true;

	while(true) do
		--ASSERT(obj->isRenderInline() || obj == this);

        local inlineFlow = if_else(obj ~= self, if_else(obj:IsLayoutInline(), obj, nil), nil);

        -- Get the last box we made for this render object.
		if(inlineFlow) then
			parentBox = inlineFlow:LastLineBox();
		else
			parentBox = obj:LastLineBox();
		end
        --parentBox = if_else(inlineFlow, inlineFlow:LastLineBox(), obj:LastLineBox());

		-- If this box or its ancestor is constructed then it is from a previous line, and we need
        -- to make a new box for our line.  If this box or its ancestor is unconstructed but it has
        -- something following it on the line, then we know we have to make a new box
        -- as well.  In this situation our inline has actually been split in two on
        -- the same line (this can happen with very fancy language mixtures).
        local constructedNewBox = false;
        local allowedToConstructNewBox = not hasDefaultLineBoxContain or inlineFlow == nil or inlineFlow:AlwaysCreateLineBoxes();
        local canUseExistingParentBox = parentBox ~= nil and not parentIsConstructedOrHaveNext(parentBox);
		if (allowedToConstructNewBox and not canUseExistingParentBox) then
            -- We need to make a new box for this render object.  Once
            -- made, we need to place it at the end of the current line.
            local newBox = createInlineBoxForRenderer(obj, obj == self);
            --ASSERT(newBox->isInlineFlowBox());
            --parentBox = toInlineFlowBox(newBox);
			parentBox = newBox;
            parentBox:SetFirstLineStyleBit(lineInfo:IsFirstLine());
            parentBox:SetIsHorizontal(self:IsHorizontalWritingMode());
            if (not hasDefaultLineBoxContain) then
                parentBox:ClearDescendantsHaveSameLineHeightAndBaseline();
			end
            constructedNewBox = true;
        end

		if (constructedNewBox or canUseExistingParentBox) then
            if (result == nil) then
                result = parentBox;
			end

            -- If we have hit the block itself, then |box| represents the root
            -- inline box for the line, and it doesn't have to be appended to any parent
            -- inline.
            if (childBox) then
                parentBox:AddToLine(childBox);
			end

            if (not constructedNewBox or obj == self) then
                break;
			end

            childBox = parentBox;
        end

		-- If we've exceeded our line depth, then jump straight to the root and skip all the remaining
        -- intermediate inline flows.
		lineDepth = lineDepth + 1;
        obj = if_else(lineDepth >= cMaxLineDepth, self, obj:Parent());
	end
	return result;
end

local function reachedEndOfTextRenderer(bidiRuns)
    local run = bidiRuns:LogicallyLastRun();
    if (run == nil) then
        return true;
	end
    local pos = run:Stop();
    local r = run.object;
    if (not r:IsText() or r:IsBR()) then
        return false;
	end
    local renderText = r;
    if (pos >= renderText:TextLength()) then
        return true;
	end
    while (UniString.IsASCIISpace(renderText:Characters()[pos])) do
        pos = pos + 1;
        if (pos >= renderText:TextLength()) then
            return true;
		end
    end
    return false;
end

--function LayoutBlock:ConstructLine(BidiRunList<BidiRun>& bidiRuns, const LineInfo& lineInfo)
function LayoutBlock:ConstructLine(bidiRuns, lineInfo)
	--ASSERT(bidiRuns.firstRun());

    local rootHasSelectedChildren = false;
    local parentBox = nil;
	local r = bidiRuns:FirstRun()
	while(r) do
		-- Create a box for our object.
        local isOnlyRun = bidiRuns:RunCount() == 1;
        if (bidiRuns:RunCount() == 2 and not r.object:IsListMarker()) then
			local run = if_else(not self:Style():IsLeftToRightDirection(), bidiRuns:LastRun(), bidiRuns:FirstRun());
            isOnlyRun = run.object:IsListMarker();
		end
        local box = createInlineBoxForRenderer(r.object, false, isOnlyRun);
        r.box = box;
		if(box) then
			if (not rootHasSelectedChildren and box:Renderer():SelectionState() ~= "SelectionNone") then
				rootHasSelectedChildren = true;
			end

			-- If we have no parent box yet, or if the run is not simply a sibling,
			-- then we need to construct inline boxes as necessary to properly enclose the
			-- run's inline box.
			if (not parentBox or parentBox:Renderer() ~= r.object:Parent()) then
				-- Create new inline boxes all the way back to the appropriate insertion point.
				parentBox = self:CreateLineBoxes(r.object:Parent(), lineInfo, box);
			else
				-- Append the inline box to this line.
				parentBox:AddToLine(box);
			end

			local visuallyOrdered = r.object:Style():RtlOrdering() == OrderEnum.VisualOrder;
			--box->setBidiLevel(r->level());

			if (box:IsInlineTextBox()) then
				local text = box;
				text:SetStart(r.start);
				text:SetLen(r.stop - r.start);
				text.dirOverride = r:DirOverride(visuallyOrdered);
				if (r.hasHyphen) then
					text:SetHasHyphen(true);
				end
			end
		end

		r = r:Next();
	end

    -- We should have a root inline box.  It should be unconstructed and
    -- be the last continuation of our line list.
    --ASSERT(lastLineBox() && !lastLineBox()->isConstructed());

    -- Set the m_selectedChildren flag on the root inline box if one of the leaf inline box
    -- from the bidi runs walk above has a selection state.
    if (rootHasSelectedChildren) then
        self:LastLineBox():Root():SetHasSelectedChildren(true);
	end

    -- Set bits on our inline flow boxes that indicate which sides should
    -- paint borders/margins/padding.  This knowledge will ultimately be used when
    -- we determine the horizontal positions and widths of all the inline boxes on
    -- the line.
    local isLogicallyLastRunWrapped = if_else(bidiRuns:LogicallyLastRun():Object() ~= nil and bidiRuns:LogicallyLastRun():Object():IsText(), not reachedEndOfTextRenderer(bidiRuns), true);
    self:LastLineBox():DetermineSpacingForFlowBoxes(lineInfo:IsLastLine(), isLogicallyLastRunWrapped, bidiRuns:LogicallyLastRun():Object());

    -- Now mark the line boxes as being constructed.
    self:LastLineBox():SetConstructed();

    -- Return the last line.
    return self:LastRootBox();
end

function LayoutBlock:CreateLineBoxesFromBidiRuns(bidiRuns, _end, lineInfo, verticalPositionCache, trailingSpaceRun)
	if (bidiRuns:RunCount() == 0) then
        return nil;
	end
    -- FIXME: Why is this only done when we had runs?
    lineInfo:SetLastLine(if_else(_end.obj, false, true));

    local lineBox = self:ConstructLine(bidiRuns, lineInfo);
    if (not lineBox) then
        return nil;
	end

    lineBox:SetEndsWithBreak(lineInfo:PreviousLineBrokeCleanly());
    
--#if ENABLE(SVG)
--    bool isSVGRootInlineBox = lineBox->isSVGRootInlineBox();
--#else
--    bool isSVGRootInlineBox = false;
--#endif
	local isSVGRootInlineBox = lineBox:IsSVGRootInlineBox();
    
    --GlyphOverflowAndFallbackFontsMap textBoxDataMap;
	local textBoxDataMap = {};
    
    -- Now we position all of our text runs horizontally.
    if (not isSVGRootInlineBox) then
        self:ComputeInlineDirectionPositionsForLine(lineBox, lineInfo, bidiRuns:FirstRun(), trailingSpaceRun, _end:AtEnd(), textBoxDataMap, verticalPositionCache);
	end
    
    -- Now position our text runs vertically.
    self:ComputeBlockDirectionPositionsForLine(lineBox, bidiRuns:FirstRun(), textBoxDataMap, verticalPositionCache);
    
--#if ENABLE(SVG)
--    // SVG text layout code computes vertical & horizontal positions on its own.
--    // Note that we still need to execute computeVerticalPositionsForLine() as
--    // it calls InlineTextBox::positionLineBox(), which tracks whether the box
--    // contains reversed text or not. If we wouldn't do that editing and thus
--    // text selection in RTL boxes would not work as expected.
--    if (isSVGRootInlineBox) {
--        ASSERT(isSVGText());
--        static_cast<SVGRootInlineBox*>(lineBox)->computePerCharacterLayoutInformation();
--    }
--#endif
    
    -- Compute our overflow now.
    lineBox:ComputeOverflow(lineBox:LineTop(), lineBox:LineBottom(), textBoxDataMap);
    
--#if PLATFORM(MAC)
--    // Highlight acts as an overflow inflation.
--    if (style()->highlight() != nullAtom)
--        lineBox->addHighlightOverflow();
--#endif
	
    return lineBox;
end

function LayoutBlock:AppendFloatingObjectToLastLine(floatingObject)
    --ASSERT(!floatingObject->m_originatingLine);
    floatingObject.originatingLine = self:LastRootBox();
    self:LastRootBox():AppendFloat(floatingObject:Renderer());
end

function LayoutBlock:LayoutRunsAndFloatsInRange(layoutState, resolver, cleanLineStart, cleanLineBidiStatus, consecutiveHyphenatedLines)
	--bool paginated = view()->layoutState() && view()->layoutState()->isPaginated();
	local paginated = false;
	if(self:View():LayoutState()) then
		paginated = self:View():LayoutState():IsPaginated();
	end
    local lineMidpointState = resolver:MidpointState();
    local _end = resolver:Position():Clone();
    local checkForEndLineMatch = layoutState:EndLine();
    local lineBreakIteratorInfo = {first = nil, second = LazyLineBreakIterator:new()};
    --VerticalPositionCache verticalPositionCache;
	local verticalPositionCache;

    local lineBreaker = LineBreaker:new():init(self);

    while (not _end:AtEnd()) do
        -- FIXME: Is this check necessary before the first iteration or can it be moved to the end?
        if (checkForEndLineMatch) then
            layoutState:SetEndLineMatched(self:MatchedEndLine(layoutState, resolver, cleanLineStart, cleanLineBidiStatus));
            if (layoutState:EndLineMatched()) then
                break;
			end
        end

        lineMidpointState:Reset();

        layoutState:LineInfo():SetEmpty(true);

        local oldEnd = _end:Clone();
        local isNewUBAParagraph = layoutState:LineInfo():PreviousLineBrokeCleanly();
        --FloatingObject* lastFloatFromPreviousLine = (m_floatingObjects && !m_floatingObjects->set().isEmpty()) ? m_floatingObjects->set().last() : 0;
		local lastFloatFromPreviousLine = nil;
		if(self.floatingObjects and not self.floatingObjects:Set():isEmpty()) then
			lastFloatFromPreviousLine = self.floatingObjects:Set():last();
		end
        _end = lineBreaker:NextLineBreak(resolver, layoutState:LineInfo(), lineBreakIteratorInfo, lastFloatFromPreviousLine, consecutiveHyphenatedLines);
		
        if (resolver:Position():AtEnd()) then
            -- FIXME: We shouldn't be creating any runs in findNextLineBreak to begin with!
            -- Once BidiRunList is separated from BidiResolver this will not be needed.
            resolver:Runs():DeleteRuns();
            resolver:MarkCurrentRunEmpty(); -- FIXME: This can probably be replaced by an ASSERT (or just removed).
            layoutState:SetCheckForFloatsFromLastLine(true);
            break;
        end
        --ASSERT(end != resolver.position());

        -- This is a short-cut for empty lines.
        if (layoutState:LineInfo():IsEmpty()) then	
            if (self:LastRootBox()) then
                self:LastRootBox():SetLineBreakInfo(_end.obj, _end.pos, resolver:Status());
			end
        else
            local override = if_else(self:Style():RtlOrdering() == OrderEnum.VisualOrder, if_else(self:Style():Direction() == TextDirectionEnum.LTR, "VisualLeftToRightOverride", "VisualRightToLeftOverride"), "NoVisualOverride");
			--local override = nil;

--            if (isNewUBAParagraph and self:Style():UnicodeBidi() == "Plaintext" and !resolver.context()->parent()) then
--                TextDirection direction = style()->direction();
--                determineParagraphDirection(direction, resolver.position());
--                resolver.setStatus(BidiStatus(direction, style()->unicodeBidi() == Override));
--            end

            -- FIXME: This ownership is reversed. We should own the BidiRunList and pass it to createBidiRunsForLine.
            local bidiRuns = resolver:Runs();
            constructBidiRuns(resolver, bidiRuns, _end, override, layoutState:LineInfo():PreviousLineBrokeCleanly());
			bidiRuns:print();
            --ASSERT(resolver.position() == end);

            --BidiRun* trailingSpaceRun = !layoutState.lineInfo().previousLineBrokeCleanly() ? handleTrailingSpaces(bidiRuns, resolver.context()) : 0;
			local trailingSpaceRun = nil;
			if(not layoutState:LineInfo():PreviousLineBrokeCleanly()) then
				trailingSpaceRun = self:HandleTrailingSpaces(bidiRuns, resolver:Context())
			end

            if (bidiRuns:RunCount() ~= 0 and lineBreaker:LineWasHyphenated()) then
                bidiRuns:LogicallyLastRun().hasHyphen = true;
                consecutiveHyphenatedLines = consecutiveHyphenatedLines + 1;
            else
                consecutiveHyphenatedLines = 0;
			end

            -- Now that the runs have been ordered, we create the line boxes.
            -- At the same time we figure out where border/padding/margin should be applied for
            -- inline flow boxes.

            local oldLogicalHeight = self:LogicalHeight();
            local lineBox = self:CreateLineBoxesFromBidiRuns(bidiRuns, _end, layoutState:LineInfo(), verticalPositionCache, trailingSpaceRun);
            bidiRuns:DeleteRuns();
            resolver:MarkCurrentRunEmpty(); -- FIXME: This can probably be replaced by an ASSERT (or just removed).

            if (lineBox) then
                lineBox:SetLineBreakInfo(_end.obj, _end.pos, resolver:Status());
                if (layoutState:UsesRepaintBounds()) then
                    layoutState:UpdateRepaintRangeFromBox(lineBox);
				end
--                if (paginated) {
--                    int adjustment = 0;
--                    adjustLinePositionForPagination(lineBox, adjustment);
--                    if (adjustment) {
--                        int oldLineWidth = availableLogicalWidthForLine(oldLogicalHeight, layoutState.lineInfo().isFirstLine());
--                        lineBox->adjustBlockDirectionPosition(adjustment);
--                        if (layoutState.usesRepaintBounds())
--                            layoutState.updateRepaintRangeFromBox(lineBox);
--
--                        if (availableLogicalWidthForLine(oldLogicalHeight + adjustment, layoutState.lineInfo().isFirstLine()) != oldLineWidth) {
--                            // We have to delete this line, remove all floats that got added, and let line layout re-run.
--                            lineBox->deleteLine(renderArena());
--                            removeFloatingObjectsBelow(lastFloatFromPreviousLine, oldLogicalHeight);
--                            setLogicalHeight(oldLogicalHeight + adjustment);
--                            resolver.setPosition(oldEnd);
--                            end = oldEnd;
--                            continue;
--                        }
--
--                        setLogicalHeight(lineBox->lineBottomWithLeading());
--                    }
--                }
            end

			for i = 1, lineBreaker:PositionedObjects():size() do
				setStaticPositions(self, lineBreaker:PositionedObjects()[i]);
			end

            layoutState:LineInfo():SetFirstLine(false);
            self:NewLine(lineBreaker:Clear());
        end

        if (self.floatingObjects and self:LastRootBox()) then
			local floatingObjectSet = self.floatingObjects:Set();
			local it = floatingObjectSet:Begin();
			if (layoutState:LastFloat()) then
                local lastFloatIterator = floatingObjectSet:find(layoutState:LastFloat());
                --ASSERT(lastFloatIterator != end);
                it = floatingObjectSet:next(lastFloatIterator);
            end
			while(it) do
				local floatingObject = it();
				self:AppendFloatingObjectToLastLine(floatingObject);
                --ASSERT(f->m_renderer == layoutState.floats()[layoutState.floatIndex()].object);
                -- If a float's geometry has changed, give up on syncing with clean lines.
                if (layoutState:Floats()[layoutState:FloatIndex()]:Rect() ~= floatingObject:FrameRect()) then
                    checkForEndLineMatch = false;
				end
                layoutState:SetFloatIndex(layoutState:FloatIndex() + 1);
	
	
				it = floatingObjectSet:next(it);
			end
			local lastFloat = nil;
			if(not floatingObjectSet:isEmpty()) then
				lastFloat = floatingObjectSet:last();
			end
			layoutState:SetLastFloat(lastFloat);
        end

        lineMidpointState:Reset();
        resolver:SetPosition(_end);
    end
end

--void RenderBlock::repaintDirtyFloats(Vector<FloatWithRect>& floats)
function LayoutBlock:RepaintDirtyFloats(floats)
    local floatCount = floats:size();
    -- Floats that did not have layout did not repaint when we laid them out. They would have
    -- painted by now if they had moved, but if they stayed at (0, 0), they still need to be
    -- painted.
    for i = 1, floatCount do
        if (not floats[i]:EverHadLayout()) then
            local f = floats[i]:Object();
            --if (!f->x() && !f->y() && f->checkForRepaintDuringLayout()) then
			if (f:X() == 0 and f:Y() == 0 and f:CheckForRepaintDuringLayout()) then
                f:Repaint();
			end
        end
    end
end

local function createRun(_start, _end, obj, resolver)
    return BidiRun:new():init(_start, _end, obj, resolver:Context(), resolver:Dir());
end

function LayoutBlock.AppendRunsForObject(runs, _start, _end, obj, resolver)
	if (_start > _end or obj:IsFloating() or
        (obj:IsPositioned() and not obj:Style():IsOriginalDisplayInlineType() and not obj:Container():IsLayoutInline())) then
        return;
	end
	local lineMidpointState = resolver:MidpointState();
    local haveNextMidpoint = lineMidpointState.currentMidpoint < lineMidpointState.numMidpoints;
    local nextMidpoint;
    if (haveNextMidpoint) then
        nextMidpoint = lineMidpointState.midpoints[lineMidpointState.currentMidpoint];
	end
    if (lineMidpointState.betweenMidpoints) then
        if (not (haveNextMidpoint and nextMidpoint.obj == obj)) then
            return;
		end
        -- This is a new start point. Stop ignoring objects and
        -- adjust our start.
        lineMidpointState.betweenMidpoints = false;
        start = nextMidpoint.pos;
        lineMidpointState.currentMidpoint = lineMidpointState.currentMidpoint + 1;
        if (_start < _end) then
            return LayoutBlock.AppendRunsForObject(runs, _start, _end, obj, resolver);
		end
    else
        if (not haveNextMidpoint or (obj ~= nextMidpoint.obj)) then
            runs:AddRun(createRun(_start, _end, obj, resolver));
            return;
        end

        -- An end midpoint has been encountered within our object.  We
        -- need to go ahead and append a run with our endpoint.
        if (nextMidpoint.pos + 1 <= _end) then
            lineMidpointState.betweenMidpoints = true;
            lineMidpointState.currentMidpoint = lineMidpointState.currentMidpoint + 1;
            if (nextMidpoint.pos ~= INT_MAX) then -- UINT_MAX means stop at the object and don't include any of it.
                if (nextMidpoint.pos + 1 > _start) then
                    runs:AddRun(createRun(start, nextMidpoint.pos + 1, obj, resolver));
				end
                return LayoutBlock.AppendRunsForObject(runs, nextMidpoint.pos + 1, _end, obj, resolver);
            end
        else
           runs:AddRun(createRun(_start, _end, obj, resolver));
		end
    end
end

--bool RenderBlock::positionNewFloatOnLine(FloatingObject* newFloat, FloatingObject* lastFloatFromPreviousLine, LineInfo& lineInfo, LineWidth& width)
function LayoutBlock:PositionNewFloatOnLine(newFloat, lastFloatFromPreviousLine, lineInfo, width)
	echo("LayoutBlock:PositionNewFloatOnLine")
    if (not self:PositionNewFloats()) then
        return false;
	end
	newFloat:Renderer():PrintNodeInfo()
	echo(newFloat:Renderer().frame_rect)
    width:ShrinkAvailableWidthForNewFloatIfNeeded(newFloat);

    -- We only connect floats to lines for pagination purposes if the floats occur at the start of
    -- the line and the previous line had a hard break (so this line is either the first in the block
    -- or follows a <br>).
    if (newFloat.paginationStrut == 0  or not lineInfo:PreviousLineBrokeCleanly() or not lineInfo:IsEmpty()) then
        return true;
	end

    local floatingObjectSet = self.floatingObjects:Set();
    --ASSERT(floatingObjectSet.last() == newFloat);

    local floatLogicalTop = self:LogicalTopForFloat(newFloat);
    local paginationStrut = newFloat.paginationStrut;

    if (floatLogicalTop - paginationStrut ~= self:LogicalHeight() + lineInfo:FloatPaginationStrut()) then
        return true;
	end

	local item = floatingObjectSet:last();
	local begin = floatingObjectSet:first();
	while(item ~= begin) do
		item = item.prev;
		local floatingObject = item;
		if(floatingObject == lastFloatFromPreviousLine) then
			break;
		end
		if (self:LogicalTopForFloat(floatingObject) == self:LogicalHeight() + lineInfo:FloatPaginationStrut()) then
            floatingObject.paginationStrut = floatingObject.paginationStrut + paginationStrut;
            local obj = floatingObject.renderer;
            self:SetLogicalTopForChild(obj, self:LogicalTopForChild(obj) + self:MarginBeforeForChild(obj) + paginationStrut);
            if (obj:IsLayoutBlock()) then
                obj:SetChildNeedsLayout(true, false);
			end
            obj:LayoutIfNeeded();
            -- Save the old logical top before calling removePlacedObject which will set
            -- isPlaced to false. Otherwise it will trigger an assert in logicalTopForFloat.
            local oldLogicalTop = self:LogicalTopForFloat(floatingObject);
            self.floatingObjects:RemovePlacedObject(floatingObject);
            self:SetLogicalTopForFloat(floatingObject, oldLogicalTop + paginationStrut);
            self.floatingObjects:AddPlacedObject(floatingObject);
        end
	end

    -- Just update the line info's pagination strut without altering our logical height yet. If the line ends up containing
    -- no content, then we don't want to improperly grow the height of the block.
    lineInfo:SetFloatPaginationStrut(lineInfo:FloatPaginationStrut() + paginationStrut);
    return true;
end

--void RenderBlock::checkFloatsInCleanLine(RootInlineBox* line, Vector<FloatWithRect>& floats, size_t& floatIndex, bool& encounteredNewFloat, bool& dirtiedByFloat)
function LayoutBlock:CheckFloatsInCleanLine(line, floats, floatIndex, encounteredNewFloat, dirtiedByFloat)
    --Vector<RenderBox*>* cleanLineFloats = line->floatsPtr();
	local cleanLineFloats = line:FloatsPtr();
    if (cleanLineFloats == nil) then
        return floatIndex, encounteredNewFloat, dirtiedByFloat;
	end

	local size = cleanLineFloats:size();
	for i = 1,size do
		floatingBox = cleanLineFloats:get(i);
		floatingBox:LayoutIfNeeded();
        local newSize = IntSize:new(floatingBox:Width() + floatingBox:MarginLeft() + floatingBox:MarginRight(), floatingBox:Height() + floatingBox:MarginTop() + floatingBox:MarginBottom());
        --ASSERT(floatIndex < floats.size());
        if (floats[floatIndex].object ~= floatingBox) then
            encounteredNewFloat = true;
            return floatIndex, encounteredNewFloat, dirtiedByFloat;
        end

        if (floats[floatIndex].rect:Size() ~= newSize) then
			local floatTop, floatHeight;
			if(self:IsHorizontalWritingMode()) then
				floatTop = floats[floatIndex].rect:Y();
				floatHeight = math.max(floats[floatIndex].rect:Height(), newSize:Height());
			else
				floatTop = floats[floatIndex].rect:X();
				floatHeight = math.max(floats[floatIndex].rect:Width(), newSize:Width());
			end
			
            floatHeight = math.min(floatHeight, INT_MAX - floatTop);
            line:MarkDirty();
            self:MarkLinesDirtyInBlockRange(line:LineBottomWithLeading(), floatTop + floatHeight, line);
            floats[floatIndex].rect:SetSize(newSize);
            dirtiedByFloat = true;
        end
        floatIndex = floatIndex + 1;
	end
	
	return floatIndex, encounteredNewFloat, dirtiedByFloat;
end

--void RenderBlock::determineEndPosition(LineLayoutState& layoutState, RootInlineBox* startLine, InlineIterator& cleanLineStart, BidiStatus& cleanLineBidiStatus)
function LayoutBlock:DetermineEndPosition(layoutState, startLine, cleanLineStart, cleanLineBidiStatus)
    --ASSERT(!layoutState.endLine());
    local floatIndex = layoutState:FloatIndex();
	--RootInlineBox* last = 0;
	local last = nil;
	local curr = startLine:NextRootBox();
	while(curr) do
		if (not curr:IsDirty()) then
            local encounteredNewFloat = false;
            local dirtiedByFloat = false;
            floatIndex, encounteredNewFloat, dirtiedByFloat = self:CheckFloatsInCleanLine(curr, layoutState:Floats(), floatIndex, encounteredNewFloat, dirtiedByFloat);
            if (encounteredNewFloat) then
                return cleanLineStart, cleanLineBidiStatus;
			end
        end
        if (curr:IsDirty()) then
            last = nil;
        elseif (last == nil) then
            last = curr;
		end
	
		curr = curr:NextRootBox();
	end

    if (last == nil) then
        return cleanLineStart, cleanLineBidiStatus;
	end

    -- At this point, |last| is the first line in a run of clean lines that ends with the last line
    -- in the block.

    local prev = last:PrevRootBox();
    cleanLineStart = InlineIterator:new():init(self, prev:LineBreakObj(), prev:LineBreakPos());
    cleanLineBidiStatus = prev:LineBreakBidiStatus();
    layoutState:SetEndLineLogicalTop(prev:LineBottomWithLeading());

	local line = last;
	while(line) do
		line:ExtractLine(); -- Disconnect all line boxes from their render objects while preserving
                             -- their connections to one another.
	
		line = line:NextRootBox();
	end

    layoutState:SetEndLine(last);
	return cleanLineStart, cleanLineBidiStatus;
end

--bool RenderBlock::checkPaginationAndFloatsAtEndLine(LineLayoutState& layoutState)
function LayoutBlock:CheckPaginationAndFloatsAtEndLine(layoutState)
    local lineDelta = self:LogicalHeight() - layoutState:EndLineLogicalTop();

	local paginated = false;
	if(self:View():LayoutState()) then
		paginated = self:View():LayoutState():IsPaginated();
	end
    if (paginated and self:InRenderFlowThread()) then
--        // Check all lines from here to the end, and see if the hypothetical new position for the lines will result
--        // in a different available line width.
--        for (RootInlineBox* lineBox = layoutState.endLine(); lineBox; lineBox = lineBox->nextRootBox()) {
--            if (paginated) {
--                // This isn't the real move we're going to do, so don't update the line box's pagination
--                // strut yet.
--                LayoutUnit oldPaginationStrut = lineBox->paginationStrut();
--                lineDelta -= oldPaginationStrut;
--                adjustLinePositionForPagination(lineBox, lineDelta);
--                lineBox->setPaginationStrut(oldPaginationStrut);
--            }
--            if (lineWidthForPaginatedLineChanged(lineBox, lineDelta))
--                return false;
--        }
    end
    
    if (lineDelta == 0 or self.floatingObjects == nil) then
        return true;
	end
    
    -- See if any floats end in the range along which we want to shift the lines vertically.
    local logicalTop = math.min(self:LogicalHeight(), layoutState:EndLineLogicalTop());

	
    local lastLine = layoutState:EndLine();
	local nextLine = lastLine:NextRootBox();
	while(nextLine) do
		lastLine = nextLine;
		nextLine = lastLine:NextRootBox();
	end

    local logicalBottom = lastLine:LineBottomWithLeading() + math.abs(lineDelta);

	local floatingObjectSet = self.floatingObjects:Set();
	local it = floatingObjectSet:Begin();
	while(it) do
		local floatingObject = it();
		if (self:LogicalBottomForFloat(f) >= logicalTop and self:LogicalBottomForFloat(f) < logicalBottom) then
            return false;
		end
		
		it = floatingObjectSet:next(it);
	end
	
    return true;
end

--bool RenderBlock::matchedEndLine(LineLayoutState& layoutState, const InlineBidiResolver& resolver, const InlineIterator& endLineStart, const BidiStatus& endLineStatus)
function LayoutBlock:MatchedEndLine(layoutState, resolver, endLineStart, endLineStatus)
    if (resolver:Position() == endLineStart) then
        if (resolver:Status() ~= endLineStatus) then
            return false;
		end
        return self:CheckPaginationAndFloatsAtEndLine(layoutState);
    end

    -- The first clean line doesn't match, but we can check a handful of following lines to try
    -- to match back up.
	-- static int numLines = 8; -- The # of lines we're willing to match against.
	local numLines = 8;
    local originalEndLine = layoutState:EndLine();
    local line = originalEndLine;
	local i = 0;
	while(i < numLines and line ~= nil) do
		if (line:LineBreakObj() == resolver:Position().obj and line:LineBreakPos() == resolver:Position().pos) then
            -- We have a match.
            if (line:LineBreakBidiStatus() ~= resolver:Status()) then
                return false; -- ...but the bidi state doesn't match.
			end
            
            local matched = false;
            local result = line:NextRootBox();
            layoutState:SetEndLine(result);
            if (result) then
                layoutState:SetEndLineLogicalTop(line:LineBottomWithLeading());
                matched = self:CheckPaginationAndFloatsAtEndLine(layoutState);
            end

            -- Now delete the lines that we failed to sync.
            deleteLineRange(layoutState, self:RenderArena(), originalEndLine, result);
            return matched;
        end
	
		
		i = i + 1;
		line = line:NextRootBox();
	end
    
    return false;
end

--void RenderBlock::linkToEndLineIfNeeded(LineLayoutState& layoutState)
function LayoutBlock:LinkToEndLineIfNeeded(layoutState)
    if (layoutState:EndLine()) then
        if (layoutState:EndLineMatched()) then
            --bool paginated = view()->layoutState() and view()->layoutState()->isPaginated();
			local paginated = false;
			if(self:View():LayoutState()) then
				paginated = self:View():LayoutState():IsPaginated();
			end
            -- Attach all the remaining lines, and then adjust their y-positions as needed.
            local delta = self:LogicalHeight() - layoutState:EndLineLogicalTop();
			local line = layoutState:EndLine();
			while(line) do
				line:AttachLine();
                if (paginated) then
                    --delta -= line->paginationStrut();
                    --adjustLinePositionForPagination(line, delta);
                end
                if (delta ~= 0) then
                    layoutState:UpdateRepaintRangeFromBox(line, delta);
                    line:AdjustBlockDirectionPosition(delta);
                end
				local cleanLineFloats = line:FloatsPtr();
                if (cleanLineFloats ~= nil) then
					for i = 1,cleanLineFloats:size() do
						local f = cleanLineFloats:get(i);
						local floatingObject = self:InsertFloatingObject(f);
						--ASSERT(!floatingObject->m_originatingLine);
						floatingObject.originatingLine = line;
						self:SetLogicalHeight(self:LogicalTopForChild(f) - self:MarginBeforeForChild(f) + delta);
						self:PositionNewFloats();
					end
                end
			
				line = line:NextRootBox();
			end

            self:SetLogicalHeight(self:LastRootBox():LineBottomWithLeading());
        else
            -- Delete all the remaining lines.
            deleteLineRange(layoutState, self:RenderArena(), layoutState:EndLine());
        end
    end
    
    if (self.floatingObjects ~= nil and (layoutState:CheckForFloatsFromLastLine() or self:PositionNewFloats()) and self:LastRootBox() ~= nil) then
        -- In case we have a float on the last line, it might not be positioned up to now.
        -- This has to be done before adding in the bottom border/padding, or the float will
        -- include the padding incorrectly. -dwh
        if (layoutState:CheckForFloatsFromLastLine()) then
            local bottomVisualOverflow = self:LastRootBox():LogicalBottomVisualOverflow();
            local bottomLayoutOverflow = self:LastRootBox():LogicalBottomLayoutOverflow();
            local trailingFloatsLineBox = TrailingFloatsRootInlineBox:new():init(self);
            self.lineBoxes:AppendLineBox(trailingFloatsLineBox);
            trailingFloatsLineBox:SetConstructed();
            --GlyphOverflowAndFallbackFontsMap textBoxDataMap;
			local textBoxDataMap = nil;
            --VerticalPositionCache verticalPositionCache;
			local verticalPositionCache = nil;
            local blockLogicalHeight = self:LogicalHeight();
            trailingFloatsLineBox:AlignBoxesInBlockDirection(blockLogicalHeight, textBoxDataMap, verticalPositionCache);
            trailingFloatsLineBox:SetLineTopBottomPositions(blockLogicalHeight, blockLogicalHeight, blockLogicalHeight, blockLogicalHeight);
            trailingFloatsLineBox:SetPaginatedLineWidth(self:AvailableLogicalWidthForContent(blockLogicalHeight));
            local logicalLayoutOverflow = IntRect:new(0, blockLogicalHeight, 1, bottomLayoutOverflow - blockLogicalHeight);
            local logicalVisualOverflow = IntRect:new(0, blockLogicalHeight, 1, bottomVisualOverflow - blockLogicalHeight);
            trailingFloatsLineBox:SetOverflowFromLogicalRects(logicalLayoutOverflow, logicalVisualOverflow, trailingFloatsLineBox:LineTop(), trailingFloatsLineBox:LineBottom());
        end

		local floatingObjectSet = self.floatingObjects:Set();
		local it = floatingObjectSet:Begin();
		
		if (layoutState:LastFloat()) then
			local lastFloatIterator = floatingObjectSet:find(layoutState:LastFloat());
            it = floatingObjectSet:next(lastFloatIterator);
		end
		
		while(it) do
			self:AppendFloatingObjectToLastLine(it());
			
			it = floatingObjectSet:next(it);
		end
		if(floatingObjectSet:isEmpty()) then
			layoutState:SetLastFloat(nil);
		else
			layoutState:SetLastFloat(floatingObjectSet:last());
		end
    end
end

function LayoutBlock:AddOverflowFromInlineChildren()
    local endPadding = if_else(self:HasOverflowClip(), self:PaddingEnd(), 0);
    -- FIXME: Need to find another way to do this, since scrollbars could show when we don't want them to.
    --if (hasOverflowClip() && !endPadding && node() && node()->rendererIsEditable() && node() == node()->rootEditableElement() && style()->isLeftToRightDirection())
--	if (self:HasOverflowClip() and endPadding == 0 and self:Style():IsLeftToRightDirection()) then
--        endPadding = 1;
--	end
	local curr = self:FirstRootBox();
	while(curr) do
		echo("LayoutBlock:AddOverflowFromInlineChildren")
		self:AddLayoutOverflow(curr:PaddedLayoutOverflowRect(endPadding));
        if (not self:HasOverflowClip()) then
            self:AddVisualOverflow(curr:VisualOverflowRect(curr:LineTop(), curr:LineBottom()));
		end
		curr = curr:NextRootBox();
	end
end

--inline BidiRun* RenderBlock::handleTrailingSpaces(BidiRunList<BidiRun>& bidiRuns, BidiContext* currentContext)
function LayoutBlock:HandleTrailingSpaces(bidiRuns, currentContext)
    if (bidiRuns:RunCount() == 0
        or not bidiRuns:LogicallyLastRun().object:Style():BreakOnlyAfterWhiteSpace()
        or not bidiRuns:LogicallyLastRun().object:Style():AutoWrap()) then
        return nil;
	end

    local trailingSpaceRun = bidiRuns:LogicallyLastRun();
    local lastObject = trailingSpaceRun.object;
    if (not lastObject:IsText()) then
        return nil;
	end

    local lastText = lastObject:ToRenderText();
    local characters = lastText:Characters();
    local firstSpace = trailingSpaceRun:Stop();
    while (firstSpace > trailingSpaceRun:Start()) do
        local current = tostring(characters[firstSpace - 1]);
        if (not isCollapsibleSpace(current, lastText)) then
            break;
		end
        firstSpace = firstSpace - 1;
    end
    if (firstSpace == trailingSpaceRun:Stop()) then
        return nil;
	end

    local direction = self:Style():Direction();
    local shouldReorder = trailingSpaceRun ~= if_else(direction == TextDirectionEnum.LTR, bidiRuns:LastRun(), bidiRuns:FirstRun());
    if (firstSpace ~= trailingSpaceRun:Start()) then
        local baseContext = currentContext;
		local parent = baseContext:Parent();
        while (parent) do
            baseContext = parent;
			parent = baseContext:Parent()
		end

        local newTrailingRun = BidiRun:new(firstSpace, trailingSpaceRun.stop, trailingSpaceRun.object, baseContext, "OtherNeutral");
        trailingSpaceRun.stop = firstSpace;
        if (direction == TextDirectionEnum.LTR) then
            bidiRuns:AddRun(newTrailingRun);
        else
            bidiRuns:PrependRun(newTrailingRun);
		end
        trailingSpaceRun = newTrailingRun;
        return trailingSpaceRun;
    end
    if (not shouldReorder) then
        return trailingSpaceRun;
	end

    if (direction == TextDirectionEnum.LTR) then
        bidiRuns:MoveRunToEnd(trailingSpaceRun);
        trailingSpaceRun.level = 0;
    else
        bidiRuns:MoveRunToBeginning(trailingSpaceRun);
        trailingSpaceRun.level = 1;
    end
    return trailingSpaceRun;
end