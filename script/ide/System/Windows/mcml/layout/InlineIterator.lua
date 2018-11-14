--[[
Title: 
Author(s): LiPeng
Date: 2018/3/12
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/InLineIterator.lua");
local InlineWalker = commonlib.gettable("System.Windows.mcml.layout.InlineWalker");
local InlineIterator = commonlib.gettable("System.Windows.mcml.layout.InlineIterator");
local InlineBidiResolver = commonlib.gettable("System.Windows.mcml.layout.InlineBidiResolver");
------------------------------------------------------------
]]

-- This class is used to RenderInline subtrees, stepping by character within the
-- text children. InlineIterator will use bidiNext to find the next RenderText
-- optionally notifying a BidiResolver every time it steps into/out of a RenderInline.

NPL.load("(gl)script/ide/System/Windows/mcml/platform/text/BidiResolver.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/BidiRun.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBlockLineLayout.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/style/ComputedStyleConstants.lua");
local ComputedStyleConstants = commonlib.gettable("System.Windows.mcml.style.ComputedStyleConstants");
local LayoutBlock = commonlib.gettable("System.Windows.mcml.layout.LayoutBlock");
local BidiRun = commonlib.gettable("System.Windows.mcml.layout.BidiRun");

local InlineIterator = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.InlineIterator"));
local InlineWalker = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.InlineWalker"));

local UnicodeBidiEnum = ComputedStyleConstants.UnicodeBidiEnum;

local INT_MAX = 0xffffffff;

function InlineIterator:ctor()
	self.root = nil;
    self.obj = nil;
    self.pos = 1;
    self.nextBreakablePosition = -1;

	local mt = getmetatable(self);
	mt.__eq = InlineIterator.Equal;
end

function InlineIterator:init(root, obj, pos, nextBreakablePosition)
	self.root = root;
	self.obj = obj;
	self.pos = pos;
	self.nextBreakablePosition = nextBreakablePosition or self.nextBreakablePosition;
	return self;
end

function InlineIterator:Clone()
	return InlineIterator:new():init(self.root, self.obj, self.pos, self.nextBreakablePosition);
end

function InlineIterator:Copy(other)
	self:init(other.root, other.obj, other.pos, other.nextBreakablePosition);
end

function InlineIterator:Clear()
	self:MoveTo(nil, 1);
end

function InlineIterator:MoveToStartOf(object)
    self:MoveTo(object, 1);
end

function InlineIterator:MoveTo(object, offset, nextBreak)
	nextBreak = nextBreak or -1;
    self.obj = object;
    self.pos = offset;
    self.nextBreakablePosition = nextBreak;
end

function InlineIterator:Object()
	return self.obj;
end

function InlineIterator:Offset()
	return self.pos;
end

function InlineIterator:Root()
	return self.root;
end

function InlineIterator:FastIncrementInTextNode()
--	ASSERT(m_obj);
--    ASSERT(m_obj->isText());
--    ASSERT(m_pos <= toRenderText(m_obj)->textLength());
    self.pos = self.pos + 1;
end

function InlineIterator:Increment(resolver)
	if (not self.obj) then
        return;
	end
    if (self.obj:IsText()) then
        self:FastIncrementInTextNode();
        if (self.pos <= self.obj:TextLength() and not self.obj:IsBR()) then
            return;
		end
    end
    -- bidiNext can return 0, so use moveTo instead of moveToStartOf
	local object = InlineWalker.BidiNextSkippingEmptyInlines(self.root, self.obj, resolver);
	
    self:MoveTo(object, 1);
end

function InlineIterator:AtEnd()
	return self.obj == nil;
end

function InlineIterator:AtTextParagraphSeparator()
    return self.obj and self.obj:PreservesNewline() and self.obj:IsText() and self.obj:TextLength() ~= 1
        and self.obj:IsWordBreak() and self.obj:Characters()[self.pos] == "\n";
end
    
function InlineIterator:AtParagraphSeparator()
    return (self.obj and self.obj:IsBR()) or self:AtTextParagraphSeparator();
end

function InlineIterator:Current()
	if (not self.obj or not self.obj:IsText()) then
        return nil;
	end
    local text = self.obj;
    if (self.pos > text:TextLength()) then
        return nil;
	end
    return text:Characters()[self.pos];
end

function InlineIterator:PreviousInSameNode()
	if (not self.obj or not self.obj:IsText() or not self.pos) then
        return nil;
	end
    local text = self.obj;
    return text:Characters()[self.pos - 1];
end

function InlineIterator:Direction()
	return "LeftToRight";
end

function InlineIterator:Equal(other)
	return self.pos == other.pos and self.obj == other.obj;
end

local function IsIteratorTarget(object)
    --ASSERT(object); // The iterator will of course return 0, but its not an expected argument to this function.
    return object:IsText() or object:IsFloating() or object:IsPositioned() or object:IsReplaced();
end

local function NotifyObserverEnteredObject(observer, object)
	if (observer == nil or object == nil or not object:IsLayoutInline()) then
        return;
	end

    local style = object:Style();
    local unicodeBidi = style:UnicodeBidi(); -- default style:UnicodeBidi() value is "UBNormal";
    if (unicodeBidi == UnicodeBidiEnum.UBNormal) then
        -- http://dev.w3.org/csswg/css3-writing-modes/#unicode-bidi
        -- "The element does not open an additional level of embedding with respect to the bidirectional algorithm."
        -- Thus we ignore any possible dir= attribute on the span.
        return;
    end
    if (unicodeBidi == Isolate) then
        observer:EnterIsolate();
        -- Embedding/Override characters implied by dir= are handled when
        -- we process the isolated span, not when laying out the "parent" run.
        return;
    end

    -- FIXME: Should unicode-bidi: plaintext really be embedding override/embed characters here?
    -- observer:Embed(embedCharFromDirection(style->direction(), unicodeBidi), FromStyleOrDOM);
end

local function notifyObserverWillExitObject(observer, object)
	--TODO: fixed this function
	if (not observer or not object or not object:IsLayoutInline()) then
        return;
	end
end

local function BidiNextShared(root, current, observer, emptyInlineBehavior, endOfInlinePtr)
	emptyInlineBehavior = emptyInlineBehavior or "SkipEmptyInlines";
	local next = nil;
    -- oldEndOfInline denotes if when we last stopped iterating if we were at the end of an inline.
    local oldEndOfInline = if_else(endOfInlinePtr ~= nil, endOfInlinePtr, false);
    local endOfInline = false;
	while (current) do
		if (not oldEndOfInline and not IsIteratorTarget(current)) then
            next = current:FirstChild();
            NotifyObserverEnteredObject(observer, next);
        end

		-- We hit this when either current has no children, or when current is not a renderer we care about.
        if (not next) then
            -- If it is a renderer we care about, and we're doing our inline-walk, return it.
            if (emptyInlineBehavior == "IncludeEmptyInlines" and not oldEndOfInline and current:IsLayoutInline()) then
				next = current;
                endOfInline = true;
                break;
            end

            while (current and current ~= root) do
                notifyObserverWillExitObject(observer, current);

                next = current:NextSibling();

                if (next) then
                    NotifyObserverEnteredObject(observer, next);
                    break;
                end

                current = current:Parent();
                if (emptyInlineBehavior == "IncludeEmptyInlines" and current and current ~= root and current:IsLayoutInline()) then
                    next = current;
                    endOfInline = true;
                    break;
                end
			end
        end

		
        if (not next) then
            break;
		end

        if (IsIteratorTarget(next)
            or ((emptyInlineBehavior == "IncludeEmptyInlines" or not next:FirstChild()) -- Always return EMPTY inlines.
                and next:IsLayoutInline())) then
            break;
		end
        current = next;
	end

	if (endOfInlinePtr ~= nil) then
        endOfInlinePtr = endOfInline;
	end
    return next, endOfInlinePtr;
end

local function BidiNextIncludingEmptyInlines(root, current, endOfInlinePtr)
	return BidiNextShared(root, current, observer, "IncludeEmptyInlines", endOfInlinePtr);
end

function InlineWalker.BidiNextSkippingEmptyInlines(root, current, observer)
    return BidiNextShared(root, current, observer, "SkipEmptyInlines");
end

-- FIXME: This method needs to be renamed when bidiNext finds a good name.
function InlineWalker.BidiFirstIncludingEmptyInlines(root)
    local o = root:FirstChild();
    -- If either there are no children to walk, or the first one is correct
    -- then just return it.
    if (not o or o:IsLayoutInline() or IsIteratorTarget(o)) then
        return o;
	end
    return BidiNextIncludingEmptyInlines(root, o);
end

-- return LayoutObject;
function InlineWalker.BidiFirstSkippingEmptyInlines(root, resolver)
    --ASSERT(resolver);
    local o = root:FirstChild();
    if (not o) then
        return nil;
	end
    if (o:IsLayoutInline()) then
        NotifyObserverEnteredObject(resolver, o);
        if (o:FirstChild()) then
            o = InlineWalker.BidiNextSkippingEmptyInlines(root, o, resolver);
        else
--            -- Never skip empty inlines.
--            if (resolver) then
--                resolver->commitExplicitEmbedding();
--			end
            return o; 
        end
    end

    -- FIXME: Unify this with the bidiNext call above.
    if (o and not IsIteratorTarget(o)) then
        o = InlineWalker.BidiNextSkippingEmptyInlines(root, o, resolver);
	end
    --resolver->commitExplicitEmbedding();
    return o;
end

function InlineWalker:ctor()
	self.root = nil;
    self.current = nil;
    self.atEndOfInline = false;	
end

function InlineWalker:init(root)
	self.root = root;
	self.current = InlineWalker.BidiFirstIncludingEmptyInlines(root);

	return self;
end

function InlineWalker:Root()
	return self.root;
end
function InlineWalker:Current()
	return self.current;
end

function InlineWalker:AtEndOfInline()
	return self.atEndOfInline;
end

function InlineWalker:AtEnd()
	return not self.current;
end

function InlineWalker:Advance()
    -- FIXME: Support SkipEmptyInlines and observer parameters.
    self.current, self.atEndOfInline = BidiNextIncludingEmptyInlines(self.root, self.current, self.atEndOfInline);
    return self.current;
end

local IsolateTracker = commonlib.inherit(nil, {});

function IsolateTracker:ctor() 
	self.nestedIsolateCount = 0; -- number
    self.haveAddedFakeRunForRootIsolate = false; -- bool
end
-- @param inIsolate: bool
function IsolateTracker:init(inIsolate) 
	self.nestedIsolateCount = if_else(inIsolate, 1, 0);
	return self;
end

function IsolateTracker:EnterIsolate()
	self.nestedIsolateCount = self.nestedIsolateCount + 1;
end

function IsolateTracker:InIsolate()
	return if_else(self.nestedIsolateCount == 0, false, true);
end

function IsolateTracker:ExitIsolate()
    --ASSERT(m_nestedIsolateCount >= 1);
    self.nestedIsolateCount = self.nestedIsolateCount - 1;
    if (not self:InIsolate()) then
        self.haveAddedFakeRunForRootIsolate = false;
	end
end

-- We don't care if we encounter bidi directional overrides.
function IsolateTracker:Embed(direction, source)

end

local function isIsolatedInline(object)
    --ASSERT(object);
    return object:IsLayoutInline() and object:Style():UnicodeBidi() == UnicodeBidiEnum.Isolate;
end

local function containingIsolate(object, root)
    --ASSERT(object);
    while (object and object ~= root) do
        if (isIsolatedInline(object)) then
            return object;
		end
        object = object:Parent();
    end
    return nil;
end

-- FIXME: This belongs on InlineBidiResolver, except it's a template specialization
-- of BidiResolver which knows nothing about RenderObjects.
local function addPlaceholderRunForIsolatedInline(resolver, isolatedInline)
    --ASSERT(isolatedInline);
    local isolatedRun = BidiRun:new():init(0, 0, isolatedInline, resolver:Context(), resolver:Dir());
    resolver:Runs():AddRun(isolatedRun);
    -- FIXME: isolatedRuns() could be a hash of object->run and then we could cheaply
    -- ASSERT here that we didn't create multiple objects for the same inline.
    --resolver:IsolatedRuns():Append(isolatedRun);
	resolver:IsolatedRuns():push_back(isolatedRun);
end

function IsolateTracker:AddFakeRunIfNecessary(obj, resolver)
    -- We only need to lookup the root isolated span and add a fake run
    -- for it once, but we'll be called for every span inside the isolated span
    -- so we just ignore the call.
    if (self.haveAddedFakeRunForRootIsolate) then
        return;
	end
    self.haveAddedFakeRunForRootIsolate = true;

    -- FIXME: position() could be outside the run and may be the wrong call here.
    -- If we were passed an InlineIterator instead that would have the right root().
    local isolatedInline = containingIsolate(obj, resolver:Position():Root());
    -- FIXME: Because enterIsolate is not passed a RenderObject, we have to crawl up the
    -- tree to see which parent inline is the isolate. We could change enterIsolate
    -- to take a RenderObject and do this logic there, but that would be a layering
    -- violation for BidiResolver (which knows nothing about RenderObject).
    addPlaceholderRunForIsolatedInline(resolver, isolatedInline);
end

local InlineBidiResolver = commonlib.inherit(commonlib.gettable("System.Windows.mcml.platform.text.BidiResolver"), commonlib.gettable("System.Windows.mcml.layout.InlineBidiResolver"));

function InlineBidiResolver:ctor()
	
end

function InlineBidiResolver:CreateIterator()
	return InlineIterator:new();
end

function InlineBidiResolver:CreateResolver()
	return InlineBidiResolver:new():init();
end

function InlineBidiResolver:Increment()
	self.current:Increment(self);
end

function InlineBidiResolver:AppendRun()
    if (not self.emptyRun and not self.eor:AtEnd()) then
        -- Keep track of when we enter/leave "unicode-bidi: isolate" inlines.
        -- Initialize our state depending on if we're starting in the middle of such an inline.
        -- FIXME: Could this initialize from this->inIsolate() instead of walking up the render tree?
        local isolateTracker = IsolateTracker:new():init(containingIsolate(self.sor.obj, self.sor:Root()));
        local start = self.sor.pos;
        local obj = self.sor.obj;
        while (obj and obj ~= self.eor.obj and obj ~= self.endOfLine.obj) do
            if (isolateTracker:InIsolate()) then
                isolateTracker:AddFakeRunIfNecessary(obj, self);
            else
                LayoutBlock.AppendRunsForObject(self.runs, start, obj:Length() + 1, obj, self);
			end
            -- FIXME: start/obj should be an InlineIterator instead of two separate variables.
            start = 1;
            obj = InlineWalker.BidiNextSkippingEmptyInlines(self.sor:Root(), obj, isolateTracker);
        end
        if (obj) then
            local pos = if_else(obj == self.eor.obj, self.eor.pos, INT_MAX);
            if (obj == self.endOfLine.obj and self.endOfLine.pos <= pos) then
                self.reachedEndOfLine = true;
                pos = self.endOfLine.pos;
            end
            -- It's OK to add runs for zero-length RenderObjects, just don't make the run larger than it should be
            local _end = if_else(obj:Length() ~= 0, pos + 1, 0);
            if (isolateTracker:InIsolate()) then
                --isolateTracker.addFakeRunIfNecessary(obj, *this);
            else
                LayoutBlock.AppendRunsForObject(self.runs, start, _end, obj, self);
			end
        end

        self.eor:Increment();
        self.sor = self.eor;
    end

    self.direction = "OtherNeutral";
    self.status.eor = "OtherNeutral";
end