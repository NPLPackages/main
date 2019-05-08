--[[
Title: scrollarea element
Author(s): LiPeng
Date: 2017/10/3
Desc: it create scroll area
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_scrollarea.lua");
Elements.pe_scrollarea:RegisterAs("pe:scrollarea");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_container.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollAreaForPage.lua");
local ScrollAreaForPage = commonlib.gettable("System.Windows.Controls.ScrollAreaForPage");
local PageElement = commonlib.gettable("System.Windows.mcml.PageElement");

local pe_scrollarea = commonlib.inherit(commonlib.gettable("System.Windows.mcml.Elements.pe_container"), commonlib.gettable("System.Windows.mcml.Elements.pe_scrollarea"));
pe_scrollarea:Property({"class_name", "pe:scrollarea"});

function pe_scrollarea:ctor()
end

function pe_scrollarea:ControlClass()
	return ScrollAreaForPage;
end