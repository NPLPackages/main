--[[
Title: StyleManager
Author(s): wxa
Date: 2020/6/30
Desc: 样式管理类
use the lib:
-------------------------------------------------------
local StyleSheet = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Style/StyleSheet.lua");
-------------------------------------------------------
]]

local Style = NPL.load("./Style.lua", IsDevEnv);
local StyleSheet = commonlib.inherit(nil, NPL.export());
local StyleSheetDebug = GGS.Debug.GetModuleDebug("StyleSheetDebug").Enable();   --Enable  Disable

local function StringTrim(str, ch)
    ch = ch or "%s";
    str = string.gsub(str, "^" .. ch .. "*", "");
    str = string.gsub(str, ch .. "*$", "");
    return str;
end

-- 获取尾部选择器
local function GetTailSelector(comboSelector)
    if (not comboSelector) then return end

    comboSelector = string.gsub(comboSelector, "%s*$", "");
    
    -- 伪类选择器
    selector = string.match(comboSelector, ":nth%-child%((%d-)%)$");
    if (selector) then return selector, "nth-child", string.gsub(comboSelector, ":nth%-child%(%d-%)$", "") end 
    
    -- 属性选择器
    selector = string.match(comboSelector, "%[([%w%d=]-)%]$");
    if (selector) then return selector, "[", string.gsub(comboSelector, "%[[%w%d=]-%]$", "") end

    -- 后代选择器 div p
    local selector = string.match(comboSelector, "%s* ([^%s%+%~%>]-)$");
    if (selector) then return selector, " ", string.gsub(comboSelector, "%s* [^%s%+%~%>]-$", "") end

    -- 子选择器 div>p
    selector = string.match(comboSelector, "%s*%>%s*([^%s%+%~%>]-)$");
    if (selector) then return selector, ">", string.gsub(comboSelector, "%s*%>%s*[^%s%+%~%>]-$", "") end

    -- 后续兄弟选择器 div~p
    selector = string.match(comboSelector, "%s*%~%s*([^%s%+%~%>]-)$");
    if (selector) then return selector, "~", string.gsub(comboSelector, "%s*%~%s*[^%s%+%~%>]-$", "") end

    -- 相邻兄弟选择器 div+p
    selector = string.match(comboSelector, "%s*%+%s*([^%s%+%~%>]-)$");
    if (selector) then return selector, "+", string.gsub(comboSelector, "%s*%+%s*[^%s%+%~%>]-$", "") end
   
    return nil;
end

-- 是否是有效的元素选择器
local function IsValidElementSelector(selector, element, selectorType)
    local elementSelector = element:GetSelector();
    if (not selector) then return false end
    
    if (selectorType == "nth-child") then
        selector = tonumber(selector);
        if (selector == element:GetIndexInParentElement()) then return true end 
        return false;
    elseif (selectorType == "[") then
        local attrKey, attrVal = string.match(selector, "(%w+)=(%w+)");
        local realAttrValue = element:GetAttrStringValue(attrKey);
        if (realAttrValue ~= attrVal) then return false end
        return true;
    end

    if (not elementSelector[selector]) then return false end
    if ((string.match(selector, ":hover%s*$")) and not element:IsHover()) then return false end
    return true;
end

-- 是否是祖先元素的选择器
local function IsAncestorElementSelector(element, selector)
    local parentElement = element:GetParentElement();
    if (not parentElement) then return false end
    if (IsValidElementSelector(selector, parentElement)) then return true, parentElement end
    return IsAncestorElementSelector(parentElement, selector);
end

-- 是否是元素的选择器
local function IsElementSelector(comboSelector, element)
    local selector, selectorType, newComboSelector = GetTailSelector(comboSelector, element);
    if (not IsValidElementSelector(selector, element, selectorType)) then return false end
    local newSelector, newSelectorType = GetTailSelector(newComboSelector);
    newSelector = StringTrim(newSelector or newComboSelector);
    -- 后代选择器 div p
    if (selectorType == " ") then
        local isAncestorElementSelector, ancestorElement = IsAncestorElementSelector(element, newSelector);
        if (not isAncestorElementSelector) then return false end
        if (not newSelectorType) then return true end
        return IsElementSelector(newComboSelector, ancestorElement);
    end

    -- 子选择器 div>p
    if (selectorType == ">") then
        local parentElement = element:GetParentElement();
        if (not parentElement) then return false end
        if (not IsValidElementSelector(newSelector, parentElement)) then return false end
        if (not newSelectorType) then return true end
        return IsElementSelector(newComboSelector, parentElement);
    end

    -- 后续兄弟选择器 div~p
    if (selectorType == "~") then
        local prevSiblingElement = element:GetPrevSiblingElement();
        while (prevSiblingElement) do
            if (IsValidElementSelector(newSelector, prevSiblingElement)) then break end
            prevSiblingElement = prevSiblingElement:GetPrevSiblingElement();
        end
        if (not prevSiblingElement) then return false end
        if (not newSelectorType) then return true end
        return IsElementSelector(newComboSelector, prevSiblingElement);
    end

    -- 相邻兄弟选择器 div+p
    if (selectorType == "+") then
        -- StyleSheetDebug.If(element:GetAttrStringValue("id") == "debug", "--------------------------------------1");
        local prevSiblingElement = element:GetPrevSiblingElement();
        if (not prevSiblingElement) then return false end
        -- StyleSheetDebug.If(element:GetAttrStringValue("id") == "debug", "--------------------------------------2", prevSiblingElementSelector, newSelector, newComboSelector, selector, comboSelector);
        if (not IsValidElementSelector(newSelector, prevSiblingElement)) then return false end
        -- StyleSheetDebug.If(element:GetAttrStringValue("id") == "debug", "--------------------------------------3");
        if (not newSelectorType) then return true end
        -- StyleSheetDebug.If(element:GetAttrStringValue("id") == "debug", "--------------------------------------4");
        return IsElementSelector(newComboSelector, prevSiblingElement);
    end

    if (newSelector == "" or IsValidElementSelector(newSelector, element)) then return true end
     
    return IsElementSelector(newSelector, element);
end

function StyleSheet:ctor()
    self.SelectorStyle = {};
    self.AnimationStyle = {};
end

function StyleSheet:LoadByString(code)
    code = string.gsub(code,"/%*.-%*/","");
    local csscode, lastCssCodePos, codelen = "", 1, string.len(code);
    -- 查找动画关键字
    local startPos, endPos = string.find(code, "@keyframes", 1, true);
    if (not startPos) then csscode = code end
    while(startPos) do
        local animationName = string.match(string.sub(code, endPos + 1), "([^{}]+)");
        local index, count = string.find(code, "{", endPos + string.len(animationName), true), 1;
        local sp, ep = nil, nil;
        while (index and index < codelen) do
            index = index + 1;
            if (sp == nil) then sp = index end 
            local ch = string.sub(code, index, index);
            if (ch == "{") then count = count + 1 end
            if (ch == "}") then count = count - 1 end
            if (count == 0) then 
                ep = index - 1 
                break;
            end
        end
        local animationCss = string.sub(code, sp, ep);
        animationName = string.match(animationName, "^%s*(.-)%s*$");
        local animation = self.AnimationStyle[animationName] or {};
        self.AnimationStyle[animationName] = animation;

        -- print(animationName);
        -- print(animationCss);

        for selector_str, declaration_str in string.gmatch(animationCss, "([^{}]+){([^{}]+)}") do
            local style = Style.ParseString(declaration_str);
            for selector in string.gmatch(selector_str, "([^,]+),?") do
                selector = string.match(selector, "^%s*(.-)%s*$");
                if (selector == "from") then selector = 0
                elseif (selector == "to") then selector = 100
                else 
                    selector = string.match(selector, "(%d+)");
                    selector = selector and tonumber(selector) or 0;
                end
                style.percentage = selector;
                table.insert(animation, style);
            end
        end
        table.sort(animation, function(item1, item2) return item1.percentage < item2.percentage end);

        csscode = csscode .. string.sub(lastCssCodePos, startPos - 1);
        startPos, endPos = string.find(code, "@keyframes", index + 1, true);
        if (not startPos) then 
            csscode = csscode .. string.sub(code, index + 1);
        else 
            lastCssCodePos = index + 1;
        end
    end

    for selector_str, declaration_str in string.gmatch(code, "([^{}]+){([^{}]+)}") do
        local style = Style.ParseString(declaration_str);
        for selector in string.gmatch(selector_str, "([^,]+),?") do
            selector = string.match(selector, "^%s*(.-)%s*$");
            self.SelectorStyle[selector] = style;
        end
    end
    return self;
end

-- 设置基础样式表
function StyleSheet:SetInheritStyleSheet(sheet)
    self.InheritStyleSheet = sheet;
end

-- 生效选择器样式
function StyleSheet:ApplySelectorStyle(selector, style, element)
    -- 选择器默认样式
    local selectorStyle = self.SelectorStyle[selector];
    if (selectorStyle) then Style.CopyStyle(style:GetNormalStyle(), selectorStyle) end

    -- 选择器激活样式
    selectorStyle = self.SelectorStyle[selector .. ":active"];
    if (selectorStyle) then Style.CopyStyle(style:GetActiveStyle(), selectorStyle) end
    -- 选择器悬浮样式
    selectorStyle = self.SelectorStyle[selector .. ":hover"];
    if (selectorStyle) then Style.CopyStyle(style:GetHoverStyle(), selectorStyle) end

    -- 选择器聚焦样式
    selectorStyle = self.SelectorStyle[selector .. ":focus"];
    if (selectorStyle) then Style.CopyStyle(style:GetFocusStyle(), selectorStyle) end

    -- 滚动条样式
    local scrollBarStyle = element:GetScrollBarStyle();
    selectorStyle = self.SelectorStyle[selector .. "::scrollbar"];
    if (selectorStyle) then Style.CopyStyle(scrollBarStyle["scrollbar"], selectorStyle) end
    selectorStyle = self.SelectorStyle[selector .. "::scrollbar-thumb"];
    if (selectorStyle) then Style.CopyStyle(scrollBarStyle["scrollbar-thumb"], selectorStyle) end
    
    -- 标记选择器
    local elementSelector = element:GetSelector();
    elementSelector[selector] = true;
    elementSelector[selector .. ":active"] = true;
    elementSelector[selector .. ":hover"] = true;
    elementSelector[selector .. ":focus"] = true;
end

-- 生效类选择器样式
function StyleSheet:ApplyClassSelectorStyle(element, style)
    local classes = element:GetAttrStringValue("class",  "");

    -- StyleSheetDebug.If(element:GetTagName() == "GoodsTooltip", classes, self.SelectorStyle);
    
    for class in string.gmatch(classes, "%s*([^%s]+)%s*") do 
        self:ApplySelectorStyle("." .. class, style, element);
    end
end

-- 生效组合选择器样式
function StyleSheet:ApplyComboSelectorStyle(element, style)
    -- 组合样式 
    for selector in pairs(self.SelectorStyle) do
        if (IsElementSelector(selector, element)) then
            self:ApplySelectorStyle(selector, style, element);
        end
    end
end

-- 生效标签名选择器样式
function StyleSheet:ApplyTagNameSelectorStyle(element, style)
    local tagname = string.lower(element:GetTagName() or "");

    self:ApplySelectorStyle(tagname, style, element);
end

-- 生效ID选择器样式
function StyleSheet:ApplyIdSelectorStyle(element, style)
    local id = element:GetAttrStringValue("id",  "");

    if (type(id) == "string" and id ~= "") then 
        self:ApplySelectorStyle("#" .. id, style, element);
    end
end

-- 应用元素样式
function StyleSheet:ApplyElementStyle(element, style)
    local elementSelector = element:GetSelector();
    for key in pairs(elementSelector) do elementSelector[key] = false end
    
    local function ApplyElementStyle(sheet, element, style)
        -- 先生效基类样式
        if (sheet.InheritStyleSheet) then ApplyElementStyle(sheet.InheritStyleSheet, element, style) end

        -- 通配符*选择器
        sheet:ApplySelectorStyle("*", style, element);

        -- 便签选择器
        sheet:ApplyTagNameSelectorStyle(element, style);

        -- 类选择器
        sheet:ApplyClassSelectorStyle(element, style);
    
        -- ID选择器
        sheet:ApplyIdSelectorStyle(element, style);

        -- 选择器组合
        sheet:ApplyComboSelectorStyle(element, style);
    end

    ApplyElementStyle(self, element, style);
end

-- 应用元素动画
function StyleSheet:ApplyElementAnimationStyle(element, style)
    local animationName = style:GetAnimationName();
    local function GetAnimation(sheet)
        if (not sheet) then return nil end

        local animation = sheet.AnimationStyle[animationName];
        if (animation) then return animation end

        return GetAnimation(sheet.InheritStyleSheet);
    end

    element:GetAnimation():SetKeyFrames(GetAnimation(self));
end

function StyleSheet:Clear()
    self.SelectorStyle = {};
    self.AnimationStyle = {};
end