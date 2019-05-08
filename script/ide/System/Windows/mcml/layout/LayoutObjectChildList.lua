--[[
Title: 
Author(s): LiPeng
Date: 2018/3/2
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObjectChildList.lua");
local LayoutObjectChildList = commonlib.gettable("System.Windows.mcml.layout.LayoutObjectChildList");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");

local LayoutObjectChildList = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.LayoutObjectChildList"));

local VisibilityEnum = ComputedStyleConstants.VisibilityEnum;
local PseudoIdEnum = ComputedStyleConstants.PseudoIdEnum;

function LayoutObjectChildList:ctor()
	self.firstChild = nil;
	self.lastChild = nil;
end

function LayoutObjectChildList:FirstChild()
	return self.firstChild;
end

function LayoutObjectChildList:LastChild()
	return self.lastChild;
end

function LayoutObjectChildList:SetFirstChild(child)
	self.firstChild = child;
end

function LayoutObjectChildList:SetLastChild(child)
	self.lastChild = child;
end

function LayoutObjectChildList:DestroyLeftoverChildren()
	while (self:FirstChild()) do
        if (self:FirstChild():IsListMarker() or (self:FirstChild():Style():StyleType() == PseudoIdEnum.FIRST_LETTER and not self:FirstChild():IsText())) then
            --firstChild()->remove();  // List markers are owned by their enclosing list and so don't get destroyed by this container. Similarly, first letters are destroyed by their remaining text fragment.
        elseif (self:FirstChild():IsRunIn() and self:FirstChild():Node()) then
            --firstChild()->node()->setRenderer(0);
            --firstChild()->node()->setNeedsStyleRecalc();
            --firstChild()->destroy();
        else
            -- Destroy any anonymous children remaining in the render tree, as well as implicit (shadow) DOM elements like those used in the engine-based text fields.
            if (self:FirstChild():Node()) then
                self:FirstChild():Node():SetRenderer(nil);
			end
            self:FirstChild():Destroy();
        end
    end
end

function LayoutObjectChildList:RemoveChildNode(owner, oldChild, fullRemove)
	fullRemove = if_else(fullRemove == nil, true, fullRemove);
	--ASSERT(oldChild->parent() == owner);

    -- So that we'll get the appropriate dirty bit set (either that a normal flow child got yanked or
    -- that a positioned child got yanked).  We also repaint, so that the area exposed when the child
    -- disappears gets repainted properly.
    if (not owner:DocumentBeingDestroyed() and fullRemove and oldChild.everHadLayout) then
        oldChild:SetNeedsLayoutAndPrefWidthsRecalc();
--        if (oldChild:IsBody()) then
--            owner:View():Repaint();
--        else
--            oldChild:Repaint();
--		end
    end

    -- If we have a line box wrapper, delete it.
    if (oldChild:IsBox()) then
        oldChild:DeleteLineBoxWrapper();
	end

    if (not owner:DocumentBeingDestroyed() and fullRemove) then
        -- if we remove visible child from an invisible parent, we don't know the layer visibility any more
        local layer = nil;
        if (owner:Style():Visibility() ~= VisibilityEnum.VISIBLE and oldChild:Style():Visibility() == VisibilityEnum.VISIBLE and not oldChild:HasLayer()) then
			layer = owner:EnclosingLayer();
            if (layer) then
                layer:DirtyVisibleContentStatus();
			end
        end

         -- Keep our layer hierarchy updated.
        if (oldChild:FirstChild() or oldChild:HasLayer()) then
            if (not layer) then
                layer = owner:EnclosingLayer();
			end
            oldChild:RemoveLayers(layer);
        end

        if (oldChild:IsListItem()) then
            --toRenderListItem(oldChild)->updateListMarkerNumbers();
		end

        if (oldChild:IsPositioned() and owner:ChildrenInline()) then
            owner:DirtyLinesFromChangedChild(oldChild);
		end
        if (oldChild:IsRenderRegion()) then
            --toRenderRegion(oldChild)->detachRegion();
		end

        if (oldChild:InRenderFlowThread() and oldChild:IsBox()) then
            --oldChild->enclosingRenderFlowThread()->removeRenderBoxRegionInfo(toRenderBox(oldChild));
		end

--        if (RenderFlowThread* containerFlowThread = renderFlowThreadContainer(owner))
--            containerFlowThread->removeFlowChild(oldChild);

--#if ENABLE(SVG)
--        -- Update cached boundaries in SVG renderers, if a child is removed.
--        owner->setNeedsBoundariesUpdate();
--#endif
    end
    
    -- If oldChild is the start or end of the selection, then clear the selection to
    -- avoid problems of invalid pointers.
    -- FIXME: The FrameSelection should be responsible for this when it
    -- is notified of DOM mutations.
--    if (not owner:DocumentBeingDestroyed() and oldChild:IsSelectionBorder()) then
--        owner:View():ClearSelection();
--	end

    -- remove the child
    if (oldChild:PreviousSibling()) then
        oldChild:PreviousSibling():SetNextSibling(oldChild:NextSibling());
	end
    if (oldChild:NextSibling()) then
        oldChild:NextSibling():SetPreviousSibling(oldChild:PreviousSibling());
	end

    if (self:FirstChild() == oldChild) then
        self:SetFirstChild(oldChild:NextSibling());
	end
    if (self:LastChild() == oldChild) then
        self:SetLastChild(oldChild:PreviousSibling());
	end

    oldChild:SetPreviousSibling();
    oldChild:SetNextSibling();
    oldChild:SetParent();

--    RenderCounter::rendererRemovedFromTree(oldChild);
--    RenderQuote::rendererRemovedFromTree(oldChild);

--    if (AXObjectCache::accessibilityEnabled())
--        owner->document()->axObjectCache()->childrenChanged(owner);

    return oldChild;
end

function RenderFlowThreadContainer(object)
	while (object and object:IsAnonymousBlock() and not object:IsRenderFlowThread()) do
        object = object:Parent();
	end
	if(object and object:IsRenderFlowThread()) then
		return object;
	end
    return nil;
end

function LayoutObjectChildList:AppendChildNode(owner, newChild, fullAppend)
	fullAppend = if_else(fullAppend == nil, true, fullAppend);
--	if(newChild:Parent()) then
--		return;
--	end
--	if(not owner:IsBlockFlow() or (not newChild:IsTableSection() and not newChild:IsTableRow() and not newChild:IsTableCell())) then
--		return;
--	end

    newChild:SetParent(owner);
    local lChild = self:LastChild();

	if (lChild) then
        newChild:SetPreviousSibling(lChild);
        lChild:SetNextSibling(newChild);
    else
        self:SetFirstChild(newChild);
	end

	self:SetLastChild(newChild);

	if (fullAppend) then
        -- Keep our layer hierarchy updated.  Optimize for the common case where we don't have any children
        -- and don't have a layer attached to ourselves.
        local layer = nil;
        if (newChild:FirstChild() or newChild:HasLayer()) then
            layer = owner:EnclosingLayer();
            newChild:AddLayers(layer);
        end

        -- if the new child is visible but this object was not, tell the layer it has some visible content
        -- that needs to be drawn and layer visibility optimization can't be used
        if (owner:Style():Visibility() ~= VisibilityEnum.VISIBLE and newChild:Style():Visibility() == VisibilityEnum.VISIBLE and not newChild:HasLayer()) then
            if (not layer) then
                layer = owner:EnclosingLayer();
			end
            if (layer) then
                layer:SetHasVisibleContent(true);
			end
        end

        if (newChild:IsListItem()) then
            --toRenderListItem(newChild)->updateListMarkerNumbers();
		end

        if (not newChild:IsFloating() and owner:ChildrenInline()) then
			owner:DirtyLinesFromChangedChild(newChild);
		end

--        if (newChild->isRenderRegion()) then
--            toRenderRegion(newChild)->attachRegion();
--		end

		local containerFlowThread = RenderFlowThreadContainer(owner);
        if (containerFlowThread) then
            --containerFlowThread:AddFlowChild(newChild);
		end
    end

--	RenderCounter::rendererSubtreeAttached(newChild);
--    RenderQuote::rendererSubtreeAttached(newChild);
    newChild:SetNeedsLayoutAndPrefWidthsRecalc(); -- Goes up the containing block hierarchy.

	if (not owner:NormalChildNeedsLayout()) then
        owner:SetChildNeedsLayout(true); -- We may supply the static position for an absolute positioned child.
	end
    
--    if (AXObjectCache::accessibilityEnabled())
--        owner->document()->axObjectCache()->childrenChanged(owner);
end

function LayoutObjectChildList:InsertChildNode(owner, child, beforeChild, fullInsert)
	fullInsert = if_else(fullInsert == nil, true, fullInsert);
	if (not beforeChild) then
        self:AppendChildNode(owner, child, fullInsert);
        return;
    end

	--ASSERT(!child->parent());
    while (beforeChild:Parent() ~= owner and beforeChild:Parent():IsAnonymousBlock()) do
        beforeChild = beforeChild:Parent();
	end
    --ASSERT(beforeChild->parent() == owner);

    --ASSERT(!owner->isBlockFlow() || (!child->isTableSection() && !child->isTableRow() && !child->isTableCell()));

    if (beforeChild == self:FirstChild()) then
        self:SetFirstChild(child);
	end

    local prev = beforeChild:PreviousSibling();
    child:SetNextSibling(beforeChild);
    beforeChild:SetPreviousSibling(child);
    if (prev) then
        prev:SetNextSibling(child);
	end
    child:SetPreviousSibling(prev);

    child:SetParent(owner);
    
    if (fullInsert) then
        -- Keep our layer hierarchy updated.  Optimize for the common case where we don't have any children
        -- and don't have a layer attached to ourselves.
        local layer = nil;
        if (child:FirstChild() or child:HasLayer()) then
            layer = owner:EnclosingLayer();
            child:AddLayers(layer);
        end

        -- if the new child is visible but this object was not, tell the layer it has some visible content
        -- that needs to be drawn and layer visibility optimization can't be used
        if (owner:Style():Visibility() ~= VisibilityEnum.VISIBLE and child:Style():Visibility() == VisibilityEnum.VISIBLE and not child:HasLayer()) then
            if (not layer) then
                layer = owner:EnclosingLayer();
			end
            if (layer) then
                layer:SetHasVisibleContent(true);
			end
        end

        if (child:IsListItem()) then
            --toRenderListItem(child)->updateListMarkerNumbers();
		end

        if (not child:IsFloating() and owner:ChildrenInline()) then
            owner:DirtyLinesFromChangedChild(child);
		end

        if (child:IsRenderRegion()) then
            --toRenderRegion(child)->attachRegion();
		end

--        if (RenderFlowThread* containerFlowThread = renderFlowThreadContainer(owner))
--            containerFlowThread->addFlowChild(child, beforeChild);
    end

--    RenderCounter::rendererSubtreeAttached(child);
--    RenderQuote::rendererSubtreeAttached(child);
    child:SetNeedsLayoutAndPrefWidthsRecalc();
    if (not owner:NormalChildNeedsLayout()) then
        owner:SetChildNeedsLayout(true); -- We may supply the static position for an absolute positioned child.
	end
    
--    if (AXObjectCache::accessibilityEnabled())
--        owner->document()->axObjectCache()->childrenChanged(owner);
end

--void updateBeforeAfterContent(RenderObject* owner, PseudoId type, const RenderObject* styledObject = 0);
--RenderObject* beforePseudoElementRenderer(const RenderObject* owner) const;
function LayoutObjectChildList:AfterPseudoElementRenderer(owner)
	local last = owner;
	last = last:LastChild();
	while (last and last:IsAnonymous() and last:Style():StyleType() == PseudoIdEnum.NOPSEUDO and not last:IsListMarker()) do
		last = last:LastChild();
	end
--    do {
--        last = last->lastChild();
--    } while (last && last->isAnonymous() && last->style()->styleType() == NOPSEUDO && !last->isListMarker());
    if (last and last:Style():StyleType() ~= PseudoIdEnum.AFTER) then
        return nil;
	end
    return last;
end


