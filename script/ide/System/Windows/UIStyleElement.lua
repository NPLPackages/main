--[[
Title: UIStyleElement
Author(s): LiXizhi
Date: 2015/4/29
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/UIStyleElement.lua");
local UIStyleElement = commonlib.gettable("System.Windows.UIStyleElement");
------------------------------------------------------------

]]
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
NPL.load("(gl)script/ide/math/Rect.lua");
NPL.load("(gl)script/ide/math/Point.lua");
local Point = commonlib.gettable("mathlib.Point");
local Rect = commonlib.gettable("mathlib.Rect");

local UIStyleElement = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.UIStyleElement"));
UIStyleElement:Property("Name", "UIStyleElement");

-- "Borders" is table, have four border: {left_border, top_border, right_border, bottom_border}, every border like as: {width = 2, style="solid", color="#ffffff"}
UIStyleElement:Property({"Borders", nil, auto=true});


function UIStyleElement:ctor()

end

function UIStyleElement:BorderVertex(side, indent)
	local x, y, w, h = self:x(), self:y(), self:width(), self:height();
	local v1, v2 = Point:new_from_pool(x, y), Point:new_from_pool(x, y);
	if(side == "left") then
		v1:set(x + 1 + indent, y + indent);
		v2:set(x + 1 + indent, y + h - indent);
--		v1:set(x + indent, y + indent);
--		v2:set(x + indent, y + h - indent - 1);
		--v1, v2 = {x + indent, y + indent}, {x + indent, y + h - indent - 1};
	elseif(side == "top") then
		v1:set(x + indent, y + indent + 1);
		v2:set(x + w - indent, y + indent + 1);
--		v1:set(x + indent - 1, y + indent);
--		v2:set(x + w - indent, y + indent);
		--v1, v2 = {x + indent - 1, y + indent}, {x + w - indent, y + indent};
	elseif(side == "right") then
		v1:set(x + w - indent, y + indent);
		v2:set(x + w - indent, y + h - indent);
--		v1:set(x + w - indent, y + indent);
--		v2:set(x + w - indent, y + h - indent - 1);
		--v1, v2 = {x + w - indent, y + indent}, {x + w - indent, y + h - indent - 1};
	elseif(side == "bottom") then
		v1:set(x + indent, y + h - indent);
		v2:set(x + w - indent, y + h - indent);
--		v1:set(x + indent - 1, y + h - indent);
--		v2:set(x + w - indent, y + h - indent);
		--v1, v2 = {x + indent - 1, y + h - indent}, {x + w - indent, y + h - indent};
	end
	return v1, v2;
end

function UIStyleElement:DrawOneBorderSide(painter, border, side)
	if(border == nil) then
		return;
	end
	painter:SetPen(border.color);
	for i = 1, border.width do
		local v1, v2 = self:BorderVertex(side, i - 1);
		painter:DrawLine(v1:x(), v1:y(), v2:x(), v2:y());
	end
end

local sides = {"left", "top", "right", "bottom"};

function UIStyleElement:PaintBorderSides(painter)
	local borders = self:GetBorders();
	if(borders) then
		--echo("UIStyleElement:PaintBorderSides")
		for i = 1, #borders do
			self:DrawOneBorderSide(painter, borders[i], sides[i]);
		end
	end
end

function UIStyleElement:ContentRect()
	local borders = self:GetBorders();
	if(borders) then
		local b_left, b_top, b_right, b_bottom = borders[1]["width"], borders[2]["width"], borders[3]["width"], borders[4]["width"];
		local x, y, w, h = b_left, b_top, self:width() - b_left - b_right, self:height() - b_top - b_bottom;
		return Rect:new_from_pool(x, y, w, h);
	end
	return UIStyleElement._super.ContentRect(self);
end

function UIStyleElement:PaintBorder(painter)
	self:PaintBorderSides(painter);
end

function UIStyleElement:PaintBackground(painter)
	local background_color, background_image = self:GetBackgroundColor(), self:GetBackground();
	if(background_color or background_image) then
		local content_rect = self:ContentRect();
		painter:SetPen(background_color);
		painter:DrawRectTexture(self:x() + content_rect:x(), self:y() + content_rect:y(), content_rect:width(), content_rect:height(), background_image);	
	end
end

function UIStyleElement:PaintBoxDecorations(painter)
	self:PaintBackground(painter);
	self:PaintBorder(painter);
end

function UIStyleElement:paintEvent(painter)
	UIStyleElement._super.paintEvent(self, painter);
	self:PaintBoxDecorations(painter);
end

-- virtual: apply css style
function UIStyleElement:ApplyCss(css)
	UIStyleElement._super.ApplyCss(self, css);
	if(css:HasBorder()) then
		self:SetBorders(css:Border():Format());
	end
end
