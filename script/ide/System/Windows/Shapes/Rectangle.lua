--[[
Title: Rectangle
Author(s): LiXizhi
Date: 2015/4/23
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Shapes/Rectangle.lua");
local Rectangle = commonlib.gettable("System.Windows.Shapes.Rectangle");
local rcShape = Rectangle:new():init(parent);
rcShape:SetBackgroundColor("#ff0000")
rcShape:setGeometry(0,0,100,32);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
local Rectangle = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.Shapes.Rectangle"));
Rectangle:Property("Name", "Rectangle");
Rectangle:Property({"BackgroundColor", "#ffffff", auto=true});
Rectangle:Property({"Background", "", auto=true});
Rectangle:Property({"Rotation", nil, auto=true});
Rectangle:Property({"UVWrappingEnabled", nil, auto=true});
Rectangle:Property({"zorder", nil, "SetZorder", "GetZorder", auto=true});

function Rectangle:ctor()
end

-- virtual: render everything here
-- @param painter: painterContext
function Rectangle:paintEvent(painter)
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

