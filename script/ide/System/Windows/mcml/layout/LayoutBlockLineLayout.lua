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
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/Length.lua");
NPL.load("(gl)script/ide/STL.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Core/UniString.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObject.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/text/BidiResolver.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/text/TextBreakIterator.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/BreakLines.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/BidiRun.lua");
local BidiRun = commonlib.gettable("System.Windows.mcml.layout.BidiRun");
local InlineBidiResolver = commonlib.gettable("System.Windows.mcml.layout.InlineBidiResolver");
local BreakLines = commonlib.gettable("System.Windows.mcml.layout.BreakLines");
local LazyLineBreakIterator = commonlib.gettable("System.Windows.mcml.platform.text.LazyLineBreakIterator");
local InlineIterator = commonlib.gettable("System.Windows.mcml.layout.InlineIterator");
local BidiStatus = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.platform.text.BidiStatus"));
local BidiResolver = commonlib.gettable("System.Windows.mcml.platform.text.BidiResolver");
local UniString = commonlib.gettable("System.Core.UniString");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");
local Length = commonlib.gettable("System.Windows.mcml.platform.graphics.Length");
local InlineWalker = commonlib.gettable("System.Windows.mcml.layout.InlineWalker");
local LayoutBlock = commonlib.gettable("System.Windows.mcml.layout.LayoutBlock");
local FloatingObject = commonlib.gettable("System.Windows.mcml.layout.LayoutBlock.FloatingObject");

local LineWidth = commonlib.inherit(nil, {});
local LineBreaker = commonlib.inherit(nil, {});
local LineLayoutState = commonlib.inherit(nil, {});
local LineInfo = commonlib.inherit(nil, {});

function LineBreaker:ctor()
	self.block = nil;
    self.hyphenated = nil;
    self.clear = nil;
    self.positionedObjects = nil;
end

function LineBreaker:init(block)
	self.block = block;
	self:Reset();
	return self;
end

function LineBreaker:Reset()
	--self.positionedObjects.clear();
    self.hyphenated = false;
    self.clear = "CNONE";
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
            --addMidpoint(lineMidpointState, InlineIterator(0, o, 0));
            return true;
        end
    end

    return false;
end

function LineBreaker:NextLineBreak(resolver, lineInfo, lineBreakIteratorInfo, lastFloatFromPreviousLine, consecutiveHyphenatedLines)
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

	-- This variable tracks whether the very last character we saw was a space.  We use
    -- this to detect when we encounter a second space so we know we have to terminate
    -- a run.
    local currentCharacterIsSpace = false;
    local currentCharacterIsWS = false;
    --TrailingObjects trailingObjects;
	local trailingObjects;

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

	local currWS = self.block:Style():WhiteSpace();
    local lastWS = currWS;

	local go_to_end = false;
	while (current.obj) do
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

		end

		if (current.obj:IsFloating()) then
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
                    -- trailingObjects.clear();
                    --addMidpoint(lineMidpointState, InlineIterator(0, current.m_obj, 0)); -- Stop ignoring spaces.
                    --addMidpoint(lineMidpointState, InlineIterator(0, current.m_obj, 0)); -- Start ignoring again.
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

		elseif(current.obj:IsText()) then
			if (current.pos ~= 1) then
				appliedStartWidth = false;
			end

			--RenderText* t = toRenderText(current.m_obj);
			local t = current.obj;

			local style = t:Style(lineInfo:IsFirstLine());
			--            if (style->hasTextCombine() && current.m_obj->isCombineText())
			--              toRenderCombineText(current.m_obj)->combineText();

			local f = style:Font();
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
			local breakNBSP = autoWrap and current.obj:Style():NbspMode() == "SPACE";
			local breakWords = current.obj:Style():BreakWords() and ((autoWrap and width:CommittedWidth() == 0) or currWS == "PRE");
			local midWordBreak = false;
			local breakAll = current.obj:Style():WordBreak() == "BreakAllWordBreak" and autoWrap;
			--float hyphenWidth = 0;

			if (t:IsWordBreak()) then
				width:Commit();
				lBreak:MoveToStartOf(current.obj);
				--ASSERT(current.m_pos == t->textLength());
			end


			while(current.pos <= t:TextLength()) do
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
				local betweenWords = c_str == "\n" or (currWS ~= "PRE" and not atStart and isBreakable);

				if((betweenWords or midWordBreak) and (ignoringSpaces and currentCharacterIsSpace)) then
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
								--addMidpoint(lineMidpointState, InlineIterator(0, current.m_obj, current.m_pos));
								stoppedIgnoringSpaces = true;
							end
						end

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
										--addMidpoint(lineMidpointState, InlineIterator(0, current.m_obj, current.m_pos - 1)); // Stop
										--addMidpoint(lineMidpointState, InlineIterator(0, current.m_obj, current.m_pos)); // Start
									end
									lBreak:Increment();
									lineInfo:SetPreviousLineBrokeCleanly(true);
								end
--								if (lBreak.m_obj && lBreak.m_pos && lBreak.m_obj->isText() && toRenderText(lBreak.m_obj)->textLength() && toRenderText(lBreak.m_obj)->characters()[lBreak.m_pos - 1] == softHyphen && style->hyphens() != HyphensNone)
--									m_hyphenated = true;
								go_to_end = true; -- Didn't fit. Jump to the end.
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
								--addMidpoint(lineMidpointState, InlineIterator(0, current.m_obj, current.m_pos - 1)); // Stop
								--addMidpoint(lineMidpointState, InlineIterator(0, current.m_obj, current.m_pos)); // Start
							end
							lBreak:MoveTo(current.obj, current.pos, current.nextBreakablePosition);
							lBreak:Increment();
							lineInfo:SetPreviousLineBrokeCleanly(true);
							return lBreak;
						end

						if (autoWrap and betweenWords) then
							width:Commit();
							wrapW = 0;
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
--								addMidpoint(lineMidpointState, ignoreStart);
--								trailingObjects.updateMidpointsForTrailingBoxes(lineMidpointState, InlineIterator(), TrailingObjects::DoNotCollapseFirstSpace);
							end
						end
					elseif (ignoringSpaces) then
						-- Stop ignoring spaces and begin at this new point.
						ignoringSpaces = false;
						lastSpaceWordSpacing = if_else(applyWordSpacing, wordSpacing, 0);
						lastSpace = current.pos; -- e.g., "Foo    goo", don't add in any of the ignored spaces.
						--addMidpoint(lineMidpointState, InlineIterator(0, current.m_obj, current.m_pos));
					end

					if (currentCharacterIsSpace and not previousCharacterIsSpace) then
						--ignoreStart.m_obj = current.m_obj;
						--ignoreStart.m_pos = current.m_pos;
					end

					if (not currentCharacterIsWS and previousCharacterIsWS) then
						if (autoWrap and current.obj:Style():BreakOnlyAfterWhiteSpace()) then
							lBreak:MoveTo(current.obj, current.pos, current.nextBreakablePosition);
						end
					end

--					if (collapseWhiteSpace && currentCharacterIsSpace && !ignoringSpaces)
--						trailingObjects.setTrailingWhitespace(toRenderText(current.m_obj));
--					else if (!current.m_obj->style()->collapseWhiteSpace() || !currentCharacterIsSpace)
--						trailingObjects.clear();

					atStart = false;
				end

				current:FastIncrementInTextNode();
			end
			if(go_to_end) then
				break;
			end

			-- IMPORTANT: current.m_pos is > length here!
            local additionalTmpW = if_else(ignoringSpaces, 0, textWidth(t, lastSpace, current.pos - lastSpace, f) + lastSpaceWordSpacing);
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

		local checkForBreak = autoWrap;
        if (width:CommittedWidth() ~= 0 and not width:FitsOnLine() and lBreak.obj and currWS == "NOWRAP") then
            checkForBreak = true;
        elseif (next and current.obj:IsText() and next:IsText() and not next:IsBR() and (autoWrap or (next:Style():AutoWrap()))) then
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
                --trailingObjects.clear();
			end

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

--        if (not current.obj:IsFloatingOrPositioned()) then
--            last = current.obj;
--            if (last:IsReplaced() and autoWrap and (not last:IsImage() or allowImagesToBreak) && (!last->isListMarker() || toRenderListMarker(last)->isInside())) {
--                width.commit();
--                lBreak.moveToStartOf(next);
--            }
--        end

        -- Clear out our character space bool, since inline <pre>s don't collapse whitespace
        -- with adjacent inline normal/nowrap spans.
        if (not collapseWhiteSpace) then
            currentCharacterIsSpace = false;
		end

        current:MoveToStartOf(next);
        atStart = false;
	end

	if(not go_to_end) then
		if (width:FitsOnLine() or lastWS == "NOWRAP") then
			lBreak:Clear();
		end
	end

	if (lBreak:Equal(resolver:Position()) and (not lBreak.obj or not lBreak.obj:IsBR())) then
        -- we just add as much as possible
        if (self.block:Style():WhiteSpace() == "PRE") then
            -- FIXME: Don't really understand this case.
            if (current.pos) then
                -- FIXME: This should call moveTo which would clear m_nextBreakablePosition
                -- this code as-is is likely wrong.
                lBreak.obj = current.obj;
                lBreak.pos = current.pos - 1;
            else
                lBreak:MoveTo(last, if_else(last:IsText(), last:Length(), 0));
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
    --checkMidpoints(lineMidpointState, lBreak);

    --trailingObjects.updateMidpointsForTrailingBoxes(lineMidpointState, lBreak, TrailingObjects::CollapseFirstSpace);

    -- We might have made lBreak an iterator that points past the end
    -- of the object. Do this adjustment to make it point to the start
    -- of the next object instead to avoid confusing the rest of the
    -- code.
    if (lBreak.pos > 1) then
        lBreak.pos = lBreak.pos - 1;
        lBreak:Increment();
    end

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

--const Vector<RenderBox*>& positionedObjects() { return m_positionedObjects; }
--EClear clear() { return m_clear; }
function LineBreaker:SkipTrailingWhitespace(iterator, lineInfo)
	--TODO: fixed this function
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
        or (whitespacePosition == "TrailingWhitespace" and style:WhiteSpace() == "PRE_WRAP" and (not lineInfo:IsEmpty() or not lineInfo:PreviousLineBrokeCleanly()));
end

local noBreakSpace = UniString.SpecialCharacter.Nbsp;

-- @param it:InlineIterator
local function skipNonBreakingSpace(it, lineInfo)
	-- if (it.m_obj->style()->nbspMode() != SPACE || it.current() != noBreakSpace)
    if (it.obj:Style():NbspMode() ~= "SPACE" or string.byte(it:Current(),1) ~= noBreakSpace) then
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

local softHyphen = UniString.SpecialCharacter.SoftHyphen;

-- @param it:InlineIterator
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
	local current_str = tostring(current);
    return current_str ~= " " and current_str ~= "\t" and string.byte(current,1) ~= softHyphen and (current_str ~= "\n" or it.obj:PreservesNewline()) and not skipNonBreakingSpace(it, lineInfo);
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

function LineBreaker:SkipLeadingWhitespace(resolver, lineInfo, lastFloatFromPreviousLine, width)
	while (not resolver:Position():AtEnd() and not requiresLineBox(resolver:Position(), lineInfo, "LeadingWhitespace")) do
        local object = resolver:Position().obj;
        if (object:IsFloating()) then
            self.block:PositionNewFloatOnLine(self.block:InsertFloatingObject(object), lastFloatFromPreviousLine, lineInfo, width);
        elseif (object:IsPositioned()) then
            --setStaticPositions(m_block, toRenderBox(object));
		end
        resolver:Increment();
    end
end


function LineLayoutState:ctor()
	self.floats = commonlib.vector:new();
	self.lastFloat = nil;
	self.endLine = nil;
	self.lineInfo = LineInfo:new();
    self.floatIndex = 0;
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
	--self.overflow.clear();

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
			
			local o = walker:Current();
            if (not hasInlineChild and o:IsInline()) then
                hasInlineChild = true;
			end

            if (o:IsReplaced() or o:IsFloating() or o:IsPositioned()) then
				--RenderBox* box = toRenderBox(o);
				local box = o;

                if (relayoutChildren or Length.IsPercent(o:Style():Width()) or Length.IsPercent(o:Style():Height())) then
                    o:SetChildNeedsLayout(true, false);
				end

                -- If relayoutChildren is set and the child has percentage padding or an embedded content box, we also need to invalidate the childs pref widths.
                if (relayoutChildren and box:NeedsPreferredWidthsRecalculation()) then
                    o:SetPreferredLogicalWidthsDirty(true, false);
				end

                if (o:IsPositioned()) then
                    o:ContainingBlock():InsertPositionedObject(box);
                elseif (o:IsFloating()) then
                    --layoutState:Floats().append(FloatWithRect(box));
                elseif (layoutState:IsFullLayout() or o:NeedsLayout()) then
                    -- Replaced elements
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
	local curr = nil;
    local last = nil;

    -- FIXME: This entire float-checking block needs to be broken into a new function.
    local dirtiedByFloat = false;

	if (not layoutState:IsFullLayout()) then
--        -- Paginate all of the clean lines.
--        bool paginated = view()->layoutState() && view()->layoutState()->isPaginated();
--        int paginationDelta = 0;
--        size_t floatIndex = 0;
--        for (curr = firstRootBox(); curr && !curr->isDirty(); curr = curr->nextRootBox()) {
--            if (paginated) {
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
--            }
--
--            // If a new float has been inserted before this line or before its last known float, just do a full layout.
--            bool encounteredNewFloat = false;
--            checkFloatsInCleanLine(curr, layoutState.floats(), floatIndex, encounteredNewFloat, dirtiedByFloat);
--            if (encounteredNewFloat)
--                layoutState.markForFullLayout();
--
--            if (dirtiedByFloat || layoutState.isFullLayout())
--                break;
--        }
--        // Check if a new float has been inserted after the last known float.
--        if (!curr && floatIndex < layoutState.floats().size())
--            layoutState.markForFullLayout();
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

	local numCleanFloats = 0;
	if (not layoutState:Floats():empty()) then
--        int savedLogicalHeight = logicalHeight();
--        // Restore floats from clean lines.
--        RootInlineBox* line = firstRootBox();
--        while (line != curr) {
--            if (Vector<RenderBox*>* cleanLineFloats = line->floatsPtr()) {
--                Vector<RenderBox*>::iterator end = cleanLineFloats->end();
--                for (Vector<RenderBox*>::iterator f = cleanLineFloats->begin(); f != end; ++f) {
--                    FloatingObject* floatingObject = insertFloatingObject(*f);
--                    ASSERT(!floatingObject->m_originatingLine);
--                    floatingObject->m_originatingLine = line;
--                    setLogicalHeight(logicalTopForChild(*f) - marginBeforeForChild(*f));
--                    positionNewFloats();
--                    ASSERT(layoutState.floats()[numCleanFloats].object == *f);
--                    numCleanFloats++;
--                }
--            }
--            line = line->nextRootBox();
--        }
--        setLogicalHeight(savedLogicalHeight);
    end

	layoutState:SetFloatIndex(numCleanFloats);
    --layoutState:LineInfo():SetFirstLine(not last);
	layoutState:LineInfo():SetFirstLine(not if_else(last, true, false));
    layoutState:LineInfo():SetPreviousLineBrokeCleanly(not if_else(last, true, false) or last:EndsWithBreak());

	if (last) then
        self:SetLogicalHeight(last:LineBottomWithLeading());
        resolver:SetPosition(InlineIterator:new(self, last:LineBreakObj(), last:LineBreakPos()));
        resolver:SetStatus(last:LineBreakBidiStatus());
    else
        local direction = self:Style():Direction();
        if (self:Style():UnicodeBidi() == "Plaintext") then
            -- FIXME: Why does "unicode-bidi: plaintext" bidiFirstIncludingEmptyInlines when all other line layout code uses bidiFirstSkippingEmptyInlines?
            --determineParagraphDirection(direction, InlineIterator(this, bidiFirstIncludingEmptyInlines(this), 0));
        end
        resolver:SetStatus(BidiStatus:new():init(direction, self:Style():UnicodeBidi() == "Override"));
		resolver:SetPosition(InlineIterator:new():init(self, InlineWalker.BidiFirstSkippingEmptyInlines(self, resolver), 1));
    end
    return curr;
end

local function printLineBoxsInfo(box)
	while(box) do
		echo(box:BoxName());
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
			local font = box.renderer:Style():Font();
			echo(box.renderer:Characters():GetWidth(font, box.start, box.len));
			echo(font);
		else
			echo("not any box");
		end

		if(box:IsInlineFlowBox()) then
			box = box:NextLineBox();
		else
			box = box:Next();
		end
			
	end
end

function LayoutBlock:LayoutRunsAndFloats(layoutState, hasInlineChild)
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
--        RenderView* v = view();
--        if (v && !v->doingFullRepaint() && hasLayer()) {
--            // Because we waited until we were already inside layout to discover
--            // that the block really needed a full layout, we missed our chance to repaint the layer
--            // before layout started.  Luckily the layer has cached the repaint rect for its original
--            // position and size, and so we can use that to make a repaint happen now.
--            repaintUsingContainer(containerForRepaint(), layer()->repaintRect());
--        }
    end

--    if (self.floatingObjects and !m_floatingObjects->set().isEmpty())
--        layoutState.setLastFloat(m_floatingObjects->set().last());

--	-- We also find the first clean line and extract these lines.  We will add them back
--    -- if we determine that we're able to synchronize after handling all our dirty lines.
--    InlineIterator cleanLineStart;
--    BidiStatus cleanLineBidiStatus;
--    if (!layoutState.isFullLayout() && startLine)
--        determineEndPosition(layoutState, startLine, cleanLineStart, cleanLineBidiStatus);

--    if (startline) {
--        if (!layoutstate.usesrepaintbounds())
--            layoutstate.setrepaintrange(logicalheight());
--        deletelinerange(layoutstate, renderarena(), startline);
--    }

--    if (!layoutState.isFullLayout() && lastRootBox() && lastRootBox()->endsWithBreak()) {
--        // If the last line before the start line ends with a line break that clear floats,
--        // adjust the height accordingly.
--        // A line break can be either the first or the last object on a line, depending on its direction.
--        if (InlineBox* lastLeafChild = lastRootBox()->lastLeafChild()) {
--            RenderObject* lastObject = lastLeafChild->renderer();
--            if (!lastObject->isBR())
--                lastObject = lastRootBox()->firstLeafChild()->renderer();
--            if (lastObject->isBR()) {
--                EClear clear = lastObject->style()->clear();
--                if (clear != CNONE)
--                    newLine(clear);
--            }
--        }
--    }

	self:LayoutRunsAndFloatsInRange(layoutState, resolver, cleanLineStart, cleanLineBidiStatus, consecutiveHyphenatedLines);

	local firstLineBox = self:FirstLineBox();
	local lastLineBox = self:LastLineBox();


	if(firstLineBox) then
		--printLineBoxsInfo(firstLineBox);
	end
--    linkToEndLineIfNeeded(layoutState);
--    repaintDirtyFloats(layoutState.floats());
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
    if (not endsWithSoftBreak and alignment == "JUSTIFY") then
        alignment = "TAAUTO";
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
    run.box:SetLogicalWidth(renderer:Width(run.start, run.stop - run.start + 1, xPos, lineInfo:IsFirstLine(), fallbackFonts, glyphOverflow) + hyphenWidth);

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

--void RenderBlock::updateLogicalWidthForAlignment(const ETextAlign& textAlign, BidiRun* trailingSpaceRun, float& logicalLeft, float& totalLogicalWidth, float& availableLogicalWidth, int expansionOpportunityCount)
function LayoutBlock:UpdateLogicalWidthForAlignment(textAlign, trailingSpaceRun, logicalLeft, totalLogicalWidth, availableLogicalWidth, expansionOpportunityCount)
	-- TODO: add function later;
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
				if (textAlign == "JUSTIFY" and r ~= trailingSpaceRun) then
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

	self:UpdateLogicalWidthForAlignment(textAlign, trailingSpaceRun, logicalLeft, totalLogicalWidth, availableLogicalWidth, expansionOpportunityCount);

    computeExpansionForJustifiedText(firstRun, trailingSpaceRun, expansionOpportunities, expansionOpportunityCount, totalLogicalWidth, availableLogicalWidth);

    -- The widths of all runs are now known.  We can now place every inline box (and
    -- compute accurate widths for the inline flow boxes).
    needsWordSpacing = false;
    lineBox:PlaceBoxesInInlineDirection(logicalLeft, needsWordSpacing, textBoxDataMap);
end

--void RenderBlock::computeBlockDirectionPositionsForLine(RootInlineBox* lineBox, BidiRun* firstRun, GlyphOverflowAndFallbackFontsMap& textBoxDataMap,
--                                                        VerticalPositionCache& verticalPositionCache)
function LayoutBlock:ComputeBlockDirectionPositionsForLine(lineBox, firstRun, textBoxDataMap, verticalPositionCache)
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
    --local hasDefaultLineBoxContain = style()->lineBoxContain() == RenderStyle::initialLineBoxContain();
	local hasDefaultLineBoxContain = true;

	while(true) do
		--ASSERT(obj->isRenderInline() || obj == this);

        local inlineFlow = if_else(obj ~= self, obj, nil);

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
        local allowedToConstructNewBox = not hasDefaultLineBoxContain or not inlineFlow or inlineFlow:AlwaysCreateLineBoxes();
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
--            if (not hasDefaultLineBoxContain) then
--                parentBox->clearDescendantsHaveSameLineHeightAndBaseline();
--			end
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

			local visuallyOrdered = r.object:Style():RtlOrdering() == "VisualOrder";
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
	local textBoxDataMap = nil;
    
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

function LayoutBlock:LayoutRunsAndFloatsInRange(layoutState, resolver, cleanLineStart, cleanLineBidiStatus, consecutiveHyphenatedLines)
	--bool paginated = view()->layoutState() && view()->layoutState()->isPaginated();
	local paginated = false;
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
--            layoutState:SetEndLineMatched(matchedEndLine(layoutState, resolver, cleanLineStart, cleanLineBidiStatus));
--            if (layoutState.endLineMatched()) then
--                break;
--			end
        end

        lineMidpointState:Reset();

        layoutState:LineInfo():SetEmpty(true);

        local oldEnd = _end:Clone();
        local isNewUBAParagraph = layoutState:LineInfo():PreviousLineBrokeCleanly();
        --FloatingObject* lastFloatFromPreviousLine = (m_floatingObjects && !m_floatingObjects->set().isEmpty()) ? m_floatingObjects->set().last() : 0;
		local lastFloatFromPreviousLine = nil;
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
            local override = if_else(self:Style():RtlOrdering() == "VisualOrder", if_else(self:Style():Direction() == "LTR", "VisualLeftToRightOverride", "VisualRightToLeftOverride"), "NoVisualOverride");
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

--			for i = 0, lineBreaker:PositionedObjects():Size() do
--				--setStaticPositions(this, lineBreaker.positionedObjects()[i]);
--			end

--            for (size_t i = 0; i < lineBreaker.positionedObjects().size(); ++i)
--                setStaticPositions(this, lineBreaker.positionedObjects()[i]);

            layoutState:LineInfo():SetFirstLine(false);
            self:NewLine(lineBreaker:Clear());
        end

--        if (m_floatingObjects && lastRootBox()) {
--            const FloatingObjectSet& floatingObjectSet = m_floatingObjects->set();
--            FloatingObjectSetIterator it = floatingObjectSet.begin();
--            FloatingObjectSetIterator end = floatingObjectSet.end();
--            if (layoutState.lastFloat()) {
--                FloatingObjectSetIterator lastFloatIterator = floatingObjectSet.find(layoutState.lastFloat());
--                ASSERT(lastFloatIterator != end);
--                ++lastFloatIterator;
--                it = lastFloatIterator;
--            }
--            for (; it != end; ++it) {
--                FloatingObject* f = *it;
--                appendFloatingObjectToLastLine(f);
--                ASSERT(f->m_renderer == layoutState.floats()[layoutState.floatIndex()].object);
--                // If a float's geometry has changed, give up on syncing with clean lines.
--                if (layoutState.floats()[layoutState.floatIndex()].rect != f->frameRect())
--                    checkForEndLineMatch = false;
--                layoutState.setFloatIndex(layoutState.floatIndex() + 1);
--            }
--            layoutState.setLastFloat(!floatingObjectSet.isEmpty() ? floatingObjectSet.last() : 0);
--        }

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
--        if (!floats[i].everHadLayout) {
--            RenderBox* f = floats[i].object;
--            if (!f->x() && !f->y() && f->checkForRepaintDuringLayout())
--                f->repaint();
--        }
    end
end

function LayoutBlock:LinkToEndLineIfNeeded(layoutState)
	-- TODO: fixed latter;
end


local function createRun(_start, _end, obj, resolver)
    return BidiRun:new():init(_start, _end, obj, resolver:Context(), resolver:Dir());
end

function LayoutBlock.AppendRunsForObject(runs, _start, _end, obj, resolver)

	if (_start > _end or obj:IsFloating() or
        (obj:IsPositioned() and not obj:Style():IsOriginalDisplayInlineType() and not obj:Container():IsRenderInline())) then
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
            if (nextMidpoint.pos ~= 0xffffffff) then -- UINT_MAX means stop at the object and don't include any of it.
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
    if (not self:PositionNewFloats()) then
        return false;
	end

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
