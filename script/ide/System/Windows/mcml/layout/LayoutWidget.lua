--[[
Title: 
Author(s): LiPeng
Date: 2019/3/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutWidget.lua");
local LayoutWidget = commonlib.gettable("System.Windows.mcml.layout.LayoutWidget");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutReplaced.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntPoint.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/PaintPhase.lua");
local PaintPhase = commonlib.gettable("System.Windows.mcml.layout.PaintPhase");
local LayoutPoint = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");
local LayoutWidget = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutReplaced"), commonlib.gettable("System.Windows.mcml.layout.LayoutWidget"));

function LayoutWidget:ctor()
	self.m_frameView = nil;
	self.m_widget = nil;
end

function LayoutWidget:init(node)
	LayoutWidget._super.init(self, node);

	self.m_frameView = node:Document():View();
	self:View():AddWidget(self);

	return self;
end

function LayoutWidget:Destroy()
	LayoutWidget._super.Destroy(self);
	self:SetNode(nil);
end

function LayoutWidget:WillBeDestroyed()
    if (self:View()) then
        self:View():RemoveWidget(self);
	end
    
--    if (AXObjectCache::accessibilityEnabled()) {
--        document()->axObjectCache()->childrenChanged(this->parent());
--        document()->axObjectCache()->remove(this);
--    }

    self:SetWidget(nil);

    LayoutWidget._super.WillBeDestroyed(self);
end

function LayoutWidget:IsWidget() 
	return true;
end

function LayoutWidget:Widget() 
	return self.m_widget;
end

--static void moveWidgetToParentSoon(Widget* child, FrameView* parent)
local function moveWidgetToParentSoon(child, parent)
	if (parent) then
        parent:AddChild(child);
    else
        child:RemoveFromParent();
    end
end

function LayoutWidget:SetWidget(widget) 
	if (widget == self.m_widget) then
        return;
	end
	if(self.m_widget) then
		moveWidgetToParentSoon(self.m_widget, nil);
		self:ClearWidget();
	end
	self.m_widget = widget;
	if(self.m_widget) then
		if (not self:NeedsLayout()) then
            local contentBox = self:ContentBoxRect();
            --IntRect absoluteContentBox = IntRect(localToAbsoluteQuad(FloatQuad(contentBox)).boundingBox());
			self:SetWidgetGeometry(contentBox);
--                if (m_widget->isFrameView()) {
--                    contentBox.setLocation(absoluteContentBox.location());
--                    setWidgetGeometry(contentBox);
--                } else
--                    setWidgetGeometry(absoluteContentBox);
        end
		moveWidgetToParentSoon(self.m_widget, self.m_frameView);
	end
end

function LayoutWidget:ClearWidget()
    self.m_widget = nil;
end

function LayoutWidget:GetName()
	return "LayoutWidget";
end

function LayoutWidget:Layout()
    --ASSERT(needsLayout());

    self:SetNeedsLayout(false);
end

--bool RenderWidget::setWidgetGeometry(const IntRect& frame)
function LayoutWidget:SetWidgetGeometry(frame)
    if (not self:Node()) then
        return false;
	end

    --IntRect clipRect = enclosingLayer()->childrenClipRect();
    --bool clipChanged = m_clipRect != clipRect;
    local boundsChanged = self.m_widget:FrameRect() ~= frame;

    --if (!boundsChanged && !clipChanged)
	if (not boundsChanged) then
        return false;
	end

    --m_clipRect = clipRect;

--    RenderWidgetProtector protector(this);
--    RefPtr<Node> protectedNode(node());
    self.m_widget:SetFrameRect(frame);
    
--#if USE(ACCELERATED_COMPOSITING)
--    if (hasLayer() && layer()->isComposited())
--        layer()->backing()->updateAfterWidgetResize();
--#endif
    
    return boundsChanged;
end

function LayoutWidget:UpdateWidgetPosition()
    if (not self.m_widget or not self:Node()) then -- Check the node in case destroy() has been called.
        return;
	end
    local contentBox = self:ContentBoxRect();
	local boundsChanged = self:SetWidgetGeometry(contentBox);

--    local absoluteContentBox = IntRect(localToAbsoluteQuad(FloatQuad(contentBox)).boundingBox());
--    bool boundsChanged;
--    if (m_widget->isFrameView()) {
--        contentBox.setLocation(absoluteContentBox.location());
--        boundsChanged = setWidgetGeometry(contentBox);
--    } else
--        boundsChanged = setWidgetGeometry(absoluteContentBox);
    
    -- if the frame bounds got changed, or if view needs layout (possibly indicating
    -- content size is wrong) we have to do a layout to set the right widget size
    if (self.m_widget and self.m_widget:IsFrameView()) then
        local frameView = self.m_widget;
        -- Check the frame's page to make sure that the frame isn't in the process of being destroyed.
        if ((boundsChanged or frameView:NeedsLayout()) and frameView:Frame():Page()) then
            frameView:Layout();
		end
    end
end

--void RenderWidget::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutWidget:Paint(paintInfo, paintOffset)
--    if (not self:ShouldPaint(paintInfo, paintOffset)) then
--        return;
--	end
    --local adjustedPaintOffset = paintOffset + self:Location();
	local adjustedPaintOffset = paintOffset

	if(paintInfo.phase == PaintPhase.PaintPhaseForeground or paintInfo.phase == PaintPhase.PaintPhaseSelection) then
		self:PaintBoxDecorations(paintInfo, adjustedPaintOffset);
	end

--    if (hasBoxDecorations() && (paintInfo.phase == PaintPhaseForeground || paintInfo.phase == PaintPhaseSelection))
--        paintBoxDecorations(paintInfo, adjustedPaintOffset);

--    if (paintInfo.phase == PaintPhaseMask) {
--        paintMask(paintInfo, adjustedPaintOffset);
--        return;
--    }

--    if ((paintInfo.phase == PaintPhaseOutline || paintInfo.phase == PaintPhaseSelfOutline) && hasOutline())
--        paintOutline(paintInfo.context, LayoutRect(adjustedPaintOffset, size()));
    if (not self.m_frameView or paintInfo.phase ~= PaintPhase.PaintPhaseForeground) then
        return;
	end
--#if PLATFORM(MAC)
--    if (style()->highlight() != nullAtom && !paintInfo.context->paintingDisabled())
--        paintCustomHighlight(paintOffset, style()->highlight(), true);
--#endif

--    if (style()->hasBorderRadius()) {
--        LayoutRect borderRect = LayoutRect(adjustedPaintOffset, size());
--
--        if (borderRect.isEmpty())
--            return;
--
--        // Push a clip if we have a border radius, since we want to round the foreground content that gets painted.
--        paintInfo.context->save();
--        paintInfo.context->addRoundedRectClip(style()->getRoundedBorderFor(borderRect));
--    }

    if (self.m_widget) then
        -- Tell the widget to paint now.  This is the only time the widget is allowed
        -- to paint itself.  That way it will composite properly with z-indexed layers.
        local widgetLocation = self.m_widget:FrameRect():Location();
        local paintLocation = LayoutPoint:new(adjustedPaintOffset:X() + self:BorderLeft() + self:PaddingLeft(), adjustedPaintOffset:Y() + self:BorderTop() + self:PaddingTop());
        local paintRect = paintInfo.rect;

        local widgetPaintOffset = paintLocation - widgetLocation;
        -- When painting widgets into compositing layers, tx and ty are relative to the enclosing compositing layer,
        -- not the root. In this case, shift the CTM and adjust the paintRect to be root-relative to fix plug-in drawing.
--        if (!widgetPaintOffset.isZero()) {
--            paintInfo.context->translate(widgetPaintOffset);
--            paintRect.move(-widgetPaintOffset);
--        }
        self.m_widget:Paint(paintInfo.context, paintRect);

--        if (!widgetPaintOffset.isZero())
--            paintInfo.context->translate(-widgetPaintOffset);

--        if (m_widget->isFrameView()) {
--            FrameView* frameView = static_cast<FrameView*>(m_widget.get());
--            bool runOverlapTests = !frameView->useSlowRepaintsIfNotOverlapped() || frameView->hasCompositedContentIncludingDescendants();
--            if (paintInfo.overlapTestRequests && runOverlapTests) {
--                ASSERT(!paintInfo.overlapTestRequests->contains(this));
--                paintInfo.overlapTestRequests->set(this, m_widget->frameRect());
--            }
--         }
    end

--    if (style()->hasBorderRadius())
--        paintInfo.context->restore();

--    // Paint a partially transparent wash over selected widgets.
--    if (isSelected() && !document()->printing()) {
--        // FIXME: selectionRect() is in absolute, not painting coordinates.
--        paintInfo.context->fillRect(selectionRect(), selectionBackgroundColor(), style()->colorSpace());
--    }
end