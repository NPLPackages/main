
--[[
Title: UIBlock
Author(s): wxa
Date: 2021/3/1
Desc: Lua
use the lib:
-------------------------------------------------------
local LanguageConfig = NPL.load("script/ide/System/UI/Blockly/Blocks/LanguageConfig.lua");
-------------------------------------------------------
]]

local npl_0_0_0 = NPL.load("./LanguageConfigs/npl_0_0_0.lua");
-- local npl_1_0_1 = NPL.load("./LanguageConfigs/npl_1_0_1.lua");
local npl_junior_0_0_0 = NPL.load("./LanguageConfigs/npl_junior_0_0_0.lua");
local cad_0_0_0 = NPL.load("./LanguageConfigs/cad_0_0_0.lua");
local cad_1_0_0 = NPL.load("./LanguageConfigs/cad_1_0_0.lua");
local cad_1_0_1 = NPL.load("./LanguageConfigs/cad_1_0_1.lua");
local mcml_0_0_0 = NPL.load("./LanguageConfigs/mcml_0_0_0.lua");
local mcml_0_0_1 = NPL.load("./LanguageConfigs/mcml_0_0_1.lua");

local LanguageConfig = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

local all_language_version_config = {};

local all_language_name_map = {
    [""] = "npl", ["npl"] = "npl", ["codeblock"] = "npl",
    ["npl_junior"] = "npl_junior",
    ["mcml"] = "mcml", ["html"] = "mcml",
    ["old_cad"] = "cad", ["old_npl_cad"] = "cad",
    ["npl_cad"] = "cad", ["cad"] = "cad", 
    ["game_inventor"] = "game_inventor",
    ["npl_python"] = "python", ["python"] = "python", ["micropython"] = "micropython",

    ["CustomCurrentBlock"] = "custom_npl", 
    ["CustomWorldBlock"] = "custom_npl", 
    ["SystemLuaBlock"] = "custom_npl", 
    ["SystemNplBlock"] = "custom_npl", 
    ["SystemUIBlock"] = "custom_npl", 
    ["SystemGIBlock"] = "custom_npl", 
    ["SystemGIBlock"] = "custom_npl", 
    ["block"] = "custom_npl", 
}

local all_language_latest_version_map = {
    -- ["npl"] = "1.0.1",
    ["npl"] = "1.0.0",
    ["cad"] = "1.0.1",
    ["npl_junior"] = "1.0.0",
    ["mcml"] = "0.0.1",
}

local all_language_type_map = {
    ["npl"] = "npl",
    ["mcml"] = "html",
    ["commands"] = "cmd",
}

local function SetLanguageConfigToolboxXmlText(language, version, toobox_xmltext)
    all_language_version_config[language] = all_language_version_config[language] or {};
    all_language_version_config[language][version] = all_language_version_config[language][version] or {}; 
    all_language_version_config[language][version].toobox_xmltext = toobox_xmltext;
end

function LanguageConfig:ctor()
    -- print("=======================Blockly LanguageConfig Init============================")
    SetLanguageConfigToolboxXmlText(npl_0_0_0.language, npl_0_0_0.version, npl_0_0_0.toolbox_xmltext);
    -- SetLanguageConfigToolboxXmlText(npl_1_0_1.language, npl_1_0_1.version, npl_1_0_1.toolbox_xmltext);
    SetLanguageConfigToolboxXmlText(npl_junior_0_0_0.language, npl_junior_0_0_0.version, npl_junior_0_0_0.toolbox_xmltext);
    SetLanguageConfigToolboxXmlText(cad_0_0_0.language, cad_0_0_0.version, cad_0_0_0.toolbox_xmltext);
    SetLanguageConfigToolboxXmlText(cad_1_0_0.language, cad_1_0_0.version, cad_1_0_0.toolbox_xmltext);
    SetLanguageConfigToolboxXmlText(cad_1_0_1.language, cad_1_0_1.version, cad_1_0_1.toolbox_xmltext);
    SetLanguageConfigToolboxXmlText(mcml_0_0_0.language, mcml_0_0_0.version, mcml_0_0_0.toolbox_xmltext);
    SetLanguageConfigToolboxXmlText(mcml_0_0_1.language, mcml_0_0_1.version, mcml_0_0_1.toolbox_xmltext);
end

function LanguageConfig:GetToolBoxXmlText(language, version)
    local language_version_config = all_language_version_config[language or "npl"];
    if (not language_version_config) then return "" end
    local config = language_version_config[version or "0.0.0"] or language_version_config["0.0.0"];
    return config.toobox_xmltext;
end

function LanguageConfig:GetLanguageName(lang)
    return all_language_name_map[lang or ""] or lang or "";
end

function LanguageConfig:GetVersion(lang)
    local lang_name = self:GetLanguageName(lang);
    return all_language_latest_version_map[lang_name] or "0.0.0"; 
end

function LanguageConfig:GetLanguageType(lang)
    local lang_name = self:GetLanguageName(lang);
    return all_language_type_map[lang_name] or "npl";
end

function LanguageConfig:IsSupportScratch(lang)
    local lang_name = self:GetLanguageName(lang);
    if(lang_name == "npl" or lang_name == "cad" or lang_name == "npl_junior" or lang_name == "mcml" or lang_name == "game_inventor") then return true end

    if (lang_name == "custom_npl") then return false end

    -- 不在指定范围内则为代码定制语言如孙子兵法  所以默认返回true
    return true;
end

LanguageConfig:InitSingleton();

--[[
更新图块步骤:
1 添加语言版本配置 SetLanguageConfigToolboxXmlText 
2 变更最新版本集 all_language_latest_version_map LanguageConfig:GetVersion(lang)
]]
