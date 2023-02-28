--[[
Title: ConvNet Volume utilities
Author(s): LiXizhi
Date: 2022/8/20
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Vol_Util.lua");
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local Vol = commonlib.gettable("System.Util.ConvNet.Vol")
local v1 = ConvNet.img_to_vol("Texture/blocks/items/brush.png", true)
local v2 = ConvNet.augment(v1, 3, 10, 10)
echo(v2)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Vol.lua");
local Vol = commonlib.gettable("System.Util.ConvNet.Vol");
local ConvNet = commonlib.gettable("System.Util.ConvNet");

-- intended for use with data augmentation
-- @param V: volume
-- @param crop is the size of output
-- @param dx,dy are offset wrt incoming volume, of the shift
-- @param flipLeftRight is boolean on whether we also want to flip left<->right
function ConvNet.augment(V, crop, dx, dy, flipLeftRight)
    -- note assumes square outputs of size crop x crop
	dx = dx or ConvNet.randi(0,(V.sx - crop));
	dy = dy or ConvNet.randi(0,(V.sy - crop));
	local W;
	if(crop ~= V.sx or dx~=0 or dy~=0) then
		W = Vol:new():Init(crop, crop, V.depth, 0);
		for x = 1, crop do
			for y = 1, crop do
				if(not(x + dx<=0 or x + dx>V.sx or y + dy<=0 or y + dy>V.sy)) then
					for d = 1, V.depth do
						W:set(x, y, d, V:get(x + dx, y + dy, d)); -- copy data over
					end
				end
			end
		end
	else
		W = V;
	end

	if(flipLeftRight) then
		W2 = W:cloneAndZero();
		for x = 1, W.sx do
			for y = 1, W.sy do
				for d = 1, V.depth do
					W2:set(x, y, d, W:get(W.sx - x + 1, y, d));
				end
			end
		end
		W = W2;
	end
	return W;
end

-- @param img: filename or {data, width, height, }
-- @param convert_grayscale: true to convert to gray scale
-- returns a Vol of size (W, H, 3). 3 is for RGBA, or (W, H, 1) for grayscale
function ConvNet.img_to_vol(img, convert_grayscale)
	if(type(img) == "string") then
		local filename = img;
		local data = {};
		img = {data = data};
		local file = ParaIO.open(filename, "image");
		if(file:IsValid()) then
			local ver = file:ReadInt();
			img.width = file:ReadInt();
			img.height = file:ReadInt();
			local bytesPerPixel = file:ReadInt();
			local pixel = {}
			for y=1, img.height do
				for x=1, img.width do
					-- array of rgba
					pixel = file:ReadBytes(bytesPerPixel, pixel);
					local red = pixel[1] or 0;
					data[#data+1] = red;
					data[#data+1] = pixel[2] or red;
					data[#data+1] = pixel[3] or red;
				end
			end
			file:close();
		end
	end

	local p = img.data;
	local W = img.width;
	local H = img.height;
	local pv = {};
	for i=1, #p do
		-- normalize image pixels to [-0.5, 0.5]
		pv[#pv+1] = (p[i] / 255) - 0.5
	end

	x = Vol:new():Init(W, H, 3, 0);
	x.w = pv;
	if (convert_grayscale) then
		-- flatten into depth=1 array
		x1 = Vol:new():Init(W, H, 1, 0);
		for i = 1, W do
			for j = 1, H do
				x1:set(i, j, 1, x:get(i, j, 1));
			end
		end
		x = x1;
	end
	return x;
end

-- @param v: in range 0-1
local function GetColorData(v)
    v = math.floor(v*16)
    return v*256+v*16+v;
end

-- show volume as 3d blocks in the world at minX, minY, minZ block position. 
-- @param vols: can be vol or array of vols, multiple volumes are displayed along the x axis. 
-- @param depthSpacing: default to 4
function ConvNet.ShowVols(vols, minX, minY, minZ, depthSpacing)
	if(#vols == 0) then
		vols = {vols}
	end
	depthSpacing = depthSpacing or 4;
    for i = 1, #vols do
		local vol = vols[i]
		local offsetX = (i-1) * (vol.sx + depthSpacing);
		local x, y, z;
		for dx = 1, vol.sx do
			x = minX + dx-1 + offsetX
			for dy = 1, vol.sy do
				y = minY + vol.sy - dy
				for dz = 1, vol.depth do
					z = minZ + (dz-1) * depthSpacing
					local v = vol:get(dx, dy, dz)
					GameLogic.BlockEngine:SetBlock(x, y, z, 10, GetColorData(v))
				end
			end
		end
	end
end