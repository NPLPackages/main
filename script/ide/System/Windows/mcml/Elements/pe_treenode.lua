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
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_treenode.lua");
System.Windows.mcml.Elements.pe_treenode:RegisterAs("pe:treenode");
------------------------------------------------------------
]]

local PageElement = commonlib.gettable("System.Windows.mcml.PageElement");
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_container.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/TreeNode.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_button.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_checkbox.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_div.lua");
local pe_button = commonlib.gettable("System.Windows.mcml.Elements.pe_button");
local pe_checkbox = commonlib.gettable("System.Windows.mcml.Elements.pe_checkbox");
local pe_div = commonlib.gettable("System.Windows.mcml.Elements.pe_div");
local TreeNode = commonlib.gettable("System.Windows.Controls.TreeNode");
local mcml = commonlib.gettable("System.Windows.mcml");

local pe_treenode = commonlib.inherit(commonlib.gettable("System.Windows.mcml.Elements.pe_container"), commonlib.gettable("System.Windows.mcml.Elements.pe_treenode"));
pe_treenode:Property({"class_name", "pe:treenode"});

function pe_treenode:ctor()
	
end

function pe_treenode:CreateControl()
	local parentElem = self:GetParentControl();
	local _this = TreeNode:new():init(parentElem);
	self:SetControl(_this);

	self.buttonName = self:GetAttributeWithCode("name",nil,true);
	--_this:Connect("clicked", self, self.OnClick, "UniqueConnection");

	pe_treenode._super.CreateControl(self);
end

function addIndentionForNode(node, indention)
	node.attr = node.attr or {};
	node.attr.style = node.attr.style or "";
	node.attr.style = string.format("margin-left:%dpx;%s", indention, node.attr.style)
end

-- draw tree node handler.
-- return nil or the new height if current node height is not suitable, it will cause the node to be redrawn.
--function pe_treenode.DrawNodeHandler(_parent,treeNode)
function pe_treenode:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	self.treeview = self:GetParent("pe:treeview");
	self.ItemToggleSize = self:GetNumber("ItemToggleSize",nil,true);

	self.DefaultIndentation = self.treeview.DefaultIndentation or 10;

	self.text = self:GetAttributeWithCode("text",nil,true);
	self.expanded = self:GetBool("expanded",false,true);
	self.selected = self:GetAttributeWithCode("selected",nil,true);
	self.NodeHeight = tonumber(self:GetAttributeWithCode("height"));
	if(not self.NodeHeight) then
		local height_property = self:GetInlineStyleDecl():GetProperty("height");
		if(height_property) then
			self.NodeHeight = height_property:Value();
		end
	end

	for child in self:next() do
		addIndentionForNode(child, self.treeview.DefaultIndentation);
	end

	self:CreateNode();

	pe_treenode._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css)
end

function pe_treenode:OnLoadComponentAfterChild(parentElem, parentLayout, css)
	self:setChildrenVisible(self.expanded);
end

function pe_treenode:CreateNode()
	local style = "";
--	if(self.attr and self.attr.style) then
--		style = self.attr.style;
--	else
--		style = "";
--	end

	local height = self.NodeHeight;
	if(not height and self.treeview) then
		height = height or self.treeview.DefaultNodeHeight or 24;
	end

	if(self.treeview) then
		style = format("min-height:%dpx;%s", self.treeview.DefaultNodeHeight or 24, style);
	end
--	style = style.."background-color:#ffffff00;";
	local node = mcml:createFromXmlNode({name="div", attr = {style = style}});
	self.node = node;

	local spacing_right;
	if(self.treeview) then
		spacing_right = self.treeview.ItemToggleRightSpacing;
	end
	spacing_right = spacing_right or 6;


	local item_size = self.ItemToggleSize;
	if(not item_size and self.treeview) then
		item_size = self.treeview.ItemToggleSize or 10;
	end

	local spacing = math.floor((height - item_size)/2);

	style = "margin-top:"..tostring(spacing).."px;width:"..tostring(item_size).."px;".."height:"..tostring(item_size).."px;";

	--local child_index = 1;
	--if(#self > 0) then
	if(self:GetChildCount() > 0) then
		local attr={ style=style};
--		attr["CheckedBG"] = self.treeview.ItemOpenBG or "Texture/3DMapSystem/common/itemopen.png";
--		attr["UncheckedBG"] = self.treeview.ItemCloseBG or "Texture/3DMapSystem/common/itemclosed.png";
		attr["CheckedBG"] = self.treeview.ItemOpenBG;
		attr["UncheckedBG"] = self.treeview.ItemCloseBG;
		attr["type"] = "checkbox";
		attr["polygonStyle"] = "narrow";
		attr["checked"] = if_else(self.expanded, "true", "false");
		node = mcml:createFromXmlNode({name="input", attr = attr});
		node.onclickscript = function ()
			pe_treenode.OnClick(self);
		end
		--self.node:AddChild(node);
		self.node:AppendChild(node, false);
		self.node.expandBtn = node;
		--child_index = child_index + 1;
	end
	

	if(not self.render_template_node) then
		local RenderTemplate = self:GetString("RenderTemplate");
		if(RenderTemplate) then
			local tmpNode = self.treeview:GetChild("NodeTemplates");
			if(tmpNode) then
				local tmpNode = tmpNode:GetChildWithAttribute("DataType", RenderTemplate);
				if(tmpNode) then
					self.render_template_node = tmpNode;
				else
					LOG.std("", "error", "pe:treeview", "unable to find data type %s", RenderTemplate)
				end
			end
		end
	end

	--local width = self.treeview.ClientWidth - item_size - spacing_right - 2;

	style = "float:true;margin-left:"..tostring(spacing_right).."px;";
	if(self.render_template_node) then
		local o = commonlib.copy(self.render_template_node);
		o.attr = o.attr or {};
		o.attr.style = style;
		node = mcml:createFromXmlNode(o);
		--self.node:AddChild(node);
		self.node:AppendChild(node, false);

--		local class_type = mcml:GetClassByTagName(o.name or "div");
--		if(class_type) then
----			self.label = class_type:createFromXmlNode(o);
----			self.node:AddChild(self.label, child_index);
--			node = class_type:createFromXmlNode(o);
--			self.node:AddChild(self.label, child_index);
--		else
--			LOG.std(nil, "warn", "mcml", "can not find tag name %s", child.name or "");
--		end
	else
		--style = style.."background-color:#ffffff00;";
		node = mcml:createFromXmlNode({name="span", attr={style=style}, self.text});
		self.node:AppendChild(node, false);


		--style = style.."background:url(Texture/alphadot.png)"
--		self.label = pe_button:createFromXmlNode({name="button", attr={value=self.text, style=style}});
--		self.label = pe_div:createFromXmlNode({name="div", attr={style=style}, self.text});
--		--self.label.onclickscript = self.OnClick;
--		self.node:AddChild(self.label, child_index);
	end

	self:InsertBefore(self.node, self:FirstChild(), false);
end

function pe_treenode:GetLabelWidth()
	local spacing_right;
	if(self.treeview) then
		spacing_right = self.treeview.ItemToggleRightSpacing;
	end
	spacing_right = spacing_right or 6;

	local item_size = self.ItemToggleSize;
	if(not item_size and self.treeview) then
		item_size = self.treeview.ItemToggleSize or 10;
	end

	local width = self.treeview.ClientWidth - item_size - spacing_right - 2;
	return width;
end

function pe_treenode:SwitchExpanded()
	self.expanded = not self.expanded;
	self.selected = not self.selected;
	for childnode in self:next() do
		--if(childnode == self.label or childnode == self.expandBtn) then
		if(childnode == self.node) then
			-- do nothing	
		else
			if(self.expanded) then
				childnode:show();
			else
				childnode:hide();
			end
		end
	end
end

function pe_treenode:setChildrenVisible(visible)
	for childnode in self:next() do
		--if(childnode == self.label or childnode == self.expandBtn) then
		if(childnode == self.node) then
			-- do nothing	
		else
			if(self.expanded) then
				childnode:show();
			else
				childnode:hide();
			end
		end
	end
end

function pe_treenode:OnClick()
	if(self:GetChildCount() > 1) then
		self.expanded = not self.expanded;
		self.selected = not self.selected;
		self:setChildrenVisible(self.expanded);
		
		return;
	end

	local bindingContext;
	local onclick = self.onclickscript or self:GetString("onclick");
	if(onclick == "")then
		onclick = nil;
	end
	if(not onclick) then
		local treeview = self:GetParent("pe:treeview");
		if(treeview) then
			onclick = treeview.onclick;
		end
	end

	local result;
	if(onclick) then
		result = self:DoPageEvent(onclick, self.buttonName, self)
	end
	return result;
end