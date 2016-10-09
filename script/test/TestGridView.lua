--[[
Author: WangTian
Date: 2008/1/21
Desc: testing GridView.
-----------------------------------------------
NPL.load("(gl)script/test/TestGridView.lua");
TestGridView();
-----------------------------------------------
]]

function OnClickShift(direction)

	local ctl = CommonCtrl.GetControl("GridView11");
	if(direction == 8) then
		ctl:OnShiftUpByCell();
	elseif(direction == 2) then
		ctl:OnShiftDownByCell();
	elseif(direction == 4) then
		ctl:OnShiftLeftByCell();
	elseif(direction == 6) then
		ctl:OnShiftRightByCell();
	end
end

function TestGridView()
	------------------------
	-- basic node testing
	------------------------
	
	NPL.load("(gl)script/ide/GridView.lua");
	local ctl = CommonCtrl.GridView:new{
		name = "GridView11",
		alignment = "_lt",
		left = 0, top = 30,
		width = 210,
		height = 210,
		cellWidth = 30,
		cellHeight = 30,
		parent = nil,
		columns = 10,
		rows = 10,
		DrawCellHandler = nil,
		};
	
	local i, j;	
	for i = 0, 9 do
		for j = 0, 9 do
			local cell = CommonCtrl.GridCell:new{
				GridView = nil,
				name = i.."-"..j,
				text = i.."-"..j,
				column = 1,
				row = 1,
				};
			ctl:InsertCell(cell, "Right");
		end
	end
	
	ctl:Show();
	
	
	local _up = ParaUI.CreateUIObject("button", "up", "_lt", 50, 300, 32, 32);
	_up.background = "Texture/3DMapSystem/common/uparrow.png";
	_up.onclick = ";OnClickShift(8);";
	_up:AttachToRoot();
	
	local _down = ParaUI.CreateUIObject("button", "down", "_lt", 100, 300, 32, 32);
	_down.background = "Texture/3DMapSystem/common/downarrow.png";
	_down.onclick = ";OnClickShift(2);";
	_down:AttachToRoot();
	
	local _left = ParaUI.CreateUIObject("button", "left", "_lt", 150, 300, 32, 32);
	_left.background = "Texture/3DMapSystem/common/leftarrow.png";
	_left.onclick = ";OnClickShift(4);";
	_left:AttachToRoot();
	
	local _right = ParaUI.CreateUIObject("button", "right", "_lt", 200, 300, 32, 32);
	_right.background = "Texture/3DMapSystem/common/rightarrow.png";
	_right.onclick = ";OnClickShift(6);";
	_right:AttachToRoot();
	
	
	------------------------
	-- owner draw GridView testing
	------------------------
	
	NPL.load("(gl)script/ide/GridView.lua");
	
	local function OwnerDrawGridCellHandler(_parent, gridcell)
		if(_parent == nil or gridcell == nil) then
			return;
		end
		
		if(gridcell ~= nil) then
			local _this = ParaUI.CreateUIObject("button", gridcell.text, "_fi", 2, 2, 2, 2);
			_this.onclick = ";_guihelper.MessageBox(\""..gridcell.row.." "..gridcell.column.."\");";
			_parent:AddChild(_this);
		end
	end
	
	local ctl2 = CommonCtrl.GridView:new{
		name = "GridView22",
		alignment = "_lt",
		container_bg = "Texture/tooltip_text.PNG",
		left = 300, top = 30,
		width = 160,
		height = 160,
		cellWidth = 20,
		cellHeight = 20,
		parent = nil,
		columns = 8,
		rows = 8,
		DrawCellHandler = OwnerDrawGridCellHandler,
	};
	
	local cell = CommonCtrl.GridCell:new{
		GridView = nil,
		name = "a",
		text = "a",
		column = 1,
		row = 1,
		};
	ctl2:InsertCell(cell, "Right");
	
	cell = CommonCtrl.GridCell:new{
		GridView = nil,
		name = "sa",
		text = "sa",
		column = 3,
		row = 3,
		};
	ctl2:InsertCell(cell, "Right");
	
	cell = CommonCtrl.GridCell:new{
		GridView = nil,
		name = "sa",
		text = "sa",
		column = 5,
		row = 7,
		};
	ctl2:InsertCell(cell, "Right");
	
	cell = CommonCtrl.GridCell:new{
		GridView = nil,
		name = "sa",
		text = "sa",
		column = 2,
		row = 8,
		};
	ctl2:InsertCell(cell, "Right");
	
	ctl2:Show();
	
	
	------------------------
	-- with TreeView
	------------------------
	
	NPL.load("(gl)script/ide/GridView.lua");
	NPL.load("(gl)script/ide/TreeView.lua");
	
	local function OwnerDrawGridCellHandler(_parent, gridcell)
		if(_parent == nil or gridcell == nil) then
			return;
		end
		
		if(gridcell ~= nil) then
			local _this = ParaUI.CreateUIObject("button", gridcell.text, "_fi", 2, 2, 2, 2);
			_this.onclick = ";_guihelper.MessageBox(\""..gridcell.text.."\");";
			_parent:AddChild(_this);
		end
	end
	
	local function OwnerDrawTreeViewHandler(_parent, treeNode)
		if(_parent == nil or treeNode == nil) then
			return;
		end
		
		local ctl = CommonCtrl.GridView:new{
			name = "GridView_"..treeNode.Row..treeNode.nCount,
			alignment = "_fi",
			container_bg = "",
			left = 0, top = 0,
			width = 0,
			height = 0,
			cellWidth = 50,
			cellHeight = 50,
			parent = _parent,
			columns = treeNode.nCount,
			rows = 1,
			DrawCellHandler = OwnerDrawGridCellHandler,
		};
		
		local i;	
		for i = 1, treeNode.nCount do
			local cell = CommonCtrl.GridCell:new{
				GridView = nil,
				name = treeNode.Row.."-"..i,
				text = treeNode.Row.."-"..i,
				column = 1,
				row = 1,
				};
			ctl:InsertCell(cell, "Right");
		end
		
		ctl:Show();
	end
	
	local ctl = CommonCtrl.TreeView:new{
		name = "TreeViewCont",
		alignment = "_lt",
		container_bg = "Texture/tooltip_text.PNG",
		left=500, top=10,
		width = 300,
		height = 300,
		parent = nil,
		DrawNodeHandler = OwnerDrawTreeViewHandler,
	};
	
	local node;
	node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new({Name = "Row1", Text = "", Row = 1, nCount = 4, NodeHeight = 50}));
	node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new({Name = "Row2", Text = "", Row = 2, nCount = 2, NodeHeight = 50}));
	node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new({Name = "Row3", Text = "", Row = 3, nCount = 1, NodeHeight = 50}));
	node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new({Name = "Row4", Text = "", Row = 4, nCount = 3, NodeHeight = 50}));
	node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new({Name = "Row5", Text = "", Row = 5, nCount = 6, NodeHeight = 50}));
	node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new({Name = "Row6", Text = "", Row = 6, nCount = 4, NodeHeight = 50}));
	node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new({Name = "Row7", Text = "", Row = 7, nCount = 7, NodeHeight = 50}));
	node = ctl.RootNode:AddChild(CommonCtrl.TreeNode:new({Name = "Row8", Text = "", Row = 8, nCount = 2, NodeHeight = 50}));
	
	ctl:Show();
	
	
end

