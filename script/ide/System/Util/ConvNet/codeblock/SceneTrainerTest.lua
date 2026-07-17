--[[
Title: scene trainer tester
Author(s): LiXizhi
Date: 2023/8/30
Desc: predict labels based on pretrained data. 
use the lib:
------------------------------------------------------------
ConvNet.SceneTrainer.LoadModelFromFile("test")
-- image to label prediction
local label, preds = ConvNet.SceneTrainer.Predict("cat.jpg", 4)
echo(label)

-- image data to label prediction
local label, preds = ConvNet.SceneTrainer.Predict({width=2, height=2, data={255,0,0,0, 255,255,255,0, 255,0,255,0, 255,255,255,0}})
echo(label)

-- for scene based batch testing
ConvNet.SceneTrainer.SetTestingSceneData(codeblock)
ConvNet.SceneTrainer.StartTesting()
-- ConvNet.SceneTrainer.HideAll()
-- ConvNet.SceneTrainer.VisualizeNetIn3DScene(19202,8,19201)
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Util/ImageProc/Image.lua");
local Image = commonlib.gettable("System.Util.ImageProc.Image");
local SceneTrainer = gettable("ConvNet.SceneTrainer");

local self = SceneTrainer;

-- set scene training data
-- @param codeblock_: codeblock where to find training dataset in the scene. 
function SceneTrainer.SetTestingSceneData(codeblock_)
    codeblock_ = codeblock_ or codeblock
    local bx, by, bz = codeblock_:GetEntity():GetBlockPos()
    self.testdata = SceneTrainer.SearchTestData(bx, by, bz);
end

-- search all connected blocks in horizontal plane for Sign block and the image block above it. 
-- return array of data each containing {imageFilename, x,y,z}, where x,y,z contains sign block position.
function SceneTrainer.SearchTestData(bx, by, bz)
    local visited = {};
    local item = {bx, by, bz}
    local queue = {};
    local data = {};
    local classNames = {};
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
                
                if(id == 211) then -- sign block
                    local entity = GameLogic.BlockEngine:GetBlockEntity(bx, by, bz)
                    if(entity) then
                        local entityImg = GameLogic.BlockEngine:GetBlockEntity(bx, by+1, bz)
                        local imgFilename = entityImg and entityImg:GetText()
                        if(imgFilename and imgFilename ~= "") then
                            local filename, maxCount, ext = imgFilename:match("^(.+_fps%d+_a)(%d%d%d)(%..+)$")
                            if(maxCount) then
                                maxCount = maxCount:gsub("^0*", "")
                                maxCount = tonumber(maxCount);
                                if(maxCount) then
                                    for i = 1, maxCount do
                                        imgFilename = string.format("%s%03d%s", filename, i, ext)
                                        data[#data + 1] = {imgFilename, bx, by, bz}
                                    end
                                end
                            else
                                data[#data + 1] = {imgFilename, bx, by, bz}
                            end
                        else
                            local dx, dy, dz = SceneTrainer.GetOffsetBySide(side)
                            local entity = GameLogic.BlockEngine:GetBlockEntity(bx+dx, by+dy, bz+dz)
                            if (entity and entity:GetBlockId() == 228) then
                                -- movie block
                                data[#data + 1] = {"movieblock",  bx, by, bz, movieBlockPos = {bx+dx, by+dy, bz+dz}}
                            end
                        end
                    end
                end
            end
        end
        item = queue[#queue]
        queue[#queue] = nil;
    end
    return data;
end

-- @param input: vol of self.width, self.height. or image filename string, or raw image data {width, height, data={r,g,b,a, r,g,b,a,...}}
-- @param sampleCount: default 4. 
-- @return label, preds: preds are array of {k, p}. k is index and p is probability. 
function SceneTrainer.Predict(input, sampleCount)
    if(type(input) == "string") then
        input = ConvNet.ImageHelper.CreateVolFromImageFile(input, self.width, self.height, self.depth);
    elseif(type(input) == "table" and input.width and input.height and input.data) then
        input = ConvNet.ImageHelper.CreateVolFromImageData(input, self.width, self.height, self.depth)
    end
    if(type(input) == "table" and input.w) then
        local num_classes = self.net.layers[#self.net.layers].out_depth;
        -- forward prop it through the network
        local aavg = ConvNet.Vol:new():Init(1, 1, num_classes, 0);
            
        -- ensures we always have a list, regardless if above returns single item or list
        local xs = {};
        sampleCount = sampleCount or 4;
        for i = 1, sampleCount do
            xs[#xs + 1] = ConvNet.augment(input, self.input_sx); -- randomly cropping to shift images
        end
    
        for i = 1, #xs do
            local a = self.net:forward(xs[i]);
            aavg:addFrom(a);
        end
    
        local preds = {};
        for k = 1, #aavg.w do
            preds[#preds + 1] = {k = k, p = aavg.w[k]/sampleCount}
        end 
        table.sort(preds, function(a, b)
            return a.p > b.p
        end)
        -- insert label attribute to the first 4. 
        for i = 1, math.min(4, #preds) do
            preds[i].label = SceneTrainer.ClassIndexToLabel(preds[i].k);
        end
        return preds[1].label, preds;
    end
end

function SceneTrainer.PredictImage(image)
    local image_width = image.width;
    local image_height = image.height;
    local width = self.width;
    local height = self.height;
    local scale = 1;
    local scale_width = scale * width;
    local scale_height = scale * height;
    local result = nil;

    while (scale_width <= image_width or scale == 1) do
        local step_width = scale_width;
        local step_height = scale_height;
        local scale_x = 0;
        while (scale_x < image_width) do
            scale_x = (scale_x + step_width) > image_width and (image_width - step_width) or scale_x;
            scale_y = 0;
            while (scale_y < image_height) do
                scale_y = (scale_y + step_height) > image_height and (image_height - step_height) or scale_y;
                local subimage = image:SubImage(scale_x, scale_y, scale_width, scale_height);
                if (scale_width ~= width or scale_height ~= height) then subimage:Resize(width, height) end
                local label, preds = SceneTrainer.Predict(subimage);
                if (not result or result.preds[1].p < preds[1].p) then
                    result = {label = label, preds = preds, x = scale_x, y = scale_y, width = scale_width, height = scale_height};
                end
                scale_y = scale_y + step_height;
            end
            scale_x = scale_x + step_width;
        end
        scale = scale + 1;
        scale_width = scale * width;
        scale_height = scale * height;
    end
    
    return result.label, result.preds;
end

-- @param sampleCount: default 4. 
function SceneTrainer.TestItem(item, sampleCount)
    local label, preds = SceneTrainer.Predict(item.input, sampleCount)
    
    local bx, by, bz = item[2], item[3], item[4]
    local entity = GameLogic.BlockEngine:GetBlockEntity(bx, by, bz)
    if(entity) then
        local text = "";
        for i = 1, 4 do
            if(preds[i]) then
                local res = SceneTrainer.ClassIndexToLabel(preds[i].k);
                local p = math.floor(preds[i].p * 100 + 0.5);
                if(p > 0) then
                    text = text..string.format("%s : %d%%\n", res, p)
                end
            end
        end
        entity:SetCommand(text)
        entity:Refresh();
    end
    return label, preds;
end

function SceneTrainer.SampleTestItem(index)
    local item = self.testdata and self.testdata[index];    
    if(item) then
        local imgFilename = item[1];
        if(not item.input) then
            if(item.movieBlockPos) then
                item.input = ConvNet.ImageHelper.CreateVolFromSingleFrameMovieData(item.movieBlockPos[1], item.movieBlockPos[2], item.movieBlockPos[3], 0, self.width, self.height)
            else
                item.input = ConvNet.ImageHelper.CreateVolFromImageFile(imgFilename, self.width, self.height, self.depth);
            end
            ConvNet.ImageHelper.ShowVol(item.input, imgFilename, index)
        end
    end
    return item;
end

function SceneTrainer.StartTesting()
    if(not self.net or not self.testdata) then
        return
    end
    tip("testing started")
    
    self.step_num = 0;
    
    SceneTrainer.ReadNetParams()
    
    for i = 1, #(self.testdata) do
        local item = SceneTrainer.SampleTestItem(i);
        SceneTrainer.TestItem(item)
        wait(0.01)
    end
end