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
NPL.load("(gl)script/ide/System/Windows/Controls/ScrollArea.lua");
local ScrollArea = commonlib.gettable("System.Windows.Controls.ScrollArea");
local PageElement = commonlib.gettable("System.Windows.mcml.PageElement");

local pe_scrollarea = commonlib.inherit(commonlib.gettable("System.Windows.mcml.Elements.pe_container"), commonlib.gettable("System.Windows.mcml.Elements.pe_scrollarea"));
pe_scrollarea:Property({"class_name", "pe:scrollarea"});

function pe_scrollarea:ctor()
end

function pe_scrollarea:LoadComponent(parentElem, parentLayout, style)
	local _this = self.control;
	if(not _this) then
		_this = ScrollArea:new():init(parentElem);
		self:SetControl(_this);
	else
		_this:SetParent(parentElem);
	end
	PageElement.LoadComponent(self, _this.viewport, parentLayout, style);
	_this:ApplyCss(self:GetStyle());
end

function pe_scrollarea:OnAfterChildLayout(layout, left, top, right, bottom)
	local css = self:GetStyle();
	local real_w, real_h = layout:GetRealSize();

	if(self.control) then
		self.control:setGeometry(left, top, right-left, bottom-top);
		if(self.control.viewport) then
			self.control.viewport:setGeometry(0, 0, real_w, real_h);
		end
		self.control:scrollToPos();

		-- use ScrollToEnd="true" in mcml <pe_treeview/>
		local ScrollToEnd = self:GetBool("ScrollToEnd");
		if(ScrollToEnd) then
			self.control:scrollToEnd();
		end
	end
end