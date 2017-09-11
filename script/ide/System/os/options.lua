--[[
Title: operating system options
Author(s): LiXizhi
Date: 2017/9/11
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/os/options.lua");
System.os.options:SetWorkerThreadsCount(2, 16);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/DOM.lua");
local DOM = commonlib.gettable("System.Core.DOM")

local options = commonlib.gettable("System.os.options");

-- make sure that there are nMaxCount workers threads processing the queue at nProcessorQueueID. 
-- worker threads of internal queues are created internally. 
-- [NOTE thread safe] function must be called by the main thread. 
-- @param nProcessorQueueID: [0, 16). And each processor thread can be associated with just one processor queue. Please note that, following are internal queues: 
-- queue[0] is for local CPU intensive tasks like unzip. (only one thread process it)
-- queue[1] is for remote background asset loading. (4 threads process it)
-- queue[2] is for remote REST URL request. (default to 2 threads process it)
-- @param nMaxCount: the max number of threads that can coexist for the nProcessorQueueID queue. 
function options.SetWorkerThreadsCount(nProcessorQueueID, nMaxCount)
	local asyncloader = DOM.GetDOM("AsyncLoader");
	if(asyncloader) then
		asyncloader:SetField("WorkerThreadsCount", {nProcessorQueueID, nMaxCount})
	end
end

-- message queue size of a given processor id
function options.SetProcessorQueueSize(nProcessorQueueID, nSize)
	local asyncloader = DOM.GetDOM("AsyncLoader");
	if(asyncloader) then
		asyncloader:SetField("ProcessorQueueSize", {nProcessorQueueID, nSize})
	end
end