--[[
    author:wyx
    time:2022-06-06
]]

-----------------------------------
-- pe_table: pure text
-----------------------------------
----------------------------------------表格------------------------------------------------------------

local pe_table = commonlib.gettable("Map3DSystem.mcml_controls.pe_table");

function pe_table.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	pe_table.create_table(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css)
end

function pe_table.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout, css)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_table.render_callback);
end

-- it will create text in available position as single lined, or as multilined in new line position.
-- the control takes up whatever vertical space needed to display the text as a paragraph,
-- param mcmlNode: is a text
-- param css: nil or a table containing css style, such as {color=string, href=string}. This is a style object to be associated with each node.
function pe_table.create_table(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout,css)
    local _this = ParaUI.CreateUIObject("container", "c", "_lt", left, top, width - left , height - top);
    _this.background = "Texture/Aries/Creator/keepwork/vip/baidiheikuang_32x32_32bits.png:3 3 3 3";
    _parent:AddChild(_this);
    local row = mcmlNode:GetChildCount()
    if row ~= 0 then
        parentLayout.rowHeight = math.floor((height - top)/row)
    else
        parentLayout.rowHeight =  height - top
    end
    local column = 0
    for childnode in mcmlNode:next() do
        local count = childnode:GetChildCount()
        if  count > column then
            column = count
        end
    end
    if column ~= 0 then
        parentLayout.columnWidth = math.floor((width - left)/column)
    else
        parentLayout.columnWidth = (width - left)
    end
    mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, parentLayout, css);
end

----------------------------------------行------------------------------------------------------------

local pe_tr = commonlib.gettable("Map3DSystem.mcml_controls.pe_tr");

function pe_tr.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	pe_tr.create_table(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css)
end

function pe_tr.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout, css)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_tr.render_callback);
end

-- it will create text in available position as single lined, or as multilined in new line position.
-- the control takes up whatever vertical space needed to display the text as a paragraph,
-- param mcmlNode: is a text
-- param css: nil or a table containing css style, such as {color=string, href=string}. This is a style object to be associated with each node.
function pe_tr.create_table(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
    css["float"] = "left"
    css.width = width - left
    css.height =  css.height or parentLayout.rowHeight
    local _this = ParaUI.CreateUIObject("container", "c", "_lt", left , top, width - left ,  css.height);
    _this.background = "Texture/Aries/Creator/keepwork/vip/baidiheikuang_32x32_32bits.png:3 3 3 3";
    if css["background-color"] then
        _guihelper.SetUIColor(_this,css["background-color"])
    end
    _parent:AddChild(_this);
    mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, parentLayout, css);
end

----------------------------------------列------------------------------------------------------------

local pe_td = commonlib.gettable("Map3DSystem.mcml_controls.pe_td");

function pe_td.render_callback(mcmlNode, rootName, bindingContext, _parent, left, top, right, bottom, myLayout, css)
	pe_td.create_table(rootName, mcmlNode, bindingContext, _parent, left, top, right, bottom, myLayout, css)
end

function pe_td.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout, css)
	return mcmlNode:DrawDisplayBlock(rootName, bindingContext, _parent, left, top, width, height, parentLayout, style, pe_td.render_callback);
end

-- it will create text in available position as single lined, or as multilined in new line position.
-- the control takes up whatever vertical space needed to display the text as a paragraph,
-- param mcmlNode: is a text
-- param css: nil or a table containing css style, such as {color=string, href=string}. This is a style object to be associated with each node.
function pe_td.create_table(rootName,mcmlNode, bindingContext, _parent, left, top, width, height, parentLayout, css)
    css["float"] = "left"
    css.width = css.width or parentLayout.columnWidth
    local _this = ParaUI.CreateUIObject("container", "c", "_lt", left , top,  css.width,parentLayout.rowHeight);
    _this.background = "Texture/Aries/Creator/keepwork/vip/baidiheikuang_32x32_32bits.png:3 3 3 3";
    -- _parent:AddChild(_this);
    mcmlNode:DrawChildBlocks_Callback(rootName, bindingContext, _parent, left, top, width, height, parentLayout, css);
end