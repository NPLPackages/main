--[[
Title: 
Author(s): LiPeng
Date: 2019/3/13
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutPart.lua");
local LayoutPart = commonlib.gettable("System.Windows.mcml.layout.LayoutPart");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutWidget.lua");
local LayoutPart = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutWidget"), commonlib.gettable("System.Windows.mcml.layout.LayoutPart"));

function LayoutPart:ctor()
	self:SetInline(false);
end

--function LayoutPart:init(node)
--	return self;
--end

function LayoutPart:IsRenderPart()
	return true;
end
