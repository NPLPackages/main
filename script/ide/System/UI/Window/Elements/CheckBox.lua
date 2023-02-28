--[[
Title: CheckBox
Author(s): wxa
Date: 2020/8/14
Desc: 复选框
-------------------------------------------------------
local CheckBox = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/CheckBox.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Element.lua", IsDevEnv);
local CheckBox = commonlib.inherit(Element, NPL.export());

local pen = {width = 2, color = "#000000"};
local lines = {{}, {}, {}, {}};

CheckBox:Property("Name", "CheckBox");
CheckBox:Property("GroupElement");           -- 所属组元素
CheckBox:Property("BaseStyle", {
    ["NormalStyle"] = {
        ["display"] = "inline-block",
        ["width"] = "20px",
        ["height"] = "20px",
        ["padding"] = "2px",
    }
});

function CheckBox:ctor()
    self.checked = false;
end

function CheckBox:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);

    self.name = self:GetAttrValue("name", "");
    self.value = self:GetAttrValue("value");

    return self;
end

function CheckBox:OnClick(event)
    self.checked = not self.checked;
    CheckBox._super.OnClick(self, event);

    local groupElement = self:GetGroupElement();
    if (groupElement) then 
        if (self.checked) then
            groupElement:AddCheckedValue(self.value); 
        else
            groupElement:RemoveCheckedValue(self.value); 
        end
    end
    
    event:Accept();
end

function CheckBox:RenderContent(painter)
    local x, y, w, h = self:GetContentGeometry();
    
    painter:SetPen("#b5b5b5");
	painter:DrawRect(x, y, w, h);

    x, y, w, h = x + 2, y + 2, w - 4, h - 4;
    painter:SetPen("#dedede");
	painter:DrawRect(x, y, w, h);

    if (self.checked) then
        pen.width = 2;
        pen.color = "#b5b5b5";
        painter:SetPen(pen);
        lines[1][1] = math.ceil(x + w * 1 / 4);
        lines[1][2] = math.ceil(y + h * 1 / 2);
        lines[1][3] = 0;
        lines[2][1] = math.ceil(x + w / 2);
        lines[2][2] = math.ceil(y + h * 3 / 4);
        lines[2][3] = 0;
        lines[3] = lines[2];
        lines[4][1] = math.ceil(x + w * 3 / 4);
        lines[4][2] = math.ceil(y + h / 4);
        lines[4][3] = 0;
        painter:DrawLineList(lines);
    end
end
	

	
