--[[
Title: Label
Author(s): LiXizhi
Date: 2015/4/29
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/Label.lua");
local Label = commonlib.gettable("System.Windows.Controls.Label");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/UITextElement.lua");
local Label = commonlib.inherit(commonlib.gettable("System.Windows.UITextElement"), commonlib.gettable("System.Windows.Controls.Label"));
Label:Property("Name", "Label");
Label:Property({"Text", auto=true})
Label:Property({"Color", "#000000", auto=true})
Label:Property({"Font", "System;14;norm", auto=true})
Label:Property({"FontSize", nil, auto=true});
Label:Property({"FontScaling", nil, auto=true});
-- default to centered and no clipping. 
Label:Property({"Alignment", 1+4+256, auto=true, desc="text alignment"});

-- text padding
Label:Property({"padding_left", 5, });
Label:Property({"padding_top", 5, });
Label:Property({"padding_right", 5, });
Label:Property({"padding_bottom", 5, });

function Label:ctor()
end

-- inner text height without padding. 
function Label:CalculateTextHeight()
	return (self:GetFontSize() or 12) * (self:GetFontScaling() or 1);
end

-- inner text width without padding. 
function Label:CalculateTextWidth()
	return _guihelper.GetTextWidth(self:GetText(), self:GetFont()) * (self:GetFontScaling() or 1);
end

function Label:SetPaddings(padding_left, padding_top, padding_right, padding_bottom)
	self.padding_left, self.padding_top, self.padding_right, self.padding_bottom = padding_left, padding_top, padding_right, padding_bottom;
end

function Label:paintEvent(painter)
	local x, y = self:x(), self:y();
	local text = self:GetText();
	if(text and text~="") then
		painter:SetFont(self:GetFont());
		painter:SetPen(self:GetColor());
		self:DrawTextScaledEx(painter, x+self.padding_left, y+self.padding_top, self:width()-self.padding_left-self.padding_right, self:height()-self.padding_top-self.padding_bottom, text, self:GetAlignment(), self:GetFontScaling());
	end
end

-- virtual: apply css style
function Label:ApplyCss(css)
	Label._super.ApplyCss(self, css);
	self:SetPaddings(css:paddings());
end

