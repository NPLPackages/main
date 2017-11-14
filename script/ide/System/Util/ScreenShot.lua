--[[
Title: Taking screen shot
Author(s): LiXizhi, 
Date: 2017/9/29
Desc: taking screen shot of the environment screen
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Util/ScreenShot.lua");
local ScreenShot = commonlib.gettable("System.Util.ScreenShot");
ScreenShot.TakeSnapshot(filepath, width,height, IncludeUI, ShowHeadOnDisplay)
------------------------------------------------------------
]]
local ScreenShot = commonlib.gettable("System.Util.ScreenShot");

-- default snapshot
ScreenShot.DefaultSnapShot = "Screen Shots/auto.jpg"

-- public function: call this function to take a new screen shot. 
-- @param filepath,width,height, IncludeUI, ShowHeadOnDisplay: all input can be nil.
-- @return: true if succeed
function ScreenShot.TakeSnapshot(filepath, width,height, IncludeUI, ShowHeadOnDisplay)
	local result;
	if(filepath == nil) then
		filepath = ScreenShot.DefaultSnapShot
	end
	
	local last_show_headon_display = ParaScene.GetAttributeObject():GetField("ShowHeadOnDisplay", true);
	if(ShowHeadOnDisplay ~= nil) then
		ParaScene.GetAttributeObject():SetField("ShowHeadOnDisplay", ShowHeadOnDisplay);
	end

	if(not IncludeUI) then
		-- save without GUI
		ParaUI.GetUIObject("root").visible = false;
		ParaUI.ShowCursor(false);
		ParaScene.EnableMiniSceneGraph(false);
		ParaEngine.ForceRender();ParaEngine.ForceRender(); -- since we take image on backbuffer, we will render it twice to make sure the backbuffer is updated
	end
	
	-- take a snapshot with defined resolution for the current screen
	if(not width and not height) then
		result = ParaMovie.TakeScreenShot(filepath)
	else
		if(width) then
			height = math.floor(width/ParaUI.GetUIObject("root").width * ParaUI.GetUIObject("root").height + 0.5);
		elseif(height) then
			width = math.floor(height/ParaUI.GetUIObject("root").height * ParaUI.GetUIObject("root").width + 0.5);
		end
		result = ParaMovie.TakeScreenShot(filepath, width, height);
	end
	
	-- refresh texture
	ParaAsset.LoadTexture("", filepath, 1):UnloadAsset();
	
	if(not IncludeUI) then
		-- restore UI
		ParaUI.ShowCursor(true);
		ParaUI.GetUIObject("root").visible = true;
		ParaScene.EnableMiniSceneGraph(true);
	end	
	if(ShowHeadOnDisplay ~= nil) then
		ParaScene.GetAttributeObject():SetField("ShowHeadOnDisplay", last_show_headon_display);
	end
	return result;
end