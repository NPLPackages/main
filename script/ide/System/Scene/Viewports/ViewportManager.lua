--[[
Title: managing all viewports (singleton class)
Author(s): LiXizhi@yeah.net
Date: 2018/3/27
Desc: by default there is a GUI viewport and scene viewport that all fills up the entire screen
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/Viewports/ViewportManager.lua");
local ViewportManager = commonlib.gettable("System.Scene.Viewports.ViewportManager");
ViewportManager:RemoveAllUserDefinedViewports();

local viewport = ViewportManager:GetSceneViewport();
viewport:SetMarginBottom(100)
viewport:SetPosition("_fi", 100,200, 100,100)
------------------------------------------------------------
]]

local ViewportManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Scene.Viewports.ViewportManager"));

function ViewportManager:ctor()
	self.viewports = {};
	NPL.load("(gl)script/ide/System/Scene/Viewports/Viewport.lua");
	local Viewport = commonlib.gettable("System.Scene.Viewports.Viewport");
	Viewport:new():init("GUI")
	
	NPL.load("(gl)script/ide/System/Scene/Viewports/SceneViewport.lua");
	local SceneViewport = commonlib.gettable("System.Scene.Viewports.SceneViewport");
	SceneViewport:new():init("scene")

    NPL.load("(gl)script/ide/System/Scene/Viewports/SceneViewport.lua");
	local SceneViewport = commonlib.gettable("System.Scene.Viewports.SceneViewport");
	SceneViewport:new():init("visual_scene_editor")
end

function ViewportManager:GetGUIViewport()
	return self.viewports["GUI"];
end

function ViewportManager:GetSceneViewport()
	return self.viewports["scene"];
end

function ViewportManager:GetVisualSceneEditorViewport()
	return self.viewports["visual_scene_editor"];
end

function ViewportManager:GetViewport(name)
	return self.viewports[name];
end

function ViewportManager:AddViewport(viewport)
	self.viewports[viewport:GetKey()] = viewport;
end

-- this is usually called when world is unloaded. 
function ViewportManager:RemoveAllUserDefinedViewports()
	local keys = {};
	for key, viewport in pairs(self.viewports) do
		if(viewport:IsUserDefined()) then
			viewport:Destroy();
			keys[#keys+1] = key; 
		end
	end
	for _, key in ipairs(keys) do
		self.viewports[key] = nil;
	end
end

ViewportManager:InitSingleton();
