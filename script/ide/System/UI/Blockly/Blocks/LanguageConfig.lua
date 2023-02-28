

local LanguageConfig = NPL.export();
local ToolBoxXmlText = NPL.load("./ToolBoxXmlText.lua");

local __language_name_map__ = {
    [""] = "npl", ["npl"] = "npl",
    ["npl_junior"] = "npl_junior",
    ["mcml"] = "mcml", ["html"] = "mcml",
    ["old_cad"] = "cad", ["old_npl_cad"] = "cad",
    ["npl_cad"] = "cad", ["cad"] = "cad", 
    ["game_inventor"] = "game_inventor",

    ["CustomWorldBlock"] = "custom_npl", 
    ["SystemLuaBlock"] = "custom_npl", 
    ["SystemNplBlock"] = "custom_npl", 
    ["SystemUIBlock"] = "custom_npl", 
    ["SystemGIBlock"] = "custom_npl", 
    ["SystemGIBlock"] = "custom_npl", 
    ["block"] = "custom_npl", 
}

function LanguageConfig.GetLanguageName(lang)
    return __language_name_map__[lang or ""] or lang or "";
end

local __language_type_map__ = {
    ["npl"] = "npl",
    ["mcml"] = "html" ,
}

function LanguageConfig.GetLanguageType(lang)
    local lang_name = LanguageConfig.GetLanguageName(lang);
    return __language_type_map__[lang_name] or "npl";
end

local __language_version_map__ = {
    ["npl"] = "1.0.0",
    ["cad"] = "1.0.0",
    ["npl_junior"] = "1.0.0",
}

function LanguageConfig.GetVersion(lang)
    local lang_name = LanguageConfig.GetLanguageName(lang);
    return __language_version_map__[lang_name] or "0.0.0"; 
end

function LanguageConfig.IsSupportScratch(lang)
    local lang_name = LanguageConfig.GetLanguageName(lang);
    if(lang_name == "npl" or lang_name == "cad" or lang_name == "npl_junior" or lang_name == "mcml" or lang_name == "game_inventor") then return true end

    if (lang_name == "custom_npl") then return false end

    -- 不在指定范围内则为代码定制语言如孙子兵法  所以默认返回true
    return true;
end

function LanguageConfig.GetToolBoxXmlText(lang, version)
    local lang_name = LanguageConfig.GetLanguageName(lang);
    return ToolBoxXmlText.GetXmlText(lang_name, version);
end