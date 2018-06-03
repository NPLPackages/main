--[[
Title: 
Author(s): LiPeng
Date: 2018/4/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/ScrollableArea.lua");
local ScrollableArea = commonlib.gettable("System.Windows.mcml.platform.ScrollableArea");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntPoint.lua");
local IntPoint = commonlib.gettable("System.Windows.mcml.platform.graphics.IntPoint");

local ScrollableArea = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.platform.ScrollableArea"));

function ScrollableArea:ctor()
	self.constrainsScrollingToContentEdge = true;
    self.inLiveResize = false;
--	enum ScrollElasticity {
--        ScrollElasticityAutomatic,
--        ScrollElasticityNone,
--        ScrollElasticityAllowed
--    };
    self.verticalScrollElasticity = "ScrollElasticityNone";
    self.horizontalScrollElasticity = "ScrollElasticityNone";
--	enum ScrollbarOverlayStyle {
--        ScrollbarOverlayStyleDefault,
--        ScrollbarOverlayStyleDark,
--        ScrollbarOverlayStyleLight
--    };
    self.scrollbarOverlayStyle = "ScrollbarOverlayStyleDefault";
	self.scrollAnimator = nil;

	self.scrollOrigin = IntPoint:new();
end

--function ScrollableArea:init()
--	
--	return self;
--end

-- Functions for controlling if you can scroll past the end of the document.
function ScrollableArea:ConstrainsScrollingToContentEdge()
	return self.constrainsScrollingToContentEdge;
end

function ScrollableArea:SetConstrainsScrollingToContentEdge(constrainsScrollingToContentEdge)
	self.constrainsScrollingToContentEdge = constrainsScrollingToContentEdge;
end

function ScrollableArea:ScrollOrigin()
	return self.scrollOrigin;
end
