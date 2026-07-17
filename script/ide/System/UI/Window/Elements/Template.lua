--[[
Title: Template
Author(s): wxa
Date: 2020/8/14
Desc: Html 元素片段
-------------------------------------------------------
local Template = NPL.load("script/ide/System/UI/Window/Elements/Template.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua");
local Template= commonlib.inherit(Element, NPL.export());

function Template:ctor()
    self:SetName("template");
end

function Template:Load(html)
    local xmlnode = ParaXML.LuaXML_ParseString(html);
    -- 先清除子元素
    self:ClearChildElement();

    -- 加载子元素
    if (xmlnode) then
       self:InitChildElement(xmlnode, self:GetWindow());
    end

    -- 加载元素
    self:LoadElement();

    -- 文档化
    self:Attach();

    -- 更新布局
    self:UpdateLayout(true);
end

-- function Template:UpdateLayout(bApplyElementStyle, forceUpdate)
--     if (forceUpdate) then
--         Template._super.UpdateLayout(self, bApplyElementStyle);
--     end
-- end

-- function Template:Hover()
-- end
