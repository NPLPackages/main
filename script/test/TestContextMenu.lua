--[[
Author: Li,Xizhi
Date: 2007-9-24
Desc: testing TreeView.
-----------------------------------------------
NPL.load("(gl)script/test/TestContextMenu.lua");
TestContextMenu()
-----------------------------------------------
]]

-- test passed on 2007-9-24 by LiXizhi
function TestContextMenu()
	------------------------
	-- basic testing
	------------------------
	NPL.load("(gl)script/ide/ContextMenu.lua");
	
	local ctl = CommonCtrl.GetControl("ContextMenu1");
	if(ctl==nil)then
		ctl = CommonCtrl.ContextMenu:new{
			name = "ContextMenu1",
			width = 300,
			height = 100,
			container_bg = "Texture/tooltip_text.PNG",
			onclick = function (node, param1) _guihelper.MessageBox(node.Text) end
		};
		local node = ctl.RootNode;
		node:AddChild("Node1");
		node:AddChild(CommonCtrl.TreeNode:new({Text = "Node2", Name = "sample"}));
		node = node:AddChild("Node3");
		node = node:AddChild("Node3_1");
		node = node:AddChild("Node3_1_1");
		ctl.RootNode:AddChild("Node4");
		ctl.RootNode:AddChild("Node5");
	end	

	ctl:Show(100, 100, nil);
end


