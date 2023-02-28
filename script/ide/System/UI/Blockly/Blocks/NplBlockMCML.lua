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

local NplBlockMCML = NPL.export();

local all_categorie_list = {
    {name = "McmlControls", text = L"控件", color="#0078d7", blocktypes = {"mcml_div", "mcml_pure_text", "mcml_button", "mcml_label", "mcml_text", "mcml_checkbox", "mcml_progressbar", "mcml_sliderbar", "mcml_br"}},
    {name = "McmlAttrs", text = L"属性" , color="#7abb55", blocktypes = {"mcml_attrs_style_key_value", "mcml_attrs_key_value_onclick", "mcml_attrs_key_value", "mcml_attrs_align_key_value"}},
    {name = "McmlStyles", text = L"样式", color="#764bcc", blocktypes = {"mcml_styles_float_key_value", "mcml_styles_key_value_margin_pixel", "mcml_styles_key_value_padding_pixel", "mcml_styles_key_value_width_pixel", 
        "mcml_styles_key_value_font_size_pixel", "mcml_styles_font_weight", "mcml_styles_key_value_color", "mcml_styles_background", "mcml_styles_position"}},
    {name = "McmlData", text = L"数据", color="#459197", blocktypes = {"mcml_data_vlaue_px", "mcml_data_vlaue_percent", "mcml_data_align", "mcml_data_label", "mcml_data_string", "mcml_data_number", "mcml_data_boolean", "mcml_data_color"}},
};


local all_block_list = {
-----------------------
{
	type = "mcml_div", 
	message = "<div %1> %2 </div>",
	arg = {
        {
            name = "attr",
            type = "input_value_list",
			separator = " ",
        },
		{
			name = "code",
			type = "input_statement",
		},
    },
	category = "McmlControls", 
	previousStatement = true,
	nextStatement = true,
    code_description = [[<div ${attr}>\n${code}</div>]]
},

{
	type = "mcml_pure_text", 
	message = "%1",
    arg = {
        {
			name = "value",
            type = "field_input",
			text = "",
		},
	},
	category = "McmlControls", 
	previousStatement = true,
	nextStatement = true,
	code_description = [[${value}]],
},

{
	type = "mcml_button", 
	message0 = "<button  %1/>",
	arg0 = {
        {
            name = "attr",
            type = "input_value_list",
			separator = " ",
        },
	},
	category = "McmlControls", 
	previousStatement = true,
	nextStatement = true,
    code_description = [[<button ${attr} />]]
},

{
    type = "mcml_label", 
	message0 = "<label  %1/>",
	arg0 = {
        {
            name = "attr",
            type = "input_value_list",
			separator = " ",
        },
	},
	category = "McmlControls", 
	previousStatement = true,
	nextStatement = true,
    code_description = [[<pe:label ${attr} />]]
},

{
    type = "mcml_text", 
	message0 = "<text  %1/>",
	arg0 = {
        {
            name = "attr",
            type = "input_value_list",
			separator = " ",
        },
	},
	category = "McmlControls", 
	previousStatement = true,
	nextStatement = true,
    code_description = [[<input type="text" ${attr} />]]
},

{
    type = "mcml_checkbox", 
	message0 = "<checkbox  %1/>",
	arg0 = {
        {
            name = "attr",
            type = "input_value_list",
			separator = " ",
        },
	},
	category = "McmlControls", 
	previousStatement = true,
	nextStatement = true,
    code_description = [[<input type="checkbox" ${attr} />]]
},

{
    type = "mcml_progressbar", 
	message0 = "<progressbar  %1/>",
	arg0 = {
        {
            name = "attr",
            type = "input_value_list",
			separator = " ",
        },
	},
	category = "McmlControls", 
	previousStatement = true,
	nextStatement = true,
    code_description = [[<pe:progressbar ${attr} />]]
},

{
    type = "mcml_sliderbar", 
	message0 = "<sliderbar  %1/>",
	arg0 = {
        {
            name = "attr",
            type = "input_value_list",
			separator = " ",
        },
	},
	category = "McmlControls", 
	previousStatement = true,
	nextStatement = true,
    code_description = [[<pe:sliderbar ${attr} />]]
},

{
    type = "mcml_br", 
	message0 = "<br/>",
	arg0 = {
	},
	category = "McmlControls", 
	previousStatement = true,
	nextStatement = true,
    code_description = [[<br />]]
},


------------------------------------------------attrs---------------------------------------------------------
{
	type = "mcml_attrs_style_key_value", 
	message = "%1 = \"%2\"",
	arg = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
				{ "style", "style"},
			},
		},
        {
            name = "value",
            type = "input_value_list",
			separator = ";",
        },
	},
    output = true,
	category = "McmlAttrs", 
	code_description = [[${key}="${value}"]]
},

{
	type = "mcml_attrs_key_value_onclick", 
	message = "%1 = \"%2\"",
	arg = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
				{ "onclick", "onclick"},
			},
		},
        {
            name = "value",
            type = "input_value",
        },
	},
    output = true,
	category = "McmlAttrs", 
	code_description = [[${key}="${value}"]]
},

{
	type = "mcml_attrs_key_value", 
	message = "%1 = \"%2\"",
	arg = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
                { "value", "value"},
				{ "name", "name"},
				{ "class", "class"},
				{ "align", "align"},
				{ "checked", "checked"},
				{ "Minimum", "Minimum"},
				{ "Maximum", "Maximum"},
				{ "min", "min"},
				{ "max", "max"},
				{ "setter", "setter"},
				{ "getter", "getter"},
				{ "tooltip", "tooltip"},
			},
		},
        {
            name = "value",
            type = "input_value",
        },
	},
    output = true,
	category = "McmlAttrs", 
	code_description = [[${key}="${value}"]]
},

{
	type = "mcml_attrs_align_key_value", 
	message = "%1 = \"%2\"",
	arg = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
                { "align", "align"},
			},
		},
        {
            name = "value",
            type = "field_dropdown",
            options = {
				{ "left", "left"},
				{ "center", "center"},
				{ "right", "right"},
			},
        },
	},
    output = true,
	category = "McmlAttrs", 
	code_description = [[${key}="${value}"]]
},

------------------------------------------------------------------style-------------------------------------------------
{
	type = "mcml_styles_float_key_value", 
	message = "%1:%2;",
	arg = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
				{ "float", "float"},
                { "text-align", "text-align"},
			},
		},
         {
			name = "value",
			type = "field_dropdown",
            options = {
				{ "left", "left"},
				{ "center", "center"},
				{ "right", "right"},
			},
		},
	},
    output = true,
	category = "McmlStyles", 
	code_description = '${key}:${value};',
},

{
	type = "mcml_styles_key_value_margin_pixel", 
	message = "%1:%2%3;",
	arg = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
				{ "margin", "margin"},
				{ "margin-left", "margin-left"},
				{ "margin-top", "margin-top"},
				{ "margin-right", "margin-right"},
				{ "margin-bottom", "margin-bottom"},
			},
		},
         {
			name = "value",
            type = "input_value",
			shadowType = "math_number",
            text = 0,
		},
        {
			name = "unit",
			type = "field_dropdown",
			options = {
				{ "px", "px"},
			},
		},
	},
    output = true,
	category = "McmlStyles", 
	code_description = '${key}:${value}${unit};',
},

{
	type = "mcml_styles_key_value_padding_pixel", 
	message = "%1:%2%3;",
	arg = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
                { "padding", "padding"},
				{ "paddingn-left", "padding-left"},
				{ "padding-top", "padding-top"},
				{ "padding-right", "padding-right"},
				{ "padding-bottom", "padding-bottom"},
			},
		},
         {
			name = "value",
            type = "input_value",
			shadowType = "math_number",
            text = 0,
		},
        {
			name = "unit",
			type = "field_dropdown",
			options = {
				{ "px", "px"},
			},
		},
	},
    output = true,
	category = "McmlStyles", 
	code_description = '${key}:${value}${unit};',
},

{
	type = "mcml_styles_key_value_width_pixel", 
	message = "%1:%2%3;",
	arg = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
                { "width", "width"},
                { "height", "height"},
			},
		},
         {
			name = "value",
            type = "input_value",
			shadowType = "math_number",
            text = 100,
		},
        {
			name = "unit",
			type = "field_dropdown",
			options = {
				{ "px", "px"},
			},
		},
	},
    output = true,
	category = "McmlStyles", 
	code_description = '${key}:${value}${unit};',
},

{
	type = "mcml_styles_key_value_font_size_pixel", 
	message = "%1:%2%3;",
	arg = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
                { "font-size", "font-size"},
			},
		},
         {
			name = "value",
            type = "input_value",
			shadowType = "math_number",
            text = 14,
		},
        {
			name = "unit",
			type = "field_dropdown",
			options = {
				{ "px", "px"},
			},
		},
	},
    output = true,
	category = "McmlStyles", 
	code_description = '${key}:${value}${unit};',
},


{
	type = "mcml_styles_font_weight", 
	message = "font-weight:%1;",
	arg = {
        {
			name = "value",
			type = "field_dropdown",
			options = {
                { "bold", "bold"},
			},
		},
	},
    output = true,
	category = "McmlStyles", 
	code_description = 'font-weight:${value};',
},

{
	type = "mcml_styles_key_value_color", 
	message = "%1:%2;",
	arg = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
                { "color", "color"},
                { "background-color", "background-color"},
			},
		},
         {
			name = "value",
			type = "field_color",
			text = "#ff0000", 
		},
	},
    output = true,
	category = "McmlStyles", 
	code_description = '${key}:${value};',
},

{
	type = "mcml_styles_background", 
	message = "%1:url(%2);",
	arg = {
        {
			name = "key",
			type = "field_dropdown",
			options = {
                { "background", "background"},
			},
		},
         {
			name = "value",
			type = "field_input",
			text = "", 
		},
	},
    output = true,
	category = "McmlStyles", 
	code_description = '${key}:url(${value});',
},

{
	type = "mcml_styles_position", 
	message = "position:%1;",
	arg = {
        {
			name = "value",
			type = "field_dropdown",
            options = {
				{ "relative", "relative"},
				{ "static", "static"},
				{ "absolute", "absolute"},
			},
		},
	},
    output = true,
	category = "McmlStyles", 
	code_description = 'position:${value};',
},

---------------------------------------------------------------------data-----------------------------------------------
{
	type = "mcml_data_vlaue_px", 
	message = "%1%2",
	arg = {
        {
			name = "value",
			type = "input_value",
			shadowType = "math_number",
			text = 0, 
		},
        {
			name = "unit",
			type = "field_dropdown",
			options = {
				{ "px", "px"},
			},
		},
	},
    output = true,
	category = "McmlData", 
	code_description = '${value}${unit}',
},

{
	type = "mcml_data_vlaue_percent", 
	message = "%1%2",
	arg = {
        {
			name = "unit",
			type = "field_dropdown",
			options = {
				{ "%", "%"},
			},
		},
        {
			name = "value",
			type = "input_value",
			shadowType = "math_number",
			text = 100, 
		},
	},
    output = true,
	category = "McmlData", 
	code_description = '${value}${unit}',
},

{
	type = "mcml_data_align", 
	message = "%1",
	arg = {
        {
			name = "value",
			type = "field_dropdown",
			options = {
                { "left", "left" },
				{ "center", "center" },
				{ "right", "right" },
            },
		},
	},
    output = true,
	category = "McmlData", 
	code_description = '${value}',
},

{
	type = "mcml_data_label", 
	message = "%1",
	arg = {
        {
			name = "value",
			type = "field_input",
			text = "label",
		},
	},
    output = true,
	category = "McmlData", 
	code_description = '${value}',
},

{
	type = "mcml_data_string", 
	message = "\"%1\"",
	arg = {
        {
			name = "value",
			type = "field_input",
			text = "string",
		},
	},
    output = true,
	category = "McmlData", 
	code_description = '"${value}"',
},

{
	type = "mcml_data_number", 
	message = "%1",
	arg = {
        {
			name = "value",
			type = "field_number",
			text = "0",
		},
	},
    output = true,
	category = "McmlData", 
	code_description = '${value}',
},

{
	type = "mcml_data_boolean", 
	message = "%1",
	arg = {
        {
			name = "value",
			type = "field_dropdown",
			options = {
				{ "true", "true" },
				{ "false", "false" },
				{ "nil", "nil" },
			  }
		},
	},
    output = true,
	category = "McmlData", 
	code_description = '${value}',
},

{
	type = "mcml_data_color", 
	message = "%1",
	arg = {
        {
			name = "value",
			type = "field_color",
			text = "#ff0000",
		},
	},
    output = true,
	category = "McmlData", 
	code_description = '${value}',
},


};

function NplBlockMCML.GetBlockMap()
    local all_block_map = {};
    for _, block in ipairs(all_block_list) do
        all_block_map[block.type] = block;
    end
	return all_block_map;
end

function NplBlockMCML.GetCategoryListAndMap()
    local all_categorie_map = {};
    for _, category in ipairs(all_categorie_list) do
        all_categorie_map[category.name] = category;
    end
	return all_categorie_list, all_categorie_map;
end