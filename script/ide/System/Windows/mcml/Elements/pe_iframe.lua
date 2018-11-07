--[[
Title: iframe
Author(s): LiPeng
Date: 2018/1/4
Desc: it handles HTML tags of <iframe> . 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_iframe.lua");
System.Windows.mcml.Elements.pe_iframe:RegisterAs("iframe");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/mcml/Elements/pe_div.lua");
local pe_iframe = commonlib.inherit(commonlib.gettable("System.Windows.mcml.Elements.pe_div"), commonlib.gettable("System.Windows.mcml.Elements.pe_iframe"));
pe_iframe:Property({"class_name", "pe:iframe"});

function pe_iframe:ctor()
end

function pe_iframe:OnLoadComponentBeforeChild(parentElem, parentLayout, css)
	local url = self:GetAbsoluteURL(self:GetAttributeWithCode("src",nil,true));
	local srcPage = System.Windows.mcml.Page:new({name = self:GetAttributeWithCode("name",nil,true) or parentElem.name, parentpage = self:GetPageCtrl()});
	srcPage:Attach(parentElem);
	srcPage:Init(url);
	self.page = srcPage;

	pe_iframe._super.OnLoadComponentBeforeChild(self, parentElem, parentLayout, css);
end

function pe_iframe:OnBeforeChildLayout(layout)
	local myLayout = layout:new();
	local css = self:GetStyle();
	local width, height = layout:GetPreferredSize();
	local padding_left, padding_top = css:padding_left(),css:padding_top();
	myLayout:reset(padding_left,padding_top,width+padding_left, height+padding_top);

	local pageElem = self.page:GetRoot();
	pageElem:UpdateLayout(myLayout);

	width, height = myLayout:GetUsedSize();
	width = width - padding_left;
	height = height - padding_top;
	layout:AddObject(width, height);
	return true;
end

