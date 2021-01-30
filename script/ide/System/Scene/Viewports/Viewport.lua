--[[
Title: base class for all viewports
Author(s): LiXizhi@yeah.net
Date: 2018/3/27
Desc: viewport alignment type is "_fi" by default. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Viewports/Viewport.lua");
local Viewport = commonlib.gettable("System.Scene.Viewports.Viewport");
Viewport:init(0):SetMarginBottom(100)
Viewport:init("GUI"):SetMarginBottom(100)
Viewport:init("scene"):SetMarginBottom(100)
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Screen = commonlib.gettable("System.Windows.Screen");

NPL.load("(gl)script/ide/System/Scene/Viewports/Viewport.lua");
local Viewport = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Scene.Viewports.Viewport"));

Viewport:Property({"MarginLeftHandler", nil, auto=true});
Viewport:Property({"MarginTopHandler", nil, auto=true});
Viewport:Property({"MarginRightHandler", nil, auto=true});
Viewport:Property({"MarginBottomHandler", nil, auto=true});

Viewport:Signal("sizeChanged");

function Viewport:ctor()
end

function Viewport:init(name_or_id)
	if(type(name_or_id) == "string") then
		self.name = name_or_id;
	elseif(type(name_or_id) == "number") then
		if(name_or_id < 0) then
			name_or_id = 0;
		end
		self.id = name_or_id;
	end
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
		local attr;
		if(self.name) then
			attr = attrManager:GetChild(self.name);
		else
			attr = attrManager:GetChildAt(self.id or 0);
		end
		if(attr:IsValid()) then
			self.attr = attr;
			return attr;
		end
	end
end

-- set alignment and position
function Viewport:SetPosition(alignment, left, top, width, height)
	local attr = self:GetAttrObject(self.nIndex);
	attr:SetField("alignment", alignment);
	attr:SetField("left", left);
	attr:SetField("top", top);
	attr:SetField("width", width);
	attr:SetField("height", height);
end

function Viewport:Apply()
	local attr = self:GetAttrObject(self.nIndex);
	attr:CallField("ApplyViewport");
end

-- assume "_fi" fill alignment
function Viewport:SetMarginBottom(margin)
	if(self:GetMarginBottom() ~= margin) then
		local attr = self:GetAttrObject();
		if(attr) then
			margin = margin or 0;
			self.margin_bottom = margin;
			attr:SetField("height", margin);
			self:sizeChanged();
		end
	end
end

function Viewport:GetMarginBottom()
	return self.margin_bottom or 0;
end


-- assume "_fi" fill alignment
function Viewport:SetMarginRight(margin)
	if(self:GetMarginRight() ~= margin) then
		local attr = self:GetAttrObject();
		if(attr) then
			margin = margin or 0;
			self.margin_right = margin;
			attr:SetField("width", margin);
			self:sizeChanged();
		end
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

function Viewport:GetLeft()
	return self.margin_left or 0;
end


function Viewport:SetTop(nValue)
	local attr = self:GetAttrObject();
	if(attr) then
		self.margin_top = nValue;
		attr:SetField("top", nValue);
		self:sizeChanged();
	end
end

function Viewport:GetTop()
	return self.margin_top or 0;
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

-- create get the UI container object that is the same size of the view port.
function Viewport:GetUIObject(bCreateIfNotExist)
	if(self.uiobject_id) then
		local _this = ParaUI.GetUIObject(self.uiobject_id);
		if(_this:IsValid()) then
			return _this;
		end
	end
	if(bCreateIfNotExist) then
		local name = "ViewportUI"..tostring(self.name or self.id)
		local _this = ParaUI.GetUIObject(name);
		if(not _this:IsValid()) then
			local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
			local viewport = ViewportManager:GetSceneViewport();
			local margin_right = math.floor(viewport:GetMarginRight() / Screen:GetUIScaling()[1]);
			local margin_bottom = math.floor(viewport:GetMarginBottom() / Screen:GetUIScaling()[2])
			local top = math.floor(viewport:GetTop() / Screen:GetUIScaling()[2]);
			_this = ParaUI.CreateUIObject("container", name, "_fi", 0,top,margin_right, margin_bottom);
			_this.background = ""
			_this:SetField("ClickThrough", true);
			
			_this.zorder = -3;
			_this:AttachToRoot();
			_this:SetScript("onsize", function()
				self:sizeChanged();
			end);
			self:Connect("sizeChanged", nil, function()
				local _this = ParaUI.GetUIObject(name);
				local margin_right = math.floor(viewport:GetMarginRight() / Screen:GetUIScaling()[1]);
				local margin_bottom = math.floor(viewport:GetMarginBottom() / Screen:GetUIScaling()[2])
				_this.y = math.floor(viewport:GetTop() / Screen:GetUIScaling()[2]);
				_this.height = margin_bottom;
				_this.width = margin_right;
			end)
		end
		self.uiobject_id = _this.id;
		return _this;
	end
end