--[[
Title: default mcml style sheet
Author(s): LiXizhi
Date: 2015/5/4
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/StyleDefault.lua");
local StyleDefault = commonlib.gettable("System.Windows.mcml.StyleDefault");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/Style.lua");
local StyleDefault = commonlib.inherit(commonlib.gettable("System.Windows.mcml.Style"), commonlib.gettable("System.Windows.mcml.StyleDefault"));

local items = {
	["h1"] = {
		["margin-top"] = 3,
		["margin-left"] = 0,
		["margin-bottom"] = 5,
		["font-weight"] = "bold",
		["font-size"] = "19",
--		headimage = "Texture/unradiobox.png",
		headimagewidth = 16,
	},
	["h2"] = {
		["margin-top"] = 3,
		["margin-left"] = 0,
		["margin-bottom"] = 3,
		["font-weight"] = "bold",
		["font-size"] = "12",
--		headimage = "Texture/unradiobox.png",
		headimagewidth = 14,
	},
	["h3"] = {
		["margin-top"] = 3,
		["margin-left"] = 0,
		["margin-bottom"] = 2,
		["font-weight"] = "bold",
--		headimage = "Texture/unradiobox.png",
		headimagewidth = 12,
	},
	["h4"] = {
		["margin-top"] = 3,
		["margin-left"] = 0,
		["margin-bottom"] = 1,
		["font-weight"] = "bold",
--		headimage = "Texture/unradiobox.png",
		headimagewidth = 10,
	},
	["pe:button"] = {
		padding=5,
		color = "#ffffff",
--		background="Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;456 396 16 16:4 4 4 4",
--		background_down="Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;473 396 16 16:4 4 4 4",
--		background_over="Texture/Aries/Creator/Theme/GameCommonIcon_32bits.png;496 400 1 1",
	},
	["pe:label"] = {
		["padding-top"]=2,
		["padding-bottom"]=2,
	},
	["pe:editbox"] = {
		height=24, 
		["min-width"]=10,
	},
	["pe:radio"]={
--		background="Texture/unradiobox.png",
--		background_checked="Texture/radiobox.png",
		iconSize = 16,
	},
	["pe:checkbox"]={
--		background="Texture/uncheckbox2.png",
--		background_checked="Texture/checkbox2.png",
		iconSize = 16,
	},
	["pe:sliderbar"]={
		height = 20,
	},
}

function StyleDefault:ctor()
	self:LoadFromTable(items);
	--self:LoadFromFile("script/ide/System/Windows/mcml/default_style.mcss");
end
