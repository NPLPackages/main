--[[
Title: FrameView
Author(s): LiPeng
Date: 2018/3/1
Desc: the layout manager used by mcml Page.
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/mcml/page/FrameView.lua");
local FrameView = commonlib.gettable("System.Windows.mcml.page.FrameView");
------------------------------------------------------------
]]

local FrameView = commonlib.inherit(nil, commonlib.gettable("System.Windows.mcml.page.FrameView"));

function FrameView:ctor()
	self.parent = nil;
	self.page = nil;
end

-- initialize a top level layout manager for a given page object(parent).
function FrameView:SetPage(page, uiElement)
	self.parent = uiElement;
	self.page = page;
end

function FrameView:RootLayout()
	if(self.page and self.page.mcmlNode) then
		--return self.page:GetLayoutObject();
		return self.page.mcmlNode:GetLayoutObject();
	end
	return nil;
end

function FrameView:Layout()
	local root = self:RootLayout();
	if(root) then
		root:Layout();
	end
end

-- recalculate the layout according to current uiElement (Window)'s size
function FrameView:activate()
	if (self.activated) then
        return false;
	end
	if(self.page and self.parent) then
		self.activated = true;
		self:Layout();
	end
end

-- Updates the layout for GetParent().
function FrameView:update(layout_object)
    local layout = self;
    while (layout and layout.activated) do
        layout.activated = false;
        if (layout.topLevel) then
            Application:postEvent(layout:GetParent(), Event:new_static("LayoutRequestEvent"));
            break;
        end
        layout = layout:GetParent();
    end
end

function FrameView:widgetEvent(event)
	local type = event:GetType();
	if(type == "sizeEvent" or type == "LayoutRequestEvent") then
		self:Layout();
	end
--	if(type == "sizeEvent") then
--		if (self.activated) then
--			self:doResize(event:width(), event:height());
--		else
--			self:activate();
--		end
--	elseif(type == "LayoutRequestEvent") then
--        if (self:GetParent() and self:GetParent():isVisible()) then
--            self:activate();
--		end
--	end
end

-- return the top level mcml page object. 
function FrameView:GetPage()
	return self.page;
end

-- If this item is a UI element, it is returned as a UI element; otherwise nil is returned. 
function FrameView:widget()
	return self.parent;
end

function FrameView:LayoutWidth()
	if(self.parent) then
		return self.parent:width();
	end
end

function FrameView:LayoutHeight()
	if(self.parent) then
		return self.parent:height();
	end
end

function FrameView:GetUsedSize()
	--TODO: fixed this function
	return 0, 0;
end