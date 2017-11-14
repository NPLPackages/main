--[[
Title: 
Author(s): LiXizhi
Date: 2015/4/29
Desc: it handles HTML tags of <pe:bindingblock> . 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_bindingblock.lua");
System.Windows.mcml.Elements.pe_bindingblock:RegisterAs("pe:bindingblock");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_div.lua");
local pe_bindingblock = commonlib.inherit(commonlib.gettable("System.Windows.mcml.Elements.pe_div"), commonlib.gettable("System.Windows.mcml.Elements.pe_bindingblock"));
pe_bindingblock:Property({"class_name", "pe:bindingblock"});

function pe_bindingblock:ctor()
end

function pe_bindingblock:LoadComponent(parentElem, parentLayout, styleItem)
	local prescript = self:GetAttribute("prescript");
	if(prescript) then
		System.Windows.mcml.Elements.pe_script.DoPageCode(prescript, self:GetPageCtrl())
	end
	pe_bindingblock._super.LoadComponent(self, parentElem, parentLayout, css);
end

