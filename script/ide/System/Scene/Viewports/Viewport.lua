--[[
Title: base class for all viewports
Author(s): LiXizhi@yeah.net
Date: 2018/3/27
Desc: viewport alignment type is "_fi" by default. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Viewports/Viewport.lua");
local Viewport = commonlib.gettable("System.Scene.Viewports.Viewport");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Screen = commonlib.gettable("System.Windows.Screen");

NPL.load("(gl)script/ide/System/Scene/Viewports/Viewport.lua");
local Viewport = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Scene.Viewports.Viewport"));

Viewport:Signal("sizeChanged");

function Viewport:ctor()
end

function Viewport:init(name)
	self.name = name;
	return self;
end

-- get the low-level attribute object
function Viewport:GetAttrObject()
	if(self.attr and self.attr:IsValid()) then
		return self.attr;
	else
		NPL.load("(gl)script/ide/System/Core/DOM.lua");
		local DOM = commonlib.gettable("System.Core.DOM")
		local attrManager = ParaEngine.GetAttributeObject():GetChild("ViewportManager");	
		local attr = attrManager:GetChild(self.name);
		if(attr:IsValid()) then
			self.attr = attr;
			return attr;
		end
	end
end

-- assume "_fi" fill alignment
function Viewport:SetMarginBottom(margin)
	local attr = self:GetAttrObject();
	if(attr) then
		margin = margin or 0;
		self.margin_bottom = margin;
		attr:SetField("height", margin);
		self:sizeChanged();
	end
end

function Viewport:GetMarginBottom()
	return self.margin_bottom or 0;
end


-- assume "_fi" fill alignment
function Viewport:SetMarginRight(margin)
	local attr = self:GetAttrObject();
	if(attr) then
		margin = margin or 0;
		self.margin_right = margin;
		attr:SetField("width", margin);
		self:sizeChanged();
	end
end

function Viewport:GetMarginRight()
	return self.margin_right or 0;
end


function Viewport:SetLeft(nValue)
	local attr = self:GetAttrObject();
	if(attr) then
		self.margin_left = nValue;
		attr:SetField("left", nValue);
		self:sizeChanged();
	end
end

function Viewport:GetLeft(nValue)
	return self.margin_left;
end


function Viewport:SetTop(nValue)
	local attr = self:GetAttrObject();
	if(attr) then
		self.margin_top = nValue;
		attr:SetField("top", nValue);
		self:sizeChanged();
	end
end

function Viewport:GetTop(nValue)
	return self.margin_top;
end

-- assume "_fi" fill alignment
function Viewport:SetWidth(nValue)
	local attr = self:GetAttrObject();
	if(attr) then
		attr:SetField("width", Screen:GetWidth() - nValue);
		self:sizeChanged();
	end
end

-- assume "_fi" fill alignment
function Viewport:SetHeight(nValue)
	local attr = self:GetAttrObject();
	if(attr) then
		attr:SetField("height", Screen:GetHeight() - nValue);
		self:sizeChanged();
	end
end