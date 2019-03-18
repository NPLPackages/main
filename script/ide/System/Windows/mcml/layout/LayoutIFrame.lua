--[[
Title: 
Author(s): LiPeng
Date: 2019/3/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutIFrame.lua");
local LayoutIFrame = commonlib.gettable("System.Windows.mcml.layout.LayoutIFrame");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutPart.lua");
local LayoutIFrame = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutPart"), commonlib.gettable("System.Windows.mcml.layout.LayoutIFrame"));

function LayoutIFrame:ctor()
	echo("LayoutIFrame:ctor")
	self:SetInline(false);
end

--function LayoutIFrame:init(node)
--	return self;
--end

function LayoutIFrame:IsFrame() 
	return true;
end

function LayoutIFrame:Layout()
	echo("LayoutIFrame:Layout")
    --ASSERT(needsLayout());

    LayoutIFrame._super.ComputeLogicalWidth(self);
    LayoutIFrame._super.ComputeLogicalHeight(self);

    LayoutIFrame._super.Layout(self);

    self.overflow = nil;
    --addBoxShadowAndBorderOverflow();
    self:UpdateLayerTransform();

    self:SetNeedsLayout(false);
end