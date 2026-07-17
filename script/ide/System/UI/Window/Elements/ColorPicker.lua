--[[
Title: Button
Author(s): wxa
Date: 2020/8/14
Desc: 颜色拾取器, 目前为blockly field_color 定制元素 可以移至blockly相关目录中
-------------------------------------------------------
local ColorPicker = NPL.load("script/ide/System/UI/Window/Elements/ColorPicker.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");

local Element = NPL.load("../Element.lua");
local ColorPicker = commonlib.inherit(Element, NPL.export());

ColorPicker:Property("Name", "ColorPicker");
ColorPicker:Property("Value", "");                                -- 按钮文本值

ColorPicker:Property("BaseStyle", {
    ["NormalStyle"] = {
        ["width"] = 145,
        ["height"] = 200,
        ["padding"] = "10px 22px ",
        ["background-color"] = "#ffffff",
        ["border"] = "1px solid #cccccc",
    }
});

function ColorPicker:ctor()
    --self.r, self.g, self.b = 255, 0, 0;
    self.h, self.s, self.l = 0, 1, 0.5;
end

function ColorPicker:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);

    local value = self:GetAttrValue("value", "#ff0000");
    self:SetColor(value);

    return self;
end

function ColorPicker:SetColor(color)
    local r,g,b,a = string.match(color or "", "(%x%x)(%x%x)(%x%x)(%x?%x?)")
    if (not r) then return end

    r = tonumber(r, 16);
    g = tonumber(g, 16);
    b = tonumber(b, 16);
    r = math.max(math.min(r, 255), 0);
    g = math.max(math.min(g, 255), 0);
    b = math.max(math.min(b, 255), 0);
    
    self.h, self.s, self.l = Color.rgb2hsl(r, g, b);

    self:SetValue(self:GetColor());
end

function ColorPicker:GetColor()
    local r, g, b = Color.hsl2rgb(self.h, self.s, self.l);
    return string.format("#%02x%02x%02x", r, g, b);
end

-- 绘制内容
function ColorPicker:RenderContent(painter)
    local x, y, w, h = self:GetContentGeometry();
    painter:Translate(x, y);

    local barWidth = w;
    local steps = 100;
    local colorWidth = barWidth / steps;
    local colorHeight = 20;
    local offsetX, offsetY, textOffsetX, colorOffsetY = 0, 0, 0, 4;
    local r, g, b = 255, 0, 0;
    painter:SetFont("System;12;norm")
    painter:SetPen("#000000");
    painter:DrawText(offsetX + textOffsetX, offsetY, string.format("颜色 %d", math.floor(self.h * 100)));
    offsetY = offsetY + 30;
    painter:DrawText(offsetX - 14, offsetY, "-");
    for i = 1, steps do
        r, g, b = Color.hsl2rgb(i/steps, self.s, self.l);
        painter:SetPen(string.format("#%02x%02x%02x", r, g, b));
        painter:DrawRect(offsetX + (i - 1) * colorWidth, offsetY, math.ceil(colorWidth), colorHeight);
    end
    painter:SetPen("#000000");
    painter:DrawText(offsetX + barWidth + 5, offsetY, "+");
    painter:DrawRect(offsetX + self.h * barWidth - 1, offsetY - colorOffsetY, 2, colorHeight + 2 * colorOffsetY);

    offsetY = offsetY + 30;
    painter:SetPen("#000000");
    painter:DrawText(offsetX + textOffsetX, offsetY, string.format("饱和度 %s", math.floor(self.s * 100)));
    offsetY = offsetY + 30;
    painter:DrawText(offsetX - 14, offsetY, "-");
    for i = 1, steps do
        r, g, b = Color.hsl2rgb(self.h, i/steps, self.l);
        painter:SetPen(string.format("#%02x%02x%02x", r, g, b));
        painter:DrawRect(offsetX + (i - 1) * colorWidth, offsetY, math.ceil(colorWidth), colorHeight);
    end
    painter:SetPen("#000000");
    painter:DrawText(offsetX + barWidth + 5, offsetY, "+");
    painter:DrawRect(offsetX + self.s * barWidth - 1, offsetY - colorOffsetY, 2, colorHeight + 2 * colorOffsetY);

    offsetY = offsetY + 30;
    painter:SetPen("#000000");
    painter:DrawText(offsetX + textOffsetX, offsetY, string.format("亮度  %s", math.floor(self.l * 100)));
    offsetY = offsetY + 30;
    painter:DrawText(offsetX - 14, offsetY, "-");
    for i = 1, steps do
        r, g, b = Color.hsl2rgb(self.h, self.s, i/steps);
        painter:SetPen(string.format("#%02x%02x%02x", r, g, b));
        painter:DrawRect(offsetX + (i - 1) * colorWidth, offsetY, math.ceil(colorWidth), colorHeight);
    end
    painter:SetPen("#000000");
    painter:DrawText(offsetX + barWidth + 5, offsetY, "+");
    painter:DrawRect(offsetX + self.l * barWidth - 1, offsetY - colorOffsetY, 2, colorHeight + 2 * colorOffsetY);

    painter:Translate(-x, -y);
end

function ColorPicker:OnMouseDown(event)
    local gx, gy = self:GetGeometry();
    local cx, cy, cw, ch = self:GetContentGeometry();
    local contentOffsetX, contentOffsetY = cx - gx, cy - gy;
    local barWidth = cw;

    local sx, sy = event:GetScreenXY();
    local rx, ry = self:GetRelPoint(sx, sy);
    local x, y = rx - contentOffsetX, ry - contentOffsetY - 30;
    if (0 <= y and y <= 20) then
        if (0 <= x and x <= barWidth) then
            self.h = x / barWidth;
        elseif (-14 <= x and x < 0) then
            self.h = math.max(self.h - 0.01, 0);
        elseif (barWidth < x and x <= barWidth + 20) then
            self.h = math.min(self.h + 0.01, 1);
        end
    end
    if (60 <= y and y <= 80) then
        if (0 <= x and x <= barWidth) then
            self.s = x / barWidth;
        elseif (-14 <= x and x < 0) then
            self.s = math.max(self.s - 0.01, 0);
        elseif (barWidth < x and x <= barWidth + 20) then
            self.s = math.min(self.s + 0.01, 1);
        end
    end
    if (120 <= y and y <= 140) then
        if (0 <= x and x <= barWidth) then
            self.l = x / barWidth;
        elseif (-14 <= x and x < 0) then
            self.l = math.max(self.l - 0.01, 0);
        elseif (barWidth < x and x <= barWidth + 20) then
            self.l = math.min(self.l + 0.01, 1);
        end
    end

    local color = self:GetColor();
    if (color ~= self:GetValue()) then
        self:SetValue(color);
        self:OnChange(color);
    end
    local window = self:GetWindow();
    if (window) then window:markDirty() end
end
