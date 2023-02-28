--[[
Title: 
Author(s): Leio
Date: 2009/11/17
Desc: 
use the lib:
-------------------------------------------------------
NPL.load("(gl)script/kids/3DMapSystemApp/mcml/pe_textsprite.lua");
-------------------------------------------------------
]]

if(not Map3DSystem.mcml_controls) then Map3DSystem.mcml_controls = {} end

local pe_textsprite = {};

pe_textsprite.Images = {
	["default"] = "Texture/16number.png",
	["MallCost"] = "Texture/Aries/Creator/keepwork/Mall/mall_number_119X95_32bits.png",
}

pe_textsprite.Sprites = {
	["default"] = {
		["1"] = {rect = "0 0 20 31", width = 20, height = 32},
		["2"] = {rect = "32 0 19 31", width = 19, height = 32},
		["3"] = {rect = "64 0 19 31", width = 19, height = 32},
		["4"] = {rect = "96 0 19 31", width = 19, height = 32},
		["5"] = {rect = "0 32 20 31", width = 20, height = 32},
		["6"] = {rect = "32 32 19 32", width = 19, height = 32},
		["7"] = {rect = "64 32 19 31", width = 19, height = 32},
		["8"] = {rect = "96 32 19 31", width = 19, height = 32},
		["9"] = {rect = "0 64 19 31", width = 19, height = 32},
		["0"] = {rect = "32 64 19 31", width = 19, height = 32},
		["A"] = {rect = "64 64 22 31", width = 22, height = 32},
		["B"] = {rect = "96 64 20 31", width = 20, height = 32},
		["C"] = {rect = "0 96 19 31", width = 19, height = 32},
		["D"] = {rect = "32 96 19 31", width = 19, height = 32},
		["E"] = {rect = "64 96 19 31", width = 19, height = 32},
		["F"] = {rect = "96 96 19 31", width = 19, height = 32},
	},

	["MallCost"] = {
		["1"] = {rect = "0 0 20 31", width = 20, height = 32},
		["2"] = {rect = "32 0 22 31", width = 22, height = 32},
		["3"] = {rect = "64 0 21 32", width = 21, height = 32},
		["4"] = {rect = "92 0 28 32", width = 28, height = 32},
		["5"] = {rect = "0 32 25 31", width = 25, height = 32},
		["6"] = {rect = "32 32 23 32", width = 23, height = 32},
		["7"] = {rect = "64 32 20 31", width = 20, height = 32},
		["8"] = {rect = "94 32 23 31", width = 23, height = 32},
		["9"] = {rect = "0 64 22 31", width = 22, height = 32},
		["0"] = {rect = "30 64 21 31", width = 21, height = 32},
		["."] = {rect = "64 64 22 31", width = 22, height = 32},
		["A"] = {rect = "64 64 22 31", width = 22, height = 32},
		["B"] = {rect = "96 64 20 31", width = 20, height = 32},
		["C"] = {rect = "0 96 19 31", width = 19, height = 32},
		["D"] = {rect = "32 96 19 31", width = 19, height = 32},
		["E"] = {rect = "64 96 19 31", width = 19, height = 32},
		["F"] = {rect = "96 96 19 31", width = 19, height = 32},
	},

	["VipLimitTime"] = {
		["0"] = {rect = "0 0 28 25", width = 28, height = 25, image_path="Texture/Aries/Creator/keepwork/vip/vip_time/0_28x25_32bits.png"},
		["1"] = {rect = "0 0 15 25", width = 15, height = 25, image_path="Texture/Aries/Creator/keepwork/vip/vip_time/1_15x25_32bits.png"},
		["2"] = {rect = "0 0 28 25", width = 28, height = 25, image_path="Texture/Aries/Creator/keepwork/vip/vip_time/2_28x25_32bits.png"},
		["3"] = {rect = "0 0 28 25", width = 28, height = 25, image_path="Texture/Aries/Creator/keepwork/vip/vip_time/3_28x25_32bits.png"},
		["4"] = {rect = "0 0 27 25", width = 27, height = 25, image_path="Texture/Aries/Creator/keepwork/vip/vip_time/4_27x25_32bits.png"},
		["5"] = {rect = "0 0 28 25", width = 28, height = 25, image_path="Texture/Aries/Creator/keepwork/vip/vip_time/5_28x25_32bits.png"},
		["6"] = {rect = "0 0 28 25", width = 28, height = 25, image_path="Texture/Aries/Creator/keepwork/vip/vip_time/6_28x25_32bits.png"},
		["7"] = {rect = "0 0 26 25", width = 26, height = 25, image_path="Texture/Aries/Creator/keepwork/vip/vip_time/7_26x25_32bits.png"},
		["8"] = {rect = "0 0 28 25", width = 28, height = 25, image_path="Texture/Aries/Creator/keepwork/vip/vip_time/8_28x25_32bits.png"},
		["9"] = {rect = "0 0 28 25", width = 28, height = 25, image_path="Texture/Aries/Creator/keepwork/vip/vip_time/9_28x25_32bits.png"},
	},

	["ProjectRate"] = {
		["0"] = {rect = "0 0 16 20", width = 16, height = 20, image_path="Texture/Aries/Creator/keepwork/ggs/user/number/0_16X20_32bits.png"},
		["1"] = {rect = "0 0 16 20", width = 16, height = 20, image_path="Texture/Aries/Creator/keepwork/ggs/user/number/1_16X20_32bits.png"},
		["2"] = {rect = "0 0 16 20", width = 16, height = 20, image_path="Texture/Aries/Creator/keepwork/ggs/user/number/2_16X20_32bits.png"},
		["3"] = {rect = "0 0 16 20", width = 16, height = 20, image_path="Texture/Aries/Creator/keepwork/ggs/user/number/3_16X20_32bits.png"},
		["4"] = {rect = "0 0 16 20", width = 16, height = 20, image_path="Texture/Aries/Creator/keepwork/ggs/user/number/4_16X20_32bits.png"},
		["5"] = {rect = "0 0 16 20", width = 16, height = 20, image_path="Texture/Aries/Creator/keepwork/ggs/user/number/5_16X20_32bits.png"},
		["6"] = {rect = "0 0 16 20", width = 16, height = 20, image_path="Texture/Aries/Creator/keepwork/ggs/user/number/6_16X20_32bits.png"},
		["7"] = {rect = "0 0 16 20", width = 16, height = 20, image_path="Texture/Aries/Creator/keepwork/ggs/user/number/7_16X20_32bits.png"},
		["8"] = {rect = "0 0 16 20", width = 16, height = 20, image_path="Texture/Aries/Creator/keepwork/ggs/user/number/8_16X20_32bits.png"},
		["9"] = {rect = "0 0 16 20", width = 16, height = 20, image_path="Texture/Aries/Creator/keepwork/ggs/user/number/9_16X20_32bits.png"},
		["."] = {rect = "0 0 7 20", width = 7, height = 20, image_path="Texture/Aries/Creator/keepwork/ggs/user/number/dian_16X20_32bits.png"},
	},
}
Map3DSystem.mcml_controls.pe_textsprite = pe_textsprite;

function pe_textsprite.create(rootName, mcmlNode, bindingContext, _parent, left, top, width, height, style, parentLayout)
	local left, top, width, height = parentLayout:GetPreferredRect();
	
	local css = mcmlNode:GetStyle(Map3DSystem.mcml_controls.pe_html.css["pe:textsprite"], style) or {};
	local padding_left, padding_top, padding_bottom, padding_right = 
		(css["padding-left"] or css["padding"] or 0),(css["padding-top"] or css["padding"] or 0),
		(css["padding-bottom"] or css["padding"] or 0),(css["padding-right"] or css["padding"] or 0);
	local margin_left, margin_top, margin_bottom, margin_right = 
			(css["margin-left"] or css["margin"] or 0),(css["margin-top"] or css["margin"] or 0),
			(css["margin-bottom"] or css["margin"] or 0),(css["margin-right"] or css["margin"] or 0);	
	if(css.width) then
		if((left + css.width)<width) then
			width = left + css.width + margin_left  + margin_right
		end
	end
	if(css.height) then
		if((top + css.height)<height) then
			height = top + css.height + margin_top  + margin_bottom
		end
	end

	local myLayout;
	if(mcmlNode:GetChildCount()>0) then
		myLayout = parentLayout:clone();
		myLayout:SetUsedSize(0,0);
		myLayout:OffsetPos(padding_left+margin_left, padding_top+margin_top);
		myLayout:IncHeight(-padding_bottom-margin_bottom);
		myLayout:IncWidth(-padding_right-margin_right);
	end	
	
	parentLayout:AddObject(width-left, height-top);
	left = left + margin_left
	top = top + margin_top;
	width = width - margin_right;
	height = height - margin_bottom;
	-- create the 3d canvas for avatar display
	local instName = mcmlNode:GetInstanceName(rootName);
	local color = css["color"] or "#FFFF00"
	local value =  mcmlNode:GetAttributeWithCode("value","", true);
	local click_through =  mcmlNode:GetBool("ClickThrough",nil);
	local fontsize =  css["font-size"] or 31;
	NPL.load("(gl)script/ide/TextSprite.lua");

	local fontName = mcmlNode:GetAttribute("fontName") or "default";
	local imagePath = pe_textsprite.Images[fontName] or "Texture/16number.png"
	local sprites = pe_textsprite.Sprites[fontName] or pe_textsprite.Sprites["default"]
	local ctl = CommonCtrl.TextSprite:new{
		name = instName,
		alignment = "_lt",
		left = left,
		top = top,
		width = width,
		height = height,
		parent = _parent,
		color = color, -- "255 255 0 128"
		text = "0123456789 ABCDEF",
		-- the height of the font. the width is determined according to the font image.
		fontsize = fontsize,
		-- sprite info, below are default settings. 
		image = imagePath,
		-- rect is "left top width height"
		sprites = sprites,
		click_through = click_through,
	};
	mcmlNode.control = ctl;
	ctl:Show(true);

	-- call update UI function whenever you have changed the properties. 
	ctl:UpdateUI();
	ctl:SetText(value);

end
-- get the UI value on the node
function pe_textsprite.GetUIValue(mcmlNode, pageInstName)
	local editBox = mcmlNode:GetControl(pageInstName);
	if(editBox) then
		if(type(editBox)=="table" and type(editBox.GetText) == "function") then
			return editBox:GetText();
		end	
	end
end

-- set the UI value on the node
function pe_textsprite.SetUIValue(mcmlNode, pageInstName, value)
	local editBox = mcmlNode:GetControl(pageInstName);
	if(editBox) then
		if(type(value) == "number") then
			value = tostring(value);
		elseif(type(value) == "table") then
			return
		end 
		if(type(editBox)=="table" and type(editBox.SetText) == "function") then
			editBox:SetText(value);
		end	
	end
end