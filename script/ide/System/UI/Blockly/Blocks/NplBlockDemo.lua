--[[
Title: NplBlock
Author(s): wxa
Date: 2021/3/1
Desc: Lua
use the lib:
-------------------------------------------------------
local NplBlockDemo = NPL.load("script/ide/System/UI/Blockly/Blocks/NplBlockDemo.lua");
-------------------------------------------------------
]]

local NplBlockDemo = NPL.export();

local all_categorie_list = {
	{
		name = "xxx",
		text = "xxx",
		color = "#000000",
		blocktypes = {"blocktype", "blocktype"},
	}
}

local all_block_list = {
	{
		type = "xxx",
		message = "%1 %2",
		arg = {
			{
				name = "field_name",
				type = "input_value", -- "input_value_list", "field_input"
				-- shadowType = ""
				text = ""
			}, 
			{

			}
		},
		output = false,
		previousStatement = true,
		nextStatement = true,
		code_description = [[]],
		-- ToCode = function(block) 
		-- end
	}
}

function NplBlockDemo.GetBlockMap()
    local all_block_map = {};
    for _, block in ipairs(all_block_list) do
        all_block_map[block.type] = block;
    end
	return all_block_map;
end

function NplBlockDemo.GetCategoryListAndMap()
    local all_categorie_map = {};
    for _, category in ipairs(all_categorie_list) do
        all_categorie_map[category.name] = category;
    end
	return all_categorie_list, all_categorie_map;
end