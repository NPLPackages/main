--[[
Title: UIBlock
Author(s): wxa
Date: 2021/3/1
Desc: Lua
use the lib:
-------------------------------------------------------
local UIBlock = NPL.load("script/ide/System/UI/Blockly/Blocks/UIBlock.lua");
-------------------------------------------------------
]]


local UIBlock = NPL.export();

local function GetUI(cache)
    cache.UI = cache.UI or {};
    return cache.UI;
end

local function InitCode(cache)
    local UI = GetUI(cache);
    if (not UI.inited) then
        UI.inited = true;
        if (IsDevEnv) then
            return 'local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua", true)\n';
        else
            return 'local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua")\n';
        end
    end
    return "";
end

local UI_Style_Item = {};
local Style_Key_Options = {
    {"宽", "width"}, 
    {"高", "height"}, 
    {"显示方式", "display"},
    {"弹性布局方向", "flex-direction"},
    {"主轴排列方式", "justify-content"},
    {"辅助排列方式", "align-items"},
    {"字体大小", "font-size"},
}
local Style_Value_Options = {
    ["display"] = { "flex", "block", "inline-block", "inline"},
    ["flex-direction"] = { "row", "column"},
    ["justify-content"] = {"center", "space-between", "space-around","flex-start", "flex-end"},
    ["align-items"] = {"center", "space-between", "space-around","flex-start", "flex-end"},
    ["font-size"] = {"10px", "12px", "14px", "16px", "18px", "20px", "24px", "28px", "30px", "36px", "40px", "50px"},
}

local function Style_Value_Options_Func(field)
    local block = field:GetBlock();
    local defaultOptions = {};
    if (not block) then return defaultOptions end
    local key = block:GetFieldValue("key") or "";
    return Style_Value_Options[key] or defaultOptions;
end

function UI_Style_Item.OnInit(option)
    local arg = option.arg;
    if (type(arg) ~= "table") then return end
    for _, field in ipairs(arg) do
        if (field.name == "key") then
            field.options = Style_Key_Options;
            field.isAllowCreate = true;
        end
        if (field.name == "value") then
            field.options = Style_Value_Options_Func;
            field.isAllowCreate = true;
        end
    end
end

local function UI_Element_Attr_Click_CallBack(field)
    local left, top = field:GetScreenXY();
    local oldLabel,oldValue = field:GetLabel(), field:GetValue();
    local obj = NPL.LoadTableFromString(oldValue);
    local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
    local function OnBlocklyChange(codetext, xmltext)
        local codes = commonlib.split(codetext, "\n");
        local attr, style = "", "";
        for _, text in ipairs(codes) do
            if (not (string.find(text, "=", 1, true))) then
                style = style .. text .. " ";
            else 
                attr = attr .. text .. " ";
            end
        end
        local label = attr .. (style ~= "" and string.format('style="%s"', style) or "");
        local value = commonlib.serialize_compact({code=code, xmltext = xmltext});
        field:SetLabel(label);
        field:SetValue(value);
        if (oldValue ~= value or oldLabel ~= label) then
            field:GetTopBlock():UpdateLayout();
            field:GetBlockly():OnChange();
        end
    end
    Page.Show({
        Left = left, Top = top,
        XmlText = obj and obj.xmltext,
        OnBlocklyChange = OnBlocklyChange,
    }, {
        url = "%ui%/Blockly/Pages/FieldEditBlockly.html",  
        width = "100%", 
        height = "100%", 
        zorder = 100,
        draggable = false,
    });
end

local function UI_Element_Attr_Click_Register(option, fieldName)
    local arg = option.arg;
    if (type(arg) ~= "table") then return end
    fieldName = fieldName or "attr";
    for _, field in ipairs(arg) do
        if (field.type == "field_button" and field.name == fieldName) then
            field.OnClick = UI_Element_Attr_Click_CallBack;
            field.value, field.label = "", "";
            break;
        end
    end
end

local UI_Element = {};
function UI_Element.ToCode(block)
    local cache = block:GetToCodeCache();
    local fieldTag = block:GetFieldValue("tag");
    local fieldAttr = block:GetFieldLabel("attr");
    return string.format('<%s %s></%s>\n', fieldTag, fieldAttr, fieldTag);
end

function UI_Element.OnInit(option)
    UI_Element_Attr_Click_Register(option, "attr");
end

local UI_Elements = {};
function UI_Elements.ToCode(block)
    local fieldTag = block:GetFieldValue("tag");
    local fieldContent = block:GetValueAsString("content");
    local fieldAttr = block:GetFieldLabel("attr");
    return string.format('<%s %s>\n%s</%s>\n', fieldTag, fieldAttr, fieldContent, fieldTag);
end

function UI_Elements.OnInit(option)
    UI_Element_Attr_Click_Register(option, "attr");
end

local UI_Element_Text = {};
function UI_Element_Text.ToCode(block)
    local cache = block:GetToCodeCache();
    local fieldText = block:GetFieldValue("text");
    local fieldAttr = block:GetFieldLabel("attr");
    return string.format('<div %s>%s</div>\n', fieldAttr, fieldText);
end
function UI_Element_Text.OnInit(option)
    UI_Element_Attr_Click_Register(option, "attr");
end

local UI_MCML_Element = {};
function UI_MCML_Element.ToCode(block)
    local cache = block:GetToCodeCache();
    local fieldTag = block:GetFieldValue("tag");
    local fieldAttr = block:GetFieldLabel("attr");
    return string.format('<%s %s></%s>\n', fieldTag, fieldAttr, fieldTag);
end

function UI_MCML_Element.OnInit(option)
    UI_Element_Attr_Click_Register(option, "attr");
end

local UI_MCML_Elements = {};
function UI_MCML_Elements.ToCode(block)
    local fieldTag = block:GetFieldValue("tag");
    local fieldContent = block:GetValueAsString("content");
    local fieldAttr = block:GetFieldLabel("attr");
    return string.format('<%s %s>\n%s</%s>\n', fieldTag, fieldAttr, fieldContent, fieldTag);
end

function UI_MCML_Elements.OnInit(option)
    UI_Element_Attr_Click_Register(option, "attr");
end
-- local UI_Component_Register = {};
-- function UI_Component_Register.ToCode(block)
--     local cache = block:GetToCodeCache();
--     local text = "";
--     local fieldWdith = block:GetFieldValue("width");
--     local fieldHeight = block:GetFieldValue("height");
--     local fieldHtml = block:GetFieldValue("html");
--     text = text .. string.format('<template style="width:%s; height: %s">\n%s</template>\n', fieldWdith, fieldHeight, fieldHtml);

--     local fieldScript = block:GetFieldValue("script");
--     local fieldSrc = block:GetFieldValue("src");
--     text = text .. string.format('<script src="%s">\n%s</script>', fieldSrc or "", fieldScript);

--     local selectors = GetSelectors(cache);
--     local selectorText = "";
--     for selector, text in pairs(selectors) do
--         selectorText = selectorText .. string.format("%s {%s}\n", selector, text);
--     end
--     text = text .. "\n<style scoped=true>\n" .. selectorText .. "</style>";

--     local UI = GetUI(cache);
--     local code = InitCode(cache)
--     local fieldName = block:GetFieldValue("name");
--     code = code .. string.format('Page.RegisterComponent("%s", {template = [====[\n%s\n]====]})', fieldName, text);
--     return code;
-- end

-- local UI_Window_Register = {};
-- function UI_Window_Register.ToCode(block)
--     local fieldName = block:GetFieldValue("name");
--     local fieldAlignment = block:GetFieldValue("alignment");
--     local fieldLeft = block:GetFieldValue("left");
--     local fieldTop = block:GetFieldValue("top");
--     local fieldWidth = block:GetFieldValue("width");
--     local fieldHeight = block:GetFieldValue("height");
--     local fieldHtml = block:GetFieldValue("html");

--     local cache = block:GetToCodeCache();
--     local code = InitCode(cache);
--     code = code .. string.format('Page.RegisterWindow({windowName = "%s", alignment = "%s", x = "%s", y = "%s", width = "%s", height = "%s", html = "<%s></%s>"})\n', fieldName, fieldAlignment, fieldLeft, fieldTop, fieldWidth, fieldHeight, fieldHtml, fieldHtml);
--     return code;
-- end

local UI_Window_Show_Html = {};
function UI_Window_Show_Html.ToCode(block)
    local fieldName = block:GetFieldValue("name");
    local fieldAlignment = block:GetFieldValue("alignment");
    local fieldLeft = block:GetFieldValue("left");
    local fieldTop = block:GetFieldValue("top");
    local fieldWidth = block:GetFieldValue("width");
    local fieldHeight = block:GetFieldValue("height");
    local fieldHtml = block:GetFieldValue("html");

    local code = InitCode(block:GetToCodeCache());
    code = code .. string.format('Page.RegisterWindow({windowName = "%s", alignment = "%s", x = "%s", y = "%s", width = "%s", height = "%s", html = [[%s]]})\n', fieldName, fieldAlignment, fieldLeft, fieldTop, fieldWidth, fieldHeight, fieldHtml);
    code = code ..string.format('Page.ShowWindow("%s", codeblock)\n', fieldName);
    return code;
end

UIBlock.UI_MCML_Elements = UI_MCML_Elements;
UIBlock.UI_MCML_Element = UI_MCML_Element;

UIBlock.UI_Elements = UI_Elements;
UIBlock.UI_Element = UI_Element;
UIBlock.UI_Element_Text = UI_Element_Text;
UIBlock.UI_Style_Item = UI_Style_Item;
-- UIBlock.UI_Component_Register = UI_Component_Register;
-- UIBlock.UI_Window_Register = UI_Window_Register;
UIBlock.UI_Window_Show_Html = UI_Window_Show_Html;