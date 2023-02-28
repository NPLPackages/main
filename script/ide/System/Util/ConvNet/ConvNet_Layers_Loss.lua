--[[
Title: ConvNet Loss Layer (last layer)
Author(s): LiXizhi
Date: 2022/8/20
Desc: Layers that implement a loss. Currently these are the layers that can initiate a backward() pass. 
In future we probably want a more flexible system that can accomodate multiple losses to do multi-task
learning, and stuff like that. But for now, all layers in this file must be the final layer in a Net.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet.lua");
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local layer = ConvNet.SoftmaxLayer:new():Init({});
-------------------------------------------------------
]]
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local SoftmaxLayer = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.SoftmaxLayer"));
local RegressionLayer = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.RegressionLayer"));
local SVMLayer = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.SVMLayer"));

------------------------------------------------------------
-- SoftmaxLayer: This is a classifier, with N discrete classes from 0 to N-1
-- it gets a stream of N incoming numbers and computes the softmax
-- function (exponentiate and normalize to sum to 1 as probabilities should)
------------------------------------------------------------

function SoftmaxLayer:ctor()
end

function SoftmaxLayer:Init(opt)
	opt = opt or {};
	self["num_inputs"] = opt["in_sx"] * opt["in_sy"] * opt["in_depth"];
	self["out_depth"] = self["num_inputs"];
	self["out_sx"] = 1;
	self["out_sy"] = 1;
	self["layer_type"] = "softmax";
	return self;
end

function SoftmaxLayer:forward(V, is_training)
	self.in_act = V;
	local A = ConvNet.Vol:new():Init(1, 1, self.out_depth, 0);

	-- compute max activation
	local as = V.w;
	local amax = V.w[1];
	for i = 2, self.out_depth do
		if(as[i] > amax) then
			amax = as[i];
		end
	end

	-- compute exponentials (carefully to not blow up)
	local es = ConvNet.zeros(self.out_depth);
	local esum = 0;
	for i = 1, self.out_depth do
		e = math.exp(as[i] - amax);
		esum = esum + e;
		es[i] = e;
	end

	-- normalize and output to sum to one
	for i = 1, self.out_depth do
		es[i] = es[i] / esum
		A.w[i] = es[i];
	end

	-- save these for backprop
	self.es = es;
	self.out_act = A;
	return self.out_act;
end

-- compute and accumulate gradient wrt weights and bias of this layer
function SoftmaxLayer:backward(y)
	local x = self.in_act;
	x.dw = ConvNet.zeros(#x.w); -- zero out the gradient of input Vol
	for i = 1, self.out_depth do
		local indicator = (i == y) and 1 or 0
		local mul = -(indicator - self.es[i]);
		x.dw[i] = mul;
	end
	-- loss is the class negative log likelihood
	return -math.log(self.es[y]);
end

function SoftmaxLayer:getParamsAndGrads()
	return {}
end

function SoftmaxLayer:toJSON()
	local json = {};
	json["out_depth"] = self["out_depth"];
	json["out_sx"] = self["out_sx"];
	json["out_sy"] = self["out_sy"];
	json["layer_type"] = self["layer_type"];
	json["num_inputs"] = self["num_inputs"];
	return json;
end

function SoftmaxLayer:fromJSON(json)
	self["out_depth"] = json["out_depth"];
	self["out_sx"] = json["out_sx"];
	self["out_sy"] = json["out_sy"];
	self["layer_type"] = json["layer_type"];
	self["num_inputs"] = json["num_inputs"];
end

-- implements an L2 regression cost layer,
-- so penalizes \sum_i(||x_i - y_i||^2), where x is its input
-- and y is the user-provided array of "correct" values.
function RegressionLayer:ctor()
end

function RegressionLayer:Init(opt)
	opt = opt or {}
	self["num_inputs"] =opt["in_sx"] * opt["in_sy"] * opt["in_depth"];
	self["out_depth"] = self["num_inputs"];
	self["out_sx"] = 1;
	self["out_sy"] = 1;
	self["layer_type"] = "regression";
	return self;
end

function RegressionLayer:forward(V, is_training)
	self["in_act"] = V;
	self["out_act"] = V;
	return V;
end

-- y is a list here of size num_inputs
-- or it can be a number if only one value is regressed
-- or it can be a struct {dim: i, val: x} where we only want to 
-- regress on dimension i and asking it to have value x
function RegressionLayer:backward(y)
	-- compute and accumulate gradient wrt weights and bias of this layer
	local x = self.in_act;
	x.dw = ConvNet.zeros(#x.w);
	local loss = 0;
	if(type(y) == "table" and not y.dim) then
		for i = 1, self.out_depth do
			local dy = x.w[i] - y[i];
			x.dw[i] = dy;
			loss = loss + (0.5 * dy * dy);
		end
	elseif(type(y) == "number") then
		--  lets hope that only one number is being regressed
		local dy = x.w[1] - y;
		x.dw[1] = dy;
		loss = loss + (0.5 * dy * dy);
	else
		-- assume it is a struct with entries .dim and .val
        -- and we pass gradient only along dimension dim to be equal to val
		local i = y.dim;
		local yi = y.val;
		local dy =(x.w[i] - yi);
		x.dw[i] = dy;
		loss = loss + (0.5 * dy * dy);
	end
	return loss;
end

function RegressionLayer:getParamsAndGrads()
	return {}
end

function RegressionLayer:toJSON()
	local json = {};
	json["out_depth"] = self["out_depth"];
	json["out_sx"] = self["out_sx"];
	json["out_sy"] = self["out_sy"];
	json["layer_type"] = self["layer_type"];
	json["num_inputs"] = self["num_inputs"];
	return json;
end
function RegressionLayer:fromJSON(json)
	self["out_depth"] = json["out_depth"];
	self["out_sx"] = json["out_sx"];
	self["out_sy"] = json["out_sy"];
	self["layer_type"] = json["layer_type"];
	self["num_inputs"] = json["num_inputs"];
end


function SVMLayer:ctor()
end

function SVMLayer:Init(opt)
	opt = opt or {};
	self["num_inputs"] = opt["in_sx"] * opt["in_sy"] * opt["in_depth"];
	self["out_depth"] = self["num_inputs"];
	self["out_sx"] = 1;
	self["out_sy"] = 1;
	self["layer_type"] = "svm";
	return self;
end

function SVMLayer:forward(V, is_training)
	self["in_act"] = V;
	self["out_act"] = V;
	return V;
end

function SVMLayer:backward(y)
	local x = self["in_act"];
	x.dw = ConvNet.zeros(#x.w);

	-- we're using structured loss here, which means that the score
    -- of the ground truth should be higher than the score of any other class, by a margin
	local yscore = x.w[y];
	local margin = 1;
	local loss = 0;
	for i = 1, self.out_depth do
		if(y ~= i) then
			local ydiff = -yscore + x.w[i] + margin;
			if (ydiff > 0) then
				-- violating dimension, apply loss
				x.dw[i] = x.dw[i] + 1
				x.dw[y] = x.dw[y] - 1
				loss = loss + ydiff;
			end
		end
	end
	return loss;
end

function SVMLayer:getParamsAndGrads()
	return {}
end

function SVMLayer:toJSON()
	local json = {}
	json["out_depth"] = self["out_depth"];
	json["out_sx"] = self["out_sx"];
	json["out_sy"] = self["out_sy"];
	json["layer_type"] = self["layer_type"];
	json["num_inputs"] = self["num_inputs"];
	return json;
end

function SVMLayer:fromJSON(json)
	self["out_depth"] = json["out_depth"];
	self["out_sx"] = json["out_sx"];
	self["out_sy"] = json["out_sy"];
	self["layer_type"] = json["layer_type"];
	self["num_inputs"] = json["num_inputs"];
end
