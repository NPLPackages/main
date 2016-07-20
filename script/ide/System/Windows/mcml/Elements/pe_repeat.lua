--[[
Title: pe:repeat element
Author(s): LiXizhi
Date: 2016/7/19
Desc: pe:repeat element
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_repeat.lua");
System.Windows.mcml.Elements.pe_repeat:RegisterAs("pe:repeat");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
NPL.load("(gl)script/ide/System/Windows/Shapes/Rectangle.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
local Button = commonlib.gettable("System.Windows.Controls.Button");
local Rectangle = commonlib.gettable("System.Windows.Shapes.Rectangle");

local pe_repeat = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_repeat"));

function pe_repeat:ctor()
end

function pe_repeat:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	if(self.isCompiled) then
		return;
	end
	self.isCompiled = true;
	self:MoveChildrenToTemplate();

	local value = self:GetAttribute("value");
	if(type(value) == "string") then
		local name, value = value:match("^([%w_]+)%s+in%s+([^%s%(]+)");
		if(name and value) then
			local arrayValues = self:GetScriptValue(value);
			if(type(arrayValues) == "function") then
				arrayValues = arrayValues();
			end
			if(arrayValues and type(arrayValues) == "table") then
				local template = self:GetTemplateNode();
				for i, v in ipairs(arrayValues) do
					local child = template:clone();
					child:SetPreValue("index", i);
					child:SetPreValue(name, v);
					self:AddChild(child);
				end
			end
		end
	end
end
