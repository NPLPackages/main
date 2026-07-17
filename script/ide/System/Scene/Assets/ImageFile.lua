--[[
Title: ImageFile
Author(s): LiXizhi@yeah.net
Date: 2024/2/3
Desc: It has identical interface as a file object(ParaIO.open), 
but it is used to open and read an image file.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Assets/ImageFile.lua");
local ImageFile = commonlib.gettable("System.Scene.Assets.ImageFile");
local file = ImageFile.open("_textureDynamicDefault")
if(file:IsValid()) then
	echo(file:GetImageData());
	echo(file:GetSubImageData(0,0,2,2));
	file:ShowImageData();

	file:close();
end
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Util/ImageProc/Image.lua");
local Image = commonlib.gettable("System.Util.ImageProc.Image")
local ImageFile = commonlib.inherit(nil, commonlib.gettable("System.Scene.Assets.ImageFile"));
local band = mathlib.bit.band;
local rshift = mathlib.bit.rshift;

function ImageFile:ctor()
end

-- this function maybe called multiple times
function ImageFile:Init(filename)
	self.filename = filename;
	local file = ParaIO.open(filename, "image");
	if(file and file:IsValid()) then
		self.file = file;
		local ver = file:ReadInt();
		self.width = file:ReadInt();
		self.height = file:ReadInt();
		self.bytesPerPixel = file:ReadInt();
	end
	return self;
end

function ImageFile:GetWidth()
	return self.width or 0;
end

function ImageFile:GetHeight()
	return self.height or 0;
end

function ImageFile:GetBytesPerPixel()
	return self.bytesPerPixel or 4;
end

function ImageFile:IsValid()
	return self.file and self.file:IsValid();
end

-- open an image file. and return the file object. one must call file:close() to close the file.
function ImageFile.open(filename)
	return ImageFile:new():Init(filename);
end

function ImageFile:close()
	if(self.file) then
		self.file:close();
		self.file = nil;
	end
end

-- @param imgData: {width, height, data = {r,g,b,r,g,b,...}}, if nil, this is the result of the last GetSubImageData or GetImageData call.
function ImageFile:ShowImageData(wndName, imgData)
	if(type(wndName) == "table") then
		imgData = wndName
		wndName = self.filename
	end
	imgData = imgData or self.img or self:GetImageData();
	if(imgData) then
		local img = Image:new():Init()
        img:LoadFromImageData(imgData)
		img:Show(wndName or self.filename);
	end
end

-- @param left, top, width, height: the sub image data to get. left,top is (0,0)
-- @param colorMode: "rgb", "rgba" or "DWORD" or "grey", default to "rgb". if "grey", value normalized to [0,1]
function ImageFile:GetSubImageData(left, top, width, height, colorMode)
	local file = self.file;
    if(file and left and width and ((left + width) <= self.width) and top and height and ((top + height) <= self.height)) then
		local img = self.img or {};
		self.img = img;
		local imgWidth = self.width
		local imgHeight = self.height
		img.data = img.data or {};
        local data = img.data
		bytesPerPixel = self.bytesPerPixel -- should always be 4
		file:seek(4*4); -- skip header
		
		local _ReadNumbers = ParaIO.ReadNumbers;
		local _ReadUInt = ParaIO._ReadUInt;
		ParaIO.SetCurrentFile(file);

        local count = 0;
		local color = colorMode or "rgb"

		local headerSize = 4*4;
		img.width = width;
		img.height = height;
		local _seek = ParaIO.seek;
		if(not _seek) then
			_seek = function(offset, whence)
				return file:seek(offset);
			end
		end
		for y=top, top + height - 1 do
			_seek(headerSize + (y*imgWidth + top)*bytesPerPixel);
			for x=left, left + width - 1 do
				if(color == "rgb") then
					local b, g, r = _ReadNumbers(4,1)
					data[count+1] = r;
					data[count+2] = g;
					data[count+3] = b;
					count = count + 3;
				elseif(color == "grey") then
					local b, g, r = _ReadNumbers(4,1)
					count = count + 1
					data[count] = math.floor((r+g+b) / 765);
				elseif(color == "rgba") then
					local b, g, r, a = _ReadNumbers(4,1)
					data[count+1] = r;
					data[count+2] = g;
					data[count+3] = b;
					data[count+4] = a;
					count = count + 4;
				else
					count = count + 1
					data[count] = _ReadUInt();
				end
			end
		end
		return img;
	end
end

-- this is slow, do it sparingly
-- @param width, height: sample at the given width and height. if nil, they will be same as the texture size.
-- @param colorMode: "rgb", "rgba" or "DWORD" or "grey", default to "rgb". if "grey", value normalized to [0,1]
-- @return nil or img table of {width, height, data = {r,g,b,r,g,b,...}}
function ImageFile:GetImageData(width, height, colorMode)
    local file = self.file;
    if(file) then
		local img = self.img or {};
		self.img = img;
		local imgWidth = self.width
		local imgHeight = self.height
		img.data = img.data or {};
        local data = img.data
		bytesPerPixel = self.bytesPerPixel -- should always be 4
		file:seek(4*4); -- skip header
		
		-- ReadInt is 2.5 times faster than ReadBytes and ParaIO.ReadUInt is 50% faster than file:ReadUInt()
		local _ReadNumbers = ParaIO.ReadNumbers;
		local _ReadUInt = ParaIO._ReadUInt;
		if(_ReadNumbers) then
			ParaIO.SetCurrentFile(file);
		else
			_ReadUInt = function()
				return file:ReadUInt();
			end
			_ReadNumbers = function()
				local color = file:ReadUInt();
				local r = band(rshift(color, 16), 0xff)
				local g = band(rshift(color, 8), 0xff);
				local b = band(color, 0xff);
				return b, g, r;
			end
		end
        local count = 0;
		local color = colorMode or "rgb"
		if(not width or not height or (width == imgWidth and height == imgHeight)) then
			img.width = imgWidth;
			img.height = imgHeight;
			if(color == "rgb") then
				for y=1, imgHeight do
					for x=1, imgWidth do
						-- array of rgba
						local b, g, r = _ReadNumbers(4,1)
						data[count+1] = r;
						data[count+2] = g;
						data[count+3] = b;
						count = count + 3;
					end
				end
			elseif(color == "grey") then
				for y=1, imgHeight do
					for x=1, imgWidth do
						local b, g, r = _ReadNumbers(4,1)
						count = count + 1
						data[count] = math.floor((r+g+b) / 765);
					end
				end
			elseif(color == "rgba") then
				for y=1, imgHeight do
					for x=1, imgWidth do
						-- array of rgba
						local b, g, r, a = _ReadNumbers(4,1)
						data[count+1] = r;
						data[count+2] = g;
						data[count+3] = b;
						data[count+4] = a;
						count = count + 4;
					end
				end
			else
				for y=1, imgHeight do
					for x=1, imgWidth do
						-- array of rgba
						count = count + 1
						data[count] = _ReadUInt();
					end
				end
			end
		else
			-- resize to width, height
			local headerSize = 4*4;
			img.width = width;
			img.height = height;
			local _seek = ParaIO.seek;
			if(not _seek) then
				_seek = function(offset, whence)
					return file:seek(offset);
				end
			end
			for y=1, height do
				for x=1, width do
					local xx = math.floor((x-1)*imgWidth/width);
					local yy = math.floor((y-1)*imgHeight/height);
					_seek(headerSize + (yy*imgWidth + xx)*bytesPerPixel);
					if(color == "rgb") then
						local b, g, r = _ReadNumbers(4,1)
						data[count+1] = r;
						data[count+2] = g;
						data[count+3] = b;
						count = count + 3;
					elseif(color == "grey") then
						local b, g, r = _ReadNumbers(4,1)
						count = count + 1
						data[count] = math.floor((r+g+b) / 765);
					elseif(color == "rgba") then
						local b, g, r, a = _ReadNumbers(4,1)
						data[count+1] = r;
						data[count+2] = g;
						data[count+3] = b;
						data[count+4] = a;
						count = count + 4;
					else
						count = count + 1
						data[count] = _ReadUInt();
					end
				end
			end
		end
		return img;
	end
end

function ImageFile:GetImageRGBData(callback)
	local width = self.width;
	local height = self.height;
    local file = self.file;

	if (not file) then return callback() end
	file:seek(4*4); -- skip header

	local data = {}
	local count = 0;
	local read_lines = function(line_size)
		local _ReadNumbers = ParaIO.ReadNumbers;
		if(_ReadNumbers) then
			ParaIO.SetCurrentFile(file);
		else
			_ReadNumbers = function()
				local color = file:ReadUInt();
				local r = band(rshift(color, 16), 0xff)
				local g = band(rshift(color, 8), 0xff);
				local b = band(color, 0xff);
				return b, g, r;
			end
		end

		for i = 1, line_size do
			for j = 1, width do
				local b, g, r = _ReadNumbers(4,1)
				data[count+1] = r;
				data[count+2] = g;
				data[count+3] = b;
				count = count + 3;
			end
		end
	end
	-- 尽量10帧读完
	local line_size_per_frame = math.floor(height / 10);
	local remain_line_size = height;
	line_size_per_frame = line_size_per_frame == 0 and height or line_size_per_frame;
	
	commonlib.TimerManager.SetInterval(function(timer)
		local line_size = line_size_per_frame > remain_line_size and remain_line_size or line_size_per_frame;
		read_lines(line_size);
		remain_line_size = remain_line_size - line_size;
		if (remain_line_size == 0) then
			callback(width, height, data);
			timer:Change();
		end
	end, 10);
end

function ImageFile:ResizeImage(filename, width, height, newFilename)
	return ParaMovie.ResizeImage(filename, width, height, newFilename)
end
