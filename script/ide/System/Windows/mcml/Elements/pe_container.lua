--[[
Title: container element
Author(s): LiXizhi
Date: 2015/4/29
Desc: it create parent child relationship
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_container.lua");
Elements.pe_container:RegisterAs("pe:container");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_div.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Canvas.lua");
NPL.load("(gl)script/ide/System/Windows/mcml/PageElement.lua");
local PageElement = commonlib.gettable("System.Windows.mcml.PageElement");
local Canvas = commonlib.gettable("System.Windows.Controls.Canvas");

local pe_container = commonlib.inherit(commonlib.gettable("System.Windows.mcml.Elements.pe_div"), commonlib.gettable("System.Windows.mcml.Elements.pe_container"));
pe_container:Property({"class_name", "pe:container"});

function pe_container:ctor()
end

function pe_container:CreateControl()
	local parentElem = self:GetParentControl();
	local _this = Canvas:new():init(parentElem);
	self:SetControl(_this);

	pe_container._super.CreateControl(self);
end