--[[
Title: DynamicTexture
Author(s): LiXizhi@yeah.net
Date: 2024/2/3
Desc: We can turn any static texture entity into a dynamic texture that can be updated by calling LoadImageFromString.
Just init the texture filename with :Init(filename, width, height), and then call :LoadImageFromString(data, fromX, fromY, toX, toY) to update the texture.
The OnRender event is called whenever the texture is used in the scene (such as in the camera viewport).
The size of the texture will be changed to be equal to the one specified in LoadImageFromString
It will reuse the same dynamic texture if size are the same.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Assets/DynamicTexture.lua");
local DynamicTexture = commonlib.gettable("System.Scene.Assets.DynamicTexture");
local tex = DynamicTexture:new():Init("_textureDynamicDefault")
tex:Connect("OnRender", function()
	tex:LoadImageFromString("data:image/png;base64,xxxxx", 0, 0, 63, 63)
end)

-- example 2: secretly modify a texture
local tex = DynamicTexture:new():Init("Texture/checkbox.png")
local binImage = commonlib.Files.GetFileText("temp/test.png")
tex:LoadImageFromString("data:image/png;base64,"..System.Encoding.base64(binImage)) -- original image size
-- tex:LoadImageFromString("data:image/png;base64,"..System.Encoding.base64(binImage), 0, 0, 255, 255)
-- tex:GetTextureFilename(); -- such as "_textureDynamicDefault" which can be used like any disk texture filename
-- echo(tex:GetImageData());

-- example 2: load from raw ARGB pixels texture and save to file
local tex = DynamicTexture:new():Init("Texture/checkbox.png")
tex:LoadImageFromString("#ffff0000#ff00ff00#ff0000ff#ff000000", 2,2)
echo(tex:GetImageData(2,2, "rgb")) -- {width=2,height=2,data={255,0,0,0,255,0,0,0,255,0,0,0,},}
--tex:LoadFromFile("Texture/checkbox.png")
--tex:SaveToFile(ParaIO.GetWritablePath().."temp/test.png")
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/PainterContext.lua");
NPL.load("(gl)script/ide/System/Scene/Assets/ImageFile.lua");
local ImageFile = commonlib.gettable("System.Scene.Assets.ImageFile");
local PainterContext = commonlib.gettable("System.Core.PainterContext");
local DynamicTexture = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Scene.Assets.DynamicTexture"));

-- this is called when self:EnableActiveRendering(true), and when the texture is used in the scene.
DynamicTexture:Signal("OnRender")

function DynamicTexture:ctor()
	System.Core.Scene:MakeAutoDestory(self);

	self.m_ignore_hit = false;
end

function DynamicTexture:Destroy()
	DynamicTexture._super.Destroy(self);
	if(self.texture) then
		LOG.std(nil, "info", "DynamicTexture", "destroy %s", self.filename or "");
		self.texture:UnloadAsset();
		self.texture = nil;
	end
	self.textureAttr = nil
	self:KillTimer();
end

-- @param filename: default to "_textureDynamicDefault".  if it begins with "_texture", paracraft will not search from disk.
-- however, it can also be any valid filename like "Texture/whitedot.png", in which case, the texture may be first loaded as
-- a normal texture, but will be changed to dynamic textures when LoadImageFromString is called.
function DynamicTexture:Init(filename, width, height)
	self.filename = filename or "_textureDynamicDefault";
	self.width = width or 256;
	self.height = height or 256;
	-- dynamic texture always have surface type 11, which will not load from filename
	self.texture = ParaAsset.LoadTexture(filename, filename, 11);
	self.textureAttr = self.texture:GetAttributeObject();
	-- just ensure the same filename is used as static texture, we will change it to dynamic. 
	self.textureAttr:SetField("SurfaceType", 11);
	self:EnableActiveRendering(true)
	return self;
end

-- call this function to restore self.filename texture to normal static texture and will be reloaded from disk when it is later requested. 
function DynamicTexture:RestoreToStaticTexture()
	if(self.textureAttr) then
		self.textureAttr:SetField("SurfaceType", 1);
	end
end

function DynamicTexture:SetDynamicTextureSize(width, height)
	self.width = width or 256;
	self.height = height or 256;
end

-- ParaUIObject can set with this method. 
-- _parent:SetBGImage(tex:GetTexture())
function DynamicTexture:GetTexture()
	return self.texture
end

-- one can also use a virtual filename to like any other disk file texture. 
function DynamicTexture:GetTextureFilename()
	return self.filename;
end

function DynamicTexture:GetHitCount()
	if(self.textureAttr) then
		return self.textureAttr:GetField("HitCount", 0);
	end
	return 0;
end

function DynamicTexture:SetHitCount(count)
	if(self.textureAttr) then
		self.textureAttr:SetField("HitCount", count or 0);
	end
end

-- load from any local file path
function DynamicTexture:LoadFromFile(filename)
	local binImage = commonlib.Files.GetFileText(filename)
	if(binImage) then
		local fileType = "png"
		if(filename:match("%.jpg")) then
			fileType = "jpg"
		end
		self:LoadImageFromString(string.format("data:image/%s;base64,%s", fileType, System.Encoding.base64(binImage)))
	end
end

-- The size of the texture will be changed to be equal to the one specified in LoadImageFromString
-- It will reuse the same dynamic texture if size are the same.
-- @param data: a string of "data:image/png;base64,"..base64ImageData.  or "#ff0000#00ff00..." RGB values
-- @param fromX, fromY, toX, toY: inclusive coordinates. such as 0, 0, 63, 63.  
-- if toX, toY are nil, fromX, fromY are image width, height
-- if all 4 values are nil, the image original size is used.
-- specify 63, 0, 0, 63 to flip horizontally.
-- specify 0, 63, 63, 0 to flip vertically.
-- Supported format is "png|jpg"
function DynamicTexture:LoadImageFromString(data, fromX, fromY, toX, toY)
	if(not fromX) then
		fromX, fromY, toX, toY = 0,0,-1,-1
	elseif(not toX) then
		toX = fromX -1;
		toY = fromY -1;
		fromX, fromY = 0, 0
	end
	if(self.textureAttr) then
		fromX = fromX or 0;
		fromY = fromY or 0;
		toX = toX or (self.width - 1);
		toY = toY or (self.height - 1);
		self.width = math.max(toX+1, fromX+1);
		self.height = math.max(toY+1, fromY+1);
		self.textureAttr:SetField("LoadImageFromString", string.format("paintrect %d %d %d %d %s", fromX, fromY, toX, toY, data));
	end
end

-- this is slow, do it sparingly
-- @param width, height: sample at the given width and height. if nil, they will be same as the texture size.
-- @param colorMode: "rgb" or "DWORD" or "grey", default to "rgb". if "grey", value normalized to [0,1]
-- @return nil or img table of {width, height, data = {r,g,b,r,g,b,...}}
function DynamicTexture:GetImageData(width, height, colorMode)
	width = width or self.width;
	height = height or self.height;
	colorMode = colorMode or "rgb";
	local file = ImageFile.open(self.filename)
	if(file:IsValid()) then
		local img = file:GetImageData(width, height, colorMode);
		file:close();
		return img;
	end
end

-- save texture to file
-- @param filename: should be a writable path
function DynamicTexture:SaveToFile(filename)
	if(self.textureAttr) then
		self.textureAttr:SetField("SaveToFile", filename);
	end
end

-- "OnRender" will be called whenever this texture is used by other objects in the scene, such as in 3d scene or 2d UI. 
function DynamicTexture:EnableActiveRendering(bValue)
	if(bValue) then
		self:ChangeTimer(1/60, 1/60);
	else
		self:KillTimer();
	end
end

function DynamicTexture:SetIgnoreHit(bValue)
	self.m_ignore_hit = bValue;
end

function DynamicTexture:IsIgnoreHit()
	return self.m_ignore_hit;
end

function DynamicTexture:OnTick()
	if(self:IsIgnoreHit() or self:GetHitCount() > 0) then
		self:SetHitCount(0);
		self:OnRender(self.m_key);
	end
end

function DynamicTexture:SetKey(key)
	self.m_key = key
end