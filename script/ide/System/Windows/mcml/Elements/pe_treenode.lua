--[[
Title: pe:treeview element
Author(s): LiXizhi
Date: 2016/7/19
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

function pe_treenode:LoadComponent(parentElem, parentLayout, styleItem)
	local _this = self.control;
	if(not _this) then
		_this = TreeNode:new():init(parentElem);
		self:SetControl(_this);
	end
	local buttonName = self:GetAttributeWithCode("name",nil,true);
	_this:Connect("clicked", function()
		self:OnClick(buttonName);
	end);
	PageElement.LoadComponent(self, _this, parentLayout, styleItem)
end

-- draw tree node handler.
-- return nil or the new height if current node height is not suitable, it will cause the node to be redrawn.
--function pe_treenode.DrawNodeHandler(_parent,treeNode)
function pe_treenode:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	self.treeview = self:GetParent("pe:treeview");
	self.ItemToggleSize = self:GetNumber("ItemToggleSize",nil,true);

	css:Merge(mcml:GetStyleItem(self.class_name));

	local _this = self.control;

	--node.Name = self:GetAttributeWithCode("name");
	self.DefaultIndentation = self.treeview.DefaultIndentation or 10;

	self.text = self:GetAttributeWithCode("text",nil,true);
	self.expanded = self:GetAttributeWithCode("expanded",false,true);
	self.selected = self:GetAttributeWithCode("selected",nil,true);
	self.NodeHeight = tonumber(self:GetAttributeWithCode("height")) or css["height"];
	
	_this:SetText(self:GetAttributeWithCode("text",nil,true));
	_this:SetTooltip(self:GetAttributeWithCode("tooltip",nil,true));
	_this:SetTextColor(css["color"]);
	local font,_,scale = css:GetFontSettings();
	_this:SetFont(font);
	_this:SetScale(scale);
	local icon = self:GetAttributeWithCode("icon",nil,true);
	if(icon) then
		_this:SetIcon(icon);
	end

	_this:SetNodeHeight(tonumber(self:GetAttributeWithCode("height"), nil, true) or css["height"]);

	local indent = self:GetAttributeWithCode("indent",nil,true);
	if(indent) then
		_this:SetIndent(tonumber(indent));
	end

	_this:SetExpanded(self.expanded);

	_this:SetSelected(self.selected);

	_this:SetInvisible(self:GetAttributeWithCode("invisible") == "true");
	_this:SetMouseOverBG(self:GetAttributeWithCode("MouseOverBG",nil,true));
	_this:SetNormalBG(self:GetAttributeWithCode("NormalBG",nil,true));
	_this:SetItemToggleSize(self:GetNumber("ItemToggleSize",nil,true));


	self:CreateNode();

--	_this:Connect("clicked", self, self.OnClick);

	--attrBind = self:GetAttributeWithCode("AttributeBind");
	-- search for render template, this is only set for static nodes. for databinded nodes, it is set during data binding. 
--	if(not self.render_template_node) then
--		local RenderTemplate = self:GetString("RenderTemplate");
--		if(RenderTemplate) then
--			local tmpNode = self:GetParent("pe:treeview");
--			if(tmpNode) then
--				local tmpNode = tmpNode:GetChild("NodeTemplates");
--				if(tmpNode) then
--					local tmpNode = tmpNode:GetChildWithAttribute("DataType", RenderTemplate);
--					if(tmpNode) then
--						self.render_template_node = tmpNode;
--					else
--						LOG.std("", "error", "pe:treeview", "unable to find data type %s", RenderTemplate)
--					end
--				end
--			end
--		end
--	end
end

function pe_treenode:OnLoadComponentAfterChild(parentElem, parentLayout, css)
	if(self.node and self.node.expandBtn and self.node.expandBtn.control) then
		local buttonName = self:GetAttributeWithCode("name",nil,true);
		self.node.expandBtn.control:Connect("clicked", function()
			self:OnClick(buttonName);
		end);
	end

--	if(self.control and self.expandBtn) then
--		self.control:Connect("clicked", self.expandBtn, self.expandBtn.OnClick);
--	end

--	if(self.label and self.label.name == "button" and self.label.control) then
--		self.label.control:Connect("clicked", self, self.OnClick)
--		self.label.control:SetBackground("Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;3 3 3 3:1 1 1 1");
--		self.label.control:SetColor("#000000");
--		if(self.expandBtn) then
--			self.label.control:Connect("clicked", self.expandBtn, self.expandBtn.OnClick)
--		end
--	end

	self:setChildrenVisible(self.expanded);
end

function pe_treenode:CreateNode()
	local style;

	local height = self.NodeHeight;
	if(not height and self.treeview) then
		height = height or self.treeview.DefaultNodeHeight or 24;
	end

	if(self.treeview) then
		style = format("min-height:%dpx;", self.treeview.DefaultNodeHeight or 24);
	end

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
	if(#self > 0) then
		local attr={ style=style};
--		attr["CheckedBG"] = self.treeview.ItemOpenBG or "Texture/3DMapSystem/common/itemopen.png";
--		attr["UncheckedBG"] = self.treeview.ItemCloseBG or "Texture/3DMapSystem/common/itemclosed.png";
		attr["CheckedBG"] = self.treeview.ItemOpenBG;
		attr["UncheckedBG"] = self.treeview.ItemCloseBG;
		attr["polygonStyle"] = "narrow";
		attr["checked"] = self.expanded;
		node = mcml:createFromXmlNode({name="checkbox", attr = attr});
		self.node:AddChild(node);
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
		self.node:AddChild(node);

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
		node = mcml:createFromXmlNode({name="div", attr={style=style}, self.text});
		self.node:AddChild(node);


		--style = style.."background:url(Texture/alphadot.png)"
--		self.label = pe_button:createFromXmlNode({name="button", attr={value=self.text, style=style}});
--		self.label = pe_div:createFromXmlNode({name="div", attr={style=style}, self.text});
--		--self.label.onclickscript = self.OnClick;
--		self.node:AddChild(self.label, child_index);
	end

	self:AddChild(self.node, 1);
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

function pe_treenode:UpdateChildLayout(layout)
	local beOffset = false;
	for childnode in self:next() do
		--if(childnode == self.label or childnode == self.expandBtn) then
		if(childnode == self.node) then
			--do nothing
		else
			if(not beOffset) then
				layout:OffsetPos(self.DefaultIndentation);
				beOffset = true;
			end
		end

		childnode:UpdateLayout(layout);
	end
	if(beOffset) then
		layout:OffsetPos(-self.DefaultIndentation);
	end
end

-- virtual function: 
-- after child node layout is updated
function pe_treenode:OnAfterChildLayout(layout, left, top, right, bottom)
	if(self.control) then
		self.control:setGeometry(left, top, right-left, bottom-top);
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

function pe_treenode:OnClick(buttonName)
	
	if(#self > 1) then
		self.expanded = not self.expanded;
		self.selected = not self.selected;
		self:setChildrenVisible(self.expanded);

		if(self.node and self.node.expandBtn) then
			self.node.expandBtn:setChecked(self.expanded);
		end
		
		return;
	end

	--self.expandBtn

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
		result = self:DoPageEvent(onclick, buttonName, self)
	end
	return result;
end