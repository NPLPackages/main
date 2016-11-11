--[[
Title: PluginConfig
Author(s): LiXizhi
Desc: 
Plugins are usually loaded from sub folders or zip files in "Mod/" directory.
"Mod/ModsConfig.xml" contains latest plugin options and where they should be enabled.

Use Lib: 
-------------------------------------------------------
NPL.load("(gl)script/ide/System/Plugins/PluginConfig.lua");
local PluginConfig = commonlib.gettable("System.Plugins.PluginConfig");
-------------------------------------------------------
]]
local PluginConfig = commonlib.inherit(nil, commonlib.gettable("System.Plugins.PluginConfig"));

function PluginConfig:ctor()
	self.name = "";
	-- mapping from worldname to plugin options, if worldname is "global", it is loaded as global plugin. 
	self.worldOptionFilters = {};
end

function PluginConfig:init(name)
	self.name = name;
	return self;
end

function PluginConfig:LoadFromXmlNode(modnode)
	local modname = modnode.attr.name;
	self.name = modname;
	self.attr = modnode.attr;
	for worldnode in commonlib.XPath.eachNode(modnode,"/world") do
		local worldname = worldnode.attr.name;
		local checked = worldnode.attr.checked;
		local options = {
			checked = checked == "true" or checked == true,
		};
		self:AddWorldOption(worldname, options);
	end
	return self;
end

-- set custom property
function PluginConfig:SetAttribute(name, value)
	self.attr = self.attr or {};
	self.attr[name] = value;
end

-- get custom property
function PluginConfig:GetAttribute(name)
	return self.attr and self.attr[name];
end

function PluginConfig:SaveToXmlNode(modnode)
	self:SetAttribute("name", self.name);
	modnode = modnode or {name='mod', attr=self.attr};
	for worldname, options in pairs(self.worldOptionFilters) do 
		local worldnode = {name='world', attr = {name = worldname}};
		worldnode.attr.checked = options.checked;
		modnode[#modnode+1] = worldnode;
	end
	return modnode;
end

function PluginConfig:AddWorldOption(worldname, options)
	self.worldOptionFilters[worldname] = options;
end

-- the returned table object can be used for read and write. 
function PluginConfig:GetWorldOption(worldname, bCreateIfNotExist)
	worldname = worldname or "global";
	local options = self.worldOptionFilters[worldname]
	if(not options and bCreateIfNotExist) then
		options = {};
		self.worldOptionFilters[worldname] = options;
	end
	return options;
end

-- whether the plugin is enabled for the given world filer name
-- @param worldname: if nil it is global.
function PluginConfig:IsEnabled(worldname)
	local options = self:GetWorldOption(worldname)
	return options and options.checked;
end

-- the plugin enabled for a given world
function PluginConfig:SetEnabled(worldname, checked)
	local options = self:GetWorldOption(worldname, checked == true)
	if(options) then
		options.checked = checked == true;
	end
end