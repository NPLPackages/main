--[[
Title: Progress
Author(s): wxa
Date: 2020/8/14
Desc: Div 元素
-------------------------------------------------------
local Progress = NPL.load("script/ide/System/UI/Window/Elements/Progress.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua");
local Progress = commonlib.inherit(Element, NPL.export());

Progress:Property("Name", "Progress");
Progress:Property("BaseStyle", {
	NormalStyle = {
		["background-color"] = "#EBEEF5",
		["width"] = "100px",
		["height"] = "10px",
	},
});

function Progress:ctor()
end

-- 渲染内容
function Progress:RenderContent(painter)
    local x, y, w, h = self:GetContentGeometry();
    local percentage = self:GetAttrNumberValue("percentage", 0);
    local color = self:GetAttrStringValue("color", "#909399");
    painter:SetPen(color);
    painter:DrawRect(x, y, w * percentage / 100, h);
end