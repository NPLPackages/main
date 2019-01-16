--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: this is layout object of the "pe:mcml" node.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutView.lua");
local LayoutView = commonlib.gettable("System.Windows.mcml.layout.LayoutView");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlock.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutState.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
local Size = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local LayoutState = commonlib.gettable("System.Windows.mcml.layout.LayoutState");
local LayoutView = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBlock"), commonlib.gettable("System.Windows.mcml.layout.LayoutView"));

local LayoutSize = Size;

function LayoutView:ctor()
	self.name = "LayoutView";

	self.frameView = nil;
	self.pageLogicalHeight = 0;
	self.pageLogicalHeightChanged = false;

	self.layoutState = nil;

	self.maximalOutlineSize = 0;

	self.layoutStateDisableCount = 0
end

function LayoutView:init(node, frameView)
	LayoutView._super.init(self, node);

	-- Clear our anonymous bit, set because RenderObject assumes
    -- any renderer with document as the node is anonymous.
    self:SetIsAnonymous(false);

    -- init RenderObject attributes
    self:SetInline(false);
    self.minPreferredLogicalWidth = 0;
    self.maxPreferredLogicalWidth = 0;

    self:SetPreferredLogicalWidthsDirty(true, false);
    
    self:SetPositioned(true); -- to 0,0 :)

	self.frameView = frameView;

	return self;
end

function LayoutView:GetName()
	return "LayoutView";
end

function LayoutView:IsLayoutView()
	return true;
end

function LayoutView:IsRoot()
	return true;
end

function LayoutView:RequiresLayer()
	return true;
end

function LayoutView:FrameView()
	return self.frameView;
end

function LayoutView:SetPageLayout(pageLayout)
	self.frameView = pageLayout;
end

function LayoutView:ViewWidth()
	if(self.frameView) then
		return self.frameView:LayoutWidth()
	end
end

function LayoutView:ViewHeight()
	if(self.frameView) then
		return self.frameView:LayoutHeight()
	end
end

function LayoutView:ViewLogicalWidth()
	return if_else(self:Style():IsHorizontalWritingMode(), self:ViewWidth(), self:ViewHeight());
end

function LayoutView:ViewLogicalHeight()
	return if_else(self:Style():IsHorizontalWritingMode(), self:ViewHeight(), self:ViewWidth());
end

function LayoutView:ComputeLogicalHeight()
    if (self.frameView) then
        self:SetLogicalHeight(self:ViewLogicalHeight());
	end
end

function LayoutView:ComputeLogicalWidth()
    if (self.frameView) then
        self:SetLogicalWidth(self:ViewLogicalWidth());
	end
end

function LayoutView:ComputePreferredLogicalWidths()
    --preferredLogicalWidthsDirty());

    LayoutView._super.ComputePreferredLogicalWidths(self);

    self.maxPreferredLogicalWidth = self.minPreferredLogicalWidth;
end


function LayoutView:Layout()
--    if (!document()->paginated())
--        setPageLogicalHeight(0);

--    if (printing())
--        m_minPreferredLogicalWidth = m_maxPreferredLogicalWidth = logicalWidth();

    -- Use calcWidth/Height to get the new width/height, since this will take the full page zoom factor into account.
    local relayoutChildren = self:Width() ~= self:ViewWidth() or self:Height() ~= self:ViewHeight();
    if (relayoutChildren) then
        self:SetChildNeedsLayout(true, false);
		local child = self:FirstChild();
		while(child) do
			--if (Length.IsPercent(child:Style():LogicalHeight()) or Length.IsPercent(child:Style():LogicalMinHeight()) or Length.IsPercent(child:Style():LogicalMaxHeight())) then
			if (child:Style():LogicalHeight():IsPercent() or child:Style():LogicalMinHeight():IsPercent() or child:Style():LogicalMaxHeight():IsPercent()) then
                child:SetChildNeedsLayout(true, false);
			end
			child = child:NextSibling();
		end
    end

    local state = LayoutState:new();
    -- FIXME: May be better to push a clip and avoid issuing offscreen repaints.
    state.clipped = false;
    state.pageLogicalHeight = self.pageLogicalHeight;
    state.pageLogicalHeightChanged = self.pageLogicalHeightChanged;
    state.isPaginated = if_else(state.pageLogicalHeight ~= 0, true, false);
    self.pageLogicalHeightChanged = false;
    self.layoutState = state;
    if (self:NeedsLayout()) then
        LayoutView._super.Layout(self);
--        if (self:HasRenderFlowThreads()) then
--            self:LayoutRenderFlowThreads();
--		end
    end

	self.layoutState = nil;
    self:SetNeedsLayout(false);
end

-- layoutDelta is used transiently during layout to store how far an object has moved from its
-- last layout location, in order to repaint correctly.
-- If we're doing a full repaint m_layoutState will be 0, but in that case layoutDelta doesn't matter.
function LayoutView:LayoutDelta()
	if(self.layoutState) then
		return self.layoutState.layoutDelta;
	end
    return LayoutSize:new();
end

function LayoutView:AddLayoutDelta(delta) 
    if (self.layoutState) then
        self.layoutState.layoutDelta = self.layoutState.layoutDelta + delta;
	end
end

function LayoutView:MaximalOutlineSize()
	return self.maximalOutlineSize;
end

--void RenderView::computeRectForRepaint(RenderBoxModelObject* repaintContainer, IntRect& rect, bool fixed) const
function LayoutView:ComputeRectForRepaint(repaintContainer, rect, fixed)
	-- parameter default value;
	fixed = if_else(fixed == nil, false, fixed);

    -- If a container was specified, and was not 0 or the RenderView,
    -- then we should have found it by now.
    --ASSERT_ARG(repaintContainer, !repaintContainer || repaintContainer == this);

--    if (printing())
--        return;

    if (self:Style():IsFlippedBlocksWritingMode()) then
        -- We have to flip by hand since the view's logical height has not been determined.  We
        -- can use the viewport width and height.
        if (self:Style():IsHorizontalWritingMode()) then
            rect:SetY(self:ViewHeight() - rect:MaxY());
        else
            rect:SetX(self:ViewWidth() - rect:MaxX());
		end
    end

	-- in normal conditions, fixed is "false"
    if (fixed and self.frameView) then
        --rect.move(m_frameView->scrollXForFixedPosition(), m_frameView->scrollYForFixedPosition());
	end
        
    -- Apply our transform if we have one (because of full page zooming).
    if (repaintContainer == nil and self.layer ~= nil and self.layer:Transform() ~= nil) then
        --rect = m_layer->transform()->mapRect(rect);
	end
	return rect;
end

--bool RenderView::shouldRepaint(const IntRect& r) const
function LayoutView:ShouldRepaint(rect)
    if (rect:Width() == 0 or rect:Height() == 0) then
        return false;
	end

    if (not self.frameView) then
        return false;
	end
    
    return true;
end

--void RenderView::repaintViewRectangle(const IntRect& ur, bool immediate)
function LayoutView:RepaintViewRectangle(ur, immediate)
	-- parameter default value;
	immediate = if_else(immediate == nil, false, immediate);
	echo("LayoutView:RepaintViewRectangle")
	echo(ur)
    if (not self:ShouldRepaint(ur)) then
        return;
	end
	
	self.frameView:RepaintContentRectangle(ur, immediate);

--    // We always just invalidate the root view, since we could be an iframe that is clipped out
--    // or even invisible.
--    Element* elt = document()->ownerElement();
--    if (!elt)
--        m_frameView->repaintContentRectangle(ur, immediate);
--    else if (RenderBox* obj = elt->renderBox()) {
--        IntRect vr = viewRect();
--        IntRect r = intersection(ur, vr);
--        
--        // Subtract out the contentsX and contentsY offsets to get our coords within the viewing
--        // rectangle.
--        r.moveBy(-vr.location());
--        
--        // FIXME: Hardcoded offsets here are not good.
--        r.move(obj->borderLeft() + obj->paddingLeft(),
--               obj->borderTop() + obj->paddingTop());
--        obj->repaintRectangle(r, immediate);
--    }
end

function LayoutView:LayoutState()
	return self.layoutState;
end

function LayoutView:DoingFullRepaint()
	return self.frameView:NeedsFullRepaint();
end

function LayoutView:LayoutStateEnabled() 
	return self.layoutStateDisableCount == 0 and self.layoutState ~= nil;
end

--IntRect RenderView::unscaledDocumentRect() const
function LayoutView:UnscaledDocumentRect()
    local overflowRect = self:LayoutOverflowRect();
    overflowRect = self:FlipForWritingMode(overflowRect);
    return overflowRect;
end

--IntRect RenderView::documentRect() const
function LayoutView:DocumentRect()
    local overflowRect = self:UnscaledDocumentRect();
    if (self:HasTransform()) then
        --overflowRect = layer()->currentTransform().mapRect(overflowRect);
	end
    return overflowRect;
end