--[[
Title: PluginManager
Author(s): LiXizhi
Desc: 
Use Lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Plugins/PluginManager.lua");
local PluginManager = commonlib.gettable("System.Plugins.PluginManager");
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local PluginManager = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Plugins.PluginManager"));

PluginManager:Property({"Name", "PluginManager"});

local allInstances = {};

function PluginManager:ctor()
	-- array of all mod
	self.mods = {};
	-- mapping from name to mod
	self.mods_name_map = {};
	-- mapping mod object to true
	self.mods_map = {};
	-- plugin manager
	self:AddInstance(self);
end

-- static method
function PluginManager.GetInstance(name)
	return allInstances[name or "PluginManager"];
end

function PluginManager:AddInstance(self)
	for name, instance in pairs(allInstances) do
		if(instance == self and self:GetName() ~= name) then
			allInstances[name] = nil;
			break;
		end
	end
	allInstances[self:GetName()] = self;
end

-- called once during initialization
function PluginManager:init()
	return self;
end

-- get plugin loader
function PluginManager:GetLoader()
	if(not self.pluginLoader) then
		NPL.load("(gl)script/ide/System/Plugins/PluginLoader.lua");
		local PluginLoader = commonlib.gettable("System.Plugins.PluginLoader");
		local loader = PluginLoader:new():init(self);	
		self.pluginLoader = loader;
	end
	return self.pluginLoader;
end


-- clean up all mods
function PluginManager:Cleanup()
	self:OnDestroy();
	self.mods = {};
	self.mods_name_map = {};
	self.mods_map = {};
end

function PluginManager:GetMod(name)
	return self.mods_name_map[name or ""];
end

function PluginManager:GetLoadedModCount()
	return #self.mods;
end

function PluginManager:IsModLoaded(mod_)
	return mod_ and self.mods_map[mod_];
end

-- add mod to the mod plugin. 
function PluginManager:AddMod(name, mod)
	if(not mod or not mod.InvokeMethod or self:IsModLoaded(mod)) then
		return;
	end
	name = name or mod:GetName() or "";
	mod:InvokeMethod("init");

	self.mods[#self.mods+1] = mod;
	self.mods_map[mod] = true;
	if(not self.mods_name_map[name]) then
		LOG.std(nil, "info", "PluginManager", "mod: %s (%s) is added", name, mod:GetName() or "");
		self.mods_name_map[name] = mod;
	else
		LOG.std(nil, "info", "PluginManager", "overriding mod with same name: %s", name);
	end
	return true;
end

-- private function: invoke method on all plugins. if the plugin does not have the method, it does nothing. 
-- it only calls method if the mod is enabled. 
-- @return the return value of the last non-nil plugin. 
function PluginManager:InvokeMethod(method_name, ...)
	local result;
	for _, mod in ipairs(self.mods) do
		if(mod:IsEnabled()) then
			result = mod:InvokeMethod(method_name, ...) or result;
		end
	end
	return result;
end

-- signal
function PluginManager:OnDestroy()
	self:InvokeMethod("OnDestroy");
end

