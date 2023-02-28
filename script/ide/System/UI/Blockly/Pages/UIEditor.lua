

local UIManager = NPL.load("./UIManager.lua", IsDevEnv);

local Window = GetWindow();
local screenX, screenY, screenWidth, screenHeight = Window:GetScreenPosition();
local PreviewWindowWidth, PreviewWindowHeight = 500, 400;
local PreviewWindowLeft, PreviewWindowTop = screenX + screenWidth - PreviewWindowWidth, screenY + 42;

local PreviewWindow = nil;
PreviewWindow = ShowWindow({
    OnWindowSizeChange = function(width, height)
        screenX, screenY, screenWidth, screenHeight = Window:GetScreenPosition();
        PreviewWindowWidth, PreviewWindowHeight = width, height;
        PreviewWindowLeft, PreviewWindowTop = screenX + screenWidth - PreviewWindowWidth, screenY + 42;
        PreviewWindow:GetG().SetWindowSize(PreviewWindowLeft, PreviewWindowTop, PreviewWindowWidth, PreviewWindowHeight);
    end,
}, {
    url = "%ui%/Blockly/Pages/UIPreview.html", 
    alignment = "_lt", 
    x = PreviewWindowLeft, 
    y = PreviewWindowTop, 
    width = PreviewWindowWidth, 
    height = PreviewWindowHeight, 
    zorder = 10,
    windowName = "UIPreview",
});

local BlocklyHtml, BlocklyLua, BlocklyCss = nil, nil;
local BlockHtmlCode, BlocklyLuaCode = "", "";
local DefaultUIFileName = "UI";
FileNameList = UIManager.GetFileNameList();
BlocklyCode = "";
CurrentUIFileName = "";

local function GenerateComponentDefineCode()
    BlocklyCode = string.format([[
%s

<script>
%s
</script>
    ]], BlockHtmlCode, BlocklyLuaCode);

    if (not PreviewWindow:GetNativeWindow()) then
        PreviewWindow:Show();
    end
    
    local PreviewWindowG = PreviewWindow:GetG();
    if (type(PreviewWindowG.SetTemplateCode) == "function") then
        PreviewWindowG.SetTemplateCode(BlocklyCode);
    end
end

function OnBlocklyHtmlChange()
    local rawcode, prettycode = BlocklyHtml:GetCode();
    BlockHtmlCode = rawcode;
    GenerateComponentDefineCode();
end

function OnBlocklyLuaChange()
    local rawcode, prettycode = BlocklyLua:GetCode();
    BlocklyLuaCode = prettycode;
    GenerateComponentDefineCode();
end


function OnReady()
    BlocklyHtml = GetRef("BlocklyHtml");
    BlocklyLua = GetRef("BlocklyLua");

    OnUIEdit(DefaultUIFileName);
end

function ClickSaveBtn()
    local HtmlXmlText = BlocklyHtml:SaveToXmlNodeText();
    local LuaXmlText = BlocklyLua:SaveToXmlNodeText();
    UIManager.SetUIByFileName(CurrentUIFileName, {HtmlXmlText = HtmlXmlText, LuaXmlText = LuaXmlText})
    local ok = UIManager.SaveUI(CurrentUIFileName);
    GameLogic.AddBBS("UIEditor", string.format("%s 保存成功", CurrentUIFileName));
end

function OnUICreate(filename)
end

function OnUIEdit(filename)
    if (filename == CurrentUIFileName) then return end
    CurrentUIFileName = filename;
    local ui = UIManager.GetUIByFileName(CurrentUIFileName) or {};
    BlocklyHtml:LoadFromXmlNodeText(ui.HtmlXmlText or "");
    BlocklyLua:LoadFromXmlNodeText(ui.LuaXmlText or "");
    ContentType = 'BlocklyHtml'
    OnBlocklyHtmlChange();
    OnBlocklyLuaChange();
    GenerateComponentDefineCode();
end

function OnUIDelete(filename)
    UIManager.DeleteUI(filename);
    OnUIEdit(DefaultUIFileName);
end