--[[
Title: TemplateList
Author(s): wxa
Date: 2020/8/14
Desc: Html 元素片段
-------------------------------------------------------
local TemplateList = NPL.load("script/ide/System/UI/Window/Elements/TemplateList.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua");
local Template = NPL.load("script/ide/System/UI/Window/Elements/Template.lua");
local TemplateList= commonlib.inherit(Element, NPL.export());

function TemplateList:ctor()
    self:SetName("template-list");
end

function TemplateList:AppendTemplate(html)
    local template = Template:new();
    template:InitElement({name = "template", attr = {}}, self:GetWindow(), self);
    template:Load(html);
    self:InsertChildElement(template);
    self:UpdateLayout();
    self:GetVerticalScrollBar():ScrollToEnd();
    self:GetWindow():Update();
    return template;
end

function TemplateList:OnBeforeUpdateChildLayout()
    return true;
end

function TemplateList:OnMouseWheel(event)
    self.m_auto_scroll = false;
    TemplateList._super.OnMouseWheel(self, event);
end

function TemplateList:ScrollToEnd()
    if (not self.m_auto_scroll) then return end
    self:GetVerticalScrollBar():ScrollToEnd();
end

function TemplateList:Hover()
end

-- local Page = NPL.load("script/ide/System/UI/Page.lua");
-- _G.IsDevEnv = true
-- Page.ShowVueTestPage(nil, {url="%vue%/Example/TemplateList.html"})