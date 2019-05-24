--[[
Title: 
Author(s): LiPeng
Date: 2019/3/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/PaintPhase.lua");
local PaintPhase = commonlib.gettable("System.Windows.mcml.layout.PaintPhase");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Util/EnumCreater.lua");
local EnumCreater = commonlib.gettable("System.Util.EnumCreater");

local layout = commonlib.gettable("System.Windows.mcml.layout");

--[[
 *  The painting of a layer occurs in three distinct phases.  Each phase involves
 *  a recursive descent into the layer's render objects. The first phase is the background phase.
 *  The backgrounds and borders of all blocks are painted.  Inlines are not painted at all.
 *  Floats must paint above block backgrounds but entirely below inline content that can overlap them.
 *  In the foreground phase, all inlines are fully painted.  Inline replaced elements will get all
 *  three phases invoked on them during this phase.
 --]]
layout.PaintPhase = EnumCreater.Transform({
    "PaintPhaseBlockBackground",
	"PaintPhaseChildBlockBackground",
	"PaintPhaseChildBlockBackgrounds",
	"PaintPhaseFloat",
	"PaintPhaseForeground",
	"PaintPhaseOutline",
	"PaintPhaseChildOutlines",
	"PaintPhaseSelfOutline",
	"PaintPhaseSelection",
	"PaintPhaseCollapsedTableBorders",
	"PaintPhaseTextClip",
	"PaintPhaseMask"
});
