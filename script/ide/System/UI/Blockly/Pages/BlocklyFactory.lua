local BlockManager = BlockManager or NPL.load("script/ide/System/UI/Blockly/Blocks/BlockManager.lua")
local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua")

BlockManager.SetCurrentCategoryAndBlockPath()

local Blockly = nil
local BlocklyEditor = nil
local BlocklyPreview = nil
local BlocklyToolBox = nil
local BlockOption = {}
-- LuaFormatter off
LangOptions = {
    {"定制当前图块", "CustomCurrentBlock"}, 
    {"定制世界图块", "CustomWorldBlock"}, 
    {"系统 NPL 图块", "SystemNplBlock"}, 
}
-- LuaFormatter on
CurrentLang = "CustomCurrentBlock"
TabIndex = "block"
ContentType = "block"
BlocklyCode = ""
BlockType = ""
BlockDefineCode = ""
ToolBoxXmlText = ""
ToolBoxBlockList = {}
ToolBoxCategoryList = {}
CategoryOptions = {}
CategoryName = ""
AllCategoryList, AllBlockList = {}, {}
SearchCategoryOptions = {{"全部", ""}}
SearchCategoryName = ""
SearchBlockType = ""
ToolBoxWidth = 300;
IsHideCategory = false;

OnToolBoxBlockWidthChange = function()
    local categoryAndBlockMap = BlockManager.GetCategoryAndBlockMap()
    categoryAndBlockMap.ToolBoxWidth = tonumber(ToolBoxWidth) or categoryAndBlockMap.ToolBoxWidth;
    BlockManager.SaveCategoryAndBlock()
end

SwitchCategoryVisible = function() 
    local categoryAndBlockMap = BlockManager.GetCategoryAndBlockMap()
    IsHideCategory = not IsHideCategory;
    categoryAndBlockMap.IsHideCategory = IsHideCategory;
    BlockManager.SaveCategoryAndBlock()
end

SelectSearchCategory = function() OnChange() end

OnSearchBlockTypeChange = function(value)
    SearchBlockType = value
    OnChange()
end

OnSelectLang = function()
    BlockManager.SetCurrentLanguage(CurrentLang)
    local categoryAndBlockMap = BlockManager.GetCategoryAndBlockMap()
    ToolBoxWidth = categoryAndBlockMap.ToolBoxWidth or ToolBoxWidth;
    IsHideCategory = categoryAndBlockMap.IsHideCategory or false;
    OnChange()
end

ClickUpdateToolBoxXmlText = function()
    BlockManager.ParseToolBoxXmlText(ToolBoxXmlText)
    ToolBoxXmlText = BlockManager.GetToolBoxXmlText()
    GameLogic.AddBBS("Blockly", "工具栏更新成功")
end

local function GetCategory(categoryName)
    local AllCategoryList = BlockManager.GetLanguageCategoryList()
    for _, categoryItem in ipairs(AllCategoryList) do if (categoryItem.name == categoryName) then return categoryItem end end
end

local function GetToolBoxBlockList()
    local AllCategoryList = BlockManager.GetLanguageCategoryList()
    local blocklist = {}
    for _, category in ipairs(AllCategoryList) do
        if (category.name == CategoryName) then
            for index, block in ipairs(category) do
                table.insert(blocklist, {blockType = block.blocktype, categoryName = category.name, hideInToolbox = block.hideInToolbox, order = index, index = index})
            end
            break

        end
    end
    return blocklist
end

OnSelectCategoryName = function() ToolBoxBlockList = GetToolBoxBlockList() end

OnToolBoxBlockOrderChange = function(block)
    local value = tonumber(block.order)
    if (not value or value == block.index) then return end
    local category = GetCategory(block.categoryName)
    if (not category) then return end
    local maxValue = #category
    value = math.max(1, math.min(value, maxValue))
    if (value == block.index) then return end
    local blockItem = category[block.index]
    table.remove(category, block.index)
    table.insert(category, value, blockItem)
    OnToolBoxChange()
    BlockManager.SaveCategoryAndBlock()
end

SwitchToolBoxBlockVisible = function(block)
    local category = GetCategory(block.categoryName)
    if (not category) then return end
    block.hideInToolbox = not block.hideInToolbox
    category[block.index].hideInToolbox = block.hideInToolbox
    OnToolBoxChange()
    BlockManager.SaveCategoryAndBlock()
end

local function GetToolBoxCategoryList()
    local AllCategoryList = BlockManager.GetLanguageCategoryList()
    local categories = {}
    local options = {}
    for index, category in ipairs(AllCategoryList) do
        table.insert(categories, {name = category.name, color = category.color, hideInToolbox = category.hideInToolbox, index = index, order = index})
        table.insert(options, #options + 1, category.name)
    end
    CategoryOptions = options
    return categories
end

SwitchToolBoxCategoryVisible = function(data)
    local category = GetCategory(data.name)
    if (not category) then return end
    data.hideInToolbox = not data.hideInToolbox
    category.hideInToolbox = data.hideInToolbox
    OnToolBoxChange()
    BlockManager.SaveCategoryAndBlock()
end

OnToolBoxCategoryColorChange = function(data)
    local category = GetCategory(data.name)
    if (not category) then return end
    category.color = data.color
    OnToolBoxChange()
    BlockManager.SaveCategoryAndBlock()
end

OnToolBoxCategoryOrderChange = function(data)
    local AllCategoryList = BlockManager.GetLanguageCategoryList()
    local value = tonumber(data.order)
    if (not value or value == data.index) then return end
    local maxValue = #AllCategoryList
    value = math.max(1, math.min(value, maxValue))
    if (value == data.index) then return end
    local categoryItem = AllCategoryList[data.index]
    table.remove(AllCategoryList, data.index)
    table.insert(AllCategoryList, value, categoryItem)
    OnToolBoxChange()
    BlockManager.SaveCategoryAndBlock()
end

ClickTabNavItemBtn = function(tabindex)
    TabIndex = tabindex
    OnChange()
end

GetTabNavItemStyle = function(tabindex) return (TabIndex == tabindex and "color: #ffffff;") or "" end

GetCategoryColorStyle = function(category) return string.format("width: 20px; height: 20px; background-color: %s; border-radius: 10px; margin-top: 4px; margin-left: 8px;", category.color) end

OnToolBoxChange = function()
    if (ContentType ~= "toolbox") then return end
    ToolBoxCategoryList = GetToolBoxCategoryList()
    ToolBoxBlockList = GetToolBoxBlockList()
    BlocklyToolBox:OnAttrValueChange("language")
end

OnBlockChange = function()
    if (ContentType ~= "block") then return end
    OnBlockListChange()
    OnCategoryListChange()
    OnToolBoxXmlTextChange()
    OnBlockDefineCodeChange()
end

SetContentType = function(contentType)
    ContentType = contentType
    if (ContentType == "blockly" and Blockly) then
        Blockly:OnAttrValueChange("language")
    elseif (ContentType == "block") then
        OnBlockChange()
    elseif (ContentType == "toolbox") then
        OnToolBoxChange()
    end
end

GetHeaderBtnStyle = function(contentType)
    if (ContentType == contentType) then return "border-bottom: 1px solid #ffffff" end
    return ""
end

local function EditBlock(blockType)
    if (BlockType == blockType) then return end
    BlockType = blockType
    local AllBlockMap = BlockManager.GetLanguageBlockMap()
    LoadBlockXmlText(AllBlockMap[BlockType])
    OnBlocklyEditorChange()
end

SelectBlock = function(blockType) EditBlock(blockType) end

ClickSaveBlockBtn = function()
    BlockOption.xml_text = BlocklyEditor:SaveToXmlNodeText()
    if (BlockType == "") then return end
    local isExist = false
    for i, opt in ipairs(AllBlockList) do
        if (opt.type == BlockType) then
            isExist = true
            break

        end
    end
    if (not isExist) then table.insert(AllBlockList, {type = BlockOption.type, category = BlockOption.category}) end

    BlockManager.NewBlock(BlockOption)
    OnChange()
end

ClickDeleteBlockBtn = function(blocktype)
    blocktype = blocktype or BlockType
    for i, block in ipairs(AllBlockList) do
        if (block.type == blocktype) then
            table.remove(AllBlockList, i)
            break

        end
    end
    BlockManager.DeleteBlock(blocktype)
    OnToolBoxXmlTextChange()
    if (blocktype == BlockType) then
        BlockType = ""
        BlocklyEditor:Reset()
        OnBlocklyEditorChange()
    end
end

ClickEditBlockBtn = function(blockType) EditBlock(blockType) end

LoadBlockXmlText = function(block)
    if (not block or not block.xml_text) then return end
    BlocklyEditor:LoadFromXmlNodeText(block.xml_text)
    BlocklyEditor:CloseFieldEditorAndContextMenu();
end

GenerateBlockOption = function()
    local rawcode, prettycode = BlocklyEditor:GetCode()
    local prettycode = string.gsub(prettycode, "\t", "    ")
    local G = {message = "", arg = {}, field_count = 0, type = "", category = "图块", color = "#2E9BEF", group = "", output = false, previousStatement = true, nextStatement = true, connections = {}, headers = {}}
    local func, errmsg = loadstring(prettycode)

    if (not func) then
        print("============================loadstring error==========================", errmsg)
        -- print(prettycode)
        return nil
    else
        -- print(prettycode)
    end
    setfenv(func, G)
    local isError = false
    xpcall(function() func() end, function(errinfo)
        print("ERROR:", errinfo)
        DebugStack()
        isError = true
    end)
    if (isError) then return nil end

    G.message = string.gsub(G.message, "^ ", "")

    local connections = G.connections
    G.connections = nil
    if (connections.output and connections.output ~= "") then G.output = connections.output end
    if (connections.previousStatement and connections.previousStatement ~= "") then G.previousStatement = connections.previousStatement end
    if (connections.nextStatement and connections.nextStatement ~= "") then G.nextStatement = connections.nextStatement end
    for _, arg in ipairs(G.arg) do
        if (arg.type == "input_value" or arg.type == "input_statement") then
            local argname = arg.name
            if (connections[argname] and connections[argname] ~= "") then arg.check = connections[argname] end
        end
    end

    return G
end

PreviewBlockOption = function(blockOption)
    if (blockOption.type == "") then
        return ;
    end
    BlocklyPreview:DefineBlock(commonlib.deepcopy(blockOption))
    local block = BlocklyPreview:GetBlockInstanceByType(blockOption.type, true)
    BlocklyPreview:ClearBlocks()
    block:SetLeftTopUnitCount(10, 10)
    block:UpdateLayout()
    BlocklyPreview:AddBlock(block)
end

OnBlocklyEditorChange = function()
    local option = GenerateBlockOption()
    if (not option) then return end
    BlockOption = option
    PreviewBlockOption(BlockOption)
    OnBlockDefineCodeChange()

    local AllBlockMap = BlockManager.GetLanguageBlockMap()
    if (BlockOption.type ~= BlockType) then
        BlockType = BlockOption.type
        if (AllBlockMap[BlockOption.type]) then
            Page.ShowMessageBoxPage({
                text = string.format("图块 %s 已经存在, 是否加载已有信息?", BlockOption.type),
                confirm = function() LoadBlockXmlText(AllBlockMap[BlockOption.type]) end
            })
        end
    end
end

OnBlocklyChange = function()
    if (not Blockly) then return end
    local rawcode, prettycode = Blockly:GetCode()
    local language = Blockly:GetLanguage()
    if (language == "SystemNplBlock") then
        BlocklyCode = string.gsub(prettycode, "\t", "    ")
    else

        BlocklyCode = rawcode
    end
end

OnToolBoxXmlTextChange = function()
    if (Blockly) then Blockly:OnAttrValueChange "language" end
    if (TabIndex ~= "toolbox" or ContentType ~= "block") then return end
    ToolBoxXmlText = BlockManager.GetToolBoxXmlText()
    ToolBoxBlockList = GetToolBoxBlockList()
end

GenerateBlockDefineCode = function(option)
    local code_description = option.code_description or ""
    code_description = string.gsub(code_description, "\n+$", "")
    code_description = string.gsub(code_description, "^\n+", "")
    local block_define_code = string.format([=[
{
    type = "%s",
    category = "%s",
    color = "%s",
    group = "%s",
    output = %s,
    previousStatement = %s, 
    nextStatement = %s,
    message = "%s",
    code_description = [[%s]],
    %s,
    %s,
}"
]=], option.type, option.category, option.color, option.group, option.output, option.previousStatement, option.nextStatement, option.message, code_description, commonlib.dump(option.arg, "arg", false, 2), commonlib.dump(option.headers, "headers", false, 2))

    return block_define_code
end

OnBlockDefineCodeChange = function()
    if (TabIndex ~= "code" or ContentType ~= "block") then return end
    BlockDefineCode = GenerateBlockDefineCode(BlockOption)
end

OnChange = function()
    OnBlockChange()
    OnToolBoxChange()
end

OnBlockListChange = function()
    if (TabIndex ~= "block" or ContentType ~= "block") then return end
    local AllBlockMap = BlockManager.GetLanguageBlockMap()
    local allBlockList = {}
    for _, block in pairs(AllBlockMap) do
        if (SearchCategoryName == "" or SearchCategoryName == block.category) then
            local blocktype = string.lower(block.type)
            if (SearchBlockType == "" or (string.find(blocktype, SearchBlockType, 1, true))) then table.insert(allBlockList, {type = block.type, category = block.category}) end
        end
    end
    table.sort(allBlockList, function(block1, block2) return (block1.category == block2.category and (block1.type < block2.type)) or (block1.category < block2.category) end)
    AllBlockList = allBlockList

    local AllCategoryMap = BlockManager.GetLanguageCategoryMap()
    SearchCategoryOptions = {{"全部", ""}}
    for _, category in pairs(AllCategoryMap) do table.insert(SearchCategoryOptions, {category.text or category.name, category.name}) end
end

OnCategoryListChange = function()
    if (TabIndex ~= "category" or ContentType ~= "block") then return end
    local AllCategoryMap = BlockManager.GetLanguageCategoryMap()
    AllCategoryList = {}
    for _, category in pairs(AllCategoryMap) do table.insert(AllCategoryList, {name = category.name, text = category.text, color = category.color or "#ffffff"}) end
end

OnReady = function()
    OnSelectLang()
    Blockly = GetRef("Blockly")
    BlocklyEditor = GetRef("BlocklyEditor")
    BlocklyPreview = GetRef("BlocklyPreview")
    BlocklyToolBox = GetRef("BlocklyToolBox")
    OnBlocklyEditorChange()
end
