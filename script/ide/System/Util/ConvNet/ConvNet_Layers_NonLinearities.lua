--[[
Title: ConvNet ReLu Layer
Author(s): LiXizhi
Date: 2022/8/20
Desc: Implements ReLU nonlinearity elementwise
x -> max(0, x)
the output is in [0, inf)

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet.lua");
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local layer = ConvNet.ReluLayer:new():Init({});
-------------------------------------------------------
]]
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local ReluLayer = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.ReluLayer"));
local SigmoidLayer = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.SigmoidLayer"));
local MaxoutLayer = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.MaxoutLayer"));
local TanhLayer = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.TanhLayer"));

function ReluLayer:ctor()
end

function ReluLayer:Init(opt)
	opt = opt or {};
	self["out_sx"] = opt["in_sx"];
	self["out_sy"] = opt["in_sy"];
	self["out_depth"] = opt["in_depth"];
	self["layer_type"] = "relu";
	return self
end

function ReluLayer:forward(V, is_training)
	self.in_act = V;
	local V2 = V:clone();
	local N = #V.w;
	local V2w = V2.w;
	for i = 1, N do
		if(V2w[i] < 0) then -- threshold at 0
			V2w[i] = 0;
		end
	end

	self.out_act = V2;
	return self.out_act;
end

function ReluLayer:backward()
	local V = self.in_act;
	local V2 = self.out_act;
	local N = #V.w;
	V.dw = ConvNet.zeros(N);
	for i = 1, N do
		if(V2.w[i] <= 0) then
			V.dw[i] = 0;
		else
			V.dw[i] = V2.dw[i];
		end
	end
end
function ReluLayer:getParamsAndGrads()
	return {};
end
function ReluLayer:toJSON()
	local json = {};
	json["out_depth"] = self["out_depth"];
	json["out_sx"] = self["out_sx"];
	json["out_sy"] = self["out_sy"];
	json["layer_type"] = self["layer_type"];
	return json;
end

function ReluLayer:fromJSON(json)
	self["out_depth"] = json["out_depth"];
	self["out_sx"] = json["out_sx"];
	self["out_sy"] = json["out_sy"];
	self["layer_type"] = json["layer_type"];
end

function SigmoidLayer:Init(opt)
	opt = opt or {};
	self["out_sx"] = opt["in_sx"];
	self["out_sy"] = opt["in_sy"];
	self["out_depth"] = opt["in_depth"];
	self["layer_type"] = "sigmoid";
	return self;
end

function SigmoidLayer:forward(V, is_training)
	self["in_act"] = V;
	local V2 = V:cloneAndZero();
	local N = #V.w;
	local V2w = V2.w;
	local Vw = V.w;
	for i = 1, N do
		V2w[i] =(1 / ( 1 + math.exp(-Vw[i])));
	end
	self["out_act"] = V2;
	return self["out_act"];
end

function SigmoidLayer:backward()
	local V = self["in_act"];
	local V2 = self["out_act"];
	local N = #V.w;
	V.dw = ConvNet.zeros(N);
	for i = 1, N do
		local v2wi = V2.w[i];
		V.dw[i] =((v2wi *(1 - v2wi)) * V2.dw[i]);
	end
end

function SigmoidLayer:getParamsAndGrads()
	return {}
end
function SigmoidLayer:toJSON()
	local json = {};
	json["out_depth"] = self["out_depth"];
	json["out_sx"] = self["out_sx"];
	json["out_sy"] = self["out_sy"];
	json["layer_type"] = self["layer_type"];
	return json;
end

function SigmoidLayer:fromJSON(json)
	self["out_depth"] = json["out_depth"];
	self["out_sx"] = json["out_sx"];
	self["out_sy"] = json["out_sy"];
	self["layer_type"] = json["layer_type"];
end

function MaxoutLayer:Init(opt)
	opt = opt or {};
	self["group_size"] = opt["group_size"] or 2;
	self["out_sx"] = opt["in_sx"];
	self["out_sy"] = opt["in_sy"];
	self["out_depth"] = math.floor((opt["in_depth"] / self["group_size"]));
	self["layer_type"] = "maxout";
	self.switches = ConvNet.zeros(((self["out_sx"] * self["out_sy"]) * self["out_depth"]));
	return self;
end
function MaxoutLayer:forward(V, is_training)
	local a2, j, ai, a, ix, i, y, x, n, V2, N;
	self["in_act"] = V;
	N = self["out_depth"];
	V2 = _new(Vol, self["out_sx"], self["out_sy"], self["out_depth"], 0);
	if((function()
		local _lev =(self["out_sx"] == 1);
		if _bool(_lev) then
			return(self["out_sy"] == 1);
		else
			return _lev;
		end
	end)()) then
		i = 0;
		while(_lt(i, N)) do
			ix =(i * self["group_size"]);
			a = V.w[ix];
			ai = 0;
			j = 1;
			while(_lt(j, self["group_size"])) do
				a2 = V.w[(_add(ix, j))];
				if(_gt(a2, a)) then
					a = a2;
					ai = j;
				end

				j = _inc(j);
			end

			V2.w[i] = a;
			self.switches[i] =(_add(ix, ai));
			i = _inc(i);
		end
	else
		n = 0;
		x = 0;
		while(_lt(x, V.sx)) do
			y = 0;
			while(_lt(y, V.sy)) do
				i = 0;
				while(_lt(i, N)) do
					ix =(i * self["group_size"]);
					a = V:get(x, y, ix);
					ai = 0;
					j = 1;
					while(_lt(j, self["group_size"])) do
						a2 = V:get(x, y,(_add(ix, j)));
						if(_gt(a2, a)) then
							a = a2;
							ai = j;
						end

						j = _inc(j);
					end

					V2:set(x, y, i, a);
					self.switches[n] =(_add(ix, ai));
					n = _inc(n);
					i = _inc(i);
				end

				y = _inc(y);
			end

			x = _inc(x);
		end
	end

	self["out_act"] = V2;
	do
		return self["out_act"];
	end
end
function MaxoutLayer:backward()
	local chain__grad, i, y, x, n, N, V2, V;
	V = self["in_act"];
	V2 = self["out_act"];
	N = self["out_depth"];
	V.dw = ConvNet.zeros(#V.w);
	if((function()
		local _lev =(self["out_sx"] == 1);
		if _bool(_lev) then
			return(self["out_sy"] == 1);
		else
			return _lev;
		end
	end)()) then
		i = 0;
		while(_lt(i, N)) do
			chain__grad = V2.dw[i];
			V.dw[self.switches[i]] = chain__grad;
			i = _inc(i);
		end
	else
		n = 0;
		x = 0;
		while(_lt(x, V2.sx)) do
			y = 0;
			while(_lt(y, V2.sy)) do
				i = 0;
				while(_lt(i, N)) do
					chain__grad =(function()
						local _self = V2;
						local _f = _self["get_grad"];
						return _f(_self, x, y, i);
					end)();
					(function()
						local _self = V;
						local _f = _self["set_grad"];
						return _f(
						_self,
						x,
						y,
						self.switches[n],
						chain__grad
						);
					end)();
					n = _inc(n);
					i = _inc(i);
				end

				y = _inc(y);
			end

			x = _inc(x);
		end
	end
end

function MaxoutLayer:getParamsAndGrads()
	return {}
end

function MaxoutLayer:toJSON()
	local json = {};
	json["out_depth"] = self["out_depth"];
	json["out_sx"] = self["out_sx"];
	json["out_sy"] = self["out_sy"];
	json["layer_type"] = self["layer_type"];
	json["group_size"] = self["group_size"];
	return json;
end
function MaxoutLayer:fromJSON(json)
	self["out_depth"] = json["out_depth"];
	self["out_sx"] = json["out_sx"];
	self["out_sy"] = json["out_sy"];
	self["layer_type"] = json["layer_type"];
	self["group_size"] = json["group_size"];
	self.switches = ConvNet.zeros(self["group_size"]);
end

function TanhLayer:ctor()
end

local function tanh(x)
	local y;
	y = math.exp(2 * x);
	return(y - 1) /(y + 1);
end

function TanhLayer:Init(opt)
	opt = opt or {};
	self["out_sx"] = opt["in_sx"];
	self["out_sy"] = opt["in_sy"];
	self["out_depth"] = opt["in_depth"];
	self["layer_type"] = "tanh";
	return self;
end
function TanhLayer:forward(V, is_training)
	self["in_act"] = V;
	local V2 = V:cloneAndZero();
	local N = #V.w;
	for i = 1, N do
		V2.w[i] = tanh(V.w[i]);
	end
	self["out_act"] = V2;
	return self["out_act"];
end
function TanhLayer:backward()
	local V = self["in_act"];
	local V2 = self["out_act"];
	local N = #V.w;
	V.dw = ConvNet.zeros(N);
	for i = 1, N do
		v2wi = V2.w[i];
		V.dw[i] =((1 -(v2wi * v2wi)) * V2.dw[i]);
	end
end

function TanhLayer:getParamsAndGrads()
	return {}
end

function TanhLayer:toJSON()
	local json = {}
	json["out_depth"] = self["out_depth"];
	json["out_sx"] = self["out_sx"];
	json["out_sy"] = self["out_sy"];
	json["layer_type"] = self["layer_type"];
	return json;
end

function TanhLayer:fromJSON(json)
	self["out_depth"] = json["out_depth"];
	self["out_sx"] = json["out_sx"];
	self["out_sy"] = json["out_sy"];
	self["layer_type"] = json["layer_type"];
end