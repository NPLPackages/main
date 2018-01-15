--[[
Title: TreeNode
Author(s): LiPeng
Date: 2017/10/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/TreeNode.lua");
local TreeNode = commonlib.gettable("System.Windows.Controls.TreeNode");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Canvas.lua");
local Canvas = commonlib.gettable("System.Windows.Controls.Canvas");
local Button = commonlib.gettable("System.Windows.Controls.Button");
local TreeNode = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.Controls.TreeNode"));
TreeNode:Property("Name", "TreeNode");
-- Gets the zero-based depth of the tree node in the TreeView control 
TreeNode:Property({"Level", 0, auto=true})
-- Gets a value indicating whether the tree node is in the expanded state. 
TreeNode:Property({"Expanded", false, auto=true})
-- Gets a value indicating whether the tree node is in the selected state. 
TreeNode:Property({"Selected", false, auto=true})
-- if true, node is invisible.
TreeNode:Property({"Invisible", nil, auto=true})
-- Gets or sets the text displayed in the label of the tree node. 
TreeNode:Property({"Text", nil, auto=true})
TreeNode:Property({"Font", "System;14;norm", auto=true})
TreeNode:Property({"TextColor", "#000000", auto=true})
TreeNode:Property({"Scale", nil, "GetScale", "SetScale", auto=true})
-- Gets or sets the URL to navigate to when the node is clicked. 
TreeNode:Property({"NavigateUrl", nil, auto=true})
-- Gets or sets a non-displayed value used to store any additional data about the node, such as data used for handling postback events. 
TreeNode:Property({"Value", nil, auto=true})
-- some predefined type, it only takes effect if one chooses to use the default draw node handler provided by this class
-- nil, "Title", "separator"
TreeNode:Property({"Type", nil, auto=true})
-- Gets or sets the object that contains data about the tree node. 
TreeNode:Property({"Tag", nil, auto=true})
-- Gets or sets the text that appears when the mouse pointer hovers over a TreeNode. 
TreeNode:Property({"ToolTipText", nil, auto=true})
-- icon texture file
TreeNode:Property({"Icon", nil, auto=true})
-- if false or nil, it will leave a white space for the Icon (even the icon is nil).
TreeNode:Property({"bSkipIconSpace", nil, auto=true})
-- Gets or sets the key for the image associated with this tree node when the node is in an unselected state. 
-- this can be a index which index into TreeView.ImageList[ImageKey] or it can be a string of image file path or URL.
TreeNode:Property({"ImageKey", nil, auto=true})
-- Gets or sets the key of the image displayed in the tree node when it is in a selected state.
-- this can be a index which index into TreeView.ImageList[ImageKey] or it can be a string of image file path or URL.
TreeNode:Property({"SelectedImageKey", nil, auto=true})
-- Height of this tree node, if this is nil, TreeView.DefaultNodeHeight will be used
TreeNode:Property({"NodeHeight", nil, auto=true})
-- Width of this tree node, if this is nil, TreeView.DefaultNodeWidth will be used
TreeNode:Property({"NodeWidth", nil, auto=true})
-- padding of this tree node. if this is nil, TreeView.DefaultNodePadding will be used
TreeNode:Property({"NodePadding", nil, auto=true})
-- how many items to display per row, this is set if one wants to display multiple items on the same row. with a fixed width. Usually the width is specified by NodeWidth,
TreeNode:Property({"ItemsPerRow", nil, auto=true})
-- string to be executed or a function of format function FuncName(treeNode) end
TreeNode:Property({"onclick", nil, auto=true})
-- Gets or sets a function by which the individual TreeNode control is drawn. The function should be of the format:
-- function DrawNodeEventHandler(parent,treeNode) end, where parent is the parent container in side which contents should be drawn. And treeNode is the TreeNode object to be drawn
-- if DrawNodeHandler is nil, and the treenode's DrawNodeHandler is also nil, the default TreeView.DrawNormalNodeHandler function will be used. 
TreeNode:Property({"DrawNodeHandler", nil, auto=true})
--------------------------------
-- internal parameters, do not use externally
--------------------------------
-- logical position of the node relative to the tree view container. 
TreeNode:Property({"LogicalX", 0, auto=true})
TreeNode:Property({"LogicalY", 0, auto=true})
-- logical position for the right bottom corner of this node and all its children
TreeNode:Property({"LogicalRight", nil, auto=true})
TreeNode:Property({"LogicalBottom", 0, auto=true})
-- internal index of this node. such that self.parent[self.index] is self. 
TreeNode:Property({"index", 0, auto=true})
-- render line index
TreeNode:Property({"lineindex", 0, auto=true})

TreeNode:Property({"indent", 0, "GetIndent", "SetIndent", auto=true})

TreeNode:Property({"OpenBackground", "Texture/3DMapSystem/common/itemopen.png", "GetOpenBackground", "SetOpenBackground", auto=true})

TreeNode:Property({"CloseBackground", "Texture/3DMapSystem/common/itemclosed.png", "GetCloseBackground", "SetCloseBackground", auto=true})

TreeNode:Property({"MouseOverBG", nil, auto=true})

TreeNode:Property({"NormalBG", nil, auto=true})

TreeNode:Property({"ItemToggleSize", nil, auto=true})

TreeNode:Signal("clicked");


function TreeNode:ctor()
--	self.control = nil;
	self.canvas = nil;
	self.indent = nil;
end

function TreeNode:init(parent)
	TreeNode._super.init(self, parent);

	--self.canvas = Canvas:new():init(self);

	self.treeview = self:GetParent("TreeView");
	--self:initExpandBtn();

	return self;
end

function TreeNode:initExpandBtn()
	local item_size = self.ItemToggleSize or self.treeview.ItemToggleSize or 10;
	local btn = Button:new():init(self);
	btn:Connect("clicked", self, "onclick");
	btn:setGeometry(0,0,item_size,item_size);
	self.expandBtn = btn;
	self:UpdateExpandButtonBackground();
end

function TreeNode:createDefaultTextDisplay()
	if(self.label) then
		self.label = Button:new():init(self);
		self.label:SetText(self.Text);
		self.label:Connect("clicked", self, "onclick");
	end
end

function TreeNode:OnClick()
	self:emitClicked();
end

function TreeNode:UpdateExpandButtonBackground(openBK, closeBK)
	if(self.treeview) then
		openBK = openBK or self.treeview.ItemOpenBG;
		closeBK = closeBK or self.treeview.ItemCloseBG;
	end 
	openBK = openBK or self.OpenBackground;
	closeBK = closeBK or self.CloseBackground;
	
	local btn = self.expandBtn;
	if(self.Expanded) then
		btn:SetBackground(openBK);
	else
		btn:SetBackground(closeBK);
	end
end

function TreeNode:hitLabelOrExpandBtn(e)
	local children = self:GetChildren();
	if(children:size() > 2) then
		local expandBtn = children:first();
		local label = children:next(expandBtn);
		if(expandBtn.crect:contains(e:pos()) or label.crect:contains(e:pos())) then
			return true;
		else
			return false;
		end
	end
	return true;
end

function TreeNode:mousePressEvent(e)
	if(e:button() == "left") then
		if(self:hitLabelOrExpandBtn(e)) then
			self:OnClick()
			e:accept();
		end
	end
end

function TreeNode:emitClicked()
	self:clicked();
end

--function TreeNode:SetOpenBackground(background)
--	self.OpenBackground = background;
--	self:UpdateExpandButtonBackground(background);
--end
--
--function TreeNode:SetCloseBackground(background)
--	self.CloseBackground = background;
--	self:UpdateExpandButtonBackground(nil, background);
--end

function TreeNode:paintEvent(painter)
	
end