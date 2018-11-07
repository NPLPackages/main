--[[
Title: imgeak row
Author(s): LiPeng
Date: 2017/10/3
Desc: it handles HTML tags of <img> . 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_img.lua");
System.Windows.mcml.Elements.pe_img:RegisterAs("pe:img","img");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/Canvas.lua");
local Canvas = commonlib.gettable("System.Windows.Controls.Canvas");
local pe_img = commonlib.inherit(commonlib.gettable("System.Windows.mcml.PageElement"), commonlib.gettable("System.Windows.mcml.Elements.pe_img"));
pe_img:Property({"class_name", "pe:img"});

function pe_img:ctor()
end

function pe_img:OnLoadComponentAfterChild(parentElem, parentLayout, css)
	css.float = css.float or true;

	local width = self:GetAttributeWithCode("width",nil, true) or css.width;
	if(width) then
		css.width = tonumber(width);
	end
	local height = self:GetAttributeWithCode("height",nil, true) or css.height;
	if(height) then
		css.height = tonumber(height);
	end

	local _this = self.control;
	if(not _this) then
		_this = Canvas:new():init(parentElem);
		self:SetControl(_this);
	end
	
	_this:SetTooltip(self:GetAttributeWithCode("tooltip", nil, true));
	

	local src = self:GetAttributeWithCode("src",nil,true);
	if(src and src ~= "") then
		-- tricky: this allows dynamic images to update itself, _this.background only handles static images with fixed size.
		if(string.match(src, "[;:]")) then
			css.background = self:GetAbsoluteURL(src);
		else
			css.background = self:GetAbsoluteURL(src);
		end	
	end

	_this:ApplyCss(css);
	--pe_img._super.OnLoadComponentAfterChild(self, parentElem, parentLayout, css);
end

function pe_img:OnAfterChildLayout(layout, left, top, right, bottom)
	if(self.control) then
		self.control:setGeometry(left, top, right-left, bottom-top);
	end
end

