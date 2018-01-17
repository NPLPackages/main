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

local PageElement = commonlib.gettable("System.Windows.mcml.PageElement");
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_scrollarea.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/TreeView.lua");
local TreeView = commonlib.gettable("System.Windows.Controls.TreeView");
local mcml = commonlib.gettable("System.Windows.mcml");

local pe_treeview = commonlib.inherit(commonlib.gettable("System.Windows.mcml.Elements.pe_scrollarea"), commonlib.gettable("System.Windows.mcml.Elements.pe_treeview"));
pe_treeview:Property({"class_name", "pe:treeview"});

function pe_treeview:ctor()
end

function pe_treeview:LoadComponent(parentElem, parentLayout, styleItem)
	local _this = self.control;
	if(not _this) then
		_this = TreeView:new():init(parentElem);
		_this:setHorizontalScrollBarPolicy("AlwaysOff");
--		_this:setVerticalScrollBarPolicy("AlwaysOff");
		self:SetControl(_this);
	end
	PageElement.LoadComponent(self, _this.viewport, parentLayout, styleItem)
end

function pe_treeview:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	css:Merge(mcml:GetStyleItem(self.class_name));

	local _this = self.control;

	self.ItemOpenBG = self:GetString("ItemOpenBG") or css.ItemOpenBG;
	self.ItemCloseBG = self:GetString("ItemCloseBG") or css.ItemCloseBG;
	self.ItemToggleSize = self:GetNumber("ItemToggleSize") or css.ItemToggleSize;
	self.DefaultNodeHeight = self:GetNumber("DefaultNodeHeight") or css.DefaultNodeHeight or 24;
	self.ItemToggleRightSpacing = self:GetNumber("ItemToggleRightSpacing") or css.ItemToggleRightSpacing;
	self.DefaultIndentation = self:GetNumber("DefaultIndentation") or css.DefaultIndentation;

	--container_bg = css.background or self:GetString("background"), -- change to css background first
	_this:SetDefaultNodeHeight(self.DefaultNodeHeight);
	_this:SetDefaultIconSize(self:GetNumber("DefaultIconSize") or css.DefaultIconSize);
	_this:SetShowIcon(self:GetBool("ShowIcon"));
	_this:SetItemOpenBG(self.ItemOpenBG);
	_this:SetItemCloseBG(self.ItemCloseBG); 
	_this:SetItemToggleSize(self.ItemToggleSize);
	_this:SetDefaultIndentation(self.DefaultIndentation);
	_this:SetVerticalScrollBarOffsetX(self:GetNumber("VerticalScrollBarOffsetX") or css.VerticalScrollBarOffsetX);
	_this:SetVerticalScrollBarStep(self:GetNumber("VerticalScrollBarStep") or css.VerticalScrollBarStep);
	_this:SetVerticalScrollBarPageSize(self:GetNumber("VerticalScrollBarPageSize") or css.VerticalScrollBarPageSize);
	_this:SetMouseOverBG(self:GetString("MouseOverBG") or css.MouseOverBG);
	--_this:SetClickThrough(self:GetBool("ClickThrough"));
	self.onclick = self:GetAttributeWithCode("OnClick", nil, true);

	if(css["overflow-y"] and css["overflow-y"] == "hidden") then
		_this:setVerticalScrollBarPolicy("AlwaysOff");
	end

	if(not css.background and not css.background2) then
		if(css["background-color"]) then
			css.background = "Texture/whitedot.png";	
		else
			css["background-color"] = "#ffffff00";
		end
	end

	if(self.control) then
		self.control:ApplyCss(css);
	end
	


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
				local style = childnode:GetStyle();
				if(not style["min-height"]) then
					style["min-height"] = self.DefaultNodeHeight;
				end
			end
		end
	end

	local ignores = {
		["NodeTemplates"] = true,
	}

	local recursives = {
		["pe:treenode"] = true,
		["DataNodePlaceholder"] = true,
	}

	setNodeMinHeightRecursive(self, ignores, recursives);

--	for childnode in self:next() do
--		if(childnode.name == "NodeTemplates") then
--			-- do nothing
--		elseif(childnode.name == "DataNodePlaceholder") then
--			for temp_node in childnode:next() do
--				if(temp_node.name == "NodeTemplate") then
--					
--				elseif(temp_node.name == "pe:treenode") then
--
--				else
--
--				end
--			end		
--		elseif(childnode.name == "pe:treenode") then
--
--		else
--
--		end
--	end
end

function pe_treeview:Rebuild(parentElem)
	if(not parentElem and self.control) then
		parentElem = self.control.viewport;
	end
	pe_treeview._super.Rebuild(self, parentElem);
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
		local generated_node = PageElement:new({name="DataNodePlaceholder"}); 
		--local generated_node = Map3DSystem.mcml.new(nil,{name="DataNodePlaceholder"});
		self:AddChild(generated_node);
		output = {generated_node};
	end
	local _, generated_node
	for _, generated_node in ipairs(output) do
		generated_node:ClearAllChildren();
	
		-- now tranverse the datasource to create all tree nodes. 
		-- Note: right now databinding is not suitable for extreamly large data source like tens of thousands of nodes
		-- since we will need to create them all during data binding.  
		local indent = 0;

		local function CreatePageElement(o)
			if(type(o) == "table") then
				o = commonlib.copy(o)
			end
			return mcml:createFromXmlNode(o)
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
						template_node = commonlib.copy(template_node);
						template_node.name = "div";
						tree_node = CreatePageElement(template_node);
					end
					if(tree_node) then
						tree_node:SetPreValue("this", inTable.attr);
						parentNode:AddChild(tree_node)
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

-- Clear all child nodes
function pe_treeview:ClearAllChildren()
	if(self.control and self.control.viewport) then
		self.control.viewport:deleteChildren();
	end
	commonlib.resize(self, 0);
end

function pe_treeview:setRealSize(width, height)
	if(self.control and self.control.viewport) then
		width = width or self.control.viewport:width();
		height = height or self.control.viewport:height();
		self.control.viewport:setGeometry(0, 0, width, height);
	end
end

function pe_treeview:AllowWheel(canWheel)
	if(self.control) then
		self.control:SetAllowWheel(canWheel);
	end
end

function pe_treeview:scrollToChild(index)
	local node = self[index];
	local style = node:GetStyle();
	if(self.control) then
		self.control:scrollToPos(nil, self.DefaultNodeHeight * (index - 1));
	end	
end

function pe_treeview:UpdateChildLayout(layout)
	pe_treeview._super.UpdateChildLayout(self, layout);
	
	local width, height = layout:GetUsedSize()
	if(self.control) then
		width = width + self.control:GetSliderSize();
	end
	layout:SetUsedSize(width, height);


	--layout:AddObject(width, height);
end