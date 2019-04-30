--[[
Title: PageElement
Author(s): LiXizhi
Date: 2015/4/27
Desc: base class to all page elements. 
Page element is responsible for creation, layout, editing(via external mcml editors) of UIElements. 
Each page element may be associated with zero or more UI elements. 

virtual functions:
	LoadComponent(parentElem, parentLayout, style) 
		OnLoadComponentBeforeChild(parentElem, parentLayout, css)
		OnLoadComponentAfterChild(parentElem, parentLayout, css)
	UpdateLayout(layout) 
		OnBeforeChildLayout(layout)
		OnAfterChildLayout(layout, left, top, right, bottom)
	paintEvent(painter)

---++ Guideline for subclass PageElement. 
Whenever a page is first loaded or refreshed, LoadComponent() is called once.
You need to overload either LoadComponent, OnLoadComponentBeforeChild, or OnLoadComponentAfterChild 
to create any inner UI Element and attach them properly to the passed-in parent UI element. 
Remember to keep a reference of the UI element on the page element as well, so that you can re-position them 
during UpdateLayout(). If there is only one UI element, we usually call SetControl() to assign it to self.control. 

After all page component is loaded, the UpdateLayout will be called. 
You need to override either UpdateLayout, OnBeforeChildLayout or OnAfterChildLayout,
 to setGeometry of any loaded components(i.e. UI Element). UpdateLayout may be called recursively. 
It is also called when the top level layout resizes due to user interaction or resize event. 

If your page element handles paintEvent, you must call EnableSelfPaint() during one of the LoadComponent overrides.
It will create a dummy UIElement which redirect paintEvent to the pageElement. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
local PageElement = commonlib.gettable("System.Windows.mcml.PageElement");
local elem = PageElement:new();
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/localserver/UrlHelper.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleDeclaration.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyle.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutTreeBuilder.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/ImageLoader.lua");
local ImageLoader = commonlib.gettable("System.Windows.mcml.ImageLoader");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local LayoutTreeBuilder = commonlib.gettable("System.Windows.mcml.layout.LayoutTreeBuilder");
local LayoutObject = commonlib.gettable("System.Windows.mcml.layout.LayoutObject");
local ComputedStyle = commonlib.gettable("System.Windows.mcml.style.ComputedStyle");
local CSSStyleDeclaration = commonlib.gettable("System.Windows.mcml.css.CSSStyleDeclaration");
local mcml = commonlib.gettable("System.Windows.mcml");
local Elements = commonlib.gettable("System.Windows.mcml.Elements");


local DisplayEnum = ComputedStyleConstants.DisplayEnum;

local PageElement = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Windows.mcml.PageElement"));
-- default style sheet
PageElement:Property("Name", "PageElement");
PageElement:Property({"class_name", nil});
PageElement:Property({"tab_index", -1, "TabIndex", "SetTabIndex", auto=true});
PageElement:Property({"classNames", nil, "GetClassNames", "SetClassNames", auto=true});
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local tonumber = tonumber
local type = type
local string_find = string.find;
local string_format = string.format;
local string_gsub = string.gsub;
local string_lower = string.lower
local string_match = string.match;
local LOG = LOG;
local NameNodeMap_ = {};
local commonlib = commonlib.gettable("commonlib");

local StyleChangeTypeEnum = ComputedStyleConstants.StyleChangeTypeEnum;

local StyleChangeEnum = { 
	["NoChange"] = 0,
	["NoInherit"] = 1, 
	["Inherit"] = 2,
	["Detach"] = 3,
	["Force"] = 4,
};

PageElement.StyleChangeEnum = StyleChangeEnum;

local NodeFlags = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.NodeFlags"));

local DefaultFlagValues = {
	["IsElementFlag"] = false;
	["IsStyledElementFlag"] = false;
	["HasIDFlag"] = false;
	["HasClassFlag"] = false;
	["IsAttachedFlag"] = false;
	["ChildNeedsStyleRecalcFlag"] = false;
	["InDocumentFlag"] = false;
	["IsLinkFlag"] = false;
    ["IsActiveFlag"] = false;
    ["IsHoveredFlag"] = false;
	["IsFocusedFlag"] = false;
	["InDetachFlag"] = false;

	["IsParsingChildrenFinishedFlag"] = false;
	["IsStyleAttributeValidFlag"] = false;

	
	["StyleChangeMask"] = StyleChangeTypeEnum.NoStyleChange;
};

function NodeFlags:ctor()
	self:Reset();
end

function NodeFlags:Reset(mask)
	if(mask) then
		self[mask] = DefaultFlagValues[mask];
	else
		for k, v in pairs(DefaultFlagValues) do
			self[k] = v;
		end
	end
end

function PageElement:ctor()
	self.m_document = nil;
	self.isPageElement = true;

	self.layout_object = nil;
	-- inline style, CSSStyleDeclaration from the attribute "style". According to inlineStyleDecl in webkit;
	-- now use "inlineStyleDecl" replaced it.
	self.style = nil;

	self.m_previous = nil;
	self.m_next = nil;

	self.m_firstChild = nil;
	self.m_lastChild = nil;

	self.inlineStyleDecl = nil;

	self.m_attributeMap = {};

	self.m_nodeFlags = NodeFlags:new();
end

-- virtual public function: create a page element (and recursively all its children) according to input xmlNode o.
-- generally one do not need to override this function, unless you want to control how child nodes are initialized. 
-- @param o: pure xml node table. 
-- @return the input o is returned. 
function PageElement:createFromXmlNode(o)
	o = self:new(o);
	o:BeginParsingChildren();
	o:createChildRecursive_helper();
	o:FinishParsingChildren();
	return o;
end

function PageElement:BeginParsingChildren()
	self:ClearIsParsingChildrenFinished();
end

function PageElement:FinishParsingChildren()
	self:SetIsParsingChildrenFinished();
end

function PageElement:CopyOriginalData()
	local o = {};
	o.name = self.name;
	o.attr = commonlib.copy(self.attr);
	if(#self ~= 0) then
		for i, child in ipairs(self) do
			if(type(child) == "table" and child.clone) then
				o[i] = child:CopyOriginalData();
			else
				o[i] = commonlib.copy(child)
			end
		end
	end
end

function PageElement:clone()
	local o = self:new();
	o.name = self.name;
	o.attr = commonlib.copy(self.attr);
	if(#self ~= 0) then
		for i, child in ipairs(self) do
			if(type(child) == "table" and child.clone) then
				o:AddChild(child:clone());
			else
				o:AddChild(commonlib.copy(child));
			end
		end
	end
	return o;
end

-- static public function
function PageElement:createChildRecursive_helper()
	if(#self ~= 0) then
		local previous;
		for i, child in ipairs(self) do
			if(type(child) == "table") then
				local class_type = mcml:GetClassByTagName(child.name or "div");
				if(class_type) then
					class_type:createFromXmlNode(child);
				else
					LOG.std(nil, "warn", "mcml", "can not find tag name %s", child.name or "");
				end
			else
				-- for inner text of xml
				child = Elements.pe_text:createFromString(child);
				--self[i] = child;
			end
			child.parent = self;
			--child.index = i;
			
			if(not self.m_firstChild) then
				self.m_firstChild = child;
			end

			self.m_lastChild = child;

			if(previous) then
				child.m_previous = previous;
				previous.m_next = child;
			end

			previous = child;
		end
	end
end

-- static function: register as a given tag name. 
-- @param name1, name2, name3, name4: can be nil, or alias name. 
function PageElement:RegisterAs(name, name1, name2, name3, name4)
	mcml:RegisterPageElement(name, self);
	if(name1) then
		mcml:RegisterPageElement(name1, self);
		if(name2) then
			mcml:RegisterPageElement(name2, self);
			if(name3) then
				mcml:RegisterPageElement(name3, self);
				if(name4) then
					mcml:RegisterPageElement(name4, self);
				end
			end
		end
	end
end

-- @param src: can be relative to current file or global filename.
function PageElement:LoadScriptFile(src)
	if(src ~= nil and src ~= "") then
		src = string.gsub(src, "^(%(.*%)).*$", "");
		src = self:GetAbsoluteURL(src);
		--if(ParaIO.DoesFileExist(src, true) or ParaIO.DoesFileExist(string.gsub(src, "(.*)lua", "bin/%1o"), true)) then
		-- SECURITY NOTE: load script in global environment
		NPL.load("(gl)"..src);
		--else
			--log("warning: MCML script does not exist locally :"..src.."\n");
		--end	
	end
end

--local skip_treenode_names = {
--	["NodeTemplates"] = true,
--	["EmptyDataTemplate"] = true,
--	["FetchingDataTemplate"] = true,
--}

local no_parse_nodes = {
	["option"] = true,
	["NodeTemplates"] = true,
	["EmptyDataTemplate"] = true,
	["FetchingDataTemplate"] = true,
	["Columns"] = true,
	["PagerSettings"] = true,
	["PagerTemplate"] = true,
	["Resource"] = true,
}

function PageElement:Rebuild(parentElem)
--	local styleItem;
--	if(self.parent) then
--		styleItem = self.parent:GetStyle();
--		parentElem = parentElem or self.parent.control;
--	end
--	self:LoadComponentIfNeeded(parentElem, nil, styleItem)
end

function PageElement:NeedsLoadComponent()
	if(no_parse_nodes[self.name]) then
		return false;
	end
	return true;
end

--[[
function PageElement:NeedsCreateControl()
	if(no_parse_nodes[self.name]) then
		return false;
	end
	return true;
end

function PageElement:CreateControlIfNeeded(parentElem)
	if(self:NeedsCreateControl()) then
		self:CreateControl(parentElem);
	end
end
--]]
function PageElement:CreateControl()

end

function PageElement:DestroyControl()
	if(self.control) then
		self.control:Destroy();
		self.control = nil;
	end
end

function PageElement:LoadComponentIfNeeded(parentElem, parentLayout, style_decl)
	if(self:NeedsLoadComponent(parentElem, parentLayout, style_decl)) then
		self:LoadComponent(parentElem, parentLayout, style_decl);
	end
end

-- virtual function: load component recursively. 
-- generally one do not need to override this function, override 
--  OnLoadComponentBeforeChild and OnLoadComponentAfterChild instead. 
-- @param parentLayout: only for casual initial layout. 
-- @return used_width, used_height
function PageElement:LoadComponent(parentElem, parentLayout, styleItem)
	-- apply models
	self:ApplyPreValues();

	-- process any variables that is taking place. 
	self:ProcessVariables();

	--self:checkAttributes();
	self:ParseAllMappedAttribute();
	
	if(self:GetAttribute("trans")) then
		-- here we will translate all child nodes recursively, using the given lang 
		-- unless any of the child attribute disables or specifies a different lang
		self:TranslateMe();
	end
	--local css = self:GetStyle();

	--self:attachLayoutTree();

	--css.background = css.background or self:GetAttribute("background", nil);

	self:OnLoadComponentBeforeChild(parentElem, parentLayout, css);

	self:OnLoadChildrenComponent(parentElem, parentLayout, css);
	
	self:OnLoadComponentAfterChild(parentElem, parentLayout, css);
	
	-- call onload(self) function if any. 
	local onloadFunc = self:GetString("onload");
	if(onloadFunc and onloadFunc~="") then
		Elements.pe_script.BeginCode(self);
		local pFunc = commonlib.getfield(onloadFunc);
		if(type(pFunc) == "function") then
			pFunc(self);
		else
			LOG.std("", "warn", "mcml", "%s node's onload call back: %s is not a valid function.", self.name, onloadFunc)	
		end
		Elements.pe_script.EndCode(rootName, self, bindingContext, _parent, left, top, width, height,style, parentLayout);
	end
	self:UnapplyPreValues();
end

function PageElement:ScrollTo(x, y)
	if(self.layout_object) then
		self.layout_object:ScrollToWithNotify(x, y);
	end
end

function PageElement:LayoutObjectIsNeeded(style)
	if(style and style:Display() == DisplayEnum.NONE) then
		return false;
	end
	return true;
end

PageElement.RendererIsNeeded = PageElement.LayoutObjectIsNeeded;


function PageElement:CreateLayoutObject(arena, style)
	return LayoutObject.CreateLayoutObject(self, style);
end

PageElement.CreateRenderer = PageElement.CreateLayoutObject;

function PageElement:GetLayoutObject()
	return self.layout_object;
end

function PageElement:Renderer()
	return self:GetLayoutObject();
end

function PageElement:SetLayoutObject(layout_object)
	self.layout_object = layout_object;
end

function PageElement:SetRenderer(renderer)
	self.layout_object = renderer;
end

function PageElement:CreateRendererIfNeeded()
	LayoutTreeBuilder:init(self):CreateLayoutObjectIfNeeded();
end

function PageElement:attachLayoutTree()
	--local computed_style = self:StyleForLayoutObject();
	--local computed_style = if_else(self.style, self.style.computed_style, nil);
	
	self:CreateRendererIfNeeded();

	local child = self.m_firstChild;
	while(child) do
		child:attachLayoutTree();
		child = child:NextSibling();
	end
--	for (Node* child = m_firstChild; child; child = child->nextSibling())
--        child->attach();
    --Node::attach();

	self:SetAttached();
    self:ClearNeedsStyleRecalc();
end



PageElement.Attach = PageElement.attachLayoutTree;

function PageElement:reattachLayoutTree()
    if (self:Attached()) then
        self:detachLayoutTree();
--		self:DestroyControl();
	end
    self:attachLayoutTree();
end

PageElement.Reattach = PageElement.reattachLayoutTree;

function PageElement:detachLayoutTree()
	local child = self.m_firstChild;
	while(child) do
		child:detachLayoutTree();

		child = child:NextSibling();
	end

	--self:DestroyControl();

    self:ClearChildNeedsStyleRecalc();


	self:SetFlag("InDetachFlag");

    if (self:Renderer()) then
        self:Renderer():Destroy();
	end
    self:SetRenderer(nil);

--    Document* doc = document();
--    if (hovered())
--        doc->hoveredNodeDetached(this);
--    if (inActiveChain())
--        doc->activeChainNodeDetached(this);

    self:ClearFlag("IsActiveFlag");
    self:ClearFlag("IsHoveredFlag");
    self:ClearFlag("IsFocusedFlag");
    self:ClearFlag("IsAttachedFlag");

    self:ClearFlag("InDetachFlag");	
end

PageElement.Detach = PageElement.detachLayoutTree;

-- private: redirector
local function paintEventRedirectFunc(uiElement, painter)
	local page_element = uiElement:PageElement();
	if(page_element) then
		page_element:paintEvent(painter);
	end
end

-- enable self.paintEvent for this page element by creating a delegate UIElement and attach it to parentElem. 
-- only call this function once during LoadComponent.
function PageElement:EnableSelfPaint(parentElem)
	if(not self.control) then
		local _this = System.Windows.UIElement:new():init(parentElem);
		--_this._page_element = self;
		_this.paintEvent = paintEventRedirectFunc;
		self:SetControl(_this);
	else
		if(self.control:PageElement() == self) then
			self.control:SetParent(parentElem);
		else
			LOG.std("", "error", "mcml", "self paint can only be enabled when there is no control created for the page element");
		end
	end
end

-- virtual function: only called if EnableSelfPaint() is called during load component. 
function PageElement:paintEvent(painter)
end

-- this function is called automatically after page component is loaded and whenever the window resize. 
function PageElement:UpdateLayout(parentLayout)
	if(self:isHidden()) then 
		return 
	end
	if(no_parse_nodes[self.name]) then
		return;
	end
	local css = self:GetStyle();
	if(not css) then
		return;
	end
	local padding_left, padding_top, padding_right, padding_bottom = css:paddings();
	local margin_left, margin_top, margin_right, margin_bottom = css:margins();
	local availWidth, availHeight = parentLayout:GetPreferredSize();
	local maxWidth, maxHeight = parentLayout:GetMaxSize();
	local left, top;
	local width, height = self:GetAttribute("width"), self:GetAttribute("height");
	if(width) then
		css.width = tonumber(string.match(width, "%d+"));
		if(css.width and string.match(width, "%%$")) then
			if(css.position == "screen") then
				css.width = ParaUI.GetUIObject("root").width * css.width/100;
			else	
				css.width=math.floor((maxWidth-margin_left-margin_right)*css.width/100);
				if(availWidth<(css.width+margin_left+margin_right)) then
					css.width=availWidth-margin_left-margin_right;
				end
				if(css.width<=0) then
					css.width = nil;
				end
			end	
		end	
	end
	if(height) then
		css.height = tonumber(string.match(height, "%d+"));
		if(css.height and string.match(height, "%%$")) then
			if(css.position == "screen") then
				css.height = ParaUI.GetUIObject("root").height * css.height/100;
			else	
				css.height=math.floor((maxHeight-margin_top-margin_bottom)*css.height/100);
				if(availHeight<(css.height+margin_top+margin_bottom)) then
					css.height=availHeight-margin_top-margin_bottom;
				end
				if(css.height<=0) then
					css.height = nil;
				end
			end	
		end	
	end
	-- whether this control takes up space
	local bUseSpace; 
	if(css.float) then
		if(css.width) then
			if(availWidth<(css.width+margin_left+margin_right)) then
				parentLayout:NewLine();
			end
		end	
	else
		parentLayout:NewLine();
	end
	local myLayout = parentLayout:clone();
	myLayout:ResetUsedSize();

	local align = self:GetAttribute("align") or css["align"];
	local valign = self:GetAttribute("valign") or css["valign"];

	if(css.position == "absolute") then
		-- absolute positioning in parent
		if(css.width and css.height and css.left and css.top) then
			-- if all rect is provided, we will do true absolute position. 
			myLayout:reset(css.left, css.top, css.left + css.width, css.top + css.height);
		else
			-- this still subject to parent rect. 
			myLayout:SetPos(css.left, css.top);
		end
		myLayout:ResetUsedSize();
	elseif(css.position == "relative") then
		-- relative positioning in next render position. 
		myLayout:OffsetPos(css.left, css.top);
	elseif(css.position == "screen") then	
		-- relative positioning in screen client area
		local offset_x, offset_y = 0, 0;
		local left, top = self:GetAttribute("left"), self:GetAttribute("top");
		if(left) then
			left = tonumber(string.match(left, "(%d+)%%$"));
			offset_x = ParaUI.GetUIObject("root").width * left/100;
		end
		if(top) then
			top = tonumber(string.match(top, "(%d+)%%$"));
			offset_y = ParaUI.GetUIObject("root").height * top/100;
		end
		local px,py = _parent:GetAbsPosition();
		myLayout:SetPos((css.left or 0)-px + offset_x, (css.top or 0)-py + offset_y); 
	else
		myLayout:OffsetPos(css.left, css.top);
		bUseSpace = true;	
	end
	
	left,top = myLayout:GetAvailablePos();
	myLayout:SetPos(left,top);
	width,height = myLayout:GetSize();
	if(css.width) then
		myLayout:IncWidth(left+margin_left+margin_right+css.width-width)
	end
	
	if(css.height) then
		myLayout:IncHeight(top+margin_top+margin_bottom+css.height-height)
	end	
	
	-- for inner control preferred size
	myLayout:OffsetPos(margin_left+padding_left, margin_top+padding_top);
	myLayout:IncWidth(-margin_right-padding_right)
	myLayout:IncHeight(-margin_bottom-padding_bottom)

	-- self.m_left, self.m_top = left+margin_left, top+margin_top;
	-----------------------------
	-- self and child layout recursively.
	-----------------------------
	if(not self:OnBeforeChildLayout(myLayout)) then
		self:UpdateChildLayout(myLayout);
	end
	
	local width, height = myLayout:GetUsedSize()
	local real_w = width + padding_right - left - margin_left;
	local real_h = height + padding_bottom - top - margin_top;
	myLayout:SetRealSize(real_w, real_h);
	width = width + padding_right + margin_right
	height = height + padding_bottom + margin_bottom
	if(css.width) then
		width = left + css.width + margin_left + margin_right;
	end	
	if(css.height) then
		height = top + css.height + margin_top + margin_bottom;
	end
	if(css["min-width"]) then
		local min_width = css["min-width"];
		if((width-left - margin_left-margin_right) < min_width) then
			width = left + min_width + margin_left + margin_right;
		end
	end
	if(css["min-height"]) then
		local min_height = css["min-height"];
		if((height-top - margin_top - margin_bottom) < min_height) then
			height = top + min_height + margin_top + margin_bottom;
		end
	end
	if(css["max-height"]) then
		local max_height = css["max-height"];
		if((height-top) > max_height) then
			height = top + max_height;
		end
	end
	myLayout:SetUsedSize(width, height);
	-- self.m_right, self.m_bottom = width-margin_right, height-margin_bottom;
	-- call virtual function for final size calculation. 
	self:OnAfterChildLayout(myLayout, left+margin_left, top+margin_top, width-margin_right, height-margin_bottom);
	width, height = myLayout:GetUsedSize();

	local size_width, size_height = width-left, height-top;
	local offset_x, offset_y = 0, 0;
	
	-- align at center. 
	if(align == "center") then
		offset_x = (maxWidth - size_width)/2
	elseif(align == "right") then
		offset_x = (maxWidth - size_width);
	end	
	
	if(valign == "center") then
		offset_y = (maxHeight - size_height)/2
	elseif(valign == "bottom") then
		offset_y = (maxHeight - size_height);
	end	
	if(offset_x~=0 or offset_y~=0) then
		-- offset and recalculate if there is special alignment. 
		myLayout = parentLayout:clone();
		local left, top = left+offset_x, top+offset_y;
		myLayout:SetPos(left, top);
		myLayout:SetSize(left+size_width, top+size_height);
		myLayout:OffsetPos(margin_left+padding_left, margin_top+padding_top);
		myLayout:IncWidth(-margin_right-padding_right);
		myLayout:IncHeight(-margin_bottom-padding_bottom);
		myLayout:ResetUsedSize();
		if(not self:OnBeforeChildLayout(myLayout)) then
			self:UpdateChildLayout(myLayout);
		end
		local right, bottom = left+size_width, top+size_height
		myLayout:SetUsedSize(right, bottom);
		self:OnAfterChildLayout(myLayout, left+margin_left, top+margin_top, right-margin_right, bottom-margin_bottom);
		width, height = myLayout:GetUsedSize();
	end

--	if(self.layout_object) then
--		self.layout_object:setLayout(myLayout)
--	end

	

	if(bUseSpace) then
		parentLayout:AddObject(width-left, height-top);
		if(not css.float) then
			parentLayout:NewLine();
		end	
	end
end

-- virtual function: adjust control size according to preferred rect of layout. 
-- before child node layout is updated.
-- @return normally return nil. if return true, child nodes will be skipped. 
function PageElement:OnBeforeChildLayout(layout)
	
end

-- virtual function: 
-- after child node layout is updated
-- @param left, top, right, bottom: may be nil. it can also be preferred size of the control after child layout is calculated (margins are already removed). 
function PageElement:OnAfterChildLayout(layout, left, top, right, bottom)
	
end

function PageElement:UpdateChildLayout(layout)
	for childnode in self:next() do
		childnode:UpdateLayout(layout);
	end
end

-- virtual function: 
-- @param css: style
function PageElement:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	local tab_index = self:GetAttributeWithCode("tabindex", nil, true);
	if(tab_index) then
		tab_index = tonumber(tab_index);
	end
	if(tab_index and tab_index > 0) then
		self:SetTabIndex(tab_index);
		local page = self:GetPageCtrl();
		page:AddTabIndexNode(tab_index, self);
	end
end

function PageElement:OnLoadComponentAfterChild(parentElem, parentLayout, css)
--	if(css) then
--		local default_css = mcml:GetStyleItem(self.class_name);
--		css:Merge(default_css);
--	end
end

function PageElement:OnLoadChildrenComponent(parentElem, parentLayout, css)
	local childnode = self:FirstChild()
	while(childnode) do
		childnode:LoadComponentIfNeeded(parentElem, parentLayout, css);

		childnode = childnode:NextSibling();
	end
end

local reset_layout_attrs = {
	["display"] = true,
	["style"] = true,
};

-- set the value of an attribute of this node. This function is rarely used. 
function PageElement:SetAttribute(attrName, value, notifyChanged)
	notifyChanged = if_else(notifyChanged==nil, true, notifyChanged)
	self.attr = self.attr or {};
	if(self.attr[attrName] ~= value) then
		self.attr[attrName] = value;
		if(notifyChanged) then
			self:AttributeChanged(attrName, value);
		end
--		if(attrName == "style" or attrName == "id" or attrName == "class") then
--			-- tricky code: since we will cache style table on the node, we need to delete the cached style when it is changed. 
--			-- self.style = nil;
--			if(attrName == "style") then
--				self.inlineStyleDecl = nil;
--			end
--
--			if(attrName == "class") then
--				self.classNames = nil;
--			end
--
--			self:SetNeedsStyleRecalc();
--			
--		end

--		if(beForceResetLayout ~= false and reset_layout_attrs[attrName]) then
--			self:resetLayout();
--		end
	end
end

function PageElement:AttributeMap()
	--self.m_attributeMap = self.m_attributeMap or {};
	return self.m_attributeMap;
end

function PageElement:AddAttributeCSSProperty(attrName, key, value)
	local attributeMap = self:AttributeMap();
	if(value == nil or value == "") then
		if(attributeMap[attrName]) then
			attributeMap[attrName] = nil;
		end
		self:SetNeedsStyleRecalc();
		return;
	end
	local attrStyleDecl = attributeMap[attrName];
	if(attrStyleDecl == nil) then
		attributeMap[attrName] = CSSStyleDeclaration:new():init(self);
		attrStyleDecl = attributeMap[attrName];
	end
	attrStyleDecl:SetProperty(key, value);
end

function PageElement:ParseAllMappedAttribute()
	if(self.attr) then
		for name, value in pairs(self.attr) do
			if(name == "request_url" or name == "page_ctrl") then
				-- do nothing for pe:mcml node "request_url" and "page_ctrl" attribute.
				-- continue; 
			else
				value = self:GetAttributeWithCode(name, nil, true);

				self:AttributeChanged(name, value);
			end
			
		end
	end
end

function PageElement:AttributeChanged(attrName, value)
	self:ParseMappedAttribute(attrName, value);
end

function PageElement:ParseMappedAttribute(attrName, value)
	--if (isIdAttributeName(attr->name()))
	if (attrName == "id") then
        self:IdAttributeChanged(value);
		self:SetNeedsStyleRecalc();
    --else if (attr->name() == classAttr)
	elseif(attrName == "class") then
        self:ClassAttributeChanged(value);
		self:SetNeedsStyleRecalc();
    --else if (attr->name() == styleAttr) {
	elseif(attrName == "style") then
        self:StyleAttributeChanged(value);
		self:SetNeedsStyleRecalc();
	elseif(attrName == "display") then
		self:AddAttributeCSSProperty("display", "display", if_else(value=="none", "none", nil));
    end

end

function PageElement:IdAttributeChanged(value)
	local hasID = value and value ~= "";
	self:SetHasID(hasID);
end

function PageElement:ClassAttributeChanged(value)
	local hasClass = value and value ~= "";
	self:SetHasClass(hasClass);

	if(hasClass) then
		self:ParseClassNames(value);
	else
		self:ClearClassNames();
	end
end

function PageElement:StyleAttributeChanged(value)
	if (value == "") then
        self:DestroyInlineStyleDecl();
	else
        self:GetInlineStyleDecl():ParseDeclaration(value);
	end
	self:SetIsStyleAttributeValid();
end

-- set the attribute if attribute is not code. 
function PageElement:SetAttributeIfNotCode(attrName, value, notifyChanged)
	self.attr = self.attr or {};
	local old_value = self.attr[attrName];
	if(type(old_value) == "string") then
		local code = string_match(old_value, "^[<%%]%%(=.*)%%[%%>]$")
		if(code) then
			return;
		end
	end

	self:SetAttribute(attrName,value,notifyChanged);
end

-- get the value of an attribute of this node as its original format (usually string)
function PageElement:GetAttribute(attrName,defaultValue)
	if(self.attr and self.attr[attrName]) then
		return self.attr[attrName];
	end
	return defaultValue;
end

local EscapeCharacters = {
	["&#10;"] = "\n",
	["&#13;"] = "\r",
	["&#32;"] = " ",
	["&#33;"] = "!",
	["&#34;"] = '"',
	["&quot;"] = '"',
}

local function processEscapeCharacters(str)
	for escapeChar, realChar in pairs(EscapeCharacters) do
		str = string.gsub(str, escapeChar, realChar);
	end
	return str;
end

-- get the value of an attribute of this node (usually string)
-- this differs from GetAttribute() in that the attribute string may contain embedded code block which may evaluates to a different string, table or even function. 
-- please note that only the first call of this method will evaluate embedded code block, subsequent calls simply return the previous evaluated result. 
-- in most cases the result is nil or string, but it can also be a table or function. 
-- @param bNoOverwrite: default to nil. if true, the code will be reevaluated the next time this is called, otherwise the evaluated value will be saved and returned the next time this is called. 
-- e.g. attrName='<%="string"+Eval("index")}%>' attrName1='<%={fieldname="table"}%>'
function PageElement:GetAttributeWithCode(attrName,defaultValue, bNoOverwrite)
	if(self.attr) then
		local value = self.attr[attrName];
		if(type(value) == "string") then
			local code = string_match(value, "^[<%%]%%(=.*)%%[%%>]$")
			if(code) then
				value = Elements.pe_script.DoPageCode(code, self:GetPageCtrl());
				if(type(value) == "string") then
					value = processEscapeCharacters(value);
				end
				if(not bNoOverwrite) then
					self.attr[attrName] = value;
				end	
			end
		end
		if(value ~= nil) then
			return value;
		end
	end
	return defaultValue;
end

function PageElement:checkAttributes()
	if(self.attr) then
		for name, value in pairs(self.attr) do
			if(type(value) == "string") then
				local code = string_match(value, "^[<%%]%%(=.*)%%[%%>]$")
				if(code) then
					value = Elements.pe_script.DoPageCode(code, self:GetPageCtrl());
					self.attr[name] = value;
				end
			end
		end
	end
end


-- get an attribute as string
function PageElement:GetString(attrName,defaultValue)
	if(self.attr and self.attr[attrName]) then
		return self.attr[attrName];
	end
	return defaultValue;
end

-- get an attribute as number
function PageElement:GetNumber(attrName,defaultValue)
	if(self.attr and self.attr[attrName]) then
		return tonumber(self.attr[attrName]);
	end
	return defaultValue;
end

-- get an attribute as integer
function PageElement:GetInt(attrName, defaultValue)
	if(self.attr and self.attr[attrName]) then
		return math.floor(tonumber(self.attr[attrName]));
	end
	return defaultValue;
end


-- get an attribute as boolean
function PageElement:GetBool(attrName, defaultValue)
	if(self.attr and self.attr[attrName]) then
		local v = string_lower(tostring(self.attr[attrName]));
		if(v == "false") then
			return false
		elseif(v == "true") then
			return true
		end
	end
	return defaultValue;
end

-- get all pure text of only text child node
function PageElement:GetPureText()
	local text = "";
	local node = self:FirstChild();
	while(node) do
		if(node) then
			if(type(node) == "string") then
				text = text..node;
			elseif(node.name== "text" and type(node.value) == "string") then
				text = text..node.value;
			end
		end

		node = node:NextSibling();
	end
	return text;
end

-- get all inner text recursively (i.e. without tags) as string. 
function PageElement:GetInnerText()
	local text = "";
	local node = self:FirstChild();
	while(node) do
		if(node) then
			if(type(node) == "string") then
				text = text..node;
			elseif(type(node) == "table") then
				text = text..node:GetInnerText();
			elseif(type(node) == "number") then
				text = text..tostring(node);
			end
		end

		node = node:NextSibling();
	end
	return text;
end

--static inline bool hasOneChild(ContainerNode* node)
local function hasOneChild(node)
    local firstChild = node:FirstChild();
    return firstChild and not firstChild:NextSibling();
end

--static inline bool hasOneTextChild(ContainerNode* node)
local function hasOneTextChild(node)
    return hasOneChild(node) and node:FirstChild():IsTextNode();
end

--static void replaceChildrenWithFragment(HTMLElement* element, PassRefPtr<DocumentFragment> fragment, ExceptionCode& ec)
local function replaceChildrenWithFragment(element, fragment)
    if (not fragment:FirstChild()) then
        element:RemoveChildren();
        return;
    end

    if (hasOneTextChild(element) and hasOneTextChild(fragment)) then
        element:FirstChild():SetData(fragment:FirstChild():Data());
        return;
    end

    if (hasOneChild(element)) then
        element:ReplaceChild(fragment, element:FirstChild());
        return;
    end

    element:RemoveChildren();
    element:AppendChild(fragment);
end

--void HTMLElement::setInnerHTML(const String& html, ExceptionCode& ec)
function PageElement:SetInnerHTML(html)
	local fragment = mcml:createFragmentFromSource(html);
    if (fragment) then
        replaceChildrenWithFragment(self, fragment);
	end
end

-- set inner text. It will replace all child nodes with a text node
function PageElement:SetInnerText(text)
	self[1] = text;
	commonlib.resize(self, 1);
end

-- get value: it is usually one of the editor tag, such as <input>
function PageElement:GetValue()
end

-- set value: it is usually one of the editor tag, such as <input>
function PageElement:SetValue(value)
end

-- get UI value: get the value on the UI object with current node
-- @param instName: the page instance name. 
function PageElement:GetUIValue(pageInstName)
end

-- set UI value: set the value on the UI object with current node
function PageElement:SetUIValue(pageInstName, value)
end


-- set UI enabled: set the enabled on the UI object with current node
function PageElement:SetUIEnabled(pageInstName, value)
end

-- get UI value: get the value on the UI object with current node
-- @param instName: the page instance name. 
function PageElement:GetUIBackground(pageInstName)
end

-- set UI value: set the value on the UI object with current node
function PageElement:SetUIBackground(pageInstName, value)
end

-- call a control method
-- @param instName: the page instance name. 
-- @param methodName: name of the method.
-- @return: the value from method is returned
function PageElement:CallMethod(pageInstName, methodName, ...)
	if(self[methodName]) then
		return self[methodName](self, pageInstName, ...);
	else
		LOG.warn("CallMethod (%s) on object %s is not supported\n", tostring(methodName), self.name)
	end
end

-- return true if the page node contains a method called methodName
function PageElement:HasMethod(pageInstName, methodName)
	if(self[methodName]) then
		return true;
	end
end

-- invoke a control method. this is same as CallMethod, except that pageInstName is ignored. 
-- @param methodName: name of the method.
-- @return: the value from method is returned
function PageElement:InvokeMethod(methodName, ...)
	if(self[methodName]) then
		return self[methodName](self, ...);
	else
		LOG.warn("InvokeMethod (%s) on object %s is not supported\n", tostring(methodName), self.name)
	end
end

function PageElement:SetObjId(id)
	self.uiobject_id = id;
end

function PageElement:SetControl(control)
	self.control = control;
	if(control) then
		control:setPageElement(self);
	end
end

function PageElement:GetParentControl()
	if(self:Renderer()) then
		return self:Renderer():GetParentControl();
	end
	if(self:ParentNode()) then
		return self:ParentNode():GetControl();
	end
	return;
end

function PageElement:GetOrCreateControl(pageName)
	local control = self:GetControl(pageName)
	if(not control) then
		self:CreateControl();
	end
	return self.control;
end

-- get the control associated with this node. 
-- if self.uiobject_id is not nil, we will fetch it using this id, if self.control is not nil, it will be returned, otherwise we will use the unique path name to locate the control or uiobject by name. 
-- @param instName: the page instance name. if nil, we will ignore global control search in page. 
-- @return: It returns the ParaUIObject or CommonCtrl object depending on the type of the control found.
function PageElement:GetControl(pageName)
	if(self.uiobject_id) then
		local uiobj = ParaUI.GetUIObject(self.uiobject_id);
		if(uiobj:IsValid()) then
			return uiobj;
		end
	elseif(self.control) then
		return self.control;
	elseif(pageName) then
		local instName = self:GetInstanceName(pageName);
		if(instName) then
			local ctl = CommonCtrl.GetControl(instName);
			if(ctl == nil) then
				local uiobj = ParaUI.GetUIObject(instName);
				if(uiobj:IsValid()) then
					return uiobj;
				end
			else
				return ctl;	
			end
		end
	end
	return nil;
end

-- return font: "System;12;norm";  return nil if not available. 
function PageElement:CalculateFont(css)
	local font;
	if(css and (css["font-family"] or css["font-size"] or css["font-weight"]))then
		local font_family = css["font-family"] or "System";
		-- this is tricky. we convert font size to integer, and we will use scale if font size is either too big or too small. 
		local font_size = math.floor(tonumber(css["font-size"] or 12));
		local font_weight = css["font-weight"] or "norm";
		font = string.format("%s;%d;%s", font_family, font_size, font_weight);
	end
	return font;
end

-- get UI control 
function PageElement:GetUIControl(pageName)
	if(self.uiobject_id) then
		local uiobj = ParaUI.GetUIObject(self.uiobject_id);
		if(uiobj:IsValid()) then
			return uiobj;
		end
	else
		local instName = self:GetInstanceName(pageName);
		if(instName) then
			local uiobj = ParaUI.GetUIObject(instName);
			if(uiobj:IsValid()) then
				return uiobj;
			end
		end
	end
end

-- print information about the parent nodes
function PageElement:printParents()
	log(tostring(self.name).." is a child of ")
	if(self.parent == nil) then
		log("\n")
	else
		self.parent:printParents();
	end
end

function PageElement:printLayout(layout)
	if(layout) then
		local temp = {};
		local name, value
		for name, value in pairs(layout) do
			if(type(value) ~= "table") then
				temp[name] = value;
			end
		end
		echo(temp);
	end	
end

-- print this node to log file for debugging purposes. 
function PageElement:print()
	log("<"..tostring(self.name));
	if(self.attr) then
		local name, value
		for name, value in pairs(self.attr) do
			commonlib.log(" %s=\"%s\"", name, value);
		end
	end	
--	local nChildSize = #(self);
--	if(nChildSize>0) then
--		log(">");
--		local i, node;
--		local text = "";
--		for i=1, nChildSize do
--			node = self[i];
--			if(type(node) == "table") then
--				log("\n")
--				node:print();
--			elseif(type(node) == "string") then
--				log(node)
--			end
--		end
--		log("</"..self.name..">\n");
--	else
--		log("/>\n");
--	end

	local node = self:FirstChild();
	if(node) then
		log(">");
		local text = "";
		while(node) do
			if(type(node) == "table") then
				log("\n")
				node:print();
			elseif(type(node) == "string") then
				log(node);
			end
			node = node:NextSibling();
		end
		log("</"..self.name..">\n");
	else
		log("/>\n");
	end
end

function PageElement:ChangeCSSValue(attrName, value)
	if(self.layout_object) then
		local computed_style = self.layout_object:Style();
		if(computed_style) then
			computed_style:ChangeValue(attrName, value);
		end
	end
end

-- set the value of a css style attribute after mcml node is evaluated. This function is rarely used. 
-- @note: one can only call this function when the mcml node is evaluated at least once, calling this function prior to evaluation will cause the style not to inherit its parent style 
-- alternatively, we can use self:SetAttribute("style", value) to change the entire attribute. 
-- @return true if succeed. 
function PageElement:SetCssStyle(attrName, value)
	if(not self.style) then
		self:CreateStyle();
	end

	if(self.style[attrName] ~= value) then
		self.style[attrName] = value;
		if(self.control) then
			self.control:ApplyCss(self.style);
		end
--		if(StyleItem.isResetField(attrName)) then
--			self:resetLayout();
--		end
	end
end


function PageElement:ApplyCss(style)
	style = style or self:GetLayoutObject():Style();
	ImageLoader.LoadHttpImage(style:BackgroundImage(), self);
	ImageLoader.LoadHttpImage(style:BackgroundCheckedImage(), self);
	ImageLoader.LoadHttpImage(style:BackgroundDownImage(), self);
	ImageLoader.LoadHttpImage(style:BackgroundOverImage(), self);

	if(self.control) then
		self.control:ApplyCss(style);
	end
end

-- get the ccs attribute of a given css style attribute value. 
function PageElement:GetCssStyle(attrName)
	if(type(self.style) == "table") then
		return self.style[attrName];
	end
end

-- update the css attribute.
-- this function is called when the texture attribute changed, such as "background", "background-color","background2", "background2-color", "background-image"
function PageElement:UpdateCssStyle()
	if(self.control) then
		self.control:ApplyCss(self.style);
	end
end

function PageElement:InvalidateStyle()
	self.style = nil;
end

-- get style item
function PageElement:GetStyle()
	return self.style;
end

-- apply any css classnames in class attribute
-- History:
--	name			date			declaration
--	lipeng			2018.1.21		now apply the style of the style sheet according to the attribute "id", "class" and its tag, its "class_name";
function PageElement:ApplyClasses(style)
	local pageStyle = self:GetPageStyle();
	if(pageStyle) then
		--local style = self:GetStyle();
		pageStyle:ApplyToStyleDeclaration(style, self);
	end
end

-- get the css style object if any. Style will only be evaluated once and saved to self.style as a table object, 
-- unless style attribute is changed by self:SetAttribute("style", value) method. 
-- order of style inheritance: base_baseStyle, baseStyle, style specified by attr.class.
-- @param baseStyle: nil or usually the default style with which the current node's style is merged.
-- @param base_baseStyle: this is optional. where to copy inheritable fields, usually from parent element's style object. 
-- @return: style table is a table of name value pairs. such as {color=string, href=string}
function PageElement:CreateStyle(baseStyle, base_baseStyle)
	local style = CSSStyleDeclaration:new():init(self);

	style:MergeInheritable(base_baseStyle);
	style:Merge(baseStyle);

	self:ApplyClasses(style);
	
	--
	-- apply instance if any
	--

	if(self.attr and self.attr.style) then
		local style_code = self:GetAttributeWithCode("style", nil, true);
		if(style_code) then
			self.style = CSSStyleDeclaration:CreateProxy(self);
			self.style:Merge(style_code);
		end
	end

	style:Merge(self.style);

	local computed_style = ComputedStyle:new():init(style);
	--self:CreateLayoutObject(computed_style);

	return computed_style;
end

function PageElement:GetComputedStyle()
	if(self.layout_object) then
		return self.layout_object:Style();
	end
	return;
end

function PageElement:RenderStyle()
	return self:GetComputedStyle();
end

function PageElement:StyleForLayoutObject()
--	local parent_style;
--	if(self.parent) then
--		local parent_computed_style = self.parent:GetComputedStyle();
--		if(parent_computed_style) then
--			parent_style = parent_computed_style:GetStyle();
--		end
--	end
--	return self:CreateStyle(nil, parent_style);
	return self:Document():StyleSelector():StyleForElement(self, nil, true);
end

--static inline void collectNodes(Node* node, NodeVector& nodes)
local function collectNodes(node, nodes)
--    for (Node* child = node->firstChild(); child; child = child->nextSibling())
--        nodes.append(child);
	local child = node:FirstChild();
	while(child) do
		nodes:append(child);
		child = child:NextSibling();
	end
end

--static void collectTargetNodes(Node* node, NodeVector& nodes)
local function collectTargetNodes(node, nodes)
    if (node:NodeType() ~= "DOCUMENT_FRAGMENT_NODE") then
        nodes:append(node);
        return;
    end
    collectNodes(node, nodes);
end

function PageElement:NodeType()
	return "ELEMENT_NODE";
end

--bool ContainerNode::replaceChild(PassRefPtr<Node> newChild, Node* oldChild, ExceptionCode& ec, bool shouldLazyAttach)
function PageElement:ReplaceChild(newChild, oldChild, refresh)
	refresh = if_else(refresh == nil, true, refresh);
    -- Check that this node is not "floating".
    -- If it is, it can be deleted as a side effect of sending mutation events.

	if(not newChild) then
		return;
	end

    if (oldChild == newChild) then -- nothing to do
        return true;
	end

    -- NOT_FOUND_ERR: Raised if oldChild is not a child of this node.
    if (not oldChild or oldChild:ParentNode() ~= self) then
        return false;
    end

    local prev = oldChild:PreviousSibling();
    local next = oldChild:NextSibling();

    -- Remove the node we're replacing
    local removedChild = oldChild;
    self:RemoveChild(oldChild, false);

    -- FIXME: After sending the mutation events, "this" could be destroyed.
    -- We can prevent that by doing a "ref", but first we have to make sure
    -- that no callers call with ref count == 0 and parent = 0 (as of this
    -- writing, there are definitely callers who call that way).

    local isFragment = newChild:NodeType() == "DOCUMENT_FRAGMENT_NODE";

    -- Add the new child(ren)
    local child = if_else(isFragment, newChild:FirstChild(), newChild);
    while (child) do
        -- If the new child is already in the right place, we're done.
        if (prev and (prev == child or prev == child:PreviousSibling())) then
            break;
		end

        -- For a fragment we have more children to do.
        local nextChild = if_else(isFragment, child:NextSibling(), nil);

        -- Remove child from its old position.
		local oldParent = child:ParentNode();
        if (oldParent) then
            oldParent:RemoveChild(child, false);
		end

        -- Due to arbitrary code running in response to a DOM mutation event it's
        -- possible that "prev" is no longer a child of "this".
        -- It's also possible that "child" has been inserted elsewhere.
        -- In either of those cases, we'll just stop.
        if (prev and prev:ParentNode() ~= self) then
            break;
		end
        if (child:ParentNode()) then
            break;
		end


        --child->setTreeScopeRecursively(treeScope());

        -- Add child after "prev".
        --forbidEventDispatch();
        local next = nil;
        if (prev) then
            next = prev:NextSibling();
            --ASSERT(m_firstChild != next);
            prev:SetNextSibling(child);
        else
            next = self.m_firstChild;
            self.m_firstChild = child;
        end
        if (next) then
            --ASSERT(m_lastChild != prev);
            --ASSERT(next->previousSibling() == prev);
            next:SetPreviousSibling(child);
        else
            --ASSERT(m_lastChild == prev);
            self.m_lastChild = child;
        end
        child:SetParent(self);
        child:SetPreviousSibling(prev);
        child:SetNextSibling(next);
        --allowEventDispatch();

        --childrenChanged(false, prev.get(), next, 1);
        --notifyChildInserted(child.get());
                
        -- Add child to the rendering tree
        if (self:Attached() and not child:Attached() and child:ParentNode() == self and refresh) then
            --if (shouldLazyAttach)
            --    child->lazyAttach();
            --else
            --    child->attach();
			child:LoadComponentIfNeeded();
			child:LazyAttach();
        end

        -- Now that the child is attached to the render tree, dispatch
        -- the relevant mutation events.
        --dispatchChildInsertionEvents(child.get());

        prev = child;
        child = nextChild;
    end

    --dispatchSubtreeModifiedEvent();
	if (self:Attached() and refresh) then
		self:PostLayoutRequestEvent();
	end
    return true;
end

function PageElement:AppendChild(newChild, refresh)
	refresh = if_else(refresh == nil, true, refresh);
	if(not newChild) then
		return;
	end

	if (newChild == self.m_lastChild) then -- nothing to do
        return false;
	end

	local targets = commonlib.vector:new();
	collectTargetNodes(newChild, targets)
	if(targets:empty()) then
		return;
	end

	-- Now actually add the child(ren)
    local prev = self:LastChild();
	for i = 1, #targets do
        local child = targets[i];
        -- If child is already present in the tree, first remove it
		local oldParent = child:ParentNode();
        if (oldParent and oldParent.RemoveChild) then
            oldParent:RemoveChild(child, false);

--            // If the child has a parent again, just stop what we're doing, because
--            // that means someone is doing something with DOM mutation -- can't re-parent
--            // a child that already has a parent.
--            if (child->parentNode())
--                break;
        end

        --child->setTreeScopeRecursively(treeScope());

        -- Append child to the end of the list
        --forbidEventDispatch();
        child:SetParent(self);
        if (self.m_lastChild) then
            child:SetPreviousSibling(self.m_lastChild);
            self.m_lastChild:SetNextSibling(child);
        else
            self.m_firstChild = child;
		end
        self.m_lastChild = child;
        --allowEventDispatch();

        -- Send notification about the children change.
        --childrenChanged(false, prev.get(), 0, 1);
        --notifyChildInserted(child);

        -- Add child to the rendering tree
        if (self:Attached() and not child:Attached() and child:ParentNode() == self and refresh) then
--            if (shouldLazyAttach) then
--                child:LazyAttach();
--            else
--                child:Attach();
--			end
			child:LoadComponentIfNeeded();
			child:LazyAttach();
        end

        -- Now that the child is attached to the render tree, dispatch
        -- the relevant mutation events.
        --dispatchChildInsertionEvents(child);
        prev = child;
    end

    --dispatchSubtreeModifiedEvent();
	if (self:Attached() and refresh) then
		self:PostLayoutRequestEvent();
	end
    return true;
end

--void ContainerNode::insertBeforeCommon(Node* nextChild, Node* newChild)
function PageElement:InsertBeforeCommon(nextChild, newChild)
	newChild.parent = self;
	if(nextChild) then
		local prev = nextChild:PreviousSibling();
		nextChild:SetPreviousSibling(newChild);
		if (prev) then
			prev:SetNextSibling(newChild);
		else
			self.m_firstChild = newChild;
		end
		
		newChild:SetPreviousSibling(prev);
		newChild:SetNextSibling(nextChild);
	else
        if (self.m_lastChild) then
            newChild:SetPreviousSibling(self.m_lastChild);
            self.m_lastChild:SetNextSibling(newChild);
        else
            self.m_firstChild = newChild;
		end

        self.m_lastChild = newChild;
	end
end

-- @param child: it can be mcmlNode or string node. 
-- @param refChild: the next node for the child.
-- @param refresh: if nil or true, attach node and relayout page.
function PageElement:InsertBefore(newChild, refChild, refresh)
	refresh = if_else(refresh == nil, true, refresh);

	if(not newChild) then
		return;
	end

	if (not refChild) then
        return self:AppendChild(newChild, refresh);
	end

	if (refChild:ParentNode() ~= self) then
        return false;
    end

	-- Now actually add the child(ren)
    if (refChild:PreviousSibling() == newChild or refChild == newChild) then -- nothing to do
        return true;
	end

	local targets = commonlib.vector:new();
	collectTargetNodes(newChild, targets)
	if(targets:empty()) then
		return
	end

	local next = refChild;
    local refChildPreviousSibling = refChild:PreviousSibling();
	for i = 1, #targets do
        local child = targets[i];

		-- If child is already present in the tree, first remove it from the old location.
		local oldParent = child:ParentNode();
        if (oldParent and oldParent.RemoveChild) then
            oldParent:RemoveChild(child, false);
		end

		if (next:ParentNode() ~= self) then
            break;
		end
        if (child:ParentNode()) then
            break;
		end

		--child->setTreeScopeRecursively(treeScope());

        self:InsertBeforeCommon(next, child);

--		// Send notification about the children change.
--        childrenChanged(false, refChildPreviousSibling.get(), next.get(), 1);
--        notifyChildInserted(child);

        -- Add child to the rendering tree.
        if (self:Attached() and not child:Attached() and child:ParentNode() == self and refresh) then
--            if (shouldLazyAttach)
--                child->lazyAttach();
--            else
--                child->attach();
			child:LoadComponentIfNeeded();
			child:LazyAttach();
        end

--		// Now that the child is attached to the render tree, dispatch
--        // the relevant mutation events.
--        dispatchChildInsertionEvents(child);
	end


	if(self:Attached() and refresh) then
		self:PostLayoutRequestEvent();
	end
	
	return true;
end

--void ContainerNode::removeBetween(Node* previousChild, Node* nextChild, Node* oldChild)
function PageElement:RemoveBetween(previousChild, nextChild, oldChild)
--    ASSERT(oldChild);
--    ASSERT(oldChild->parentNode() == this);

    --forbidEventDispatch();

    -- Remove from rendering tree
    if (oldChild:Attached()) then
        oldChild:detachLayoutTree();
	end

    if (nextChild) then
        nextChild:SetPreviousSibling(previousChild);
	end
    if (previousChild) then
        previousChild:SetNextSibling(nextChild);
	end
    if (self.m_firstChild == oldChild) then
        self.m_firstChild = nextChild;
	end
    if (self.m_lastChild == oldChild) then
        self.m_lastChild = previousChild;
	end

    oldChild:SetPreviousSibling();
    oldChild:SetNextSibling();
	oldChild.parent = nil;

    --oldChild->setTreeScopeRecursively(document());

    --allowEventDispatch();
end

function PageElement:RemoveChild(child, refresh)
	refresh = if_else(refresh == nil, true, refresh)
	if(child == nil) then
		return;
	end

	if (child:ParentNode() ~= self) then
		return;
	end

	local prev = child:PreviousSibling();
    local next = child:NextSibling();
    self:RemoveBetween(prev, next, child);

	--child:LazyAttach();
	if(refresh) then
		self:PostLayoutRequestEvent();
	end
end

-- @param child: it can be mcmlNode or string node. 
-- @param index: 1 based index, at which to insert the item. if nil, it will be inserted to the end
function PageElement:AddChild(child, index)
	if(type(child)=="table") then
		local nCount = #(self) or 0;
		child.index = commonlib.insertArrayItem(self, index, child)
		child.parent = self;
	elseif(type(child)=="string") then	
		local nCount = #(self) or 0;
		commonlib.insertArrayItem(self, index, child)
	end	
	--self:resetLayout();
end

function PageElement:ClearClassNames()
	self:SetClassNames(nil);
end

function PageElement:ParseClassNames(value)
	local classes = commonlib.split(value,"%s");
	if(self.class_name) then
		classes = classes or {};
		classes[#classes+1] = self.class_name;
	end
	if(classes) then
		local classNames = {};
		for i = 1,#classes do
			classNames[classes[i]] = true;
		end
		self:SetClassNames(classNames);
	end

--	if(not self.classNames) then
--		local classes = nil;
--		local classStr = self:GetAttributeWithCode("class",nil,true);
--		if(classStr) then
--			classes = commonlib.split(classStr,"%s");
--		end
--		if(self.class_name) then
--			classes = classes or {};
--			classes[#classes+1] = self.class_name;
--		end
--		if(classes) then
--			self.classNames = {};
--			for i = 1,#classes do
--				self.classNames[classes[i]] = true;
--			end
--		end
--	end
--	return self.classNames;
end

-- detach this node from its parent node. 
function PageElement:Detach()
	self:DetachControls();

	local parentNode = self.parent
	if(parentNode == nil) then
		return
	end
	local nSize = #(parentNode);
	local i, node;
	
	if(nSize == 1) then
		parentNode[1] = nil; 
		parentNode:ClearAllChildren();
		return;
	end
	
	local i = self.index;
	local node;
	if(i<nSize) then
		local k;
		for k=i+1, nSize do
			node = parentNode[k];
			parentNode[k-1] = node;
			if(node~=nil) then
				node.index = k-1;
				parentNode[k] = nil;
			end	
		end
	else
		parentNode[i] = nil;
	end	
end

-- check whether this baseNode has a parent with the given name. It will search recursively for all ancesters. 
-- @param name: the parent name to search for. If nil, it will return parent regardless of its name. 
-- @return: the parent object is returned. 
function PageElement:GetParent(name)
	if(name==nil) then
		return self.parent
	end
	local parent = self.parent;
	while (parent~=nil) do
		if(parent.name == name) then
			return parent;
		end
		parent = parent.parent;
	end
end

-- get the root node, it will find in ancestor nodes until one without parent is found
-- @return root node.
function PageElement:GetRoot()
	local parent = self;
	while (parent.parent~=nil) do
		parent = parent.parent;
	end
	return parent;
end

function PageElement:Document()
	return self:GetRoot();
end

-- Get the page control(PageCtrl) that loaded this mcml page. 
function PageElement:GetPageCtrl()
	return self:GetAttribute("page_ctrl") or self:GetParentAttribute("page_ctrl");
end	

-- get the page style object shared by all page elements.
function PageElement:GetPageStyle()
	local page = self:GetPageCtrl();
	if(page) then
		return page:GetStyle();
	end
end

-- search all parent with a given attribute name. It will search recursively for all ancesters.  
-- this function is usually used for getting the "request_url" field which is inserted by MCML web browser to the top level node. 
-- @param attrName: the parent field name to search for
-- @return: the nearest parent object field is returned. it may return, if no such parent is found. 
function PageElement:GetParentAttribute(attrName)
	local parent = self.parent;
	while (parent~=nil) do
		if(parent.GetAttribute and parent:GetAttribute(attrName)~=nil) then
			return parent:GetAttribute(attrName);
		end
		parent = parent.parent;
	end
end

-- get the url request of the mcml node if any. It will search for "request_url" attribtue field in the ancestor of this node. 
-- PageCtrl and BrowserWnd will automatically insert "request_url" attribtue field to the root MCML node before instantiate them. 
-- @return: nil or the request_url is returned. we can extract requery string parameters using regular expressions or using GetRequestParam
function PageElement:GetRequestURL()
	return self:GetParentAttribute("request_url") or self:GetAttribute("request_url");
end

-- get request url parameter by its name. for example if page url is "www.paraengine.com/user?id=10&time=20", then GetRequestParam("id") will be 10.
-- @return: nil or string value.
function PageElement:GetRequestParam(paramName)
	local request_url = self:GetRequestURL();
	return System.localserver.UrlHelper.url_getparams(request_url, paramName)
end

-- convert a url to absolute path using "request_url" if present
-- it will replace %NAME% with their values before processing next. 
-- @param url: it is any script, image or page url path which may be absolute, site root or relative path. 
--  relative to url path can not contain "/", anotherwise it is regarded as client side relative path. such as "Texture/whitedot.png"
-- @return: it always returns absolute path. however, if path cannot be resolved, the input is returned unchanged. 
function PageElement:GetAbsoluteURL(url)
	if(not url or url=="") then return url end
	
	if(string_find(url, "^([%w]*)://"))then
		-- already absolute path
	else	
		local request_url = self:GetRequestURL();
		if(request_url) then
			NPL.load("(gl)script/ide/System/localserver/security_model.lua");
			local secureOrigin = System.localserver.SecurityOrigin:new(request_url)
			
			if(string_find(url, "^/\\")) then
				-- relative to site root.
				if(secureOrigin.url) then
					url = secureOrigin.url..url;
				end	
			elseif(string_find(url, "[/\\]")) then
				-- if relative to url path contains "/", it is regarded as client side SDK root folder. such as "Texture/whitedot.png"
			elseif(string_find(url, "^#")) then	
				-- this is an anchor
				url = string_gsub(request_url,"^([^#]*)#.-$", "%1")..url
			else
				-- relative to request url path
				url = string_gsub(string_gsub(request_url, "%?.*$", ""), "^(.*)/[^/\\]-$", "%1/")..url
			end
		end	
	end
	return url;
end

-- get the user ID of the owner of the profile. 
function PageElement:GetOwnerUserID()
	local profile = self:GetParent("pe:profile") or self;
	if(profile) then
		return profile:GetAttribute("uid");
	end
end

-- Get child count
function PageElement:GetChildCount()
	return self:ChildNodeCount()
	--return #(self);
end

-- remove all child nodes and move them to an internal template node
function PageElement:MoveChildrenToTemplate()
	local templateNode;
	if(self.m_firstChild) then
		if(self.m_firstChild == self.m_lastChild) then
			templateNode = self.m_firstChild;
		else
			-- use anonymous parent element if multiple nodes in the template 
			templateNode = PageElement:new(); 
			for child in self:next() do
				templateNode:AppendChild(child);
			end
		end
	end

--	local templateNode;
--	if(#self == 1) then
--		templateNode = self[1];
--	else
--		-- use anonymous parent element if multiple nodes in the template 
--		templateNode = PageElement:new(); 
--		for child in self:next() do
--			templateNode:AddChild(child);
--		end
--	end
	self.templateNode = templateNode;
	self:ClearAllChildren();
end

-- this may return nil if self:MoveChildrenToTemplate is never called. 
function PageElement:GetTemplateNode()
	return self.templateNode;
end

-- generate a less compare function according to a node field name. 
-- @param fieldName: the name of the field, such as "text", "name", etc
function PageElement.GenerateLessCFByField(fieldName)
	fieldName = fieldName or "name";
	return function(node1, node2)
		if(node1[fieldName] == nil) then
			return true
		elseif(node2[fieldName] == nil) then
			return false
		else
			return node1[fieldName] < node2[fieldName];
		end	
	end
end

-- generate a greater compare function according to a node field name. 
-- @param fieldName: the name of the field, such as "text", "name", etc
--   One can also build a compare function by calling PageElement.GenerateLessCFByField(fieldName) or PageElement.GenerateGreaterCFByField(fieldName)
function PageElement.GenerateGreaterCFByField(fieldName)
	fieldName = fieldName or "name";
	return function(node1, node2)
		if(node2[fieldName] == nil) then
			return true
		elseif(node1[fieldName] == nil) then
			return false
		else
			return node1[fieldName] > node2[fieldName];
		end	
	end
end

-- sorting the children according to a compare function. Internally it uses table.sort().
-- Note: child indices are rebuilt and may cause UI binded controls to misbehave
-- compareFunc: if nil, it will compare by node.name. 
function PageElement:SortChildren(compareFunc)
	compareFunc = compareFunc or PageElement.GenerateLessCFByField("name");
	-- quick sort
	table.sort(self, compareFunc)
	-- rebuild index. 
	local i, node
	for i,node in ipairs(self) do
		node.index = i;
	end
end

-- get a string containing the node path. such as "1/1/1/3"
-- as long as the baseNode does not change, the node path uniquely identifies a baseNode.
function PageElement:GetNodePath()
	local path = tostring(self.index);
	while (self.parent ~=nil) do
		path = tostring(self.parent.index).."/"..path;
		self = self.parent;
	end
	return path;
end

-- @param rootName: a name that uniquely identifies a UI instance of this object, usually the userid or app_key. The function will generate a sub control name by concartinating this rootname with relative baseNode path. 
function PageElement:GetInstanceName(rootName)
	return tostring(rootName)..self:GetNodePath();
end

-- get the first occurance of first level child node whose name is name
-- @param name: if can be the name of the node, or it can be a interger index. 
function PageElement:GetChild(name)
	local index = 1;
	local node = self:FirstChild();
	while(node) do
		if(type(name) == "number" and name == index) then
			return node;
		elseif(type(node)=="table" and name == node.name) then
			return node;
		end
		index = index + 1;
		node = node:NextSibling();
	end

--	if(type(name) == "number") then
--		return self[name];
--	else
--		local nSize = #(self);
--		local node;
--		for i=1, nSize do
--			node = self[i];
--			if(type(node)=="table" and name == node.name) then
--				return node;
--			end
--		end
--	end	
end

-- get the first occurance of first level child node whose name is name
-- @param name: if can be the name of the node, or it can be a interger index. 
-- @return nil if not found
function PageElement:GetChildWithAttribute(name, value)
	for node in self:next() do
		if(type(node)=="table") then
			if(value == node:GetAttribute(name)) then
				return node;
			end	
		end
	end

--	local nSize = #(self);
--	local i, node;
--	for i=1, nSize do
--		node = self[i];
--		if(type(node)=="table") then
--			if(value == node:GetAttribute(name)) then
--				return node;
--			end	
--		end
--	end
end

-- get the first occurance of child node whose attribute name is value. it will search for all child nodes recursively. 
function PageElement:SearchChildByAttribute(name, value)
	for node in self:next() do
		if(type(node)=="table") then
			if(value == node:GetAttributeWithCode(name, nil, true) or (node.buttonName and node.buttonName == value)) then
				return node;
			else
				node = node:SearchChildByAttribute(name, value);
				if(node) then
					return node;
				end
			end
		end
	end

--	local nSize = #(self);
--	local i, node;
--	for i=1, nSize do
--		node = self[i];
--		if(type(node)=="table") then
--			if(value == node:GetAttribute(name)) then
--				return node;
--			else
--				node = node:SearchChildByAttribute(name, value);
--				if(node) then
--					return node;
--				end
--			end	
--		end
--	end
end

-- return an iterator of all first level child nodes whose name is name
-- a more advanced way to tranverse mcml tree is using ide/Xpath
-- @param name: if name is nil, all child is returned. 
function PageElement:next(name)
	local current_node = self:FirstChild();
	return function ()
		local node = current_node;
		while(node) do
			current_node = current_node:NextSibling();
			if(not name or (type(node) == "table" and name == node.name)) then
				return node;
			end
			node = current_node;
		end
	end

--	local nSize = #(self);
--	local i = 1;
--	return function ()
--		local node;
--		while i <= nSize do
--			node = self[i];
--			i = i+1;
--			if(not name or (type(node) == "table" and name == node.name)) then
--				return node;
--			end
--		end
--	end	
end


-- this is a jquery meta table, if one wants to add jquery-like function calls, just set this metatable as the class array table. 
-- e.g. setmetatable(some_table, jquery_metatable)
local jquery_metatable = {
	-- each invocation will create additional tables and closures, hence the performance is not supper good. 
	__index = function(t, k)
		if(type(k) == "string") then
			local func = {};
			setmetatable(func, {
				-- the first parameter is always the mcml_node. 
				-- the return value is always the last node's result
				__call = function(self, self1, ...)
					local output;
					local i, node
					for i, node in ipairs(t) do
						if(type(node[k]) == "function")then
							output = node[k](node, ...);
						end
					end
					return output;
				end,
			});
			return func;
		elseif(type(k) == "number") then
			return t[k];
		end
	end,
}

-- provide jquery-like syntax to find all nodes that match a given name pattern and then use the returned object to invoke a method on all returned nodes. 
-- it can also be used to create a new node like "<div />"
--  e.g. node:jquery("a"):show();
-- @param pattern: The valid format is [tag_name][#name_id][.class_name] or "<tag_name />". 
--  e.g. "div#name.class_name", "#some_name", ".some_class", "div"
--  e.g. "<div />" will create a new node. 
-- @param param1: additional xml node when pattern is "<tag_name />"
function PageElement:jquery(pattern, param1)
	local tagName = pattern and pattern:match("^<([^%s]*).*/>$") or pattern:match("^<([^%s]*)>.*</(%1)>$");
	--local tagName = pattern and pattern:match("^<([^%s/>]*)");
	if(tagName) then
		param1 = param1 or {name=tagName, attr={}};
		param1.name = param1.name or tagName;
		return mcml:createFromXmlNode(param1);
	else
		local output = {}
		if(pattern) then
			local tag_name, pattern = pattern:match("^([^#%.]*)(.*)");
			if(tag_name == "") then
				tag_name = nil;
			end
			local id;
			if(pattern) then
				id = pattern:match("#([^#%.]+)");
			end
			local class_name;
			if(pattern) then
				class_name = pattern:match("%.([^#%.]+)");
			end
			self:GetAllChildWithNameIDClass(tag_name, id, class_name, output);
		
		end
		setmetatable(output, jquery_metatable)
		return output;
	end
end

-- show this node. one may needs to refresh the page if page is already rendered
function PageElement:show()
	self:GetInlineStyleDecl():SetProperty("display", "");
end

-- hide this node. one may needs to refresh the page if page is already rendered
function PageElement:hide()
	self:GetInlineStyleDecl():SetProperty("display", "none");
end

-- get/set inner text
-- @param v: if not nil, it will set inner text instead of get
-- return the inner text or empty string. 
function PageElement:text(v)
	if(v == nil) then
		local inner_text = self[1];
		if(type(inner_text) == "string") then
			return inner_text;
		else
			return ""
		end
	else
		self:ClearAllChildren();
		self[1] = v;
	end
end

-- get/set ui or node value of the node. 
-- @param v: if not nil, it will set value instead of get
function PageElement:value(v)
	if(v == nil) then
		local value_ = self:GetUIValue();
		if(value_==nil) then
			return self:GetValue();
		else
			return value_;	
		end	
	else
		self:SetUIValue(v);
		self:SetValue(v);
	end
end

-- return a table containing all child nodes whose name is name. (it will search recursively)
-- a more advanced way to tranverse mcml tree is using ide/Xpath
-- @param name: the tag name. if nil it matches all
-- @param id: the name attribute. if nil it matches all
-- @param class: the class attribute. if nil it matches all
-- @param output: nil or a table to receive the result. child nodes with the name is saved to this table array. if nil, a new table will be created. 
-- @return output: the output table containing all children. It may be nil if no one is found and input "output" is also nil.
function PageElement:GetAllChildWithNameIDClass(name, id, class, output)
	for node in self:next() do
		if(type(node) == "table") then
			if( (not name or name == node.name) and
				(not id or id == node:GetAttribute("name")) and
				(not class or class==node:GetAttribute("class")) ) then
				output = output or {};
				table.insert(output, node);
			else
				output = node:GetAllChildWithNameIDClass(name, id, class, output)
			end	
		end
	end

--	local nSize = #(self);
--	local i = 1;
--	local node;
--	while i <= nSize do
--		node = self[i];
--		i = i+1;
--		if(type(node) == "table") then
--			if( (not name or name == node.name) and
--				(not id or id == node:GetAttribute("name")) and
--				(not class or class==node:GetAttribute("class")) ) then
--				output = output or {};
--				table.insert(output, node);
--			else
--				output = node:GetAllChildWithNameIDClass(name, id, class, output)
--			end	
--		end
--	end
	return output;
end

-- return a table containing all child nodes whose name is name. (it will search recursively)
-- a more advanced way to tranverse mcml tree is using ide/Xpath
-- @param name: the tag name
-- @param output: nil or a table to receive the result. child nodes with the name is saved to this table array. if nil, a new table will be created. 
-- @return output: the output table containing all children. It may be nil if no one is found and input "output" is also nil.
function PageElement:GetAllChildWithName(name, output)
	for node in self:next() do
		if(type(node) == "table") then
			if(name == node.name) then
				output = output or {};
				table.insert(output, node);
			else
				output = node:GetAllChildWithName(name, output)
			end	
		end
	end

--	local nSize = #(self);
--	local i = 1;
--	local node;
--	while i <= nSize do
--		node = self[i];
--		i = i+1;
--		if(type(node) == "table") then
--			if(name == node.name) then
--				output = output or {};
--				table.insert(output, node);
--			else
--				output = node:GetAllChildWithName(name, output)
--			end	
--		end
--	end
	return output;
end

-- return an iterator of all child nodes whose attribtue attrName is attrValue. (it will search recursively)
-- a more advanced way to tranverse mcml tree is using ide/Xpath
-- @param name: if name is nil, all child is returned. 
-- @param output: nil or a table to receive the result. child nodes with the name is saved to this table array. if nil, a new table will be created. 
-- @return output: the output table containing all children. It may be nil if no one is found and input "output" is also nil.
function PageElement:GetAllChildWithAttribute(attrName, attrValue, output)
	for node in self:next() do
		if(type(node) == "table") then
			if(node:GetAttribute(attrName) == attrValue) then
				output = output or {};
				table.insert(output, node);
			else
				output = node:GetAllChildWithAttribute(attrName, attrValue, output)
			end	
		end
	end

--	local nSize = #(self);
--	local i = 1;
--	local node;
--	while i <= nSize do
--		node = self[i];
--		i = i+1;
--		if(type(node) == "table") then
--			if(node:GetAttribute(attrName) == attrValue) then
--				output = output or {};
--				table.insert(output, node);
--			else
--				output = node:GetAllChildWithAttribute(attrName, attrValue, output)
--			end	
--		end
--	end
	return output;
end

-- get code value in NPL code script. 
-- @param name: can be any name with commmar 
function PageElement:GetScriptValue(name)
	local pageScope = self:GetPageCtrl():GetPageScope();
	return commonlib.getfield(name, pageScope);
end

-- this function will apply self.pre_values to current page scope during rendering.
-- making it accessible to XPath and Eval function.  
function PageElement:ApplyPreValues()
	if(type(self.pre_values) == "table") then
		local pageScope = self:GetPageCtrl():GetPageScope();
		if(pageScope) then
			for name, value in pairs(self.pre_values) do
				pageScope[name] = value;
			end
		end
	end
end

-- pop page script 
function PageElement:UnapplyPreValues()
	if(type(self.pre_values) == "table") then
		local pageScope = self:GetPageCtrl():GetPageScope();
		if(pageScope) then
			for name, value in pairs(self.pre_values) do
				pageScope[name] = nil;
			end
		end
	end
end

-- apply a given pre value to this node, so that when the node is rendered, the name, value pairs will be
-- written to the current page scope. Not all mcml node support pre values. it is most often used by databinding template node. 
function PageElement:SetPreValue(name, value)
	self.pre_values = self.pre_values or {};
	self.pre_values[name] = value;
end

-- get a prevalue by name. this function is usually called on data binded mcml node 
-- @param name: name of the pre value
-- @param bSearchParent: if true, it will search parent node recursively until name is found or root node is reached. 
function PageElement:GetPreValue(name, bSearchParent)
	if(self.pre_values) then
		return self.pre_values[name];
	elseif(bSearchParent) then
		local parent = self.parent;
		while (parent~=nil) do
			if(parent.pre_values) then
				return parent.pre_values[name];
			end
			parent = parent.parent;
		end
	end
end

-- here we will translate current node and all of its child nodes recursively, using the given langTable 
-- unless any of the child attribute disables or specifies a different lang using the trans attribute
-- @note: it will secretly mark an already translated node, so it will not be translated twice when the next time this method is called.
-- @param langTable: this is a translation table from CommonCtrl.Locale(transName); if this is nil, 
-- @param transName: the translation name of the langTable. 
function PageElement:TranslateMe(langTable, transName)
	local trans = self:GetAttribute("trans");
	if(trans) then
		if(trans == "no" or trans == "none") then 
			return
		elseif(trans ~= transName) then
			langTable = CommonCtrl.Locale(trans);
			transName = trans;
			if(not langTable) then
				LOG.warn("lang table %s is not found for the mcml page\n", trans);
			end
		end	
		-- secretly mark an already translated node, so it will not be translated twice when the next time this method is called.
		if(self.IsTranslated) then
			return
		else
			self.IsTranslated = true;
		end
	end	
	-- translate this and all child nodes recursively
	if(langTable) then
		-- translate attributes of current node. 
		if(self.attr) then
			local name, value 
			for name, value in pairs(self.attr) do
				-- we will skip some attributes. 
				if(name~="style" and name~="id" and name~="name") then
					if(type(value) == "string") then
						-- TRANSLATE: translate value
						if(langTable:HasTranslation(value)) then
							--commonlib.echo(langTable(value))
							self.attr[name] = langTable(value);
						end	
					end
				end	
			end
		end

		for node in self:next() do
			if(type(node) == "table") then
				node:TranslateMe(langTable, transName);
			end
		end
	
--		-- translate child nodes recursively. 	
--		local nSize = #(self);
--		local i = 1;
--		local node;
--		while i <= nSize do
--			node = self[i];
--			if(type(node) == "table") then
--				node:TranslateMe(langTable, transName)
--			elseif(type(node) == "string") then
--				-- only translate if the node is not unknown and not script node.
--				if(self.name ~= "script" and self.name ~= "unknown" and self.name ~= "pe:script") then
--					-- TRANSLATE: translate inner text
--					if(langTable:HasTranslation(node)) then
--						--commonlib.echo(langTable(node))
--						self[i] = langTable(node)
--					end
--				end	
--			end
--			i = i+1;
--		end
	end
end

-- if there an attribute called variables. 
-- variables are frequently used for localization in mcml. Both table based localization and commonlib.Locale based localization are supported. 
function PageElement:ProcessVariables()
	local variables_str = self:GetAttribute("variables");
	if(variables_str and not self.__variable_processed) then
		self.__variable_processed = true;

		--  a table containing all variables
		local variables = {};

		local var_name, var_value
		for var_name, var_value in string.gmatch(variables_str, "%$(%w*)=([^;%$]+)") do
			local func = commonlib.getfield(var_value) or commonlib.Locale:GetByName(var_value);
			variable = {
					var_name=var_name, 
					match_exp="%$"..var_name.."{([^}]*)}", 
					gsub_exp="%$"..var_name.."{[^}]*}", 
				};
			if(not func) then
				-- try to find a locale file with value under the given folder
				-- suppose var_value is "locale.mcml.IDE", then we will first try "locale/mcml/IDE.lua" and then try "locale/mcml/IDE_enUS.lua"
				local filename = var_value:gsub("%.", "/");
				local locale_file1 = format("%s.lua", filename);
				local locale_file2 = format("%s_%s.lua", filename, ParaEngine.GetLocale());
				if(ParaIO.DoesFileExist(locale_file1)) then
					filename = locale_file1;
				elseif(ParaIO.DoesFileExist(locale_file2)) then
					filename = locale_file2;
				else
					filename = nil;
				end
				if(filename) then
					NPL.load("(gl)"..filename);
					LOG.std(nil, "system", "mcml", "loaded variable file %s for %s", filename, var_value);
					func = commonlib.getfield(var_value) or commonlib.Locale:GetByName(var_value);
					if(not func) then
						func = commonlib.gettable(var_value);
						LOG.std(nil, "warn", "mcml", "empty table is created and used for variable %s. Ideally it should be %s or %s", var_value, locale_file1, locale_file2);
					end
				else
					LOG.std(nil, "warn", "mcml", "can not find variable table file for %s. It should be %s or %s", var_value, locale_file1, locale_file2);
				end
			end

			if(type(func) == "function") then
				variable.func = func
				variables[#variables+1] = variable;
			elseif(type(func) == "table") then
				local meta_table = getmetatable(func);
				if(meta_table and meta_table.__call) then
					variable.func = func
				else
					variable.func = function(name)
						return func[name];
					end
				end
				variables[#variables+1] = variable;
			else
				LOG.std(nil, "warn", "mcml", "unsupported $ %s params", var_name);
			end
		end

		if(#variables>0) then
			self:ReplaceVariables(variables);
		end
	end
end

function PageElement:ReplaceVariables(variables)
	if(variables) then
		-- translate this and all child nodes recursively
		-- translate attributes of current node. 
		if(self.attr) then
			local name, value 
			for name, value in pairs(self.attr) do
				-- we will skip some attributes. 
				if(type(value) == "string") then
					-- REPLACE
					local k;
					for k=1, #variables do
						local variable = variables[k];
						local var_value = value:match(variable.match_exp)
						if(var_value) then
							value = value:gsub(variable.gsub_exp, variable.func(var_value) or var_value);
							self.attr[name] = value;
						end
					end
				end
			end
		end

		for node in self:next() do
			if(type(node) == "table") then
				node:ReplaceVariables(variables);
			end
		end
	
--		-- translate child nodes recursively. 	
--		local nSize = #(self);
--		local i = 1;
--		local node;
--		while i <= nSize do
--			node = self[i];
--			if(type(node) == "table") then
--				node:ReplaceVariables(variables)
--			elseif(type(node) == "string") then
--				local value = node;
--				-- REPLACE
--				local k;
--				for k=1, #variables do
--					local variable = variables[k];
--					local var_value = value:match(variable.match_exp)
--					if(var_value) then
--						value = value:gsub(variable.gsub_exp, variable.func(var_value) or var_value); 
--						self[i] = value;
--					end
--				end
--			end
--			i = i+1;
--		end
	end
end

-- fire a given page event
-- @param handlerScript: the call back script function name or function itself.
--  the script function will be called with function(...) end
-- @param ... : event parameter
function PageElement:DoPageEvent(handlerScript, ...)
	local pageEnv, result;
	if(self) then
		-- get the page env table where the inline script function is defined, it may be nil if there is no page control or there is no inline script function. 
		local pageCtrl = self:GetPageCtrl();
		if(pageCtrl) then
			pageEnv = pageCtrl._PAGESCRIPT
		end
		
		Elements.pe_script.BeginCode(self);
	end
	if(type(handlerScript) == "string") then
		if(string.find(handlerScript, "http://")) then
			-- TODO: post values using http post. 
		else
			-- first search function in page script environment and then search in global environment. 
			local pFunc;
			if(pageEnv) then
				pFunc = commonlib.getfield(handlerScript, pageEnv);
			end
			if(type(pFunc) ~= "function") then
				pFunc = commonlib.getfield(handlerScript);
			end	
			if(type(pFunc) == "function") then
				result = pFunc(...);
			else
				log("warning: MCML page event call back "..handlerScript.." is not a valid function. \n")	
			end
		end	
	elseif(type(handlerScript) == "function") then
		--result = pFunc(...);
		result = handlerScript(...);
	end
	if(self) then
		Elements.pe_script.EndCode();
	end
	return result;
end

function PageElement:isHidden() 
	local parent = self;
	while (parent ~= nil) do
		if(parent:GetAttribute("display") == "none") then
			return true;
		end
		local css = parent:GetStyle();
		if(css and css["display"] == "none") then
			return true;
		end
		parent = parent.parent;
	end
	return false;
end

function PageElement:resetLayout()
	local page = self:GetPageCtrl();
	if(page and page.layout) then
		local window = page:GetWindow();
		if(window and window:testAttribute("WA_WState_Created")) then
			page.layout:invalidate();
		end
	end
end

function PageElement:IsClip()
	local parent = self;
	while(parent) do
		local control = self.control;
		if(control and control:IsClip()) then
			return true;
		end
		parent = parent.parent;
	end
end

-- clip region. 
function PageElement:ClipRegion()
	local parent = self;
	while(parent) do
		local control = parent.control;
		if(control and control:IsClip()) then
			local clip_rect = control:ClipRegion();
			if(clip_rect) then
				clip_rect:setX(control:x() + clip_rect:x() - self:x());
				clip_rect:setY(control:y() + clip_rect:y() - self:y());
				return clip_rect;
			end
		end
		parent = parent.parent;
	end
end

function PageElement:SetFocus()
	if(self.control) then
		self.control:setFocus("TabFocusReason");
	end
end

function PageElement:TabLostFocus()
	return true;
end

function PageElement:Focused()
	return self:GetPageCtrl():FocusNode() == self;
end

function PageElement:FocusInEvent()
	if(not self:Focused()) then
		self:GetPageCtrl():SetFocusNode(self);
	end
end

function PageElement:FocusOutEvent()
	if(self:Focused()) then
		self:GetPageCtrl():SetFocusNode();
	end
end

function PageElement:HaveChildren()
	if(self.m_firstChild) then
		return true;
	end
	return false;
end

function PageElement:NextTabNode(node)
	if(self:TabIndex() == 0 and not self:Focused()) then
		return self;
	end

	if(not self:HaveChildren() or (node ~= nil and node:NextSibling() == nil)) then
		if(self.parent) then
			return self.parent:NextTabNode(self);
		else
			return;
		end
	else
		if(node) then
			node = node:NextSibling();
		else
			node = self:FirstChild();
		end
		return node:NextTabNode();
	end
end

function PageElement:CreateInlineStyleDecl()
    self.inlineStyleDecl = CSSStyleDeclaration:new():init(self);
--	if(self.attr and self.attr.style) then
--		self.inlineStyleDecl:AddString(self.attr.style);
--	end
end

function PageElement:DestroyInlineStyleDecl()
	if(self.inlineStyleDecl) then
		self.inlineStyleDecl:SetNode(nil);
		self.inlineStyleDecl = nil;
	end
end

function PageElement:GetInlineStyleDecl()
    if (not self.inlineStyleDecl) then
        self:CreateInlineStyleDecl();
	end
    return self.inlineStyleDecl;
end

--CSSMutableStyleDeclaration* inlineStyleDecl() const { return m_inlineStyleDecl.get(); }
function PageElement:InlineStyleDecl() 
	return self.inlineStyleDecl;
end

--function PageElement:Style() 
--
--end

function PageElement:ParentNodeForRenderingAndStyle()
	--return LayoutTreeBuilder:init(self):ParentNodeForRenderingAndStyle();
	return self.parent;
end

function PageElement:TagName()
	--return self.class_name;
	local tagName = string.gsub(self.name,"pe:","");
	return tagName;
end

function PageElement:HasTagName(tag_name)
	local name = string.gsub(self.name,"pe:","");
	return name == tag_name;
	--return self.name == tag_name or self.class_name == tag_name or self.class_name == "pe:"..tag_name;
end

function PageElement:StyleChangeType()
	return self.m_nodeFlags.StyleChangeMask;
end

function PageElement:NeedsStyleRecalc()
	return self:StyleChangeType() ~= StyleChangeTypeEnum.NoStyleChange;
end

--function PageElement:SetNeedsStyleRecalc(changeType)
--	changeType = if_else(changeType == nil, StyleChangeTypeEnum.FullStyleChange, changeType);
--	self.m_nodeFlags.StyleChangeMask = changeType;
--end

function PageElement:ClearNeedsStyleRecalc()
	self.m_nodeFlags.StyleChangeMask = StyleChangeTypeEnum.NoStyleChange;
end

function PageElement:ChildNeedsStyleRecalc()
	return self.m_nodeFlags.ChildNeedsStyleRecalcFlag;
end

function PageElement:SetChildNeedsStyleRecalc()
	self.m_nodeFlags.ChildNeedsStyleRecalcFlag = true;
end

function PageElement:ClearChildNeedsStyleRecalc()
	self.m_nodeFlags.ChildNeedsStyleRecalcFlag = false;
end

function PageElement:IsElementNode()
	return self.m_nodeFlags.IsElementFlag;
end

function PageElement:SetElementNode(b)
	b = if_else(b == nil, true, b);
	self.m_nodeFlags.IsElementFlag = b;
end

function PageElement:PreviousSibling()
	return self.m_previous;
end

function PageElement:SetPreviousSibling(prev)
	self.m_previous = prev;
end

function PageElement:NextSibling()
	return self.m_next;
end

function PageElement:SetNextSibling(next)
	self.m_next = next;
end

function PageElement:FirstChild()
    return self.m_firstChild;
end

function PageElement:SetFirstChild(child)
    self.m_firstChild = child;
end

function PageElement:LastChild()
    return self.m_lastChild;
end

function PageElement:SetLastChild(child)
    self.m_lastChild = child;
end

function PageElement:IsTextNode()
	return false;
end

--Node::StyleChange Node::diff(const RenderStyle* s1, const RenderStyle* s2)
function PageElement:Diff(s1, s2)
	local ch = StyleChangeEnum.NoInherit;

	local display1 = DisplayEnum.NONE;
	if(s1) then
		display1 = s1:Display();
	end
	local display2 = DisplayEnum.NONE;
	if(s2) then
		display2 = s2:Display();
	end

	if (display1 ~= display2) then
		ch = StyleChangeEnum.Detach;
	elseif(s1 == nil or s2 == nil) then
		ch = StyleChangeEnum.Inherit;
	elseif(s1 == s2) then
		ch = StyleChangeEnum.NoChange;
	elseif (s1:InheritedNotEqual(s2)) then
        ch = StyleChangeEnum.Inherit;
	end

	return ch;
end

function PageElement:SetRenderStyle(style)
	if (self.layout_object) then
        self.layout_object:SetAnimatableStyle(style); 
	end
end

function PageElement:RecalcStyle(change)
	local hasParentStyle = false;
	if(self:ParentNodeForRenderingAndStyle() and self:ParentNodeForRenderingAndStyle():RenderStyle()) then
		hasParentStyle = true;
	end
	if(hasParentStyle and (change >= StyleChangeEnum.Inherit or self:NeedsStyleRecalc())) then
		local currentStyle = self:RenderStyle();
		local newStyle = self:StyleForLayoutObject();

		local ch = self:Diff(currentStyle, newStyle);

		if (ch == StyleChangeEnum.Detach or not currentStyle) then
            -- FIXME: The style gets computed twice by calling attach. We could do better if we passed the style along.
            self:reattachLayoutTree();
            -- attach recalculates the style for all children. No need to do it twice.
            self:ClearNeedsStyleRecalc();
            self:ClearChildNeedsStyleRecalc();

--            if (hasCustomWillOrDidRecalcStyle())
--                didRecalcStyle(change);
            return;
        end

		self:SetRenderStyle(newStyle);

		change = ch;
	end
	local node = self:FirstChild();
	while(node) do
--        if (!n->isElementNode())
--            continue;
		if (node:IsTextNode()) then
            --parentPusher.push();
            node:RecalcTextStyle(change);
            --continue;
		else
			local element = node;
			if (change >= StyleChangeEnum.Inherit or element:NeedsStyleRecalc() or element:ChildNeedsStyleRecalc()) then
				element:RecalcStyle(change);
			end	
        end

		node = node:NextSibling();
    end

	self:ClearNeedsStyleRecalc();
	self:ClearChildNeedsStyleRecalc();
end

function PageElement:Parent()
	return self.parent;
end

function PageElement:SetParent(p)
	self.parent = p;
end

function PageElement:ParentNode()
	return self:Parent();
end

function PageElement:ParentOrHostNode()
	return self:Parent();
end
-- @param mask: NodeFlags 
function PageElement:GetFlag(mask)
	return self.m_nodeFlags[mask];
end

function PageElement:SetFlag(mask, b)
	b = if_else(b == nil, true, b);
	self.m_nodeFlags[mask] = b;
end

function PageElement:ClearFlag(mask)
	self.m_nodeFlags[mask] = DefaultFlagValues[mask];
end

function PageElement:Attached()
	return self:GetFlag("IsAttachedFlag");
end

function PageElement:SetAttached()
	self:SetFlag("IsAttachedFlag")
end

function PageElement:IsParsingChildrenFinished() 
	return self:GetFlag("IsParsingChildrenFinishedFlag");
end

function PageElement:SetIsParsingChildrenFinished(f) 
	self:SetFlag("IsParsingChildrenFinishedFlag", f);
end

function PageElement:ClearIsParsingChildrenFinished() 
	self:ClearFlag("IsParsingChildrenFinishedFlag");
end

function PageElement:IsStyleAttributeValid() 
	return self:GetFlag("IsStyleAttributeValidFlag");
end

function PageElement:SetIsStyleAttributeValid(f) 
	self:SetFlag("IsStyleAttributeValidFlag", f);
end

function PageElement:ClearIsStyleAttributeValid() 
	self:ClearFlag("IsStyleAttributeValidFlag");
end

function PageElement:SetInDocument()
	self:SetFlag("InDocumentFlag");
end

function PageElement:ClearInDocument()
	self:ClearFlag("InDocumentFlag");
end

function PageElement:HasID() 
	return self:GetFlag("HasIDFlag");
end

function PageElement:SetHasID(f) 
	self:SetFlag("HasIDFlag", f);
end

function PageElement:HasClass() 
	return self:GetFlag("HasClassFlag");
end

function PageElement:SetHasClass(f) 
	self:SetFlag("HasClassFlag", f);
end

function PageElement:Active()
	return self:GetFlag("IsActiveFlag");
end

function PageElement:Hovered()
	return self:GetFlag("IsHoveredFlag");
end

function PageElement:Focused()
	return self:GetFlag("IsFocusedFlag");
end

function PageElement:SetActive(f)
	f = if_else(f == nil, true, f)
	self:SetFlag("IsActiveFlag", f);
end

function PageElement:SetHovered(f)
	f = if_else(f == nil, true, f)
	self:SetFlag("IsHoveredFlag", f);
end

function PageElement:SetFocused(f)
	f = if_else(f == nil, true, f)
	self:SetFlag("IsFocusedFlag", f);
end


function PageElement:InDetach() 
	return self:GetFlag("InDetachFlag");
end

function PageElement:PostLayoutRequestEvent()
	if(self:Document() and self:Document():View()) then
		self:Document():View():PostLayoutRequestEvent();
	end
end

function PageElement:SetNeedsStyleRecalc(changeType)
	changeType = if_else(changeType == nil, StyleChangeTypeEnum.FullStyleChange, changeType);
	if (not self:Attached()) then -- changed compared to what?
        return;
	end

	self:PostLayoutRequestEvent();

--	if(changeType == StyleChangeTypeEnum.InlineStyleChange) then
--		self.inlineStyleDecl = nil;
--	end

    --StyleChangeType existingChangeType = styleChangeType();
	local existingChangeType = self:StyleChangeType();
    if (changeType > existingChangeType) then
        self:SetStyleChange(changeType);
	end
	if (existingChangeType == StyleChangeTypeEnum.NoStyleChange) then
		self:MarkAncestorsWithChildNeedsStyleRecalc();
	end
end

-- inline void Node::setStyleChange(StyleChangeType changeType)
function PageElement:SetStyleChange(changeType)
    self.m_nodeFlags["StyleChangeMask"] = changeType;
end


function PageElement:MarkAncestorsWithChildNeedsStyleRecalc()
	local parent = self:ParentOrHostNode();
	while(parent and not parent:ChildNeedsStyleRecalc()) do
		parent:SetChildNeedsStyleRecalc();
		parent = parent:ParentOrHostNode();
	end
end

function PageElement:PrintNodeInfo() 
	echo(self.name);
	if(self.attr and self.attr.name) then
		echo(self.attr.name)
	end
end

--enum ShouldSetAttached {
--    SetAttached,
--    DoNotSetAttached
--};
--void Node::lazyAttach(ShouldSetAttached shouldSetAttached)
function PageElement:LazyAttach(shouldSetAttached)
	ShouldSetAttached = if_else(ShouldSetAttached == nil, "SetAttached", ShouldSetAttached);
	local n = self;
	while(n) do
		if (n:FirstChild()) then
            n:SetChildNeedsStyleRecalc();
		end
        n:SetStyleChange(StyleChangeTypeEnum.FullStyleChange);
        if (shouldSetAttached == "SetAttached") then
            n:SetAttached();
		end
		n = n:TraverseNextNode(self);
	end
    self:MarkAncestorsWithChildNeedsStyleRecalc();
end

--Node* Node::traverseNextNode(const Node* stayWithin) const
function PageElement:TraverseNextNode(stayWithin)
    if (self:FirstChild()) then
        return self:FirstChild();
	end
    if (self == stayWithin) then
        return nil;
	end
    if (self:NextSibling()) then
        return self:NextSibling();
	end
    --const Node *n = this;
	local n = self;
    while (n and n:NextSibling() == nil and (stayWithin == nil or n:ParentNode() ~= stayWithin)) do
        n = n:ParentNode();
	end
    if (n) then
        return n:NextSibling();
	end
    return nil;
end

--unsigned ContainerNode::childNodeCount() const
function PageElement:ChildNodeCount()
    local count = 0;
    local node = self:FirstChild();
	while(node) do
		count = count + 1;
		node = node:NextSibling();
	end
    return count;
end

-- this differs from other remove functions because it forcibly removes all the children,
-- regardless of read-only status or event exceptions, e.g.
--void ContainerNode::removeChildren()
function PageElement:RemoveChildren()
    if (not self.m_firstChild) then
        return;
	end

    -- The container node can be removed from event handlers.
    -- RefPtr<ContainerNode> protect(this);

    -- Do any prep work needed before actually starting to detach
    -- and remove... e.g. stop loading frames, fire unload events.
    -- willRemoveChildren(protect.get());

    -- exclude this node when looking for removed focusedNode since only children will be removed
    -- document()->removeFocusedNodeOfSubtree(this, true);


    -- forbidEventDispatch();
    --Vector<RefPtr<Node>, 10> removedChildren;
    --removedChildren.reserveInitialCapacity(childNodeCount());
	local removedChildren = {};
	local n = self.m_firstChild;
    while (n) do
		
        local next = n:NextSibling();

        -- Remove the node from the tree before calling detach or removedFromDocument (4427024, 4129744).
        -- removeChild() does this after calling detach(). There is no explanation for
        -- this discrepancy between removeChild() and its optimized version removeChildren().
        n:SetPreviousSibling(nil);
        n:SetNextSibling(nil);
        n:SetParent(nil);
        --n->setTreeScopeRecursively(document());

        self.m_firstChild = next;
        if (n == self.m_lastChild) then
            self.m_lastChild = nil;
		end
        --removedChildren.append(n.release());
		removedChildren[#removedChildren + 1] = n

		n = self.m_firstChild;
    end
    local removedChildrenCount = #removedChildren;

    -- Detach the nodes only after properly removed from the tree because
    -- a. detaching requires a proper DOM tree (for counters and quotes for
    -- example) and during the previous loop the next sibling still points to
    -- the node being removed while the node being removed does not point back
    -- and does not point to the same parent as its next sibling.
    -- b. destroying Renderers of standalone nodes is sometimes faster.
    for i = 1, removedChildrenCount do
        local removedChild = removedChildren[i];
        if (removedChild:Attached()) then
            removedChild:detachLayoutTree();
		end
    end

    --allowEventDispatch();

    -- Dispatch a single post-removal mutation event denoting a modified subtree.
    -- childrenChanged(false, 0, 0, -static_cast<int>(removedChildrenCount));
    -- dispatchSubtreeModifiedEvent();

--    for (i = 0; i < removedChildrenCount; ++i) {
--        Node* removedChild = removedChildren[i].get();
--        if (removedChild->inDocument())
--            removedChild->removedFromDocument();
--        -- removeChild() calls removedFromTree(true) if the child was not in the
--        -- document. There is no explanation for this discrepancy between removeChild()
--        -- and its optimized version removeChildren().
--    }
	self:PostLayoutRequestEvent();
end

PageElement.ClearAllChildren = PageElement.RemoveChildren;

--bool inDocument() const 
function PageElement:InDocument()
    --ASSERT(m_document || !getFlag(InDocumentFlag));
    return self:GetFlag("InDocumentFlag");
end

--void Node::insertedIntoDocument()
function PageElement:InsertedIntoDocument()
    self:SetInDocument();
end

--void Node::removedFromDocument()
function PageElement:RemovedFromDocument()
    self:ClearInDocument();
end

--inline bool Node::isDocumentNode() const
function PageElement:IsDocumentNode()
    return self == self.m_document;
end

--inline Element* firstElementChild(const ContainerNode* container)
function PageElement:FirstElementChild(container)
    --ASSERT_ARG(container, container);
    local child = container:FirstChild();
	return child;
--    while (child and not child->isElementNode())
--        child = child->nextSibling();
--    return static_cast<Element*>(child);
end

function PageElement:IsFrameOwnerElement() 
	return false; 
end