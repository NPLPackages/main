--[[
local ObjectDetect = NPL.load("(gl)script/ide/System/Util/ConvNet/test/test_ObjectDetect.lua");
ObjectDetect:Run()
]]

NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet.lua");
NPL.load("(gl)script/ide/System/Util/ImageProc/Image.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Image = commonlib.gettable("System.Util.ImageProc.Image")
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local ObjectDetect = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());
-- local labels = {"猫", "其它"};

-- local train_datas = {
--     {path = "C:/Users/xiaoyao/Downloads/archive/coco128/images/train2017/000000000650.jpg", index = 1},
--     {path = "C:/Users/xiaoyao/Downloads/archive/coco128/images/train2017/000000000472.jpg", index = 1}
-- };

local train_labels = {"掉头", "右转", "隧道"};
local train_datas = {
    {path = GameLogic.GetWorldDirectory() .. "images/1.png", label = 1, width = 400, height = 400},
    {path = GameLogic.GetWorldDirectory() .. "images/2.png", label = 2, width = 400, height = 400},
    {path = GameLogic.GetWorldDirectory() .. "images/3.png", label = 3, width = 400, height = 400},
}

function ObjectDetect:ctor()
    -- 定义输入图像宽高
    self.m_image_width = 40;
    self.m_image_height = 40;

    self.m_train_datas = {};
    self.m_train_labels = {};
end

function ObjectDetect:Init()
    -- 固定网络结构
    local layer_defs = {
        {type = 'input', out_sx = self.m_image_width, out_sy = self.m_image_height, out_depth = 1}, 
        {type = 'conv', sx = 5, filters = 8, stride = 1, pad = 2, activation = 'relu'}, 
        {type = 'pool', sx = 2, stride = 2},
        {type = 'conv', sx = 5, filters = 16, stride = 1, pad = 2, activation = 'relu'}, 
        {type = 'pool', sx = 3, stride = 3}, 
        {type = 'softmax', num_classes = 3}
    }

    self.m_net = ConvNet.Net:new():Init(layer_defs);
    self.m_trainer = ConvNet.SGDTrainer:new():Init(self.m_net, {batch_size = 20, l2_decay = 0.001, method = 'adadelta'});
    self.m_step = 0;
    self.m_sample_count = 1000;

    -- 构造训练数据
    self.m_examples = {};
    for index, item in ipairs(train_datas) do
        self.m_examples[index] = self:LoadExampleItem(item);
    end
end

function ObjectDetect:Run()
    -- local start_time = ParaGlobal.timeGetTime();
    self.m_step = 0;
    for i= 0, self.m_sample_count do
		self:Step();
	end
    -- print("Run use time: ", ParaGlobal.timeGetTime() - start_time);
end

function ObjectDetect:PredictBox(image)

end

function ObjectDetect:Predict(input)
    -- local start_time = ParaGlobal.timeGetTime();
    local vol = self.m_net:forward(input);
    -- print("Predict use time: ", ParaGlobal.timeGetTime() - start_time);
    print("Predict: ", vol.w[1], vol.w[2], vol.w[3]);
end

function ObjectDetect:SampleTrainingInstance(index)
    local size = #self.m_examples;
    if (index) then
        index = ((index - 1) % size) + 1;
    else
        index = math.floor(math.random() * size) + 1;
    end

    local example = self.m_examples[index]; 

    return {input = ConvNet.augment(example.input, self.m_image_width, 10, 10), output = example.output};
end

function ObjectDetect:LoadExampleItem(item)
    -- local start_time = ParaGlobal.timeGetTime();

   -- 加载图像
    local img = Image:new():LoadFromFile(item.path);
    -- 缩放图像
    img:Resize(self.m_image_width, self.m_image_height);
    -- 灰度图像
    -- img:Sobel();
    -- 获取图像数据
    local data = img.data;
    local width = self.m_image_width;
    local height = self.m_image_height;
    local input = ConvNet.Vol:new():Init(width, height, 1, 0);

    -- 创建输入
    for y = 1, height do
        for x = 1, width do
            local ix = ((width * (y - 1)) + (x - 1)) * 3 + 1;
            input:set(x, y, 1, (data[ix] + data[ix+1] + data[ix+2]) / 3 / 255);
            -- input:set(x, y, 1, data[ix] / 255);
        end
    end
    
    -- print("LoadExampleItem use time: ", ParaGlobal.timeGetTime() - start_time);
    return {input = input, output = item.label};
end

function ObjectDetect:Step(sample) 
    sample = sample or self:SampleTrainingInstance();

    local stats = self.m_trainer:train(sample.input, sample.output);
    local predictedIndex = self.m_net:getPrediction();
    local train_acc = (predictedIndex == sample.output) and 1 or 0;

    self.m_step = self.m_step + 1;
    
    -- print("train_acc", train_acc, predictedIndex, sample.output)
    -- echo(stats, true);
end


function ObjectDetect:GetModelDiskFile(filename)
    filename = filename or "npl_object_detect.json"
    if(not filename:match("%.")) then filename = filename..".json" end
    filename = GameLogic.GetWorldDirectory()..filename;
    return filename;
end

function ObjectDetect:SaveModelToFile(filename)
    local json = self:ToJSON();
    if(json) then
        filename = self:GetModelDiskFile(filename);

        if(commonlib.Files.WriteFile(filename, commonlib.serialize_compact(json))) then
            print("successfully saved to ".. filename)
            return true
        end
    end
end

function ObjectDetect:LoadModelFromFile(filename)
    filename = self:GetModelDiskFile(filename);
    if(filename) then
        local text = commonlib.Files.GetFileText(filename)
        if(text) then
            local json = commonlib.LoadTableFromString(text);
            if(json) then
                self:FromJSON(json)
                print("successfully loaded ".. filename)
                return true
            end
        end
    end
end

function ObjectDetect:ToJSON()
    local json = {
        model = self.m_net and self.m_net:toJSON(),
        width = self.m_image_width,
        height = self.m_image_height,
    }
    return json;
end

function ObjectDetect:FromJSON(json)
    self.m_net = ConvNet.Net:new();
    self.m_net:fromJSON(json["model"])
    self.m_image_width = json["width"];
    self.m_image_height = json["height"];
end


ObjectDetect:InitSingleton();

ObjectDetect:Init();
ObjectDetect:Run();
ObjectDetect:SaveModelToFile();

-- ObjectDetect:LoadModelFromFile();
ObjectDetect:Predict(ObjectDetect.m_examples[1].input);


