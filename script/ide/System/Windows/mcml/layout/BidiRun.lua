--[[
Title: 
Author(s): LiPeng
Date: 2018/3/27
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/BidiRun.lua");
local BidiRun = commonlib.gettable("System.Windows.mcml.layout.BidiRun");
------------------------------------------------------------
]]

NPL.load("(gl)script/ide/System/Windows/mcml/platform/text/BidiResolver.lua");

local BidiRun = commonlib.inherit(commonlib.gettable("System.Windows.mcml.platform.text.BidiCharacterRun"), commonlib.gettable("System.Windows.mcml.layout.BidiRun"));

function BidiRun:ctor()
	self.object = nil;
    self.box = nil;
    self.hasHyphen = false;
end

function BidiRun:init(start, stop, object, context, dir)
	BidiRun._super.init(self, start, stop, context, dir);
	self.object = object;
	return self;
end

function BidiRun:Object()
	return self.object;
end