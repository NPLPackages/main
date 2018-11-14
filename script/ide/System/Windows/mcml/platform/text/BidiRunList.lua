--[[
Title: 
Author(s): LiPeng
Date: 2018/3/27
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/text/BidiRunList.lua");
local BidiRunList = commonlib.gettable("System.Windows.mcml.platform.text.BidiRunList");
------------------------------------------------------------
]]

local BidiRunList = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.platform.text.BidiRunList"));

function BidiRunList:ctor()
	self.firstRun = nil;
    self.lastRun = nil;
    self.logicallyLastRun = nil;
    self.runCount = 0;
end

function BidiRunList:FirstRun()
	return self.firstRun;
end

function BidiRunList:LastRun()
	return self.lastRun;
end

function BidiRunList:LogicallyLastRun()
	return self.logicallyLastRun;
end

function BidiRunList:RunCount()
	return self.runCount;
end

function BidiRunList:AddRun(run)
	if (not self.firstRun) then
        self.firstRun = run;
    else
        self.lastRun.next = run;
	end
    self.lastRun = run;
    self.runCount = self.runCount + 1;
end

function BidiRunList:PrependRun(run)
	--ASSERT(!run->m_next);

    if (not self.lastRun) then
        self.lastRun = run;
    else
        run.next = self.firstRun;
	end
    self.firstRun = run;
    self.runCount = self.runCount + 1;
end

function BidiRunList:MoveRunToEnd(run)
--	ASSERT(m_firstRun);
--    ASSERT(m_lastRun);
--    ASSERT(run->m_next);

    local current = nil;
    local next = self.firstRun;
    while (next ~= run) do
        current = next;
        next = current:Next();
    end

    if (not current) then
        self.firstRun = run:Next();
    else
        current.next = run.next;
	end
    run.next = nil;
    self.lastRun.next = run;
    self.lastRun = run;
end

function BidiRunList:MoveRunToBeginning(run)
--	ASSERT(m_firstRun);
--    ASSERT(m_lastRun);
--    ASSERT(run != m_firstRun);

    local current = self.firstRun;
    local next = current:Next();
    while (next ~= run) do
        current = next;
        next = current:Next();
    end

    current.next = run.next;
    if (run == self.lastRun) then
        self.lastRun = current;
	end

    run.next = self.firstRun;
    self.firstRun = run;
end

function BidiRunList:DeleteRuns()
	if (not self.firstRun) then
        return;
	end

    local curr = self.firstRun;
    while (curr) do
        local s = curr:Next();
        curr:Destroy();
        curr = s;
    end

	self.firstRun = nil;
    self.lastRun = nil;
    self.runCount = 0;
end

function BidiRunList:ReverseRuns(_start, _end)
	if (_start >= _end) then
        return;
	end

    --ASSERT(end < self.runCount);

    -- Get the item before the start of the runs to reverse and put it in
    -- |beforeStart|. |curr| should point to the first run to reverse.
    local curr = self.firstRun;
    local beforeStart = nil;
    local i = 0;
    while (i < _start) do
        i = i + 1;
        beforeStart = curr;
        curr = curr:Next();
    end

    local startRun = curr;
    while (i < _end) do
        i = i + 1;
        curr = curr:Next();
    end
    local endRun = curr;
    local afterEnd = curr:Next();

    i = start;
    curr = startRun;
    local newNext = afterEnd;
    while (i <= _end) do
        -- Do the reversal.
        local next = curr:Next();
        curr.next = newNext;
        newNext = curr;
        curr = next;
        i = i + 1;
    end

    -- Now hook up beforeStart and afterEnd to the startRun and endRun.
    if (beforeStart) then
        beforeStart.next = endRun;
    else
        self.firstRun = endRun;
	end

    startRun.next = afterEnd;
    if (not afterEnd) then
        self.lastRun = startRun;
	end
end

function BidiRunList:ReorderRunsFromLevels()

end

function BidiRunList:SetLogicallyLastRun(run)
	self.logicallyLastRun = run;
end

function BidiRunList:ReplaceRunWithRuns(toReplace, newRuns)
--	ASSERT(newRuns.runCount());
--    ASSERT(m_firstRun);
--    ASSERT(toReplace);

    if (self.firstRun == toReplace) then
        self.firstRun = newRuns:FirstRun();
    else
        -- Find the run just before "toReplace" in the list of runs.
        local previousRun = self.firstRun;
        while (previousRun:Next() ~= toReplace) do
            previousRun = previousRun:Next();
		end
        --ASSERT(previousRun);
        previousRun:SetNext(newRuns:FirstRun());
    end

    newRuns:LastRun():SetNext(toReplace:Next());

    -- Fix up any of other pointers which may now be stale.
    if (self.lastRun == toReplace) then
        self.lastRun = newRuns:LastRun();
	end
    if (self.logicallyLastRun == toReplace) then
        self.logicallyLastRun = newRuns:LogicallyLastRun();
	end
    self.runCount = self.runCount + newRuns:RunCount() - 1; -- We added the new runs and removed toReplace.

    toReplace:Destroy();
    newRuns:ClearWithoutDestroyingRuns();
end

function BidiRunList:ClearWithoutDestroyingRuns()
	self.firstRun = nil;
    self.lastRun = nil;
    self.logicallyLastRun = nil;
    self.runCount = 0;
end

function BidiRunList:print()
	echo("BidiRunList:print");
	if(self.firstRun) then
		local run = self.firstRun;
		local run_index = 1;
		while(run) do
			echo("run_index:"..run_index);
			run.object:PrintNodeInfo();
			run_index = run_index + 1;
			run = run:Next();
		end
	end
end