--[[
Title: 
Author(s): LiPeng
Date: 2017/10/3
Desc: it handles HTML tags of <pe:pager> . 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_pager.lua");
System.Windows.mcml.Elements.pe_pager:RegisterAs("pe:pager");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_container.lua");
local mcml = commonlib.gettable("System.Windows.mcml");
local pe_pager = commonlib.inherit(commonlib.gettable("System.Windows.mcml.Elements.pe_container"), commonlib.gettable("System.Windows.mcml.Elements.pe_pager"));
pe_pager:Property({"class_name", "pe:pager"});

function pe_pager:ctor()
end

--function pe_pager:createFromXmlNode(o)
--	o = pe_pager._super.createFromXmlNode(self, o);
--
--end

--function pe_pager:UpdateLayout(parentLayout)
--	parentLayout:NewLine();
--end

-- create pager control for navigation
function pe_pager:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	local prevButtonBackground = "";
	local nextButtonBackground = "";
	
	local default_css = mcml:GetStyleItem(self.class_name);
	if(default_css) then
		prevButtonBackground = default_css.prevButtonBackground or prevButtonBackground;
		nextButtonBackground = default_css.nextButtonBackground or nextButtonBackground;
	end
	

	if(self:GetChildCount() == 0) then
		--
		-- the user did not provide any template
		--
		local formNode = mcml:createFromXmlNode({name="form"});
		self:AddChild(formNode, nil);
		
		-- hidden input storing which control this pager is bound to
		local node = mcml:createFromXmlNode({name="input", attr={type="hidden"}});
		node:SetAttribute("name", "target");
		node:SetAttribute("value", self:GetAttribute("target"));
		formNode:AddChild(node, nil);
		
--		-- pre button
		local previousPageText = self:GetAttribute("PreviousPageText");
		if(previousPageText ~= "") then
			--local nodeNav = Map3DSystem.mcml.new(nil, {name="div"});
			local nodeNav = mcml:createFromXmlNode({name="div"});
			nodeNav:SetAttribute("name", "pre");
			nodeNav:SetAttribute("style", "float:left;color:#000066;background:;");
			nodeNav:SetAttribute("onclick", "System.Windows.mcml.Elements.pe_pager.OnPrePage");
			formNode:AddChild(nodeNav, nil);
			
			node = mcml:createFromXmlNode({name="button"});
			node:SetAttribute("polygonStyle","narrow");
			node:SetAttribute("direction","left");
			node:SetAttribute("style", string.format("width:16px;height:16px;margin-right:5px;margin-top:2px;background:%s",prevButtonBackground));
			node:SetAttribute("onclick", "System.Windows.mcml.Elements.pe_pager.OnPrePage");
			nodeNav:AddChild(node, nil);
			
			node = mcml:createFromXmlNode({previousPageText or L"Previous", name="span"});
			nodeNav:AddChild(node, nil);
		else
			node = mcml:createFromXmlNode({name="input", attr={type="button"}});
			node:SetAttribute("name", "pre");
			node:SetAttribute("polygonStyle","narrow");
			node:SetAttribute("direction","left");
			--node:SetAttribute("style", "background:url(Texture/3DMapSystem/common/PageLeft.png);width:22px;height:22px;margin:2px");
			node:SetAttribute("style", string.format("width:22px;height:22px;margin:2px;background:%s",prevButtonBackground));
			node:SetAttribute("onclick", "System.Windows.mcml.Elements.pe_pager.OnPrePage");
			formNode:AddChild(node, nil);
		end	

		
		-- page label
		node = mcml:createFromXmlNode({name="label"});
		node:SetAttribute("name", "page");
		node:SetAttribute("style", "height:18px;margin-top:2px;margin-left:10px;margin-right:10px;width:50px;text-align:center");
		formNode:AddChild(node, nil);
		
		-- next button
		local nextPageText = self:GetAttribute("NextPageText");
		if(nextPageText ~= "") then
			local nodeNav = mcml:createFromXmlNode({name="div"});
			nodeNav:SetAttribute("name", "next");
			--nodeNav:SetAttribute("style", "float:left;color:#000066;background:;background2:url(Texture/3DMapSystem/common/href.png:2 2 2 2)");
			nodeNav:SetAttribute("style", "float:left;color:#000066;background:;");
			nodeNav:SetAttribute("onclick", "System.Windows.mcml.Elements.pe_pager.OnNextPage");
			formNode:AddChild(nodeNav, nil);
			
			node = mcml:createFromXmlNode({nextPageText or L"Next", name="span"});
			nodeNav:AddChild(node, nil);
			
			node = mcml:createFromXmlNode({name="button"});
			node:SetAttribute("polygonStyle","narrow");
			node:SetAttribute("direction","right");
			node:SetAttribute("style", string.format("width:16px;height:16px;margin-left:5px;margin-top;2px;background:%s",nextButtonBackground));
			node:SetAttribute("onclick", "System.Windows.mcml.Elements.pe_pager.OnNextPage");
			nodeNav:AddChild(node, nil);
		else
			node = mcml:createFromXmlNode({name="input", attr={type="button", onclick="System.Windows.mcml.Elements.pe_pager.OnNextPage"}});
			node:SetAttribute("name", "next");
			node:SetAttribute("polygonStyle","narrow");
			node:SetAttribute("direction","right");
			--node:SetAttribute("style", "background:url(Texture/3DMapSystem/common/PageRight.png);width:22px;height:22px;margin:2px");
			node:SetAttribute("style", string.format("width:22px;height:22px;margin:2px;background:%s",nextButtonBackground));
			formNode:AddChild(node, nil);
		end	
	else	
		--
		-- use the user template
		--	
		local formNode = self:GetChild("form");
		if(formNode) then
			local node = self:SearchChildByAttribute("name", "target");
			if(node) then
				if(not node:GetAttribute("value")) then
					node:SetAttribute("value", self:GetAttribute("target"));
				end	
			else
				node = mcml:createFromXmlNode({name="input", attr={type="hidden"}});
				--node = Map3DSystem.mcml.new(nil, {name="input"});
				--node:SetAttribute("type", "hidden");
				node:SetAttribute("name", "target");
				node:SetAttribute("value", self:GetAttribute("target"));
				formNode:AddChild(node, nil);
			end
			
			node = self:SearchChildByAttribute("name", "pre");
			if(node and not node:GetAttribute("onclick")) then
				node:SetAttribute("onclick", "System.Windows.mcml.Elements.pe_pager.OnPrePage");
			end
			
			node = self:SearchChildByAttribute("name", "next");
			if(node and not node:GetAttribute("onclick")) then
				node:SetAttribute("onclick", "System.Windows.mcml.Elements.pe_pager.OnNextPage");
			end
		end	
	end	
	
	-- just use the standard style to create the control	
	--Map3DSystem.mcml_controls.pe_simple_styles.create(rootName, self, bindingContext, _parent, left, top, width, height, style, parentLayout);
end

-- previous page
function pe_pager.OnPrePage(btnName, btn)
	local pager;
	if(btn) then
		pager = btn:GetParent("pe:pager")
	end	
	if(pager) then
		local targetControl = pager:GetAttribute("target");
		if(targetControl) then
			local pageindex = pager:GetPageCtrl():CallMethod(targetControl, "GetCurrentPage") 
			if(pageindex) then
				pager:GetPageCtrl():CallMethod(targetControl, "GotoPage", pageindex-1) 
			end	
		end	
	end
end

-- next page
function pe_pager.OnNextPage(btnName, btn)
	local pager;
	if(btn) then
		pager = btn:GetParent("pe:pager")
	end	
	if(pager) then
		local targetControl = pager:GetAttribute("target");
		if(targetControl) then
			local pageindex = pager:GetPageCtrl():CallMethod(targetControl, "GetCurrentPage") 
			if(pageindex) then
				pager:GetPageCtrl():CallMethod(targetControl, "GotoPage", pageindex+1) 
			end	
		end	
	end
end

-- Public method: call this method whenever page index or page count changes.
function pe_pager:UpdatePager(pageInstName, pageindex, pagecount)
	if(pageindex and pagecount) then
		local bAutoHidePager = self:GetBool("AutoHidePager", false);
		
		local node = self:SearchChildByAttribute("name", "page")
		if(node and node.SetValue) then
			local value = format("%d/%d", pageindex, pagecount);
			node:SetValue(value);
			--node:SetUIValue(pageInstName, value);
--			if(bAutoHidePager) then
--				local ctl = node:GetControl();
--				if(ctl) then
--					ctl.visible = not (pagecount == 1);
--				end
--			end
		end

--		local node = self:SearchChildByAttribute("name", "singlepage")
--		if(node and node.SetUIValue) then
--			local value = format("%d", pageindex);
--			node:SetValue(value);
--			node:SetUIValue(pageInstName, value);
--			if(bAutoHidePager) then
--				local ctl = node:GetControl();
--				if(ctl) then
--					ctl.visible = not (pagecount == 1);
--				end
--			end
--		end

--		-- enable/disable prev button
--		local node = self:SearchChildByAttribute("name", "pre")
--		if(node and node:HasMethod(pageInstName, "SetEnable")) then
--			node:CallMethod(pageInstName, "SetEnable", (pageindex > 1))
--			if(bAutoHidePager) then
--				local ctl = node:GetControl();
--				if(ctl) then
--					ctl.visible = not (pagecount == 1);
--				end
--			end
--		end
--		
--		-- enable/disable next button
--		local node = self:SearchChildByAttribute("name", "next")
--		if(node and node:HasMethod(pageInstName, "SetEnable")) then
--			node:CallMethod(pageInstName, "SetEnable", (pageindex < pagecount))
--			if(bAutoHidePager) then
--				local ctl = node:GetControl();
--				if(ctl) then
--					ctl.visible = not (pagecount == 1);
--				end
--			end
--		end
	end
end

--function pe_pager:OnAfterChildLayout(layout, left, top, right, bottom)
--	
--	if(self.control) then
--		self.control:setGeometry(left, top, right-left, bottom-top);
--	end
--end