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
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntPoint.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
local Size = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local IntPoint = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");
local ScrollView = commonlib.inherit(commonlib.gettable("System.Windows.mcml.platform.ScrollableArea"), commonlib.gettable("System.Windows.mcml.platform.ScrollView"));

local IntSize = Size;

function ScrollView:ctor()
	self.paintsEntireContents = false;
    self.clipsRepaints = true;

	self.scrollOffset = IntSize:new();
end

--function ScrollView:init()
--	
--	return self;
--end

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
	echo("ScrollView:RepaintContentRectangle")
	echo(rect)
    local paintRect = rect:clone_from_pool();
    if (self:ClipsRepaints() and not self:PaintsEntireContents()) then
        paintRect:Intersect(self:VisibleContentRect());
	end
	echo(paintRect)
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