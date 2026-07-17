--[[
local ImageDataSet = NPL.load("(gl)script/ide/System/Util/DarkNet/ImageDataSet.lua");
local image_dataset = ImageDataSet:new():Init();
image_dataset:Show();
]]
NPL.load("(gl)script/ide/System/Util/ImageProc/Image.lua");
local Image = commonlib.gettable("System.Util.ImageProc.Image")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Encoding = commonlib.gettable("System.Encoding");
local WebCamera = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/WebCamera.lua");
local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");

local Page = NPL.load("script/ide/System/UI/Page.lua");
local ImageDataSet = commonlib.inherit(nil, NPL.export());

function ImageDataSet:ctor()
    self.m_name = "imagedataset";
    self.m_datas = {};
end

function ImageDataSet:Init(name)
    self.m_name = name or self.m_name;
    self.m_filepath = CommonLib.ToCanonicalFilePath(CommonLib.GetWorldDirectory() .. "/" .. self.m_name .. ".table");
    self:Load();
    return self;
end

function ImageDataSet:Save()
    local text = commonlib.serialize_compact(self.m_datas);
    self:WriteFile(self.m_filepath, text);
end

function ImageDataSet:Load()
    local text = self:ReadFile(self.m_filepath);
    self.m_datas = NPL.LoadTableFromString(text) or {};
end

function ImageDataSet:WriteFile(file_path, file_text)
    local io = ParaIO.open(file_path, "w");
    io:WriteString(file_text);
    io:close();
end

function ImageDataSet:ReadFile(file_path)
    local io = ParaIO.open(file_path, "r");
    if(not io:IsValid()) then return end 
    local text = io:GetText();
    io:close();
    return text;
end

function ImageDataSet:GetDatas()
    return self.m_datas;
end

function ImageDataSet:SetDatas(datas)
    self.m_datas = datas or {};

end

function ImageDataSet:Show()
    if (_G.ImageDataSetPage) then _G.ImageDataSetPage:CloseWindow() end
    _G.IsDevEnv = true;

    self.m_camera_id = WebCamera:OpenCamera(320, 240, false, 10, 10, nil, nil);
    WebCamera:GetVideoTexture(self.m_camera_id):SetIgnoreHit(true);
    local page =  Page.Show({
        ImageDataSet = self,
        camera_url = WebCamera:GetTextureFilename(),
        OnClose = function()
            WebCamera:Close();
        end
    }, {
        url = "script/ide/System/Util/DarkNet/ImageDataSet.html",
        width = 410,
        height = 340,
    });
    _G.ImageDataSetPage = page
end


function ImageDataSet:GetImageDircetory()
    if (self.m_image_directory) then return self.m_image_directory end
    self.m_image_directory = CommonLib.ToCanonicalFilePath(CommonLib.GetWorldDirectory() .. "/images/");
    ParaIO.CreateDirectory(self.m_image_directory);
    return self.m_image_directory;
end

function ImageDataSet:SaveCameraImage()
    local msg = WebCamera:GetCameraData(self.m_camera_id);
    if(not msg or type(msg.data) ~= "string") then return end
    local img_fmt = WebCamera:GetCamera().m_image_format;
    local base64_image_data = string.gsub(msg.data, "data:image/" .. img_fmt .. ";base64,", "");
    local image_data = Encoding.unbase64(base64_image_data);
    local temp_img_path = "temp/tmp." .. img_fmt;
    CommonLib.WriteFile(temp_img_path, image_data);
    local img = Image:new();
    img:LoadFromFile(temp_img_path);
    if (not img.data or not img.width or not img.height) then return end
    local width = img.width;
    local height = img.height;
    local min_width_height = math.min(width, height);
    img = img:SubImage((math.floor(width - min_width_height) / 2), math.floor((height - min_width_height) / 2), min_width_height, min_width_height);
    img:DrawQRCode();
    local filepath =  self:GetImageDircetory() .. "/" .. tostring(os.time()) .. "." .. img_fmt;
    img:SaveToFile(filepath);
    return filepath;
end
