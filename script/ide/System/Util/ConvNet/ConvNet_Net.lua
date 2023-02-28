--[[
Title: ConvNet Net
Author(s): LiXizhi
Date: 2022/8/20
Desc: Net manages a set of layers
Simple linear order of layers, first layer is input, and last layer is a lose layer

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Net.lua");
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local net = ConvNet.Net:new():Init({});
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Util.lua");
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Layers_Input.lua");
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Layers_Loss.lua");
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Layers_Pool.lua");
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Layers_DotProducts.lua");
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Layers_NonLinearities.lua");
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Layers_Dropout.lua");
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Layers_Normalization.lua");

local ConvNet = commonlib.gettable("System.Util.ConvNet");
local Net = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.Net"));

function Net:ctor()
	self.layers = {}
end

function Net:Init(defs)
	if(defs) then
		self:makeLayers(defs)
	end
	return self;
end

-- takes a list of layer definitions and creates the network layer objects
function Net:makeLayers(defs)
	assert(#defs >= 2, 'Error! At least one input layer and one loss layer are required.');
	assert(defs[1].type == 'input', 'Error! First layer must be the input layer, to declare size of inputs');

	-- desugar layer_defs for adding activation, dropout layers etc
	local function desugar()
		local new_defs = {};
		for i = 1, #defs do
			local layerDef = defs[i]
			if((layerDef.type == "softmax") or(layerDef.type == "svm")) then
				-- add an fc layer here, there is no reason the user should
				-- have to worry about this and we almost always want to
				new_defs[#new_defs + 1] = {type = "fc", num_neurons = layerDef.num_classes};
			end

			if(layerDef.type == "regression") then
				new_defs[#new_defs + 1] = {type = "fc", num_neurons = layerDef.num_neurons};
			end

			if((layerDef.type=='fc' or layerDef.type=='conv') and not layerDef.bias_pref) then
				layerDef.bias_pref = 0;
				if(layerDef.activation == 'relu') then
					-- relus like a bit of positive bias to get gradients early
					-- otherwise it's technically possible that a relu unit will never turn on (by chance)
					-- and will never get any gradient and never contribute any computation. Dead relu.
					layerDef.bias_pref = 0.1;
				end
			end

			new_defs[#new_defs + 1] = layerDef
			if(layerDef.activation) then
				if(layerDef.activation == "relu") then
					new_defs[#new_defs + 1] = {type = "relu"};
				elseif(layerDef.activation == "sigmoid") then
					new_defs[#new_defs + 1] = {type = "sigmoid"};
				elseif(layerDef.activation == "tanh") then
					new_defs[#new_defs + 1] = {type = "tanh"};
				elseif(layerDef.activation == "maxout") then
					local gs = layerDef.group_size or 2;
					new_defs[#new_defs + 1] = {type = "maxout", group_size = gs};
				else
					LOG.std(nil, "warn", "ConvNet", "ERROR unsupported activation %s", layerDef.activation)
				end
			end

			if(layerDef.drop_prob and layerDef.type ~= "dropout") then
				new_defs[#new_defs + 1] = {type = "dropout",["drop_prob"] = layerDef.drop_prob};
			end
		end
		return new_defs;
	end
	defs = desugar(defs);

	-- create the layers
	self.layers = {};
	for i = 1, #defs do
		local layerDef = defs[i];
		if(i > 1) then
			local prev = self.layers[i - 1];
			layerDef["in_sx"] = prev["out_sx"];
			layerDef["in_sy"] = prev["out_sy"];
			layerDef["in_depth"] = prev["out_depth"];
		end
		local layerType = layerDef.type;
        
		if(layerType == "fc") then
			self.layers[#self.layers + 1] = ConvNet.FullyConnLayer:new():Init(layerDef);
		elseif(layerType == "lrn") then
			self.layers[#self.layers + 1] = ConvNet.LocalResponseNormalizationLayer:new():Init(layerDef);
		elseif(layerType == "dropout") then
			self.layers[#self.layers + 1] = ConvNet.DropoutLayer:new():Init(layerDef);
		elseif(layerType == "input") then
			self.layers[#self.layers + 1] = ConvNet.InputLayer:new():Init(layerDef);
		elseif(layerType == "softmax") then
			self.layers[#self.layers + 1] = ConvNet.SoftmaxLayer:new():Init(layerDef);
		elseif(layerType == "regression") then
			self.layers[#self.layers + 1] = ConvNet.RegressionLayer:new():Init(layerDef);
		elseif(layerType == "conv") then
			self.layers[#self.layers + 1] = ConvNet.ConvLayer:new():Init(layerDef);
		elseif(layerType == "pool") then
			self.layers[#self.layers + 1] = ConvNet.PoolLayer:new():Init(layerDef);
		elseif(layerType == "relu") then
			self.layers[#self.layers + 1] = ConvNet.ReluLayer:new():Init(layerDef);
		elseif(layerType == "sigmoid") then
			self.layers[#self.layers + 1] = ConvNet.SigmoidLayer:new():Init(layerDef);
		elseif(layerType == "tanh") then
			self.layers[#self.layers + 1] = ConvNet.TanhLayer:new():Init(layerDef);
		elseif(layerType == "maxout") then
			self.layers[#self.layers + 1] = ConvNet.MaxoutLayer:new():Init(layerDef);
		elseif(layerType == "svm") then
			self.layers[#self.layers + 1] = ConvNet.SVMLayer:new():Init(layerDef);
		else
			LOG.std(nil, "warn", "ConvNet", 'ERROR: UNRECOGNIZED LAYER TYPE: ' .. layerDef.type)
		end
	end
end

-- forward prop the network. 
-- The trainer class passes is_training = true, but when this function is
-- called from outside (not from the trainer), it defaults to prediction mode
function Net:forward(V, is_training)
	local act = self.layers[1]:forward(V, is_training);
	for i = 2, #self.layers do
		act = self.layers[i]:forward(act, is_training);
	end
	return act;
end    

function Net:getCostLoss(V, y)
	self:forward(V, false);
	local N = #self.layers;
	local loss = self.layers[N]:backward(y);
	return loss;
end

-- backprop: compute gradients wrt all parameters
function Net:backward(y)
	local N = #self.layers;
	local loss = self.layers[N]:backward(y);
	for i = N - 1, 1, -1 do
		self.layers[i]:backward();
	end
	return loss;
end

-- accumulate parameters and gradients for the entire network
function Net:getParamsAndGrads()
	local response = {}
	for i = 1, #self.layers do
		local layer_response = self.layers[i]:getParamsAndGrads();
		for j = 1, #layer_response do
			response[#response+1] = layer_response[j];
		end
	end
	return response;
end

-- this is a convenience function for returning the argmax
-- prediction, assuming the last layer of the net is a softmax
-- @return index of the class with highest class probability
function Net:getPrediction()
	local S = self.layers[#self.layers];
	assert(S.layer_type == "softmax", "getPrediction function assumes softmax as last layer of the net!");
	p = S.out_act.w;
	local maxv = p[1];
	local maxi = 1;
	for i = 2, #p do
		if(p[i] > maxv) then
			maxv = p[i];
			maxi = i;
		end
	end
	return maxi;
end

function Net:toJSON()
	local json = {layers = {}};
	for i = 1, #self.layers do
		json.layers[#json.layers + 1] = self.layers[i]:toJSON();
	end
	return json;
end

function Net:fromJSON(json)
	self.layers = {};
	for i = 1, #json.layers do
		local Lj = json.layers[i];
		local t = Lj.layer_type;
		if(t == "input") then
			L = ConvNet.InputLayer:new()
		elseif(t == "relu") then
			L = ConvNet.ReluLayer:new()
		elseif(t == "sigmoid") then
			L = ConvNet.SigmoidLayer:new()
		elseif(t == "tanh") then
			L = ConvNet.TanhLayer:new()
		elseif(t == "dropout") then
			L = ConvNet.DropoutLayer:new()
		elseif(t == "conv") then
			L = ConvNet.ConvLayer:new()
		elseif(t == "pool") then
			L = ConvNet.PoolLayer:new()
		elseif(t == "lrn") then
			L = ConvNet.LocalResponseNormalizationLayer:new()
		elseif(t == "softmax") then
			L = ConvNet.SoftmaxLayer:new()
		elseif(t == "regression") then
			L = ConvNet.RegressionLayer:new()
		elseif(t == "fc") then
			L = ConvNet.FullyConnLayer:new()
		elseif(t == "maxout") then
			L = ConvNet.MaxoutLayer:new()
		elseif(t == "svm") then
			L = ConvNet.SVMLayer:new()
		end
		L:fromJSON(Lj);
		self.layers[#self.layers + 1] = L;
	end
end
