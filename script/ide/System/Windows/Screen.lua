--[[
Title: Screen
Author(s): LiXizhi
Date: 2015/8/20
Desc: a singleton class for current screen. 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Screen.lua");
local Screen = commonlib.gettable("System.Windows.Screen");
echo({Screen:GetWidth(), Screen:GetHeight()})
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Core/ToolBase.lua");
local Screen = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.gettable("System.Windows.Screen"));
Screen:Property({"Name", "Screen"});
Screen:Property({"m_width", nil, "GetWidth"});
Screen:Property({"m_height", nil, "GetHeight"});

Screen:Signal("sizeChanged", function(width, height) end)

function Screen:ctor()
	commonlib.EventSystem.getInstance():AddEventListener("RendererRecreated", function(self)
		self:OnSizeChange(self:GetWidth(), self:GetHeight());
	end, self);
end

function Screen:GetGUIRoot()
	if(not self.root or not self.root:IsValid()) then
		self.root = ParaUI.GetUIObject("root");
	end
	return self.root;
end

function Screen:GetWidth()
	return self:GetGUIRoot().width;
end

function Screen:GetHeight()
	return self:GetGUIRoot().height;
end

local scaling = {1,1}

-- return {scaleX, scaleY}
function Screen:GetUIScaling()
	return self:GetGUIRoot():GetField("UIScale", scaling)
end

function Screen:OnSizeChange(width, height)
	if(self.last_width ~= width or self.last_height~=height) then
		self.last_width, self.last_height = width, height;
		self:sizeChanged(width, height);
	end
end

Screen:InitSingleton();