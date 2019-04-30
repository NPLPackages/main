--[[
Title: 
Author(s): LiPeng
Date: 2018/4/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/ScrollView.lua");
local ScrollView = commonlib.gettable("System.Windows.mcml.platform.ScrollView");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/platform/ScrollableArea.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntPoint.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
local Size = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local IntPoint = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");
local ScrollView = commonlib.inherit(commonlib.gettable("System.Windows.mcml.platform.ScrollableArea"), commonlib.gettable("System.Windows.mcml.platform.ScrollView"));

local IntSize = Size;
local IntRect = Rect;

function ScrollView:ctor()
	self.paintsEntireContents = false;
    self.clipsRepaints = true;

	self.scrollOffset = IntSize:new();

	--IntRect m_frame; // Not used when a native widget exists.
	self.m_frameRect = IntRect:new();

	self.m_widget = nil;

	self.m_parent = nil;

	self.m_children = commonlib.vector:new();
end

function ScrollView:Parent()
	return self.m_parent;
end

--void Widget::setParent(ScrollView* view)
function ScrollView:SetParent(view)
	self.m_parent = view;
end

function ScrollView:Children()
	return self.m_children;
end

--void ScrollView::addChild(PassRefPtr<Widget> prpChild) 
function ScrollView:AddChild(child) 
    --ASSERT(child != this && !child->parent());
    child:SetParent(self);
    self.m_children:add(child);
end

function ScrollView:RemoveFromParent()
    if (self:Parent()) then
        seklf:Parent():RemoveChild(self);
	end
end

--void ScrollView::removeChild(Widget* child)
function ScrollView:RemoveChild(child)
    --ASSERT(child->parent() == this);
    child:SetParent(nil);
    self.m_children:removeByValue(child);
end

function ScrollView:PaintsEntireContents()
    return self.paintsEntireContents;
end

function ScrollView:SetPaintsEntireContents(paintsEntireContents)
    self.paintsEntireContents = paintsEntireContents;
end

function ScrollView:ClipsRepaints()
    return self.clipsRepaints;
end

function ScrollView:SetClipsRepaints(clipsRepaints)
    self.clipsRepaints = clipsRepaints;
end

-- we must implement this function in derived class, such as FrameView, LayoutLayer .
--virtual IntRect visibleContentRect(bool includeScrollbars = false) const;
function ScrollView:VisibleContentRect(includeScrollbars)
	includeScrollbars = if_else(includeScrollbars == nil, false, includeScrollbars);

	-- TODO: fixed later;
end

-- Functions for querying the current scrolled position (both as a point, a size, or as individual X and Y values).
function ScrollView:ScrollPosition()
	return self:VisibleContentRect():Location();
end

function ScrollView:ScrollOffset()
	-- Gets the scrolled position as an IntSize. Convenient for adding to other sizes.
	return self:VisibleContentRect():Location() - IntPoint:new_from_pool();
end 

--void ScrollView::repaintContentRectangle(const IntRect& rect, bool now)
function ScrollView:RepaintContentRectangle(rect, now)
    local paintRect = rect:clone_from_pool();
    if (self:ClipsRepaints() and not self:PaintsEntireContents()) then
        paintRect:Intersect(self:VisibleContentRect());
	end
    if (paintRect:IsEmpty()) then
        return;
	end

--    if (platformWidget()) {
--        notifyPageThatContentAreaWillPaint();
--        platformRepaintContentRectangle(paintRect, now);
--        return;
--    }

--    if (hostWindow())
--        hostWindow()->invalidateContentsAndWindow(contentsToWindow(paintRect), now /*immediate*/);
	self:InvalidateContentsAndWindow(self:ContentsToWindow(paintRect), now);
end

--IntRect ScrollView::contentsToWindow(const IntRect& contentsRect) const
function ScrollView:ContentsToWindow(contentsRect)
--    IntRect viewRect = contentsRect;
--    viewRect.move(-scrollOffset());
--    return convertToContainingWindow(viewRect);
	return contentsRect;
end

--void Chrome::invalidateContentsAndWindow(const IntRect& updateRect, bool immediate)
function ScrollView:InvalidateContentsAndWindow(updateRect, immediate)

end

--void ScrollView::paint(GraphicsContext* context, const IntRect& rect)
function ScrollView:Paint(context, rect)
	local documentDirtyRect = rect;

	self:PaintContents(context, documentDirtyRect);
end

--void ScrollView::paintContents(GraphicsContext* p, const LayoutRect& rect)
-- virtual function
function ScrollView:PaintContents(p, rect)
	
end

--IntRect Widget::frameRect() const
function ScrollView:FrameRect()
    return self.m_frameRect;
end

--void Widget::setFrameRect(const IntRect& rect)
function ScrollView:SetFrameRect(rect)
    self.m_frameRect = rect;
end

function ScrollView:X() return self:FrameRect():X(); end
function ScrollView:Y() return self:FrameRect():Y(); end
function ScrollView:Width() return self:FrameRect():Width(); end
function ScrollView:Height() return self:FrameRect():Height(); end
function ScrollView:Size() return self:FrameRect():Size(); end
function ScrollView:Location() return self:FrameRect():Location(); end

function ScrollView:BoundsRect() return IntRect:new(0, 0, self:Width(),  self:Height()); end

function ScrollView:Resize(w, h) 
	if(h) then
		self:SetFrameRect(IntRect:new(self:X(), self:Y(), w, h)); 
		return
	end
	local size = w;
	self:SetFrameRect(IntRect:new(self:Location(), size));
end
function ScrollView:Move(x, y) 
	if(y) then
		self:SetFrameRect(IntRect:new(x, y, self:Width(), self:Height())); 
		return;
	end
	local point = x;
	self:SetFrameRect(IntRect:new(point, self:Size()));
end

function ScrollView:IsFrameView() return true; end

function ScrollView:LayoutWidth()
	--return m_fixedLayoutSize.isEmpty() || !m_useFixedLayout ? visibleWidth() : m_fixedLayoutSize.width();
	return self:VisibleWidth();
end

function ScrollView:LayoutHeight()
	--return m_fixedLayoutSize.isEmpty() || !m_useFixedLayout ? visibleHeight() : m_fixedLayoutSize.height();
	return self:VisibleHeight();
end

function ScrollView:VisibleWidth() 
	return self:VisibleContentRect():Width()
end
function ScrollView:VisibleHeight() 
	return self:VisibleContentRect():Height();
end

function ScrollView:VisibleContentRect(includeScrollbars)
	includeScrollbars = if_else(includeScrollbars == nil, false, includeScrollbars);

	-- TODO: fixed later;
	local x ,y ,w, h = self.scrollOffset:Width(), self.scrollOffset:Height(), self:Width(), self:Height();
	return Rect:new_from_pool(x ,y ,w, h);
end