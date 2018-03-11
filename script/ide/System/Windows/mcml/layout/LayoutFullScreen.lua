--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutFullScreen.lua");
local LayoutFullScreen = commonlib.gettable("System.Windows.mcml.layout.LayoutFullScreen");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutObject.lua");
local LayoutFullScreen = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutObject"), commonlib.gettable("System.Windows.mcml.layout.LayoutFullScreen"));

function LayoutFullScreen:ctor()

end

function LayoutFullScreen:WrapLayoutObject(object,parent,document)

end
