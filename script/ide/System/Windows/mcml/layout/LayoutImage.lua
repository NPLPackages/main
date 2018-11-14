--[[
Title: 
Author(s): LiPeng
Date: 2018/11/14
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutImage.lua");
local LayoutImage = commonlib.gettable("System.Windows.mcml.layout.LayoutImage");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutReplaced.lua");
local LayoutImage = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutReplaced"), commonlib.gettable("System.Windows.mcml.layout.LayoutImage"));

function LayoutImage:ctor()

end

function LayoutImage:GetName()
	return "LayoutImage";
end

function LayoutImage:IsImage()
	return true;
end

