--[[
Title: ConvNet Training class
Author(s): LiXizhi
Date: 2022/8/20
Desc: 

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet.lua");
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local layer = ConvNet.InputLayer:new():Init({});
-------------------------------------------------------
]]
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local Trainer = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.Trainer"));
ConvNet.SGDTrainer = Trainer

function Trainer:ctor()
end

function Trainer:Init(net, options)
	self.net = net;
	options = options or {};
	self["learning_rate"] = options["learning_rate"] or 0.01;
	self["l1_decay"] = options["l1_decay"] or 0
	self["l2_decay"] = options["l2_decay"] or 0
	self["batch_size"] = options["batch_size"] or 1;
	self.method = options.method or "sgd"; -- sgd/adam/adagrad/adadelta/windowgrad/netsterov
	self.momentum = options.momentum or 0.9
	self.ro = options.ro or 0.95;  -- used in adadelta
	self.eps = options.eps or 0.00000001; -- used in adam or adadelta
	self.beta1 = options.beta1 or 0.9; -- used in adam
	self.beta2 = options.beta2 or 0.999; -- used in adam
	self.k = 0; -- iteration counter
	self.gsum = {}; -- last iteration gradients (used for momentum calculations)
	self.xsum = {}; -- used in adam or adadelta

    -- check if regression is expected 
	if(self.net.layers[#(self.net.layers)]["layer_type"] == "regression") then
		self.regression = true;
	else
		self.regression = false;
	end
	return self
end

local function GetCurrentTime()
	return commonlib.TimerManager.timeGetTime()
end

function Trainer:train(x, y)
	local start_time = GetCurrentTime()
	self.net:forward(x, true);
	local end_time = GetCurrentTime()
	local fwd_time = (end_time - start_time);
	local start_time = GetCurrentTime();
	local cost_loss = self.net:backward(y);
	local l2_decay_loss = 0;
	local l1_decay_loss = 0;
	local end_time = GetCurrentTime()
	local bwd_time = (end_time - start_time);
	if(self.printFailingNet) then
		self.printFailingNet = false;
		ConvNet.PrintNet(self.net, self);
	end

	if(self.regression and type(y) ~= "table") then
		LOG.std(nil, "warn", "ConvNet.Trainer", "Warning: a regression net requires an array as training output vector.");
		return
	end

	self.k = self.k + 1
	self.batchIndex = self.k % self["batch_size"]
	if(self.batchIndex == 0) then
		local pglist = self.net:getParamsAndGrads();
        -- initialize lists for accumulators. Will only be done once on first iteration
		if(#self.gsum == 0 and(self.method ~= 'sgd' or self.momentum > 0.0)) then
            -- only vanilla sgd doesnt need either lists
            -- momentum needs gsum
            -- adagrad needs gsum
            -- adam and adadelta needs gsum and xsum
			for i = 1, #pglist do
				self.gsum[#self.gsum + 1] = ConvNet.zeros(#(pglist[i].params));
				if((self.method == "adam") or(self.method == "adadelta")) then
					self.xsum[#self.xsum + 1] = ConvNet.zeros(#(pglist[i].params));
				else
					self.xsum[#self.xsum + 1] = {}; -- conserve memory
				end
			end
		end

        -- perform an update for all sets of weights
		for i = 1, #pglist do
			local pg = pglist[i]; -- param, gradient, other options in future (custom learning rate etc)
			local p = pg.params;
			local g = pg.grads;
			local l2_decay_mul = pg["l2_decay_mul"] or 1
			local l1_decay_mul = pg["l1_decay_mul"] or 1;
			local l2_decay =(self["l2_decay"] * l2_decay_mul);
			local l1_decay =(self["l1_decay"] * l1_decay_mul);
			local plen = #p;
			for j = 1, plen do
				l2_decay_loss = l2_decay_loss +(l2_decay * p[j] * p[j] / 2); -- accumulate weight decay loss
				l1_decay_loss = l1_decay_loss +(l1_decay * math.abs(p[j]));
				local l1grad = l1_decay *((p[j] > 0) and 1 or -1)
				local l2grad = l2_decay * p[j];

				local gij = (l2grad + l1grad + g[j]) / self.batch_size; --  raw batch gradient
				local gsumi = self.gsum[i];
				local xsumi = self.xsum[i];
				if(self.method == "adam") then
                    -- adam update
					gsumi[j] = ((gsumi[j] * self.beta1) + ((1 - self.beta1) * gij)); -- update biased first moment estimate
					xsumi[j] = ((xsumi[j] * self.beta2) + (((1 - self.beta2) * gij) * gij)); -- update biased second moment estimate
					local biasCorr1 = (gsumi[j] * (1 - math.pow(self.beta1, self.k))); -- correct bias first moment estimate
					local biasCorr2 = (xsumi[j] * (1 - math.pow(self.beta2, self.k))); -- correct bias second moment estimate
					local dx = -self.learning_rate * biasCorr1 /(math.sqrt(biasCorr2) + self.eps);
					p[j] = p[j] + dx

				elseif(self.method == "adagrad") then
                    -- adagrad update
					gsumi[j] = gsumi[j] + gij * gij;
					local dx = - self.learning_rate / math.sqrt(gsumi[j] + self.eps) * gij;
					p[j] = p[j] + dx

				elseif(self.method == "windowgrad") then
                    -- this is adagrad but with a moving window weighted average
                    -- so the gradient is not accumulated over the entire history of the run. 
                    -- it's also referred to as Idea #1 in Zeiler paper on Adadelta. Seems reasonable to me!
					gsumi[j] = self.ro * gsumi[j] +(1 - self.ro) * gij * gij;
					local dx = - self.learning_rate / math.sqrt(gsumi[j] + self.eps) * gij; -- eps added for better conditioning
					p[j] = p[j] + dx

				elseif(self.method == "adadelta") then
					gsumi[j] = self.ro * gsumi[j] +(1 - self.ro) * gij * gij;
					local dx = - math.sqrt((xsumi[j] + self.eps) /(gsumi[j] + self.eps)) * gij;
					xsumi[j] = self.ro * xsumi[j] +(1 - self.ro) * dx * dx; -- yes, xsum lags behind gsum by 1.
					p[j] = p[j] + dx

				elseif(self.method == "nesterov") then
					local dx = gsumi[j];
					gsumi[j] = gsumi[j] * self.momentum + self.learning_rate * gij;
					dx = self.momentum * dx -(1 + self.momentum) * gsumi[j];
					p[j] = p[j] + dx
				else
                    -- assume SGD
					if(self.momentum > 0) then
                        -- momentum update
						local dx = self.momentum * gsumi[j] - self.learning_rate * gij;
						gsumi[j] = dx; -- back this up for next iteration of momentum
						p[j] = p[j] + dx -- apply corrected gradient
                        
                        -- @Note LiXizhi: for some reason, it will explode to NAN
                        --if(math.abs(dx) > 1) then
                        --    self.printFailingNet = true
                        --end
					else
                        -- vanilla sgd
						p[j] = p[j] - self.learning_rate * gij
					end
				end
				g[j] = 0; -- zero out gradient so that we can begin accumulating anew
			end
		end
	end

    -- appending softmax_loss for backwards compatibility, but from now on we will always use cost_loss
    -- in future, TODO: have to completely redo the way loss is done around the network as currently 
    -- loss is a bit of a hack. Ideally, user should specify arbitrary number of loss functions on any layer
    -- and it should all be computed correctly and automatically. 
	return {
	["fwd_time"] = fwd_time,
	["bwd_time"] = bwd_time,
	["l2_decay_loss"] = l2_decay_loss,
	["l1_decay_loss"] = l1_decay_loss,
	["cost_loss"] = cost_loss,
	["softmax_loss"] = cost_loss,
	["loss"] = cost_loss + l1_decay_loss + l2_decay_loss,
	};
end