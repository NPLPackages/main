--[[
Title: ConvNet helper functions
Author(s): LiXizhi
Date: 2022/8/20
Desc: A volume in convolutional neural network. A Vol is a [width, height, depth] array. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet_Util.lua", true);
local ConvNet = commonlib.gettable("System.Util.ConvNet")
echo(ConvNet.zeros(3))
local a = ConvNet.randperm(10)
echo(a)
echo(ConvNet.maxmin(a))

local window = ConvNet.Window:Init(100);
window:add(10)
window:get_average()
-------------------------------------------------------
]]
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local Window = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.Window"));

local return_v = false;
local v_val = 0;

-- Random number utilities
function ConvNet.gaussRandom()
	if return_v then
		return_v = false;
		return v_val;
	end

	local u = ((2 * math.random()) - 1);
	local v = ((2 * math.random()) - 1);
	local r = ((u * u) + (v * v));
	if(r == 0 or r > 1) then
		return ConvNet.gaussRandom();
	end

	local c = math.sqrt(((-2 * math.log(r)) / r));
	v_val =(v * c);  -- cache this
	return_v = true;
	return(u * c);
end

function ConvNet.randf(a, b)
	return math.random() * (b - a) + a;
end

function ConvNet.randi(a, b)
	return math.floor(math.random() * (b - a) + a);
end

function ConvNet.randn(mu, std)
	return mu + ConvNet.gaussRandom() * std;
end

-- return array of 0
function ConvNet.zeros(n)
	local array = commonlib.UnorderedArray:new()
	for i = 1, n do
		array[i] = 0;
	end
	return array;
end

-- return max and min of a given non-empty array.
function ConvNet.maxmin(w)
	if(not w or #w == 0) then
		return {};
	end
	local maxv = w[1];
	local minv = w[1];
	local maxi = 1;
	local mini = 1;
	local n = #w;
	for i = 2, n do
		if(w[i] > maxv) then
			maxv = w[i];
			maxi = i;
		end
		if(w[i] < minv) then
			minv = w[i];
			mini = i;
		end
	end
	return {
	maxi = maxi,
	maxv = maxv,
	mini = mini,
	minv = minv,
	dv =(maxv - minv),
	maxABS = math.max(math.abs(minv), math.abs(maxv))
	};
end

-- create random permutation of numbers, in range [1..n]
function ConvNet.randperm(n)
	local array = {};
	for i = 1, n do
		array[i] = i;
	end

	for i = n, 1, -1 do
		local j = math.floor(math.random() * i) + 1;
		array[i], array[j] = array[j], array[i];
	end
	return array;
end

-- sample from list lst according to probabilities in list probs
-- the two lists are of same size, and probs adds up to 1
function ConvNet.weightedSample(lst, probs)
	local p = ConvNet.randf(0, 1);
	local cumprob = 0;
	for k = 1, #lst do
		cumprob = cumprob + probs[k];
		if(p < cumprob) then
			return lst[k];
		end
	end
end

-- syntactic sugar function for getting default parameter values
function ConvNet.getopt(opt, field_name, default_value)
	if(type(field_name) == "string") then
        -- in case of single string
		return opt[field_name] or default_value
	else
        -- assume we are given a list of string instead
		local ret = default_value;
		for i = 1, #field_name do
			local f = field_name[i];
			if(opt[f]) then
				ret = opt[f];  -- overwrite return value
			end
		end
		return ret;
	end
end

-- @param v: in range 0-1
local function GetColorData(v)
	v = math.min(15, math.floor(v * 16))
	return v * 256 + v * 16 + v;
end
-- @param v: in range 0-1
local function GetColorDataNeg(v)
	v = math.min(15, math.floor(v * 16))
	return v
end
local function GetColorDataPos(v)
	v = math.min(15, math.floor(v * 16))
	return v * 256
end

-- visualize as a given activition volume
-- @param pos: {bx, by, bz, depthSpacing} where to draw
-- @param A: is the activation Vol() to use
-- @param draw_grads: if grads is true then gradients are used instead
-- @return total depth
function ConvNet.draw_activations(pos, A, draw_grads)
    -- get max and min activation to scale the maps automatically
	local w = draw_grads and A.dw or A.w;
	local mm = ConvNet.maxmin(w);
	local depthSpacing = pos[4] or 4;
	local minX, minY, minZ = pos[1], pos[2], pos[3]

	local bx, by, bz;
    -- activation map
	for d = 1, A.depth do 
		bz = minZ + (d-1) * depthSpacing
		for x = 1, A.sx do
			bx = minX + x-1
            
            -- if sx == 1, we will display along x axis
			if(A.sx == 1) then
				bz = minZ + x -1
				bx = minX + (d-1) * depthSpacing
			end
        
			for y = 1, A.sy do
				by = minY + A.sy - y
				local dval
				if(draw_grads) then
					local v = A:get_grad(x, y, d)
					dval = math.abs(v / mm.maxABS)
                    --dval = (v-mm.minv) / mm.dv;
					GameLogic.BlockEngine:SetBlock(bx, by, bz, 10, v >= 0 and GetColorDataPos(dval) or GetColorDataNeg(dval))
				else
					local v = A:get(x, y, d)
					local color
					if(mm.maxABS == mm.dv) then
						dval = (A:get(x, y, d)-mm.minv) / mm.dv;  
						color = GetColorData(dval)
					else
						dval = math.abs(v / mm.maxABS)
						color = v >= 0 and GetColorDataPos(dval) or GetColorDataNeg(dval)
					end
					GameLogic.BlockEngine:SetBlock(bx, by, bz, 10, color)
                    
                    --dval =(A:get(x, y, d)-mm.minv) / mm.dv;  
                    --GameLogic.BlockEngine:SetBlock(bx, by, bz, 10, GetColorData(dval))
				end
			end
		end
	end
    
	return A.sx == 1 and depthSpacing or A.depth * depthSpacing;
end

function ConvNet.CreateSignBlock(x, y, z, text, width)
	if(width == 3) then
		GameLogic.BlockEngine:SetBlock(x-1, y, z, 211, 3)
		GameLogic.BlockEngine:SetBlock(x + 1, y, z, 211, 3)
	end
	GameLogic.BlockEngine:SetBlock(x, y, z, 211, 3, nil, {attr = {}, {name = "cmd", text}})
end

function ConvNet.floatToString(v)
	return string.format("%.2f", v);
end

function ConvNet.PrintNet(net, trainer)
	local o = {};
	if(trainer) then
		o[#o + 1] = "\n\n==============convnet tostring: learning iteration " ..(trainer.k or 0);
	else
		o[#o + 1] = "\n\n==============convnet tostring";
	end
    
    -- show activations in each layer
	local N = #net.layers;
	for i = 1, N do
		local L = net.layers[i];
        
        -- print stats
		local t1 = (L.layer_type or "") .. ' layer(' .. L.out_sx .. 'x' .. L.out_sy .. 'x' .. L.out_depth .. ')';
		if(L.layer_type=='conv') then
			t1 = t1..""..'filter size ' .. L.filters[1].sx .. 'x' .. L.filters[1].sy .. 'x' .. L.filters[1].depth .. 'stride ' .. L.stride;
		end
		if(L.layer_type=='pool') then
			t1 = t1..'pooling size '..L.sx..'x'..L.sy..'stride '..L.stride;
		end
		o[#o + 1] = "Layer "..i.."  "..t1.."-------------------------------"
        
        -- number of parameters
		if(L.layer_type=='conv') then
			local tot_params = L.sx * L.sy * L.in_depth *(#L.filters) + (#L.filters);
			local t = 'parameters: '..(#L.filters)..'x'..L.sx..'x'..L.sy..'x'..L.in_depth..'+'..(#L.filters)..' = '..tot_params;
			o[#o + 1] = t
		end
		if(L.layer_type=='fc') then
			local tot_params = L.num_inputs *(#L.filters) + (#L.filters);
			local t = 'parameters: '..(#L.filters)..'x'..L.num_inputs..'+'..(#L.filters)..' = '..tot_params;
			o[#o + 1] = t
		end
        
		local mma = ConvNet.maxmin(L.out_act.w);
		local t = 'max: '..ConvNet.floatToString(mma.maxv)..'min: '..ConvNet.floatToString(mma.minv);
		o[#o + 1] = "output "..t
		o[#o + 1] = commonlib.serialize_compact(L.out_act.w)
        
        -- visualize data gradients
		if(L.layer_type ~= 'softmax') then
			if(L.layer_type=='softmax' or L.layer_type=='fc') then
				depth_scaling = 1; -- for softmax
			end
			local mma = ConvNet.maxmin(L.out_act.dw);
			local t = 'max: '..ConvNet.floatToString(mma.maxv)..'min: '..ConvNet.floatToString(mma.minv);
			o[#o + 1] = "output gradients "..t
			o[#o + 1] = commonlib.serialize_compact(L.out_act.dw)
		end
                
        -- visualize filters if they are of reasonable size
		if(L.filters) then
			o[#o + 1] = "weights/grads:"
			local s = {};
			for j = 1, #L.filters do
				s[#s + 1] = commonlib.serialize_compact(L.filters[j].w);
			end
			o[#o + 1] = table.concat(s, "::::")

			local s = {};
			for j = 1, #L.filters do
				s[#s + 1] = commonlib.serialize_compact(L.filters[j].dw);
			end
			o[#o + 1] = table.concat(s, "::::")
            
			if(L.biases) then
				o[#o + 1] = "biases/grads:"
				o[#o + 1] = commonlib.serialize_compact(L.biases.w);
				o[#o + 1] = commonlib.serialize_compact(L.biases.dw);
			end
		end
	end
	local str = table.concat(o, "\n")
	commonlib.log.log_long(str);
end

-- visualize all activations in a network. 
-- @param pos: {bx, by, bz, depthSpacing} where to draw, depthSpacing default to 4;
function ConvNet.visualize_activations(net, pos, bShowWeights)
    -- show activations in each layer
	local N = #net.layers;
	for i = 1, N do
		local L = net.layers[i];
    
		local depth = 0;
		if(L.layer_type=='softmax' or L.layer_type=='fc') then
            -- for softmax
		end
		local depth_spacing = L.out_act.sx > 1 and 4 or 1;
		depth = math.max(depth, ConvNet.draw_activations({pos[1], pos[2], pos[3], depth_spacing}, L.out_act));
        -- find min, max activations and display them
		local mma = ConvNet.maxmin(L.out_act.w);
		local t = 'max: '..ConvNet.floatToString(mma.maxv)..'\nmin: '..ConvNet.floatToString(mma.minv);
		ConvNet.CreateSignBlock(pos[1]-1, pos[2], pos[3], "output\n"..t)
        
        -- visualize data gradients
		if(L.layer_type ~= 'softmax') then
			if(L.layer_type=='softmax' or L.layer_type=='fc') then
				depth_scaling = 1; -- for softmax
			end
			local mma = ConvNet.maxmin(L.out_act.dw);
			local t = 'max: '..ConvNet.floatToString(mma.maxv)..'\nmin: '..ConvNet.floatToString(mma.minv);
        
			if(L.out_act.sx >1) then
				ConvNet.CreateSignBlock(pos[1] + (L.out_act.sx + 1), pos[2], pos[3], "output gradients\n"..t)
				depth = math.max(depth, ConvNet.draw_activations({pos[1] +(L.out_act.sx + 2), pos[2], pos[3], depth_spacing}, L.out_act, true));
			else
				ConvNet.CreateSignBlock(pos[1]-1, pos[2], pos[3] + depth + 2, "output gradients\n"..t)
				depth = depth + 1 + ConvNet.draw_activations({pos[1], pos[2], pos[3] + depth + 2, depth_spacing}, L.out_act, true);
			end
		end
                
        -- visualize filters if they are of reasonable size
		if(L.layer_type == 'conv') then
			if(L.filters[1].sx>3) then
                -- actual weights
				for j = 1, #L.filters do
					ConvNet.draw_activations({pos[1] + (L.filters[j].sx + 2) *(j-1), pos[2] +(L.out_act.sy + 2), pos[3], depth_spacing}, L.filters[j]);
				end

                -- gradients
				for j = 1, #L.filters do
					ConvNet.draw_activations({pos[1] + (L.filters[j].sx + 2) *(j-1), pos[2] +(L.out_act.sy + 2) +(L.filters[j].sy + 1), pos[3], depth_spacing}, L.filters[j], true);
				end
			else
                -- Weights hidden, too small
			end
		end
		if(L.layer_type == 'fc' and L.bShowWeights) then
            -- actual weights
			for j = 1, #L.filters do
				ConvNet.draw_activations({pos[1], pos[2] + 1 + j, pos[3], depth_spacing}, L.filters[j]);
			end
			ConvNet.CreateSignBlock(pos[1]-1, pos[2] + 2, pos[3], "param weights")

			local offset = L.filters[1].depth + 1
            -- gradients
			for j = 1, #L.filters do
				ConvNet.draw_activations({pos[1] + offset + 1, pos[2] + 1 + j, pos[3], depth_spacing}, L.filters[j], true);
			end
			ConvNet.CreateSignBlock(pos[1] + offset, pos[2] + 2, pos[3], "param gradients")
		end

        -- print some stats on left of the layer
		local t1 = (L.layer_type or "") .. ' layer\n(' .. L.out_sx .. 'x' .. L.out_sy .. 'x' .. L.out_depth .. ')';
    
		if(L.layer_type=='conv') then
			t1 = t1.."\n"..'filter size ' .. L.filters[1].sx .. 'x' .. L.filters[1].sy .. 'x' .. L.filters[1].depth .. '\nstride ' .. L.stride;
		end
		if(L.layer_type=='pool') then
			t1 = t1.."\n"..'pooling size '..L.sx..'x'..L.sy..'\nstride '..L.stride;
		end
    
		ConvNet.CreateSignBlock(pos[1]-2, pos[2], pos[3], t1, 1)
    
        -- number of parameters
		if(L.layer_type=='conv') then
			local tot_params = L.sx * L.sy * L.in_depth *(#L.filters) + (#L.filters);
			local t = 'parameters: '..(#L.filters)..'x'..L.sx..'x'..L.sy..'x'..L.in_depth..'+'..(#L.filters)..' = '..tot_params;
			ConvNet.CreateSignBlock(pos[1]-2, pos[2] + 1, pos[3], t, 3)
		end
		if(L.layer_type=='fc') then
			local tot_params = L.num_inputs *(#L.filters) + (#L.filters);
			local t = 'parameters: '..(#L.filters)..'x'..L.num_inputs..'+'..(#L.filters)..' = '..tot_params;
			ConvNet.CreateSignBlock(pos[1]-2, pos[2] + 1, pos[3], t, 3)
		end
		pos[3] = pos[3] + depth + 10;
	end
end

-- a window stores _size_ number of values
-- and returns averages. Useful for keeping running
-- track of validation or training accuracy during SGD
function Window:Init(size, minsize)
	self.v = commonlib.vector:new();
	self.size = size or 100;
	self.minsize = minsize or 20
	self.sum = 0;
	return self;
end

function Window:add(x)
	self.v:push_back(x);
	self.sum = self.sum + x;
	if(#self.v >self.size) then
		local xold = self.v:pop_front()
		self.sum = self.sum - xold;
	end
end

function Window:get_average()
	if(#self.v < self.minsize) then
		return -1;
	else 
		return self.sum / #(self.v);
	end
end

function Window:reset()
	self.v:clear()
	self.sum = 0;
end