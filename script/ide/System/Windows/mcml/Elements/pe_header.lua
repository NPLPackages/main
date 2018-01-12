--[[
Title: header element
Author(s): LiPeng
Date: 2017/10/3
Desc: it handles HTML tags of <h1>,<h2>,<h3>,<h4> in HTML. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_header.lua");
System.Windows.mcml.Elements.pe_header:RegisterAs("h1","h2","h3","h4");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_div.lua");
local mcml = commonlib.gettable("System.Windows.mcml");

local pe_header = commonlib.inherit(commonlib.gettable("System.Windows.mcml.Elements.pe_div"), commonlib.gettable("System.Windows.mcml.Elements.pe_header"));
pe_header:Property({"class_name", "header"});

function pe_header:ctor()
end

function pe_header:LoadComponent(parentElem, parentLayout, styleItem)
	local css = self:CreateStyle(mcml:GetStyleItem(self.name), styleItem);
	pe_header._super.LoadComponent(self, parentElem, parentLayout, css);
end