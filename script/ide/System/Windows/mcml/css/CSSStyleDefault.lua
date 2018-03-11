--[[
Title: default mcml style sheet
Author(s): LiPeng
Date: 2017/11/3
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/css/CSSStyleDefault.lua");
local CSSStyleDefault = commonlib.gettable("System.Windows.mcml.css.CSSStyleDefault");
------------------------------------------------------------
]]
local CSSStyleDefault = commonlib.gettable("System.Windows.mcml.css.CSSStyleDefault");

CSSStyleDefault.items = {
	["pe:div"] = {
		["background-color"] = "#ffffff00",
	},
--	["pe:style"] = {
--		["display"] = "none",
--	},
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
