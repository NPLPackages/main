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
local pe_br = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_br"));

function pe_br:ctor()
end

function pe_br:UpdateLayout(parentLayout)
	parentLayout:NewLine();
end

