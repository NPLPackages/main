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
NPL.load("(gl)script/ide/System/Windows/mcml/geometry/Length.lua");
local Length = commonlib.gettable("System.Windows.mcml.geometry.Length");
local LayoutView = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBlock"), commonlib.gettable("System.Windows.mcml.layout.LayoutView"));

function LayoutView:ctor()
	self.name = "LayoutView";

	self.frameView = nil;
	self.pageLogicalHeight = 0;
	self.pageLogicalHeightChanged = false;

	-- Clear our anonymous bit, set because RenderObject assumes
    -- any renderer with document as the node is anonymous.
    self:SetIsAnonymous(false);

    -- init RenderObject attributes
    self:SetInline(false);
    
    self.minPreferredLogicalWidth = 0;
    self.maxPreferredLogicalWidth = 0;

    self:SetPreferredLogicalWidthsDirty(true, false);
    
    self:SetPositioned(true); -- to 0,0 :)
end

function LayoutView:init(node, frameView)
	LayoutView._super.init(self, node);
	self.frameView = frameView;

	return self;
end

function LayoutView:BeLayoutView()
	return true;
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
			if (Length.IsPercent(child:Style():LogicalHeight()) or Length.IsPercent(child:Style():LogicalMinHeight()) or Length.IsPercent(child:Style():LogicalMaxHeight())) then
                child:SetChildNeedsLayout(true, false);
			end
			child = child:NextSibling();
		end
    end

--    LayoutState state;
--    // FIXME: May be better to push a clip and avoid issuing offscreen repaints.
--    state.m_clipped = false;
--    state.m_pageLogicalHeight = m_pageLogicalHeight;
--    state.m_pageLogicalHeightChanged = m_pageLogicalHeightChanged;
--    state.m_isPaginated = state.m_pageLogicalHeight;
    self.pageLogicalHeightChanged = false;
    --m_layoutState = &state;

    if (self:NeedsLayout()) then
        LayoutView._super.Layout(self);
--        if (self:HasRenderFlowThreads()) then
--            self:LayoutRenderFlowThreads();
--		end
    end

    self:SetNeedsLayout(false);
end

