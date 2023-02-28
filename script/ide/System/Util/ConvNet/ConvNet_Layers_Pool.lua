--[[
Title: ConvNet PoolLayer
Author(s): LiXizhi
Date: 2022/8/20
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet.lua");
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local layer = ConvNet.PoolLayer:new():Init({});
-------------------------------------------------------
]]
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local PoolLayer = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.PoolLayer"));

function PoolLayer:ctor()
end

function PoolLayer:Init(opt)
	opt = opt or {}
	-- required
	self.sx = opt.sx; -- filter size
	self["in_depth"] = opt["in_depth"];
	self["in_sx"] = opt["in_sx"];
	self["in_sy"] = opt["in_sy"];
	
	-- optional
	self.sy = opt.sy or self.sx
	self.stride = opt.stride or 2;
	self.pad = opt.pad or 0 -- amount of 0 padding to add around borders of input volume

	-- computed
	self["out_depth"] = self["in_depth"];
	self["out_sx"] = math.floor((self.in_sx + self.pad * 2 - self.sx) / self.stride + 1);
	self["out_sy"] = math.floor((self.in_sy + self.pad * 2 - self.sy) / self.stride + 1);
	self["layer_type"] = "pool";

	-- store switches for x,y coordinates for where the max comes from, for each output neuron
	self.switchx = ConvNet.zeros(self["out_sx"] * self["out_sy"] * self["out_depth"]);
	self.switchy = ConvNet.zeros(self["out_sx"] * self["out_sy"] * self["out_depth"]);

	return self;
end

function PoolLayer:forward(V, is_training)
	self.in_act = V;
	local A = ConvNet.Vol:new():Init(self["out_sx"], self["out_sy"], self["out_depth"], 0);
	-- a counter for switches
	local n = 1;
	for d = 1, self.out_depth do
		local x = - self.pad + 1
		local y = - self.pad + 1
		
		for ax = 1, self.out_sx do
			y = - self.pad + 1
			for ay = 1, self.out_sy do
				-- convolve centered at this particular location
				local a = -99999 -- hopefully small enough
				local winx = -1;
				local winy = -1;
				for fx = 0, self.sx - 1 do
					for fy = 0, self.sy - 1 do
						local oy = y + fy;
						local ox = x + fx;
						if(oy>=1 and oy<=V.sy and ox>=1 and ox<=V.sx) then
							local v = V:get(ox, oy, d);
							-- perform max pooling and store pointers to where
							-- the max came from. This will speed up backprop 
							-- and can help make nice visualizations in future
							if(v > a) then
								a = v;
								winx = ox;
								winy = oy;
							end
						end
					end
				end

				self.switchx[n] = winx;
				self.switchy[n] = winy;
				n = n + 1;
				A:set(ax, ay, d, a);
				y = y + self.stride
			end
			x = x + self.stride
		end
	end

	self.out_act = A;
	return self.out_act;
end

-- pooling layers have no parameters, so simply compute gradient wrt data here
function PoolLayer:backward()
	local V = self.in_act;
	V.dw = ConvNet.zeros(#V.w);
	local A = self.out_act;
	local n = 1;
	for d = 1, self.out_depth do
		x = -self.pad + 1
		y = -self.pad + 1
		for ax = 1, self.out_sx do
			y = -self.pad + 1
			for ay = 1, self.out_sy do
				local chain_grad = self.out_act:get_grad(ax, ay, d)
				V:add_grad(self.switchx[n], self.switchy[n], d, chain_grad);
				n = n + 1;
				y = y + self.stride
			end
			x = x + self.stride
		end
	end
end

function PoolLayer:getParamsAndGrads()
	return {}
end

function PoolLayer:toJSON()
	local json = {}
	json.sx = self.sx;
	json.sy = self.sy;
	json.stride = self.stride;
	json["in_depth"] = self["in_depth"];
	json["out_depth"] = self["out_depth"];
	json["out_sx"] = self["out_sx"];
	json["out_sy"] = self["out_sy"];
	json["layer_type"] = self["layer_type"];
	json.pad = self.pad;
	return json;
end

function PoolLayer:fromJSON(json)
	self["out_depth"] = json["out_depth"];
	self["out_sx"] = json["out_sx"];
	self["out_sy"] = json["out_sy"];
	self["layer_type"] = json["layer_type"];
	self.sx = json.sx;
	self.sy = json.sy;
	self.stride = json.stride;
	self["in_depth"] = json["in_depth"];
	self.pad = json.pad or 0;
	self.switchx = ConvNet.zeros(self["out_sx"] * self["out_sy"] * self["out_depth"]);
	self.switchy = ConvNet.zeros(self["out_sx"] * self["out_sy"] * self["out_depth"]);
end