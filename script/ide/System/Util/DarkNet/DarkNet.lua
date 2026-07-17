--[[
local DarkNet = NPL.load("(gl)script/ide/System/Util/DarkNet/DarkNet.lua");
]]

local CommonLib = NPL.load("Mod/GeneralGameServerMod/CommonLib/CommonLib.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Encoding = commonlib.gettable("System.Encoding");
local DarkNet = commonlib.inherit(nil, NPL.export());

function DarkNet:ctor()
    self.m_config = {};
    self.m_datas = {};
    self.m_classIndexToNames = {};
    self.m_classNameToIndexs = {};
    self.m_width = 64;
    self.m_height = 64;
    self.m_channels = 3;
    self.m_softmax = false;
    self.m_yolo = false;
end

function DarkNet:Init(config)
    self.m_config = config or {};
    self.m_name = self.m_config.name or "darknet";
    self.m_root_directory = self:GetDarkNetRootDircetory();
    self.m_net_filepath = self.m_root_directory .. "net.ini";
    self.m_dataset_filepath = self.m_root_directory .. "dataset.ini";
    self.m_config_filepath = self.m_root_directory .. "config.ini";
    self.m_model_filepath = self.m_root_directory .. "models/" .. self.m_name .. ".model";
    self.m_layers = self.m_config.layers or {};
    self.m_width = self.m_config.width or self.m_width;
    self.m_height = self.m_config.height or self.m_height;
    self.m_channels = self.m_config.channels or self.m_channels;
    ParaIO.CreateDirectory(self.m_root_directory);
    ParaIO.CreateDirectory(self.m_root_directory .. "models/");
    ParaIO.CreateDirectory(self.m_root_directory .. "images/");
    self:WriteNetFile();
    self:WriteConfigFile();
    self:SetDatas(self.m_config.datas);
    return self;
end

function DarkNet:GetDarkNet() 
    if (self.m_darknet) then return self.m_darknet end
    if (not _G.LuaDarkNet) then require ("LuaDarkNet") end
    self.m_darknet = LuaDarkNet.LuaDarkNet();
    return self.m_darknet;
end

function DarkNet:Load(model_path)
    return self:GetDarkNet():Load(model_path);
end

function DarkNet:Train(callback, finish_callback)
    self:GetDarkNet():LoadConfig(self.m_config_filepath, true);

    local max_epochs = self:GetConfigValue("max_epochs", 1000);
    local epochs = 1;
    self.m_train_timer = commonlib.TimerManager.SetInterval(function()
        if (epochs > max_epochs) then
            self.m_train_timer:Change();
            self.m_train_timer = nil;
            self:GetDarkNet():Save(self.m_model_filepath);
            if (finish_callback) then finish_callback() end
            return;
        end

        local loss = self:GetDarkNet():DoEpoch();
        if (callback) then callback(loss, epochs) end
        epochs = epochs + 1;
    end, 100);
end

function DarkNet:DoEpoch()
	local loss = self:GetDarkNet():DoEpoch();
	return loss;
end

function DarkNet:Predict(image_path, is_image_path, x, y, w, h)
    x = math.floor(x or 0);
    y = math.floor(y or 0);
    w = math.floor(w or 0);
    h = math.floor(h or 0);
    is_image_path = (is_image_path or is_image_path == nil) and true or false;
    -- print(image_path, is_image_path, x, y, w, h)
    if (w <= 0 or h <= 0) then
        self.m_predicts = self:GetDarkNet():Predict(image_path, is_image_path);
    else
        self.m_predicts = self:GetDarkNet():PredictSubImage(image_path, is_image_path, x, y, w, h);
    end
    return self.m_predicts;
end

function DarkNet:GetMaxProbabilityIndex()
    local max_value = 0;
    local max_index = 0;
    for index, probability in ipairs(self.m_predicts) do
        if (max_value < probability) then
            max_value = probability;
            max_index = index;
        end
    end
    return max_index, max_value, self.m_classIndexToNames[max_index];
end

-- search all connected blocks in horizontal plane for Sign block and the image block above it. 
-- return array of data each containing {imageFilename, signText}
function DarkNet:SearchTrainingData(bx, by, bz)
    local visited = {};
    local item = {bx, by, bz}
    local queue = {};
    local datas = {};
    while (item) do
        bx, by, bz = item[1], item[2], item[3]
        local id, side = GameLogic.BlockEngine:GetBlockIdAndData(bx, by, bz)
        if(id > 0) then
            local idx = GameLogic.BlockEngine:GetSparseIndex(bx, by, bz)
            if(not visited[idx]) then
                visited[idx] = true;
                
                queue[#queue+1] = {bx+1, by, bz}
                queue[#queue+1] = {bx-1, by, bz}
                queue[#queue+1] = {bx, by, bz+1}
                queue[#queue+1] = {bx, by, bz-1}
                
                local entity = GameLogic.BlockEngine:GetBlockEntity(bx, by, bz)
                local output = (entity and entity:GetCommand()) or "";
                local entityImg = GameLogic.BlockEngine:GetBlockEntity(bx, by+1, bz)
                local imgFilename = (entityImg and entityImg:GetText()) or "";
                if(id == 211 and imgFilename ~= "" and output ~= "") then -- sign block
                    if(imgFilename:match("/$")) then -- this is an image folder
                        local results = {}
                        Game.Common.Files:FindWorldFiles(results, imgFilename, 2, 1000, "texture")
                        for _, file in ipairs(results) do
                            datas[#datas + 1] = {filepath = imgFilename .. file.filename, label = output}
                        end
                    else
                        datas[#datas + 1] = {filepath = imgFilename, label = output}
                    end
                end
            end
        end
    
        item = queue[#queue]
        queue[#queue] = nil;
    end

    local path_labels = {}

    for _, data in ipairs(datas) do
        local filepath = Files.GetWorldFilePath(data.filepath)
        path_labels[filepath] = data.label;
    end

    self.m_datas = path_labels;
    return path_labels;
end

function DarkNet:SetDatas(datas)
    if (not datas) then return end
    self.m_datas = datas;
    self.m_classNameToIndexs, self.m_classIndexToNames = self:GetClassNameAndIndexs();
    self:WriteDataSetFile();
end

function DarkNet:GetClassNameAndIndexs()
    local classNameToIndexs = {}
    local classIndexToNames = {}
    for _, name in pairs(self.m_datas) do
        if (classNameToIndexs[name] == nil) then
            classIndexToNames[#classIndexToNames + 1] = name;
            classNameToIndexs[name] = #classIndexToNames;
        end
    end
    return classNameToIndexs, classIndexToNames;
end

function DarkNet:GetDarkNetRootDircetory()
    return CommonLib.ToCanonicalFilePath(CommonLib.GetWorldDirectory() .. "/" .. (self.m_name or "darknet") .. "/");
end

function DarkNet:GetDarkNetImagesDircetory()
    return CommonLib.ToCanonicalFilePath(self:GetDarkNetRootDircetory() .. "images/");
end

function DarkNet:GetFileName(filepath)
    return string.match(filepath or "", "([^\\/]*)$");
end

function DarkNet:WriteFile(file_path, file_text)
    local io = ParaIO.open(file_path, "w");
    io:WriteString(file_text);
    io:close();
end

function DarkNet:WriteDataSetFile()
    local text = "";
    local classNameToIndexs, classIndexToNames = self:GetClassNameAndIndexs();
    local classSize = #classIndexToNames;
    for filepath, label in pairs(self.m_datas) do
        text = text .. filepath .. "\n";
        local label_class = classNameToIndexs[label];
        for i = 1, classSize do
            text = text .. (i == label_class and "1" or "0") .. (i == classSize and "\n" or " ");
        end
    end

    self:WriteFile(self.m_dataset_filepath, text);
end

function DarkNet:WriteNetFile()
    local layers = self.m_layers or {};
    if (not next(layers)) then return end

    local text = "";
    text = text .. "[net]" .. "\n";
    text = text .. "width=" .. tostring(self.m_width or 64) .. "\n";
    text = text .. "height=" .. tostring(self.m_height or 64) .. "\n";
    text = text .. "channels=" .. tostring(self.m_channels or 3) .. "\n";
    text = text .. "\n";

    for _, layer in ipairs(layers) do
        if (type(layer.type) == "string") then
            text = text .. "[" .. layer.type .. "]\n";
            for key, value in pairs(layer) do
                if (key ~= "type") then
                    text = text .. tostring(key) .. "=" .. tostring(value) .. "\n";
                end
            end 
            text = text .. "\n";
        end
    end

    self:WriteFile(self.m_net_filepath, text);
end

function DarkNet:WriteConfigFile()
    local text = self:GetDarkNetConfigText();
    self:WriteFile(self.m_config_filepath, text);
end

function DarkNet:GetDarkNetConfigText()
    local text = "";
    text = text .. "net=" .. self.m_net_filepath .. "\n";
    text = text .. "dataset=" .. self.m_dataset_filepath .. "\n";
    text = text .. "batch=" .. tostring(self:GetConfigValue("batch", 1)) .. "\n";
    text = text .. "argument=" .. (self:GetConfigValue("arugument", true) and "1" or "0") .. "\n";
    text = text .. "random=" .. (self:GetConfigValue("random", true) and "1" or "0") .. "\n";
    text = text .. "max_epochs=" .. tostring(self:GetConfigValue("max_epochs", 2000)) .. "\n";

    return text;
end

function DarkNet:GetConfigValue(key, defaut_value)
    if (self.m_config[key] == nil) then return defaut_value end
    return self.m_config[key];
end

function DarkNet:Test()
    local darknet = DarkNet:new();
    darknet:Load("D:/workspace/cpp/darknet/data/softmax/models/model.lastest");
    darknet:Predict("D:/workspace/cpp/darknet/data/softmax/images/5_05.png");

    local WebCamera = NPL.load("(gl)script/apps/Aries/Creator/Game/NplBrowser/WebCamera.lua");
    WebCamera:Close();
    local camera_id = WebCamera:OpenCamera(320, 240);
    WebCamera:GetVideoTexture(camera_id):SetIgnoreHit(true);
    WebCamera:SetReceiveCameraDataInterval(1000, camera_id);
    WebCamera:SetReceiveCameraDataCallback(function(msg)
        if(type(msg.data) == "string") then
            local base64_image_data = string.gsub(msg.data, "data:image/jpeg;base64,", "");
            local image_data = Encoding.unbase64(base64_image_data);
            -- CommonLib.WriteFile("temp/test.jpg", image_data);
            darknet:Predict(image_data, false);
            print(darknet:GetMaxProbabilityIndex());
        end
    end, camera_id);
end
