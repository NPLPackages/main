--[[
Title: ConvNet Deep Q Learning
Author(s): LiXizhi
Date: 2022/9/8
Desc: More demo info, please refer to https://cs.stanford.edu/people/karpathy/convnetjs/demo/rldemo.html

use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ConvNet/DeepQLearn.lua");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Util/ConvNet/ConvNet.lua");
local DeepQLearn = commonlib.gettable("System.Util.ConvNet.DeepQLearn");
local ConvNet = commonlib.gettable("System.Util.ConvNet");
local Brain = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.DeepQLearn.Brain"));
local Experience = commonlib.inherit(nil, commonlib.gettable("System.Util.ConvNet.DeepQLearn.Experience"));

function Brain:ctor()
end

-- An agent is in state0 and does action0
-- environment then assigns reward0 and provides new state, state1
-- Experience nodes store all this information, which is used in the
-- Q-learning update step
function Experience:Init(state0, action0, reward0, state1)
	self.state0 = state0;
	self.action0 = action0;
	self.reward0 = reward0;
	self.state1 = state1;
	return self
end

-- A Brain object does all the magic. over time it receives some inputs and some rewards
-- and its job is to set the outputs to maximize the expected reward
function Brain:Init(num_states, num_actions, opt)
	local opt = opt or {};
	-- in number of time steps, of temporal memory
	-- the ACTUAL input to the net will be (x,a) temporal_window times, and followed by current x
	-- so to have no information from previous time step going into value function, set to 0.
	self.temporal_window = opt.temporal_window or 1; 
	-- size of experience replay memory
	self.experience_size = opt.experience_size or 30000;
	-- number of examples in experience replay memory before we begin learning
	self.start_learn_threshold = opt.start_learn_threshold or math.floor(math.min(self.experience_size * 0.1, 1000)); 
	-- gamma is a crucial parameter that controls how much plan-ahead the agent does. In [0,1]
	self.gamma = opt.gamma or 0.8;
    
	-- number of steps we will learn for
	self.learning_steps_total = opt.learning_steps_total or 100000;
	-- how many steps of the above to perform only random actions (in the beginning)?
	self.learning_steps_burnin = opt.learning_steps_burnin or 3000;
	-- what epsilon value do we bottom out on? 0.0 => purely deterministic policy at end
	self.epsilon_min = opt.epsilon_min or 0.05;
	-- what epsilon to use at test time? (i.e. when learning is disabled)
	self.epsilon_test_time = opt.epsilon_test_time or 0.01;
    
	-- advanced feature. Sometimes a random action should be biased towards some values
	-- for example in flappy bird, we may want to choose to not flap more often
	if(opt.random_action_distribution) then
		-- this better sum to 1 by the way, and be of length self.num_actions
		self.random_action_distribution = opt.random_action_distribution;
		if(#self.random_action_distribution ~= num_actions) then
			LOG.std(nil, "warn", "Brain", 'TROUBLE. random_action_distribution should be same length as num_actions.');
		end
		local a = self.random_action_distribution;
		local s = 0.0; 
		for k = 1, #a.length do
			s = s + a[k];
		end
		if(math.abs(s-1.0)>0.0001) then
			LOG.std(nil, "warn", "Brain", 'TROUBLE. random_action_distribution should sum to 1!');
		end
	else
		self.random_action_distribution = {};
	end
    
	-- states that go into neural net to predict optimal action look as
	-- x0,a0,x1,a1,x2,a2,...xt
	-- this variable controls the size of that temporal window. Actions are
	-- encoded as 1-of-k hot vectors
	self.net_inputs = num_states * self.temporal_window + num_actions * self.temporal_window + num_states;
	self.num_states = num_states;
	self.num_actions = num_actions;
	self.window_size = math.max(self.temporal_window, 2); -- must be at least 2, but if we want more context even more
	self.state_window = commonlib.Array:new(); -- array of self.window_size
	self.action_window = commonlib.Array:new(); -- array of self.window_size
	self.reward_window = commonlib.Array:new(); -- array of self.window_size
	self.net_window = commonlib.Array:new(); -- array of self.window_size
    
	-- create [state -> value of all possible actions] modeling net for the value function
	local layer_defs = {};
	if(opt.layer_defs) then
		-- this is an advanced usage feature, because size of the input to the network, and number of
		-- actions must check out. This is not very pretty Object Oriented programming but I can't see
		-- a way out of it :(
		layer_defs = opt.layer_defs;
		if(#layer_defs < 2) then
			LOG.std(nil, "warn", "Brain", 'TROUBLE! must have at least 2 layers');
		end
		if(layer_defs[1].type ~= 'input') then
			LOG.std(nil, "warn", "Brain", 'TROUBLE! first layer must be input layer!');
		end
		if(layer_defs[#layer_defs].type ~= 'regression') then
			LOG.std(nil, "warn", "Brain", 'TROUBLE! last layer must be input regression!');
		end
		if(layer_defs[1].out_depth * layer_defs[1].out_sx * layer_defs[1].out_sy ~= self.net_inputs) then
			LOG.std(nil, "warn", "Brain", 'TROUBLE! Number of inputs must be num_states * temporal_window + num_actions * temporal_window + num_states!');
		end
		if(layer_defs[#layer_defs].num_neurons ~= self.num_actions) then
			LOG.std(nil, "warn", "Brain", 'TROUBLE! Number of regression neurons should be num_actions!');
		end
	else
		-- create a very simple neural net by default
		layer_defs[#layer_defs+1] = {type='input', out_sx=1, out_sy=1, out_depth=self.net_inputs}
		if(opt.hidden_layer_sizes) then
			-- allow user to specify this via the option, for convenience
			local hl = opt.hidden_layer_sizes;
			for k=01, #hl do
				layer_defs[#layer_defs+1] = {type='fc', num_neurons=hl[k], activation='relu'}; -- relu by default
			end
		end
		layer_defs[#layer_defs+1] = {type='regression', num_neurons=num_actions}; -- value function output
	end
	self.value_net = ConvNet:new():Init();
	self.value_net:makeLayers(layer_defs);
    
	-- and finally we need a Temporal Difference Learning trainer!
	local tdtrainer_options = opt.tdtrainer_options or {learning_rate=0.01, momentum=0.0, batch_size=64, l2_decay=0.01};
	
	self.tdtrainer = ConvNet.SGDTrainer:new():Init(self.value_net, tdtrainer_options);
    
	-- experience replay
	self.experience = commonlib.Array:new();
    
	-- various housekeeping variables
	self.age = 0; -- incremented every backward()
	self.forward_passes = 0; -- incremented every forward()
	self.epsilon = 1.0; -- controls exploration exploitation tradeoff. Should be annealed over time
	self.latest_reward = 0;
	self.last_input_array = {};
	self.average_reward_window = ConvNet.Window:new():Init(1000, 10);
	self.average_loss_window = ConvNet.Window:new():Init(1000, 10);
	self.learning = true;
	return self;
end

function Brain:random_action()
    -- a bit of a helper function. It returns a random action
    -- we are abstracting this away because in future we may want to 
    -- do more sophisticated things. For example some actions could be more
    -- or less likely at "rest"/default state.
    if(#self.random_action_distribution == 0) then
		return ConvNet.randi(0, self.num_actions);
	else
		-- okay, lets do some fancier sampling:
		local p = ConvNet.randf(0, 1.0);
		local cumprob = 0.0;
		for k=1, self.num_actions do
			cumprob = cumprob + self.random_action_distribution[k];
			if(p < cumprob) then
				return k;
			end
		end
		return self.num_actions;
    end
end

-- use deep learning and max-action-value policy to return the action. 
function Brain:policy(s)
    -- compute the value of doing any action in this state
    -- and return the argmax action and its value
    local svol = ConvNet.Vol:new():Init(1, 1, self.net_inputs);
    svol.w = s;
    local action_values = self.value_net:forward(svol);
    local maxk = 1 
    local maxval = action_values.w[1];
    for k=2, self.num_actions do
		if(action_values.w[k] > maxval) then
			maxk = k; 
			maxval = action_values.w[k];
		end
    end
    return {action = maxk, value = maxval};
end

function Brain:getNetInput(xt)
    -- return s = (x,a,x,a,x,a,...xt) state vector. 
    -- It's a concatenation of last window_size (x,a) pairs and current state x
    local w = commonlib.Array:new();
    w:concat(xt); -- start with current state
    -- and now go backwards and append states and actions from history temporal_window times
    local n = self.window_size; 
    for k=1, self.temporal_window do
		-- state
		w:concat(self.state_window[n+1-k]);
		-- action, encoded as 1-of-k indicator vector. We scale it up a bit because
		-- we dont want weight regularization to undervalue this information, as it only exists once
		local action1ofk = {};
		for q=1, self.num_actions do
			action1ofk[q] = 0.0;
		end
		action1ofk[self.action_window[n+1-k]] = 1.0*self.num_states;
		w:concat(action1ofk);
    end
    return w;
end

-- @param input_array: current x(t) state
function Brain:forward(input_array)
    -- compute forward (behavior) pass given the input neuron signals from body
    self.forward_passes = self.forward_passes + 1;
    self.last_input_array = input_array; -- back this up
      
    -- create network input
    local action;
	local net_input;
    if(self.forward_passes > self.temporal_window) then
		-- we have enough to actually do something reasonable
		net_input = self:getNetInput(input_array);
		if(self.learning) then
			-- compute epsilon for the epsilon-greedy policy
			self.epsilon = math.min(1.0, math.max(self.epsilon_min, 1.0-(self.age - self.learning_steps_burnin)/(self.learning_steps_total - self.learning_steps_burnin))); 
		else
			self.epsilon = self.epsilon_test_time; -- use test-time value
		end
		local rf = ConvNet.randf(0,1);
		if(rf < self.epsilon) then
			-- choose a random action with epsilon probability
			action = self:random_action();
		else
			-- otherwise use our policy to make decision
			local maxact = self:policy(net_input);
			action = maxact.action;
		end
	else
		-- pathological case that happens first few iterations 
		-- before we accumulate window_size inputs
		net_input = {};
		action = self:random_action();
    end
      
    -- remember the state and action we took for backward pass
    self.net_window:pop_front();
    self.net_window:push_back(net_input);
    self.state_window:pop_front(); 
    self.state_window:push_back(input_array);
    self.action_window:pop_front(); 
    self.action_window:push_back(action);
      
    return action;
end

function Brain:backward(reward)
    self.latest_reward = reward;
    self.average_reward_window:add(reward);
    self.reward_window:pop_front();
    self.reward_window:push_back(reward);
      
    if(not self.learning) then
		return
	end
      
    -- various book-keeping
    self.age = self.age + 1;
      
    -- it is time t+1 and we have to store (s_t, a_t, r_t, s_{t+1}) as new experience
    -- (given that an appropriate number of state measurements already exist, of course)
    if(self.forward_passes > self.temporal_window + 1) then
		local e = Experience:new():Init();
		local n = self.window_size;
		e.state0 = self.net_window[n-1];
		e.action0 = self.action_window[n-1];
		e.reward0 = self.reward_window[n-1];
		e.state1 = self.net_window[n];
		if(#self.experience < self.experience_size) then
			self.experience:push_back(e);
		else
			-- replace. finite memory!
			local ri = ConvNet.randi(1, self.experience_size);
			self.experience[ri] = e;
		end
	end
      
	-- learn based on experience, once we have some samples to go on
	-- this is where the magic happens...
	if(#self.experience > self.start_learn_threshold) then
		local avcost = 0.0;
		for k=1, self.tdtrainer.batch_size do
			local re = ConvNet.randi(1, #self.experience); -- pick a random experience to learn from
			local e = self.experience[re];
			local x = ConvNet.Vol:new():Init(1, 1, self.net_inputs);
			x.w = e.state0;
			local maxact = self:policy(e.state1); -- replay this experience
			local r = e.reward0 + self.gamma * maxact.value;
			local ystruct = {dim = e.action0, val = r};
			local loss = self.tdtrainer:train(x, ystruct);
			avcost = avcost + loss.loss;
		end
		avcost = avcost / self.tdtrainer.batch_size;
		self.average_loss_window:add(avcost);
    end
end

-- visualize the brain
function Brain:visSelf()
    local t = '';
    t = t..'experience replay size: ' .. self.experience.length .. '\n';
    t = t..'exploration epsilon: ' .. self.epsilon .. '\n';
    t = t..'age: ' .. self.age .. '\n';
    t = t..'average Q-learning loss: ' .. self.average_loss_window:get_average() .. '\n';
    t = t..'smooth-ish reward: ' .. self.average_reward_window:get_average() .. '\n';
    return t;
end

