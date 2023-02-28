--[[
Title: Color
Author(s): wxa
Date: 2020/6/30
Desc: 对象字段
use the lib:
-------------------------------------------------------
local Color = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Color.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/Json.lua");

local Const = NPL.load("../Const.lua");
local Shape = NPL.load("../Shape.lua");
local Field = NPL.load("./Field.lua", IsDevEnv);

local Color = commonlib.inherit(Field, NPL.export());

function Color:UpdateWidthHeightUnitCount()
    return Const.MinTextShowWidthUnitCount, Const.LineHeightUnitCount;
end
     
function Color:RenderContent(painter)
    Shape:SetBrush(self:GetValue());
    Shape:DrawInputValue(painter, self.widthUnitCount, self.heightUnitCount);
end

function Color:GetFieldEditType()
    return "color";
end
