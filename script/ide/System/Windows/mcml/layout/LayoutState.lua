--[[
Title: 
Author(s): LiPeng
Date: 2018/5/10
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutState.lua");
local LayoutState = commonlib.gettable("System.Windows.mcml.layout.LayoutState");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObject.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntSize.lua");
local LayoutSize = commonlib.gettable("System.Windows.mcml.platform.graphics.IntSize");
local LayoutRect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
local LayoutState = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.LayoutState"));

function LayoutState:ctor()
	self.clipped = false;
    self.isPaginated = false;
    self.clipRect = LayoutRect:new();
    
    -- x/y offset from container. Includes relative positioning and scroll offsets.
    self.paintOffset = LayoutSize:new();
    -- x/y offset from container. Does not include relative positioning or scroll offsets.
    self.layoutOffset = LayoutSize:new();
    -- Transient offset from the final position of the object
    -- used to ensure that repaints happen in the correct place.
    -- This is a total delta accumulated from the root. 
    self.layoutDelta = LayoutSize:new();

    -- The current page height for the pagination model that encloses us.
    self.pageLogicalHeight = 0;
    -- If our page height has changed, this will force all blocks to relayout.
    self.pageLogicalHeightChanged = false;
    -- The offset of the start of the first page in the nearest enclosing pagination model.
    self.pageOffset = LayoutSize:new();
    -- If the enclosing pagination model is a column model, then this will store column information for easy retrieval/manipulation.
    self.columnInfo = nil;

    self.next = nil;
--#ifndef NDEBUG
    self.renderer = nil; 
--#endif
end

--function LayoutState:init(LayoutState* prev, RenderBox* renderer, const LayoutSize& offset, LayoutUnit pageLogicalHeight, bool pageLogicalHeightChanged, ColumnInfo* columnInfo)
function LayoutState:init(prev, renderer, offset, pageLogicalHeight, pageLogicalHeightChanged, columnInfo)
	if(pageLogicalHeight ~= nil or pageLogicalHeightChanged ~= nil or columnInfo ~= nil) then
		-- TODO: add latter
	else
		if(renderer ~= nil or offset ~= nil) then
			local _prev, _flowThread, _regionsChanged = prev, renderer, offset;
			self.clipped = false;
			self.isPaginated = true;
			self.pageLogicalHeight = 1;
			self.pageLogicalHeightChanged = _regionsChanged;
			self.columnInfo = nil;
			self.next = _prev;
			self.renderer = _flowThread;
		else
			--local root = prev;
			-- TODO: add latter
		end
	end
end

--LayoutUnit LayoutState::pageLogicalOffset(LayoutUnit childLogicalOffset) const
function LayoutState:PageLogicalOffset(childLogicalOffset)
    return self.layoutOffset:Height() + childLogicalOffset - self.pageOffset:Height();
end

function LayoutState:IsPaginatingColumns()
	return if_else(self.columnInfo, true, false);
end

function LayoutState:IsPaginated()
	return self.isPaginated;
end

function LayoutState:PageLogicalHeight()
	return if_else(self.pageLogicalHeight ~= 0, true, false);
end

function LayoutState:PageLogicalHeightChanged()
	return self.pageLogicalHeightChanged;
end
