--[[
Title: Const
Author(s): wxa
Date: 2020/6/30
Desc: Const
use the lib:
-------------------------------------------------------
local Const = NPL.load("Mod/GeneralGameServerMod/App/ui/Core/Blockly/Const.lua");
-------------------------------------------------------
]]

local Const = NPL.export();

Const.UnitSize = 3;                               -- 单元格大小
Const.ConnectionRegionHeightUnitCount = 14;       -- 连接区域高度
Const.ConnectionRegionWidthUnitCount = 16;        -- 连接区域宽度
Const.ConnectionHeightUnitCount = 2;              -- 连接高度
Const.ConnectionWidthUnitCount = 16;              -- 连接高度
Const.BlockEdgeHeightUnitCount = 1;               -- 块边缘高度
Const.BlockEdgeWidthUnitCount = 4;                -- 块边缘高度
Const.StatementWidthUnitCount = 4;                -- 输入语句左边宽度

Const.LineHeightUnitCount = 8;                    -- 每行内容高为8
Const.InputValueWidthUnitCount = 10;              -- 输入值宽度
Const.FieldSpaceWidthUnitCount = 1;               -- 空白字段宽度

Const.MinEditFieldWidthUnitCount = 30;            -- 最小编辑字段宽度
Const.MaxTextShowWidthUnitCount = 100;            -- 最大文本显示宽度
Const.MinTextShowWidthUnitCount = 10;             -- 最小文本显示宽度
Const.TextMarginUnitCount = 0;                    -- 文本边距

Const.ToolBoxWidth = 300;                         -- 工具栏宽度
Const.ToolBoxCategoryWidth = 60;                  -- 分类宽
Const.ToolBoxCategoryHeight = 60;                 -- 分类高

Const.MiniMapWidth = 150 
Const.MiniMapHeight = 150;
Const.MiniMapMargin = 20;    

-- 图块颜色
Const.Colors = {"#2E9BEF", "#76CE62", "#764BCC", "#EC522E", "#C38A3F", "#69B090", "#569138", "#459197", "#FF8C1A"};

Const.HighlightColors = {
    ["#764BCC"] = "#A98AE6",
    ["#7ABB55"] = "#86DF72",
    ["#459197"] = "#7DCED4",
    ["#69B090"] = "#91D3B5",
    ["#569138"] = "#8FCC70",
    ["#8F6D40"] = "#C38A3F",
    ["#0078D7"] = "#2E9BEF",
    ["#D83B01"] = "#FF7757",
}

-- Const.SCROLL_BAR_VERSION = 1;