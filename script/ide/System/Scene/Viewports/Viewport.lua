--[[
Title: base class for all viewports
Author(s): LiXizhi@yeah.net
Date: 2018/3/27
Desc: viewport alignment type is "_fi" by default. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Viewports/Viewport.lua");
local Viewport = commonlib.gettable("System.Scene.Viewports.Viewport");
-- create custom viewport. 
local viewport = Viewport:new():init("userCamera0")
viewport:SetRenderTargetName(nil, 400, 300) -- returns "_miniscenegraph_userCamera0"
local x, y, z = ParaScene.GetPlayer():GetPosition()
viewport:SetCameraViewParams({x, y, z}, {x+10, y+10, z}, {0,1,0});
viewport:SetEnabled(true)
window(format('<div style="width:400px;height:300px;background:url(%s# 0 0 400 300)"></div>', viewport:GetRenderTargetName()),"_lt", 0, 0, 400, 300)
registerStopEvent(function() viewport:Destroy() end)

-- predefined viewport: "scene" and "GUI"
Viewport:new():init(0):SetMarginBottom(100)
Viewport:new():init("GUI"):SetMarginBottom(100)
Viewport:new():init("scene"):SetMarginBottom(100)
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
NPL.load("(gl)script/ide/System/Scene/Viewports/Viewport.lua");
NPL.load("(gl)script/ide/System/Scene/Assets/ImageFile.lua");
local ImageFile = commonlib.gettable("System.Scene.Assets.ImageFile");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
local Screen = commonlib.gettable("System.Windows.Screen");
local Viewport = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Scene.Viewports.Viewport"));

Viewport:Property({"MarginLeftHandler", nil, auto=true});
Viewport:Property({"MarginTopHandler", nil, auto=true});
Viewport:Property({"MarginRightHandler", nil, auto=true});
Viewport:Property({"MarginBottomHandler", nil, auto=true});
Viewport:Property({"alignment", "_fi", "GetAlignment", "SetAlignment", auto=true});

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
	Screen:Connect("sizeChanged", self, self.OnUpdateSize, "UniqueConnection");
	ViewportManager:AddViewport(self);
	return self;
end

function Viewport:GetKey()
	return self.name or self.id;
end

-- destroy the viewport
function Viewport:Destroy()
	Viewport._super.Destroy(self);

	local attrManager = ParaEngine.GetAttributeObject():GetChild("ViewportManager");	
	if(attrManager) then
		attrManager:SetField("DeleteViewportByName", tostring(self.name or self.id))
	end
end

-- get the camera object
function Viewport:GetCameraAttrObject()
	if(not self.cameraAttr) then
		local attr = self:GetAttrObject()
		attr = attr:GetChild("camera")
		if(attr:IsValid()) then
			self.cameraAttr = attr
		end
	end
	return self.cameraAttr
end

function Viewport:SetFarPlane(farPlane)
	local attr = self:GetCameraAttrObject()
	if(attr) then
		attr:SetField("FarPlane", farPlane)
	end
end

function Viewport:SetCameraViewParams(lookAtPos, eyePos, cameraUp, farPlane)
	self:SetUseSceneCamera(false)
	local attr = self:GetCameraAttrObject()
	if(attr) then
		if(lookAtPos) then
			attr:SetField("Lookat position", lookAtPos);
		end
		if(eyePos) then
			attr:SetField("Eye position", eyePos);
		end
		if(cameraUp) then
			attr:SetField("CameraUp", cameraUp);
		end
		if(farPlane) then
			attr:SetField("FarPlane", farPlane);
		end
	end
end

-- @param fov: default to 60/180*3.14 = 1.0472. If value is bigger than 3.15, it is in radian.
function Viewport:SetCameraFieldOfView(fov, nearPlane, farPlane)
	local attr = self:GetCameraAttrObject()
	if(attr) then
		if(fov > 3.15) then
			fov = fov / 180 * math.pi;
		end
		attr:SetField("FieldOfView", fov)
		if(nearPlane) then
			attr:SetField("NearPlane", nearPlane)
		end
		if(farPlane) then
			attr:SetField("FarPlane", farPlane)
		end
	end
end

function Viewport:SetUseSceneCamera(bUseSceneCamera)
	self:GetAttrObject():SetField("UseSceneCamera", bUseSceneCamera)
end

function Viewport:SetEnabled(bEnabled)
	local attr = self:GetAttrObject()
	if(attr) then
		attr:SetField("enabled", bEnabled~=false)
	end
end

-- get the low-level attribute object
function Viewport:GetAttrObject()
	if(self.attr and self.attr:IsValid()) then
		return self.attr;
	else
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
		else
			local nCount = attrManager:GetChildCount()
			attr = ParaEngine.GetViewportAttributeObject(nCount);
			self.attr = attr;
			if(self.name) then
				attr:SetField("name", self.name or "");
			end
			-- default to custom camera scene
			attr:SetField("zorder", 100);
			attr:SetField("IsDeltaTimeDisabled", true);
			attr:SetField("PipelineOrder", 1);
			if(self.name ~= "scene" and self.name ~= "GUI") then
				self.isUserDefined = true
			end
			return attr;
		end
	end
end

function Viewport:IsUserDefined()
	return self.isUserDefined;
end

-- @param order: -1 for both GUI and scene, 0 for GUI only, 1 for scene only
function Viewport:SetPipelineOrder(order)
	local attr = self:GetAttrObject();
	if(attr) then
		attr:SetField("PipelineOrder", order or -1);
	end
end

-- set custom render target name
-- @param name: should begin with "_miniscenegraph_". if nil, it default to "_miniscenegraph_"..self.name
function Viewport:SetRenderTargetName(name, width, height)
	local attr = self:GetAttrObject();
	if(attr) then
		if(name and not name:match("^_miniscenegraph")) then
			log("warning: Viewport:SetRenderTargetName input name should begin with `_miniscenegraph` \n");
		end
		self.renderTargetName = name or ("_miniscenegraph_"..(self.name or "viewport"));
		attr:SetField("RenderTargetName", self.renderTargetName);
		self.renderTargetWidth, self.renderTargetHeight = width, height;

		if(width and height) then
			-- local renderTarget = ParaAsset.LoadTexture(name, name, 0); 
			-- renderTarget:SetSize(width, height);
			self:SetPosition("_lt", 0, 0, width, height)
		end
		return self.renderTargetName;
	end
end

function Viewport:GetRenderTargetName()
	return self.renderTargetName;
end

function Viewport:GetRenderTarget()
	local renderTargetName = self:GetRenderTargetName();
	if(renderTargetName and renderTargetName ~= "") then
		local renderTarget = ParaScene.GetAttributeObject():GetChild("CRenderTarget"):GetChild(renderTargetName);
		return renderTarget;
	end
end

-- get render target image data as a table. only call this function after self:SetRenderTargetName. 
-- @param width, height: sample at the given width and height. if nil, they will be same as the texture size.
-- @param colorMode: "rgb" or "DWORD" or "grey", default to "rgb". if "grey", value normalized to [0,1]
-- @return nil or {width=number, height=number, data = {r,g,b, r,g,b, ...} }
function Viewport:GetImageData(width, height, colorMode)
	local renderTarget = self:GetRenderTarget()
	if (renderTarget) then
		local file = ImageFile.open(self.renderTargetName)
		if(file:IsValid()) then
			local img = file:GetImageData(width, height, colorMode)
			file:close();
			return img;
		end
	end
end

-- save texture to file
-- @param filename: should be a writable path, default to "temp/viewport.jpg"
-- @param width, height: default to nil, if specified, it will save the texture to the given size.
-- @return filename
function Viewport:SaveToFile(filename, width, height)
	local renderTarget = self:GetRenderTarget()
	if(renderTarget) then
		filename = filename or "temp/viewport.jpg"
		local filenameWithRegion = filename;
		if(self.renderTargetWidth) then
			filenameWithRegion = string.format("%s;0 0 %d %d", filename, width or self.renderTargetWidth, height or self.renderTargetHeight)
		end
		renderTarget:SetField("SaveToFile", filenameWithRegion)
		return filename;
	end
end

-- set alignment and position
function Viewport:SetPosition(alignment, left, top, width, height)
	local attr = self:GetAttrObject();
	self.alignment = alignment
	attr:SetField("alignment", alignment);
	attr:SetField("left", left);
	attr:SetField("top", top);
	attr:SetField("width", width);
	attr:SetField("height", height);
end

function Viewport:Apply()
	local attr = self:GetAttrObject();
	attr:CallField("ApplyViewport");
end

function Viewport:SetMarginBottom(margin)
	if(self:GetMarginBottom() ~= margin) then
		local attr = self:GetAttrObject();
		if(attr) then
			margin = margin or 0;
			self.margin_bottom = margin;
			if(self.alignment == "_fi") then
				attr:SetField("height", margin);
			else
				local ui_scaling = Screen:GetUIScaling(true)
				attr:SetField("height", Screen:GetHeight()*ui_scaling[2] - margin);
			end
			self:OnUpdateSize();
		end
	end
end

function Viewport:GetMarginBottom()
	return self.margin_bottom or 0;
end

function Viewport:SetMarginRight(margin)
	if(self:GetMarginRight() ~= margin) then
		local attr = self:GetAttrObject();
		if(attr) then
			margin = margin or 0;
			self.margin_right = margin;
			if(self.alignment == "_fi") then
				attr:SetField("width", margin);
			else
				local ui_scaling = Screen:GetUIScaling(true)
				attr:SetField("width", Screen:GetWidth()*ui_scaling[2] - margin);
			end
			
			self:OnUpdateSize();
		end
	end
end

function Viewport:GetMarginRight()
	return self.margin_right or 0;
end

function Viewport:SetMargins(left, top, right, bottom)
	left = left or 0
	top = top or 0
	right = right or 0
	bottom = bottom or 0
	if(left ~= self:GetLeft() or top ~= self:GetTop() or right ~= self:GetMarginRight() or bottom ~= self:GetMarginBottom()) then
		local attr = self:GetAttrObject();
		if(attr) then
			self.margin_left = left;
			self.margin_top = top;
			self.margin_right = right;
			self.margin_bottom = bottom;
			if(self.alignment == "_fi") then
				attr:SetField("left", left);
				attr:SetField("top", top);
				attr:SetField("width", right);
				attr:SetField("height", bottom);
			else
				local ui_scaling = Screen:GetUIScaling(true)
				attr:SetField("left", left);
				attr:SetField("top", top);
				attr:SetField("width", (Screen:GetWidth()*ui_scaling[1] - left - right));
				attr:SetField("height", (Screen:GetHeight()*ui_scaling[2] - top - bottom));
			end
			self:OnUpdateSize();
		end
	end
end

function Viewport:SetLeft(nValue)
	local attr = self:GetAttrObject();
	if(attr) then
		self.margin_left = nValue;
		attr:SetField("left", nValue);
		self:OnUpdateSize();
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
		self:OnUpdateSize();
	end
end

function Viewport:GetTop()
	return self.margin_top or 0;
end

function Viewport:SetWidth(nValue)
	local attr = self:GetAttrObject();
	if(attr) then
		if(self.alignment == "_fi") then
			local ui_scaling = Screen:GetUIScaling(true)
			attr:SetField("width", Screen:GetWidth()*ui_scaling[1] - nValue);
		else
			attr:SetField("width", nValue);
		end
		self:OnUpdateSize();
	end
end

function Viewport:SetHeight(nValue)
	local attr = self:GetAttrObject();
	if(attr) then
		if(self.alignment == "_fi") then
			local ui_scaling = Screen:GetUIScaling(true)
			attr:SetField("height", Screen:GetHeight()*ui_scaling[2] - nValue);
		else
			attr:SetField("height", nValue);
		end
		self:OnUpdateSize();
	end
end

function Viewport:OnUpdateSize()
	local _this = self:GetUIObject()
	if(_this) then
		local viewportUI = ViewportManager:GetGUIViewport()
		local margin_right = math.floor((self:GetMarginRight() - viewportUI:GetMarginRight()) / Screen:GetUIScaling()[1]);
		local margin_bottom = math.floor((self:GetMarginBottom() - viewportUI:GetMarginBottom()) / Screen:GetUIScaling()[2])
		_this.x = math.floor((self:GetLeft() - viewportUI:GetLeft()) / Screen:GetUIScaling()[1]);
		_this.y = math.floor((self:GetTop() - viewportUI:GetTop()) / Screen:GetUIScaling()[2]);
		_this.height = margin_bottom;
		_this.width = margin_right;
	end
	self:sizeChanged();
end

-- @return left, top, width, height in screen UI space
function Viewport:GetUIRect()
	local viewportUI = ViewportManager:GetGUIViewport()
	local left = math.floor((self:GetLeft() - viewportUI:GetLeft()) / Screen:GetUIScaling()[1]);
	local top = math.floor((self:GetTop() - viewportUI:GetTop()) / Screen:GetUIScaling()[2]);
	local width = Screen:GetWidth() - left - math.floor((self:GetMarginRight() - viewportUI:GetMarginRight()) / Screen:GetUIScaling()[1]);
	local height = Screen:GetHeight() - top - math.floor((self:GetMarginBottom() - viewportUI:GetMarginBottom()) / Screen:GetUIScaling()[2])
	return left, top, width, height;
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
			local viewport = ViewportManager:GetSceneViewport(); -- why scene not self?
			local viewportUI = ViewportManager:GetGUIViewport()
			local margin_right = math.floor((viewport:GetMarginRight() - viewportUI:GetMarginRight()) / Screen:GetUIScaling()[1]);
			local margin_bottom = math.floor((viewport:GetMarginBottom() - viewportUI:GetMarginBottom()) / Screen:GetUIScaling()[2])
			local left = math.floor((viewport:GetLeft() - viewportUI:GetLeft()) / Screen:GetUIScaling()[1]);
			local top = math.floor((viewport:GetTop() - viewportUI:GetTop()) / Screen:GetUIScaling()[2]);
			_this = ParaUI.CreateUIObject("container", name, "_fi", left, top, margin_right, margin_bottom);
			_this.background = ""
			_this:SetField("ClickThrough", true);
			
			_this.zorder = -3;
			_this:AttachToRoot();

			_this:SetScript("onsize", function()
				self:OnUpdateSize();
			end);
		end
		self.uiobject_id = _this.id;
		return _this;
	end
end