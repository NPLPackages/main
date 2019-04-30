--[[
Title: unknown element
Author(s): LiXizhi
Date: 2015/5/3
Desc: it only renders its child nodes as if this node does not exist. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_unknown.lua");
Elements.pe_unknown:RegisterAs("pe:flushnode", "pe:fallthrough");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_div.lua");
local pe_unknown = commonlib.inherit(commonlib.gettable("System.Windows.mcml.Elements.pe_div"), commonlib.gettable("System.Windows.mcml.Elements.pe_unknown"));

