--[[
Title: page
Author(s): wxa
Date: 2020/6/30
Desc: main file to create user interface
use the lib:
-------------------------------------------------------
local Page = NPL.load("script/ide/System/UI/Page.lua");
Page.ShowVueTestPage(nil, {url = "%vue%/Example/Select.html"})
Page.ShowUserInfoPage({username="xiaoyao"});
-------------------------------------------------------
]]
local Vue = NPL.load("script/ide/System/UI/Vue/Vue.lua");
local Page = NPL.export();
local pages = {};
local __auto_close_pages__ = {};
local _3d_pages = {};
local inited = false;
local windows = {};

if (IsDevEnv) then
    _G.pages = _G.pages or {};
    pages = _G.pages;

    for _, page in pairs(_G.__auto_close_pages__ or {}) do
        page:CloseWindow();
    end
    _G.__auto_close_pages__ = __auto_close_pages__;
end

local function OnWorldLoaded()
end

local function OnWorldUnloaded()
    for _, page in pairs(_3d_pages) do 
        page:CloseWindow();
    end

    for _, page in ipairs(__auto_close_pages__) do
        page:CloseWindow();
    end
end

function Page.RegisterComponent(tagname, tagclass)
    Vue.Register(tagname, tagclass);
end

function Page.RegisterWindow(params)
    local window = {params = params, G = params.G};
    windows[params.windowName] = window;
end

function Page.ShowWindow(windowName, codeblock)
    local window = windows[windowName];
    if (not window) then return end
    if (window.page) then window.page:CloseWindow() end 
    window.page = Page.Show(window.G, window.params);

    if (codeblock and not window.isRegisterCodeBlockStopEvent) then
        window.isRegisterCodeBlockStopEvent = true;
        codeblock:Connect("codeUnloaded", function()
            Page.CloseWindow(windowName);
        end);
    end
end

-- 关闭窗口
function Page.CloseWindow(windowName)
    local window = windows[windowName];
    if (not window or not window.page) then return end
    window.page:CloseWindow();
end

function Page.GetWindow(windowName)
    local window = windows[windowName];
    return window and window.page;
end

function Page.StaticInit()
    if (inited) then return end
    inited = true;

    GameLogic:Connect("WorldLoaded", nil, OnWorldLoaded, "UniqueConnection");
    GameLogic:Connect("WorldUnloaded", nil, OnWorldUnloaded, "UniqueConnection");
end

function Page.BindPageToBlockSign(blockX, blockY, blockZ, page)
    if (not blockX or not blockY or not blockZ or not page) then return end
    local entity = GameLogic.BlockEngine:GetBlockEntity(blockX, blockY, blockZ); 
    if (not entity) then return print("3D 实体不存在") end
    entity.cmd = "<div></div>";
    entity:Refresh();
    local obj = entity:GetInnerObject();
    obj:ShowHeadOnDisplay(true, 0);
    obj:SetHeadOnUITemplateName(page:GetWindowId(), 0);
    obj:SetHeadOnOffset(0, 0.42, 0.37, 0);
    obj:SetField("HeadOn3DFacing", -1.57);
end

-- show a page 
function Page.Show(G, params, isNew)
    params = params or {};
    local key = params.html or params.template or params.url;
    if (not key) then return end
    
    if (not isNew and pages[key] and pages[key]:GetNativeWindow()) then pages[key]:CloseWindow() end
    local page = (not IsDevEnv and pages[key]) and pages[key] or Vue:new();
    if (isNew) then 
        page = Vue:new();
    else
        pages[key] = page;
    end

    params.G = G;
    page:Show(params);
    return page;
end

function Page.ShowUserInfoPage(G, params)
    local userId = G and G.userId 
    local username = G and G.username or ""
    local UserInfoPage = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/User/UserInfoPage.lua");
    if UserInfoPage then
        UserInfoPage.ShowPage(username,nil,userId)
    end
end

local DebugInfoPage;
function Page.ShowDebugInfoPage(G, params)
    DebugInfoPage = DebugInfoPage or Vue:new();
    params = params or {};

    params.url = "%vue%/Page/Debug/DebugInfo.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or 600;
    params.height = params.height or 500;
    DebugInfoPage:Show(params);

    return DebugInfoPage;
end

local BlocklyPage
function Page.ShowBlocklyPage(G, params)
    BlocklyPage = BlocklyPage or Vue:new();
    if (IsDevEnv) then
        if (_G.BlocklyPage) then
            _G.BlocklyPage:CloseWindow();
        end        
        _G.BlocklyPage = BlocklyPage;
    end

    params = params or {};

    params.url = "%ui%/Blockly/Pages/Blockly.html";
    params.draggable = true;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    BlocklyPage:Show(params);

    return BlocklyPage;
end

local BlocklyFactoryPage
function Page.ShowBlocklyFactoryPage()
    BlocklyFactoryPage = BlocklyFactoryPage or Vue:new(G, params);
    params = params or {};

    params.url = "%ui%/Blockly/Pages/BlocklyFactory.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or 1200;
    params.height = params.height or 800;
    params.windowName = "__BlocklyFactory__";
    BlocklyFactoryPage:Show(params);
    return BlocklyFactoryPage;
end

local VueTestPage;
function Page.ShowVueTestPage(G, params)
    VueTestPage = VueTestPage or Vue:new();
    if (IsDevEnv) then
        if (_G.VueTestPage) then
            _G.VueTestPage:CloseWindow();
        end        
        _G.VueTestPage = VueTestPage;
    end

    params = params or {};
    -- params.draggable = false;
    params.url = params.url or "%vue%/Example/Test.html";
    params.G = G;
    params.width = params.width or 600;
    params.height = params.height or 500;
    VueTestPage:Show(params);

    return VueTestPage;
end

local MessageBoxPage
function Page.ShowMessageBoxPage(G)
    MessageBoxPage = MessageBoxPage or Vue:new();
    local params = {};
    
    params.G = G;
    params.url = "%ui%/Page/Common/MessageBox.html";
    params.draggable=false;
    params.width = "80%";
    params.height = "80%";
    params.zorder = 2;
    
    MessageBoxPage:Show(params);

    return MessageBoxPage;
end

local UIEditorPage;
function Page.ShowUIEditorPage(G, params)
    UIEditorPage = UIEditorPage or Vue:new();
    params = params or {};
    params.url = "%ui%/Blockly/Pages/UIEditor.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    UIEditorPage:Show(params);
    return UIEditorPage;
end

local SubTitlePage
function Page.ShowSubTitlePage(G, params)
    SubTitlePage = SubTitlePage or Vue:new();
    params = params or {};
    G = G or {};

    if (not G.text or G.text == "") then return end 
    
    G.isPlayVoice = if_else(G.isPlayVoice == nil, true, G.isPlayVoice);
    G.isAutoClose = if_else(G.isAutoClose == nil, true, G.isAutoClose);

    params.url = "%ui%/Page/Common/SubTitle.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or 200;
    params.alignment = "_lb";

    if (IsDevEnv) then
        if (_G.VueTestPage) then
            _G.VueTestPage:CloseWindow();
        end        
        _G.VueTestPage = SubTitlePage;
    end

    SubTitlePage:Show(params);
    return SubTitlePage; 
end

local ShenTongBeiPage;
function Page.ShowShenTongBeiPage(G, params)
    ShenTongBeiPage = ShenTongBeiPage or Vue:new();
    __auto_close_pages__[ShenTongBeiPage] = ShenTongBeiPage;

    params = params or {};
    params.url = "%ui%/App/RedSummerCamp/ShenTongBei.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    params.fixedRootScreenWidth = params.fixedRootScreenWidth or 1280;
    params.fixedRootScreenHeight = params.fixedRootScreenHeight or 720;
    ShenTongBeiPage:Show(params);
    return ShenTongBeiPage;
end

local ShenTongBeiCourePage
function Page.ShowShenTongBeiCourePage()
    ShenTongBeiCourePage = ShenTongBeiCourePage or Vue:new();
    __auto_close_pages__[ShenTongBeiCourePage] = ShenTongBeiCourePage;
    params = params or {};
    params.url = "%ui%/App/RedSummerCamp/Course.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    params.fixedRootScreenWidth = params.fixedRootScreenWidth or 1280;
    params.fixedRootScreenHeight = params.fixedRootScreenHeight or 720;
    ShenTongBeiCourePage:Show(params);
end

local ShenTongBeiConstituionPage
function Page.ShowShenTongBeiConstituionPage()
    ShenTongBeiConstituionPage = ShenTongBeiConstituionPage or Vue:new();
    print("ShowShenTongBeiConstituionPage")
    __auto_close_pages__[ShenTongBeiConstituionPage] = ShenTongBeiConstituionPage;
    params = params or {};
    params.url = "%ui%/App/RedSummerCamp/Constitution.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    params.fixedRootScreenWidth = params.fixedRootScreenWidth or 1280;
    params.fixedRootScreenHeight = params.fixedRootScreenHeight or 720;
    ShenTongBeiConstituionPage:Show(params);
end

local ShenTongBeiCompetitionPage
function Page.ShowShenTongBeiCompetitionPage()
    ShenTongBeiCompetitionPage = ShenTongBeiCompetitionPage or Vue:new();
    print("ShenTongBeiCompetitionPage")
    __auto_close_pages__[ShenTongBeiCompetitionPage] = ShenTongBeiCompetitionPage;
    params = params or {};
    params.url = "%ui%/App/RedSummerCamp/Competition.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    params.fixedRootScreenWidth = params.fixedRootScreenWidth or 1280;
    params.fixedRootScreenHeight = params.fixedRootScreenHeight or 720;
    ShenTongBeiCompetitionPage:Show(params);
end

local ShenTongBeiZiZhiPage
function Page.ShowShenTongBeiZiZhiPage()
    ShenTongBeiZiZhiPage = ShenTongBeiZiZhiPage or Vue:new();
    __auto_close_pages__[ShenTongBeiZiZhiPage] = ShenTongBeiZiZhiPage;
    params = params or {};
    params.url = "%ui%/App/RedSummerCamp/Qualification.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    params.fixedRootScreenWidth = params.fixedRootScreenWidth or 1280;
    params.fixedRootScreenHeight = params.fixedRootScreenHeight or 720;
    ShenTongBeiZiZhiPage:Show(params);
end

local BigImagePage;
function Page.ShowBigImagePage(G, params)
    BigImagePage = BigImagePage or Vue:new();
    __auto_close_pages__[BigImagePage] = BigImagePage;
    params = params or {};
    params.url = "%ui%/Page/Common/BigImage.html";
    params.draggable = false;
    params.G = G;
    params.width = params.width or "100%";
    params.height = params.height or "100%";
    BigImagePage:Show(params);
    return BigImagePage;
end

local MatataLabPage;
function Page.ShowMatataLabPage()
    MatataLabPage = MatataLabPage or Vue:new();
    __auto_close_pages__[MatataLabPage] = MatataLabPage;
    MatataLabPage:CloseWindow();
    NPL.load("script/ide/System/UI/MatataLab/MatataLab.lua");
    params = params or {};
    params.url = "%ui%/MatataLab/MatataLab.html";
    params.draggable = false;
    params.G = {};
    params.width = 1280;
    params.height = 720;
    -- params.width = params.width or "100%";
    -- params.height = params.height or "100%";
    -- params.fixedRootScreenWidth = params.fixedRootScreenWidth or 1280;
    -- params.fixedRootScreenHeight = params.fixedRootScreenHeight or 720;
    params.G.matatalab = {
        title = "火星救援", description = "MatataLab 图块编程图块编程图块编程图块编程图块编程",   
        block_option_list = {   -- 块定义
            {
                type = "上",
                icon = "Texture/Aries/Creator/keepwork/ggs/matatalab/shang_68x50_32bits.png#0 0 68 50",
                code = "MoveUp()",
                match = "Number0-9"
            }, 
            {
                type = "下",
                icon = "Texture/Aries/Creator/keepwork/ggs/matatalab/xia_68x50_32bits.png#0 0 68 50",
                code = "MoveDown()",
            }, 
            {
                type = "左",
                icon = "Texture/Aries/Creator/keepwork/ggs/matatalab/zuo_68x50_32bits.png#0 0 68 50",
                code = "MoveLeft()",
            }, 
            {
                type = "右",
                icon = "Texture/Aries/Creator/keepwork/ggs/matatalab/you_68x50_32bits.png#0 0 68 50",
                code = "MoveRight()",
            }, 
            {
                type = "NumberBlock2", 
                number = 2, 
                isNumberBlock = true,
                icon = "Texture/Aries/Creator/keepwork/ggs/matatalab/2_68x40_32bits.png#0 0 68 40",
                code = "2",
                match = "Number0-9"
            },
            {
                type = "NumberBlock3", 
                number = 3, 
                isNumberBlock = true,
                icon = "Texture/Aries/Creator/keepwork/ggs/matatalab/3_68x40_32bits.png#0 0 68 40",
                code = "3",
                match = "String0-9"
            }, 
            {
                type = "NumberBlock5", 
                number = 5, 
                isNumberBlock = true,
                icon = GameLogic.GetWorldDirectory() .. "UI/5_68x40_32bits.png#0 0 68 40",
                code = "5",
            }, 
        },
        toolbox_block_list = {"上", "右", "下", "左", "上", "右", "下", "左", "上"},   -- toolbox 工具栏块列表
        toolbox_number_block_list = {"NumberBlock2", "NumberBlock3", "NumberBlock5"},   -- toolbox 工具栏数字块列表
        OnStart = function(matatalab)             -- 点击运行回调
            local code = matatalab:GetCode();
            print(code);
            -- TODO RunCode

            matatalab:GetWorkspace():ClickStateBtn(); -- 再次点击变为开始状态
        end,
        OnStop = function(matatalab)              -- 点击停止回调
            -- TODO StopCode
        end
    };
    MatataLabPage:Show(params);
    return MatataLabPage;
end

--[[
打开冬令营主面板
defaultTabIndex:
    "quweibiancheng" 趣味编程
    "kuailejianzao"  快乐建造
    "jingcaidonghua" 精彩动画
    "lajifenlei"     垃圾分类
    "tiyujinsai"     体育竞赛
]]  
function Page.ShowWinterCampMainWindow(defaultTabIndex)
    -- local Independent = NPL.load("Mod/GeneralGameServerMod/GI/Independent/Independent.lua");
    -- local independent = Independent:GetSingletonInstance();
    -- independent:Start("script/ide/System/UI/App/WinterCamp/WinterCamp.lua.html");
    -- independent:GetCodeEnv().ShowWinterCampMainWindow(defaultTabIndex);
    -- Independent:LoadString([[
    --     ShowWinterCampMainWindow();
    -- ]]);
end

