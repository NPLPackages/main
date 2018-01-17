--[[
Title: GridView
Author(s): LiPeng
Date: 2017/10/3
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/GridView.lua");
local GridView = commonlib.gettable("System.Windows.Controls.GridView");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
local GridView = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.Controls.GridView"));
GridView:Property("Name", "GridView");

-- the client area X, Y position in pixels relative to the logical tree view container. 
GridView:Property({"ClientX", 0, auto = "true"});
GridView:Property({"ClientY", 0, auto = "true"});
-- this is automatically set according to whether a scroll bar is available.
GridView:Property({"ClientWidth", 10, auto = "true"});
GridView:Property({"ClientHeight", 10, auto = "true"});
-- default indentation
GridView:Property({"DefaultIndentation", 5, auto = "true"});
-- whether to show icon on the left of each line. 
GridView:Property({"ShowIcon", true, auto = "true"});
-- how many items to display per row for the root node.
GridView:Property({"ItemsPerRow", nil, auto = "true"});
-- Default height of Tree Node
GridView:Property({"DefaultNodeHeight", 24, auto = "true"});
-- Default width of Tree Node, this is not used unless we are displaying the treenode in a grid view style. 
GridView:Property({"DefaultNodeWidth", nil, auto = "true"});
-- Default padding of tree nodes. this is not used unless we are displaying the treenode in a grid view style. 
GridView:Property({"DefaultNodePadding", 0, auto = "true"});
-- how many pixels to scroll each time
GridView:Property({"VerticalScrollBarStep", 24, auto = "true"});
-- how many pixels to scroll when user hit the empty space of the scroll bar. this is usually same as DefaultNodeHeight
GridView:Property({"VerticalScrollBarPageSize", 24, auto = "true"});

GridView:Property({"ItemOpenBG", "Texture/3DMapSystem/common/itemopen.png", auto=true})

GridView:Property({"ItemCloseBG", "Texture/3DMapSystem/common/itemclosed.png", auto=true})

GridView:Property({"MouseOverBG", nil, auto=true})

GridView:Property({"NormalBG", nil, auto=true})

GridView:Property({"ItemToggleSize", nil, auto=true})

GridView:Property({"DefaultIconSize", nil, auto=true})

GridView:Property({"VerticalScrollBarOffsetX", nil, auto=true})

GridView:Property({"DefaultIconSize", nil, auto=true})

function GridView:ctor()
end
