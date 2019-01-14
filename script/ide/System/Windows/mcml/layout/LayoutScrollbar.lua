--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutScrollbar.lua");
local LayoutScrollbar = commonlib.gettable("System.Windows.mcml.layout.LayoutScrollbar");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlock.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollBar.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/ScrollbarTheme.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/graphics/IntRect.lua");
local Rect = commonlib.gettable("System.Windows.mcml.platform.graphics.IntRect");
local ScrollbarTheme = commonlib.gettable("System.Windows.mcml.platform.ScrollbarTheme");
local ScrollBar = commonlib.gettable("System.Windows.Controls.ScrollBar");
local LayoutScrollbar = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBlock"), commonlib.gettable("System.Windows.mcml.layout.LayoutScrollbar"));

local IntRect = Rect;

function LayoutScrollbar:ctor()
	-- LayoutLayer
	self.scrollArea = nil
	self.orientation = nil
	self.control = nil;
	-- LayoutBox
	self.owner = nil;

	self.theme = ScrollbarTheme:theme();

	self.enabled = true;

	self.visibleSize = 0;
    self.totalSize = 0;
    --float m_currentPos;
    --float m_dragOrigin;
    self.lineStep = 0;
    self.pageStep = 0;
	self.scrollStep = 100;
    --float m_pixelStep;
end

function LayoutScrollbar:init(scrollArea, orientation, renderer)
	LayoutScrollbar._super.init(self)
	self.scrollArea = scrollArea;
	self.orientation = orientation;
	self.owner = renderer;

	local thickness = self.theme:scrollbarThickness();
    self:SetFrameRect(IntRect:new(0, 0, thickness, thickness));

	--self:SetChildrenInline(false);
	return self;
end

function LayoutScrollbar:GetName()
	return "LayoutScrollbar";
end

function LayoutScrollbar.PixelsPerLineStep()
	return 32;
end

function LayoutScrollbar.PixelsPerScrollStep()
	return LayoutScrollbar.PixelsPerLineStep() * 3;
end

--RenderBox* RenderScrollbar::owningRenderer() const
function LayoutScrollbar:OwningRenderer()
--    if (m_owningFrame) {
--        RenderBox* currentRenderer = m_owningFrame->ownerRenderer();
--        return currentRenderer;
--    }
    return self.owner;
end

function LayoutScrollbar:Destroy()
	scrollbar:ClearOwningRenderer();
    scrollbar:DisconnectFromScrollableArea();
	if(self.control) then
		local scrollArea_control = self.scrollArea:Renderer():GetControl();
		local direction = directionMap[self.orientation];
		scrollArea_control:DestroyScrollbar(direction); 
		self.control = nil;
	end
end

function LayoutScrollbar:ClearOwningRenderer()
	self.owner = nil;
end

function LayoutScrollbar:DisconnectFromScrollableArea() 
	self.scrollableArea = 0;
end
--ScrollableArea* scrollableArea() const { return m_scrollableArea; }
function LayoutScrollbar:ScrollableArea()
	return self.scrollableArea;
end

--void Scrollbar::setEnabled(bool e)
function LayoutScrollbar:SetEnabled(e) 
    if (self.enabled == e) then
        return;
	end
    self.enabled = e;
--    theme()->updateEnabledState(this);
--    invalidate();
end

function LayoutScrollbar:StyleChanged()
    --updateScrollbarParts();
end

function LayoutScrollbar:IsOverlayScrollbar()
	return self.theme:usesOverlayScrollbars();
end

--void Scrollbar::setSteps(int lineStep, int pageStep, int pixelsPerStep)
function LayoutScrollbar:SetSteps(lineStep, pageStep, pixelsPerStep)
	self.lineStep = lineStep;
    self.pageStep = pageStep;
end

--void Scrollbar::setProportion(int visibleSize, int totalSize)
function LayoutScrollbar:SetProportion(visibleSize, totalSize)
    if (visibleSize == self.visibleSize and totalSize == self.totalSize) then
        return;
	end
	echo("LayoutScrollbar:SetProportion")
	echo({visibleSize, totalSize})
    self.visibleSize = visibleSize;
    self.totalSize = totalSize;

    --updateThumbProportion();
end

local directionMap = {
	["HorizontalScrollbar"] = "horizontal",
	["VerticalScrollbar"] = "vertical",
}

function LayoutScrollbar:GetControl()	
	if(not self.control) then
		local scrollArea_control = self.scrollArea:Renderer():GetControl();
		local direction = directionMap[self.orientation];
		local scrollbar = scrollArea_control:CreateScrollbar(direction);
		scrollbar:Connect("valueChanged", function(value)
			echo("valueChanged");
			echo(value)
			if(self.scrollArea) then
				if(self.orientation == "HorizontalScrollbar") then
					self.scrollArea:ScrollTo(value, nil)
				end
				if(self.orientation == "VerticalScrollbar") then
					self.scrollArea:ScrollTo(nil, value)
				end

				local view = self.scrollArea:Renderer():View();
				if(view) then
					local frameview = view:FrameView();
					frameview:PostLayoutRequestEvent();
				end
			end
		end);
		--scrollbar:SetValue(self.visibleSize)
		self.control = scrollbar;
	end	
	echo("LayoutScrollbar:GetControl")
	echo({self.lineStep, self.pageStep, self.visibleSize, self.totalSize})
	self.control:setRange(0, self.totalSize - self.visibleSize)
	--self.control:setStep(self.lineStep, self.pageStep, LayoutScrollbar.PixelsPerScrollStep())
	self.control:setStep(self.lineStep, self.pageStep, self.scrollStep)
	return self.control
end

--void RenderReplaced::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
function LayoutScrollbar:Paint(paintInfo, paintOffset)
	echo("LayoutScrollbar:Paint")
	echo(paintOffset)
	echo(self.frame_rect)
	echo(self.enabled)
	echo({self.lineStep, self.pageStep, self.visibleSize, self.totalSize})

	self:PaintBoxDecorations(paintInfo, paintOffset);
	self:GetControl():SetDisabled(not self.enabled);
end
