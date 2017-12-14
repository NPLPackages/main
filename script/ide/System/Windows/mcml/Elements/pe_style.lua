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

function pe_style:LoadComponent(parentElem, parentLayout, style)
	if(self.isLoaded) then
		return
	end
	self.isLoaded = true;

	-- nil or "text/mcss"
	local scriptType = self:GetString("type");
	local type = string.match(scriptType,"[^/]+/([^/]+)");
	-- Defines a URL to a file that contains the script (instead of inserting the script into your HTML document, you can refer to a file that contains the script)
	local src = self:GetString("src");
	if(src and src ~= "") then
		local pageStyle = self:GetPageStyle();
		if(pageStyle) then
			src = string.gsub(src, "^(%(.*%)).*$", "");
			src = self:GetAbsoluteURL(src);
			pageStyle:AddStyleSheetFromFile(src);
		end
	end

	local code = self:GetPureText();
	if(code~=nil and code~="") then
		local pageStyle = self:GetPageStyle();
		if(pageStyle) then
			if(type == "css") then
				pageStyle:AddStyleSheetFromString(code);
			elseif(type == "mcss") then
				local t = commonlib.LoadTableFromString(code);
				if(t and type(t) == "table") then
					pageStyle:AddStyleSheetFromTable(code);
				end
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
			local pageStyle = self:GetPageStyle();
			if(pageStyle) then
				pageStyle:AddReference(style);
			end
		end
	end
end