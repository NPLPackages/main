--[[
Title: Div
Author(s): wxa
Date: 2020/8/14
Desc: DateTimeText 元素
-------------------------------------------------------
local DateTimeText = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/DateTimeText.lua");
-------------------------------------------------------
]]


local Element = NPL.load("../Element.lua");
local DateTimeText = commonlib.inherit(Element, NPL.export());

DateTimeText:Property("Name", "DateTimeText");

function DateTimeText:ctor()
end

function DateTimeText:GetText()
    local fmt = self:GetAttrStringValue("fmt", "%H:%M");
    local text = os.date(fmt, os.time());
    return text;
end

function DateTimeText:OnUpdateLayout()
    local text = self:GetText();
	local textWidth, textHeight = _guihelper.GetTextWidth(text, self:GetFont()), self:GetLineHeight();
	local width, height = self:GetLayout():GetFixedWidthHeight();
	self:GetLayout():SetWidthHeight(width or textWidth, height or textHeight);
    return true; 
end

-- 绘制内容
function DateTimeText:RenderContent(painter)
    local text = self:GetText();
    local x, y, w, h = self:GetContentGeometry();

    painter:SetFont(self:GetFont());
	painter:SetPen(self:GetColor("#000000"));
    painter:DrawText(x, y, text);
end