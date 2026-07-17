--[[
Title: BlockManager
Author(s): wxa
Date: 2020/6/30
Desc: 文件管理器
use the lib:
-------------------------------------------------------
local BlockManager = NPL.load("script/ide/System/UI/Blockly/Blocks/BlockManager.lua");
local AllBlockMap = BlockManager.GetBlockMap("CustomWorldBlock");
-- 代码定义图块
AllBlockMap["SetKeyValue"] = {
    type = "SetKeyValue",
    category = "Data",
    color = "#2E9BEF",
    output = false,
    previousStatement = true, 
    nextStatement = true,
    message = "设置表 %1 键 %2 值 %3",
    code_description = "${tablename}[$(key)]=${value};",
    arg = {
        { name="tablename", text="obj", type="field_input" },
        { name="key", text="key", type="field_input" },
        { name="value", shadowType="field_input", text="value", type="input_value" } 
      },
  }
-------------------------------------------------------
]]

local CommonLib = NPL.load("(gl)script/ide/System/Util/CommonLib.lua");
local Helper = NPL.load("../Helper.lua");

local NplBlockManager = NPL.load("./NplBlockManager.lua");
local BlockBlockManager = NPL.load("./BlockBlockManager.lua");
local SystemBlockDirectory = "script/ide/System/UI/BlocklyBlocks/";

local LanguagePathMap = {
    -- ["SystemLuaBlock"] = SystemBlockDirectory .. "SystemLuaBlock",
    ["SystemNplBlock"] = SystemBlockDirectory .. "SystemNplBlock",
    -- ["SystemUIBlock"] = SystemBlockDirectory .. "SystemUIBlock",
    ["SystemGIBlock"] = SystemBlockDirectory .. "SystemGIBlock",
}
local WorldCategoryAndBlockDirectory = "";
local WorldCategoryAndBlockPath = "";
local WorldAllCustomCurrentBlockCategoryAndBlockPath = "";
local CurrentCategoryAndBlockPath = "";
local CurrentLanguage = "";
local AllCategoryAndBlockMap = {};
local AllCategoryAndBlockMapTextCache = {};
local WorldAllCustomCurrentBlockCategoryAndBlockMapChange = false;
local AllBlockMap = {};
local inited = false;
local BlockManager = NPL.export();

function BlockManager.GetLanguagePath(lang, default_path)
    lang = lang or "CustomCurrentBlock";
    if (lang == "CustomCurrentBlock") then return BlockManager.GetCustomCurrentBlockPath() end
    if (lang == "CustomWorldBlock") then return WorldCategoryAndBlockPath end
    if (LanguagePathMap[lang]) then return LanguagePathMap[lang] end
    return default_path or CommonLib.ToCanonicalFilePath(WorldCategoryAndBlockDirectory .. "/" .. lang);
end

function BlockManager.SetCurrentCategoryAndBlockPath(path)
    CurrentCategoryAndBlockPath = path or WorldCategoryAndBlockPath;
end

function BlockManager.SetCurrentLanguage(lang)
    CurrentLanguage = lang or "";
    BlockManager.SetCurrentCategoryAndBlockPath(BlockManager.GetLanguagePath(CurrentLanguage));
end

function BlockManager.GetCurrentLanguage()
    return CurrentLanguage;
end

function BlockManager.GetCustomCureentBlockEntity()
    NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
    local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
    local entity = CodeBlockWindow.GetCodeEntity()
    return entity;
end

function BlockManager.GetCustomCurrentBlockPath(entity)
    entity = entity or BlockManager.GetCustomCureentBlockEntity();
    if (not entity) then return "CustomCurrentBlock" end
	local bx, by, bz = entity:GetBlockPos();
    return tostring(bx) .. "_" .. tostring(by) .. "_" .. tostring(bz);
end

function BlockManager.LoadCustomCurrentBlockEntity(entity)
    entity = entity or BlockManager.GetCustomCureentBlockEntity();
    local filepath = BlockManager.GetCustomCurrentBlockPath();
    if (not entity or not entity.GetCustomBlockText) then return end
    local text = entity:GetCustomBlockText();
    if (AllCategoryAndBlockMapTextCache[filepath] == text) then return end
    AllCategoryAndBlockMapTextCache[filepath] = text;
    local oldCurrentLanguage = BlockManager.GetCurrentLanguage();
    BlockManager.SetCurrentLanguage("CustomWorldBlock");
    BlockManager.LoadCategoryAndBlockFromText(text, filepath);
    BlockManager.SetCurrentLanguage(oldCurrentLanguage);
end

function BlockManager.SaveCustomCureentBlockEntity(entity)
    entity = entity or BlockManager.GetCustomCureentBlockEntity();
    if (entity and entity.SetCustomBlockText) then
        local CustomCategoryAndBlockMap = BlockManager.GetCustomCurrentBlockCategoryAndBlockMap(entity);
        entity:SetCustomBlockText(commonlib.serialize_compact(CustomCategoryAndBlockMap))
    end
end

function BlockManager.IsCustomLanguage(lang)
    if (lang == "CustomWorldBlock") then return true end 
    if (lang == "CustomCurrentBlock") then return true end 
    return LanguagePathMap[lang] and true or false;
end

function BlockManager.GetBlocklyDirectory()
    return CommonLib.ToCanonicalFilePath(CommonLib.GetWorldDirectory() .. "/blockly/");
end

function BlockManager.GetCategoryAndBlockMap(path)
    path = path or CurrentCategoryAndBlockPath;
    path = BlockManager.GetLanguagePath(path, path);

    if (not AllCategoryAndBlockMap[path]) then
        AllCategoryAndBlockMap[path] = {
            Key = path,
            AllCategoryList = {},
            AllCategoryMap = {},
            AllBlockMap = {},
            IsHideCategory = false,
            ToolBoxWidth = 300,
        };
        print("=================Load CategoryAndBlockMap: ".. path);
    end
    
    local pos = string.find(path, SystemBlockDirectory, 1, true);

    return AllCategoryAndBlockMap[path]; 
end

function BlockManager.GetCustomCurrentBlockCategoryAndBlockMap(entity)
    local path = BlockManager.GetCustomCurrentBlockPath(entity);
    if (not AllCategoryAndBlockMap[path]) then
        BlockManager.LoadCustomCurrentBlockEntity(entity);
    end
    return BlockManager.GetCategoryAndBlockMap(path);
end

function BlockManager.GetCustomCurrentBlockAllBlockMap()
    return BlockManager.GetCustomCurrentBlockCategoryAndBlockMap().AllBlockMap;
end

function BlockManager.GetCustomCurrentBlockAllCategoryMap()
    return BlockManager.GetCustomCurrentBlockCategoryAndBlockMap().AllCategoryMap;
end

function BlockManager.LoadWorldAllCustomCurrentBlockCategoryAndBlockMap()
    -- 先清掉上个世界的定制方块
    for key in pairs(AllCategoryAndBlockMapTextCache) do
        AllCategoryAndBlockMap[key] = nil;
    end
    AllCategoryAndBlockMapTextCache = {};

    local io = ParaIO.open(WorldAllCustomCurrentBlockCategoryAndBlockPath, "r");
    if(not io:IsValid()) then 
        return;
    end 
    local text = io:GetText();
    io:close();
    local tmpWorldAllCustomCurrentBlockCategoryAndBlockMap = NPL.LoadTableFromString(text);

    tmpWorldAllCustomCurrentBlockCategoryAndBlockMap = tmpWorldAllCustomCurrentBlockCategoryAndBlockMap or {};
    for key, CustomCategoryAndBlockMap in pairs(tmpWorldAllCustomCurrentBlockCategoryAndBlockMap) do
        local filename = string.match(key, "([^\\/]*)$");
        AllCategoryAndBlockMap[filename] = CustomCategoryAndBlockMap;
    end
    print("==============================BlockManager.LoadWorldAllCustomCurrentBlockCategoryAndBlockMap=====================================")
end

function BlockManager.SetWorldAllCustomCurrentBlockCategoryAndBlockMapChange(bChange)
    WorldAllCustomCurrentBlockCategoryAndBlockMapChange = bChange;
    BlockManager.SaveCustomCureentBlockEntity();
end

function BlockManager.SaveWorldAllCustomCurrentBlockCategoryAndBlockMap()
    if (not WorldAllCustomCurrentBlockCategoryAndBlockMapChange) then return end
    WorldAllCustomCurrentBlockCategoryAndBlockMapChange = false;
    -- 禁用文件存储
    -- if (true) then return end

    local allCustomCurrentBlockCategoryAndBlockMap = {};
    for key, categoryAndBlockMap in pairs(AllCategoryAndBlockMap) do
        if (AllCategoryAndBlockMapTextCache[key]) then
            allCustomCurrentBlockCategoryAndBlockMap[key] = categoryAndBlockMap;
        end
    end
    local io = ParaIO.open(WorldAllCustomCurrentBlockCategoryAndBlockPath, "w");
    io:WriteString(commonlib.serialize_compact(allCustomCurrentBlockCategoryAndBlockMap));
    io:close();
    print("==============================BlockManager.SaveWorldAllCustomCurrentBlockCategoryAndBlockMap=====================================")
end

function BlockManager.LoadCategoryAndBlockFromText(text, filename)
    local CategoryBlockMap = NPL.LoadTableFromString(text);
    CategoryBlockMap = type(CategoryBlockMap) == "table" and CategoryBlockMap or {};

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
    CategoryAndBlockMap.IsHideCategory = CategoryBlockMap.IsHideCategory;
    CategoryAndBlockMap.ToolBoxWidth = CategoryBlockMap.ToolBoxWidth;

    for blockType, blockOption in pairs(LangBlockMap) do
        AllBlockMap[blockType] = blockOption;
    end

    return CategoryAndBlockMap;
end

function BlockManager.LoadCategoryAndBlockFromFile(filename)
    filename = filename or CurrentCategoryAndBlockPath;

    local io = ParaIO.open(filename, "r");
    if(not io:IsValid()) then 
		io = ParaIO.open(filename..".table", "r");
		if(not io:IsValid()) then 
			print("file invalid: ", filename)
			return nil;
		end
    end 

    local text = io:GetText();
    io:close();

    return BlockManager.LoadCategoryAndBlockFromText(text, filename);
end

function BlockManager.SaveCategoryAndBlock(filename)
    -- 确保目存在
    ParaIO.CreateDirectory(BlockManager.GetBlocklyDirectory());

    filename = filename or CurrentCategoryAndBlockPath;
    local isNormalUserCustomSystemBlock = false;
	
	local diskFilename = filename;
    if (CurrentLanguage ~= "CustomWorldBlock" and CurrentLanguage ~= "CustomCurrentBlock") then
        for language, path in pairs(LanguagePathMap) do
            if (filename == path) then 
                local default_directory = ParaIO.GetWritablePath().."temp/blockly/";
                ParaIO.CreateDirectory(default_directory);
                diskFilename = default_directory .. language;
                break;
            end
        end
    end
    local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(filename);
    -- 重写全局 BlockMap
    for blockType, blockOption in pairs(CategoryAndBlockMap.AllBlockMap) do AllBlockMap[blockType] = blockOption end
    
    print("Save:", CurrentCategoryAndBlockPath, CategoryAndBlockMap.ToolBoxWidth, CategoryAndBlockMap.IsHideCategory)

    CategoryAndBlockMap.ToolBoxXmlText = BlockManager.GenerateToolBoxXmlText(filename);
    if (CurrentLanguage == "CustomCurrentBlock") then 
        -- 将所有方块各自定义再保存一份到文件
        BlockManager.SetWorldAllCustomCurrentBlockCategoryAndBlockMapChange(true)
        BlockManager.SaveWorldAllCustomCurrentBlockCategoryAndBlockMap();
    else
        local text = commonlib.serialize_compact(CategoryAndBlockMap);
        local io = ParaIO.open(diskFilename, "w");
        io:WriteString(text);
        io:close();
    end
    if (not isNormalUserCustomSystemBlock) then GameLogic.AddBBS("Blockly", "图块更改已保存") end
end

function BlockManager.NewBlock(block)
    if (not block.type) then return end
    local allBlockMap = BlockManager.GetLanguageBlockMap();
    allBlockMap[block.type] = {
        type = block.type,
        category = block.category,
        color = block.color,
        group = block.group,
        hideInToolbox = block.hideInToolbox,
        output = block.output,
        previousStatement = block.previousStatement,
        nextStatement = block.nextStatement,
        message = block.message,
        arg = block.arg,
        code_description = block.code_description,
        xml_text = block.xml_text,
        folded_xml_text = block.folded_xml_text,
        is_folded = block.is_folded,
        is_folded_draggable = block.is_folded_draggable,
        code = block.code,
        headerText = block.headerText,
        headers = block.headers,
    };
    for key, value in pairs(block) do
        if (string.find(key, "code_description_", 1, true) == 1) then
            allBlockMap[block.type][key] = block[key];
        end
    end
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
    if (directory == WorldCategoryAndBlockDirectory) then return end
    WorldCategoryAndBlockDirectory = directory;
    WorldCategoryAndBlockPath = CommonLib.ToCanonicalFilePath(directory .. "/CustomWorldBlock");
    WorldAllCustomCurrentBlockCategoryAndBlockPath = CommonLib.ToCanonicalFilePath(directory .. "/CustomWorldAllCurrentBlock");
    CurrentCategoryAndBlockPath = WorldCategoryAndBlockPath;
    
    -- 确保目存在
    -- ParaIO.CreateDirectory(directory);
    -- 加载定制世界块
    BlockManager.LoadCategoryAndBlockFromFile(CurrentCategoryAndBlockPath);
    -- 加载定制世界所有当前块
    BlockManager.LoadWorldAllCustomCurrentBlockCategoryAndBlockMap();
end

local function OnWorldUnloaded()
end

function BlockManager.StaticInit()
    if (inited) then return BlockManager end
    inited = true;

    for _, path in pairs(LanguagePathMap) do
        BlockManager.LoadCategoryAndBlockFromFile(path);
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
    for _, CategoryAndBlockMap in pairs(AllCategoryAndBlockMap) do
        local BlockMap = CategoryAndBlockMap.AllBlockMap;
        if (BlockMap and BlockMap[blockType]) then 
            local block = commonlib.deepcopy(BlockMap[blockType]);
            local category = CategoryAndBlockMap.AllCategoryMap[block.category] or {};
            block.color = block.color or category.color;
            return block;
        end
    end
    return nil;
end

function BlockManager.GetSystemBlockOption(blockType)
    for _, path in pairs(LanguagePathMap) do
        local CategoryAndBlockMap = AllCategoryAndBlockMap[path];
        if (CategoryAndBlockMap and CategoryAndBlockMap.AllBlockMap[blockType]) then 
            local block = commonlib.deepcopy(CategoryAndBlockMap.AllBlockMap[blockType]);
            local category = CategoryAndBlockMap.AllCategoryMap[block.category] or {};
            block.color = block.color or category.color;
            return block;
        end
    end
end

local LanguageConfig
function BlockManager.GetLanguageConfig()
    LanguageConfig = LanguageConfig or NPL.load("script/ide/System/UI/Blockly/Blocks/LanguageConfig.lua");
    return LanguageConfig
end

function BlockManager.GetBlockMap(lang)
    if (BlockManager.GetLanguageConfig():IsSupportScratch(lang)) then return NplBlockManager.GetBlockMap(BlockManager, lang) end
    if (lang == "block") then return BlockBlockManager.GetBlockMap() end
    local nplBlockMap = NplBlockManager.GetBlockMap(BlockManager, lang);
    for key, value in pairs(nplBlockMap or {}) do AllBlockMap[key] = value end
    local blockMap = BlockManager.GetLanguageBlockMap(lang);
    for key, value in pairs(blockMap) do AllBlockMap[key] = value end
    return LanguagePathMap[lang] and blockMap or AllBlockMap;
end

function BlockManager.GetCategoryList(lang)
    if (BlockManager.GetLanguageConfig():IsSupportScratch(lang)) then return NplBlockManager.GetCategoryList(BlockManager, lang) end
    if (lang == "block") then return BlockBlockManager.GetCategoryList() end
    return {};
end

function BlockManager.GetCategoryListAndMap(lang)
    if (BlockManager.GetLanguageConfig():IsSupportScratch(lang)) then return NplBlockManager.GetCategoryListAndMap(BlockManager, lang) end
    if (lang == "block") then return BlockBlockManager.GetCategoryListAndMap() end
    return BlockManager.GetLanguageCategoryListAndMap(BlockManager.GetLanguagePath(lang));
end

function BlockManager.IsHideCategory(lang)
    return BlockManager.GetCustomCurrentBlockCategoryAndBlockMap().IsHideCategory;
    -- local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(BlockManager.GetLanguagePath(lang));
    -- print("BlockManager.IsHideCategory:", CategoryAndBlockMap.Key, CategoryAndBlockMap.IsHideCategory, type(CategoryAndBlockMap.IsHideCategory));
    -- return CategoryAndBlockMap.IsHideCategory;
end

function BlockManager.GetToolBoxWidth(lang)
    return BlockManager.GetCustomCurrentBlockCategoryAndBlockMap().ToolBoxWidth or 300;
    -- local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(BlockManager.GetLanguagePath(lang));
    -- print("BlockManager.GetToolBoxWidth:", CategoryAndBlockMap.Key, CategoryAndBlockMap.ToolBoxWidth);
    -- return CategoryAndBlockMap.ToolBoxWidth or 300;
end

BlockManager.StaticInit();
