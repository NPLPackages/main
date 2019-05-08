--[[
Title: pe:treeview element
Author(s): LiPeng
Date: 2017/10/3
Desc: pe:treeview element

### `pe:treeview` tag
@param value: "[name] in [func_or_table]"
@param DataSource: alternatively one can use DataSource rather than `value`

Examples: 
```xml
<%
treeview_data = { {a=1}, {a=2} };
function GetDS()
    return treeview_data;
end
%>
<pe:treeview value="item in treeview_data" style="float:left">
    <div style="float:left;"><%=item.a%></div>
</pe:treeview>
<pe:treeview value="item in GetDS()" style="float:left">
    <div style="float:left;"><%=item.a%></div>
</pe:treeview>
<pe:treeview DataSource='<%=GetDS()%>' style="float:left">
    <div style="float:left;"><%=a%></div>
</pe:treeview>
```
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_treeview.lua");
System.Windows.mcml.Elements.pe_treeview:RegisterAs("pe:treeview");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_div.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/TreeView.lua");
local TreeView = commonlib.gettable("System.Windows.Controls.TreeView");
local mcml = commonlib.gettable("System.Windows.mcml");

local pe_treeview = commonlib.inherit(commonlib.gettable("System.Windows.mcml.Elements.pe_div"), commonlib.gettable("System.Windows.mcml.Elements.pe_treeview"));
pe_treeview:Property({"class_name", "pe:treeview"});

function pe_treeview:ctor()
end

function pe_treeview:ControlClass()
	return TreeView;
end

function pe_treeview:CreateControl()
	pe_treeview._super.CreateControl(self);

	local _this = self:GetControl();
	if(_this) then
		--_this:setHorizontalScrollBarPolicy("AlwaysOff");

		--container_bg = css.background or self:GetString("background"), -- change to css background first
		_this:SetDefaultNodeHeight(self.DefaultNodeHeight);
		_this:SetDefaultIconSize(self:GetNumber("DefaultIconSize"));
		_this:SetShowIcon(self:GetBool("ShowIcon"));
		_this:SetItemOpenBG(self.ItemOpenBG);
		_this:SetItemCloseBG(self.ItemCloseBG); 
		_this:SetItemToggleSize(self.ItemToggleSize);
		_this:SetDefaultIndentation(self.DefaultIndentation);
		_this:SetVerticalScrollBarOffsetX(self:GetNumber("VerticalScrollBarOffsetX"));
		_this:SetVerticalScrollBarStep(self:GetNumber("VerticalScrollBarStep"));
		_this:SetVerticalScrollBarPageSize(self:GetNumber("VerticalScrollBarPageSize"));
		_this:SetMouseOverBG(self:GetString("MouseOverBG"));
	end
end

function pe_treeview:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	self.ItemOpenBG = self:GetString("ItemOpenBG");
	self.ItemCloseBG = self:GetString("ItemCloseBG");
	self.ItemToggleSize = self:GetNumber("ItemToggleSize");
	self.DefaultNodeHeight = self:GetNumber("DefaultNodeHeight") or 24;
	self.ItemToggleRightSpacing = self:GetNumber("ItemToggleRightSpacing");
	self.DefaultIndentation = self:GetNumber("DefaultIndentation") or 30;


	-- Extract from datasource if it is already provided in the input. 
	local ds = self:GetAttributeWithCode("DataSourceID", nil, true);
	if(ds) then
		self:SetDataSource(ds);
	else
		ds = self:GetAttributeWithCode("DataSource",nil,true);
		if(ds) then
			self:SetDataSource(ds);
		end
	end
	if(self.datasource) then
		-- instantiate child nodes from data source 
		self:DataBind(false);
	end

	pe_treeview._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css)
end

function pe_treeview:OnLoadComponentAfterChild(parentElem, parentLayout, css)
	local function setNodeMinHeightRecursive(node, ignores, recursives)
		for childnode in node:next() do
			local setMinHeight = false;
			if(ignores[childnode.name]) then
				-- do nothing
			elseif(recursives[childnode.name]) then
				setNodeMinHeightRecursive(childnode, ignores, recursives)
--				if(childnode.name == "pe:treenode") then
--					setMinHeight = true;
--				end
			else
				setMinHeight = true;
			end

			if(setMinHeight) then
				local inline_style = childnode:GetInlineStyleDecl();
				local min_height = inline_style:GetProperty("min-height");
				if(not min_height) then
					inline_style:SetProperty("min-height", self.DefaultNodeHeight);
				end
--
--				local style = childnode:GetStyle();
--				if(not style["min-height"]) then
--					style["min-height"] = self.DefaultNodeHeight;
--				end
			end
		end
	end

	local ignores = {
		["NodeTemplates"] = true,
	}

	local recursives = {
		["pe:treenode"] = true,
	}

	setNodeMinHeightRecursive(self, ignores, recursives);
end

function pe_treeview:Rebuild(parentElem)
	if(not parentElem and self.control) then
		parentElem = self.control.viewport;
	end
	--pe_treeview._super.Rebuild(self, parentElem);

	local layout = self.myLayout:clone();
	local css = self:GetStyle();

	self:OnLoadChildrenComponent(parentElem, layout, css);

	self:OnLoadComponentAfterChild(parentElem, layout, css);

	self:UpdateChildLayout(layout);
end

function pe_treeview:SetDataSource(dataSource)
	local pageCtrl = self:GetPageCtrl();
	if(not pageCtrl) then return end
	if(type(dataSource) == "string") then
		-- this is data source ID, we will convert it to a function that dynamically retrieve item from the data source control. 
		self.datasource = pageCtrl:GetNode(dataSource);
	else
		self.datasource = dataSource;
	end
end

-- Public method: rebind (refresh) the data.
-- each bind data row node contains page variable "index" and any other data column values for that row. 
-- the template node can then evaluate for the values of the node to dynamic generate content specific to that row. 
-- such as <%=Eval("xpath")%> will return the xpath of the node
-- @param bRefreshUI: true to refresh UI. otherwise node is updated but UI is not. 
function pe_treeview:DataBind(bRefreshUI)
	local templates_node = self:GetChild("NodeTemplates");
	if(not templates_node or type(self.datasource)~="table") then
		return 
	end
	-- build a fast map for look up. 
	local template_map = self.template_map;
	if(not template_map) then
		template_map = {};
		self.template_map = template_map;
		local childnode;

		for childnode in templates_node:next("NodeTemplate") do
			if(childnode.attr and childnode.attr.DataType) then
				template_map[childnode.attr.DataType] = childnode;
			end
		end
	end
	-- now prepare an empty node to which all generated treenode will be added. 
	
	local output = self:GetAllChildWithName("DataNodePlaceholder");
	if(not output) then
		--local generated_node = PageElement:new({name="div"}); 
		local generated_node = mcml:createFromXmlNode({name="div"}); 
		--local generated_node = Map3DSystem.mcml.new(nil,{name="DataNodePlaceholder"});
		--self:AddChild(generated_node);
		self:AppendChild(generated_node, false);
		output = {generated_node};
	end
	local _, generated_node
	for _, generated_node in ipairs(output) do
		--generated_node:ClearAllChildren();
		generated_node:RemoveChildren();
	
		-- now tranverse the datasource to create all tree nodes. 
		-- Note: right now databinding is not suitable for extreamly large data source like tens of thousands of nodes
		-- since we will need to create them all during data binding.  
		local indent = 0;

		local function CreatePageElement(o)
			if(type(o) == "table") then
				o = commonlib.copy(o)
				--o = o:CopyOriginalData()
			end
			return mcml:createFromXmlNode(o)
		end

		local function needIndented(node)
			local parent = node:Parent();
			while(parent and parent:TagName() ~= "treeview") do
				if(parent:TagName() == "treenode") then
					return true;
				end
				parent = parent:Parent();
			end
			return false;
		end

		local function CreateTreeNode(inTable, parentNode)
			if(not inTable) then return end
			if(type(inTable) == "table") then 	
				local template_node = template_map[inTable.name]
				local thisNode;
				if(template_node) then
					-- create a child using the template. 
					local tree_node;
					if(template_node:GetChildCount() == 1) then
						local source_node = template_node[1];
						if(type(source_node) == "table") then
							if(source_node.name == "pe:treenode") then
								tree_node = CreatePageElement(source_node);

								local render_template = tree_node:GetAttribute("RenderTemplate");
								if(render_template) then
									tree_node.render_template_node = template_map[render_template];
								end
							else
								tree_node = CreatePageElement(source_node);
							end
						elseif(type(source_node) == "string") then
							tree_node = CreatePageElement(source_node); 
						end
					else
						--template_node = commonlib.copy(template_node);
						template_node = template_node:clone();
						template_node.name = "div";
						tree_node = CreatePageElement(template_node);
					end
					if(tree_node) then
						tree_node:SetPreValue("this", inTable.attr);
						parentNode:AppendChild(tree_node, false)
--						if(needIndented(tree_node)) then
--							tree_node.attr = tree_node.attr or {};
--							tree_node.attr.style = tree_node.attr.style or "";
--							tree_node.attr.style = string.format("margin-left:%dpx;%s", self.DefaultIndentation, tree_node.attr.style)
--						end
						thisNode = tree_node;
					end
				end	
				local nChildSize = table.getn(inTable);
				if(nChildSize>0) then
					indent = indent+1;
					local i, childNode
					for i, childNode in ipairs(inTable) do
						CreateTreeNode(childNode, thisNode or parentNode);
					end
					indent = indent-1;
				end
			end
		end
		-- check for xpath
		local xpath = generated_node:GetString("xpath");
		if(not xpath or xpath == "*" or xpath=="") then
			CreateTreeNode(self.datasource, generated_node)
		else
			local node; 
			for node in commonlib.XPath.eachNode(self.datasource, xpath) do
				CreateTreeNode(node, generated_node)
			end
		end
	end
end

function pe_treeview:AllowWheel(canWheel)
	if(self.control) then
		self.control:SetAllowWheel(canWheel);
	end
end

function pe_treeview:ScrollToEnd()
	if(self.control) then
		self.control:scrollToEnd();
	end	
end

function pe_treeview:scrollToChild(index)
--	if(self.control) then
--		self.control:scrollToPos(nil, self.DefaultNodeHeight * (index - 1));
--	end	
	self:ScrollTo(nil, self.DefaultNodeHeight * (index - 1))
end