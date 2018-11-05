--[[
Title: 
Author(s): LiPeng
Date: 2018/3/27
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/text/BidiResolver.lua");
local BidiResolver = commonlib.gettable("System.Windows.mcml.platform.text.BidiResolver");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/layout/InLineIterator.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/text/BidiRunList.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/BidiRun.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/platform/text/BidiContext.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local BidiContext = commonlib.gettable("System.Windows.mcml.platform.text.BidiContext");
local BidiRun = commonlib.gettable("System.Windows.mcml.layout.BidiRun");
local BidiRunList = commonlib.gettable("System.Windows.mcml.platform.text.BidiRunList");
local InlineIterator = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.InlineIterator"));

local BidiResolver = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.platform.text.BidiResolver"));

local MidpointState = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.platform.text.MidpointState"));

local BidiStatus = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.platform.text.BidiStatus"));

local BidiCharacterRun = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.platform.text.BidiCharacterRun"));

local TextDirectionEnum = ComputedStyleConstants.TextDirectionEnum;

function MidpointState:ctor()
	-- self.midpoints is a array of "InlineIterator";
    self.midpoints = commonlib.vector:new();
    self.numMidpoints = 0;
    self.currentMidpoint = 0;
    self.betweenMidpoints = false;
end

function MidpointState:init()
	self:Reset();

	return self;
end

function MidpointState:Reset()
    numMidpoints = 0;
    currentMidpoint = 0;
    betweenMidpoints = false;
end

function BidiStatus:ctor()
	self.eor = "OtherNeutral"; -- WTF::Unicode::Direction
    self.lastStrong = "OtherNeutral"; -- WTF::Unicode::Direction
    self.last = "OtherNeutral"; -- WTF::Unicode::Direction
    self.context = nil;

	local mt = getmetatable(self);
	mt.__eq = BidiStatus.Equal;
end

function BidiStatus:init(eorDir, lastStrongDir, lastDir, bidiContext)

	if(lastDir ~= nil and bidiContext ~= nil) then
		self.eor = eorDir; -- WTF::Unicode::Direction
		self.lastStrong = lastStrongDir; -- WTF::Unicode::Di
		self.last = lastDir; -- WTF::Unicode::Directio
		self.context = bidiContext;
	elseif(eorDir ~= nil and lastStrongDir ~= nil) then
		local textDirection, isOverride = eorDir, lastStrongDir;
		local direction = if_else(textDirection == TextDirectionEnum.LTR, "LeftToRight", "RightToLeft");
		self.eor, self.lastStrong, self.last = direction, direction, direction;
		local level = if_else(textDirection == TextDirectionEnum.LTR, 0, 1);
		self.context = BidiContext.Create(level, direction, isOverride);
	else
		self.context = BidiContext:new();
	end

	return self;
end

function BidiStatus:Equal(other)
	return self.eor == other.eor and self.last == other.last and self.lastStrong == other.lastStrong and self.context == other.context;
end


function BidiCharacterRun:ctor()
	self.level = nil;
    self.start = nil;
    self.stop = nil;
    self.override = nil;
    self.next = nil;
end

function BidiCharacterRun:init(start, stop, context, dir)
	self.start = start;
	self.stop = stop;

--	if (dir == WTF::Unicode::OtherNeutral)
--        dir = context->dir();
--
--    m_level = context->level();
--
--    // add level of run (cases I1 & I2)
--    if (m_level % 2) {
--        if (dir == WTF::Unicode::LeftToRight || dir == WTF::Unicode::ArabicNumber || dir == WTF::Unicode::EuropeanNumber)
--            m_level++;
--    } else {
--        if (dir == WTF::Unicode::RightToLeft)
--            m_level++;
--        else if (dir == WTF::Unicode::ArabicNumber || dir == WTF::Unicode::EuropeanNumber)
--            m_level += 2;
--    }

	return self;
end

function BidiCharacterRun:Destroy()
	self.next = nil;
end

function BidiCharacterRun:Start()
	return self.start;
end

function BidiCharacterRun:Stop()
	return self.stop;
end

function BidiCharacterRun:Level()
	return self.level;
end

function BidiCharacterRun:Reversed(visuallyOrdered)
	--return m_level % 2 && !visuallyOrdered;
end

function BidiCharacterRun:DirOverride(visuallyOrdered)
	--return m_override || visuallyOrdered;
end


function BidiCharacterRun:Next()
	return self.next;
end

function BidiCharacterRun:SetNext(next)
	self.next = next;
end
    

function BidiResolver:ctor()
	
end

function BidiResolver:init()
	self.current = self:CreateIterator();
    -- sor and eor are "start of run" and "end of run" respectively and correpond
    -- to abreviations used in UBA spec: http://unicode.org/reports/tr9/#BD7
    self.sor = self:CreateIterator(); -- Points to the first character in the current run.
    self.eor = self:CreateIterator(); -- Points to the last character in the current run.
    self.last = self:CreateIterator();
    self.status = nil;
    self.direction = "OtherNeutral";
    self.endOfLine = self:CreateIterator();
    self.reachedEndOfLine = false;
    self.lastBeforeET = self:CreateIterator(); -- Before a EuropeanNumberTerminator
    self.emptyRun = true;

    -- FIXME: This should not belong to the resolver, but rather be passed
    -- into createBidiRunsForLine by the caller.
    self.runs = BidiRunList:new();

    self.midpointState = MidpointState:new():init();

    self.nestedIsolateCount = 0;
    self.isolatedRuns = commonlib.vector:new();

	return self;
end

function BidiResolver:CreateIterator()
	
end

function BidiResolver:CreateResolver()
	
end

function BidiResolver:Position()
	return self.current;
end

function BidiResolver:SetPosition(position)
	self.current:Copy(position);
end

function BidiResolver:Increment()
	self.current:Increment();
end

function BidiResolver:Context()
	return self.status.context;
end

function BidiResolver:SetContext(context)
	self.status.context = context;
end

function BidiResolver:SetLastDir(lastDir)
	self.status.last = lastDir;
end

function BidiResolver:SetLastStrongDir(lastStrongDir)
	self.status.lastStrong = lastStrongDir;
end

function BidiResolver:SetEorDir(eorDir)
	self.status.eor = eorDir;
end

function BidiResolver:Dir()
	return self.direction;
end

function BidiResolver:SetDir(dir)
	self.direction = dir;
end

function BidiResolver:Status()
	return self.status;
end

function BidiResolver:SetStatus(status)
	self.status = status;
end

function BidiResolver:MidpointState()
	return self.midpointState;
end

-- The current algorithm handles nested isolates one layer of nesting at a time.
-- But when we layout each isolated span, we will walk into (and ignore) all
-- child isolated spans.
function BidiResolver:EnterIsolate()
	self.nestedIsolateCount = self.nestedIsolateCount + 1;
end

function BidiResolver:ExitIsolate()
	--ASSERT(m_nestedIsolateCount >= 1); 
	self.nestedIsolateCount = self.nestedIsolateCount - 1;
end

function BidiResolver:InIsolate()
	return self.nestedIsolateCount;
end

function BidiResolver:Embed(dir, source)
	-- TODO: add function later;
end

function BidiResolver:CommitExplicitEmbedding()
	-- TODO: add function later;
end

function BidiResolver:CreateBidiRunsForLine(_end, override, hardLineBreak)
	override = override or "NoVisualOverride";
	hardLineBreak = if_else(hardLineBreak == nil, false, hardLineBreak);

--	using namespace WTF::Unicode;
--
--    ASSERT(m_direction == OtherNeutral);

    if (override ~= "NoVisualOverride") then
        self.emptyRun = false;
        self.sor:Copy(self.current);
        self.eor = self:CreateIterator();
        while (self.current:Equal(_end) and not self.current:AtEnd()) do
            self.eor:Copy(self.current);
            self:Increment();
        end
        self.direction = if_else(override == "VisualLeftToRightOverride", "LeftToRight", "RightToLeft");
        self:AppendRun();
        self.runs:SetLogicallyLastRun(self.runs:LastRun());
        if (override == "VisualRightToLeftOverride") then
            self.runs:ReverseRuns(0, self.runs:RunCount() - 1);
		end
        return;
    end

	self.emptyRun = true;

    self.eor = self:CreateIterator();

    self.last:Copy(self.current);
    local pastEnd = false;
    local stateAtEnd = self:CreateResolver();
	while (true) do
        local dirCurrent;
        if (pastEnd and (hardLineBreak or self.current:AtEnd())) then
            local c = self:Context();
            if (hardLineBreak) then
                -- A deviation from the Unicode Bidi Algorithm in order to match
                -- WinIE and user expectations: hard line breaks reset bidi state
                -- coming from unicode bidi control characters, but not those from
                -- DOM nodes with specified directionality
                stateAtEnd:SetContext(c:CopyStackRemovingUnicodeEmbeddingContexts());

                dirCurrent = stateAtEnd:Context():Dir();
                stateAtEnd:SetEorDir(dirCurrent);
                stateAtEnd:SetLastDir(dirCurrent);
                stateAtEnd:SetLastStrongDir(dirCurrent);
            else
                while (c:Parent()) do
                    c = c:Parent();
				end
                dirCurrent = c:Dir();
            end
        else
            dirCurrent = self.current:Direction();
            if (self:Context():Override()
                    and dirCurrent ~= "RightToLeftEmbedding"
                    and dirCurrent ~= "LeftToRightEmbedding"
                    and dirCurrent ~= "RightToLeftOverride"
                    and dirCurrent ~= "LeftToRightOverride"
                    and dirCurrent ~= "PopDirectionalFormat") then
                dirCurrent = self:Context():Dir();
            elseif (dirCurrent == "NonSpacingMark") then
                dirCurrent = self.status.last;
			end
        end

		-- We ignore all character directionality while in unicode-bidi: isolate spans.
        -- We'll handle ordering the isolated characters in a second pass.
        if (self:InIsolate() ~= 0) then
            dirCurrent = "OtherNeutral";
		end
--      ASSERT(m_status.eor != OtherNeutral || m_eor.atEnd());
		if(dirCurrent == "LeftToRight") then
			
			self.eor:Copy(self.current);
            self.status.eor = "LeftToRight";
            self.status.lastStrong = "LeftToRight";
            self.direction = "LeftToRight";
		end
		if (pastEnd and self.eor:Equal(self.current)) then
            if (not self.reachedEndOfLine) then
                self.eor:Copy(self.endOfLine);
				if(self.status.eor == "LeftToRight" or self.status.eor == "RightToLeft" or self.status.eor == "ArabicNumber") then
					self.direction = self.status.eor;
				elseif(self.status.eor == "EuropeanNumber") then
					self.direction = if_else(self.status.lastStrong == "LeftToRight", "LeftToRight", "EuropeanNumber");
				end
                self:AppendRun();
            end
            self.current:Copy(_end);
            self.status = stateAtEnd.status;
            self.sor:Copy(stateAtEnd.sor); 
            self.eor:Copy(stateAtEnd.eor);
            self.last:Copy(stateAtEnd.last);
            self.reachedEndOfLine = stateAtEnd.reachedEndOfLine;
            self.lastBeforeET = stateAtEnd.lastBeforeET;
            self.emptyRun = stateAtEnd.emptyRun;
            self.direction = "OtherNeutral";
            break;
        end

		self:UpdateStatusLastFromCurrentDirection(dirCurrent);
        self.last:Copy(self.current);

        if (self.emptyRun) then
            self.sor:Copy(self.current);
            self.emptyRun = false;
        end

        self:Increment();
--        if (!m_currentExplicitEmbeddingSequence.isEmpty()) {
--            bool committed = commitExplicitEmbedding();
--            if (committed && pastEnd) {
--                m_current = end;
--                m_status = stateAtEnd.m_status;
--                m_sor = stateAtEnd.m_sor; 
--                m_eor = stateAtEnd.m_eor;
--                m_last = stateAtEnd.m_last;
--                m_reachedEndOfLine = stateAtEnd.m_reachedEndOfLine;
--                m_lastBeforeET = stateAtEnd.m_lastBeforeET;
--                m_emptyRun = stateAtEnd.m_emptyRun;
--                m_direction = OtherNeutral;
--                break;
--            }
--        }

        if (not pastEnd and (self.current:Equal(_end) or self.current:AtEnd())) then
            if (self.emptyRun) then
                break;
			end
            stateAtEnd.status = self.status;
            stateAtEnd.sor:Copy(self.sor);
            stateAtEnd.eor:Copy(self.eor);
            stateAtEnd.last:Copy(self.last);
            stateAtEnd.reachedEndOfLine = self.reachedEndOfLine;
            stateAtEnd.lastBeforeET = self.lastBeforeET;
            stateAtEnd.emptyRun = self.emptyRun;
            self.endOfLine:Copy(self.last);
            pastEnd = true;
        end
	end
	self.runs:SetLogicallyLastRun(self.runs:LastRun());
    self:ReorderRunsFromLevels();
    self.endOfLine = self:CreateIterator();
end

function BidiResolver:UpdateStatusLastFromCurrentDirection(dirCurrent)
	-- TODO: fixed function later;
	self.status.last = dirCurrent
end

function BidiResolver:ReorderRunsFromLevels()

end

function BidiResolver:Runs()
	return self.runs;
end

-- FIXME: This used to be part of deleteRuns() but was a layering violation.
-- It's unclear if this is still needed.
function BidiResolver:MarkCurrentRunEmpty()
	self.emptyRun = true;
end

function BidiResolver:IsolatedRuns()
	return self.isolatedRuns;
end

function BidiResolver:AppendRun()
	if (not self.emptyRun and not self.eor:AtEnd()) then
        local startOffset = self.sor:Offset();
        local endOffset = self.eor:Offset();

        if (not endOfLine:AtEnd() and endOffset >= endOfLine:Offset()) then
            self.reachedEndOfLine = true;
            endOffset = endOfLine:Offset();
        end

        if (endOffset >= startOffset) then
            self.runs:AddRun(BidiRun:new()(startOffset, endOffset + 1, context(), self.direction));
		end

        self.eor.increment();
        self.sor:Copy(self.eor);
    end

    self.direction = "OtherNeutral";
    --self.status.eor = WTF::Unicode::OtherNeutral;
end