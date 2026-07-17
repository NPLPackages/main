NPL.export({
    version = "0.0.0",
    language = "mcml",
    toolbox_xmltext = [[
        <toolbox>
        <category name="McmlControls">
            <block type="mcml_div"/>
            <block type="mcml_pure_text"/>
            <block type="mcml_button"/>
            <block type="mcml_label"/>
            <block type="mcml_text"/>
            <block type="mcml_checkbox"/>
            <block type="mcml_progressbar"/>
            <block type="mcml_sliderbar"/>
            <block type="mcml_br"/>
        </category>
        <category name="McmlAttrs">
            <block type="mcml_attrs_style_key_value"/>
            <block type="mcml_attrs_key_value_onclick"/>
            <block type="mcml_attrs_key_value"/>
            <block type="mcml_attrs_align_key_value"/>
        </category>
        <category name="McmlStyles">
            <block type="mcml_styles_float_key_value"/>
            <block type="mcml_styles_key_value_margin_pixel"/>
            <block type="mcml_styles_key_value_padding_pixel"/>
            <block type="mcml_styles_key_value_width_pixel"/>
            <block type="mcml_styles_key_value_font_size_pixel"/>
            <block type="mcml_styles_font_weight"/>
            <block type="mcml_styles_key_value_color"/>
            <block type="mcml_styles_background"/>
            <block type="mcml_styles_position"/>
        </category>
        <category name="McmlData">
            <block type="mcml_data_vlaue_px"/>
            <block type="mcml_data_vlaue_percent"/>
            <block type="mcml_data_align"/>
            <block type="mcml_data_label"/>
            <block type="mcml_data_string"/>
            <block type="mcml_data_number"/>
            <block type="mcml_data_boolean"/>
            <block type="mcml_data_color"/>
        </category>
        </toolbox>    
    ]]
})