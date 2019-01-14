--[[
Title: 
Author(s): LiPeng
Date: 2018/11/22
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/platform/ScrollbarTheme.lua");
local ScrollbarTheme = commonlib.gettable("System.Windows.mcml.platform.ScrollbarTheme");
------------------------------------------------------------
]]

local ScrollbarTheme = commonlib.gettable("System.Windows.mcml.platform.ScrollbarTheme");

function ScrollbarTheme:theme()
	return self;
end


function ScrollbarTheme:scrollbarThickness()
	return 16;
end

function ScrollbarTheme:usesOverlayScrollbars()
	return false;
end

