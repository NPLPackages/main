--[[
Title: NplToolbox
Author(s): wxa
Date: 2021/3/1
Desc: Lua
use the lib:
-------------------------------------------------------
local NplToolbox = NPL.load("script/ide/System/UI/Blockly/Blocks/NplToolbox.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpWindow.lua");
local CodeHelpWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow");

-- local GIBlockly = NPL.load("Mod/GeneralGameServerMod/GI/Independent/GIBlockly.lua");

local NplBlockMCML = NPL.load("./NplBlockMCML.lua");
local NplBlockCad = NPL.load("./NplBlockCad.lua");

local NplBlockManager = NPL.export();

local BlockManager = nil;
local all_blocks_cache = {};
local all_block_map_cache = {};
local all_category_list_cache = {};
local all_category_map_cache = {};

local function GetAllBlocksAndCategoryList(all_cmds, all_categories, lang)
    local key = tostring(lang) .. "_" .. tostring(all_cmds) .. "_" .. tostring(all_categories);
    if (all_blocks_cache[key]) then return all_blocks_cache[key], all_category_list_cache[key], all_block_map_cache[key], all_category_map_cache[key] end

    local CategoryList = {};  -- 分类列表
    local CategoryMap = {};   -- 分类MAP
    local AllBlocks = {};     -- 所有块列表
    local AllBlockMap = {};

    for index, category in ipairs(all_categories) do
        table.insert(CategoryList, index, {
            name = category.name,
            text = category.text,
            color = category.colour,
            blocktypes = {},
        });
        CategoryMap[CategoryList[index].name] = CategoryList[index];
    end
    
    local function format_field_type(args)
        if (not args) then return end
        for _, arg in ipairs(args) do
            if (arg.type == "colour_picker") then arg.type = "field_color" end
            if (type(arg.shadow) == "table" and arg.shadow.type == "colour_picker") then arg.shadow.type = "field_color" end 
            if (type(arg.shadow) == "table" and arg.shadow.type == "functionParams") then arg.text, arg.shadow.value = "", "" end 
        end
    end

    local cmd_count = #all_cmds;
    for i = 1, cmd_count do
        local cmd = all_cmds[i];
        local category = CategoryMap[cmd.category];
        if (category) then
            -- if (not cmd.func_description) then echo(cmd) end
            local func_description = string.gsub(cmd.func_description or "", "\\n", "\n");
            func_description = string.gsub(func_description, "%%d", "%%s");
            local block = {
                isScratchBlock = true;
                color = category and category.color;
                category = cmd.category;
                message = cmd.message,
                arg = commonlib.deepcopy(cmd.arg),
                previousStatement = cmd.previousStatement and true or false,
                nextStatement = cmd.nextStatement and true or false,
                output = cmd.output and true or false,
                type = cmd.type,
                code = cmd.code,
                code_description = cmd.code_description,
                headerText = cmd.headerText,
                topython = cmd.ToPython,
                tomicropython = cmd.ToMicroPython,
                toarduino = cmd.ToArduino or cmd.ToCpp,
                tocpp = cmd.ToCpp,
                ToCode = cmd.ToCode or function(block, DefaultToCode)
                    if (cmd.code_description) then return DefaultToCode(block) end
                    if (not cmd.func_description) then return cmd.ToNPL(block) end

                    local args = {};
                    local index = 1;
                    for i, opt in ipairs(block.inputFieldOptionList) do
                        if (opt.type ~= "input_dummy") then
                            if (opt.type == "input_value" or opt.type == "input_statement") then
                                args[index] = block:GetValueAsString(opt.name) or "";
                            else 
                                args[index] = block:GetFieldValue(opt.name) or "";
                            end
                            index = index + 1;
                        end
                    end
                    return string.format(func_description, unpack(args));
                end,
                tocpp = cmd.ToCpp,
                PostProcess = cmd.PostProcess,
                hideInToolbox = cmd.hide_in_toolbox,
                hideInBlockly = cmd.hide_in_blockly,
            } 
            if (block.previousStatement or block.nextStatement) then block.output = false end
            if (block.previousStatement or block.nextStatement) then func_description = func_description .. "\n" end 
            format_field_type(block.arg);
            for i = 0, 10 do
                local messageName = "message" .. tostring(i);
                local argName = "arg" .. tostring(i);
                if (not cmd[messageName]) then break end
                block[messageName] = cmd[messageName];
                block[argName] = commonlib.deepcopy(cmd[argName]);
                format_field_type(block[argName]);
            end
        
            if (not block.hideInToolbox and not block.hideInBlockly) then
                table.insert(category.blocktypes, #(category.blocktypes) + 1, block.type);
            end
            table.insert(AllBlocks, #AllBlocks + 1, block);
            AllBlockMap[block.type] = block;
        end
    end

    all_blocks_cache[key], all_category_list_cache[key] = AllBlocks, CategoryList;
    all_block_map_cache[key], all_category_map_cache[key] = AllBlockMap, CategoryMap;
    return AllBlocks, CategoryList, AllBlockMap, CategoryMap;
end

function NplBlockManager.IsNplLanguage(lang)
    if (CodeHelpWindow.codeLanguageType == "python") then return false end 
    return CodeHelpWindow.GetLanguageConfigFile() == "npl" or CodeHelpWindow.GetLanguageConfigFile() == "" or CodeHelpWindow.GetLanguageConfigFile() == "npl_junior" or CodeHelpWindow.GetLanguageConfigFile() == "codeblock";
end

function NplBlockManager.IsMcmlLanguage(lang)
    return CodeHelpWindow.GetLanguageConfigFile() == "mcml" or CodeHelpWindow.GetLanguageConfigFile() == "html";
end

function NplBlockManager.IsCadLanguage(lang)
    if (lang == "old_npl_cad" or lang == "old_cad") then return false end   -- 使用程序自动转换
    return string.lower(CodeHelpWindow.GetLanguageConfigFile()) == "cad" or string.lower(CodeHelpWindow.GetLanguageConfigFile()) == "npl_cad";
end

function NplBlockManager.IsGILanguage(lang)
    return CodeHelpWindow.GetLanguageConfigFile() == "game_inventor";
end

function NplBlockManager.GetMcmlBlockMap()
    return NplBlockMCML.GetBlockMap();
    -- return BlockManager.GetLanguageBlockMap("SystemUIBlock");
end

function NplBlockManager.GetMcmlCategoryListAndMap()
    return NplBlockMCML.GetCategoryListAndMap();
--     return BlockManager.GetCategoryListAndMapByXmlText([[
-- <toolbox>
--     <category name="元素" color="#2E9BEF">
--         <block type="UI_MCML_Elements"/>
--         <block type="UI_MCML_Element"/>
--         <block type="UI_Element_Text"/>
--     </category>
--     <category name="窗口" color="#EC522E">
--         <block type="UI_Window_Show_Html"/>
--     </category>
-- </toolbox>    
--     ]],"SystemUIBlock");
end

function NplBlockManager.GetCadBlockMap()
    return NplBlockCad.GetBlockMap();
end

function NplBlockManager.GetCadCategoryListAndMap()
    return NplBlockCad.GetCategoryListAndMap();
end

function NplBlockManager.GetNplBlockMap()
    return BlockManager.GetLanguageBlockMap("SystemNplBlock");
end

function NplBlockManager.GetNplCategoryListAndMap()
    return BlockManager.GetLanguageCategoryListAndMap("SystemNplBlock");
end

function NplBlockManager.GetGIBlockMap()
    return BlockManager.GetLanguageBlockMap("SystemGIBlock");
end

function NplBlockManager.GetGICategoryListAndMap()
    return BlockManager.GetLanguageCategoryListAndMap("SystemGIBlock");
end

function NplBlockManager.GetBlockMap(blockManager, lang)
    BlockManager = blockManager;
    if (NplBlockManager.IsNplLanguage(lang)) then return NplBlockManager.GetNplBlockMap() end
    if (NplBlockManager.IsMcmlLanguage(lang)) then return NplBlockManager.GetMcmlBlockMap() end
    if (NplBlockManager.IsGILanguage(lang)) then return NplBlockManager.GetGIBlockMap() end 
    if (NplBlockManager.IsCadLanguage(lang)) then return NplBlockManager.GetCadBlockMap() end
   
    local all_cmds = CodeHelpWindow.GetAllCmds();
    local all_categories = CodeHelpWindow.GetCategoryButtons();

    -- if (IsDevEnv and NplBlockManager.IsGILanguage()) then
    --     all_cmds = GIBlockly.GetAllCmds();
    --     all_categories = GIBlockly.GetCategoryButtons();
    -- end

    local AllBlocks, CategoryList, AllBlockMap, AllCategoryMap = GetAllBlocksAndCategoryList(all_cmds, all_categories, lang);
    return AllBlockMap;
end

function NplBlockManager.GetCategoryList(blockManager)
    local _, AllCategoryList = NplBlockManager.GetCategoryListAndMap(blockManager);
    return AllCategoryList;
end

function NplBlockManager.GetCategoryListAndMap(blockManager, lang)
    BlockManager = blockManager;
    if (NplBlockManager.IsNplLanguage(lang)) then return NplBlockManager.GetNplCategoryListAndMap() end
    if (NplBlockManager.IsMcmlLanguage(lang)) then return NplBlockManager.GetMcmlCategoryListAndMap() end
    if (NplBlockManager.IsGILanguage(lang)) then return NplBlockManager.GetGICategoryListAndMap() end 
    if (NplBlockManager.IsCadLanguage(lang)) then return NplBlockManager.GetCadCategoryListAndMap() end

    local all_cmds = CodeHelpWindow.GetAllCmds();
    local all_categories = CodeHelpWindow.GetCategoryButtons();
    
    -- if (IsDevEnv and NplBlockManager.IsGILanguage()) then
    --     all_cmds = GIBlockly.GetAllCmds();
    --     all_categories = GIBlockly.GetCategoryButtons();
    -- end

    local AllBlocks, CategoryList, AllBlockMap, AllCategoryMap = GetAllBlocksAndCategoryList(all_cmds, all_categories, lang);
    return CategoryList, AllCategoryMap;
end

