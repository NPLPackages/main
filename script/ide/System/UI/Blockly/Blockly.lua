
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
local IsRecursiveLoadFile = __rts__:GetField("IsRecursiveLoadFile", true);
__rts__:SetField("IsRecursiveLoadFile", false);

NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Sound/BlockSound.lua");

local BlockSound = commonlib.gettable("MyCompany.Aries.Game.Sound.BlockSound");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");
local BlockManager = NPL.load("./Blocks/BlockManager.lua");
local Helper = NPL.load("./Helper.lua");
local ToolBoxXmlText = NPL.load("./Blocks/ToolBoxXmlText.lua");
local BlockOptionGlobal = NPL.load("./Blocks/BlockOptionGlobal.lua");
local Options = NPL.load("./Options.lua");
local Const = NPL.load("./Const.lua");
local Shape = NPL.load("./Shape.lua");
NPL.load("./Block.lua"); -- preload to prevent recursion
local LuaFmt = NPL.load("./LuaFmt.lua");
local Element = NPL.load("../Window/Element.lua");
local ToolBox = NPL.load("./ToolBox.lua");
local ContextMenu = NPL.load("./ContextMenu.lua");
local Block = NPL.load("./Block.lua");
local ShadowBlock = NPL.load("./ShadowBlock.lua");
local FoldedBlock = NPL.load("./FoldedBlock.lua");
local BlocklyEditor = NPL.load("./BlocklyEditor.lua");
local Note = NPL.load("./Note.lua");
local BlocklySimulator = NPL.load("./BlocklySimulator.lua");
local ScrollBar = NPL.load("./ScrollBar.lua");

__rts__:SetField("IsRecursiveLoadFile", IsRecursiveLoadFile);

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
Blockly:Property("LanguageType");             -- 语言类型
Blockly:Property("LanguageText");             -- 语言问题
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
Blockly:Property("CustomBlocklyFactory", false, "IsCustomBlocklyFactory");         -- 是否是定制工具

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
    self.BlockMap, self.CategoryList, self.CategoryMap, self.CategoryColor = {}, {}, {}, {};
    self:Reset();
    self:SetToolBox(ToolBox:new():Init(self));
    self:SetOptionGlobal(BlockOptionGlobal:new():Init());
end

function Blockly:Reset()
    self.undos = {};
    self.redos = {};
    self.blocks = {};
    self.notes = {};
    self.__block_id_map__ = {};
    self.__running_block_id_stack__ = {};
    self.offsetX, self.offsetY = 0, 0;
    self.__target_offset_x__, self.__target_offset_y__ = nil, nil;   -- 平滑滚动目标偏移
    if (self.__pending_do_timer__) then self.__pending_do_timer__:Change(); self.__pending_do_timer__ = nil end
    self.__pending_do_cmd__ = nil;
    self.mouseMoveX, self.mouseMoveY = 0, 0;
    self.__content_left_unit_count__, self.__content_top_unit_count__, self.__content_right_unit_count__, self.__content_bottom_unit_count__ = 0, 0, 0, 0;
    self.__offset_x_unit_count__, self.__offset_y_unit_count__ = 0, 0;
    self.__horizontal_scroll_bar__ = ScrollBar:new():Init(self, "horizontal");
    self.__vertical_scroll_bar__ = ScrollBar:new():Init(self, "vertical");
    self.Const = Const;
    self.ToolBoxWidth = Const.ToolBoxWidth;
    self.ToolBoxBlockMap = {};
    self.init_workspace_xml = "";
    self:ResetExtendBlockAndCategory();
    self:SetScale(1);
end

function Blockly:ResetExtendBlockAndCategory()
    self.ExtendCategory = { name = "扩展", text = "扩展", color = "#FF8C1A", blocktypes = {}};
    self.ExtendBlockMap = {};
    self.CategoryColor[self.ExtendCategory.name] = self.ExtendCategory.color;
    self.CategoryColor[self.ExtendCategory.text] = self.ExtendCategory.color;
end

function Blockly:GetExtendCategory()
    return self.ExtendCategory;
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

    self:SetCustomBlocklyFactory(self:GetAttrStringValue("CustomBlocklyFactory") == "true");
    self:SetLanguage(self:GetAttrStringValue("language"));
    self:SetLanguageType(self:GetAttrStringValue("LanguageType"));
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
    local all_category_map = BlockManager.GetCustomCurrentBlockAllCategoryMap();
    local all_block_map = BlockManager.GetCustomCurrentBlockAllBlockMap();
    if (toolboxNode) then
        local categorylist, categorymap = {}, {};
        for _, categoryNode in ipairs(toolboxNode) do
            if (categoryNode.attr and categoryNode.attr.name) then
                local category_attr = categoryNode.attr;
                local default_category = self.CategoryMap[category_attr.name] or all_category_map[category_attr.name] or {};
                local category = categorymap[category_attr.name] or {};
                category.name = category.name or category_attr.name or default_category.name;
                category.text = category.text or category_attr.text or default_category.text;
                category.color = category.color or category_attr.color or default_category.color;
                default_category.color = default_category.color or category.color;
                -- local hideInToolbox = if_else(category_attr.hideInToolbox ~= nil, category_attr.hideInToolbox == "true", default_category.hideInToolbox and true or false);
                -- category.hideInToolbox = if_else(category.hideInToolbox ~= nil, category.hideInToolbox, hideInToolbox);
                category.hideInToolbox = category_attr.hideInToolbox == "true";
                for _, blockTypeNode in ipairs(categoryNode) do
                    if (blockTypeNode.attr and blockTypeNode.attr.type) then
                        local blocktype = blockTypeNode.attr.type;
                        local disabled = blockTypeNode.attr.disabled == "true";
                        local hideInToolbox = blockTypeNode.attr.hideInToolbox == "true";
                        local color = blockTypeNode.color;
                        table.insert(category, {blocktype = blocktype, hideInToolbox = hideInToolbox, disabled = disabled, color = color});
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
    self.ToolBoxBlockMap = {};
    for _, category in ipairs(self.CategoryList) do
        for _, blocktype in ipairs(category.blocktypes or {}) do
            local option = self.BlockMap[blocktype];
            if (option) then  
                option.category = category.name; 
                option.color = category.color;
                self.ToolBoxBlockMap[blocktype] = option;
            else
                print("================block undefined:", blocktype);
            end
        end
        for _, block in ipairs(category) do
            local blocktype = block.blocktype;
            local option = self.BlockMap[blocktype] or all_block_map[blocktype];
            if (option) then  
                option.category = category.name; 
                option.color = category.color;
                self.ToolBoxBlockMap[blocktype] = option;
            else
                print("================block undefined:", blocktype);
            end
        end
        self.CategoryColor[category.name] = category.color;
        self.CategoryColor[category.text or category.name] = category.color;
    end

    self:ResetExtendBlockAndCategory();
    if (self:IsCustomLanguage()) then
        if (#(self.CategoryList) == 0) then
            local all_block_map = BlockManager.GetCustomCurrentBlockAllBlockMap();
            local all_category_map = BlockManager.GetCustomCurrentBlockAllCategoryMap();
            local category_map = {};
            for block_type, block in pairs(all_block_map) do
                local category_name = block.category;
                local category = category_map[category_name];
                if (not category) then
                    local default_category = all_category_map[category_name] or {};
                    category = { color = default_category.color, name = default_category.name, text = default_category.text, blocktypes = {} };
                end
                table.insert(category.blocktypes, #category.blocktypes + 1, block_type);
                block.color = block.color or category.color;
                block.group = block.group or category.name or "";
                self.ToolBoxBlockMap[block_type] = block;
            end
            for _, category in pairs(all_category_map) do
                table.insert(self.CategoryList, #self.CategoryList + 1, category);  
            end
        end
    else
        local all_block_map = BlockManager.GetCustomCurrentBlockAllBlockMap();
        local all_category_map = BlockManager.GetCustomCurrentBlockAllCategoryMap();
        for block_type, block in pairs(all_block_map) do
            if (block_type ~= "" and not self.ExtendBlockMap[block_type] and not self.ToolBoxBlockMap[block_type]) then
                local extend_block = commonlib.deepcopy(block);
                local extend_category = all_category_map[extend_block.category] or {};
                extend_block.color = extend_block.color or extend_category.color;
                extend_block.group = extend_block.group or extend_category.name or "";
                self.ExtendBlockMap[block_type] = extend_block;
                self.ToolBoxBlockMap[block_type] = extend_block;
                table.insert(self.ExtendCategory.blocktypes, #(self.ExtendCategory.blocktypes) + 1, block_type);
                self:SortExtendBlocks();
            end
        end
    end

    self:GetToolBox():SetCategoryList(self.CategoryList);
end

function Blockly:SortExtendBlocks()
    local __self__ = self;
    table.sort(self.ExtendCategory.blocktypes, function(block_type_1, block_type_2)
        local block_1 = __self__.ExtendBlockMap[block_type_1] or __self__.ToolBoxBlockMap[block_type_1];
        local block_2 = __self__.ExtendBlockMap[block_type_2] or __self__.ToolBoxBlockMap[block_type_2];
        local group_1 = (block_1 and block_1.group or "") or "";
        local group_2 = (block_2 and block_2.group or "") or "";
        return group_1 < group_2 or (group_1 == group_2 and block_type_1 < block_type_2);
    end);
end

function Blockly:IsOnlyGenerateStartBlockCode()
    return self:GetAttrBoolValue("OnlyGenerateStartBlockCode", false);
end

function Blockly:IsCustomLanguage()
    local language = self:GetLanguage();
    return language == "CustomWorldBlock" or CustomWorldBlock == "CustomCurrentBlock";
end

function Blockly:OnAttrValueChange(attrName, attrValue, oldAttrValue)
    if (attrName == "ToolBoxXmlText") then
            -- self:OnToolBoxXmlTextChange(self:GetAttrStringValue("ToolBoxXmlText"));
        self.m_on_toolbox_xml_text_change_timer = self.m_on_toolbox_xml_text_change_timer or commonlib.TimerManager.SetTimeout(function()  
            self:OnToolBoxXmlTextChange(self:GetAttrStringValue("ToolBoxXmlText"));
            self.m_on_toolbox_xml_text_change_timer = nil;
        end,  10);
    elseif (attrName == "language" or attrName == "LanguageText") then
        self:SetLanguage(self:GetAttrStringValue("language"));
        self:SetLanguageText(self:GetAttrStringValue("LanguageText", "{}"));
        local CustomCurrentBlockLanguage = self:GetLanguage();
        BlockManager.LoadCustomCurrentBlockEntity();
        self:LoadBlockMap();
        self.CategoryList, self.CategoryMap = BlockManager.GetCategoryListAndMap(CustomCurrentBlockLanguage);
        -- self:OnToolBoxXmlTextChange(self:GetAttrStringValue("ToolBoxXmlText"));
        self:SetShowCategory(not BlockManager.IsHideCategory(CustomCurrentBlockLanguage));
        self:SetToolBoxWidth(BlockManager.GetToolBoxWidth(CustomCurrentBlockLanguage));
        self.m_on_toolbox_xml_text_change_timer = self.m_on_toolbox_xml_text_change_timer or commonlib.TimerManager.SetTimeout(function()  
            self:OnToolBoxXmlTextChange(self:GetAttrStringValue("ToolBoxXmlText"));
            self.m_on_toolbox_xml_text_change_timer = nil;
        end,  10);
    elseif (attrName == "LanguageType") then
        self:SetLanguageType(self:GetAttrStringValue("LanguageType"));
    end
end

function Blockly:LoadBlockMap()
    local block_count = 0;
    self.BlockMap = {};
    local BlockMap = BlockManager.GetBlockMap(self:GetLanguage());
    local optionGlobal = self:GetOptionGlobal();
    for blockType, blockOption in pairs(BlockMap) do
        local option = commonlib.deepcopy(blockOption);
        if (not option.isScratchBlock) then
            commonlib.mincopy(option, optionGlobal:GetDefaultOption(blockType));
            commonlib.partialcopy(option, optionGlobal:GetOverWriteOption(blockType));
        end
        block_count = block_count + 1;
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
    -- print("===========LoadBlockMap===============", self:GetLanguage(), block_count);
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
    cmd = cmd or {};
    -- 小工作区直接快照; 大工作区全量XML序列化开销大, 延迟合并快照避免频繁操作卡顿
    if (self:GetStatementBlockCount() < 300) then
        self:FlushPendingDo();
        return self:DoSnapshot(cmd);
    end
    self.__pending_do_cmd__ = cmd;
    if (self.__pending_do_timer__) then return end
    self.__pending_do_timer__ = commonlib.TimerManager.SetTimeout(function()
        self.__pending_do_timer__ = nil;
        local pending_cmd = self.__pending_do_cmd__;
        self.__pending_do_cmd__ = nil;
        if (pending_cmd) then self:DoSnapshot(pending_cmd) end
    end, 200);
end

-- 立即执行挂起的延迟快照
function Blockly:FlushPendingDo()
    if (self.__pending_do_timer__) then
        self.__pending_do_timer__:Change();
        self.__pending_do_timer__ = nil;
    end
    local pending_cmd = self.__pending_do_cmd__;
    self.__pending_do_cmd__ = nil;
    if (pending_cmd) then self:DoSnapshot(pending_cmd) end
end

function Blockly:DoSnapshot(cmd)
    cmd.workspace_xml_text = self:SaveToXmlNodeText();

    local last_cmd = self.undos[#self.undos];
    if (last_cmd and last_cmd.workspace_xml_text == cmd.workspace_xml_text) then return end

    table.insert(self.undos, #self.undos + 1, cmd);
    self.redos = {}
    self:OnChange();
    -- 如果超过50个，删除第一个
    if (#self.undos > 50) then
        table.remove(self.undos, 1);
    end
end

-- 撤销命令
function Blockly:Undo()
    self:FlushPendingDo();
    if (#self.undos == 0) then return end
    table.insert(self.redos, #self.redos + 1, self.undos[#self.undos]);
    table.remove(self.undos, #self.undos);
    local cmd = self.undos[#self.undos];
    self:LoadFromXmlNodeText(cmd and cmd.workspace_xml_text or self.init_workspace_xml);
    self:OnChange();
end

-- 恢复
function Blockly:Redo()
    self:FlushPendingDo();
    if (#self.redos == 0) then return end
    local cmd = self.redos[#self.redos];
    table.remove(self.redos, #self.redos);
    table.insert(self.undos, #self.undos + 1, cmd);
    self:LoadFromXmlNodeText(cmd.workspace_xml_text);
    self:OnChange();
end

-- 设置工具块
function Blockly:SetToolBoxBlockList()
end

-- 定义块
function Blockly:DefineBlock(block)
    self.BlockMap[block.type] = block;
    self.ToolBoxBlockMap[block.type] = block;
end

function Blockly:GetBlockOptionByType(blocktype)
    return self.ToolBoxBlockMap[blocktype] or self.BlockMap[blocktype];
end

-- 获取块
function Blockly:GetBlockInstanceByType(blockType, isToolBoxBlock, source_all_block_map)
    if (blockType == "") then return nil end
    local LangBlockMap = BlockManager.GetBlockMap(self:GetLanguage());
    local options = self.ToolBoxBlockMap[blockType] or self.ExtendBlockMap[blockType] or LangBlockMap[blockType];
    if (not self:IsCustomLanguage()) then
        options = options or self.BlockMap[blockType];
    end
    if (options == nil) then 
        if (type(source_all_block_map) == "table") then options = source_all_block_map[blockType] end
        options = options or BlockManager.GetBlockOption(blockType, self:GetLanguage());
        if (options == nil) then return nil end
        options.category = self.ExtendCategory.name;
        self.ExtendBlockMap[blockType] = options;
        self.ToolBoxBlockMap[blockType] = options;
        table.insert(self.ExtendCategory.blocktypes, #(self.ExtendCategory.blocktypes) + 1, blockType);
        self:SortExtendBlocks();
        self:GetToolBox():SetCategoryList(self.CategoryList);

        -- 保存到当前块的文件中
        local all_block_map = BlockManager.GetCustomCurrentBlockAllBlockMap();
        if (not all_block_map[blockType] and not BlockManager.GetSystemBlockOption(blockType)) then
            all_block_map[blockType] = options;
            BlockManager.SetWorldAllCustomCurrentBlockCategoryAndBlockMapChange(true);
            print("===========New Extend Block:", blockType);
        end
    end 
    local block = Block:new():Init(self, options, isToolBoxBlock);

    if (isToolBoxBlock) then
        local block_option = block:GetOption();
        local folded_xmlnode = Helper.XmlString2Lua(block_option.folded_xml_text or "");
        if (type(folded_xmlnode) == "table" and folded_xmlnode[1]) then
            local next_block = self:GetBlockInstanceByXmlNode(folded_xmlnode[1]);
            if (next_block and block_option.is_folded_draggable == false) then
                next_block:DisableDraggable(true);
            end
            if (next_block and next_block.previousConnection and block.nextConnection) then
                block.nextConnection:Connection(next_block.previousConnection);
                if (block_option.is_folded ~= false) then
                    block = FoldedBlock:new():Init(self, block);
                    block:SetType(block_option.type);
                end
            end
        end
    end

    return block;
end

-- 获取块
function Blockly:GetBlockInstanceByXmlNode(xmlNode, source_all_block_map)
    if (type(xmlNode) ~= "table" or xmlNode.name ~= "Block" or type(xmlNode.attr) ~= "table" or not xmlNode.attr.type) then return end
    local isFoldedBlock = xmlNode.attr.isFoldedBlock == "true";
    if (isFoldedBlock) then 
        for _, childXmlNode in ipairs(xmlNode) do
            if (childXmlNode.name == "FoldedBlock" and childXmlNode[1]) then
                local folded_block = self:GetBlockInstanceByXmlNode(childXmlNode[1]);
                local block = FoldedBlock:new():Init(self, folded_block);
                block:LoadFromXmlNode(xmlNode);
                return block;
            end
        end
    end

    local block = self:GetBlockInstanceByType(xmlNode.attr.type, false, source_all_block_map);
    if (not block) then 
        print("block: " .. xmlNode.attr.type .. " undefined");
        return nil 
    end
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
    local cx, cy = self.ToolBoxWidth + self.offsetX + hw, self.offsetY + hh;
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
    if (0 <= mx and mx <= 42 and 148 <= my and my <= 193 and self:GetCurrentBlock() and self:GetCurrentBlock():IsDragging()) then return 4 end
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
    self:UpdateSmoothScroll();
    self:RenderBG(painter);
    self:RenderIcons(painter);
    -- 设置绘图类
    -- Shape:SetPainter(painter);
    local DraggingBlock = nil;
    local toolboxWidth = self.ToolBoxWidth;
    painter:Translate(x, y);
    Shape:SetUnitSize(UnitSize);
    painter:Save();
    if (self.isHideToolBox) then
        painter:SetClipRegion(0, 0, w, h);
    else
        painter:SetClipRegion(toolboxWidth, 0, w - toolboxWidth, h);
    end
    painter:Scale(scale, scale);
    painter:Translate(self.offsetX, self.offsetY);
    -- 视口的逻辑坐标范围, 裁剪屏幕外的块
    local viewLeft = (self.isHideToolBox and 0 or toolboxWidth) / scale - self.offsetX;
    local viewTop = -self.offsetY;
    local viewRight = w / scale - self.offsetX;
    local viewBottom = h / scale - self.offsetY;
    self.__render_culling_top__, self.__render_culling_bottom__ = viewTop, viewBottom;
    for _, block in ipairs(self.blocks) do
        if (block:IsDragging()) then
            if (self:GetMouseCaptureUI() ~= block) then
                block:SetDragging(false);
                self:GetShadowBlock():Shadow(nil);
            else
                DraggingBlock = block;
            end
        elseif ((block.left or 0) <= viewRight and ((block.left or 0) + (block.totalWidth or 0)) >= viewLeft and
                (block.top or 0) <= viewBottom and ((block.top or 0) + (block.totalHeight or 0)) >= viewTop) then
            block:Render(painter);
            painter:Flush();
        end
    end
    self.__render_culling_top__, self.__render_culling_bottom__ = nil, nil;
    painter:Translate(-self.offsetX, -self.offsetY);
    painter:Scale(1 / scale, 1 / scale);
    painter:Restore();

    if (not self.isHideToolBox) then 
        self:GetToolBox():Render(painter);
        painter:Flush();
    end 
    
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

function Blockly:CloseFieldEditorAndContextMenu()
    local focusUI = self:GetFocusUI();
    if (focusUI ~= nil and type(focusUI.OnFocusOut) == "function") then 
        focusUI:OnFocusOut();
    end
    self:SetFocusUI(nil);

    local contextmenu = self:GetContextMenu();
    if (contextmenu ~= nil) then
        contextmenu:Hide();
    end
end

-- 鼠标按下事件
function Blockly:OnMouseDown(event)
    event:Accept();
    self:CancelSmoothScroll();
    self.mouseMoveX, self.mouseMoveY = Blockly._super.GetRelPoint(self, event.x, event.y);
    self:GetContextMenu():Hide();
    local ui = self:GetMouseDownUI(event);
    
    -- 失去焦点
    local focusUI = self:GetFocusUI();
    if (focusUI ~= ui and focusUI and type(focusUI.OnFocusOut) == "function") then 
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
    if (not self.isHideToolBox) then offsetX = offsetX - self.ToolBoxWidth end 
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
    if (not self.isHideToolBox) then width = width - self.ToolBoxWidth end
    local viewLeft, viewTop = math.floor(width / 3),  math.floor(height / 4);
    if (self.isHideToolBox) then 
        self.offsetX, self.offsetY = viewLeft - left, viewTop - top;
    else
        self.offsetX, self.offsetY = viewLeft - left + self.ToolBoxWidth, viewTop - top;
    end
    self:OnOffsetChange();
end

-- 更新缩放: 以锚点(屏幕坐标)为中心缩放, 缺省锚点为工作区视口中心, 缩放前后锚点下的逻辑点保持不动
function Blockly:UpdateScale(offset, anchorX, anchorY)
    local oldScale = self:GetScale();
    local newScale = offset and (oldScale + offset) or 1;
    newScale = math.min(newScale, 4);
    newScale = math.max(newScale, 0.5);

    if (oldScale == newScale) then return end
    if (not anchorX or not anchorY) then
        local width, height = self:GetSize();
        local toolboxWidth = self.isHideToolBox and 0 or self.ToolBoxWidth;
        anchorX, anchorY = toolboxWidth + (width - toolboxWidth) / 2, height / 2;
    end
    self:CancelSmoothScroll();
    -- 锚点下的逻辑点: anchor / scale - offset, 保持不变可得新偏移
    local UnitSize = self:GetUnitSize();
    local offsetX = anchorX / newScale - (anchorX / oldScale - self.offsetX);
    local offsetY = anchorY / newScale - (anchorY / oldScale - self.offsetY);
    self:SetScale(newScale);
    self:AdjustContentSize();
    self.__offset_x_unit_count__ = math.floor(offsetX / UnitSize + 0.5);
    self.__offset_y_unit_count__ = math.floor(offsetY / UnitSize + 0.5);
    self.__offset_x_unit_count__ = math.min(math.max(self.__offset_x_unit_count__, self.__min_offset_x_count__), self.__max_offset_x_count__);
    self.__offset_y_unit_count__ = math.min(math.max(self.__offset_y_unit_count__, self.__min_offset_y_count__), self.__max_offset_y_count__);
    self.offsetX = self.__offset_x_unit_count__ * UnitSize;
    self.offsetY = self.__offset_y_unit_count__ * UnitSize;
    self:OnOffsetChange();
end

-- 获取当前鼠标顶点值
function Blockly:GetMouseLeftTopUnitCount()
    local x, y = self:GetLogicAbsPoint();
    local UnitSize = self:GetUnitSize();
    return math.floor(x / UnitSize), math.floor(y/ UnitSize);
end

-- 鼠标移动事件
function Blockly:OnMouseMove(event)
    self.mouseMoveX, self.mouseMoveY = Blockly._super.GetRelPoint(self, event.x, event.y);
    if (not self.isHideToolBox) then
        local toolbox = self:GetToolBox();
        if (self.mouseMoveX > 0 and self.mouseMoveX < self.ToolBoxWidth) then
            toolbox:OnMouseEnter(event);
        else 
            toolbox:OnMouseLeave(event);
        end
    end
    if (not event:IsLeftButton() and self:GetMouseCaptureUI() == nil) then return end

    local UnitSize = self:GetUnitSize();
    local x, y = self:GetLogicAbsPoint(event);
    local logicViewX, logicViewY = self:GetLogicViewPoint(event);
    local ui = self:GetMouseUI(x, y, event);
    if (ui and ui ~= self) then 
        return ui:OnMouseMove(event) 
    end
    
    if (not self.isMouseDown or not event:IsLeftButton()) then return end
    
    event:Accept();
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
        if (focusUI ~= ui and focusUI and focusUI.OnFocusOut) then focusUI:OnFocusOut() end
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
    
    if (event:IsRightButton() and not self:IsReadOnly()) then
        local menuType = "block";
        if (self:IsInnerToolBox(event)) then
            -- menuType = "toolbox";
            -- self:SetCurrentBlock(nil);
            return;
        elseif (ui == self or (type(ui) == "table" and type(ui.GetClassName) == "function" and ui:GetClassName() == "Blockly")) then 
            menuType = "blockly";
            self:SetCurrentBlock(nil);
        elseif (type(ui) == "table" and type(ui.GetBlock) == "function") then
            block = ui:GetBlock();
            self:SetCurrentBlock(block:GetProxyBlock() or block);
        else
            return;
        end
        local contextmenu = self:GetContextMenu();
        contextmenu:SetMenuType(menuType);
        local absX, absY = Blockly._super.GetRelPoint(self, event.x, event.y);  -- 相对坐标为窗口的缩放后坐标
        -- local absX, absY = self:GetLogicViewPoint(event);
        local x, y, w, h = self:GetGeometry();
        local menuitem_count = contextmenu:GetMenuItemCount();
        local menuitem_width = contextmenu:GetMenuItemWidth();
        local menuitem_height = contextmenu:GetMenuItemHeight() * menuitem_count;
        if ((absX + menuitem_width) > (x + w)) then
            absX = x + w - menuitem_width;
        end
        if ((absY + menuitem_height) > (y + h)) then
            absY = y + h - menuitem_height;
        end

        contextmenu:SetStyleValue("left", absX);
        contextmenu:SetStyleValue("top", absY);
        self:GetContextMenu():Show(menuType);
        self.__context_menu_x__, self.__context_menu_y__ = event:GetScreenXY();
    end
end

function Blockly:AdjustContentSize()
    local width, height = self:GetSize();
    local UnitSize = self:GetUnitSize();
    local scale = self:GetScale();
    self.__toolbox_unit_count__ = self.isHideToolBox and 0 or math.floor(self.ToolBoxWidth / UnitSize);
    self.__width_unit_count__, self.__height_unit_count__ = math.ceil(width / UnitSize), math.ceil(height / UnitSize);
    self.__offset_x_unit_count__, self.__offset_y_unit_count__ = math.floor(self.offsetX / UnitSize), math.floor(self.offsetY / UnitSize);
    local left, top, right, bottom = nil, nil, nil, nil;
    for _, block in ipairs(self.blocks) do
        local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
        local widthUnitCount, heightUnitCount = block:GetTotalWidthHeightUnitCount();
        local rightUnitCount, bottomUnitCount = leftUnitCount + widthUnitCount, topUnitCount + heightUnitCount;
        left = left and math.min(left, leftUnitCount) or leftUnitCount;
        top = top and math.min(top, topUnitCount) or topUnitCount;
        right = right and math.max(right, rightUnitCount) or rightUnitCount;
        bottom = bottom and math.max(bottom, bottomUnitCount) or bottomUnitCount;
    end
    self.__content_left_unit_count__, self.__content_top_unit_count__, self.__content_right_unit_count__, self.__content_bottom_unit_count__ = left or 0, top or 0, right or 0, bottom or 0;
    -- 滚动边界 = 内容包围盒向四周扩展半个视口(视口逻辑尺寸受缩放影响), 避免内容被滑出可视范围太远
    local view_width_unit_count = math.ceil(width / scale / UnitSize);
    local view_height_unit_count = math.ceil(height / scale / UnitSize);
    local toolbox_view_unit_count = self.isHideToolBox and 0 or math.ceil(self.ToolBoxWidth / scale / UnitSize);
    local half_view_width_unit_count = math.floor((view_width_unit_count - toolbox_view_unit_count) / 2);
    local half_view_height_unit_count = math.floor(view_height_unit_count / 2);
    self.__min_offset_x_count__ = toolbox_view_unit_count - half_view_width_unit_count - self.__content_right_unit_count__;
    self.__max_offset_x_count__ = view_width_unit_count + half_view_width_unit_count - self.__content_left_unit_count__;
    self.__min_offset_y_count__ = -half_view_height_unit_count - self.__content_bottom_unit_count__;
    self.__max_offset_y_count__ = view_height_unit_count + half_view_height_unit_count - self.__content_top_unit_count__;
    -- 当前偏移可能超出上述边界(旧存档保存的偏移/居中定位等): 扩展边界包含当前偏移,
    -- 保证从当前位置能平滑滚回内容区而不被钳制卡住(否则平移会被钳在边界上拖不动, 滚动条滑块也会画出轨道外)
    self.__min_offset_x_count__ = math.min(self.__min_offset_x_count__, self.__offset_x_unit_count__);
    self.__max_offset_x_count__ = math.max(self.__max_offset_x_count__, self.__offset_x_unit_count__);
    self.__min_offset_y_count__ = math.min(self.__min_offset_y_count__, self.__offset_y_unit_count__);
    self.__max_offset_y_count__ = math.max(self.__max_offset_y_count__, self.__offset_y_unit_count__);
end

function Blockly:OnOffsetChange()
    for _, note in ipairs(self.notes) do
        note:UpdateWindowPos();
    end
end

function Blockly:GetOffset()
    return self.offsetX, self.offsetY;
end

-- 平滑滚动: 每帧向目标偏移插值, 由 RenderContent 驱动
function Blockly:UpdateSmoothScroll()
    if (not self.__target_offset_x__ and not self.__target_offset_y__) then return end
    local UnitSize = self:GetUnitSize();
    local function NextOffset(offset, target)
        if (not target) then return offset, nil end
        local diff = target - offset;
        if (math.abs(diff) <= UnitSize) then return target, nil end
        return offset + diff * 0.4, target;
    end
    self.offsetX, self.__target_offset_x__ = NextOffset(self.offsetX, self.__target_offset_x__);
    self.offsetY, self.__target_offset_y__ = NextOffset(self.offsetY, self.__target_offset_y__);
    self.__offset_x_unit_count__ = math.floor(self.offsetX / UnitSize + 0.5);
    self.__offset_y_unit_count__ = math.floor(self.offsetY / UnitSize + 0.5);
    self:OnOffsetChange();
end

-- 取消平滑滚动(直接设置偏移前调用, 防止插值与直接操作冲突)
function Blockly:CancelSmoothScroll()
    self.__target_offset_x__, self.__target_offset_y__ = nil, nil;
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
    event:Accept();
    if (self:IsInnerToolBox(event)) then return self:GetToolBox():OnMouseWheel(event) end
    if (self:IsEditing()) then return end
    local delta = event:GetDelta();             -- 1 向上滚动  -1 向下滚动
    local UnitSize = self:GetUnitSize();
    local scale = self:GetScale();

    -- Ctrl + 滚轮: 以鼠标位置为锚点缩放
    if (event.ctrl_pressed) then
        local anchorX, anchorY = Blockly._super.GetRelPoint(self, event.x, event.y);
        self:UpdateScale(delta > 0 and 0.1 or -0.1, anchorX, anchorY);
        return;
    end

    -- 每格滚动约3行内容高, 除以缩放值使视觉步长恒定; 只更新目标偏移, 由 UpdateSmoothScroll 逐帧插值
    local step = delta * Const.LineHeightUnitCount * UnitSize * 3 / scale;
    if (event.shift_pressed) then
        local targetX = (self.__target_offset_x__ or self.offsetX) + step;
        targetX = math.floor(targetX / UnitSize) * UnitSize;
        targetX = math.min(math.max(targetX, self.__min_offset_x_count__ * UnitSize), self.__max_offset_x_count__ * UnitSize);
        self.__target_offset_x__ = targetX;
    else
        local targetY = (self.__target_offset_y__ or self.offsetY) + step;
        targetY = math.floor(targetY / UnitSize) * UnitSize;
        targetY = math.min(math.max(targetY, self.__min_offset_y_count__ * UnitSize), self.__max_offset_y_count__ * UnitSize);
        self.__target_offset_y__ = targetY;
    end
end

-- 键盘事件
function Blockly:OnKeyDown(event)
    if (not self:IsFocus()) then return end
    event:Accept();
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
    self:Do();
end

function Blockly:CopyBlock(targetBlock, cloneBlock, isCloneAllBlock)
    if (not targetBlock) then return end 
    cloneBlock = targetBlock:Clone(cloneBlock, isCloneAllBlock);

    -- 录制或播放模式走旧逻辑
    if (BlocklySimulator:IsRecordingOrPlaying()) then
        local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
        cloneBlock:SetLeftTopUnitCount(leftUnitCount + 4, topUnitCount + 4);
        cloneBlock:UpdateLayout();

        self:AddBlock(cloneBlock);
        self:SetCurrentBlock(cloneBlock);
        self:OnChange();
    else
        local leftUnitCount, topUnitCount = self:GetMouseLeftTopUnitCount();
        cloneBlock:SetLeftTopUnitCount(leftUnitCount - 4, topUnitCount - 4);
        cloneBlock:UpdateLayout();
        cloneBlock:OnMouseDown();
        cloneBlock:SetDragging(true);
        self:SetCurrentBlock(cloneBlock);
        self:CaptureMouse(cloneBlock);
        self:AddBlock(cloneBlock);
        self:GetShadowBlock():Shadow(cloneBlock);
    end

    local xmlText = Helper.Lua2XmlString(cloneBlock:SaveToXmlNode(), true);
    ParaMisc.CopyTextToClipboard(xmlText);
end

-- 复制当前块
function Blockly:handlePaste()
    local block = self:GetCurrentBlock();
    if (not block) then
        -- local text = ParaMisc.GetTextFromClipboard();
        -- local workspace = commonlib.Json.Decode(text);
        -- if (type(workspace) == "table") then
        --     self:Load({
        --         blocks = workspace.blocks.blocks,
        --     });
        -- end
        -- self:Do();
    else
        self:CopyBlock(self:GetCurrentBlock(), nil, nil);
        self:Do();
    end
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
        local connectionBlock = block.previousConnection:GetConnectionBlock();
        block.previousConnection:Disconnection();
        if (connectionBlock) then connectionBlock:UpdateLayout() end
    end
    local nextBlock = block;
    while (nextBlock) do
        self:OnDestroyBlock(nextBlock);
        nextBlock = nextBlock:GetNextBlock();
    end
    self:RemoveBlock(block);
    self:SetCurrentBlock(nil);
    self:Do();
end

-- 禁用块
function Blockly:HandleDisableBlock()
    local block = self:GetCurrentBlock();
    if (not block) then return end
    block:DisableRun();
    self:Do();
end

-- 启用块
function Blockly:HandleEnableBlock()
    local block = self:GetCurrentBlock();
    if (not block) then return end

    local prevBlock = block:GetPrevBlock() or block:GetOutputBlock();
    while (prevBlock and prevBlock:IsDisableRun()) do
        block = prevBlock;
        prevBlock = block:GetPrevBlock() or block:GetOutputBlock();
    end

    block:EnableRun();
    self:Do();
end

-- 折叠块
function Blockly:HandleFoldedBlock()
    local block = self:GetCurrentBlock();
    if (not block) then return end
    block:Folded();
    self:Do();
end

-- 展开块
function Blockly:HandleExpandBlock()
    local block = self:GetCurrentBlock();
    if (not block) then return end
    block:Expand();
    self:Do();
end

function Blockly:HandleDisableEnableBlock()
    local block = self:GetCurrentBlock();
    if (not block) then return end
    if (block:IsDisableRun()) then
        self:HandleEnableBlock();
    else
        self:HandleDisableBlock();
    end
end

function Blockly:HandleFoldedExpandBlock()
    local block = self:GetCurrentBlock();
    if (not block) then return end
    if (block:IsFoldedBlock()) then
        self:HandleExpandBlock();
    else
        self:HandleFoldedBlock();
    end
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

-- @param order: if nil, it default to 0, and will be appended. the larger the order, the later it will be inserted to code header.
-- @return index of the added text
function Blockly:AddUniqueHeader(headerText, zorder)
    if(headerText and self.uniqueHeaders) then
        if(not self.uniqueHeaders:contains(headerText)) then
            self.uniqueHeaders:add(headerText, zorder or 0);
        end
        return self.uniqueHeaders:getIndex(headerText)
    end
end
-- fixed typo
Blockly.AddUnqiueHeader = Blockly.AddUniqueHeader

-- check if a unique header exist
function Blockly:HasUniqueHeader(headerText)
    if(headerText and self.uniqueHeaders) then
        if(self.uniqueHeaders:contains(headerText)) then
            return true;
        end
    end
end

-- reset nextId when calling GetCode()
function Blockly:GetNextId()
    self.nextId = (self.nextId or 0) + 1;
    return self.nextId;
end

function Blockly:ResetNextId()
    self.nextId = 0;
end

function Blockly:UpdateAllVariables()
    -- just make it dirty until we call GetAllVariables()
    -- since in most languages, this is not necessary, however, python need to predefine global variables in every function. 
    self.variables = nil;
end

-- get all variables in blocks as array of names
function Blockly:GetAllVariables()
    if(not self.variables) then 
        local variables = {};
        local exist = {};
        self:ForEachUI(function(blockInputField)
            if (not blockInputField:IsField() or blockInputField:GetType() ~= "field_variable") then return end
            local varname = blockInputField:GetValue();
            if (varname and varname ~= "" and not exist[varname]) then
                variables[#variables+1] = varname
                exist[varname] = true;
            end
        end);
        self.variables = variables;
    end
    return self.variables;
end

-- 获取代码
function Blockly:GetCode()
    -- print("=============GetCode==================")
    self.__block_id_map__ = {};
    self.__running_block_id_stack__ = {};
    self.uniqueHeaders = commonlib.ArrayMap:new();
    self:ResetNextId();
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
    self:UpdateAllVariables();

    self:SetToCodeCache({});  -- 设置缓存对象

    local code = "";
    local lines = {};
    for _, block in ipairs(blocks) do
        local nextBlock = block;
        if (only_generate_start_block_code and nextBlock:IsStart()) then
            blockCode = nextBlock:GetCode();
        else
            while (nextBlock) do
                lines[#lines+1] = nextBlock:GetCode()
                nextBlock = nextBlock:GetNextBlock();
            end
        end
        lines[#lines+1] = "\n"
    end

    if(self.uniqueHeaders:size() > 0) then
        self.uniqueHeaders:valueSort(function(a, b) return a <= b end);
		for i = 1, self.uniqueHeaders:size() do
            table.insert(lines, i, self.uniqueHeaders:getKeyAt(i) .. "\n")
		end
	end

    -- post process code
    for _, block in ipairs(blocks) do
        while (block) do
            local option = block:GetOption();
            if(option and option.PostProcess) then
                lines = option.PostProcess(block, lines) or lines;
            end
            block = block:GetNextBlock();
        end
    end

    -- for _, block in ipairs(self.blocks) do
    --     local option = block:GetOption();
    --     if(option and option.PostProcess) then
    --         lines = option.PostProcess(block, lines) or lines;
    --     end
    -- end
    code = table.concat(lines)

    self:SetToCodeCache(nil); -- 清除缓存
    
    code = self:PostProcessCode(code);

    return code, self:GetPrettyCode(code);
end

function Blockly:PostProcessCode(code)
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpWindow.lua");
    local CodeHelpWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow");
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/LanguageConfigurations.lua");
    local LanguageConfigurations = commonlib.gettable("MyCompany.Aries.Game.Code.LanguageConfigurations");
    local filename = CodeHelpWindow.GetLanguageConfigFile();
    local langConfig = LanguageConfigurations:LoadConfigByFilename(filename);
    if (type(langConfig) == "table" and type(langConfig.PostProcessBlocklyCode) == "function") then
        code = langConfig.PostProcessBlocklyCode(self, code);
    end
    return code;
end

function Blockly:Save()
    local blockly = { blocks = {} };

    for _, block in ipairs(self.blocks) do
        table.insert(blockly.blocks, block:Save());
    end

    return blockly;
end

function Blockly:Load(blockly)
    for _, block in ipairs(blockly.blocks) do
        local block_type = block.type;
        local block_inst = self:GetBlockInstanceByType(block_type);
        if (block_inst) then
            block_inst:Load(block);
            block_inst:UpdateLayout();
            self:AddBlock(block_inst);
        end
    end
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
    if (type(xmlNode) ~= "table") then return end
    local blocklyXmlNode = commonlib.XPath.selectNode(xmlNode, "//Blockly");
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

function Blockly:SetToolBoxWidth(width)
    self.ToolBoxWidth = width;
    self:GetToolBox().ToolBoxWidth = self.ToolBoxWidth;
    self:UpdateLayout();
end

function Blockly:SetShowCategory(bShow)
    if (self:GetToolBox():IsShowCategory() == bShow) then return end
    self:GetToolBox():SetShowCategory(bShow);
    self:GetToolBox():SetCategoryList(self.CategoryList);
end

function Blockly:SetInitWorkspaceXml(xml_text)
    if (self.m_on_toolbox_xml_text_change_timer) then
        self.m_on_toolbox_xml_text_change_timer:Change();
        self.m_on_toolbox_xml_text_change_timer = nil;
        self:OnToolBoxXmlTextChange(self:GetAttrStringValue("ToolBoxXmlText"));
    end
    self.init_workspace_xml = xml_text;
    self:LoadFromXmlNodeText(xml_text);
end
