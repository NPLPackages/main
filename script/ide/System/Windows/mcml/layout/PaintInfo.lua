--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/PaintInfo.lua");
local PaintInfo = commonlib.gettable("System.Windows.mcml.layout.PaintInfo");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
local IntRect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");

local PaintInfo = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.PaintInfo"));

function PaintInfo:ctor()
	-- unused
	self.context = nil;
	self.rect = IntRect:new();
	self.phase = nil;
	-- unused
	self.forceBlackText = nil;
	self.paintingRoot = nil;
	-- unused
	self.renderRegion = nil;
	-- unused
	self.outlineObjects = nil;
	-- unused
	self.overlapTestRequests = nil;
end

--PaintInfo(GraphicsContext* newContext, const IntRect& newRect, PaintPhase newPhase, bool newForceBlackText,
--              RenderObject* newPaintingRoot, RenderRegion* region, ListHashSet<RenderInline*>* newOutlineObjects,
--              OverlapTestRequestMap* overlapTestRequests = 0)
function PaintInfo:init(newContext, newRect, newPhase, newForceBlackText, newPaintingRoot, region, newOutlineObjects, overlapTestRequests)
	self.context = newContext;
	self.rect:Reset(newRect:X(), newRect:Y(), newRect:Width(), newRect:Height());
	self.phase = newPhase;
	self.forceBlackText = newForceBlackText;
	self.paintingRoot = newPaintingRoot;
	self.renderRegion = region;
	self.newOutlineObjects = newOutlineObjects;
	self.overlapTestRequests = overlapTestRequests;
	return self;
end

function PaintInfo:clone()
	return PaintInfo:new():init(self.context, self.rect, self.phase, self.forceBlackText, self.paintingRoot,self.renderRegion, self.newOutlineObjects, self.overlapTestRequests)
end

--void updatePaintingRootForChildren(const RenderObject* renderer)
function PaintInfo:UpdatePaintingRootForChildren(renderer)
    if (not self.paintingRoot) then
        return;
	end

    -- If we're the painting root, kids draw normally, and see root of 0.
    if (self.paintingRoot == renderer) then
        self.paintingRoot = nil; 
        return;
    end
end

function PaintInfo:Rect()
	return self.rect;
end

local INT_MIN = (-2147483647 - 1) -- minimum (signed) int value 
local INT_MAX = 2147483647    -- maximum (signed) int value

--static IntRect infiniteRect() { return IntRect(INT_MIN / 2, INT_MIN / 2, INT_MAX, INT_MAX); }
function PaintInfo.InfiniteRect()
	return IntRect:new(INT_MIN / 2, INT_MIN / 2, INT_MAX, INT_MAX);
end

--bool shouldPaintWithinRoot(const RenderObject* renderer) const
function PaintInfo:ShouldPaintWithinRoot(renderer)
    return not self.paintingRoot or self.paintingRoot == renderer;
end