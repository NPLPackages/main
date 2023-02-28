--[[
Title: Text
Author(s): wxa
Date: 2020/8/14
Desc: 文本
-------------------------------------------------------
local Text = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Controls/Text.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua", IsDevEnv);

local Text = commonlib.inherit(Element, NPL.export());

local TextDebug = GGS.Debug.GetModuleDebug("TextDebug").Disable();  -- Enable() Disable;

Text:Property("Value");  -- 文本值
Text:Property("Name", "Text");
Text:Property("BaseStyle", {
	NormalStyle = {
		["display"] = "inline",
	}
});

-- 处理实体字符
local function ReplaceEntityReference(value)
	value = string.gsub(value or "", "&?nbsp;", " ");
	return value;
end

function Text:ctor()
	self.texts = {};
end

-- public:
function Text:Init(xmlNode, window, parent)
	self:InitElement(xmlNode, window, parent);

	-- 处理实体字符
	self:SetValue(self:GetInnerText() or "");

	return self;
end

function Text:Clone()
	local clone = Text:new():Init(self:GetXmlNode(), self:GetWindow(), self:GetParentElement());
	clone:SetValue(self:GetValue());
	return clone;
end

function Text:FormatText(text)
	text = ReplaceEntityReference(text);
	text = string.gsub(text, "\t", "    ");
	
	local whiteSpace = self:GetStyle():GetWhiteSpace();

	text = string.gsub(text, "\r\n", "\n");
	if (whiteSpace == "pre") then
	else  -- normal
		text = string.gsub(text, "%s", " ");
	end

	return text;
end

function Text:SetText(value)
	if (value == self:GetValue()) then return end
	self:SetValue(value or "");
	self:UpdateLayout();
end

function Text:GetText()
	return self:FormatText(self:GetValue() or "");
end

function Text:GetTextAlign()
	return self:GetStyle():GetTextAlign();
end

local function CalculateTextLayout(self, text, width, left, top)
	TextDebug.FormatIf(self:GetParentElement():GetAttrStringValue("id") == "debug", "CalculateTextLayout, text = %s, width = %s, left = %s, top = %s", text, width, left, top);
	if(not text or text == "") then return 0, 0 end

	local textWidth, textHeight = _guihelper.GetTextWidth(text, self:GetFont()), self:GetLineHeight();
	local remaining_text = nil;

	if(width and width > 0 and textWidth > width) then
		text, remaining_text = _guihelper.TrimUtf8TextByWidth(text, width, self:GetFont())
		textWidth = _guihelper.GetTextWidth(text, self:GetFont());
		if (textWidth == 0) then 
			text, remaining_text = remaining_text, nil;
			textWidth = _guihelper:GetTextWidth(text, self:GetFont());
		end
	end

	TextDebug.FormatIf(self:GetParentElement():GetAttrStringValue("id") == "debug", "text = %s, x = %s, y = %s, w = %s, h = %s", text, left, top, textWidth, textHeight);
	local textObject = {text = text, x = left, y = top, w = textWidth, h = textHeight};
	table.insert(self.texts, textObject);
	
	local textAlign = self:GetTextAlign();
	if(width and width > 0 and width > textWidth and textAlign) then
		if(textAlign == "right") then
			textObject.x = left + width - textWidth;
		elseif(textAlign == "center") then
			textObject.x = left + (width - textWidth) / 2;
		end
	end
	
	if (remaining_text and remaining_text ~= "") then
		local remainingWidth, remainingHeight = CalculateTextLayout(self, remaining_text, width, left, top + textHeight);
		textHeight = textHeight + remainingHeight;
	end

	return textWidth, textHeight;
end

function Text:OnUpdateLayout()
	local layout, parentStyle = self:GetLayout(), self:GetParentElement():GetStyle();
	local parentLayout = self:GetParentElement():GetLayout();
	local parentContentWidth, parentContentHeight = parentLayout:GetFixedContentWidthHeight();
	local width, height = layout:GetFixedWidthHeight();
	local left, top = 0, 0;
	local textWidth, textHeight = 0, 0;
	local text = self:GetText();
	self.texts = {};

	TextDebug.FormatIf(self:GetParentElement():GetAttrStringValue("id") == "debug", "width = %s, height = %s, parentWidth = %s, parentHeight = %s, parentIsFixedWidth = %s", width, height, parentContentWidth, parentContentHeight, parentLayout:IsFixedWidth());
	if (parentStyle["text-wrap"] == "none") then
		--  不换行
		local textWidth, textHeight = _guihelper.GetTextWidth(text, self:GetFont()), self:GetLineHeight();
		local textObject = {text = text, x = 0, y = 0, w = textWidth, h = textHeight}
		table.insert(self.texts, textObject);
		height = height or parentContentHeight or textHeight;
		width = width or parentContentWidth or textWidth;
		if (width < textWidth) then
			if (parentStyle["text-overflow"] == "ellipsis") then
				textObject.text = _guihelper.AutoTrimTextByWidth(text, width - 16, self:GetFont()) .. "...";
			else
				textObject.text = _guihelper.AutoTrimTextByWidth(text, width, self:GetFont());
			end
			textObject.width = width;
		end
	else
		-- 自动换行
		local textlines = commonlib.split(text, "\n");
		for _, textline in ipairs(textlines) do
			local linewidth, lineheight = CalculateTextLayout(self, textline, width or parentContentWidth, left, top);
			textWidth = math.max(linewidth, textWidth);
			textHeight = textHeight + lineheight;
			top = top + lineheight;
		end
		height = height or textHeight;
		width = width or textWidth;
		-- TextDebug(text, self.texts);
	end

	TextDebug.FormatIf(self:GetParentElement():GetAttrStringValue("id") == "debug", "OnBeforeUpdateChildElementLayout, width = %s, height = %s, textCount = %s", width, height, #self.texts);

	self:GetLayout():SetWidthHeight(width or textWidth, height or textHeight);
    return true; 
end

-- 绘制文本
function Text:OnRender(painter)
	local style, layout = self:GetStyle(), self:GetLayout();
	local fontSize = self:GetFontSize(14)
	local lineHeight = self:GetLineHeight();
	local linePadding = (lineHeight - fontSize) / 2 - fontSize / 6;
	-- local linePadding = (lineHeight - self:GetSingleLineTextHeight()) / 2;
	local left, top = layout:GetPos();

	painter:SetFont(self:GetFont());
	painter:SetPen(self:GetColor("#000000"));
	for i = 1, #self.texts do
		local obj = self.texts[i];
		local x, y, text = left + obj.x, top + obj.y + linePadding, obj.text;

		-- TextDebug.FormatIf(self:GetParentElement():GetAttrStringValue("id") == "debug", "OnReader, x = %s, y = %s, text = %s", x, y, text);

		painter:DrawText(x, y, text);
	end
end