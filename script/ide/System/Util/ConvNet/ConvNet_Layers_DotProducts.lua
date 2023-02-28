--[[
Title: ConvNet Dot Products
Author(s): LiXizhi
Date: 2022/8/20
Desc: This file contains all layers that do dot products with input,
but usually in a different connectivity pattern and weight sharing
schemes: 
- FullyConn is fully connected dot products 
- ConvLayer does convolutions (so weight sharing spatially)
putting them together in one file because they are very similar

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet.lua");
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local layer = ConvNet.ConvLayer:new():Init({});
-------------------------------------------------------
]]
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local ConvLayer = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.ConvLayer"));
local FullyConnLayer = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.FullyConnLayer"));

function ConvLayer:ctor()
end

function ConvLayer:Init(opt)
	opt = opt or {}
	self["out_depth"] = opt.filters;
	self.sx = opt.sx; -- filter size. Should be odd if possible, it's cleaner.
	self["in_depth"] = opt["in_depth"];
	self["in_sx"] = opt["in_sx"];
	self["in_sy"] = opt["in_sy"];
	self.sy = opt.sy or self.sx;
        
	self.stride = opt.stride or 1 -- stride at which we apply filters to input volume
	self.pad = opt.pad or 0 --  amount of 0 padding to add around borders of input volume
	self["l1_decay_mul"] = opt["l1_decay_mul"] or 0;
	self["l2_decay_mul"] = opt["l2_decay_mul"] or 1;

	-- note we are doing floor, so if the strided convolution of the filter doesnt fit into the input
    -- volume exactly, the output volume will be trimmed and not contain the (incomplete) computed final application.        
	self["out_sx"] = math.floor(((((self["in_sx"] + (self.pad * 2)) - self.sx) / self.stride) + 1));
	self["out_sy"] = math.floor(((((self["in_sy"] + (self.pad * 2)) - self.sy) / self.stride) + 1));
	self["layer_type"] = "conv";
	local bias = opt["bias_pref"] or 0;
	self.filters = {}
	for i = 1, self.out_depth do
		self.filters[#self.filters + 1] = ConvNet.Vol:new():Init(self.sx, self.sy, self.in_depth);
	end
	self.biases = ConvNet.Vol:new():Init(1, 1, self.out_depth, bias);
	return self;
end

function ConvLayer:forward(V, is_training)
	self.in_act = V;
	local A = ConvNet.Vol:new():Init(self.out_sx, self.out_sy, self.out_depth)
	local V_sx = V.sx
	local V_sy = V.sy
	local xy_stride = self.stride
	
	for d = 1, self.out_depth do
		local f = self.filters[d];
		local x = - self.pad + 1;
		local y = - self.pad + 1;
		for ay = 1, self.out_sy do
			x = - self.pad + 1
			for ax = 1, self.out_sx do
				-- convolve centered at this particular location
				local a = 0;
				for fy = 0, f.sy-1 do
					local oy = y + fy; -- coordinates in the original input array coordinates
					for fx = 0, f.sx - 1 do
						local ox = x + fx;
						if(oy>=1 and oy<=V.sy and ox>=1 and ox<=V.sx) then
							for fd = 1, f.depth do
								-- avoid function call overhead (x2) for efficiency, compromise modularity :(
								a = a + f.w[((f.sx * fy)+fx)*f.depth+fd] * V.w[((V_sx * (oy-1))+(ox-1))*V.depth+fd];
							end
						end
					end
				end

				a = a + self.biases.w[d];
				A:set(ax, ay, d, a);
				x = x + xy_stride
			end
			y = y + xy_stride
		end
	end

	self.out_act = A;
	return self.out_act
end

function ConvLayer:backward()
	local V = self.in_act;
	V.dw = ConvNet.zeros(#V.w);
	local V_sx = V.sx
	local V_sy = V.sy
	local xy_stride = self.stride
	for d = 1, self.out_depth do
		local f = self.filters[d];
		local x = - self.pad + 1
		local y = - self.pad + 1
		for ay = 1, self.out_sy do
			x = - self.pad + 1
			for ax = 1, self.out_sx do
				local chain_grad = self.out_act:get_grad(ax, ay, d);
				for fy = 0, f.sy-1 do
					local oy = y + fy; -- coordinates in the original input array coordinates
					for fx = 0, f.sx - 1 do
						local ox = x + fx;
						if(oy>=1 and oy<=V.sy and ox>=1 and ox<=V.sx) then
							for fd = 1, f.depth do
								local ix1 = ((V_sx * (oy - 1))+(ox-1))*V.depth+fd;
								local ix2 = ((f.sx * fy)+fx)*f.depth+fd;
								f.dw[ix2] = f.dw[ix2] + V.w[ix1]*chain_grad;
								V.dw[ix1] = V.dw[ix1] + f.w[ix2]*chain_grad;
							end
						end
					end
				end

				self.biases.dw[d] = self.biases.dw[d] + chain_grad;
				x = x + xy_stride
			end
			y = y + xy_stride
		end
	end
end

function ConvLayer:getParamsAndGrads()
	local response = {}
	for i = 1, self.out_depth do
		response[#response+1] = {
			["params"] = self.filters[i].w,
			["grads"] = self.filters[i].dw,
			["l2_decay_mul"] = self["l2_decay_mul"],
			["l1_decay_mul"] = self["l1_decay_mul"]
		};
	end

	response[#response+1] = {
		["params"] = self.biases.w,
		["grads"] = self.biases.dw,
		["l1_decay_mul"] = 0,
		["l2_decay_mul"] = 0
	}
	return response;
end

function ConvLayer:toJSON()
	local json = {}
	json.sx = self.sx;
	json.sy = self.sy;
	json.stride = self.stride;
	json["in_depth"] = self["in_depth"];
	json["out_depth"] = self["out_depth"];
	json["out_sx"] = self["out_sx"];
	json["out_sy"] = self["out_sy"];
	json["layer_type"] = self["layer_type"];
	json["l1_decay_mul"] = self["l1_decay_mul"];
	json["l2_decay_mul"] = self["l2_decay_mul"];
	json.pad = self.pad;
	json.filters = {}
	for i = 1, #self.filters do
		json.filters[#json.filters+1] = self.filters[i]:toJSON();
	end
	json.biases = self.biases:toJSON();
	return json;
end

function ConvLayer:fromJSON(json)
	self["out_depth"] = json["out_depth"];
	self["out_sx"] = json["out_sx"];
	self["out_sy"] = json["out_sy"];
	self["layer_type"] = json["layer_type"];
	self.sx = json.sx;
	self.sy = json.sy;
	self.stride = json.stride;
	self["in_depth"] = json["in_depth"];
	self.filters = {}
	self["l1_decay_mul"] = json["l1_decay_mul"] or 1
	self["l2_decay_mul"] = json["l2_decay_mul"] or 1;
	self.pad = json.pad or 0;
		
	for i = 1, #json.filters do
		local v = ConvNet.Vol:new():Init(0, 0, 0, 0);
		v:fromJSON(json.filters[i]);
		self.filters[#self.filters+1] = v;
	end

	self.biases = ConvNet.Vol:new():Init(0, 0, 0, 0);
	self.biases:fromJSON(json.biases);
end


----------------------------------
-- fully connected layer
----------------------------------
function FullyConnLayer:ctor()
end

function FullyConnLayer:Init(opt)
	opt = opt or {};
	self["out_depth"] = opt["num_neurons"] or opt.filters;
	self["l1_decay_mul"] = opt["l1_decay_mul"] or 0;
	self["l2_decay_mul"] = opt["l2_decay_mul"] or 1;
		
	self["num_inputs"] = opt["in_sx"] * opt["in_sy"] * opt["in_depth"];
	self["out_sx"] = 1;
	self["out_sy"] = 1;
	self["layer_type"] = "fc";
	local bias = opt["bias_pref"] or 0;
	self.filters = {};
	
	for i = 1, self.out_depth do
		self.filters[#self.filters + 1] = ConvNet.Vol:new():Init(1, 1, self.num_inputs);
	end
	self.biases = ConvNet.Vol:new():Init(1, 1, self.out_depth, bias);
	return self;
end

function FullyConnLayer:forward(V, is_training)
	self.in_act = V;
	local A = ConvNet.Vol:new():Init(1, 1, self.out_depth, 0);
	local Vw = V.w;
	for i = 1, self.out_depth do
		local a = 0;
		local wi = self.filters[i].w;
		for d = 1, self.num_inputs do
			a = a + Vw[d] * wi[d];
		end
		a = a + self.biases.w[i];
		A.w[i] = a;
	end

	self.out_act = A;
	return self.out_act;
end

function FullyConnLayer:backward()
	local V = self.in_act;
	V.dw = ConvNet.zeros(#V.w);

	-- compute gradient wrt weights and data
	for i = 1, self.out_depth do
		local tfi = self.filters[i];
		chain_grad = self["out_act"].dw[i];
		for d = 1, self.num_inputs do
			V.dw[d] = V.dw[d] + tfi.w[d] * chain_grad -- grad wrt input data
			tfi.dw[d] = tfi.dw[d] + V.w[d] * chain_grad -- grad wrt params
		end
		self.biases.dw[i] = self.biases.dw[i] + chain_grad
	end
end

function FullyConnLayer:getParamsAndGrads()
	local response = {}
	for i = 1, self.out_depth do
		response[#response+1] = {
			["params"] = self.filters[i].w,
			["grads"] = self.filters[i].dw,
			["l1_decay_mul"] = self["l1_decay_mul"],
			["l2_decay_mul"] = self["l2_decay_mul"]
		}
	end

	response[#response+1] = {
		["params"] = self.biases.w,
		["grads"] = self.biases.dw,
		["l1_decay_mul"] = 0,
		["l2_decay_mul"] = 0
	}
	return response;
end

function FullyConnLayer:toJSON()
	local json = {}
	json["out_depth"] = self["out_depth"];
	json["out_sx"] = self["out_sx"];
	json["out_sy"] = self["out_sy"];
	json["layer_type"] = self["layer_type"];
	json["num_inputs"] = self["num_inputs"];
	json["l1_decay_mul"] = self["l1_decay_mul"];
	json["l2_decay_mul"] = self["l2_decay_mul"];
	json.filters = {}
	for i = 1, #self.filters do
		json.filters[#json.filters+1] = self.filters[i]:toJSON();
	end

	json.biases = self.biases:toJSON();
	return json;
end

function FullyConnLayer:fromJSON(json)
	self["out_depth"] = json["out_depth"];
	self["out_sx"] = json["out_sx"];
	self["out_sy"] = json["out_sy"];
	self["layer_type"] = json["layer_type"];
	self["num_inputs"] = json["num_inputs"];
	self["l1_decay_mul"] = json["l1_decay_mul"] or 1
	self["l2_decay_mul"] = json["l2_decay_mul"] or 1;
		
	self.filters = {}
	for i = 1, #json.filters do
		local v = ConvNet.Vol:new():Init(0, 0, 0, 0);
		v:fromJSON(json.filters[i]);
		self.filters[#self.filters + 1] = v
	end

	self.biases = ConvNet.Vol:new():Init(0, 0, 0, 0);
	self.biases:fromJSON(json.biases);
end