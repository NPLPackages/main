--[[
Title: Button
Author(s): wxa
Date: 2020/8/14
Desc: Loading
-------------------------------------------------------
local Loading = NPL.load("script/ide/System/UI/Window/Elements/Loading.lua");
-------------------------------------------------------
]]
local Element = NPL.load("../Element.lua");
local Loading = commonlib.inherit(Element, NPL.export());

Loading:Property("Name", "Canvas");
Loading:Property("BaseStyle", {
    ["NormalStyle"] = {
        ["width"] = "100%",
        ["height"] = "100%",
    }
})
function Loading:ctor()
    self:SetName("Loading");
    self.rotate = 0;
    self.tick = 0;
end

-- 绘制内容
function Loading:RenderContent(painter)
    local x, y, w, h = self:GetContentGeometry();
    local offsetX, offsetY = 0, 50;

    painter:Translate(x, y);
    painter:Translate(w / 2 - offsetX, h / 2 - offsetY);
    self.tick = self.tick + 1;
    if (self.tick > 10) then
        self.rotate = (self.rotate + 45) % 360;
        self.tick = 0;
    end

    local iconWidth, iconHeight = 114, 114;
    painter:Rotate(self.rotate);
    painter:SetPen("#ffffff");
    painter:DrawRectTexture(-iconWidth / 2, -iconHeight / 2, iconWidth, iconHeight, "Texture/Aries/Creator/keepwork/ggs/dialog/loading_114X114_32bits.png;0 0 114 114");
    painter:Rotate(-self.rotate);
    local textWidth, textHeight = 181, 23;
    painter:DrawRectTexture(-textWidth / 2 + 10, iconHeight / 2 + 20, textWidth, textHeight, "Texture/Aries/Creator/keepwork/ggs/dialog/zi_jiazaiz_181X23_32bits.png;0 0 181 23");

    painter:Translate(-w / 2 + offsetX, -h / 2 + offsetY);
    painter:Translate(-x, -y);
end