--[[
Title: G
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Block = NPL.load("script/ide/System/UI/Blockly/Block.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
local BlocklySimulator = NPL.load("./BlocklySimulator.lua");

local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");
local Const = NPL.load("./Const.lua");
local Shape = NPL.load("./Shape.lua");
local Connection = NPL.load("./Connection.lua");
local BlockInputField = NPL.load("./BlockInputField.lua");
local Input = NPL.load("./Inputs/Input.lua");
local Field = NPL.load("./Fields/Field.lua");
local InputFieldContainer = NPL.load("./InputFieldContainer.lua");
local FieldSpace = NPL.load("./Fields/Space.lua");
local FieldColor = NPL.load("./Fields/Color.lua");
local FieldLabel = NPL.load("./Fields/Label.lua");
local FieldValue = NPL.load("./Fields/Value.lua");
local FieldButton = NPL.load("./Fields/Button.lua");
local FieldImage = NPL.load("./Fields/Image.lua");
local FieldInput = NPL.load("./Fields/Input.lua");
local FieldTextarea = NPL.load("./Fields/Textarea.lua");
local FieldJson = NPL.load("./Fields/Json.lua");
local FieldSelect = NPL.load("./Fields/Select.lua");
local FieldVariable = NPL.load("./Fields/Variable.lua");
local InputValue = NPL.load("./Inputs/Value.lua");
local InputValueList = NPL.load("./Inputs/ValueList.lua");
local InputStatement = NPL.load("./Inputs/Statement.lua");
local FieldCode = NPL.load("./FieldCode.lua");
local FoldedBlock = NPL.load("./FoldedBlock.lua");
local Block = commonlib.inherit(BlockInputField, NPL.export());
local BlockDebug = System.Util.Debug.GetModuleDebug("BlockDebug").Disable();   --Enable  Disable

local nextBlockId = 1;
local BlockPen = {width = 1, color = "#ffffff"};
local CurrentBlockPen = {width = 2, color = "#cccccc"};
local BlockBrush = {color = "#ffffff"};
local CurrentBlockBrush = {color = "#ffffff"};
local DisableRunBlockColor = "#e0e0e0";

Block:Property("Blockly");
Block:Property("Id");
Block:Property("ClassName", "Block");
Block:Property("TopBlock", false, "IsTopBlock");                               -- 是否是顶层块
Block:Property("InputShadowBlock", false, "IsInputShadowBlock");               -- 是否是输入shadow块
Block:Property("ToolBoxBlock", false, "IsToolBoxBlock");                       -- 是否是工具箱块
Block:Property("Draggable", true, "IsDraggable");                              -- 是否可以拖拽
Block:Property("Dragging", true, "IsDragging");                                -- 是否在拖拽中
Block:Property("ProxyBlock");                                                  -- 代理块
Block:Property("HideInToolbox", false, "IsHideInToolbox");                     -- 是否在工具栏中隐藏
Block:Property("Indent", "");                                                  -- 缩进
Block:Property("DisableRun", false, "IsDisableRun");                           -- 是否禁止执行

function Block:ctor()
    self:SetId(nextBlockId);
    nextBlockId = nextBlockId + 1;

    self.inputFieldContainerList = {};           -- 输入字段容器列表
    self.inputFieldMap = {};
    self.inputFieldOptionList = {};

    self:SetToolBoxBlock(false);
    self:SetDraggable(true);
    self:SetDragging(false);
end

function Block:Init(blockly, opt, isToolBoxBlock)
    self:SetBlockly(blockly);
    self:SetToolBoxBlock(isToolBoxBlock);

    Block._super.Init(self, self, opt);
    
    self:SetHideInToolbox(opt.hideInToolbox);
    self:SetDraggable(if_else(opt.isDraggable == false, false, true));

    if (opt.id) then self:SetId(opt.id) end
    
    if (opt.output) then self.outputConnection = Connection:new():Init(self, "output_connection", opt.output) end
    if (opt.previousStatement) then self.previousConnection = Connection:new():Init(self, "previous_connection", opt.previousStatement) end
    if (opt.nextStatement) then self.nextConnection = Connection:new():Init(self, "next_connection", opt.nextStatement) end
    
    self:ParseMessageAndArg(opt);
    return self;
end

function Block:OnCreate()
    for i, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        for j, inputField in ipairs(inputFieldContainer.inputFields) do
            inputField:OnCreate();
        end
    end 
    local OnCreate = self:GetOption().OnCreate;
    if (type(OnCreate) == "function") then
        OnCreate(self);
    end
end

function Block:Clone(clone, isAll)
    clone = clone or Block:new():Init(self:GetBlockly(), self:GetOption());
    clone:SetLeftTopUnitCount(self.leftUnitCount, self.topUnitCount);
    for i, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        for j, inputField in ipairs(inputFieldContainer.inputFields) do
            local cloneInputField = clone.inputFieldContainerList[i].inputFields[j];
            if (inputField:GetType() == "input_value" and inputField:IsValueListItem() and cloneInputField and cloneInputField:GetType() == "input_value_list") then
                cloneInputField = cloneInputField:AddInputValue();
            end
            if (inputField:IsCanEdit()) then
                cloneInputField:SetLabel(inputField:GetLabel());
                cloneInputField:SetValue(inputField:GetValue());
            end
            if (inputField:IsInput() and inputField.inputConnection:IsConnection()) then
                local connectionBlock = inputField.inputConnection:GetConnectionBlock();
                local cloneConnectionBlock = connectionBlock:Clone(connectionBlock:IsInputShadowBlock() and cloneInputField.inputConnection:GetConnectionBlock() or nil, true);
                cloneInputField.inputConnection:Connection(cloneConnectionBlock.outputConnection or cloneConnectionBlock.previousConnection);
                if (connectionBlock:GetProxyBlock() == self) then cloneConnectionBlock:SetProxyBlock(clone) end
            end
        end
    end 
    clone:UpdateLayout();
    clone:SetDraggable(self:IsDraggable());
    clone:SetInputShadowBlock(self:IsInputShadowBlock());

    if (isAll) then 
        local nextBlock = self:GetNextBlock();
        local nextCloneBlock = nextBlock and nextBlock:Clone(nil, true);
        if (nextCloneBlock) then
            clone.nextConnection:Connection(nextCloneBlock.previousConnection);
        end
    end
    return clone;
end

function Block:ParseMessageAndArg(opt)
    local index, inputFieldContainerIndex = 0, 1;

    local function GetMessageArg()
        if (opt.message) then
            if (index ~= 0) then return nil, nil end
            index = -1;
            return opt.message, opt.arg;
        end

        local messageIndex, argIndex = "message" .. tostring(index), "arg" .. tostring(index);
        local message, arg = opt[messageIndex], opt[argIndex];
        if (index == 0) then message, arg = opt.message or message, opt.arg or arg end
        index = index + 1;
        return message, arg;
    end

    local function GetInputFieldContainer(isFillFieldSpace)
        local inputFieldContainer = self.inputFieldContainerList[inputFieldContainerIndex] or InputFieldContainer:new():Init(self, isFillFieldSpace);
        self.inputFieldContainerList[inputFieldContainerIndex] = inputFieldContainer;
        return inputFieldContainer;
    end

    local text_template = "";
    local message, arg = GetMessageArg();
    while (message) do
        local lastNo = 0;
        local startPos, len = 1, string.len(message);
        while(startPos <= len) do
            local inputFieldContainer = GetInputFieldContainer(true);
            local pos = string.find(message, "%%", startPos);
            if (not pos) then pos = len + 1 end
            local nostr = string.match(message, "%%([%*%d]+)", startPos) or "";
            local no, nolen = tonumber(nostr), string.len(nostr);
            local text = string.sub(message, startPos, pos - 1) or "";
            local textlen = string.len(text);
            text = string.gsub(string.gsub(text, "^%s*", ""), "%s*$", "");
             -- 添加FieldLabel
            if (text ~= "") then 
                inputFieldContainer:AddInputField(FieldLabel:new():Init(self, {text = text}), true);
                text_template = text_template .. text .. " ";
            end
            no = no or (nolen > 0 and lastNo + 1 or nil);
            if (no and arg and arg[no]) then
                -- 添加InputAndField
                local inputField = arg[no];
                if (inputField.type == "field_label") then
                    inputFieldContainer:AddInputField(FieldLabel:new():Init(self, inputField), true);
                elseif (inputField.type == "field_input" or inputField.type == "field_number" or inputField.type == "field_password") then
                    inputFieldContainer:AddInputField(FieldInput:new():Init(self, inputField), true);
                elseif (inputField.type == "field_color") then
                    inputFieldContainer:AddInputField(FieldColor:new():Init(self, inputField), true);
                elseif (inputField.type == "field_button") then
                    inputFieldContainer:AddInputField(FieldButton:new():Init(self, inputField), true);
                elseif (inputField.type == "field_image") then
                    inputFieldContainer:AddInputField(FieldImage:new():Init(self, inputField), true);
                elseif (inputField.type == "field_value") then
                    inputFieldContainer:AddInputField(FieldValue:new():Init(self, inputField), true);
                elseif (inputField.type == "field_textarea") then
                    inputFieldContainer:AddInputField(FieldTextarea:new():Init(self, inputField), true);
                elseif (inputField.type == "field_json") then
                    inputFieldContainer:AddInputField(FieldJson:new():Init(self, inputField), true);
                elseif (inputField.type == "field_select" or inputField.type == "field_dropdown") then
                    inputFieldContainer:AddInputField(FieldSelect:new():Init(self, inputField), true);
                elseif (inputField.type == "field_variable") then
                    inputFieldContainer:AddInputField(FieldVariable:new():Init(self, inputField), true);
                elseif (inputField.type == "input_dummy") then
                    -- inputFieldContainer:AddInputField(InputDummy:new():Init(self, inputField));
                elseif (inputField.type == "input_value") then
                    inputFieldContainer:AddInputField(InputValue:new():Init(self, inputField), true);
                elseif (inputField.type == "input_value_list") then
                    inputFieldContainer:AddInputField(InputValueList:new():Init(self, inputField), true);
                elseif (inputField.type == "input_statement") then
                    -- inputFieldContainer:AddInputField(FieldSpace:new():Init(self));
                    inputFieldContainerIndex = inputFieldContainerIndex + 1;
                    inputFieldContainer = GetInputFieldContainer();
                    inputFieldContainer:AddInputField(InputStatement:new():Init(self, inputField));
                    inputFieldContainer:SetInputStatementContainer(true);
                    inputFieldContainerIndex = inputFieldContainerIndex + 1;
                end
                
                table.insert(self.inputFieldOptionList, inputField);

                local field_name = inputField.name or "";
                if (field_name ~= "") then
                    text_template = text_template .. " " .. string.format("${%s}", field_name);
                end
            end
            startPos = pos + 1 + nolen;
            lastNo = no;
        end
        
        message, arg = GetMessageArg();
    end

    self.m_text_template = text_template;
    if (#self.inputFieldContainerList == 0) then GetInputFieldContainer(true) end
end

function Block:GetText()
    local field_texts = {};
    local field_size = #self.inputFieldOptionList;
    for i = 1, field_size do
        local input_field_option = self.inputFieldOptionList[i];
        local field_name = input_field_option.name or "";
        local input_field = self:GetField(field_name);
        if (field_name ~= "" and input_field) then
            field_texts[field_name] = input_field:GetText();
        end  
    end
    return string.gsub(self.m_text_template, "%$%{([%w%_]+)%}", field_texts);      -- ${name} 取字段值
end

-- 大小改变
function Block:OnSizeChange()
    -- 设置连接大小
    if (self.previousConnection) then
        self.previousConnection:SetGeometry(self.leftUnitCount, self.topUnitCount - Const.ConnectionRegionHeightUnitCount / 2, self.widthUnitCount, Const.ConnectionRegionHeightUnitCount);
    end

    if (self.nextConnection) then
        self.nextConnection:SetGeometry(self.leftUnitCount, self.topUnitCount + self.heightUnitCount - Const.ConnectionRegionHeightUnitCount / 2, self.widthUnitCount, Const.ConnectionRegionHeightUnitCount);
    end

    if (self.outputConnection) then
        self.outputConnection:SetGeometry(self.leftUnitCount, self.topUnitCount, self.widthUnitCount, self.heightUnitCount);
    end
end

function Block:IsOutput()
    return self.outputConnection ~= nil;
end

function Block:IsStatement()
    return self.previousConnection ~= nil or self.nextConnection ~= nil;
end

function Block:IsStart()
    return self.previousConnection == nil and self.nextConnection ~= nil;
end

function Block:GetPen()
    local isCurrentBlock = self:GetBlockly():GetCurrentBlock() == self;
    return isCurrentBlock and CurrentBlockPen or BlockPen;
end

function Block:GetBrush()
    local isCurrentBlock = self:GetBlockly():GetCurrentBlock() == self;
    local brush = isCurrentBlock and CurrentBlockBrush or BlockBrush;
    brush.color = self:GetColor();
    local connectionBlock = self:IsOutput() and self.outputConnection:GetConnectionBlock();
    if (self.__is_running__ or (connectionBlock and connectionBlock.__is_running__)) then
        brush.color = Const.HighlightColors[brush.color] or brush.color;
    end
    return brush;
end

function Block:Render(painter)
    -- 绘制凹陷部分
    -- Shape:SetPen(self:GetPen());
    if (self.__is_running__) then
        self.__render_count__ = (self.__render_count__ or 0) + 1;
        if (self.__is_hide__) then
            if (self.__render_count__ > 20) then
                self.__is_hide__ = false;
                self.__render_count__ = 0;
            end
        else
            if (self.__render_count__ > 20) then
                self.__is_hide__ = true;
                self.__render_count__ = 0;
            end
        end
    end
    
    Shape:SetBrush(self:GetBrush());
    painter:Translate(self.left, self.top);
    -- 绘制上下连接
    if (self:IsStatement()) then
        if (self.previousConnection) then
            Shape:DrawPrevConnection(painter, self.widthUnitCount);
        else
            Shape:DrawStartEdge(painter, self.widthUnitCount);
        end
        Shape:DrawNextConnection(painter, self.widthUnitCount, 0, self.heightUnitCount - Const.ConnectionHeightUnitCount);
    else
        Shape:DrawOutput(painter, self.widthUnitCount, self.heightUnitCount);
    end
    painter:Translate(-self.left, -self.top);

    -- 绘制输入字段
    for i, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        -- if (not self.__is_hide__ or inputFieldContainer:IsInputStatementContainer()) then
            inputFieldContainer:Render(painter);
        -- end
    end

    local nextBlock = self:GetNextBlock();
    if (nextBlock) then nextBlock:Render(painter) end
end

function Block:GetMinWidthUnitCount()
    if (self.outputConnection) then return 8 
    elseif (self.previousConnection and self.nextConnection) then return 16
    elseif (not self.previousConnection and self.nextConnection) then return 32 
    else return 0 end
end

function Block:GetMinHeightUnitCount()
    if (self.outputConnection) then return Const.LineHeightUnitCount + Const.BlockEdgeHeightUnitCount * 2
    elseif (self.previousConnection and self.nextConnection) then return Const.LineHeightUnitCount + Const.ConnectionHeightUnitCount * 2
    elseif (not self.previousConnection and self.nextConnection) then return Const.LineHeightUnitCount + Const.ConnectionHeightUnitCount + Const.BlockEdgeHeightUnitCount + 4
    else return 0 end
end

function Block:UpdateWidthHeightUnitCount()
    local maxWidthUnitCount, maxHeightUnitCount, widthUnitCount, heightUnitCount = 0, 0, 0, 0;                                                           -- 方块宽高
    for _, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        local inputFieldContainerMaxWidthUnitCount, inputFieldContainerMaxHeightUnitCount, inputFieldContainerWidthUnitCount, inputFieldContainerHeightUnitCount = inputFieldContainer:UpdateWidthHeightUnitCount();
        inputFieldContainerWidthUnitCount, inputFieldContainerHeightUnitCount = inputFieldContainerWidthUnitCount or inputFieldContainerMaxWidthUnitCount, inputFieldContainerHeightUnitCount or inputFieldContainerMaxHeightUnitCount;
        
        widthUnitCount = math.max(widthUnitCount, inputFieldContainerWidthUnitCount);
        heightUnitCount = heightUnitCount + inputFieldContainerHeightUnitCount;
        maxWidthUnitCount = math.max(maxWidthUnitCount, inputFieldContainerMaxWidthUnitCount);
        maxHeightUnitCount = maxHeightUnitCount + inputFieldContainerMaxHeightUnitCount;
    end
    
    widthUnitCount = math.max(widthUnitCount, self:GetMinWidthUnitCount());
    heightUnitCount = math.max(heightUnitCount, Const.LineHeightUnitCount);
    maxWidthUnitCount = math.max(widthUnitCount, maxWidthUnitCount);
    maxHeightUnitCount = math.max(heightUnitCount, maxHeightUnitCount);

    for _, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        inputFieldContainer:SetWidthHeightUnitCount(widthUnitCount, nil);
    end

    if (self:IsStatement()) then 
        heightUnitCount = heightUnitCount + Const.ConnectionHeightUnitCount * 2;
        maxHeightUnitCount = maxHeightUnitCount + Const.ConnectionHeightUnitCount * 2;
    else
        heightUnitCount = heightUnitCount + Const.BlockEdgeHeightUnitCount * 2;
        maxHeightUnitCount = maxHeightUnitCount + Const.BlockEdgeHeightUnitCount * 2;
    end

    self:SetWidthHeightUnitCount(widthUnitCount, heightUnitCount);
    self:SetMaxWidthHeightUnitCount(maxWidthUnitCount, maxHeightUnitCount);
    -- BlockDebug.Format("widthUnitCount = %s, heightUnitCount = %s, maxWidthUnitCount = %s, maxHeightUnitCount = %s", widthUnitCount, heightUnitCount, maxWidthUnitCount, maxHeightUnitCount);
    
    local nextBlock = self:GetNextBlock();
    if (nextBlock) then 
        local _, _, _, _, nextBlockTotalWidthUnitCount, nextBlockTotalHeightUnitCount = nextBlock:UpdateWidthHeightUnitCount();
        self:SetTotalWidthHeightUnitCount(math.max(maxWidthUnitCount, nextBlockTotalWidthUnitCount), maxHeightUnitCount + nextBlockTotalHeightUnitCount);
    else
        self:SetTotalWidthHeightUnitCount(maxWidthUnitCount, maxHeightUnitCount);
    end
    local totalWidthUnitCount, totalHeightUnitCount = self:GetTotalWidthHeightUnitCount();
    return maxWidthUnitCount, maxHeightUnitCount, widthUnitCount, heightUnitCount, totalWidthUnitCount, totalHeightUnitCount;
end

-- 更新左上位置
function Block:UpdateLeftTopUnitCount()
    local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
    local offsetX, offsetY = leftUnitCount, topUnitCount;
    
    if (self:IsStatement()) then 
        offsetY = topUnitCount + Const.ConnectionHeightUnitCount;
    else
        offsetY = topUnitCount + Const.BlockEdgeHeightUnitCount;
    end

    for i, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        -- local prev, next = self.inputFieldContainerList[i - 1], self.inputFieldContainerList[i + 1];
        -- local isOffset = prev and prev:IsInputStatementContainer() and next and next:IsInputStatementContainer() and (not inputFieldContainer:IsInputStatementContainer());
        local inputFieldContainerTotalWidthUnitCount, inputFieldContainerTotalHeightUnitCount = inputFieldContainer:GetWidthHeightUnitCount();
        -- offsetY = offsetY + (isOffset and -1 or 0);
        inputFieldContainer:SetLeftTopUnitCount(offsetX, offsetY);
        inputFieldContainer:UpdateLeftTopUnitCount();
        offsetY = offsetY + inputFieldContainerTotalHeightUnitCount;
    end
   
    local nextBlock = self:GetNextBlock();
    if (nextBlock) then
        local widthUnitCount, heightUnitCount = self:GetWidthHeightUnitCount();
        nextBlock:SetLeftTopUnitCount(leftUnitCount, topUnitCount + heightUnitCount);
        nextBlock:UpdateLeftTopUnitCount();
    end
end

function Block:UpdateLayout()
    self:UpdateWidthHeightUnitCount();
    self:UpdateLeftTopUnitCount();
end

-- 获取鼠标元素
function Block:GetMouseUI(x, y, event)
    -- 整个块区域内
    if (x < self.left or x > (self.left + self.totalWidth) or y < self.top or y > (self.top + self.totalHeight)) then return end
    
    -- 不在block内
    if (x < self.left or x > (self.left + self.maxWidth) or y < self.top or y > (self.top + self.maxHeight)) then 
        local nextBlock = self:GetNextBlock();
        return nextBlock and nextBlock:GetMouseUI(x, y, event);
    end

    -- 上下边缘高度
    local height = (not self:IsStatement() and Const.BlockEdgeHeightUnitCount or Const.ConnectionHeightUnitCount) * self:GetUnitSize();
    -- 在block上下边缘
    if (self.left < x and x < (self.left + self.width)) then
        if (self.top < y and y < (self.top + height)) then return self end
        if (y > (self.top + self.height - height) and y < (self.top + self.height + (self.nextConnection and height or 0))) then return self end
    end
    
    -- 遍历输入
    for _, inputFieldContainer in ipairs(self.inputFieldContainerList) do
        local ui = inputFieldContainer:GetMouseUI(x, y, event);
        if (ui) then return ui end
    end

    return nil;
end

function Block:IsFilterDrag() --lock edit
    local draggFilter = GameLogic.GetFilters():apply_filters('CodeBlockWindow.IsDragable')
    return draggFilter == false
end

function Block:OnMouseDown(event)
    if (self:IsDragging() or self:IsFilterDrag()) then return end 
   
    local blockly = self:GetBlockly();
    self.startX, self.startY = blockly:GetLogicViewPoint(event);
    self.lastMouseMoveX, self.lastMouseMoveY = self.startX, self.startY;
    self.startLeftUnitCount, self.startTopUnitCount = self.leftUnitCount, self.topUnitCount;
    self.isMouseDown = true;
end

function Block:OnMouseMove(event)
    if (not self.isMouseDown or (not event:IsLeftButton() and not self:IsDragging())) then return end
    if (not self:IsDraggable()) then return end
    
    local x, y = self:GetBlockly():GetLogicViewPoint(event);
    if (x == self.lastMouseMoveX and y == self.lastMouseMoveY) then return end
    
    event:Accept();

    self.lastMouseMoveX, self.lastMouseMoveY = x, y;
    
    local blockly, block = self:GetBlockly(), self;
    local scale, toolboxScale = blockly:GetScale(), blockly:GetToolBox():GetScale();
    if (not block:IsDragging()) then
        if (not event:IsMove()) then return end
        if (block:IsToolBoxBlock()) then 
            clone = block:Clone(nil, true);
            clone:SetToolBoxBlock(false);
            clone:OnCreate();
            clone.isNewBlock = true;
            clone.startX, clone.startY, clone.lastMouseMoveX, clone.lastMouseMoveY, clone.isMouseDown = block.startX, block.startY, block.lastMouseMoveX, block.lastMouseMoveY, block.isMouseDown;
            local blockX, blockY = math.floor(block.leftUnitCount * block:GetUnitSize() * toolboxScale / scale + 0.5) - blockly.offsetX, math.floor(block.topUnitCount * block:GetUnitSize() * toolboxScale / scale + 0.5) - blockly.offsetY; 
            clone.startLeftUnitCount = math.floor(blockX / clone:GetUnitSize());
            clone.startTopUnitCount = math.floor(blockY / clone:GetUnitSize());
            clone:SetLeftTopUnitCount(clone.startLeftUnitCount, clone.startTopUnitCount);
            clone:UpdateLayout();
            self:GetBlockly():OnCreateBlock(clone);
            block.isMouseDown = false;
            block = clone;
        end
        block:SetDragging(true);
        blockly:CaptureMouse(block);
    end
    if (block:IsDragging() and blockly:GetMouseCaptureUI() ~= block) then blockly:CaptureMouse(block) end
    blockly:SetCurrentBlock(block);

    local UnitSize = block:GetUnitSize();
    local XUnitCount = math.floor((x - block.startX) / UnitSize);
    local YUnitCount = math.floor((y - block.startY) / UnitSize);
    
    if (block.previousConnection and block.previousConnection:IsConnection()) then 
        local connection = block.previousConnection:Disconnection();
        if (connection) then connection:GetBlock():GetTopBlock():UpdateLayout() end
    end

    if (block.outputConnection and block.outputConnection:IsConnection()) then
        local connection = self.outputConnection:Disconnection();
        if (connection) then connection:GetBlock():GetTopBlock():UpdateLayout() end
    end

    block:GetBlockly():AddBlock(block);
    block:SetLeftTopUnitCount(block.startLeftUnitCount + XUnitCount, block.startTopUnitCount + YUnitCount);
    block:UpdateLeftTopUnitCount();
    blockly:GetShadowBlock():Shadow(block);
end

function Block:OnMouseUp(event)
    local blockly = self:GetBlockly();
    blockly:GetShadowBlock():Shadow(nil);
    local function delete_block()
        blockly:RemoveBlock(self);
        blockly:OnDestroyBlock(self);
        blockly:SetCurrentBlock(nil);
        blockly:ReleaseMouseCapture();
        -- 移除块
        if (not self.isNewBlock) then 
            blockly:Do({action = "DeleteBlock", block = self, blockCount = blockCount});
            blockly:PlayDestroyBlockSound();
        end
        self:SetDragging(false);
        self.isMouseDown = false;
        self.isNewBlock = false;
    end

    if (self:IsDragging()) then
        if (blockly:IsInnerDeleteArea(event.x, event.y)) then
            return delete_block();
        else
            local isConnection = self:TryConnectionBlock();
            if (isConnection) then 
                -- blockly:PlayConnectionBlockSound();
            else
                if ((false and self:IsOutput()) or (self.previousConnection and not self.previousConnection:IsConnection() and self.previousConnection:GetCheck())) then
                    return delete_block();
                end
            end
        end
        if (self.isNewBlock) then 
            blockly:Do({action = "NewBlock", block = self, blockCount = blockCount});
            blockly.PlayCreateBlockSound();
            if (blockly:IsCanSimulateEvent()) then
                BlocklySimulator:AddNewBlockVirtualEvent(self:GetType());
            end
        else
            blockly:Do({action = "MoveBlock", block = self, blockCount = blockCount});
        end
        blockly:AdjustContentSize();
    end

    blockly:SetCurrentBlock(self);
    self.isMouseDown = false;
    self.isNewBlock = false;
    self:SetDragging(false);
    blockly:ReleaseMouseCapture();
end

function Block:Disconnection()
    local previousConnection = self.previousConnection and self.previousConnection:Disconnection();
    local nextConnection = self.nextConnection and self.nextConnection:Disconnection();

    if (previousConnection) then
        previousConnection:Connection(nextConnection);
        previousConnection:GetBlock():GetTopBlock():UpdateLayout();
    else 
        if (nextConnection) then
            self:GetBlockly():AddBlock(nextConnection:GetBlock());
        end
    end

    if (self.outputConnection) then self.outputConnection:Disconnection() end
end

function Block:GetBlockCount()
    local block = self;
    local count = 0;
    while(block) do
        count = count + 1;
        block = block:GetNextBlock();
    end
    return count;
end

function Block:GetConnection()
    if (self.outputConnection) then return self.outputConnection:GetConnection() end
    if (self.previousConnection) then return self.previousConnection:GetConnection() end
    return nil;
end

function Block:TryConnectionBlock(target_block)
    target_block = target_block or self;
    target_block.m_connection_distance = nil;
    target_block.m_connection_callback = nil;

    local blocks = self:GetBlockly():GetBlocks();
    local is_connect = false;
    for _, block in ipairs(blocks) do
        -- if (block:ConnectionBlock(target_block)) then return true end
        local is_connect_block = block:ConnectionBlock(target_block);
        is_connect = is_connect or is_connect_block;
    end

    if (target_block.m_connection_distance) then
        target_block.m_connection_callback();
        return true;
    end

    return is_connect;
end

function Block:IsIntersect(block, isSingleBlock)
    local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
    local widthUnitCount, heightUnitCount = block:GetWidthHeightUnitCount();
    local halfWidthUnitCount, halfHeightUnitCount = widthUnitCount / 2, heightUnitCount / 2;
    local centerX, centerY = leftUnitCount + halfWidthUnitCount, topUnitCount + halfHeightUnitCount;

    local blockLeftUnitCount, blockTopUnitCount = self:GetLeftTopUnitCount();
    local blockWidthUnitCount, blockHeightUnitCount = self:GetMaxWidthHeightUnitCount();
    if (not isSingleBlock) then blockWidthUnitCount, blockHeightUnitCount = self:GetTotalWidthHeightUnitCount() end
    local blockHalfWidthUnitCount, blockHalfHeightUnitCount = blockWidthUnitCount / 2, blockHeightUnitCount / 2;
    local blockCenterX, blockCenterY = blockLeftUnitCount + blockHalfWidthUnitCount, blockTopUnitCount + blockHalfHeightUnitCount;
    BlockDebug.Format("Id = %s, left = %s, top = %s, width = %s, height = %s, Id = %s, left = %s, top = %s, width = %s, height = %s", 
        block:GetId(), leftUnitCount, topUnitCount, widthUnitCount, heightUnitCount, block:GetId(), blockLeftUnitCount, blockTopUnitCount, blockWidthUnitCount, blockHeightUnitCount);
    BlockDebug.Format("centerX = %s, centerY = %s, halfWidthUnitCount = %s, halfHeightUnitCount = %s, blockCenterX = %s, blockCenterY = %s, blockHalfWidthUnitCount = %s, blockHalfHeightUnitCount = %s", 
        centerX, centerY, halfWidthUnitCount, halfHeightUnitCount, blockCenterX, blockCenterY, blockHalfWidthUnitCount, blockHalfHeightUnitCount);

    local nextBlock = self:GetNextBlock();
    local prevBlock = self:GetPrevBlock();
    while (prevBlock and prevBlock.leftUnitCount == leftUnitCount) do prevBlock = prevBlock:GetPrevBlock() end
    local OffsetHeight = (prevBlock or nextBlock) and 0 or Const.ConnectionRegionHeightUnitCount;
    -- return math.abs(centerX - blockCenterX) <= (halfWidthUnitCount + blockHalfWidthUnitCount) and math.abs(centerY - blockCenterY) <= (halfHeightUnitCount + blockHalfHeightUnitCount + OffsetHeight); -- 预留一个连接高度
    if (math.abs(centerX - blockCenterX) <= (halfWidthUnitCount + blockHalfWidthUnitCount)) then
        if (math.abs(centerY - blockCenterY) <= (halfHeightUnitCount + blockHalfHeightUnitCount)) then
            return true;
        end
        if (math.abs(centerY - blockCenterY) <= (halfHeightUnitCount + blockHalfHeightUnitCount + Const.ConnectionRegionHeightUnitCount)) then
            if (not isSingleBlock) then return true end
            if (not prevBlock and centerY < blockCenterY) then
                return true;
            end
            if (not nextBlock and centerY > blockCenterY) then
                return true;
            end
        end
    end
    return false;
end

function Block:ConnectionBlock(block)
    if (not block or self == block) then return end
    if (block.isShadowBlock and block.shadowBlock == self) then return end

    BlockDebug("==========================BlockConnectionBlock============================");
    -- 只有顶层块才判定是否在整个区域内
    if ((not self.previousConnection or not self.previousConnection:IsConnection()) and self.nextConnection and not self:IsIntersect(block, false)) then return end

    -- 优先匹配上连接
    if (block:IsStart()) then
        if (not self.previousConnection or self.previousConnection:IsConnection()) then return end 
        if (self:IsDraggable() and self.topUnitCount > block.topUnitCount and not (block.isShadowBlock and block.shadowBlock or block).nextConnection:IsConnection() and self.previousConnection:IsMatch(block.nextConnection)) then
            -- 不使用距离规则
            -- self:GetBlockly():RemoveBlock(self);
            -- self.previousConnection:Connection(block.nextConnection)
            -- block:SetLeftTopUnitCount(self.leftUnitCount, self.topUnitCount - block.heightUnitCount);
            -- block:GetTopBlock():UpdateLayout();
            -- 使用距离规则
            local source_block = self;
            local target_block = block;
            local distance = math.abs(source_block.leftUnitCount - target_block.leftUnitCount);
            if (not target_block.m_connection_distance or distance < target_block.m_connection_distance) then
                target_block.m_connection_distance = distance;
                target_block.m_connection_callback = function()
                    source_block:GetBlockly():RemoveBlock(source_block);
                    source_block.previousConnection:Connection(target_block.nextConnection)
                    target_block:SetLeftTopUnitCount(source_block.leftUnitCount, source_block.topUnitCount - target_block.heightUnitCount);
                    target_block:GetTopBlock():UpdateLayout();
                end
            end
            return true;         
        end
        return ;
    end

    -- 是否在块区域内
    if (not self:IsIntersect(block, true)) then
        local nextBlock = self:GetNextBlock();
        return nextBlock and nextBlock:ConnectionBlock(block);
    end

    if (self:IsDraggable() and self.topUnitCount > block.topUnitCount and self.previousConnection and block.nextConnection and 
        not (block.isShadowBlock and block.shadowBlock or block).nextConnection:IsConnection() and self.previousConnection:IsMatch(block.nextConnection)) then
        -- local previousConnection = self.previousConnection:Disconnection();
        -- if (previousConnection) then 
        --     previousConnection:Connection(block.previousConnection);
        --     self:GetBlockly():RemoveBlock(block);
        -- else
        --     self:GetBlockly():RemoveBlock(self);
        -- end
        -- self.previousConnection:Connection(block.nextConnection)
        -- block:SetLeftTopUnitCount(self.leftUnitCount, self.topUnitCount - block.heightUnitCount);
        -- block:GetTopBlock():UpdateLayout();
        
        local source_block = self;
        local target_block = block;
        local distance = math.abs(source_block.leftUnitCount - target_block.leftUnitCount);
        if (not target_block.m_connection_distance or distance < target_block.m_connection_distance) then
            target_block.m_connection_distance = distance;
            target_block.m_connection_callback = function()
                local previousConnection = source_block.previousConnection:Disconnection();
                if (previousConnection) then 
                    previousConnection:Connection(target_block.previousConnection);
                    source_block:GetBlockly():RemoveBlock(target_block);
                else
                    source_block:GetBlockly():RemoveBlock(source_block);
                end
                source_block.previousConnection:Connection(target_block.nextConnection)
                target_block:SetLeftTopUnitCount(source_block.leftUnitCount, source_block.topUnitCount - target_block.heightUnitCount);
                target_block:GetTopBlock():UpdateLayout();
            end
        end
        BlockDebug("===================nextConnection match previousConnection====================");
        return true;
    end

    local nextBlock = self:GetNextBlock();
    -- 下连接匹配
    if ((self.topUnitCount + self.heightUnitCount - Const.ConnectionRegionHeightUnitCount) < block.topUnitCount 
        and self.nextConnection and block.previousConnection and self.nextConnection:IsMatch(block.previousConnection)) then
        -- 当比较靠上时, 优先内部连接匹配
        if ((self.topUnitCount + self.heightUnitCount - Const.ConnectionHeightUnitCount * 2) > block.topUnitCount) then
            for _, inputAndFieldContainer in ipairs(self.inputFieldContainerList) do
                if (inputAndFieldContainer:ConnectionBlock(block)) then return true end
            end
        end

        if (nextBlock and nextBlock.topUnitCount < block.topUnitCount and nextBlock:IsIntersect(block, true)) then
            local isConnection = nextBlock:ConnectionBlock(block);
            if (isConnection) then return true end
        end

        -- self:GetBlockly():RemoveBlock(block);
        -- local nextConnectionConnection = self.nextConnection:Disconnection();
        -- self.nextConnection:Connection(block.previousConnection);
        -- local lastNextBlock = block:GetLastNextBlock();
        -- if (lastNextBlock.nextConnection) then lastNextBlock.nextConnection:Connection(nextConnectionConnection) end
        -- block:SetLeftTopUnitCount(self.leftUnitCount, self.topUnitCount + self.heightUnitCount);
        -- block:GetTopBlock():UpdateLayout();

        -- local blockPrevBlock = block:GetPrevBlock();
        -- local blockNextBlock = block:GetNextBlock();
        -- if (blockPrevBlock and blockPrevBlock:IsDisableRun() and blockNextBlock and blockNextBlock:IsDisableRun() and not block.isShadowBlock) then block:DisableRun(true) end

        if (nextBlock and not nextBlock:IsDraggable()) then return end

        local source_block = self;
        local target_block = block;
        local distance = math.abs(source_block.leftUnitCount - target_block.leftUnitCount);
        if (not target_block.m_connection_distance or distance < target_block.m_connection_distance) then
            target_block.m_connection_distance = distance;
            target_block.m_connection_callback = function()
                source_block:GetBlockly():RemoveBlock(target_block);
                local nextConnectionConnection = source_block.nextConnection:Disconnection();
                source_block.nextConnection:Connection(target_block.previousConnection);
                local lastNextBlock = target_block:GetLastNextBlock();
                if (lastNextBlock.nextConnection) then lastNextBlock.nextConnection:Connection(nextConnectionConnection) end
                target_block:SetLeftTopUnitCount(source_block.leftUnitCount, source_block.topUnitCount + source_block.heightUnitCount);
                target_block:GetTopBlock():UpdateLayout();
        
                local blockPrevBlock = target_block:GetPrevBlock();
                local blockNextBlock = target_block:GetNextBlock();
                if (blockPrevBlock and blockPrevBlock:IsDisableRun() and blockNextBlock and blockNextBlock:IsDisableRun() and not target_block.isShadowBlock) then target_block:DisableRun(true) end
            end
        end
        BlockDebug("===================previousConnection match nextConnection====================");
        return true;
    end

    BlockDebug("===================outputConnection match inputConnection====================");
    -- 字段匹配
    for _, inputAndFieldContainer in ipairs(self.inputFieldContainerList) do
        if (inputAndFieldContainer:ConnectionBlock(block)) then return true end
    end

    -- 下个块如果相交则继续判定下个块
    if (nextBlock and nextBlock:IsIntersect(block, true)) then
        return nextBlock:ConnectionBlock(block);
    end
end

-- 遍历
function Block:ForEach(callback)
    Block._super.ForEach(self, callback);
    for _, inputAndFieldContainer in ipairs(self.inputFieldContainerList) do
        inputAndFieldContainer:ForEach(callback);
    end
    
    local nextBlock = self:GetNextBlock();
    if (nextBlock) then
        nextBlock:ForEach(callback);
    end
end

-- 是否是块
function Block:IsBlock()
    return true;
end

-- 设置所有字段值
function Block:SetFieldsValue(value)
    local values = commonlib.split(value, ' ');
    for i, opt in ipairs(self.inputFieldOptionList) do
        local field = self:GetInputField(opt.name);
        if (field) then field:SetFieldValue(values[i]) end 
    end
end

-- 设置字段值
function Block:SetFieldValue(name, value)
    local inputAndField = self.inputFieldMap[name];
    if (inputAndField) then
        inputAndField:SetFieldValue(value);
    end
end

-- 获取所有字段值
function Block:GetFieldsValue()
    local value = "";
    for i, opt in ipairs(self.inputFieldOptionList) do
        local fieldValue = self:GetFieldValue(opt.name);
        if (i == 1) then value = fieldValue
        else value = value .. " " .. fieldValue end 
    end
    return value;
end

-- 获取字段值
function Block:GetFieldValue(name)
    local inputAndField = self.inputFieldMap[name];
    return inputAndField and inputAndField:GetFieldValue() or nil;
end

-- 获取字段标签
function Block:GetFieldLabel(name)
    local inputAndField = self.inputFieldMap[name];
    return inputAndField and inputAndField:GetLabel() or nil;
end

-- 获取字段
function Block:GetField(name)
    return self.inputFieldMap[name];
end

-- 获取字段
function Block:GetValueAsString(name)
    local inputAndField = self.inputFieldMap[name];
    return inputAndField and inputAndField:GetValueAsString() or "";
end

-- 获取字段值
function Block:getFieldValue(name)
    return self:GetFieldValue(name);
end

-- 获取字符串字段
function Block:getFieldAsString(name)
    return self:GetFieldValue(name);
end

-- 获取输入字段
function Block:GetInputField(name)
    return self.inputFieldMap[name];
end

local _Byte = string.byte("_");
local aByte = string.byte("a");
local zByte = string.byte("z");
local AByte = string.byte("A");
local ZByte = string.byte("Z");
local _0Byte = string.byte("0");
local _9Byte = string.byte("9");
local function ToVarFuncName(str)
    local newstr = "";
    for i = 1, #str do
        local byte = string.byte(str, i, i);
        if (_Byte == byte or (aByte <= byte and byte <=zByte) or (AByte <= byte and byte <=ZByte) or (_0Byte <= byte and byte <= _9Byte)) then
            newstr = newstr .. string.char(byte);
        else 
            newstr = newstr .. string.format("_%X", byte)
        end
    end
    return newstr;
end

local function AutoIndexCodeDescription(code_description, excludes)
    code_description = code_description or "";
    
    local lines = {}
    for line in code_description:gmatch("[^\r\n]+") do
        table.insert(lines, line);
    end
    
    excludes = excludes or {};
    excludes["INDENT"] = true;
    
    local codes = lines[1] or "";
    local lines_size = #lines;
    for i = 2, lines_size do
        local line = lines[i];
        local is_skip_indent = false;

        for key in pairs(excludes or {}) do
            if (string.match(line, "^%s*%$%{" .. key .. "%}")) then
                is_skip_indent = true;
                break;
            end
        end

        if (is_skip_indent) then
            codes = codes .. "\n" .. line;
        else
            codes = codes .. "\n${INDENT}" .. line;
        end
    end

    return codes;
end

local function DefaultToCode(block)
    local blockly = block:GetBlockly();
    local language = block:GetLanguageType();
    local blockType = block:GetType();
    local blockIndent = block:GetIndent()
    local option = block:GetOption();
    if (not option) then return "" end
    local args, argStrs, auto_indent_excludes = {}, {}, {};
    if (option.arg) then
        for i, arg in ipairs(option.arg) do
            if (arg.name) then
                local field = block:GetField(arg.name);
                local field_value = field and field:GetFieldValue() or "";
                local field_code = field and field:GetFieldCode() or "";
                if (type(FieldCode[field_code]) == "function") then field_value = (FieldCode[field_code])(field_value) end

                args[arg.name] = field_value;
                argStrs[arg.name] = field and field:GetValueAsString(field_value) or "";
                
                if (field:GetType() == "input_statement") then
                    auto_indent_excludes[field:GetName()] = true;
                end
            end
        end 
    end
    args["INDENT"] = blockIndent;
    args["ENTER"] = "\n";
    local NEXT_BLOCK_CODE = nil;
    local code_description = option.code_description;
    local code_description_key = "code_description_" .. string.lower(language);
    if (type(option[code_description_key]) == "string") then
        code_description = option[code_description_key];
    end
    local template_format = function(template_code)
        local format_code = string.gsub(template_code or "", "\\n", "\n");
        format_code = string.gsub(format_code, "%$%{([%w%_]+)%}", args);      -- ${name} 取字段值
        format_code = string.gsub(format_code, "%$%(([%w%_]+)%)", argStrs);   -- $(name) 取字段字符串值
        format_code = string.gsub(format_code, "%$%{NEXT%_BLOCK%_CODE%}", function()
            if (NEXT_BLOCK_CODE) then return NEXT_BLOCK_CODE end 
            NEXT_BLOCK_CODE = block:GetAllNextCode();
            return NEXT_BLOCK_CODE;
        end);     -- ${NEXT_BLOCK_CODE}
        format_code = string.gsub(format_code, "%$VAR%_FUNC%_NAME%(([%w%_]+)%)", function(name)
            return ToVarFuncName(args[name]);
        end)
        format_code = string.gsub(format_code, "[\n]+$", "");
        format_code = string.gsub(format_code, "^\n+", "");
        return format_code;
    end

    for _, header in ipairs(option.headers or {}) do
        if (type(header) == "table" and type(header.text) == "string") then
            blockly:AddUniqueHeader(template_format(header.text), tonumber(header.zorder) or 0);
        end
    end

    local code = template_format(AutoIndexCodeDescription(code_description, auto_indent_excludes));

    if (not option.output) then 
        code = code .. "\n" 
    else
        code = string.gsub(code, "[;%s]*$", "");
    end
    return code;
end

function Block:GetToCodeCache()
    return self:GetBlockly():GetToCodeCache();
end

function Block:GetAllCode(indent)
    local block, code = self, "";

    indent = indent or "";
    while (block) do
        local block_code = block:GetCode(indent);
        if (block_code ~= "" and block_code ~= "\n") then 
            code = code .. indent .. block:GetCode(indent);
        end
        block = block:GetNextBlock();
    end
    return code;
end

-- 获取块代码
function Block:GetCode(indent)
    if (self:IsDisableRun()) then return "" end
    self:SetIndent(indent or "");

    local blockly = self:GetBlockly();
    local languageType = self:GetLanguageType();
    local option = self:GetOption();
    local ToLanguageTypeCodeName = string.lower("To" .. languageType);
    local ToLanguageCodeName = string.lower("To" .. self:GetLanguage());
    local ToCode = option[ToLanguageCodeName] or option[ToLanguageTypeCodeName] or DefaultToCode

    if (ToCode == DefaultToCode and type(option.ToCode) == "function") then
        ToCode = option.ToCode;
    else 
        -- print("---------------------图块转换函数不存在---------------------")
    end
    if(option.headerText and option.headerText~="") then
        for header in option.headerText:gmatch("[^\n]+") do
            blockly:AddUniqueHeader(header, -1)
        end
    end
    local OnGenerateBlockCodeBefore = blockly:GetAttrFunctionValue("OnGenerateBlockCodeBefore");
    local beforeBlockCode = OnGenerateBlockCodeBefore and OnGenerateBlockCodeBefore(self) or "";
    local blockCode = ToCode and ToCode(self, DefaultToCode) or "";
    local OnGenerateBlockCodeAfter = blockly:GetAttrFunctionValue("OnGenerateBlockCodeAfter");
    local afterBlockCode = OnGenerateBlockCodeAfter and OnGenerateBlockCodeAfter(self) or "";

    blockly.__block_id_map__[self:GetId()] = self;

    return beforeBlockCode .. blockCode .. afterBlockCode;
end

function Block:GetAllNextCode()
    local code = "";
    local nextBlock = self:GetNextBlock();
    while (nextBlock) do
        code = code .. nextBlock:GetCode();
        nextBlock = nextBlock:GetNextBlock();
    end
    return code;
end

function Block:Save()
    local block = {type = self:GetType(), inputs = {}, fields = {}};
    local blockly = self:GetBlockly();
    if (not (self.previousConnection and self.previousConnection:IsConnection())) then block.x, block.y = self.left, self.top end

    for _, inputAndField in pairs(self.inputFieldMap) do
        local name = inputAndField:GetName();
        if (inputAndField:IsInput()) then
            local input = inputAndField:Save();
            if (input) then block.inputs[name] = input end
        else
            local field = inputAndField:Save();
            if (field) then block.fields[name] = field end
        end
    end

    local next_block = self:GetNextBlock();
    if (next_block) then 
        block.next = {
            type = self:GetType(),
            block = next_block:Save(), 
        } 
    end

    return block;
end

function Block:Load(block)
    if (block.x and block.y) then
        self:SetLeftTopUnitCount(math.floor(block.x / self:GetUnitSize()), math.floor(block.y / self:GetUnitSize()));
    end

    for field_name, field_value in pairs(block.fields or {}) do
        local inputField = self:GetInputField(field_name);
        if (inputField) then
            inputField:Load(field_value);
        end
    end

    for field_name, field_value in pairs(block.inputs or {}) do
        local inputField = self:GetInputField(field_name);
        if (inputField) then
            inputField:Load(field_value);
        end
    end
    if (block.next and block.next.block) then
        local nextBlock = self:GetBlockly():GetBlockInstanceByType(block.next.block.type);
        nextBlock:Load(block.next.block);
        if (nextBlock) then
            self.nextConnection:Connection(nextBlock.previousConnection);
        end
    end
end

-- 获取xmlNode
function Block:SaveToXmlNode()
    local xmlNode = {name = "Block", attr = {}};
    local attr = xmlNode.attr;
    
    attr.type = self:GetType();
    attr.leftUnitCount, attr.topUnitCount = self:GetLeftTopUnitCount();
    attr.isInputShadowBlock = self:IsInputShadowBlock() and "true" or "false";
    attr.isDraggable = self:IsDraggable() and "true" or "false";
    attr.isDisableRun = self:IsDisableRun() and "true" or "false";
    attr.isFoldedBlock = self:IsFoldedBlock() and "true" or "false";

    for _, inputAndField in pairs(self.inputFieldMap) do
        local subXmlNode = inputAndField:SaveToXmlNode();
        if (subXmlNode) then table.insert(xmlNode, subXmlNode) end
    end

    local nextBlock = self:GetNextBlock();
    if (nextBlock) then table.insert(xmlNode, nextBlock:SaveToXmlNode()) end

    local blockly = self:GetBlockly();
    for _, note in ipairs(blockly:GetNotes()) do
        if (note:GetBlock() == self) then
            table.insert(xmlNode, note:SaveToXmlNode());
        end
    end

    if (self:IsFoldedBlock()) then
        local foldedBlockXmlNode = self:GetFoldedBlock():SaveToXmlNode();
        table.insert(xmlNode, {name = "FoldedBlock", [1] = foldedBlockXmlNode});
    end
    return xmlNode;
end

-- 加载xmlNode
function Block:LoadFromXmlNode(xmlNode)
    local attr = xmlNode.attr;

    self:SetLeftTopUnitCount(tonumber(attr.leftUnitCount) or 0, tonumber(attr.topUnitCount) or 0);
    self:SetInputShadowBlock(attr.isInputShadowBlock == "true");
    self:SetDraggable(if_else(attr.isDraggable == "false", false, true));

    local blockly = self:GetBlockly();
    local nextBlock = nil;
    for _, childXmlNode in ipairs(xmlNode) do
        if (childXmlNode.name == "Block") then
            nextBlock = self:GetBlockly():GetBlockInstanceByXmlNode(childXmlNode);
        elseif (childXmlNode.name == "Note") then
            blockly:AddNote(self):LoadFromXmlNode(childXmlNode);
        elseif (childXmlNode.name == "FoldedBlock") then
            -- 忽略
        else
            local inputField = self:GetInputField(childXmlNode.attr.name);
            if (inputField) then 
                inputField:LoadFromXmlNode(childXmlNode);
            end
        end
    end

    if (if_else(attr.isDisableRun == "true", true, false)) then 
        self:DisableRun();
    end
    
    if (nextBlock) then
        self.nextConnection:Connection(nextBlock.previousConnection);
    end
end

function Block:DisableRun(is_disable_next_block)
    if (self:IsDisableRun()) then return end
    self.enable_block_color = self:GetColor();
    self:SetColor(DisableRunBlockColor);
    self:SetDisableRun(true);

    for _, inputAndField in pairs(self.inputFieldMap) do
        inputAndField:DisableRun();
    end

    if (is_disable_next_block) then
        local next_block = self:GetNextBlock();
        if (next_block) then
            next_block:DisableRun(true);
        end
    end
end

function Block:EnableRun(is_enable_next_block)
    if (not self:IsDisableRun()) then return end

    self:SetColor(self.enable_block_color);
    self:SetDisableRun(false);

    for _, inputAndField in pairs(self.inputFieldMap) do
        inputAndField:EnableRun();
    end

    if (is_enable_next_block) then
        local next_block = self:GetNextBlock();
        if (next_block) then
            next_block:EnableRun(true);
        end
    end
end

function Block:IsFoldedBlock()
    return false;
end

function Block:Folded()
    if (self:IsFoldedBlock()) then return end

    local blockly = self:GetBlockly();
    local top_block = self:GetTopBlock();
    local next_block = self:GetNextBlock();
    self.nextConnection:Disconnection();

    local folded_block = FoldedBlock:new():Init(self:GetBlockly(), self);
    if (top_block == self) then
        blockly:RemoveBlock(self);
        blockly:AddBlock(folded_block);
        top_block = folded_block;
        local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
        top_block:SetLeftTopUnitCount(leftUnitCount, topUnitCount);
    end
    
    if (next_block) then
        folded_block.nextConnection:Connection(next_block.previousConnection);
    end

    top_block:UpdateLayout();
end

function Block:Expand()
    if (not self:IsFoldedBlock()) then return end
    local blockly = self:GetBlockly();
    local folded_block = self:GetFoldedBlock();
    local top_block = self:GetTopBlock();
    local folded_last_next_block = folded_block:GetLastNextBlock();

    local previousNextConnection = self.previousConnection and self.previousConnection:Disconnection();
    local nextPreviousConnection = self.nextConnection and self.nextConnection:Disconnection();
    local outputInputConnection = self.outputConnection and self.outputConnection:Disconnection();
    if (previousNextConnection and folded_block.previousConnection) then
        previousNextConnection:Connection(folded_block.previousConnection);
    end
    if (nextPreviousConnection and folded_last_next_block and folded_last_next_block.nextConnection) then
        nextPreviousConnection:Connection(folded_last_next_block.nextConnection);
    end
    if (outputInputConnection and folded_block.outputConnection) then
        outputInputConnection:Connection(folded_block.outputConnection);
    end

    if (top_block == self) then 
        blockly:RemoveBlock(self);
        blockly:AddBlock(folded_block);
        top_block = folded_block;
        local leftUnitCount, topUnitCount = self:GetLeftTopUnitCount();
        top_block:SetLeftTopUnitCount(leftUnitCount, topUnitCount);
    end

    top_block:UpdateLayout();
end

function Block:DisableDraggable(is_disable_next_block)
    self:SetDraggable(false);

    for _, inputAndField in pairs(self.inputFieldMap) do
        if (inputAndField:IsInput()) then
            local input_block = inputAndField:GetInputBlock();
            if (input_block) then
                input_block:DisableDraggable(true);
            end
        end
    end

    if (is_disable_next_block) then
        local next_block = self:GetNextBlock();
        if (next_block) then
            next_block:DisableDraggable(true);
        end
    end
end

function Block:EnableDraggable(is_enable_next_block)
    self:SetDraggable(true);

    for _, inputAndField in pairs(self.inputFieldMap) do
        if (inputAndField:IsInput()) then
            local input_block = inputAndField:GetInputBlock();
            if (input_block) then
                input_block:EnableDraggable(true);
            end
        end
    end

    if (is_enable_next_block) then
        local next_block = self:GetNextBlock();
        if (next_block) then
            next_block:EnableDraggable(true);
        end
    end
end