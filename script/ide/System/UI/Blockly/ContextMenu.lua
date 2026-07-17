--[[
Title: ContextMenu
Author(s): wxa
Date: 2020/6/30
Desc: ContextMenu
use the lib:
-------------------------------------------------------
local ContextMenu = NPL.load("script/ide/System/UI/Blockly/ContextMenu.lua");
-------------------------------------------------------
]]
local BlockManager = NPL.load("./Blocks/BlockManager.lua");
local Element = NPL.load("../Window/Element.lua");
local Helper = NPL.load("./Helper.lua");
local Const = NPL.load("./Const.lua");

local ContextMenu = commonlib.inherit(Element, NPL.export());

local ExportAllBlockMap = {}

ContextMenu:Property("Name", "ContextMenu");
ContextMenu:Property("MenuType", "blockly");
ContextMenu:Property("Blockly");

local MenuItemWidth = 120;
local MenuItemHeight = 30;
local block_menus = {
    { text = "复制单块", cmd = "copy"},
    { text = "删除单块", cmd = "delete"},
    { text = "复制整块", cmd = "copyAll"},
    { text = "删除整块", cmd = "deleteAll"},
    { text = "添加注释", cmd = "add_note"},
    { text = "复制XML", cmd = "export_block_xml_text"},
    { text = "禁用|启用块", cmd = "disable_enable_block" },
    { text = "折叠|展开块", cmd = "folded_expand_block"},
    -- { text = "禁用块", cmd = "disable_block"},
    -- { text = "启用块", cmd = "enable_block"},
    -- { text = "折叠块", cmd = "folded_block"},
    -- { text = "展开块", cmd = "expand_block"},
}

local blockly_menus = {
    { text = "撤销", cmd = "undo"},
    { text = "重做", cmd = "redo"},
    { text = "添加注释", cmd = "add_note"},
    { text = "复制XML", cmd = "export_workspace_xml_text"},
    { text = "粘贴XML", cmd = "import_blockly_or_block_xml_text"},
    { text = "生成图块代码", cmd = "export_code"},
    { text = "生成宏示教代码", cmd = "export_macro_code"},
    { text = "生成工具栏XML", cmd = "export_toolbox_xml_text"},
    { text = "用外部网页编辑...", cmd = "export_google_blockly"},
    
    -- { text = "导入工作区XML", cmd = "import_workspace_xml_text"},
    -- { text = "导入图块XML", cmd = "import_block_xml_text"},
}

local toolbox_menus = {
    { text = "导入定制块", cmd = "show_load_custom_block_dialog"},
}

function ContextMenu:GetMenuItemWidth()
    return MenuItemWidth;
end 

function ContextMenu:GetMenuItemHeight()
    return MenuItemHeight;
end

function ContextMenu:Init(xmlNode, window, parent)
    ContextMenu._super.Init(self, xmlNode, window, parent);

    self.selectedIndex = 0;
    return self;
end

function ContextMenu:GetMenus()
    local menuType = self:GetMenuType();
    local menus = blockly_menus;
    if (menuType == "block") then menus = block_menus end
    if (menuType == "toolbox") then menus = toolbox_menus end
    return menus;

    -- if (not self:GetBlockly():IsCustomBlocklyFactory()) then return menus end
    -- local factory_menus = {};
    -- for index, menu in ipairs(menus) do
    --     factory_menus[index] = menu;
    -- end
    -- if (menuType ~= "block" and menuType ~= "toolbox") then
    --     factory_menus[#factory_menus + 1] = { text = "用外部网页编辑...", cmd = "export_google_blockly" }
    -- end
    -- return factory_menus;
end

function ContextMenu:GetMenuItem(index)
    local menus = self:GetMenus();
    return menus[index];
end

function ContextMenu:GetMenuItemCount()
    local menus = self:GetMenus();
    return #menus;
end

function ContextMenu:RenderContent(painter)
    local x, y = self:GetPosition();
    local menus = self:GetMenus();
    painter:SetBrush("#285299")
    painter:SetFont("System;12;norm")
    painter:DrawRect(x, y + self.selectedIndex * MenuItemHeight, MenuItemWidth, MenuItemHeight);
    painter:SetBrush(self:GetColor());
    for i, menu in ipairs(menus) do
        painter:DrawText(x + 20 , y + (i - 1) * MenuItemHeight + 8, menu.text);
    end
end

function ContextMenu:SelectMenuItem(event)
    local mouseMoveX, mouseMoveY = self:GetRelPoint(event.x, event.y);
    self.selectedIndex = math.floor(mouseMoveY / MenuItemHeight);
    self.selectedIndex = math.min(self.selectedIndex, self:GetMenuItemCount() - 1);
    return self.selectedIndex;
end

function ContextMenu:OnMouseDown(event)
    event:Accept();
    self:CaptureMouse();
end

function ContextMenu:OnMouseMove(event)
    event:Accept();
    self:SelectMenuItem(event);
end

function ContextMenu:OnMouseUp(event)
    event:Accept();
    self:Hide();
    self:ReleaseMouseCapture();

    local menuitem = self:GetMenuItem(self:SelectMenuItem(event) + 1);
    if (not menuitem) then return end
    local blockly = self:GetBlockly();
    if (menuitem.cmd == "copy") then
        blockly:handlePaste();
    elseif (menuitem.cmd == "delete") then
        blockly:handleDelete();
    elseif (menuitem.cmd == "copyAll") then
        blockly:handleCopyAll();
    elseif (menuitem.cmd == "deleteAll") then
        blockly:handleDeleteAll();
    elseif (menuitem.cmd == "undo") then
        blockly:Undo();
    elseif (menuitem.cmd == "redo") then
        blockly:Redo();
    elseif (menuitem.cmd == "disable_block") then
        blockly:HandleDisableBlock();
    elseif (menuitem.cmd == "enable_block") then
        blockly:HandleEnableBlock();
    elseif (menuitem.cmd == "folded_block") then
        blockly:HandleFoldedBlock();
    elseif (menuitem.cmd == "expand_block") then
        blockly:HandleExpandBlock();
    elseif (menuitem.cmd == "disable_enable_block") then
        blockly:HandleDisableEnableBlock();
    elseif (menuitem.cmd == "folded_expand_block") then
        blockly:HandleFoldedExpandBlock();
    elseif (menuitem.cmd == "export_workspace_xml_text") then
        self:ExportWorkspaceXmlText();
    elseif (menuitem.cmd == "import_workspace_xml_text") then
        self:ImportWorkspaceXmlText();
    elseif (menuitem.cmd == "export_toolbox_xml_text") then
        self:ExportToolboxXmlText();
    elseif (menuitem.cmd == "export_code") then
        self:ExportCode();
    elseif (menuitem.cmd == "export_macro_code") then
        self:ExportMacroCode();
    elseif (menuitem.cmd == "add_note") then
        self:GetBlockly():AddNote();
    elseif (menuitem.cmd == "export_block_xml_text") then
        self:ExportBlockXmlText();
    elseif (menuitem.cmd == "import_block_xml_text") then
        self:ImportBlockXmlText();
    elseif (menuitem.cmd == "import_blockly_or_block_xml_text") then
        self:ImportBlocklyOrBlockXmlText();
    elseif (menuitem.cmd == "show_load_custom_block_dialog") then
        self:ShowLoadCustomBlockDialog();
    elseif (menuitem.cmd == "export_google_blockly") then
        self:ExportGoogleBlockly();
    end 
end

function ContextMenu:ImportBlocklyOrBlockXmlText()
    if not GameLogic.options.CanPasteBlockly then
        GameLogic.AddBBS("Blockly", "无法粘贴Blockly代码,当前世界禁止粘贴外部Blockly代码");
        return 
    end
    local text = ParaMisc.GetTextFromClipboard();
    local xmlnode = Helper.XmlString2Lua(text);
    if (type(xmlnode) ~= "table" or type(xmlnode[1]) ~= "table") then return end
    local root = xmlnode[1];

    if (root.name == "Blockly") then
        self:GetBlockly():LoadFromXmlNodeText(text);
    end
    
    if (root.name == "Block") then 
        self:ImportBlockXmlNode(root); 
    end
end

function ContextMenu:ImportBlockXmlNode(xmlnode)
    local block = self:GetBlockly():GetBlockInstanceByXmlNode(xmlnode, ExportAllBlockMap);
    if (not xmlnode or not block) then return end
    local relx, rely = self:GetPosition();
    local sx, sy = self:GetBlockly():RelativePointToScreenPoint(relx, rely);
    local lx, ly = self:GetBlockly():GetLogicAbsPoint(nil, sx, sy);
    local leftUnitCount, topUnitCount = math.floor(lx / Const.UnitSize), math.floor(ly / Const.UnitSize);
    block:SetLeftTopUnitCount(leftUnitCount, topUnitCount);
    block:UpdateLayout();
    self:GetBlockly():AddBlock(block);
end

function ContextMenu:ExportBlockXmlText()
    local block = self:GetBlockly():GetCurrentBlock();
    if (not block) then return end 
    local xmlText = Helper.Lua2XmlString(block:SaveToXmlNode(), true);
    ParaMisc.CopyTextToClipboard(xmlText);
    GameLogic.AddBBS("Blockly", "图块 XML 已拷贝至剪切板");
    ExportAllBlockMap = BlockManager.GetCustomCurrentBlockAllBlockMap();
end

function ContextMenu:ImportBlockXmlText()
    local Page = NPL.load("script/ide/System/UI/Page.lua");
    Page.Show({
        title = "请输入图块XML文本",
        confirm = function(text)
            local xmlnode = Helper.XmlString2Lua(text);
            if (type(xmlnode) ~= "table") then return end
            self:ImportBlockXmlNode(xmlnode[1]);
        end,
    }, {
        url = "%ui%/Blockly/Pages/XmlTextInput.html",
        width = 500,
        height = 400,
    });
end

function ContextMenu:ExportWorkspaceXmlText()
    local xmlText = self:GetBlockly():SaveToXmlNodeText();
    ParaMisc.CopyTextToClipboard(xmlText);
    GameLogic.AddBBS("Blockly", "导出 XML 已拷贝至剪切板");
end

function ContextMenu:ImportWorkspaceXmlText()
    local Page = NPL.load("script/ide/System/UI/Page.lua");
    Page.Show({
        title = "请输入工作区XML文本",
        confirm = function(text)
            self:GetBlockly():LoadFromXmlNodeText(text);
        end,
    }, {
        url = "%ui%/Blockly/Pages/XmlTextInput.html",
        width = 500,
        height = 400,
    })
end

function ContextMenu:ExportCode()
    local blockly = self:GetBlockly();
    local rawcode, prettycode = blockly:GetCode();
    local text = string.gsub(prettycode, "\t", "    ");
    print(text);
    ParaMisc.CopyTextToClipboard(text);
    GameLogic.AddBBS("Blockly", "图块代码已拷贝至剪切板");
end

function ContextMenu:ExportMacroCode(bHideBBS)
    local blockly = self:GetBlockly();
    local toolbox = blockly:GetToolBox();
    local category_list = toolbox:GetCategoryList();
    local blocks = blockly:GetBlocks();
    local params = {};
    local width, height = blockly:GetSize();
    local ToolBoxWidth = blockly.isHideToolBox and 0 or blockly.ToolBoxWidth;
    local viewLeft, viewTop = math.floor(width / 5),  math.floor(height / 5);
    local ViewRight, viewBottom = width - viewLeft, height - viewTop;
    local oldOffsetX, oldOffsetY, oldCategoryName = blockly.offsetX, blockly.offsetY, category_list[1] and category_list[1].name or "";
    -- local offsetX, offsetY = oldOffsetX, oldOffsetY;
    local xmlText = blockly:SaveToXmlNodeText();
    toolbox:SwitchCategory(oldCategoryName);
    local isSetBlocklyEnv = false;
    local function ExportBlockMacroCode(block)
        if (not block) then return end 

        local blocktype = block:GetType();
        local blockoption = block:GetOption();
        if (string.match(blocktype, "^NPL_Macro_")) then
            local previousConnection = block.previousConnection and block.previousConnection:Disconnection();
            local nextConnection = block.nextConnection and block.nextConnection:Disconnection();
            if (previousConnection) then
                previousConnection:Connection(nextConnection);
                previousConnection:GetBlock():GetTopBlock():UpdateLayout();
            end
            local code = type(blockoption.ToMacroCode) == "function" and blockoption.ToMacroCode(block) or "";
            if (code and code ~= "") then 
                params[#params + 1] = {macroCode = code, blockType = blocktype, isMacroBlock = true}; 
            end
            ExportBlockMacroCode(nextConnection and nextConnection:GetBlock());
            return;
        end
        if (not isSetBlocklyEnv) then
            params[#params + 1] = {action = "SetBlocklyEnv", offsetX = oldOffsetX, offsetY = oldOffsetY, categoryName = oldCategoryName};
            isSetBlocklyEnv = true;
        end
        -- 调整工作区
        local left, top = oldOffsetX + block.left - ToolBoxWidth, oldOffsetY + block.top;
        if (left < viewLeft or left > ViewRight or top < viewTop or top > viewBottom) then
            local newOffsetX, newOffsetY = viewLeft + ToolBoxWidth - block.left, viewTop - block.top;
            params[#params + 1] = {action = "SetBlocklyOffset", oldOffsetX = oldOffsetX, oldOffsetY = oldOffsetY, newOffsetX = newOffsetX, newOffsetY = newOffsetY};
            oldOffsetX, oldOffsetY = newOffsetX, newOffsetY;
        end
        -- 校准分类  分类不同且不可见时需增加点击分类操作
        local newCategoryName = block:GetOption().category or "";
        if (oldCategoryName ~= newCategoryName and not toolbox:IsVisibleBlock(block:GetType())) then
            params[#params + 1] = {action = "SetToolBoxCategory", oldCategoryName = oldCategoryName, newCategoryName = newCategoryName}; 
            oldCategoryName = newCategoryName;
        end
        -- 滚动图块使其可见 TODO: 在拖拽图块中自动实现

        -- 拖拽图块
        local leftUnitCount, topUnitCount = block:GetLeftTopUnitCount();
        params[#params + 1] = {action = "SetBlockPos", blockType = block:GetType(), leftUnitCount = leftUnitCount, topUnitCount = topUnitCount};

        -- 编辑图块字段
        for _, opt in ipairs(block.inputFieldOptionList) do
            local inputfield = block:GetInputField(opt.name);
            if (inputfield) then
                if (inputfield:IsInput() and inputfield:GetInputBlock()) then
                    ExportBlockMacroCode(inputfield:GetInputBlock());
                elseif (inputfield:GetDefaultValue() ~= inputfield:GetValue()) then
                    local leftUnitCount, topUnitCount = inputfield:GetLeftTopUnitCount();
                    params[#params + 1] = {action = "SetInputValue", name = inputfield:GetName(), label = inputfield:GetLabel(), value = inputfield:GetValue(), leftUnitCount = leftUnitCount, topUnitCount = topUnitCount};
                end
            end
        end

        -- 导出下一个块
        ExportBlockMacroCode(block:GetNextBlock());
    end
    for _, block in ipairs(blocks) do
        -- if (not block.previousConnection and block.nextConnection) then
        ExportBlockMacroCode(block);
        -- end
    end
    -- blockly.offsetX, blockly.offsetY = offsetX, offsetY;
    local text = "";
    local windowName = blockly:GetWindow():GetWindowName();
    local blocklyId = blockly:GetAttrStringValue("id");
    local isExitMacroText = false;
    for _, param in ipairs(params) do
        if (param.isMacroBlock) then
            local code = param.macroCode;
            if (param.blockType == "NPL_Macro_Start") then
                code = string.gsub(code, "[;\n]+$", "");
                text = code .. "\n" .. text;
            else 
                code = string.gsub(code, "[;\n]+$", "");
                text = text .. code .. "\n";
            end
            if (param.blockType == "NPL_Macro_Text") then
                isExitMacroText = true;
            end
        else 
            param.blocklyId = blocklyId;
            local params_text = commonlib.serialize_compact({
                window_name = windowName,
                simulator_name = "BlocklySimulator",
                virtual_event_params = param,
            });
            text = text .. string.format("UIWindowEventTrigger(%s)\n", params_text);
            text = text .. string.format("UIWindowEvent(%s)\n", params_text);
            if (isExitMacroText) then
                text = text .. "text()\n";  -- 插入一条空字幕用于清除;
                isExitMacroText = false;
            end
        end
    end
    blockly:LoadFromXmlNodeText(xmlText);
    if not bHideBBS then
        ParaMisc.CopyTextToClipboard(text);
        GameLogic.AddBBS("Blockly", "示教代码已拷贝至剪切板");
    else
        return text
    end
end

function ContextMenu:ExportToolboxXmlText()
    local blockTypeMap = {};
    self:GetBlockly():ForEachUI(function(ui)
        if (ui:IsBlock()) then
            blockTypeMap[ui:GetType()] = true;
        end
    end);
    local categoryList = self:GetBlockly():GetToolBox():GetCategoryList();
    local toolbox = {name = "toolbox"};
    for _, categoryItem in ipairs(categoryList) do
        local category = {
            name = "category",
            attr = {name = categoryItem.name},
        }
        table.insert(toolbox, #toolbox + 1, category);
        for _, blocktype in ipairs(categoryItem.blocktypes) do 
            if (blockTypeMap[blocktype] or not next(blockTypeMap)) then
                table.insert(category, #category + 1, {name = "block", attr = {type = blocktype}});
            end
        end
        if (#category == 0) then table.remove(toolbox, #toolbox) end
    end
    local xmlText = Helper.Lua2XmlString(toolbox, true);
    ParaMisc.CopyTextToClipboard(xmlText);
    print(xmlText)
    GameLogic.AddBBS("Blockly", "图块工具栏XML已拷贝至剪切板");
end

function ContextMenu:ShowLoadCustomBlockDialog()
    local LoadCustomBlock = NPL.load("script/ide/System/UI/Blockly/Pages/LoadCustomBlock.lua");
    LoadCustomBlock.Show()
end

-- 定宽不定高
function ContextMenu:OnUpdateLayout()
    self:GetLayout():SetWidthHeight(MenuItemWidth, self:GetMenuItemCount() * MenuItemHeight);
end

function ContextMenu:Show(menuType)
    local draggFilter = GameLogic.GetFilters():apply_filters('CodeBlockWindow.IsDragable')
    if draggFilter == false then return end
    self:SetMenuType(menuType);
    local menus = self:GetMenus();
    if (#menus == 0) then return end

    self.selectedIndex = 0;
    self:SetVisible(true);
    self:UpdateLayout();
end

function ContextMenu:Hide()
    self:SetVisible(false);
end

function ContextMenu:ExportGoogleBlockly()
    -- 获取工作区块集
    local blockly = self:GetBlockly();
    -- local blocks = {};
    -- blockly:ForEachUI(function(ui)
    --     if (ui:IsBlock()) then
    --         blocks[ui:GetType()] = ui;
    --     end
    -- end);
    local GoogleNplBlockly = NPL.load("script/ide/System/UI/Blockly/GoogleNplBlockly.lua", true);
    -- GoogleNplBlockly:NplBlocklyToGoogleBlockly(self:GetBlockly());
    -- GoogleNplBlockly:OpenGoogleBlockly(self:GetBlockly(), blocks);
    GoogleNplBlockly:OpenGoogleBlockly(self:GetBlockly());
end