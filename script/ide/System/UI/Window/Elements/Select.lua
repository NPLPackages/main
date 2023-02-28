--[[
Title: Select
Author(s): wxa
Date: 2020/8/14
Desc: 按钮
-------------------------------------------------------
local Select = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Elements/Select.lua");
-------------------------------------------------------
]]
local Simulator = NPL.load("../Event/Simulator.lua");
local Element = NPL.load("../Element.lua", IsDevEnv);
local InputElement = NPL.load("./Input.lua");

-- SelectSimulator
local SelectSimulator = commonlib.inherit(Simulator, {});
SelectSimulator:Property("SimulatorName", "SelectSimulator");

function SelectSimulator:ctor()
    self:RegisterSimulator();
end

function SelectSimulator:SimulateSelectOption(selectId, value)
    if (not selectId) then return end

    self:AddVirtualEvent("SelectOption", {value = value, selectId = selectId});
end

function SelectSimulator:HandlerSelectOption(params, window)
    local selectId, value = params.selectId, params.value;
    local select = window:GetElementById(selectId);
    if (not select) then return end
    select:ReleaseFocus();
    select:SetAttrValue("value", value);
    select:CallAttrFunction("onselect", nil, select:GetValue(), select:GetLabel());
end

function SelectSimulator:TriggerSelectOption(params, window)
    local selectId, value = params.selectId, params.value;
    local select = window:GetElementById(selectId);
    if (not select) then return end

    local sx, sy = select:AutoScrollToValue(value);
    if (not sx or not sy) then return end 
    return self:SetClickTrigger(sx + 14, sy + 14);
end

function SelectSimulator:HandlerVirtualEvent(virtualEventType, virtualEventParams, window)
    if (virtualEventType == "SelectOption") then return self:HandlerSelectOption(virtualEventParams, window) end
end

function SelectSimulator:TriggerVirtualEvent(virtualEventType, virtualEventParams, window)
    if (virtualEventType == "SelectOption") then return self:TriggerSelectOption(virtualEventParams, window) end
end

SelectSimulator:InitSingleton();

local Option = commonlib.inherit(Element, {});
Option:Property("Name", "Option");
Option:Property("Value", "");
Option:Property("Label", "");
Option:Property("Text", "");
Option:Property("SelectElement");
Option:Property("BaseStyle", {
    NormalStyle = {
        height = "28px",
        ["line-height"] = "28px",
        ["min-width"] = "100%",
        padding = "0px 10px 0px 4px",
    },
    HoverStyle = {
        ["background-color"] = "#cccccc",
    },
});

function Option:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);
    self:SetLabel(self:GetAttrStringValue("label") or self:GetInnerText() or "");
    self:SetValue(self:GetAttrStringValue("value", ""));
    self:SetText(self:GetLabel());
    return self;
end

function Option:OnUpdateLayout()
	local layout, style = self:GetLayout(), self:GetStyle();
	local parentLayout = self:GetParentElement():GetLayout();
    local parentWidth, parentHeight = parentLayout:GetWidthHeight();
	local width, height = layout:GetWidthHeight();
	local text = self:GetLabel();

    local marginTop, marginRight, marginBottom, marginLeft = layout:GetMargin();
	local paddingTop, paddingRight, paddingBottom, paddingLeft = layout:GetPadding();
    if (width) then width = width - paddingLeft - paddingRight - marginLeft - marginRight end 

    local textWidth, textHeight = _guihelper.GetTextWidth(text, self:GetFont()), self:GetLineHeight();
    width, height = width or textWidth, height or textHeight;
    if (width < textWidth) then
        if (style["text-overflow"] == "ellipsis") then
            text = _guihelper.TrimUtf8TextByWidth(text, width - 16, self:GetFont()) .. "...";
        else
            text = _guihelper.TrimUtf8TextByWidth(text, width, self:GetFont());
        end
        self:SetText(text);    
    end

    width = width + paddingLeft + paddingRight + marginLeft + marginRight;

    layout:SetWidthHeight(width, height);

    return true; 
end

function Option:RenderContent(painter)
    local x, y, w, h = self:GetContentGeometry();
    local text = self:GetText();
    local lineHeight, fontSize = self:GetLineHeight(), self:GetFontSize();

    painter:SetPen(self:GetColor("#000000"));
    painter:SetFont(self:GetFont());
    painter:DrawText(math.floor(x), math.floor(y + (lineHeight - fontSize) / 2 - fontSize / 6), text);
    -- print(math.floor(x), math.floor(y + (lineHeight - fontSize) / 2 - fontSize / 6), text)
end

function Option:OnMouseDown(event)
    Option._super.OnMouseDown(self, event);
    local select = self:GetSelectElement();
    select:OnSelect(self);

    if (self:IsCanSimulateEvent()) then
        SelectSimulator:SimulateSelectOption(select:GetAttrStringValue("id"), self:GetValue());
    end
    
    event:Accept();
    self:CaptureMouse();
end

function Option:OnMouseUp(event)
    Option._super.OnMouseUp(self, event);
    event:Accept();
    self:ReleaseMouseCapture();
end

function Option:SimulateEvent()
    SelectSimulator:SetSimulated(true);
end

-- SelectListBox
local ListBox = commonlib.inherit(Element, {});
ListBox:Property("Name", "ListBox");

function ListBox:OnAfterUpdateLayout()
    local width, height = self:GetLayout():GetContentWidthHeight();
    for _, childElement in ipairs(self.childrens) do
        local layout = childElement:GetLayout();
        local childWidth, childHeight = layout:GetWidthHeight();
        if (width > childWidth) then
            childElement:SetStyleValue("width", width);
            layout:SetWidthHeight(width, childHeight);
        end
    end
    self:OnRealContentSizeChange();
end

function ListBox:SimulateEvent()
    SelectSimulator:SetSimulated(true);
end

-- Select
local Select = commonlib.inherit(Element, NPL.export());

Select:Property("Name", "Select");
Select:Property("Label", "");
Select:Property("Value", "");
Select:Property("ListBoxElement");
Select:Property("InputBoxElement");
Select:Property("SelectedOptionElement");
Select:Property("CaptureFocus", false, "IsCaptureFocus"); -- 是否捕获焦点
Select:Property("BaseStyle", {
    NormalStyle = {
        ["display"] = "inline-block",
        ["background-color"] = "#ffffff",
        ["width"] = "120px",
        ["height"] = "30px",
        ["padding"] = "2px 4px",
        ["border"] = "1px solid #cccccc",
    }
});

function Select:ctor()
    self:SetCanFocus(true);
end

function Select:Init(xmlNode, window, parent)
    self:InitElement(xmlNode, window, parent);
    local attrStyle = self:GetAttrStyle();
    local ListBox = ListBox:new():Init({
        name = "ListBox",
        attr = {
            style = "position: absolute; left: 0px; top: 105%; min-width: 100%; max-height: 142px; overflow-x: hidden; overflow-y: auto; background-color: #ffffff; border: 1px solid #cccccc;",
        }
    }, window, self);

    local function InputValueFinish(value)
        local label = self:GetLabelByValue(value);
        if (value ~= self:GetValue() or label ~= self:GetLabel()) then
            value = self:GetValueByLabel(value);
            self:SetValue(value);
            self:SetLabel(label);
            self:CallAttrFunction("onchange", nil, self:GetValue(), self:GetLabel());
            self:CallAttrFunction("onselect", nil, self:GetValue(), self:GetLabel());
        end
        self:ReleaseFocus();
    end

    -- local listboxAttrStyle = ListBox:GetAttrStyle();
    -- listboxAttrStyle["padding-top"], listboxAttrStyle["padding-right"], listboxAttrStyle["padding-bottom"], listboxAttrStyle["padding-left"] = attrStyle["padding-top"], attrStyle["padding-right"], attrStyle["padding-bottom"], attrStyle["padding-left"];
    local InputBox = InputElement:new():Init({
        name = "input",
        attr = {
            style = "position: absolute; left: 0px; top: 0px; right: 0px; bottom: 0px; border: none; background-color: #ffffff00; height: 100%; width: 100%;",
        }
    }, window, self);

    InputBox:SetAttrValue("onblur", function()
        -- self:OnFocusOut();
        InputValueFinish(InputBox:GetValue());
    end);

    InputBox:SetAttrValue("onkeydown.enter", function(value)
        InputValueFinish(value);
    end);

    InputBox:SetAttrValue("onchange", function(value)
        self:CallAttrFunction("onchange", nil, value);
    end);

    local inputAttrStyle = InputBox:GetAttrStyle();
    inputAttrStyle["padding-top"],
    inputAttrStyle["padding-right"],
    inputAttrStyle["padding-bottom"],
    inputAttrStyle["padding-left"] =
        attrStyle["padding-top"],
        attrStyle["padding-right"],
        attrStyle["padding-bottom"],
        attrStyle["padding-left"];

    self:SetListBoxElement(ListBox);
    self:SetInputBoxElement(InputBox);
    self:InsertChildElement(InputBox);
    self:InsertChildElement(ListBox);

    local options = self:GetAttrValue("options");

    if (options) then
        self:OnOptionsAttrValueChange(options);
    else
        -- 创建子元素
        for i, childXmlNode in ipairs(xmlNode) do
            if (type(childXmlNode) == "table" and childXmlNode.name == "option") then
                local childElement = Option:new():Init(childXmlNode, window, ListBox);
                childElement:SetSelectElement(self);
                ListBox:InsertChildElement(childElement);
            end
        end
    end

    self:OnValueAttrValueChange(self:GetAttrStringValue("value"));

    InputBox:SetVisible(false);
    ListBox:SetVisible(false);

    return self;
end

function Select:IsAllowCreate()
    return self:GetAttrBoolValue("isAllowCreate");
end

function Select:OnAttrValueChange(attrName, attrValue, oldAttrValue)
    Select._super.OnAttrValueChange(self, attrName, attrValue, oldAttrValue);
    
    if (attrName == "value") then
        self:OnValueAttrValueChange(attrValue);
    elseif (attrName == "options") then
        self:OnOptionsAttrValueChange(attrValue);
    end
end

function Select:OnOptionsAttrValueChange(attrValue)
    if (type(attrValue) ~= "table") then return end
    local ListBox = self:GetListBoxElement();
    local option = self:GetSelectedOptionElement();
    local value = option and option:GetValue() or self:GetAttrStringValue("value");
    ListBox:ClearChildElement();
    self:SetSelectedOptionElement(nil);
    for _, option in ipairs(attrValue) do
        if (type(option) == "string") then option = {label = option, value = option} end
        if (type(option) == "table") then
            local childElement = Option:new():Init({name = "option", attr = {label = option[1] or option.label or option.value, value = option[2] or option[1] or option.value or option.label}}, self:GetWindow(), ListBox);
            childElement:SetSelectElement(self);
            ListBox:InsertChildElement(childElement);
            if (childElement:GetValue() == value) then
                self:SetValue(childElement:GetValue());
                self:SetLabel(childElement:GetLabel());
                self:SetSelectedOptionElement(childElement);
            end
        end
    end
end

function Select:OnValueAttrValueChange(attrValue)
    self:SetSelectedOptionElement(nil);
    local ListBox = self:GetListBoxElement();
    for _, childElement in ipairs(ListBox.childrens) do
        if (childElement:GetValue() == attrValue) then
            self:SetValue(childElement:GetValue());
            self:SetLabel(childElement:GetLabel());
            return self:SetSelectedOptionElement(childElement);
        end
    end
    self:SetValue(attrValue);
    self:SetLabel(attrValue);
end

function Select:GetLabelByValue(value)
    local ListBox = self:GetListBoxElement();
    for _, option in ipairs(ListBox.childrens) do
        if (value == option:GetValue()) then return option:GetLabel() end
    end
    return value;
end

function Select:GetValueByLabel(label)
    local ListBox = self:GetListBoxElement();
    for _, option in ipairs(ListBox.childrens) do
        if (label == option:GetLabel()) then return option:GetValue() end
    end
    return label;
end

function Select:FilterOptions(filter)
    local ListBox = self:GetListBoxElement();
    for _, option in ipairs(ListBox.childrens) do
        local value = option:GetValue();
        if (not filter or filter == "") then option:SetVisible(true)
        elseif (type(filter) == "string" and (string.find(value, filter, 1, true))) then option:SetVisible(true)
        elseif (type(filter) == "function" and filter(value)) then option:SetVisible(true) 
        else option:SetVisible(false) end
    end
    ListBox:UpdateLayout();
end

function Select:OnSelect(option)
    if (self:GetSelectedOptionElement() == option) then return end
    self:ReleaseFocus();
    self:SetSelectedOptionElement(option);
    local value = option and option:GetValue();
    local label = option and option:GetLabel();
    self:SetValue(value);
    self:SetLabel(label);
    self:CallAttrFunction("onchange", nil, value, label);
    self:CallAttrFunction("onselect", nil, value, label);
end

function Select:GetOptionIndex(value)
    local ListBox = self:GetListBoxElement();
    
    value = value or self:GetValue();
    for i, childElement in ipairs(ListBox.childrens) do
        if (childElement:GetValue() == value) then
            return i;
        end
    end
    
    return nil;
end

function Select:AutoScrollToValue(value)
    local ListBox = self:GetListBoxElement();
    local index = self:GetOptionIndex(value);
    if (not index) then return nil, nil end
    local _, _, _, ListBoxHeight = ListBox:GetContentGeometry();
    local OptionHeight = ListBox.childrens[1]:GetHeight();
    local OptionTotalCount = #ListBox.childrens;
    local viewOptionCount = math.floor(ListBoxHeight / OptionHeight);
    local viewOptionHalfCount = math.ceil(viewOptionCount / 2);
    -- 剩余选项过少, 直接滚动到底部
    local offset = 0;
    if (index <= viewOptionCount) then
        offset = 0;
    elseif ((OptionTotalCount - index) < (viewOptionCount - viewOptionHalfCount)) then
        offset = (OptionTotalCount - viewOptionCount) * OptionHeight;
    else
        offset = (index - viewOptionHalfCount) * OptionHeight;
    end

    local scroll = ListBox:GetVerticalScrollBar();
    if (scroll) then scroll:ScrollTo(offset) end

    local relX, relY =  0, (index - 1) * OptionHeight - offset;
    return ListBox:RelativePointToScreenPoint(relX, relY);
end

function Select:ReleaseFocus()
    self:SetCaptureFocus(false);
    self:SetFocus(nil);
    self:OnFocusOut();
end

function Select:OnFocusIn(event)
    if (self:IsDisabled()) then return end
    
    if (self:IsAllowCreate()) then
        self:SetCaptureFocus(true);
        self:GetInputBoxElement():SetAttrValue("value", self:GetLabel());
        self:GetInputBoxElement():handleSelectAll();
        self:GetInputBoxElement():FocusIn();
        self:GetInputBoxElement():SetVisible(true);
        self:GetInputBoxElement():UpdateLayout();
    end
    self:GetListBoxElement():SetVisible(true);
    self:GetListBoxElement():UpdateLayout();
    if (self:GetAttrBoolValue("isAutoScroll", false)) then
        self:AutoScrollToValue();
    end
    Select._super.OnFocusIn(self, event);
end

function Select:OnFocusOut(event)
    if (self:IsCaptureFocus()) then return end

    self:GetInputBoxElement():SetVisible(false);
    self:GetListBoxElement():SetVisible(false);
    Select._super.OnFocusOut(self, event);
end

local ArrowAreaSize = 20;

function Select:RenderContent(painter)
    if (self:GetInputBoxElement():GetVisible()) then return end
    self:RenderArrowIcon(painter);

    local text = self:GetAttrStringValue("placeholder");
    local x, y, w, h = self:GetContentGeometry();

    painter:SetPen(self:GetColor("#000000"));
    painter:SetFont(self:GetFont());
    if (self:GetLabel() ~= "") then
        text = self:GetLabel(); 
    else
        painter:SetPen("#A8A8A8"); -- placeholder color;
    end
    local textWidth = self:IsShowArrowIcon() and (w - ArrowAreaSize) or w;
    text = _guihelper.TrimUtf8TextByWidth(text, textWidth, self:GetFont());
    painter:DrawText(math.floor(x), math.floor(y + (h - self:GetSingleLineTextHeight()) / 2), (text or "") .. "");
end

local ArrowSize = 12;
local Points = {
    Down = {
        {0, ArrowSize / 4, 0},
        {ArrowSize / 2, ArrowSize * 3 / 4, 0},
        {ArrowSize / 2, ArrowSize * 3 / 4, 0},
        {ArrowSize, ArrowSize / 4, 0},
    },
    
    Up = {
        {0, ArrowSize * 3 / 4, 0},
        {ArrowSize / 2, ArrowSize / 4, 0},
        {ArrowSize / 2, ArrowSize / 4, 0},
        {ArrowSize, ArrowSize * 3 / 4, 0},
    }
}

function Select:IsShowArrowIcon()
    return self:GetAttrBoolValue("isShowArrowIcon", true);
end

function Select:RenderArrowIcon(painter)
    if (not self:IsShowArrowIcon()) then return end

    local x, y, w, h = self:GetGeometry();

    painter:Translate(x + w - ArrowAreaSize, y + (h - ArrowSize) / 2);
    painter:SetPen(self:GetColor("#000000"));
    painter:SetFont(self:GetFont());
    painter:DrawLineList(self:GetListBoxElement():IsVisible() and Points.Up or Points.Down);
    painter:Translate(-(x + w - ArrowAreaSize), -(y + (h - ArrowSize) / 2));
    painter:Flush();
end
