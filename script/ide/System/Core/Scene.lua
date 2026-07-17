--[[
Title: Scene 
Author: LiXizhi
Date: 2024.2.4
Desc: singleton class for scene management.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Core/Scene.lua");
local Scene = commonlib.gettable("System.Core.Scene");
Scene:Reset();
System.Core.Scene:MakeAutoDestory(obj);
------------------------------------------------------------
]]
local Scene = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Core.Scene"));

Scene:Signal("OnReset")

function Scene:ctor()
end

-- @param obj: the obj:Destroy() will be called when scene is reset.
function Scene:MakeAutoDestory(obj)
	self:Connect("OnReset", obj, obj.Destroy)
end

-- reset the scene
-- @param bPerserveUI: if true, UI and timers are not cleared. default to nil
function Scene:Reset(bPerserveUI)
	self:OnReset();
	if(not bPerserveUI) then
		-- kill all timers.
		NPL.KillTimer(-1);
		-- kill all virtual timers. 
		if(commonlib.TimerManager) then
			commonlib.TimerManager.Clear();
		end	
	end	
	self:Destroy();
	ParaScene.Reset();
	if(not bPerserveUI) then
		ParaUI.ResetUI();
	end	
	ParaAsset.GarbageCollect();
	ParaGlobal.SetGameStatus("disable");
	if(_AI and _AI.temp_memory) then
		_AI.temp_memory = {}
	end
	if(System.ResetState) then
		System.ResetState();
	end
	collectgarbage();
	log("scene has been reset\n");

	if(IPCDebugger) then
		IPCDebugger.Start();
	end	
	-- clear all entity cache . This is defined in NPL.load("(gl)script/ide/IPCBinding/EntityHelper.lua");
	local clear_cache_func = commonlib.getfield("IPCBinding.EntityHelper.ClearAllCachedObject");
	if(type(clear_cache_func) == "function") then
		clear_cache_func();
	end
end

-- create singleton
Scene:InitSingleton();