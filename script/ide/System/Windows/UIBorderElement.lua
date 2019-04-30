--[[
Title: UIBorderElement
Author(s): LiXizhi
Date: 2015/4/29
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/UIBorderElement.lua");
local UIBorderElement = commonlib.gettable("System.Windows.UIBorderElement");
------------------------------------------------------------

]]
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
NPL.load("(gl)script/ide/math/Rect.lua");
local Rect = commonlib.gettable("mathlib.Rect");

local UIBorderElement = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.UIBorderElement"));
UIBorderElement:Property("Name", "UIBorderElement");

-- "Borders" is table, have four border: {left_border, top_border, right_border, bottom_border}, every border like as: {width = 2, style="solid", color="#ffffff"}
UIBorderElement:Property({"Borders", nil, auto=true});


function UIBorderElement:ctor()

end

function UIBorderElement:BorderVertex(side, indent)
	local x, y, w, h = self:x(), self:y(), self:width(), self:height();
	local v1, v2 = {x, y}, {x, y};
	if(side == "left") then
		v1, v2 = {x + indent, y + indent}, {x + indent, y + h - indent - 1};
	elseif(side == "top") then
		v1, v2 = {x + indent - 1, y + indent}, {x + w - indent, y + indent};
	elseif(side == "right") then
		v1, v2 = {x + w - indent, y + indent}, {x + w - indent, y + h - indent - 1};
	elseif(side == "bottom") then
		v1, v2 = {x + indent - 1, y + h - indent}, {x + w - indent, y + h - indent};
	end
	return v1, v2;
end

function UIBorderElement:DrawOneBorderSide(painter, border, side)
	if(border == nil) then
		return;
	end
	painter:SetPen(border.color);
	for i = 1, border.width do
		local v1, v2 = self:BorderVertex(side, i - 1);
		painter:DrawLine(v1[1], v1[2], v2[1], v2[2]);
	end
end

local sides = {"left", "top", "right", "bottom"};

function UIBorderElement:PaintBorderSides(painter)
	local borders = self:GetBorders();
	if(borders) then
		for i = 1, #borders do
			self:DrawOneBorderSide(painter, borders[i], sides[i]);
		end
	end
end

function UIBorderElement:paintEvent(painter)
	UIBorderElement._super.paintEvent(self, painter);
	self:PaintBorderSides(painter);
end

-- virtual: apply css style
function UIBorderElement:ApplyCss(css)
	UIBorderElement._super.ApplyCss(self, css);
	if(css:HasBorder()) then
		self:SetBorders(css:Border():Format());
	end
end
