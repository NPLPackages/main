--[[
Title: RGB Image in Memory Table
Author(s): LiXizhi
Date: 2024/2/8
Desc: RGB image processing in Memory Table. It provide several LoadXXX function to load image from different sources.
It also provide several image processing functions such as Resize, RGBToGreyScale, GaussianBlur, etc.
Show function will create a window to display the image usually for debugging purpose.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ImageProc/Image.lua");
local Image = commonlib.gettable("System.Util.ImageProc.Image")
-- local img = Image:new({width=16, height=16, data = {r,g,b,...}})
-- local img = Image:new():Init(width, height)
local img = Image:new():LoadFromRGBString("#ff0000#00ff00#0000ff#000000", 2,2);
img:LoadFromImageData({width=2, height=2, data={255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0}})
img:Resize(16,16)
img:Show()
img:GaussianBlur()
img:Show("blur")
img:RGBToGreyScale()
img:Show("grey")
img:VerticalFlip()
img:Show("vflip")
img:HorizontalFlip()
img:Show("hflip")
img:Transpose()
img:Show("transpose")
img:Sobel()
img:Show("sobel")
img:LoadFromFile("Texture/checkbox.png")
img:Rotate(30)
img:Show("diskfile")
img:RGBToGreyScale():Convolve(Image:new():Gaussian1D(3))
img:Show("gradientX")
-- img:SaveToFile("temp/test.png")
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Assets/DynamicTexture.lua");
NPL.load("(gl)script/ide/System/Scene/Assets/ImageFile.lua");
local ImageFile = commonlib.gettable("System.Scene.Assets.ImageFile");
local DynamicTexture = commonlib.gettable("System.Scene.Assets.DynamicTexture");
local Image = commonlib.inherit(nil, commonlib.gettable("System.Util.ImageProc.Image"));

Image._pages = {};

function Image:ctor()
end

-- @param width, height: the width and height of the image.
-- @param data: {r,g,b,...}
function Image:Init(width, height, data)
	self.width = width or 1;
	self.height = height or 1;
	if(not data) then
		-- init as black image
		data = {};
		for i = 1, self.width*self.height*3 do
			data[i] = 0;
		end
	end

	if (#data == self.width*self.height*4) then
		local rgb = {};
		local dst_index = 0;
		local src_index = 0;
		for i = 1, self.width * self.height do
			rgb[dst_index + 1] = data[src_index + 1];
			rgb[dst_index + 2] = data[src_index + 2];
			rgb[dst_index + 3] = data[src_index + 3];
			dst_index = dst_index + 3;
			src_index = src_index + 4;
		end
		data = rgb;
	end

	self.data = data;
	return self;
end

function Image:Clone()
	local img = Image:new();
	local dst_data = {};
	local src_data = self.data;
	img.width = self.width;
	img.height = self.height;
	img.data = dst_data;

	local data_size = #src_data;
	for i = 1, data_size do
		dst_data[i] = src_data[i];
	end
	return img;
end

-- save to disk file
function Image:SaveToFile(filename)
	local texture = DynamicTexture:new():Init("_texture_TempFile", self.width, self.height);
	texture:LoadImageFromString(self:ToColorRGBString(), self.width, self.height);
	texture:SaveToFile(filename)
end

-- @param filename: the image file name
function Image:LoadFromFile(filename)
	local file = ImageFile.open(filename);
	if(file:IsValid()) then
		local img = file:GetImageData();
		self:LoadFromImageData(img);
		file:close();
	end
	return self;
end

-- @param img: {width=16, height=16, data = {r,g,b,...}}
function Image:LoadFromImageData(img)
	if(img) then
		self.width = img.width or self.width
		self.height = img.height or self.height
		self.data = img.data or self.data
	end
	return self;
end

--@param texture: a DynamicTexture object
function Image:LoadFromDynamicTexture(texture)
	self.texture = texture;
	local img = texture:GetImageData(nil, nil, "rgb");
	self:LoadFromImageData(img);
	return self;
end

-- @param str: "#ff0000#00ff00..."
function Image:LoadFromRGBString(str, width, height)
	self.width = width
	self.height = height
	local data = {}
	local i = 1
	for r, g, b in string.gmatch(str, "#(%x%x)(%x%x)(%x%x)") do
		data[i] = tonumber(r, 16)
		data[i+1] = tonumber(g, 16)
		data[i+2] = tonumber(b, 16)
		i = i + 3
	end
	self.data = data;
	return self;
end


-- using the standard formula for luminance
-- the coefficients (0.299, 0.587, 0.114) are used to account for human perception, as we are more sensitive to green and less sensitive to blue.
function Image:RGBToGreyScale()
	local data = self.data;
	local w = self.width;
	local h = self.height;
	for y = 1, h do
		for x = 1, w do
			local idx = (y-1)*w*3 + (x-1)*3 + 1;
			local r, g, b = data[idx], data[idx+1], data[idx+2];
			local grey = math.floor(r*0.299 + g*0.587 + b*0.114);
			data[idx] = grey;
			data[idx+1] = grey;
			data[idx+2] = grey;
		end
	end
	return self;
end

function Image:getPixel(x, y)
	local idx = (y-1)*self.width*3 + (x-1)*3 + 1;
	return self.data[idx], self.data[idx+1], self.data[idx+2];
end

-- @param r,g,b: 0-255
function Image:setPixel(x,y, r, g, b)
	local idx = (y-1)*self.width*3 + (x-1)*3 + 1;
	self.data[idx] = r;
	self.data[idx+1] = g;
	self.data[idx+2] = b;
end

function Image:drawBox(cx, cy, length, r,g, b)
	local x1 = math.floor(math.max(1, cx - length));
	local x2 = math.floor(math.min(self.width, cx + length));
	local y1 = math.floor(math.max(1, cy - length));
	local y2 = math.floor(math.min(self.height, cy + length));
	for x = x1, x2 do
		self:setPixel(x, y1, r,g,b);
		self:setPixel(x, y2, r,g,b);
	end
	for y = y1, y2 do
		self:setPixel(x1, y, r,g,b);
		self:setPixel(x2, y, r,g,b);
	end
end

function Image:drawRectangle(x, y, w, h, r,g, b)
	local x1 = math.floor(math.max(1, x));
	local x2 = math.floor(math.min(self.width, x + w));
	local y1 = math.floor(math.max(1, y));
	local y2 = math.floor(math.min(self.height, y + h));
	for x = x1, x2 do
		for y = y1, y2 do
			self:setPixel(x, y, r,g,b);
			self:setPixel(x, y, r,g,b);
		end
	end
end

function Image:DrawQRCode(size)
	size = size or math.floor(self.width * 20 / 100); 
	local unit_size = math.max(1, math.ceil(size / 9)); -- 1:1:3:1:1 = 7
	size = size + math.floor((unit_size * 9 - size) / 2);
	local x, y = 1, 1;  -- left top
	self:drawRectangle(x, y, size, size, 0xff, 0xff, 0xff); -- fill white
	self:drawRectangle(x + unit_size * 1, y + unit_size * 1, size - unit_size * 2, size - unit_size * 2, 0x00, 0x00, 0x00); -- fill black
	self:drawRectangle(x + unit_size * 2, y + unit_size * 2, size - unit_size * 4, size - unit_size * 4, 0xff, 0xff, 0xff); -- fill white
	self:drawRectangle(x + unit_size * 3, y + unit_size * 3, size - unit_size * 6, size - unit_size * 6, 0x00, 0x00, 0x00); -- fill black
	
	x, y = self.width - size, 0;  -- right top
	self:drawRectangle(x, y, size, size, 0xff, 0xff, 0xff); -- fill white
	self:drawRectangle(x + unit_size * 1, y + unit_size * 1, size - unit_size * 2, size - unit_size * 2, 0x00, 0x00, 0x00); -- fill black
	self:drawRectangle(x + unit_size * 2, y + unit_size * 2, size - unit_size * 4, size - unit_size * 4, 0xff, 0xff, 0xff); -- fill white
	self:drawRectangle(x + unit_size * 3, y + unit_size * 3, size - unit_size * 6, size - unit_size * 6, 0x00, 0x00, 0x00); -- fill black
	
	x, y = 0, self.height - size; -- left bottom
	self:drawRectangle(x, y, size, size, 0xff, 0xff, 0xff); -- fill white
	self:drawRectangle(x + unit_size * 1, y + unit_size * 1, size - unit_size * 2, size - unit_size * 2, 0x00, 0x00, 0x00); -- fill black
	self:drawRectangle(x + unit_size * 2, y + unit_size * 2, size - unit_size * 4, size - unit_size * 4, 0xff, 0xff, 0xff); -- fill white
	self:drawRectangle(x + unit_size * 3, y + unit_size * 3, size - unit_size * 6, size - unit_size * 6, 0x00, 0x00, 0x00); -- fill black
	
	x, y = self.width - size, self.height - size; -- right bottom
	self:drawRectangle(x, y, size, size, 0xff, 0xff, 0xff); -- fill white
	self:drawRectangle(x + unit_size * 1, y + unit_size * 1, size - unit_size * 2, size - unit_size * 2, 0x00, 0x00, 0x00); -- fill black
	self:drawRectangle(x + unit_size * 2, y + unit_size * 2, size - unit_size * 4, size - unit_size * 4, 0xff, 0xff, 0xff); -- fill white
	self:drawRectangle(x + unit_size * 3, y + unit_size * 3, size - unit_size * 6, size - unit_size * 6, 0x00, 0x00, 0x00); -- fill black
end

function Image:HorizontalFlip()
	local data = self.data;
	local w = self.width;
	local h = self.height;
	for y = 1, h do
		for x = 1, math.floor(w/2) do
			local idx = (y-1)*w*3 + (x-1)*3 + 1;
			local idx2 = (y-1)*w*3 + (w-x)*3 + 1;
			data[idx], data[idx2] = data[idx2], data[idx];
			data[idx+1], data[idx2+1] = data[idx2+1], data[idx+1];
			data[idx+2], data[idx2+2] = data[idx2+2], data[idx+2];
		end
	end
	return self;
end

function Image:VerticalFlip()
	local data = self.data;
	local w = self.width;
	local h = self.height;
	for y = 1, math.floor(h/2) do
		for x = 1, w do
			local idx = (y-1)*w*3 + (x-1)*3 + 1;
			local idx2 = (h-y)*w*3 + (x-1)*3 + 1;
			data[idx], data[idx2] = data[idx2], data[idx];
			data[idx+1], data[idx2+1] = data[idx2+1], data[idx+1];
			data[idx+2], data[idx2+2] = data[idx2+2], data[idx+2];
		end
	end
	return self;
end

-- apply a Gaussian blur to the image with 5*5 kernel
-- @param sigma: default to 1.4
function Image:GaussianBlur(sigma)
	local w = self.width
	local h = self.height
	local data = self.data
	sigma = sigma or 1.4
	local sigma2 = 2*sigma*sigma
	local sqrt2pi = math.sqrt(2*math.pi)
	local k = 1/(sigma2*sqrt2pi)
	local kernel = {}
	local sum = 0
	for i = 1, 5 do
		local x = i - 3
		kernel[i] = k * math.exp(-x*x/sigma2)
		sum = sum + kernel[i]
	end
	for i = 1, 5 do
		kernel[i] = kernel[i]/sum
	end
	local temp = {}
	for y = 1, h do
		for x = 1, w do
			local idx = (y-1)*w*3 + (x-1)*3 + 1
			local r, g, b = 0, 0, 0
			for i = 1, 5 do
				local x1 = math.max(1, math.min(w, x-3+i))
				local idx1 = (y-1)*w*3 + (x1-1)*3 + 1
				r = r + data[idx1]*kernel[i]
				g = g + data[idx1+1]*kernel[i]
				b = b + data[idx1+2]*kernel[i]
			end
			temp[idx] = r
			temp[idx+1] = g
			temp[idx+2] = b
		end
	end
	for y = 1, h do
		for x = 1, w do
			local idx = (y-1)*w*3 + (x-1)*3 + 1
			local r, g, b = 0, 0, 0
			for i = 1, 5 do
				local y1 = math.max(1, math.min(h, y-3+i))
				local idx1 = (y1-1)*w*3 + (x-1)*3 + 1
				r = r + temp[idx1]*kernel[i]
				g = g + temp[idx1+1]*kernel[i]
				b = b + temp[idx1+2]*kernel[i]
			end
			data[idx] = r
			data[idx+1] = g
			data[idx+2] = b
		end
	end
	return self;
end

-- resize the image
function Image:Resize(width, height)
	local w = self.width
	local h = self.height
	local data = self.data
	local data2 = {}
	local x_ratio = w/width
	local y_ratio = h/height
	local px, py = 0, 0
	for i = 0, height-1 do
		for j = 0, width-1 do
			px = math.floor(j*x_ratio)
			py = math.floor(i*y_ratio)
			local idx = py*w*3 + px*3 + 1
			data2[#data2+1] = data[idx]
			data2[#data2+1] = data[idx+1]
			data2[#data2+1] = data[idx+2]
		end
	end
	self.width = width
	self.height = height
	self.data = data2
	return self;
end

-- channel = 1 R 2 G 3 B or (R + G + B) / 3
function Image:Gray(channel)
	local data = self.data;
	local width = self.width;
	local height = self.height;
	local gray_data = {};
	channel = (channel == 1 or channel == 2 or channel == 3) and channel or nil;
	for y = 0, height - 1 do
		for x = 0, width - 1 do
			local dst_index = y * width + x;
			local src_index = dst_index * 3;
			if (not channel) then
				gray_data[dst_index + 1] = (data[src_index + 1] + data[src_index + 2] + data[src_index + 3]) / 3;
			else
				gray_data[dst_index + 1] = data[src_index + channel];
			end
		end
	end
	self.data = gray_data;
end

-- crop image of a given size, clamp if exceed the image size. 
function Image:SubImage(x, y, width, height)
	local image_width = self.width;
	local image_height = self.height;
	local image_data = self.data;
	local data = {};
	for j = 0, height - 1 do
		for i = 0, width - 1 do
			local ix = i + x - 1;
			local jy = j + y - 1;
			ix = ix > 0 and (ix >= image_width and (image_width - 1) or ix) or 0;
			jy = jy > 0 and (jy >= image_height and (image_height - 1) or jy) or 0;
			local idx = (jy * image_width + ix) * 3 + 1;
			data[#data+1] = image_data[idx];
			data[#data+1] = image_data[idx+1];
			data[#data+1] = image_data[idx+2];
		end
	end
	return Image:new():Init(width, height, data);
end

-- rotate image by given degree by a given point clockwise
-- color on the edge is used for pixels not inside the image. 
-- @param degree: [-180, 180]
-- @param cx, cy: default to center of the image
function Image:Rotate(degree, cx, cy)
	local w = self.width
	local h = self.height
	local data = self.data
	local data2 = {}
	local angle = math.rad(-degree)
	cx = cx or w/2
	cy = cy or h/2
	for y = 1, h do
		for x = 1, w do
			local dx = x - cx
			local dy = y - cy
			local x2 = math.floor(cx + dx * math.cos(angle) - dy * math.sin(angle))
			local y2 = math.floor(cy + dx * math.sin(angle) + dy * math.cos(angle))
			x2 = x2 >= 1 and (x2 <= w and x2 or w) or 1
			y2 = y2 >= 1 and (y2 <= h and y2 or h) or 1
			local idx = (y-1)*w*3 + (x-1)*3 + 1
			local idx2 = (y2-1)*w*3 + (x2-1)*3 + 1
			data2[idx] = data[idx2]
			data2[idx+1] = data[idx2+1]
			data2[idx+2] = data[idx2+2]
		end
	end
	self.data = data2
	return self;
end

function Image:Transpose()
	local w = self.width
	local h = self.height
	local data = self.data
	local data2 = {}
	for y = 1, w do
		for x = 1, h do
			local idx = (y-1)*w*3 + (x-1)*3 + 1
			local idx2 = (x-1)*h*3 + (y-1)*3 + 1
			data2[idx2] = data[idx]
			data2[idx2+1] = data[idx+1]
			data2[idx2+2] = data[idx+2]
		end
	end
	self.width = h
	self.height = w
	self.data = data2
	return self;
end

-- create a kernel image of size * 1. rgb value is weighted by the gaussian function
function Image:Gaussian1D(size, sigma)
	sigma = sigma or 1.4
	local sigma2 = 2*sigma*sigma
	local sqrt2pi = math.sqrt(2*math.pi)
	local k = 1/(sigma2*sqrt2pi)
	local kernel = {}
	local sum = 0
	local dx =  math.floor(size/2) + 1
	for i = 1, size do
		local x = i - dx
		kernel[i] = k * math.exp(-x*x/sigma2)
		sum = sum + kernel[i]
	end
	for i = 1, size do
		kernel[i] = kernel[i]/sum
	end

	self.width = size;
	self.height = 1;
	local data = {}
	for i = 1, size do
		-- local weight = kernel[i] * 255
		local weight = kernel[i]
		data[i*3-2] = weight
		data[i*3-1] = weight
		data[i*3] = weight
	end
	self.data = data;
	return self;
end

-- apply a convolution kernel to the image
-- @param kernelImage: {width, height, data = {weightR, weightG, weihtB, ...}}
function Image:Convolve(kernelImage)
	local w = self.width
	local h = self.height
	local data = self.data
	local w2 = kernelImage.width
	local h2 = kernelImage.height
	local data2 = kernelImage.data
	local data3 = {}
	local k = 1
	local rx, ry = math.floor(w2/2) + 1, math.floor(h2/2) + 1
	for y = 1, h do
		for x = 1, w do
			local r, g, b = 0, 0, 0
			for y2 = 1, h2 do
				for x2 = 1, w2 do
					local x3 = x + x2 - rx
					local y3 = y + y2 - ry
					if(x3 >= 1 and x3 <= w and y3 >= 1 and y3 <= h) then
						local idx = (y3-1)*w*3 + (x3-1)*3 + 1
						local idx2 = (y2-1)*w2*3 + (x2-1)*3 + 1
						r = r + data[idx]*data2[idx2]
						g = g + data[idx+1]*data2[idx2+1]
						b = b + data[idx+2]*data2[idx2+2]
					end
				end
			end
			data3[k] = r
			data3[k+1] = g
			data3[k+2] = b
			k = k + 3
		end
	end
	self.data = data3
	return self;
end

-- generate edge image using sobel edge detection
function Image:Sobel()
	local sobel_v ={
	  -1.0, 0.0, 1.0,
	  -2.0, 0.0, 2.0,
	  -1.0, 0.0, 1.0
	};

	local sobel_h ={
	  -1.0, -2.0, -1.0,
	   0.0,  0.0,  0.0,
	  1.0, 2.0, 1.0
	};

	local pixels = {};
	local data = self.data;
	local width = self.width;
	local height = self.height;

	-- create greyscale first
	local i = #self.data
    while i > 0 do
        local b = data[i]
        local g = data[i-1]
        local r = data[i-2]
        pixels[i/3] = 0.3*r + 0.59*g + 0.11*b -- Luminocity weighted average.
        i = i - 3
    end
	local pixels2 = {}
	-- sobel gradient
	for i = 1, #pixels do
		-- loop our 3x3 kernels, build our kernel values
		local hSum = 0
		local vSum = 0
		for y = 0, 2 do
			for x = 0, 2 do
				local pixel = pixels[i + (width * (y-1)) + x-1] or 0
				local kernelAccessor = (x) * 3 + (y) + 1
				hSum = hSum + pixel * sobel_h[kernelAccessor]
				vSum = vSum + pixel * sobel_v[kernelAccessor]
			end
		end
		-- apply kernel evaluation to current pixel
		pixels2[i] = math.sqrt(hSum * hSum + vSum * vSum)
		-- pixels2[i] = math.abs((hSum + vSum) * 0.5)
	end

	-- assign pixels to r,g,b of self.data
	local i = #self.data
	while i > 0 do
		local grey = math.min(255, math.floor(pixels2[i/3]))
		self.data[i] = grey
		self.data[i-1] = grey
		self.data[i-2] = grey
		i = i - 3
	end
end	

-- "#ffff0000#ff0000ff#..."
function Image:ToColorRGBString()
	local w = self.width
	local h = self.height
	local data = self.data
	local o = {}
	for y = 1, h do
		for x = 1, w do
			local idx = (y-1)*w*3 + (x-1)*3 + 1
			local r, g, b = data[idx], data[idx+1], data[idx+2]
			o[#o+1] = string.format("#ff%02x%02x%02x", r, g, b)
		end
	end
	return table.concat(o);
end

-- create a named window and show the image
-- @param name: the name of the image. default to ""
function Image:Show(name, left, top)
	if(self.lastName ~= name) then
		self.texture = nil;
	end
	self.lastName = name;
	name = name or "";

	if(not left) then
		Image.defaultLeftTop = Image.defaultLeftTop or commonlib.ArrayMap:new();
		local value = Image.defaultLeftTop:get(name)
		if(not value) then
			value = Image.defaultLeftTop:size() + 1;
			Image.defaultLeftTop:add(name, value)
		end
		left = 32*((value % 10) + 1) + 64*(math.floor(value / 10) % 5);
		top = 32*((value % 10) + 1);
	end

	if(not self.texture) then
		local filename = format("_textureImage_%s", name or "")
		self.texture = DynamicTexture:new():Init(filename, self.width, self.height);
	end
	self.texture:LoadImageFromString(self:ToColorRGBString(), self.width, self.height);

	local params = {
        url = string.format("script/ide/System/Util/ImageProc/ImageWnd.html?filename=%s&width=%d&height=%d&name=%s", self.texture:GetTextureFilename(), self.width, self.height, name),
        name = "ImageProc.ImageShow"..(name or ""),
        isShowTitleBar = false,
        DestroyOnClose = true,
        bToggleShowHide = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = true,
        -- enable_esc_key = true,
        bShow = true,
        click_through = false,
        directPosition = true,
        align = "_lt",
        x = left or 10,
        y = top or 10,
        width = 260,
        height = 280
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end

function Image:Close()
	local _page = Image._pages[self.lastName];
	if(_page) then
		_page:CloseWindow();
		Image._pages[self.lastName] = nil;
	end
end

