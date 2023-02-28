--[[
Title: Radio
Author(s): wxa
Date: 2020/8/14
Desc: 按钮
-------------------------------------------------------
local Radio = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Radio.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua", IsDevEnv);
local Radio = commonlib.inherit(Element, NPL.export());

Radio:Property("Name", "Radio");
Radio:Property("GroupElement");           -- 所属组元素
Radio:Property("BaseStyle", {
    ["NormalStyle"] = {
        ["display"] = "inline-block",
        ["width"] = "20px",
        ["height"] = "20px",
        ["padding"] = "2px",
    }
});

function Radio:ctor()
    self.checked = false;
end

function Radio:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);

    self.value = self:GetAttrValue("value");
    self.checked = self:GetAttrBoolValue("checked", false);
    return self;
end

function Radio:OnClick(event)
    local name = self:GetAttrValue("name", "");
    local groupElement = self:GetGroupElement();
    if (groupElement) then
        groupElement:SetValue(self.value);
    else
        self:GetWindow():ForEach(function(element)
            if (element:GetName() == "Radio" and element:GetAttrValue("name", "") == name) then
                element.checked = false;
            end
        end);
    end

    self.checked = true;
    Radio._super.OnClick(self, event);

    self:OnChange(self.value);

    event:Accept();
end

function Radio:RenderContent(painter)
    local x, y, w, h = self:GetContentGeometry();
    local radius = math.min(w, h) / 2;
    local cx, cy = x + radius, y + radius;
    
    painter:Translate(cx, cy);
    painter:SetPen("#b5b5b5");
	painter:DrawCircle(0, 0, 0, radius, "z", true);

	painter:SetPen("#dedede");
	painter:DrawCircle(0, 0, 0, radius - 2, "z", true);

    if (self.checked) then
        painter:SetPen("#666666");
		painter:DrawCircle(0, 0, 0, radius-3, "z", true);
    end

    if(self:IsHover()) then
        painter:SetPen("#ffffff33");
        painter:DrawCircle(0, 0, 0, radius, "z");
    end

	painter:Translate(-cx, -cy);
end
	

	
