--[[
Title: ThreadWorker
Author(s): LiXizhi@yeah.net
Date: 2023/5/18
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Concurrent/ThreadWorker.lua");
local ThreadWorker = commonlib.gettable("System.Concurrent.ThreadWorker");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/System.lua");

local ThreadWorker = commonlib.inherit(nil, commonlib.gettable("System.Concurrent.ThreadWorker"));

function ThreadWorker:ctor()
	self.functionToIds = {};
	self.sandboxEnvFuncs = {}; -- keep track of sandbox envs
end

function ThreadWorker:Init(name)
	self.name = name;
	return self;
end

function ThreadWorker:GetName()
	return self.name;
end

function ThreadWorker:SetSandboxEnvFunc(name, func)
	self.sandboxEnvFuncs[name] = func;
end

function ThreadWorker:GetSandboxEnvFunc(name)
	return self.sandboxEnvFuncs[name];
end

function ThreadWorker:GetFunctionId(mainFuncStr)
	return self.functionToIds[mainFuncStr]
end

function ThreadWorker:SetFunctionId(mainFuncStr, id)
	self.functionToIds[mainFuncStr] = id;
end

-- return gen_id of the most recent request
function ThreadWorker:GetCurrentMsgQueueSize()
	local thread = __rts__;
	local nSize = thread:GetCurrentQueueSize();
	-- local msg = thread:PeekMessage(i, {filename=true, msg=true});
	-- thread:PopMessageAt(i, {});
	return nSize;
end
