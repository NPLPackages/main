--[[
-------------------------------------------------------
local LoadCustomBlock = NPL.load("script/ide/System/UI/Blockly/Pages/LoadCustomBlock.lua");
-------------------------------------------------------
]] 

NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/EntityManager.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/FindBlockTask.lua");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local ItemClient = commonlib.gettable("MyCompany.Aries.Game.Items.ItemClient");
local FindBlockTask = commonlib.gettable("MyCompany.Aries.Game.Tasks.FindBlockTask");
local BlockManager = NPL.load("script/ide/System/UI/Blockly/Blocks/BlockManager.lua");
local Page = NPL.load("script/ide/System/UI/Page.lua");
local LoadCustomBlock = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

function LoadCustomBlock.FindAll()
    local entities = EntityManager.FindEntities({category = "b", type = "EntityCode"});
    local current_entity = LoadCustomBlock.entity;
    if (not entities or not current_entity) then return end
    local current_language = current_entity:GetLanguageConfigFile();
    local index = 1;
    local resultDS = {};    
    local results = {};
    for i, entity in ipairs(entities) do
        local name = entity:GetDisplayName() or "";
        local language = entity:GetLanguageConfigFile();
        local custom_block_text = type(entity.GetCustomBlockText) == "function" and entity:GetCustomBlockText() or "";
        local block_list = LoadCustomBlock.LoadEntityCustomBlockList(entity)
        local bx, by, bz = entity:GetBlockPos();
        local block_pos_name = tostring(bx) .. "_" .. tostring(by) .. "_" .. tostring(bz);
        name = name:gsub("\r?\n", " ")
        name = name == "" and block_pos_name or (block_pos_name .. "_" .. name);
        if (current_language == language and custom_block_text ~= "" and (#block_list) > 0) then
            resultDS[index] = {type = "block", index = index, name = name, lowerText = string.lower(name)};
            results[index] = entity;
            index = index + 1;
        end
    end
    LoadCustomBlock.resultDS = resultDS;
    LoadCustomBlock.results = results;
end

function LoadCustomBlock.FilterResult(text)
    if (text and text ~= "") then
        text = string.lower(text);
        local resultFiltered = {};
        for i, result in ipairs(LoadCustomBlock.resultDS) do if (result.lowerText:find(text, 1, true)) then resultFiltered[#resultFiltered + 1] = result; end end
        LoadCustomBlock.filteredResultDS = resultFiltered;
    else
        LoadCustomBlock.filteredResultDS = nil;
    end
    LoadCustomBlock.page:GetG().RefreshFileList();
end

function LoadCustomBlock.LoadEntityCustomBlock(entity)
    if (not entity or not entity.GetCustomBlockText) then return end
    local filepath = BlockManager.GetCustomCurrentBlockPath(entity);
    local text = entity:GetCustomBlockText();
    return BlockManager.LoadCategoryAndBlockFromText(text, filepath);
end

function LoadCustomBlock.LoadEntityCustomBlockList(entity)
    local CategoryAndBlockMap = LoadCustomBlock.LoadEntityCustomBlock(entity);
    local allBlockMap = CategoryAndBlockMap.AllBlockMap;
    local allCategoryMap = CategoryAndBlockMap.AllCategoryMap;
    local all_block_map = {};
    local block_list = {};
    for block_type, block in pairs(allBlockMap) do
        local category = allCategoryMap[block.category] or {};
        block.color = block.color or category.color;
        block_list[#block_list + 1] = block_type;
        all_block_map[block_type] = block;
    end
    return block_list, all_block_map;
end

function LoadCustomBlock.OnClickEdit()
	local BlockManager = NPL.load("script/ide/System/UI/Blockly/Blocks/BlockManager.lua");
	BlockManager.LoadCustomCurrentBlockEntity();
	local Page = NPL.load("script/ide/System/UI/Page.lua");
	Page.Show({
		BlockManager = BlockManager,
	}, {
		-- draggable = false,
		draggable = true,
		width = 1200,
		height = 800,
		alignment="_mt",
		url = "%ui%/Blockly/Pages/BlocklyFactory.html",
	});    
end

function LoadCustomBlock.OnClickImport()
	local KeepWorkMallPage = NPL.load("(gl)script/apps/Aries/Creator/Game/KeepWork/KeepWorkMallPageV2.lua");
	if not KeepWorkMallPage.isOpen then
		KeepWorkMallPage.Show(true);
	else
		KeepWorkMallPage.Close()
	end
end

function LoadCustomBlock.OnClickOK(index_map, index_block_map)
    local is_updated = false;
    local dst_entity = LoadCustomBlock.entity;
    if (not dst_entity or not dst_entity.GetCustomBlockText) then return end
    local dst_filepath = BlockManager.GetCustomCurrentBlockPath(dst_entity);
    local dst_all_block_map = BlockManager.LoadCategoryAndBlockFromText(dst_entity:GetCustomBlockText(), dst_filepath).AllBlockMap;
    for index, checked in pairs(index_map) do
        if (checked) then
            local entity = LoadCustomBlock.results[index];
            local checked_block_map = index_block_map[index];
            if (entity) then
                local src_filepath = BlockManager.GetCustomCurrentBlockPath(entity);
                local src_all_block_map = BlockManager.LoadCategoryAndBlockFromText(entity:GetCustomBlockText(), src_filepath).AllBlockMap;
                for block_type, block_option in pairs(src_all_block_map) do
                    if (checked_block_map[block_type]) then
                        is_updated = true;
                        dst_all_block_map[block_type] = block_option;
                        print("add block type:", block_type, "from:", index, "color: ", block_option.color);
                    end
                end
            end
        end
    end
    if (is_updated) then
        BlockManager.SaveCustomCureentBlockEntity(dst_entity);
        CodeBlockWindow.ShowNplBlocklyEditorPage();
    end
end

function LoadCustomBlock.Show()
    if (_G.LoadCustomBlockPage ~= nil) then _G.LoadCustomBlockPage:CloseWindow() end
    LoadCustomBlock.entity = CodeBlockWindow.GetCodeEntity();
    if (not LoadCustomBlock.entity) then return end
    -- mouse down 调用  mouse up 正好命中关闭按钮导致窗口关闭, 使用timeout跳过mouse up事件
    LoadCustomBlock.FindAll();
    commonlib.TimerManager.SetTimeout(function()  
        LoadCustomBlock.page = Page.Show({
            LoadCustomBlock = LoadCustomBlock,
            GetBlockListByIndex = function(index)
                local entity = LoadCustomBlock.results[index];
                return LoadCustomBlock.LoadEntityCustomBlockList(entity);
            end
        }, {url = "%ui%/Blockly/Pages/LoadCustomBlock.html", width = 600, height = 450, zorder = 1});
        _G.LoadCustomBlockPage = LoadCustomBlock.page;
    end, 200);
end
