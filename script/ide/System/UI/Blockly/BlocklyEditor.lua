--[[
Title: G
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local BlocklyEditor = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/BlocklyEditor.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Window/Element.lua", IsDevEnv);

local BlocklyEditor = commonlib.inherit(Element, NPL.export());

BlocklyEditor:Property("Name", "BlocklyEditor");
BlocklyEditor:Property("Blockly");

function BlocklyEditor:OnMouseDown(event)
    event:Accept();
end

function BlocklyEditor:OnMouseMove(event)
    event:Accept();
end

function BlocklyEditor:OnMouseUp(event)
    event:Accept();
end

-- 目前只有定位元素才具备这样实现
function BlocklyEditor:Render(painter, root)
    local scale = self:GetBlockly():GetScale();
    painter:Scale(scale, scale);
    BlocklyEditor._super.Render(self, painter, root);
    painter:Scale(1 / scale, 1 / scale);
end

function BlocklyEditor:SaveEvent(event)
    local blockly = self:GetBlockly();
    local relx, rely = blockly:ScreenPointToRelativePoint(event.x, event.y);
    local scale = blockly:GetScale();
    self.event_x, self.event_y = event.x, event.y;
    event.x, event.y = blockly:RelativePointToScreenPoint(relx / scale, rely / scale);
end

function BlocklyEditor:RestoreEvent(event)
    event.x, event.y = self.event_x, self.event_y;
end

-- 悬浮捕捉
function BlocklyEditor:Hover(event, isUpdateLayout, zindex, isParentElementHover, isParentPositionElement, scrollElement)
    self:SaveEvent(event);
    local element, zindex = BlocklyEditor._super.Hover(self, event, isUpdateLayout, zindex, isParentElementHover, isParentPositionElement, scrollElement);
    self:RestoreEvent(event);
    return element, zindex;
end

-- 事件捕捉
function BlocklyEditor:GetMouseHoverElement(event, zindex, isParentElementHover, isParentPositionElement, scrollElement)
    self:SaveEvent(event);
    local element, zindex = BlocklyEditor._super.GetMouseHoverElement(self, event, zindex, isParentElementHover, isParentPositionElement, scrollElement);
    self:RestoreEvent(event);
    return element, zindex;
end

-- 事件处理前
function BlocklyEditor:HandleMouseEventBefore(event)
    self:SaveEvent(event);
end

-- 事件处理后
function BlocklyEditor:HandleMouseEventAfter(event)
    self:RestoreEvent(event);
end