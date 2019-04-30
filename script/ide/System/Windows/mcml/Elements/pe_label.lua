--[[
Title: pe_label
Author(s): LiPeng
Date: 2017/10/3
Desc: it handles HTML tags of <label> . 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_label.lua");
System.Windows.mcml.Elements.pe_label:RegisterAs("label","pe:label");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_span.lua");
local pe_label = commonlib.inherit(commonlib.gettable("System.Windows.mcml.Elements.pe_span"), commonlib.gettable("System.Windows.mcml.Elements.pe_label"));
pe_label:Property({"class_name", "pe:label"});

function pe_label:ctor()
end

-- get value: it is usually one of the editor tag, such as <input>
function pe_label:GetValue()
	return self:GetAttribute("value");
end

-- set value: it is usually one of the editor tag, such as <input>
function pe_label:SetValue(value)
	self:SetAttribute("value", value);
	if(self.control) then
		return self.control:SetText(value);
	end
end
