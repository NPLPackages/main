--[[
Title: QRCode
Author(s): wxa
Date: 2020/8/14
Desc: Label
-------------------------------------------------------
local QRCode = NPL.load("script/ide/System/UI/Window/Elements/QRCode.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Movie/QREncode.lua");
local QREncode = commonlib.gettable("MyCompany.Aries.Game.Movie.QREncode");

local Element = NPL.load("../Element.lua", IsDevEnv);
local QRCode = commonlib.inherit(Element, NPL.export());

QRCode:Property("Name", "QRCode");
QRCode:Property("BaseStyle", {
    ["NormalStyle"] = {
        ["display"] = "inline-block",
        ["width"] = "200px",
        ["height"] = "200px",
    }
});

function QRCode:ctor()
    self.qrcode = nil;
end

function QRCode:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);

    self:GenerateQRCode(self:GetAttrStringValue("url"));

    return self;
end

function QRCode:OnAttrValueChange(attrName, attrValue)
    if (attrName == "url") then
        self:GenerateQRCode(attrValue);
    end
end

function QRCode:GenerateQRCode(url)
    local ok, qrcode = QREncode.qrcode(url or "ParaCraft");
    if (not ok) then return end
	self.qrcode = qrcode;
end

-- 绘制内容
function QRCode:RenderContent(painter)
    if (not self.qrcode) then return end
    local x, y, w, h = self:GetContentGeometry();

    painter:Translate(x, y);
    painter:SetPen(self:GetColor("#000000ff"));

    local block_size = w / #(self.qrcode);
	for i = 1, #(self.qrcode) do
		for j = 1, #(self.qrcode[i]) do
			local code = self.qrcode[i][j];
			if (code < 0) then
				painter:DrawRect((i-1) * block_size, (j-1) * block_size, block_size, block_size);
			end
		end
    end
    
    painter:Translate(-x, -y);
end