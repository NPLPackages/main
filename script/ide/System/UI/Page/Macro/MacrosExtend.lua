--[[
Title: MacrosExtend
Author(s): wxa
Date: 2020/6/30
Desc: 宏接口扩展
use the lib:
-------------------------------------------------------
local MacrosExtend = NPL.load("script/ide/System/UI/Page/Macro/MacrosExtend.lua");
-------------------------------------------------------
]]

NPL.load("(gl)script/apps/Aries/Creator/Game/Macros/Macros.lua");
local Macros = commonlib.gettable("MyCompany.Aries.Game.GameLogic.Macros");

local Page = NPL.load("Mod/GeneralGameServerMod/UI/Page.lua");
local MacrosExtend = NPL.export();

function Macros.ShowSubTitlePage(params)
    local callback = {};

    Page.ShowSubTitlePage({
        text = params.text,
        OnClose = function() 
            if(callback.OnFinish) then callback.OnFinish() end
        end,
    });

    return callback;
end

local MacroManagerPage = nil;
GameLogic.GetFilters():add_filter("Macro_BeginRecord", function()
    if (not GGS.IsDeveloper) then return end
    
    MacroManagerPage = Page.Show(nil, {
        url="%ui%/Page/Macro/MacrosManager.html",  
        alignment="_lt", 
        x = 80, 
        y = 0, 
        width = 500, 
        height = 80,
    });
end);

GameLogic.GetFilters():add_filter("Macro_EndRecord", function()
    if (not MacroManagerPage) then return end
    MacroManagerPage:CloseWindow();
    MacroManagerPage = nil;
end);


-- 