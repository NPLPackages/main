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
local LayoutObjectChildList = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.LayoutObjectChildList"));

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
	--TODO: fixed this function

--	while (firstChild()) {
--        if (firstChild()->isListMarker() || (firstChild()->style()->styleType() == FIRST_LETTER && !firstChild()->isText()))
--            firstChild()->remove();  // List markers are owned by their enclosing list and so don't get destroyed by this container. Similarly, first letters are destroyed by their remaining text fragment.
--        else if (firstChild()->isRunIn() && firstChild()->node()) {
--            firstChild()->node()->setRenderer(0);
--            firstChild()->node()->setNeedsStyleRecalc();
--            firstChild()->destroy();
--        } else {
--            // Destroy any anonymous children remaining in the render tree, as well as implicit (shadow) DOM elements like those used in the engine-based text fields.
--            if (firstChild()->node())
--                firstChild()->node()->setRenderer(0);
--            firstChild()->destroy();
--        }
--    }
end

function LayoutObjectChildList:RemoveChildNode(owner, oldChild, fullRemove)
	--TODO: fixed this function
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
        if (owner:Style():Visibility() ~= "VISIBLE" and newChild:Style():Visibility() == "VISIBLE" and not newChild:HasLayer()) then
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

--	ASSERT(!child->parent());
--    while (beforeChild->parent() != owner && beforeChild->parent()->isAnonymousBlock())
--        beforeChild = beforeChild->parent();
--    ASSERT(beforeChild->parent() == owner);
--
--    ASSERT(!owner->isBlockFlow() || (!child->isTableSection() && !child->isTableRow() && !child->isTableCell()));
--
--    if (beforeChild == firstChild())
--        setFirstChild(child);
--
--    RenderObject* prev = beforeChild->previousSibling();
--    child->setNextSibling(beforeChild);
--    beforeChild->setPreviousSibling(child);
--    if (prev)
--        prev->setNextSibling(child);
--    child->setPreviousSibling(prev);
--
--    child->setParent(owner);
--    
--    if (fullInsert) {
--        // Keep our layer hierarchy updated.  Optimize for the common case where we don't have any children
--        // and don't have a layer attached to ourselves.
--        RenderLayer* layer = 0;
--        if (child->firstChild() || child->hasLayer()) {
--            layer = owner->enclosingLayer();
--            child->addLayers(layer);
--        }
--
--        // if the new child is visible but this object was not, tell the layer it has some visible content
--        // that needs to be drawn and layer visibility optimization can't be used
--        if (owner->style()->visibility() != VISIBLE && child->style()->visibility() == VISIBLE && !child->hasLayer()) {
--            if (!layer)
--                layer = owner->enclosingLayer();
--            if (layer)
--                layer->setHasVisibleContent(true);
--        }
--
--        if (child->isListItem())
--            toRenderListItem(child)->updateListMarkerNumbers();
--
--        if (!child->isFloating() && owner->childrenInline())
--            owner->dirtyLinesFromChangedChild(child);
--
--        if (child->isRenderRegion())
--            toRenderRegion(child)->attachRegion();
--
--        if (RenderFlowThread* containerFlowThread = renderFlowThreadContainer(owner))
--            containerFlowThread->addFlowChild(child, beforeChild);
--    }
--
--    RenderCounter::rendererSubtreeAttached(child);
--    RenderQuote::rendererSubtreeAttached(child);
--    child->setNeedsLayoutAndPrefWidthsRecalc();
--    if (!owner->normalChildNeedsLayout())
--        owner->setChildNeedsLayout(true); // We may supply the static position for an absolute positioned child.
--    
--    if (AXObjectCache::accessibilityEnabled())
--        owner->document()->axObjectCache()->childrenChanged(owner);
end

--void updateBeforeAfterContent(RenderObject* owner, PseudoId type, const RenderObject* styledObject = 0);
--RenderObject* beforePseudoElementRenderer(const RenderObject* owner) const;
function LayoutObjectChildList:AfterPseudoElementRenderer(owner)
	local last = owner;
	last = last:LastChild();
	while (last and last:IsAnonymous() and last:Style():StyleType() == "NOPSEUDO" and not last:IsListMarker()) do
		last = last:LastChild();
	end
--    do {
--        last = last->lastChild();
--    } while (last && last->isAnonymous() && last->style()->styleType() == NOPSEUDO && !last->isListMarker());
    if (last and last:Style():StyleType() ~= "AFTER") then
        return nil;
	end
    return last;
end


