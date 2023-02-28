--[[
Title: Vue
Author(s): wxa
Date: 2020/6/30
Desc: Lua
use the lib:
-------------------------------------------------------
local Blocks = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Blocks/Blocks.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/StyleColor.lua");
local StyleColor = commonlib.gettable("System.Windows.mcml.css.StyleColor");

local DataBlocks = NPL.load("./Data.lua", IsDevEnv);
local MathBlocks = NPL.load("./Math.lua", IsDevEnv);
local VarBlocks = NPL.load("./Var.lua", IsDevEnv);
local ControlBlocks = NPL.load("./Control.lua", IsDevEnv);
local EventBlocks = NPL.load("./Event.lua", IsDevEnv);
local LogBlocks = NPL.load("./Log.lua", IsDevEnv);
local HelperBlocks = NPL.load("./Helper.lua", IsDevEnv);


local VueToolbox = NPL.load("./VueToolbox.lua", IsDevEnv);
local NplToolbox = NPL.load("./NplToolbox.lua", IsDevEnv);
local BlockToolbox = NPL.load("./BlockToolbox.lua", IsDevEnv);
local BlockManager = NPL.load("./BlockManager.lua", IsDevEnv);

local Toolbox = NPL.export();

local Colors = {"#2E9BEF", "#76CE62", "#764BCC", "#EC522E", "#C38A3F", "#69B090", "#569138", "#459197"};
local AllBlocks = {};
local AllBlockMap = {};
local CategoryList = {
    {
        name = "数据",
        color = StyleColor.ConvertTo16("rgb(0,120,215)"),
        blocktypes = {}
    },
    {
        name = "运算",
        color = StyleColor.ConvertTo16("rgb(122,187,85)"),
        blocktypes = {}
    },
    {
        name = "控制",
        color = StyleColor.ConvertTo16("rgb(118,75,204)"),
        blocktypes = {}
    },
    {
        name = "事件",
        color = StyleColor.ConvertTo16("rgb(216,59,1)"),
        blocktypes = {}
    },
    {
        name = "辅助",
        color = StyleColor.ConvertTo16("rgb(143,109,64)"),
        blocktypes = {}
    },
}
local CategoryMap = {};

for _, category in ipairs(CategoryList) do
    CategoryMap[category.name] = category;
end

local function AddToAllBlocks(blocks, categoryName)
    local category = CategoryMap[categoryName];

    for _, block in ipairs(blocks) do
        if (category) then
            block.color = category.color;
            block.category = categoryName;
            table.insert(category.blocktypes, #(category.blocktypes) + 1, block.type);
        end

        table.insert(AllBlocks, #AllBlocks + 1, block);
        AllBlockMap[block.type] = block;
    end
end

AddToAllBlocks(VarBlocks, "数据");
AddToAllBlocks(DataBlocks, "数据");
AddToAllBlocks(MathBlocks, "运算");
AddToAllBlocks(ControlBlocks, "控制");
AddToAllBlocks(EventBlocks, "事件");
AddToAllBlocks(LogBlocks, "辅助");
AddToAllBlocks(HelperBlocks, "辅助");

function GetToolbox(typ)
    if (typ == "npl") then return NplToolbox end
    if (typ == "vue") then return VueToolbox end
    if (typ == "block") then return BlockToolbox end
    if (typ == "custom") then return BlockManager end 
    return nil;
end

function Toolbox.GetAllBlockList(typ)
    local toolbox = GetToolbox(typ);
    if (not toolbox) then return {}, {} end
    return toolbox.GetAllBlockList();
end

function Toolbox.GetAllCategoryList(typ, toolboxXmlText)
    local toolbox = GetToolbox(typ);
    if (not toolbox) then return {}, {} end
    local all_category_list, all_category_map = toolbox.GetAllCategoryList();
    
    if (toolboxXmlText and toolboxXmlText ~= "") then
        local all_blocks, all_block_map = Toolbox.GetAllBlockList(typ);
        return Toolbox.GetCategoryListByToolBoxXmlText(toolboxXmlText, all_blocks, all_block_map, all_category_list, all_category_map);
    end

    return all_category_list, all_category_map;
end

function Toolbox.GetCategoryListByToolBoxXmlText(toolboxXmlText, all_blocks, all_block_map, all_category_list, all_category_map)
    local xmlNode = ParaXML.LuaXML_ParseString(toolboxXmlText);
    local toolboxNode = xmlNode and commonlib.XPath.selectNode(xmlNode, "//toolbox");
    if (not toolboxNode) then return all_category_list, all_category_map end

    local category_list = {};
    for _, categoryNode in ipairs(toolboxNode) do
        if (categoryNode.attr and categoryNode.attr.name) then
            local category_attr = categoryNode.attr;
            local default_category = all_category_map[category_attr.name];
            local category = {
                name = category_attr.name,
                text = category_attr.text or (default_category and default_category.text),
                color = category_attr.color or (default_category and default_category.color),
                blocktypes = {},
            }
            table.insert(category_list, #category_list + 1, category);
            local blocktypes = category.blocktypes;
            for _, blockTypeNode in ipairs(categoryNode) do
                if (blockTypeNode.attr and blockTypeNode.attr.type) then
                    local blocktype = blockTypeNode.attr.type;
                    table.insert(blocktypes, #blocktypes + 1, blocktype);
                end
            end
            if (#blocktypes == 0) then table.remove(category_list, #category_list) end
        end
    end
    return category_list, all_category_map;
end

function Toolbox.GetBlockOption(blockType)
    return BlockManager.GetBlockOption(blockType);
end



    -- 导入旧npl blockly的分类列表
    -- local CategoryList = NplBlockManager.GetCategoryListAndMap();
    -- local CategoryAndBlockMap = BlockManager.GetCategoryAndBlockMap(LanguagePathMap["SystemNplBlock"]);
    -- local BlockMap = CategoryAndBlockMap.AllBlockMap;
    -- local AllCategoryList = {};
    -- for _, category in ipairs(CategoryList) do
    --     local blocktypes = {};
    --     local index = 1;
    --     for _, blocktype in ipairs(category.blocktypes) do
    --         blocktype = "NPL_" .. blocktype;
    --         if (BlockMap[blocktype]) then
    --             blocktypes[index] = blocktype;
    --             index = index + 1;
    --         end
    --     end
    --     category.blocktypes = blocktypes;
    --     table.insert(AllCategoryList, category);
    -- end
    -- echo(AllCategoryList, true);
    -- CategoryAndBlockMap.AllCategoryList = AllCategoryList;
    -- BlockManager.SaveCategoryAndBlock(LanguagePathMap["SystemNplBlock"]);