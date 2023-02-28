
local BlockToolbox = NPL.export();

local AllBlockList = {
    {
        type = "set_block_type",
        message = "图块-类型 %1",
        arg = {
            {
                name = "block_type",
                type = "field_input",
                text = ""
            },
        },
        category = "BlockAttr",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local block_type = block:GetFieldValue("block_type");
            return string.format('type = "%s";\n', block_type);
        end,
    },
    {
        type = "set_block_category",
        message = "图块-类别 %1",
        arg = {
            {
                name = "block_category",
                type = "field_input",
                text = "图块"
            },
        },
        category = "BlockAttr",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local block_category = block:GetFieldValue("block_category");
            return string.format('category = "%s";\n', block_category);
        end,
    },
    {
        type = "set_block_connection",
        message = "图块-连接 %1",
        arg = {
            {
                name = "block_connection",
                type = "field_dropdown",
                text = "StatementConnection",
                options = {
                    {"语句链接", "StatementConnection"},
                    {"值连接", "OutputConnection"},
                    {"开始连接", "StartConnection"},
                }
            },
        },
        category = "BlockAttr",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local block_connection = block:GetFieldValue("block_connection");
            if (block_connection == "OutputConnection") then
                return string.format('previousStatement = false;\nnextStatement = false;\noutput = true;\n');
            elseif (block_connection == "StartConnection") then
                return string.format('previousStatement = false;\nnextStatement = true;\noutput = false;\n');
            else 
                return string.format('previousStatement = true;\nnextStatement = true;\noutput = false;\n');
            end
        end,
    },
    {
        type = "set_block_color",
        message = "图块-颜色 %1",
        arg = {
            {
                name = "block_color",
                type = "field_input",
                text = "#2E9BEF"
            },
        },
        category = "BlockAttr",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local block_color = block:GetFieldValue("block_color");
            return string.format('color = "%s";\n', block_color);
        end,
    },
    {
        type = "set_block_hide_in_toolbox",
        message = "图块-工具栏中 %1",
        arg = {
            {
                name = "block_hide_in_toolbox",
                type = "field_dropdown",
                text = "false",
                options = {{"显示", "false"}, {"隐藏", "true"}},
            }
        },
        category = "BlockAttr",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local block_hide_in_toolbox = block:GetFieldValue("block_hide_in_toolbox");
            return string.format("hideInToolbox = %s;\n", block_hide_in_toolbox);
        end,
    },
    {
        type = "set_field_text",
        message = "字段-文本 %1",
        arg = {
            {
                name = "field_text",
                type = "field_input",
                text = "文本内容",
            },
        },
        category = "BlockField",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local field_text = block:GetFieldValue("field_text");
            return string.format('message = message .. " " .. [==[%s]==];\n', field_text);
        end,
    },
    -- {
    --     type = "set_field_button",
    --     message = "字段-按钮 %1 %2",
    --     arg = {
    --         {
    --             name = "field_text",
    --             type = "field_input",
    --             text = "按钮内容",
    --         },
    --         {
    --             name = "field_callback",
    --             type = "field_textarea",
    --             text = "",
    --         },
    --     },
    --     category = "BlockField",
    --     previousStatement = true,
	--     nextStatement = true,
    --     ToCode = function(block)
    --         local field_text = block:GetFieldValue("field_text");
    --         local field_callback = block:GetFieldValue("field_callback");
    --         return string.format([==[
    --             field_count = field_count + 1;
    --             message = message .. " %%" .. field_count;
    --             arg[field_count] = {type = "field_button", text = "%s", callback = [[%s]]};
    --             ]==], field_text, field_callback);
    --     end,
    -- },
    -- {
    --     type = "set_field_variable",
    --     message = "字段-变量 %1 %2 %3",
    --     arg = {
    --         {
    --             name = "field_name",
    --             type = "field_input",
    --             text = "名称",
    --         },
    --         {
    --             name = "field_value",
    --             type = "field_input",
    --             text = "默认值",
    --         },
    --         {
    --             name = "field_type",
    --             type = "field_input",
    --             text = "类型",
    --         },
    --     },
    --     category = "BlockField",
    --     previousStatement = true,
	--     nextStatement = true,
    --     ToCode = function(block)
    --         local field_name = block:GetFieldValue("field_name");
    --         local field_value = block:GetFieldValue("field_value");
    --         local field_type = block:GetFieldValue("field_type");
    --         return string.format([==[
    --             field_count = field_count + 1;
    --             message = message .. " %%" .. field_count;
    --             arg[field_count] = {name = "%s", type = "field_variable", vartype = "%s", text = [[%s]]};
    --             ]==], field_name, field_type, field_value);
    --     end,
    -- },
    {
        type = "set_field_input",
        message = "字段-输入 %1 %2 %3",
        arg = {
            {
                name = "field_name",
                type = "field_input",
                text = "名称",
            },
            {
                name = "field_value",
                type = "field_input",
                text = "默认值",
            },
            {
                name = "field_type",
                type = "field_dropdown",
                text = "field_input",
                options = {
                    {"文本", "field_input"},
                    {"数字", "field_number"},
                    {"多行文本", "field_textarea"},
                    {"列表", "field_dropdown"},
                    {"颜色", "field_color"},
                    {"变量", "field_variable"},
                    {"按钮", "field_button"},
                    {"数据", "field_value"},
                    {"代码", "field_code"},
                }
            },
        },
        category = "BlockField",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local field_name = block:GetFieldValue("field_name");
            local field_type = block:GetFieldValue("field_type");
            local field_value = block:GetFieldValue("field_value");
            return string.format([==[
                field_count = field_count + 1;
                message = message .. " %%" .. field_count;
                arg[field_count] = {name = "%s", type = "%s", text = [[%s]]};
                ]==], field_name, field_type, field_value);
        end,
    },
    {
        type = "set_field_dropdown_code_options",
        message = "字段-列表 %1 %2 %3 %4",
        arg = {
            {
                name = "field_name",
                type = "field_input",
                text = "名称",
            },
            {
                name = "field_value",
                type = "field_input",
                text = "默认值",
            },
            {
                name = "field_options",
                type = "field_input",
                text = [[{{"标签1", "值1"}, {"标签2", "值2"}, {"标签3", "值3"}}]]
            },
            {
                name = "field_allow_new_option",
                type = "field_dropdown",
                text = "false",
                options = {{"禁止新增", "false"}, {"允许新增", "true"}},
            }
        },
        category = "BlockField",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local field_name = block:GetFieldValue("field_name");
            local field_value = block:GetFieldValue("field_value");
            local field_options = block:GetFieldValue("field_options");
            local field_allow_new_option = block:GetFieldValue("field_allow_new_option");
            return string.format([==[
                field_count = field_count + 1;
                message = message .. " %%" .. field_count;
                arg[field_count] = {name = "%s", type = "field_dropdown", text = "%s", options = %s, isAllowNewSelectOption = %s};
                ]==], field_name, field_value, field_options, field_allow_new_option);
        end,
    },
    -- {
    --     type = "set_field_dropdown",
    --     message = "字段-列表 %1 %2 %3",
    --     arg = {
    --         {
    --             name = "field_name",
    --             type = "field_input",
    --             text = "字段名",
    --         },
    --         {
    --             name = "field_value",
    --             type = "field_input",
    --             text = "默认值",
    --         },
    --         {
    --             name = "field_options",
    --             type = "input_statement",
    --             check = {"set_field_dropdown_option"},
    --         },
    --     },
    --     category = "BlockField",
    --     previousStatement = true,
	--     nextStatement = true,
    --     ToCode = function(block)
    --         local field_name = block:GetFieldValue("field_name");
    --         local field_value = block:GetFieldValue("field_value");
    --         local field_options = block:GetValueAsString("field_options");
    --         return string.format('field_count = field_count + 1;\nmessage = message .. " %%" .. field_count;\narg[field_count] = {name = "%s", type = "field_dropdown", text = "%s", options = {}};\nlocal field_dropdown_options = arg[field_count].options;\n%s', field_name, field_value, field_options);
    --     end,
    -- },

    -- {
    --     type = "set_field_dropdown_option",
    --     message = "字段-列表项 %1 %2",
    --     arg = {
    --         {
    --             name = "field_option_label",
    --             type = "field_input",
    --             text = "标签",
    --         },
    --         {
    --             name = "field_option_value",
    --             type = "field_input",
    --             text = "值",
    --         },
    --     },
    --     category = "BlockField",
    --     previousStatement = {"set_field_dropdown", "set_field_dropdown_option"},
	--     nextStatement = {"set_field_dropdown_option"},
    --     ToCode = function(block)
    --         local field_option_label = block:GetFieldValue("field_option_label");
    --         local field_option_value = block:GetFieldValue("field_option_value");
    --         return string.format('field_dropdown_options[#field_dropdown_options + 1] = {"%s", "%s"};\n', field_option_label, field_option_value);
    --     end,
    -- },

    {
        type = "set_input_value",
        message = "输入-值 %1 %2 %3",
        arg = {
            {
                name = "input_name",
                type = "field_input",
                text = "名称",
            },
            {
                name = "input_value",
                type = "field_input",
                text = "默认值",
            },
            {
                name = "input_type",
                type = "input_value",
                shadowType = "field_dropdown",
                text = "field_input",
                options = {
                    {"文本", "field_input"},
                    {"数字", "field_number"},
                    {"颜色", "field_color"},
                    {"代码", "field_code"},
                },
                check = "System_Lua_String",
            },
        },
        category = "BlockInput",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local input_name = block:GetFieldValue("input_name");
            local input_value = block:GetFieldValue("input_value");
            local input_type = block:GetValueAsString("input_type");
            return string.format([==[
                field_count = field_count + 1;
                message = message .. " %%" .. field_count;
                arg[field_count] = {name = "%s", type = "input_value", text = [[%s]], shadowType = %s};
                ]==], input_name, input_value, input_type);
        end,
    },

    {
        type = "set_input_dropdown_code_options",
        message = "输入-列表 %1 %2 %3",
        arg = {
            {
                name = "input_name",
                type = "field_input",
                text = "名称",
            },
            {
                name = "input_value",
                type = "field_input",
                text = "默认值",
            },
            {
                name = "input_options",
                type = "field_input",
                text = [[{{"标签1", "值1"}, {"标签2", "值2"}, {"标签3", "值3"}}]]
            },
        },
        category = "BlockInput",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local input_name = block:GetFieldValue("input_name");
            local input_value = block:GetFieldValue("input_value");
            local input_options = block:GetFieldValue("input_options");
            return string.format([==[
                field_count = field_count + 1;
                message = message .. " %%" .. field_count;
                arg[field_count] = {name = "%s", type = "input_value", shadowType = "field_dropdown", text = "%s", options = %s};
                ]==], input_name, input_value, input_options);
        end,
    },

    -- {
    --     type = "set_input_value_dropdown",
    --     message = "输入-列表值 %1 %2 %3",
    --     arg = {
    --         {
    --             name = "input_name",
    --             type = "field_input",
    --             text = "名称",
    --         },
    --         {
    --             name = "input_value",
    --             type = "field_input",
    --             text = "默认值",
    --         },
    --         {
    --             name = "input_options",
    --             type = "input_statement",
    --             check = {"set_input_value_dropdown_option"},
    --         },
    --     },
    --     category = "BlockInput",
    --     previousStatement = true,
	--     nextStatement = true,
    --     ToCode = function(block)
    --         local input_name = block:GetFieldValue("input_name");
    --         local input_value = block:GetFieldValue("input_value");
    --         local input_options = block:GetValueAsString("input_options");
    --         -- return string.format('field_count = field_count + 1;\nmessage = message .. " %%" .. field_count;\narg[field_count] = {name = "%s", type = "field_dropdown", text = "%s", options = {}};\nlocal field_dropdown_options = arg[field_count].options;\n%s', field_name, field_value, field_options);
    --         return string.format('field_count = field_count + 1;\nmessage = message .. " %%" .. field_count;\narg[field_count] = {name = "%s", type = "input_value", text = "%s", shadowType = "field_dropdown", options = {}};\nlocal input_dropdown_options = arg[field_count].options;\n%s', input_name, input_value, input_options);
    --     end,
    -- },

    -- {
    --     type = "set_input_value_dropdown_option",
    --     message = "输入-列表值项 %1 %2",
    --     arg = {
    --         {
    --             name = "input_option_label",
    --             type = "field_input",
    --             text = "标签",
    --         },
    --         {
    --             name = "input_option_value",
    --             type = "field_input",
    --             text = "值",
    --         },
    --     },
    --     category = "BlockInput",
    --     previousStatement = {"set_input_value_dropdown", "set_input_value_dropdown_option"},
	--     nextStatement = {"set_input_value_dropdown_option"},
    --     ToCode = function(block)
    --         local input_option_label = block:GetFieldValue("input_option_label");
    --         local input_option_value = block:GetFieldValue("input_option_value");
    --         return string.format('input_dropdown_options[#input_dropdown_options + 1] = {"%s", "%s"};\n', input_option_label, input_option_value);
    --     end,
    -- },

    {
        type = "set_input_statement",
        message = "输入-语句 %1",
        arg = {
            {
                name = "input_name",
                type = "field_input",
                text = "名称",
            },
        },
        category = "BlockInput",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local input_name = block:GetFieldValue("input_name");
            return string.format([[
                field_count = field_count + 1;
                message = message .. " %%" .. field_count;
                arg[field_count] = {name = "%s", type = "input_statement"};
                ]], input_name);
        end,
    },
    {
        type = "set_input_value_list",
        message = "输入-值列表 %1 %2",
        arg = {
            {
                name = "input_name",
                type = "field_input",
                text = "名称",
            },
            {
                name = "input_separator",
                type = "field_dropdown",
                text = ",",
                options = {{"逗号", ","}, {"空格", " "}},
            },
        },
        category = "BlockInput",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local input_name = block:GetFieldValue("input_name");
            local input_separator = block:GetFieldValue("input_separator");
            return string.format([==[
                field_count = field_count + 1;
                message = message .. " %%" .. field_count;
                arg[field_count] = {name = "%s", type = "input_value_list", separator = "%s"};
                ]==], input_name, input_separator);
        end,
    },
    {
        type = "set_input_field_option",
        message = "选项 键 %1 值 %2",
        arg = {
            {
                name = "key",
                type = "field_dropdown",
                text = "key",
                options = {
                    {"背景颜色", "background-color"},
                    {"提示文本", "placeholder"},
                },
            },
            {
                name = "value",
                type = "field_input",
                text = "value",
            }
        },
        category = "BlockInputField",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local key = block:GetFieldValue("key");
            local value = block:GetFieldValue("value");
            return string.format('arg[field_count]["%s"] = "%s";\n', key, value);
        end
    },
    {
        type = "set_connection_type",
        message = "连接 %1 类型 %2",
        arg = {
            {
                name = "connection_name",
                type = "input_value",
                text = "output",
                shadowType = "field_dropdown",
                options = {
                    {"值连接", "output"},
                    {"语句-上连接", "previousStatement"},
                    {"语句-下连接", "nextStatement"},
                },
            },
            {
                name = "connection_type",
                type = "field_input",
                text = "",
            }
        },
        category = "BlockConnection",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local connection_name = block:GetValueAsString("connection_name");
            local connection_type = block:GetFieldValue("connection_type");
            return string.format('connections[%s] = "%s";\n', connection_name, connection_type);
        end
    },

    {
        type = "set_code_description",
        message = "代码-格式 %1",
        arg = {
            {
                name = "code_description",
                type = "field_textarea",
                -- type = "field_input",
                text = "${VALUE}",
            },
        },
        category = "BlockCode",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local code_description = block:GetFieldValue("code_description");
            return string.format('code_description = [====[%s]====];\n', code_description);
        end,
    },

    {
        type = "set_code",
        message = "图块自定义代码 %1",
        arg = {
            {
                name = "code_description",
                type = "field_textarea",
                text = "",
            },
        },
        category = "BlockCode",
        previousStatement = true,
	    nextStatement = true,
        ToCode = function(block)
            local code_description = block:GetFieldValue("code_description");
            return string.format('code = [====[%s]====];\n', code_description);
        end,
    },

    {
        type = "string",
        message = '" %1 "',
        arg = {
            {
                name = "field_string",
                type = "field_input",
                text = "string",
            },
        },
        category = "BlockData",
	    output = true,
        ToCode = function(block)
            local field_string = block:GetFieldValue("field_string");
            return string.format('"%s"', field_string);
        end,
    },
};

local AllBlockMap = {};

local AllCategoryList = {
    {
        name = "BlockAttr",
        text = "属性",
        color = "#2E9BEF",
        blocktypes = {}
    },
    {
        name = "BlockField",
        text = "字段",
        color = "#76CE62",
        blocktypes = {}
    },
    {
        name = "BlockInput",
        text = "输入",
        color = "#764BCC",
        blocktypes = {}
    },
    {
        name = "BlockInputField",
        text = "选项",
        color = "#FF8C1A",
        blocktypes = {}
    },
    {
        name = "BlockConnection",
        text = "连接",
        color = "#69B090",
        blocktypes = {}
    },
    {
        name = "BlockCode",
        text = "代码",
        color = "#EC522E",
        blocktypes = {}
    },
    {
        name = "BlockData",
        text = "数据",
        color = "#C38A3F",
        blocktypes = {}
    },
}
local AllCategoryMap = {};

for _, category in ipairs(AllCategoryList) do
    AllCategoryMap[category.name] = category;
end

for _, block in ipairs(AllBlockList) do
    AllBlockMap[block.type] = block;
    local category = block.category and AllCategoryMap[block.category];
    if (category) then
        block.color = category.color;
        table.insert(category.blocktypes, #(category.blocktypes) + 1, block.type);
    end
end

function BlockToolbox.GetBlockMap()
    return AllBlockMap;
end

function BlockToolbox.GetCategoryList()
    return AllCategoryList;
end

function BlockToolbox.GetCategoryListAndMap()
    return AllCategoryList, AllCategoryMap;
end
