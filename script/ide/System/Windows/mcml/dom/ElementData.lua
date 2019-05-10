--[[
Title: ElementData
Author(s): LiPeng
Date: 2019/5/9
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/dom/ElementData.lua");
local ElementData = commonlib.gettable("System.Windows.mcml.dom.ElementData");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/dom/Attribute.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleDeclaration.lua");
local CSSStyleDeclaration = commonlib.gettable("System.Windows.mcml.css.CSSStyleDeclaration");
local Attribute = commonlib.gettable("System.Windows.mcml.dom.Attribute");
local ElementData = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Windows.mcml.dom.ElementData"));

ElementData:Property("Name", "ElementData");
ElementData:Property({"idForStyleResolution", nil, "GetID", "SetID", auto=true});
ElementData:Property({"classNames", nil, "GetClassNames", "SetClassNames", auto=true});

function ElementData:ctor()
	self.m_attributes = {};
	self.m_attributeStyleDecl = nil;
	self.m_element = nil;
end

function ElementData:init(element)
	self.m_element = element;
	return self;
end

function ElementData:Element()
	return self.m_element;
end

function ElementData:AddAttribute(name, value, declKey, declValue)
	local attributes = self.m_attributes;
	local attribute = nil;
	for i = 1, #attributes do
		local temp_attribute = attributes[i];
		if(temp_attribute and temp_attribute:Name() == name) then
			attribute = temp_attribute;
			if(attribute:Value() == value) then
				return;
			end
		end
	end
	if(not attribute) then
		attributes[#attributes + 1] = Attribute:new():init(name, value);
		attribute = attributes[#attributes];
	end
	attribute:SetValue(value);
	self:AddAttributeCSSProperty(declKey, declValue);
end

function ElementData:GetAttribute(name)
	local attributes = self.m_attributes;
	for i=1,#attributes do
		local attribute = attributes[i];
		if(attribute and attribute:Name() == name) then
			return attribute;
		end
	end
	return nil;
end

function ElementData:GetAttributeValue(name)
	local attr = self:GetAttribute(name)
	if(attr) then
		return attr:Value();
	end
	return nil;
end

function ElementData:SetAttributeValue(name, value, declKey, declValue)
	self:AddAttribute(name, value, declKey, declValue);
end

function ElementData:AttributeStyleDecl()
	return self.m_attributeStyleDecl;
end

function ElementData:GetAttributeStyleDecl()
    if (not self.m_attributeStyleDecl) then
        self.m_attributeStyleDecl = CSSStyleDeclaration:new():init(self.m_element);
	end
    return self.m_attributeStyleDecl;
end

function ElementData:AddAttributeCSSProperty(key, value)
	if(key) then
		local styleDecl = self:GetAttributeStyleDecl();
		styleDecl:SetProperty(key, value);
	end
end