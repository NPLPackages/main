--[[
Title: ConvNet
Author(s): ported and refactored from convnetjs by LiXizhi
Date: 2022/8/20
Desc: convolutional neural network in pure NPL, no GPU.
It currently supports:

- Common Neural Network modules (fully connected layers, non-linearities ReLu)
- Classification (SVM/Softmax) and Regression (L2) cost functions
- Ability to specify and train Convolutional Networks that process images
- An experimental Reinforcement Learning module, based on Deep Q Learning

For more information, see https://cs.stanford.edu/people/karpathy/convnetjs/
and for image number databases, see http://yann.lecun.com/exdb/mnist/

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet.lua");
local ConvNet = commonlib.gettable("System.Util.ConvNet");

-- Example 1:
-- species a 2-layer neural network with one hidden layer of 20 neurons
local layer_defs = {
	-- input layer declares size of input. here: 2-D data
	-- it works on 3-Dimensional volumes (sx, sy, depth), but if you're not dealing with images
	-- then the first two dimensions (sx, sy) will always be kept at size 1
	{type='input', out_sx=1, out_sy=1, out_depth=2}, 
	-- declare 20 neurons, followed by ReLU (rectified linear unit non-linearity)
	{type='fc', num_neurons=20, activation='relu'},
	-- declare the linear classifier on top of the previous hidden layer
	{type='softmax', num_classes=10};
}
local net = ConvNet.Net:new():Init(layer_defs);

-- forward a random data point through the network
local x = ConvNet.Vol:new():Init({0.3, -0.5});
local prob = net:forward(x); 

-- prob is a Vol. Vols have a field .w that stores the raw data, and .dw that stores gradients
echo('probability that x is class 1: ' .. prob.w[1]); -- prints 0.50101

local trainer = ConvNet.SGDTrainer:new():Init(net, {learning_rate=0.01, l2_decay=0.001});
trainer:train(x, 1); -- train the network, specifying that x is class 1

local prob2 = net:forward(x);
echo('probability that x is class 1: ' .. prob2.w[1]);
-- now prints 0.50374, slightly higher than previous 0.50101: the networks
-- weights have been adjusted by the Trainer to give a higher probability to
-- the class we trained the network with (zero)


-- Example 2: predicting images with labels
local layer_defs = {
	{type='input', out_sx=32, out_sy=32, out_depth=1}, -- declare size of input
	-- output Vol is of size 32x32x1 here
	{type='conv', sx=5, filters=16, stride=1, pad=2, activation='relu'},
	-- the layer will perform convolution with 16 kernels, each of size 5x5.
	-- the input will be padded with 2 pixels on all sides to make the output Vol of the same size
	-- output Vol will thus be 32x32x16 at this point
	{type='pool', sx=2, stride=2},
	-- output Vol is of size 16x16x16 here
	{type='conv', sx=5, filters=20, stride=1, pad=2, activation='relu'},
	-- output Vol is of size 16x16x20 here
	{type='pool', sx=2, stride=2},
	-- output Vol is of size 8x8x20 here
	{type='conv', sx=5, filters=20, stride=1, pad=2, activation='relu'},
	-- output Vol is of size 8x8x20 here
	{type='pool', sx=2, stride=2},
	-- output Vol is of size 4x4x20 here
	{type='softmax', num_classes=10},
	-- output Vol is of size 1x1x10 here
}

local net = ConvNet.Net:new():Init(layer_defs);

-- helpful utility for converting images into Vols is included
local x = ConvNet.img_to_vol("Texture/blocks/items/brush.png", true)
local prob1 = net:forward(x)
echo('probability that x is class 1: ' .. prob1.w[1]);
local trainer = ConvNet.SGDTrainer:new():Init(net, {learning_rate=0.01, l2_decay=0.001});
trainer:train(x, 1); -- train the network, specifying that x is class 1
local prob2 = net:forward(x);
echo('probability that x is class 1: ' .. prob2.w[1]);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Vol.lua");
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Vol_Util.lua");
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Util.lua");
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Net.lua");
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Trainers.lua");
local ConvNet = commonlib.gettable("System.Util.ConvNet");
