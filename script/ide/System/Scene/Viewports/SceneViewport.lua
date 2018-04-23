--[[
Title: The default scene viewport
Author(s): LiXizhi@yeah.net
Date: 2018/3/27
Desc: by default the 3d scene viewport fills up the entire screen. One can use this class to change the view port.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Viewports/SceneViewport.lua");
local SceneViewport = commonlib.gettable("System.Scene.Viewports.SceneViewport");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Viewports/Viewport.lua");
local SceneViewport = commonlib.inherit(commonlib.gettable("System.Scene.Viewports.Viewport"), commonlib.gettable("System.Scene.Viewports.SceneViewport"));


function SceneViewport:ctor()
end
