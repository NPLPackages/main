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

	local view = renderer:View();
    --bool usePrintRect = !v->printRect().isEmpty();
	local usePrintRect = false;
    local outlineSize = renderer:MaximalOutlineSize();
    if (not self:AnyLineIntersectsRect(renderer, paintInfo:Rect(), paintOffset, usePrintRect, outlineSize)) then
        return;
	end

--	if (!anyLineIntersectsRect(renderer, paintInfo.rect, paintOffset, usePrintRect, outlineSize))
--        return;

	local info = paintInfo;

	local curr = self:FirstLineBox();
	while(curr) do
--		if (lineIntersectsDirtyRect(renderer, curr, info, paintOffset)) {
--            RootInlineBox* root = curr->root();
--            curr->paint(info, paintOffset, root->lineTop(), root->lineBottom());
--        end
		local root = curr:Root();
        curr:Paint(info, paintOffset, root:LineTop(), root:LineBottom());

		curr = curr:NextLineBox();
	end
end

--bool RenderLineBoxList::anyLineIntersectsRect(RenderBoxModelObject* renderer, const LayoutRect& rect, const LayoutPoint& offset, bool usePrintRect, LayoutUnit outlineSize) const
function LayoutLineBoxList:AnyLineIntersectsRect(renderer, rect, offset, usePrintRect, outlineSize)
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
    local logicalTop = firstLineTop - outlineSize;
    local logicalBottom = outlineSize + lastLineBottom;
    
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

	-- TODO: fixed latter;
end