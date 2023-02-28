--[[
Title: DefaultStyle
Author(s): wxa
Date: 2020/6/30
Desc: 样式管理类
use the lib:
-------------------------------------------------------
local DefaultStyle = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Window/Style/DefaultStyle.lua");
-------------------------------------------------------
]]


local DefaultStyle = NPL.export();

local DefaultStyleString = [[
    .center {
        display: flex;
        justify-content: center;
        align-items: center;
    }
    .hcenter {
        display: flex;
        justify-content: center;
    }
    .vcenter {
        display: flex;
        flex-direction: column;
        justify-content: center;
    }
    .full-height {
        height: 100%;
    }
    .full-width {
        width: 100%;
    }
    .btn {
        display: flex;
        justify-content: center;
        align-items: center;
    }
    .btn:hover {
        background-color: #ffffff;
    }
]]

function DefaultStyle.GetDefaultStyleString()
    return DefaultStyleString;
end