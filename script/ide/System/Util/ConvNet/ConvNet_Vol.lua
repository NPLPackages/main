--[[
Title: ConvNet Vol
Author(s): LiXizhi
Date: 2022/8/20
Desc: Vol is the basic building block of all data in a net.
it is essentially just a 3D volume of numbers, with a width (sx), height (sy), and depth (depth).
it is used to hold data for all filters, all volumes, all weights, and also stores all gradients w.r.t. 
the data. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Vol.lua");
local Vol = commonlib.gettable("System.Util.ConvNet.Vol");
local neurons = Vol:new():Init(16, 16, 1);
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Util.lua");
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local Vol = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.Vol"));

function Vol:ctor()
end

-- @param c: c is optionally a value to initialize the volume with. 
-- If c is nil, fills the Vol with random numbers.
function Vol:Init(sx, sy, depth, c)
	if(type(sx) == "table") then
		-- we were given a list in sx, assume 1D volume and fill it up
		self.sx = 1;
		self.sy = 1;
		self.depth = #sx;
		self.w = ConvNet.zeros(self.depth);
		self.dw = ConvNet.zeros(self.depth);
		for i = 1, self.depth do
			self.w[i] = sx[i];
		end
	else
		-- we were given dimensions of the vol
		self.sx = sx;
		self.sy = sy;
		self.depth = depth;
		local n = ((sx * sy) * depth);
		self.w = ConvNet.zeros(n);
		self.dw = ConvNet.zeros(n);
		if(not c) then
			-- weight normalization is done to equalize the output
			-- variance of every neuron, otherwise neurons with a lot
			-- of incoming connections have outputs of larger variance
			local scale = math.sqrt((1/(sx * sy * depth)));
			for i = 1, n do
				self.w[i] = ConvNet.randn(0, scale);
			end
		else
			for i = 1, n do
				self.w[i] = c;
			end
		end
	end
	return self;
end

function Vol:get(x, y, d)
	local ix =((self.sx *(y-1) + x-1) * self.depth) + d;
	return self.w[ix];
end

function Vol:set(x, y, d, v)
	local ix =((self.sx *(y-1)) + x-1) * self.depth + d;
	self.w[ix] = v;
end

function Vol:add(x, y, d, v)
	local ix =((self.sx *(y-1)) + x-1) * self.depth + d;
	self.w[ix] = self.w[ix] + v
end

function Vol:get_grad(x, y, d)
	local ix =((self.sx *(y-1)) + x-1) * self.depth + d;
	return self.dw[ix];
end

function Vol:set_grad(x, y, d, v)
	local ix =((self.sx *(y-1)) + x-1) * self.depth + d;
	self.dw[ix] = v;
end

function Vol:add_grad(x, y, d, v)
	local ix =((self.sx *(y-1)) + x-1) * self.depth + d;
	self.dw[ix] = self.dw[ix] + v
end

function Vol:cloneAndZero()
	return Vol:new():Init(self.sx, self.sy, self.depth, 0);
end

function Vol:clone()
	local V = Vol:new():Init(self.sx, self.sy, self.depth, 0);
	for i=1, #(self.w) do
		V.w[i] = self.w[i];
	end
	return V;
end

function Vol:addFrom(V)
	for k=1, #self.w do
		self.w[k] = self.w[k] +  V.w[k]
	end
end

function Vol:addFromScaled(V, a)
	for k=1, #self.w do
		self.w[k] = self.w[k] + a * V.w[k]
	end
end

function Vol:setConst(a)
	for k=1, #self.w do
		self.w[k] = a
	end
end

function Vol:toJSON()
	local json = {}
	json.sx = self.sx;
	json.sy = self.sy;
	json.depth = self.depth;
	json.w = self.w;
	return json;
end

function Vol:fromJSON(json)
	self.sx = json.sx;
	self.sy = json.sy;
	self.depth = json.depth;
	local n = (self.sx * self.sy * self.depth);
	self.w = ConvNet.zeros(n);
	self.dw = ConvNet.zeros(n);
	for k=1, #self.w do
		self.w[i] = json.w[i];
	end
end 