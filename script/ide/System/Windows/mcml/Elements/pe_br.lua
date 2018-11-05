--[[
Title: break row
Author(s): LiXizhi
Date: 2015/4/29
Desc: it handles HTML tags of <br> . 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_br.lua");
System.Windows.mcml.Elements.pe_br:RegisterAs("br");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBR.lua");
local LayoutBR = commonlib.gettable("System.Windows.mcml.layout.LayoutBR");
local pe_br = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_br"));

function pe_br:ctor()
end

-- skip child node parsing.
function pe_br:createFromXmlNode(o)
	return self:new(o);
end

--function pe_br:UpdateLayout(parentLayout)
--	parentLayout:NewLine();
--end

function pe_br:CreateLayoutObject(arena, style)
	return LayoutBR:new():init(self);
end

