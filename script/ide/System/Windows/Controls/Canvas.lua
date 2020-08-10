--[[
Title: Canvas
Author(s): LiXizhi
Date: 2015/4/20
Desc: draw anything custom on the canvas
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/Canvas.lua");
local Canvas = commonlib.gettable("System.Windows.Controls.Canvas");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
local Canvas = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.Controls.Canvas"));
Canvas:Property("Name", "Canvas");
Canvas:Property({"BackgroundColor", "#ffffff", auto=true});
Canvas:Property({"Background", nil, auto=true});

function Canvas:ctor()
end

function Canvas:paintEvent(painter)
	painter:Rotate(self:GetRotation() / math.pi * 180);
	painter:Scale(self:GetScalingX(), self:GetScalingY());
	painter:Translate(self:GetTranslationX(), self:GetTranslationY());

	local color = Color.Multiply(self:GetBackgroundColor(), self:GetColor());
	painter:SetPen(color);
	painter:DrawRectTexture(self:x(), self:y(), self:width(), self:height(), self:GetBackground());

	painter:Translate(-self:GetTranslationX(), -self:GetTranslationY());
	painter:Scale(1, 1);
	painter:Rotate(0);
end