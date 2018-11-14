--[[
Title: 
Author(s): LiPeng
Date: 2018/10/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBR.lua");
local LayoutBR = commonlib.gettable("System.Windows.mcml.layout.LayoutBR");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutText.lua");
local LayoutBR = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutText"), commonlib.gettable("System.Windows.mcml.layout.LayoutBR"));

function LayoutBR:ctor()
	self.lineHeight = -1;
end

function LayoutBR:init(node)

	--LayoutBR._super.init(self, node, "&#13;&#10;");
	LayoutBR._super.init(self, node, "\r\n");

	return self;
end

function LayoutBR:GetName()
	return "LayoutBR";
end

--int RenderBR::lineHeight(bool firstLine) const
function LayoutBR:LineHeight(firstLine)
    if (firstLine and self:Document():UsesFirstLineRules()) then
        local s = self:Style(firstLine);
        if (s ~= self:Style()) then
            return s:ComputedLineHeight();
		end
    end
    
    if (self.lineHeight == -1) then
        self.lineHeight = self:Style():ComputedLineHeight();
	end
    
    return self.lineHeight;
end

--void RenderBR::styleDidChange(StyleDifference diff, const RenderStyle* oldStyle)
function LayoutBR:StyleDidChange(diff, oldStyle)
    LayoutBR._super.StyleDidChange(self, diff, oldStyle);
    self.lineHeight = -1;
end

--int RenderBR::caretMinOffset() const 
function LayoutBR:CaretMinOffset()
    return 0;
end

--int RenderBR::caretMaxOffset() const 
function LayoutBR:CaretMaxOffset()
    return 1;
end

function LayoutBR:GetName()
	return "LayoutBR";
end

function LayoutBR:Width(from, len, font, xPos, fallbackFonts, glyphOverflow)
	return 0;
end

function LayoutBR:IsBR() 
	return true;
end
