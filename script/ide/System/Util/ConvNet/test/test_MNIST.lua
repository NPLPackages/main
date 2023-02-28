--[[
Title: ConvNet mnist demo
Author(s): LiXizhi
Date: 2022/8/20
Desc: number 0-9 image recognition. 
For more information, see https://cs.stanford.edu/people/karpathy/convnetjs/
and for image number databases, see http://yann.lecun.com/exdb/mnist/

The MNIST database of handwritten digits, has a training set of 60,000 samples, and a test set of 10,000 samples. 
Each file contains 3000 images, and stored in "mnist_batch_[0-20].png", we used only the first 3000*21 = 63000 samples.
Batched image file is (28*28)*3000 = 784*3000 pixels 
Labels are stored in mnist_labels.csv files containing all 70000 numbers in text. 

This network takes a 28x28 MNIST image and crops a random 24x24 window before training on it 
(this technique is called data augmentation and improves generalization). 
Similarly to do prediction, 4 random crops are sampled and the probabilities across all crops 
are averaged to produce final predictions. The network runs at about 5ms for both forward and backward pass.
By default, in this demo we're using Adadelta which is one of per-parameter adaptive step size methods,
so we don't have to worry about changing learning rates or momentum over time.

ProjectID in paracraft: 1072951
learning dataset: mnist_batch_[0-4].png
testing dataset: mnist_batch_20.png
labels of all ds: mnist_labels.csv

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/test/test_MNIST.lua");
local MNIST = commonlib.gettable("System.Util.ConvNet.tests.MNIST");
MNIST.run()
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local MNIST = commonlib.gettable("System.Util.ConvNet.tests.MNIST");

local classes_txt = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'};
local use_validation_data = true;

-- each batch contains 3000 images
local num_batches = 5; -- 4 training batches, 1 test (the last one is always for testing)
MNIST.img_data = MNIST.img_data or {};
MNIST.loaded = MNIST.loaded or {}
MNIST.loaded_train_batches = MNIST.loaded_train_batches or {};
MNIST.labels = MNIST.labels or {}
local step_num = 0;

-- @param index: if nil it will randomnly pick one
function MNIST.sample_training_instance(index)
	-- find an unloaded batch
	local bi = math.floor(math.random() *(#MNIST.loaded_train_batches));
	local b = MNIST.loaded_train_batches[bi + 1];
	local k = math.floor(math.random() * 3000); -- sample within the batch
	if(index) then
		b = math.floor((index-1) / 3000) + 1;
		k =(index - 1) % 3000;
	end
	local n =(b-1) * 3000 + 3000 - k;

	-- load more batches over time
	if((step_num%5000==0) and step_num>0) then
		for i = 1, num_batches do
			if(not MNIST.loaded[i]) then
				load_data_batch(i);
				break;
			end
		end
	end

	-- fetch the appropriate row of the training image and reshape into a Vol
	local p = MNIST.img_data[b].data;
	local x = ConvNet.Vol:new():Init(28, 28, 1, 0);
	local W = 28 * 28;
	for i = 1, W do
		local ix = ((W * k) + i-1) * 1 + 1;
		x.w[i] = p[ix] / 255;
	end
	x = ConvNet.augment(x, 24);

	local isval = use_validation_data and((n%10)==0);
	return {x = x, label = MNIST.labels[n], isval = isval, n=n};
end

-- sample a random testing instance
function MNIST.sample_test_instance(index)
	local b = num_batches;
	local k = math.floor(math.random() * 3000);
	if(index) then
		k =(index - 1) % 3000;
	end
	local n =(b-1) * 3000 + 3000 - k;

	local p = MNIST.img_data[b].data;
	local x = ConvNet.Vol:new():Init(28, 28, 1, 0.0);
	local W = 28 * 28;
	for i = 1, W do
		local ix = ((W * k) + i-1) * 1 + 1;
		x.w[i] = p[ix] / 255;
	end
	local xs = {};
	for i = 1, 4 do
		xs[#xs + 1] = ConvNet.augment(x, 24); -- randomly cropping to shift images
	end
	-- return multiple augmentations, and we will average the network over them to increase performance
	return {x = xs, label = MNIST.labels[n], n=n};
end

function MNIST.load_data_batch(batch_num)
	if(MNIST.loaded[batch_num]) then
		return
	else
		MNIST.loaded[batch_num] = true;
	end
	local data = {};
	local img = {data = data};
	MNIST.img_data[batch_num] = img
	local filename = Files.GetWorldFilePath("mnist_batch_" ..(batch_num-1) .. ".png")
	if(filename) then 
		local file = ParaIO.open(filename, "image");
		if(file:IsValid()) then
			local ver = file:ReadInt();
			img.width = file:ReadInt();
			img.height = file:ReadInt();
			local bytesPerPixel = file:ReadInt();
			local pixel = {}
			for y = 1, img.height do
				for x = 1, img.width do
					-- array of rgba
					pixel = file:ReadBytes(bytesPerPixel, pixel);
					local red = pixel[1] or 0;
					data[#data + 1] = red;
				end
			end
			file:close();
			if(batch_num < num_batches) then
				MNIST.loaded_train_batches[#MNIST.loaded_train_batches + 1] = batch_num
			end
			echo('finished loading data batch ' .. batch_num);
		end
	end		
end

-- 70000 labels 
function MNIST.LoadLabels()
	if(#MNIST.labels > 0) then
		return MNIST.labels
	end
	local filename = Files.GetWorldFilePath("mnist_labels.csv")
	if(filename) then
		local file = ParaIO.open(filename, "r");
		if(file:IsValid()) then
			local text = file:GetText(0, -1)
			MNIST.labels = commonlib.LoadTableFromString(format("{%s}", text))
			file:close();
			echo('finished loading lables ' ..(#MNIST.labels));
		end
	end
	return MNIST.labels;
end

function MNIST.Init()
	MNIST.LoadLabels()
	MNIST.load_data_batch(1); 
	MNIST.load_data_batch(2); 
	MNIST.load_data_batch(3); 
	MNIST.load_data_batch(num_batches); -- last batch is used for testing
end

function MNIST.run()
	MNIST.Init()
	local layer_defs = {
	{type = 'input', out_sx = 24, out_sy = 24, out_depth = 1},
	{type = 'conv', sx = 5, filters = 8, stride = 1, pad = 2, activation = 'relu'},
	{type = 'pool', sx = 2, stride = 2},
	{type = 'conv', sx = 5, filters = 16, stride = 1, pad = 2, activation = 'relu'},
	{type = 'pool', sx = 3, stride = 3},
	{type = 'softmax', num_classes = 10},
	}
	MNIST.net = ConvNet.Net:new():Init(layer_defs);
	MNIST.trainer = ConvNet.SGDTrainer:new():Init(MNIST.net, {
	method = 'adadelta', batch_size = 20, l2_decay = 0.001
	})

	--[[ in code block, one can run following
	for i=0, 10000 do
		MNIST.step();
		if(i%100 == 0) then
			ConvNet.visualize_activations(MNIST.net, {minX, minY, minZ})
		end
		if((i%500) == 0) then
			MNIST.test_predict()
		end
	end
	]]
end

function MNIST.LabelToClassIndex(y)
	return y + 1;
end
function MNIST.ClassIndexToLabel(y)
	return y-1;
end

function MNIST.step(sample)
	sample = sample or MNIST.sample_training_instance();
	local x = sample.x;
	local y = MNIST.LabelToClassIndex(sample.label);

	-- train on it with network
	local stats = MNIST.trainer:train(x, MNIST.LabelToClassIndex(y));
    -- keep track of stats such as the average training error and loss
	local yhat = MNIST.net:getPrediction();
	yhat = MNIST.ClassIndexToLabel(yhat);

	echo({step_num, yhat == y, yhat, y, })
	step_num = step_num + 1;
end

-- evaluate current network on test set
-- 4 random crops are sampled and the probabilities across all crops are averaged to produce final predictions. 
function MNIST.test_predict()
	local num_classes = MNIST.net.layers[#MNIST.net.layers].out_depth;

	-- grab a random test image
	for num = 1, 20 do
		local sample = MNIST.sample_test_instance();
		local y = sample.label;  -- ground truth label

		-- forward prop it through the network
		local aavg = ConvNet.Vol:new():Init(1, 1, num_classes, 0);

		-- ensures we always have a list, regardless if above returns single item or list
		local xs = sample.x;
		local n = xs.length;
		for i = 1, #xs do
			local a = MNIST.net:forward(xs[i]);
			aavg:addFrom(a);
		end

		local preds = {};
		for k = 1, #aavg.w do
			preds[#preds + 1] = {k = k, p = aavg.w[k]}
		end 
		table.sort(preds, function(a, b)
			return a.p > b.p
		end)
		y_result = MNIST.ClassIndexToLabel(preds[1].k);
		echo(format("testing %d: %d as %d %s", step_num, y, y_result, tostring(y == y_result)))
	end
end