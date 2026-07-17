--[[
local DarkNetQRCode = NPL.load("(gl)script/ide/System/Util/DarkNet/DarkNetQRCode.lua");
]]

NPL.load("(gl)script/ide/System/Util/ImageProc/Image.lua");
local Image = commonlib.gettable("System.Util.ImageProc.Image")
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local DarkNet = NPL.load("(gl)script/ide/System/Util/DarkNet/DarkNet.lua", true);
local DarkNetQRCode = commonlib.inherit(DarkNet, NPL.export());

function DarkNetQRCode:ctor()
    self.m_name = "darknet_qrcode";
end

function DarkNetQRCode:Init(config)
    config = config or {};
    config.name = self.m_name;
    DarkNetQRCode._super.Init(self, config);
    -- 二维码提取网络
    self.m_qrcode_darknet = DarkNet:new();
    self.m_qrcode_darknet:Load(self:GetDarkNetRootDircetory() .. "models/qrcode.model");
    return self;
end

function DarkNetQRCode:Predict(image_path, is_image_path)
    local _, x, y, w, h = self:GetQRCodePositions(image_path, is_image_path);
    return DarkNetQRCode._super.Predict(self, image_path, is_image_path, x, y, w, h);
end

function DarkNetQRCode:SetDatas(datas)
    if (not datas) then return end

    local images_directory = self:GetDarkNetImagesDircetory();
    local qrcode_datas = {};
    
    ParaIO.CreateDirectory(images_directory);
    print("images_directory:", images_directory);
    for filepath, label in pairs(datas) do
        filepath = CommonLib.ToCanonicalFilePath(filepath);
        local filename = self:GetFileName(filepath);
        local qrcode_filepath = CommonLib.ToCanonicalFilePath(images_directory .. filename);
        local pos = string.find(qrcode_filepath, filepath)
        if (not pos) then
            -- 不在目标目录下, 自动打上二维码标记并保存到目标目录下
            local img = Image:new();
            img:LoadFromFile(Files.GetWorldFilePath(filepath));
            if (not img.width or not img.height) then
                print("invalid data => ", filepath);
            else
                img:Resize(self.m_width, self.m_height);
                img:DrawQRCode();
                img:SaveToFile(qrcode_filepath);
                qrcode_datas[qrcode_filepath] = label;
            end
        else
            qrcode_datas[qrcode_filepath] = label;
        end
    end

    DarkNetQRCode._super.SetDatas(self, qrcode_datas);
end

function DarkNetQRCode:GetQRCodePositions(image_path, is_image_path)
    local predicts = self.m_qrcode_darknet:Predict(image_path, is_image_path);
    local index = 0;
    local size = #predicts;
    local qrcodes = {};
    local min_x, max_x, min_y, max_y = 0, 0, 0, 0;
    while (index < size) do
        local x = predicts[index + 1];
        local y = predicts[index + 2];
        local w = predicts[index + 3];
        local h = predicts[index + 4];
        qrcodes[#qrcodes + 1] = {x = x, y = y, w = w, h = h};
        min_x = min_x == 0 and (x - w / 2) or math.min(min_x, (x - w / 2));
        max_x = max_x == 0 and (x + w / 2) or math.max(max_x, (x + w / 2));
        min_y = min_y == 0 and (y - h / 2) or math.min(min_y, (y - h / 2));
        max_y = max_y == 0 and (y + h / 2) or math.max(max_y, (y + h / 2));
        index = index + 6;
    end

    return qrcodes, min_x, min_y, max_x - min_x, max_y - min_y;
end

function DarkNetQRCode:Test()
    -- 配置网络
    local darknet = DarkNetQRCode:new():Init({
        layers = {
            {
                type = "convolutional",
                size = 3,
                filters = 16,
                stride = 1,
                padding = 1,
                activation = "leaky",
            },
            {
                type = "maxpool",
                size = 2,
                stride = 2,
            },
            {
                type = "convolutional",
                filters = 32,
                size = 3,
                stride = 1,
                padding = 1,
                activation = "leaky",
            },
            {
                type = "maxpool",
                size = 2,
                stride = 2,
            },
            {
                type = "connected",
                output = 3,
                activation = "linear",
            },
            {
                type = "softmax",
            }
        },
        batch = 4,
    });
    -- 设置数据
    darknet:SetDatas({
        ["darknet_qrcode/images/turn_left.png"] = "turn_left",
        ["darknet_qrcode/images/turn_left_01.png"] = "turn_left",
        ["darknet_qrcode/images/turn_left_02.png"] = "turn_left",
        ["darknet_qrcode/images/turn_left_03.png"] = "turn_left",
        ["darknet_qrcode/images/turn_right.png"] = "turn_right",
        ["darknet_qrcode/images/turn_right_01.png"] = "turn_right",
        ["darknet_qrcode/images/turn_right_02.png"] = "turn_right",
        ["darknet_qrcode/images/turn_right_03.png"] = "turn_right",
        ["darknet_qrcode/images/upload.png"] = "upload",
        ["darknet_qrcode/images/upload_01.png"] = "upload",
        ["darknet_qrcode/images/upload_02.png"] = "upload",
        ["darknet_qrcode/images/upload_03.png"] = "upload",
    });
    -- 训练网络
    -- darknet:Train(function(loss, epochs)
    --     print("loss: " .. loss .. ", epochs: " .. epochs);
    -- end);

    -- 加载网络
    darknet:Load(darknet.m_model_filepath);

    -- 预测网络
    -- darknet:Predict("D:/workspace/program/ParacraftDev/worlds/DesignHouse/_user/xiaoyao/object-detect/darknet_qrcode/images/turn_right.png");
    -- local darknet = DarkNet:new();
    -- darknet:Load("D:/workspace/program/ParacraftDev/worlds/DesignHouse/_user/xiaoyao/object-detect/darknet_qrcode/qrcode.model");
    darknet:Predict("D:/workspace/cpp/darknet/data/qrcode/images/3.png");
    print(darknet:GetMaxProbabilityIndex())
    -- echo(darknet:GetQRCodePositions("D:/workspace/cpp/darknet/data/qrcode/images/3.png"), true);

    -- NPL.load("(gl)script/ide/System/Util/ImageProc/Image.lua", true);
    -- local Image = commonlib.gettable("System.Util.ImageProc.Image")
    -- local img = Image:new();
    -- img:LoadFromFile("D:/workspace/program/ParacraftDev/worlds/DesignHouse/_user/xiaoyao/object-detect/darknet_qrcode/images/white.png");
    -- img:DrawQRCode();
    -- img:SaveToFile("D:/workspace/program/ParacraftDev/worlds/DesignHouse/_user/xiaoyao/object-detect/darknet_qrcode/images/white_qrcode.png");
end