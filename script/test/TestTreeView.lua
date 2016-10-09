--[[
Author: Li,Xizhi
Date: 2007-9-19
Desc: testing TreeView.
-----------------------------------------------
NPL.load("(gl)script/test/TestTreeView.lua");
TestTreeView()
-----------------------------------------------
]]

-- test passed on 2007-9-20 by LiXizhi
function TestTreeView()
	------------------------
	-- basic testing
	------------------------
	NPL.load("(gl)script/ide/TreeView.lua");
	local ctl = CommonCtrl.TreeView:new{
		name = "TreeView1",
		alignment = "_lt",
		container_bg = "Texture/whitedot.png",
		left=10, top=10,
		width = 200,
		height = 200,
		parent = nil,
	};
	local node
	local i;
	-- breadth test for 5000 TreeNode
	local function OnClickNode(treeNode)
		-- a dirty way for double clicking
		if(mouse_x == lastmousex and mouse_y == lastmousey) then
			if(treeNode~=nil) then
				_guihelper.MessageBox(treeNode:GetNodePath());
			end	
		end
		lastmousex, lastmousey = mouse_x, mouse_y;
	end
	
	for i=1,1000 do
		local node = ctl.RootNode;
		node:AddChild("A"..i);	
		node:AddChild(CommonCtrl.TreeNode:new({Text = "Button"..i, onclick= OnClickNode}));	
		node = node:AddChild(CommonCtrl.TreeNode:new({Text = "C"..i, Name = "sample"}));
		node = node:AddChild("C"..i.."_1");
		node = node:AddChild("C"..i.."_1_1");
	end
	
	-- depth test for 20 TreeNode levels
	local node = ctl.RootNode;
	for i=1,20 do
		node = node:AddChild("Depth"..i);
	end
	
	-- long text test
	ctl.RootNode:AddChild("very long text 123456789  very long 123456789 very long");
	
	-- last test
	ctl.RootNode:AddChild("最后的一个");

	ctl:Show();
	-- One needs to call Update() if made any modifications to the TreeView, such as adding or removing new nodes, or changing text of a given node. 
	-- ctl:Update();
	
	------------------------
	-- owner draw TreeView testing
	------------------------
	
	NPL.load("(gl)script/ide/TreeView.lua");
	
	local function OwnerDrawTreeNodeHandler(_parent,treeNode)
		if(_parent == nil or treeNode == nil) then
			return
		end
		
		local _this;
		local left = 2 + treeNode.TreeView.DefaultIndentation*treeNode.Level; -- indentation of this node. 
		local top = 2;
		local nodeWidth = treeNode.TreeView.ClientWidth;
		
		if(treeNode:GetChildCount() > 0) then
			-- node that contains children. We shall display some
			_this=ParaUI.CreateUIObject("button","b","_lt", left, top , 20, 20);
			_this.onclick = string.format(";CommonCtrl.TreeView.OnToggleNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
			_parent:AddChild(_this);
			left = left + 22;
			
			if(treeNode.Expanded) then
				_this.background = "Texture/unradiobox.png";
			else
				_this.background = "Texture/radiobox.png";
			end
		end
		if(treeNode.Text ~= nil) then
			_this=ParaUI.CreateUIObject("button","b","_lt", left, top , 24, 24);
			_parent:AddChild(_this);
			_this.background = "Texture/face/19.png";
			left = left + 25;
			
			if(treeNode.type == "customUI") then
				-- just some custom UI code here
				_this=ParaUI.CreateUIObject("imeeditbox","b","_lt", left, top , 50, 27);
				_this.text = treeNode.Text;
				_parent:AddChild(_this);
				left = left + 50;
				
				_this=ParaUI.CreateUIObject("slider","b","_lt", left, top+25 , 70, 20);
				_parent:AddChild(_this);
			end
			
			-- node that text. We shall display text
			if(treeNode.onclick ~= nil or treeNode.ondoubleclick ~= nil) then
				_this=ParaUI.CreateUIObject("button","b","_lt", left, top , nodeWidth - left-1, 16);
				_parent:AddChild(_this);
				_this.font = "System;12;norm";
				--_this.background = "";
				_guihelper.SetUIFontFormat(_this, 36); -- single line and vertical align
				if(treeNode.onclick~=nil) then
					_this.onclick = string.format(";CommonCtrl.TreeView.OnClickNode(%q, %q)", treeNode.TreeView.name, treeNode:GetNodePath());
				end	
			else
				_this=ParaUI.CreateUIObject("text","b","_lt", left, top , nodeWidth - left-1, 16);
				_parent:AddChild(_this);
				_this.font = "System;12;norm";
				_this:GetFont("text").format=36; -- single line and vertical align
			end	
			_this.text = treeNode.Text;
		end
	end
	
	local ctl = CommonCtrl.TreeView:new{
		name = "TreeView2",
		alignment = "_lt",
		container_bg = "Texture/tooltip_text.PNG",
		left=300, top=10,
		width = 200,
		height = 200,
		parent = nil,
		-- function DrawNodeEventHandler(parent,treeNode) end, where parent is the parent container in side which contents should be drawn. And treeNode is the TreeNode object to be drawn
		DrawNodeHandler = OwnerDrawTreeNodeHandler,
	};
	node = ctl.RootNode:AddChild("Owner Draw Node");
	-- custom UI
	node:AddChild(CommonCtrl.TreeNode:new({Text = "Custom UI", type = "customUI", NodeHeight = 60}));
	node = ctl.RootNode:AddChild("Owner Draw Node3");
	node:AddChild("Owner Draw Node2");
	-- custom height
	node:AddChild(CommonCtrl.TreeNode:new({Text = "Custom Height 50 pixel", NodeHeight = 50}));
	node = ctl.RootNode:AddChild("Owner Draw Node4");
	node:AddChild("Owner Draw Node4");
	node:AddChild("Owner Draw Node4_1");
	node:AddChild("Owner Draw Node4_1_1");
	
	ctl:Show();
	
	---------------------------------
	-- test auto generated code by ParaIDE.NPLDesigner
	---------------------------------
	NPL.load("(gl)script/ide/TreeView.lua");
	local ctl = CommonCtrl.TreeView:new{
		name = "treeViewContacts",
		alignment = "_lt",
		left = 660,
		top = 33,
		width = 227,
		height = 224,
		parent = nil,
		DefaultIndentation = 19,
		DefaultNodeHeight = 16,
	};
	local node = ctl.RootNode;
	node = node:AddChild( CommonCtrl.TreeNode:new({Text = "Node0", Name = "Node0", }) );
	node = node.parent;
	node = node:AddChild( CommonCtrl.TreeNode:new({Text = "Node1", Name = "Node1", }) );
	node = node:AddChild( CommonCtrl.TreeNode:new({Text = "Node1_1", Name = "Node2", }) );
	node = node:AddChild( CommonCtrl.TreeNode:new({Text = "Node1_1_1", Name = "Node5", }) );
	node = node.parent;
	node = node:AddChild( CommonCtrl.TreeNode:new({Text = "Node1_1_2", Name = "Node6", }) );
	node = node.parent;
	node = node.parent;
	node = node:AddChild( CommonCtrl.TreeNode:new({Text = "Node_1_2", Name = "Node3", }) );
	node = node.parent;
	node = node:AddChild( CommonCtrl.TreeNode:new({Text = "Node1_3", Name = "Node4", }) );
	node = node.parent;
	node = node.parent;
	node = node:AddChild( CommonCtrl.TreeNode:new({Text = "Node3", Name = "Node7", }) );
	node = node.parent;
	ctl:Show();
end



function testNineElementContainer()
	if(ParaUI.GetUIObject("testNineElementContainer"):IsValid() == false) then
		local _this = ParaUI.CreateUIObject("container", "testNineElementContainer", "_lt", 0, 0, 100, 100)
		_this.candrag = true;
		_this:SetNineElementBG("Texture/uncheckbox.png", 10,10,10,10);
		_this:AttachToRoot();
	end
end