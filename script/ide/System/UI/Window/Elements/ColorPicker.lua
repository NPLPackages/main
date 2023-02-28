--[[
Title: Button
Author(s): wxa
Date: 2020/8/14
Desc: 颜色拾取器, 目前为blockly field_color 定制元素 可以移至blockly相关目录中
-------------------------------------------------------
local ColorPicker = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/ColorPicker.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");

local Element = NPL.load("../Element.lua", IsDevEnv);
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

    -- local targetColorWidth, targetColorHeight = 40, 20;
    -- painter:SetPen(string.format("#%02x%02x%02x", self.r, self.g, self.b));
    -- painter:DrawRect(w / 2 - targetColorWidth / 2, 10, targetColorWidth, targetColorHeight);
    -- offsetY = offsetY + 30;
    
    local colorWidth, colorHeight = 1, 20;
    local offsetX, offsetY, textOffsetX, colorOffsetY = 0, 0, 0, 4;
    local r, g, b = 255, 0, 0;

    painter:SetPen("#000000");
    painter:DrawText(offsetX + textOffsetX, offsetY, string.format("颜色 %d", math.floor(self.h * 100)));
    offsetY = offsetY + 30;
    painter:DrawText(offsetX - 14, offsetY, "-");
    for i = 1, 100 do
        r, g, b = Color.hsl2rgb(i/100, self.s, self.l);
        painter:SetPen(string.format("#%02x%02x%02x", r, g, b));
        painter:DrawRect(offsetX + (i - 1) * colorWidth, offsetY, colorWidth, colorHeight);
    end
    painter:SetPen("#000000");
    painter:DrawText(offsetX + 105, offsetY, "+");
    painter:DrawRect(offsetX + (self.h*100 - 1) * colorWidth, offsetY - colorOffsetY, colorWidth, colorHeight + 2 * colorOffsetY);

    offsetY = offsetY + 30;
    painter:SetPen("#000000");
    painter:DrawText(offsetX + textOffsetX, offsetY, string.format("饱和度 %s", math.floor(self.s * 100)));
    offsetY = offsetY + 30;
    painter:DrawText(offsetX - 14, offsetY, "-");
    for i = 1, 100 do
        r, g, b = Color.hsl2rgb(self.h, i/100, self.l);
        painter:SetPen(string.format("#%02x%02x%02x", r, g, b));
        painter:DrawRect(offsetX + (i - 1) * colorWidth, offsetY, colorWidth, colorHeight);
    end
    painter:SetPen("#000000");
    painter:DrawText(offsetX + 105, offsetY, "+");
    painter:DrawRect(offsetX + (self.s*100 - 1) * colorWidth, offsetY - colorOffsetY, colorWidth, colorHeight + 2 * colorOffsetY);

    offsetY = offsetY + 30;
    painter:SetPen("#000000");
    painter:DrawText(offsetX + textOffsetX, offsetY, string.format("亮度  %s", math.floor(self.l * 100)));
    offsetY = offsetY + 30;
    painter:DrawText(offsetX - 14, offsetY, "-");
    for i = 1, 100 do
        r, g, b = Color.hsl2rgb(self.h, self.s, i/100);
        painter:SetPen(string.format("#%02x%02x%02x", r, g, b));
        painter:DrawRect(offsetX + (i - 1) * colorWidth, offsetY, colorWidth, colorHeight);
    end
    painter:SetPen("#000000");
    painter:DrawText(offsetX + 105, offsetY, "+");
    painter:DrawRect(offsetX + (self.l*100 - 1) * colorWidth, offsetY - colorOffsetY, colorWidth, colorHeight + 2 * colorOffsetY);

    painter:Translate(-x, -y);
end

function ColorPicker:OnMouseDown(event)
    local x, y  = self:GetGeometry();
    local cx, cy = self:GetContentGeometry();
    local offsetX, offsetY = cx - x, cy - y;

    x, y = event:GetScreenXY();
    x, y = self:GetRelPoint(x, y);
    x, y = x - offsetX, y - offsetY - 30;
    if (0 <= y and y <= 20) then
        if (0 <= x and x <= 100) then
            self.h = x / 100;
        elseif (-10 <= x and x <= 0) then
            self.h = self.h - 0.01;
            self.h = math.max(self.h, 0);
        elseif (100 <= x and x <= 120) then
            self.h = self.h + 0.01;
            self.h = math.min(self.h, 1);
        end
    end
    if (60 <= y and y <= 80) then
        if (0 <= x and x <= 100) then
            self.s = x / 100;
        elseif (-10 <= x and x <= 0) then
            self.s = self.s - 0.01;
            self.s = math.max(self.s, 0);
        elseif (100 <= x and x <= 120) then
            self.s = self.s + 0.01;
            self.s = math.min(self.s, 1);
        end
    end
    if (120 <= y and y <= 140) then
        if (0 <= x and x <= 100) then
            self.l = x / 100;
        elseif (-10 <= x and x <= 0) then
            self.l = self.l - 0.01;
            self.l = math.max(self.l, 0);
        elseif (100 <= x and x <= 120) then
            self.l = self.l + 0.01;
            self.l = math.min(self.l, 1);
        end
    end

    local color = self:GetColor();
    if (color ~= self:GetValue()) then
        self:SetValue(color);
        self:OnChange(color);
    end
end
