
local GlobalScope = GetGlobalScope();

_G.WindowElement = nil;
_G.BlocklyElement = nil;
_G.CurrentElement = nil;
_G.CurrentListItemData = {};
_G.ListItemDataMap = {};

_G.StyleNameList = {
    "width", "height", "left", "top", "right", "bottom", "display", "position", "font-size", "color", "background", "background-color",
    "margin-top", "margin-right", "margin-bottom", "margin-left", "padding-top", "padding-right", "padding-bottom", "padding-left", 
    "justify-content", "align-items", "align-self", "border",
};

_G.StyleOptions = {
    {"宽", "width"}, 
    {"高", "height"}, 
    {"X", "left"}, 
    {"Y", "top"}, 
    {"字体大小", "font-size"}, 
    {"字体颜色", "color"}, 
    {"背景颜色", "background-color"}, 
    {"背景图片", "background"},
    {"display", "display"},
    {"justify-content", "justify-content"},
    {"align-items", "align-items"},
};

_G.StyleValueOptions = {
    ["display"] = {"flex", "block", "inline-block", "inline"},
    ["justify-content"] = {"center", "space-between", "space-around","flex-start", "flex-end"},
    ["align-items"] = {"center", "space-between", "space-around","flex-start", "flex-end"},
    ["font-size"] = {"10px", "12px", "14px", "16px", "18px", "20px", "24px", "28px", "30px", "36px", "40px", "50px"},
}

_G.TagNameOptions = {"div", "select", "input", "textarea", "radio", "radiogroup", "checkbox", "checkboxgroup"};

local function GetStyleString(style)
    local styleString = "";
    for _, styleName in ipairs(StyleNameList) do 
        if (style[styleName]) then
            styleString = string.format("%s:%s;%s", styleName, style[styleName], styleString);
        end
    end
    return styleString;
end

local ElementId = 0;
local function GetNextElementId()
    ElementId = ElementId + 1;
    return string.format("ID_%s", ElementId);
end

local function GenerateListItemData(opt)
    local item = {
        id = GetNextElementId(),
        parentId = "",
        text = "",
        textVarName = "",  -- 动态文本
        style = { 
            width = 200,
            height = 100,
            -- ["background-color"] = "#ffffff",
        },
        hoverStyle = {},
        attr = {},
        vbind = {},
        tagname = "div",
        order = ElementId,
    }

    commonlib.partialcopy(item, opt);

    return item;
end

local function GenerateWindowItemData()
    return GenerateListItemData({
        id = string.format("ID_%s", 1),
        style = {width = "100%", height = "100%"}, 
        isWindowItemData = true,
        tagname = "template",
    });
end

_G.CurrentElementStyleChange = function ()

end

_G.WindowItemData = GenerateWindowItemData();


_G.ListItemDataMap[WindowItemData.id] = WindowItemData;

_G.Reset = function()
    GlobalScope:Set("CurrentElementId", "");
    GlobalScope:Set("IsWindowElement", false);
    GlobalScope:Set("ElementList", {});
    GlobalScope:Set("AllCode", "");
    GlobalScope:Set("CssCode", "");
    GlobalScope:Set("ScriptCode", "");
    GlobalScope:Set("ScriptFileName", "");
end

_G.Reset();

local function GetElementById(id)
    local function getElementById(el, id) 
        if (el:GetAttrStringValue("id") == id) then return el end
        for _, childEl in ipairs(el.childrens) do 
            local idEl = getElementById(childEl, id);  
            if (idEl) then return idEl end
        end
        return nil;
    end

    return getElementById(WindowElement, id);  
end

local function SetCurrentElement(curElement)
    _G.CurrentElement = curElement;
    local CurrentElementId = CurrentElement and CurrentElement:GetAttrStringValue("id");

    _G.CurrentListItemData = ListItemDataMap[CurrentElementId];
    _G.CurrentListItemData.style.left, _G.CurrentListItemData.style.top = CurrentElement:GetPosition();
    GlobalScope:Set("CurrentElementId", CurrentElementId);
    GlobalScope:Set("IsWindowElement", CurrentElementId == WindowItemData.id);
    _G.CurrentElement:SetAttrValue("style", CurrentListItemData.style);
end

function SelectCurrentElementId(elementId)
    local element = GetElementById(elementId);
    SetCurrentElement(element);
end

function GetCurrentElementId()
    return GlobalScope:Get("CurrentElementId");
end

function DraggableFlagElementOnMouseDown(el)
    el:GetParentElement():OnMouseDown(GetEvent());
end

function DraggableFlagElementOnMouseMove(el)
    el:GetParentElement():OnMouseMove(GetEvent());
end

function DraggableFlagElementOnMouseUp(el)
    el:GetParentElement():OnMouseUp(GetEvent());
end

local DraggableData = {};
function DraggableSizeElementOnMouseDown(el, event)
    DraggableData.element = el;
    DraggableData.isMouseDown = true;
    DraggableData.startDragX, DraggableData.startDragY = event:GetWindowXY(); 
    DraggableData.elementLeft, DraggableData.elementTop = el:GetPosition();
    DraggableData.parentElementWidth, DraggableData.parentElementHeight = el:GetParentElement():GetSize();
end

function DraggableSizeElementOnMouseMove(el, event)
    if (DraggableData.element == el and DraggableData.isMouseDown and event:IsLeftButton() ) then
		if(not DraggableData.isDragging and not event:IsMove()) then return end
        DraggableData.isDragging = true;
        el:CaptureMouse();

        local DragMoveX, DragMoveY = event:GetWindowXY();
        local DragOffsetX, DragOffsetY = DragMoveX - DraggableData.startDragX, DragMoveY - DraggableData.startDragY;
        local style = CurrentListItemData.style;
        style.width = DraggableData.parentElementWidth + DragOffsetX;
        style.height = DraggableData.parentElementHeight + DragOffsetY;
        el:GetParentElement():SetSize(style.width, style.height);
        el:SetPosition(DraggableData.elementLeft + DragOffsetX, DraggableData.elementTop + DragOffsetY);
        el:GetParentElement():SetAttrValue("style", CurrentListItemData.style);
    end
end

function DraggableSizeElementOnMouseUp(el, event)
    if (DraggableData.isDragging and DraggableData.element == el) then
		el:ReleaseMouseCapture();
        local parentElement = el:GetParentElement();
        -- parentElement:SetAttrValue("style", CurrentListItemData.style);
        _G.UpdateCurrentListItemDataStyle();
    end
    DraggableData.isDragging = false;
    DraggableData.isMouseDown = false;
end

function DraggableSizeElementOnRender(el, painter)
    local x, y, w, h = el:GetGeometry();
    painter:SetPen(el:GetColor("#cccccc"));
    painter:DrawLine(x, y + h / 2, x + w, y + h / 2);
    painter:DrawLine(x + w / 2, y, x + w / 2, y + h);
end

function DraggableElementOnMouseDown(el)
end

function DraggableElementOnMouseMove(el)
end

function DraggableElementOnMouseUp(el)
    GetEvent():Accept();
    SetCurrentElement(el);
end

function OnReady()
    _G.WindowElement = GetRef("window");
    _G.BlocklyElement = GetRef("blockly");
    SetCurrentElement(_G.WindowElement);

    _G.EditCurrentFile();
end

_G.GetIdOptions = function()
    local opts = {};
    local list = GlobalScope:Get("ElementList");
    for _, item in ipairs(list) do table.insert(opts, #opts + 1, item.id) end 
    table.sort(opts);
    return opts;
end 

_G.GetListItemById = function(id)
    local list = GlobalScope:Get("ElementList");
    for i = 1, #list do 
        if (list[i].id == id) then 
            return list[i], i;
        end
    end
    return _G.WindowItemData, 0;
end

function ClickNewElementBtn()
    local list = GlobalScope:Get("ElementList");
    local item = GenerateListItemData({
        style = {
            position = "absolute",
            left = 0,
            top = 0,
        }
    });
    _G.ListItemDataMap[item.id] = item;
    table.insert(list, {id = item.id, text = item.text, tagname = item.tagname});
end

function ClickDeleteElementBtn()
    local CurrentElementId = GetCurrentElementId()
    if (not CurrentElementId) then return end
    local _, index = GetListItemById(CurrentElementId);
    if (index > 0) then 
        table.remove(GlobalScope:Get("ElementList"), index);
        _G.ListItemDataMap[CurrentElementId] = nil;
    end
end

function ClickCopyElementBtn()
    local list = GlobalScope:Get("ElementList");
    local item = commonlib.deepcopy(CurrentListItemData);
    item.id = GetNextElementId();
    _G.ListItemDataMap[item.id] = item;
    table.insert(list, {id = item.id, text = item.text, tagname = item.tagname});
end

function ClickSaveBtn()
    _G.SaveCurrentFile();
    Tip("保存成功");
end

_G.GenerateCode = function()
    local allcode = "";
    local scopedCssText = "";
    local list = {};
    for _, item in pairs(_G.ListItemDataMap) do
        if (not WindowItemData or item.id ~= WindowItemData.id) then table.insert(list, item) end
    end
    table.sort(list, function(item1, item2) return item1.order < item2.order end);
    -- local IdSuffix = os.time();
    -- template
    local function generateElementCode(item)
        if (not item) then return "" end
        local tagname = if_else(not item.tagname or item.tagname == "", "div", item.tagname);

        local hoverStyleString = GetStyleString(item.hoverStyle);
        if (hoverStyleString ~= "") then scopedCssText = string.format(".%s:hover { %s }\n%s", item.id, hoverStyleString, scopedCssText) end

        -- 追加ID为类名
        local oldClassString = item.attr["class"];
        if (oldClassString and oldClassString ~= "") then item.attr["class"] = string.format("%s %s", item.id, oldClassString or "") 
        else item.attr["class"] = item.id end
        
        local attrString = "";
        for key, val in pairs(item.attr) do attrString = string.format('%s="%s" %s', key, val, attrString) end
        item.attr["class"] = oldClassString;

        local vbindAttrString = "";
        for key, val in pairs(item.vbind) do vbindAttrString = string.format('v-bind:%s="%s" %s', key, val, vbindAttrString) end
        local textString = "";
        
        if (item.textVarName ~= "") then textString = "{{" .. item.textVarName .. "}}" 
        elseif (item.text ~= "") then textString = item.text 
        else end
        -- local idString = string.format("%s_%s", item.id, IdSuffix);
        -- return string.format([[<%s id="%s" %s %s style="%s">%s</%s>]], tagname, idString, vbindAttrString, attrString, GetStyleString(item.style), item.text, tagname)
        return string.format([[<%s %s %s style="%s">%s</%s>]], tagname, vbindAttrString, attrString, GetStyleString(item.style), textString, tagname)
    end

    for _, item in ipairs(list) do
        allcode = allcode .. "\n\t" .. generateElementCode(item);
    end

    -- allcode = string.format('<template id="%s_%s" style="%s">%s\n</template>', WindowItemData.id, IdSuffix, GetStyleString(WindowItemData), allcode);
    allcode = string.format('<template style="%s">%s\n</template>', GetStyleString(WindowItemData.style), allcode);

    -- script
    local rawcode, prettycode = BlocklyElement:GetCode();
    local GlobalCssCode = GlobalScope:Get("CssCode");
    local scriptCode = GlobalScope:Get("ScriptCode");
    if (scriptCode ~= "") then prettycode = prettycode .. "\n" .. scriptCode .. "\n" end
    local scriptFileName = GlobalScope:Get("ScriptFileName");
    local scriptStartTag = '\n<script type="text/lua">\n';
    if (scriptFileName ~= "") then scriptStartTag = string.format('\n<script type="text/lua" src="%s">\n', scriptFileName) end
    allcode = allcode .. scriptStartTag .. prettycode .. '</script>\n\n<style scoped=true>\n' .. scopedCssText .. "\n" .. GlobalCssCode .. '\n</style>';
    GlobalScope:Set("AllCode", allcode);

    -- print(allcode);
    return allcode;
end

-- 保存到文本
_G.SaveToText = function () 
    local uiText = commonlib.sea
    local LogicText = BlocklyElement:SaveToXmlNodeText();

    _G.ListItemDataMap[WindowItemData.id] = WindowItemData;
    local obj = {
        ListItemDataMap = _G.ListItemDataMap,
        LogicText = LogicText,
    }

    -- echo(obj, true);

    return commonlib.serialize_compact(obj);
end

-- 从文本加载
_G.LoadFromText = function (text)
    _G.Reset();

    ElementId = 0;
    
    local windowItemData = GenerateWindowItemData();
    local obj = NPL.LoadTableFromString(text) or {};

    local list = {};
    _G.ListItemDataMap = obj.ListItemDataMap or {};
    _G.ListItemDataMap[windowItemData.id] = _G.ListItemDataMap[windowItemData.id] or windowItemData;
    for key, item in pairs(_G.ListItemDataMap) do
        if (item.isWindowItemData) then 
            _G.WindowItemData = item;
        else 
            table.insert(list, {id = item.id, text = item.text, tagname = item.tagname});
            local id = tonumber(string.match(item.id, "%d+")) or 0;
            ElementId = ElementId < id and id or ElementId;
        end
        item.order = item.order or ElementId;
    end
    GlobalScope:Set("ElementList", list);

    _G.ListItemDataMap[WindowItemData.id] = WindowItemData;
    SetCurrentElement(WindowElement);

    BlocklyElement:LoadFromXmlNodeText(obj.LogicText);
end
