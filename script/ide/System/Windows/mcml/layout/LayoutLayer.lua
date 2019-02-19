--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutLayer.lua");
local LayoutLayer = commonlib.gettable("System.Windows.mcml.layout.LayoutLayer");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/platform/ScrollableArea.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntPoint.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/PaintInfo.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutScrollbar.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/ScrollbarTheme.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutScrollCorner.lua");
local LayoutScrollCorner = commonlib.gettable("System.Windows.mcml.layout.LayoutScrollCorner");
local ScrollbarTheme = commonlib.gettable("System.Windows.mcml.platform.ScrollbarTheme");
local LayoutScrollbar = commonlib.gettable("System.Windows.mcml.layout.LayoutScrollbar");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local PaintInfo = commonlib.gettable("System.Windows.mcml.layout.PaintInfo");
local LayoutPoint = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");
local LayoutSize = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");

local LayoutLayer = commonlib.inherit(commonlib.gettable("System.Windows.mcml.platform.ScrollableArea"), commonlib.gettable("System.Windows.mcml.layout.LayoutLayer"));


local VisibilityEnum = ComputedStyleConstants.VisibilityEnum;
local PositionEnum = ComputedStyleConstants.PositionEnum;
local OverflowEnum = ComputedStyleConstants.OverflowEnum;
local MarqueeBehaviorEnum = ComputedStyleConstants.MarqueeBehaviorEnum;
local ResizeEnum = ComputedStyleConstants.ResizeEnum;

local LayoutRect,IntRect = Rect, Rect;

local ClipRect = commonlib.gettable("System.Windows.mcml.layout.ClipRect");
local ClipRects = commonlib.gettable("System.Windows.mcml.layout.ClipRects");

ClipRect.__index = ClipRect;
-- create a new ClipRect
function ClipRect:new(rect, hasRadius)
	local o = {};
	if(rect) then
		o.rect = rect:clone()
	else
		o.rect = LayoutRect:new();
	end
	o.hasRadius = if_else(hasRadius == nil, false, hasRadius);
	setmetatable(o, self);
	return o;
end

--function ClipRect:ctor()
--	self.rect = LayoutRect:new();
--	self.hasRadius = false;
--end

function ClipRect:clone()
	return ClipRect:new(self.rect, self.hasRadius);
end
---- @param rect: Rect
--function ClipRect:init(rect)
--	self.rect:Reset(rect);
--	return self;
--end

function ClipRect:Reset(other)
	if(other.rect ~= nil and other.hasRadius ~= nil) then
		self.rect:Reset(other.rect);
		self.hasRadius = other.hasRadius;
	else
		self.rect:Reset(other);
	end
end
    
function ClipRect:Rect()
	return self.rect;
end

function ClipRect:SetRect(rect) 
	self.rect:Reset(rect);
end

function ClipRect:HasRadius() 
	return self.hasRadius;
end

function ClipRect:SetHasRadius(hasRadius)
	self.hasRadius = hasRadius;
end

function ClipRect.__eq(a,b)
	return a:Rect() == b:Rect() and a:HasRadius() == b:HasRadius();
end

function ClipRect:Intersect(other)
	if(other.rect ~= nil and other.hasRadius ~= nil) then
		self.rect:Intersect(other:Rect());
		if (other:HasRadius()) then
			self.hasRadius = true;
		end
	else
		self.rect:Intersect(other);
	end
end

function ClipRect:Move(x, y)
	rect:Move(x, y);
end

function ClipRect:IsEmpty()
	return self.rect:IsEmpty();
end

function ClipRect:Intersects(rect) 
	return self.rect:Intersects(rect);
end

--inline ClipRect intersection(const ClipRect& a, const ClipRect& b)
function ClipRect.Intersection(a, b)
    local c = a:clone();
    c:Intersect(b);
    return c;
end

ClipRects.__index = ClipRects;

-- create a new ClipRects
function ClipRects:new(rect)
	local o = {};
	o.overflowClipRect = ClipRect:new(rect);
    o.fixedClipRect = ClipRect:new(rect);
    o.posClipRect = ClipRect:new(rect);
    o.refCnt = 0;
    o.fixed = false;
	setmetatable(o, self);
	return o;
end

function ClipRects:clone()
	local newClipRects = ClipRects:new();
	newClipRects.overflowClipRect:Reset(self.overflowClipRect);
	newClipRects.fixedClipRect:Reset(self.fixedClipRect);
	newClipRects.posClipRect:Reset(self.posClipRect);
	newClipRects.fixed = self.fixed;
	return newClipRects;
end


function ClipRects:Reset(rect)
    self.overflowClipRect:Reset(rect);
    self.fixedClipRect:Reset(rect);
    self.posClipRect:Reset(rect);
    self.fixed = false;
end

function ClipRects:OverflowClipRect()
	return self.overflowClipRect;
end

function ClipRects:SetOverflowClipRect(clipRect)
	self.overflowClipRect:Reset(clipRect);
end

function ClipRects:FixedClipRect()
	return self.fixedClipRect;
end

function ClipRects:SetFixedClipRect(clipRect)
	self.fixedClipRect:Reset(clipRect);
end

function ClipRects:PosClipRect()
	return self.posClipRect;
end

function ClipRects:SetPosClipRect(clipRect)
	self.posClipRect:Reset(clipRect);
end


function ClipRects:Fixed()
	return self.fixed;
end

function ClipRects:SetFixed(fixed)
	self.fixed = fixed;
end

function ClipRects:Ref()
	self.refCnt = self.refCnt + 1;
end

function ClipRects:Deref(renderArena)
	self.refCnt = self.refCnt - 1;
	if (self.refCnt == 0) then
		self:Destroy(renderArena);
	end
end

function ClipRects:Destroy(renderArena)
	-- TODO: fixed latter;
end

function ClipRects.__eq(a, b)
	return a:OverflowClipRect() == b:OverflowClipRect() and 
			a:FixedClipRect() == b:FixedClipRect() and
			a:PosClipRect() == b:PosClipRect() and
			a:Fixed() == b:Fixed();
end


function LayoutLayer:ctor()	
    self.inResizeMode = false;
    self.scrollDimensionsDirty = true;
    self.zOrderListsDirty = true;
    self.normalFlowListDirty = true;
	self.isNormalFlowOnly = false;
    self.usedTransparency = false;
    self.paintingInsideReflection = false;
    self.inOverflowRelayout = false;
    self.needsFullRepaint = false;
    self.overflowStatusDirty = true;
    self.visibleContentStatusDirty = true;
    self.hasVisibleContent = false;
    self.visibleDescendantStatusDirty = false;
    self.hasVisibleDescendant = false;
    self.isPaginated = false;
    self._3DTransformedDescendantStatusDirty = true;
    self.has3DTransformedDescendant = false;
--#if USE(ACCELERATED_COMPOSITING)
    self.hasCompositingDescendant = false;
    self.mustOverlapCompositedLayers = false;
--#endif
    self.containsDirtyOverlayScrollbars = false;
    self.renderer = nil;
    self.parent = nil;
    self.previous = nil;
    self.next = nil;
    self.first = nil;
    self.last = nil;
    self.posZOrderList = nil;
    self.negZOrderList = nil;
    self.normalFlowList = nil;
    self.clipRects = nil;
--#ifndef NDEBUG
    self.clipRectsRoot = nil;
--#endif
    self.marquee = nil;
    self.staticInlinePosition = 0;
    self.staticBlockPosition = 0;
    self.reflection = nil;
    self.scrollCorner = nil;
    self.resizer = nil;
    self.scrollableAreaPage = nil;

	-- Cached repaint rects. Used by layout.
	self.repaintRect = LayoutRect:new(); 
    self.outlineBox = LayoutRect:new();

    -- Our current relative position offset.
    self.relativeOffset = LayoutSize:new();

    -- Our (x,y) coordinates are in our parent layer's coordinate space.
    self.topLeft = LayoutPoint:new();

    -- The layer's width/height
    self.layerSize = LayoutSize:new();

    -- Our scroll offsets if the view is scrolled.
    self.scrollOffset = LayoutSize:new();

    self.scrollOverflow = LayoutSize:new();
    
    -- The width/height of our scrolled area.
    self.scrollSize = LayoutSize:new();

    -- For layers with overflow, we have a pair of scrollbars.
    self.hBar = nil;
    self.vBar = nil;

	self.cachedOverlayScrollbarOffset = nil;

	self.transform = nil;

	self.blockSelectionGapsBounds = 0;

	self.backing = nil;

	self.inClipRect = true;
end

function LayoutLayer:InClipRect()
	return self.inClipRect;
end

function LayoutLayer:IsInClipRect()
	if(not self:Parent()) then
		--return true;
	elseif(self:Parent():InClipRect() == false) then
		self.inClipRect = false;
	else
		echo("LayoutLayer:IsInClipRect")
		self:Renderer():PrintNodeInfo()
		echo({self:Parent():Location(), self:Location()})
		local parentRect = IntRect:new_from_pool(0, 0, self:Parent():Size():Width(), self:Parent():Size():Height())
		local selfRect = IntRect:new_from_pool(self:Location(), self:Size())

--		local scrollOffset = self:Parent():ScrolledContentOffset();
--		echo(scrollOffset)
--		selfRect:Move(scrollOffset);

--		if (self:Renderer():IsRelPositioned()) then
--			--local relativeOffset = self:Renderer():RelativePositionOffset();
--			selfRect:Move(self.relativeOffset);
--		end
		echo(selfRect)
		echo(parentRect)
		local rect = Rect.Intersection(parentRect, selfRect);

		self.inClipRect = if_else(rect:IsEmpty(), false, true)
	end

	return self.inClipRect;
end

--const LayoutSize& relativePositionOffset() const { return m_relativeOffset; }
function LayoutLayer:RelativePositionOffset()
	echo("LayoutLayer:RelativePositionOffset")
	self:Renderer():PrintNodeInfo()
	echo(self.relativeOffset)
	return self.relativeOffset;
end

function LayoutLayer:Destroy(renderArena)
	echo("LayoutLayer:Destroy")
	self:Renderer():PrintNodeInfo()
--    delete this;
--
--    // Recover the size left there for us by operator delete and free the memory.
--    renderArena->free(*(size_t *)this, this);

	self:DestroyScrollbar("HorizontalScrollbar")
	self:DestroyScrollbar("VerticalScrollbar")

	self:DestroyScrollCorner();
end

function LayoutLayer:Renderer()
	return self.renderer;
end

function LayoutLayer:RenderBox()
	if(self.renderer and self.renderer:IsBox()) then
		return self.renderer;
	end
	return nil;
end

function LayoutLayer:Parent()
	return self.parent;
end

function LayoutLayer:PreviousSibling()
	return self.previous;
end

function LayoutLayer:NextSibling()
	return self.next;
end

function LayoutLayer:FirstChild()
	return self.first;
end

function LayoutLayer:LastChild()
	return self.last;
end

function LayoutLayer:SetNextSibling(next)
	self.next = next;
end

function LayoutLayer:SetPreviousSibling(prev)
	self.previous = prev;
end

function LayoutLayer:SetParent(parent)
	if (parent == self.parent) then
        return;
	end

--#if USE(ACCELERATED_COMPOSITING)
--    if (m_parent && !renderer()->documentBeingDestroyed())
--        compositor()->layerWillBeRemoved(m_parent, this);
--#endif
    
    self.parent = parent;
    
--#if USE(ACCELERATED_COMPOSITING)
--    if (m_parent && !renderer()->documentBeingDestroyed())
--        compositor()->layerWasAdded(m_parent, this);
--#endif
end

function LayoutLayer:SetFirstChild(first)
	self.first = first;
end

function LayoutLayer:SetLastChild(last)
	self.last = last;
end

function LayoutLayer:RepaintRect()
	return self.repaintRect;
end

function LayoutLayer:ShouldBeNormalFlowOnly()
	local r = self:Renderer();
    return (r:HasOverflowClip()
                or r:HasReflection()
                or r:HasMask()
                or r:IsCanvas()
                or r:IsVideo()
                or r:IsEmbeddedObject()
                or r:IsApplet()
                or r:IsLayoutIFrame()
                or r:Style():SpecifiesColumns())
            and not r:IsPositioned()
            and not r:IsRelPositioned()
            and not r:HasTransform()
            and not self:IsTransparent();
end

function LayoutLayer:IsSelfPaintingLayer()
    return not self:IsNormalFlowOnly()
        or self:Renderer():HasReflection()
        or self:Renderer():HasMask()
        or self:Renderer():IsTableRow()
        or self:Renderer():IsCanvas()
        or self:Renderer():IsVideo()
        or self:Renderer():IsEmbeddedObject()
        or self:Renderer():IsApplet()
        or self:Renderer():IsLayoutIFrame();
end

function LayoutLayer:IsTransparent()
--#if ENABLE(SVG)
--    if (renderer()->node() && renderer()->node()->namespaceURI() == SVGNames::svgNamespaceURI)
--        return false;
--#endif
    return self:Renderer():IsTransparent() or self:Renderer():HasMask();
end

function LayoutLayer:IsNormalFlowOnly()
	return self.isNormalFlowOnly;
end

function LayoutLayer:IsPaginated()
	return self.isPaginated;
end

function LayoutLayer:Location()
	return self.topLeft;
end

function LayoutLayer:SetLocation(x, y)
	self.topLeft:Reset(x, y);
end

function LayoutLayer:Size()
	return self.layerSize;
end

function LayoutLayer:SetSize(size)
	self.layerSize:Reset(size:Width(), size:Height());
end

function LayoutLayer:Rect()
	return LayoutRect:new(self:Location(), self:Size());
end

function LayoutLayer:StaticInlinePosition()
	return self.staticInlinePosition;
end

function LayoutLayer:StaticBlockPosition()
	return self.staticBlockPosition;
end
   
function LayoutLayer:SetStaticInlinePosition(position)
	self.staticInlinePosition = position;
end

function LayoutLayer:SetStaticBlockPosition(position)
	self.staticBlockPosition = position;
end

function LayoutLayer:DirtyNormalFlowList()
    if (self.normalFlowList) then
        self.normalFlowList:clear();
	end
    self.normalFlowListDirty = true;

--#if USE(ACCELERATED_COMPOSITING)
--    if (!renderer()->documentBeingDestroyed())
--        compositor()->setCompositingLayersNeedRebuild();
--#endif
end

function LayoutLayer:StackingContext()
    local layer = self:Parent();
    while (layer and not layer:Renderer():IsLayoutView() and not layer:Renderer():IsRoot() and layer:Renderer():Style():HasAutoZIndex()) do
        layer = layer:Parent();
	end
    return layer;
end

function LayoutLayer:DirtyStackingContextZOrderLists()
    local sc = self:StackingContext();
    if (sc) then
        sc:DirtyZOrderLists();
	end
end

function LayoutLayer:DirtyZOrderLists()
    if (self.posZOrderList) then
        self.posZOrderList:clear();
	end
    if (self.negZOrderList) then
        self.negZOrderList:clear();
	end
    self.zOrderListsDirty = true;

--#if USE(ACCELERATED_COMPOSITING)
--    if (!renderer()->documentBeingDestroyed())
--        compositor()->setCompositingLayersNeedRebuild();
--#endif
end

function LayoutLayer:UpdateVisibilityStatus()
    if (self.visibleDescendantStatusDirty) then
        self.hasVisibleDescendant = false;
		local child = self:FirstChild();
		while(child) do
			child:UpdateVisibilityStatus();        
            if (child.hasVisibleContent or child.hasVisibleDescendant) then
                self.hasVisibleDescendant = true;
                break;
            end
			child = child:NextSibling();
		end

        self.visibleDescendantStatusDirty = false;
    end

    if (self.visibleContentStatusDirty) then
        if (self:Renderer():Style():Visibility() == VisibilityEnum.VISIBLE) then
            self.hasVisibleContent = true;
        else
            -- layer may be hidden but still have some visible content, check for this
            self.hasVisibleContent = false;
            r = self:Renderer():FirstChild();
            while (r) do
                if (r:Style():Visibility() == VisibilityEnum.VISIBLE and not r:HasLayer()) then
                    self.hasVisibleContent = true;
                    break;
                end
                if (r:FirstChild() and not r:HasLayer()) then
                    r = r:FirstChild();
                elseif (r:NextSibling()) then
                    r = r:NextSibling();
                else
                    
                    r = r:Parent();
                    if (r == self:Renderer()) then
                        r = nil;
					end
                    while (r and not r:NextSibling()) do
						r = r:Parent();
						if (r == self:Renderer()) then
							r = nil;
						end
					end
                    if (r) then
                        r = r:NextSibling();
					end
                end
            end
        end    
        self.visibleContentStatusDirty = false; 
    end
end

--void RenderLayer::childVisibilityChanged(bool newVisibility) 
function LayoutLayer:ChildVisibilityChanged(newVisibility) 
    if (self.hasVisibleDescendant == newVisibility or self.visibleDescendantStatusDirty) then
        return;
	end
    if (newVisibility) then
        local l = self;
        while (l and not l.visibleDescendantStatusDirty and not l.hasVisibleDescendant) do
            l.hasVisibleDescendant = true;
            l = l:Parent();
        end
    else 
        self:DirtyVisibleDescendantStatus();
	end
end

function LayoutLayer:DirtyVisibleDescendantStatus()
    local l = self;
    while (l and not l.visibleDescendantStatusDirty) do
        l.visibleDescendantStatusDirty = true;
        l = l:Parent();
    end
end

--void RenderLayer::addChild(RenderLayer* child, RenderLayer* beforeChild)
function LayoutLayer:AddChild(child, beforeChild)
	echo("LayoutLayer:AddChild")
	self:Renderer():PrintNodeInfo()
	child:Renderer():PrintNodeInfo()
	local prevSibling;
	if(beforeChild) then
		prevSibling = beforeChild:PreviousSibling();
	else
		prevSibling = self:LastChild();
	end

    if (prevSibling) then
        child:SetPreviousSibling(prevSibling);
        prevSibling:SetNextSibling(child);
        --ASSERT(prevSibling != child);
    else
        self:SetFirstChild(child);
	end

    if (beforeChild) then
        beforeChild:SetPreviousSibling(child);
        child:SetNextSibling(beforeChild);
        --ASSERT(beforeChild != child);
    else
        self:SetLastChild(child);
	end

    child:SetParent(self);

    if (child:IsNormalFlowOnly()) then
        self:DirtyNormalFlowList();
	end

    if (not child:IsNormalFlowOnly() or child:FirstChild()) then
        -- Dirty the z-order list in which we are contained.  The stackingContext() can be null in the
        -- case where we're building up generated content layers.  This is ok, since the lists will start
        -- off dirty in that case anyway.
        child:DirtyStackingContextZOrderLists();
    end

    child:UpdateVisibilityStatus();
    if (child.hasVisibleContent or child.hasVisibleDescendant) then
        self:ChildVisibilityChanged(true);
	end
    


--#if USE(ACCELERATED_COMPOSITING)
--    compositor()->layerWasAdded(this, child);
--#endif
end

--RenderLayer* RenderLayer::removeChild(RenderLayer* oldChild)
function LayoutLayer:RemoveChild(oldChild)
--	#if USE(ACCELERATED_COMPOSITING)
--		if (!renderer()->documentBeingDestroyed())
--			compositor()->layerWillBeRemoved(this, oldChild);
--	#endif

    -- remove the child
    if (oldChild:PreviousSibling()) then
        oldChild:PreviousSibling():SetNextSibling(oldChild:NextSibling());
	end

    if (oldChild:NextSibling()) then
        oldChild:NextSibling():SetPreviousSibling(oldChild:PreviousSibling());
	end

    if (self.first == oldChild) then
        self.first = oldChild:NextSibling();
	end
    if (self.last == oldChild) then
        self.last = oldChild:PreviousSibling();
	end

    if (oldChild:IsNormalFlowOnly()) then
        self:DirtyNormalFlowList();
	end

    if (not oldChild:IsNormalFlowOnly() or oldChild:FirstChild()) then
        -- Dirty the z-order list in which we are contained.  When called via the
        -- reattachment process in removeOnlyThisLayer, the layer may already be disconnected
        -- from the main layer tree, so we need to null-check the |stackingContext| value.
        oldChild:DirtyStackingContextZOrderLists();
    end

    oldChild:SetPreviousSibling(nil);
    oldChild:SetNextSibling(nil);
    oldChild:SetParent(nil);
    
    oldChild:UpdateVisibilityStatus();
    if (oldChild.hasVisibleContent or oldChild.hasVisibleDescendant) then
        self:ChildVisibilityChanged(false);
	end
    return oldChild;
end

function LayoutLayer:init(renderer)
	echo("LayoutLayer:init")
	renderer:PrintNodeInfo()
	self.renderer = renderer;

	self.isNormalFlowOnly = self:ShouldBeNormalFlowOnly();
	echo(self.isNormalFlowOnly)
    --ScrollableArea::setConstrainsScrollingToContentEdge(false);
	self:SetConstrainsScrollingToContentEdge(false);

    if (not renderer:FirstChild() and renderer:Style()) then
        self.visibleContentStatusDirty = false;
        self.hasVisibleContent = renderer:Style():Visibility() == VisibilityEnum.VISIBLE;
    end

	return self;
end

function LayoutLayer:ReflectionLayer()
    --return m_reflection ? m_reflection->layer() : 0;
	if(self.reflection) then
		self.reflection:Layer();
	end
	return nil;
end

function LayoutLayer:InsertOnlyThisLayer()
    if (self.parent == nil and self:Renderer():Parent()) then
        -- We need to connect ourselves when our renderer() has a parent.
        -- Find our enclosingLayer and add ourselves.
        local parentLayer = self:Renderer():Parent():EnclosingLayer();

        --ASSERT(parentLayer);
        local beforeChild = if_else(parentLayer:ReflectionLayer() ~= self, self:Renderer():Parent():FindNextLayer(parentLayer, self:Renderer()), nil);
        parentLayer:AddChild(self, beforeChild);
    end

    -- Remove all descendant layers from the hierarchy and add them to the new position.
	local curr = self:Renderer():FirstChild();
	while(curr) do
		curr:MoveLayers(self.parent, self);
		curr = curr:NextSibling();
	end
--    for (RenderObject* curr = renderer()->firstChild(); curr; curr = curr->nextSibling())
--        curr->moveLayers(m_parent, this);

    -- Clear out all the clip rects.
    self:ClearClipRectsIncludingDescendants();
end

function LayoutLayer:ClearClipRectsIncludingDescendants()
    if (not self.clipRects) then
        return;
	end

    self:ClearClipRects();
    
	local l = self:FirstChild();
	while(l) do
		l:ClearClipRectsIncludingDescendants();
		l = l:NextSibling()
	end
end

function LayoutLayer:ClearClipRects()
    if (self.clipRects) then
        self.clipRects:Deref(self:Renderer():RenderArena());
        self.clipRects = nil;
--#ifndef NDEBUG
        self.clipRectsRoot = nil;
--#endif    
    end
end

function LayoutLayer:SetNeedsFullRepaint(f)
	f = if_else(f == nil, true, f);
	self.needsFullRepaint = f;
end

--void RenderLayer::updateLayerPositions(LayoutPoint* offsetFromRoot, UpdateLayerPositionsFlags flags)
function LayoutLayer:UpdateLayerPositions(offsetFromRoot, flags)
	echo("LayoutLayer:UpdateLayerPositions begin")
	self:Renderer():PrintNodeInfo()
	self:UpdateLayerPosition();
	echo("LayoutLayer:UpdateLayerPositions 1111111111")
		local oldOffsetFromRoot;
    if (offsetFromRoot) then
        -- We can't cache our offset to the repaint container if the mapping is anything more complex than a simple translation
        if (not self:CanUseConvertToLayerCoords()) then
            offsetFromRoot = nil; -- If our cached offset is invalid make sure it's not passed to any of our children
        else
            oldOffsetFromRoot = offsetFromRoot;
            -- Frequently our parent layer's renderer will be the same as our renderer's containing block.  In that case,
            -- we just update the cache using our offset to our parent (which is m_topLeft). Otherwise, regenerated cached
            -- offsets to the root from the render tree.
            if (self.parent == nil or self.parent:Renderer() == self:Renderer():ContainingBlock()) then
                offsetFromRoot:Move(self.topLeft:X(), self.topLeft:Y()); -- Fast case
            else
                local offset = LayoutPoint:new();
                offset = self:ConvertToLayerCoords(self:Root(), offset);
                offsetFromRoot = offset;
            end
        end
    end

    local offset = LayoutPoint:new();
    if (offsetFromRoot) then
        offset = offsetFromRoot;
    else
        -- FIXME: It looks suspicious to call convertToLayerCoords here
        -- as canUseConvertToLayerCoords may be true for an ancestor layer.
        offset = self:ConvertToLayerCoords(self:Root(), offset);
    end
	echo("LayoutLayer:UpdateLayerPositions 22222222222")
    self:PositionOverflowControls(offset:ToSize());
	echo("LayoutLayer:UpdateLayerPositions 33333333333")
    self:UpdateVisibilityStatus();

    if (self.hasVisibleContent) then
        local view = self:Renderer():View();
        -- ASSERT(view);
        -- FIXME: LayoutState does not work with RenderLayers as there is not a 1-to-1
        -- mapping between them and the RenderObjects. It would be neat to enable
        -- LayoutState outside the layout() phase and use it here.
        -- ASSERT(!view->layoutStateEnabled());

        local repaintContainer = self:Renderer():ContainerForRepaint();
        -- IntRect oldRepaintRect = m_repaintRect;
        -- IntRect oldOutlineBox = m_outlineBox;
		local oldRepaintRect, oldOutlineBox = self.repaintRect, self.outlineBox;
        self:ComputeRepaintRects(offsetFromRoot);
        -- FIXME: Should ASSERT that value calculated for m_outlineBox using the cached offset is the same
        -- as the value not using the cached offset, but we can't due to https://bugs.webkit.org/show_bug.cgi?id=37048
    else
        self:ClearRepaintRects();
	end

	self.needsFullRepaint = false;
	echo("LayoutLayer:UpdateLayerPositions 44444444444444444444")
	local child = self:FirstChild();
	while(child) do
		child:UpdateLayerPositions(offsetFromRoot, flags);
		child = child:NextSibling()
	end

	if (offsetFromRoot) then
        offsetFromRoot = oldOffsetFromRoot;
	end
	echo("LayoutLayer:UpdateLayerPositions end")
end

function LayoutLayer:RemoveOnlyThisLayer()
    if (not self.parent) then
        return;
	end

    -- Mark that we are about to lose our layer. This makes render tree
    -- walks ignore this layer while we're removing it.
    self.renderer:SetHasLayer(false);

--#if USE(ACCELERATED_COMPOSITING)
--    compositor()->layerWillBeRemoved(m_parent, this);
--#endif

    -- Dirty the clip rects.
    self:ClearClipRectsIncludingDescendants();

    -- Remove us from the parent.
    local parent = self.parent;
    local nextSib = self:NextSibling();
    local hasLayerOffset;

	-- TODO: fixed latter
--    const LayoutPoint offsetFromRootBeforeMove = computeOffsetFromRoot(hasLayerOffset);
--    parent->removeChild(this);
--    
--    if (reflection())
--        removeChild(reflectionLayer());
--
--    // Now walk our kids and reattach them to our parent.
--    RenderLayer* current = m_first;
--    while (current) {
--        RenderLayer* next = current->nextSibling();
--        removeChild(current);
--        parent->addChild(current, nextSib);
--        current->setNeedsFullRepaint();
--        LayoutPoint offsetFromRoot = offsetFromRootBeforeMove;
--        // updateLayerPositions depends on hasLayer() already being false for proper layout.
--        ASSERT(!renderer()->hasLayer());
--        current->updateLayerPositions(hasLayerOffset ? &offsetFromRoot : 0);
--        current = next;
--    }
--
--    m_renderer->destroyLayer();
end

function LayoutLayer:HasReflection()
	return self:Renderer():HasReflection();
end

function LayoutLayer:IsReflection()
	return self:Renderer():IsReplica();
end

function LayoutLayer:Reflection() 
	return self.reflection;
end

function LayoutLayer:ScrollsOverflow()
    if (not self:Renderer():IsBox()) then
        return false;
	end
    
    return self:Renderer():ScrollsOverflow();
end

function LayoutLayer:UpdateScrollCornerStyle()
	--TODO: fixed latter
end

function LayoutLayer:UpdateResizerStyle()
	--TODO: fixed latter
end

function LayoutLayer:UpdateTransform()
	--TODO: fixed latter
end

--void RenderLayer::styleChanged(StyleDifference diff, const RenderStyle* oldStyle)
function LayoutLayer:StyleChanged(diff, oldStyle)
    local isNormalFlowOnly = self:ShouldBeNormalFlowOnly();
    if (isNormalFlowOnly ~= self.isNormalFlowOnly) then
        self.isNormalFlowOnly = isNormalFlowOnly;
        local p = self:Parent();
        if (p) then
            p:DirtyNormalFlowList();
		end
        self:DirtyStackingContextZOrderLists();
    end

    if (self:Renderer():Style():OverflowX() == OverflowEnum.OMARQUEE and self:Renderer():Style():MarqueeBehavior() ~= MarqueeBehaviorEnum.MNONE and self:Renderer():IsBox()) then
--        if (!m_marquee)
--            m_marquee = new RenderMarquee(this);
--        m_marquee->updateMarqueeStyle();
    elseif (self.marquee) then
        --delete m_marquee;
        --m_marquee = 0;
    end
    
    if (not self:HasReflection() and self.reflection) then
        --self:RemoveReflection();
    elseif (self:HasReflection()) then
--        if (!m_reflection)
--            createReflection();
--        updateReflectionStyle();
    end
    
    if (self:ScrollsOverflow()) then
--        if (!m_scrollableAreaPage) {
--            if (Frame* frame = renderer()->frame()) {
--                if (Page* page = frame->page()) {
--                    m_scrollableAreaPage = page;
--                    m_scrollableAreaPage->addScrollableArea(this);
--                }
--            }
--        }
    elseif (self.scrollableAreaPage) then
--        m_scrollableAreaPage->removeScrollableArea(this);
--        m_scrollableAreaPage = 0;
    end
    
    -- FIXME: Need to detect a swap from custom to native scrollbars (and vice versa).
    if (self.hBar) then
        --m_hBar->styleChanged();
	end
    if (self.vBar) then
        --m_vBar->styleChanged();
	end
    
    self:UpdateScrollCornerStyle();
    self:UpdateResizerStyle();

--#if USE(ACCELERATED_COMPOSITING)
--    updateTransform();
--
--    if (compositor()->updateLayerCompositingState(this))
--        compositor()->setCompositingLayersNeedRebuild();
--    else if (m_backing)
--        m_backing->updateGraphicsLayerGeometry();
--    else if (oldStyle && oldStyle->overflowX() != renderer()->style()->overflowX()) {
--        if (stackingContext()->hasCompositingDescendant())
--            compositor()->setCompositingLayersNeedRebuild();
--    }
--    
--    if (m_backing && diff >= StyleDifferenceRepaint)
--        m_backing->setContentsNeedDisplay();
--#else
--    UNUSED_PARAM(diff);
--#endif
end

function LayoutLayer:HasVisibleContent()
	return self.hasVisibleContent;
end

function LayoutLayer:HasVisibleDescendant()
	return self.hasVisibleDescendant;
end

function LayoutLayer:DirtyVisibleContentStatus() 
    self.visibleContentStatusDirty = true; 
    if (self:Parent()) then
        self:Parent():DirtyVisibleDescendantStatus();
	end
end

function LayoutLayer:DirtyVisibleDescendantStatus()
    local layer = self;
    while (layer and not layer.visibleDescendantStatusDirty) do
        layer.visibleDescendantStatusDirty = true;
        layer = layer:Parent();
    end
end

function LayoutLayer:ScrolledContentOffset()
	return self:ScrollOffset() + self.scrollOverflow;
end

function LayoutLayer:ScrollXOffset()
	return self.scrollOffset:Width() + self.scrollOrigin:X();
end

function LayoutLayer:ScrollYOffset()
	return self.scrollOffset:Height() + self.scrollOrigin:Y();
end
function LayoutLayer:ScrollOffset()
	return LayoutSize:new(self:ScrollXOffset(), self:ScrollYOffset());
end

-- Note that this transform has the transform-origin baked in.
--TransformationMatrix* transform() const { return m_transform.get(); }
function LayoutLayer:Transform()
	return self.transform;
end

--void RenderLayer::computeRepaintRects(IntPoint* offsetFromRoot)
function LayoutLayer:ComputeRepaintRects(offsetFromRoot)
	echo("LayoutLayer:ComputeRepaintRects")
	self:Renderer():PrintNodeInfo();
    --ASSERT(!m_visibleContentStatusDirty);

    local repaintContainer = self:Renderer():ContainerForRepaint();
    self.repaintRect = self:Renderer():ClippedOverflowRectForRepaint(repaintContainer);
	echo(ComputeRepaintRects)
    self.outlineBox = self:Renderer():OutlineBoundsForRepaint(repaintContainer, offsetFromRoot);
end

function LayoutLayer:SetHasVisibleContent(b)
    if (self.hasVisibleContent == b and not self.visibleContentStatusDirty) then
        return;
	end
    self.visibleContentStatusDirty = false; 
    self.hasVisibleContent = b;
    if (self.hasVisibleContent) then
        self:ComputeRepaintRects();
        if (not self:IsNormalFlowOnly()) then
			local sc = self:StackingContext();
			while(sc) do
				sc:DirtyZOrderLists();
                if (sc:HasVisibleContent()) then
                    break;
				end

				sc = sc:StackingContext();
			end
        end
    end
    if (self:Parent()) then
        self:Parent():ChildVisibilityChanged(self.hasVisibleContent);
	end
end

--void RenderLayer::paint(GraphicsContext* p, const LayoutRect& damageRect, PaintBehavior paintBehavior, RenderObject *paintingRoot, RenderRegion* region, PaintLayerFlags paintFlags)
function LayoutLayer:Paint(p, damageRect, paintBehavior, paintingRoot, region, paintFlags)
    local overlapTestRequests = self:PaintLayer(self, p, damageRect, paintBehavior, paintingRoot, region, nil, paintFlags);
--    OverlapTestRequestMap::iterator end = overlapTestRequests.end();
--    for (OverlapTestRequestMap::iterator it = overlapTestRequests.begin(); it != end; ++it)
--        it->first->setOverlapTestResult(false);
end

--static inline bool shouldSuppressPaintingLayer(RenderLayer* layer)
local function shouldSuppressPaintingLayer(layer)
	-- TODO: add latter
	return false;
end

--void RenderLayer::updateLayerListsIfNeeded()
function LayoutLayer:UpdateLayerListsIfNeeded()
    self:UpdateZOrderLists();
    self:UpdateNormalFlowList();
end

function LayoutLayer:UpdateNormalFlowList()
	echo("LayoutLayer:UpdateNormalFlowList begin")
    if (not self.normalFlowListDirty) then
        return;
	end
        echo("LayoutLayer:UpdateNormalFlowList")
		self:Renderer():PrintNodeInfo()
	local child = self:FirstChild();
	while(child) do
		echo("while(child) do")
		child:Renderer():PrintNodeInfo()
		echo(child:IsNormalFlowOnly())
		-- Ignore non-overflow layers and reflections.
		if (child:IsNormalFlowOnly() and (not self.reflection or self:ReflectionLayer() ~= child)) then
            if (not self.normalFlowList) then
                self.normalFlowList = commonlib.vector:new();
			end
			echo("self.normalFlowList:append")
			
            self.normalFlowList:append(child);
		end

		child = child:NextSibling();
	end
    
    self.normalFlowListDirty = false;
end

function LayoutLayer:UpdateVisibilityStatus()
    if (self.visibleDescendantStatusDirty) then
        self.hasVisibleDescendant = false;

		local child = self:FirstChild();
		while(child) do
			child:UpdateVisibilityStatus();        
            if (child.hasVisibleContent or child.hasVisibleDescendant) then
                self.hasVisibleDescendant = true;
                break;
            end

			child = child:NextSibling();
		end

        self.visibleDescendantStatusDirty = false;
    end

    if (self.visibleContentStatusDirty) then
        if (self:Renderer():Style():Visibility() == VisibilityEnum.VISIBLE) then
            self.hasVisibleContent = true;
        else
            -- layer may be hidden but still have some visible content, check for this
            self.hasVisibleContent = false;
            local r = self:Renderer():FirstChild();
            while (r) do
                if (r:Style():Visibility() == VisibilityEnum.VISIBLE and not r:HasLayer()) then
                    self.hasVisibleContent = true;
                    break;
                end
                if (r:FirstChild() and not r:HasLayer()) then
                    r = r:FirstChild();
                elseif (r:NextSibling()) then
                    r = r:NextSibling();
                else
					r = r:Parent();
                    if (r == self:Renderer()) then
                        r = nil;
					end

					while(r and not r:NextSibling()) do
						r = r:Parent();
						if (r == self:Renderer()) then
							r = nil;
						end
					end

                    if (r) then
                        r = r:NextSibling();
					end
                end
            end
        end
        self.visibleContentStatusDirty = false; 
    end
end

function LayoutLayer:IsStackingContext()
--bool isStackingContext() const { return !hasAutoZIndex() || renderer()->isRenderView(); }
	return not self:HasAutoZIndex() or self:Renderer():IsLayoutView();
	--return true;
end

--bool hasAutoZIndex() const { return renderer()->style()->hasAutoZIndex(); }
function LayoutLayer:HasAutoZIndex()
	return self:Renderer():Style():HasAutoZIndex();
end
--int zIndex() const { return renderer()->style()->zIndex(); }
function LayoutLayer:ZIndex()
	return self:Renderer():Style():ZIndex();
end

--void RenderLayer::collectLayers(Vector<RenderLayer*>*& posBuffer, Vector<RenderLayer*>*& negBuffer)
function LayoutLayer:CollectLayers(posBuffer, negBuffer)
	echo("LayoutLayer:CollectLayers")
	self:Renderer():PrintNodeInfo();
    self:UpdateVisibilityStatus();
	echo({self.hasVisibleContent, self.hasVisibleDescendant, self:IsStackingContext(), self:IsNormalFlowOnly(), self:Renderer():IsLayoutFlowThread()})
    -- Overflow layers are just painted by their enclosing layers, so they don't get put in zorder lists.
    if ((self.hasVisibleContent or (self.hasVisibleDescendant and self:IsStackingContext())) and not self:IsNormalFlowOnly() and not self:Renderer():IsLayoutFlowThread()) then
        -- Determine which buffer the child should be in.
        local buffer = if_else(self:ZIndex() >= 0, posBuffer, negBuffer);

        -- Create the buffer if it doesn't exist yet.
        if (not buffer) then
            buffer = commonlib.vector:new();
			if(self:ZIndex() >= 0) then
				posBuffer = buffer;
			else
				negBuffer = buffer;
			end
		end
		echo("buffer:append")
        -- Append ourselves at the end of the appropriate buffer.
        buffer:append(self);
    end

    -- Recur into our children to collect more layers, but only if we don't establish
    -- a stacking context.
    if (self.hasVisibleDescendant and not self:IsStackingContext()) then
		local child = self:FirstChild();
		while(child) do
			-- Ignore reflections.
            if (self.reflection == nil or self:ReflectionLayer() ~= child) then
                posBuffer, negBuffer = child:CollectLayers(posBuffer, negBuffer);
			end

			child = child:NextSibling();
		end
	end
	return posBuffer, negBuffer;
end

--void RenderLayer::updateZOrderLists()
function LayoutLayer:UpdateZOrderLists()
	echo("LayoutLayer:UpdateZOrderLists begin")
	self:Renderer():PrintNodeInfo()
	echo(self:IsStackingContext())
	echo(self.zOrderListsDirty)
    if (not self:IsStackingContext() or not self.zOrderListsDirty) then
        return;
	end
	echo("LayoutLayer:UpdateZOrderLists")
	local child = self:FirstChild();
	while(child) do
		if (not self.reflection or self:ReflectionLayer() ~= child) then
            self.posZOrderList, self.negZOrderList = child:CollectLayers(self.posZOrderList, self.negZOrderList);
		end

		child = child:NextSibling();
	end

    -- Sort the two lists.
    if (self.posZOrderList) then
        --std::stable_sort(m_posZOrderList->begin(), m_posZOrderList->end(), compareZIndex);
		table.sort(self.posZOrderList,function(a,b) return a:ZIndex() < b:ZIndex() end )
	end

    if (self.negZOrderList) then
        --std::stable_sort(m_negZOrderList->begin(), m_negZOrderList->end(), compareZIndex);
		table.sort(self.negZOrderList,function(a,b) return a:ZIndex() < b:ZIndex() end )
	end

    self.zOrderListsDirty = false;
end

function LayoutLayer:RenderBoxLocation()
	return if_else(self:Renderer():IsBox(), self:Renderer():Location(), LayoutPoint:new());
end

function LayoutLayer:RenderBoxX()
	return self:RenderBoxLocation():X();
end

function LayoutLayer:RenderBoxY()
	return self:RenderBoxLocation():Y();
end

--bool RenderLayer::intersectsDamageRect(const LayoutRect& layerBounds, const LayoutRect& damageRect, const RenderLayer* rootLayer) const
function LayoutLayer:IntersectsDamageRect(layerBounds, damageRect, rootLayer)
    -- Always examine the canvas and the root.
    -- FIXME: Could eliminate the isRoot() check if we fix background painting so that the RenderView
    -- paints the root's background.
    if (self:Renderer():IsLayoutView() or self:Renderer():IsRoot()) then
        return true;
	end

	--return false;

    -- If we aren't an inline flow, and our layer bounds do intersect the damage rect, then we 
    -- can go ahead and return true.
    local view = self:Renderer():View();
    --ASSERT(view);
    if (view and not self:Renderer():IsLayoutInline()) then
        local b = layerBounds:clone_from_pool();
        b:Inflate(view:MaximalOutlineSize());
        if (b:Intersects(damageRect)) then
            return true;
		end
    end
        
    -- Otherwise we need to compute the bounding box of this single layer and see if it intersects
    -- the damage rect.
    return self:BoundingBox(rootLayer):Intersects(damageRect);
end

--void RenderLayer::clipToRect(RenderLayer* rootLayer, GraphicsContext* context, const LayoutRect& paintDirtyRect, const ClipRect& clipRect, BorderRadiusClippingRule rule)
function LayoutLayer:ClipToRect(rootLayer, context, paintDirtyRect, clipRect, rule)
    if (clipRect:Rect() == paintDirtyRect) then
        return;
	end
--    context->save();
--    context->clip(clipRect.rect());
    
    if (not clipRect:HasRadius()) then
        return;
	end

--#ifndef DISABLE_ROUNDED_CORNER_CLIPPING
--    // If the clip rect has been tainted by a border radius, then we have to walk up our layer chain applying the clips from
--    // any layers with overflow. The condition for being able to apply these clips is that the overflow object be in our
--    // containing block chain so we check that also.
--    for (RenderLayer* layer = rule == IncludeSelfForBorderRadius ? this : parent(); layer; layer = layer->parent()) {
--        if (layer->renderer()->hasOverflowClip() && layer->renderer()->style()->hasBorderRadius() && inContainingBlockChain(this, layer)) {
--                LayoutPoint delta;
--                layer->convertToLayerCoords(rootLayer, delta);
--                context->addRoundedRectClip(layer->renderer()->style()->getRoundedInnerBorderFor(LayoutRect(delta, layer->size())));
--        }
--
--        if (layer == rootLayer)
--            break;
--    }
--#endif
end
--void RenderLayer::paintLayer(RenderLayer* rootLayer, GraphicsContext*, const LayoutRect& paintDirtyRect, PaintBehavior, RenderObject* paintingRoot, RenderRegion* = 0, OverlapTestRequestMap* = 0, PaintLayerFlags = 0);
function LayoutLayer:PaintLayer(rootLayer, p, paintDirtyRect, paintBehavior, paintingRoot, region, overlapTestRequests, paintFlags)
	echo("LayoutLayer:PaintLayer begin")
	self:Renderer():PrintNodeInfo()
	echo(paintDirtyRect)
	if (shouldSuppressPaintingLayer(self)) then
        return;
	end

	-- If this layer is totally invisible then there is nothing to paint.
    if (self:Renderer():Opacity() == 0) then
        return;
	end

	-- Apply a transform if we have one.  A reflection is considered to be a transform, since it is a flip and a translate.
	-- TODO: add transform latter;

	--PaintLayerFlags localPaintFlags = paintFlags & ~PaintLayerAppliedTransform;
	local localPaintFlags = nil;

	-- Paint the reflection first if we have one and needed.

	-- Calculate the clip rects we should use.
    local layerBounds = LayoutRect:new();
    --ClipRect damageRect, clipRectToApply, outlineRect;
	local damageRect, clipRectToApply, outlineRect = ClipRect:new(), ClipRect:new(), ClipRect:new();
    --calculateRects(rootLayer, region, paintDirtyRect, layerBounds, damageRect, clipRectToApply, outlineRect, localPaintFlags & PaintLayerTemporaryClipRects);
	layerBounds, damageRect, clipRectToApply, outlineRect = self:CalculateRects(rootLayer, region, paintDirtyRect, layerBounds, damageRect, clipRectToApply, outlineRect, localPaintFlags);
	echo("LayoutLayer:PaintLayer")
	echo(self:IsInClipRect())
	echo(self.clipRects)
	--echo(self.clipsRepaints)
	echo({self.topLeft, self.layerSize, self.relativeOffset})
	self:Renderer():PrintNodeInfo()
	echo(damageRect)
	echo(layerBounds)
	echo(self:RenderBoxLocation())
	echo(clipRectToApply)
	echo(self.relativeOffset)
    --local paintOffset = (layerBounds:Location() - self:RenderBoxLocation()):ToPoint();
	local paintOffset = layerBounds:Location();

	-- Ensure our lists are up-to-date.
    self:UpdateLayerListsIfNeeded();

	-- If this layer's renderer is a child of the paintingRoot, we render unconditionally, which
    -- is done by passing a nil paintingRoot down to our renderer (as if no paintingRoot was ever set).
    -- Else, our renderer tree may or may not contain the painting root, so we pass that root along
    -- so it will be tested against as we descend through the renderers.
	local paintingRootForRenderer = nil;
    if (paintingRoot and not self:Renderer():IsDescendantOf(paintingRoot)) then
        paintingRootForRenderer = paintingRoot;
	end


	-- We want to paint our layer, but only if we intersect the damage rect.
    local shouldPaint = self:IntersectsDamageRect(layerBounds, damageRect:Rect(), rootLayer) and self.hasVisibleContent and self:IsSelfPaintingLayer();
	echo("shouldPaint")
	echo(shouldPaint)
	echo(self:IntersectsDamageRect(layerBounds, damageRect:Rect(), rootLayer))
	echo(self.hasVisibleContent)
	echo(self:IsSelfPaintingLayer())
	--local shouldPaint = true;
    --if (shouldPaint && !selectionOnly && !damageRect.isEmpty() && !paintingOverlayScrollbars) {
	if (shouldPaint and not damageRect:IsEmpty()) then
		self:Renderer():AttachControl()
        -- Begin transparency layers lazily now that we know we have to paint something.
--        if (haveTransparency)
--            beginTransparencyLayers(p, rootLayer, paintBehavior);
        
        -- Paint our background first, before painting any child layers.
        -- Establish the clip used to paint our background.
        self:ClipToRect(rootLayer, p, paintDirtyRect, damageRect, "DoNotIncludeSelfForBorderRadius"); -- Background painting will handle clipping to self.

        -- Paint the background.
        local paintInfo = PaintInfo:new():init(p, damageRect:Rect(), "PaintPhaseBlockBackground", false, paintingRootForRenderer, region);
		echo("self:Renderer():Paint")
		self:Renderer():PrintNodeInfo()
		echo(damageRect:Rect())
        self:Renderer():Paint(paintInfo, paintOffset);

--        // Restore the clip.
--        restoreClip(p, paintDirtyRect, damageRect);
	else
		if(self:IsInClipRect()) then
			self:Renderer():AttachControl()
		else
			self:Renderer():DetachControl()
		end
    end

	-- Now walk the sorted list of children with negative z-indices.
    self:PaintList(self.negZOrderList, rootLayer, p, paintDirtyRect, paintBehavior, paintingRoot, region, overlapTestRequests, localPaintFlags);

	-- Now establish the appropriate clip and paint our child RenderObjects.
	-- now in mcmlv2 we don't distinguish the backround and the foreground, content of the control;

	-- Paint any child layers that have overflow.
    self:PaintList(self.normalFlowList, rootLayer, p, paintDirtyRect, paintBehavior, paintingRoot, region, overlapTestRequests, localPaintFlags);
    
    -- Now walk the sorted list of children with positive z-indices.
    self:PaintList(self.posZOrderList, rootLayer, p, paintDirtyRect, paintBehavior, paintingRoot, region, overlapTestRequests, localPaintFlags);
end

--void RenderLayer::paintList(Vector<RenderLayer*>* list, RenderLayer* rootLayer, GraphicsContext* p,
--                            const LayoutRect& paintDirtyRect, PaintBehavior paintBehavior,
--                            RenderObject* paintingRoot, RenderRegion* region, OverlapTestRequestMap* overlapTestRequests,
--                            PaintLayerFlags paintFlags)
function LayoutLayer:PaintList(list, rootLayer, p, paintDirtyRect, paintBehavior, paintingRoot, region, overlapTestRequests, paintFlags)
	
    if (not list) then
        return;
	end
	echo("LayoutLayer:PaintList")
	self:RenderBox():PrintNodeInfo()
	for i = 1, list:size() do
		local childLayer = list:get(i);
        if (not childLayer:IsPaginated()) then
			--local location = childLayer:RenderBoxLocation()
			--local location = childLayer:Location()
			local offset = childLayer:ConvertToLayerCoords(self, LayoutPoint:new());
			childPaintDirtyRect = paintDirtyRect:clone();
			childPaintDirtyRect:Move(-offset:ToSize())
			echo("childPaintDirtyRect:Move")
			echo(paintDirtyRect)
			--echo(location)
			echo(offset)
			echo(childPaintDirtyRect)
            childLayer:PaintLayer(rootLayer, p, childPaintDirtyRect, paintBehavior, paintingRoot, region, overlapTestRequests, paintFlags);
        else
            self:PaintPaginatedChildLayer(childLayer, rootLayer, p, paintDirtyRect, paintBehavior, paintingRoot, region, overlapTestRequests, paintFlags);
		end
	end
end

--void RenderLayer::paintPaginatedChildLayer(RenderLayer* childLayer, RenderLayer* rootLayer, GraphicsContext* context,
--                                           const LayoutRect& paintDirtyRect, PaintBehavior paintBehavior,
--                                           RenderObject* paintingRoot, RenderRegion* region, OverlapTestRequestMap* overlapTestRequests,
--                                           PaintLayerFlags paintFlags)
function LayoutLayer:PaintPaginatedChildLayer(childLayer, rootLayer, context, paintDirtyRect, paintBehavior, paintingRoot, region, overlapTestRequests, paintFlags)
	
end

--void RenderLayer::calculateClipRects(const RenderLayer* rootLayer, RenderRegion* region, ClipRects& clipRects,
--    bool useCached, OverlayScrollbarSizeRelevancy relevancy) const
function LayoutLayer:CalculateClipRects(rootLayer, region, clipRects, useCached, relevancy)
	echo("LayoutLayer:CalculateClipRects")
	echo(clipRects)
	useCached = if_else(useCached == nil, false, useCached);
	relevancy = if_else(relevancy == nil, "IgnoreOverlayScrollbarSize" , relevancy);

	if (not self:Parent()) then
        -- The root layer's clip rect is always infinite.
        clipRects:Reset(PaintInfo.InfiniteRect());
        return clipRects;
    end

		-- For transformed layers, the root layer was shifted to be us, so there is no need to
    -- examine the parent.  We want to cache clip rects with us as the root.
    local parentLayer = if_else(rootLayer ~= self, self:Parent(), nil);
    
    -- Ensure that our parent's clip has been calculated so that we can examine the values.
    if (parentLayer) then
        if (useCached and parentLayer:ClipRects()) then
            clipRects = parentLayer:ClipRects();
        else
            clipRects = parentLayer:CalculateClipRects(rootLayer, region, clipRects);
		end
    else
        clipRects:Reset(PaintInfo.InfiniteRect());
	end

    -- A fixed object is essentially the root of its containing block hierarchy, so when
    -- we encounter such an object, we reset our clip rects to the fixedClipRect.
    if (self:Renderer():Style():Position() == PositionEnum.FixedPosition) then
        clipRects:SetPosClipRect(clipRects:FixedClipRect());
        clipRects:SetOverflowClipRect(clipRects:FixedClipRect());
        clipRects:SetFixed(true);
    elseif (self:Renderer():Style():Position() == PositionEnum.RelativePosition) then
        clipRects:SetPosClipRect(clipRects:OverflowClipRect());
    elseif (self:Renderer():Style():Position() == PositionEnum.AbsolutePosition) then
        clipRects:SetOverflowClipRect(clipRects:PosClipRect());
    end
    -- Update the clip rects that will be passed to child layers.
    if (self:Renderer():HasOverflowClip() or self:Renderer():HasClip()) then
        -- This layer establishes a clip of some kind.
        local offset = LayoutPoint:new();
        offset = self:ConvertToLayerCoords(rootLayer, offset);
        local view = self:Renderer():View();
        --ASSERT(view);
        if (view and clipRects:Fixed() and rootLayer:Renderer() == view) then
            offset = offset - view:FrameView():ScrollOffsetForFixedPosition();
        end
        
        if (self:Renderer():HasOverflowClip()) then
            local newOverflowClip = ClipRect:new(self:Renderer():ToRenderBox():OverflowClipRect(offset, region, relevancy));
            if (self:Renderer():Style():HasBorderRadius()) then
                newOverflowClip:SetHasRadius(true);
			end
			echo("newOverflowClip")
			echo(newOverflowClip)
			echo(clipRects)
            clipRects:SetOverflowClipRect(ClipRect.Intersection(newOverflowClip, clipRects:OverflowClipRect()));
            if (self:Renderer():IsPositioned() or self:Renderer():IsRelPositioned()) then
                clipRects:SetPosClipRect(ClipRect.Intersection(newOverflowClip, clipRects:PosClipRect()));
			end
        end
		echo("1111111111111111111111")
        if (self:Renderer():HasClip()) then
            local newPosClip = ClipRect:new(self:Renderer():ToRenderBox():ClipRect(offset, region));
            clipRects:SetPosClipRect(Rect.Intersection(newPosClip, clipRects:PosClipRect()));
            clipRects:SetOverflowClipRect(Rect.Intersection(newPosClip, clipRects:OverflowClipRect()));
            clipRects:SetFixedClipRect(Rect.Intersection(newPosClip, clipRects:FixedClipRect()));
        end
    end
	return clipRects;
end

--void RenderLayer::updateClipRects(const RenderLayer* rootLayer, RenderRegion* region, OverlayScrollbarSizeRelevancy relevancy)
function LayoutLayer:UpdateClipRects(rootLayer, region, relevancy)
	relevancy = if_else(relevancy == nil, "IgnoreOverlayScrollbarSize" , relevancy);

    if (self.clipRects) then
        --ASSERT(rootLayer == m_clipRectsRoot);
        return; -- We have the correct cached value.
    end
    
    -- For transformed layers, the root layer was shifted to be us, so there is no need to
    -- examine the parent.  We want to cache clip rects with us as the root.
    local parentLayer = if_else(rootLayer ~= self, self:Parent(), nil);
    if (parentLayer) then
        parentLayer:UpdateClipRects(rootLayer, region, relevancy);
	end

    local clipRects = ClipRects:new();
    clipRects = self:CalculateClipRects(rootLayer, region, clipRects, true, relevancy);

    if (parentLayer and parentLayer:ClipRects() and clipRects == parentLayer:ClipRects()) then
        self.clipRects = parentLayer:ClipRects();
    else
        self.clipRects = clipRects:clone();
	end
    self.clipRects:Ref();
--#ifndef NDEBUG
    self.clipRectsRoot = rootLayer;
--#endif
end

function LayoutLayer:ClipRects()
	return self.clipRects;
end

--void RenderLayer::parentClipRects(const RenderLayer* rootLayer, RenderRegion* region, ClipRects& clipRects, bool temporaryClipRects, OverlayScrollbarSizeRelevancy relevancy) const
function LayoutLayer:ParentClipRects(rootLayer, region, clipRects, temporaryClipRects, relevancy)
	temporaryClipRects = if_else(temporaryClipRects == nil, false, temporaryClipRects);
	relevancy = if_else(relevancy == nil, "IgnoreOverlayScrollbarSize" , relevancy);
    --ASSERT(parent());
    if (temporaryClipRects) then
        clipRects = self:Parent():CalculateClipRects(rootLayer, region, clipRects, false, relevancy);
        return clipRects;
    end

    self:Parent():UpdateClipRects(rootLayer, region, relevancy);
    clipRects = self:Parent():ClipRects();
	return clipRects;
end

--ClipRect RenderLayer::backgroundClipRect(const RenderLayer* rootLayer, RenderRegion* region, bool temporaryClipRects, OverlayScrollbarSizeRelevancy relevancy) const
function LayoutLayer:BackgroundClipRect(rootLayer, region, temporaryClipRects, relevancy)
	relevancy = if_else(relevancy == nil, "IgnoreOverlayScrollbarSize" , relevancy);

    local backgroundRect = ClipRect:new();
    if (self:Parent()) then
        local parentRects = ClipRects:new();
        parentRects = self:ParentClipRects(rootLayer, region, parentRects, temporaryClipRects, relevancy);
        backgroundRect = if_else(self:Renderer():Style():Position() == PositionEnum.FixedPosition, parentRects:FixedClipRect(),
							if_else(self:Renderer():IsPositioned(), parentRects:PosClipRect(), parentRects:OverflowClipRect()));
        local view = self:Renderer():View();
        --ASSERT(view);
        if (view and parentRects:Fixed() and rootLayer:Renderer() == view) then
            --backgroundRect:Move(view:FrameView():ScrollXForFixedPosition(), view:FrameView():ScrollYForFixedPosition());
		end
    end
    return backgroundRect;
end

--static inline bool isPositionedContainer(RenderLayer* layer)
local function isPositionedContainer(layer)
    local o = layer:Renderer();
    return o:IsLayoutView() or o:IsPositioned() or o:IsRelPositioned() or layer:HasTransform();
end

--RenderLayer* RenderLayer::enclosingPositionedAncestor() const
function LayoutLayer:EnclosingPositionedAncestor()
    local curr = self:Parent();
    while (curr and not isPositionedContainer(curr)) do
        curr = curr:Parent();
	end

    return curr;
end

function LayoutLayer:ConvertToLayerCoordsForRect(ancestorLayer, rect)
	local location = LayoutPoint:new();
	location = self:ConvertToLayerCoords(ancestorLayer, location);
	rect:Move(-location:X(), -location:Y());
end

--RenderLayer::convertToLayerCoords(const RenderLayer* ancestorLayer, LayoutPoint& location) const
function LayoutLayer:ConvertToLayerCoords(ancestorLayer, location)
	if(location:IsRect()) then
		self:ConvertToLayerCoordsForRect(ancestorLayer, location);
		return location;
	end


    if (ancestorLayer == self) then
        return location;
	end

    local position = self:Renderer():Style():Position();
    if (position == PositionEnum.FixedPosition and (ancestorLayer == nil or ancestorLayer == self:Renderer():View():Layer())) then
--        // If the fixed layer's container is the root, just add in the offset of the view. We can obtain this by calling
--        // localToAbsolute() on the RenderView.
--        FloatPoint absPos = renderer()->localToAbsolute(FloatPoint(), true);
--        location += flooredLayoutSize(absPos);
--        return;
    end
 
    if (position == PositionEnum.FixedPosition) then
--        // For a fixed layers, we need to walk up to the root to see if there's a fixed position container
--        // (e.g. a transformed layer). It's an error to call convertToLayerCoords() across a layer with a transform,
--        // so we should always find the ancestor at or before we find the fixed position container.
--        RenderLayer* fixedPositionContainerLayer = 0;
--        bool foundAncestor = false;
--        for (RenderLayer* currLayer = parent(); currLayer; currLayer = currLayer->parent()) {
--            if (currLayer == ancestorLayer)
--                foundAncestor = true;
--
--            if (isFixedPositionedContainer(currLayer)) {
--                fixedPositionContainerLayer = currLayer;
--                ASSERT_UNUSED(foundAncestor, foundAncestor);
--                break;
--            }
--        }
--        
--        ASSERT(fixedPositionContainerLayer); // We should have hit the RenderView's layer at least.
--
--        if (fixedPositionContainerLayer != ancestorLayer) {
--            LayoutPoint fixedContainerCoords;
--            convertToLayerCoords(fixedPositionContainerLayer, fixedContainerCoords);
--
--            LayoutPoint ancestorCoords;
--            ancestorLayer->convertToLayerCoords(fixedPositionContainerLayer, ancestorCoords);
--
--            location += (fixedContainerCoords - ancestorCoords);
--            return;
--        }
    end
    
    local parentLayer = nil;
    if (position == PositionEnum.AbsolutePosition or position == PositionEnum.FixedPosition) then
        -- Do what enclosingPositionedAncestor() does, but check for ancestorLayer along the way.
        parentLayer = self:Parent();
        local foundAncestorFirst = false;
        while (parentLayer) do
            if (isPositionedContainer(parentLayer)) then
                break;
			end
            if (parentLayer == ancestorLayer) then
                foundAncestorFirst = true;
                break;
            end

            parentLayer = parentLayer:Parent();
        end

        if (foundAncestorFirst) then
            -- Found ancestorLayer before the abs. positioned container, so compute offset of both relative
            -- to enclosingPositionedAncestor and subtract.
            local positionedAncestor = parentLayer:EnclosingPositionedAncestor();

            local thisCoords = LayoutPoint:new();
            self:ConvertToLayerCoords(positionedAncestor, thisCoords);
            
            local ancestorCoords = LayoutPoint:new();
            ancestorLayer:ConvertToLayerCoords(positionedAncestor, ancestorCoords);

            location = location + (thisCoords - ancestorCoords);
            return location;
        end
    else
        parentLayer = self:Parent();
	end
    
    if (not parentLayer) then
        return location;
	end

    location = parentLayer:ConvertToLayerCoords(ancestorLayer, location);
    location = location + self.topLeft:ToSize();
	return location;
end

--void RenderLayer::calculateRects(const RenderLayer* rootLayer, RenderRegion* region, const LayoutRect& paintDirtyRect, LayoutRect& layerBounds,
--                                 ClipRect& backgroundRect, ClipRect& foregroundRect, ClipRect& outlineRect, bool temporaryClipRects,
--                                 OverlayScrollbarSizeRelevancy relevancy) const
function LayoutLayer:CalculateRects(rootLayer, region, paintDirtyRect, layerBounds, backgroundRect, foregroundRect, outlineRect, temporaryClipRects, relevancy)
	echo("LayoutLayer:CalculateRects")
	echo({region, paintDirtyRect, layerBounds, backgroundRect, foregroundRect, outlineRect, temporaryClipRects, relevancy})
	temporaryClipRects = if_else(temporaryClipRects == nil, false, temporaryClipRects);
	relevancy = if_else(relevancy == nil, "IgnoreOverlayScrollbarSize" , relevancy);

    if (rootLayer ~= self and self:Parent()) then
        backgroundRect = self:BackgroundClipRect(rootLayer, region, true, relevancy);
		echo("backgroundRect")
		echo(backgroundRect)
        backgroundRect:Intersect(paintDirtyRect);
--
--		local tempBackgroundRect = self:BackgroundClipRect(rootLayer, region, true, relevancy)
--		echo("tempBackgroundRect")
--		echo(tempBackgroundRect)
    else
        backgroundRect = ClipRect:new(paintDirtyRect);
	end
	--backgroundRect = ClipRect:new(paintDirtyRect);
	echo("backgroundRect")
	echo(backgroundRect)
    foregroundRect = backgroundRect:clone();
	foregroundRect:Rect():SetLocation(LayoutPoint:new());
    outlineRect = backgroundRect:clone();
    
    local offset = LayoutPoint:new();

--	if(self:Parent()) then
--		local scrollOffset = self:Parent():ScrolledContentOffset();
--		offset = offset - scrollOffset;
--	end

	if (self:Renderer():IsRelPositioned()) then
		--local relativeOffset = self:Renderer():RelativePositionOffset();
		offset:Move(self.relativeOffset);
	end

	
    --offset = self:ConvertToLayerCoords(rootLayer, offset);
    layerBounds = LayoutRect:new(offset, self:Size());
	echo("offset")
	echo(offset)
    -- Update the clip rects that will be passed to child layers.
    if (self:Renderer():HasOverflowClip() or self:Renderer():HasClip()) then
        -- This layer establishes a clip of some kind.
        if (self:Renderer():HasOverflowClip()) then
            foregroundRect:Intersect(self:Renderer():ToRenderBox():OverflowClipRect(offset, region, relevancy));
            if (self:Renderer():Style():HasBorderRadius()) then
                --foregroundRect.setHasRadius(true);
			end
        end

        if (self:Renderer():HasClip()) then
            -- Clip applies to *us* as well, so go ahead and update the damageRect.
            local newPosClip = self:Renderer():ToRenderBox():ClipRect(offset, region);
            backgroundRect:Intersect(newPosClip);
			echo("backgroundRect:Intersect(newPosClip)")
			echo(newPosClip)
			echo(backgroundRect)
            foregroundRect:Intersect(newPosClip);
            outlineRect:Intersect(newPosClip);
        end

        -- If we establish a clip at all, then go ahead and make sure our background
        -- rect is intersected with our layer's bounds including our visual overflow,
        -- since any visual overflow like box-shadow or border-outset is not clipped by overflow:auto/hidden.
        if (self:RenderBox():HasVisualOverflow()) then
            -- FIXME: Does not do the right thing with CSS regions yet, since we don't yet factor in the
            -- individual region boxes as overflow.
            local layerBoundsWithVisualOverflow = self:RenderBox():VisualOverflowRect();
            layerBoundsWithVisualOverflow = self:RenderBox():FlipForWritingMode(layerBoundsWithVisualOverflow); -- Layers are in physical coordinates, so the overflow has to be flipped.
            layerBoundsWithVisualOverflow:MoveBy(offset);
            backgroundRect:Intersect(layerBoundsWithVisualOverflow);
			echo("backgroundRect:Intersect(layerBoundsWithVisualOverflow)")
			echo(layerBoundsWithVisualOverflow)
			echo(backgroundRect)
        else
            -- Shift the bounds to be for our region only.
            local bounds = self:RenderBox():BorderBoxRectInRegion(region);
            bounds:MoveBy(offset);
            backgroundRect:Intersect(bounds);
			echo("backgroundRect:Intersect(bounds)")
			echo(bounds)
			echo(backgroundRect)
        end
    end
	return layerBounds, backgroundRect, foregroundRect, outlineRect;
end

--LayoutPoint RenderLayer::computeOffsetFromRoot(bool& hasLayerOffset) const
function LayoutLayer:ComputeOffsetFromRoot(hasLayerOffset)
    hasLayerOffset = true;

    if (not self:Parent()) then
        return LayoutPoint:new(), hasLayerOffset;
	end

    -- This is similar to root() but we check if an ancestor layer would
    -- prevent the optimization from working.
    local rootLayer = nil;
	local parentLayer = self:Parent();
	while(parentLayer) do
		hasLayerOffset = parentLayer:CanUseConvertToLayerCoords();
        if (not hasLayerOffset) then
            return LayoutPoint:new(), hasLayerOffset;
		end

		rootLayer = parentLayer;
		parentLayer = parentLayer:Parent();
	end

    --ASSERT(rootLayer == root());

    local offset = LayoutPoint:new();
    offset = self:Parent():ConvertToLayerCoords(rootLayer, offset);
    return offset, hasLayerOffset;
end

function LayoutLayer:UpdateLayerPosition()
	echo("LayoutLayer:UpdateLayerPosition begin")
    local localPoint = LayoutPoint:new();
    local inlineBoundingBoxOffset = LayoutSize:new(); -- We don't put this into the RenderLayer x/y for inlines, so we need to subtract it out when done.
    if (self:Renderer():IsLayoutInline()) then
        local inlineFlow = self:Renderer();
        local lineBox = inlineFlow:LinesBoundingBox();
        self:SetSize(lineBox:Size());
        inlineBoundingBoxOffset = lineBox:Location():ToSize();
        localPoint = localPoint + inlineBoundingBoxOffset;
    else
		local box = self:RenderBox()
		if (box) then
			self:SetSize(box:Size());
			localPoint = localPoint + box:TopLeftLocationOffset();
		end
    end
	echo(localPoint)
    -- Clear our cached clip rect information.
    self:ClearClipRects();
 
    if (not self:Renderer():IsPositioned() and self:Renderer():Parent()) then
        -- We must adjust our position by walking up the render tree looking for the
        -- nearest enclosing object with a layer.
        local curr = self:Renderer():Parent();
        while (curr and not curr:HasLayer()) do
            if (curr:IsBox() and not curr:IsTableRow()) then
                -- Rows and cells share the same coordinate space (that of the section).
                -- Omit them when computing our xpos/ypos.
                localPoint = localPoint + curr:TopLeftLocationOffset();
            end
            curr = curr:Parent();
        end
        if (curr:IsBox() and curr:IsTableRow()) then
            -- Put ourselves into the row coordinate space.
            localPoint = localPoint - curr:TopLeftLocationOffset();
        end
    end
    echo(localPoint)
    -- Subtract our parent's scroll offset.
    if (self:Renderer():IsPositioned() and self:EnclosingPositionedAncestor()) then
        local positionedParent = self:EnclosingPositionedAncestor();

        -- For positioned layers, we subtract out the enclosing positioned layer's scroll offset.
        local offset = positionedParent:ScrolledContentOffset();
        localPoint = localPoint - offset;
        
        if (self:Renderer():IsPositioned() and positionedParent:Renderer():IsRelPositioned() and positionedParent:Renderer():IsLayoutInline()) then
            local offset = positionedParent:Renderer():ToRenderInline():RelativePositionedInlineOffset(self:Renderer():ToRenderBox());
            localPoint = localPoint + offset;
        end
    elseif (self:Parent()) then
        if (self:IsComposited()) then
--            // FIXME: Composited layers ignore pagination, so about the best we can do is make sure they're offset into the appropriate column.
--            // They won't split across columns properly.
--            LayoutSize columnOffset;
--            parent()->renderer()->adjustForColumns(columnOffset, localPoint);
--            localPoint += columnOffset;
        end
		echo("scrollOffset")
        local scrollOffset = self:Parent():ScrolledContentOffset();
		echo(scrollOffset)
        localPoint = localPoint - scrollOffset;
    end
    echo(localPoint)  
	echo(self:Renderer():IsRelPositioned())  
    if (self:Renderer():IsRelPositioned()) then
        self.relativeOffset = self:Renderer():RelativePositionOffset();
        localPoint:Move(self.relativeOffset);
    else
        self.relativeOffset = LayoutSize:new();
    end

    -- FIXME: We'd really like to just get rid of the concept of a layer rectangle and rely on the renderers.
    localPoint = localPoint - inlineBoundingBoxOffset;
	echo(self.relativeOffset)
	echo("LayoutLayer:UpdateLayerPosition")
	self:Renderer():PrintNodeInfo()
	echo(self:Renderer():IsPositioned())
	echo(localPoint);
    self:SetLocation(localPoint:X(), localPoint:Y());
end

function LayoutLayer:IsComposited() return false; end

function LayoutLayer:Marquee() 
	return self.marquee;
end

function LayoutLayer:HorizontalScrollbar() return self.hBar; end
function LayoutLayer:VerticalScrollbar() return self.vBar; end

function LayoutLayer:UpdateScrollInfoAfterLayout()
	echo("LayoutLayer:UpdateScrollInfoAfterLayout")
	
	local box = self:RenderBox();
	box:PrintNodeInfo()
    if (box == nil) then
        return;
	end

    self.scrollDimensionsDirty = true;

    local horizontalOverflow, verticalOverflow = self:ComputeScrollDimensions();
	echo("horizontalOverflow, verticalOverflow")
	echo({horizontalOverflow, verticalOverflow})
    if (box:Style():OverflowX() ~= OverflowEnum.OMARQUEE) then
        -- Layout may cause us to be in an invalid scroll position.  In this case we need
        -- to pull our scroll offsets back to the max (or push them up to the min).
        local newX = math.max(0, math.min(self:ScrollXOffset(), self:ScrollWidth() - box:ClientWidth()));
        local newY = math.max(0, math.min(self:ScrollYOffset(), self:ScrollHeight() - box:ClientHeight()));
        if (newX ~= self:ScrollXOffset() or newY ~= self:ScrollYOffset()) then
            --scrollToOffset(newX, newY);
		end
    end

    local haveHorizontalBar = self.hBar ~= nil;
    local haveVerticalBar = self.vBar ~= nil;
	echo("haveHorizontalBar, haveVerticalBar")
    echo({haveHorizontalBar, haveVerticalBar})
    -- overflow:scroll should just enable/disable.
    if (self:Renderer():Style():OverflowX() == OverflowEnum.OSCROLL) then
        self.hBar:SetEnabled(horizontalOverflow);
	end
    if (self:Renderer():Style():OverflowY() == OverflowEnum.OSCROLL) then
        self.vBar:SetEnabled(verticalOverflow);
	end

    -- A dynamic change from a scrolling overflow to overflow:hidden means we need to get rid of any
    -- scrollbars that may be present.
    if (self:Renderer():Style():OverflowX() == OverflowEnum.OHIDDEN and haveHorizontalBar) then
        self:SetHasHorizontalScrollbar(false);
	end
    if (self:Renderer():Style():OverflowY() == OverflowEnum.OHIDDEN and haveVerticalBar)  then
        self:SetHasVerticalScrollbar(false);
	end
    
    -- overflow:auto may need to lay out again if scrollbars got added/removed.
    local scrollbarsChanged = (box:HasAutoHorizontalScrollbar() and haveHorizontalBar ~= horizontalOverflow) or 
                             (box:HasAutoVerticalScrollbar() and haveVerticalBar ~= verticalOverflow);    
    if (scrollbarsChanged) then
        if (box:HasAutoHorizontalScrollbar()) then
            self:SetHasHorizontalScrollbar(horizontalOverflow);
		end
        if (box:HasAutoVerticalScrollbar()) then
            self:SetHasVerticalScrollbar(verticalOverflow);
		end

        self:Renderer():Repaint();

        if (self:Renderer():Style():OverflowX() == OverflowEnum.OAUTO or self:Renderer():Style():OverflowY() == OverflowEnum.OAUTO) then
            if (not self.inOverflowRelayout) then
                -- Our proprietary overflow: overlay value doesn't trigger a layout.
                self.inOverflowRelayout = true;
                self:Renderer():SetNeedsLayout(true, false);
                if (self:Renderer():IsLayoutBlock()) then
                    local block = self:Renderer():ToRenderBlock();
                    block:ScrollbarsChanged(box:HasAutoHorizontalScrollbar() and haveHorizontalBar ~= horizontalOverflow,
                                             box:HasAutoVerticalScrollbar() and haveVerticalBar ~= verticalOverflow);
                    block:LayoutBlock(true); -- FIXME: Need to handle positioned floats triggering extra relayouts.
                else
                    self:Renderer():Layout();
				end
                self.inOverflowRelayout = false;
            end
        end
    end
    
    -- If overflow:scroll is turned into overflow:auto a bar might still be disabled (Bug 11985).
    if (self.hBar and box:HasAutoHorizontalScrollbar()) then
        self.hBar:SetEnabled(true);
	end
    if (self.vBar and box:HasAutoVerticalScrollbar()) then
        self.vBar:SetEnabled(true);
	end

    -- Set up the range (and page step/line step).
    if (self.hBar) then
		
        local clientWidth = box:ClientWidth();
        self.hBar:SetSteps(LayoutScrollbar.PixelsPerLineStep(), clientWidth);
		echo("self.hBar")
		echo(clientWidth)
		echo(self.scrollSize)
        self.hBar:SetProportion(clientWidth, self.scrollSize:Width());
    end
    if (self.vBar) then
        local clientHeight = box:ClientHeight();
        self.vBar:SetSteps(LayoutScrollbar.PixelsPerLineStep(), clientHeight);
		echo("self.vBar")
		echo(clientHeight)
        self.vBar:SetProportion(clientHeight, self.scrollSize:Height());
    end
 
    --scrollToOffset(scrollXOffset(), scrollYOffset());

	if(self.hBar == nil or self.vBar == nil) then
		self:SetHasScrollCorner(false)
	else
		self:SetHasScrollCorner(true)
	end

	if (self:Renderer():Node()) then
        self:UpdateOverflowStatus(horizontalOverflow, verticalOverflow);
	end

	echo(self.scrollSize)
	echo("LayoutLayer:UpdateScrollInfoAfterLayout end")
end

--LayoutUnit RenderLayer::scrollWidth()
function LayoutLayer:ScrollWidth()
    if (self.scrollDimensionsDirty) then
        self:ComputeScrollDimensions();
	end
    return self.scrollSize:Width();
end

--LayoutUnit RenderLayer::scrollHeight()
function LayoutLayer:ScrollHeight()
    if (self.scrollDimensionsDirty) then
        self:ComputeScrollDimensions();
	end
    return self.scrollSize:Height();
end

--LayoutUnit RenderLayer::overflowLeft() const
function LayoutLayer:OverflowLeft()
    local box = self:RenderBox();
    local overflowRect = box:LayoutOverflowRect();
    overflowRect = box:FlipForWritingMode(overflowRect);
    return overflowRect:X();
end

--LayoutUnit RenderLayer::overflowRight() const
function LayoutLayer:OverflowRight()
    local box = self:RenderBox();
    local overflowRect = box:LayoutOverflowRect();
    overflowRect = box:FlipForWritingMode(overflowRect);
    return overflowRect:MaxX();
end

--LayoutUnit RenderLayer::overflowTop() const
function LayoutLayer:OverflowTop()
    local box = self:RenderBox();
    local overflowRect = box:LayoutOverflowRect();
    overflowRect = box:FlipForWritingMode(overflowRect);
    return overflowRect:Y();
end

--LayoutUnit RenderLayer::overflowBottom() const
function LayoutLayer:OverflowBottom()
	echo("LayoutLayer:OverflowBottom")
    local box = self:RenderBox();
    local overflowRect = box:LayoutOverflowRect();
	echo(overflowRect)
    overflowRect = box:FlipForWritingMode(overflowRect);
    return overflowRect:MaxY();
end

function LayoutLayer:ComputeScrollDimensions()
	echo("LayoutLayer:ComputeScrollDimensions")
    local box = self:RenderBox();
	box:PrintNodeInfo();
    --ASSERT(box);
    
    self.scrollDimensionsDirty = false;
	echo("self:Overflow")
	echo({self:OverflowLeft(),self:OverflowRight()})
	echo({self:OverflowTop(),self:OverflowBottom()})
    self.scrollOverflow:SetWidth(self:OverflowLeft() - box:BorderLeft());
    self.scrollOverflow:SetHeight(self:OverflowTop() - box:BorderTop());

    self.scrollSize:SetWidth(self:OverflowRight() - self:OverflowLeft());
    self.scrollSize:SetHeight(self:OverflowBottom() - self:OverflowTop());
    
    self.scrollOrigin = LayoutPoint:new(-self.scrollOverflow:Width(), -self.scrollOverflow:Height());
	echo("self.scrollSize")
	echo(self.scrollSize)
	echo("box:ClientWidth,box:ClientHeight")
	echo({box:ClientWidth(),box:ClientHeight()})
    local needHBar = self.scrollSize:Width() > box:ClientWidth();
	local needVBar = self.scrollSize:Height() > box:ClientHeight();
	return needHBar, needVBar;
end

--int RenderLayer::verticalScrollbarWidth(OverlayScrollbarSizeRelevancy relevancy) const
function LayoutLayer:VerticalScrollbarWidth(relevancy)
--    if (!m_vBar || (m_vBar->isOverlayScrollbar() && relevancy == IgnoreOverlayScrollbarSize))
	if(self.vBar == nil) then
        return 0;
	end
    return self.vBar:Width();
end

--int RenderLayer::horizontalScrollbarHeight(OverlayScrollbarSizeRelevancy relevancy) const
function LayoutLayer:HorizontalScrollbarHeight(relevancy)
    --if (!m_hBar || (m_hBar->isOverlayScrollbar() && relevancy == IgnoreOverlayScrollbarSize))
    if(self.hBar == nil) then
        return 0;
	end
	echo("LayoutLayer:HorizontalScrollbarHeight")
	echo(self.hBar:Height())
    return self.hBar:Height();
end

--PassRefPtr<Scrollbar> RenderLayer::createScrollbar(ScrollbarOrientation orientation)
function LayoutLayer:CreateScrollbar(orientation)
	echo("LayoutLayer:CreateScrollbar")
	local actualRenderer = self:Renderer();
	local scrollbar = LayoutScrollbar:new():init(self, orientation, actualRenderer);
	return scrollbar;
end

--void RenderLayer::destroyScrollbar(ScrollbarOrientation orientation)
function LayoutLayer:DestroyScrollbar(orientation)
	echo("LayoutLayer:DestroyScrollbar")
	local scrollbar = if_else(orientation == "HorizontalScrollbar", self.hBar, self.vBar);
    if (scrollbar) then
--        scrollbar:ClearOwningRenderer();
--        scrollbar:DisconnectFromScrollableArea();
		scrollbar:Destroy();
    end
	if(orientation == "HorizontalScrollbar") then
		self.hBar = nil;
	else
		self.vBar = nil;
	end
end

--void RenderLayer::setHasHorizontalScrollbar(bool hasScrollbar)
function LayoutLayer:SetHasHorizontalScrollbar(hasScrollbar)
    if (hasScrollbar == (self.hBar ~= nil)) then
        return;
	end

    if (hasScrollbar) then
        self.hBar = self:CreateScrollbar("HorizontalScrollbar");
    else
        self:DestroyScrollbar("HorizontalScrollbar");
	end

    -- Destroying or creating one bar can cause our scrollbar corner to come and go.  We need to update the opposite scrollbar's style.
    if (self.hBar) then
        self.hBar:StyleChanged();
	end
    if (self.vBar) then
        self.vBar:StyleChanged();
	end
end

--void RenderLayer::setHasVerticalScrollbar(bool hasScrollbar)
function LayoutLayer:SetHasVerticalScrollbar(hasScrollbar)
    if (hasScrollbar == (self.vBar ~= nil)) then
        return;
	end

    if (hasScrollbar) then
        self.vBar = self:CreateScrollbar("VerticalScrollbar");
    else
        self:DestroyScrollbar("VerticalScrollbar");
	end

    -- Destroying or creating one bar can cause our scrollbar corner to come and go.  We need to update the opposite scrollbar's style.
    if (self.hBar) then
        self.hBar:StyleChanged();
	end
    if (self.vBar) then
        self.vBar:StyleChanged();
	end
end

function LayoutLayer:CreateScrollCorner()
	echo("LayoutLayer:CreateScrollCorner")
	local actualRenderer = self:Renderer();
	local scrollCorner = LayoutScrollCorner:new():init(self, actualRenderer);
	return scrollCorner;
end

function LayoutLayer:DestroyScrollCorner()
    if (self.scrollCorner) then
		self.scrollCorner:Destroy();
		self.scrollCorner = nil;
    end
end

function LayoutLayer:SetHasScrollCorner(hasScrollCorner)
	echo("LayoutLayer:SetHasScrollCorner")
	echo(hasScrollCorner)
	if (hasScrollCorner) then
		if(self.scrollCorner == nil) then
			self.scrollCorner = self:CreateScrollCorner();
		end
    else
        self:DestroyScrollCorner();
	end
end

--static LayoutRect cornerRect(const RenderLayer* layer, const LayoutRect& bounds)
local function cornerRect(layer, bounds)
	echo("cornerRect")
    local horizontalThickness, verticalThickness;
    if (layer:VerticalScrollbar() == nil and layer:HorizontalScrollbar() == nil) then
        -- FIXME: This isn't right.  We need to know the thickness of custom scrollbars
        -- even when they don't exist in order to set the resizer square size properly.
        horizontalThickness = ScrollbarTheme:theme():scrollbarThickness();
        verticalThickness = horizontalThickness;
    elseif (layer:VerticalScrollbar() and layer:HorizontalScrollbar() == nil) then
        horizontalThickness = layer:VerticalScrollbar():Width();
        verticalThickness = horizontalThickness;
    elseif (layer:HorizontalScrollbar() and layer:VerticalScrollbar() == nil) then
        verticalThickness = layer:HorizontalScrollbar():Height();
        horizontalThickness = verticalThickness;
    else
        horizontalThickness = layer:VerticalScrollbar():Width();
        verticalThickness = layer:HorizontalScrollbar():Height();
    end
    return LayoutRect:new(bounds:MaxX() - horizontalThickness - layer:Renderer():Style():BorderRightWidth(), 
                      bounds:MaxY() - verticalThickness - layer:Renderer():Style():BorderBottomWidth(),
                      horizontalThickness, verticalThickness);
end

--LayoutRect RenderLayer::scrollCornerRect() const
function LayoutLayer:ScrollCornerRect()
	echo("LayoutLayer:ScrollCornerRect")
    -- We have a scrollbar corner when a scrollbar is visible and not filling the entire length of the box.
    -- This happens when:
    -- (a) A resizer is present and at least one scrollbar is present
    -- (b) Both scrollbars are present.
    local hasHorizontalBar = self:HorizontalScrollbar() ~= nil;
    local hasVerticalBar = self:VerticalScrollbar() ~= nil;
    local hasResizer = self:Renderer():Style():Resize() ~= ResizeEnum.RESIZE_NONE;
	echo({hasHorizontalBar, hasVerticalBar, hasResizer})
    if ((hasHorizontalBar and hasVerticalBar) or (hasResizer and (hasHorizontalBar or hasVerticalBar))) then
        return cornerRect(self, self:RenderBox():BorderBoxRect());
	end
    return LayoutRect:new();
end

--void RenderLayer::positionOverflowControls(const LayoutSize& offsetFromLayer)
function LayoutLayer:PositionOverflowControls(offsetFromLayer)
    if (not self.hBar and not self.vBar and (not self:Renderer():HasOverflowClip() or self:Renderer():Style():Resize() == ResizeEnum.RESIZE_NONE)) then
        return;
	end
    
    local box = self:RenderBox();
    if (not box) then
        return;
	end
    local borderBox = box:BorderBoxRect();
    local scrollCorner = self:ScrollCornerRect();
    --local absBounds = LayoutRect:new(borderBox:Location() + offsetFromLayer, borderBox:Size());
	local absBounds = borderBox;
	echo("LayoutLayer:PositionOverflowControls");
	echo(offsetFromLayer)
	echo(borderBox);
	echo(scrollCorner)
    if (self.vBar) then
        self.vBar:SetFrameRect(LayoutRect:new(absBounds:MaxX() - box:BorderRight() - self.vBar:Width(),
                                        absBounds:Y() + box:BorderTop(),
                                        self.vBar:Width(),
                                        absBounds:Height() - (box:BorderTop() + box:BorderBottom()) - scrollCorner:Height()));
	end

    if (self.hBar) then
        self.hBar:SetFrameRect(LayoutRect:new(absBounds:X() + box:BorderLeft(),
                                        absBounds:MaxY() - box:BorderBottom() - self.hBar:Height(),
                                        absBounds:Width() - (box:BorderLeft() + box:BorderRight()) - scrollCorner:Width(),
                                        self.hBar:Height()));
	end
    if (self.scrollCorner) then
		echo("self.scrollCorner:SetFrameRect")
        self.scrollCorner:SetFrameRect(scrollCorner);
	end
--    if (self.resizer)
--        self.resizer->setFrameRect(resizerCornerRect(this, borderBox));
end



--void RenderLayer::paintOverflowControls(GraphicsContext* context, const LayoutPoint& paintOffset, const LayoutRect& damageRect, bool paintingOverlayControls)
function LayoutLayer:PaintOverflowControls(context, paintOffset, damageRect, paintingOverlayControls)
    -- Don't do anything if we have no overflow.
    if (not self:Renderer():HasOverflowClip()) then
        return;
	end

    -- This check is required to avoid painting custom CSS scrollbars twice.
    if (paintingOverlayControls and not self:HasOverlayScrollbars()) then
        return;
	end

    local adjustedPaintOffset = paintOffset;
    if (paintingOverlayControls) then
        adjustedPaintOffset = self.cachedOverlayScrollbarOffset;
	end

    -- Move the scrollbar widgets if necessary.  We normally move and resize widgets during layout, but sometimes
    -- widgets can move without layout occurring (most notably when you scroll a document that
    -- contains fixed positioned elements).
    self:PositionOverflowControls(adjustedPaintOffset:ToSize());

    -- Now that we're sure the scrollbars are in the right place, paint them.
    if (self.hBar) then
        --self.hBar:Paint(context, damageRect);
		self.hBar:Paint(context, LayoutPoint:new());
	end
    if (self.vBar) then
        --self.vBar:Paint(context, damageRect);
		self.vBar:Paint(context, LayoutPoint:new());
	end

	echo("LayoutLayer:PaintOverflowControls")
--	if(self.hBar ~= nil or self.vBar ~= nil or (self:Renderer():Style():OverflowY() == OverflowEnum.OHIDDEN or self:Renderer():Style():OverflowX() == OverflowEnum.OHIDDEN)) then
--		self:Renderer()
--	end
	if(self.scrollCorner) then
		self.scrollCorner:Paint(context, LayoutPoint:new());
	end

    -- We fill our scroll corner with white if we have a scrollbar that doesn't run all the way up to the
    -- edge of the box.
    -- paintScrollCorner(context, adjustedPaintOffset, damageRect);
end

--void RenderLayer::setScrollOffset(const LayoutPoint& offset)
function LayoutLayer:SetScrollOffset(offset)
    self:ScrollTo(offset:X(), offset:Y());
end

function LayoutLayer:ScrollToWithNotify(x, y)
	if(self.hBar or self.vBar) then
		if(self.hBar and x) then
			self.hBar:SetValue(x, true);
		end

		if(self.vBar and y) then
			self.vBar:SetValue(y, true);
		end
	else
		self:ScrollTo(x, y)
		local view = self:Renderer():View();
		if(view) then
			local frameview = view:FrameView();
			frameview:PostLayoutRequestEvent();
		end
	end
	
end

--void RenderLayer::scrollTo(LayoutUnit x, LayoutUnit y)
function LayoutLayer:ScrollTo(x, y)
	echo("LayoutLayer:ScrollTo")
	echo(self.scrollOrigin)
	echo(self.scrollOffset)
	echo({x,y})
	x = if_else(x == nil, self.scrollOffset:Width(), x)
	y = if_else(y == nil, self.scrollOffset:Height(), y)
    local box = self:RenderBox();
    if (box == nil) then
        return;
	end

    if (box:Style():OverflowX() ~= OMARQUEE) then
        -- Ensure that the dimensions will be computed if they need to be (for overflow:hidden blocks).
        if (self.scrollDimensionsDirty) then
            self:ComputeScrollDimensions();
		end
    end
    
    -- FIXME: Eventually, we will want to perform a blit.  For now never
    -- blit, since the check for blitting is going to be very
    -- complicated (since it will involve testing whether our layer
    -- is either occluded by another layer or clipped by an enclosing
    -- layer or contains fixed backgrounds, etc.).
    local newScrollOffset = LayoutSize:new(x - self.scrollOrigin:X(), y - self.scrollOrigin:Y());
    if (self.scrollOffset == newScrollOffset) then
        return;
	end
	echo("newScrollOffset")
	echo(newScrollOffset)
    self.scrollOffset = newScrollOffset;

    -- Update the positions of our child layers (if needed as only fixed layers should be impacted by a scroll).
    -- We don't update compositing layers, because we need to do a deep update from the compositing ancestor.
    self:UpdateLayerPositionsAfterScroll();

    local view = self:Renderer():View();

    local repaintContainer = self:Renderer():ContainerForRepaint();

    -- Just schedule a full repaint of our object.
	echo("self.repaintRect")
	echo(self.repaintRect)
    if (view) then
        self:Renderer():RepaintUsingContainer(repaintContainer, self.repaintRect);
	end
end

--void RenderLayer::updateLayerPositionsAfterScroll(bool fixed)
function LayoutLayer:UpdateLayerPositionsAfterScroll(fixed)
	echo("LayoutLayer:UpdateLayerPositionsAfterScroll")
	self:Renderer():PrintNodeInfo()
	fixed = if_else(fixed == nil, false, fixed);
    --ASSERT(!m_visibleContentStatusDirty);

    -- If we have no visible content, there is no point recomputing our rectangles as
    -- they will be empty. If our visibility changes, we are expected to recompute all
    -- our positions anyway.
    if (not self.hasVisibleContent) then
        return;
	end

    self:UpdateLayerPosition();

    if (fixed or self:Renderer():Style():Position() == PositionEnum.FixedPosition) then
        -- FIXME: Is it worth passing the offsetFromRoot around like in updateLayerPositions?
        self:ComputeRepaintRects();
        fixed = true;
    elseif (self:Renderer():HasTransform() and not self:Renderer():IsLayoutView()) then
        -- Transforms act as fixed position containers, so nothing inside a
        -- transformed element can be fixed relative to the viewport if the
        -- transformed element is not fixed itself or child of a fixed element.
        return;
    end


	local child = self:FirstChild();
	while(child) do
		child:UpdateLayerPositionsAfterScroll(fixed);
		child = child:NextSibling();
	end

    -- We don't update our reflection as scrolling is a translation which does not change the size()
    -- of an object, thus RenderReplica will still repaint itself properly as the layer position was
    -- updated above.

    -- if (m_marquee)
    --     m_marquee->updateMarqueePosition();
end

--bool canUseConvertToLayerCoords() const
function LayoutLayer:CanUseConvertToLayerCoords()
    -- These RenderObject have an impact on their layers' without them knowing about it.
    return not self:Renderer():HasColumns() and not self:Renderer():HasTransform() and not self:IsComposited()
end

--const RenderLayer* root() const
function LayoutLayer:Root()
    local curr = self;
    while (curr:Parent()) do
        curr = curr:Parent();
	end
    return curr;
end

--void RenderLayer::updateOverflowStatus(bool horizontalOverflow, bool verticalOverflow)
function LayoutLayer:UpdateOverflowStatus(horizontalOverflow, verticalOverflow)
    if (self.overflowStatusDirty) then
        self.horizontalOverflow = horizontalOverflow;
        self.verticalOverflow = verticalOverflow;
        self.overflowStatusDirty = false;
        return;
    end
    
    local horizontalOverflowChanged = (self.horizontalOverflow ~= horizontalOverflow);
    local verticalOverflowChanged = (self.verticalOverflow ~= verticalOverflow);
    
    if (horizontalOverflowChanged or verticalOverflowChanged) then
        self.horizontalOverflow = horizontalOverflow;
        self.verticalOverflow = verticalOverflow;
        
--        if (FrameView* frameView = renderer()->document()->view()) {
--            frameView->scheduleEvent(OverflowEvent::create(horizontalOverflowChanged, horizontalOverflow, verticalOverflowChanged, verticalOverflow),
--                renderer()->node());
--        end
    end
end

--LayoutRect RenderLayer::localBoundingBox() const
function LayoutLayer:LocalBoundingBox()
    -- There are three special cases we need to consider.
    -- (1) Inline Flows.  For inline flows we will create a bounding box that fully encompasses all of the lines occupied by the
    -- inline.  In other words, if some <span> wraps to three lines, we'll create a bounding box that fully encloses the
    -- line boxes of all three lines (including overflow on those lines).
    -- (2) Left/Top Overflow.  The width/height of layers already includes right/bottom overflow.  However, in the case of left/top
    -- overflow, we have to create a bounding box that will extend to include this overflow.
    -- (3) Floats.  When a layer has overhanging floats that it paints, we need to make sure to include these overhanging floats
    -- as part of our bounding box.  We do this because we are the responsible layer for both hit testing and painting those
    -- floats.
    local result;
    if (self:Renderer():IsLayoutInline()) then
        result = self:Renderer():ToRenderInline():LinesVisualOverflowBoundingBox();
    elseif (self:Renderer():IsTableRow()) then
        -- Our bounding box is just the union of all of our cells' border/overflow rects.
--        for (RenderObject* child = self:Renderer()->firstChild(); child; child = child->nextSibling()) then
--            if (child->isTableCell()) then
--                LayoutRect bbox = toRenderBox(child)->borderBoxRect();
--                result.unite(bbox);
--                LayoutRect overflowRect = renderBox()->visualOverflowRect();
--                if (bbox != overflowRect)
--                    result.unite(overflowRect);
--            end
--        end
    else
        local box = self:RenderBox();
        -- ASSERT(box);
        if (box:HasMask()) then
            -- result = box->maskClipRect();
            -- box->flipForWritingMode(result); -- The mask clip rect is in physical coordinates, so we have to flip, since localBoundingBox is not.
        else
            local bbox = box:BorderBoxRect();
            result = bbox;
            local overflowRect = box:VisualOverflowRect();
            if (bbox ~= overflowRect) then
                result:Unite(overflowRect);
			end
        end
    end

    local view = self:Renderer():View();
    -- ASSERT(view);
    if (view) then
        result:Inflate(view:MaximalOutlineSize()); -- Used to apply a fudge factor to dirty-rect checks on blocks/tables.
	end
    return result;
end

--LayoutRect RenderLayer::boundingBox(const RenderLayer* ancestorLayer) const
function LayoutLayer:BoundingBox(ancestorLayer)
    local result = self:LocalBoundingBox();
    if (self:Renderer():IsBox()) then
        result = self:RenderBox():FlipForWritingMode(result);
    else
        result = self:Renderer():ContainingBlock():FlipForWritingMode(result);
	end
    local delta = LayoutPoint:new();
    delta = self:ConvertToLayerCoords(ancestorLayer, delta);
    result:MoveBy(delta);
    return result;
end

--LayoutRect RenderLayer::absoluteBoundingBox() const
function LayoutLayer:AbsoluteBoundingBox()
    return self:BoundingBox(self:Root());
end

--void RenderLayer::repaintIncludingDescendants()
function LayoutLayer:RepaintIncludingDescendants()
    self:Renderer():Repaint();
	local curr = self:FirstChild();
	while(curr) do
		curr:RepaintIncludingDescendants();
		curr = curr:NextSibling();
	end
end

--static inline const RenderLayer* compositingContainer(const RenderLayer* layer)
local function compositingContainer(layer)
    return if_else(layer:IsNormalFlowOnly(), layer:Parent(), layer:StackingContext());
end

--RenderLayer* RenderLayer::clippingRoot() const
function LayoutLayer:ClippingRoot()
    local current = self;
    while (current) do
        if (current:Renderer():IsLayoutView()) then
            return current;
		end

        current = compositingContainer(current);
        --ASSERT(current);
        if (current:Transform()) then
            return current;
		end
    end
    return nil;
end

---- Returns the foreground clip rect of the layer in the document's coordinate space.
--LayoutRect childrenClipRect() const; 
---- Returns the background clip rect of the layer in the document's coordinate space.
--LayoutRect selfClipRect() const; 