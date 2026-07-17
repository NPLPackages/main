--[[
Title: RenderTarget
Author(s): LiXizhi@yeah.net
Date: 2024/2/3
Desc: default to a persistent render target, that the OnPaint event is called whenever the render target is used(rendered in viewport) in the scene.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Assets/RenderTarget.lua");
local RenderTarget = commonlib.gettable("System.Scene.Assets.RenderTarget");
local rt = RenderTarget:new():Init("rendertarget_video", 256, 256)
local hitCount = 0
rt:Connect("OnPaint", function(painter)
    hitCount = hitCount + 1;
    painter:SetPen(0xff000000);
    painter:DrawRect(0, 0, 200, 32);
    painter:SetPen(0xffffff00);
    painter:DrawText(0, 0, "hitcount: "..hitCount);
end)
-- use this filename in the scene to display the render target. like "_miniscenegraph_rendertarget_video"
echo(rt:GetTextureFilename()); 
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/PainterContext.lua");
local PainterContext = commonlib.gettable("System.Core.PainterContext");
local RenderTarget = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Scene.Assets.RenderTarget"));

RenderTarget:Signal("OnPaint");

function RenderTarget:ctor()
	System.Core.Scene:MakeAutoDestory(self);
end

function RenderTarget:Destroy()
	RenderTarget._super.Destroy(self);
	if(self.textureAsset) then
		LOG.std(nil, "info", "RenderTarget", "destroy %s", self.filename or "");
		self.textureAsset:UnloadAsset();
		self.textureAsset = nil;
	end
	self.renderTarget = nil;
	self.painter = nil;
end

function RenderTarget:Init(filename, width, height)
	self.filename = filename or "defaultRenderTarget";
	self.width = width or 256;
	self.height = height or 256;
	self.painter = System.Core.PainterContext:new();

	-- create render target with Paint event
	local renderTarget = ParaScene.GetObject("<CRenderTarget>"..self.filename);
	if(not renderTarget:IsValid()) then
		renderTarget = ParaScene.CreateObject("CRenderTarget", self.filename, 0, 0, 0);
		ParaScene.Attach(renderTarget);
	end
	self.renderTarget = renderTarget;

	self:SetRenderTargetSize(width, height)
	renderTarget:SetField("Dirty", false);
	renderTarget:SetField("IsRenderTarget", true);
	renderTarget:SetField("EnableActiveRendering", true);
	renderTarget:SetField("IsPersistentRenderTarget", true);
	self.textureAsset = renderTarget:GetPrimaryAsset(); -- touch to create the texture asset.
	renderTarget:SetScript("On_Paint", function()
		self:OnPaint(self.painter);
	end)
	
	return self;
end

function RenderTarget:SetRenderTargetSize(width, height)
	self.width = width or 256;
	self.height = height or 256;
	if(self.renderTarget) then
		self.renderTarget:SetField("RenderTargetSize", {self.width, self.height});
	end
end

function RenderTarget:EnableActiveRendering(bValue)
	if(self.renderTarget) then
		self.renderTarget:SetField("EnableActiveRendering", bValue == true);
	end
end

function RenderTarget:SetPersistentRenderTarget(bValue)
	if(self.renderTarget) then
		self.renderTarget:SetField("IsPersistentRenderTarget", bValue == true);
	end
end

-- ParaUIObject can set with this method. 
-- _parent:SetBGImage(rt:GetTexture())
function RenderTarget:GetTexture()
	if(self.renderTarget) then
		self.renderTarget:GetPrimaryAsset()
	end
end

-- one can also use a virtual filename to like any other disk file texture. 
-- this is usually "_miniscenegraph_"..self.filename, one can assume this name in the scene to display the render target.
function RenderTarget:GetTextureFilename()
	if(self.renderTarget) then
		self.renderTarget:GetPrimaryAsset():GetKeyName();
	end
end

-- TODO: not implemented yet
-- @param data: a string of "data:image/png;base64,"..base64ImageData. 
-- Supported format is "png|jpg"
function RenderTarget:LoadImageFromString(data, fromX, toX, fromY, toY)
	if(self.renderTarget) then
		self.renderTarget:SetField("run", string.format("paintrect %d %d %d %d %s", fromX or 0, toX or self.width, fromY or 0, toY or self.height, data));
	end
end