--[[
Author: 
Date: 2009.6.1
Desc: some useful commands for F12 debug panel
-----------------------------------------------
NPL.load("(gl)script/test/UsefulCommands.lua");
-----------------------------------------------
]]
-- turn off fog
ParaScene.GetAttributeObject():SetField("EnableFog", false);