--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/BreakLines.lua");
local BreakLines = commonlib.gettable("System.Windows.mcml.layout.BreakLines");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObject.lua");
local BreakLines = commonlib.gettable("System.Windows.mcml.layout.BreakLines");

local function nextBreakablePosition(lazyBreakIterator, pos, treatNoBreakSpaceAsBreak)
	treatNoBreakSpaceAsBreak = if_else(treatNoBreakSpaceAsBreak == nil, false, treatNoBreakSpaceAsBreak);

	local str = lazyBreakIterator:String();
    local len = lazyBreakIterator:Length();
    local nextBreak = -1;
	len = str:nextBreakablePosition(pos);
--    lcoal lastLastCh = if_else(pos > 1, str[pos - 2] : 0;
--    lcoal lastCh = if_else(pos > 0 ? str[pos - 1] : 0;
--    for (int i = pos; i < len; i++) {
--        UChar ch = str[i];
--
--        if (isBreakableSpace(ch, treatNoBreakSpaceAsBreak) || shouldBreakAfter(lastLastCh, lastCh, ch))
--            return i;
--
--        if (needsLineBreakIterator(ch) || needsLineBreakIterator(lastCh)) {
--            if (nextBreak < i && i) {
--                TextBreakIterator* breakIterator = lazyBreakIterator.get();
--                if (breakIterator)
--                    nextBreak = textBreakFollowing(breakIterator, i - 1);
--            }
--            if (i == nextBreak && !isBreakableSpace(lastCh, treatNoBreakSpaceAsBreak))
--                return i;
--        }
--
--        lastLastCh = lastCh;
--        lastCh = ch;
--    }

    return len;
end

function BreakLines.IsBreakable(lazyBreakIterator, pos, nextBreakableWrapper, breakNBSP)
	breakNBSP = if_else(breakNBSP == nil, false, breakNBSP);
	local nextBreakable = nextBreakableWrapper.value;
	if (pos > nextBreakable) then
        nextBreakable = nextBreakablePosition(lazyBreakIterator, pos, breakNBSP);
	end
	nextBreakableWrapper.value = nextBreakable
    return pos == nextBreakable;
end
