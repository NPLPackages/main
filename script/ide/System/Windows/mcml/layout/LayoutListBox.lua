--[[
Title: 
Author(s): LiPeng
Date: 2018/11/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutListBox.lua");
local LayoutListBox = commonlib.gettable("System.Windows.mcml.layout.LayoutListBox");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlock.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutTheme.lua");
local LayoutTheme = commonlib.gettable("System.Windows.mcml.layout.LayoutTheme");

local LayoutListBox = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBlock"), commonlib.gettable("System.Windows.mcml.layout.LayoutListBox"));

local optionsSpacingHorizontal = 2;

local rowSpacing = 1

function LayoutListBox:ctor()
	self.m_optionsWidth = 0;
end

function LayoutListBox:GetName()
	return "LayoutListBox";
end

function LayoutListBox:StyleDidChange(diff, oldStyle)
	LayoutListBox._super.StyleDidChange(self, diff, oldStyle);
	self:UpdateFromElement();
end

function LayoutListBox:UpdateFromElement()
	local items = self.node:ListItems();
	local font = self.style:Font():ToString();
	local width = 0;
	for i = 1, #items do
		local text = items[i]["text"];
		width = math.max(width, text:GetWidth(font));
	end
	self.m_optionsWidth = width;
end

function LayoutListBox:ComputePreferredLogicalWidths()
    --ASSERT(!m_optionsChanged);

    self.minPreferredLogicalWidth = 0;
    self.maxPreferredLogicalWidth = 0;

    if (self:Style():Width():IsFixed() and self:Style():Width():Value() > 0) then
        self.maxPreferredLogicalWidth = self:ComputeContentBoxLogicalWidth(self:Style():Width():Value());
		self.minPreferredLogicalWidth = self.maxPreferredLogicalWidth;
    else
        self.maxPreferredLogicalWidth = self.m_optionsWidth + LayoutTheme:DefaultTheme():ScrollbarThickness();
--        if (m_vBar)
--            self.maxPreferredLogicalWidth = self.maxPreferredLogicalWidth + m_vBar->width();
    end

    if (self:Style():MinWidth():IsFixed() and self:Style():MinWidth():Value() > 0) then
        self.maxPreferredLogicalWidth = math.max(self.maxPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():MinWidth():Value()));
        self.minPreferredLogicalWidth = math.max(self.minPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():MinWidth():Value()));
    elseif (self:Style():Width():IsPercent() or (self:Style():Width():IsAuto() and self:Style():Height():IsPercent())) then
        self.minPreferredLogicalWidth = 0;
    else
        self.minPreferredLogicalWidth = self.maxPreferredLogicalWidth;
	end

    if (self:Style():MaxWidth():IsFixed()) then
        self.maxPreferredLogicalWidth = math.min(self.maxPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():MaxWidth():Value()));
        self.minPreferredLogicalWidth = math.min(self.minPreferredLogicalWidth, self:ComputeContentBoxLogicalWidth(self:Style():MaxWidth():Value()));
    end

    local toAdd = self:BorderAndPaddingWidth();
    self.minPreferredLogicalWidth = self.minPreferredLogicalWidth + toAdd;
    self.maxPreferredLogicalWidth = self.maxPreferredLogicalWidth + toAdd;
                                
    self:SetPreferredLogicalWidthsDirty(false);
end

function LayoutListBox:Size()
    local size = self:Node():Size();
    return size;
end

function LayoutListBox:ItemHeight()
    return self:Style():ComputedLineHeight();
end

function LayoutListBox:ComputeLogicalHeight()
    local toAdd = self:BorderAndPaddingHeight();
    local itemHeight = self:ItemHeight();
    --self:SetHeight(itemHeight * self:Size() - rowSpacing + toAdd);
	self:SetHeight(itemHeight * self:Size())
    
    LayoutListBox._super.ComputeLogicalHeight(self);
    
--    if (m_vBar) {
--        bool enabled = numVisibleItems() < numItems();
--        m_vBar->setEnabled(enabled);
--        m_vBar->setSteps(1, max(1, numVisibleItems() - 1), itemHeight);
--        m_vBar->setProportion(numVisibleItems(), numItems());
--        if (!enabled)
--            m_indexOffset = 0;
--    }
end

function LayoutListBox:Paint(paintInfo, paintOffset)
    LayoutListBox._super.Paint(self, paintInfo, paintOffset);
	local control = self:GetControl();
	if(control) then
		control:setVerticalScrollBarPolicy("AlwaysOn");
		local items = self.node:ListItems();
		control.vbar:SetDisabled(self:Size() >= #items);
	end
end


