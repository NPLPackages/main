--[[
Title: GoogleNplBlockly
Author(s): wxa
-------------------------------------------------------
local GoogleNplBlockly = NPL.load("script/ide/System/UI/Blockly/GoogleNplBlockly.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/Json.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeHelpWindow.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Code/CodeBlockWindow.lua");
local CodeBlockWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeBlockWindow");
local CodeHelpWindow = commonlib.gettable("MyCompany.Aries.Game.Code.CodeHelpWindow");
local EntityManager = commonlib.gettable("MyCompany.Aries.Game.EntityManager");
local NPLJS = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/NPLJS.lua");
local Options = NPL.load("script/ide/System/UI/Blockly/Options.lua");
local Color = commonlib.gettable("System.Core.Color");
local GoogleNplBlockly = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

function GoogleNplBlockly:NplArgTypeToGoogleArgType(argType)
    if (argType == "input_value") then
        return "input_value";
    elseif (argType == "input_statement") then
        return "input_statement";
    elseif (argType == "field_dropdown") then
        return "field_dropdown";
    -- elseif (argType == "field_input" or argType == "field_number" or argType == "field_password" or argType == "field_text") then
    --     return "field_input";
    else
        return "field_input";
    end
end

function GoogleNplBlockly:NplDropdownOptionsToGoogleDropdownOptions(options)
    if (type(options) == "string") then
        local extend_options = Options[options];
        if (type(extend_options) == "function") then options = extend_options() end
        if (type(extend_options) == "table") then options = extend_options end
    end

    if (type(options) ~= "table" or not next(options)) then return nil end
    local google_options = {};
    for _, option in ipairs(options) do
        local google_option = {};
        google_option[#google_option + 1] = tostring(option.label or option[1]);
        google_option[#google_option + 1] = tostring(option.value or option[2]);
        google_options[#google_options + 1] = google_option;
    end

    if (not next(google_options)) then return nil end
    return google_options;
end

function GoogleNplBlockly:NplColorToGoogleColor(color)
    local r,g,b,a = string.match(color or "", "(%x%x)(%x%x)(%x%x)(%x?%x?)");
    if (not r) then return 0 end

    r = tonumber(r, 16);
    g = tonumber(g, 16);
    b = tonumber(b, 16);
    r = math.max(math.min(r, 255), 0);
    g = math.max(math.min(g, 255), 0);
    b = math.max(math.min(b, 255), 0);
    
    local h, s, l = Color.rgb2hsl(r, g, b);
    return math.floor(h * 360), math.floor(s * 100), math.floor(l * 100);
end

function GoogleNplBlockly:NplBlockOptionToGoogleBlockOption(option)
    local message_index = 0;
    local function GetMessageArg()
        if (option.message) then
            if (message_index ~= 0) then return nil, nil end
            message_index = 1;
            return option.message, option.arg;
        end
    
        local messageIndex, argIndex, argsIndex = "message" .. tostring(message_index), "arg" .. tostring(message_index), "args" .. tostring(message_index);
        local message, arg = option[messageIndex], option[argIndex] or option[argsIndex];
        message_index = message_index + 1;
        return message, arg;
    end

    local google_option = { 
        inputsInline = true, 
        type = option.type, 
        output = option.output,
        previousStatement = option.previousStatement,
        nextStatement = option.nextStatement,
        tooltip = "", 
        helpUrl = "", 
        colour = self:NplColorToGoogleColor(option.color) 
    };
    
    local google_extend_options = {}
    local message, arg = GetMessageArg();
    while (message) do
        message = string.gsub(message, "%%(%d+)", " %%%1 ");
        local google_message, google_arg, google_arg_index = "", {}, 1;
        for word in message:gmatch("%S+") do
            if (word:sub(1, 1) == "%") then
                local arg_index = tonumber(word:sub(2));
                local index_arg = arg[arg_index];
                if (not index_arg or not index_arg.name) then 
                    if (option.type == "oled.DispChar") then
                        print("invalid options:", word, arg_index, message);
                        echo(option, true)
                    end
                    return 
                end
                local google_arg_type = self:NplArgTypeToGoogleArgType(index_arg.type);
                local dropdown_options = self:NplDropdownOptionsToGoogleDropdownOptions(index_arg.options);
                if (google_arg_type == "field_dropdown" and not dropdown_options) then google_arg_type = "field_input" end
                google_message = google_message .. " %" .. tostring(google_arg_index);
                google_arg[google_arg_index] = {name = index_arg.name, type = google_arg_type, options = dropdown_options};
                google_arg_index = google_arg_index + 1;
                -- if (google_arg_type ~= "input_value" and google_arg_type ~= "input_statement") then
                --     google_message = google_message .. " %" .. tostring(google_arg_index);
                --     google_arg[google_arg_index] = {type = "input_dummy"};
                --     google_arg_index = google_arg_index + 1;
                -- end

                local shadow_type = index_arg.shadowType or (index_arg.shadow and index_arg.shadow.type) or "";
                local is_dropdown = shadow_type == "field_dropdown" or shadow_type == "field_select" or shadow_type == "select";
                if (google_arg_type == "input_value" and is_dropdown and dropdown_options) then
                    google_extend_options[#google_extend_options + 1] = {
                        type = index_arg.name .. "Options",
                        tooltip = "", 
                        helpUrl = "",   
                        message0 = "%1 %2",
                        args0 = {
                            {
                                type = "field_dropdown",
                                name = "TEXT",
                                options = dropdown_options
                            },
                            {
                                type = "input_dummy",
                            }
                        },
                        output = true,
                        colour = google_option.colour
                    }
                end
            else 
                google_message = google_message .. (google_message == "" and "" or " ") .. word;
                google_message = google_message .. " %" .. tostring(google_arg_index);
                google_arg[google_arg_index] = {type = "input_dummy"};
                google_arg_index = google_arg_index + 1;
            end
        end 
        google_option["message" .. tostring(message_index - 1)] = google_message;
        google_option["args" .. tostring(message_index - 1)] = google_arg;
        message, arg = GetMessageArg();
    end
    return google_option, google_extend_options;
end

function GoogleNplBlockly:NplBlockOptionListToGoogleBlockOptionList(option_list)
    local google_option_list = {};
    local google_option_map = {};
    for _, option in pairs(option_list) do
        local npl_option = option.GetOption and option:GetOption() or option;
        if (not google_option_map[npl_option.type]) then
            local google_option, google_extend_options = self:NplBlockOptionToGoogleBlockOption(npl_option);
            if (google_option and google_extend_options) then
                google_option_list[#google_option_list + 1] = google_option;
                google_option_map[npl_option.type] = true;
                for _, extend_option in ipairs(google_extend_options) do
                    if (not google_option_map[extend_option.type]) then
                        google_option_list[#google_option_list + 1] = extend_option;
                        google_option_map[extend_option.type] = true;                    
                    end
                end
            end
        end
    end
    return google_option_list;
end

function GoogleNplBlockly:NplBlockXmlToGoogleBlockXml(block_xml, block_options)

end

function GoogleNplBlockly:NplToolBoxToGoogleToolBox(toolbox_xml, block_options)
    local root = ParaXML.LuaXML_ParseString(toolbox_xml);
    local toolbox = root and commonlib.XPath.selectNode(root, "//toolbox");
    if (not toolbox) then return end
    local function get_block_xml_node(block_option)
        if (not block_option) then return end
        local xml_node = {name = "block", attr = {type = block_option.type}};
        for _, arg in ipairs(block_option.arg or block_option.args) do
            if (arg.type == "input_value") then
                if (arg.shadowType == "field_input") then
                    xml_node[#xml_node + 1] = {name = "value", attr = {name = arg.name}, [1] = { { name = "block", attr = {type = "text"},  { name = "field", attr = {name = "TEXT"}, [1] = arg.text }}} };
                elseif (arg.shadowType == "field_number") then
                    xml_node[#xml_node + 1] = {name = "value", attr = {name = arg.name}, [1] = { { name = "block", attr = {type = "math_number"},  { name = "field", attr = {name = "NUM"}, [1] = arg.text }}} };
                else
                    local shadow_block_option = block_options[arg.shadowType];
                    local shadow_block_xml_node = get_block_xml_node(shadow_block_option);
                    if (shadow_block_xml_node) then
                        xml_node[#xml_node + 1] = {name = "value", attr = {name = arg.name}, [1] = shadow_block_xml_node };
                    end
                end
            end
        end  
        return xml_node;      
    end

    local toolbox_block_options = {};
    local google_toolbox = { name = "xml", attr = {xmlns="https://developers.google.com/blockly/xml", id="toolbox", style="display: none"} };
    for _, category in ipairs(toolbox) do
        local category_attr = category.attr or {};
        local google_category = { name = "category", attr = {} };
        google_category.attr.name = category_attr.label or category_attr.text or category_attr.name;
        google_category.attr.colour = category_attr.color;
        google_toolbox[#google_toolbox + 1] = google_category;

        for _, block in ipairs(category) do
            local block_type = block.attr.type;
            local block_option = block_options[block_type];
            local google_block = get_block_xml_node(block_option);
            google_category[#google_category + 1] = google_block;
            toolbox_block_options[block_type] = block_option;
        end
    end

    return commonlib.Lua2XmlString(google_toolbox, true), toolbox_block_options;
end

function GoogleNplBlockly:NplWorksapceToGoogleWorkspace(workspace)
    return {
        blocks = {
            blocks = next(workspace.blocks) and workspace.blocks or nil,
            languageVersion = 0,
        }
    }
end

function GoogleNplBlockly:GoogleWorkspaceToNplWorksapce(workspace)
    return {
        blocks = workspace.blocks.blocks,
    }
end

function GoogleNplBlockly:GenerateGoogleToolBoxJson(blockly, blocks)
    local google_toolbox = {kind = "categoryToolbox", contents = {}};
    local google_category_list = google_toolbox.contents;

    local category_list = blockly:GetToolBox():GetCategoryList();
    for _, category_item in ipairs(category_list) do
        local google_category = {
            kind = "category",
            name = category_item.label or category_item.text or category_item.name,
            colour = category_item.color or category_item.colour,
            contents = {}
        }
        local google_category_blocks = google_category.contents;

        for _, blocktype in ipairs(category_item.blocktypes) do 
            local block = blocks[blocktype] and blockly:GetBlockInstanceByType(blocktype);
            if (block) then
                local block_state = block:Save();
                local google_block = {
                    kind = "block",
                    type = block_state.type,
                    fields = next(block_state.fields) and block_state.fields or nil,
                    inputs = next(block_state.inputs) and block_state.inputs or nil,
                }
                google_category_blocks[#google_category_blocks + 1] = google_block;
            end
        end
        if (#google_category_blocks > 0) then 
            google_category_list[#google_category_list + 1] = google_category;
        end
    end

    -- google_category_list[#google_category_list + 1] = {
    --     kind = "category",
    --     name = "数据",
    --     contents = {
    --         {
    --             kind = "block",
    --             type = "math_number",
    --         },
    --         {
    --             kind = "block",
    --             type = "text",
    --         }
    --     }
    -- };
    return google_toolbox;
end

function GoogleNplBlockly:GetNplBlocks(blockly, fetch_all_blocks)
    local blocks = {};

    if (not fetch_all_blocks) then
        blockly:ForEachUI(function(ui)
            if (ui:IsBlock()) then
                blocks[ui:GetType()] = ui;
                local block = ui;
                for _, input_field in pairs(block.inputFieldMap) do
                    if (input_field:GetType() == "input_value") then
                        local shadow_type = input_field:GetShadowType();
                        local shadow_block = blockly:GetBlockInstanceByType(shadow_type or "");
                        if (shadow_block) then
                            blocks[shadow_type] = shadow_block;
                        end
                    end
                end
            end
        end);
    end

    if (not next(blocks)) then
        local category_list = blockly:GetToolBox():GetCategoryList();
        for _, category_item in ipairs(category_list) do
            for _, blocktype in ipairs(category_item.blocktypes) do 
                local block = blockly:GetBlockInstanceByType(blocktype);
                if (block) then
                    blocks[blocktype] = block;
                    for _, input_field in pairs(block.inputFieldMap) do
                        if (input_field:GetType() == "input_value") then
                            local shadow_type = input_field:GetShadowType();
                            local shadow_block = blockly:GetBlockInstanceByType(shadow_type or "");
                            if (shadow_block) then
                                blocks[shadow_type] = shadow_block;
                            end
                        end
                    end
                else
                    print("block not found: "..blocktype);
                end
            end
        end        
    end

    return blocks;
end

function GoogleNplBlockly:NplBlocklyToGoogleBlockly(blockly, blocks, fetch_all_blocks)
    local google_blockly = {};
    -- 获取块选项
    if (not blocks or not next(blocks)) then blocks = self:GetNplBlocks(blockly, fetch_all_blocks) end
    -- 工作去转换
    google_blockly.workspace = self:NplWorksapceToGoogleWorkspace(blockly:Save());
    -- 块定义转换
    google_blockly.blocks = self:NplBlockOptionListToGoogleBlockOptionList(blocks);
    -- 生成工具箱
    google_blockly.toolbox = self:GenerateGoogleToolBoxJson(blockly, blocks);
    -- 生成代码
    google_blockly.code = blockly:GetCode();
    -- 转json字符串
    -- local google_blockly_json = commonlib.Json.Encode(google_blockly);
    -- copy to clipboard
    -- ParaMisc.CopyTextToClipboard("window.npl_to_google_blockly_config = " .. google_blockly_json);
    -- GameLogic.AddBBS("Blockly", "已经将转换后的Blockly配置复制到剪切板中, 请粘贴到js文件中", 5000, "0 255 0");
    -- self:WriteFile(ParaIO.GetWritablePath() .. "temp/npl_to_google_blockly_config.js", "window.npl_to_google_blockly_config = " .. google_blockly_json);
    -- self:WriteFile("D:/workspace/js/blockly-blockly-v11.0.0.-beta.6/npl_to_google_blockly_config.js", "window.npl_to_google_blockly_config = " .. google_blockly_json);
    return google_blockly;
end

function GoogleNplBlockly:WriteFile(file_path, file_text)
    local io = ParaIO.open(file_path, "w");
    io:WriteString(file_text);
    io:close();
end

function GoogleNplBlockly:OpenGoogleBlockly(npl_blockly, blocks)
    local winX, winY, winWidth, winHeight = npl_blockly:GetWindow():GetScreenPosition();
    local screenX, screenY, screenWidth, screenHeight = npl_blockly:GetWindow():GetParentNativeWindow():GetAbsPosition();
    local width = winX;
    local height = screenHeight;
    local G = npl_blockly:GetWindow():GetG();
    local OnClose = G.OnClose;
    G.OnClose = function()
        if(OnClose) then
            OnClose();
        end
        NPLJS:Close();
    end

    local google_blockly_config = self:NplBlocklyToGoogleBlockly(npl_blockly, blocks);
    NPLJS:Close();
    NPLJS:StartWebServer(function(site_url)
        -- site_url = "http://127.0.0.1:8088/npl/webparacraft/blockly/index.html";
        site_url = site_url .. "blockly.html";
        NPLJS:Open(site_url, function()
            NPLJS:SendMsg("LoadNplToGoogleBlocklyConfig", {google_blockly_config = google_blockly_config}, nil, nil, true, 200, false);
        end, 0, 0, width or 1280, height or 720);
    
        NPLJS:OnMsg("SaveGoogleWorkspace", function(msgdata)
            local google_workspace = msgdata.google_workspace;
            self:LoadGoogleWorkspace(npl_blockly, google_workspace);
        end);
    end);
end

function GoogleNplBlockly:LoadGoogleWorkspace(npl_blockly, google_workspace)
    npl_blockly:ClearBlocks();
    npl_blockly:ClearNotes();
    if (not google_workspace or not google_workspace.blocks or not google_workspace.blocks.blocks) then return end
    npl_blockly:Load({blocks = google_workspace.blocks.blocks});
    npl_blockly:AdjustCenter();
end

function GoogleNplBlockly:GetEntity(name)
    if (type(name) == "string") then
        local entities = EntityManager.FindEntities({category="b", type="EntityCode"});
        if(entities) then
            for i, entity in ipairs(entities) do
                if(entity:GetDisplayName() == name) then
                    return entity;
                end
            end
        end
    end
    return type(name) == "table" and name or nil;
end

function GoogleNplBlockly:FormatCode(code, entity)
	local prettyCode = code;
	local language = entity and entity:GetLanguageConfigFile();
	local LanguageConfig = NPL.load("script/ide/System/UI/Blockly/Blocks/LanguageConfig.lua");
	if (LanguageConfig:GetLanguageType(language) == "npl") then
		local LuaFmt = NPL.load("script/ide/System/UI/Blockly/LuaFmt.lua");
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

function GoogleNplBlockly:LoadEntityGoogleBlockly(entity, google_blockly_workspace)
    entity = self:GetEntity(entity);
    if (not entity) then return end

    local old_language_config_file, old_language_type = CodeHelpWindow.GetLanguageConfigFile();
    local old_entity = CodeBlockWindow.entity;

    CodeBlockWindow.entity = entity;
	CodeHelpWindow.SetLanguageConfigFile(entity:GetLanguageConfigFile(),entity:GetCodeLanguageType());
	local config = CodeBlockWindow.PrepareNplBlocklyConfig(entity);
	local Page = NPL.load("script/ide/System/UI/Page.lua");
	local blockly_page = Page.Show({
		Language = config.language,
		LanguageType = config.language_type,
		xmltext = config.workspace_xmltext,
		ToolBoxXmlText = config.toolbox_xmltext,
	}, { 
        template = [[
        <template style="width: 100%; height: 100%;">
            <div style="position: absolute; left: 0px; right: 0px; top: 0px; bottom: 0px;">
                <Blockly ref="blockly" 
                    v-bind:language="Language or 'SystemNplBlock'" 
                    v-bind:LanguageType="LanguageType or 'npl'" 
                    style="width: 100%; height: 100%;" 
                    CustomBlocklyFactory="true"
                    v-bind:ToolBoxXmlText="ToolBoxXmlText">
                </Blockly>
            </div>
        </template>            
        ]],
		alignment="_rt",
		x = 0, y = 0,
		width = 1280,
		height = 720,
		zorder = -2,
	});

    local function GetBlockly(el)
        if (el:GetName() == "Blockly") then return el end
        for _, child in ipairs(el.childrens) do
            local e = GetBlockly(child);
            if (e ~= nil) then return e end
        end
    end

    local npl_blockly = GetBlockly(blockly_page);
    if (npl_blockly == nil) then return end
    if (not google_blockly_workspace or not google_blockly_workspace.blocks) then 
        npl_blockly:SetInitWorkspaceXml(config.workspace_xmltext);
    else
        self:LoadGoogleWorkspace(npl_blockly, google_blockly_workspace);
    end 
    local google_blockly = self:NplBlocklyToGoogleBlockly(npl_blockly, nil, google_blockly_workspace and google_blockly_workspace.fetch_all_blocks);
    -- 保存到代码方块
    local code = self:FormatCode(npl_blockly:GetCode(), entity);
    local xml = npl_blockly:SaveToXmlNodeText();
	entity:SetNPLBlocklyXMLCode(xml);
	entity:SetNPLBlocklyNPLCode(code);

    -- 转json字符串
    -- local google_blockly_json = commonlib.Json.Encode(google_blockly);
    -- self:WriteFile("D:/workspace/js/blockly-blockly-v11.0.0.-beta.6/npl_to_google_blockly_config.js", "window.npl_to_google_blockly_config = " .. google_blockly_json);

    blockly_page:CloseWindow();
    CodeBlockWindow.entity = old_entity;
	CodeHelpWindow.SetLanguageConfigFile(old_language_config_file, old_language_type);

    return google_blockly;
end

GoogleNplBlockly:InitSingleton();

-- function GoogleNplBlockly:Test()
--     local BlockManager = NPL.load("script/ide/System/UI/Blockly/Blocks/BlockManager.lua");
--     local npl_block_options = BlockManager.GetBlockMap("npl");
--     local toolbox_xml = [[
--     <toolbox>
-- 	<category name="运动">
-- 		<block type="NPL_moveForward"/>
-- 	</category>
-- 	<category name="外观">
-- 		<block type="NPL_sayAndWait"/>
-- 	</category>
-- 	<category name="事件">
-- 		<block type="NPL_registerKeyPressedEvent"/>
-- 	</category>
-- 	<category name="控制">
-- 		<block type="NPL_if_else"/>
-- 	</category>
-- </toolbox>
--     ]]
--     local google_toolbox_xml, toolbox_block_options = self:NplToolBoxToGoogleToolBox(toolbox_xml, npl_block_options);
--     local google_toolbox_block_options = self:NplBlockOptionListToGoogleBlockOptionList(toolbox_block_options); 
--     local google_blockly = {
--         toolbox = google_toolbox_xml,
--         blocks = google_toolbox_block_options,
--         -- workspace = 
--     }
--     local google_blockly_json = commonlib.Json.Encode(google_blockly);
--     self:WriteFile("D:/workspace/js/blockly-blockly-v11.0.0.-beta.6/npl_to_google_blockly_config.js", "window.npl_to_google_blockly_config = " .. google_blockly_json);
-- end

-- GoogleNplBlockly:Test();

-- local google_option_json = commonlib.Json.Encode(google_option);
-- print(google_option_json);


-- function GoogleNplBlockly:OpenConsoleGoogleBlockly(npl_blockly, blocks)
--     self.m_blockly = npl_blockly;
--     self.m_google_blockly_config = self:NplBlocklyToGoogleBlockly(npl_blockly, blocks);
--     local CommandManager = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
--     CommandManager:RunCommand("/open npl://blockly");
--     return self.m_google_blockly_config;
-- end