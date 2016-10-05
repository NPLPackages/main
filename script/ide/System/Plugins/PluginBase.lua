--[[
Title: PluginBase
Author(s): LiXizhi
Desc: 
virtual functions:
  init(): 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Plugins/PluginBase.lua");
local PluginBase = commonlib.gettable("System.Plugins.PluginBase");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local PluginBase = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Plugins.PluginBase"));

PluginBase:Property({"Name", "PluginBase"});
PluginBase:Property({"Desc", "", auto=true});
PluginBase:Property({"Enabled", true, "IsEnabled", "SetEnabled", auto=true});

function PluginBase:ctor()
end

-- called once during initialization
function PluginBase:init()
	return self;
end