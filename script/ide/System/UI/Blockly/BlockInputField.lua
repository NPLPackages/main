--[[
Title: InputField
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local BlockInputField = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/BlockInputField.lua");
-------------------------------------------------------
]]
local DivElement = NPL.load("../Window/Elements/Div.lua", IsDevEnv);
local InputElement = NPL.load("../Window/Elements/Input.lua", IsDevEnv);
local SelectElement = NPL.load("../Window/Elements/Select.lua", IsDevEnv);
local ColorPickerElement = NPL.load("../Window/Elements/ColorPicker.lua", IsDevEnv);
local TextAreaElement = NPL.load("../Window/Elements/TextArea.lua", IsDevEnv);

local Const = NPL.load("./Const.lua");
local Options = NPL.load("./Options.lua");
local Shape = NPL.load("./Shape.lua");
local Validator = NPL.load("./Validator.lua", IsDevEnv);

local BlockInputField = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

BlockInputField:Property("ClassName", "BlockInputField");
BlockInputField:Property("Name");
BlockInputField:Property("Type");
BlockInputField:Property("Block");
BlockInputField:Property("Option");
BlockInputField:Property("Color", "#ffffff");                    -- 颜色
BlockInputField:Property("BackgroundColor", "#ffffff");          -- 背景颜色
BlockInputField:Property("Edit", false, "IsEdit");               -- 是否在编辑
BlockInputField:Property("Validator", nil);                      -- 验证器
BlockInputField:Property("Value", "");                           -- 值
BlockInputField:Property("DefaultValue", "");                    -- 默认值
BlockInputField:Property("Label", "");                           -- 显示值
BlockInputField:Property("DefaultLabel", "");                           -- 显示值
BlockInputField:Property("Text", "");                            -- 文本值
BlockInputField:Property("EditElement", nil);                    -- 编辑元素
BlockInputField:Property("SelectType");
BlockInputField:Property("AllowNewSelectOption", false, "IsAllowNewSelectOption");  -- 是否允许新增选项
BlockInputField:Property("InputFieldContainer");                 -- 所属输入字段容器
BlockInputField:Property("CanDelete", false, "IsCanDelete");     -- 是否可删除
BlockInputField:Property("Placeholder", "");

local UnitSize = Const.UnitSize;

function BlockInputField:ctor()
    self.leftUnitCount, self.topUnitCount, self.widthUnitCount, self.heightUnitCount = 0, 0, 0, 0;
    self.left, self.top, self.width, self.height = 0, 0, 0, 0;
    self.maxWidthUnitCount, self.maxHeightUnitCount, self.maxWidth, self.maxHeight = 0, 0, 0, 0;
    self.totalWidthUnitCount, self.totalHeightUnitCount, self.totalWidth, self.totalHeight = 0, 0, 0, 0;
end

function BlockInputField:Init(block, option)
    option = option or {};

    self:SetBlock(block);
    self:SetOption(option or {});
    self:SetName(option.name);
    self:SetType(option.type);
    self:SetSelectType(option.selectType);
    self:SetValidator(option.validator);
    self:SetValue(self:GetOptionText());
    self:SetLabel(tostring(option.label or self:GetValue()));
    self:SetDefaultValue(self:GetValue());
    self:SetDefaultLabel(self:GetLabel());
    -- 解析颜色值

    if (option["background-color"]) then 
        local bgColor = option["background-color"];
        self:SetBackgroundColor(self:TrimString(bgColor)); 
    end 

    if (option.placeholder) then self:SetPlaceholder(self:TrimString(option.placeholder)) end 

    if (self:IsBlock()) then
        self:SetColor(self:GetCategoryColor());
    else 
        self:SetColor(option.color);
    end
    self:SetColor(string.upper(self:GetColor()));
    
    self:SetAllowNewSelectOption(option.isAllowNewSelectOption == true and true or false);

    if (self:IsSelectType()) then
        self:SetLabel(self:GetLabelByValue(self:GetValue(), self:GetDefaultLabel()));
        self:SetValue(self:GetValueByLablel(self:GetLabel(), self:GetDefaultValue()));
    end 
    
    if (option.name and option.name ~= "") then block.inputFieldMap[option.name] = self end
    return self;
end

function BlockInputField:TrimString(str)
    str = string.gsub(str, "^%s*", "");
    str = string.gsub(str, "%s$*", "");
    return str;
end

function BlockInputField:GetCategoryColor()
    local blockOption = self:GetBlock():GetOption();
    local CategoryColor = self:GetBlock():GetBlockly().CategoryColor;
    return CategoryColor[blockOption.category] or blockOption.color;
end

function BlockInputField:GetOptions(bRefresh)
    local option = self:GetOption();
    local options = option.options;
    if (type(options) == "string") then options = Options[options] end
    if (type(options) == "table") then 
        if (not option.option_options and type(options[1]) == "string") then
            option.option_options = {};
            for i, v in ipairs(options) do
                option.option_options[i] = {v, v};
            end
        end
        return option.option_options or option.options; 
    end 
    if (type(options) == "function") then 
        if (not bRefresh and self.option_options) then return self.option_options end
        self.option_options = options(self);
        return self.option_options;
    end
    return {};
end

function BlockInputField:GetValueByLablel(label, defaultValue)
    local options = self:GetOptions();
    for _, option in ipairs(options) do
        if (option[1] == label or option.label == label) then return option[2] or option.value end
    end
    if (self:IsAllowNewSelectOption()) then return defaultValue or label end 
    return options[1] and (options[1][2] or options[1].value) or defaultValue or label;
end

function BlockInputField:GetLabelByValue(value, defaultLabel)
    local options = self:GetOptions();
    for _, option in ipairs(options) do
        if (option[2] == value or option.value == value) then return option[1] or option.label end
    end
    if (self:IsAllowNewSelectOption()) then return defaultLabel or value end 
    return options[1] and (options[1][1] or options[1].label) or defaultLabel or value;
end

-- 获取选项文本, 默认为字段值(value)
function BlockInputField:GetOptionText()
    local opt = self:GetOption();
    if (type(opt.text) == "function") then 
        return opt.text(); 
    elseif (type(opt.text) == "string" or type(opt.text) == "number") then 
        return opt.text; 
    else 
        return "";
    end
end

function BlockInputField:IsField()
    return false;
end

function BlockInputField:IsInput()
    return false;
end

function BlockInputField:IsBlock()
    return false;
end

function BlockInputField:GetInputFieldType()
    if (not self:IsField() and not self:IsInput()) then return "" end
    local typ = self:GetType();
    if (typ == "input_value") then return self:GetShadowType() end
    return typ;
end

function BlockInputField:IsNumberType(typ)
    typ = typ or self:GetInputFieldType();
    return typ == "field_number" or typ == "math_number" or typ == "number";
end

function BlockInputField:IsInputType(typ)
    typ = typ or self:GetInputFieldType();
    return typ == "field_input" or typ == "field_text" or typ == "text";
end

function BlockInputField:IsTextType(typ)
    typ = typ or self:GetInputFieldType();
    return self:IsInputType() or self:IsSelectType();
end

function BlockInputField:IsSelectType(typ)
    typ = typ or self:GetInputFieldType();
    return typ == "field_dropdown" or typ == "field_select" or typ == "select";
end

function BlockInputField:IsCodeType(typ)
    typ = typ or self:GetInputFieldType();
    return typ == "field_block" or typ == "block" or typ == "field_code" or typ == "code";
end

function BlockInputField:SetTotalWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    local UnitSize = self:GetUnitSize();
    self.totalWidthUnitCount, self.totalHeightUnitCount = widthUnitCount, heightUnitCount;
    self.totalWidth, self.totalHeight = widthUnitCount * UnitSize, heightUnitCount * UnitSize;
end

function BlockInputField:GetTotalWidthHeightUnitCount()
    return self.totalWidthUnitCount, self.totalHeightUnitCount;
end

function BlockInputField:SetMaxWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    local UnitSize = self:GetUnitSize();
    self.maxWidthUnitCount, self.maxHeightUnitCount = widthUnitCount or self.maxWidthUnitCount or self.widthUnitCount, heightUnitCount or self.maxHeightUnitCount or self.heightUnitCount;
    self.maxWidth, self.maxHeight = self.maxWidthUnitCount * UnitSize, self.maxHeightUnitCount * UnitSize;
    if (self.width and self.maxWidth and self.width > self.maxWidth) then self.maxWidth, self.maxWidthUnitCount = self.width, self.widthUnitCount end
    if (self.height and self.maxHeight and self.height > self.maxHeight) then self.maxHeight, self.maxHeightUnitCount = self.height, self.heightUnitCount end
end

function BlockInputField:UpdateWidthHeightUnitCount()
    return 0, 0, 0, 0, 0, 0;  -- 最大宽高, 元素宽高, 元素总宽高
end

function BlockInputField:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount)
    local UnitSize = self:GetUnitSize();
    widthUnitCount, heightUnitCount = widthUnitCount or self.widthUnitCount or 0, heightUnitCount or self.heightUnitCount or 0;
    self.widthUnitCount, self.heightUnitCount = widthUnitCount, heightUnitCount;
    local width, height = widthUnitCount * UnitSize, heightUnitCount * UnitSize;
    if (width == self.width and height == self.height) then return end
    self.width, self.height = width, height;
    if (self.width and self.maxWidth and self.width > self.maxWidth) then self.maxWidth, self.maxWidthUnitCount = self.width, self.widthUnitCount end
    if (self.height and self.maxHeight and self.height > self.maxHeight) then self.maxHeight, self.maxHeightUnitCount = self.height, self.heightUnitCount end
    self:SetMaxWidthHeightUnitCount(math.max(widthUnitCount, self.maxWidthUnitCount or 0), math.max(heightUnitCount, self.maxHeightUnitCount or 0));
    self:OnSizeChange();
end

function BlockInputField:GetMaxWidthHeightUnitCount()
    return self.maxWidthUnitCount, self.maxHeightUnitCount;
end

function BlockInputField:GetWidthHeightUnitCount()
    return self.widthUnitCount, self.heightUnitCount;
end

function BlockInputField:UpdateLeftTopUnitCount()
end

function BlockInputField:SetLeftTopUnitCount(leftUnitCount, topUnitCount)
    local UnitSize = self:GetUnitSize();
    self.leftUnitCount, self.topUnitCount = leftUnitCount, topUnitCount;
    local left, top = leftUnitCount * UnitSize, topUnitCount * UnitSize;
    if (self.left == left and self.top == top) then return end
    self.left, self.top = left, top;
    self:OnSizeChange();
end

function BlockInputField:GetLeftTopUnitCount()
    return self.leftUnitCount, self.topUnitCount;
end

function BlockInputField:GetAbsoluteLeftTopUnitCount()
    if (self == self:GetBlock()) then return self:GetLeftTopUnitCount() end
    local blockLeftUnitCount, blockTopUnitCount = self:GetBlock():GetLeftTopUnitCount();
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    return blockLeftUnitCount + leftUnitCount, blockTopUnitCount + topUnitCount;
end

function BlockInputField:OnSizeChange()
end

function BlockInputField:GetTextWidthUnitCount(text)
    return math.ceil(_guihelper.GetTextWidth(text or "", self:GetFont()) / self:GetUnitSize())
end

function BlockInputField:GetTextHeightUnitCount()
    return math.floor(self:GetFontSize() / self:GetUnitSize());
end

function BlockInputField:GetLineHeightUnitCount()
    return Const.LineHeightUnitCount;
end

function BlockInputField:GetUnitSize()
    local block = self:GetBlock();
    local blockly = self:GetBlock():GetBlockly();
    local unitsize = blockly:GetUnitSize();
    if (block:IsToolBoxBlock()) then 
        unitsize = blockly:GetToolBox():GetUnitSize();
    end
    return unitsize or UnitSize;
end

function BlockInputField:GetFontSize()
    -- return (self:GetLineHeightUnitCount() - 4) * self:GetUnitSize();
    return math.floor(Const.LineHeightUnitCount * self:GetUnitSize() * 3 / 5);
end

function BlockInputField:GetSingleLineTextHeight()
    return math.floor(self:GetFontSize() * 6 / 5);
end

function BlockInputField:GetShowText(text)
    local text = self:GetLabel();
    if (self.widthUnitCount < Const.MaxTextShowWidthUnitCount) then return text end
    if (self.show_text_label == text) then return self.show_text end
    local width = (self.widthUnitCount - Const.BlockEdgeWidthUnitCount * 2) * self:GetUnitSize();
    local show_text = _guihelper.TrimUtf8TextByWidth(text, width, self:GetFont());  -- AutoTrimTextByWidth 使用此函数中文显示可能异常
    -- local show_text = string.gsub(text, "\n", " ");
    -- show_text = _guihelper.TrimUtf8TextByWidth(show_text, width, self:GetFont());  -- AutoTrimTextByWidth 使用此函数中文显示可能异常
    self.show_text, self.show_text_label = show_text .. " ...", text;
    return show_text;
end

function BlockInputField:GetFont()
    return string.format("System;%s", self:GetFontSize());
end

function BlockInputField:RenderContent(painter)
end

function BlockInputField:GetOffset()
    return self.left + (self.maxWidth - self.width) / 2, self.top + (self.maxHeight - self.height) / 2;
end

function BlockInputField:Render(painter)
end


function BlockInputField:UpdateLayout()
end

function BlockInputField:OnClick()
end

function BlockInputField:OnCreate()
end

function BlockInputField:OnMouseDown(event)
    local block = self:GetBlock();
    local blockly = block:GetBlockly();

    block = block:GetProxyBlock() or block;
    block:OnMouseDown(event);

    if ((self == block or block:IsToolBoxBlock()) and blockly:IsTouchMode()) then
        blockly:CaptureMouse(block);
        blockly:SetCurrentBlock(block);
    end
end

function BlockInputField:OnMouseMove(event)
    local block = self:GetBlock();
    block = block:GetProxyBlock() or block;
    block:OnMouseMove(event);
end

function BlockInputField:OnMouseUp(event)
    local block = self:GetBlock();
    block = block:GetProxyBlock() or block;
    block:OnMouseUp(event);
end

function BlockInputField:GetMouseUI(x, y)
    local left, top = self:GetOffset();
    if (x < left or x > (left + self.width) or y < top or y > (top + self.height)) then return end
    return self;
end

function BlockInputField:OnFocusOut()
end

function BlockInputField:OnFocusIn()
end

function BlockInputField:FocusIn()
    local blockly = self:GetBlock():GetBlockly();
    local focusUI = blockly:GetFocusUI();
    if (focusUI == self) then return end
    if (focusUI) then focusUI:OnFocusOut() end
    self:OnFocusIn();
end

function BlockInputField:FocusOut()
    self:OnFocusOut();

    local blockly = self:GetBlock():GetBlockly();
    local focusUI = blockly:GetFocusUI();
    if (focusUI == self) then blockly:SetFocusUI(nil) end
end


function BlockInputField:ConnectionBlock(block)
    return ;
end

function BlockInputField:GetNextBlock()
    local block = self:GetBlock();
    local connection = block.nextConnection and block.nextConnection:GetConnection();
    return connection and connection:GetBlock();
end

function BlockInputField:GetLastNextBlock()
    local prevBlock, nextBlock = self:GetBlock(), self:GetNextBlock();
    while (nextBlock) do 
        prevBlock = nextBlock;
        nextBlock = prevBlock:GetNextBlock();
    end
    return prevBlock;
end

function BlockInputField:GetOutputBlock()
    local block = self:GetBlock();
    local connection = block.outputConnection and block.outputConnection:GetConnection();
    return connection and connection:GetBlock();
end

function BlockInputField:GetTopBlock()
    local prevBlock, nextBlock = self:GetPrevBlock() or self:GetOutputBlock(), self:GetBlock();
    while (prevBlock) do 
        nextBlock = prevBlock;
        prevBlock = nextBlock:GetPrevBlock() or nextBlock:GetOutputBlock();
    end
    return nextBlock;
end

function BlockInputField:GetPrevBlock()
    local block = self:GetBlock();
    local connection = block.previousConnection and block.previousConnection:GetConnection();
    return connection and connection:GetBlock();
end

function BlockInputField:GetEditorElement()
    return self:GetBlock():GetBlockly():GetEditorElement();
end

function BlockInputField:GetBlocklyElement()
    return self:GetBlock():GetBlockly();
end

function BlockInputField:Debug()
    GGS.DEBUG.Format("left = %s, top = %s, width = %s, height = %s, maxWidth = %s, maxHeight = %s, totalWidth = %s, totalHeight = %s", 
        self.leftUnitCount, self.topUnitCount, self.widthUnitCount, self.heightUnitCount, self.maxWidthUnitCount, self.maxHeightUnitCount, self.totalWidthUnitCount, self.totalHeightUnitCount);
end

function BlockInputField:IsCanEdit()
    return false;
end

function BlockInputField:GetMinEditFieldWidthUnitCount()
    return Const.MinEditFieldWidthUnitCount;
end

function BlockInputField:OnValueChanged(oldValue, newValue)
end

function BlockInputField:GetFieldInputEditElement(parentElement)
    local UnitSize = self:GetUnitSize();
    local InputEditElement = InputElement:new():Init({
        name = "input",
        attr = {
            id = "BlocklyFieldInputEditId",
            style = string.format('width: 100%%; height: 100%%; border: none; background: %s; background-color: %s; font-size: %spx; padding-left: %spx', Shape:GetOutputTexture(), self:GetBackgroundColor(), self:GetFontSize(), UnitSize * Const.BlockEdgeWidthUnitCount),
            value = self:GetValue(),
            type = (self:GetType() == "field_number" or (self:GetType() == "input_value" and self:IsNumberType(self:GetShadowType()))) and "number" or "text",
        },
    }, parentElement:GetWindow(), parentElement);

    local function InputChange(bFinish)
        local value = InputEditElement:GetValue();
        self:SetFieldValue(value);
        local label = string.gsub(tostring(self:GetValue()), "\n", " ");
        self:SetLabel(label);
        self:UpdateEditAreaSize();
        if (value ~= self:GetValue()) then
            InputEditElement:SetAttrValue("value", self:GetValue());
        end
        if (bFinish) then self:FocusOut() end
    end 

    InputEditElement:SetAttrValue("onkeydown.enter", function() InputChange(true) end);
    InputEditElement:SetAttrValue("onblur", function() InputChange(true) end);
    InputEditElement:SetAttrValue("onchange", function() InputChange(false) end);

    return InputEditElement;
end 

function BlockInputField:GetFieldSelectEditElement(parentElement)
    local UnitSize = self:GetUnitSize();
    local isAllowCreate = self:IsAllowNewSelectOption();  -- 只有输入可以新增
    local SelectEditElement = SelectElement:new():Init({
        name = "select",
        attr = {
            id = "BlocklyFieldSelectEditId",
            isAllowCreate = isAllowCreate,
            isShowArrowIcon = false, 
            style = string.format('width: 100%%; height: 100%%; border: none; background: %s; font-size: %spx; padding-top: 2px; padding-left: %spx',  Shape:GetOutputTexture(), self:GetFontSize(), UnitSize * Const.BlockEdgeWidthUnitCount),
            value = self:GetValue(),
            options = self:GetOptions(true),
        },
    }, parentElement:GetWindow(), parentElement);

    -- SelectEditElement.OnRender = function() end
    SelectEditElement:SetAttrValue("onchange", function(value)
        if (not isAllowCreate) then return end
        local label = string.gsub(value, "\n", " ");
        self:SetLabel(self:GetLabelByValue(label, label));
        self:UpdateEditAreaSize();
    end);

    SelectEditElement:SetAttrValue("onselect", function(value, label)
        local oldValue = self:GetValue();
        if (oldValue == value) then return end
        self:SetValue(value);
        self:SetLabel(label);
        self:FocusOut();
        self:OnValueChanged(value, oldValue);
    end);

    return SelectEditElement;
end

function BlockInputField:GetFieldColorEditElement(parentElement)
    local ColorPickerEditElement = ColorPickerElement:new():Init({
        name = "ColorPicker",
        attr = {
            style = 'position: absolute; left: -60px; top: 30px;', 
            value = self:GetValue(),
        },
    }, parentElement:GetWindow(), parentElement);

    ColorPickerEditElement:SetAttrValue("onchange", function(value) 
        self:SetFieldValue(value);
        self:SetLabel(value);
    end);

    return ColorPickerEditElement;
end

function BlockInputField:GetFieldTextAreaEditElement(parentElement)
    local TextAreaEditElement = TextAreaElement:new():Init({
        name = "textarea",
        attr = {
            style = 'position: absolute; left: 50%; top: 40px; width: 300px; height: 160px; margin-left: -150px;', 
            value = self:GetValue(),
        },
    }, parentElement:GetWindow(), parentElement);

    TextAreaEditElement:SetAttrValue("onblur", function()
        local value = TextAreaEditElement:GetValue(); 
        self:SetValue(value);
        self:SetLabel(string.gsub(value, "\n", " "));
    end);

    return TextAreaEditElement;
end

function BlockInputField:UpdateEditAreaSize()
    if (not self:IsEdit()) then return end

    self:GetTopBlock():UpdateLayout();
    local blockly = self:GetBlock():GetBlockly();
    local editor = self:GetEditorElement();
    local offsetX, offsetY = 0, 0;
    -- local scale = blockly:GetScale();
    local left = self.left + (self.maxWidth - self.width) / 2 + blockly.offsetX + offsetX;
    local top = self.top + (self.maxHeight - self.height) / 2 + blockly.offsetY + offsetY;
    editor:SetStyleValue("left", left);
    editor:SetStyleValue("top", top);
    editor:SetStyleValue("width", self.width);
    editor:SetStyleValue("height", self.height);
    editor:UpdateLayout();
end

function BlockInputField:GetScreenXY()
    local blockly = self:GetBlock():GetBlockly();
    local left, top = self.left + blockly.offsetX, self.top + blockly.offsetY;
    return blockly:RelativePointToScreenPoint(left, top);
end

function BlockInputField:GetFieldEditType()
    return "none";
end

function BlockInputField:GetFieldEditElement(parentElement)
    local editElement = self:GetEditElement();
    local edittype = self:GetFieldEditType();
    
    if (editElement) then 
        if (edittype == "select") then editElement:SetAttrValue("options", self:GetOptions(true)) end
        return editElement;
    end

    if (edittype == "input") then
        editElement = self:GetFieldInputEditElement(parentElement);
    elseif (edittype == "textarea") then
        editElement = self:GetFieldTextAreaEditElement(parentElement);
    elseif (edittype == "select") then
        editElement = self:GetFieldSelectEditElement(parentElement);
    elseif (edittype == "color") then
        editElement = self:GetFieldColorEditElement(parentElement);
    end

    self:SetEditElement(editElement);
    return editElement;
end

function BlockInputField:BeginEdit()
    if (not self:IsCanEdit()) then return end

    -- 获取编辑器元素
    local editor = self:GetEditorElement();
    -- 清空旧编辑元素
    editor:ClearChildElement();
    -- 获取编辑元素
    local fieldEditElement = self:GetFieldEditElement(editor);
    -- 不存在退出
    if (not fieldEditElement) then return end
    -- 设置当前值
    fieldEditElement:SetAttrValue("value", self:GetValue());
    -- 添加编辑元素
    editor:InsertChildElement(fieldEditElement);
    -- 添加删除 Icon
    if (self:IsCanDelete()) then 
        local deleteIcon = DivElement:new():Init({
            name = "div",
            attr = {style = "position: absolute; left: 50%; top: -30px; width: 14px; height: 15px; margin-left: -7px; background: url(Texture/Aries/Creator/keepwork/ggs/blockly/delete_14x15_32bits.png#0 0 14 15);"}
        }, editor:GetWindow(), editor);
        deleteIcon:SetAttrValue("onmousedown", function()
            local topBlock = self:GetTopBlock();
            local InputFieldContainer = self:GetInputFieldContainer();
            InputFieldContainer:DeleteInputField(self);
            topBlock:UpdateLayout();
        end);
        editor:InsertChildElement(deleteIcon);
    end
    -- 设置元素编辑状态
    self:SetEdit(true);
    -- 显示编辑
    editor:SetVisible(true);
    -- 更新布局
    self:UpdateEditAreaSize();
    -- 聚焦
    fieldEditElement:FocusIn();
    -- 全选
    if (self:GetFieldEditType() == "input") then fieldEditElement:handleSelectAll() end

    self:GetBlock():GetBlockly():SetEditing(true);
end

function BlockInputField:EndEdit()
    self:SetEdit(false);
    self:GetBlock():GetBlockly():SetEditing(false);

    -- 失焦
    local fieldEditElement = self:GetEditElement();
    if (fieldEditElement) then fieldEditElement:FocusOut() end

    local editor = self:GetEditorElement();
    editor:ClearChildElement();
    editor:SetVisible(false);
    self:GetTopBlock():UpdateLayout();
    self:GetBlock():GetBlockly():OnChange(); -- {action = "field_edit"}
    self:GetBlock():GetBlockly():SetFocusUI(nil);
end

function BlockInputField:OnBeginEdit()
end

function BlockInputField:OnEndEdit()
    
end

function BlockInputField:OnFocusIn()
    self:BeginEdit();
    self:OnBeginEdit();
end

function BlockInputField:OnFocusOut()
    self:EndEdit();
    self:OnEndEdit();
end

function BlockInputField:GetLanguage()
    return self:GetBlock():GetBlockly():GetLanguage();
end

function BlockInputField:GetNumberValue()
    local value = self:GetValue();
    value = string.gsub(value, ' ', '');
    return tonumber(value) or self:GetDefaultValue() or 0;
end

function BlockInputField:GetFieldValue()
    return self:GetValue();
end

function BlockInputField:SetFieldValue(value)
    local validator = self:GetValidator();
    value = tostring(value or "");
    if (type(validator) == "function") then value = validator(value) end
    if (type(validator) == "string" and type(Validator[validator]) == "function") then value = (Validator[validator])(value) end
    self:SetValue(value);
    self:SetLabel(value);
end

function BlockInputField:GetScale()
    return self:GetBlock():GetBlockly():GetScale();
end

function BlockInputField:ForEach(callback)
    if (type(callback) == "function") then callback(self) end
end

function BlockInputField:OnUI(eventName, eventData)
end

function BlockInputField:TextToXmlInnerNode(text)
	if(text and commonlib.Encoding.HasXMLEscapeChar(text)) then
		return {name="![CDATA[", [1] = text};
	else
		return text;
	end
end