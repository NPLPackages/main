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
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local PaintInfo = commonlib.gettable("System.Windows.mcml.layout.PaintInfo");
local LayoutPoint = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");
local LayoutSize = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local LayoutRect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");

local LayoutLayer = commonlib.inherit(commonlib.gettable("System.Windows.mcml.platform.ScrollableArea"), commonlib.gettable("System.Windows.mcml.layout.LayoutLayer"));


local VisibilityEnum = ComputedStyleConstants.VisibilityEnum;
local PositionEnum = ComputedStyleConstants.PositionEnum;
local OverflowEnum = ComputedStyleConstants.OverflowEnum;
local MarqueeBehaviorEnum = ComputedStyleConstants.MarqueeBehaviorEnum;

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
	self.renderer = renderer;

	self.isNormalFlowOnly = self:ShouldBeNormalFlowOnly();

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
	
	self:UpdateLayerPosition();

	local child = self:FirstChild();
	while(child) do
		child:UpdateLayerPositions(offsetFromRoot, flags);
		child = child:NextSibling()
	end
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
    --ASSERT(!m_visibleContentStatusDirty);

    local repaintContainer = self:Renderer():ContainerForRepaint();
    self.repaintRect = self:Renderer():ClippedOverflowRectForRepaint(repaintContainer);
    self.outlineBox = self:Renderer():OutlineBoundsForRepaint(repaintContainer, offsetFromRoot);
end

function LayoutLayer:SetHasVisibleContent(b)
    if (self.hasVisibleContent == b and not self.visibleContentStatusDirty) then
        return;
	end
    self.visibleContentStatusDirty = false; 
    self.hasVisibleContent = b;
    if (self.hasVisibleContent) then
--        self:ComputeRepaintRects();
--        if (not self:IsNormalFlowOnly()) then
--            for (RenderLayer* sc = stackingContext(); sc; sc = sc->stackingContext()) {
--                sc->dirtyZOrderLists();
--                if (sc->hasVisibleContent())
--                    break;
--            }
--        end
    end
    if (self:Parent()) then
        self:Parent():ChildVisibilityChanged(m_hasVisibleContent);
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
    if (not self.normalFlowListDirty) then
        return;
	end
        
	local child = self:FirstChild();
	while(child) do
		-- Ignore non-overflow layers and reflections.
		if (child:IsNormalFlowOnly() and (not self.reflection or self:ReflectionLayer() ~= child)) then
            if (not self.normalFlowList) then
                self.normalFlowList = new commonlib.vector:new();
			end
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
	return true;
end

function LayoutLayer:ZIndex()
	--int zIndex() const { return renderer()->style()->zIndex(); }
	return self:Renderer():Style():ZIndex();
end

--void RenderLayer::collectLayers(Vector<RenderLayer*>*& posBuffer, Vector<RenderLayer*>*& negBuffer)
function LayoutLayer:CollectLayers(posBuffer, negBuffer)
    self:UpdateVisibilityStatus();

    -- Overflow layers are just painted by their enclosing layers, so they don't get put in zorder lists.
    if ((self.hasVisibleContent or (self.hasVisibleDescendant and self:IsStackingContext())) and self:IsNormalFlowOnly() == false and self:Renderer():IsLayoutFlowThread() == false) then
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
                child:CollectLayers(posBuffer, negBuffer);
			end

			child = child:NextSibling();
		end
	end
	return posBuffer, negBuffer;
end

--void RenderLayer::updateZOrderLists()
function LayoutLayer:UpdateZOrderLists()
--    if (!isStackingContext() || !m_zOrderListsDirty)
--        return;

	local child = self:FirstChild();
	while(child) do
		if (not self.reflection or self:ReflectionLayer() ~= child) then
            self.posZOrderList, self.negZOrderList = child:CollectLayers(self.posZOrderList, self.negZOrderList);
		end

		child = child:NextSibling();
	end

--    // Sort the two lists.
--    if (m_posZOrderList)
--        std::stable_sort(m_posZOrderList->begin(), m_posZOrderList->end(), compareZIndex);
--
--    if (m_negZOrderList)
--        std::stable_sort(m_negZOrderList->begin(), m_negZOrderList->end(), compareZIndex);

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

	return false;

--    // If we aren't an inline flow, and our layer bounds do intersect the damage rect, then we 
--    // can go ahead and return true.
--    RenderView* view = renderer()->view();
--    ASSERT(view);
--    if (view && !renderer()->isRenderInline()) {
--        LayoutRect b = layerBounds;
--        b.inflate(view->maximalOutlineSize());
--        if (b.intersects(damageRect))
--            return true;
--    }
--        
--    // Otherwise we need to compute the bounding box of this single layer and see if it intersects
--    // the damage rect.
--    return boundingBox(rootLayer).intersects(damageRect);
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
	paintDirtyRect, layerBounds, damageRect, clipRectToApply, outlineRect = self:CalculateRects(rootLayer, region, paintDirtyRect, layerBounds, damageRect, clipRectToApply, outlineRect, localPaintFlags);
    local paintOffset = (layerBounds:Location() - self:RenderBoxLocation()):ToPoint();

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
    --local shouldPaint = self:IntersectsDamageRect(layerBounds, damageRect.rect(), rootLayer) && m_hasVisibleContent && isSelfPaintingLayer();
	local shouldPaint = true;
    --if (shouldPaint && !selectionOnly && !damageRect.isEmpty() && !paintingOverlayScrollbars) {
	if (shouldPaint and not damageRect:IsEmpty()) then
        -- Begin transparency layers lazily now that we know we have to paint something.
--        if (haveTransparency)
--            beginTransparencyLayers(p, rootLayer, paintBehavior);
        
        -- Paint our background first, before painting any child layers.
        -- Establish the clip used to paint our background.
        self:ClipToRect(rootLayer, p, paintDirtyRect, damageRect, "DoNotIncludeSelfForBorderRadius"); -- Background painting will handle clipping to self.

        -- Paint the background.
        local paintInfo = PaintInfo:new():init(p, damageRect:Rect(), "PaintPhaseBlockBackground", false, paintingRootForRenderer, region);
        self:Renderer():Paint(paintInfo, paintOffset);

--        // Restore the clip.
--        restoreClip(p, paintDirtyRect, damageRect);
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

	for i = 1, list:size() do
		local childLayer = list:get(i);
        if (not childLayer:IsPaginated()) then
            childLayer:PaintLayer(rootLayer, p, paintDirtyRect, paintBehavior, paintingRoot, region, overlapTestRequests, paintFlags);
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
	useCached = if_else(useCached == nil, false, useCached);
	relevancy = if_else(relevancy == nil, "IgnoreOverlayScrollbarSize" , relevancy);

	if (not self:Parent()) then
        -- The root layer's clip rect is always infinite.
        clipRects:Reset(PaintInfo.InfiniteRect());
        return;
    end

	-- TODO: add later
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
    self:CalculateClipRects(rootLayer, region, clipRects, true, relevancy);

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
        self:Parent():CalculateClipRects(rootLayer, region, clipRects, false, relevancy);
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

    parentLayer:ConvertToLayerCoords(ancestorLayer, location);
    location = location + self.topLeft:ToSize();
	return location;
end

--void RenderLayer::calculateRects(const RenderLayer* rootLayer, RenderRegion* region, const LayoutRect& paintDirtyRect, LayoutRect& layerBounds,
--                                 ClipRect& backgroundRect, ClipRect& foregroundRect, ClipRect& outlineRect, bool temporaryClipRects,
--                                 OverlayScrollbarSizeRelevancy relevancy) const
function LayoutLayer:CalculateRects(rootLayer, region, paintDirtyRect, layerBounds, backgroundRect, foregroundRect, outlineRect, temporaryClipRects, relevancy)
	temporaryClipRects = if_else(temporaryClipRects == nil, false, temporaryClipRects);
	OverlayScrollbarSizeRelevancy = if_else(OverlayScrollbarSizeRelevancy == nil, "IgnoreOverlayScrollbarSize" , OverlayScrollbarSizeRelevancy);

    if (rootLayer ~= self and self:Parent()) then
        backgroundRect = self:BackgroundClipRect(rootLayer, region, temporaryClipRects, relevancy);
        backgroundRect:Intersect(paintDirtyRect);
    else
        backgroundRect = ClipRect:new(paintDirtyRect);
	end

    foregroundRect = backgroundRect:clone();
    outlineRect = backgroundRect:clone();
    
    local offset = LayoutPoint:new();
    offset = self:ConvertToLayerCoords(rootLayer, offset);
    layerBounds = LayoutRect:new(offset, self:Size());

    -- Update the clip rects that will be passed to child layers.
    if (self:Renderer():HasOverflowClip() or self:Renderer():HasClip()) then
--        // This layer establishes a clip of some kind.
--        if (renderer()->hasOverflowClip()) {
--            foregroundRect.intersect(toRenderBox(renderer())->overflowClipRect(offset, region, relevancy));
--            if (renderer()->style()->hasBorderRadius())
--                foregroundRect.setHasRadius(true);
--        }
--
--        if (renderer()->hasClip()) {
--            // Clip applies to *us* as well, so go ahead and update the damageRect.
--            LayoutRect newPosClip = toRenderBox(renderer())->clipRect(offset, region);
--            backgroundRect.intersect(newPosClip);
--            foregroundRect.intersect(newPosClip);
--            outlineRect.intersect(newPosClip);
--        }
--
--        // If we establish a clip at all, then go ahead and make sure our background
--        // rect is intersected with our layer's bounds including our visual overflow,
--        // since any visual overflow like box-shadow or border-outset is not clipped by overflow:auto/hidden.
--        if (renderBox()->hasVisualOverflow()) {
--            // FIXME: Does not do the right thing with CSS regions yet, since we don't yet factor in the
--            // individual region boxes as overflow.
--            LayoutRect layerBoundsWithVisualOverflow = renderBox()->visualOverflowRect();
--            renderBox()->flipForWritingMode(layerBoundsWithVisualOverflow); // Layers are in physical coordinates, so the overflow has to be flipped.
--            layerBoundsWithVisualOverflow.moveBy(offset);
--            backgroundRect.intersect(layerBoundsWithVisualOverflow);
--        } else {
--            // Shift the bounds to be for our region only.
--            LayoutRect bounds = renderBox()->borderBoxRectInRegion(region);
--            bounds.moveBy(offset);
--            backgroundRect.intersect(bounds);
--        }
    end
	return paintDirtyRect, layerBounds, backgroundRect, foregroundRect, outlineRect;
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
    local localPoint = LayoutPoint:new();
    local inlineBoundingBoxOffset = LayoutSize:new(); -- We don't put this into the RenderLayer x/y for inlines, so we need to subtract it out when done.
    if (self:Renderer():IsLayoutInline()) then
--        local inlineFlow = self:Renderer();
--        local lineBox = inlineFlow:LinesBoundingBox();
--        setSize(lineBox.size());
--        inlineBoundingBoxOffset = toSize(lineBox.location());
--        localPoint += inlineBoundingBoxOffset;
    else
--		local box = self:RenderBox()
--		if (box) then
--			self:SetSize(box:Size());
--			localPoint = localPoint + box:TopLeftLocationOffset();
--		end
    end

    -- Clear our cached clip rect information.
    self:ClearClipRects();
 
--    if (not self:Renderer():IsPositioned() and self:Renderer():Parent()) then
--        -- We must adjust our position by walking up the render tree looking for the
--        -- nearest enclosing object with a layer.
--        local curr = self:Renderer():Parent();
--        while (curr and not curr:HasLayer()) do
--            if (curr:IsBox() and not curr:IsTableRow()) then
--                -- Rows and cells share the same coordinate space (that of the section).
--                -- Omit them when computing our xpos/ypos.
--                localPoint = localPoint + curr:TopLeftLocationOffset();
--            end
--            curr = curr:Parent();
--        end
--        if (curr:IsBox() and curr:IsTableRow()) then
--            -- Put ourselves into the row coordinate space.
--            localPoint = localPoint - curr:TopLeftLocationOffset();
--        end
--    end
    
    -- Subtract our parent's scroll offset.
    if (self:Renderer():IsPositioned() and self:EnclosingPositionedAncestor()) then
        local positionedParent = self:EnclosingPositionedAncestor();

        -- For positioned layers, we subtract out the enclosing positioned layer's scroll offset.
        local offset = positionedParent:ScrolledContentOffset();
        localPoint = localPoint - offset;
        
        if (self:Renderer():IsPositioned() and positionedParent:Renderer():IsRelPositioned() and positionedParent:Renderer():IsLayoutInline()) then
--            LayoutSize offset = toRenderInline(positionedParent->renderer())->relativePositionedInlineOffset(toRenderBox(renderer()));
--            localPoint += offset;
        end
    elseif (self:Parent()) then
        if (self:IsComposited()) then
--            // FIXME: Composited layers ignore pagination, so about the best we can do is make sure they're offset into the appropriate column.
--            // They won't split across columns properly.
--            LayoutSize columnOffset;
--            parent()->renderer()->adjustForColumns(columnOffset, localPoint);
--            localPoint += columnOffset;
        end

        local scrollOffset = self:Parent():ScrolledContentOffset();
        localPoint = localPoint - scrollOffset;
    end
        
    if (self:Renderer():IsRelPositioned()) then
        self.relativeOffset = self:Renderer():RelativePositionOffset();
        localPoint:Move(self.relativeOffset);
    else
        self.relativeOffset = LayoutSize:new();
    end

    -- FIXME: We'd really like to just get rid of the concept of a layer rectangle and rely on the renderers.
    localPoint = localPoint - inlineBoundingBoxOffset;
    self:SetLocation(localPoint:X(), localPoint:Y());
end

function LayoutLayer:IsComposited() return false; end