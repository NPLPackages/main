--[[
Title: gridview
Author(s): LiPeng
Date: 2017/10/3
Desc: it handles HTML tags of <gridview> . 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_gridview.lua");
System.Windows.mcml.Elements.pe_gridview:RegisterAs("pe:gridview");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/GridView.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_treeview.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_bindingblock.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_container.lua");
local mcml = commonlib.gettable("System.Windows.mcml");
local PageElement = commonlib.gettable("System.Windows.mcml.PageElement");
local GridView = commonlib.gettable("System.Windows.Controls.GridView");
local pe_gridview = commonlib.inherit(commonlib.gettable("System.Windows.mcml.Elements.pe_container"), commonlib.gettable("System.Windows.mcml.Elements.pe_gridview"));
pe_gridview:Property({"class_name", "pe:gridview"});

function pe_gridview:ctor()
	self.treeview = nil;
	self.topPager = nil;
	self.bottomPager= nil;
end

function pe_gridview:LoadComponent(parentElem, parentLayout, styleItem)
	local _this = self.control;
	if(not _this) then
		_this = GridView:new():init(parentElem);
		self:SetControl(_this);
	end
	PageElement.LoadComponent(self, _this, parentLayout, styleItem)
end

function pe_gridview:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	css:Merge(mcml:GetStyleItem(self.class_name));

	local _this = self.control;

	self.ItemOpenBG = self:GetString("ItemOpenBG") or css.ItemOpenBG;
	self.ItemCloseBG = self:GetString("ItemCloseBG") or css.ItemCloseBG;
	self.ItemToggleSize = self:GetNumber("ItemToggleSize") or css.ItemToggleSize;
	self.DefaultNodeHeight = self:GetNumber("DefaultNodeHeight") or css.DefaultNodeHeight or 20;
	self.ItemToggleRightSpacing = self:GetNumber("ItemToggleRightSpacing") or css.ItemToggleRightSpacing;
	self.DefaultIndentation = self:GetNumber("DefaultIndentation") or css.DefaultIndentation;
	self.AllowPaging = self:GetAttributeWithCode("AllowPaging", nil, true);
	self.pagesize = tonumber(self:GetAttributeWithCode("pagesize", nil, true));
	if(type(self.AllowPaging) == "string") then
		self.AllowPaging = string.lower(self.AllowPaging);
	end
	if(self.AllowPaging == "true") then
		self.AllowPaging = true;
	elseif(self.AllowPaging == "false") then
		self.AllowPaging = false;
	end
	self.fitHeight = self:CountHeight();
	

	--container_bg = css.background or self:GetString("background"), -- change to css background first
	_this:SetDefaultNodeHeight(self.DefaultNodeHeight or 24);
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


	self:CreateTreeViewNode();
	


	--self.onclick = self:GetAttributeWithCode("OnClick", nil, true);

	

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

	self:CreatePagerNode();
end

function pe_gridview:OnLoadComponentAfterChild(parentElem, parentLayout, css)
	if(self.AllowPaging and self.treeview) then
		self.treeview:AllowWheel(false);
	end
	self:UpdatePageText();
	pe_gridview._super.OnLoadComponentAfterChild(self, parentElem, parentLayout, css)
end

function pe_gridview:CountHeight()
	local height = nil;
	local pagesize = tonumber(self:GetAttributeWithCode("pagesize", nil, true));
	if(pagesize) then
		local nodeHeight = self.DefaultNodeHeight;
		local cellPadding = self:GetAttribute("CellPadding");
		if(cellPadding) then
			cellPadding = tonumber(string.match(cellPadding, "%d+"));
			if(cellPadding) then
				--nodeHeight = nodeHeight + cellPadding * 2;
				nodeHeight = nodeHeight + cellPadding;
			end
		end	
		height = pagesize * nodeHeight;
	end
	return height;
end

function pe_gridview:CreatePagerNode()
	if(self.AllowPaging) then
		if(not self:GetChild("pe:pager")) then
			-- create the top and/or bottom pager panel for page navigation. 
			-- Usually a pager contains current page index, total items, next and prev page button. 
			local PagerSettings = {
				height = 26,
				-- can be either "Top", "Bottom", or "TopAndBottom"
				Position = "TopAndBottom",
				--Position = "Bottom",
			};
			local node = self:GetChild("PagerSettings");
			if(node) then
				PagerSettings.Position = node:GetAttribute("Position") or PagerSettings.Position;
				PagerSettings.height = node:GetAttribute("height") or PagerSettings.height;
				PagerSettings.NextPageText = node:GetAttribute("NextPageText");
				PagerSettings.PreviousPageText = node:GetAttribute("PreviousPageText")
				PagerSettings.style = node:GetAttribute("style")
			end


			
			-- create at top and/or bottom
			local i
			for i=1, 2 do 
				local position;
				if(i == 1) then
					position= "Top";
				else
					position= "Bottom";
				end
--				local pagerTop;
--				if( i == 1) then
--					if(string.find(PagerSettings.Position, "Top")) then
--						pagerTop = top
--						top = top + PagerSettings.height
--					end
--				else	
--					if(string.find(PagerSettings.Position, "Bottom")) then
--						height = height - PagerSettings.height
--						pagerTop = height
--					end
--				end
				if(string.find(PagerSettings.Position, position)) then
					local pagerTempate = self:GetChild("PagerTemplate")
					local node;
					if(pagerTempate) then
						local o = commonlib.copy(pagerTempate);
						o.name = "pe:pager";
						node = mcml:createFromXmlNode(o);
--						node = Map3DSystem.mcml.new(nil, pagerTempate:clone());
--						node.name = "pe:pager"
					else
						--node = Map3DSystem.mcml.new(nil, {name="pe:pager"});
						node = mcml:createFromXmlNode({name="pe:pager"});
						if(PagerSettings.PreviousPageText or PagerSettings.NextPageText) then
							node:SetAttribute("PreviousPageText", PagerSettings.PreviousPageText);	
							node:SetAttribute("NextPageText", PagerSettings.NextPageText);	
						end	
					end	
					node:SetAttribute("height", PagerSettings.height);
					node:SetAttribute("target", self:GetString("name", ""));

					local index = nil;
					if(i==1) then
						node:SetAttribute("position", "Top");
						self.topPager = node;
						if(self.treeview) then
							index = self.treeview.index;
						end
					else
						node:SetAttribute("position", "Bottom");
						self.bottomPager = node;
					end	
					if(PagerSettings.style) then
						node:SetAttribute("style", PagerSettings.style);
					end
					self:AddChild(node, index);
				end
			end	
--		else
--			-- if already created or specified, just use it to create. The position attribute of pe:pager defines where the pager will be located. 
--			local pager;
--			for pager in self:next("pe:pager") do
--				local pagerTop;
--				local pagerHeight = pager:GetNumber("height") or 26;
--				if( pager:GetAttribute("position") == "Top") then
--					pagerTop = top
--					top = top + pagerHeight
--				elseif( pager:GetAttribute("position") == "Bottom") then
--					height = height - pagerHeight
--					pagerTop = height
--				end
--				if(pagerTop) then
--					local myLayout = Map3DSystem.mcml_controls.layout:new();
--					myLayout:reset(left, pagerTop, width, pagerTop + pagerHeight);
--					Map3DSystem.mcml_controls.create(rootName, pager, bindingContext, _parent, left, pagerTop, width, height, nil, myLayout);
--				end
--			end
		end	
	end
end

function pe_gridview:CreateTreeViewNode()
	local TreeViewNode = self:GetChild("pe:treeview");
	if( not TreeViewNode ) then
		local cellPadding = self:GetAttribute("CellPadding");
		if(cellPadding) then
			cellPadding = string.match(cellPadding, "%d+");
		end	
		local attr={};
		if(self.fitHeight) then
			attr.style = format("max-height:%dpx;",self.fitHeight);
		end
		if(cellPadding) then
			attr.style = format("%smargin:%spx;",attr.style,cellPadding);
			--TreeViewNode:SetAttribute("style", format("margin:%spx", cellPadding))
		end
		if(self.AllowPaging) then
			attr.style = format("%s%s;",attr.style,"overflow-y:hidden;");
		end
		TreeViewNode = mcml.Elements.pe_treeview:new({name="pe:treeview",attr=attr});
		local defaultnodeheight = self:GetAttribute("DefaultNodeHeight")
		if(defaultnodeheight) then
			TreeViewNode:SetAttribute("DefaultNodeHeight", defaultnodeheight + (cellPadding or 0))
		end
		local verticalscrollbarstep = self:GetAttribute("VerticalScrollBarStep")
		if(verticalscrollbarstep) then
			TreeViewNode:SetAttribute("VerticalScrollBarStep", verticalscrollbarstep);
		end
		
		local verticalscrollbaroffsetX = self:GetNumber("VerticalScrollBarOffsetX")
		if(verticalscrollbaroffsetX) then
			TreeViewNode:SetAttribute("VerticalScrollBarOffsetX", verticalscrollbaroffsetX);
		end

		TreeViewNode:SetAttribute("background", self:GetAttribute("background"))
		TreeViewNode:SetAttribute("ShowIcon", false);
		TreeViewNode:SetAttribute("DefaultIndentation", 0);
		
		if(self:GetBool("RememberScrollPos")) then
			TreeViewNode:SetAttribute("RememberScrollPos", true);
		end	
		if(self:GetBool("ClickThrough")) then
			TreeViewNode:SetAttribute("ClickThrough", true);
		end	
		
		

		local VerticalScrollBarWidth = self:GetNumber("VerticalScrollBarWidth")
		if(VerticalScrollBarWidth) then
			TreeViewNode:SetAttribute("VerticalScrollBarWidth", VerticalScrollBarWidth);
		end

		local ScrollBarTrackWidth = self:GetNumber("ScrollBarTrackWidth")
		if(ScrollBarTrackWidth) then
			TreeViewNode:SetAttribute("ScrollBarTrackWidth", ScrollBarTrackWidth);
		end

		self:AddChild(TreeViewNode);

		self.treeview = TreeViewNode;
	end
end

function pe_gridview:resetDataSource(dataSource)
	self:SetAttribute("pageindex", 1);
	self:SetDataSource(dataSource);
	if(self.treeview) then
		self.treeview:Rebuild();
	end
	if(self.treeview) then
		self:UpdatePageText();
	end
end

function pe_gridview:SetDataSource(dataSource)
	local pageCtrl = self:GetPageCtrl();
	if(not pageCtrl) then return end
	if(type(dataSource) == "string") then
		-- this is data source ID, we will convert it to a function that dynamically retrieve item from the data source control. 
		self.datasource = pageCtrl:GetNode(dataSource);
	else
		self.datasource = dataSource;
	end

	-- reset page count when data source changes. 
	self.pagecount = nil;
	
	-- update page count
	local pagesize = tonumber(self:GetAttributeWithCode("pagesize", nil, true));
	if(pagesize) then
		if(type(self.datasource) == "table") then
			self.pagecount = math.ceil((#(self.datasource))/pagesize);
		elseif(type(self.datasource) == "function") then
			self.pagecount = math.ceil((self.datasource() or 0)/pagesize);
		end
	end	
	local OnDataBound = self:GetAttribute("DataBound");
	if(OnDataBound) then
		-- call data bound event
		--self:DoPageEvent(onclick, buttonName, self)
		self:DoPageEvent(OnDataBound, self.GetAttribute("name"), dataSource, self)
	end
	
	-- we will ensure page index  is smaller than page count 
	
	local pageindex = self:GetAttribute("pageindex");
	if(pageindex) then
		if(self.pagecount==nil or pagesize==nil or (pageindex) > self.pagecount) then
			self:SetAttribute("pageindex", nil);
		end	
	end

	self:DataBind();
end

-- Public method: rebind (refresh) the data.
-- each bind data row node contains page variable "index" and any other data column values for that row. 
-- the template node can then evaluate for the values of the node to dynamic generate content specific to that row. 
-- such as <%=Eval("xpath")%> will return the xpath of the node
-- @param bRefreshUI: true to refresh UI. otherwise node is updated but UI is not. 
function pe_gridview:DataBind(pageInstName)
	local TreeViewNode = self.treeview;
	if(not TreeViewNode) then
		log("warning: inner tree view node not found in pe:gridview \n");
		return 
	end
	
	-- iterate and create node. 
	local cellPadding = self:GetAttribute("CellPadding");
	if(cellPadding) then
		cellPadding = string.match(cellPadding, "%d+");
	end	
	local pagesize = tonumber(self:GetAttributeWithCode("pagesize", nil, true));
	--local AllowPaging = self:GetBool("AllowPaging");
	local ItemsPerLine = self:GetNumber("ItemsPerLine") or 1;

	local ScrollToEnd = self:GetBool("ScrollToEnd");
	
	local columnsNode = self:GetChild("Columns");
	if(columnsNode) then
		TreeViewNode:ClearAllChildren();
		
		-- test if it is empty data
		local nDataCount = true;
		local dataSourceType;
		if(type(self.datasource) == "table") then
			nDataCount = #(self.datasource)
			dataSourceType = 0;
		elseif(type(self.datasource) == "function")	then
			nDataCount = self.datasource()
			dataSourceType = 1;
		end

		if(type(nDataCount) == "number" and pagesize) then
			self.pagecount = math.ceil(nDataCount/pagesize);
		end
		
		if(nDataCount==nil or nDataCount==0) then
			-- if empty data, show empty templates if any. 
			local EmptyTemplateNode;
			if(nDataCount == nil) then
				EmptyTemplateNode = self:GetChild("FetchingDataTemplate") or self:GetChild("EmptyDataTemplate");
			else
				EmptyTemplateNode = self:GetChild("EmptyDataTemplate");
			end
			if(EmptyTemplateNode) then
				local rowNode = EmptyTemplateNode:clone();
				rowNode.name = "div";
				if(cellPadding) then
					--rowNode:SetAttribute("style", format("padding-right:%spx;padding-bottom:%spx", cellPadding, cellPadding))
					rowNode:SetAttribute("style", format("padding-right:%spx;padding-bottom:%spx", cellPadding, cellPadding))
					--rowNode:SetAttribute("style", format("padding:%spx", cellPadding))
				end
				TreeViewNode:AddChild(rowNode, nil);
			end
		else
			-- show data of current page. 
			--local nFromIndex, nToIndex = 1, nil;
			if(self.AllowPaging and pagesize) then
				local pageindex = self:GetAttribute("pageindex") or 1;
				if(pageindex > (self.pagecount or 1)) then
					pageindex = self.pagecount or 1;
				end
				self:SetAttribute("pageindex", pageindex);
				--self.pageindex = self.pageindex or 1;
				--nFromIndex = (pageindex-1)*pagesize + 1;
				--nToIndex = nFromIndex + pagesize - 1;
			else
				--nToIndex = pagesize;
			end
			self.eval_names_ = self.eval_names_ or {};
			local i = 1;
			local LineNode;
			while (i <= nDataCount) do
				local row;
				if(dataSourceType == 0) then
					row = self.datasource[i];
				elseif(dataSourceType == 1) then
					row = self.datasource(i);
				end
				if(type(row) == "table") then
					local o = commonlib.copy(columnsNode);
					o.name = "pe:bindingblock";
					local rowNode = mcml:createFromXmlNode(o);

					if(cellPadding) then
						--rowNode:SetAttribute("style", format("margin-right:%spx;margin-bottom:%spx;", cellPadding, cellPadding), false);
						rowNode:SetAttribute("style", format("padding-right:%spx;padding-bottom:%spx;", cellPadding, cellPadding), false);
						--rowNode:SetAttribute("style", format("padding:%spx;", cellPadding), false);
					end
					if(ItemsPerLine == 1) then
						TreeViewNode:AddChild(rowNode, nil);
					else
						rowNode:SetAttribute("style", format("float:float;%s", rowNode:GetAttribute("style") or ""));
						
						local nSubIndex	= i % ItemsPerLine;
						if(nSubIndex == 1) then
							LineNode = mcml:createFromXmlNode({name="div"})
							--LineNode = Map3DSystem.mcml.new(nil,{name="div"});
							local lineAlign = self:GetAttribute("LineAlign");
							if(lineAlign and lineAlign == "center") then
								local LineWidth = self:GetNumber("LineWidth");
								if(LineWidth) then
									if((nDataCount-i) < ItemsPerLine) then
										local nLastRowCount = nDataCount % ItemsPerLine;
										if(nLastRowCount == 0) then
											nLastRowCount = ItemsPerLine;
										end
										local max_width = math.floor((nLastRowCount / ItemsPerLine) * LineWidth);
										LineNode:SetAttribute("style", format("max-width:%dpx", max_width));
									else
										LineNode:SetAttribute("style", format("max-width:%dpx", LineWidth));
									end
									LineNode:SetAttribute("align", "center");
								end	
							end
							TreeViewNode:AddChild(LineNode);
						end
						if(LineNode) then
							LineNode:AddChild(rowNode, nil);
						end
					end	
					
					-- set row index and all other column data in the row 
					-- so that in rowNode it can reference them via page scope Eval(), such as <%=Eval("index")%>
					local envCode = format("index=%d", i);
					local n, v;
					for n,v in pairs(self.eval_names_) do
						self.eval_names_[n] = false;
					end
					for n,v in pairs(row) do
						self.eval_names_[n] = true;
						local typeV = type(v)
						if(typeV == "number") then
							envCode = format("%s\n%s=%s", envCode, n, tostring(v));
						elseif(typeV == "string") then
							envCode = format("%s\n%s=\"%s\"", envCode, n, v);
						elseif(typeV == "boolean" or typeV == "nil") then
							envCode = format("%s\n%s=%s", envCode, n, tostring(v));
						elseif(typeV == "table") then
							envCode = format("%s\n%s=%s", envCode, n, commonlib.serialize_compact(v));
						end
					end
					for n,v in pairs(self.eval_names_) do
						if(not v) then
							envCode = format("%s\n%s=nil", envCode, n);
						end
					end
					rowNode:SetPreValue("this", row);
					-- set prescript attribute of pe:bindingblock
					rowNode:SetAttribute("prescript", envCode);
					i = i + 1;
				else
					break;	
				end
			end
		end
	else
		log("warning: pe_gridview.DataBind failed because Columns node is not defined\n");
	end
end

-- Public method: update pager text
function pe_gridview:UpdatePageText()
	if(self.AllowPaging) then
		for pagerNode in self:next("pe:pager") do
			local pageindex = self:GetAttribute("pageindex");
			pagerNode:UpdatePager(pageInstName, pageindex or 0, self.pagecount);
		end
	end	
end

-- Public method: for pe:pager
function pe_gridview:GetCurrentPage(pageInstName)
	return self:GetAttribute("pageindex") or 1;
	--return self.pageindex or 1;
end

---- Public method: for pe:pager
function pe_gridview:GotoPage(pageInstName, nPageIndex)
	local pagecount = self:GetTotalPage(pageInstName)
	if(nPageIndex and nPageIndex>=1 and nPageIndex<=pagecount) then
		local OnPageIndexChanging = self:GetAttribute("OnPageIndexChanging");
		local DisableIndexChange;
		if(OnPageIndexChanging) then
			-- call page index changing event
			DisableIndexChange = self:DoPageEvent(OnPageIndexChanging, self.GetAttribute("name"), nPageIndex)
		end
		if(not DisableIndexChange) then
			self:SetAttribute("pageindex", nPageIndex);
			--self.pageindex = nPageIndex;
			--self:DataBind(pageInstName)
			self:ScrollToPage(pageInstName, nPageIndex);
			
			local OnPageIndexChanged = self:GetAttribute("OnPageIndexChanged");
			if(OnPageIndexChanged) then
				-- call page index changed event
				self:DoPageEvent(OnPageIndexChanged, self.GetAttribute("name"), nPageIndex)
			end
		end	
	end
end

function pe_gridview:ScrollToPage(pageInstName, nPageIndex)
	if(self.AllowPaging and self.pagesize and nPageIndex) then
		local child_index = self.pagesize * (nPageIndex - 1) + 1;
		self.treeview:scrollToChild(child_index);

		for pagerNode in self:next("pe:pager") do
			pagerNode:UpdatePager(pageInstName, nPageIndex, self.pagecount);
		end
	end
end

-- Public method: for pe:pager
function pe_gridview:GetTotalPage(pageInstName)
	return self.pagecount or 1;
end

function pe_gridview:OnAfterChildLayout(layout, left, top, right, bottom)
	pe_gridview._super.OnAfterChildLayout(self, layout, left, top, right, bottom);
	if(self.AllowPaging and self.treeview) then
		local nodeHeight = self.DefaultNodeHeight;
		local cellPadding = self:GetAttribute("CellPadding");
		if(cellPadding) then
			cellPadding = tonumber(string.match(cellPadding, "%d+"));
			if(cellPadding) then
				--nodeHeight = nodeHeight + cellPadding * 2;
				nodeHeight = nodeHeight + cellPadding;
			end
		end	
		local height = self.pagesize * self.pagecount * nodeHeight;
		self.treeview:setRealSize(nil, height);
	end
end

