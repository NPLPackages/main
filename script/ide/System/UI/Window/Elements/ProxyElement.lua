--[[
Title: ProxyElement
Author(s): wxa
Date: 2020/8/14
Desc: ProxyElement 元素
-------------------------------------------------------
local ProxyElement = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/ProxyElement.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua");
local ProxyElement = commonlib.inherit(Element, NPL.export());

ProxyElement:Property("Name", "ProxyElement");
ProxyElement:Property("ProxyElement");                            -- 代理元素

-- 组件构造函数
function ProxyElement:ctor()
end

-- 初始化
function ProxyElement:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);
    self:InitChildElement(xmlNode, window);
    self:LoadProxyElement(xmlNode, window, parent);
    return self;
end

function ProxyElement:LoadProxyElement(xmlNode, window, parent)
    local tagname = self:GetAttrStringValue("is");
    tagname = tagname and tagname ~= "" and tagname or "div";
    local ProxyElementClass = self:GetElementByTagName(tagname);
    if (not ProxyElementClass) then
        self:SetProxyElement(nil);
        return;
    end
    local proxyElement = ProxyElementClass:new():Init({name = tagname}, window, nil);
    self:SetProxyElement(proxyElement);
    return;
end

function ProxyElement:UpdateLayout(bApplyElementStyle)
    ProxyElement._super.UpdateLayout(self, bApplyElementStyle);

    local proxyElement = self:GetProxyElement();
    if (not proxyElement) then return end

    local style = self:GetStyle();
    local width, height = self:GetSize();
    local proxyStyle = proxyElement:GetAttrStyle();
    for key, val in pairs(style) do 
        if (type(val) == "string" or type(val) == "number") then
            proxyStyle[key] = val;
        end
    end
    proxyStyle.position, proxyStyle.left, proxyStyle.top, proxyStyle.width, proxyStyle.height = nil, nil, nil, width, height;

    proxyElement:ApplyElementStyle();
    proxyElement:UpdateLayout(bApplyElementStyle);
end

function ProxyElement:Attach()
    ProxyElement._super.Attach(self);

    local proxyElement = self:GetProxyElement();
    if (not proxyElement) then return end
    
    proxyElement:Attach();
end

function ProxyElement:Detach()
    ProxyElement._super.Detach(self);

    local proxyElement = self:GetProxyElement();
    if (not proxyElement) then return end
    
    proxyElement:Detach();
end

function ProxyElement:OnRender()
end

function ProxyElement:RenderStaticElement(painter, root)
    local proxyElement = self:GetProxyElement();
    if (proxyElement) then 
        local left, top = self:GetPosition();
        painter:Translate(left, top);
        proxyElement:RenderStaticElement(painter, root);
        painter:Translate(-left, -top);
    end

    ProxyElement._super.RenderStaticElement(self, painter, root);
end

function ProxyElement:OnAttrValueChange(attrName, attrValue, oldAttrValue)
    ProxyElement._super.OnAttrValueChange(self, attrName, attrValue, oldAttrValue);
    if (attrName ~= "is") then return end
    self:LoadProxyElement(self:GetXmlNode(), self:GetWindow());
    self:UpdateLayout(true);
end

function ProxyElement:SetSize(width, height)
    ProxyElement._super.SetSize(self, width, height);

    local proxyElement = self:GetProxyElement();
    if (not proxyElement) then return end

    proxyElement:SetSize(width, height);
end