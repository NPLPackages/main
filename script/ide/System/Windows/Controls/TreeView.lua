--[[
Title: TreeView
Author(s): LiPeng
Date: 2017/9/18
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/TreeView.lua");
local TreeView = commonlib.gettable("System.Windows.Controls.TreeView");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/TreeNode.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollArea.lua");
--local ScrollArea = commonlib.gettable("System.Windows.Controls.ScrollArea");
local TreeNode = commonlib.gettable("System.Windows.Controls.TreeNode");
local TreeView = commonlib.inherit(commonlib.gettable("System.Windows.Controls.ScrollArea"), commonlib.gettable("System.Windows.Controls.TreeView"));
TreeView:Property("Name", "TreeView");

-- the client area X, Y position in pixels relative to the logical tree view container. 
TreeView:Property({"ClientX", 0, auto = "true"});
TreeView:Property({"ClientY", 0, auto = "true"});
-- this is automatically set according to whether a scroll bar is available.
TreeView:Property({"ClientWidth", 10, auto = "true"});
TreeView:Property({"ClientHeight", 10, auto = "true"});
-- default indentation
TreeView:Property({"DefaultIndentation", 5, auto = "true"});
-- whether to show icon on the left of each line. 
TreeView:Property({"ShowIcon", true, auto = "true"});
-- how many items to display per row for the root node.
TreeView:Property({"ItemsPerRow", nil, auto = "true"});
-- Default height of Tree Node
TreeView:Property({"DefaultNodeHeight", 24, auto = "true"});
-- Default width of Tree Node, this is not used unless we are displaying the treenode in a grid view style. 
TreeView:Property({"DefaultNodeWidth", nil, auto = "true"});
-- Default padding of tree nodes. this is not used unless we are displaying the treenode in a grid view style. 
TreeView:Property({"DefaultNodePadding", 0, auto = "true"});
-- how many pixels to scroll each time
TreeView:Property({"VerticalScrollBarStep", 24, auto = "true"});
-- how many pixels to scroll when user hit the empty space of the scroll bar. this is usually same as DefaultNodeHeight
TreeView:Property({"VerticalScrollBarPageSize", 24, auto = "true"});

TreeView:Property({"ItemOpenBG", "Texture/3DMapSystem/common/itemopen.png", auto=true})

TreeView:Property({"ItemCloseBG", "Texture/3DMapSystem/common/itemclosed.png", auto=true})

TreeView:Property({"MouseOverBG", nil, auto=true})

TreeView:Property({"NormalBG", nil, auto=true})

TreeView:Property({"ItemToggleSize", nil, auto=true})

TreeView:Property({"DefaultIconSize", nil, auto=true})

TreeView:Property({"VerticalScrollBarOffsetX", nil, auto=true})

TreeView:Property({"DefaultIconSize", nil, auto=true})

function TreeView:ctor()
end
