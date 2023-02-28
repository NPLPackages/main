--[[
Title: ConvNet Dropout
Author(s): LiXizhi
Date: 2022/8/20
Desc: An inefficient dropout layer
Note self is not most efficient implementation since the layer before
computed all these activations and now we're just going to drop them :(
same goes for backward pass. Also, if we wanted to be efficient at test time
we could equivalently be clever and upscale during train and copy pointers during test
todo: make more efficient.

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet.lua");
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local layer = ConvNet.InputLayer:new():Init({});
-------------------------------------------------------
]]

local ConvNet = commonlib.gettable("System.Util.ConvNet");
local DropoutLayer = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.DropoutLayer"));

function DropoutLayer:ctor()
end

function DropoutLayer:Init(opt)
	opt = opt or {};
	self["out_sx"] = opt["in_sx"];
	self["out_sy"] = opt["in_sy"];
	self["out_depth"] = opt["in_depth"];
	self["layer_type"] = "dropout";
	self["drop_prob"] = opt["drop_prob"] or 0.5
	self.dropped = ConvNet.zeros(self["out_sx"] * self["out_sy"] * self["out_depth"]);
end

function DropoutLayer:forward(V, is_training)
	self["in_act"] = V;
	local V2 = V:clone();
	local N = #V.w;
	if(is_training) then
		for i = 1, N do
			if(math.random() < self["drop_prob"])then
				V2.w[i] = 0;
				self.dropped[i] = true;
			else
				self.dropped[i] = false;
			end
		end
	else
		for i = 1, N do
			V2.w[i] = V2.w[i] * self["drop_prob"]
		end
	end
	self["out_act"] = V2;
	return self["out_act"];
end

function DropoutLayer:backward()
	local V = self["in_act"];
	local chain_grad = self["out_act"];
	local N = #V.w;
	V.dw = ConvNet.zeros(N);
	for i = 1, N do
		if not self.dropped[i] then
			V.dw[i] = chain_grad.dw[i];
		end
	end
end

function DropoutLayer:getParamsAndGrads()
	return {}
end

function DropoutLayer:toJSON()
	local json = {}
	json["out_depth"] = self["out_depth"];
	json["out_sx"] = self["out_sx"];
	json["out_sy"] = self["out_sy"];
	json["layer_type"] = self["layer_type"];
	json["drop_prob"] = self["drop_prob"];
	return json;
end

function DropoutLayer:fromJSON(json)
	self["out_depth"] = json["out_depth"];
	self["out_sx"] = json["out_sx"];
	self["out_sy"] = json["out_sy"];
	self["layer_type"] = json["layer_type"];
	self["drop_prob"] = json["drop_prob"];
end