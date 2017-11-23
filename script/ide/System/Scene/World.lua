--[[
Title: Global World (scene) 
Author(s):  LiXizhi
Date: 2007/8/22, refactored 2017.8
Desc: Create or Load 3d World (scene).
This class can be used as a singleton or instanced class.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Scene/World.lua");
System.Scene.World:LoadWorld(worldpath, bPerserveUI, bHideProgressUI, OnProgressCallBack)
System.Scene.World:CreateWorld(NewWorldpath, BaseWorldPath, bUseBaseWorldNPC, bCloneBaseWorldScene, bMinClone, bOverWrite)
------------------------------------------------------------
]]
local World = commonlib.inherit(nil, commonlib.gettable("System.Scene.World"));

-- world information
World.worlddir = "worlds/";
World.defaultskymesh = "model/Skybox/skybox3/skybox3.x";--the snow sky box
World.asset_defaultPlayerModel = "";
World.worldzipfile = nil; -- if the world is a zip file, it will be the local file name
World.name = "_noname";
World.shortname = "_noname";
World.sConfigFile = "";
World.sNpcDbFile = "";
World.sAttributeDbFile = "";
World.sBaseWorldCfgFile = "_emptyworld/worldconfig.txt";
World.sBaseWorldAttFile = "_emptyworld/_emptyWorld.attribute.db"
World.sBaseWorldNPCFile = "_emptyworld/_emptyWorld.NPC.db"
World.createtime = "2006-1-26";
World.author = "ParaEngine";
World.desc = "create world description";
World.terrain = {type=0, basetex=0, commontex=0};
World.env_set = 0;
World.sky = 0;
World.readonly = nil;
-- the default player position if the player has never been here before.
World.defaultPos = {x=20000,y=20000};

function World:ctor()
end

-- load a world immediately without doing any error checking or report. This is usually called by ParaIDE from the Load world menu. 
-- @param worldpath: the directory containing the world config file, such as "sample","worlds/demo" 
-- or it can also be a [worldname].zip file that contains the world directory. 
-- @param bPerserveUI: if true, UI are not cleared. default to nil
-- @param bHideProgressUI: if true, progress UI is hidden. default to nil
-- @param OnProgressCallBack: nil or a function of function(percent) end, where percent is between [0,100]
-- @return bSucceed, errorMsg. 
function World:LoadWorldImmediate(worldpath, bPerserveUI, bHideProgressUI, OnProgressCallBack)
	if(worldpath) then
		worldpath = string.gsub(worldpath, "[/\\]+$", "")
	end	
	if(string.find(worldpath, ".*%.zip$")~=nil or string.find(worldpath, ".*%.pkg$")~=nil) then
		-- open zip archive with relative path
		if(self.worldzipfile and self.worldzipfile~= worldpath) then
			ParaAsset.CloseArchive(self.worldzipfile); -- close last world archive
		end
		self.worldzipfile = worldpath;
		
		ParaAsset.OpenArchive(worldpath, true);

		ParaIO.SetDiskFilePriority(-1);
		local search_result = ParaIO.SearchFiles("","*.", worldpath, 0, 10, 0);
		local nCount = search_result:GetNumOfResult();
		if(nCount>0) then
			-- just use the first directory in the world zip file as the world name.
			local WorldName = search_result:GetItem(0);
			WorldName = string.gsub(WorldName, "[/\\]$", "");
			worldpath = string.gsub(worldpath, "([^/\\]+)%.%w%w%w$", WorldName); -- get rid of the zip file extension for display 
		else
			-- make it the directory path
			worldpath = string.gsub(worldpath, "(.*)%.%w%w%w$", "%1"); -- get rid of the zip file extension for display 		
		end
		if(not ParaIO.DoesFileExist(worldpath, false)) then
			ParaIO.SetDiskFilePriority(0);
		else
			LOG.std(nil, "warn", "loadworld", "opening zip file while disk file already exist, use zip priority now");
		end
		self:SetReadOnly(true);
		
		NPL.load("(gl)script/ide/sandbox.lua");
		ParaSandBox.ApplyToWorld(nil);
		ParaSandBox.Reset();
	else
		if(self.worldzipfile) then
			ParaAsset.CloseArchive(self.worldzipfile); 
		end	
		self.worldzipfile = nil;
		self:SetReadOnly(false);
		ParaIO.SetDiskFilePriority(0);
		
		-- do not use a sandbox for writable world.
		NPL.load("(gl)script/ide/sandbox.lua");
		ParaSandBox.ApplyToWorld(nil);
		ParaSandBox.Reset();
	end
	
	self.name = worldpath;
	
	self:UseDefaultFileMapping();
	
	if(ParaIO.DoesAssetFileExist(self.sConfigFile, true)) then
		if(self:LoadWorldImp(bPerserveUI, bHideProgressUI, OnProgressCallBack) == true) then
			return true;
		else
			return false, worldpath.." failed loading the world."
		end
	else
		LOG.std(nil, "error", "LoadWorld", "unable to find file: %s", self.sConfigFile or "");
		return false, worldpath.." world does not exist"
	end	
end

-- static function: loadworld and start the default UI.
-- @param input: it can be worldpath string, such as "worlds/3DMapStartup", or a table of 
-- {worldpath, bExclusiveMode, bRunOnloadScript, OnProgress}
--		bExclusiveMode: use exclusive desktop mode. menu and taskbar will not be created. 
--		OnProgress: nil or a function of function(percent) end, where percent is between [0,100]
-- @param bHideProgressUI: if true, progress UI is hidden. default to nil
-- @return bSucceed, errorMsg. 
function World:LoadWorld(input, isPerserveUI, bHideProgressUI)
	local worldpath;
	local bExclusiveMode, bRunOnloadScript = false, true
	if(type(input) == "string") then
		worldpath = input;
	elseif(type(input) == "table") then
		worldpath = input.worldpath;
		if(input.bExclusiveMode~=nil) then
			bExclusiveMode = input.bExclusiveMode
		end	
		if(input.bRunOnloadScript~=nil) then
			bRunOnloadScript = input.bRunOnloadScript
		end
	end
	if(not worldpath) then
		return nil, "world path can not be empty";
	end

	local currentWorldPath = ParaWorld.GetWorldDirectory();
	if(currentWorldPath ~= "_emptyworld/") then
		if(System.App.AppManager.OnWorldClosing()) then
			return "当前世界的关闭, 需要确认";
		end
		if(not System.App.AppManager.OnWorldClosed()) then
			log("error: sending APP_WORLD_CLOSED message to all applications\n");
			return;
		end
	end
	
	local res, msg = self:LoadWorldImmediate(worldpath, isPerserveUI, bHideProgressUI, function (percent)
		if(input.OnProgress) then
			input.OnProgress(percent*0.8);
		end
	end);

	if(res == true) then
		if(not System.options.servermode) then
			System.Animation.InitAnimationManager();
			
			NPL.load("(gl)script/kids/3DMapSystemUI/Desktop/AppDesktop.lua");
			System.UI.AppDesktop.OnInit()

			-- Locale IDE to fetch the head arrow asset
			System.HeadArrowAsset = ParaAsset.LoadParaX("", CommonCtrl.Locale("IDE")("asset_headarrow"));
		
			-- rebind event handlers
			System.ReBindEventHandlers();
		
			-- send APP_WORLD_LOAD msg for each installed application, whenever a new world is loaded
			System.App.AppManager.OnWorldLoad();
		
			-- load menu and app task bar.
			System.UI.AppDesktop.LoadDesktop(bExclusiveMode);
		end
		
		-- TODO: security alert, this is not in sandbox.  call the onload script for the given world
		if(bRunOnloadScript) then
			local sOnLoadScript = string.gsub(self.sConfigFile, "[^/\\]+$", "onload.lua");
			if(ParaIO.DoesFileExist(sOnLoadScript, true))then
				NPL.load("(gl)"..sOnLoadScript, true);
			end
		end	
		if(input.OnProgress) then
			input.OnProgress(100);
		end
	end
	return res, msg;	
end

-- private: clear the scene and load the world using the settings in the System, return false if failed.
-- @param bPerserveUI: if true, UI are not cleared and progress bar are not disabled. default to nil
-- @param bHideProgressUI: if true, progress UI is hidden. default to nil
-- @param OnProgressCallBack: nil or a function of function(percent) end, where percent is between [0,100]
-- @return bSucceed, errMsg
function World:LoadWorldImp(bPerserveUI, bHideProgressUI, OnProgressCallBack)
	-- clear the scene
	System.reset(bPerserveUI);
	
	if(self.sConfigFile ~= "") then
		if(OnProgressCallBack) then
			OnProgressCallBack(0)
		end
		-- disable the game 
		ParaScene.EnableScene(false);
		if(OnProgressCallBack) then
			OnProgressCallBack(20)
		end
		
		-- TODO: security alert, this is not in sandbox.  call the preload script for the given world
		local sOnLoadScript = string.gsub(self.sConfigFile, "[^/\\]+$", "preload.lua");
		if(ParaIO.DoesAssetFileExist(sOnLoadScript, true))then
			NPL.load("(gl)"..sOnLoadScript, true);
		end
		
		-- create/load world
		ParaScene.CreateWorld("", 32000, self.sConfigFile); 
		if(OnProgressCallBack) then
			OnProgressCallBack(30)
		end
		
		-- load from database
		self:LoadWorldFromDB();
		if(OnProgressCallBack) then
			OnProgressCallBack(100)
		end
		
		-- we have built the scene, now we can enable the game
		ParaScene.EnableScene(true);
		return true;
	else
		return false, "world config file not exist";
	end
end

-- static function: create a new world at path
--@param newworldpath such as "worlds/LiXizhi"
--@param BaseWorldPath: from which world the new world is derived. It can be nil if the empty world should be used. 
--@param bUseBaseWorldNPC: if this is true, base world NPC are inherited.
--@param bCloneBaseWorldScene: if this is true, base world files are cloned to the new world path. otherwise it will reuse the files from the base world. 
--@param bMinClone: we will only copy minimum files necessary to the new world path. if nil, it will copy all files under base world directory to the new world directory. 
--@return bSucceed, errorMsg: 
function World:CreateWorld(NewWorldpath, BaseWorldPath, bUseBaseWorldNPC, bCloneBaseWorldScene, bMinClone, bOverWrite)
	NewWorldpath = string.gsub(NewWorldpath, "[/\\]+$", "")
	if(BaseWorldPath) then
		BaseWorldPath = string.gsub(BaseWorldPath, "[/\\]+$", "")
	end	
	local world = World:new();
	world.name = NewWorldpath;
	world:SetDefaultFileMapping(NewWorldpath);
	
	-- ensure that the directory exists.
	ParaIO.CreateDirectory(NewWorldpath.."/log.txt");
	if(ParaIO.DoesFileExist(world.sConfigFile, true) == true and not bOverWrite) then
		return false, "世界已经存在了, 如想重新创建, 请手工删除文件夹./"..commonlib.Encoding.DefaultToUtf8(NewWorldpath);
	else
		if(world:SetBaseWorldName(BaseWorldPath) ==  true) then
			local sConfigFileName = ParaWorld.NewWorld(NewWorldpath.."/", world.sBaseWorldCfgFile);
			if(sConfigFileName ~= "") then
				world.sConfigFile = sConfigFileName;
				-- copy the base world's attribute file to the newly created world.
				-- so that environment and initial character position are preserved. 
				if(world.sBaseWorldAttFile) then
					if(not ParaIO.CopyFile(world.sBaseWorldAttFile, world.sAttributeDbFile, true)) then
						commonlib.log("warning: failed copying file sBaseWorldAttFile when creating world\n")
					end
				end
				
				if(bUseBaseWorldNPC and world.sBaseWorldNPCFile) then
					if(not ParaIO.CopyFile(world.sBaseWorldNPCFile, world.sNpcDbFile, true)) then
						commonlib.log("warning: failed copying file sBaseWorldNPCFile when creating world\n")
					end
				end
				
				if(bCloneBaseWorldScene and BaseWorldPath) then
					
					if(not bMinClone) then
						-- copy all other files under the directory. 
						local output = {};
						commonlib.SearchFiles(output, ParaIO.GetCurDirectory(0)..BaseWorldPath.."/", "*.*", 10, 10000, true)
						local _, file;
						for _, file in ipairs(output) do
							-- ignore any db, backup and worldconfig files.
							if(not string.match(file, "%.db$") and not string.match(file, "worldconfig%.txt$") and not string.match(file, "%.bak$")) then
								if(string.match(file, "[/\\][^.]+$")) then
									-- this is directory
									ParaIO.CreateDirectory(BaseWorldPath.."/"..file.."/log.txt");
								else
									ParaIO.CopyFile(BaseWorldPath.."/"..file, NewWorldpath.."/"..file, true);
								end	
							end
						end
					else
						-- copy only used files, this way we can support clone a world from assets manifest files. 
						local base_world = World:new();
						local worldpath = BaseWorldPath;
						base_world:SetDefaultFileMapping(worldpath);
						local new_name = NewWorldpath:match("([^/\\]+)$");
								
						local config_file = ParaIO.OpenAssetFile(base_world.sConfigFile);
						if(config_file:IsValid()) then
							-- find all referenced files
							local text = config_file:GetText();
							local files = {};
							local w;
							for w in string.gfind(text, "[^\r\n]+") do
								w = string.match(w, "[^/]+config%.txt$");
								if(w) then
									local config_file_name = worldpath.."/config/"..w;
									--files["/config/"..w] = "/config/"..w:gsub("^.*(_%d+_%d+%.)", new_game.."%1");
									files["/config/"..w] = true;
						
									local file = ParaIO.OpenAssetFile(config_file_name);
									if(file:IsValid()) then
										local tile_text = file:GetText();
										for w in string.gfind(tile_text, "[^\r\n]+") do
											local content = string.match(w, "[^/]+%.onload%.lua$");
											if(content) then
												files["/script/"..content] = true;
												files["/config/"..string.gsub(content, "onload%.lua$", "mask")] = true;
											end
											local content = string.match(w, "[^/]+%.raw$");
											if(content) then
												files["/elev/"..content] = true;
											end
										end
										file:close();
									else
										commonlib.log("warning: config file %s is not found\n", config_file_name);
									end
								end	
							end
							config_file:close();
							
							-- we will assume there is a preview image, and we will copy that too. Since it is harmless even there is no such file. 
							files["/preview.jpg"] = true;
							files["/LocalNPC.xml"] = true;
							files["/Player.xml"] = true;
							files["/tag.xml"] = true;
							files["/entity.xml"] = true;

							local filename, to_filename;
							for filename, to_filename in pairs(files) do
								
								-- commonlib.echo({worldpath..filename, NewWorldpath..filename});
								if(to_filename == true) then
									ParaIO.CopyFile(worldpath..filename, NewWorldpath..filename, true);
								else
									ParaIO.CopyFile(worldpath..filename, NewWorldpath..to_filename, true);
								end
							end

							-- check for any block world
							local output = {};
							commonlib.SearchFiles(output, ParaIO.GetCurDirectory(0)..BaseWorldPath.."/blockWorld.lastsave/", "*.*", 0, 1000, true)
							if(#output > 0) then
								ParaIO.CreateDirectory(NewWorldpath.."/blockWorld.lastsave/");
								local _, file;
								for _, file in ipairs(output) do
									local file_ending =  file:match("_(%d+_%d+%.raw)$")
									if(file_ending) then
										ParaIO.CopyFile(BaseWorldPath.."/blockWorld.lastsave/"..file, NewWorldpath.."/blockWorld.lastsave/"..file_ending, true);
									else
										ParaIO.CopyFile(BaseWorldPath.."/blockWorld.lastsave/"..file, NewWorldpath.."/blockWorld.lastsave/"..file, true);
									end
								end
							end
						else
							commonlib.echo({"file not found", config_file})	
						end
					end	
				end
				
				--TODO: keep other info from the user.
				return true;
			else 
				return false, "世界创建失败了。";
			end
		else
			return false, "被派生的世界不存在。";
		end
	end
end

-- close current world
function World:CloseWorld()
	if(self.worldzipfile) then
		ParaAsset.CloseArchive(self.worldzipfile); 
	end	
	self.worldzipfile = nil;
	self:SetReadOnly(false);
	ParaIO.SetDiskFilePriority(0);
		
	-- do not use a sandbox for writable world.
	NPL.load("(gl)script/ide/sandbox.lua");
	ParaSandBox.ApplyToWorld(nil);
	ParaSandBox.Reset();
end

-- @param bIsReadOnly: boolean
function World:SetReadOnly(bIsReadOnly)
	self.readonly = bIsReadOnly;
	-- for backward compatible
	commonlib.setfield("System.World.readonly", self.readonly);
end

function World:IsReadOnly()
	return self.readonly;
end

function World:LoadWorldFromDB(name)
	local att;
	-- set the default NPC db
	ParaWorld.SetAttributeProvider(self.sAttributeDbFile);
	ParaWorld.SetNpcDB(self.sNpcDbFile);
	
	-- use default sky and fog
	ParaScene.CreateSkyBox ("MySkyBox", ParaAsset.LoadStaticMesh("", self.defaultskymesh), 160,160,160, 0);
	ParaScene.SetFog(true, "0.7 0.7 1.0", 40.0, 120.0, 0.7);
	
	-- load last player location
	local db = ParaWorld.GetAttributeProvider();
	db:SetTableName("WorldInfo");
	local x,y,z;
	x = db:GetAttribute("PlayerX", self.defaultPos.x);
	y = db:GetAttribute("PlayerY", 0);
	z = db:GetAttribute("PlayerZ", self.defaultPos.y);
	
	-- ocean level
	local OceanEnabled = db:GetAttribute("OceanEnabled", false);
	local OceanLevel = db:GetAttribute("OceanLevel", 0);
	ParaScene.SetGlobalWater(OceanEnabled, OceanLevel);
	att = ParaScene.GetAttributeObjectOcean();
	att:SetField("OceanColor", {db:GetAttribute("OceanColor_R", 0.2), db:GetAttribute("OceanColor_G", 0.3), db:GetAttribute("OceanColor_B", 0.3)});
	att:SetField("RenderTechnique", db:GetAttribute("RenderTechnique", 3));
	
	-- load sky
	att = ParaScene.GetAttributeObjectSky();
	att:SetField("SkyMeshFile", db:GetAttribute("SkyMeshFile", self.defaultskymesh));
	att:SetField("SkyColor", {db:GetAttribute("SkyColor_R", 1), db:GetAttribute("SkyColor_G", 1), db:GetAttribute("SkyColor_B", 1)});
	att:SetField("SkyFogAngleFrom", db:GetAttribute("SkyFogAngleFrom", -0.05));
	att:SetField("SkyFogAngleTo", db:GetAttribute("SkyFogAngleTo", 0.6));
	
	-- sky simulated 
	att:SetField("SimulatedSky", db:GetAttribute("SimulatedSky", false));
	att:SetField("IsAutoDayTime", db:GetAttribute("IsAutoDayTime", true));
	att:SetField("SunGlowTexture", db:GetAttribute("SunGlowTexture", nil));
	att:SetField("CloudTexture", db:GetAttribute("CloudTexture", nil));
	
	-- sun light
	local att = ParaScene.GetAttributeObjectSunLight();
	att:SetField("DayLength", db:GetAttribute("DayLength", 10000));
	att:SetField("TimeOfDaySTD", db:GetAttribute("TimeOfDaySTD", 0.4));
	att:SetField("MaximumAngle", db:GetAttribute("MaximumAngle", 1.5));
	att:SetField("AutoSunColor", db:GetAttribute("AutoSunColor", false));
	local r,g,b = db:GetAttribute("Ambient", "0.59 0.59 0.59"):match("^(%S+)%s(%S+)%s(%S+)")
	att:SetField("Ambient", {tonumber(r), tonumber(g), tonumber(b)} );
	local r,g,b = db:GetAttribute("Diffuse", "1 1 1"):match("^(%S+)%s(%S+)%s(%S+)")
	att:SetField("Diffuse", {tonumber(r), tonumber(g), tonumber(b)} );
	att:SetField("ShadowFactor",db:GetAttribute("ShadowFactor",0.35));

	-- load fog 
	att = ParaScene.GetAttributeObject();
	att:SetField("FogEnd", db:GetAttribute("FogEnd", 120));
	att:SetField("FogStart", db:GetAttribute("FogStart", 40));
	att:SetField("FogDensity", db:GetAttribute("FogDensity", 0.69));
	att:SetField("FogColor", {db:GetAttribute("FogColor_R", 1), db:GetAttribute("FogColor_G", 1), db:GetAttribute("FogColor_B", 1)});
	
	-- load fullscreen glow effect
	att:SetField("Glowness", {db:GetAttribute("Glowness_R", 1), db:GetAttribute("Glowness_G", 1), db:GetAttribute("Glowness_B", 1),db:GetAttribute("Glowness_A", 1)})
	att:SetField("GlowIntensity", db:GetAttribute("GlowIntensity", 0.8));
	att:SetField("GlowFactor", db:GetAttribute("GlowFactor", 1));
	--att:SetField("FullScreenGlow", db:GetAttribute("FullScreenGlow", false));
	
	-- load camera settings
	att = ParaCamera.GetAttributeObject();
	att:SetField("FarPlane", db:GetAttribute("CameraFarPlane", 120));
	att:SetField("NearPlane", db:GetAttribute("CameraNearPlane", 0.5));
	att:SetField("FieldOfView", db:GetAttribute("FieldOfView", 1.0472));
	
	-- editor attributes
	local attributes = {};
	local function save_attr(name, value)
		attributes[name] = value;
	end
	self.attributes = attributes;
	att = ParaEngine.GetAttributeObject();
	save_attr("Effect Level", db:GetAttribute("Effect Level", att:GetField("Effect Level", 0)));
	local size = att:GetField("ScreenResolution", {1024,768});
	save_attr("ScreenResolution.width", db:GetAttribute("ScreenResolution.width", size[1]));
	save_attr("ScreenResolution.height", db:GetAttribute("ScreenResolution.height", size[2]));
	save_attr("TextureLOD", db:GetAttribute("TextureLOD", att:GetField("TextureLOD", 0)));
	att = ParaScene.GetAttributeObjectOcean();
	save_attr("EnableTerrainReflection", db:GetAttribute("EnableTerrainReflection", att:GetField("EnableTerrainReflection", false)))
	save_attr("EnableMeshReflection", db:GetAttribute("EnableMeshReflection", att:GetField("EnableMeshReflection", false)))
	save_attr("EnablePlayerReflection", db:GetAttribute("EnablePlayerReflection", att:GetField("EnablePlayerReflection", false)))
	save_attr("EnableCharacterReflection", db:GetAttribute("EnableCharacterReflection", att:GetField("EnableCharacterReflection", false)))
	att = ParaScene.GetAttributeObject();
	save_attr("SetShadow", db:GetAttribute("SetShadow", att:GetField("SetShadow", false)))
	save_attr("FullScreenGlow", db:GetAttribute("FullScreenGlow", att:GetField("FullScreenGlow", false)))

	-- create the default player
	local PlayerAsset = db:GetAttribute("PlayerAsset", self.asset_defaultPlayerModel);
		
	if(System.options and System.options.ignorePlayerAsset) then
		PlayerAsset = "";
	end
	local asset = ParaAsset.LoadParaX("", PlayerAsset);
	
	local player;
	local playerChar;
	player = ParaScene.CreateCharacter(tostring(commonlib.getfield("System.User.nid") or "player"), asset, "", true, 0.35, db:GetAttribute("PlayerFacing", 3.9), 1.0);
	player:SetPosition(x, y, z);
	--player:SnapToTerrainSurface(0);
	player:GetAttributeObject():SetField("SentientField", 65535);--senses everybody including its own kind.
	
	--------------------------------------------------------
	--player:GetAttributeObject():SetField("GroupID", 1);
	--player:GetAttributeObject():SetField("AlwaysSentient", true);
	--player:GetAttributeObject():SetField("Sentient", true);
	--------------------------------------------------------
	
	-- set movable region: it will apply to all characters in this concise version.
	-- player:SetMovableRegion(16000,0,16000, 16000,16000,16000);
	ParaScene.Attach(player);
	playerChar = player:ToCharacter();
	playerChar:SetFocus();
	ParaCamera.ThirdPerson(0, db:GetAttribute("CameraObjectDistance", 5), db:GetAttribute("CameraLiftupAngle", 0.4), db:GetAttribute("CameraRotY", 0));
end

-- attributes with self.attributes will be applied.
function World:ApplyEditorAttributes()
	if(not self.attributes) then
		return
	end
	local attributes = self.attributes;

	local att = ParaEngine.GetAttributeObject();
	if(attributes["Effect Level"]~=nil) then
		att:SetField("Effect Level", attributes["Effect Level"]);
	end
	if(attributes["ScreenResolution.width"]~=nil) then
		att:SetField("ScreenResolution", {attributes["ScreenResolution.width"], attributes["ScreenResolution.height"]});
	end
	if(attributes["TextureLOD"]~=nil) then
		att:SetField("TextureLOD", attributes["TextureLOD"]);
	end
	att = ParaScene.GetAttributeObjectOcean();
	if(attributes["EnableTerrainReflection"]~=nil) then
		att:SetField("EnableTerrainReflection", attributes["EnableTerrainReflection"]);
	end
	if(attributes["EnableMeshReflection"]~=nil) then
		att:SetField("EnableMeshReflection", attributes["EnableMeshReflection"]);
	end
	if(attributes["EnablePlayerReflection"]~=nil) then
		att:SetField("EnablePlayerReflection", attributes["EnablePlayerReflection"]);
	end
	if(attributes["EnableCharacterReflection"]~=nil) then
		att:SetField("EnableCharacterReflection", attributes["EnableCharacterReflection"]);
	end
	att = ParaScene.GetAttributeObject();
	if(attributes["SetShadow"]~=nil) then
		att:SetField("SetShadow", attributes["SetShadow"]);
	end
	if(attributes["FullScreenGlow"]~=nil) then
		att:SetField("FullScreenGlow", attributes["FullScreenGlow"]);
	end
end

-- save world info to db 
function World:SaveWorldToDB()
	local att, color;
	
	ParaWorld.SetAttributeProvider(self.sAttributeDbFile);
	ParaWorld.SetNpcDB(self.sNpcDbFile);
	
	-- save last player location
	local db = ParaWorld.GetAttributeProvider();
	db:ExecSQL("BEGIN")
	db:SetTableName("WorldInfo");
	local x,y,z = ParaScene.GetPlayer():GetPosition();
	db:UpdateAttribute("PlayerAsset", ParaScene.GetPlayer():GetPrimaryAsset():GetKeyName());
	db:UpdateAttribute("PlayerX", x);
	db:UpdateAttribute("PlayerY", y);
	db:UpdateAttribute("PlayerZ", z);
	db:UpdateAttribute("PlayerFacing", ParaScene.GetPlayer():GetFacing());
	
	--save ocean level.
	db:UpdateAttribute("OceanEnabled", ParaScene.IsGlobalWaterEnabled());
	db:UpdateAttribute("OceanLevel", ParaScene.GetGlobalWaterLevel());
	att = ParaScene.GetAttributeObjectOcean();
	color = att:GetField("OceanColor", {1, 1, 1});
	db:UpdateAttribute("OceanColor_R", color[1]);
	db:UpdateAttribute("OceanColor_G", color[2]);
	db:UpdateAttribute("OceanColor_B", color[3]);
	db:UpdateAttribute("RenderTechnique", att:GetField("RenderTechnique", 3));
	
	-- save sky
	att = ParaScene.GetAttributeObjectSky();
	local str = att:GetField("SkyMeshFile", self.defaultskymesh);
	db:UpdateAttribute("SkyMeshFile", str);
	color = att:GetField("SkyColor", {1, 1, 1});
	db:UpdateAttribute("SkyColor_R", color[1]);
	db:UpdateAttribute("SkyColor_G", color[2]);
	db:UpdateAttribute("SkyColor_B", color[3]);
	db:UpdateAttribute("SkyFogAngleFrom", att:GetField("SkyFogAngleFrom", -0.05));
	db:UpdateAttribute("SkyFogAngleTo", att:GetField("SkyFogAngleTo", 0.6));
	
	-- sky simulated
	db:UpdateAttribute("SimulatedSky", att:GetField("SimulatedSky", false));
	db:UpdateAttribute("IsAutoDayTime", att:GetField("IsAutoDayTime", true));
	db:UpdateAttribute("SunGlowTexture", att:GetField("SunGlowTexture", ""));
	db:UpdateAttribute("CloudTexture", att:GetField("CloudTexture", ""));
	
	-- sun light
	local att = ParaScene.GetAttributeObjectSunLight();
	db:UpdateAttribute("DayLength", att:GetField("DayLength", 10000));
	db:UpdateAttribute("TimeOfDaySTD", att:GetField("TimeOfDaySTD", 0.1));
	db:UpdateAttribute("MaximumAngle", att:GetField("MaximumAngle", 1.5));
	db:UpdateAttribute("AutoSunColor", att:GetField("AutoSunColor", false));
	local color = att:GetField("Ambient", {0.3, 0.3, 0.3});
	db:UpdateAttribute("Ambient", string.format("%f %f %f", color[1], color[2], color[3]));
	local color = att:GetField("Diffuse", {1, 1, 1});
	db:UpdateAttribute("Diffuse", string.format("%f %f %f", color[1], color[2], color[3]));
	db:UpdateAttribute("ShadowFactor",att:GetField("ShadowFactor",0.35));

	-- save fog 
	att = ParaScene.GetAttributeObject();
	db:UpdateAttribute("FogEnd", att:GetField("FogEnd", 120));
	db:UpdateAttribute("FogStart", att:GetField("FogStart", 40));
	db:UpdateAttribute("FogDensity", att:GetField("FogDensity", 0.69));
	color = att:GetField("FogColor", {1, 1, 1});
	db:UpdateAttribute("FogColor_R", color[1]);
	db:UpdateAttribute("FogColor_G", color[2]);
	db:UpdateAttribute("FogColor_B", color[3]);
	
	-- save fullscreen glow effect
	db:UpdateAttribute("GlowIntensity", att:GetField("GlowIntensity", 0.8));
	db:UpdateAttribute("GlowFactor", att:GetField("GlowFactor", 1));
	color = att:GetField("Glowness", {1,1,1,1});
	db:UpdateAttribute("Glowness_R", color[1]);
	db:UpdateAttribute("Glowness_G", color[2]);
	db:UpdateAttribute("Glowness_B", color[3]);
	db:UpdateAttribute("Glowness_A", color[4]);
	--db:UpdateAttribute("FullScreenGlow", att:GetField("FullScreenGlow", false));
	
	-- save camera settings
	att = ParaCamera.GetAttributeObject();
	db:UpdateAttribute("CameraFarPlane", att:GetField("FarPlane", 120));
	db:UpdateAttribute("CameraNearPlane", att:GetField("NearPlane", 0.5));
	db:UpdateAttribute("FieldOfView", att:GetField("FieldOfView", 1.0472));
	
	db:UpdateAttribute("CameraObjectDistance", att:GetField("CameraObjectDistance", 5));
	db:UpdateAttribute("CameraLiftupAngle", att:GetField("CameraLiftupAngle", 0.4));
	db:UpdateAttribute("CameraRotY", att:GetField("CameraRotY", 0));
	
	-- Editor only attribute
	att = ParaEngine.GetAttributeObject();
	db:UpdateAttribute("Effect Level", att:GetField("Effect Level", 0));
	local size = att:GetField("ScreenResolution", {1024,768});
	db:UpdateAttribute("ScreenResolution.width", size[1]);
	db:UpdateAttribute("ScreenResolution.height", size[2]);
	db:UpdateAttribute("TextureLOD", att:GetField("TextureLOD", 0));
	att = ParaScene.GetAttributeObjectOcean();
	db:UpdateAttribute("EnableTerrainReflection", att:GetField("EnableTerrainReflection", false))
	db:UpdateAttribute("EnableMeshReflection", att:GetField("EnableMeshReflection", false))
	db:UpdateAttribute("EnablePlayerReflection", att:GetField("EnablePlayerReflection", false))
	db:UpdateAttribute("EnableCharacterReflection", att:GetField("EnableCharacterReflection", false))
	att = ParaScene.GetAttributeObject();
	db:UpdateAttribute("SetShadow", att:GetField("SetShadow", false))
	db:UpdateAttribute("FullScreenGlow", att:GetField("FullScreenGlow", false))

	db:ExecSQL("END")
end


--[[set the world name from which a new world is derived
@param name: a world name or nil or "". if "_emptyworld", a new world will be created if not exists.
@return : true if succeeded, nil if not.]]
function World:SetBaseWorldName(name)
	if(name == nil or name == "") then
		self.sBaseWorldCfgFile = "";
		self.sBaseWorldAttFile = nil;
		self.sBaseWorldNPCFile = nil;
		if(not ParaIO.DoesAssetFileExist("_emptyworld/flat.raw", true)) then	
			ParaWorld.NewEmptyWorld("_emptyworld", 533.3333, 64);
		end
		return true;
	elseif(name == "_emptyworld") then
		-- if the empty world does not exist, the empty world will be created and used as the base world
		self.sBaseWorldCfgFile = ParaWorld.NewEmptyWorld("_emptyworld", 533.3333, 64);
		log(self.sBaseWorldCfgFile.."\n does not exist. _emptyworld is created and used as the base world to create the new world;\n");
	end

	local sWorldConfigName = self:GetDefaultWorldConfigName(name);
	local sWorldAttName = self:GetDefaultAttributeDatabaseName(name);
	local sWorldNPCFile = self:GetDefaultNPCDatabaseName(name);
	
	if(ParaIO.DoesAssetFileExist(sWorldAttName, true)) then	
		self.sBaseWorldAttFile = sWorldAttName;
	else	
		self.sBaseWorldAttFile = nil;
	end
	
	if(ParaIO.DoesAssetFileExist(sWorldNPCFile, true)) then	
		self.sBaseWorldNPCFile = sWorldNPCFile;
	else	
		self.sBaseWorldNPCFile = nil;
	end
	
	if(ParaIO.DoesAssetFileExist(sWorldConfigName, true) == true) then	
		self.sBaseWorldCfgFile = sWorldConfigName;
		return true;
	end
end

function World:SetDefaultFileMapping(name)
	if(not name)then
		name = self.name;
	end
	self.sConfigFile = self:GetDefaultWorldConfigName(name);
	self.sNpcDbFile = self:GetDefaultNPCDatabaseName(name);
	self.sAttributeDbFile = self:GetDefaultAttributeDatabaseName(name);
end

-- use default world config name, npc db and attribute db.
function World:UseDefaultFileMapping()
	self:UseDefaultWorldConfigName();
	self:UseDefaultNPCDatabase();
	self:UseDefaultAttributeDatabase();
end

-- update world config file name from the world name
function World:UseDefaultWorldConfigName()
	if(self.name == "") then
		self.sConfigFile = "";
	else
		local name = self.name;
		self.sConfigFile = self:GetDefaultWorldConfigName(self.name, true);
	end
end

-- update npc database file name from the world name
function World:UseDefaultNPCDatabase()
	if(self.name == "") then
		self.sNpcDbFile = "";
	else
		self.sNpcDbFile = self:GetDefaultNPCDatabaseName(self.name);
	end
end
-- update attribute database file name from the world name
function World:UseDefaultAttributeDatabase()
	if(self.name == "") then
		self.sAttributeDbFile = "";
	else
		self.sAttributeDbFile = self:GetDefaultAttributeDatabaseName(self.name)
	end
end

---------------------------------
-- static public functions
---------------------------------
-- static function
-- @param worldpath: such as worlds/worldname or worlds/worldname/ 
-- @param bSearchZipFile:true to search in zip files. 
-- return true if worldpath is a world directory. 
function World:DoesWorldExist(worldpath, bSearchZipFile)
	if(worldpath) then
		worldpath = string.gsub(worldpath, "[/\\]+$", "")
		local sWorldConfigName = self:GetDefaultWorldConfigName(worldpath, bSearchZipFile);
		if(ParaIO.DoesAssetFileExist(sWorldConfigName, bSearchZipFile)) then
			return true;
		end
	end	
end

-- if [world_dir]/[filename] does not exist, we will try [world_dir]/[worldname].[filename]. 
-- @param filename: such as "worldconfig.txt", "NPC.db"
function World:TryGetWorldFilePath(world_dir, filename, bSearchZipFile)
	if(bSearchZipFile == nil) then
		bSearchZipFile = true;
	end
	local sFileName = world_dir.."/"..filename;
	if(ParaIO.DoesAssetFileExist(sFileName, bSearchZipFile)) then
		return sFileName;
	else
		local sOldFileName = world_dir.."/"..ParaIO.GetFileName(world_dir).."."..filename;	
		if(ParaIO.DoesAssetFileExist(sOldFileName, bSearchZipFile)) then
			return sOldFileName;
		else
			return sFileName;
		end
	end
end

--@param name: world directory name. such as "world/demo"
function World:GetDefaultWorldConfigName(name, bSearchZipFile)
	return self:TryGetWorldFilePath(name, "worldconfig.txt", bSearchZipFile);
end

--@param name: world directory name. such as "world/demo"
function World:GetDefaultNPCDatabaseName(name, bSearchZipFile)
	return self:TryGetWorldFilePath(name, "NPC.db", bSearchZipFile);
end

--@param name: world directory name. such as "world/demo"
function World:GetDefaultAttributeDatabaseName(name, bSearchZipFile)
	return self:TryGetWorldFilePath(name, "attribute.db", bSearchZipFile);
end