--[[
Title: BlockElement
Author(s): wxa
Date: 2020/6/30
Desc: 图块预览
use the lib:
-------------------------------------------------------
local BlockElement = NPL.load("script/ide/System/UI/Blockly/BlockElement.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Window/Element.lua", IsDevEnv);
local Block = NPL.load("./Block.lua")
local BlocklyElement = commonlib.inherit(Element, NPL.export());

Canvas:Property("Name", "BlocklyElement");
Canvas:Property("BaseStyle", {
    ["NormalStyle"] = {
        ["min-width"] = "350px",
        ["min-height"] = "150px",
    }
});


function BlocklyElement:OnAttrValueChange(attrName, attrValue, oldAttrValue)
    if (attrName == "BlockOption") then
    end
end