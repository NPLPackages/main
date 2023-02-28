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
        ["width"] = 300,
        ["height"] = 200,
        ["padding"] = "10px 22px ",
        ["background-color"] = "#ffffff",
        ["border"] = "1px solid #cccccc",
    }
});

function ColorPicker:ctor()
    self.r, self.g, self.b = 255, 0, 0;
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
    self.r = math.max(math.min(r, 255), 0);
    self.g = math.max(math.min(g, 255), 0);
    self.b = math.max(math.min(b, 255), 0);

    self:SetValue(self:GetColor());
end

function ColorPicker:GetColor()
    return string.format("#%02x%02x%02x", self.r, self.g, self.b);
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

    painter:SetPen("#000000");
    painter:DrawText(offsetX + textOffsetX, offsetY, string.format("R = %s", self.r));
    offsetY = offsetY + 30;
    painter:DrawText(offsetX - 14, offsetY, "-");
    for i = 1, 255 do
        painter:SetPen(string.format("#%02x%02x%02x", i, self.g, self.b));
        painter:DrawRect(offsetX + (i - 1) * colorWidth, offsetY, colorWidth, colorHeight);
    end
    painter:SetPen("#000000");
    painter:DrawText(offsetX + 260, offsetY, "+");
    painter:DrawRect(offsetX + (self.r - 1) * colorWidth, offsetY - colorOffsetY, colorWidth, colorHeight + 2 * colorOffsetY);

    offsetY = offsetY + 30;
    painter:SetPen("#000000");
    painter:DrawText(offsetX + textOffsetX, offsetY, string.format("G = %s", self.g));
    offsetY = offsetY + 30;
    painter:DrawText(offsetX - 14, offsetY, "-");
    for i = 1, 255 do
        painter:SetPen(string.format("#%02x%02x%02x", self.r, i, self.b));
        painter:DrawRect(offsetX + (i - 1) * colorWidth, offsetY, colorWidth, colorHeight);
    end
    painter:SetPen("#000000");
    painter:DrawText(offsetX + 260, offsetY, "+");
    painter:DrawRect(offsetX + (self.g - 1) * colorWidth, offsetY - colorOffsetY, colorWidth, colorHeight + 2 * colorOffsetY);

    offsetY = offsetY + 30;
    painter:SetPen("#000000");
    painter:DrawText(offsetX + textOffsetX, offsetY, string.format("B = %s", self.b));
    offsetY = offsetY + 30;
    painter:DrawText(offsetX - 14, offsetY, "-");
    for i = 1, 255 do
        painter:SetPen(string.format("#%02x%02x%02x", self.r, self.g, i));
        painter:DrawRect(offsetX + (i - 1) * colorWidth, offsetY, colorWidth, colorHeight);
    end
    painter:SetPen("#000000");
    painter:DrawText(offsetX + 260, offsetY, "+");
    painter:DrawRect(offsetX + (self.b - 1) * colorWidth, offsetY - colorOffsetY, colorWidth, colorHeight + 2 * colorOffsetY);

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
        if (0 <= x and x <= 255) then
            self.r = x;
        elseif (-16 <= x and x <= 0) then
            self.r = self.r - 1;
            self.r = math.max(self.r, 0);
        elseif (255 <= x and x <= 270) then
            self.r = self.r + 1;
            self.r = math.min(self.r, 255);
        end
    end
    if (60 <= y and y <= 80) then
        if (0 <= x and x <= 255) then
            self.g = x;
        elseif (-16 <= x and x <= 0) then
            self.g = self.g - 1;
            self.g = math.max(self.g, 0);
        elseif (255 <= x and x <= 270) then
            self.g = self.g + 1;
            self.g = math.min(self.g, 255);
        end
    end
    if (120 <= y and y <= 140) then
        if (0 <= x and x <= 255) then
            self.b = x;
        elseif (-16 <= x and x <= 0) then
            self.b = self.b - 1;
            self.b = math.max(self.b, 0);
        elseif (255 <= x and x <= 270) then
            self.b = self.b + 1;
            self.b = math.min(self.b, 255);
        end
    end

    local color = self:GetColor();
    if (color ~= self:GetValue()) then
        self:SetValue(color);
        self:OnChange(color);
    end
end
