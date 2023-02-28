
--[[
Title: G
Author(s): wxa
Date: 2020/6/30
Desc: G
use the lib:
-------------------------------------------------------
local Blockly = NPL.load("script/ide/System/UI/Blockly/Blockly.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BlockSound.lua");
local BlockSound = commonlib.gettable("MyCompany.Aries.Game.Sound.BlockSound");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");
local Helper = NPL.load("./Helper.lua", IsDevEnv);
local BlockManager = NPL.load("./Blocks/BlockManager.lua", IsDevEnv);
local ToolBoxXmlText = NPL.load("./Blocks/ToolBoxXmlText.lua", IsDevEnv);
local BlockOptionGlobal = NPL.load("./Blocks/BlockOptionGlobal.lua", IsDevEnv);
local Options = NPL.load("./Options.lua", IsDevEnv);
local Const = NPL.load("./Const.lua", IsDevEnv);
local Shape = NPL.load("./Shape.lua", IsDevEnv);
local LuaFmt = NPL.load("./LuaFmt.lua", IsDevEnv);
local Element = NPL.load("../Window/Element.lua", IsDevEnv);
local ToolBox = NPL.load("./ToolBox.lua", IsDevEnv);
local ContextMenu = NPL.load("./ContextMenu.lua", IsDevEnv);
local Block = NPL.load("./Block.lua", IsDevEnv);
local ShadowBlock = NPL.load("./ShadowBlock.lua", IsDevEnv);
local BlocklyEditor = NPL.load("./BlocklyEditor.lua", IsDevEnv);
local Note = NPL.load("./Note.lua", IsDevEnv);
local BlocklySimulator = NPL.load("./BlocklySimulator.lua", IsDevEnv);
local ScrollBar = NPL.load("./ScrollBar.lua", IsDevEnv);
local Blockly = commonlib.inherit(Element, NPL.export());

local ConnectionBlockSound = BlockSound:new():Init({"cloth1", "cloth2", "cloth3",});
local DestroyBlockSound = BlockSound:new():Init({"break3", "break2", });

Blockly:Property("Name", "Blockly");  
Blockly:Property("ClassName", "Blockly");  
Blockly:Property("EditorElement");            -- 编辑元素 用户输入
Blockly:Property("Editing", false, "IsEditing");  -- 是否在编辑字段
Blockly:Property("ContextMenu");              -- 上下文菜单
Blockly:Property("MouseCaptureUI");           -- 鼠标捕获UI
Blockly:Property("FocusUI");                  -- 聚焦UI
Blockly:Property("CurrentBlock");             -- 当前拽块
Blockly:Property("RunningBlock");             -- 运行块
Blockly:Property("Language");                 -- 语言
Blockly:Property("FileManager");              -- 文件管理器
Blockly:Property("ToolBox");                  -- 工具栏
Blockly:Property("ShadowBlock");              -- 占位块
Blockly:Property("Scale", 1);                 -- 缩放
Blockly:Property("ReadOnly", false, "IsReadOnly");    -- 只读
Blockly:Property("OptionGlobal");             -- 选项全局表
Blockly:Property("ToCodeCache");              -- 生成代码的时缓存对象
Blockly:Property("RunBlockId", 0);            -- 运行块ID
Blockly:Property("ShowMiniMap", false, "IsShowMiniMap");  -- 是否显示小地图
Blockly:Property("Version", "1.0.0");         -- 当前版本

function Blockly.PlayCreateBlockSound()
    ConnectionBlockSound:play2d();
end

function Blockly.PlayConnectionBlockSound()
    ConnectionBlockSound:play2d();
end

function Blockly.PlayDestroyBlockSound()
    DestroyBlockSound:play2d();
end

function Blockly:ctor()
    self:Reset();
    self.BlockMap, self.CategoryList, self.CategoryMap, self.CategoryColor = {}, {}, {}, {};
    self:SetToolBox(ToolBox:new():Init(self));
    self:SetOptionGlobal(BlockOptionGlobal:new():Init());

    local IsMobileUIEnabled = GameLogic.GetFilters():apply_filters('MobileUIRegister.IsMobileUIEnabled',false)
	if (IsMobileUIEnabled and not GameLogic.Macros:IsRecording() and not GameLogic.Macros:IsPlaying()) then
        Const.UnitSize = 4;
    else 
        Const.UnitSize = 3;
    end
end

function Blockly:Reset()
    self.undos = {};
    self.redos = {};
    self.blocks = {};
    self.notes = {};
    self.__block_id_map__ = {};
    self.__running_block_id_stack__ = {};
    self.offsetX, self.offsetY = 0, 0;
    self.mouseMoveX, self.mouseMoveY = 0, 0;
    self.__content_left_unit_count__, self.__content_top_unit_count__, self.__content_right_unit_count__, self.__content_bottom_unit_count__ = 0, 0, 0, 0;
    self.__offset_x_unit_count__, self.__offset_y_unit_count__ = 0, 0;
    self.__horizontal_scroll_bar__ = ScrollBar:new():Init(self, "horizontal");
    self.__vertical_scroll_bar__ = ScrollBar:new():Init(self, "vertical");
    self:SetScale(1);
end

function Blockly:Init(xmlNode, window, parent)
    Blockly._super.Init(self, xmlNode, window, parent);
    local blocklyEditor = BlocklyEditor:new():Init({
        name = "BlocklyEditor",
        attr = {
            style = "position: absolute; left: 0px; top: 0px; width: 0px; height: 0px; overflow: hidden; background-color: #ffffff00;",
        }
    }, window, self);

    table.insert(self.childrens, blocklyEditor);
    blocklyEditor:SetVisible(false);
    blocklyEditor:SetBlockly(self);
    self:SetEditorElement(blocklyEditor);

    local BlocklyContextMenu = ContextMenu:new():Init({
        name = "ContextMenu",
        attr = {
            style = "position: absolute; left: 0px; top: 0px; width: 0px; height: 0px; overflow: hidden; background-color: #383838; color: #ffffff;",
        }
    }, window, self);
    table.insert(self.childrens, BlocklyContextMenu);
    BlocklyContextMenu:SetVisible(false);
    BlocklyContextMenu:SetBlockly(self);
    self:SetContextMenu(BlocklyContextMenu);

    self:SetShadowBlock(ShadowBlock:new():Init(self));

    self:SetLanguage(self:GetAttrStringValue("language"));
    self:LoadBlockMap();
    self.CategoryList, self.CategoryMap = BlockManager.GetCategoryListAndMap(self:GetLanguage());
    self:OnToolBoxXmlTextChange(self:GetAttrStringValue("ToolBoxXmlText"));
    self:GetToolBox():SetCategoryList(self.CategoryList);

    self.isHideToolBox = self:GetAttrBoolValue("isHideToolBox", false);
    self.isHideIcons = self:GetAttrBoolValue("isHideIcons", false);
    self:SetReadOnly(self:GetAttrBoolValue("readonly", false));

    return self;
end

function Blockly:OnToolBoxXmlTextChange(toolboxXmlText)
    local xmlNode = ParaXML.LuaXML_ParseString(toolboxXmlText);
    local toolboxNode = xmlNode and commonlib.XPath.selectNode(xmlNode, "//toolbox");
    if (toolboxNode) then
        local categorylist, categorymap = {}, {};
        for _, categoryNode in ipairs(toolboxNode) do
            if (categoryNode.attr and categoryNode.attr.name) then
                local category_attr = categoryNode.attr;
                local default_category = self.CategoryMap[category_attr.name] or {};
                local category = categorymap[category_attr.name] or {};
                category.name = category.name or category_attr.name or default_category.name;
                category.text = category.text or category_attr.text or default_category.text;
                category.color = category.color or category_attr.color or default_category.color;
                -- local hideInToolbox = if_else(category_attr.hideInToolbox ~= nil, category_attr.hideInToolbox == "true", default_category.hideInToolbox and true or false);
                -- category.hideInToolbox = if_else(category.hideInToolbox ~= nil, category.hideInToolbox, hideInToolbox);
                category.hideInToolbox = category_attr.hideInToolbox == "true";
                for _, blockTypeNode in ipairs(categoryNode) do
                    if (blockTypeNode.attr and blockTypeNode.attr.type) then
                        local blocktype = blockTypeNode.attr.type;
                        local disabled = blockTypeNode.attr.disabled == "true";
                        local hideInToolbox = blockTypeNode.attr.hideInToolbox == "true";
                        table.insert(category, {blocktype = blocktype, hideInToolbox = hideInToolbox, disabled = disabled});
                    end
                end
                if (not categorymap[category.name]) then
                    table.insert(categorylist, #categorylist + 1, category);
                    categorymap[category.name] = category;
                end    
            end
        end
        self.CategoryList = categorylist;
    end
    for _, category in ipairs(self.CategoryList) do
        for _, block in ipairs(category) do
            local option = self.BlockMap[block.blocktype];
            if (option) then  
                option.category = category.name; 
                option.color = category.color;
            end
        end
        self.CategoryColor[category.name] = category.color;
        self.CategoryColor[category.text or category.name] = category.color;
    end
    self:GetToolBox():SetCategoryList(self.CategoryList);
end

function Blockly:IsOnlyGenerateStartBlockCode()
    return self:GetAttrBoolValue("OnlyGenerateStartBlockCode", false);
end

function Blockly:OnAttrValueChange(attrName, attrValue, oldAttrValue)
    if (attrName == "ToolBoxXmlText") then
        self:OnToolBoxXmlTextChange(self:GetAttrStringValue("ToolBoxXmlText"));
    elseif (attrName == "language") then
        self:SetLanguage(self:GetAttrStringValue("language"));
        self:LoadBlockMap();
        self.CategoryList, self.CategoryMap = BlockManager.GetCategoryListAndMap(self:GetLanguage());
        self:OnToolBoxXmlTextChange(self:GetAttrStringValue("ToolBoxXmlText"));
    end
end

function Blockly:LoadBlockMap()
    local BlockMap = BlockManager.GetBlockMap(self:GetLanguage());
    self.BlockMap = {};

    local optionGlobal = self:GetOptionGlobal();
    for blockType, blockOption in pairs(BlockMap) do
        local option = commonlib.deepcopy(blockOption);
        if (not option.isScratchBlock) then
            commonlib.mincopy(option, optionGlobal:GetDefaultOption(blockType));
            commonlib.partialcopy(option, optionGlobal:GetOverWriteOption(blockType));
        end
        
        self.BlockMap[blockType] = option;
        optionGlobal:DefineGlobalOption(blockType, option);

        if (option.code and option.code ~= "") then
            local func, errmsg = loadstring(option.code);
            if (func) then
                setfenv(func, optionGlobal:GetG());
                func();
            else
                print(errmsg);
            end
        end

        -- 调用初始化回调
        if (type(option.OnInit) == "function") then option.OnInit(option) end 
    end 
end

-- 添加一个注释
function Blockly:AddNote(block)
    block = block or self:GetCurrentBlock();
    local x, y = self:GetLogicAbsPoint(nil, self.__context_menu_x__ or 0, self.__context_menu_y__ or 0);  -- 相对坐标为窗口的缩放后坐标
    if (block) then
        local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
        local widthUnitCount, heightUnitCount = block:GetWidthHeightUnitCount();
        x, y = (leftUnitCount + widthUnitCount + 10) * Const.UnitSize, topUnitCount * Const.UnitSize;
    end

    local note = Note:new():Init({
        name = "Note",
        attr = {ID = #self.notes + 1},
    }, self:GetWindow(), self);

    table.insert(self.childrens, note);
    note:SetBlockly(self);
    note:SetBlock(block);
    note:UpdateLayout(true);
    note:SetStyleValue("left", x);
    note:SetStyleValue("top", y);
    note:SetPosition(x,  y);
    note:UpdateWindowPos();
    table.insert(self.notes, note);
    return note;
end

-- 移除注释
function Blockly:RemoveNote(note)
    for index, item in ipairs(self.notes) do
        if (item == note) then
            table.remove(self.notes, index);
            break;
        end
    end
    for index, item in ipairs(self.childrens) do
        if (item == note) then
            table.remove(self.childrens, index);
            break;
        end
    end
end

function Blockly:RemoveBlockNotes(block)
    local notes = {};
    for _, note in ipairs(self.notes) do
        if (note:GetBlock() == block) then
            for index, item in ipairs(self.childrens) do
                if (item == note) then
                    table.remove(self.childrens, index);
                    break;
                end
            end
        else
            table.insert(notes, note);
        end
        
    end
    self.notes = notes;
end

function Blockly:ClearNotes()
    for _, note in ipairs(self.notes) do
        for index, item in ipairs(self.childrens) do
            if (item == note) then
                table.remove(self.childrens, index);
                break;
            end
        end
    end
    self.notes = {};
end

function Blockly:GetNotes()
    return self.notes;
end

function Blockly:GetUnitSize()
    return Const.UnitSize;
end

-- 操作
function Blockly:Do(cmd)
    local block = cmd.block;
    cmd.startLeftUnitCount = block.startLeftUnitCount;
    cmd.startTopUnitCount = block.startTopUnitCount;
    cmd.endLeftUnitCount = block.leftUnitCount;
    cmd.endTopUnitCount = block.topUnitCount;
    table.insert(self.undos, cmd);
    self:OnChange();
end

-- 撤销命令
function Blockly:Undo()
    local cmd = self.undos[#self.undos];
    if (not cmd) then return end
    table.remove(self.undos, #self.undos);
    local action, block, blockCount = cmd.action, cmd.block, cmd.blockCount;
    local tmpBlock = block;
    local blocks = {};
    local index = 1;
    for index = 1, blockCount do
        if (tmpBlock) then
            blocks[index] = tmpBlock;
            blocks[index]:Disconnection();
            tmpBlock = tmpBlock:GetNextBlock();
            if (index > 1 and blocks[index-1].nextConnection) then
                blocks[index-1].nextConnection:Connection(blocks[index].previousConnection);
            end
            index = index + 1;
        end
    end
    if (action == "DeleteBlock" or action == "MoveBlock") then
        self:AddBlock(block);
        block:SetLeftTopUnitCount(cmd.startLeftUnitCount, cmd.startTopUnitCount);
        block:UpdateLeftTopUnitCount();
        block:TryConnectionBlock();
    elseif (action == "NewBlock") then
        self:RemoveBlock(block);
    end
    table.insert(self.redos, cmd);
    self:OnChange();
end

-- 恢复
function Blockly:Redo()
    local cmd = self.redos[#self.redos];
    if (not cmd) then return end
    table.remove(self.redos, #self.redos);
    local action, block = cmd.action, cmd.block;
    local connection = block and block:GetConnection();

    if (connection) then
        connection:Disconnection();
        connection:GetBlock():GetTopBlock():UpdateLayout();
    end

    if (action == "NewBlock" or action == "MoveBlock") then
        self:AddBlock(block);
        block:SetLeftTopUnitCount(cmd.endLeftUnitCount, cmd.endTopUnitCount);
        block:UpdateLeftTopUnitCount();
        block:TryConnectionBlock();
    elseif (action == "DeleteBlock") then
        self:RemoveBlock(block);
    end

    table.insert(self.undos, cmd);
    self:OnChange();
end

-- 设置工具块
function Blockly:SetToolBoxBlockList()
end

-- 定义块
function Blockly:DefineBlock(block)
    self.BlockMap[block.type] = block;
end

-- 获取块
function Blockly:GetBlockInstanceByType(typ, isToolBoxBlock)
    local opts = self.BlockMap[typ] or BlockManager.GetBlockOption(typ, self:GetLanguage());
    if (not opts) then return nil end
    return Block:new():Init(self, opts, isToolBoxBlock);
end

-- 获取块
function Blockly:GetBlockInstanceByXmlNode(xmlNode)
    local block = self:GetBlockInstanceByType(xmlNode.attr.type);
    if (not block) then return nil end
    block:LoadFromXmlNode(xmlNode);
    return block;
end

-- 获取所有顶层块
function Blockly:GetBlocks()
    return self.blocks;
end

-- 清空所有块
function Blockly:ClearBlocks()
    self.blocks = {};
    self:SetCurrentBlock(nil);
end

-- 遍历
function Blockly:ForEachUI(callback)
    for _, block in ipairs(self.blocks) do
        if (type(callback) == "function") then callback(block) end
        block:ForEach(callback);
    end
end

-- 获取块索引
function Blockly:GetBlockIndex(block)
    for index, _block in ipairs(self.blocks) do
        if (_block == block) then return index end
    end
    return ;
end

-- 移除块
function Blockly:AddBlock(block, isHeadBlock)
    block:SetTopBlock(true);
    local index = self:GetBlockIndex(block);
    if (not index) then 
        if (isHeadBlock) then
            return table.insert(self.blocks, 1, block);
        else
            return table.insert(self.blocks, block); 
        end
    end
    
    local head, tail = 1, #self.blocks;
    if (isHeadBlock) then
        self.blocks[head], self.blocks[index] = self.blocks[index], self.blocks[head];  -- 放置头部
    else
        self.blocks[tail], self.blocks[index] = self.blocks[index], self.blocks[tail];  -- 放置尾部
    end
end

-- 添加块
function Blockly:RemoveBlock(block)
    block:SetTopBlock(false);
    local index = self:GetBlockIndex(block);
    if (not index) then return end
    table.remove(self.blocks, index);
end

-- 创建block
function Blockly:OnCreateBlock(block)
end

function Blockly:OnDestroyBlock(block)
    self:RemoveBlockNotes(block);
end

-- 是否在工作区内
function Blockly:IsInnerViewPort(block)
    local x, y, w, h = self:GetContentGeometry();
    local hw, hh = w / 2, h / 2;
    local cx, cy = Const.ToolBoxWidth + self.offsetX + hw, self.offsetY + hh;
    local b_x, b_y, b_hw, b_hh = block.left, block.top, block.width / 2, block.height / 2;
    local b_cx, b_cy = b_x + b_hw, b_y + b_hh;
    return math.abs(b_cx - cx) <= (hw + b_hw) and math.abs(b_cy - cy) <= (hh + b_hh);
end

local IconViewWidth, IconViewHeight = 82, 220;
function Blockly:GetMousePosIndex(mouseMoveX, mouseMoveY)
    local x, y, w, h = self:GetGeometry();
    local mx, my = (mouseMoveX or self.mouseMoveX) - w + IconViewWidth, (mouseMoveY or self.mouseMoveY) - h + IconViewHeight;
    if (10 <= mx and mx <=42 and -42 <= my and my <= -10) then return -1 end 
    if (10 <= mx and mx <= 42 and 0 <= my and my <= 32) then return 1 end
    if (10 <= mx and mx <= 42 and 42 <= my and my <= 74) then return 2 end
    if (10 <= mx and mx <= 42 and 84 <= my and my <= 116) then return 3 end
    if (0 <= mx and mx <= 42 and 148 <= my and my <= 193) then return 4 end
    return 0;
end

function Blockly:RenderIcons(painter)
    if (self.isHideIcons) then return end
    local x, y, w, h = self:GetGeometry();
    local offsetX, offsetY = x + w - IconViewWidth, y + h - IconViewHeight;
    local mousePosIndex = self:GetMousePosIndex();
    
    painter:Translate(offsetX, offsetY);
    if (mousePosIndex == -1) then painter:SetPen("#ffffffff")
    else painter:SetPen("#ffffff80") end
    painter:DrawRectTexture(10, -42, 32, 32, "Texture/Aries/Creator/keepwork/ggs/blockly/suoluetu_32x26_32bits.png;0 0 32 32");

    if (mousePosIndex == 1) then painter:SetPen("#ffffffff")
    else painter:SetPen("#ffffff80") end
    painter:DrawRectTexture(10, 0, 32, 32, "Texture/Aries/Creator/keepwork/ggs/blockly_icons_128x128_32bit.png;0 64 32 32");
    
    if (mousePosIndex == 2) then painter:SetPen("#ffffffff")
    else painter:SetPen("#ffffff80") end
    painter:DrawRectTexture(10, 42, 32, 32, "Texture/Aries/Creator/keepwork/ggs/blockly_icons_128x128_32bit.png;32 64 32 32");

    if (mousePosIndex == 3) then painter:SetPen("#ffffffff")
    else painter:SetPen("#ffffff80") end
    painter:DrawRectTexture(10, 84, 32, 32, "Texture/Aries/Creator/keepwork/ggs/blockly_icons_128x128_32bit.png;64 64 32 32");

    if (mousePosIndex == 4) then 
        painter:SetPen("#ffffffff")
        painter:Translate(42, 157);
        painter:Rotate(45);
        painter:DrawRectTexture(-42, -9, 42, 9, "Texture/Aries/Creator/keepwork/ggs/blockly_icons_128x128_32bit.png;0 0 42 9");
        painter:Rotate(-45);
        painter:Translate(-42, -157);
    else 
        painter:SetPen("#ffffff80");
        painter:DrawRectTexture(0, 148, 42, 9, "Texture/Aries/Creator/keepwork/ggs/blockly_icons_128x128_32bit.png;0 0 42 9");
    end
    painter:DrawRectTexture(0, 157, 42, 45, "Texture/Aries/Creator/keepwork/ggs/blockly_icons_128x128_32bit.png;0 9 42 45");
    painter:Translate(-offsetX, -offsetY);
end

function Blockly:RenderBG(painter)
    local x, y, w, h = self:GetContentGeometry();
    painter:SetBrush("f9f9f9");
    painter:DrawRect(x, y, w, h);
end

-- 渲染Blockly
function Blockly:RenderContent(painter)
    local UnitSize, scale = self:GetUnitSize(), self:GetScale();
    local x, y, w, h = self:GetContentGeometry();
    self:RenderBG(painter);
    self:RenderIcons(painter);
    -- 设置绘图类
    -- Shape:SetPainter(painter);
    local DraggingBlock = nil;
    local toolboxWidth = Const.ToolBoxWidth;
    painter:Translate(x, y);
    if (not self.isHideToolBox) then 
        self:GetToolBox():Render(painter);
        painter:Flush();
    end 

    Shape:SetUnitSize(UnitSize);
    painter:Save();
    if (self.isHideToolBox) then
        painter:SetClipRegion(0, 0, w, h);
    else
        painter:SetClipRegion(toolboxWidth, 0, w - toolboxWidth, h);
    end
    painter:Scale(scale, scale);
    painter:Translate(self.offsetX, self.offsetY);
    for _, block in ipairs(self.blocks) do
        if (block:IsDragging()) then
            if (self:GetMouseCaptureUI() ~= block) then 
                block:SetDragging(false);
                self:GetShadowBlock():Shadow(nil);
            else
                DraggingBlock = block;
            end
        else 
            block:Render(painter);
            painter:Flush();
        end
    end
    painter:Translate(-self.offsetX, -self.offsetY);
    painter:Scale(1 / scale, 1 / scale);
    painter:Restore();

    if (DraggingBlock) then
        painter:Save();
        painter:SetClipRegion(0, 0, w, h);
        painter:Scale(scale, scale);
        painter:Translate(self.offsetX, self.offsetY);
        DraggingBlock:Render(painter);
        painter:Flush();
        painter:Translate(-self.offsetX, -self.offsetY);
        painter:Scale(1 / scale, 1 / scale);
        painter:Restore();

        if ((self.mouseMoveX <= toolboxWidth and not self.isHideToolBox) or self:GetMousePosIndex() == 4) then
            local width, height = 12, 12;
            painter:SetPen("#ff0000");
            -- painter:DrawRectTexture(self.mouseMoveX - width / 2, self.mouseMoveY - height / 2, width, height, Shape:GetCloseTexture());
            painter:Scale(scale, scale);
            painter:DrawRectTexture(DraggingBlock.left + self.offsetX - width / 2, DraggingBlock.top + self.offsetY - height / 2, width, height, Shape:GetCloseTexture());
            painter:Scale(1 / scale, 1 / scale);
        end
    end

    self.__horizontal_scroll_bar__:Render(painter);
    self.__vertical_scroll_bar__:Render(painter);
    painter:Translate(-x, -y);

    if (self:IsShowMiniMap()) then self:RenderMiniMap(painter) end 
end

function Blockly:RenderMiniMap(painter) 
    local x, y, w, h = self:GetContentGeometry();
    local MiniMapWidth, MiniMapHeight = Const.MiniMapWidth, Const.MiniMapHeight;
    local scale = 0.5;
    local UnitSize = self:GetUnitSize();
    painter:Translate(x + w - MiniMapWidth, y);
    painter:Save();
    painter:SetClipRegion(0, 0, MiniMapWidth, MiniMapHeight);
    -- 背景
    painter:SetPen("#ffffff");
    painter:DrawRectTexture(0, 0, MiniMapWidth, MiniMapHeight,  "Texture/Aries/Creator/keepwork/ggs/blockly/waikuang_32x32_32bits.png;0 0 32 32:12 12 12 12");
    
    if (#self.blocks ~= 0) then 
        local margin = Const.MiniMapMargin;
        local left, top, width , height = self.__content_left_unit_count__, self.__content_top_unit_count__, self.__content_right_unit_count__ - self.__content_left_unit_count__, self.__content_bottom_unit_count__ - self.__content_top_unit_count__;
        left, top, width, height = left * UnitSize, top * UnitSize, math.max(width * UnitSize + 2 * margin, w), math.max(height * UnitSize + 2 * margin, h);
        local scale = math.min(MiniMapWidth / width, MiniMapHeight / height);
        -- print(left, top, width, height, scale)
        self.__minimap_scale__ = scale;
        self.__minimap_left__, self.__minimap_top__, self.__minimap_width__, self.__minimap_height__ = left, top, width, height;
        painter:Scale(scale, scale);
        painter:Translate(-(left - margin), -(top - margin));
        for _, block in ipairs(self.blocks) do
            block:Render(painter);
        end
        painter:Translate((left - margin), (top - margin));
        painter:Scale(1 / scale, 1 / scale);
    end
    painter:Restore();
    painter:Translate(-(x + w - MiniMapWidth), -y);
end

-- 布局Blockly
function Blockly:UpdateWindowPos(forceUpdate)
    Blockly._super.UpdateWindowPos(self, forceUpdate);
    for _, block in ipairs(self.blocks) do
        block:UpdateLayout();
    end
    self:GetToolBox():UpdateLayout();
    self:AdjustContentSize();
end

-- 捕获鼠标
function Blockly:CaptureMouse(ui)
    self:SetMouseCaptureUI(ui);
    if (self:GetWindow():GetMouseCaptureElement() ~= self) then
        Blockly._super.CaptureMouse(self);
    end
end

-- 释放鼠标
function Blockly:ReleaseMouseCapture()
    self:SetMouseCaptureUI(nil);
	return Blockly._super.ReleaseMouseCapture(self);
end

function Blockly:GetLogicViewPoint(event, screen_x, screen_y)
    local x, y = screen_x or (event and event.x), screen_y or (event and event.y);
    if (not x or not y) then x, y = ParaUI.GetMousePosition() end 
    x, y = Blockly._super.GetRelPoint(self, x, y);                    -- 相对坐标为窗口的缩放后坐标
    local scale = self:GetScale();                                    -- 获取缩放值
    return math.floor(x / scale + 0.5), math.floor(y / scale + 0.5);  -- 转化为逻辑坐标
end

function Blockly:GetLogicAbsPoint(event, screen_x, screen_y)
    local x, y = self:GetLogicViewPoint(event, screen_x, screen_y);
    return x - self.offsetX, y - self.offsetY;
end

local ClassNameZIndexs = {["BlockInputField"] = 1, ["Block"] = 2, ["Input"] = 3, ["Field"] = 4, ["FieldInput"] = 5};
function Blockly:GetMouseDownUI(event)
    -- if (self:IsTouchMode()) then
    --     if (event:GetType() == "mousePressEvent") then 
    --         local fingerSize, fingerStepSize = 0, 10;
    --         local stepCount = fingerSize / fingerStepSize / 2;
    --         local lastRadius, lastZIndex, lastMouseX, lastMouseY, lastUI = 1000000, 0, 0, 0, self;
    --         local mouseX, mouseY = event.x, event.y;
    --         for i = -stepCount, stepCount do
    --             for j = -stepCount, stepCount do 
    --                 local newMouseX, newMouseY = mouseX + i * fingerStepSize,  mouseY + j * fingerStepSize;
    --                 event.x, event.y = newMouseX, newMouseY;
    --                 local x, y = self:GetLogicAbsPoint(event);
    --                 local ui = self:GetMouseUI(x, y, event) or self;
    --                 local zindex = ClassNameZIndexs[ui:GetClassName()] or 0;
    --                 local radius = i * i + j * j;
    --                 if (lastZIndex < zindex or (lastZIndex == zindex and radius < lastRadius)) then
    --                     lastMouseX, lastMouseY = newMouseX, newMouseY;
    --                     lastUI, lastRadius, lastZIndex = ui, radius, zindex;
    --                 end
    --             end
    --         end
    --         event.x, event.y = lastMouseX, lastMouseY;
    --         self.last_ui_mouse_down_x, self.last_ui_mouse_down_y, self.last_ui = lastMouseX, lastMouseY, lastUI;
    --         return self.last_ui;
    --     end
    --     if (event:GetType() == "mouseReleaseEvent" and event:GetLastType() == "mousePressEvent") then
    --         event.x, event.y = self.last_ui_mouse_down_x, self.last_ui_mouse_down_y;
    --         return self.last_ui;
    --     end
    -- end
    local x, y = self:GetLogicAbsPoint(event);
    local ui = self:GetMouseUI(x, y, event);
    return ui;
end

-- 鼠标按下事件
function Blockly:OnMouseDown(event)
    event:Accept();
    self.mouseMoveX, self.mouseMoveY = Blockly._super.GetRelPoint(self, event.x, event.y);
    self:GetContextMenu():Hide();
    local ui = self:GetMouseDownUI(event);
    
    -- 失去焦点
    local focusUI = self:GetFocusUI();
    if (focusUI ~= ui and focusUI) then 
        focusUI:OnFocusOut();
        self:SetFocusUI(nil);
    end

    if (not event:IsLeftButton()) then return end

    self.mouse_down_ui = ui;
    -- 元素被点击 直接返回元素事件处理
    if (ui ~= self) then 
        return ui:OnMouseDown(event);
    end

    -- 点击小地图
    if (self:IsInnerMiniMap(event)) then
        if (0 == #self.blocks) then return end 
        local w, h = self:GetSize();
        local offsetX, offsetY = self.mouseMoveX - (w - Const.MiniMapWidth), self.mouseMoveY;
        local centerX, centerY = self.__minimap_left__ + offsetX / self.__minimap_scale__, self.__minimap_top__ + offsetY / self.__minimap_scale__;
        local centerXUnitSize, centerYUnitSize = math.floor(centerX / Const.UnitSize), math.floor(centerY / Const.UnitSize);
        self.__offset_x_unit_count__, self.__offset_y_unit_count__ = math.floor(self.__width_unit_count__ / 2) - centerXUnitSize, math.floor(self.__height_unit_count__ / 2) - centerYUnitSize;
        self.offsetX = self.__offset_x_unit_count__ * Const.UnitSize;
        self.offsetY = self.__offset_y_unit_count__ * Const.UnitSize;
        self:OnOffsetChange();
        return ;
    end
    
    local mousePosIndex = self:GetMousePosIndex();
    if (mousePosIndex == -1) then
        self:SetShowMiniMap(not self:IsShowMiniMap());
    elseif (mousePosIndex == 1) then         -- 重置
        self:UpdateScale();
        local targetBlock, left, top = nil, nil, nil;
        for _, block in ipairs(self.blocks) do
            if (not left or block.left < left or (block.left == left and block.top < top)) then targetBlock, left, top = block, block.left, block.top end
        end
        self:AdjustCenter(targetBlock);
    elseif (mousePosIndex == 2) then     -- 放大
       self:UpdateScale(0.1);
    elseif (mousePosIndex == 3) then     -- 缩小
       self:UpdateScale(-0.1);
    elseif (mousePosIndex == 4) then
    else
        -- 工作区被点击
        self.isMouseDown = true;
        self.startX, self.startY = self:GetLogicViewPoint(event);
        self.startOffsetX, self.startOffsetY = self.offsetX, self.offsetY;
    end
end

-- 调整中心
function Blockly:AdjustCenter(targetBlock)
    local left, top = nil, nil;
    local offsetX, offsetY = self.offsetX, self.offsetY;
    if (not self.isHideToolBox) then offsetX = offsetX - Const.ToolBoxWidth end 
    if (targetBlock) then
        -- 以目标块为基准块
        left, top = targetBlock.left, targetBlock.top;
    else 
        -- 以视图中最左一个方块为基准
        for _, block in ipairs(self.blocks) do
            local viewLeft, viewTop = block.left + offsetX, block.top + offsetY;
            if (not left or (left + offsetX) < 0 or (viewLeft > 0  and viewTop > 0 and (block.left < left or (block.left == left and block.top < top))))  then
                left, top = block.left, block.top;
            end
        end
    end
    
    if (not left) then return end
    local width, height = self:GetSize();
    if (not self.isHideToolBox) then width = width - Const.ToolBoxWidth end
    local viewLeft, viewTop = math.floor(width / 3),  math.floor(height / 4);
    if (self.isHideToolBox) then 
        self.offsetX, self.offsetY = viewLeft - left, viewTop - top;
    else
        self.offsetX, self.offsetY = viewLeft - left + Const.ToolBoxWidth, viewTop - top;
    end
    self:OnOffsetChange();
end

-- 重新布局
function Blockly:UpdateScale(offset)
    local oldScale = self:GetScale();
    local newScale = offset and (oldScale + offset) or 1;
    newScale = math.min(newScale, 4);
    newScale = math.max(newScale, 0.5);
    
    if (oldScale == newScale) then return end
    self:SetScale(newScale);
    self:AdjustCenter();
    -- for _, block in ipairs(self.blocks) do
    --     local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
    --     leftUnitCount = math.floor(leftUnitCount * oldScale / newScale);
    --     topUnitCount = math.floor(topUnitCount * oldScale / newScale);
    --     block:SetLeftTopUnitCount(leftUnitCount, topUnitCount);
    --     block:UpdateLayout();
    -- end
end

-- 获取当前鼠标顶点值
function Blockly:GetMouseLeftTopUnitCount()
    local x, y = self:GetLogicAbsPoint();
    local UnitSize = self:GetUnitSize();
    return math.floor(x / UnitSize), math.floor(y/ UnitSize);
end

-- 鼠标移动事件
function Blockly:OnMouseMove(event)
    event:Accept();
    self.mouseMoveX, self.mouseMoveY = Blockly._super.GetRelPoint(self, event.x, event.y);
    if (not event:IsLeftButton() and self:GetMouseCaptureUI() == nil) then return end

    local UnitSize = self:GetUnitSize();
    local x, y = self:GetLogicAbsPoint(event);
    local logicViewX, logicViewY = self:GetLogicViewPoint(event);
    local ui = self:GetMouseUI(x, y, event);
    if (ui and ui ~= self) then return ui:OnMouseMove(event) end
    
    if (not self.isMouseDown or not event:IsLeftButton()) then return end
    local offsetX = math.floor((logicViewX - self.startX) / UnitSize) * UnitSize;
    local offsetY = math.floor((logicViewY - self.startY) / UnitSize) * UnitSize;
    if (not self.isDragging) then
        if (offsetX == 0 and offsetY == 0) then return end
        self.isDragging = true;
        self:CaptureMouse(self);
    end
    self.__offset_x_unit_count__ = math.floor((self.startOffsetX + offsetX) / UnitSize);
    self.__offset_y_unit_count__ = math.floor((self.startOffsetY + offsetY) / UnitSize);
    self.__offset_x_unit_count__ = math.min(math.max(self.__offset_x_unit_count__, self.__min_offset_x_count__), self.__max_offset_x_count__);
    self.__offset_y_unit_count__ = math.min(math.max(self.__offset_y_unit_count__, self.__min_offset_y_count__), self.__max_offset_y_count__);
    self.offsetX = self.__offset_x_unit_count__ * UnitSize;
    self.offsetY = self.__offset_y_unit_count__ * UnitSize;
    -- print("-------0", self.__offset_x_unit_count__, self.__offset_y_unit_count__, self.__width_unit_count__, self.__height_unit_count__);
    -- print("-------1", self.__min_offset_x_count__, self.__max_offset_x_count__, self.__min_offset_y_count__, self.__max_offset_y_count__)
    -- print("-------2", self.__content_left_unit_count__, self.__content_right_unit_count__, self.__content_top_unit_count__, self.__content_bottom_unit_count__)
    self:OnOffsetChange();
end

-- 鼠标抬起事件
function Blockly:OnMouseUp(event)
    event:Accept();
    self.mouseMoveX, self.mouseMoveY = Blockly._super.GetRelPoint(self, event.x, event.y);
    self.isDragging = false;
    self.isMouseDown = false;
    -- 优先处理捕获的UI 防止其 OnMouseUp 事件未触发
    local captureUI = self:GetMouseCaptureUI();
    self:ReleaseMouseCapture();
    if (captureUI and captureUI ~= self) then return captureUI:OnMouseUp(event) end

    local x, y = self:GetLogicAbsPoint(event);
    local ui = self:GetMouseUI(x, y, event) or self;

    if (event:IsLeftButton()) then
        local focusUI = self:GetFocusUI();  -- 获取焦点
        if (focusUI ~= ui and focusUI) then focusUI:OnFocusOut() end
        if (ui ~= self) then ui:OnMouseUp(event) end
        if (self.mouse_down_ui == ui) then
            if (type(ui.OnClick) == "function") then
                ui:OnClick();
            end 
            if (focusUI ~= ui) then
                if (type(ui.OnFocusIn) == "function") then
                    ui:OnFocusIn();
                end 
                self:SetFocusUI(ui);
            end
        end
    end
    
    if (event:IsRightButton() and not self:IsInnerToolBox(event) and not self:IsReadOnly()) then
        local contextmenu = self:GetContextMenu();
        local absX, absY = Blockly._super.GetRelPoint(self, event.x, event.y);  -- 相对坐标为窗口的缩放后坐标
        -- local absX, absY = self:GetLogicViewPoint(event);
        local menuType = "block";
        contextmenu:SetStyleValue("left", absX);
        contextmenu:SetStyleValue("top", absY);
        if (ui == self or (type(ui) == "table" and type(ui.GetClassName) == "function" and ui:GetClassName() == "Blockly")) then 
            menuType = "blockly";
            self:SetCurrentBlock(nil);
        elseif (type(ui) == "table" and type(ui.GetBlock) == "function") then
            block = ui:GetBlock();
            self:SetCurrentBlock(block:GetProxyBlock() or block);
        else
            return;
        end
        self:GetContextMenu():Show(menuType);
        self.__context_menu_x__, self.__context_menu_y__ = event:GetScreenXY();
    end
end

function Blockly:AdjustContentSize()
    local width, height = self:GetSize();
    local UnitSize = self:GetUnitSize();
    self.__toolbox_unit_count__ = self.isHideToolBox and 0 or math.floor(Const.ToolBoxWidth / UnitSize);
    self.__width_unit_count__, self.__height_unit_count__ = math.ceil(width / UnitSize), math.ceil(height / UnitSize);
    self.__offset_x_unit_count__, self.__offset_y_unit_count__ = math.floor(self.offsetX / UnitSize), math.floor(self.offsetY / UnitSize);
    local left, top, right, bottom = nil, nil, nil, nil;
    local content_offset, max_block_width_unit_count, max_block_height_unit_count = -1000, 0, 0;
    for _, block in ipairs(self.blocks) do 
        local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
        local widthUnitCount, heightUnitCount = block:GetWidthHeightUnitCount();
        local rightUnitCount, bottomUnitCount = leftUnitCount + widthUnitCount, topUnitCount + heightUnitCount;
        left = left and math.min(left, leftUnitCount) or leftUnitCount;
        top = top and math.min(top, topUnitCount) or topUnitCount;
        right = right and math.max(right, rightUnitCount) or rightUnitCount;
        bottom = bottom and math.max(bottom, bottomUnitCount) or bottomUnitCount;
        max_block_width_unit_count = math.max(max_block_width_unit_count, widthUnitCount);
        max_block_height_unit_count = math.max(max_block_height_unit_count, heightUnitCount);
    end
    max_block_width_unit_count, max_block_height_unit_count = 0, 0; -- 兼容宏示教,  比较好的效果应屏蔽  content_offset = 20
    self.__content_left_unit_count__, self.__content_top_unit_count__, self.__content_right_unit_count__, self.__content_bottom_unit_count__ = left or 0, top or 0, right or 0, bottom or 0;
    self.__min_offset_x_count__ = self.__toolbox_unit_count__ + content_offset + max_block_width_unit_count - self.__content_right_unit_count__;
    self.__max_offset_x_count__ = self.__width_unit_count__ - content_offset - max_block_width_unit_count - self.__content_left_unit_count__;
    self.__min_offset_y_count__ = content_offset + max_block_height_unit_count - self.__content_bottom_unit_count__;
    self.__max_offset_y_count__ = self.__height_unit_count__ - content_offset - max_block_height_unit_count - self.__content_top_unit_count__;
end

function Blockly:OnOffsetChange()
    for _, note in ipairs(self.notes) do
        note:UpdateWindowPos();
    end
end

function Blockly:GetOffset()
    return self.offsetX, self.offsetY;
end

-- 获取鼠标元素
function Blockly:GetMouseUI(x, y, event)
    if (self:IsReadOnly()) then return self end 

    local ui = self:GetMouseCaptureUI();
    if (ui) then return ui end

    if (self:IsInnerMiniMap(event)) then return self end 

    if (self:IsInnerToolBox(event)) then
        ui = self:GetToolBox():GetMouseUI(x + self.offsetX, y + self.offsetY, event);
        return ui or self:GetToolBox();
    end

    if (self.__horizontal_scroll_bar__:GetMouseUI(x, y, event)) then return self.__horizontal_scroll_bar__ end 
    if (self.__vertical_scroll_bar__:GetMouseUI(x, y, event)) then return self.__vertical_scroll_bar__ end
    
    ui = self:GetXYUI(x, y);
    return ui or self;
end

-- 获取XY UI
function Blockly:GetXYUI(x, y)
    local size = #self.blocks;
    for i = size, 1, -1 do
        local block = self.blocks[i];
        ui = block:GetMouseUI(x, y, nil);
        if (ui) then return ui end
    end
end

function Blockly:IsInnerMiniMap(event)
    if (not self:IsShowMiniMap()) then return false end
    local _, _, w, h = self:GetContentGeometry();
    local x, y = Blockly._super.GetRelPoint(self, event.x, event.y);         -- 防止减去偏移量
    local MiniMapWidth, MiniMapHeight = Const.MiniMapWidth, Const.MiniMapHeight;
    return (w - MiniMapWidth) < x and x < w and 0 < y and y < MiniMapHeight; 
end

function Blockly:IsInnerToolBox(event)
    if (self.isHideToolBox) then return false end
    local x, y = Blockly._super.GetRelPoint(self, event.x, event.y);         -- 防止减去偏移量
    if (self:GetToolBox():IsContainPoint(x, y)) then return true end
    return false;
end

-- 是否在删除区域
function Blockly:IsInnerDeleteArea(x, y)
    if (self:GetMousePosIndex() == 4) then return true end
    if (self.isHideIcons) then return false end;
    local x, y = Blockly._super.GetRelPoint(self, x, y);                      -- 防止减去偏移量
    if (self:GetToolBox():IsContainPoint(x, y)) then return true end
    return false;
end

-- 鼠标滚动事件
function Blockly:OnMouseWheel(event)
    if (self:IsInnerToolBox(event)) then return self:GetToolBox():OnMouseWheel(event) end
    if (self:IsEditing()) then return end 
    local delta = event:GetDelta();             -- 1 向上滚动  -1 向下滚动
    local UnitSize = self:GetUnitSize();
    self.__offset_y_unit_count__ = math.floor((self.offsetY + delta * 20) / UnitSize);
    self.__offset_y_unit_count__ = math.min(math.max(self.__offset_y_unit_count__, self.__min_offset_y_count__), self.__max_offset_y_count__);
    self.offsetY = self.__offset_y_unit_count__ * UnitSize;
end

-- 键盘事件
function Blockly:OnKeyDown(event)
    if (not self:IsFocus()) then return end

	local keyname = event.keyname;
	if (keyname == "DIK_RETURN") then 
	elseif (event:IsKeySequence("Undo")) then self:Undo()
	elseif (event:IsKeySequence("Redo")) then self:Redo()
	-- elseif (event:IsKeySequence("Copy")) then self:handleCopy(event)
	elseif (event:IsKeySequence("Paste")) then self:handlePaste()
    elseif (event:IsKeySequence("Delete")) then self:handleDelete()
    else -- 处理普通输入
	end
end

-- 删除当前块
function Blockly:handleDelete()
    local block = self:GetCurrentBlock();
    if (not block) then return end
    block:Disconnection();
    self:RemoveBlock(block);
    self:OnDestroyBlock(block);
    self:SetCurrentBlock(nil);
    self:OnChange();
end

function Blockly:CopyBlock(targetBlock, cloneBlock, isCloneAllBlock)
    if (not targetBlock) then return end 
    cloneBlock = targetBlock:Clone(cloneBlock, isCloneAllBlock);

    -- 录制或播放模式走旧逻辑
    if (BlocklySimulator:IsRecordingOrPlaying()) then
        local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
        cloneBlock:SetLeftTopUnitCount(leftUnitCount + 4, topUnitCount + 4);
        cloneBlock:UpdateLeftTopUnitCount();

        self:AddBlock(cloneBlock);
        self:SetCurrentBlock(cloneBlock);
        self:OnChange();
    else
        local leftUnitCount, topUnitCount = self:GetMouseLeftTopUnitCount();
        cloneBlock:SetLeftTopUnitCount(leftUnitCount - 4, topUnitCount - 4);
        cloneBlock:UpdateLeftTopUnitCount();
        cloneBlock:OnMouseDown();
        cloneBlock:SetDragging(true);
        self:SetCurrentBlock(cloneBlock);
        self:CaptureMouse(cloneBlock);
        self:AddBlock(cloneBlock);
        self:GetShadowBlock():Shadow(cloneBlock);
    end
end

-- 复制当前块
function Blockly:handlePaste()
    self:CopyBlock(self:GetCurrentBlock(), nil, nil);
end

-- 复制整块
function Blockly:handleCopyAll()
    self:CopyBlock(self:GetCurrentBlock(), nil, true);
end

-- 删除整块
function Blockly:handleDeleteAll()
    local block = self:GetCurrentBlock();
    if (not block) then return end
    if (block.previousConnection) then
        block.previousConnection:Disconnection();
    end
    local nextBlock = block;
    while (nextBlock) do
        self:OnDestroyBlock(nextBlock);
        nextBlock = nextBlock:GetNextBlock();
    end
    self:RemoveBlock(block);
    self:SetCurrentBlock(nil);
    self:OnChange();
end

function Blockly:GetPrettyCode(code)
    local prettyCode = code;
    local language = self:GetLanguage();
    if (language == "SystemNplBlock") then
        local ok, errinfo = pcall(function()
            prettyCode = LuaFmt.Pretty(code);
            prettyCode = string.gsub(prettyCode, "\t", "    ");
        end);
        if (not ok) then 
            print("=============code error==========", errinfo);
            prettyCode = code;
        end
    end
    return prettyCode;
end

-- 获取代码
function Blockly:GetCode()
    -- print("=============GetCode==================")
    self.__block_id_map__ = {};
    self.__running_block_id_stack__ = {};
    local only_generate_start_block_code = self:IsOnlyGenerateStartBlockCode();
    local blocks, lastStartIndex = {}, 1;
    for _, block in ipairs(self.blocks) do
        if (block:GetType() == "System_Main") then 
            table.insert(blocks, 1, block);
            lastStartIndex = lastStartIndex + 1;
        elseif (not block.previousConnection and block.nextConnection) then
            table.insert(blocks, lastStartIndex, block);
            lastStartIndex = lastStartIndex + 1;
        elseif (not only_generate_start_block_code and block.previousConnection and block.nextConnection) then
            table.insert(blocks, block);
        else
            -- print("顶层输出块不产生代码");
        end
    end

    self:SetToCodeCache({});  -- 设置缓存对象

    local code = "";
    for _, block in ipairs(blocks) do
        local blockCode = "";
        local nextBlock = block;
        if (only_generate_start_block_code and nextBlock:IsStart()) then
            blockCode = nextBlock:GetCode();
        else
            while (nextBlock) do
                blockCode = blockCode .. nextBlock:GetCode();
                nextBlock = nextBlock:GetNextBlock();
            end
        end
        code = code .. blockCode .. "\n";
    end

    self:SetToCodeCache(nil); -- 清除缓存
    
    return code, self:GetPrettyCode(code);
end

-- 转换成xml
function Blockly:SaveToXmlNode()
    local xmlNode = {name = "Blockly", attr = {}};
    local attr = xmlNode.attr;

    attr.offsetX = self.offsetX;
    attr.offsetY = self.offsetY;

    for _, block in ipairs(self.blocks) do
        table.insert(xmlNode, block:SaveToXmlNode());
    end

    local toolboxXmlNode = self:GetToolBox():SaveToXmlNode();
    if (toolboxXmlNode) then table.insert(xmlNode, toolboxXmlNode) end

    -- 注释
    for _, note in ipairs(self.notes) do
        if (not note:GetBlock()) then
            table.insert(xmlNode, note:SaveToXmlNode());
        end
    end

    return xmlNode;
end

function Blockly:LoadFromXmlNode(xmlNode)
    if (not xmlNode or xmlNode.name ~= "Blockly") then return end

    local attr = xmlNode.attr;

    self.offsetX = tonumber(attr.offsetX) or 0;
    self.offsetY = tonumber(attr.offsetY) or 0;
    for _, subXmlNode in ipairs(xmlNode) do
        if (subXmlNode.name == "Block") then
            local block = self:GetBlockInstanceByXmlNode(subXmlNode);
            table.insert(self.blocks, block);
        elseif (subXmlNode.name == "ToolBox") then
            self:GetToolBox():LoadFromXmlNode(subXmlNode);
        elseif (subXmlNode.name == "Note") then
            self:AddNote():LoadFromXmlNode(subXmlNode);
        end
    end

    for _, block in ipairs(self.blocks) do
        block:UpdateLayout();
    end
end

function Blockly:LoadFromXmlNodeText(text)
    self:ClearBlocks();
    self:ClearNotes();
    local xmlNode = Helper.XmlString2Lua(text);
    if (not xmlNode) then return end
    local blocklyXmlNode = xmlNode and commonlib.XPath.selectNode(xmlNode, "//Blockly");
    self:LoadFromXmlNode(blocklyXmlNode);

    self:EmitUI("LoadXmlTextToWorkspace");
end

function Blockly:SaveToXmlNodeText()
    local text = Helper.Lua2XmlString(self:SaveToXmlNode(), true);
    return text;
end

-- 发生改变
function Blockly:OnChange(event)
    self:CallAttrFunction("onchange", nil, event);
end

-- 发送事件到UI
function Blockly:EmitUI(eventName, eventData)
    self:ForEachUI(function(blockInputField)
        blockInputField:OnUI(eventName, eventData);
    end);
end

function Blockly:GetStatementBlockCount()
    local total_count = 0;
    local function GetStatementBlockCount(block)
        if (not block) then return 0 end
        local count = 1;
        for _, field in pairs(block.inputFieldMap) do
            if (field:GetType() == "input_statement") then
                count = count + GetStatementBlockCount(field:GetInputBlock());
            end
        end
        return count + GetStatementBlockCount(block:GetNextBlock());
    end

    for _, block in ipairs(self.blocks) do
        total_count = total_count + GetStatementBlockCount(block);
    end

    return total_count;
end

function Blockly:SetRunBlockId(blockid)
    local last_running_block = self:GetRunningBlock();
    if (last_running_block) then
        last_running_block.__is_running__ = false;
        last_running_block.__render_count__ = 0;
        last_running_block.__is_hide__ = false;
    end
    local current_running_block = self.__block_id_map__[blockid or 0];
    if (current_running_block) then
        current_running_block.__is_running__ = true;
        current_running_block.__render_count__ = 0;
        current_running_block.__is_hide__ = false;
    end
    self:SetRunningBlock(current_running_block);
end

function Blockly:PushRunBlockId(blockid)
    local stack_top_index = #self.__running_block_id_stack__ + 1;
    self.__running_block_id_stack__[stack_top_index] = blockid;
    return self.__running_block_id_stack__[stack_top_index] or 0;
end

function Blockly:PopRunBlockId()
    local stack_top_index = #self.__running_block_id_stack__ ;
    self.__running_block_id_stack__[stack_top_index] = nil;
    stack_top_index = math.max(stack_top_index - 1, 1);
    return self.__running_block_id_stack__[stack_top_index] or 0;
end