--[[
Title: Space
Author(s): wxa
Date: 2020/6/30
Desc: 标签字段
use the lib:
-------------------------------------------------------
local Space = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Fields/Space.lua");
-------------------------------------------------------
]]

local Const = NPL.load("../Const.lua");
local Field = NPL.load("./Field.lua", IsDevEnv);
local Space = commonlib.inherit(Field, NPL.export());

Space:Property("ClassName", "FieldSpace");

function Space:RenderContent(painter)
end

function Space:UpdateWidthHeightUnitCount()
    return Const.FieldSpaceWidthUnitCount, Const.LineHeightUnitCount;
end

function Space:SaveToXmlNode()
    return nil;
end

function Space:LoadFromXmlNode(xmlNode)
end

function Space:IsCanEdit()
    return false;
end