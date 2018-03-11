--[[
Title: 
Author(s): LiPeng
Date: 2018/1/16
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/render/LayoutInline.lua");
local LayoutInline = commonlib.gettable("System.Windows.mcml.layout.LayoutInline");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/layout/LayoutBoxModelObject.lua");
local LayoutInline = commonlib.inherit(commonlib.gettable("System.Windows.mcml.layout.LayoutBoxModelObject"), commonlib.gettable("System.Windows.mcml.layout.LayoutInline"));

function LayoutInline:ctor()

end

function LayoutInline:DirtyLinesFromChangedChild(child)
	--TODO: fixed this function
end