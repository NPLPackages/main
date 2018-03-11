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
--NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBox.lua");
--NPL.load("(gl)script/ide/System/Windows/mcml/geometry/Length.lua");
--local Length = commonlib.gettable("System.Windows.mcml.geometry.Length");
--local LayoutModel = commonlib.gettable("System.Windows.mcml.layout.LayoutModel");
--local LayoutBlock = commonlib.gettable("System.Windows.mcml.layout.LayoutBlock");

--NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlock.lua");
local LayoutBlock = commonlib.gettable("System.Windows.mcml.layout.LayoutBlock");

function LayoutBlock:LayoutInlineChildren(relayoutChildren, repaintLogicalTop, repaintLogicalBottom)
	--TODO: fixed this function
	--self.overflow.clear();

    self:SetLogicalHeight(self:BorderBefore() + self:PaddingBefore());

--	bool isFullLayout = !firstLineBox() || selfNeedsLayout() || relayoutChildren;
--    LineLayoutState layoutState(isFullLayout, repaintLogicalTop, repaintLogicalBottom);
--
--    if (isFullLayout)
--        lineBoxes()->deleteLineBoxes(renderArena());
--	end

--	-- Text truncation only kicks in if your overflow isn't visible and your text-overflow-mode isn't
--    -- clip.
--    -- FIXME: CSS3 says that descendants that are clipped must also know how to truncate.  This is insanely
--    -- difficult to figure out (especially in the middle of doing layout), and is really an esoteric pile of nonsense
--    -- anyway, so we won't worry about following the draft here.
	   local hasTextOverflow = self:Style():TextOverflow() and self:HasOverflowClip();
--
--    -- Walk all the lines and delete our ellipsis line boxes if they exist.
--    if (hasTextOverflow) then
--         self:DeleteEllipsisLineBoxes();
--	end

--	if (firstChild()) {
--        // layout replaced elements
--        bool hasInlineChild = false;
--        for (InlineWalker walker(this); !walker.atEnd(); walker.advance()) {
--            RenderObject* o = walker.current();
--            if (!hasInlineChild && o->isInline())
--                hasInlineChild = true;
--
--            if (o->isReplaced() || o->isFloating() || o->isPositioned()) {
--                RenderBox* box = toRenderBox(o);
--
--                if (relayoutChildren || o->style()->width().isPercent() || o->style()->height().isPercent())
--                    o->setChildNeedsLayout(true, false);
--
--                // If relayoutChildren is set and the child has percentage padding or an embedded content box, we also need to invalidate the childs pref widths.
--                if (relayoutChildren && box->needsPreferredWidthsRecalculation())
--                    o->setPreferredLogicalWidthsDirty(true, false);
--
--                if (o->isPositioned())
--                    o->containingBlock()->insertPositionedObject(box);
--                else if (o->isFloating())
--                    layoutState.floats().append(FloatWithRect(box));
--                else if (layoutState.isFullLayout() || o->needsLayout()) {
--                    // Replaced elements
--                    toRenderBox(o)->dirtyLineBoxes(layoutState.isFullLayout());
--                    o->layoutIfNeeded();
--                }
--            } else if (o->isText() || (o->isRenderInline() && !walker.atEndOfInline())) {
--                if (!o->isText())
--                    toRenderInline(o)->updateAlwaysCreateLineBoxes(layoutState.isFullLayout());
--                if (layoutState.isFullLayout() || o->selfNeedsLayout())
--                    dirtyLineBoxesForRenderer(o, layoutState.isFullLayout());
--                o->setNeedsLayout(false);
--            }
--        }
--
--        layoutRunsAndFloats(layoutState, hasInlineChild);
--    }

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
end
