--[[
Title: element of css style
Author(s): LiPeng
Date: 2017/10/23
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/CssSelectorItem.lua");
local CssSelectorItem = commonlib.gettable("System.Windows.mcml.CssSelectorItem");
------------------------------------------------------------
]]
local CssSelectorItem = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.CssSelectorItem"));

function CssSelectorItem:ctor()
	self.name = nil;
	self.classes = nil;
	self.id = nil;
	self.attrs = nil;

	self.ancestor = nil;
end

function CssSelectorItem:init(name, classes, id, attrs, ancestor)
	if(classes or id or attrs or ancestor) then
		self.name = name;
		self.classes = classes;
		self.id = id;
		self.attrs = attrs;
		self.ancestor = ancestor;
	else
		self:parse(name);
	end
	return self;
end

-- @param element_info: string like "input.redbutton#warning[type=\"button\"]"
function CssSelectorItem:parse(element_info)
    self.name = string.match(element_info,"^[^.#[]+");

	for class in string.gmatch(element_info,"[.]([^.#[]+)") do
		self.classes = self.classes or {};
		self.classes[#self.classes+1] = class;
	end

	self.id = string.match(element_info,"#([^.#[]+)");

	for attr in string.gmatch(element_info,"%[([^%[%]]*)%]") do
		self.attrs = self.attrs or {};
		if(not string.find(attr,"=")) then
			self.attrs[attr] = true;
		else
			local key, value = string.match(attr,"([%w_]+)=\"([%w_]+)\"");
			self.attrs[attr] = value;
		end
	end
end

function CssSelectorItem:match(pageElement)
	if(self.name and self.name ~= pageElement.name) then
		return false;
	end
	
	if(self.id) then
		local id = pageElement:GetAttributeWithCode("id", nil, true);
		if(not id or self.id ~= id) then
			return false;
		end
	end
	
	if(self.classes) then
		local classes = pageElement:GetAttributeWithCode("class", nil, true);
		if(classes) then
			for i = 1,#self.classes do
				local class = self.classes[i];
				if(not string.find(classes,class)) then
					return false;
				end
			end
		else
			return false;
		end
	end

	if(self.attrs) then
		for key,value in pairs(self.attrs) do
			local attr_value = pageElement:GetAttributeWithCode(key, nil, true);
			if(attr_value) then
				if(type(value) == "string" and value ~= attr_value) then
					return false;
				end
			else
				return false;
			end
		end
	end

	if(self.ancestor and self.ancestor.name) then
		local ancestorPageElement = pageElement:GetParent(self.ancestor.name);
		if(ancestorPageElement) then
			return self.ancestor:match(ancestorPageElement);
		else
			return false;
		end
	else
		return true;
	end
end