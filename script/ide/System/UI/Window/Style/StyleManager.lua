--[[
Title: StyleManager
Author(s): wxa
Date: 2020/6/30
Desc: 样式管理类
use the lib:
-------------------------------------------------------
local StyleManager = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/StyleManager.lua");
-------------------------------------------------------
]]

local DefaultStyle = NPL.load("./DefaultStyle.lua", IsDevEnv);
local Style = NPL.load("./Style.lua", IsDevEnv);
local StyleSheet = NPL.load("./StyleSheet.lua", IsDevEnv);

local StyleManager = commonlib.inherit(nil, NPL.export());


function StyleManager:ctor()
    self.styleSheets = {self:GetStyleSheetByString(DefaultStyle.GetDefaultStyleString())};  -- 样式表集
end

function StyleManager:NewStyleSheet()
    return StyleSheet:new();
end

function StyleManager:GetStyleSheetByString(code)
    local styleSheet = StyleSheet:new();
    styleSheet:LoadByString(code);
    return styleSheet;
end

function StyleManager:AddStyleSheetByString(code)
    return self:AddStyleSheet(self:GetStyleSheetByString(code));
end

function StyleManager:AddStyleSheet(styleSheet)
    table.insert(self.styleSheets, styleSheet);
    return styleSheet;
end

function StyleManager:RemoveStyleSheet(styleSheet)
    for i, sheet in ipairs(self.styleSheets) do
        if (sheet == styleSheet) then
            table.remove(self.styleSheets, i);
            break;
        end
    end
    return styleSheet;
end

function StyleManager:Clear()
    self.styleSheets = {};
end

function StyleManager:ApplyElementStyle(element, style)
    for _, sheet in ipairs(self.styleSheets) do
        sheet:ApplyElementStyle(element, style);
    end
end

function StyleManager:ApplyElementAnimationStyle(element, style)
    for _, sheet in ipairs(self.styleSheets) do
        sheet:ApplyElementAnimationStyle(element, style);
    end
end