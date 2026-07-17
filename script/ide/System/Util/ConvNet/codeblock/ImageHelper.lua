--[[
Title: image helper
Author(s): LiXizhi
Date: 2023/8/30
Desc: we can display up to 10 images
use the lib:
------------------------------------------------------------
-- create from image 
local input = ConvNet.ImageHelper.CreateVolFromImageFile(imgFilename, width, height, depth);
ConvNet.ImageHelper.ShowVol(input, imgFilename, index)

-- create from image data
local input = ConvNet.ImageHelper.CreateVolFromImageData({width=2, height=2, data = {255,0,0,0, 255,255,255,0, 255,0,255,0, 255,255,255,0}})
ConvNet.ImageHelper.ShowVol(input, "imageData", 4)

-- show live camera capture at given interval
ConvNet.ImageHelper.ShowCamera(0.2)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Encoding/crc32.lua");
NPL.load("(gl)script/ide/System/Util/ImageProc/Image.lua");
local Image = commonlib.gettable("System.Util.ImageProc.Image");
local Encoding = commonlib.gettable("System.Encoding");
local ImageHelper = gettable("ConvNet.ImageHelper");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Color = commonlib.gettable("System.Core.Color");

ImageHelper.images = {};
ImageHelper.maxImageCount = 10;
ImageHelper.isShowCamera = false;

-- @param bCache: if true, we will cache the image data in memory
-- @return {data, width, height, filename}
function ImageHelper.GetImageData(filename, bCache, width, height)
    local img = ImageHelper.images[filename]
    if(img) then
        return img;
    end
    local data = {};
    img = {data = data};
    filename = Files.GetWorldFilePath(filename)
    if(filename) then 
        local file = ParaIO.open(filename, "image");
        if(file:IsValid()) then
            local ver = file:ReadInt();
            img.width = file:ReadInt();
            img.height = file:ReadInt();
            local bytesPerPixel = file:ReadInt();
            img.filename = filename;
            
            local pixel = {}
            if(not width) then
                for y = 1, img.height do
                    for x = 1, img.width do
                        -- array of rgb
                        pixel = file:ReadBytes(bytesPerPixel, pixel);
                        data[#data + 1] = pixel[1] or 0;
                        data[#data + 1] = pixel[2] or 0;
                        data[#data + 1] = pixel[3] or 0;
                    end
                end
            else
                for y = 1, height do
                    for x = 1, width do
                        local xx = math.floor((x-1) / width * img.width)
                        local yy = math.floor((y-1) / height * img.height)
                        local ix = (img.width * yy + xx) * bytesPerPixel + 16;
                        
                        file:seek(ix);
                        pixel = file:ReadBytes(bytesPerPixel, pixel);
                        data[#data + 1] = pixel[1] or 0;
                        data[#data + 1] = pixel[2] or 0;
                        data[#data + 1] = pixel[3] or 0;
                    end
                end
                img.width, img.height = width, height
            end
            file:close();
            if(bCache) then
                ImageHelper.images[img.filename] = img;
            end
            return img;
        else
            log("warn: failed to open file: "..filename)
        end
    end
end

-- @param imageData: {width, height, data}
function ImageHelper.CreateVolFromImageData(imageData, width, height, depth)
    if(imageData and imageData.data) then
        local p = imageData.data
        depth = depth or 1;
        width = width or imageData.width or 24
        height = height or imageData.height or width;
        -- fetch the appropriate training image and reshape into a Vol
        local vol = ConvNet.Vol:new():Init(width, height, depth, 0);
        if(depth == 1) then
            if(width == imageData.width) then
                local bytesPerPixel = (#p == height*width*3) and 3 or 4;
                -- r,g,b,r,g,b
                for y = 1, height do
                    for x = 1, width do
                        local ix = ((width*(y-1))+(x-1))*bytesPerPixel + 1;
                        --local h, s, l = Color.rgb2hsl(p[ix], p[ix+1], p[ix+2])
                        -- grey scale image
                        vol:set(x, y, 1, (p[ix]+p[ix+1]+p[ix+2])/3/255)
                    end
                end
            else
                local bytesPerPixel = (#p == height*width*3) and 3 or 4;
                for y = 1, height do
                    for x = 1, width do
                        local xx = math.floor((x-1) / width * imageData.width)
                        local yy = math.floor((y-1) / height * imageData.height)
                        local ix = (imageData.width * yy + xx) * bytesPerPixel + 1;
                        vol:set(x, y, 1, (p[ix]+p[ix+1]+p[ix+2])/3/255)
                    end
                end
            end
            return vol
        end
    end
end

-- @param imageData: {width, height, data}
function ImageHelper.CreateVolFromImageData_RGB(imageData, width, height)
    if(imageData and imageData.data) then
        width = width or imageData.width or 24
        height = height or imageData.height or width;
        
        local image = Image:new():Init(imageData.width or width, imageData.height or height, imageData.data);
        if (width ~= imageData.width) then image:Resize(width, height) end
        local data = image.data;
        
        -- fetch the appropriate training image and reshape into a Vol
        local vol = ConvNet.Vol:new():Init(width, height, 3, 0);
        -- r,g,b,r,g,b
        for y = 1, height do
            for x = 1, width do
                local ix = ((width * (y - 1)) + (x - 1)) * 3;
                vol:set(x, y, 1, data[ix + 1] / 255);
                vol:set(x, y, 2, data[ix + 2] / 255);
                vol:set(x, y, 3, data[ix + 3] / 255);
            end
        end
        return vol
    end
end

-- @param imageData: {width, height, data}
function ImageHelper.CreateVolFromImageData_Sobel(imageData, width, height, depth)
    if(imageData and imageData.data) then
        depth = depth or 1;
        width = width or imageData.width or 24
        height = height or imageData.height or width;
        
        local image = Image:new():Init(imageData.width or width, imageData.height or height, imageData.data);
        if (width ~= imageData.width) then image:Resize(width, height) end
        image:Sobel();
        local p = image.data;
        
        -- fetch the appropriate training image and reshape into a Vol
        local vol = ConvNet.Vol:new():Init(width, height, depth, 0);
        if(depth == 1) then
            local bytesPerPixel = (#p == height*width*3) and 3 or 4;
            -- r,g,b,r,g,b
            for y = 1, height do
                for x = 1, width do
                    local ix = ((width*(y-1))+(x-1))*bytesPerPixel + 1;
                    --local h, s, l = Color.rgb2hsl(p[ix], p[ix+1], p[ix+2])
                    -- grey scale image
                    vol:set(x, y, 1, (p[ix]+p[ix+1]+p[ix+2])/3/255)
                end
            end
            return vol
        end
    end
end

-- @param sampleInterval: default to one vol every 1000ms
function ImageHelper.CreateVolsFromMovieData(bx, by, bz, sampleInterval, width, height)
    local entity = getBlockEntity(bx, by, bz)
    if(entity and entity.GetMovieClipLength) then
        local totalLength = math.floor(entity:GetMovieClipLength() * 1000);
        sampleInterval = sampleInterval or 1000
        local vols = {}
        for time = 0, totalLength, sampleInterval do
            vols[#vols+1] = ImageHelper.CreateVolFromSingleFrameMovieData(bx, by, bz, time, width, height)
        end
        return vols
    end
end

-- @param data: array of {key, value} pairs are supported. and value is either number or number array. 
-- @param bNormalize: if true, normalize from [-1, 1] to [0, 1]
function ImageHelper.CreateVolFromTable(data, width, height, bNormalize)
    local vol = ConvNet.Vol:new():Init(width, height, 1, 0);
    
    local lastValueCount = {};
    local function setValue_(x, y, value)
        value = bNormalize and (value / 2 + 0.5) or value
        
        local lastVCount = lastValueCount[y * width + x]
        if(lastVCount) then
            value = (value + vol:get(x, y, 1)*lastVCount) / (lastVCount + 1);
        end
        lastValueCount[y * width + x] = (lastVCountor or 0) + 1;
        vol:set(x, y, 1, value)
    end
    for _, item in ipairs(data) do
        local name, value = item[1], item[2]
        local posValue = System.Encoding.crc32(name)
        posValue = posValue % (width * height)
        local y = math.floor(posValue / width) + 1
        local x = posValue % width + 1
        if type(value) == "number" then
            setValue_(x, y, value)
            vol:set(x, y, 1, bNormalize and (value / 2 + 0.5) or value)
        elseif type(value) == "table" then
            for i, v in ipairs(value) do
                setValue_((x+i-2) % width + 1, y, v)
            end
        end
    end
    return vol;
end

-- convert from a single snapshot of bone poses in a movie block to vol of width and height
-- @param bx, by, bz: movie block position
-- @param time: default to 0, in ms seconds.
function ImageHelper.CreateVolFromSingleFrameMovieData(bx, by, bz, time, width, height)
    local entity = getBlockEntity(bx, by, bz)
    if(entity and entity.GetFirstActorStack) then
        local itemStack = entity:GetFirstActorStack()
        if(itemStack and itemStack.serverdata and itemStack.serverdata.timeseries) then
            time = time or 0;
            local timeseries = itemStack.serverdata.timeseries;
            local data = {}
            if(timeseries.anim) then
                local anim = commonlib.AnimBlock:new(timeseries.anim)
                local animId = anim:getValue(1, time)
                data[#data+1] = {"anim", (animId%256) / 256} -- normalize value
            end
            if(timeseries.bones) then
                for name, value in pairs(timeseries.bones) do
                    if(type(value) == "table") then
                        local v = commonlib.AnimBlock:new(value):getValue(1, time);
                        data[#data+1] = {name, {mathlib.Quaternion.ToEulerAngles(v)}}
                    end
                end
            end
            local vol = ImageHelper.CreateVolFromTable(data, width, height, true)
            return vol;
        end
    end
end

function ImageHelper.CreateVolFromImageFile(filename, width, height, depth)
    local img = ImageHelper.GetImageData(filename, false, width, height)
    if(img) then
        return ImageHelper.CreateVolFromImageData(img, width, height, depth)
        -- return ImageHelper.CreateVolFromImageData_Sobel(img, width, height, depth)
    end

end

-- @param interval: default to 0.3 second
-- @param width, height: default to 32, 32. 
-- @param cameraImageCallback: function(vol) end, if nil, default to ImageHelper.ShowVol
function ImageHelper.ShowCamera(interval, width, height, cameraImageCallback)
    interval = interval or 0.3
    width = width or 32
    height = height or 32
    cmd("/capture video -x 10 -y 200 -width 128 -height 128")
    ImageHelper.isShowCamera = true
    ImageHelper.cameraWidth, ImageHelper.cameraHeight = width, height
    ImageHelper.cameraImageCallback = cameraImageCallback or ImageHelper.ShowVol
    
    run(function()
        while (ImageHelper.isShowCamera) do
            cmd("/capture videoimage -format raw -event OnVideoImageCaptured")
            wait(interval)
        end
    end)
end

function ImageHelper.ShowObjectDetectCamera(cameraImageCallback)
    interval = interval or 0.3
    cmd("/capture video -x 10 -y 200 -width 128 -height 128")
    ImageHelper.isShowCamera = true
    ImageHelper.cameraImageCallback = cameraImageCallback or ImageHelper.ShowVol
    
    run(function()
        while (ImageHelper.isShowCamera) do
            cmd("/capture videoimage -format raw -event OnVideoImageObjectDetectCaptured")
            wait(interval)
        end
    end)
end

registerStopEvent(function()
    ImageHelper.HideCamera()
end)

function ImageHelper.HideCamera()
    ImageHelper.isShowCamera = false;
    cmd("/capture video stop")
end

function ImageHelper.FlipImageVolHorizontally(vol)
    local ix = 1; 
    local count = vol.sx * vol.sy;
    local w = vol.w;
    for y = 1, math.floor(vol.sy/2) do 
        for x = 1, vol.sx do 
            local ix2 = count - ix - (vol.sx - 2*x)
            w[ix], w[ix2] = w[ix2], w[ix]
            ix = ix + 1; 
        end 
    end 
end

local isCapturingVideoImage;
registerBroadcastEvent("OnVideoImageCaptured", function(msg)
    if(type(msg) == "table") then
        if(isCapturingVideoImage) then
            return
        end
        isCapturingVideoImage = true;
        local vol = ImageHelper.CreateVolFromImageData(msg, ImageHelper.cameraWidth, ImageHelper.cameraHeight, 1)
        ImageHelper.FlipImageVolHorizontally(vol)
        if(ImageHelper.cameraImageCallback and vol) then
            ImageHelper.cameraImageCallback(vol)
        end
        isCapturingVideoImage = false;
    end
end)

registerBroadcastEvent("OnVideoImageObjectDetectCaptured", function(msg)
    if(type(msg) == "table") then
        if(isCapturingVideoImage) then
            return
        end
        isCapturingVideoImage = true;
        local image = Image:new():Init(msg.width, msg.height, msg.data);
        image:VerticalFlip();
        if(ImageHelper.cameraImageCallback) then
            ImageHelper.cameraImageCallback(image)
        end
        isCapturingVideoImage = false;
    end
end)
local wnds = {}

-- @param vol: image volume or text to display
-- @param name: name string    
-- @param showPos: [1-9] image position, default to 1.
function ImageHelper.ShowVol(vol, name, showPos)
    showPos = (((showPos or 1) - 1) % ImageHelper.maxImageCount) + 1;
    name = name or "";
    if(vol and showPos <= ImageHelper.maxImageCount) then
        local wnd = wnds[showPos]
        local size = 128;
        if(not wnd) then
            wnd = window([[]], "_lt", 10 + size*(showPos-1), 10, size, size);
            wnds[showPos] = wnd;
        end
        local ctx = wnd:getContext();
        
        if(type(vol) == "table") then
            ctx.strokeStyle = "#ff0000"
            ctx.lineWidth = 2
            ctx.font="System;12;"
            
            local width, height = vol.sx, vol.sy;
        
            if(wnd.lastImageWidth ~= width or wnd.lastImageName~=name) then
                wnd.lastImageWidth = width;
                wnd.lastImageName = name;
                ctx.fillStyle = "#000000"
                ctx:fillRect(0,0,ctx:getWidth(),ctx:getHeight())
            end
            
            local scale = math.max(1, math.floor(size/height))
            local count = 0;
            for y = 1, math.min(size, height) do
                for x = 1, math.min(size, width) do
                    local v = vol:get(x, height-y+1, 1)
                    local r, g, b
                    if(v < 0) then
                        if(v < -1) then
                            v = -1;
                        end
                        r, g, b = -v, 0, 1 -- show blue color for negative value
                    else
                        if(v > 1) then
                            v = 1
                        end
                        r, g, b = v, v, v;
                    end
                    ctx.fillStyle = Color.RGBAfloat_TO_ColorStr(r,g,b);
                    ctx:fillRect((x-1)*scale, (y-1)*scale, scale, scale)
                    count = count + 1;
                    if(count%1600 == 0) then
                        wait(0.01)
                    end
                end
            end
            ctx.fillStyle = "#ffffff"
            name = name:match("[^/\\]+/?$")
            -- name = name:sub(math.max(1, #name - 18), -1)
            ctx:fillText(name, 2, ctx:getHeight() - 15)
        else
            ctx.fillStyle = "#000000"
            ctx:fillRect(0,0,40,15)
            vol = tostring(vol):sub(1, 5)
            ctx.fillStyle = "#ffffff"
            ctx:fillText(tostring(vol), 2, 1)
        end
    end
end

-- hide and close all shown images
function ImageHelper.CloseAll()
    for _, wnd in pairs(wnds) do
        wnd:CloseWindow();
    end
    wnds = {};
end