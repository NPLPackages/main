--[[
Title: 
Author(s): LiPeng
Date: 2018/11/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutMenuList.lua");
local LayoutMenuList = commonlib.gettable("System.Windows.mcml.layout.LayoutMenuList");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlock.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutTheme.lua");
local LayoutTheme = commonlib.gettable("System.Windows.mcml.layout.LayoutTheme");
local LayoutMenuList = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBlock"), commonlib.gettable("System.Windows.mcml.layout.LayoutMenuList"));

local optionsSpacingHorizontal = 2;

function LayoutMenuList:ctor()
	self.m_optionsWidth = 0;
end

function LayoutMenuList:GetName()
	return "LayoutMenuList";
end

function LayoutMenuList:StyleDidChange(diff, oldStyle)
	LayoutMenuList._super.StyleDidChange(self, diff, oldStyle);
	self:UpdateFromElement();
end

function LayoutMenuList:UpdateFromElement()
	local items = self.node:ListItems();
	local font = self.style:Font():ToString();
	local width = 0;
	for i = 1, #items do
		local text = items[i]["text"];
		width = math.max(width, text:GetWidth(font));
	end
	self.m_optionsWidth = width;
end

function LayoutMenuList:ComputePreferredLogicalWidths()
    --ASSERT(!m_optionsChanged);

    self.minPreferredLogicalWidth = 0;
    self.maxPreferredLogicalWidth = 0;

    if (self:Style():Width():IsFixed() and self:Style():Width():Value() > 0) then
        self.maxPreferredLogicalWidth = self:ComputeContentBoxLogicalWidth(self:Style():Width():Value());
		self.minPreferredLogicalWidth = self.maxPreferredLogicalWidth;
    else
        self.maxPreferredLogicalWidth = self.m_optionsWidth;
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


function LayoutMenuList:Paint(paintInfo, paintOffset)
    LayoutMenuList._super.Paint(self, paintInfo, paintOffset);
	local control = self:GetControl();
	if(control) then
		local dropDownButtonWidth = LayoutTheme:DefaultTheme():ScrollbarThickness();
		control:SetTextMargin(self:PaddingLeft(), self:PaddingTop(), self:PaddingRight() - dropDownButtonWidth, self:PaddingBottom());
	end
end



