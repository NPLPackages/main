--[[
Title: 
Author(s): LiPeng
Date: 2018/11/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutReplica.lua");
local LayoutReplica = commonlib.gettable("System.Windows.mcml.layout.LayoutReplica");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/PaintPhase.lua");
local PaintPhase = commonlib.gettable("System.Windows.mcml.layout.PaintPhase");
local LayoutReplica = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBox"), commonlib.gettable("System.Windows.mcml.layout.LayoutReplica"));

function LayoutReplica:ctor()
	self:SetReplaced(true);
end

function LayoutReplica:RequiresLayer()
	return true;
end

function LayoutReplica:GetName()
	return "LayoutReplica";
end

function LayoutReplica:IsReplica()
	return true;
end

function LayoutReplica:Layout()
    self:SetFrameRect(self:ParentBox():BorderBoxRect());
    self:UpdateLayerTransform();
    self:SetNeedsLayout(false);
end

function LayoutReplica:ComputePreferredLogicalWidths()
    self.minPreferredLogicalWidth = self:ParentBox():Width();
    self.maxPreferredLogicalWidth = self.minPreferredLogicalWidth;
    self:SetPreferredLogicalWidthsDirty(false);
end

function LayoutReplica:Paint(paintInfo, paintOffset)
    if (paintInfo.phase ~= PaintPhase.PaintPhaseForeground and paintInfo.phase ~= PaintPhase.PaintPhaseMask) then
        return;
	end
    local adjustedPaintOffset = paintOffset + self:Location();

    if (paintInfo.phase == PaintPhase.PaintPhaseForeground) then
        -- Turn around and paint the parent layer. Use temporary clipRects, so that the layer doesn't end up caching clip rects
        -- computing using the wrong rootLayer
        self:Layer():Parent():PaintLayer(if_else(self:Layer():Transform(), self:Layer():Parent(), self:Layer():EnclosingTransformedAncestor()),
                                      paintInfo.context, paintInfo:Rect(), "PaintBehaviorNormal", nil, paintInfo.renderRegion);
--    elseif (paintInfo.phase == PaintPhaseMask) then
--        paintMask(paintInfo, adjustedPaintOffset);
	end
end

