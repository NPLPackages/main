--[[
Title: SearchBox
Author(s): LiXizhi
Date: 2015/4/29
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/Controls/SearchBox.lua");
local SearchBox = commonlib.gettable("System.Windows.Controls.SearchBox");
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Windows/UIElement.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/EditBox.lua");
NPL.load("(gl)script/ide/System/Windows/Controls/Button.lua");
NPL.load("(gl)script/ide/System/Scene/Overlays/ShapesDrawer.lua");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local Button = commonlib.gettable("System.Windows.Controls.Button");
local EditBox = commonlib.gettable("System.Windows.Controls.EditBox");
local SearchBox = commonlib.inherit(commonlib.gettable("System.Windows.UIElement"), commonlib.gettable("System.Windows.Controls.SearchBox"));
SearchBox:Property("Name", "SearchBox");
SearchBox:Property({"BackgroundColor", "#ffffff", auto=true});
SearchBox:Property({"InputBoxWidth", 100, auto=true})
SearchBox:Property({"InputBoxHeight", 20, auto=true})
SearchBox:Property({"InputBoxMarginLeft", 0, auto=true})
SearchBox:Property({"InputBoxMarginTop", 0, auto=true})
SearchBox:Property({"InputBoxMarginRight", 0, auto=true})
SearchBox:Property({"InputBoxMarginBottom", 0, auto=true})

SearchBox:Property({"CloseBtnWidth", 20, auto=true})
SearchBox:Property({"CloseBtnHeight", 20, auto=true})
SearchBox:Property({"CloseBtnMarginLeft", 0, auto=true})
SearchBox:Property({"CloseBtnMarginTop", 0, auto=true})
SearchBox:Property({"CloseBtnMarginRight", 0, auto=true})
SearchBox:Property({"CloseBtnMarginBottom", 0, auto=true})

SearchBox:Property({"PaddingLeft", 5, auto=true})
SearchBox:Property({"PaddingTop", 5, auto=true})
SearchBox:Property({"PaddingRight", 5, auto=true})
SearchBox:Property({"PaddingBottom", 5, auto=true})

SearchBox:Property({"BorderWidth", 1, auto=true})
SearchBox:Property({"BorderColor", "#000000", auto=true})

SearchBox:Signal("moveUp", function(text) end);
SearchBox:Signal("moveDown", function(text) end);

SearchBox:Signal("textChanged", function(text) end);

SearchBox:Signal("closed");


--SearchBox:Property({"m_blinkPeriod", 0, "getCursorBlinkPeriod", "setCursorBlinkPeriod"})

function SearchBox:ctor()
	self.inputbox = nil;
	self.closebtn = nil;
	self.owner = nil;

	self.realWidth = nil;
	self.realHeight = nil;
end

function SearchBox:init(parent)
	SearchBox._super.init(self, parent)

	self.inputbox = EditBox:new():init(self);
	self.inputbox:SetBackgroundColor("#ffffff")
	self.inputbox:SetAlignment(0+4+256)
	self.inputbox:Connect("textChanged",function(text)
		self.inputbox:SetColor("#000000");
		self:textChanged(text);
	end)
	self.inputbox:Connect("escape",function()
		self:emitClosed();
	end)
	self.inputbox:Connect("editingFinished",function()
		self:moveDown(self.inputbox:GetText());
	end)
	self.closebtn = Button:new():init(self);
	self.closebtn:SetPolygonStyle("close");
	self.closebtn:SetSize(10);
	self.closebtn:Connect("clicked",function()
		self:emitClosed();
	end)

	self:updateChildrenPosition();

	return self;
end

function SearchBox:emitClosed()
	self:closed()
end

function SearchBox:setSearchContent(text)
	if(text) then
		self.inputbox:SetText(text);
	end
	self.inputbox:selectAll();
	self.inputbox:setFocus("OtherFocusReason");
end

function SearchBox:updateChildrenPosition()
	local x, y, w, h = self:GetInputBoxMarginLeft(), self:GetInputBoxMarginTop(), self:GetInputBoxWidth(), self:GetInputBoxHeight();
	x = x + self:GetBorderWidth() + self:GetPaddingLeft();
	y = y + self:GetBorderWidth() + self:GetPaddingTop();
	self.inputbox:setGeometry(x, y, w, h);
	x, y, w, h = self:GetCloseBtnMarginLeft(), self:GetCloseBtnMarginTop(), self:GetCloseBtnWidth(), self:GetCloseBtnHeight();
	x = x + self:GetBorderWidth() + self:GetPaddingLeft();
	x = x + self:GetInputBoxMarginLeft() + self:GetInputBoxWidth() + self:GetInputBoxMarginRight();
	y = y + self:GetBorderWidth() + self:GetPaddingTop();
	self.closebtn:setGeometry(x, y, w, h);
end

function SearchBox:reset()
	self.realWidth = nil;
	self.realHeight = nil;
end

function SearchBox:childrenWidth()
	local width = self:GetInputBoxMarginLeft() + self:GetInputBoxWidth() + self:GetInputBoxMarginRight()
	width = width + self:GetCloseBtnMarginLeft() + self:GetCloseBtnWidth() + self:GetCloseBtnMarginRight()
	return width
end

function SearchBox:calculateWidth()
	if(not self.realWidth) then
		local width = self:GetBorderWidth() + self:GetPaddingLeft();
		width = width + self:GetInputBoxMarginLeft() + self:GetInputBoxWidth() + self:GetInputBoxMarginRight()
		width = width + self:GetCloseBtnMarginLeft() + self:GetCloseBtnWidth() + self:GetCloseBtnMarginRight()
		width = width + self:GetBorderWidth() + self:GetPaddingRight();
		self.realWidth = width;
	end
	return self.realWidth;
end

function SearchBox:childrenHeight()
	local inputboxHeight = self:GetInputBoxMarginTop() + self:GetInputBoxHeight() + self:GetInputBoxMarginBottom();
	local closebtnHeight = self:GetCloseBtnMarginTop() + self:GetCloseBtnHeight() + self:GetCloseBtnMarginBottom();
	local height = math.max(inputboxHeight, closebtnHeight);
	return height
end

function SearchBox:calculateHeight()
	if(not self.realHeight) then
		local height = self:GetBorderWidth() + self:GetPaddingTop();
		local inputboxHeight = self:GetInputBoxMarginTop() + self:GetInputBoxHeight() + self:GetInputBoxMarginBottom();
		local closebtnHeight = self:GetCloseBtnMarginTop() + self:GetCloseBtnHeight() + self:GetCloseBtnMarginBottom();
		height = height + math.max(inputboxHeight, closebtnHeight);
		height = height + self:GetBorderWidth() + self:GetPaddingBottom();
		self.realHeight = height;
	end
	return self.realHeight;
end

function SearchBox:setPosition(x, y)
	local w, h = self:calculateWidth(), self:calculateHeight();
	self:setGeometry(x, y, w, h);
end

function SearchBox:setGeometry(ax, ay, aw, ah)
	SearchBox._super.setGeometry(self, ax, ay, aw, ah);
	local childrenWidth, childrenHeight = self:childrenWidth(), self:childrenHeight();
	local real_w = childrenWidth + self:GetBorderWidth() * 2 + self:GetPaddingLeft() + self:GetPaddingRight();
	local real_h = childrenHeight + self:GetBorderWidth() * 2 + self:GetPaddingTop() + self:GetPaddingBottom();
	if(aw > real_w or ah > real_h) then
		if(aw > real_w) then
--			local padding = math.floor((aw - childrenWidth - self:GetBorderWidth() * 2) / 2 + 0.5);
--			self:SetPaddingLeft(padding);
--			self:SetPaddingRight(padding);
			self:SetInputBoxWidth(self:GetInputBoxWidth() + aw - real_w)
		end

		if(ah > real_h) then
			local padding = math.floor((ah - childrenHeight - self:GetBorderWidth() * 2) / 2 + 0.5);
			self:SetPaddingTop(padding);
			self:SetPaddingBottom(padding);
		end
		self:updateChildrenPosition();
	end


end

function SearchBox:searchResult(b)
	local color = if_else(b, "#000000", "#ff0000");
	self.inputbox:SetColor(color);
end

-- for performance reasons, use global variables
local pen = {};

function SearchBox:paintBorder(painter)
	local borderWidth = self:GetBorderWidth();
	
	pen.width = borderWidth;
	pen.color = self:GetBorderColor();
	painter:SetPen(pen);

	ShapesDrawer.DrawRect2DBorder(painter, self:x(), self:y(), self:width(), self:height())
end

function SearchBox:paintEvent(painter)
	painter:SetPen(self:GetBackgroundColor());
	painter:DrawRectTexture(self:x(), self:y(), self:width(), self:height(), self:GetBackground());

	self:paintBorder(painter)
end


