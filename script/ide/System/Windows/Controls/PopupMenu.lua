--[[
Title: PopupMenu
Author(s): LiPeng
Date: 2019/4/23
Desc: draw anything custom on the PopupMenu
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/PopupMenu.lua");
local PopupMenu = commonlib.gettable("System.Windows.Controls.PopupMenu");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/Controls/ListBox.lua");
NPL.load("(gl)script/ide/math/Point.lua");
local Point = commonlib.gettable("mathlib.Point");
local PopupMenu = commonlib.inherit(commonlib.gettable("System.Windows.Controls.ListBox"), commonlib.gettable("System.Windows.Controls.PopupMenu"));
PopupMenu:Property("Name", "PopupMenu");

function PopupMenu:ctor()
	self.hideReason = "";
	self.nextFocus = nil;
end

function PopupMenu:ClearHideInfo()
	self.hideReason = "";
	self.nextFocus = nil;
end

function PopupMenu:UpdateFromElement(element)
	if(element) then
		self:clear();
		self:AddItems(element:Items())
		self:selectItem(element:SelectedIndex());


		local size = math.min(self:Size(), element:GetMaxVisibleItems());
		local x, y = 0, element:height();
		local point = element:mapTo(self:GetWindow(), Point:new_from_pool(x, y));
		x, y = point:x(), point:y();
		local w, h = element:width(), self:GetItemHeight() * size;
		self:setGeometry(x, y, w, h);
	end
end

function PopupMenu:Open(element, focusReason)
	if(not self:isHidden()) then
		return;
	end
	if(element and element:GetField("Name") == "DropdownListbox" and self:NextFocus()) then
		if(self:NextFocus() == element and self.hideReason == "MouseFocusReason") then
			self:ClearHideInfo();
			return;
		end
	end

	self:UpdateFromElement(element);
	self:show();
	self:setFocus(focusReason);
end

function PopupMenu:Close()
	
end

function PopupMenu:HideReason()
	return self.hideReason;
end

function PopupMenu:NextFocus()
	return self.nextFocus;
end

function PopupMenu:focusOutEvent(event)
	PopupMenu._super.focusOutEvent(self, event)
	self.hideReason = event:GetReason();
	self.nextFocus = event:GetPrevOrNext();
	self:hide();
end

function PopupMenu:ApplyCss(css)
	self:SetBackgroundColor(css:BackgroundColor():ToString());
	self:SetBackground(css:BackgroundImage());

	if(css:HasBorder()) then
		self:SetBorders(css:Border():Format());
	end

	self:SetItemHeight(css:ComputedLineHeight());
	if(self.viewport) then
		self.viewport:ApplyCss(css);
	end
end

function PopupMenu:SetTextMargin(left, top, right, bottom)
	if(self.viewport) then
		self.viewport:SetIndent(left);
	end
end