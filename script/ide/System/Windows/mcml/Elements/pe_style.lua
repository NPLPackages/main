--[[
Title: pe_style
Author(s): LiXizhi
Date: 2016/10/12
Desc: it only renders its child nodes if condition is true
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_style.lua");
Elements.pe_style:RegisterAs("pe:if");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleSelector.lua");

local pe_style = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_style"));

function pe_style:ctor()
	self.sheet = nil;
end

-- skip child node parsing.
function pe_style:createFromXmlNode(o)
	return self:new(o);
end

function pe_style:attachLayoutTree()
	
end

function pe_style:LoadComponent(parentElem, parentLayout, style)
	if(self.isLoaded) then
		return
	end

	local styleSelector = self:GetPageCtrl():StyleSelector();
	if(not styleSelector) then
		return;
	end

	self.isLoaded = true;

	-- nil or "text/mcss"
	local scriptType = self:GetString("type") or "text/css";
	local type = string.match(scriptType,"[^/]+/([^/]+)");
	-- Defines a URL to a file that contains the script (instead of inserting the script into your HTML document, you can refer to a file that contains the script)
	local src = self:GetString("src") or self:GetString("href");
	if(src and src ~= "") then
		src = string.gsub(src, "^(%(.*%)).*$", "");
		src = self:GetAbsoluteURL(src);
		styleSelector:AddStyleSheetFromFile(src);
	end

	local code = self:GetPureText();
	if(code~=nil and code~="") then
		if(type == "css") then
			styleSelector:AddStyleSheetFromString(code);
		elseif(type == "mcss") then
			local t = commonlib.LoadTableFromString(code);
			if(t and type(t) == "table") then
				styleSelector:AddStyleSheetFromTable(code);
			end
		end
	end
end

-- @param src: can be relative to current file or global filename.
function pe_style:LoadStyleFile(src)
	if(src ~= nil and src ~= "") then
		src = string.gsub(src, "^(%(.*%)).*$", "");
		src = self:GetAbsoluteURL(src);
		local style = StyleManager:GetStyle(src);
		if(style) then
			style:SetPage(self:GetPageCtrl());
			local pageStyle = self:GetPageStyle();
			if(pageStyle) then
				pageStyle:AddReference(style);
			end
		end
	end
end

function pe_style:NeedsLoadComponent()
	return true;
end

-- get all pure text of only text child node
-- because skip child node parsing, we need traverse it by index
function pe_style:GetPureText()
	local nSize = #(self);
	local text = "";
	for i=1, nSize do
		node = self[i];
		if(node) then
			if(type(node) == "string") then
				text = text..node;
			elseif(node.name== "text" and type(node.value) == "string") then
				text = text..node.value;
			end
		end
	end
	return text;
end