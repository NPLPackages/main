--[[
Title: imgeak row
Author(s): LiPeng
Date: 2017/10/3
Desc: it handles HTML tags of <img> . 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_img.lua");
System.Windows.mcml.Elements.pe_img:RegisterAs("pe:img","img");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/Canvas.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutImage.lua");
local LayoutImage = commonlib.gettable("System.Windows.mcml.layout.LayoutImage");
local Canvas = commonlib.gettable("System.Windows.Controls.Canvas");
local pe_img = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_img"));
pe_img:Property({"class_name", "pe:img"});

function pe_img:ctor()
end

function pe_img:ParseMappedAttribute(attrName, value)
	if(attrName == "src" or attrName == "width" or attrName == "height") then
		local cssKey, cssValue;
		if(attrName == "src") then
			cssKey, cssValue = "background", self:GetAbsoluteURL(value);
		elseif(attrName == "width" or attrName == "height") then
			cssKey, cssValue = attrName, value.."px";
		end
		return cssKey, cssValue;
	end
	return pe_img._super.ParseMappedAttribute(self, attrName, value)
end

function pe_img:ControlClass()
	return Canvas;
end

function pe_img:CreateLayoutObject(arena, style)
	return LayoutImage:new():init(self);
end