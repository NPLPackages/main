--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutLayer.lua");
local LayoutLayer = commonlib.gettable("System.Windows.mcml.layout.LayoutLayer");
------------------------------------------------------------
]]

local LayoutLayer = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.layout.LayoutLayer"));

function LayoutLayer:ctor()
	self.renderObject = nil;
end
