
--[[
Title: Note
Author(s): wxa
Date: 2020/6/30
Desc: Note
use the lib:
-------------------------------------------------------
local Note = NPL.load("script/ide/System/UI/Blockly/Note.lua");
-------------------------------------------------------
]]

local Element = NPL.load("../Window/Element.lua");
local TextArea = NPL.load("../Window/Elements/TextArea.lua");

local Const = NPL.load("./Const.lua");
local DEFAULT_EXPAND_HEIGHT = 30;
local Note = commonlib.inherit(Element, NPL.export());

local Draggable = commonlib.inherit(Element, {});
Draggable:Property("Note");
Draggable:Property("TextArea");

function Draggable:RenderContent(painter)
    local x, y, w, h = self:GetGeometry();
    painter:SetPen("#E4DB8C");
    painter:DrawLine(x, y + h - 2, x + w - 2, y);
    painter:DrawLine(x + 4, y + h - 2, x + w - 2, y + 4);
end

function Draggable:OnMouseDown(event)
    self.isMouseDown = true;
    self.startDragX, self.startDragY = event:GetScreenXY();
    self.startDragElementX, self.startDragElementY = self:GetPosition();
    self.noteWidth, self.noteHeight = self:GetNote():GetSize();
    self.textareaWidth, self.textareaHeight = self:GetTextArea():GetSize();
    self:CaptureMouse();
    event:Accept();
end

function Draggable:OnMouseMove(event)
    if (not self.isMouseDown) then return end 
    self.dragMoveX, self.dragMoveY = event:GetScreenXY();
    local offsetX, offsetY = self.dragMoveX - self.startDragX, self.dragMoveY - self.startDragY;
    local width, height = self.noteWidth + offsetX, self.noteHeight + offsetY;
    if (height < 40 or width < 64) then return end 
    self:SetPosition(self.startDragElementX + offsetX, self.startDragElementY + offsetY);
    self:GetTextArea():SetSize(self.textareaWidth + offsetX, self.textareaHeight + offsetY);
    self:GetNote():SetSize(width, height);
    event:Accept();
end

function Draggable:OnMouseUp(event)
    self:ReleaseMouseCapture();
    self.isMouseDown = false;
    local note = self:GetNote();
    local width, height = note:GetSize();
    note:SetStyleValue("width", width);
    note:SetStyleValue("height", height);
    note:UpdateLayout();
    event:Accept();
end

local NoteTextArea = commonlib.inherit(TextArea, {});
NoteTextArea:Property("Note");

function NoteTextArea:OnMouseDown(event)
    if (not self:IsFocus()) then
        return self:GetNote():OnMouseDown(event);
    end
    return NoteTextArea._super.OnMouseDown(self, event);
end

function NoteTextArea:OnMouseMove(event)
    return NoteTextArea._super.OnMouseMove(self, event);
end

function NoteTextArea:OnMouseUp(event)
    return NoteTextArea._super.OnMouseUp(self, event);
end

Note:Property("BaseStyle", {
    NormalStyle = {
        ["color"] = "#000000",
        ["width"] = 150,
        ["height"] = 160,
        ["font-size"] = "14px",
        ["background-color"] = "#E4DB8C",
        ["overflow-y"] = "scroll",
        ["position"] = "absolute", 
        ["left"] = 0,
        ["top"] = 0,
    }
});

Note:Property("Expand", true, "IsExpand");  -- 是否展开
Note:Property("Blockly");                   -- Blockly
Note:Property("Block");                     -- 所属块
Note:Property("Label", "");                 -- 更新label

function Note:ctor()
    self:SetName("Note");
end

-- 初始化完成
function Note:Init(xmlNode, window, parent)
    Note._super.Init(self, xmlNode, window, parent);

    local textarea = NoteTextArea:new():Init({
        name = "notetextarea",
        attr = {
            style = "position: absolute; left: 1px; top: 30px; bottom: 1px; right: 1px; border: none; min-width: 0px; min-height: 0px; background-color: rgb(254,244,156);",
        }
    }, window, self);
    table.insert(self.childrens, textarea);
    textarea:SetNote(self);
    
    local draggable = Draggable:new():Init({
        name = "textarea",
        attr = {
            style = "position: absolute; bottom: 0px; right: 0px; width: 12px; height: 12px;",
            placeholder = "说些什么...",
        }
    }, window, self);
    table.insert(self.childrens, draggable);
    draggable:SetNote(self);
    draggable:SetTextArea(textarea);

    self.__textarea__ = textarea;
    self.__draggable__ = draggable;
    self.__expand_height__ = DEFAULT_EXPAND_HEIGHT;

    return self;
end

function Note:RenderContent(painter)
    local x, y, w, h = self:GetGeometry();
    local icon_size = 16;
    painter:SetPen("#000000");
    if (self:IsExpand()) then
        painter:DrawRectTexture(x + 8, y + 7, icon_size, icon_size, "Texture/Aries/Creator/keepwork/ggs/blockly/icons_80x16bits.png#0 0 16 16");
    else
        painter:DrawRectTexture(x + 8, y + 7, icon_size, icon_size, "Texture/Aries/Creator/keepwork/ggs/blockly/icons_80x16bits.png#32 0 16 16");
        painter:DrawText(x + 32, y + 7, self:GetLabel());
    end
    painter:DrawRectTexture(x + w - 24, y + 7, icon_size, icon_size, "Texture/Aries/Creator/keepwork/ggs/blockly/icons_80x16bits.png#64 0 16 16");

    local block = self:GetBlock();
    if (not block) then return end
    painter:SetPen("#CCCCCC");
    local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
    local widthUnitCount, heightUnitCount = block:GetWidthHeightUnitCount();
    local to_x, to_y = (leftUnitCount + widthUnitCount) * Const.UnitSize, topUnitCount * Const.UnitSize;
    painter:DrawLine(x, y, to_x, to_y);
end

-- 渲染
function Note:Render(painter)
    local blockly = self:GetBlockly();
    if (not blockly) then return end 

    local UnitSize, scale = blockly:GetUnitSize(), blockly:GetScale();
    local x, y, w, h = blockly:GetContentGeometry();
    painter:Save();
    if (blockly.isHideToolBox) then
        painter:SetClipRegion(0, 0, w, h);
    else
        painter:SetClipRegion(Const.ToolBoxWidth, 0, w - Const.ToolBoxWidth, h);
    end
    painter:Scale(scale, scale);
    painter:Translate(blockly.offsetX, blockly.offsetY);
    
    Note._super.Render(self, painter);

    painter:Translate(-blockly.offsetX, -blockly.offsetY);
    painter:Scale(1 / scale, 1 / scale);
    painter:Restore();
end


function Note:IsInnerBlocklyToolBox(event)
    return self:GetBlockly():IsInnerToolBox(event);
end

function Note:UpdateLable()
    local text = self.__textarea__:GetValue();
    local width = self:GetWidth() - 64;
    local label = _guihelper.TrimUtf8TextByWidth(string.gsub(text, "\n", " "), width, self:GetFont());
    self:SetLabel(label .. "...");
end

function Note:SwitchExpand(expand)
    -- 展开或收起
    self:SetExpand(expand);
    self:UpdateLable();
    if (self:IsExpand()) then
        self.__textarea__:SetVisible(true);
        self.__draggable__:SetVisible(true);
    else
        self.__textarea__:SetVisible(false);
        self.__draggable__:SetVisible(false);
    end
    local __expand_height__ = self:GetHeight();
    self:SetStyleValue("height", self.__expand_height__);
    self.__expand_height__ = __expand_height__;
    self:UpdateLayout();
end

function Note:HandleIconEvent(event)
    if (self:IsInnerBlocklyToolBox(event)) then return true end 

    local _, _, w, h = self:GetGeometry();
    local x, y = self:GetRelPoint(event:GetScreenXY());
    if (y < 7 or y > 23) then return false end
    
    if (8 <= x and x <= 24) then
        self:SwitchExpand(not self:IsExpand());
        return true;
    end

    -- 移除
    if ((w - 24) <= x and x <= (w - 8)) then
        self:GetBlockly():RemoveNote(self);
        return true;
    end

    return false;
end

function Note:AdjustZOrder()
    -- 调整z-index序
    local childrens = self:GetBlockly().childrens;
    for index, note in ipairs(childrens) do
        if (note == self) then
            childrens[#childrens], childrens[index] = childrens[index], childrens[#childrens];
            break;
        end
    end
end

function Note:OnMouseDown(event)
    if (self:HandleIconEvent(event)) then return end 

    self.isMouseDown = true;
    self.startDragX, self.startDragY = event:GetScreenXY();
    self.startDragElementX, self.startDragElementY = self:GetPosition();
    self:CaptureMouse();
    self:AdjustZOrder();
    event:Accept();
end

function Note:OnMouseMove(event)
    if (not self.isMouseDown) then return end 
    self.dragMoveX, self.dragMoveY = event:GetScreenXY();
    local offsetX, offsetY = self.dragMoveX - self.startDragX, self.dragMoveY - self.startDragY;
    local x, y = self.startDragElementX + offsetX, self.startDragElementY + offsetY;
    self:SetPosition(x, y);
    event:Accept();
end

function Note:OnMouseUp(event)
    if (self.isMouseDown and not event:IsMove()) then self.__textarea__:FocusIn() end

    Note._super.OnMouseUp(self, event);
    self:ReleaseMouseCapture();
    self.isMouseDown = false;
    local left, top = self:GetPosition();
    self:SetStyleValue("left", left);
    self:SetStyleValue("top", top);
    self:UpdateLayout();
    event:Accept();
end

function Note:UpdateWindowPos(forceUpdate)
    local x, y = self:GetPosition();
    local oldWindowX, oldWindowY = self:GetWindowPos();
    local parentWindowX, parentWindowY = self:GetParentElement():GetWindowPos();
    local offsetX, offsetY = self:GetParentElement():GetOffset();  -- parent element is blockly;
    local windowX, windowY = parentWindowX + x + offsetX, parentWindowY + y + offsetY;
    self:SetWindowPos(windowX, windowY);
    self:SetWindowSize(self:GetSize());
    if (forceUpdate or oldWindowX ~= windowX or oldWindowY ~= windowY) then 
        for child in self:ChildElementIterator() do
            child:UpdateWindowPos(forceUpdate);
        end
    end
end

-- function Note:SaveEvent(event)
--     local blockly = self:GetBlockly();
--     local relx, rely = blockly:ScreenPointToRelativePoint(event.x, event.y);
--     local scale = blockly:GetScale();
--     self.event_x, self.event_y = event.x, event.y;
--     event.x, event.y = blockly:RelativePointToScreenPoint(relx / scale, rely / scale);
-- end

-- function Note:RestoreEvent(event)
--     event.x, event.y = self.event_x, self.event_y;
-- end

-- 悬浮捕捉
-- function Note:Hover(event, isUpdateLayout, zindex, isParentElementHover, isParentPositionElement, scrollElement)
--     self:SaveEvent(event);
--     local element, zindex = BlocklyEditor._super.Hover(self, event, isUpdateLayout, zindex, isParentElementHover, isParentPositionElement, scrollElement);
--     self:RestoreEvent(event);
--     return element, zindex;
-- end


function Note:SaveToXmlNode()
    local xmlNode = {name = "Note", attr = {}};
    local attr = xmlNode.attr;
    attr.x, attr.y, attr.w, attr.h = self:GetGeometry();
    attr.expand = tostring(self:IsExpand())
    attr.expandHeight = self.__expand_height__;
    attr.text = self.__textarea__:GetValue();
    return xmlNode;
end

function Note:LoadFromXmlNode(xmlNode)
    local attr = xmlNode.attr;
    self:SetStyleValue("left", attr.x);
    self:SetStyleValue("top", attr.y);
    self:SetStyleValue("width", attr.w);
    self:SetStyleValue("height", attr.h);
    self:SetExpand(attr.expand == "true");
    self.__expand_height__ = tonumber(attr.expandHeight) or DEFAULT_EXPAND_HEIGHT;
    self.__textarea__:SetAttrValue("value", attr.text);
    self.__textarea__:SetVisible(self:IsExpand());
    self.__draggable__:SetVisible(self:IsExpand());
    self:UpdateLable();
    self:UpdateLayout();
end