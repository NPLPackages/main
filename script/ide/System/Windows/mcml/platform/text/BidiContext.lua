--[[
Title: 
Author(s): LiPeng
Date: 2018/3/28
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/text/BidiContext.lua");
local BidiContext = commonlib.gettable("System.Windows.mcml.platform.text.BidiContext");
------------------------------------------------------------
]]

local BidiContext = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.platform.text.BidiContext"));

function BidiContext:ctor()
	self.level = nil;
    self.direction = nil; -- Direction
    self.override = nil;
    self.source = nil; -- BidiEmbeddingSource
    self.parent = nil;

	local mt = getmetatable(self);
	mt.__eq = BidiContext.Equal;
end

function BidiContext:init(level, direction, override, source, parent)
	self.level = level;
    self.direction = direction; -- Direction
    self.override = override;
    self.source = source; -- BidiEmbeddingSource
    self.parent = parent;
	return self;
end

function BidiContext:Parent()
	return self.parent;
end

function BidiContext:Level()
	return self.level;
end

function BidiContext:Dir()
	return self.direction;
end

function BidiContext:Override()
	return self.override;
end

function BidiContext:Source()
	return self.source;
end

function BidiContext.CreateUncached(level, direction, override, source, parent)
	return BidiContext:new():init(level, direction, override, source, parent);
end

function BidiContext.Create(level, direction, override, source, parent)
	override = if_else(override == nil, false, override);
	source = source or "FromStyleOrDOM";

	--ASSERT(direction == (level % 2 ? RightToLeft : LeftToRight));

    if (parent) then
        return BidiContext.CreateUncached(level, direction, override, source, parent);
	end

    --ASSERT(level <= 1);
    if (level == 0) then
        if (not override) then
            local ltrContext = BidiContext.CreateUncached(0, "LeftToRight", false, "FromStyleOrDOM", nil);
            return ltrContext;
        end

        local ltrOverrideContext = BidiContext.CreateUncached(0, "LeftToRight", true, "FromStyleOrDOM", nil);
        return ltrOverrideContext;
    end

    if (not override) then
        local rtlContext = BidiContext.CreateUncached(1, "RightToLeft", false, "FromStyleOrDOM", nil);
        return rtlContext;
    end

    local rtlOverrideContext = BidiContext.CreateUncached(1, "RightToLeft", true, "FromStyleOrDOM", nil);
    return rtlOverrideContext;
end

--inline unsigned char nextGreaterOddLevel(unsigned char level)
local function nextGreaterOddLevel(level)
    return mathlib.bit.bor(level + 1, 1);
end

--inline unsigned char nextGreaterEvenLevel(unsigned char level)
local function nextGreaterEvenLevel(level)
    return mathlib.bit.band(level + 2, mathlib.bit.bnot(1));
end

--static inline PassRefPtr<BidiContext> copyContextAndRebaselineLevel(BidiContext* context, BidiContext* parent)
local function copyContextAndRebaselineLevel(context, parent)
    --ASSERT(context);
	local newLevel = 0;
	if(parent) then
		newLevel = parent:Level();
	end
    if (context:Dir() == "RightToLeft") then
        newLevel = nextGreaterOddLevel(newLevel);
    elseif (parent) then
        newLevel = nextGreaterEvenLevel(newLevel);
	end

    return BidiContext.Create(newLevel, context:Dir(), context:Override(), context:Source(), parent);
end

function BidiContext:CopyStackRemovingUnicodeEmbeddingContexts()
	local contexts = {};
	local iter = self;
	while(iter) do
		if (iter:Source() ~= "FromUnicode") then
            contexts[#contexts+1] = iter;
		end

		iter = iter:Parent();
	end

    --ASSERT(contexts.size());
 
	local topContext = copyContextAndRebaselineLevel(contexts[#contexts], nil);

	for i = #contexts, 2, -1 do
		topContext = copyContextAndRebaselineLevel(contexts[i - 1], topContext);
	end

    return topContext;
end

function BidiContext:Equal(other)
    if (self:Level() ~= other:Level() or self:Override() ~= other:Override() or self:Dir() ~= other:Dir() or self:Source() ~= other:Source()) then
        return false;
	end
    if (self:Parent() == nil) then
        return other:Parent() == nil;
	end
    return other:Parent() ~= nil and self:Parent() == other:Parent();
end