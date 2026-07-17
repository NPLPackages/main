--[[
NPL.load("(gl)script/ide/System/Util/ImageProc/ColorImage.lua");
local ColorImage = commonlib.gettable("System.Util.ImageProc.ColorImage")
]] 

-- ColorImage

NPL.load("(gl)script/ide/System/Util/ImageProc/Image.lua");
local Image = commonlib.gettable("System.Util.ImageProc.Image");
local WebCamera = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/WebCamera.lua");
local ColorImage = commonlib.inherit(nil, commonlib.gettable("System.Util.ImageProc.ColorImage"));

function ColorImage.IsRedColor(r, g, b) return (r - g) > 0x20 and (r - b) > 0x20 and (g < b and b - g or g - b) < 0x18; end

function ColorImage.GetColorImage(img, IsColor)
    local pixels, width, height = img.data, img.width, img.height;
    local scale = width > 64 and 64 / width or 1;
    local scale_width = width * scale;
    local scale_height = height * scale;
    local scale_size = scale_width * scale_height;
    local step_x = width / scale_width;
    local step_y = height / scale_height;
    local step_size = step_x * step_y;
    local min_x, min_y, max_x, max_y = scale_width, scale_height, 0, 0;

    for sy = 1, scale_height do
        for sx = 1, scale_width do
            local x = (sx - 1) * step_x;
            local y = (sy - 1) * step_y;
            local sum = 0;
            for j = 1, step_y do
                for i = 1, step_x do
                    local index = ((y + j - 1) * width + x + i - 1) * 3 + 1;
                    local r, g, b = pixels[index], pixels[index + 1], pixels[index + 2];
                    if IsColor(r, g, b) then sum = sum + 1; end
                end
            end
            if (sum > (step_size / 2)) then
                min_x = math.min(min_x, sx);
                min_y = math.min(min_y, sy);
                max_x = math.max(max_x, sx);
                max_y = math.max(max_y, sy);
            end
        end
    end
    local extend_size = 20;
    local x = math.max(math.floor(min_x / scale - extend_size / 2), 1);
    local y = math.max(math.floor(min_y / scale - extend_size / 2), 1);
    local r = math.min(math.floor(max_x / scale + extend_size / 2), width);
    local b = math.min(math.floor(max_y / scale + extend_size / 2), height);
    local w = r - x;
    local h = b - y;
    if (w < 1 or h < 1) then return nil end
    return img:SubImage(x, y, w, h);
end

function ColorImage.ScaleFill(img, fixed_width, fixed_height)
    if (not img) then return nil end

    local pixels, width, height = img.data, img.width, img.height;
    local fixed_pixels = {};
    local scale_x = fixed_width / width;
    local scale_y = fixed_height / height;
    local min_scale = scale_x < scale_y and scale_x or scale_y;
    local offset_x = math.floor((fixed_width / min_scale - width) / 2);
    local offset_y = math.floor((fixed_height / min_scale - height) / 2);
    for y = 1, fixed_height do
        for x = 1, fixed_width do
            local sx = math.floor(x / min_scale - offset_x);
            local sy = math.floor(y / min_scale - offset_y);
            local sindex = ((sy - 1) * width + sx - 1) * 3 + 1;
            local index = ((y - 1) * fixed_width + x - 1) * 3 + 1;
            if (sx > 0 and sx <= width and sy > 0 and sy <= height) then
                fixed_pixels[index] = pixels[sindex];
                fixed_pixels[index + 1] = pixels[sindex + 1];
                fixed_pixels[index + 2] = pixels[sindex + 2];
            else
                fixed_pixels[index] = 0;
                fixed_pixels[index + 1] = 0;
                fixed_pixels[index + 2] = 0;
            end
        end
    end
    return Image:new():Init(fixed_width, fixed_height, fixed_pixels);
end

function ColorImage.GetColorImageFromWebCamera(callback, camera_id)
    WebCamera:GetImageRGBData(function(image_width, image_height, image_data)
        if (image_width and image_height and image_data) then
            local img = Image:new():Init(image_width, image_height, image_data);
            local color_img = ColorImage.GetColorImage(img, ColorImage.IsRedColor);
            local dst_img = ColorImage.ScaleFill(color_img, 32, 24);
            if (callback) then callback(dst_img) end
        end
    end, camera_id);
end

-- local src_paths = {
--     "D:/workspace/cpp/darknet/data/roadsigns/images/forbid/10.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/forbid/15.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/forbid/20.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/forbid/25.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/forbid/30.png",

--     "D:/workspace/cpp/darknet/data/roadsigns/images/forword/10.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/forword/15.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/forword/20.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/forword/25.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/forword/30.png",

--     "D:/workspace/cpp/darknet/data/roadsigns/images/left/10.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/left/15.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/left/20.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/left/25.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/left/30.png",

--     "D:/workspace/cpp/darknet/data/roadsigns/images/right/10.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/right/15.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/right/20.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/right/25.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/right/30.png",

--     "D:/workspace/cpp/darknet/data/roadsigns/images/stop/10.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/stop/15.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/stop/20.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/stop/25.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/stop/30.png",

--     "D:/workspace/cpp/darknet/data/roadsigns/images/tunnel/10.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/tunnel/15.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/tunnel/20.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/tunnel/25.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/tunnel/30.png",

--     "D:/workspace/cpp/darknet/data/roadsigns/images/unload/10.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/unload/15.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/unload/20.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/unload/25.png",
--     "D:/workspace/cpp/darknet/data/roadsigns/images/unload/30.png",
-- }

-- for _, path in ipairs(src_paths) do
--     local img = Image:LoadFromFile(path);
--     local color_img = ColorImage.GetColorImage(img, ColorImage.IsRedColor);
--     local dst_img = ColorImage.ScaleFill(color_img, 32, 24);
--     local dst_path = path:gsub("D:/workspace/cpp/darknet/data/roadsigns/images", "D:/workspace/program/ParacraftDev/worlds/DesignHouse/_user/xiaoyao/object-detect/images/roadsigns");
--     local dst_dir = dst_path:match("(.+)/[^/]+$");
--     ParaIO.CreateDirectory(dst_dir .. "/");
--     print(dst_path, dst_img == nil, color_img == nil, img == nil);
--     if dst_img then dst_img:SaveToFile(dst_path); end
-- end

-- local img = Image:LoadFromFile("D:/workspace/cpp/darknet/data/roadsigns/images/forword/10.png");
-- local color_img = ColorImage.GetColorImage(img, ColorImage.IsRedColor);
-- local dst_img = ColorImage.ScaleFill(color_img, 32, 24);
-- dst_img:SaveToFile("D:/test.png");


-- local src_paths = {
--     "images/roadsigns/forbid/10.png",
--     "images/roadsigns/forbid/15.png",
--     "images/roadsigns/forbid/20.png",
--     "images/roadsigns/forbid/25.png",
--     "images/roadsigns/forbid/30.png",

--     "images/roadsigns/forword/10.png",
--     "images/roadsigns/forword/15.png",
--     "images/roadsigns/forword/20.png",
--     "images/roadsigns/forword/25.png",
--     "images/roadsigns/forword/30.png",

--     "images/roadsigns/left/10.png",
--     "images/roadsigns/left/15.png",
--     "images/roadsigns/left/20.png",
--     "images/roadsigns/left/25.png",
--     "images/roadsigns/left/30.png",

--     "images/roadsigns/right/10.png",
--     "images/roadsigns/right/15.png",
--     "images/roadsigns/right/20.png",
--     "images/roadsigns/right/25.png",
--     "images/roadsigns/right/30.png",

--     "images/roadsigns/stop/10.png",
--     "images/roadsigns/stop/15.png",
--     "images/roadsigns/stop/20.png",
--     "images/roadsigns/stop/25.png",
--     "images/roadsigns/stop/30.png",

--     "images/roadsigns/tunnel/10.png",
--     "images/roadsigns/tunnel/15.png",
--     "images/roadsigns/tunnel/20.png",
--     "images/roadsigns/tunnel/25.png",
--     "images/roadsigns/tunnel/30.png",

--     "images/roadsigns/unload/10.png",
--     "images/roadsigns/unload/15.png",
--     "images/roadsigns/unload/20.png",
--     "images/roadsigns/unload/25.png",
--     "images/roadsigns/unload/30.png",
-- }