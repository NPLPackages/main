--[[
Title: 
Author(s): LiPeng
Date: 2018/3/12
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutLineBoxList.lua");
local LayoutLineBoxList = commonlib.gettable("System.Windows.mcml.layout.LayoutLineBoxList");
------------------------------------------------------------
]]
local LayoutLineBoxList = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.LayoutLineBoxList"));

function LayoutLineBoxList:ctor()
	self.firstLineBox = nil;
    self.lastLineBox = nil;
--	InlineFlowBox* m_firstLineBox;
--  InlineFlowBox* m_lastLineBox;
end

function LayoutLineBoxList:AppendLineBox(box)
    self:CheckConsistency();
    
    if (not self.firstLineBox) then
        self.firstLineBox = box;
		self.lastLineBox = box;
    else
        self.lastLineBox:SetNextLineBox(box);
        box:SetPreviousLineBox(self.lastLineBox);
        self.lastLineBox = box;
    end

    self:CheckConsistency();
end

function LayoutLineBoxList:DeleteLineBoxes(arena)
	if(self.firstLineBox) then
		local curr = self.firstLineBox;
		local next;
		while(curr) do
			next = curr:NextLineBox();
			curr:Destroy(arena);
			curr = next;
		end

		self.firstLineBox = nil;
		self.lastLineBox = nil;
	end
end

function LayoutLineBoxList:DirtyLineBoxes()
	local curr = self:FirstLineBox();
	while(curr) do
		curr:DirtyLineBoxes();
		curr = curr:NextLineBox();
	end
end

function LayoutLineBoxList:FirstLineBox()
	return self.firstLineBox;
end

function LayoutLineBoxList:LastLineBox()
	return self.lastLineBox;
end

function LayoutLineBoxList:CheckConsistency()

end

function LayoutLineBoxList:RemoveLineBox(box)
    self:CheckConsistency();

    if (box == self.firstLineBox) then
        self.firstLineBox = box:NextLineBox();
	end
    if (box == self.lastLineBox) then
        self.lastLineBox = box:PrevLineBox();
	end
    if (box:NextLineBox()) then
        box:NextLineBox():SetPreviousLineBox(box:PrevLineBox());
	end
    if (box:PrevLineBox()) then
        box:PrevLineBox():SetNextLineBox(box:NextLineBox());
	end

    self:CheckConsistency();
end

--void RenderLineBoxList::paint(RenderBoxModelObject* renderer, PaintInfo& paintInfo, const LayoutPoint& paintOffset) const
function LayoutLineBoxList:Paint(renderer, paintInfo, paintOffset)
	if (self:FirstLineBox() == nil) then
		return;
	end
	echo("LayoutLineBoxList:Paint")
	renderer:PrintNodeInfo()
	echo("22222222")
	echo(paintOffset)
	echo(paintInfo:Rect())
	local view = renderer:View();
    --bool usePrintRect = !v->printRect().isEmpty();
	local usePrintRect = false;
    local outlineSize = renderer:MaximalOutlineSize();
	echo(outlineSize)
    if (not self:AnyLineIntersectsRect(renderer, paintInfo:Rect(), paintOffset, usePrintRect, outlineSize)) then
        return;
	end

--	if (!anyLineIntersectsRect(renderer, paintInfo.rect, paintOffset, usePrintRect, outlineSize))
--        return;

	

	local curr = self:FirstLineBox();
	while(curr) do
		echo("LayoutLineBoxList:Paint while");
		--if (self:LineIntersectsDirtyRect(renderer, curr, info, paintOffset)) then
		if(true) then
			echo("1111111111");
			echo(curr:BoxName());
            local root = curr:Root();
			local info = paintInfo:clone();
			info:Rect():SetX(info:Rect():X() - curr:X())
			info:Rect():SetY(info:Rect():Y() - curr:Y())
			curr:Paint(info, paintOffset, root:LineTop(), root:LineBottom());
        end
		
		curr = curr:NextLineBox();
	end
end

--bool RenderLineBoxList::anyLineIntersectsRect(RenderBoxModelObject* renderer, const LayoutRect& rect, const LayoutPoint& offset, bool usePrintRect, LayoutUnit outlineSize) const
function LayoutLineBoxList:AnyLineIntersectsRect(renderer, rect, offset, usePrintRect, outlineSize)
	echo("LayoutLineBoxList:AnyLineIntersectsRect")
	usePrintRect = if_else(usePrintRect == nil, false, usePrintRect);
	outlineSize = outlineSize or 0;
    -- We can check the first box and last box and avoid painting/hit testing if we don't
    -- intersect.  This is a quick short-circuit that we can take to avoid walking any lines.
    -- FIXME: This check is flawed in the following extremely obscure way:
    -- if some line in the middle has a huge overflow, it might actually extend below the last line.
    local firstRootBox = self:FirstLineBox():Root();
    local lastRootBox = self:LastLineBox():Root();
    local firstLineTop = self:FirstLineBox():LogicalTopVisualOverflow(firstRootBox:LineTop());
--    if (usePrintRect && !firstLineBox()->parent())
--        firstLineTop = min(firstLineTop, firstLineBox()->root()->lineTop());
    local lastLineBottom = self:LastLineBox():LogicalBottomVisualOverflow(lastRootBox:LineBottom());
--    if (usePrintRect && !lastLineBox()->parent())
--        lastLineBottom = max(lastLineBottom, lastLineBox()->root()->lineBottom());
	echo({firstLineTop, lastLineBottom})
    local logicalTop = firstLineTop - outlineSize;
    local logicalBottom = outlineSize + lastLineBottom;
	echo("LayoutLineBoxList:AnyLineIntersectsRect")
	echo(renderer.frame_rect)
    echo({logicalTop, logicalBottom, rect, offset})
    return self:RangeIntersectsRect(renderer, logicalTop, logicalBottom, rect, offset);
end

--bool RenderLineBoxList::lineIntersectsDirtyRect(RenderBoxModelObject* renderer, InlineFlowBox* box, const PaintInfo& paintInfo, const IntPoint& offset) const
function LayoutLineBoxList:LineIntersectsDirtyRect(renderer, box, paintInfo, offset)
    local root = box:Root();
    local logicalTop = math.min(box:LogicalTopVisualOverflow(root:LineTop()), root:SelectionTop()) - renderer:MaximalOutlineSize(paintInfo.phase);
    local logicalBottom = box:LogicalBottomVisualOverflow(root:LineBottom()) + renderer:MaximalOutlineSize(paintInfo.phase);
    
    return self:RangeIntersectsRect(renderer, logicalTop, logicalBottom, paintInfo:Rect(), offset);
end

--bool RenderLineBoxList::rangeIntersectsRect(RenderBoxModelObject* renderer, int logicalTop, int logicalBottom, const IntRect& rect, const IntPoint& offset) const
function LayoutLineBoxList:RangeIntersectsRect(renderer, logicalTop, logicalBottom, rect, offset)
	echo("LayoutLineBoxList:RangeIntersectsRect")
    local block;
    if (renderer:IsBox()) then
        block = renderer;
    else
        block = renderer:ContainingBlock();
	end
    local physicalStart = block:FlipForWritingMode(logicalTop);
    local physicalEnd = block:FlipForWritingMode(logicalBottom);
    local physicalExtent = math.abs(physicalEnd - physicalStart);
    physicalStart = math.min(physicalStart, physicalEnd);
    echo({physicalStart, physicalExtent, offset})
    if (renderer:Style():IsHorizontalWritingMode()) then
        physicalStart = physicalStart + offset:Y();
        if (physicalStart >= rect:MaxY() or physicalStart + physicalExtent <= rect:Y()) then
            return false;
		end
    else
        physicalStart = physicalStart + offset:X();
        if (physicalStart >= rect:MaxX() or physicalStart + physicalExtent <= rect:X()) then
            return false;
		end
    end
    
    return true;
end

--void RenderLineBoxList::dirtyLinesFromChangedChild(RenderObject* container, RenderObject* child)
function LayoutLineBoxList:DirtyLinesFromChangedChild(container, child)
    if (not container:Parent() or (container:IsLayoutBlock() and (container:SelfNeedsLayout() or not container:IsBlockFlow()))) then
        return;
	end

	local inlineContainer;
	if(container:IsLayoutInline()) then
		inlineContainer = container:ToRenderInline();
	end
	local firstBox;
	if(inlineContainer) then
		firstBox = inlineContainer:FirstLineBoxIncludingCulling();
	else
		firstBox = self:FirstLineBox();
	end

    -- If we have no first line box, then just bail early.
    if (not firstBox) then
        -- For an empty inline, go ahead and propagate the check up to our parent, unless the parent
        -- is already dirty.
        if (container:IsInline() and not container:Parent():SelfNeedsLayout()) then
            container:Parent():DirtyLinesFromChangedChild(container);
            container:SetNeedsLayout(true); -- Mark the container as needing layout to avoid dirtying the same lines again across multiple destroy() calls of the same subtree.
        end
        return;
    end

    -- Try to figure out which line box we belong in.  First try to find a previous
    -- line box by examining our siblings.  If we didn't find a line box, then use our 
    -- parent's first line box.
    --RootInlineBox* box = 0;
    --RenderObject* curr = 0;
	local box, curr;
	local curr = child:PreviousSibling();
	while(curr) do
		if (curr:IsFloatingOrPositioned()) then
            --continue;
		else
			if (curr:IsReplaced()) then
				local wrapper = curr:ToRenderBox():InlineBoxWrapper();
				if (wrapper) then
					box = wrapper:Root();
				end
			elseif (curr:IsText()) then
				local textBox = curr:ToRenderText():LastTextBox();
				if (textBox) then
					box = textBox:Root();
				end
			elseif (curr:IsLayoutInline()) then
				local lastSiblingBox = curr:ToRenderInline():LastLineBoxIncludingCulling();
				if (lastSiblingBox) then
					box = lastSiblingBox:Root();
				end
			end

			if (box) then
				break;
			end
		end
	
		curr = curr:PreviousSibling();
	end
	
    if (not box) then
        if (inlineContainer and not inlineContainer:AlwaysCreateLineBoxes()) then
            -- https:--bugs.webkit.org/show_bug.cgi?id=60778
            -- We may have just removed a <br> with no line box that was our first child. In this case
            -- we won't find a previous sibling, but firstBox can be pointing to a following sibling.
            -- This isn't good enough, since we won't locate the root line box that encloses the removed
            -- <br>. We have to just over-invalidate a bit and go up to our parent.
            if (not inlineContainer:Parent():SelfNeedsLayout()) then
                inlineContainer:Parent():DirtyLinesFromChangedChild(inlineContainer);
                inlineContainer:SetNeedsLayout(true); -- Mark the container as needing layout to avoid dirtying the same lines again across multiple destroy() calls of the same subtree.
            end
            return;
        end
        box = firstBox:Root();
    end

    -- If we found a line box, then dirty it.
    if (box) then
        local adjacentBox;
        box:MarkDirty();

        -- dirty the adjacent lines that might be affected
        -- NOTE: we dirty the previous line because RootInlineBox objects cache
        -- the address of the first object on the next line after a BR, which we may be
        -- invalidating here.  For more info, see how RenderBlock::layoutInlineChildren
        -- calls setLineBreakInfo with the result of findNextLineBreak.  findNextLineBreak,
        -- despite the name, actually returns the first RenderObject after the BR.
        -- <rdar:--problem/3849947> "Typing after pasting line does not appear until after window resize."
        adjacentBox = box:PrevRootBox();
        if (adjacentBox) then
            adjacentBox:MarkDirty();
		end
        adjacentBox = box:NextRootBox();
        if (adjacentBox and (adjacentBox:LineBreakObj() == child or child:IsBR() or (curr and curr:IsBR()))) then
            adjacentBox:MarkDirty();
		end
    end
end


--void RenderLineBoxList::deleteLineBoxTree(RenderArena* arena)
function LayoutLineBoxList:DeleteLineBoxTree(arena)
    local line = self.firstLineBox;
    local nextLine;
    while (line) do
        nextLine = line:NextLineBox();
        line:DeleteLine(arena);
        line = nextLine;
    end
    self.firstLineBox = nil;
	self.lastLineBox = nil;
end

--void RenderLineBoxList::extractLineBox(InlineFlowBox* box)
function LayoutLineBoxList:ExtractLineBox(box)
    self:CheckConsistency();
    
    self.lastLineBox = box:PrevLineBox();
    if (box == self.firstLineBox) then
        self.firstLineBox = nil;
	end
    if (box:PrevLineBox()) then
        box:PrevLineBox():SetNextLineBox(nil);
	end
    box:SetPreviousLineBox(nil);
	local curr = box;
	while(curr) do
		curr:SetExtracted();

		curr = curr:NextLineBox();
	end
    self:CheckConsistency();
end

--void RenderLineBoxList::attachLineBox(InlineFlowBox* box)
function LayoutLineBoxList:AttachLineBox(box)
    self:CheckConsistency();

    if (self.lastLineBox) then
        self.lastLineBox:SetNextLineBox(box);
        box:SetPreviousLineBox(self.lastLineBox);
    else
        self.firstLineBox = box;
	end
    local last = box;
	local curr = box;
	while(curr) do
		curr:SetExtracted(false);
        last = curr;

		curr = curr:NextLineBox();
	end

    self.lastLineBox = last;

    self:CheckConsistency();
end
