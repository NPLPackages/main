--[[
Title: ConvNet Normalization layer
Author(s): LiXizhi
Date: 2022/9/8
Desc: a bit experimental layer for now. I think it works but I'm not 100%
the gradient check is a bit funky. I'll look into this a bit later.
Local Response Normalization in window, along depths of volumes

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Layers_Normalization.lua");
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local layer = ConvNet.ConvNet_Layers_Normalization:new():Init({});
-------------------------------------------------------
]]
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local LocalResponseNormalizationLayer = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.LocalResponseNormalizationLayer"));

function LocalResponseNormalizationLayer:ctor()
end

function LocalResponseNormalizationLayer:Init(opt)
	local opt = opt or {};

    -- required
	self.k = opt.k;
	self.n = opt.n;
	self.alpha = opt.alpha;
	self.beta = opt.beta;

    -- computed
	self.out_sx = opt.in_sx;
	self.out_sy = opt.in_sy;
	self.out_depth = opt.in_depth;
	self.layer_type = 'lrn';

    -- checks
	if((self.n%2) == 0) then
		LOG.std(nil, "warn", "LocalResponseNormalizationLayer", 'WARNING n should be odd for LRN layer');
	end
	return self;
end

function LocalResponseNormalizationLayer:forward(V, is_training)
	self.in_act = V;

	local A = V:cloneAndZero();
	self.S_cache_ = V:cloneAndZero();
	local n2 = math.floor(self.n / 2);
	for x = 1, V.sx do
		for y = 1, V.sy do
			for i = 1, V.depth do
				local ai = V:get(x, y, i);

				-- normalize in a window of size n
				local den = 0.0;
				for j = math.max(1, i-n2), math.min(i + n2, V.depth) do
					local aa = V:get(x, y, j);
					den = den + aa * aa;
				end
				den = den * self.alpha / self.n;
				den = den + self.k;
				self.S_cache_:set(x, y, i, den); -- will be useful for backprop
				den = math.pow(den, self.beta);
				A:set(x, y, i, ai / den);
			end
		end
	end

	self.out_act = A;
	return self.out_act; -- dummy identity function for now
end

function LocalResponseNormalizationLayer:backward()
    -- evaluate gradient wrt data
	local V = self.in_act; -- we need to set dw of self
	V.dw = global.zeros(V.w.length); -- zero out gradient wrt data
	local A = self.out_act; -- computed in forward pass 

	local n2 = math.floor(self.n / 2);
	for x = 1, V.sx do
		for y = 1, V.sy do
			for i = 1, V.depth do
				local chain_grad = self.out_act:get_grad(x, y, i);
				local S = self.S_cache_:get(x, y, i);
				local SB = math.pow(S, self.beta);
				local SB2 = SB * SB;

				-- normalize in a window of size n
				for j = math.max(1, i-n2), math.min(i + n2, V.depth) do
					local aj = V:get(x, y, j); 
					local g = -aj * self.beta * math.pow(S, self.beta-1) * self.alpha / self.n * 2 * aj;
					if(j==i) then
						g = g + SB;
					end
					g = g / SB2;
					g = g * chain_grad;
					V:add_grad(x, y, j, g);
				end
			end
		end
	end
end

function LocalResponseNormalizationLayer:getParamsAndGrads()
	return {}
end

function LocalResponseNormalizationLayer:toJSON()
	local json = {};
	json.k = self.k;
	json.n = self.n;
	json.alpha = self.alpha; -- normalize by size
	json.beta = self.beta;
	json.out_sx = self.out_sx; 
	json.out_sy = self.out_sy;
	json.out_depth = self.out_depth;
	json.layer_type = self.layer_type;
	return json;
end

function LocalResponseNormalizationLayer:fromJSON(json)
	self.k = json.k;
	self.n = json.n;
	self.alpha = json.alpha; -- normalize by size
	self.beta = json.beta;
	self.out_sx = json.out_sx; 
	self.out_sy = json.out_sy;
	self.out_depth = json.out_depth;
	self.layer_type = json.layer_type;
end