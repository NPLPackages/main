--[[
Title: BlockManager
Author(s): wxa
Date: 2020/6/30
Desc: 文件管理器
use the lib:
-------------------------------------------------------
local BlockManager = NPL.load("script/ide/System/UI/Blockly/BlockManager.lua");
-------------------------------------------------------
]]


local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local Helper = NPL.load("../Helper.lua");

local NplBlockManager = NPL.load("./NplBlockManager.lua", IsDevEnv);
local BlockBlockManager = NPL.load("./BlockBlockManager.lua", IsDevEnv);

local LanguageConfig = NPL.load("./LanguageConfig.lua", IsDevEnv);

local SystemBlockDirectory = "Mod/GeneralGameServerMod/UI/BlocklyBlocks/";

local LanguagePathMap = {
    ["SystemLuaBlock"] = SystemBlockDirectory .. "SystemLuaBlock",
    ["SystemNplBlock"] = SystemBlockDirectory .. "SystemNplBlock",
    ["SystemUIBlock"] = SystemBlockDirectory .. "SystemUIBlock",
    ["SystemGIBlock"] = SystemBlockDirectory .. "SystemGIBlock",
}
local WorldCategoryAndBlockDirectory = "";
local WorldCategoryAndBlockPath = "";
local CurrentCategoryAndBlockPath = "";
local AllCategoryAndBlockMap = {};
local AllBlockMap = {};
local inited = false;
local BlockManager = NPL.export();

function BlockManager.IsCustomLanguage(lang)
    if (lang == "CustomWorldBlock") then return true end 
    return LanguagePathMap[lang] and true or false;
end

function BlockManager.GetBlocklyDirectory()
    return CommonLib.ToCanonicalFilePath(CommonLib.GetWorldDirectory() .. "/blockly/");
end

function BlockManager.LoadCategoryAndBlock(filename)
    filename = filename or CurrentCategoryAndBlockPath;

    if (AllCategoryAndBlockMap[filename]) then return AllCategoryAndBlockMap[filename] end
    
    local io = ParaIO.open(filename, "r");
    if(not io:IsValid()) then 
        print("file invalid: ", filename)
        return nil;
    end 

    local text = io:GetText();
    io:close();
    local CategoryBlockMap = NPL.LoadTableFromString(text);

    local CategoryMap = CategoryBlockMap.AllCategoryMap or {};
    local BlockMap = CategoryBlockMap.AllBlockMap or {};

    local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(filename);
    local LangCategoryMap, LangBlockMap = CategoryAndBlockMap.AllCategoryMap, CategoryAndBlockMap.AllBlockMap;
    for categoryName, category in pairs(CategoryMap) do
        LangCategoryMap[categoryName] = LangCategoryMap[categoryName] or {name = categoryName};
        commonlib.partialcopy(LangCategoryMap[categoryName], category);
    end
    for blockType, block in pairs(BlockMap) do
        LangBlockMap[blockType] = block;  -- 直接覆盖
        LangCategoryMap[block.category] = LangCategoryMap[block.category] or {name = block.category};
    end

    CategoryAndBlockMap.AllCategoryList = CategoryBlockMap.AllCategoryList or CategoryAndBlockMap.AllCategoryList;
    CategoryAndBlockMap.ToolBoxXmlText = CategoryBlockMap.ToolBoxXmlText or CategoryAndBlockMap.ToolBoxXmlText or BlockManager.GenerateToolBoxXmlText(filename);

    for blockType, blockOption in pairs(LangBlockMap) do
        AllBlockMap[blockType] = blockOption;
    end

    return CategoryAndBlockMap;
end

function BlockManager.SaveCategoryAndBlock(filename)
    -- 确保目存在
    ParaIO.CreateDirectory(BlockManager.GetBlocklyDirectory());

    filename = filename or CurrentCategoryAndBlockPath;
    local isNormalUserCustomSystemBlock = false;
    if (filename ~= WorldCategoryAndBlockPath and not IsDevEnv) then
        for language, path in pairs(LanguagePathMap) do
            if (filename == path) then 
                local default_directory = "temp/blockly/";
                ParaIO.CreateDirectory(default_directory);
                filename = default_directory .. language;
                isNormalUserCustomSystemBlock = true;
                break;
            end
        end
        if (not isNormalUserCustomSystemBlock) then return end
        GameLogic.AddBBS("Blockly", "非开发人员只能定制世界图块, 系统块定制保存至: " .. filename);
    end
    local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(filename);
    -- 重写全局 BlockMap
    for blockType, blockOption in pairs(CategoryAndBlockMap.AllBlockMap) do AllBlockMap[blockType] = blockOption end

    CategoryAndBlockMap.ToolBoxXmlText = BlockManager.GenerateToolBoxXmlText(filename);
    
    local text = commonlib.serialize_compact(CategoryAndBlockMap);
    local io = ParaIO.open(filename, "w");
	io:WriteString(text);
    io:close();
    if (not isNormalUserCustomSystemBlock) then GameLogic.AddBBS("Blockly", "图块更改已保存") end
end

function BlockManager.GetCategoryAndBlockMap(path)
    path = path or CurrentCategoryAndBlockPath;
    path = LanguagePathMap[path] or path;
    AllCategoryAndBlockMap[path] = AllCategoryAndBlockMap[path] or {
        AllCategoryList = {},
        AllCategoryMap = {},
        AllBlockMap = {},
    };
    return AllCategoryAndBlockMap[path]; 
end

function BlockManager.SetCurrentCategoryAndBlockPath(path)
    CurrentCategoryAndBlockPath = path or WorldCategoryAndBlockPath;
end

function BlockManager.SetCurrentLanguage(lang)
    BlockManager.SetCurrentCategoryAndBlockPath(LanguagePathMap[lang or ""]);
end

function BlockManager.NewBlock(block)
    if (not block.type) then return end
    local allBlockMap = BlockManager.GetLanguageBlockMap();
    allBlockMap[block.type] = {
        type = block.type,
        category = block.category,
        color = block.color,
        hideInToolbox = block.hideInToolbox,
        output = block.output,
        previousStatement = block.previousStatement,
        nextStatement = block.nextStatement,
        message = block.message,
        arg = block.arg,
        -- func_description = block.func_description,
        code_description = block.code_description,
        xml_text = block.xml_text,
        code = block.code,
    };
    BlockManager.SaveCategoryAndBlock();
end

function BlockManager.DeleteBlock(blockType)
    local allBlockMap = BlockManager.GetLanguageBlockMap();
    allBlockMap[blockType] = nil;
    BlockManager.SaveCategoryAndBlock();
end

function BlockManager.GetLanguageCategoryMap(path)
    return BlockManager.GetCategoryAndBlockMap(path).AllCategoryMap;
end

function BlockManager.GetLanguageCategoryList(path)
    return BlockManager.GetCategoryAndBlockMap(path).AllCategoryList;
end

function BlockManager.GetLanguageBlockMap(path)
    return BlockManager.GetCategoryAndBlockMap(path).AllBlockMap;
end

local function OnWorldLoaded()
    local directory = BlockManager.GetBlocklyDirectory();
    local filename = CommonLib.ToCanonicalFilePath(directory .. "/CustomWorldBlock");
    if (filename == WorldCategoryAndBlockPath) then return end
    WorldCategoryAndBlockDirectory = directory;
    WorldCategoryAndBlockPath = filename;
    CurrentCategoryAndBlockPath = WorldCategoryAndBlockPath;
    
    -- 确保目存在
    -- ParaIO.CreateDirectory(directory);

    --加载数据
    BlockManager.LoadCategoryAndBlock();
end

local function OnWorldUnloaded()
end

function BlockManager.StaticInit()
    if (inited) then return BlockManager end
    inited = true;

    for _, path in pairs(LanguagePathMap) do
        BlockManager.LoadCategoryAndBlock(path);
    end

    GameLogic:Connect("WorldLoaded", nil, OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", nil, OnWorldUnloaded, "UniqueConnection");
    
    OnWorldLoaded();

    return BlockManager;
end

function BlockManager.GetToolBoxXmlText(path)
    return BlockManager.GetCategoryAndBlockMap(path).ToolBoxXmlText;
end

function BlockManager.GenerateToolBoxXmlText(path)
    local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(path);
    local AllCategoryList = CategoryAndBlockMap.AllCategoryList; --  CategoryAndBlockMap.AllBlockMap;
    local BlockTypeMap, AllCategoryMap = {}, {};
    for _, category in ipairs(AllCategoryList) do
        AllCategoryMap[category.name] = category;
        local index, size = 1, #category;
        for i = 1, size do
            local blockitem = category[i];
            local blocktype = blockitem.blocktype;
            local languageBlock = CategoryAndBlockMap.AllBlockMap[blocktype]
            local systemBlock = AllBlockMap[blocktype];
            if ((languageBlock and languageBlock.category == category.name) or (not languageBlock and systemBlock)) then
                BlockTypeMap[blocktype] = true;
                category[index] = blockitem;
                index = index + 1;
            end
        end

        -- 清除不存在的图块
        for i = index, size do category[i] = nil end
    end

    for blocktype, block in pairs(CategoryAndBlockMap.AllBlockMap) do
        local category = AllCategoryMap[block.category];
        if (not category) then
            category = {name = block.category};
            AllCategoryMap[block.category] = category;
            table.insert(AllCategoryList, category);
        end
        -- 分类不存在则添加分类
        if (not BlockTypeMap[blocktype]) then
            table.insert(category, #category + 1, {blocktype = blocktype});
        end
    end

    -- 删除无块分类
    for categoryName, category in pairs(AllCategoryMap) do
        if (#category == 0) then
            for index, item in ipairs(AllCategoryList) do
                if (item.name == categoryName) then
                    table.remove(AllCategoryList, index);
                    break;
                end
            end
        end
    end
    CategoryAndBlockMap.AllCategoryMap = AllCategoryMap;

    local toolbox = {name = "toolbox"};
    for _, categoryItem in ipairs(AllCategoryList) do
        local category = {
            name = "category",
            attr = {name = categoryItem.name, color = categoryItem.color, text = categoryItem.text, hideInToolbox = categoryItem.hideInToolbox and "true" or nil},
        }
        table.insert(toolbox, #toolbox + 1, category);
        for _, blockItem in ipairs(categoryItem) do 
            table.insert(category, #category + 1, {name = "block", attr = {type = blockItem.blocktype, hideInToolbox = blockItem.hideInToolbox and "true" or nil}});
        end
    end
    local xmlText = Helper.Lua2XmlString(toolbox, true);
    return xmlText;
end

function BlockManager.GetCategoryListAndMapByXmlText(xmlText, path)
    local xmlNode = ParaXML.LuaXML_ParseString(xmlText);
    local toolboxNode = xmlNode and commonlib.XPath.selectNode(xmlNode, "//toolbox");
    if (not toolboxNode) then return end
    local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(path);
    local AllCategoryMap = {};
    local AllCategoryList = {};
    for _, categoryNode in ipairs(toolboxNode) do
        if (categoryNode.attr and categoryNode.attr.name) then
            local category_attr = categoryNode.attr;
            local category = AllCategoryMap[category_attr.name] or {};
            category.name = category.name or category_attr.name;
            category.text = category.text or category_attr.text;
            category.color = category.color or category_attr.color;
            category.hideInToolbox = if_else(category.hideInToolbox == nil, category_attr.hideInToolbox == "true", category.hideInToolbox);
            if (not AllCategoryMap[category.name]) then
                table.insert(AllCategoryList, #AllCategoryList + 1, category);
                AllCategoryMap[category.name] = category;
            end            
            for _, blockTypeNode in ipairs(categoryNode) do
                if (blockTypeNode.attr and blockTypeNode.attr.type) then
                    local blocktype = blockTypeNode.attr.type;
                    local hideInToolbox = blockTypeNode.attr.hideInToolbox == "true";
                    if (CategoryAndBlockMap.AllBlockMap[blocktype] or AllBlockMap[blocktype]) then
                        table.insert(category, {blocktype = blocktype, hideInToolbox = hideInToolbox});
                    end
                end
            end
        end
    end
    return AllCategoryList, AllCategoryMap;
end

function BlockManager.ParseToolBoxXmlText(xmlText, path)
    local AllCategoryList, AllCategoryMap = BlockManager.GetCategoryListAndMapByXmlText(xmlText, path);
    if (not AllCategoryList) then return end
    local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(path);
    CategoryAndBlockMap.AllCategoryList = AllCategoryList;
    CategoryAndBlockMap.AllCategoryMap = AllCategoryMap;
    BlockManager.SaveCategoryAndBlock(path);
    return AllCategoryList, AllCategoryMap;
end

function BlockManager.GetLanguageCategoryListAndMap(path)
    local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(path);
    if (#CategoryAndBlockMap.AllCategoryList > 0) then
        return CategoryAndBlockMap.AllCategoryList, CategoryAndBlockMap.AllCategoryMap;
    end

    local allCategoryMap, allBlockMap = CategoryAndBlockMap.AllCategoryMap, CategoryAndBlockMap.AllBlockMap;
    local categoryList = {};
    local categoryMap = {};
    for _, category in pairs(allCategoryMap) do
        local data = {
            name = category.name,
            text = category.text,
            color = category.color,
            blocktypes = {},
        }
        categoryMap[data.name] = data;
        table.insert(categoryList, data);
    end
    for block_type, block in pairs(allBlockMap) do 
        if (block_type ~= "") then
            local categoryName = block.category;
            local category = categoryMap[categoryName];
            if (not category) then
                category = {name = categoryName, blocktypes = {}}
                categoryMap[categoryName] = category;
                table.insert(categoryList, category);
            end
            table.insert(category.blocktypes, #(category.blocktypes) + 1, block_type);
        end
    end
    for _, category in ipairs(categoryList) do
        table.sort(category.blocktypes);
    end
    
    return categoryList, categoryMap;
end

function BlockManager.GetBlockOption(blockType, lang)
    local BlockMap = BlockManager.GetBlockMap(lang);
    if (BlockMap and BlockMap[blockType]) then return BlockMap[blockType] end
    
    for _, path in pairs(LanguagePathMap) do
        local BlockMap = BlockManager.GetLanguageBlockMap(path);
        if (BlockMap and BlockMap[blockType]) then return BlockMap[blockType] end
    end

    return nil;
end

function BlockManager.GetBlockMap(lang)
    if (LanguageConfig.IsSupportScratch(lang)) then return NplBlockManager.GetBlockMap(BlockManager, lang) end
    if (lang == "block") then return BlockBlockManager.GetBlockMap() end
    return AllBlockMap;
    -- if (LanguagePathMap[lang]) then return BlockManager.GetLanguageBlockMap(LanguagePathMap[lang]) end
    -- return BlockManager.GetLanguageBlockMap(WorldCategoryAndBlockPath);
end

function BlockManager.GetCategoryList(lang)
    if (LanguageConfig.IsSupportScratch(lang)) then return NplBlockManager.GetCategoryList(BlockManager, lang) end
    if (lang == "block") then return BlockBlockManager.GetCategoryList() end
    return {};
end

function BlockManager.GetCategoryListAndMap(lang)
    if (LanguageConfig.IsSupportScratch(lang)) then return NplBlockManager.GetCategoryListAndMap(BlockManager, lang) end
    if (lang == "block") then return BlockBlockManager.GetCategoryListAndMap() end
    if (LanguagePathMap[lang]) then return BlockManager.GetLanguageCategoryListAndMap(LanguagePathMap[lang]) end
    return BlockManager.GetLanguageCategoryListAndMap(WorldCategoryAndBlockPath);
end

BlockManager.StaticInit();
